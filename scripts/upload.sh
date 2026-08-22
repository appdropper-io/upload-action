#!/usr/bin/env bash
# The action's "Upload build" step, extracted to a file so it's testable in
# isolation (see test/) instead of only inline in action.yml.
set -euo pipefail

if [ -z "${APPDROPPER_TOKEN:-}" ]; then
  echo '::error::No token supplied. Set the step input "token" to your APPDROPPER_TOKEN repository secret.'
  exit 1
fi
if [ ! -f "${INPUT_FILE:-}" ]; then
  echo "::error::No such file: ${INPUT_FILE:-}"
  exit 1
fi

# An empty api-url input must not shadow the CLI's own default.
if [ -z "${APPDROPPER_API_URL:-}" ]; then unset APPDROPPER_API_URL; fi

# Default the notes to the commit that triggered the run — the single
# most useful thing to show a tester, and free to collect here.
NOTES="${INPUT_NOTES:-}"
if [ -z "${NOTES}" ]; then NOTES="${HEAD_COMMIT_MESSAGE:-}"; fi

ARGS=(upload "${INPUT_FILE}" --timeout "${INPUT_TIMEOUT}" --no-qr)
if [ -n "${NOTES}" ]; then ARGS+=(--notes "${NOTES}"); fi
if [ -n "${INPUT_TAG:-}" ]; then ARGS+=(--tag "${INPUT_TAG}"); fi

# The CLI writes install-url, build-id and qr-url to $GITHUB_OUTPUT
# itself, so there is nothing to parse out of its stdout here.
npx --yes "appdropper@${CLI_VERSION}" "${ARGS[@]}"
