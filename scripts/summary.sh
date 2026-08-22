#!/usr/bin/env bash
# The action's "Job summary" step, extracted for testability.
set -euo pipefail

{
  echo "### 📲 Build ready to install"
  echo
  echo "[**Open the install page**](${INSTALL_URL})"
  echo
  echo "<img src=\"${QR_URL}&size=180\" width=\"180\" alt=\"Install QR code\">"
  echo
  echo "Scan it with the phone you want to install on."
} >> "$GITHUB_STEP_SUMMARY"
