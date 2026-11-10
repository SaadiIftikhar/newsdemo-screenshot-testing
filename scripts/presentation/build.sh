#!/usr/bin/env bash
# Rebuilds presentation/Presentation.pptx, the three presentation pages and prepare.sh.
# Edit content.js (notes, commands) or build.js (slide layout), then run: scripts/presentation/build.sh
set -euo pipefail
cd "$(dirname "$0")"
SKILL="${PPTX_SKILL:-$HOME/.claude/skills/synced/c69cde16-63a9-4ecd-8c56-e23972afbf61_9f55ebd2-3747-4f93-9652-9214306ca1bd/pptx}"
[ -d node_modules/pptxgenjs ] || npm install pptxgenjs@3.12.0 --silent
NODE_PATH="$PWD/node_modules" APPLY_THEME="$SKILL/scripts/apply_theme.js" node build.js ../../presentation/Presentation.pptx
if [ -x .venv/bin/python ]; then .venv/bin/python "$SKILL/scripts/office/validate.py" ../../presentation/Presentation.pptx | tail -1; fi
node pages.js
