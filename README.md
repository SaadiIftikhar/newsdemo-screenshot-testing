# Screenshot testing with mocked data: a news app demo (iOS)

A small news app in **SwiftUI**, covered by **screenshot tests driven by fixed fake data**, gated in **GitHub Actions** on every pull request. It answers the take-home challenge: *how do we catch unintended visual changes in the BILD and WELT apps, without the content changing under us?*

The strategy covers iOS and Android; this demo implements **iOS end to end** (app, tests, CI). Android works the same way with the same fixtures ([STRATEGY.md §10](STRATEGY.md)).

## Deliverables

| Deliverable | Where |
|---|---|
| Strategy document (~3 pages) | [STRATEGY.md](STRATEGY.md) · [STRATEGY.pdf](STRATEGY.pdf) · evidence: [docs/EVIDENCE.md](docs/EVIDENCE.md) |
| Working demo with goldens | `ios/` (app + tests), `fixtures/` (fake data), 89 goldens in `ios/NewsKit/Tests/NewsUISnapshotTests/__Snapshots__/` |
| Deliberate regression with diff | branch `demo/regression` · captured result: [docs/regression/](docs/regression/) |
| How to run and regenerate | this README |
| Prompts used | [PROMPTS.md](PROMPTS.md) |
| Walkthrough | [presentation/Demo-script.html](presentation/Demo-script.html): the live-demo talk track (what to say, which window/tab to show, the few commands to run); [presentation/setup.sh](presentation/setup.sh) prepares and opens everything in one command |
| CI/CD | [.github/workflows/screenshots.yml](.github/workflows/screenshots.yml), running on GitHub Actions |

## Quick start

**Needs:** macOS with **Xcode 27** (a beta/preview release at the time of writing), the **iOS 27.0 simulator runtime** (`xcodebuild -downloadPlatform iOS -buildVersion 27.0`) and **XcodeGen** (`brew install xcodegen`, for the app and UI tests). Run everything from the repository root.

```bash
make ios-test                       # 89 screenshots + logic tests: green
git checkout demo/regression        # a "refactor" that drops the PLUS badge
make ios-test                       # fails: 29 of 89
open artifacts/ios/diffs/index.html # golden | this change | changed pixels
git checkout main                   # always switch back
```

## What's where

```
├── README.md · STRATEGY.md/.pdf · PROMPTS.md       the documents
├── Makefile                      every command (make help)
├── fixtures/                     FAKE DATA: feed JSON + images, the input of every test (see fixtures/README.md)
├── ios/
│   ├── NewsKit/Sources/          the app code: NewsCore (models), NewsUI (feed), Games, Account, AppShell
│   ├── NewsKit/Tests/
│   │   ├── NewsUISnapshotTests/  SCREENSHOT TESTS, and __Snapshots__/ = the GOLDENS (approved PNGs)
│   │   └── NewsCoreTests/        logic, contract, edge-case and contrast tests (no pictures)
│   ├── UITests/                  tap-through tests + Apple's accessibility audit on the real app
│   └── App/, project.yml         the app target (XcodeGen)
├── scripts/                      simulator pinning, diff report, golden lint, gallery, run helper, PDF export
├── docs/                         EVIDENCE.md, regression/ (captured result of the deliberate regression)
├── presentation/                 Demo-script.html (talk track) + setup.sh (one-command demo setup)
├── .github/                      CI workflow, CODEOWNERS (who approves goldens)
└── artifacts/                    OUTPUT of test runs (not in git; recreated by every run)
```

## Commands

| Command | What it does | When |
|---|---|---|
| `make ios-test` | Renders every screen with the fake data, compares it with its golden, runs the logic tests. On failure: `artifacts/ios/diffs/index.html` + `summary.md` | After any change |
| `make ios-ui-test` | Taps through the real app on the simulator + Apple's accessibility audit (~5 min) | Before merging |
| `make lint-goldens` | Fails on blank or unreadable goldens | After recording |
| `make gallery` | Every golden on one page: `artifacts/gallery/index.html` | Design review |
| `make ios-record-missing` | Records goldens only for new tests | After adding a test |
| `make ios-record` | Re-records all goldens from an empty folder | After an intended visual change |
| `make ios-run` | Opens the app in the simulator. Options: `FIXTURE=feed_hostile_content`, `OFFLINE=1`, `DROP_CONNECTION=1`, `TAB=games\|account`, `SIGNED_IN=1` | To look at a state |
| `make help` | Lists every command | |

## Workflows

**A test fails and you did NOT mean it (a bug):** open `artifacts/ios/diffs/index.html` (golden | new | changed pixels in magenta) and `summary.md` (each change labelled *layout*, *visible* or *subtle*). Fix the code. **Never re-record to make a red test green.**

**The appearance changes on purpose (a redesign):** check the diff shows only the intended change, then update the goldens. In a team, add the `record-snapshots` label to the pull request: CI re-records on its pinned machine, proves the new goldens and pushes them; a design/QA code owner approves the image diff. Locally:
```bash
make ios-record      # always reports "failed": that's normal in record mode
make lint-goldens
git status           # review every changed PNG before committing
```

**Add a new screenshot:** add or extend a fixture in `fixtures/feed/`, add a `func test_…()` in `ios/NewsKit/Tests/NewsUISnapshotTests/` (copy an existing one; it's one line), then:
```bash
make ios-record-missing   # records only the new golden
make lint-goldens && make ios-test
```
Look at the new PNG yourself before committing: a new golden is approved by a person, never trusted blindly.

**The API changes shape:** update the fixture from an anonymised real response in its own pull request; contract and precondition tests tell you if a golden would now mean something different.

**It fails only on CI, or only sometimes:** CI is the source of truth; download the `ios-snapshot-diffs` artifact from the run. Check the pinned simulator runtime (`scripts/ios-sim.sh`). Flaky tests are never retried: fix the cause or quarantine the test within 24 hours with an owner.

## The app

- **Nachrichten (feed):** breaking banner, live ticker (live, ended, no entries yet), teasers with and without images, **PLUS** teasers behind a paywall, video, ads (and an ad that returned nothing), skeleton loading, empty, offline, error, and **offline with cached content** ("Stand 15:02 Uhr", pull to refresh). Headlines are **real public WELT/BILD articles**; tapping one opens the publisher's page.
- **Spiele:** Tic-Tac-Toe against the computer, a pairs game, a 4×4 Mini-Sudoku.
- **Konto:** login with validation, profile. Demo logins (password `demo1234`): `demo@newsdemo.app` (PLUS subscriber), `basis@newsdemo.app` (no subscription: PLUS articles show the paywall).
- Messy CMS text (`&amp;`, stray line breaks, soft hyphens, emoji) is cleaned before it reaches the screen.

## Content and licensing

Headlines and links are real, from the public RSS feeds of welt.de and bild.de (fetched 2026-11-05). Teaser sentences are our own and only restate the headline; article text is never copied. Images, video durations, the paywall offer and prices are placeholders. The games are generic public-domain classics written from scratch.

## Honest notes

- **Xcode 27 is a preview release** at the time of writing; the CI job uses GitHub's `xcode-27` preview runner.
- **Goldens are recorded by CI** on the pinned simulator (iOS 27.0, iPhone 17); a Mac with the same runtime verifies them, so local and CI agree.
- **Without a `SNAPSHOT_BOT_TOKEN` secret**, the bot's re-recorded goldens don't start a new CI run on their own; push any commit or re-run the workflow.
- **The nightly run** recommended in the strategy is switched off in this repo to save CI minutes (see the comment in the workflow).
