#!/usr/bin/env bash
#
# Runs the unit tests on a simulator.
#
# Usage: scripts/test.sh [--clean] [--filter Suite/test] [-- <extra xcodebuild args>]
#
# The destination is resolved at run time rather than hard-coded, because the
# installed simulator runtimes differ between a laptop and a CI runner, and a
# pinned "iPhone 17, OS 26.5" is the single most common reason a green pipeline
# turns red on someone else's machine.
#
# Cull has no test target yet; this stops with a note saying how to add one
# rather than failing somewhere inside xcodebuild.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CLEAN=0
FILTER=""
EXTRA=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean) CLEAN=1; shift ;;
        --filter) FILTER="${2:?--filter needs a test identifier}"; shift 2 ;;
        --) shift; EXTRA=("$@"); break ;;
        -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) fail "Unknown argument: $1" ;;
    esac
done

if ! has_test_target; then
    warn "No $TEST_TARGET target in Cull.xcodeproj yet."
    info "Add one in Xcode: File ▸ New ▸ Target ▸ Unit Testing Bundle, named $TEST_TARGET."
    info "Then this script runs it unchanged, as does 'make test'."
    exit 1
fi

if ! has_eligible_simulator_destination; then
    platform_download_hint
    exit 1
fi

read -r UDID SIMULATOR_NAME <<<"$(resolve_simulator)" || fail "Could not pick a simulator."
[[ -n "$UDID" ]] || fail "Could not pick a simulator."
step "Testing on simulator $SIMULATOR_NAME ($UDID)"

RESULT_BUNDLE="$BUILD_DIR/TestResults.xcresult"
rm -rf "$RESULT_BUNDLE"
mkdir -p "$BUILD_DIR"

ARGS=(
    -project "$PROJECT"
    -scheme "$SCHEME"
    -configuration Debug
    -destination "platform=iOS Simulator,id=$UDID"
    -resultBundlePath "$RESULT_BUNDLE"
    # A simulator build needs no identity, and signing it would drag the whole
    # provisioning apparatus into a run that never leaves this machine.
    CODE_SIGNING_ALLOWED=NO
)
[[ -n "$FILTER" ]] && ARGS+=(-only-testing:"$TEST_TARGET/$FILTER")
[[ ${#EXTRA[@]} -gt 0 ]] && ARGS+=("${EXTRA[@]}")

ACTIONS=()
[[ $CLEAN -eq 1 ]] && ACTIONS+=(clean)
ACTIONS+=(test)

set +e
if command -v xcbeautify >/dev/null 2>&1; then
    NSUnbufferedIO=YES xcodebuild "${ARGS[@]}" "${ACTIONS[@]}" 2>&1 | xcbeautify
    STATUS=${PIPESTATUS[0]}
else
    NSUnbufferedIO=YES xcodebuild "${ARGS[@]}" "${ACTIONS[@]}"
    STATUS=$?
fi
set -e

echo
if [[ $STATUS -eq 0 ]]; then
    ok "Tests passed"
else
    warn "Tests failed (exit $STATUS)"
    note "Full log: xcrun xcresulttool get test-report tests --path $RESULT_BUNDLE"
fi
exit $STATUS
