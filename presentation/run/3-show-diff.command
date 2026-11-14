#!/bin/bash
# Open the diff report in the browser and print the triage summary (only exists after a failing run).
# Linked from the slide deck: clicking the link opens this in a new Terminal window.
cd "$(dirname "$0")/../.." || exit 1
clear
if [ ! -f artifacts/ios/diffs/index.html ]; then
  printf 'No diff report yet: run 2-break-it first (it only exists after a failing run).\n'
  exit 1
fi
printf '\033[1mOpen the diff report and print the summary\033[0m\n\n'
printf '\033[2m$ open artifacts/ios/diffs/index.html\033[0m\n'
open artifacts/ios/diffs/index.html
printf '\n\033[2m$ cat artifacts/ios/diffs/summary.md\033[0m\n'
cat artifacts/ios/diffs/summary.md
