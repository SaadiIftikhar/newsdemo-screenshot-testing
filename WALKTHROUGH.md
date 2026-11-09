# Walkthrough (3–5 minutes)

The reasoning, in the order I would demo it. Every claim points to something in this repo you can open or run.

## 1. The problem, in one sentence (20 s)

A news feed has dozens of visual states: breaking, live, PLUS, ads, offline, dark mode, huge text, long German words. They depend on backend data, so checking them by hand on two platforms before every release doesn't scale.

## 2. The approach (60 s): STRATEGY.md §1–§3

- **One fixture set for both platforms.** `/fixtures` holds the API responses. iOS and Android decode the *same files* with their production decoders, so one fixture is one UI state on both. Even the golden file names are identical (`make lint-goldens` enforces it).
- **Native, in-process snapshots as the PR gate:**
  - iOS: swift-snapshot-testing
  - Android: Roborazzi on Robolectric
  - Fast (about 30 s and 12 s of test time), no emulator, deterministic: fixed clock, locale, time zone, seeded randomness, no animations, no network images.
- **What snapshots can't see goes to a nightly layer:** system chrome, real devices, hostile device settings.

## 3. Show it working (60 s)

```bash
make ios-test && make android-test     # 89 screenshots per platform + logic, contract, contrast and UI interaction tests
make ios-run TAB=games                 # the real app, starting on any state
```

## 4. Show it catching a regression (60 s): `docs/regression/`

```bash
git checkout demo/regression           # a plausible "refactor": PLUS badge dropped, banner padding −2pt
make ios-test                          # fails; artifacts/ios/diffs/index.html shows golden | change | pixels
make android-test                      # fails on the same screenshots
git checkout main
```

The two platforms fail on **exactly the same screenshots**, and every unaffected screen stays green. The review flow:
- **Unintended:** fix the code.
- **Intended:** add the `record-snapshots` label. CI re-records, proves the new goldens, and pushes them. A design/QA code owner approves the golden diff.

## 5. What I learned from building it (60 s): STRATEGY.md Appendix A

- **A green test can protect nothing.** After an SDK upgrade, 44 of 62 Android goldens were blank, and verify still passed (blank equals blank). There is now a capture guard plus a golden lint in CI.
- **Approved goldens still hid contrast bugs.** One was purple-on-red buttons in Android dark mode. WCAG contrast tests on the colour tokens now run on both platforms.
- **Pinning the environment proves stability, not correctness.** The "11:05 PM Uhr" bug only showed on a real device with US settings. That's why Layer 2 exists.
- **Five role-based reviews** (PM, developer, QA, accessibility, hiring panel) found the paywall gap, data-decoding differences between the platforms, and lost-state bugs. All of them are fixed and covered by tests now.

## 5b. Content that changes every minute (45 s): STRATEGY.md §2

- **Goldens are tied to fixtures, not to live news**, so they never go stale. Timestamps are relative to a pinned clock.
- **What actually changes, the shape of the data, is tested without goldens:** a shared hostile-content fixture (`&amp;`, line breaks, emoji, a 1:02:03 video), a seeded fuzz test (one corrupted item must never hide the others), and date boundaries (DST, New Year, clock skew).
- **Offline is a state too:** `make ios-run DROP_CONNECTION=1`, then pull down. The last feed stays, with "Stand 15:02 Uhr".
- **Accessibility audits on every screen** found that hidden tabs were still reachable by VoiceOver: invisible in every screenshot.

## 6. How I'd roll it out at BILD/WELT (30 s): STRATEGY.md §7–§9

- **Sprint 1:** design-system components, report-only.
- **Sprint 2:** shared fixtures package, plus pairing with each squad.
- **Sprint 3:** the gate becomes required and part of the Definition of Done.
- **Developers own the tests.** QA owns the system around them: fixtures, matrix rules and coaching. Design owns golden approval.
