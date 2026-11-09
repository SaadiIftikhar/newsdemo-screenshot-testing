# NewsDemo: cross-platform screenshot testing with mocked data

A small news app, built natively on **iOS (SwiftUI)** and **Android (Compose)** with the same design, behaviour and test names:

- **Nachrichten** (feed):
  - breaking-news banner, live ticker (live and ended), teasers with and without images
  - **PLUS** (paywalled) teasers
  - video teaser, ad slot (and an ad that returned nothing, which collapses)
  - skeleton loading, empty, offline and error states
  - **offline with cached content:** the last feed stays, with "Stand 15:02 Uhr" and pull-to-refresh
  - **messy CMS text** cleaned identically on both platforms: `&amp;`, stray line breaks, emoji, soft hyphens
  - headlines are **real public WELT/BILD articles**; tapping one opens the publisher's page in-app
  - **PLUS articles open only for subscribers**; everyone else sees a paywall
- **Spiele** (games): Tic-Tac-Toe against the computer, a pairs card game, a 4×4 Mini-Sudoku.
- **Konto** (account): login with validation, two demo accounts (subscriber and basic), and the profile.
- A **floating 3-tab bar** above the content.

Every screen is covered by screenshot tests driven by **one shared set of JSON fixtures** (`/fixtures`).

| | iOS | Android |
|---|---|---|
| Screenshot tool | swift-snapshot-testing 1.19.7 | Roborazzi 1.77.0 on Robolectric 4.17 |
| Golden images | 89 | 89 (identical names, enforced by `make lint-goldens`) |
| Logic / contract / contrast / edge-case tests | 35 | 36 (same cases + an Arabic-locale digit test) |
| UI interaction tests | 9 (XCUITest, real app on the simulator) | 10 (Robolectric) |
| Accessibility audits (every screen) | 6 (`performAccessibilityAudit`) | 6 (Google ATF via Roborazzi) |
| `make` time (measured, after the first build) | about 30 s (+ about 2 min UI tests and audits) | about 20 s |

- **Strategy:** [STRATEGY.md](STRATEGY.md) (PDF: [STRATEGY.pdf](STRATEGY.pdf))
- **Walkthrough notes:** [WALKTHROUGH.md](WALKTHROUGH.md)
- **Prompts used:** [PROMPTS.md](PROMPTS.md)
- **Deliberate regression:** branch `demo/regression`, captured diffs in [docs/regression/](docs/regression/)

```
fixtures/            shared JSON + images  ← single source of truth for UI states (both platforms)
ios/NewsKit/         SPM package: NewsCore · NewsUI (feed, paywall) · Games · Account · AppShell · NewsFixtures
  Tests/NewsUISnapshotTests/__Snapshots__/   iOS goldens
ios/App, ios/UITests, project.yml            app shell + XCUITest (XcodeGen)
android/app/         Compose app: core/ · ui/ (feed, paywall, app shell) · games/ · account/
  src/test/screenshots/                      Android goldens
scripts/             pinned simulator, run helpers, diff report, golden lint, PDF export
.github/             CI workflow (lint / verify / record), CODEOWNERS for goldens
```

## 2-minute reviewer path (no Xcode beta needed)

Run these from the repository root. You need JDK 21 and the Android SDK platform 37 (`sdkmanager "platforms;android-37.0"`).

```bash
make android-test                                           # 89 screenshots + logic + interaction + accessibility: green
git checkout demo/regression && make android-test           # fails on 29 screenshots (PLUS badge dropped, banner −2pt)
open artifacts/android/diffs/index.html                     # golden | this change | changed pixels
git checkout main
```

## Prerequisites (everything)

| Platform | Needs |
|---|---|
| iOS | macOS with **Xcode 27** (currently a beta/preview release) and the iOS 26.5 simulator runtime. `make` creates the pinned "NewsDemo Snapshots" iPhone 17 simulator. `xcodegen` is needed for the app and UI tests |
| Android | JDK 21, Android SDK platform 37, `ANDROID_HOME` or `android/local.properties`. No emulator needed for tests |

