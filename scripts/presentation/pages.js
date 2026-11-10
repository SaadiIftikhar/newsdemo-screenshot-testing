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
// Each section: a full talk track (say), the commands (steps), what you'll see, a fallback and the bridge.
// steps: [where, what, command, what you'll see]
const demo = [
  {
    title: "Opening", min: 1,
    goal: "Say who you are, what they'll see, and that everything is real.",
    say: `Hi, I'm Saad. Instead of slides, I'll show you the project itself: a small news app in SwiftUI, the screenshot tests around it, and the CI pipeline on GitHub.

The question it answers: how do we catch visual bugs in the BILD and WELT apps, like a PLUS badge that silently disappears, before a reader sees them, even though the news content changes every minute? I'll show how it works, break it on purpose, and show what happens next. At the end, how the same approach works on Android.`,
    steps: [["Terminal", "Make sure you're on the correct code (prepare.sh already did this).", "git branch --show-current", "main"]],
    next: "Let me start with what's in the repo.",
  },
  {
    title: "1. What's in the repo", min: 1.5,
    goal: "Give them a map before you go into details.",
    say: `It's one repository. fixtures holds the fake data every test uses. ios holds the app and its tests. scripts holds small helpers like the diff report, and docs holds the strategy evidence and the captured regression.

Everything you can do is one make command, so nobody has to remember long Xcode commands. Here they all are.`,
    steps: [
      ["VS Code", "Open the project.", `${VSC} .`, "fixtures/, ios/, scripts/, docs/, presentation/, Makefile, README.md."],
      ["Terminal", "List every command.", "make help", "ios-test, ios-ui-test, lint-goldens, gallery, ios-record, ios-run… each with a one-line description."],
    ],
    next: "First, the app itself, so you know what we're testing.",
  },
  {
    title: "2. The app", min: 2,
    goal: "They see the real product the tests protect, including the PLUS paywall.",
    say: `This is the app, running on fake data. A news feed with a breaking banner, a live ticker, teasers, video and ads; a games tab; and an account tab.

The important one for today is this PLUS article. If I'm not a subscriber and I tap it, I get the paywall. If I log in as the demo subscriber, it opens. That PLUS badge is exactly the thing a refactor could break without anyone noticing.`,
    steps: [
      ["Simulator", "Open the app (already built by prepare.sh, ~15 s).", "make ios-run", "The NewsDemo feed. Tap the Tesla article (PLUS) → paywall. Konto tab: demo@newsdemo.app / demo1234 → tap it again → it opens."],
    ],
    fallback: "If the simulator is slow, describe the screens and move on; you'll see them as goldens in section 3.",
    next: "So how do we test all these states without clicking through them?",
  },
  {
    title: "3. How one screenshot test works", min: 3,
    goal: "They understand fixture → render → golden, with real files.",
    say: `Three pieces. One: the fixture, frozen fake API data. This file is the feed the tests read; this item has premium: true, that's the PLUS article.

Two: the test. One line renders the real production feed screen with that data, in memory, and compares it with an approved picture.

Three: that approved picture, the golden, stored in git. One PNG per screen and variant: light, dark, the largest text size. If the new picture matches, the test passes. If not, it fails and shows me the difference. And here are all 89 approved states on one page.`,
    steps: [
      ["VS Code", "The fixture.", `${VSC} fixtures/feed/feed_default.json`, "Point at \"premium\": true on tsr-002."],
      ["VS Code", "The test.", `${VSC} ios/NewsKit/Tests/NewsUISnapshotTests/FeedScreenSnapshotTests.swift`, "func test_feed_default: one line."],
      ["Finder", "The goldens folder.", "open ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__/FeedScreenSnapshotTests", "test_feed_default.light.png, .dark.png, .light_xxxl.png…"],
      ["Browser", "Every golden on one page.", "make gallery && open artifacts/gallery/index.html", "89 screenshots, grouped by test, variants side by side."],
    ],
    next: "But a news app changes every minute. Won't these pictures be outdated tomorrow?",
  },
  {
    title: "4. Content changes, goldens don't", min: 1.5,
    goal: "Answer the obvious question before they ask it.",
    say: `No, because a golden belongs to a fixture, not to live news. The fixture is frozen, and so is everything else that varies: the clock, the German locale, the Berlin time zone, random numbers, animations and images. "vor 9 Min." stays "vor 9 Min." forever, so a difference can only mean the code changed.

What does change in reality is the shape of the data, and that's tested without screenshots: contract tests, a fuzz test, and messy-content fixtures. I'll show those later.`,
    steps: [
      ["VS Code", "Where the clock, locale and time zone are pinned.", `${VSC} ios/NewsKit/Sources/NewsFixtures/FixtureStore.swift`, "FixtureEnvironment: now = 2026-11-05 14:13:20Z, de_DE, Europe/Berlin."],
    ],
    next: "Let me show you everything is green right now.",
  },
  {
    title: "5. Everything is green", min: 1.5,
    goal: "A real, passing run on the correct code.",
    say: `This runs every screenshot and every logic test: 89 screenshots and 35 logic tests. It takes about 40 seconds, because the screens are drawn in memory: no app launch, no tapping, no network. [While it runs:] The same command runs in CI on every pull request.`,
    steps: [["Terminal", "Run all tests.", "make ios-test", "~40–60 s, ends with \"no snapshot failures\"."]],
    fallback: "If it's slow, keep talking; prepare.sh already ran it green.",
    next: "Now the interesting part: does it catch a real bug?",
  },
  {
    title: "6. Break it on purpose", min: 3.5,
    goal: "The core moment: a harmless-looking change is caught.",
    say: `This branch contains a plausible refactor: "simplify the kicker row, tighten the banner". It's one file, a few lines, and it looks harmless in a code review. By accident it drops the PLUS badge and takes 2 points of padding off the breaking banner.

This is supposed to fail. [While it runs, ~1 min:] Every screen with a PLUS teaser or the banner should go red; everything else should stay green.

29 of 89 screenshots fail, and the other 60 stay green: games, account, the paywall. Here is the diff: the approved picture, the new one, and in magenta the pixels that changed. The badge is simply gone. And the summary already says what kind of change each one is: 10 layout changes, because the banner got shorter, and 19 visible ones. That table is what CI posts on the pull request.`,
    steps: [
      ["Terminal", "Show how small the change is.", "git diff main demo/regression --stat", "1 file changed."],
      ["Terminal", "Switch to the branch with the bug.", "git checkout demo/regression", "Switched to branch 'demo/regression'."],
      ["Terminal", "Run the tests: they must fail.", "make ios-test", "~1 min, fails: \"diff report: 29 failure(s)\"."],
      ["Browser", "Open the diff page.", "open artifacts/ios/diffs/index.html", "Scroll to ComponentSnapshotTests/test_teaserCard_premium.dark: golden with PLUS | new without | magenta."],
      ["Terminal", "Show the triage summary.", "cat artifacts/ios/diffs/summary.md", "29 changed (layout: 10, visible: 19, subtle: 0)."],
      ["Terminal", "ALWAYS switch back to the correct code.", "git checkout main", "Switched to branch 'main'."],
    ],
    fallback: "If anything goes wrong: git checkout main, then open docs/regression (the captured CI result). \"Here's the captured run.\"",
    next: "The gate failed. What happens next is a human decision.",
  },
  {
    title: "7. A human decides", min: 2,
    goal: "Show both outcomes, live on GitHub.",
    say: `When a pull request fails, a person looks at the diff and decides.

If it's a bug, like this one, we fix the code and the goldens stay. This is that change as a pull request: blocked, with the bot's table.

If the change is intended, like a redesign, we add the record-snapshots label. CI re-records the goldens on its fixed machine, proves them, and pushes them as a bot commit; then a design or QA code owner approves the new pictures. This second pull request did exactly that: rounder cards, 33 screenshots changed on purpose, re-recorded by the bot, then green. Goldens never come from someone's laptop, and approval is never automatic.`,
    steps: [
      ["Browser", "The regression pull request.", `open ${PR_REGRESSION}`, "Red check; the bot comment: 29 changed."],
      ["Browser", "The redesign pull request's commits.", `open ${PR_REDESIGN}/commits`, "\"snapshot-bot: re-record iOS goldens\", then green."],
      ["Terminal", "Who must approve golden changes.", "cat .github/CODEOWNERS", "Golden folders need design/QA review."],
    ],
    fallback: "Offline? open docs/regression and show summary.md: \"this is what the bot posts\".",
    next: "One more question: how small a difference do we allow?",
  },
  {
    title: "8. How much difference is allowed", min: 1,
    goal: "Show you thought about tolerance and human confirmation.",
    say: `Rendering noise no person can see is ignored: a perceptual precision of 0.98 absorbs GPU anti-aliasing. Anything beyond that fails, however small: a 2-point shift and a missing badge are both small, and both are bugs. A pixel count can't tell intent, so the labels are triage, never approval. And tolerance is never loosened globally.`,
    steps: [["VS Code", "(Optional) The tolerance in code.", `${VSC} ios/NewsKit/Tests/NewsUISnapshotTests/SnapshotSupport.swift`, "perceptualPrecision: 0.98, with the reason in a comment."]],
    next: "Now the messy reality of news content.",
  },
  {
    title: "9. Messy content and offline", min: 2.5,
    goal: "Product thinking: real content is messy, and the app handles it.",
    say: `This fixture is what a content system really sends: ampersand entities, line breaks inside headlines, emoji, a live ticker with no entries yet, and a video over an hour long.

In the app it's cleaned: readable headlines, "Noch keine Einträge", and 1:02:03 instead of 62:03. And offline: the first load works, then the connection drops. When I pull to refresh, the articles stay, with the time they were loaded, instead of an error screen.`,
    steps: [
      ["VS Code", "The messy fixture.", `${VSC} fixtures/feed/feed_hostile_content.json`, "&amp;, line breaks, \"durationSeconds\": 3723."],
      ["Simulator", "The app with that fixture.", "make ios-run FIXTURE=feed_hostile_content", "Clean headlines, \"Noch keine Einträge\", 1:02:03."],
      ["Simulator", "Offline after the first load.", "make ios-run DROP_CONNECTION=1", "Drag the feed down: \"Offline – gespeicherte Artikel · Stand 15:13 Uhr\"."],
    ],
    fallback: "If the simulator is slow, show the fixture only and describe the result.",
    next: "Screenshots only see pixels, so there are checks that see more.",
  },
  {
    title: "10. Safety nets", min: 1.5,
    goal: "Show the tests can't pass while protecting nothing.",
    say: `A blank golden would make a test pass while protecting nothing, so a lint rejects them. Apple's accessibility audit runs on every screen of the real app; it found hidden tabs that VoiceOver could still reach, which no screenshot can show. And my rule: every check is shown to fail once before I trust it.`,
    steps: [
      ["Terminal", "Run the golden lint.", "make lint-goldens", "\"checked 89 image(s)\" in ~2 s."],
      ["VS Code", "(Optional) The accessibility audit test.", `${VSC} ios/UITests/AccessibilityAuditTests.swift`, "The audit and its documented exceptions. Don't run it live (~5 min)."],
    ],
    next: "All of this also runs automatically on every pull request.",
  },
  {
    title: "11. CI", min: 1.5,
    goal: "It works beyond your laptop.",
    say: `On GitHub every pull request runs all of this on the merged result: screenshots, UI tests and the accessibility audit, in 12 to 19 minutes. Here's the history: red for the regression, green for main and for the approved redesign. Real CI also taught me things a laptop didn't, like a simulator version that didn't exist on GitHub's machines, which I fixed by re-pinning it and re-recording in one reviewed pull request.`,
    steps: [["Browser", "The Actions tab.", `open ${GH}/actions`, "The run history; open one run to show its steps."]],
    fallback: "Offline? Describe it; the numbers are in the README.",
    next: "Finally, Android.",
  },
  {
    title: "12. Android and rollout", min: 2,
    goal: "Show the design transfers to Android, and that you can roll it out.",
    say: `Everything I showed works on Android the same way. Android reads the same fixture files and uses the same test names, so one regression fails in the same places on both. The tool is Roborazzi on Robolectric: Compose rendered on the JVM, no emulator. I built that version first, and it found real bugs, like a decoder difference that made a PLUS article free on Android. I cut it from the demo to keep today focused; it's in section 10 of the strategy.

To roll it out: start with one app and five design-system components in report-only mode, add the shared fixtures, then make the gate required, in about four sprints. Developers own the tests, QA owns the system around them, and design approves the goldens.`,
    steps: [["Preview", "The strategy, for the details.", "open STRATEGY.pdf", "§9 rollout, §10 Android."]],
    next: "To wrap up.",
  },
  {
    title: "Close", min: 0.5,
    goal: "Three sentences they'll remember, then questions.",
    say: `Frozen data makes every difference meaningful. Machines compare, but a person decides what's intended. And the same fixtures carry the approach to Android. Everything is in the repository. Happy to take questions.`,
    steps: [["Terminal", "Confirm you're back on main.", "git branch --show-current", "main"]],
    next: null,
  },
];
{
  const dtotal = Math.round(demo.reduce((t, s) => t + s.min, 0));
  let body = `<h1>Demo without slides</h1>
<p class="lead">Show the project itself, in this order: the repo, the app, how a test works, a green run, a bug caught live, the human decision on GitHub, messy content, safety nets, CI, then Android. About ${dtotal} minutes, then questions. Run <a href="1-Before-the-presentation.html">1 · Before the presentation</a> first.</p>
<div class="card"><h3>How to run it</h3><ul class="tips">
<li><b>For every section:</b> say the script (or your own words), then press <b>Copy</b> on each command, Cmd+Tab to Terminal, Cmd+V, Enter. Read the command out loud as you run it.</li>
<li><b>Say what to look for <i>before</i> you run a command</b>, so people know where to look.</li>
<li><b>Section 6 is the heart of the demo.</b> Never skip it. Short on time: skip sections 8 and 10.</li>
<li><b>If something breaks:</b> don't debug in front of them. <code>git checkout main</code>, then use the fallback written in that section.</li></ul></div>
<div class="card"><h3>Running order</h3><table><thead><tr><th>Section</th><th>Minutes</th><th>What happens</th></tr></thead><tbody>
${demo.map((s) => `<tr><td><a href="#d${demo.indexOf(s)}">${esc(s.title)}</a></td><td>${s.min}</td><td>${esc(s.goal)}</td></tr>`).join("")}</tbody></table></div>`;
  demo.forEach((s, i) => {
    body += `<section class="card" id="d${i}"><h3>${esc(s.title)}</h3>
<div class="meta"><span class="badge time">about ${s.min} min</span></div>
<p class="goal"><b>Goal:</b> ${esc(s.goal)}</p><div class="label">Say</div><blockquote>${paragraphs(s.say)}</blockquote>
<div class="label">Do</div>${stepsHtml(s.steps)}
${s.fallback ? `<div class="fallback"><b>If it fails:</b> ${esc(s.fallback)}</div>` : ""}
${s.next ? `<p class="bridge">Bridge to the next section: <i>"${esc(s.next)}"</i></p>` : ""}</section>`;
  });
  body += `<h2>Likely questions</h2><div class="card"><p class="see" style="margin:0">The same questions and short answers as in <a href="2-Presenting-with-slides.html#qa">2 · Presenting with slides</a>.</p></div>`;
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
