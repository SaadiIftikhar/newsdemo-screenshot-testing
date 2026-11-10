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
  ["fixtures/feed/feed_default.json", "the fake API response (section 3)"],
  [`${SNAP}/FeedScreenSnapshotTests.swift`, "a screenshot test (section 3)"],
  ["ios/NewsKit/Sources/NewsFixtures/FixtureStore.swift", "where the clock, locale and time zone are pinned (section 4)"],
  [".github/CODEOWNERS", "who must approve golden changes (section 7)"],
  [`${SNAP}/SnapshotSupport.swift`, "the tolerance setting (section 8)"],
  ["fixtures/feed/feed_hostile_content.json", "messy CMS content (section 9)"],
  ["ios/UITests/AccessibilityAuditTests.swift", "the accessibility audit (section 10)"],
  [".github/workflows/screenshots.yml", "the CI pipeline (section 11)"],
];
const browserTabs = [
  ["artifacts/gallery/index.html", "every approved screenshot on one page (section 3)"],
  [`${GH}/pull/1`, "PR #1: the regression, blocked (section 7)"],
  [`${GH}/pull/2/commits`, "PR #2: the redesign, re-recorded by the bot (section 7)"],
  [`${GH}/actions`, "the CI run history (section 11)"],
];
const tab = (list, file) => list.findIndex(([f]) => f === file) + 1;
const vs = (file) => `VS Code tab ${tab(vscodeTabs, file)} "${path.basename(file)}"`;
const br = (url) => `browser tab ${tab(browserTabs, url)}`;

