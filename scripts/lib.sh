# Shared plumbing for the Cull scripts. Sourced, never executed.
#
# Everything machine-specific (team ID, which phone) is resolved here, so the
# other scripts read as the workflow itself rather than as a pile of lookups.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The project sits one level down: the repo root holds scripts/, docs/ and the
# design sources, and Cull/ is the Xcode project itself.
PROJECT="$ROOT/Cull/Cull.xcodeproj"
SCHEME="Cull"
APP_TARGET="Cull"
TEST_TARGET="CullTests"
BUNDLE_ID="com.mirobehninger.cull"
BUILD_DIR="$ROOT/build"
BACKUP_DIR="$ROOT/backups"

# Machine-local settings, kept out of git: DEVELOPMENT_TEAM, CULL_DEVICE.
LOCAL_ENV="$ROOT/scripts/local.env"
# shellcheck disable=SC1090
[[ -f "$LOCAL_ENV" ]] && source "$LOCAL_ENV"

if [[ -t 1 ]]; then
    BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
else
    BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; RESET=""
fi

step() { printf '%s==>%s %s\n' "$BOLD" "$RESET" "$*"; }
info() { printf '    %s\n' "$*"; }
note() { printf '    %s%s%s\n' "$DIM" "$*" "$RESET"; }
warn() { printf '%s !! %s%s\n' "$YELLOW" "$*" "$RESET" >&2; }
fail() { printf '%s !! %s%s\n' "$RED" "$*" "$RESET" >&2; exit 1; }
ok()   { printf '%s ✓  %s%s\n' "$GREEN" "$*" "$RESET"; }

# Whether the project has a unit-test target yet. Cull ships without one, and
# `test` has to say that plainly rather than fail inside xcodebuild.
has_test_target() {
    xcodebuild -list -project "$PROJECT" 2>/dev/null \
        | awk '/Targets:/{t=1;next} /^$/{t=0} t' | grep -qx "[[:space:]]*$TEST_TARGET"
}

# Teams Xcode itself knows about, one "<teamID> <name>" per line. Empty when no
# Apple ID is signed in under Xcode ▸ Settings ▸ Accounts — which is the state
# that makes automatic signing fail with "No profiles for ... were found",
# however correct the team ID is.
xcode_teams() {
    local plist="$HOME/Library/Preferences/com.apple.dt.Xcode.plist"
    [[ -f "$plist" ]] || return 0
    plutil -convert json -o - "$plist" 2>/dev/null | python3 -c '
import json, sys

try:
    preferences = json.load(sys.stdin)
except ValueError:
    sys.exit(0)

for entries in (preferences.get("IDEProvisioningTeams") or {}).values():
    for team in entries:
        identifier = team.get("teamID")
        if identifier:
            print(identifier, team.get("teamName", ""))
'
}

# The Apple Developer team the device build signs with.
#
# In order: the environment, scripts/local.env, the teams Xcode has signed in,
# and finally the signing certificate in the keychain. The team ID there is the
# *organisational unit*, not the parenthesised id in the certificate name — that
# one is the individual developer, and handing it to xcodebuild produces a
# baffling "No Account for Team" error.
resolve_team() {
    if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
        printf '%s' "$DEVELOPMENT_TEAM"
        return
    fi

    local guess
    guess="$(xcode_teams | head -1 | cut -d' ' -f1)"
    if [[ -z "$guess" ]]; then
        guess="$(certificate_team)"
    fi

    [[ -n "$guess" ]] || fail "No signing team found. Sign in under Xcode ▸ Settings ▸ Accounts, or put DEVELOPMENT_TEAM=XXXXXXXXXX in scripts/local.env."
    printf '%s' "$guess"
}

# Team ID from the OU of a valid "Apple Development" certificate in the keychain.
certificate_team() {
    security find-certificate -a -c "Apple Development" -p 2>/dev/null | python3 -c '
import subprocess, sys

pem = sys.stdin.read()
header = "-----BEGIN CERTIFICATE-----"
for block in pem.split(header)[1:]:
    certificate = header + block
    # -checkend 0 fails on an expired certificate, so an old one cannot win.
    result = subprocess.run(
        ["openssl", "x509", "-noout", "-subject", "-checkend", "0"],
        input=certificate, capture_output=True, text=True,
    )
    if result.returncode != 0:
        continue
    for field in result.stdout.split(","):
        field = field.strip()
        if field.startswith("OU="):
            print(field[3:].strip())
            sys.exit(0)
'
}

