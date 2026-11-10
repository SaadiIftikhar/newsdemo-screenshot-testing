// Builds presentation/Screenshot-Testing-Presentation.pptx.
// Slide text lives here; speaker notes and LIVE tags come from content.js (also the source of SCRIPT.md / COMMANDS.md).
// Run: presentation/src/build.sh
const path = require("path");
const pptxgen = require("pptxgenjs");
const { applyTheme } = require(process.env.APPLY_THEME);
const { slides: CONTENT } = require("./content.js");

const OUT = process.argv[2];
const A = (f) => path.join(__dirname, "assets", f);

const THEME = {
  name: "Screenshot Gate",
  headFontFace: "Arial",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "1B1F3B", lt1: "FFFFFF", dk2: "3A4363", lt2: "EEF1F6",
    accent1: "0E8C99", // teal: the process
    accent2: "C2185B", // magenta: changed / failed / live (same meaning as in the diff images)
    accent3: "E09B2D", accent4: "2E9E5B", accent5: "5B6478", accent6: "9AA3B5",
    hlink: "0E8C99", folHlink: "5B6478",
  },
};

const pres = new pptxgen();
pres.layout = "LAYOUT_16x9"; // 10 x 5.625 in
pres.author = "Saad Iftikhar";
pres.title = "Screenshot testing with mocked data";
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
const C = pres.SchemeColor;
const ALL = [];
const addSlide = (o) => { const sl = pres.addSlide(o); ALL.push(sl); return sl; };

// ---------- layouts ----------
pres.defineSlideMaster({
  title: "Title dark",
  background: { color: C.text1 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 1.0, w: 4.9, h: 2.1, fontFace: THEME.headFontFace,
      fontSize: 34, bold: true, color: C.background1, valign: "bottom", align: "left", margin: 0 }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: 0.6, y: 3.25, w: 4.9, h: 1.8, fontSize: 15,
      color: C.accent6, valign: "top", align: "left", margin: 0 }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "Content",
  background: { color: C.background1 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.5, y: 0.3, w: 9, h: 0.75, fontFace: THEME.headFontFace,
      fontSize: 28, bold: true, color: C.text1, valign: "middle", align: "left", margin: 0 }, text: "" } },
    { text: { text: "Screenshot testing with mocked data · Saad Iftikhar", options: { x: 0.5, y: 5.2, w: 6, h: 0.3,
      fontSize: 10, color: C.accent5, margin: 0, isTextBox: true } } },
  ],
  slideNumber: { x: 9.0, y: 5.2, w: 0.5, h: 0.3, fontSize: 10, color: C.accent5, align: "right" },
});

// ---------- helpers ----------
const shadow = () => ({ type: "outer", color: "1B1F3B", opacity: 0.18, blur: 8, offset: 3, angle: 90 });

function phone(slide, img, x, y, h, label, labelColor) {
  const w = h * (416 / 900);
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: x - 0.06, y: y - 0.06, w: w + 0.12, h: h + 0.12, rectRadius: 0.12,
    fill: { color: C.background1 }, line: { color: C.accent6, width: 0.75 }, shadow: shadow(), objectName: `frame ${label || img}` });
  slide.addImage({ path: A(img), x, y, w, h, altText: label ? `${label} screenshot` : "App screenshot", objectName: `shot ${img}` });
  if (label) slide.addText(label, { x: x - 0.1, y: y + h + 0.1, w: w + 0.2, h: 0.28, fontSize: 11, bold: true, align: "center",
    color: labelColor || C.accent5, margin: 0, isTextBox: true });
}

function dot(slide, n, x, y, color) {
  slide.addShape(pres.shapes.OVAL, { x, y, w: 0.42, h: 0.42, fill: { color: color || C.accent1 }, line: { type: "none" }, objectName: `step ${n}` });
  slide.addText(String(n), { x, y, w: 0.42, h: 0.42, fontSize: 14, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });
}

