# Evidence behind the strategy

Supporting material for [STRATEGY.md](../STRATEGY.md): what building and running the demo actually found, and the objections the strategy was tested against.

## A. What building the demo found

**Product bugs caught before any deliberate regression:**
- the banner timestamp was grey on red
- the kicker was truncated, and "EILMEL-DUNG" hyphenated, at large text sizes
- Android didn't hyphenate German headlines while iOS did (found by comparing the same fixture across platforms)
- a 60-letter compound word breaks mid-word on both platforms. This is a **content** finding: the fix is soft hyphens from the CMS
- an e-mail placeholder rendered as a Markdown link
- "11:05 PM Uhr" on an en_US device (found by Layer 2)

**Found by the edge-case and accessibility round:**
- a video over one hour showed "62:03"
- Android used the device locale for durations, so an Arabic phone would show non-Latin digits
- a live ticker without entries was dropped from the feed
- raw `&amp;` and line breaks from the CMS would reach the screen
- a fixture image without `.png` loaded on iOS but not on Android (the image contract now checks exact file names)
- **hidden tabs were still reachable by VoiceOver** (found by the iOS audit); the sign-out button failed contrast
- after a failed refresh, Android inserted the offline notice just above the visible list, so readers never saw it (found by the pull-to-refresh interaction test)
- Google's official Compose accessibility hook silently checks nothing under Robolectric: a deliberately broken button passed. A guard that can't fail protects nothing, so every new check was first shown to fail.

**Tooling incidents, each now guarded against:**
- 44 of 62 Android goldens blank but green (capture guard and golden lint)
- a transitive Espresso crash on SDK 37 (pinned test dependencies)
- the Liquid Glass tab bar can't be captured in-process (custom bar in the demo; Layer 2 in production)
- tall components clipped by the harness
- stale diff files shown to reviewers (cleared before every run)
- a stale app build launched by the run script (project-local build, always rebuilt)
- the pinned simulator runtime vanished mid-session (re-pin plus re-baseline in one commit)
- the first CI run failed before any test: the pinned iOS runtime was not on the CI image, and the fallback silently installed a different one (now: pin a runtime that exists on both, fetch exactly that version or fail)
- `xcodegen` is not on the GitHub macOS image, so the UI tests could not even start on CI (now installed, pinned to the version the dev Macs use)
- the diff report needs CoreGraphics, which Linux does not have, so Android failures on CI had no gallery or summary (now built by a short macOS job from the Android job's images)
- the bot's golden commit, pushed with the default CI token, does not start a new run by design (a repo-scoped `SNAPSHOT_BOT_TOKEN` fixes it)

**Five role-based reviews**, by a product manager, a senior developer, a senior QA, an accessibility/design reviewer and a hiring-panel reviewer, found:
- the missing paywall/entitlement states
- decoding differences between the platforms
- Android losing state on tab switches and rotation
- Android dark-mode buttons that were purple on red (about 2.3:1) in *approved* goldens
- undersized iOS game boards
- low-contrast secondary text
- CI record-mode gaps

All are fixed and covered by tests. **Deliberate regression** (PLUS badge dropped, banner −2pt), on GitHub Actions (PR #2): the **same 29 of 89** snapshots fail on both platforms, with the same triage (10 layout, 19 visible), including a real WELTplus teaser silently losing its paywall badge. Every unaffected screen (games, account, paywall) stays green.

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
