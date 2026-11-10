// Single source for the deck's speaker notes and the three presentation pages.
// do-steps: [where, what, command | null, what you'll see | null]
const REPO = "SaadiIftikhar/newsdemo-screenshot-testing";
const GH = `https://github.com/${REPO}`;
const PR_REGRESSION = `${GH}/pull/1`;
const PR_REDESIGN = `${GH}/pull/2`;
const VSC = 'open -a "Visual Studio Code"';

const slides = [
  {
    n: 1, title: "Catching visual bugs before readers do", min: 1, live: null,
    goal: "Introduce yourself and set expectations: this is real and it runs.",
    say: `Hi, I'm Saad. Today I'll show how we can catch visual bugs in the BILD and WELT apps before a reader sees them, using screenshot tests with mocked data.

Everything I show is real and runs: a small news app in SwiftUI, its tests, and a CI pipeline on GitHub. I built it for iOS end to end; at the end I'll show how Android does exactly the same. A few times I'll switch to the terminal to show it live.`,
    do: [],
    next: "Let's start with why this is hard.",
  },
  {
    n: 2, title: "The problem: too many states to check by hand", min: 1.5, live: null,
    goal: "Make them feel the problem; plant the PLUS-badge example you'll use in the demo.",
    say: `Four apps share one design system, on two platforms. A single news feed has dozens of visual states, and all of them depend on data from the backend: breaking news, live tickers, PLUS articles, ads, offline, dark mode, accessibility text sizes, very long German words.

Checking these by hand before every release doesn't scale. And the bugs that cost money are small. My example for today: a refactor that silently drops the PLUS badge. The screen still looks fine, so nobody notices. But paid articles now look free.`,
    do: [],
    next: "So machines should compare the pixels, and people should decide. Here's how.",
  },
  {
    n: 3, title: "The approach in one picture", min: 2, live: "Editor",
    goal: "They understand fixture → render → golden, and see that each is a real file.",
    say: `Three steps. One: JSON fixtures, frozen fake API data. Two: the test renders the real production screen with that data, in memory. Three: it compares the picture with a "golden", an approved screenshot stored in git. Same picture: pass. Different: fail, with a diff image.

Because every input is frozen, a difference can only mean the code changed how the screen looks. Let me show you the three pieces.`,
    do: [
      ["Finder", "Show the folder with the fake data.", "open fixtures/feed", "The JSON files: feed_default, feed_edge_cases, feed_hostile_content…"],
      ["VS Code", "Open the default fixture.", `${VSC} fixtures/feed/feed_default.json`, "Point at \"premium\": true on tsr-002: \"this is the PLUS article we'll break later\"."],
      ["VS Code", "Open the screenshot test.", `${VSC} ios/NewsKit/Tests/NewsUISnapshotTests/FeedScreenSnapshotTests.swift`, "func test_feed_default: one line renders the real feed with the fixture and compares it."],
      ["Finder", "Show the goldens folder.", "open ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__/FeedScreenSnapshotTests", "One PNG per test and variant: test_feed_default.light.png, .dark.png, .light_xxxl.png…"],
      ["Preview", "Open that golden.", "open ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__/FeedScreenSnapshotTests/test_feed_default.light.png", "\"This is the approved picture every run is compared with.\""],
    ],
    fallback: "If an app doesn't open, describe the three folders; they're on the slide.",
    next: "Which tool draws these pictures?",
  },
  {
    n: 4, title: "Tooling: native, in-process, fast", min: 1.5, live: "Terminal",
    goal: "Justify the tool choice and show a real green run.",
    say: `On iOS I use swift-snapshot-testing from Point-Free: it renders SwiftUI inside the test on a pinned simulator, and since BILD and WELT probably use TCA, mocking reuses its dependency system. On Android the same role goes to Roborazzi on Robolectric: no emulator, works with Hilt.

Rejected for the pull-request gate: Paparazzi and Google's preview tool, both alpha, and device-based tools with a paid service, which take minutes per screen. Those stay for a nightly run on real devices. Let me run the whole iOS suite.`,
    do: [
      ["Terminal", "Run all screenshot and logic tests.", "make ios-test", "~40–60 s (start it, keep talking), ends with \"no snapshot failures\": 89 screenshots and 35 logic tests, green."],
      ["Terminal", "(Optional) list every command.", "make help", "Each make target with a one-line description."],
    ],
    fallback: "If it's slow, keep talking about the tools; prepare.sh already ran it green.",
    next: "Now, the question everyone asks about a news app.",
  },
  {
    n: 5, title: "Mocked data: content changes, goldens don't", min: 1.5, live: "Browser",
    goal: "Answer \"won't the goldens be outdated tomorrow?\" before they ask it.",
    say: `The content changes every minute, so won't the goldens be out of date tomorrow? No: a golden belongs to a fixture, not to live news. The fixture is frozen, and so is everything else: the clock, the German locale, the Berlin time zone, random numbers, animations, images. "vor 9 Min." stays "vor 9 Min." forever.

What really changes is the shape of the data, and that's tested without screenshots: contract tests, a fuzz test, hostile content. Here are all 89 approved states.`,
    do: [
      ["VS Code", "Show where the clock, locale and time zone are pinned.", `${VSC} ios/NewsKit/Sources/NewsFixtures/FixtureStore.swift`, "FixtureEnvironment: now = 2026-11-05 14:13:20Z, de_DE, Europe/Berlin."],
      ["Browser", "Open the gallery of every golden (built by prepare.sh).", "open artifacts/gallery/index.html", "All 89 screenshots, grouped by test; light, dark and largest text side by side."],
    ],
    fallback: "If the gallery is missing: make gallery (1 s), then open it again.",
    next: "Now the part I care about most: does it catch a real bug?",
  },
  {
    n: 6, title: "Demo: a refactor drops the PLUS badge", min: 3, live: "Terminal",
    goal: "The core moment: a harmless-looking change is caught.",
    say: `This branch contains a plausible refactor: "simplify the kicker row, tighten the banner". One file, a few lines. It drops the PLUS badge and takes 2 points of padding off the breaking banner.

[While the tests run, ~1 min:] This is supposed to fail. Every screen that shows a PLUS teaser or the banner should go red; everything else should stay green.

29 of 89 screenshots fail. Every unaffected screen stays green: games, account, the paywall itself. And the report already says what kind of change each one is: 10 layout changes, because the banner got shorter, and 19 visible ones.`,
    do: [
      ["Terminal", "Show how small the change is.", "git diff main demo/regression --stat", "1 file changed: \"looks harmless\"."],
      ["Terminal", "Switch to the branch with the bug.", "git checkout demo/regression", "Switched to branch 'demo/regression'."],
      ["Terminal", "Run the tests: they must fail.", "make ios-test", "~1 min, fails: \"diff report: 29 failure(s)\"."],
      ["Browser", "Open the diff page.", "open artifacts/ios/diffs/index.html", "Scroll to ComponentSnapshotTests/test_teaserCard_premium.dark: golden with PLUS | new without | magenta = the missing badge."],
      ["Terminal", "Show the triage table (what the PR bot posts).", "cat artifacts/ios/diffs/summary.md", "29 changed (layout: 10, visible: 19, subtle: 0)."],
      ["Terminal", "ALWAYS switch back to the correct code.", "git checkout main", "Switched to branch 'main'."],
    ],
    fallback: "If anything goes wrong live: git checkout main, then open docs/regression (the captured CI result). \"Here's the captured run.\"",
    next: "So the gate failed. What happens next is a human decision.",
  },
  {
    n: 7, title: "Review: machines compare, people decide", min: 1.5, live: "Browser",
    goal: "Show the decision path, and that it ran for real on GitHub.",
    say: `When a pull request fails, the bot posts one comment that lists the changed screens and what kind of change each is. A human opens the diff gallery and decides.

Not intended, like the badge: fix the code, the goldens stay. That's this pull request: blocked. Intended, like a redesign: add the record-snapshots label. CI re-records the goldens on its fixed machine, proves them, and pushes them as a bot commit; a design or QA code owner approves the image diff. That's this second pull request. Goldens never come from a laptop, and approval is never automatic.`,
    do: [
      ["Browser", "The regression pull request: blocked.", `open ${PR_REGRESSION}`, "Red check; the bot comment with the triage table (29 changed)."],
      ["Browser", "The intended redesign: re-recorded by CI.", `open ${PR_REDESIGN}/commits`, "A \"snapshot-bot\" commit: \"re-record iOS goldens\"; then green checks."],
      ["Terminal", "Who must approve golden changes.", "cat .github/CODEOWNERS", "Golden folders need design/QA review."],
    ],
    fallback: "Offline? open docs/regression/summary.md: \"this is the comment the bot posts\".",
    next: "A fair question: how much difference do we allow?",
  },
  {
    n: 8, title: "How much difference is allowed?", min: 1.5, live: null,
    goal: "Show you thought about tolerance and human confirmation.",
    say: `Rendering noise is ignored: a perceptual precision of 0.98 absorbs GPU anti-aliasing. Anything beyond noise fails, however small. A 2-point shift and a missing badge are both small, and both are bugs: a pixel count can't tell intent.

So the labels are triage, not approval. Tolerance is never loosened globally; a per-test exception needs a comment and a review.`,
    do: [["VS Code", "(Optional, if asked) the tolerance in code.", `${VSC} ios/NewsKit/Tests/NewsUISnapshotTests/SnapshotSupport.swift`, "perceptualPrecision: 0.98, and why, in the comment."]],
    next: "Knowing it's a news app, I added the edge cases real content produces.",
  },
  {
    n: 9, title: "Edge cases of a news app", min: 2, live: "Simulator",
    goal: "Show product thinking: real content is messy, and the app now handles it.",
    say: `Messy text from the content system, like ampersand entities and stray line breaks, is cleaned before it reaches the screen. Soft hyphens let long German words break properly. A live ticker before kick-off used to disappear; now it says "Noch keine Einträge". A one-hour video showed 62:03; now 1:02:03. Offline, the last feed stays with the time it was loaded. And dates: the daylight-saving night, New Year, clock skew.

Plus a fuzz test: one feed item corrupted 300 ways, and every other item must still show.`,
    do: [
      ["VS Code", "The messy fixture.", `${VSC} fixtures/feed/feed_hostile_content.json`, "&amp;, line breaks inside headlines, \"durationSeconds\": 3723."],
      ["Simulator", "The app with that fixture.", "make ios-run FIXTURE=feed_hostile_content", "~15 s: clean headlines, \"Noch keine Einträge\", the 1:02:03 video."],
      ["Simulator", "Offline after the first load.", "make ios-run DROP_CONNECTION=1", "Drag the feed down: \"Offline – gespeicherte Artikel · Stand 15:13 Uhr\", articles stay."],
    ],
    fallback: "If the simulator is slow, use the screenshots on this slide.",
    next: "Screenshots only see pixels. So I added checks that see more.",
  },
  {
    n: 10, title: "Beyond pixels: checks that can actually fail", min: 1.5, live: "Terminal",
    goal: "Show the quality of the safety net.",
    say: `Accessibility: Apple's audit runs on every screen. It found hidden tabs that VoiceOver could still reach: invisible in every screenshot.

Guards against tests that pass while protecting nothing: a lint rejects blank goldens, and fixture checks make sure "the premium teaser" really is premium. My rule: every guard must be shown to fail first. On the Android version, that caught an official accessibility hook that silently checked nothing.`,
    do: [
      ["Terminal", "Run the golden lint.", "make lint-goldens", "\"checked 89 image(s)\" in ~2 s."],
      ["VS Code", "(Optional) the accessibility audit test.", `${VSC} ios/UITests/AccessibilityAuditTests.swift`, "Every accepted exception is documented with evidence. Don't run make ios-ui-test live (~5 min)."],
    ],
    next: "Does this survive a real CI pipeline?",
  },
  {
    n: 11, title: "CI/CD: proven on GitHub Actions", min: 1.5, live: "Browser",
    goal: "Show it works beyond your laptop, and what real CI taught you.",
    say: `It runs on every pull request on its merge result, on the merge queue and on main. A full iOS run, snapshots plus UI tests and the accessibility audit, takes 12 to 19 minutes.

Real CI taught me things a laptop didn't. The simulator version I'd pinned didn't exist on GitHub's machines, so I re-pinned it and let CI re-record every golden, in one reviewed pull request. A tool was missing on the runner. And I got the first flaky test, racing an animation: I fixed the cause, no retries.`,
    do: [["Browser", "The Actions tab.", `open ${GH}/actions`, "The run history: red for the regression, green for main; open a run to show its steps."]],
    fallback: "Offline? Use the numbers on the slide.",
    next: "How would I roll this out at BILD and WELT?",
  },
  {
    n: 12, title: "Rollout: about 4 sprints", min: 1.5, live: null,
    goal: "Show you can lead the change, not just build it.",
    say: `In about four sprints, without blocking feature work. Sprint 1: one app, both platforms, five design-system components, CI report-only. Sprint 2: shared fixtures, feed and paywall states, the diff gallery, and pairing with each squad. Sprint 3: the gate becomes required and part of the Definition of Done. Then the other three apps.

Developers write and maintain the tests, because they change the UI. QA owns the system around them: the strategy, the fixtures, the rules for what we test. Design approves goldens.`,
    do: [],
    next: "And Android? Exactly the same idea.",
  },
  {
    n: 13, title: "Android: the same approach", min: 1.5, live: null,
    goal: "Show the design transfers 1:1 to Android, and that you've done it.",
    say: `Everything I showed works on Android with the same pieces. Android reads the same fixture files with its own decoder and asserts the same contracts, and the tests use the same names, so one regression fails in the same places on both platforms.

The tool is Roborazzi on Robolectric: Compose rendered on the JVM, no emulator. I built that version first: the same 89 screenshots ran in about 20 seconds, and it found real bugs, like a decoder difference that made a PLUS article free on Android. I cut it from the demo to keep today focused.`,
    do: [],
    next: "To wrap up.",
  },
  {
    n: 14, title: "Takeaways", min: 0.5, live: null,
    goal: "Three sentences they'll remember, then questions.",
    say: `Frozen data makes every difference meaningful. Machines compare, but a person decides what's intended. And the same fixtures carry the approach to Android.

Everything is in the repo: the strategy, the evidence, the regression and the CI runs. Happy to take questions.`,
    do: [
      ["Terminal", "Make sure you're back on main.", "git branch --show-current", "main"],
      ["Preview", "Keep the strategy ready for questions.", "open STRATEGY.pdf", "The 3-page strategy."],
    ],
    next: null,
  },
];