// ---------- the talk track ----------
// step: { where, what, cmd?, see? }  — cmd only for things you RUN live; everything else is already open.
const demo = [
  {
    title: "Opening", min: 1,
    goal: "Say who you are, what they'll see, and that everything is real.",
    say: `Hi, I'm Saad. Instead of slides, I'll show you the project itself: a small news app in SwiftUI, the screenshot tests around it, and the CI pipeline on GitHub.

The question it answers: how do we catch visual bugs in the BILD and WELT apps, like a PLUS badge that silently disappears, before a reader sees them, even though the news content changes every minute? I'll show how it works, break it on purpose, and show what happens next. At the end, how the same approach works on Android.`,
    steps: [{ where: "Terminal", what: "Start here. setup.sh left you in the project folder, on main." }],
    next: "Let me start with what's in the repo.",
  },
  {
    title: "1. What's in the repo", min: 1.5,
    goal: "Give them a map before you go into details.",
    say: `It's one repository. fixtures holds the fake data every test uses. ios holds the app and its tests. scripts holds small helpers like the diff report, and docs holds the strategy evidence and the captured regression.

Everything you can do is one make command, so nobody has to remember long Xcode commands. Here they all are.`,
    steps: [
      { where: "VS Code", what: "The Explorer on the left shows the folders: fixtures, ios, scripts, docs, presentation, plus Makefile and README.md." },
      { where: "Terminal", what: "List every command.", cmd: "make help", see: "ios-test, ios-ui-test, lint-goldens, gallery, ios-record, ios-run… each with a one-line description." },
    ],
    next: "First, the app itself, so you know what we're testing.",
  },
  {
    title: "2. The app", min: 2,
    goal: "They see the real product the tests protect, including the PLUS paywall.",
    say: `This is the app, running on fake data. A news feed with a breaking banner, a live ticker, teasers, video and ads; a games tab; and an account tab.

The important one for today is this PLUS article. If I'm not a subscriber and I tap it, I get the paywall. If I log in as the demo subscriber, it opens. That PLUS badge is exactly the thing a refactor could break without anyone noticing.`,
    steps: [
      { where: "Simulator", what: "The NewsDemo app is already open on the feed. Scroll to the Tesla article with the PLUS badge and tap it: the paywall appears. Close it." },
      { where: "Simulator", what: "Konto tab → log in with demo@newsdemo.app / demo1234 → back to Nachrichten → tap the Tesla article again: it opens." },
    ],
    fallback: "If the simulator is closed or slow, run make ios-run (~15 s), or describe the screens; you'll see them as goldens in section 3.",
    next: "So how do we test all these states without clicking through them?",
  },
  {
    title: "3. How one screenshot test works", min: 3,
    goal: "They understand fixture → render → golden, with real files.",
    say: `Three pieces. One: the fixture, frozen fake API data. This file is the feed the tests read; this item has premium: true, that's the PLUS article.

Two: the test. One line renders the real production feed screen with that data, in memory, and compares it with an approved picture.

Three: that approved picture, the golden, stored in git. One PNG per screen and variant: light, dark, the largest text size. If the new picture matches, the test passes. If not, it fails and shows me the difference. And here are all 89 approved states on one page.`,
    steps: [
      { where: "VS Code", what: `${vs("fixtures/feed/feed_default.json")}.`, see: "Point at \"premium\": true on the item tsr-002." },
      { where: "VS Code", what: `${vs(`${SNAP}/FeedScreenSnapshotTests.swift`)}.`, see: "func test_feed_default: one line renders the real feed with the fixture and compares it." },
      { where: "Finder", what: "The window \"FeedScreenSnapshotTests\" (the goldens folder).", see: "test_feed_default.light.png, .dark.png, .light_xxxl.png… Press Space on one to preview it." },
      { where: "Browser", what: `${br("artifacts/gallery/index.html")}: the gallery.`, see: "All 89 approved screenshots, grouped by test; light, dark and largest text side by side." },
    ],
    next: "But a news app changes every minute. Won't these pictures be outdated tomorrow?",
  },
  {
    title: "4. Content changes, goldens don't", min: 1.5,
    goal: "Answer the obvious question before they ask it.",
    say: `No, because a golden belongs to a fixture, not to live news. The fixture is frozen, and so is everything else that varies: the clock, the German locale, the Berlin time zone, random numbers, animations and images. "vor 9 Min." stays "vor 9 Min." forever, so a difference can only mean the code changed.

What does change in reality is the shape of the data, and that's tested without screenshots: contract tests, a fuzz test, and messy-content fixtures. I'll show those later.`,
    steps: [{ where: "VS Code", what: `${vs("ios/NewsKit/Sources/NewsFixtures/FixtureStore.swift")}.`, see: "FixtureEnvironment: now = 2026-11-05 14:13:20Z, locale de_DE, time zone Europe/Berlin." }],
    next: "Let me show you everything is green right now.",
  },
  {
    title: "5. Everything is green", min: 1.5,
    goal: "A real, passing run on the correct code.",
    say: `This runs every screenshot and every logic test: 89 screenshots and 35 logic tests. It takes under a minute, because the screens are drawn in memory: no app launch, no tapping, no network. [While it runs:] The same command runs in CI on every pull request.`,
    steps: [{ where: "Terminal", what: "Run all tests.", cmd: "make ios-test", see: "~40–60 s, ends with \"no snapshot failures\"." }],
    fallback: "If it's slow, keep talking; setup.sh already ran it green.",
    next: "Now the interesting part: does it catch a real bug?",
  },
  {
    title: "6. Break it on purpose", min: 3.5,
    goal: "The core moment: a harmless-looking change is caught.",
    say: `This branch contains a plausible refactor: "simplify the kicker row, tighten the banner". It's one file, a few lines, and it looks harmless in a code review. By accident it drops the PLUS badge and takes 2 points of padding off the breaking banner.

This is supposed to fail. [While it runs, ~1 min:] Every screen with a PLUS teaser or the banner should go red; everything else should stay green.

29 of 89 screenshots fail, and the other 60 stay green: games, account, the paywall. Here is the diff: the approved picture, the new one, and in magenta the pixels that changed. The badge is simply gone. And the summary already says what kind of change each one is: 10 layout changes, because the banner got shorter, and 19 visible ones. That table is what CI posts on the pull request.`,
    steps: [
      { where: "Terminal", what: "Show how small the change is.", cmd: "git diff main...demo/regression --stat", see: "1 file changed." },
      { where: "Terminal", what: "Switch to the branch with the bug.", cmd: "git checkout demo/regression", see: "Switched to branch 'demo/regression'." },
      { where: "Terminal", what: "Run the tests: they must fail.", cmd: "make ios-test", see: "~1 min, fails: \"diff report: 29 failure(s)\"." },
      { where: "Browser", what: "Open the diff page (it only exists after this failing run).", cmd: "open artifacts/ios/diffs/index.html", see: "Scroll to ComponentSnapshotTests/test_teaserCard_premium.dark: golden with PLUS | new without | magenta." },
      { where: "Terminal", what: "Show the triage summary.", cmd: "cat artifacts/ios/diffs/summary.md", see: "29 changed (layout: 10, visible: 19, subtle: 0)." },
      { where: "Terminal", what: "ALWAYS switch back to the correct code.", cmd: "git checkout main", see: "Switched to branch 'main'." },
    ],
    fallback: "If anything goes wrong: git checkout main, then open docs/regression in Finder (the captured CI result). \"Here's the captured run.\"",
    next: "The gate failed. What happens next is a human decision.",
  },
  {
    title: "7. A human decides", min: 2,
    goal: "Show both outcomes, live on GitHub.",
    say: `When a pull request fails, a person looks at the diff and decides.

If it's a bug, like this one, we fix the code and the goldens stay. This is that change as a pull request: blocked, with the bot's table.

If the change is intended, like a redesign, we add the record-snapshots label. CI re-records the goldens on its fixed machine, proves them, and pushes them as a bot commit; then a design or QA code owner approves the new pictures. This second pull request did exactly that: rounder cards, 33 screenshots changed on purpose, re-recorded by the bot, then green. Goldens never come from someone's laptop, and approval is never automatic.`,
    steps: [
      { where: "Browser", what: `${br(`${GH}/pull/1`)}: PR #1.`, see: "Red check; the bot comment: 29 changed (10 layout, 19 visible)." },
      { where: "Browser", what: `${br(`${GH}/pull/2/commits`)}: PR #2's commits.`, see: "\"snapshot-bot: chore(snapshots): re-record iOS goldens\", then green checks." },
      { where: "VS Code", what: `${vs(".github/CODEOWNERS")}.`, see: "Golden folders need design/QA review." },
    ],
    fallback: "Offline? Open docs/regression/summary.md in Finder: \"this is what the bot posts\".",
    next: "One more question: how small a difference do we allow?",
  },
  {
    title: "8. How much difference is allowed", min: 1,
    goal: "Show you thought about tolerance and human confirmation.",
    say: `Rendering noise no person can see is ignored: a perceptual precision of 0.98 absorbs GPU anti-aliasing. Anything beyond that fails, however small: a 2-point shift and a missing badge are both small, and both are bugs. A pixel count can't tell intent, so the labels are triage, never approval. And tolerance is never loosened globally.`,
    steps: [{ where: "VS Code", what: `${vs(`${SNAP}/SnapshotSupport.swift`)} (optional).`, see: "perceptualPrecision: 0.98, with the reason in a comment." }],
    next: "Now the messy reality of news content.",
  },
  {
    title: "9. Messy content and offline", min: 2.5,
    goal: "Product thinking: real content is messy, and the app handles it.",
    say: `This fixture is what a content system really sends: ampersand entities, line breaks inside headlines, emoji, a live ticker with no entries yet, and a video over an hour long.

In the app it's cleaned: readable headlines, "Noch keine Einträge", and 1:02:03 instead of 62:03. And offline: the first load works, then the connection drops. When I pull to refresh, the articles stay, with the time they were loaded, instead of an error screen.`,
    steps: [
      { where: "VS Code", what: `${vs("fixtures/feed/feed_hostile_content.json")}.`, see: "&amp;, line breaks inside headlines, \"durationSeconds\": 3723." },
      { where: "Simulator", what: "Relaunch the app with that fixture.", cmd: "make ios-run FIXTURE=feed_hostile_content", see: "~15–40 s: clean headlines, \"Noch keine Einträge\", the 1:02:03 video." },
      { where: "Simulator", what: "Relaunch in drop-connection mode, then drag the feed down.", cmd: "make ios-run DROP_CONNECTION=1", see: "\"Offline – gespeicherte Artikel · Stand 15:13 Uhr\"; the articles stay." },
    ],
    fallback: "If the simulator is slow, show the fixture only and describe the result.",
    next: "Screenshots only see pixels, so there are checks that see more.",
  },
  {
    title: "10. Safety nets", min: 1.5,
    goal: "Show the tests can't pass while protecting nothing.",
    say: `A blank golden would make a test pass while protecting nothing, so a lint rejects them. Apple's accessibility audit runs on every screen of the real app; it found hidden tabs that VoiceOver could still reach, which no screenshot can show. And my rule: every check is shown to fail once before I trust it.`,
    steps: [
      { where: "Terminal", what: "Run the golden lint.", cmd: "make lint-goldens", see: "\"checked 89 image(s)\" in ~2 s." },
      { where: "VS Code", what: `${vs("ios/UITests/AccessibilityAuditTests.swift")} (optional; don't run it live, it takes ~5 min).`, see: "The audit and its documented exceptions." },
    ],
    next: "All of this also runs automatically on every pull request.",
  },
  {
    title: "11. CI", min: 1.5,
    goal: "It works beyond your laptop.",
    say: `On GitHub every pull request runs all of this on the merged result: screenshots, UI tests and the accessibility audit, in 12 to 19 minutes. Here's the history: red for the regression, green for main and for the approved redesign. Real CI also taught me things a laptop didn't, like a simulator version that didn't exist on GitHub's machines, which I fixed by re-pinning it and re-recording in one reviewed pull request.`,
    steps: [
      { where: "Browser", what: `${br(`${GH}/actions`)}: the Actions tab.`, see: "The run history; click one run to show its steps." },
      { where: "VS Code", what: `${vs(".github/workflows/screenshots.yml")} (optional).`, see: "The pipeline: when it runs, the iOS job, the record mode." },
    ],
    fallback: "Offline? Describe it; the numbers are in the README.",
    next: "Finally, Android.",
  },
  {
    title: "12. Android and rollout", min: 2,
    goal: "Show the design transfers to Android, and that you can roll it out.",
    say: `Everything I showed works on Android the same way. Android reads the same fixture files and uses the same test names, so one regression fails in the same places on both. The tool is Roborazzi on Robolectric: Compose rendered on the JVM, no emulator. I built that version first, and it found real bugs, like a decoder difference that made a PLUS article free on Android. I cut it from the demo to keep today focused; it's in section 10 of the strategy.

To roll it out: start with one app and five design-system components in report-only mode, add the shared fixtures, then make the gate required, in about four sprints. Developers own the tests, QA owns the system around them, and design approves the goldens.`,
    steps: [{ where: "Preview", what: "The window \"STRATEGY.pdf\".", see: "§9 rollout, §10 Android." }],
    next: "To wrap up.",
  },
  {
    title: "Close", min: 0.5,
    goal: "Three sentences they'll remember, then questions.",
    say: `Frozen data makes every difference meaningful. Machines compare, but a person decides what's intended. And the same fixtures carry the approach to Android. Everything is in the repository. Happy to take questions.`,
    steps: [{ where: "Terminal", what: "Confirm you're back on main.", cmd: "git branch --show-current", see: "main" }],
    next: null,
  },
];

