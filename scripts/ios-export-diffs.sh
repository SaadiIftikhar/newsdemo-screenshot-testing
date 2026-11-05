#!/usr/bin/env bash
# Extracts reference / failure / difference images of failed snapshot tests from the .xcresult
# into artifacts/ios/diffs/, so they can be uploaded by CI and reviewed in the PR.
set -uo pipefail

ARTIFACTS="${1:-artifacts/ios}"
RESULT="$ARTIFACTS/NewsKit.xcresult"
OUT="$ARTIFACTS/diffs"

[[ -d "$RESULT" ]] || exit 0
rm -rf "$OUT" && mkdir -p "$OUT"
xcrun xcresulttool export attachments --path "$RESULT" --output-path "$OUT" --only-failures >/dev/null 2>&1 || exit 0

# Rename exported files using the manifest: <TestClass>.<test>__<attachment>.png
python3 - "$OUT" <<'EOF'
import json, os, re, sys
out = sys.argv[1]
manifest = os.path.join(out, "manifest.json")
if not os.path.exists(manifest):
    sys.exit(0)
count = 0
for test in json.load(open(manifest)):
    test_id = re.sub(r"[^A-Za-z0-9_.]+", "_", test.get("testIdentifier", "test")).strip("_")
    for att in test.get("attachments", []):
        src = os.path.join(out, att["exportedFileName"])
        label = re.sub(r"[^A-Za-z0-9_.-]+", "_", att.get("suggestedHumanReadableName", "image"))
        if os.path.exists(src):
            os.rename(src, os.path.join(out, f"{test_id}__{label}"))
            count += 1
print(f"exported {count} diff attachment(s) to {out}" if count else "no snapshot failures")
EOF
