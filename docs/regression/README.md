# Deliberate regression: what the gate shows a reviewer

Branch **`demo/regression`** contains a plausible "refactor" commit on each platform:

1. **The PLUS (paywall) badge is silently dropped** from the teaser card. This is the brief's own example: *"a paywall badge that disappears after a refactor"*.
2. **The breaking-news banner's vertical padding shrinks by 2pt/dp.** This is a subtle change that a human reviewer would miss in a screenshot. It proves the tolerance setting doesn't hide real layout shifts.

## Result

| | iOS (swift-snapshot-testing) | Android (Roborazzi) |
|---|---|---|
| Failing tests | 8 (of 20) | 8 test methods |
| Failing snapshots | 17 (of 35) | 17 (of 35) |
| Unaffected (correctly green) | non-premium teasers, live ticker, video, ad, empty/offline/error states | same |

The two platforms fail on **exactly the same 17 snapshots**, because they share fixtures, test names and the variant matrix.

## Review artifacts

- **iOS:** `ios/` has composites from `scripts/diff-report.swift`, showing **golden | this PR | changed pixels (magenta)**. Locally, `make ios-test` writes the full gallery to `artifacts/ios/diffs/index.html`. `failing-tests.txt` is the raw xcodebuild summary.
- **Android:** `android/` has Roborazzi's built-in `_compare.png` (**Reference | Diff | New**), written to `android/app/build/outputs/roborazzi/`.

In CI these are uploaded as run artifacts and linked from an automatic PR comment (see `.github/workflows/screenshots.yml`).

## Reviewer decision

- **Unintended (as here):** fix the code. The goldens stay unchanged.
- **Intended:** add the `record-snapshots` label. CI re-records on the pinned image and pushes the new goldens, and `CODEOWNERS` requires design/QA approval of that golden diff.

Reproduce:

```bash
git checkout demo/regression && make ios-test ; make android-test ; git checkout main
```
