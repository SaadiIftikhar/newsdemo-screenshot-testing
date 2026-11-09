#!/usr/bin/env bash
# Prints the UDID of the pinned snapshot simulator, creating it if needed.
# Pinning device type + runtime is the #1 lever against "passes locally, fails on CI" snapshot flakiness.
set -euo pipefail

SIM_NAME="${IOS_SIM_NAME:-NewsDemo Snapshots}"
DEVICE_TYPE="${IOS_DEVICE_TYPE:-com.apple.CoreSimulator.SimDeviceType.iPhone-17}"
RUNTIME="${IOS_RUNTIME:-com.apple.CoreSimulator.SimRuntime.iOS-27-0}"

if ! xcrun simctl list runtimes | grep -q "$RUNTIME"; then
  echo "error: simulator runtime $RUNTIME is not installed (xcodebuild -downloadPlatform iOS -buildVersion 27.0)" >&2
  exit 1
fi

udid=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)['devices'].get('$RUNTIME', [])
print(next((d['udid'] for d in data if d['name'] == '$SIM_NAME' and d['isAvailable']), ''))
")

if [[ -z "$udid" ]]; then
  udid=$(xcrun simctl create "$SIM_NAME" "$DEVICE_TYPE" "$RUNTIME")
  echo "created simulator '$SIM_NAME' ($udid)" >&2
fi

echo "$udid"