function card(slide, x, y, w, h, title, body, opts = {}) {
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.08, fill: { color: C.background2 }, line: { type: "none" }, objectName: `card ${title}` });
  slide.addText(title, { x: x + 0.2, y: y + 0.15, w: w - 0.4, h: 0.4, fontSize: 15, bold: true, color: opts.titleColor || C.text1, margin: 0, valign: "top", isTextBox: true });
  slide.addText(body, { x: x + 0.2, y: y + 0.58, w: w - 0.4, h: h - 0.7, fontSize: opts.bodySize || 13, color: C.text2, margin: 0, valign: "top", paraSpaceAfter: 4, isTextBox: true });
}

function bullets(items, size = 14) {
  return items.map((t, i) => ({ text: t, options: { bullet: true, breakLine: i < items.length - 1, fontSize: size, paraSpaceAfter: 6 } }));
}

function stat(slide, x, y, w, big, small, color, size = 30) {
  const bh = size / 72 * 1.25;
  slide.addText(big, { x, y, w, h: bh, fontSize: size, bold: true, color: color || C.accent1, margin: 0, valign: "top", isTextBox: true, fontFace: THEME.headFontFace });
  slide.addText(small, { x, y: y + bh, w, h: 0.45, fontSize: 12, color: C.text2, margin: 0, valign: "top", isTextBox: true });
}

const arrow = (slide, x, y, w) => slide.addShape(pres.shapes.RIGHT_ARROW, { x, y, w, h: 0.3, fill: { color: C.accent6 }, line: { type: "none" }, objectName: "arrow" });

const S = { intro: "Why and what", how: "How it works", proof: "Proof", edge: "Changing content", rollout: "CI and rollout" };

// 1. Title
pres.addSection({ title: S.intro });
let s = addSlide({ masterName: "Title dark", sectionTitle: S.intro });
s.addText("Catching visual bugs before readers do", { placeholder: "title" });
s.addText([
  { text: "Screenshot testing with mocked data for the BILD and WELT apps, on iOS and Android", options: { breakLine: true } },
  { text: " ", options: { breakLine: true, fontSize: 8 } },
  { text: "Saad Iftikhar · QA Engineer", options: { color: C.background1, bold: true } },
], { placeholder: "body" });
phone(s, "ios_feed.png", 5.9, 0.75, 3.9, "iOS", C.accent6);
phone(s, "and_feed.png", 7.9, 0.75, 3.9, "Android", C.accent6);

// 2. Problem
s = addSlide({ masterName: "Content", sectionTitle: S.intro });
s.addText("The problem: too many states to check by hand", { placeholder: "title" });
stat(s, 0.5, 1.3, 2.7, "4 apps", "BILD, Sport BILD, WELT News, WELT Edition");
stat(s, 0.5, 2.55, 2.7, "2 platforms", "iOS and Android, built natively");
stat(s, 0.5, 3.8, 2.7, "89 states", "per platform in the demo alone", C.accent2);
card(s, 3.4, 1.35, 6.1, 1.65, "A news feed is many screens in one",
  "Breaking news, live tickers, PLUS paywalls, ads, video, offline and error states, dark mode, huge accessibility text, long German compound words. Each depends on backend data.");
card(s, 3.4, 3.2, 6.1, 1.65, "The expensive bug is a small one",
  "A refactor silently drops the PLUS badge: paid articles now look free. Nobody notices in a manual release check, because the screen still looks fine.", { titleColor: C.accent2 });

