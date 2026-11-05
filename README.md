# NewsDemo: cross-platform screenshot testing with mocked data

A small news app (a feed with a breaking-news banner, live ticker, teasers with and without images, a paywalled **PLUS** teaser, a video teaser, an ad slot, and empty/offline/error states) built natively on **iOS (SwiftUI)** and **Android (Compose)**. Both apps are covered by screenshot tests driven by **one shared set of JSON fixtures**.

- **Strategy:** [STRATEGY.md](STRATEGY.md) (PDF: [STRATEGY.pdf](STRATEGY.pdf))
- **Prompts used:** [PROMPTS.md](PROMPTS.md)
- **Deliberate regression:** branch `demo/regression`, captured diffs in [docs/regression/](docs/regression/)

```
fixtures/            shared JSON + images  ← single source of truth for UI states (both platforms)
ios/NewsKit/         SPM package: NewsCore (models, FeedClient seam) · NewsUI · NewsFixtures
  Tests/NewsUISnapshotTests/__Snapshots__/   iOS goldens (swift-snapshot-testing)
ios/App/, project.yml  thin app shell (XcodeGen), launch args select fixture/offline/live
android/app/         Compose app: core/ (models, FeedClient seam) · ui/
  src/test/screenshots/                      Android goldens (Roborazzi)
scripts/             pinned simulator, diff report, fixture image generator
.github/             CI workflow (verify / record), CODEOWNERS for goldens
```

## Prerequisites

| Platform | Needs |
|---|---|
| iOS | macOS, Xcode 27.2, iOS 26.5 simulator runtime (`make` creates the pinned "NewsDemo Snapshots" iPhone 17 simulator); `xcodegen` only for building the app shell |
| Android | JDK 21, Android SDK 36 (`ANDROID_HOME` or `android/local.properties`). No emulator needed |

## Run

```bash
make ios-test          # verify iOS snapshots against the goldens (what CI runs)
make android-test      # verify Android snapshots against the goldens
```

## Regenerate goldens

```bash
make ios-record        # re-record all iOS goldens (record mode reports "failed"; that's expected)
make android-record    # re-record all Android goldens
git diff --stat        # then REVIEW the changed PNGs before committing
```

In a team setup, goldens are recorded only by CI: add the `record-snapshots` label to a PR (see `.github/workflows/screenshots.yml`).

## See the regression and the review workflow

```bash
git checkout demo/regression     # a "refactor" that drops the PLUS badge and tightens the banner by 2pt
make ios-test                    # fails: 8 tests / 17 snapshots
open artifacts/ios/diffs/index.html   # golden | this PR | changed pixels, for every failure
make android-test                # same regression on Android → android/app/build/outputs/roborazzi/*_compare.png
git checkout main
```

Pre-captured output is in [docs/regression/](docs/regression/), in case you don't want to run it.

## Run the apps (mock mode)

```bash
make ios-app      # builds for the pinned simulator; launch args: -fixture feed_long_headlines | -offline | -baseURL http://localhost:8080
cd android && ./gradlew installDebug
adb shell am start -n com.example.newsdemo/.MainActivity --es fixture feed_long_headlines
```

The same fixture names drive the tests, the apps' mock mode and (in the strategy) nightly Maestro flows.

## Honest notes

- The committed goldens were recorded on an Apple Silicon Mac. iOS goldens are only valid for the pinned Xcode and simulator. Android goldens recorded on macOS can differ in font rasterisation from Linux CI runners. That's why the strategy makes CI the only recorder of goldens. The first CI run would re-baseline via the `record-snapshots` label.
- The CI workflow is written but has not run (this repo has no remote yet).
- Ads, WebViews and remote image loading are replaced by placeholders and local images in tests on purpose (see STRATEGY.md §2).