Run everything from the repository root. `make help` lists all commands.

## Run the tests

```bash
make ios-test          # iOS screenshots (89) + logic/contract/contrast/edge-case tests
make ios-ui-test       # iOS UI interaction tests + accessibility audit on the real app (XCUITest)
make android-test      # Android screenshots (89) + logic/contract/edge-case + interaction + accessibility (ATF)
make lint-goldens      # no blank golden, and iOS/Android golden names must match
make gallery           # iOS vs Android side by side: open artifacts/side-by-side/index.html
```

## Regenerate goldens (only after an intended UI change)

```bash
make ios-record        # starts from an empty golden folder; record mode always reports "failed"
make android-record
make lint-goldens
git status             # review every changed or deleted PNG before committing
```

In a team setup only CI records goldens: add the `record-snapshots` label to a PR (see `.github/workflows/screenshots.yml`).

## The regression and the review workflow

```bash
git checkout demo/regression
make ios-test                          # fails: 29 screenshots
open artifacts/ios/diffs/index.html    # golden | this change | changed pixels (magenta = clear, orange = subtle)
cat artifacts/ios/diffs/summary.md     # each change classified: layout / visible / subtle (what CI posts on the PR)
make android-test                      # fails on the same 29
open artifacts/android/diffs/index.html
git checkout main                      # always switch back
```

Pre-captured output: [docs/regression/](docs/regression/).

## Run the apps (mock mode)

```bash
make ios-run                                  # (re)builds, boots the pinned simulator, opens it, launches (first time ~75 s)
make ios-run FIXTURE=feed_long_headlines      # feed_default | feed_long_headlines | feed_edge_cases | feed_hostile_content | feed_empty
make ios-run OFFLINE=1                        # offline state
make ios-run DROP_CONNECTION=1                # loads, then goes offline: pull down to see the cached-content notice
make ios-run TAB=games                        # start on Spiele (or TAB=account)
make ios-run TAB=account SIGNED_IN=1          # logged in as the PLUS subscriber
make android-run                              # same options; uses a plugged-in phone, a running emulator, or boots NewsDemo_API34
```

- **Demo logins** (password `demo1234` for both):
  - `demo@newsdemo.app`: PLUS subscriber, so PLUS articles open
  - `basis@newsdemo.app`: no subscription, so PLUS articles show the paywall
- **Xcode 27** replaced Simulator.app with **DeviceHub**; `ios-run` handles both.
- **Demo toggles:**
  - iOS: `xcrun simctl ui booted appearance dark`, `xcrun simctl ui booted content_size accessibility-extra-extra-extra-large`
  - Android: `adb shell cmd uimode night yes`, `adb shell settings put system font_scale 2.0`

## Content and licensing

- **Headlines and links:** real, from the public RSS feeds of welt.de and bild.de (fetched 2026-11-05).
- **Teaser sentences:** our own, and they only restate the headline.
- **Article text:** never copied. Tapping opens the publisher's own page.
- **Images, video durations, the paywall offer and prices:** demo placeholders.
- **Games:** generic public-domain classics written from scratch.

## Honest notes

- **Goldens were recorded on an Apple Silicon Mac.** Android goldens recorded on macOS can differ in font rasterisation from Linux CI, which is why only CI records (the strategy plans a Docker image for local parity).
- **The CI workflow has never run.** There is no remote yet; re-recording on CI also needs a `SNAPSHOT_BOT_TOKEN` secret.
- **Android tests run on Robolectric's SDK 36 runtime**, while the app compiles against and targets SDK 37. On the SDK 37 runtime most captures came out blank (STRATEGY, Appendix A).
- **Keep the Mac awake for long runs.** A laptop that sleeps mid-run turns green tests into timeouts. The `make` test targets wrap the runs in `caffeinate -i`.
- **Verified on this machine** (see STRATEGY §6 and Appendix A):
  - 10 consecutive full runs per platform, all green
  - both suites pass on `main` and fail on the same snapshots on `demo/regression`
  - every `make` command was run
  - both apps launch in every mode
