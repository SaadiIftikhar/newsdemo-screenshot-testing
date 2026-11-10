# Evidence behind the strategy

Supporting material for [STRATEGY.md](../STRATEGY.md): what building and running the demo actually found, and the objections the strategy was tested against.

## A. What building the demo found

**Product bugs caught before any deliberate regression:**
- the banner timestamp was grey on red
- the kicker was truncated, and "EILMEL-DUNG" hyphenated, at large text sizes
- a 60-letter compound word breaks mid-word. This is a **content** finding: the fix is soft hyphens from the CMS
- an e-mail placeholder rendered as a Markdown link
- "11:05 PM Uhr" on an en_US device (found by running the real app, i.e. Layer 2, not by snapshots)

**Found by the edge-case and accessibility round:**
- a video over one hour showed "62:03"
- a live ticker without entries was dropped from the feed
- raw `&amp;` and line breaks from the CMS would reach the screen
- a fixture image without `.png` loaded only because `UIImage(contentsOfFile:)` guesses the extension (the image contract now checks exact file names)
- **hidden tabs were still reachable by VoiceOver** (found by Apple's accessibility audit, invisible in every screenshot); the sign-out button failed contrast

**Tooling incidents, each now guarded against:**
- the Liquid Glass tab bar can't be captured in-process (custom bar in the demo; Layer 2 in production)
- tall components clipped by the harness
- stale diff files shown to reviewers (cleared before every run)
- a stale app build launched by the run script (project-local build, always rebuilt)
- the pinned simulator runtime vanished mid-session (re-pin plus re-baseline in one commit)
- the first CI run failed before any test: the pinned iOS runtime was not on the CI image, and the fallback silently installed a different one (now: pin a runtime that exists on both, fetch exactly that version or fail)
- `xcodegen` is not on the GitHub macOS image, so the UI tests could not even start on CI (now installed, pinned to the version the dev Macs use)
- the bot's golden commit, pushed with the default CI token, does not start a new run by design (a repo-scoped `SNAPSHOT_BOT_TOKEN` fixes it)
- **the first CI flake:** a paywall UI test passed on one run and failed on the next with no iOS change. It tapped and asserted without waiting, which a laptop tolerates and a slower runner does not. Fixed at the root (explicit waits, a polling wait for the selected tab), not retried; failing UI runs now upload their result bundle

**Five role-based reviews**, by a product manager, a senior developer, a senior QA, an accessibility/design reviewer and a hiring-panel reviewer, found the missing paywall/entitlement states, decoding gaps, undersized game boards, low-contrast secondary text and CI record-mode gaps. All are fixed and covered by tests.

**Deliberate regression** (PLUS badge dropped, banner −2pt), on GitHub Actions: **29 of 89** snapshots fail, triaged as 10 layout and 19 visible changes, including a real WELTplus teaser silently losing its paywall badge. Every unaffected screen (games, account, paywall) stays green. See [docs/regression/](regression/).

### From the earlier Android version of the demo

The demo first shipped on both platforms (Compose + Roborazzi on Robolectric, same fixtures and test names) and was then cut to iOS to keep the presentation focused. What the Android side taught, which §10 of the strategy builds on:
- **Shared fixtures made the platforms comparable:** the same regression failed the same 29 snapshots on iOS and Android, and comparing them exposed real differences: Android didn't hyphenate German headlines, its decoder treated a missing `premium` as free while iOS dropped the whole feed, and it lost game state on tab switches and rotation.
- **A green test can protect nothing:** after a Robolectric SDK upgrade, 44 of 62 Android goldens were blank and still passed (blank equals blank). Hence the capture guard and the golden lint.
- **Approved goldens hid a contrast bug:** dark-mode buttons were purple on red (about 2.3:1). Hence the token contrast tests.
- **Every check must be shown to fail:** Google's official Compose accessibility hook silently checked nothing under Robolectric; a deliberately broken button passed, so it was replaced by Roborazzi's ATF integration.
- **Hostile device settings:** Android formatted durations with the device locale, so an Arabic phone would have shown non-Latin digits.
- **Mac vs Linux:** Mac- and Linux-rendered goldens differed on 0.005% of pixels by at most 2/255, inside the tolerance, so goldens were portable between developer Macs and Linux CI.

## B. Devil's advocate

| Objection | Answer |
|---|---|
| "Reviewers will approve diffs without looking." | Small focused snapshots, code-owner approval, stale approvals dismissed, and the diff is in the PR |
| "In-process rendering isn't the real app." | True. That's Layer 2's job (system chrome, devices, hostile settings) |
| "Every OS or Xcode upgrade changes every golden." | Yes, as a planned re-baseline PR per upgrade |
| "Too many combinations." | Curated matrix rules, affected-modules-only runs, quarterly pruning |
| "Roborazzi is largely one maintainer." | Exact pinning, and thin test code over portable fixtures: switching to Paparazzi is cheap |
| "QA should own the tests." | Developers own them. QA owns the system around them |
| "Can AI approve diffs?" | AI triages (summarises diffs, generates edge-case fixtures). A human approves goldens |
