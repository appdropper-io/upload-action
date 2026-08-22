#!/usr/bin/env bash
# Covers scripts/summary.sh: the GitHub Actions job-summary markdown.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./helpers.sh

ACTION_DIR="$(cd .. && pwd)"
SUMMARY_SH="$ACTION_DIR/scripts/summary.sh"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo
echo "scripts/summary.sh"
echo

SUMMARY_FILE="$WORKDIR/summary.md"
: > "$SUMMARY_FILE"
INSTALL_URL="https://appdropper.io/d/checkout" \
QR_URL="https://appdropper.io/api/v1/qr/build123" \
GITHUB_STEP_SUMMARY="$SUMMARY_FILE" \
  "$SUMMARY_SH"

content=$(cat "$SUMMARY_FILE")
assert_contains "links the install page" "$content" "[**Open the install page**](https://appdropper.io/d/checkout)"
assert_contains "embeds the QR code image at a fixed size" "$content" '<img src="https://appdropper.io/api/v1/qr/build123&size=180" width="180"'
assert_contains "has a heading" "$content" "Build ready to install"

# The real step summary is appended to across a workflow run — a build step
# earlier in the same job may already have written to it.
echo "### Earlier step output" > "$SUMMARY_FILE"
INSTALL_URL="https://appdropper.io/d/checkout" \
QR_URL="https://appdropper.io/api/v1/qr/build123" \
GITHUB_STEP_SUMMARY="$SUMMARY_FILE" \
  "$SUMMARY_SH"
content=$(cat "$SUMMARY_FILE")
assert_contains "appends rather than overwriting the existing summary" "$content" "Earlier step output"
assert_contains "still adds its own section after the existing content" "$content" "Build ready to install"

summarize
