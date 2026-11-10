// Single source for the speaker notes, SCRIPT.md and COMMANDS.md.
// Each step in `do`: [window, action, command or null, what you will see / say].
const REPO = "SaadiIftikhar/newsdemo-screenshot-testing";
const GH = `https://github.com/${REPO}`;

const slides = [
  {
    n: 1, title: "Catching visual bugs before readers do", min: 1, live: null,
    goal: "Introduce yourself and set expectations: this is real and it runs.",
    say: `Hi, I'm Saad. Today I'll show how we can catch visual bugs in the BILD and WELT apps before a reader sees them, on iOS and Android, with screenshot tests that use mocked data.

Everything I show is real and runs: a small news app built natively on both platforms, the tests, and a CI pipeline I ran on GitHub. A few times I'll switch to the terminal to show it live.

The plan: the problem, the approach, a live regression, how we handle content that changes every minute, what CI taught me, and how I'd roll it out.`,
    do: [["Slides", "Start the slideshow on slide 1. Terminal, editor and browser are already open from the preparation (see COMMANDS.md, part 1).", null, null]],
    fallback: null,
    next: "Let's start with why this is hard.",
  },
  {
    n: 2, title: "The problem: too many states to check by hand", min: 1.5, live: null,
    goal: "Make them feel the problem; plant the PLUS-badge example you'll use in the demo.",
    say: `Four apps share one design system, on two platforms. A single news feed has dozens of visual states, and all of them depend on data from the backend: breaking news, live tickers, PLUS articles, ads, offline, dark mode, accessibility text sizes, very long German words.

Checking these by hand before every release doesn't scale. And the bugs that cost money are small. My example for today: a refactor that silently drops the PLUS badge. The screen still looks fine, so nobody notices. But paid articles now look free.

The demo alone has 89 states per platform.`,
    do: [["Slides", "Stay on the slide.", null, null]],
    fallback: null,
    next: "So machines should compare the pixels, and people should decide. Here's how.",
  },
  {
    n: 3, title: "The approach in one picture", min: 2, live: "Editor",
    goal: "They understand fixture → render → golden, and see that each is a real file.",
    say: `Three steps. One: shared JSON fixtures, frozen fake API data, the same files for iOS and Android. Two: the test renders the real production screen with that data, in memory. Three: it compares the picture with a "golden", an approved screenshot stored in git. Same picture: pass. Different: fail, with a diff image.

Because every input is frozen, a difference can only mean the code changed how the screen looks. Let me show you the three pieces.`,
    do: [
      ["Terminal", "Open the fixture: the fake API response.", "open -a \"Visual Studio Code\" fixtures/feed/feed_default.json", "Point at \"premium\": true on tsr-002: \"this is the PLUS article we'll break later\"."],
      ["Terminal", "Open the iOS test file.", "open -a \"Visual Studio Code\" ios/NewsKit/Tests/NewsUISnapshotTests/FeedScreenSnapshotTests.swift", "Point at func test_feed_default: one line renders the real FeedView with the fixture and compares it."],
      ["Terminal", "Open the iOS and Android goldens of that test.", "open ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__/FeedScreenSnapshotTests/test_feed_default.light.png android/app/src/test/screenshots/FeedScreenSnapshotTests/test_feed_default.light.png", "Two pictures in Preview: \"same test name, its own golden per platform\"."],
      ["Slides", "Close Preview and return to the slideshow.", null, null],
    ],
    fallback: "If an app doesn't open, show the folders in Finder instead: fixtures/feed and the two golden folders.",
    next: "Which tools draw these pictures?",
  },
  {
    n: 4, title: "Tooling: native, in-process, fast", min: 1.5, live: "Terminal",
    goal: "Justify the tool choice and show a real green run.",
    say: `On each platform I use the native tool. iOS: swift-snapshot-testing, which renders SwiftUI inside the test on a pinned simulator, and fits a TCA codebase. Android: Roborazzi on Robolectric, which runs on the Java runtime: no emulator, works with Hilt, and the same run does tap tests and accessibility checks.

Rejected for the pull-request gate: Paparazzi and Google's preview tool, both still alpha, and device-based tools with a paid service, which take minutes per screen. Those stay for a nightly run on real devices. Let me run the Android suite.`,
    do: [
      ["Terminal", "Run all Android screenshot, logic, interaction and accessibility tests.", "make android-test", "~20 s, ends with BUILD SUCCESSFUL: \"89 screenshots and 52 other tests, green\"."],
      ["Terminal", "(Optional) list every command.", "make help", "Each make target with a one-line description."],
    ],
    fallback: "If the build is slow, keep talking; iOS was already run during preparation (prepare.sh).",
    next: "Now, the question everyone asks about a news app.",
  },
  {
    n: 5, title: "Mocked data: content changes, goldens don't", min: 1.5, live: "Browser",
    goal: "Answer \"won't the goldens be outdated tomorrow?\" before they ask it.",
    say: `The content changes every minute, so won't the goldens be out of date tomorrow? No: a golden belongs to a fixture, not to live news. The fixture is frozen, and so is everything else: the clock, the German locale, the Berlin time zone, random numbers, animations, images. "vor 9 Min." stays "vor 9 Min." forever.

What really changes is the shape of the data, and that's tested without screenshots: contract tests, a fuzz test, hostile content. And this is the same fixture on iOS and Android.`,
    do: [
      ["Terminal", "Show where the clock, locale and time zone are pinned.", "open -a \"Visual Studio Code\" ios/NewsKit/Sources/NewsFixtures/FixtureStore.swift", "Point at FixtureEnvironment: now = 2026-11-05 14:13:20Z, de_DE, Europe/Berlin."],
      ["Terminal", "Open the iOS-vs-Android gallery (built during preparation).", "open artifacts/side-by-side/index.html", "Scroll to FeedScreenSnapshotTests: \"same data, each platform's own look\"."],
    ],
    fallback: "If the gallery is missing, run make gallery first (1 s).",
    next: "Now the part I care about most: does it catch a real bug?",
  },
  {
    n: 6, title: "Demo: a refactor drops the PLUS badge", min: 3, live: "Terminal",
    goal: "The core moment: a harmless-looking change is caught, on both platforms, in the same places.",
    say: `This branch contains a plausible refactor: "simplify the kicker row, tighten the banner". Two lines changed. It drops the PLUS badge and takes 2 points of padding off the breaking banner.

Watch the gate: 29 of 89 screenshots fail, and it's the same 29 on iOS and Android, because they share fixtures and test names. Every unaffected screen stays green. The report already classifies the changes: 10 layout changes, because the banner got shorter, and 19 visible ones.`,
    do: [
      ["Terminal", "Show how small the change is.", "git diff main demo/regression --stat", "2 files changed: \"looks harmless\"."],
      ["Terminal", "Switch to the branch with the bug.", "git checkout demo/regression", "Switched to branch 'demo/regression'."],
      ["Terminal", "Run the Android tests: they must fail.", "make android-test", "~20 s, fails: \"diff report: 29 failure(s)\"."],
      ["Terminal", "Open the diff page.", "open artifacts/android/diffs/index.html", "Scroll to ComponentSnapshotTests/test_teaserCard_premium.dark: golden with PLUS | new without | magenta = the missing badge."],
      ["Terminal", "Show the triage table (what the PR bot posts).", "cat artifacts/android/diffs/summary.md", "29 changed (layout: 10, visible: 19, subtle: 0)."],
      ["Terminal", "iOS fails on the same 29 (pre-captured; a live iOS run takes ~2 min).", "open examples/artifacts/ios/diffs/index.html", "Same teaserCard_premium diff on iOS."],
      ["Terminal", "ALWAYS switch back to the correct code.", "git checkout main", "Switched to branch 'main'."],
    ],
    fallback: "If anything goes wrong live: git checkout main, then open examples/artifacts/android/diffs/index.html (or docs/regression/). \"Here is the captured run.\"",
    next: "So the gate failed. What happens next is a human decision.",
  },
  {
    n: 7, title: "Review: machines compare, people decide", min: 1.5, live: "Browser",
    goal: "Show the decision path, and that it ran for real on GitHub.",
    say: `When a pull request fails, the bot posts one comment that lists the changed screens and what kind of change each is. A human opens the diff gallery and decides.

Not intended, like the badge: fix the code, the goldens stay. Intended, like a redesign: add the record-snapshots label. CI re-records the goldens on its fixed machine, proves them, and pushes them as a bot commit. Then a design or QA code owner approves the image diff. Goldens never come from a laptop, and approval is never automatic.`,
    do: [
      ["Browser", "Open PR #2: the blocked regression.", `open ${GH}/pull/2`, "Red iOS and Android checks; the bot comment with both tables (29 changed each)."],
      ["Browser", "Open PR #1: the intended re-record.", `open ${GH}/pull/1/commits`, "The snapshot-bot commits \"re-record iOS goldens\", then green checks."],
      ["Terminal", "Show who must approve golden changes.", "cat .github/CODEOWNERS", "Golden folders need design/QA review."],
    ],
    fallback: "Offline? Show docs/regression/ios/summary.md and say \"this is the comment the bot posts\".",
    next: "A fair question: how much difference do we allow?",
  },
  {
    n: 8, title: "How much difference is allowed?", min: 1.5, live: null,
    goal: "Show you thought about tolerance and human confirmation.",
    say: `Rendering noise is ignored. On iOS a perceptual precision absorbs GPU anti-aliasing. On Android I measured Mac against Linux: at most 2 out of 255 on 0.005% of pixels, inside the tolerance.

Anything beyond noise fails, however small. A 2-point shift and a missing badge are both small, and both are bugs: a pixel count can't tell intent. So the labels are triage, not approval. Tolerance is never loosened globally.`,
    do: [["Terminal", "(Optional, if asked) show the tolerance in code.", "open -a \"Visual Studio Code\" ios/NewsKit/Tests/NewsUISnapshotTests/SnapshotSupport.swift", "perceptualPrecision 0.98 (Android: changeThreshold = 0 in SnapshotSupport.kt)."]],
    fallback: null,
    next: "Knowing it's a news app, I added the edge cases real content produces.",
  },
  {
    n: 9, title: "Edge cases of a news app", min: 2, live: "Simulator",
    goal: "Show product thinking: real content is messy, and the app now handles it.",
    say: `Messy text from the content system, like ampersand entities and stray line breaks, is cleaned the same way on both platforms. Soft hyphens let long German words break properly. A live ticker before kick-off used to disappear; now it says "Noch keine Einträge". A one-hour video showed 62:03; now 1:02:03. Offline, the last feed stays with the time it was loaded. And dates: the daylight-saving night, New Year, clock skew.

Plus a fuzz test: one feed item corrupted 300 ways, and every other item must still show.`,
    do: [
      ["Terminal", "Open the app with the messy-content fixture.", "make ios-run FIXTURE=feed_hostile_content", "~15 s; in the simulator: clean headlines, \"Noch keine Einträge\", the 1:02:03 video."],
      ["Terminal", "Open the app in drop-connection mode.", "make ios-run DROP_CONNECTION=1", "Then in the simulator drag the feed down: \"Offline – gespeicherte Artikel · Stand 15:13 Uhr\" and the articles stay."],
    ],
    fallback: "If the simulator is slow, use the screenshots on this slide.",
    next: "Screenshots only see pixels. So I added checks that see more.",
  },
  {
    n: 10, title: "Beyond pixels: checks that can actually fail", min: 1.5, live: "Terminal",
    goal: "Show quality of the safety net: accessibility, and guards proven to work.",
    say: `Accessibility audits run on every screen: Apple's on iOS, Google's on Android. The iOS audit found hidden tabs that were still reachable by VoiceOver: invisible in every screenshot.

Early on, 44 Android goldens were blank and still passed, because blank equals blank. Now a lint rejects blank goldens and checks that both platforms have the same names. My rule: every guard must be shown to fail first. That caught Google's official accessibility hook, which silently checked nothing in our setup.`,
    do: [
      ["Terminal", "Run the golden lint.", "make lint-goldens", "\"checked 178 image(s), parity iOS ↔ Android\" in ~2 s."],
      ["Terminal", "(Optional) show the accessibility audit test.", "open -a \"Visual Studio Code\" ios/UITests/AccessibilityAuditTests.swift", "Accepted exceptions are documented with evidence. Don't run make ios-ui-test live (~5 min)."],
    ],
    fallback: null,
    next: "Finally: does this survive a real CI pipeline?",
  },
  {
    n: 11, title: "CI/CD: proven on GitHub Actions", min: 1.5, live: "Browser",
    goal: "Show it works beyond your laptop, and what real CI taught you.",
    say: `It runs on every pull request, on the merge queue, on main and nightly. Android takes 1 to 6 minutes, iOS 12 to 19 including the UI tests.

Real CI taught me things a laptop didn't. The simulator version I'd pinned didn't exist on GitHub's machines, so I re-pinned it and let CI re-record every iOS golden, in one reviewed PR. A tool was missing on the runner. And I got the first flaky test, racing an animation: I fixed the cause, no retries.`,
    do: [["Browser", "Open the Actions tab.", `open ${GH}/actions`, "The run history: red for the regression, green for the fixes; open one run to show job durations."]],
    fallback: "Offline? Use the numbers on the slide.",
    next: "How would I roll this out at BILD and WELT?",
  },
  {
    n: 12, title: "Rollout: about 4 sprints", min: 1.5, live: null,
    goal: "Show you can lead the change, not just build it.",
    say: `In about four sprints, without blocking feature work. Sprint 1: one app, both platforms, five design-system components, CI report-only. Sprint 2: shared fixtures, feed and paywall states, the diff gallery, and pairing with each squad. Sprint 3: the gate becomes required and part of the Definition of Done. Then the other three apps.

Developers write and maintain the tests, because they change the UI. QA owns the system around them: the strategy, the fixtures, the rules for what we test. Design approves goldens.`,
    do: [["Slides", "Stay on the slide.", null, null]],
    fallback: null,
    next: "To wrap up.",
  },
  {
    n: 13, title: "Takeaways", min: 0.5, live: null,
    goal: "Three sentences they'll remember, then questions.",
    say: `Frozen data makes every difference meaningful. Shared fixtures and test names mean one regression produces the same failures on both platforms. And machines compare, but a person decides what's intended.

Everything is in the repo: the strategy, the evidence, the regression demo and the CI runs. Happy to take questions.`,
    do: [
      ["Terminal", "Make sure you're back on main.", "git branch --show-current", "main"],
      ["Desktop", "Keep these ready for questions.", "open STRATEGY.pdf docs/EVIDENCE.md", "The 3-page strategy and the evidence file."],
    ],
    fallback: null,
    next: null,
  },
];