// 3. Approach
pres.addSection({ title: S.how });
s = addSlide({ masterName: "Content", sectionTitle: S.how });
s.addText("The approach in one picture", { placeholder: "title" });
[["Shared JSON fixtures", "Frozen fake API data, used by both platforms"],
 ["Render the real screen", "Production UI code, in a fast in-process test"],
 ["Compare to golden", "An approved PNG stored in git"]].forEach(([t, b], i) => {
  const x = 0.5 + i * 2.55;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.5, w: 2.15, h: 1.55, rectRadius: 0.08, fill: { color: C.background2 }, line: { type: "none" }, objectName: `flow ${i + 1}` });
  dot(s, i + 1, x + 0.15, 1.65);
  s.addText(t, { x: x + 0.15, y: 2.12, w: 1.9, h: 0.4, fontSize: 14, bold: true, color: C.text1, margin: 0, isTextBox: true });
  s.addText(b, { x: x + 0.15, y: 2.5, w: 1.9, h: 0.5, fontSize: 11, color: C.text2, margin: 0, valign: "top", isTextBox: true });
  if (i < 2) arrow(s, x + 2.2, 2.12, 0.3);
});
arrow(s, 8.15, 2.12, 0.3);
s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 8.5, y: 1.5, w: 1.0, h: 0.7, rectRadius: 0.08, fill: { color: C.accent4 }, line: { type: "none" }, objectName: "pass" });
s.addText("Same: pass", { x: 8.5, y: 1.5, w: 1.0, h: 0.7, fontSize: 12, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });
s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 8.5, y: 2.35, w: 1.0, h: 0.7, rectRadius: 0.08, fill: { color: C.accent2 }, line: { type: "none" }, objectName: "fail" });
s.addText("Different: fail + diff", { x: 8.5, y: 2.35, w: 1.0, h: 0.7, fontSize: 11, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });
s.addText(bullets([
  "Inputs are frozen, so a difference always means the code changed how a screen looks",
  "Same fixtures and the same test names on iOS and Android: one regression fails on both, in the same places",
  "A human reviews every difference: machines compare, people decide",
]), { x: 0.5, y: 3.4, w: 9, h: 1.6, color: C.text2, margin: 0, valign: "top", isTextBox: true });

// 4. Tooling
s = addSlide({ masterName: "Content", sectionTitle: S.how });
s.addText("Tooling: native, in-process, fast", { placeholder: "title" });
card(s, 0.5, 1.3, 4.35, 2.45, "iOS: swift-snapshot-testing",
  "Point-Free's library, pinned. Renders SwiftUI in-process on a pinned simulator. Fits a TCA codebase: mocking reuses withDependencies.\n\nAbout 40 s for 89 screenshots and 35 logic tests.");
card(s, 5.15, 1.3, 4.35, 2.45, "Android: Roborazzi on Robolectric",
  "Runs on the JVM, no emulator. Works with Hilt. The same run also drives tap-and-type interaction tests and accessibility checks.\n\nAbout 20 s for 89 screenshots and 52 other tests.");
s.addText([
  { text: "Rejected for the PR gate: ", options: { bold: true, color: C.text1 } },
  { text: "Paparazzi (2.0 alpha, no Hilt), Compose Preview Screenshot Testing (alpha), Appium or Maestro with a paid visual service (minutes per screen, flakier). Device-level tools stay, as a nightly Layer 2 for what in-process rendering can't see: system chrome, real devices, hostile settings.", options: { color: C.text2 } },
], { x: 0.5, y: 3.95, w: 9, h: 1.1, fontSize: 13, margin: 0, valign: "top", isTextBox: true });

// 5. Mocked data
s = addSlide({ masterName: "Content", sectionTitle: S.how });
s.addText("Mocked data: content changes, goldens don't", { placeholder: "title" });
s.addText(bullets([
  "A golden belongs to a fixture, never to live news, so it can't go stale",
  "Everything is pinned: clock, de_DE locale, Berlin time zone, seeded randomness, animations off, local images",
  "Timestamps are relative to the pinned clock: \"vor 9 Min.\" forever",
  "Real data changes are tested without screenshots: decoder contract tests, a fuzz test, hostile-content fixtures",
  "When the API changes, the fixture is refreshed in its own PR, which shows exactly which goldens change",
]), { x: 0.5, y: 1.3, w: 5.2, h: 3.7, color: C.text2, margin: 0, valign: "top", isTextBox: true });
phone(s, "ios_feed.png", 6.15, 1.2, 3.55, "iOS");
phone(s, "and_feed.png", 8.0, 1.2, 3.55, "Android");

// 6. Regression demo
pres.addSection({ title: S.proof });
s = addSlide({ masterName: "Content", sectionTitle: S.proof });
s.addText("Demo: a refactor drops the PLUS badge", { placeholder: "title" });
["Golden (approved)", "This PR", "Changed pixels"].forEach((t, i) => {
  s.addText(t, { x: 1.25 + i * 2.5, y: 1.15, w: 2.5, h: 0.3, fontSize: 12, bold: true, align: "center", color: i === 2 ? C.accent2 : C.text2, margin: 0, isTextBox: true });
});
s.addImage({ path: A("reg_teaser.png"), x: 1.25, y: 1.5, w: 7.5, h: 7.5 * 598 / 1800,
  altText: "Diff of the premium teaser: golden with PLUS badge, this PR without it, changed pixels in magenta", objectName: "regression diff" });
