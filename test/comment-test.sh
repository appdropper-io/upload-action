#!/usr/bin/env bash
# Covers scripts/comment.sh: the find-or-create PR comment upsert. A `gh`
# stand-in on PATH records every call instead of hitting the GitHub API.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./helpers.sh

ACTION_DIR="$(cd .. && pwd)"
COMMENT_SH="$ACTION_DIR/scripts/comment.sh"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

MOCKBIN="$WORKDIR/bin"
mkdir -p "$MOCKBIN"
# GH_EXISTING_ID (set by each test) is what the lookup call "finds"; empty
# means no comment exists yet. GH_LOG records every call this script makes.
cat > "$MOCKBIN/gh" <<'EOF'
#!/usr/bin/env bash
echo "CALL:$*" >> "$GH_LOG"
if [[ "$*" == *"--method PATCH"* ]] || [[ "$*" == *"--method POST"* ]]; then
  exit 0
fi
# The lookup call: `gh api repos/.../comments --paginate --jq '...'`
echo "${GH_EXISTING_ID:-}"
exit 0
EOF
chmod +x "$MOCKBIN/gh"
export PATH="$MOCKBIN:$PATH"

APK="$WORKDIR/app-release.apk"
touch "$APK"

reset_env() {
  unset GH_EXISTING_ID INSTALL_URL QR_URL PR_NUMBER REPO FILE GITHUB_SHA 2>/dev/null || true
}

run_comment() {
  GH_LOG="$WORKDIR/gh.log" "$COMMENT_SH"
}

echo
echo "scripts/comment.sh"
echo

reset_env
: > "$WORKDIR/gh.log"
export GH_EXISTING_ID="" INSTALL_URL="https://appdropper.io/d/checkout" \
       QR_URL="https://appdropper.io/api/v1/qr/build123" PR_NUMBER=42 \
       REPO="acme/checkout-app" FILE="$APK" GITHUB_SHA="a1b2c3d4e5f6"
run_comment
log=$(cat "$WORKDIR/gh.log")
assert_contains "looks up any existing comment first" "$log" "repos/acme/checkout-app/issues/42/comments"
assert_contains "creates a new comment when none exists yet" "$log" "--method POST"
assert_not_contains "does not PATCH when there was nothing to update" "$log" "--method PATCH"
assert_contains "the comment body links the install page" "$log" "https://appdropper.io/d/checkout"
assert_contains "the comment body names the artifact file, not its full path" "$log" "app-release.apk"
assert_contains "the comment body shows a short commit SHA" "$log" "a1b2c3d"
assert_not_contains "the commit SHA is truncated to 7 characters" "$log" "a1b2c3d4e5f6"

reset_env
: > "$WORKDIR/gh.log"
export GH_EXISTING_ID="98765" INSTALL_URL="https://appdropper.io/d/checkout" \
       QR_URL="https://appdropper.io/api/v1/qr/build123" PR_NUMBER=42 \
       REPO="acme/checkout-app" FILE="$APK" GITHUB_SHA="a1b2c3d4e5f6"
run_comment
log=$(cat "$WORKDIR/gh.log")
assert_contains "edits the existing comment in place when one is found" "$log" "--method PATCH"
assert_contains "PATCHes the specific comment id" "$log" "issues/comments/98765"
assert_not_contains "does not also create a duplicate" "$log" "--method POST"

summarize
