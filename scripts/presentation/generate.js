// Generates presentation/Demo-script.html (the talk track) and presentation/setup.sh (the one-command setup)
// from the data below, so the script and the setup can never disagree about which window or tab is where.
// Run: node scripts/presentation/generate.js
const fs = require("fs");
const path = require("path");
const OUT = path.join(__dirname, "..", "..", "presentation");
const REPO = "SaadiIftikhar/newsdemo-screenshot-testing";
const GH = `https://github.com/${REPO}`;
const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

// ---------- what setup.sh opens, in presentation order ----------
const SNAP = "ios/NewsKit/Tests/NewsUISnapshotTests";
const vscodeTabs = [
  ["fixtures/feed/feed_default.json", "the fake API response (section 2)"],
  [`${SNAP}/FeedScreenSnapshotTests.swift`, "a screenshot test (section 2)"],
  ["fixtures/feed/feed_hostile_content.json", "messy CMS content (section 6)"],
];
const browserTabs = [
  ["artifacts/gallery/index.html", "the gallery: every approved screenshot (section 2)"],
  [`${GH}/pull/1`, "PR #1: the regression, blocked (section 5)"],
  [`${GH}/pull/2/commits`, "PR #2: the redesign, re-recorded by the bot (section 5)"],
];
const tab = (list, file) => list.findIndex(([f]) => f === file) + 1;
const vs = (file) => `VS Code tab ${tab(vscodeTabs, file)} "${path.basename(file)}"`;
const br = (url) => `Browser tab ${tab(browserTabs, url)}`;

// ---------- the talk track ----------
// Each section is a list of beats: what to show (a window/tab, or a command you run live) + what to say with it.
const demo = [
  {
    title: "Opening", min: 0.5,
    beats: [
      { show: [{ where: "Terminal", what: "Project folder, on main." }],
        say: `I'm Saad. Instead of slides I'll show the project itself: a small SwiftUI news app, its screenshot tests and the CI around them. The question: how do we catch visual bugs, like a PLUS badge that silently disappears, while the news changes every minute?` },
    ],
  },
  {
    title: "1. The app", min: 1.5,
    beats: [
      { show: [{ where: "Simulator", what: "The feed. Tap the Tesla article with the PLUS badge: paywall. Close it." }],
        say: `This is the app on fake data: feed, breaking banner, live ticker, games and account. As a non-subscriber, this PLUS article shows the paywall.` },
      { show: [{ where: "Simulator", what: "Konto → Anmelden (the demo account is pre-filled) → Nachrichten → tap the Tesla article: it opens." }],
        say: `Logged in as a subscriber, it opens. That PLUS badge is exactly what a refactor could break without anyone noticing.` },
    ],
  },
  {
    title: "2. How a screenshot test works", min: 2,
    beats: [
      { show: [{ where: "VS Code", what: `Tab 1 "feed_default.json": point at "premium": true.` }],
        say: `One: a fixture, frozen fake API data. The clock, locale and time zone are pinned too, so "vor 9 Min." never changes and the pictures never go stale.` },
      { show: [{ where: "VS Code", what: `Tab 2 "FeedScreenSnapshotTests.swift": test_feed_default.` }],
        say: `Two: the test renders the real feed screen with that data, in memory, and compares it with an approved picture.` },
      { show: [{ where: "Browser", what: `${br("artifacts/gallery/index.html")}: the gallery.` }],
        say: `Three: the approved pictures, the goldens, stored in git: light, dark and the largest text size. Here are all 89.` },
    ],
  },
  {
    title: "3. Everything is green", min: 1,
    beats: [
      { show: [{ where: "Terminal", what: "Run all tests.", cmd: "make ios-test", see: "~45 s: \"no snapshot failures\"." }],
        say: `89 screenshots and 35 logic tests in under a minute: no app launch, no network. CI runs the same command on every pull request.` },
    ],
  },
  {
    title: "4. Break it on purpose", min: 3,
    beats: [
      { show: [{ where: "Terminal", what: "Switch to the branch with the bug.", cmd: "git checkout demo/regression" },
               { where: "Terminal", what: "Run the tests again.", cmd: "make ios-test", see: "~1 min, fails: \"29 failure(s)\"." }],
        say: `This branch is a harmless-looking one-file refactor. By accident it drops the PLUS badge and takes 2 points off the banner. [While it runs:] Every screen with a PLUS teaser or the banner should go red.` },
      { show: [{ where: "Browser", what: "Open the diff report.", cmd: "open artifacts/ios/diffs/index.html", see: "test_teaserCard_premium: golden | new | changed pixels in magenta." }],
        say: `29 of 89 fail; the other 60 stay green. Golden, new picture, and in magenta what changed: the badge is gone.` },
      { show: [{ where: "Terminal", what: "Always switch back.", cmd: "git checkout main" }],
        say: `Back to the correct code.` },
    ],
    fallback: "Anything goes wrong: git checkout main (button at the top) and continue with section 5.",
  },
  {
    title: "5. A human decides", min: 1.5,
    beats: [
      { show: [{ where: "Browser", what: `${br(`${GH}/pull/1`)}: PR #1, red, with the bot's table.` }],
        say: `On GitHub the same change is blocked, and the bot says what kind of change it is. A bug: fix the code, the goldens stay.` },
      { show: [{ where: "Browser", what: `${br(`${GH}/pull/2/commits`)}: PR #2, the snapshot-bot commit, then green.` }],
        say: `An intended redesign: add a label, CI re-records the goldens and pushes them, and a design or QA owner approves. Goldens never come from a laptop, and approval is never automatic.` },
    ],
  },
  {
    title: "6. Messy content", min: 1.5,
    beats: [
      { show: [{ where: "VS Code", what: `Tab 3 "feed_hostile_content.json".` }],
        say: `Real CMS content is messy: HTML entities, line breaks in headlines, emoji, an empty live ticker, an hour-long video.` },
      { show: [{ where: "Simulator", what: "Relaunch the app with that data.", cmd: "make ios-run FIXTURE=feed_hostile_content", see: "~30 s: clean headlines, \"Noch keine Einträge\", 1:02:03." }],
        say: `The app cleans it up. Each of these cases has its own golden, so a regression there is caught too.` },
    ],
  },
  {
    title: "7. Android and rollout", min: 1,
    beats: [
      { show: [{ where: "Preview", what: "STRATEGY.pdf, §9 and §10." }],
        say: `Android works the same way: same fixtures, same test names, Roborazzi on the JVM, no emulator. I built it first, and it found a bug that made a PLUS article free on Android. Rollout: one app, a few components in report-only mode, then a required gate, in about four sprints.` },
    ],
  },
  {
    title: "Close", min: 0.5,
    beats: [
      { show: [{ where: "Terminal", what: "Stay on main." }],
        say: `Frozen data makes every difference meaningful. Machines compare, a person decides. And the same fixtures carry it to Android. Questions?` },
    ],
  },
];