const prep = [
  { title: "Go to the project, on the correct code", cmds: [
    ["cd ~/Desktop/Task", "Moves into the project folder. Every other command runs from here."],
    ["git checkout main && git pull", "Switches to the correct code and fetches the latest version from GitHub."],
    ["git status", "Should say \"nothing to commit, working tree clean\"."],
  ]},
  { title: "Warm up the build and confirm everything is green", cmds: [
    ["make ios-test", "Builds the project and runs all screenshot and logic tests (1–2 min the first time). Must end with \"no snapshot failures\". After this, the live run on slide 4 takes ~40 s."],
  ]},
  { title: "Warm up the regression demo (it fails on purpose)", cmds: [
    ["git checkout demo/regression && make ios-test ; git checkout main", "Builds the bug branch once, so the live demo on slide 6 is quick. It fails on purpose (29 failures); the last part switches back to main."],
  ]},
  { title: "Build the page you'll open on slide 5", cmds: [
    ["make gallery", "Creates artifacts/gallery/index.html: every golden on one page."],
  ]},
  { title: "Start the simulator with the app", cmds: [
    ["make ios-run", "Builds the app, boots the pinned simulator and opens it (first time ~1.5 min). After this, ios-run on slide 9 takes ~15 s."],
  ]},
  { title: "Open the windows you'll switch between", cmds: [
    [`${VSC} .`, "Opens the project in VS Code, so files open instantly during the talk."],
    [`open ${PR_REGRESSION} ${PR_REDESIGN} ${GH}/actions`, "Opens the browser tabs for slides 7 and 11."],
    ["open presentation/Presentation.pptx", "Opens the deck in PowerPoint."],
  ]},
];

module.exports = { slides, prep, GH, PR_REGRESSION, PR_REDESIGN, VSC };
