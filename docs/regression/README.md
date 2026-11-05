# Deliberate regression: what the gate shows a reviewer

Branch **`demo/regression`** contains a plausible "refactor" commit on each platform:

1. **The PLUS (paywall) badge is silently dropped** from the teaser card. This is the brief's own example: *"a paywall badge that disappears after a refactor"*.
2. **The breaking-news banner's vertical padding shrinks by 2pt/dp.** This is a subtle change that a human reviewer would miss in a screenshot. It proves the tolerance setting doesn't hide real layout shifts.

## Result

| | iOS (swift-snapshot-testing) | Android (Roborazzi) |
|---|---|---|
| Failing snapshots | 19 (of 62) | 19 (of 62) |
| Failing tests | 9 test methods | 9 test methods |
| Unaffected (correctly green) | non-premium teasers, live ticker, video, ad, empty/offline/error states, all Games and Account screens | same |

The two platforms fail on **exactly the same 19 snapshots** (lists in `ios/failing-tests.txt` and `android/failing-snapshots.txt`), because they share fixtures, test names and the variant matrix. The failures include the app shell's feed tab, and a real WELTplus teaser losing its PLUS badge.

## Review artifacts

- **iOS:** `ios/` has composites (teaser, breaking banner, whole app shell) from `scripts/diff-report.swift`, showing **golden | this PR | changed pixels (magenta)**. Locally, `make ios-test` writes the full gallery to `artifacts/ios/diffs/index.html`. 
- **Android:** `android/` has Roborazzi's built-in `_compare.png` for the same three screens (**Reference | Diff | New**), written to `android/app/build/outputs/roborazzi/`.

In CI these are uploaded as run artifacts and linked from an automatic PR comment (see `.github/workflows/screenshots.yml`).

## Reviewer decision

- **Unintended (as here):** fix the code. The goldens stay unchanged.
- **Intended:** add the `record-snapshots` label. CI re-records on the pinned image and pushes the new goldens, and `CODEOWNERS` requires design/QA approval of that golden diff.

Reproduce:

```bash
git checkout demo/regression && make ios-test ; make android-test ; git checkout main
```