stat(s, 1.25, 4.1, 2.5, "29 of 89", "screenshots fail", C.accent2, 24);
stat(s, 3.75, 4.1, 2.5, "Same 29", "on iOS and on Android", undefined, 24);
stat(s, 6.25, 4.1, 2.5, "10 + 19", "layout + visible, 0 subtle", C.text1, 24);

// 7. Review workflow
s = addSlide({ masterName: "Content", sectionTitle: S.proof });
s.addText("Review: machines compare, people decide", { placeholder: "title" });
[["PR fails", "Bot comment: which screens, and what kind of change"], ["Human looks", "Diff gallery: golden, this PR, changed pixels"]].forEach(([t, b], i) => {
  const y = 1.35 + i * 1.25;
  dot(s, i + 1, 0.5, y);
  s.addText(t, { x: 1.05, y: y - 0.02, w: 2.6, h: 0.4, fontSize: 15, bold: true, color: C.text1, margin: 0, isTextBox: true });
  s.addText(b, { x: 1.05, y: y + 0.38, w: 2.6, h: 0.7, fontSize: 12, color: C.text2, margin: 0, valign: "top", isTextBox: true });
});
card(s, 3.95, 1.3, 5.55, 1.45, "Not intended: fix the code", "Like the PLUS badge. The goldens stay; the PR stays blocked until the screen is right again.", { titleColor: C.accent2 });
card(s, 3.95, 2.95, 5.55, 2.0, "Intended: re-record on CI, then approve",
  "Add the record-snapshots label. CI re-records on the pinned image, proves the new goldens (lint plus a full verify) and pushes them as a bot commit. A design or QA code owner approves the image diff.", { titleColor: C.accent4 });
s.addText("Goldens never come from a laptop. Approval is never automatic.", { x: 0.5, y: 4.0, w: 3.3, h: 0.9, fontSize: 13, italic: true, color: C.accent1, margin: 0, valign: "top", isTextBox: true });

// 8. Tolerance
s = addSlide({ masterName: "Content", sectionTitle: S.proof });
s.addText("How much difference is allowed?", { placeholder: "title" });
card(s, 0.5, 1.3, 2.85, 2.6, "Rendering noise: ignored", "iOS: perceptual precision 0.98 absorbs GPU anti-aliasing.\nAndroid: measured Mac vs Linux, at most 2/255 on 0.005% of pixels: inside the tolerance.", { titleColor: C.accent4 });
card(s, 3.575, 1.3, 2.85, 2.6, "Any real change: fails", "A 2pt shift and a missing badge are both \"small\". Both are bugs. A pixel count can't tell intent.", { titleColor: C.accent2 });
card(s, 6.65, 1.3, 2.85, 2.6, "Triage, not approval", "Each change is labelled layout, visible or subtle, so the reviewer knows what to look for. A person still decides.", { titleColor: C.accent1 });
s.addText("No \"small diff = auto-pass\". Tolerance is never loosened globally; a per-test exception needs a comment and a review.",
  { x: 0.5, y: 4.15, w: 9, h: 0.8, fontSize: 14, italic: true, color: C.text1, margin: 0, valign: "top", isTextBox: true });