# The iPhone to install onto: $CULL_DEVICE if set, otherwise the only connected
# one. Prints the device identifier.
resolve_device() {
    local json chosen
    json="$(mktemp)"
    xcrun devicectl list devices --json-output "$json" >/dev/null 2>&1 \
        || fail "devicectl could not list devices. Is Xcode installed and the phone trusted?"

    # The exit status of this function has to be python's, not the cleanup's — a
    # caller asking "is a phone connected?" reads the exit code.
    chosen="$(DEVICE_JSON="$json" WANTED="${CULL_DEVICE:-}" python3 - <<'PY'
import json, os, sys

devices = json.load(open(os.environ["DEVICE_JSON"]))["result"]["devices"]
wanted = os.environ.get("WANTED", "").strip()

# `devicectl list devices` lists the simulators as well, and every one of them
# is "paired" and a booted one is "connected" — so a predicate that only asks
# about the connection matches all of them and the real phone drowns in a
# "more than one device connected" error.
#
# Excluding the simulators rather than requiring reality == "physical": a phone
# devicectl has not yet opened a tunnel to reports no hardware properties at all
# — reality and model both null — and the positive test drops it silently. The
# phone then never appears as a candidate, and a second, older phone that *is*
# fully described wins every install without a word about it.
def is_phone(device):
    return device.get("hardwareProperties", {}).get("reality") != "simulated"

# A wired, trusted phone sits at tunnelState "disconnected" until something
# actually talks to it; devicectl opens the tunnel on demand. So "unavailable"
# is the only value that means out of reach, and an unpaired phone is one that
# has not been told to trust this Mac.
def usable(device):
    connection = device.get("connectionProperties", {})
    return (connection.get("tunnelState") != "unavailable"
            and connection.get("pairingState") == "paired")

# CULL_DEVICE may name the phone or either of its two ids: `devicectl list
# devices` prints the hardware UDID in its Identifier column, while the JSON
# "identifier" is a different uuid, and the one you can read is the one you
# will paste.
def identities(device):
    hardware = device.get("hardwareProperties", {})
    return {device["identifier"], hardware.get("udid"),
            device["deviceProperties"].get("name")} - {None}

def describe(device):
    hardware = device.get("hardwareProperties", {})
    identifier = hardware.get("udid") or device["identifier"]
    model = hardware.get("marketingName")
    name = device["deviceProperties"].get("name", "?")
    return (f"{name} [{model}]" if model else name), identifier

phones = [d for d in devices if is_phone(d)]

if wanted:
    for device in phones:
        if wanted in identities(device):
            print(device["identifier"])
            sys.exit(0)
    sys.exit(f"No iPhone matching CULL_DEVICE={wanted!r}. Seen: " +
             (", ".join(f"{n} ({i})" for n, i in map(describe, phones)) or "none"))

candidates = [d for d in phones if usable(d)]
if not candidates:
    seen = ", ".join(f"{n} ({i})" for n, i in map(describe, phones)) or "none"
    sys.exit("No connected iPhone. Plug it in, unlock it, and trust this Mac. "
             f"Known iPhones: {seen}")
if len(candidates) > 1:
    listed = ", ".join(f"{n} ({i})" for n, i in map(describe, candidates))
    sys.exit("More than one iPhone connected; set CULL_DEVICE in scripts/local.env "
             f"to one of these UDIDs. Candidates: {listed}")
print(candidates[0]["identifier"])
PY
    )" || { rm -f "$json"; return 1; }
    rm -f "$json"
    printf '%s' "$chosen"
}

device_name() {
    local json name
    json="$(mktemp)"
    xcrun devicectl list devices --json-output "$json" >/dev/null 2>&1 || { rm -f "$json"; return 1; }
    # The model goes in the name: two phones on this Mac can be called the same
    # thing, and "iPhone von Miro" alone does not say which one was installed to.
    name="$(DEVICE_JSON="$json" WANTED="$1" python3 -c '
import json, os
devices = json.load(open(os.environ["DEVICE_JSON"]))["result"]["devices"]
wanted = os.environ["WANTED"]
for device in devices:
    if device["identifier"] != wanted:
        continue
    name = device["deviceProperties"].get("name", "?")
    model = device.get("hardwareProperties", {}).get("marketingName")
    print(f"{name} [{model}]" if model else name)
    break
else:
    print(wanted)')"
    rm -f "$json"
    printf '%s' "$name"
}

