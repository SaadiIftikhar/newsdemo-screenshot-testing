#!/usr/bin/env bash
# Prepares the demo in one command. Run 15–30 minutes before presenting:
#   cd ~/Desktop/Task && presentation/setup.sh
#
# 1. checks the tools          2. starts from clean output      3. main must be green
# 4. the regression branch must fail on exactly 29 screenshots (then its diffs are removed again)
# 5. builds the golden gallery 6. starts the app in the simulator
# It opens no windows: you show files and pages yourself. Running it also warms the build, so live runs are fast.
#
# Safe to run again: it always ends on main and never changes tracked files.
set -u
cd "$(dirname "$0")/.." || exit 1
[ -z "${CAFFEINATED:-}" ] && command -v caffeinate >/dev/null && CAFFEINATED=1 exec caffeinate -i "$0" "$@"   # keep the Mac awake

B=$'\033[1m'; G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; N=$'\033[0m'
step() { printf '\n%s▶ %s%s\n' "$B" "$1" "$N"; }
ok()   { printf '  %s✓ %s%s\n' "$G" "$1" "$N"; }
warn() { printf '  %s! %s%s\n' "$Y" "$1" "$N"; }
die()  { printf '  %s✗ %s%s\n\n' "$R" "$1" "$N"; exit 1; }
back_to_main() { [ "$(git branch --show-current 2>/dev/null)" != "main" ] && git checkout -q main 2>/dev/null; true; }
trap back_to_main EXIT

SNAP=ios/NewsKit/Tests/NewsUISnapshotTests

step "1/6 Tools"
command -v xcodebuild >/dev/null || die "Xcode is not installed"
xcodebuild -version 2>/dev/null | head -1 | grep -q "Xcode 27" && ok "$(xcodebuild -version | head -1)" || die "Xcode 27 is required"
command -v xcodegen >/dev/null && ok "xcodegen" || die "xcodegen missing: brew install xcodegen"
UDID=$(scripts/ios-sim.sh 2>&1 | tail -1)
[[ "$UDID" =~ ^[0-9A-F-]{36}$ ]] && ok "pinned simulator (iPhone 17, iOS 27.0)" || die "iOS 27.0 runtime missing: xcodebuild -downloadPlatform iOS -buildVersion 27.0"
[ -z "$(git status --porcelain --untracked-files=no)" ] && ok "no uncommitted changes" || die "uncommitted changes: commit or stash them first (git status)"
git checkout -q main && ok "on main" || die "could not switch to main"
git pull -q --ff-only 2>/dev/null && ok "up to date" || warn "git pull skipped (offline?): using the local copy"

step "2/6 Clean output"
rm -rf artifacts && mkdir -p artifacts/setup-logs && ok "artifacts/ emptied (test output only, never in git)"
LOG=artifacts/setup-logs

step "3/6 main must be green (~1 min)"
make ios-test > "$LOG/main.log" 2>&1 && ok "no snapshot failures" || die "main is red: see $LOG/main.log"

step "4/6 demo/regression must fail on 29 screenshots (~1.5 min; failing is expected)"
git checkout -q demo/regression || die "could not switch to demo/regression"
make ios-test > "$LOG/regression.log" 2>&1
if grep -q '^\*\*29 changed\*\*' artifacts/ios/diffs/summary.md 2>/dev/null; then ok "$(head -1 artifacts/ios/diffs/summary.md | sed 's/\*//g')"
else warn "unexpected regression result: see $LOG/regression.log"; fi
rm -rf artifacts/ios && ok "regression diffs removed: they appear again only after your live run (live demo)"
git checkout -q main && ok "back on main"

step "5/6 Golden gallery"
make lint-goldens > "$LOG/lint.log" 2>&1 && ok "$(tail -1 "$LOG/lint.log")" || die "golden lint failed: see $LOG/lint.log"
make gallery > "$LOG/gallery.log" 2>&1 && ok "artifacts/gallery/index.html" || die "gallery failed: see $LOG/gallery.log"

step "6/6 App in the simulator"
make ios-run > "$LOG/app.log" 2>&1 && ok "NewsDemo is running (feed, logged out)" || die "the app did not launch: see $LOG/app.log"

printf '\n%s%sREADY%s on %s.\n' "$B" "$G" "$N" "$(git branch --show-current)"
printf 'Everything is ready: tests warm, regression checked, gallery built, app in the simulator.\n'
