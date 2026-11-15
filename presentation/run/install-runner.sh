#!/usr/bin/env bash
# Builds "NewsDemo Runner" (~/Applications) so the slide deck's buttons can run the live-demo commands.
#   presentation/run/install-runner.sh
# Slide buttons link to newsdemo://run-tests, newsdemo://break-it, newsdemo://show-diff, newsdemo://back-to-main.
# Remove again: rm -rf ~/Applications/"NewsDemo Runner.app"
set -euo pipefail
cd "$(dirname "$0")/../.."
REPO="$(pwd)"
APP="$HOME/Applications/NewsDemo Runner.app"
SRC="$(mktemp -t runner).applescript"

mkdir -p "$HOME/Applications"
sed "s|__REPO__|$REPO|" presentation/run/runner.applescript > "$SRC"
rm -rf "$APP"
osacompile -o "$APP" "$SRC"
rm -f "$SRC"

PLIST="$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIdentifier" "$PLIST" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy \
  -c "Add :CFBundleIdentifier string app.newsdemo.runner" \
  -c "Add :CFBundleURLTypes array" \
  -c "Add :CFBundleURLTypes:0 dict" \
  -c "Add :CFBundleURLTypes:0:CFBundleURLName string NewsDemo Runner" \
  -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" \
  -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string newsdemo" \
  -c "Add :LSBackgroundOnly bool true" \
  "$PLIST"
codesign --force --sign - "$APP" >/dev/null 2>&1
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
echo "Installed: $APP"
echo "Test it:   open newsdemo://back-to-main"
