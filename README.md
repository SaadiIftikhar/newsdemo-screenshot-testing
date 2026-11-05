# NewsDemo: cross-platform screenshot testing with mocked data

A small news app, built natively on **iOS (SwiftUI)** and **Android (Compose)** with the same design, behaviour and test names:

- **Nachrichten** (feed): breaking-news banner, live ticker, teasers with and without images, a paywalled **PLUS** teaser, video teaser, ad slot, and empty/offline/error states. Headlines are **real public WELT/BILD articles**; tapping one opens the publisher's page in-app (SFSafariViewController / Custom Tabs).
- **Spiele** (games): Tic-Tac-Toe against the computer, a pairs card game, and a 4×4 Mini-Sudoku.
- **Konto** (account): login with validation against an offline demo backend, plus the signed-in profile.
- A **floating 3-tab bar** that hovers above the content.

Every screen is covered by screenshot tests driven by **one shared set of JSON fixtures** (`/fixtures`).

| | iOS | Android |
|---|---|---|
| Screenshot tool | swift-snapshot-testing 1.19.7 | Roborazzi 1.77.0 on Robolectric 4.17 |
| Golden images | 62 | 62 (identical names) |
| Other tests | 16 logic/contract tests | 16 logic/contract tests + 5 UI interaction tests |
| Runtime | about 20 s after build | about 30 s after build |

- **Strategy:** [STRATEGY.md](STRATEGY.md) (PDF: [STRATEGY.pdf](STRATEGY.pdf))
- **Prompts used:** [PROMPTS.md](PROMPTS.md)
- **Deliberate regression:** branch `demo/regression`, captured diffs in [docs/regression/](docs/regression/)

```
fixtures/            shared JSON + images  ← single source of truth for UI states (both platforms)
ios/NewsKit/         SPM package: NewsCore · NewsUI (feed) · Games · Account · AppShell (tabs) · NewsFixtures
  Tests/NewsUISnapshotTests/__Snapshots__/   iOS goldens
ios/App/, project.yml  thin app shell (XcodeGen); launch args pick fixture/offline/tab/login
android/app/         Compose app: core/ · ui/ (feed, app shell) · games/ · account/
  src/test/screenshots/                      Android goldens
scripts/             pinned simulator, run helpers, diff report, golden lint, PDF export
.github/             CI workflow (lint / verify / record), CODEOWNERS for goldens
```

## Prerequisites

| Platform | Needs |
|---|---|
| iOS | macOS, Xcode 27.x, iOS 26.5 simulator runtime. `make` creates the pinned "NewsDemo Snapshots" iPhone 17 simulator. `xcodegen` is needed only to build the app |
| Android | JDK 21, Android SDK platform 37 (`sdkmanager "platforms;android-37.0"`), `ANDROID_HOME` or `android/local.properties`. No emulator needed for tests |

Run everything from the repository root (`cd ~/Desktop/Task`). `make help` lists all commands.

## Run the tests

```bash
make ios-test          # verify iOS: 50 tests, 62 screenshots
make android-test      # verify Android: 83 tests, 62 screenshots
make lint-goldens      # fail if any golden image is blank (see STRATEGY §5)
```

## Regenerate goldens

```bash
make ios-record        # re-record all iOS goldens (record mode always reports "failed"; that's expected)
make android-record    # re-record all Android goldens
make lint-goldens      # never commit a blank golden
git status             # review every changed PNG before committing
```

In a team setup, goldens are recorded only by CI: add the `record-snapshots` label to a PR (see `.github/workflows/screenshots.yml`).

## See the regression and the review workflow

```bash
git checkout demo/regression     # a "refactor" that drops the PLUS badge and tightens the banner by 2pt
make ios-test                    # fails: 19 of 62 screenshots changed
open artifacts/ios/diffs/index.html   # golden | this PR | changed pixels, for every failure
make android-test                # fails: the same 19 screenshots
open android/app/build/outputs/roborazzi/   # *_compare.png
git checkout main                # always switch back
```

Pre-captured output is in [docs/regression/](docs/regression/).

## Run the apps (mock mode)

```bash
make ios-run                                  # builds if needed, boots the pinned simulator, opens it, launches
make ios-run FIXTURE=feed_long_headlines      # feed_default | feed_long_headlines | feed_empty
make ios-run OFFLINE=1                        # offline state
make ios-run TAB=games                        # start on Spiele (or TAB=account)
make ios-run TAB=account SIGNED_IN=1          # start logged in as the demo user
make android-run                              # same options; uses a plugged-in phone, a running emulator, or boots NewsDemo_API34
```

- **Demo login:** `demo@newsdemo.app` / `demo1234`
- **Xcode 27** replaced Simulator.app with **DeviceHub** (`open -a DeviceHub`); `ios-run` handles both.
- **Demo toggles:**
  - iOS: `xcrun simctl ui booted appearance dark` and `xcrun simctl ui booted content_size accessibility-extra-extra-extra-large`
  - Android: `adb shell cmd uimode night yes` and `adb shell settings put system font_scale 2.0`

## Content and licensing

- **Headlines and links:** the feed's headlines and links come from the public RSS feeds of welt.de and bild.de, fetched on 2026-11-05.
- **Teaser sentences:** written by us and only restate the headline.
- **Article text:** never copied. Tapping opens the publisher's own page.
- **Images and video durations:** demo placeholders.
- **Games:** generic public-domain classics written from scratch.

## Honest notes

- **Goldens were recorded on an Apple Silicon Mac.** iOS goldens are valid only for the pinned Xcode and simulator. Android goldens recorded on macOS can differ in font rasterisation from Linux CI. That's why the strategy makes CI the only recorder; the first CI run would re-baseline via the `record-snapshots` label.
- **The CI workflow has never run.** This repo has no remote.
- **Android tests run on Robolectric's SDK 36 runtime** while the app compiles against and targets SDK 37. On the SDK 37 runtime most captures came out blank. See STRATEGY §5.
- **Verified from a fresh clone:**
  - both suites pass on `main` and fail with the same 19 diffs on `demo/regression`
  - both apps launch in every mode (simulator, emulator)
  - every `make` command works