const qa = [
  ["Who approved the goldens?", "I did, as code owner. AI may triage; a human approves and merges."],
  ["Fails on CI, passes on my Mac?", "CI is the source of truth. Download the diff artifact from the run, and use the same pinned simulator to reproduce it."],
  ["How small a difference is allowed?", "Only invisible rendering noise (perceptual precision 0.98). Anything visible fails; tolerance is never loosened globally."],
  ["How fast at scale?", "12–19 min per PR on GitHub today; at scale, only affected modules, sharding, slow checks nightly."],
  ["Flaky tests?", "No automatic retries; quarantine within 24 hours with an owner, then fix the cause."],
  ["Why only iOS?", "The brief asks for one platform plus a strategy for both; Android is STRATEGY §10."],
];

// ---------- page ----------
const CSS = `
:root{--bg:#f6f7f9;--card:#fff;--ink:#1b1f3b;--ink2:#4a5270;--muted:#6b7389;--line:#e3e6ee;--teal:#0e8c99;--magenta:#c2185b;--green:#2e9e5b;
--code-bg:#1b1f3b;--code-ink:#e8ecf5;--chip:#eef1f6;--shadow:0 1px 2px rgba(27,31,59,.06),0 4px 16px rgba(27,31,59,.06)}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#11142a;--card:#1a1e38;--ink:#eef0f7;--ink2:#c3c8db;--muted:#9aa2bb;--line:#2c3150;
--teal:#3cc2cf;--magenta:#ff6fa3;--green:#5fd18f;--code-bg:#0b0d1d;--code-ink:#e8ecf5;--chip:#262b4a;--shadow:none}}
:root[data-theme="dark"]{--bg:#11142a;--card:#1a1e38;--ink:#eef0f7;--ink2:#c3c8db;--muted:#9aa2bb;--line:#2c3150;--teal:#3cc2cf;--magenta:#ff6fa3;
--green:#5fd18f;--code-bg:#0b0d1d;--code-ink:#e8ecf5;--chip:#262b4a;--shadow:none}
*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:72px}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
.wrap{max-width:920px;margin:0 auto;padding:0 16px 80px}
header.top{position:sticky;top:0;z-index:5;background:color-mix(in srgb,var(--bg) 88%,transparent);backdrop-filter:blur(8px);border-bottom:1px solid var(--line)}
header.top .wrap{display:flex;gap:12px;align-items:center;padding-top:10px;padding-bottom:10px;flex-wrap:wrap}
header.top .brand{font-weight:700;margin-right:auto}
h1{font-size:30px;line-height:1.2;margin:32px 0 8px}h2{font-size:22px;margin:40px 0 12px}h3{font-size:18px;margin:0}
p.lead{color:var(--ink2);margin:0 0 20px;max-width:70ch}
.card{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:20px;margin:0 0 16px;box-shadow:var(--shadow)}
.meta{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin:6px 0 12px;color:var(--muted);font-size:14px}
.badge{display:inline-block;border-radius:999px;padding:2px 10px;font-size:12px;font-weight:700;background:var(--chip);color:var(--ink2)}
.badge.run{background:var(--magenta);color:#fff}
.goal{color:var(--ink2);margin:0 0 12px}.goal b{color:var(--ink)}
blockquote{margin:0 0 16px;padding:12px 16px;border-left:3px solid var(--teal);background:var(--chip);border-radius:0 8px 8px 0;color:var(--ink)}
blockquote p{margin:0 0 8px}blockquote p:last-child{margin:0}
.label{font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);margin:16px 0 8px}
ol.steps{list-style:none;margin:0;padding:0;counter-reset:s}
ol.steps>li{counter-increment:s;position:relative;padding:0 0 14px 40px}
ol.steps>li::before{content:counter(s);position:absolute;left:0;top:0;width:26px;height:26px;border-radius:50%;background:var(--teal);color:#fff;
font-size:13px;font-weight:700;display:flex;align-items:center;justify-content:center}
.where{display:inline-block;font-size:12px;font-weight:700;color:var(--teal);background:var(--chip);border-radius:6px;padding:1px 8px;margin-right:6px}
.show+.show{margin-top:12px}
.say{margin-top:10px;padding:10px 14px;border-left:3px solid var(--teal);background:var(--chip);border-radius:0 8px 8px 0}
.say p{margin:0 0 8px}.say p:last-child{margin:0}
.saylabel{display:block;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);margin-bottom:4px}
ol.steps>li{padding-bottom:22px}
.see{color:var(--muted);font-size:14px;margin-top:6px}.see b{color:var(--ink2);font-weight:600}
.cmd{display:flex;align-items:stretch;margin-top:8px;border-radius:8px;overflow:hidden;background:var(--code-bg)}
.cmd code{flex:1;min-width:0;padding:10px 12px;color:var(--code-ink);font:14px/1.45 ui-monospace,SFMono-Regular,Menlo,monospace;white-space:pre-wrap;word-break:break-word}
.cmd code::before{content:"$ ";color:#7f88a8}
.cmd button{flex:none;border:0;border-left:1px solid #2f3557;background:#262b4a;color:#e8ecf5;font:600 13px -apple-system,sans-serif;padding:0 14px;cursor:pointer;min-width:72px}
.cmd button:hover{background:#323866}.cmd button.ok{background:var(--green);color:#0b0d1d}
.cmd button:focus-visible{outline:2px solid var(--teal);outline-offset:-2px}
.fallback{margin-top:8px;font-size:14px;color:var(--ink2);background:color-mix(in srgb,var(--magenta) 8%,var(--card));border:1px solid color-mix(in srgb,var(--magenta) 25%,var(--line));border-radius:8px;padding:8px 12px}
.bridge{margin-top:12px;font-size:14px;color:var(--ink2)}.bridge i{color:var(--ink)}
.emergency{display:flex;gap:8px;align-items:center;font-size:13px;color:var(--muted)}
.emergency .cmd{margin:0}.emergency .cmd code{padding:6px 10px;font-size:13px}.emergency .cmd button{min-width:60px}
ul.tips{margin:0;padding-left:20px}ul.tips li{margin:0 0 6px}
.check{display:flex;gap:10px;align-items:flex-start;padding:6px 0}.check input{margin-top:5px;width:18px;height:18px;accent-color:var(--teal)}
table{width:100%;border-collapse:collapse;font-size:14px}th,td{text-align:left;padding:8px;border-bottom:1px solid var(--line);vertical-align:top}th{color:var(--muted);font-weight:600}
td code{font-size:13px;word-break:break-all}
a{color:var(--teal)}
.qa dt{font-weight:700;margin-top:12px}.qa dd{margin:4px 0 0;color:var(--ink2)}
@media (max-width:600px){h1{font-size:24px}ol.steps>li{padding-left:34px}.cmd{flex-direction:column}.cmd button{min-height:36px;border-left:0;border-top:1px solid #2f3557}}
`;
const JS = `
function copyText(t){if(navigator.clipboard&&window.isSecureContext){return navigator.clipboard.writeText(t)}
return new Promise(function(res,rej){var a=document.createElement('textarea');a.value=t;a.style.position='fixed';a.style.opacity='0';document.body.appendChild(a);a.select();
try{document.execCommand('copy')?res():rej()}catch(e){rej(e)}finally{document.body.removeChild(a)}})}
document.addEventListener('click',function(e){var b=e.target.closest('.cmd button');if(!b)return;var t=b.parentElement.querySelector('code').textContent;
copyText(t).then(function(){b.textContent='Copied';b.classList.add('ok');setTimeout(function(){b.textContent='Copy';b.classList.remove('ok')},1400)},
function(){b.textContent='Select';})});
document.querySelectorAll('.check input').forEach(function(c){var k='chk:'+c.id;try{c.checked=localStorage.getItem(k)==='1'}catch(e){}
c.addEventListener('change',function(){try{localStorage.setItem(k,c.checked?'1':'0')}catch(e){}})});
`;
const cmd = (c) => `<div class="cmd"><code>${esc(c)}</code><button type="button" aria-label="Copy command">Copy</button></div>`;
const paragraphs = (t) => t.split("\n\n").map((p) => `<p>${esc(p)}</p>`).join("");
const total = Math.round(demo.reduce((t, s) => t + s.min, 0));
const runsIn = (s) => s.beats.reduce((n, b) => n + b.show.filter((x) => x.cmd).length, 0);
const runCount = demo.reduce((n, s) => n + runsIn(s), 0);

