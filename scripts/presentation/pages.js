// Generates the three presentation pages (with copy buttons) and scripts/presentation/prepare.sh
// from content.js, so the deck notes, the pages and the prep script can never disagree.
const fs = require("fs");
const path = require("path");
const { slides, prep, GH, PR_REGRESSION, PR_REDESIGN, VSC } = require("./content.js");
const OUT = path.join(__dirname, "..", "..", "presentation");
const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
const total = Math.round(slides.reduce((t, s) => t + s.min, 0));

// ---------- shared page shell ----------
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
.badge{display:inline-block;border-radius:999px;padding:2px 10px;font-size:12px;font-weight:700;letter-spacing:.02em}
.badge.live{background:var(--magenta);color:#fff}.badge.time{background:var(--chip);color:var(--ink2)}
.goal{color:var(--ink2);margin:0 0 12px}.goal b{color:var(--ink)}
blockquote{margin:0 0 16px;padding:12px 16px;border-left:3px solid var(--teal);background:var(--chip);border-radius:0 8px 8px 0;color:var(--ink)}
blockquote p{margin:0 0 8px}blockquote p:last-child{margin:0}
.label{font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);margin:16px 0 8px}
ol.steps{list-style:none;margin:0;padding:0;counter-reset:s}
ol.steps>li{counter-increment:s;position:relative;padding:0 0 14px 40px}
ol.steps>li::before{content:counter(s);position:absolute;left:0;top:0;width:26px;height:26px;border-radius:50%;background:var(--teal);color:#fff;
font-size:13px;font-weight:700;display:flex;align-items:center;justify-content:center}
.where{display:inline-block;font-size:12px;font-weight:700;color:var(--teal);background:var(--chip);border-radius:6px;padding:1px 8px;margin-right:6px}
.see{color:var(--muted);font-size:14px;margin-top:6px}.see b{color:var(--ink2);font-weight:600}
.cmd{display:flex;align-items:stretch;margin-top:8px;border-radius:8px;overflow:hidden;background:var(--code-bg)}
.cmd code{flex:1;min-width:0;padding:10px 12px;color:var(--code-ink);font:14px/1.45 ui-monospace,SFMono-Regular,Menlo,monospace;white-space:pre-wrap;word-break:break-word}
.cmd code::before{content:"$ ";color:#7f88a8}
.cmd button{flex:none;border:0;border-left:1px solid #2f3557;background:#262b4a;color:#e8ecf5;font:600 13px -apple-system,sans-serif;padding:0 14px;cursor:pointer;min-width:72px}
.cmd button:hover{background:#323866}.cmd button.ok{background:var(--green);color:#0b0d1d}
.cmd button:focus-visible{outline:2px solid var(--teal);outline-offset:-2px}
.fallback{margin-top:8px;font-size:14px;color:var(--ink2);background:color-mix(in srgb,var(--magenta) 8%,var(--card));border:1px solid color-mix(in srgb,var(--magenta) 25%,var(--line));border-radius:8px;padding:8px 12px}
.bridge{margin-top:12px;font-size:14px;color:var(--ink2)}.bridge i{color:var(--ink)}
nav.slides{display:flex;flex-wrap:wrap;gap:6px;margin:0 0 20px}
nav.slides a{display:inline-block;padding:4px 10px;border-radius:999px;background:var(--card);border:1px solid var(--line);color:var(--ink);text-decoration:none;font-size:13px}
nav.slides a.live{border-color:var(--magenta)}
.emergency{display:flex;gap:8px;align-items:center;font-size:13px;color:var(--muted)}
.emergency .cmd{margin:0}.emergency .cmd code{padding:6px 10px;font-size:13px}.emergency .cmd button{min-width:60px}
ul.tips{margin:0;padding-left:20px}ul.tips li{margin:0 0 6px}
.check{display:flex;gap:10px;align-items:flex-start;padding:6px 0}.check input{margin-top:5px;width:18px;height:18px;accent-color:var(--teal)}
table{width:100%;border-collapse:collapse;font-size:14px}th,td{text-align:left;padding:8px;border-bottom:1px solid var(--line);vertical-align:top}th{color:var(--muted);font-weight:600}
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
document.querySelectorAll('.check input').forEach(function(c){var k='chk:'+location.pathname+':'+c.id;try{c.checked=localStorage.getItem(k)==='1'}catch(e){}
c.addEventListener('change',function(){try{localStorage.setItem(k,c.checked?'1':'0')}catch(e){}})});
`;
const cmd = (c) => `<div class="cmd"><code>${esc(c)}</code><button type="button" aria-label="Copy command">Copy</button></div>`;
const page = (title, brand, body, extraHeader = "") => `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(title)}</title><style>${CSS}</style></head><body>
<header class="top"><div class="wrap"><span class="brand">${esc(brand)}</span>${extraHeader}</div></header>
<main class="wrap">${body}</main><script>${JS}</script></body></html>`;
const emergency = `<div class="emergency"><span>Lost? Back to the correct code:</span>${cmd("git checkout main")}</div>`;
const paragraphs = (t) => t.split("\n\n").map((p) => `<p>${esc(p)}</p>`).join("");
function stepsHtml(steps) {
  return `<ol class="steps">${steps.map(([where, what, c, see]) => `<li><span class="where">${esc(where)}</span>${esc(what)}${c ? cmd(c) : ""}${see ? `<div class="see"><b>You'll see:</b> ${esc(see)}</div>` : ""}</li>`).join("")}</ol>`;
}

// ---------- 1. Before the presentation ----------
{
  let body = `<h1>Before the presentation</h1>
<p class="lead">Run this 15–30 minutes before you present. It warms the build, warms the regression demo, builds the gallery, opens the simulator, VS Code, the GitHub tabs and the slides. Every command runs in <b>Terminal</b>, from the project folder.</p>
<div class="card"><h3>The quick way: one command</h3><p class="goal">Runs every step below in order, explains each one as it runs, and ends on <code>main</code>. About 5–8 minutes.</p>
${cmd("cd ~/Desktop/Task && scripts/presentation/prepare.sh")}
<div class="see"><b>You'll see at the end:</b> "All steps passed. You're ready." (The regression step prints a failure on purpose: that's the bug the demo catches.)</div></div>
<h2>Or step by step</h2>`;
  prep.forEach((p, i) => {
    body += `<div class="card"><h3>${i + 1}. ${esc(p.title)}</h3>${p.cmds.map(([c, d]) => `<p class="goal" style="margin:14px 0 0">${esc(d)}</p>${cmd(c)}`).join("")}</div>`;
  });
  const checks = [
    "Terminal open in ~/Desktop/Task, font enlarged (Cmd +), on branch main",
    "The simulator is open with the NewsDemo app",
    "VS Code is open on the project",
    "Browser: the regression PR, the redesign PR and the Actions tab, loaded",
    "PowerPoint open (Presenter View if you have two screens)",
    "This page and \"2 · Presenting with slides\" open in the browser, for copying commands",
    "Do Not Disturb on; Slack and mail closed",
  ];
  body += `<h2>Checklist</h2><div class="card">${checks.map((c, i) => `<label class="check"><input type="checkbox" id="c${i}"><span>${esc(c)}</span></label>`).join("")}</div>
<h2>Rules for the live parts</h2><div class="card"><ul class="tips">
<li>Say what you're about to show <i>before</i> you run the command.</li>
<li>The red test on slide 6 is the point: say "this is supposed to fail" before you run it.</li>
<li>Never run <code>make ios-record</code> live: it rewrites the goldens.</li>
<li>Always end the demo with <code>git checkout main</code>.</li>
<li>If something breaks, don't debug it in front of them: use the fallback written under that slide.</li></ul></div>`;
  fs.writeFileSync(path.join(OUT, "1-Before-the-presentation.html"), page("Before the presentation", "1 · Before the presentation", body));
}

// ---------- 2. Presenting with slides ----------
{
  let body = `<h1>Presenting with slides</h1>
<p class="lead">The full talk, slide by slide: what to say, what to open or run, and what to do if a live step fails. The same text is in the PowerPoint speaker notes. About ${total} minutes, then questions.</p>
<div class="card"><h3>How to present it</h3><ul class="tips">
<li><b>Rhythm for every LIVE slide:</b> tell (what to look for) → show (one command, point at one thing) → tell again (what it proved), then back to the slides with Cmd+Tab.</li>
<li><b>Screens:</b> with two screens, use Presenter View. With one laptop on a call, share the whole screen and keep this page on a second device or printed.</li>
<li><b>Copying commands:</b> press <b>Copy</b>, Cmd+Tab to Terminal, Cmd+V, Enter. Read the command out loud as you run it.</li>
<li><b>Short on time:</b> skip the steps marked "(Optional)" and slide 8's code. Never skip slide 6.</li></ul></div>
<nav class="slides" aria-label="Slides">${slides.map((s) => `<a href="#s${s.n}" class="${s.live ? "live" : ""}">${s.n}${s.live ? " · LIVE" : ""}</a>`).join("")}</nav>`;
  for (const s of slides) {
    body += `<section class="card" id="s${s.n}"><h3>Slide ${s.n} · ${esc(s.title)}</h3>
<div class="meta"><span class="badge time">about ${s.min} min</span>${s.live ? `<span class="badge live">LIVE · ${esc(s.live)}</span>` : ""}</div>
<p class="goal"><b>Goal:</b> ${esc(s.goal)}</p><div class="label">Say</div><blockquote>${paragraphs(s.say)}</blockquote>
${s.do.length ? `<div class="label">Do</div>${stepsHtml(s.do)}<div class="see">Then Cmd+Tab back to the slideshow.</div>` : `<div class="label">Do</div><p class="see" style="margin:0">Stay on the slide.</p>`}
${s.fallback ? `<div class="fallback"><b>If it fails:</b> ${esc(s.fallback)}</div>` : ""}
${s.next ? `<p class="bridge">Bridge to the next slide: <i>"${esc(s.next)}"</i></p>` : ""}</section>`;
  }
  const qa = [
    ["Who approved these goldens?", "I did, as the code owner. The AI did a first pass and caught real bugs, but approving goldens and merging pull requests were never delegated. That's the process I propose: AI may triage, a human approves."],
    ["A test fails on CI but passes on my Mac. How do I debug it?", "CI is the source of truth and records the goldens. Download the ios-snapshot-diffs artifact from the run; the PR comment already says what kind of change it is. Then check the pinned simulator runtime: the same runtime on the Mac reproduces CI exactly."],
    ["You replaced the native tab bar because the tool couldn't capture it. Would you change product UI for a test tool?", "No, that was a demo shortcut. In production: keep the system tab bar, snapshot the tab content, and cover system chrome in the nightly device layer."],
    ["BILD has years of UIKit and a singleton API client. What do you ship in the first two weeks?", "Snapshots of design-system components that take plain models, a URLProtocol stub serving the fixtures as a stopgap, one client seam at one feature boundary, and CI in report-only mode."],
    ["Show me a regression that passes your tolerance.", "A colour change below about ΔE 2, like a slight brand-colour tweak. That's why colour tokens have their own contrast tests, and design reviews token changes."],
    ["News changes every minute. How do goldens stay valid?", "They belong to frozen fixtures, not live content. The shape of real data is tested separately: contract tests, the fuzz test, hostile-content fixtures; fixtures are refreshed from real responses in their own PR."],
    ["How fast and how expensive at scale?", "A full iOS run on GitHub is 12–19 minutes including UI tests. At scale: only affected modules, sharding, iOS only when iOS code changes, the slowest checks nightly. Target: under 10 minutes per PR."],
    ["What about flaky tests?", "No automatic retries, because they hide flakiness. Quarantine within 24 hours with an owner. CI found one real flake, a UI test racing an animation, and I fixed the cause."],
    ["Why only iOS? What about Android?", "I built both first; the Android version used Roborazzi on Robolectric with the same fixtures and test names, and found real cross-platform bugs. I cut it to keep the demo focused; STRATEGY §10 and the Android slide describe it."],
    ["How did you use AI?", "As a pair programmer: research, code, docs, running the tests. I made the scope and product decisions and approved the results; PROMPTS.md lists every prompt and decision."],
  ];
  body += `<h2 id="qa">Likely questions</h2><div class="card"><dl class="qa">${qa.map(([q, a]) => `<dt>"${esc(q)}"</dt><dd>${esc(a)}</dd>`).join("")}</dl>
<p class="see" style="margin-top:16px">Can't answer one? "Good question; I haven't measured that. Here's how I'd find out: …", then name the test or experiment.</p></div>`;
  fs.writeFileSync(path.join(OUT, "2-Presenting-with-slides.html"), page("Presenting with slides", "2 · Presenting with slides", body, emergency));
}

// ---------- 3. Demo without slides ----------
const flow = [
  ["1. What's in the repo", [
    ["One repo, one small news app in SwiftUI, and one folder of fake data that every test uses.", ["VS Code", "Open the project.", `${VSC} .`, "fixtures/, ios/, scripts/, docs/, Makefile."]],
    ["Every action is one make command; here they all are.", ["Terminal", "List the commands.", "make help", "ios-test, ios-ui-test, lint-goldens, gallery, ios-record, ios-run…"]],
  ]],
  ["2. The app itself", [
    ["The app runs on fake data: a feed, games and an account. Tap the PLUS article (the Tesla one): without a subscription you get the paywall. Log in as demo@newsdemo.app / demo1234 and it opens.", ["Simulator", "Open the app.", "make ios-run", "The NewsDemo feed in the simulator."]],
  ]],
  ["3. How one screenshot test works", [
    ["This is the fake API response the tests read. tsr-002 has premium: true: that's the PLUS article.", ["VS Code", "Open the fixture.", `${VSC} fixtures/feed/feed_default.json`, "The feed JSON."]],
    ["A screenshot test: one line renders the real feed with that data and compares it with the approved picture.", ["VS Code", "Open the test.", `${VSC} ios/NewsKit/Tests/NewsUISnapshotTests/FeedScreenSnapshotTests.swift`, "func test_feed_default."]],
    ["These are the goldens: one approved PNG per test and variant.", ["Finder", "Open the goldens folder.", "open ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__/FeedScreenSnapshotTests", "test_feed_default.light.png, .dark.png, .light_xxxl.png…"]],
    ["And all 89 on one page.", ["Browser", "Open the gallery.", "make gallery && open artifacts/gallery/index.html", "Every golden, grouped by test."]],
  ]],
  ["4. Everything is green", [
    ["The whole suite: 89 screenshots and 35 logic tests.", ["Terminal", "Run the tests.", "make ios-test", "~40–60 s: \"no snapshot failures\"."]],
  ]],
  ["5. Break it on purpose", [
    ["This branch is a plausible refactor: one file. It drops the PLUS badge and tightens the banner by 2 points.", ["Terminal", "Show the change.", "git diff main demo/regression --stat", "1 file changed."]],
    ["Switching to the branch with the bug.", ["Terminal", "Check out the branch.", "git checkout demo/regression", "Switched to branch 'demo/regression'."]],
    ["This should fail. Watch how many screenshots catch it.", ["Terminal", "Run the tests.", "make ios-test", "~1 min, fails: 29 failures."]],
    ["Approved picture, new picture, changed pixels in magenta. Scroll to teaserCard_premium: the badge is gone.", ["Browser", "Open the diff page.", "open artifacts/ios/diffs/index.html", "golden | new | magenta diff."]],
    ["The triage table the CI bot posts on the pull request.", ["Terminal", "Show the summary.", "cat artifacts/ios/diffs/summary.md", "29 changed: 10 layout, 19 visible, 0 subtle."]],
    ["Back to the correct code. Always.", ["Terminal", "Switch back.", "git checkout main", "Switched to branch 'main'."]],
  ]],
  ["6. What happens next: a human decides", [
    ["A bug, like here: fix the code, the goldens stay. This pull request is blocked.", ["Browser", "The regression PR.", `open ${PR_REGRESSION}`, "Red check and the bot's triage table."]],
    ["An intended change: CI re-records the goldens and a code owner approves them. This PR did exactly that.", ["Browser", "The redesign PR's commits.", `open ${PR_REDESIGN}/commits`, "A \"snapshot-bot\" commit: \"re-record iOS goldens\"."]],
  ]],
  ["7. Content that changes every minute", [
    ["News content is messy: HTML entities, line breaks, emoji, a ticker with no entries, a one-hour video.", ["VS Code", "Open the messy fixture.", `${VSC} fixtures/feed/feed_hostile_content.json`, "&amp;, line breaks, durationSeconds 3723."]],
    ["The app cleans it: readable headlines, \"Noch keine Einträge\", 1:02:03.", ["Simulator", "Open the app with that fixture.", "make ios-run FIXTURE=feed_hostile_content", "Clean headlines in the simulator."]],
    ["Offline: the first load works, then the connection drops. Pull the feed down: the articles stay, with the time they were loaded.", ["Simulator", "Open the app in drop-connection mode.", "make ios-run DROP_CONNECTION=1", "\"Offline – gespeicherte Artikel · Stand 15:13 Uhr\"."]],
  ]],
  ["8. Safety nets", [
    ["A blank golden would make a test pass while protecting nothing; the lint catches it.", ["Terminal", "Run the golden lint.", "make lint-goldens", "checked 89 image(s)."]],
    ["Apple's accessibility audit runs on every screen; it found hidden tabs VoiceOver could still reach. (Running it takes ~5 min.)", ["VS Code", "Show the audit test.", `${VSC} ios/UITests/AccessibilityAuditTests.swift`, "The audit and its documented exceptions."]],
  ]],
  ["9. The same thing in CI", [
    ["Every pull request runs all of this on GitHub.", ["Browser", "The Actions tab.", `open ${GH}/actions`, "Red for the regression, green for main."]],
  ]],
  ["10. Android", [
    ["The same fixtures and test names work on Android with Roborazzi on Robolectric; I built that version first and cut it to keep the demo focused (STRATEGY §10).", ["Preview", "Open the strategy.", "open STRATEGY.pdf", "§10: Android, the same approach."]],
  ]],
];
{
  let n = 0;
  let body = `<h1>Demo without slides</h1>
<p class="lead">Show the project itself: the repo, the app, the tests and a regression being caught. About 15–20 minutes. Run <a href="1-Before-the-presentation.html">1 · Before the presentation</a> first. For each step: say the line, then copy and run the command.</p>
<div class="card"><h3>Tips</h3><ul class="tips">
<li>Say the line <i>before</i> you run the command, so people know what to look for.</li>
<li>Step 5's failing run is the point of the demo. Say so before you run it.</li>
<li>Short on time? Start at section 5.</li>
<li>If something breaks: <code>git checkout main</code>, then show the captured result: <code>open docs/regression</code>.</li></ul></div>`;
  for (const [title, steps] of flow) {
    body += `<section class="card"><h3>${esc(title)}</h3><ol class="steps" style="margin-top:12px">${steps.map(([say, [where, what, c, see]]) => { n++; return `<li><blockquote style="margin:0 0 8px"><p>${esc(say)}</p></blockquote><span class="where">${esc(where)}</span>${esc(what)}${cmd(c)}<div class="see"><b>You'll see:</b> ${esc(see)}</div></li>`; }).join("")}</ol></section>`;
  }
  body += `<div class="card"><h3>Close</h3><p class="goal">"That's the whole loop: frozen data, render, compare, and a person decides. Questions?"</p>${cmd("git branch --show-current")}<div class="see"><b>You'll see:</b> main</div></div>`;
  fs.writeFileSync(path.join(OUT, "3-Demo-without-slides.html"), page("Demo without slides", "3 · Demo without slides", body, emergency));
}

// ---------- prepare.sh ----------
{
  let sh = `#!/usr/bin/env bash
# Gets everything ready for the presentation (see presentation/1-Before-the-presentation.html).
# Generated by scripts/presentation/pages.js from content.js.
cd "$(dirname "$0")/../.." || exit 1
step() { printf '\\n\\033[1m▶ %s\\033[0m\\n  %s\\n' "$1" "$2"; }
fail=0
`;
  prep.forEach((p, i) => {
    sh += `\necho; echo "=== ${i + 1}/${prep.length}: ${p.title} ==="\n`;
    p.cmds.forEach(([c, d]) => {
      if (c.startsWith("cd ")) return;
      sh += `step ${JSON.stringify(c)} ${JSON.stringify(d)}\n`;
      if (c.includes("demo/regression")) sh += `${c}\necho "  (the failure above is expected: it's the deliberate regression)"\n`;
      else if (c.includes("git pull")) sh += `${c.replace(" && git pull", "")} || { echo "  ✗ step failed"; fail=1; }\ngit pull --ff-only || echo "  (git pull skipped: offline or no upstream)"\n`;
      else sh += `${c} || { echo "  ✗ step failed"; fail=1; }\n`;
    });
  });
  sh += `
git checkout -q main
echo
echo "=== Done. Branch: $(git branch --show-current) ==="
[ "$fail" = 0 ] && echo "All steps passed. You're ready." || echo "Some step failed: scroll up for ✗ before presenting."
`;
  fs.writeFileSync(path.join(__dirname, "prepare.sh"), sh, { mode: 0o755 });
}
console.log("wrote presentation/1-Before-the-presentation.html, 2-Presenting-with-slides.html, 3-Demo-without-slides.html, scripts/presentation/prepare.sh");
