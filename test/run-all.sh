#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

failed=0
for suite in upload-test.sh summary-test.sh comment-test.sh; do
  bash "$suite" || failed=1
done

exit $failed