// 9. Edge cases
pres.addSection({ title: S.edge });
s = addSlide({ masterName: "Content", sectionTitle: S.edge });
s.addText("Edge cases of a news app", { placeholder: "title" });
phone(s, "ios_hostile.png", 0.75, 1.2, 3.55, "Hostile content");
[["Messy CMS text", "&amp;, stray line breaks, emoji: cleaned identically on both platforms"],
 ["Long German words", "Soft hyphens from the CMS let them break correctly"],
 ["Ticker before kick-off", "\"Noch keine Einträge\" (it used to vanish)"],
 ["Long videos", "1:02:03 (it showed 62:03)"],
 ["Offline", "The last feed stays: \"Stand 15:02 Uhr\", pull to refresh"],
 ["Time", "Daylight-saving night, New Year, clock skew"]].forEach(([t, b], i) => {
  const x = 2.95 + (i % 2) * 3.3, y = 1.25 + Math.floor(i / 2) * 1.15;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w: 3.1, h: 1.0, rectRadius: 0.08, fill: { color: C.background2 }, line: { type: "none" }, objectName: `edge ${t}` });
  s.addText(t, { x: x + 0.15, y: y + 0.1, w: 2.8, h: 0.32, fontSize: 13, bold: true, color: C.text1, margin: 0, isTextBox: true });
  s.addText(b, { x: x + 0.15, y: y + 0.42, w: 2.8, h: 0.55, fontSize: 11, color: C.text2, margin: 0, valign: "top", isTextBox: true });
});
s.addText("Plus a seeded fuzz test: one feed item corrupted 300 ways, and every other item must still show.",
  { x: 2.95, y: 4.75, w: 6.55, h: 0.4, fontSize: 12, italic: true, color: C.accent1, margin: 0, isTextBox: true });

// 10. Beyond pixels
s = addSlide({ masterName: "Content", sectionTitle: S.edge });
s.addText("Beyond pixels: checks that can actually fail", { placeholder: "title" });
[["Accessibility audits on every screen", "Apple's audit on iOS, Google's ATF on Android. They found hidden tabs still reachable by VoiceOver: invisible in every screenshot."],
 ["Guards against green-but-empty tests", "Golden lint (blank images, iOS/Android name parity), a capture guard, fixture preconditions such as \"the premium teaser is premium\"."],
 ["Every guard is shown to fail first", "Google's Compose accessibility hook checked nothing under Robolectric: a broken button passed. It was replaced."]].forEach(([t, b], i) => {
  const y = 1.3 + i * 1.2;
  dot(s, i + 1, 0.5, y + 0.05, i === 2 ? C.accent2 : C.accent1);
  s.addText(t, { x: 1.1, y, w: 4.7, h: 0.38, fontSize: 15, bold: true, color: C.text1, margin: 0, isTextBox: true });
  s.addText(b, { x: 1.1, y: y + 0.38, w: 4.7, h: 0.75, fontSize: 12, color: C.text2, margin: 0, valign: "top", isTextBox: true });
});
phone(s, "ios_offline.png", 6.55, 1.2, 3.55, "Offline, cached feed");

// 11. CI
pres.addSection({ title: S.rollout });
s = addSlide({ masterName: "Content", sectionTitle: S.rollout });
s.addText("CI/CD: proven on GitHub Actions", { placeholder: "title" });
s.addText([
  { text: "When it runs", options: { bold: true, fontSize: 15, color: C.text1, breakLine: true } },
  ...bullets(["Every PR, on its merge result", "The merge queue", "Main, after merge", "Nightly, to catch toolchain drift"], 13),
], { x: 0.5, y: 1.3, w: 2.9, h: 2.4, color: C.text2, margin: 0, valign: "top", isTextBox: true });
stat(s, 0.5, 3.7, 1.4, "1–6 min", "Android", undefined, 22);
stat(s, 1.95, 3.7, 1.6, "12–19 min", "iOS, incl. UI tests", C.text1, 22);
card(s, 3.75, 1.3, 5.75, 3.7, "What real CI taught us",
  "• The pinned iOS 26.5 simulator wasn't on GitHub's Xcode 27 machines: re-pinned to 27.0 and re-recorded on CI, in one reviewed PR\n• A tool (xcodegen) wasn't on the runner: now installed, pinned\n• The first flaky UI test: fixed at the cause, with explicit waits; never retried\n• A Mac verifies the CI-recorded goldens: local equals CI\n• macOS minutes cost 10× on a private repo: run iOS only when iOS files change",
  { bodySize: 12 });