let body = `<h1>Demo script</h1>
<p class="lead">The project, live, without slides. About ${total} minutes, then questions.</p>

<div class="card"><h3>Before you start: one command</h3>
<p class="goal">In Terminal, 15–30 minutes before. It checks both branches (main green, the regression failing on 29) and opens every window in demo order. About 3 minutes.</p>
${cmd("cd ~/Desktop/Task && presentation/setup.sh")}
<div class="see"><b>You'll see at the end:</b> "READY".</div></div>

<div class="card"><h3>What setup.sh leaves open</h3><table><thead><tr><th>Window</th><th>What's in it, in order</th></tr></thead><tbody>
<tr><td><b>Terminal</b></td><td>The project folder <code>~/Desktop/Task</code>, on <code>main</code>. You type the live commands here.</td></tr>
<tr><td><b>Simulator</b></td><td>The NewsDemo app, on the feed.</td></tr>
<tr><td><b>VS Code</b></td><td><ol style="margin:0;padding-left:18px">${vscodeTabs.map(([f, d]) => `<li><code>${esc(path.basename(f))}</code>: ${esc(d)}</li>`).join("")}</ol></td></tr>
<tr><td><b>Browser</b></td><td><ol style="margin:0;padding-left:18px">${browserTabs.map(([u, d]) => `<li>${esc(d)}</li>`).join("")}</ol></td></tr>
<tr><td><b>Preview</b></td><td><code>STRATEGY.pdf</code> (section 7).</td></tr></tbody></table></div>

<div class="card"><h3>How to run it</h3><ul class="tips">
<li>Each step: show it (click the tab, or Copy the command → Terminal → Cmd+V → Enter), then say the line under it.</li>
<li>Section 4 is the heart of the demo; never skip it. If anything breaks: <code>git checkout main</code> (button at the top) and move on.</li></ul></div>

<div class="card"><h3>Running order</h3><table><thead><tr><th>Section</th><th>Min</th><th>Live commands</th></tr></thead><tbody>
${demo.map((s, i) => `<tr><td><a href="#d${i}">${esc(s.title)}</a></td><td>${s.min}</td><td>${runsIn(s) || "–"}</td></tr>`).join("")}</tbody></table></div>`;

