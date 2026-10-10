#!/usr/bin/env bash
#
# Builds and runs Cull in a simulator.
#
#   scripts/sim.sh [--photos N] [--media PATH] [--erase]
#                  [--grant|--revoke] [--console]
#
# A fresh simulator's photo library is empty, and Cull with nothing to swipe
# shows its empty state and nothing else. --photos seeds generated images so the
# card stack, the progress counter and the delete confirmation all have
# something to work on; --media adds real files instead (a file or a directory).
#
# The permission prompt is part of the flow worth testing: --revoke puts the
# simulator back to "not yet asked", --grant skips straight past it, and --erase
# wipes the device entirely (photos, permissions and Cull's own counters).
#
# Note: this deliberately does *not* pass CODE_SIGNING_ALLOWED=NO, so the
# simulator build keeps the same entitlements as the device one.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

PHOTOS=0
MEDIA=()
ERASE=0
PRIVACY=""
CONSOLE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --photos) PHOTOS="${2:?--photos needs a count}"; shift 2 ;;
        --media) MEDIA+=("${2:?--media needs a path}"); shift 2 ;;
        --erase) ERASE=1; shift ;;
        --grant) PRIVACY="grant"; shift ;;
        --revoke) PRIVACY="reset"; shift ;;
        --console) CONSOLE=1; shift ;;
        -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) fail "Unknown argument: $1" ;;
    esac
done

[[ "$PHOTOS" =~ ^[0-9]+$ ]] || fail "--photos needs a number, got: $PHOTOS"

if ! has_eligible_simulator_destination; then
    platform_download_hint
    exit 1
fi

read -r UDID SIMULATOR_NAME <<<"$(resolve_simulator)"

if [[ $ERASE -eq 1 ]]; then
    step "Erasing $SIMULATOR_NAME"
    xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true   # already shut down is fine
    xcrun simctl erase "$UDID"
fi

step "Building for $SIMULATOR_NAME"

DERIVED="$BUILD_DIR/sim"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$UDID" \
    -derivedDataPath "$DERIVED" \
    build \
    | grep -E "error:|BUILD" || true

APP="$DERIVED/Build/Products/Debug-iphonesimulator/Cull.app"
[[ -d "$APP" ]] || fail "Build produced no app at $APP"

step "Booting $SIMULATOR_NAME"
# Open the UI first, then wait for the boot to finish. Installing into a
# half-booted device fails in ways that read as a signing or build problem.
#
# Not fatal: the install and launch below work on a headless device. But it must
# not be silent — a simulator that never appears while the script prints
# "Running" is the one failure this hides.
open_simulator_ui || warn "Could not open the simulator UI — the app will still run, but headlessly. Run scripts/doctor.sh."
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true   # already booted is fine
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || fail "Simulator $SIMULATOR_NAME would not boot."

step "Installing"
xcrun simctl install "$UDID" "$APP"

# ---------------------------------------------------------------- photos
#
# addmedia needs a booted device and copies into the Photos library, so the
# images survive reinstalls and only go away with --erase.

if [[ "$PHOTOS" -gt 0 ]]; then
    step "Generating $PHOTOS photos"
    GENERATED="$(mktemp -d)"
    # Written by hand rather than with Pillow: python3 is on every Mac and
    # Pillow is on none of them. Varying sizes matter — the summary screen adds
    # up bytes freed, and identical files make that number look fake.
    COUNT="$PHOTOS" OUT="$GENERATED" python3 - <<'PY'
import os, struct, zlib

count = int(os.environ["COUNT"])
out = os.environ["OUT"]

def chunk(kind, payload):
    return (struct.pack(">I", len(payload)) + kind + payload
            + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF))

for index in range(count):
    # A spread of sizes and hues, so the stack does not look like one photo
    # repeated and the storage figures vary.
    width = 900 + (index % 7) * 240
    height = 1200 + (index % 5) * 260
    hue = (index * 37) % 360
    rows = bytearray()
    for y in range(height):
        rows.append(0)  # PNG filter type for the scanline
        # A vertical gradient per image, tinted by the hue, computed once per row.
        shade = int(40 + 180 * y / height)
        red = (shade * (1 + hue % 3)) % 256
        green = (shade + hue) % 256
        blue = (shade * 2 + hue // 2) % 256
        rows.extend(bytes((red, green, blue)) * width)
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(bytes(rows), 6))
           + chunk(b"IEND", b""))
    with open(os.path.join(out, f"cull-sample-{index:03d}.png"), "wb") as handle:
        handle.write(png)
PY
    xcrun simctl addmedia "$UDID" "$GENERATED"/*.png
    rm -rf "$GENERATED"
    ok "$PHOTOS photos in the library"
fi

if [[ ${#MEDIA[@]} -gt 0 ]]; then
    step "Adding ${MEDIA[*]}"
    for path in "${MEDIA[@]}"; do
        [[ -e "$path" ]] || fail "No such file or directory: $path"
        if [[ -d "$path" ]]; then
            # Nullglob off by default in bash 3.2, so an empty directory would
            # hand simctl a literal glob; check first and say so.
            files=("$path"/*)
            [[ -e "${files[0]}" ]] || fail "$path is empty."
            xcrun simctl addmedia "$UDID" "${files[@]}"
        else
            xcrun simctl addmedia "$UDID" "$path"
        fi
    done
fi

# ---------------------------------------------------------------- permission

case "$PRIVACY" in
    grant)
        step "Granting photo access"
        # Both services: Cull reads the library and deletes from it.
        xcrun simctl privacy "$UDID" grant photos "$BUNDLE_ID" >/dev/null 2>&1 \
            || warn "Could not grant 'photos' — the app will ask on launch."
        xcrun simctl privacy "$UDID" grant photos-add "$BUNDLE_ID" >/dev/null 2>&1 || true
        ;;
    reset)
        step "Resetting photo access — the app will ask again"
        xcrun simctl privacy "$UDID" reset photos "$BUNDLE_ID" >/dev/null 2>&1 \
            || warn "Could not reset 'photos'."
        xcrun simctl privacy "$UDID" reset photos-add "$BUNDLE_ID" >/dev/null 2>&1 || true
        ;;
esac

step "Launching"
if [[ $CONSOLE -eq 1 ]]; then
    xcrun simctl launch --console-pty --terminate-running-process "$UDID" "$BUNDLE_ID"
else
    # --terminate-running-process: without it, launching over the copy that is
    # already running just foregrounds the old code and the rebuild is invisible.
    xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" >/dev/null
    ok "Running on $SIMULATOR_NAME"
fi
