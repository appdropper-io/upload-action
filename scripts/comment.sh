#!/usr/bin/env bash
# The action's "Comment on the pull request" step, extracted for testability.
# One comment per pull request, edited in place: a long-running PR shouldn't
# accumulate a comment per push, and the marker below is how the existing one
# is found again.
set -euo pipefail

BODY=$(cat <<EOF
<!-- appdropper-install-link -->
### 📲 Test build ready

| | |
|---|---|
| **Install** | [${INSTALL_URL}](${INSTALL_URL}) |
| **Artifact** | \`$(basename "${FILE}")\` |
| **Commit** | \`${GITHUB_SHA:0:7}\` |

<img src="${QR_URL}&size=200" width="200" alt="Install QR code">

Open the link on the device you want to install on, or scan the code.
EOF
)

EXISTING=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" --paginate \
  --jq 'map(select(.body | contains("<!-- appdropper-install-link -->"))) | .[0].id // empty' || true)

if [ -n "${EXISTING}" ]; then
  gh api --method PATCH "repos/${REPO}/issues/comments/${EXISTING}" -f body="${BODY}" >/dev/null
else
  gh api --method POST "repos/${REPO}/issues/${PR_NUMBER}/comments" -f body="${BODY}" >/dev/null
fi
