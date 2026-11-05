#!/usr/bin/env bash
# Launch the iOS demo app on the pinned simulator in a chosen state.
#   scripts/ios-run.sh [fixture]        e.g. feed_default | feed_long_headlines | feed_empty
#   OFFLINE=1 scripts/ios-run.sh        offline state
#   TAB=games|account, SIGNED_IN=1      start on another tab / logged in as the demo user
# Xcode 27+ ships the simulator UI inside DeviceHub.app; older Xcode uses Simulator.app.
set -euo pipefail
cd "$(dirname "$0")/.."

FIXTURE="${1:-feed_default}"
BUNDLE_ID="com.example.newsdemo"
UDID=$(scripts/ios-sim.sh)

APP=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 6 \
  -path "*NewsDemo-*/Build/Products/Debug-iphonesimulator/NewsDemo.app" 2>/dev/null | head -1)
if [[ -z "$APP" ]]; then
  echo "App not built yet; building (make ios-app)…"
  make ios-app
  APP=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 6 \
    -path "*NewsDemo-*/Build/Products/Debug-iphonesimulator/NewsDemo.app" | head -1)
fi

xcrun simctl boot "$UDID" 2>/dev/null || true          # already booted is fine
xcrun simctl bootstatus "$UDID" -b >/dev/null
open -a DeviceHub 2>/dev/null || open -a Simulator 2>/dev/null || true   # show the device window

xcrun simctl install "$UDID" "$APP"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
args=()
if [[ -n "${OFFLINE:-}" ]]; then args+=(-offline); else args+=(-fixture "$FIXTURE"); fi
[[ -n "${TAB:-}" ]] && args+=(-tab "$TAB")
[[ -n "${SIGNED_IN:-}" ]] && args+=(-signedIn)
xcrun simctl launch "$UDID" "$BUNDLE_ID" "${args[@]}" >/dev/null
echo "Launched NewsDemo (${args[*]}) on simulator $UDID"
