#!/usr/bin/env bash
# Covers scripts/upload.sh: the guard clauses, the notes/tag defaulting, and
# exactly what gets passed to `npx appdropper upload`. No test existed for
# this action at all before this file — it previously shipped as inline YAML
# bash with no coverage.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./helpers.sh

ACTION_DIR="$(cd .. && pwd)"
UPLOAD_SH="$ACTION_DIR/scripts/upload.sh"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# A fake `npx` on PATH that records how it was invoked instead of hitting the
# real registry. Writes one line per argv entry plus the env vars the wrapper
# cares about, so a test can assert on exactly what the CLI would have seen.
MOCKBIN="$WORKDIR/bin"
mkdir -p "$MOCKBIN"
cat > "$MOCKBIN/npx" <<'EOF'
#!/usr/bin/env bash
{
  echo "ARGS:$#"
  for a in "$@"; do echo "ARG:$a"; done
  echo "API_URL:${APPDROPPER_API_URL-<unset>}"
} > "$NPX_LOG"
exit 0
EOF
chmod +x "$MOCKBIN/npx"
export PATH="$MOCKBIN:$PATH"
export NPX_LOG="$WORKDIR/npx.log"

APK="$WORKDIR/app.apk"
touch "$APK"

# Every env var the wrapper reads, so each test block starts from a clean
# slate rather than leaking state from the one before it (these run in the
# same shell, not a subshell per block, so PASS/FAIL in helpers.sh actually
# accumulate).
reset_env() {
  unset APPDROPPER_TOKEN INPUT_FILE INPUT_NOTES INPUT_TAG INPUT_TIMEOUT \
        CLI_VERSION HEAD_COMMIT_MESSAGE APPDROPPER_API_URL 2>/dev/null || true
}

run_upload() {
  "$UPLOAD_SH"
}

echo
echo "scripts/upload.sh"
echo

# ------------------------------------------------------------------- guards

reset_env
export INPUT_FILE="$APK" INPUT_TIMEOUT=600 CLI_VERSION=1
out=$(run_upload 2>&1); code=$?
assert_eq "missing token exits 1" "1" "$code"
assert_contains "missing token names the fix" "$out" "No token supplied"

reset_env
export APPDROPPER_TOKEN=adp_x INPUT_FILE="$WORKDIR/ghost.apk" INPUT_TIMEOUT=600 CLI_VERSION=1
out=$(run_upload 2>&1); code=$?
assert_eq "missing file exits 1" "1" "$code"
assert_contains "missing file names the path" "$out" "No such file: $WORKDIR/ghost.apk"

# --------------------------------------------------------------- arg building

reset_env
export APPDROPPER_TOKEN=adp_x INPUT_FILE="$APK" INPUT_TIMEOUT=600 CLI_VERSION=1
run_upload >/dev/null 2>&1
log=$(cat "$WORKDIR/npx.log")
assert_contains "invokes appdropper at the pinned CLI version" "$log" "ARG:appdropper@1"
assert_contains "passes the upload subcommand and file" "$log" "ARG:upload"
assert_contains "always passes --no-qr (the action renders its own summary)" "$log" "ARG:--no-qr"
assert_not_contains "no --notes flag when nothing to say" "$log" "ARG:--notes"
assert_not_contains "no --tag flag when none was given" "$log" "ARG:--tag"

reset_env
export APPDROPPER_TOKEN=adp_x INPUT_FILE="$APK" INPUT_TIMEOUT=600 CLI_VERSION=1
export HEAD_COMMIT_MESSAGE="Fix the login crash"
run_upload >/dev/null 2>&1
log=$(cat "$WORKDIR/npx.log")
assert_contains "notes default to the triggering commit message" "$log" "ARG:Fix the login crash"

reset_env
export APPDROPPER_TOKEN=adp_x INPUT_FILE="$APK" INPUT_TIMEOUT=600 CLI_VERSION=1
export HEAD_COMMIT_MESSAGE="Fix the login crash" INPUT_NOTES="Custom notes for this build"
run_upload >/dev/null 2>&1
log=$(cat "$WORKDIR/npx.log")
assert_contains "an explicit release-notes input wins over the commit message" "$log" "ARG:Custom notes for this build"
assert_not_contains "the commit message is dropped once notes are explicit" "$log" "ARG:Fix the login crash"

reset_env
export APPDROPPER_TOKEN=adp_x INPUT_FILE="$APK" INPUT_TIMEOUT=600 CLI_VERSION=1 INPUT_TAG=nightly
run_upload >/dev/null 2>&1
log=$(cat "$WORKDIR/npx.log")
assert_contains "--tag is passed through when set" "$log" "ARG:nightly"

reset_env
export APPDROPPER_TOKEN=adp_x INPUT_FILE="$APK" INPUT_TIMEOUT=45 CLI_VERSION=2.3.1
run_upload >/dev/null 2>&1
log=$(cat "$WORKDIR/npx.log")
assert_contains "the cli-version input pins the npx package version" "$log" "ARG:appdropper@2.3.1"
assert_contains "the timeout input is forwarded" "$log" "ARG:45"

reset_env
export APPDROPPER_TOKEN=adp_x INPUT_FILE="$APK" INPUT_TIMEOUT=600 CLI_VERSION=1
export APPDROPPER_API_URL=""
run_upload >/dev/null 2>&1
log=$(cat "$WORKDIR/npx.log")
assert_contains "an empty api-url input doesn't shadow the CLI's own default" "$log" "API_URL:<unset>"

reset_env
export APPDROPPER_TOKEN=adp_x INPUT_FILE="$APK" INPUT_TIMEOUT=600 CLI_VERSION=1
export APPDROPPER_API_URL="https://staging.appdropper.io/api/v1"
run_upload >/dev/null 2>&1
log=$(cat "$WORKDIR/npx.log")
assert_contains "a real api-url override is forwarded to the CLI" "$log" "API_URL:https://staging.appdropper.io/api/v1"

summarize
