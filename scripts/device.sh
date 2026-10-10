#!/usr/bin/env bash
#
# The loop for running Cull on your own iPhone, against your real photo library.
#
#   scripts/device.sh install [--no-backup] [--no-launch] [--release]
#   scripts/device.sh backup  [--source PATH]
#   scripts/device.sh restore <backups/DIR>
#   scripts/device.sh logs
#   scripts/device.sh files   [PATH]
#   scripts/device.sh list
#
# Installing over the app already on the phone is an *update*: iOS keeps the
# app's container, so the kept-photo marks and the lifetime counters survive.
# What loses them is deleting the app, or signing the next build as a different
# team. `install` therefore takes a backup first, unless told not to.
#
# Scope worth being clear about: these backups cover Cull's own state only. Your
# photos live in the system photo library, which nothing here copies — and which
# Cull deletes from only through PhotoKit, so removed photos sit in Recently
# Deleted for 30 days.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

usage() { sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; }

# ---------------------------------------------------------------- helpers

# PID of the running app on the device, if any.
app_pid() {
    local device="$1" json
    json="$(mktemp)"
    if ! xcrun devicectl device info processes --device "$device" --json-output "$json" >/dev/null 2>&1; then
        rm -f "$json"; return 1
    fi
    PROC_JSON="$json" python3 -c '
import json, os
processes = json.load(open(os.environ["PROC_JSON"]))["result"]["runningProcesses"]
for process in processes:
    path = process.get("executable", "") or ""
    if "/Cull.app/Cull" in path:
        print(process["processIdentifier"])
        break
'
    rm -f "$json"
}

# ---------------------------------------------------------------- backup

do_backup() {
    local source_path="/"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --source) source_path="${2:?--source needs a path}"; shift 2 ;;
            *) fail "backup: unknown argument $1" ;;
        esac
    done

    local device destination
    device="$(resolve_device)"
    destination="$BACKUP_DIR/$(date +%Y%m%dT%H%M%S)"
    mkdir -p "$destination"

    step "Backing up $BUNDLE_ID from $(device_name "$device")"
    if ! xcrun devicectl device copy from \
        --device "$device" \
        --domain-type appDataContainer \
        --domain-identifier "$BUNDLE_ID" \
        --source "$source_path" \
        --destination "$destination" >/dev/null 2>&1
    then
        rmdir "$destination" 2>/dev/null || true
        warn "Could not copy the container."
        info "Usually this means the app is not installed on the phone yet, or this build was not signed for development."
        info "Run 'scripts/device.sh install --no-backup' first."
        return 1
    fi

    # What the backup is *of* matters as much as the bytes: a restore weeks later
    # has to know which build wrote this state.
    {
        echo "captured:  $(date -Iseconds)"
        echo "device:    $(device_name "$device") ($device)"
        echo "bundle:    $BUNDLE_ID"
        echo "source:    $source_path"
        echo "commit:    $(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
        echo "branch:    $(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
        echo "dirty:     $([[ -n "$(git -C "$ROOT" status --porcelain 2>/dev/null)" ]] && echo yes || echo no)"
    } > "$destination/MANIFEST.txt"

    ok "Backup at ${destination#$ROOT/} ($(du -sh "$destination" | cut -f1))"
}

# ---------------------------------------------------------------- restore