# A simulator to run on: a booted one if there is one, else the newest available
# iPhone. Prints "<udid> <name>". Resolved at run time because the installed
# runtimes differ between this Mac and a CI runner.
resolve_simulator() {
    xcrun simctl list devices available --json | python3 -c '
import json, sys

devices = json.load(sys.stdin)["devices"]

def runtime_order(runtime):
    # "com.apple.CoreSimulator.SimRuntime.iOS-26-2" → (26, 2)
    tail = runtime.rsplit(".", 1)[-1]
    parts = tail.split("-")[1:]
    return tuple(int(p) for p in parts if p.isdigit())

best = None
for runtime, entries in devices.items():
    if "iOS" not in runtime:
        continue
    for device in entries:
        if not device["name"].startswith("iPhone"):
            continue
        # Booted first, then newest runtime: reusing a booted simulator saves
        # the ~20s cold boot on every run, and keeps the photos already seeded
        # into its library.
        key = (device["state"] == "Booted", runtime_order(runtime))
        if best is None or key > best[0]:
            best = (key, device["udid"], device["name"], runtime)

if best is None:
    sys.exit("No iPhone simulator available. Run: xcodebuild -downloadPlatform iOS")
_, udid, name, _ = best
print(udid, name)
'
}

# The destinations Xcode will actually accept for this scheme, one per line.
#
# `-showdestinations` prints the usable ones first and the rejected ones under a
# second header, and the wording of both headers moves between Xcode releases:
# 26 said "Available destinations"/"Ineligible destinations", 27 says
# "Destinations compatible with"/"Destinations incompatible with". Matching one
# header exactly is what silently breaks after an Xcode update — the range
# matches nothing, so every caller concludes there are no destinations at all.
#
# So: stop at whichever rejected-section header this Xcode prints, and belt and
# braces, drop any line carrying `error:`, which only a rejected entry has.
compatible_destinations() {
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null \
        | awk '/[Ii]neligible destinations|[Dd]estinations incompatible/ { exit } !/error:/'
}

# Whether Xcode has a usable iOS simulator destination for this project. When the
# SDK is newer than every installed runtime, Xcode rejects all of them and
# nothing that needs a destination — running in a simulator, installing on a
# phone — can work until the platform is downloaded.
has_eligible_simulator_destination() {
    compatible_destinations | grep -q "platform:iOS Simulator"
}

# The same question for the phone. "platform:iOS," with the comma so it cannot
# match "platform:iOS Simulator".
has_eligible_device_destination() {
    compatible_destinations | grep -q "platform:iOS,"
}

# Opens the UI that shows a booted simulator's screen. Non-zero if it cannot.
#
# Xcode 27 deleted the standalone Simulator.app and replaced it with
# DeviceHub.app, moving the bundled apps from Contents/Developer/Applications
# to Contents/Applications. `open -a Simulator` does not degrade gracefully
# there — it fails outright with "Unable to find application named 'Simulator'",
# so the device boots and the app launches headlessly while no window ever
# appears, and the script reports success while showing nothing.
#
# Resolve inside the *active* Xcode first so a second Xcode on the machine
# cannot win, then by bundle id, and finally fall back to the pre-27 app.
open_simulator_ui() {
    local devicehub
    devicehub="$(xcode-select -p 2>/dev/null)/../Applications/DeviceHub.app"

    if [[ -d "$devicehub" ]]; then
        if open "$devicehub" 2>/dev/null; then return 0; fi
    fi
    # Xcode 27+ by bundle id, then the pre-27 app.
    if open -b com.apple.dt.Devices 2>/dev/null; then return 0; fi
    if open -a Simulator 2>/dev/null; then return 0; fi
    return 1
}

platform_download_hint() {
    warn "No eligible iOS destination — Xcode's SDK is newer than every installed runtime."
    info "Fix it once (~8 GB):"
    info "    xcodebuild -downloadPlatform iOS"
    info "Then re-run this script."
}
