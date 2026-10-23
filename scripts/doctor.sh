#!/usr/bin/env bash
#
# Checks everything the workflow depends on, and says what to do about each
# thing that is missing. Run it first when something stops working.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

FAILURES=0
pass() { printf '%s ✓ %s %s\n' "$GREEN" "$RESET" "$*"; }
miss() { printf '%s ✗ %s %s\n' "$RED" "$RESET" "$*"; FAILURES=$((FAILURES + 1)); }
soft() { printf '%s ~ %s %s\n' "$YELLOW" "$RESET" "$*"; }

step "Toolchain"
if command -v xcodebuild >/dev/null 2>&1; then
    pass "$(xcodebuild -version | head -1) at $(xcode-select -p)"
else
    miss "No xcodebuild. Install Xcode and run: sudo xcode-select -s /Applications/Xcode.app"
fi
if [[ -d "$PROJECT" ]]; then
    pass "Project at ${PROJECT#$ROOT/}"
else
    miss "No project at ${PROJECT#$ROOT/} — PROJECT in scripts/lib.sh is wrong."
fi

step "iOS platform"
# The failure this catches is the confusing one: the project and scheme are
# fine, but Xcode's SDK is newer than every installed runtime, so it rejects
# every destination and nothing can be built or tested.
if has_eligible_simulator_destination; then
    pass "Simulator destinations available"
    xcrun simctl list runtimes 2>/dev/null | grep -i "^iOS" | sed 's/^/      /'
else
    miss "No eligible iOS simulator destination. Fix once (~8 GB): xcodebuild -downloadPlatform iOS"
fi
if has_eligible_device_destination; then
    pass "Device destinations available"
else
    miss "No iOS device destination — the same download fixes this."
fi
# Xcode 27 replaced Simulator.app with DeviceHub.app. Without this check a
# missing UI app is invisible: the device boots headlessly and sim.sh looks fine.
devicehub="$(xcode-select -p 2>/dev/null)/../Applications/DeviceHub.app"
if [[ -d "$devicehub" ]]; then
    pass "Simulator UI: DeviceHub.app (Xcode 27+)"
elif open -Ra Simulator 2>/dev/null; then
    pass "Simulator UI: Simulator.app (Xcode 26 and older)"
else
    miss "No simulator UI app found — simulators will only run headlessly. Reinstall Xcode."
fi

step "Photo access"
# Rummage is nothing without the photo library, and a missing usage description is
# not a build error: the app launches, asks for access, and iOS kills it the
# instant it does. Checked against the build settings because the Info.plist is
# generated from them (INFOPLIST_KEY_*), so there is no file to read.
settings="$(xcodebuild -project "$PROJECT" -target "$APP_TARGET" -configuration Debug -showBuildSettings 2>/dev/null || true)"
for key in NSPhotoLibraryUsageDescription; do
    if grep -q "INFOPLIST_KEY_$key = ." <<<"$settings"; then
        pass "$key set"
    else
        miss "$key missing — the app will be killed when it asks for the library. Add it in the target's Info settings."
    fi
done

step "Signing"
if identity="$(security find-identity -v -p codesigning 2>/dev/null \
    | sed -n 's/.*"\(Apple Development: [^"]*\)".*/\1/p' | head -1)" && [[ -n "$identity" ]]; then
    pass "$identity"
    if team="$(resolve_team 2>/dev/null)"; then
        if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
            pass "Team $team (from ${LOCAL_ENV#$ROOT/})"
        else
            soft "Team $team (read from the certificate; pin it in ${LOCAL_ENV#$ROOT/} if installs fail)"
        fi
    fi
else
    miss "No Apple Development certificate. Add your Apple ID in Xcode ▸ Settings ▸ Accounts."
fi

# Xcode caches the teams it has fetched for signing. The cache being empty does
# *not* prove no account is signed in — it is only populated once Xcode has
# actually signed something — so this is a hint, never a verdict. Whether
# signing works is decided by Apple's servers at build time.
if teams="$(xcode_teams)" && [[ -n "$teams" ]]; then
    pass "Xcode knows team(s): $(echo "$teams" | tr '\n' ';' | sed 's/;$//')"
else
    soft "Xcode has no cached teams yet — normal before the first device build."
    note "If signing fails, the error names the cause. Two that read as project problems:"
    note "  'No Account for Team X'  → no Apple ID in Xcode ▸ Settings ▸ Accounts, or the wrong team"
    note "  'PLA Update available'   → accept the agreement at developer.apple.com/account"
fi

if [[ -n "$(ls -A "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" 2>/dev/null)" ]]; then
    pass "Provisioning profiles present"
else
    soft "No provisioning profile yet — the first device install creates one."
fi

step "iPhone"
# resolve_device's own message says which of "not plugged in", "not trusted"
# and "more than one phone" it is. Discarding it and printing a generic
# "no iPhone" is what makes a phone devicectl can see look absent.
reason="$(mktemp)"
if device="$(resolve_device 2>"$reason")"; then
    pass "$(device_name "$device") ($device)"
    if apps="$(xcrun devicectl device info apps --device "$device" --bundle-id "$BUNDLE_ID" 2>/dev/null)" \
        && grep -q "$BUNDLE_ID" <<<"$apps"; then
        pass "Rummage is installed — the next install is an update and keeps its state"
    else
        soft "Rummage is not installed yet. First install: scripts/device.sh install --no-backup"
    fi
else
    soft "$(< "$reason")"
fi
rm -f "$reason"

step "Backups"
if [[ -d "$BACKUP_DIR" ]] && newest="$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | sort | tail -1)" && [[ -n "$newest" ]]; then
    pass "Newest: ${newest#$ROOT/} ($(du -sh "$newest" | cut -f1))"
else
    soft "No backups yet. 'scripts/device.sh install' takes one before each update."
fi

step "Tests"
if has_test_target; then
    pass "$TEST_TARGET target present — run it with scripts/test.sh"
else
    soft "No $TEST_TARGET target yet. Add one in Xcode (File ▸ New ▸ Target ▸ Unit Testing Bundle)."
fi

echo
if [[ $FAILURES -eq 0 ]]; then
    ok "Ready"
else
    fail "$FAILURES thing(s) need fixing"
fi