do_restore() {
    local backup="${1:?restore needs a backup directory — see backups/}"
    [[ -d "$backup" ]] || fail "No such backup: $backup"

    # Cull keeps everything it owns in UserDefaults — the kept-photo marks, the
    # lifetime culled count, the storage-freed total — which on disk is
    # Library/Preferences/<bundle id>.plist inside the container. The container
    # copy lands under one directory per domain, so find that tree rather than
    # guess at the nesting.
    local payload
    payload="$(find "$backup" -maxdepth 3 -type d -name "Preferences" -print -quit || true)"
    [[ -n "$payload" ]] || fail "No 'Library/Preferences' directory inside $backup — is this a container backup?"

    local device
    device="$(resolve_device)"

    warn "This replaces Cull's stored state on $(device_name "$device") with the copy in $backup."
    note "Your photos are untouched either way — they are not in this backup."
    [[ -f "$backup/MANIFEST.txt" ]] && sed 's/^/    /' "$backup/MANIFEST.txt"
    printf 'Type "restore" to continue: '
    read -r answer
    [[ "$answer" == "restore" ]] || fail "Cancelled."

    # The running app holds its defaults in memory and writes them back on the
    # way out, which would undo the restore a minute later.
    local pid
    pid="$(app_pid "$device" || true)"
    if [[ -n "${pid:-}" ]]; then
        step "Stopping the app (pid $pid)"
        xcrun devicectl device process terminate --device "$device" --pid "$pid" >/dev/null 2>&1 || true
        sleep 1
    fi

    step "Restoring Library/Preferences"
    xcrun devicectl device copy to \
        --device "$device" \
        --domain-type appDataContainer \
        --domain-identifier "$BUNDLE_ID" \
        --source "$payload" \
        --destination "Library/Preferences" \
        --remove-existing-content true \
        || fail "Restore failed. The app's own state is untouched unless the copy had already started."

    ok "Restored. Launch the app and check the counters on the home screen."
}

# ---------------------------------------------------------------- install

do_install() {
    local backup=1 launch=1 configuration="Debug"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-backup) backup=0; shift ;;
            --no-launch) launch=0; shift ;;
            --release) configuration="Release"; shift ;;
            *) fail "install: unknown argument $1" ;;
        esac
    done

    local device team
    device="$(resolve_device)"
    team="$(resolve_team)"

    if ! has_eligible_device_destination; then
        platform_download_hint
        exit 1
    fi

    if [[ $backup -eq 1 ]]; then
        # Best effort: a first install has nothing to back up, and that is not a
        # reason to refuse to install.
        do_backup || note "Continuing without a backup."
    fi

    step "Building $configuration for $(device_name "$device")"
    local derived="$BUILD_DIR/device"
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$configuration" \
        -destination "platform=iOS,id=$device" \
        -derivedDataPath "$derived" \
        -allowProvisioningUpdates \
        DEVELOPMENT_TEAM="$team" \
        build \
        | grep -E "error:|warning: .*(deprecat|unused)|BUILD" || true

    local app="$derived/Build/Products/$configuration-iphoneos/Cull.app"
    [[ -d "$app" ]] || fail "Build produced no app at $app"

    step "Installing (this is an update — the app's state stays)"
    xcrun devicectl device install app --device "$device" "$app" >/dev/null \
        || fail "Install failed. If iOS complained about the signature, the previous build was signed by a different team; that needs the app deleted, so restore from backups/ afterwards."

    if [[ $launch -eq 1 ]]; then
        step "Launching"
        xcrun devicectl device process launch --device "$device" --terminate-existing "$BUNDLE_ID" >/dev/null \
            || warn "Installed, but could not launch it from here. Tap the icon."
    fi

    ok "Cull $configuration is on $(device_name "$device")"
    note "Signed with team $team. Keep that the same or iOS will refuse the update."
}

# ---------------------------------------------------------------- misc

do_logs() {
    local device
    device="$(resolve_device)"
    step "Launching with the console attached — Ctrl-C to stop"
    xcrun devicectl device process launch \
        --device "$device" \
        --console \
        --terminate-existing \
        "$BUNDLE_ID"
}

do_files() {
    local device path="${1:-/}"
    device="$(resolve_device)"
    xcrun devicectl device info files \
        --device "$device" \
        --domain-type appDataContainer \
        --domain-identifier "$BUNDLE_ID" \
        --subdirectory "$path"
}

do_list() {
    xcrun devicectl list devices
}

# ---------------------------------------------------------------- dispatch

command="${1:-}"
[[ $# -gt 0 ]] && shift || true
case "$command" in
    install) do_install "$@" ;;
    backup)  do_backup "$@" ;;
    restore) do_restore "$@" ;;
    logs)    do_logs ;;
    files)   do_files "$@" ;;
    list)    do_list ;;
    ""|-h|--help) usage ;;
    *) warn "Unknown command: $command"; usage; exit 1 ;;
esac