// 12. Rollout
s = addSlide({ masterName: "Content", sectionTitle: S.rollout });
s.addText("Rollout: about 4 sprints", { placeholder: "title" });
const hdr = (t) => ({ text: t, options: { bold: true, color: C.background1, fill: { color: C.text1 }, fontSize: 12 } });
const cell = (t, b) => ({ text: t, options: { color: C.text2, fontSize: 12, bold: !!b } });
s.addTable([
  [hdr("Sprint"), hdr("Step"), hdr("Exit criterion")],
  [cell("1", true), cell("One app, both platforms: support module, 5 design-system components, CI report-only"), cell("Green for 5 days, no flakes")],
  [cell("2", true), cell("Shared fixtures, feed and paywall states, diff gallery and PR comment; pair with each squad"), cell("Every squad merged one snapshot test")],
  [cell("3", true), cell("Gate required and in the Definition of Done; CI-only recording; nightly Layer 2"), cell("Under 10 min, flake rate under 1%")],
  [cell("4+", true), cell("The other three apps; accessibility snapshots; trial a hosted review tool"), cell("Visual bugs caught by the gate, not in release testing")],
], { x: 0.5, y: 1.25, w: 9, colW: [0.8, 5.2, 3.0], border: { type: "solid", pt: 0.5, color: "D5DAE3" }, fill: { color: C.background1 }, rowH: 0.5, margin: 0.08 });
s.addText([
  { text: "Ownership: ", options: { bold: true, color: C.text1 } },
  { text: "developers write and keep the tests; QA owns the strategy, the fixtures and the matrix rules; design approves goldens. AI may triage diffs, a human approves.", options: { color: C.text2 } },
], { x: 0.5, y: 4.3, w: 9, h: 0.75, fontSize: 13, margin: 0, valign: "top", isTextBox: true });

// 13. Close
s = addSlide({ masterName: "Title dark", sectionTitle: S.rollout });
s.addText("Takeaways", { placeholder: "title" });
s.addText([
  { text: "Frozen data makes every difference meaningful", options: { bullet: true, breakLine: true } },
  { text: "Same fixtures and names: one regression, the same failures on iOS and Android", options: { bullet: true, breakLine: true } },
  { text: "Machines compare; a person decides what's intended", options: { bullet: true, breakLine: true } },
  { text: "Questions?", options: { bold: true, color: C.background1, fontSize: 20 } },
], { placeholder: "body" });
phone(s, "ios_feed_xxxl.png", 5.9, 0.75, 3.9, "Largest text", C.accent6);
phone(s, "ios_feed_dark.png", 7.9, 0.75, 3.9, "Dark mode", C.accent6);

// ---------- notes + LIVE tags from content.js ----------
function noteText(c) {
  const lines = [`GOAL: ${c.goal}`, `TIME: about ${c.min} min`, "", "SAY:", c.say, ""];
  const steps = c.do.filter((d) => d[2] || d[0] !== "Slides");
  lines.push("DO (on screen):");
  if (!steps.length) lines.push("Stay on the slide.");
  steps.forEach((d, i) => {
    lines.push(`${i + 1}. [${d[0]}] ${d[1]}`);
    if (d[2]) lines.push(`   $ ${d[2]}`);
    if (d[3]) lines.push(`   You'll see: ${d[3]}`);
  });
  if (steps.length) lines.push(`${steps.length + 1}. Back to the slideshow.`);
  if (c.fallback) lines.push("", `IF IT FAILS: ${c.fallback}`);
  if (c.next) lines.push("", `NEXT (bridge sentence): "${c.next}"`);
  return lines.join("\n");
}
if (ALL.length !== CONTENT.length) throw new Error(`slides ${ALL.length} != content ${CONTENT.length}`);
ALL.forEach((sl, i) => {
  const c = CONTENT[i];
  sl.addNotes(noteText(c));
  if (c.live) {
    sl.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 7.45, y: 5.16, w: 1.45, h: 0.3, rectRadius: 0.15, fill: { color: C.accent2 }, line: { type: "none" }, objectName: "live tag" });
    sl.addText(`LIVE · ${c.live}`, { x: 7.45, y: 5.16, w: 1.45, h: 0.3, fontSize: 10, bold: true, color: C.background1, align: "center", valign: "middle", margin: 0, isTextBox: true });
  }
});

(async () => {
  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log("wrote " + OUT);
})();