const qa = [
  ["Who approved these goldens?", "I did, as the code owner. The AI did a first pass and caught real bugs, but approving goldens and merging pull requests were never delegated. That's the process I propose: AI may triage, a human approves."],
  ["A test fails on CI but passes on my Mac. How do I debug it?", "CI is the source of truth and records the goldens. Download the ios-snapshot-diffs artifact from the run; the PR comment already says what kind of change it is. Then check the pinned simulator runtime: the same runtime on the Mac reproduces CI exactly."],
  ["You replaced the native tab bar because the tool couldn't capture it. Would you change product UI for a test tool?", "No, that was a demo shortcut. In production: keep the system tab bar, snapshot the tab content, and cover system chrome in the nightly device layer."],
  ["BILD has years of UIKit and a singleton API client. What do you ship in the first two weeks?", "Snapshots of design-system components that take plain models, a URLProtocol stub serving the fixtures as a stopgap, one client seam at one feature boundary, and CI in report-only mode."],
  ["Show me a regression that passes your tolerance.", "A colour change below about ΔE 2, like a slight brand-colour tweak. That's why colour tokens have their own contrast tests, and design reviews token changes."],
  ["How fast and how expensive at scale?", "A full iOS run on GitHub is 12–19 minutes including UI tests. At scale: only affected modules, sharding, iOS only when iOS code changes, the slowest checks nightly. Target: under 10 minutes per PR."],
  ["What about flaky tests?", "No automatic retries, because they hide flakiness. Quarantine within 24 hours with an owner. CI found one real flake, a UI test racing an animation, and I fixed the cause."],
  ["Why only iOS?", "The brief asks for a working demo on at least one platform plus a strategy that covers the other. I built Android first too, then cut it to keep the demo focused; STRATEGY §10 describes it."],
  ["How did you use AI?", "As a pair programmer: research, code, docs, running the tests. I made the scope and product decisions and approved the results; PROMPTS.md lists every prompt and decision."],
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
const runCount = demo.reduce((n, s) => n + s.steps.filter((x) => x.cmd).length, 0);

let body = `<h1>Demo script</h1>
<p class="lead">A walkthrough of the project without slides: the repo, the app, how a test works, a green run, a bug caught live, the human decision on GitHub, messy content, safety nets, CI, then Android. About ${total} minutes, then questions.</p>

<div class="card"><h3>Before you start: one command</h3>
<p class="goal">Run this in Terminal 15–30 minutes before. It checks your tools, makes sure both branches build and behave (main green, the regression failing on 29), then opens every window you'll point at, in the order you'll need them. About 3 minutes (up to 10 on a cold machine).</p>
${cmd("cd ~/Desktop/Task && presentation/setup.sh")}
<div class="see"><b>You'll see at the end:</b> "READY" and a list of what is open where. (The regression check prints a failure on purpose: that's the bug the demo catches.)</div></div>

<div class="card"><h3>What setup.sh leaves open</h3><table><thead><tr><th>Window</th><th>What's in it, in order</th></tr></thead><tbody>
<tr><td><b>Terminal</b></td><td>The project folder <code>~/Desktop/Task</code>, on <code>main</code>. You type the live commands here.</td></tr>
<tr><td><b>Simulator</b></td><td>The NewsDemo app, on the feed.</td></tr>
<tr><td><b>VS Code</b></td><td><ol style="margin:0;padding-left:18px">${vscodeTabs.map(([f, d]) => `<li><code>${esc(path.basename(f))}</code>: ${esc(d)}</li>`).join("")}</ol></td></tr>
<tr><td><b>Finder</b></td><td>The goldens folder <code>FeedScreenSnapshotTests</code> (section 3).</td></tr>
<tr><td><b>Browser</b></td><td><ol style="margin:0;padding-left:18px">${browserTabs.map(([u, d]) => `<li>${esc(d)}</li>`).join("")}</ol></td></tr>
<tr><td><b>Preview</b></td><td><code>STRATEGY.pdf</code> (section 12).</td></tr></tbody></table></div>

<div class="card"><h3>How to run the demo</h3><ul class="tips">
<li><b>Files are already open:</b> when the script says "VS Code tab 2", just click that tab. Only the <b>${runCount} commands you run live</b> have a Copy button: press Copy, Cmd+Tab to Terminal, Cmd+V, Enter, and read the command out loud.</li>
<li><b>Say what to look for <i>before</i> you switch windows or run a command</b>, so people know where to look.</li>
<li><b>Section 6 is the heart of the demo.</b> Never skip it. Short on time: skip sections 8 and 10.</li>
<li><b>If something breaks:</b> don't debug in front of them. Run <code>git checkout main</code> (button at the top), then use the fallback written in that section.</li>
<li><b>Screens:</b> share your whole screen; keep this page on a second device (tablet or phone) or printed.</li></ul></div>

<div class="card"><h3>Running order</h3><table><thead><tr><th>Section</th><th>Min</th><th>Live commands</th><th>Goal</th></tr></thead><tbody>
${demo.map((s, i) => `<tr><td><a href="#d${i}">${esc(s.title)}</a></td><td>${s.min}</td><td>${s.steps.filter((x) => x.cmd).length || "–"}</td><td>${esc(s.goal)}</td></tr>`).join("")}</tbody></table></div>`;

demo.forEach((s, i) => {
  const runs = s.steps.filter((x) => x.cmd).length;
  body += `<section class="card" id="d${i}"><h3>${esc(s.title)}</h3>
<div class="meta"><span class="badge">about ${s.min} min</span>${runs ? `<span class="badge run">${runs} live command${runs > 1 ? "s" : ""}</span>` : ""}</div>
<p class="goal"><b>Goal:</b> ${esc(s.goal)}</p><div class="label">Say</div><blockquote>${paragraphs(s.say)}</blockquote>
<div class="label">Show / do</div><ol class="steps">${s.steps.map((st) => `<li><span class="where">${esc(st.where)}</span>${esc(st.what)}${st.cmd ? cmd(st.cmd) : ""}${st.see ? `<div class="see"><b>You'll see:</b> ${esc(st.see)}</div>` : ""}</li>`).join("")}</ol>
${s.fallback ? `<div class="fallback"><b>If it fails:</b> ${esc(s.fallback)}</div>` : ""}
${s.next ? `<p class="bridge">Bridge to the next section: <i>"${esc(s.next)}"</i></p>` : ""}</section>`;
});
body += `<h2>Likely questions</h2><div class="card"><dl class="qa">${qa.map(([q, a]) => `<dt>"${esc(q)}"</dt><dd>${esc(a)}</dd>`).join("")}</dl>
<p class="see" style="margin-top:16px">Can't answer one? "Good question; I haven't measured that. Here's how I'd find out: …", then name the test or experiment.</p></div>`;

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
git checkout -q main && ok "back on main"

step "4/6 Golden lint and gallery"
make lint-goldens > "$LOG/lint.log" 2>&1 && ok "$(tail -1 "$LOG/lint.log")" || die "golden lint failed: see $LOG/lint.log"
make gallery > "$LOG/gallery.log" 2>&1 && ok "gallery: artifacts/gallery/index.html" || die "gallery failed: see $LOG/gallery.log"

step "5/6 The app in the simulator (first time ~1.5 min)"
make ios-run > "$LOG/ios-run.log" 2>&1 && ok "NewsDemo is running in the simulator" || die "the app did not launch: see $LOG/ios-run.log"

step "6/6 Opening the windows, in the order the demo uses them"
"$VSCODE" --new-window . >/dev/null 2>&1; sleep 3
"$VSCODE" --reuse-window ${vscodeTabs.map(([f]) => q(f)).join(" ")} >/dev/null 2>&1
ok "VS Code tabs: ${vscodeTabs.map(([f], i) => `${i + 1} ${path.basename(f)}`).join(", ")}"
open ${q(`${SNAP}/__Snapshots__/FeedScreenSnapshotTests`)} && ok "Finder: the goldens folder FeedScreenSnapshotTests"
${browserTabs.map(([u]) => `open ${q(u)}; sleep 1`).join("\n")}
ok "Browser tabs: 1 gallery, 2 PR #1, 3 PR #2 commits, 4 Actions"
open STRATEGY.pdf && ok "Preview: STRATEGY.pdf"
open presentation/Demo-script.html && ok "This script: presentation/Demo-script.html (move it to your second device)"

printf '\\n%s%sREADY.%s Branch: %s. Logs: %s/\\n' "$B" "$G" "$N" "$(git branch --show-current)" "$LOG"
printf 'Now: bring Terminal to the front, enlarge the font (Cmd +), turn on Do Not Disturb, and start with the Opening.\\n'
`;
fs.writeFileSync(path.join(OUT, "setup.sh"), sh, { mode: 0o755 });
console.log(`wrote presentation/Demo-script.html (${demo.length} sections, ${runCount} live commands) and presentation/setup.sh`);