demo.forEach((s, i) => {
  const runs = runsIn(s);
  body += `<section class="card" id="d${i}"><h3>${esc(s.title)}</h3>
<div class="meta"><span class="badge">about ${s.min} min</span>${runs ? `<span class="badge run">${runs} live command${runs > 1 ? "s" : ""}</span>` : ""}</div>
<ol class="steps">${s.beats.map((b) => `<li>${b.show.map((st) => `<div class="show"><span class="where">${esc(st.where)}</span>${esc(st.what)}${st.cmd ? cmd(st.cmd) : ""}${st.see ? `<div class="see"><b>You'll see:</b> ${esc(st.see)}</div>` : ""}</div>`).join("")}
<div class="say"><span class="saylabel">Say</span>${paragraphs(b.say)}</div></li>`).join("")}</ol>
${s.fallback ? `<div class="fallback"><b>If it fails:</b> ${esc(s.fallback)}</div>` : ""}
${s.next ? `<p class="bridge">Bridge to the next section: <i>"${esc(s.next)}"</i></p>` : ""}</section>`;
});
body += `<h2>If they ask</h2><div class="card"><dl class="qa">${qa.map(([q, a]) => `<dt>"${esc(q)}"</dt><dd>${esc(a)}</dd>`).join("")}</dl>
</div>`;

const html = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Demo script</title><style>${CSS}</style></head><body>
<header class="top"><div class="wrap"><span class="brand">Demo script · screenshot testing</span>
<div class="emergency"><span>Lost? Back to the correct code:</span>${cmd("git checkout main")}</div></div></header>
<main class="wrap">${body}</main><script>${JS}</script></body></html>`;
fs.writeFileSync(path.join(OUT, "Demo-script.html"), html);

// ---------- setup.sh ----------
const q = (s) => `"${s.replace(/(["\\$`])/g, "\\$1")}"`;
const sh = `#!/usr/bin/env bash
# One-command setup for the demo (see presentation/Demo-script.html). Generated by scripts/presentation/generate.js.
#   presentation/setup.sh
# 1. checks the tools   2. main green   3. the regression fails as expected   4. lint + gallery
# 5. the app in the simulator   6. opens every window in the order the demo uses them
# Safe to run again: it always ends on main and never changes tracked files.
set -u
cd "$(dirname "$0")/.." || exit 1
[ -z "\${CAFFEINATED:-}" ] && command -v caffeinate >/dev/null && CAFFEINATED=1 exec caffeinate -i "$0" "$@"   # keep the Mac awake

B=$'\\033[1m'; G=$'\\033[32m'; R=$'\\033[31m'; Y=$'\\033[33m'; N=$'\\033[0m'
rm -rf artifacts   # start clean: no leftovers from earlier runs (artifacts/ is test output, never in git)
LOG=artifacts/setup-logs; mkdir -p "$LOG"
step() { printf '\\n%s▶ %s%s\\n' "$B" "$1" "$N"; }
ok()   { printf '  %s✓ %s%s\\n' "$G" "$1" "$N"; }
warn() { printf '  %s! %s%s\\n' "$Y" "$1" "$N"; }
die()  { printf '  %s✗ %s%s\\n\\n' "$R" "$1" "$N"; exit 1; }
back_to_main() { [ "$(git branch --show-current 2>/dev/null)" != "main" ] && git checkout -q main 2>/dev/null; true; }
trap back_to_main EXIT

VSCODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

step "1/6 Checking the tools"
command -v xcodebuild >/dev/null || die "Xcode is not installed"
xcodebuild -version 2>/dev/null | head -1 | grep -q "Xcode 27" && ok "$(xcodebuild -version | head -1)" || die "Xcode 27 is required (found: $(xcodebuild -version 2>/dev/null | head -1))"
command -v xcodegen >/dev/null && ok "xcodegen $(xcodegen --version 2>/dev/null | awk '{print $2}')" || die "xcodegen missing: brew install xcodegen"
UDID=$(scripts/ios-sim.sh 2>&1 | tail -1); [[ "$UDID" =~ ^[0-9A-F-]{36}$ ]] && ok "pinned simulator ready (iOS 27.0, iPhone 17)" || die "simulator runtime missing: xcodebuild -downloadPlatform iOS -buildVersion 27.0"
[ -x "$VSCODE" ] && ok "VS Code" || die "Visual Studio Code not found in /Applications"
[ -z "$(git status --porcelain --untracked-files=no)" ] && ok "no uncommitted changes" || die "uncommitted changes in tracked files: commit or stash them first (git status)"
git checkout -q main && ok "on main" || die "could not switch to main"
git pull -q --ff-only 2>/dev/null && ok "up to date with GitHub" || warn "git pull skipped (offline?): using the local copy"

step "2/6 main: all screenshot and logic tests must pass (1–2 min)"
if make ios-test > "$LOG/main-ios-test.log" 2>&1; then ok "main is green: no snapshot failures"; else die "main is red: see $LOG/main-ios-test.log"; fi

step "3/6 demo/regression: must fail on exactly 29 screenshots (~1.5 min, the failure is expected)"
git checkout -q demo/regression || die "could not switch to demo/regression"
make ios-test > "$LOG/regression-ios-test.log" 2>&1
if grep -q "^\\*\\*29 changed\\*\\*" artifacts/ios/diffs/summary.md 2>/dev/null; then ok "regression behaves: $(head -1 artifacts/ios/diffs/summary.md | sed 's/\\*//g')"; else warn "unexpected regression result: see $LOG/regression-ios-test.log"; fi
rm -rf artifacts/ios && ok "regression diffs removed: artifacts/ios/diffs appears only after your live failing run (section 4)"
git checkout -q main && ok "back on main"

step "4/6 Golden lint and gallery"
make lint-goldens > "$LOG/lint.log" 2>&1 && ok "$(tail -1 "$LOG/lint.log")" || die "golden lint failed: see $LOG/lint.log"
make gallery > "$LOG/gallery.log" 2>&1 && ok "gallery: artifacts/gallery/index.html" || die "gallery failed: see $LOG/gallery.log"

step "5/6 The app in the simulator (first time ~1.5 min)"
make ios-run > "$LOG/ios-run.log" 2>&1 && ok "NewsDemo is running in the simulator" || die "the app did not launch: see $LOG/ios-run.log"

step "6/6 Opening the windows, in the order the demo uses them"
"$VSCODE" . >/dev/null 2>&1; sleep 3   # reuses the project window if it is already open (no duplicates on re-runs)
"$VSCODE" --reuse-window ${vscodeTabs.map(([f]) => q(f)).join(" ")} >/dev/null 2>&1
ok "VS Code tabs: ${vscodeTabs.map(([f], i) => `${i + 1} ${path.basename(f)}`).join(", ")}"
${browserTabs.map(([u]) => `open ${q(u)}; sleep 1`).join("\n")}
ok "Browser tabs: 1 gallery, 2 PR #1, 3 PR #2 commits"
open STRATEGY.pdf && ok "Preview: STRATEGY.pdf"
open presentation/Demo-script.html && ok "This script: presentation/Demo-script.html (move it to your second device)"

printf '\\n%s%sREADY.%s Branch: %s. Logs: %s/\\n' "$B" "$G" "$N" "$(git branch --show-current)" "$LOG"
printf 'Tip: if VS Code already had other tabs open, close them (Cmd+K W) and re-run, so the tab numbers match the script.\\n'
printf 'Now: bring Terminal to the front, enlarge the font (Cmd +), turn on Do Not Disturb, and start with the Opening.\\n'
`;
fs.writeFileSync(path.join(OUT, "setup.sh"), sh, { mode: 0o755 });
console.log(`wrote presentation/Demo-script.html (${demo.length} sections, ${runCount} live commands) and presentation/setup.sh`);
