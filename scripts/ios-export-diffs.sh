#!/usr/bin/env bash
# After an iOS snapshot run: turn failed snapshots into a reviewable diff report
# (artifacts/ios/diffs/index.html with reference | actual | changed-pixels composites).
set -uo pipefail

ARTIFACTS="${1:-artifacts/ios}"
FAILURES="$ARTIFACTS/failures"
GOLDENS="ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__"
OUT="$ARTIFACTS/diffs"

rm -rf "$OUT"
if [[ ! -d "$FAILURES" ]] || [[ -z "$(find "$FAILURES" -name '*.png' -print -quit)" ]]; then
  echo "no snapshot failures"
  exit 0
fi
swift "$(dirname "$0")/diff-report.swift" "$GOLDENS" "$FAILURES" "$OUT"