const prep = [
  { title: "Go to the project and make sure you're on the correct code", cmds: [
    ["cd ~/Desktop/Task", "Moves into the project folder. Every command runs from here."],
    ["git checkout main && git status", "Switches to the correct code and shows that nothing is half-edited (\"nothing to commit\")."],
  ]},
  { title: "Warm up both builds and confirm everything is green", cmds: [
    ["make ios-test", "Builds the iOS project and runs all iOS screenshot and logic tests (1–2 min). Must end with \"no snapshot failures\". Afterwards a live iOS run is quick."],
    ["make android-test", "Builds Android and runs all Android tests (~1 min the first time, ~20 s after). Must end with BUILD SUCCESSFUL."],
  ]},
  { title: "Warm up the regression demo (it fails on purpose)", cmds: [
    ["git checkout demo/regression && make android-test ; git checkout main", "Compiles the bug branch once, so the live demo takes 20 s instead of a minute. It fails on purpose; the last part switches back to main."],
  ]},
  { title: "Build the pages you will open", cmds: [
    ["make gallery", "Creates artifacts/side-by-side/index.html (iOS vs Android), used on slide 5."],
    ["ls examples/artifacts/ios/diffs/index.html", "Checks the pre-captured iOS diff page exists (slide 6). If it's missing, see examples/README.md to recreate it."],
  ]},
  { title: "Start the simulator and the app", cmds: [
    ["make ios-run", "Builds the app, boots the pinned simulator and opens it (first time ~1.5 min). After this, ios-run on slide 9 takes ~15 s."],
  ]},
  { title: "Open the windows you'll switch between", cmds: [
    [`open ${GH}/pull/2 ${GH}/pull/1 ${GH}/actions`, "Opens the three browser tabs for slides 7 and 11 (log in to GitHub first)."],
    ["open -a \"Visual Studio Code\" .", "Opens the project in VS Code, so files open instantly on slides 3 and 5."],
    ["open presentation/Screenshot-Testing-Presentation.pptx", "Opens the deck in PowerPoint."],
  ]},
];

module.exports = { slides, prep, GH };
