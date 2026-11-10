# Deliberate regression: what the gate shows a reviewer

Branch **`demo/regression`** contains a plausible "refactor" ("simplify the kicker row, tighten the banner") that changes two things by accident:

1. **The PLUS (paywall) badge is silently dropped** from the teaser card. This is the brief's own example: *"a paywall badge that disappears after a refactor"*.
2. **The breaking-news banner's vertical padding shrinks by 2pt.** A change a human reviewer would miss in a screenshot; it proves the tolerance setting doesn't hide real layout shifts.

## Result

| | |
|---|---|
| Failing snapshots | **29 of 89** (list: `failing-tests.txt`) |
| Failing test methods | 15 |
| Triage (`summary.md`, what CI posts on the PR) | **10 layout** changes (the banner got 4pt shorter, so the image size changed), **19 visible**, 0 subtle |
| Unaffected (correctly green) | non-premium teasers, live ticker, video, ad, empty/offline/error states, all Games, Account and Paywall screens |

The failures include the app shell's feed tab, the offline (cached content) and hostile-content feeds, and a real WELTplus teaser losing its PLUS badge.

## What's in this folder

| File | What it is |
|---|---|
| `ComponentSnapshotTests__test_teaserCard_premium.dark.png` | **golden \| this PR \| changed pixels (magenta)** for the PLUS teaser: the badge is gone |
| `ComponentSnapshotTests__test_breakingBanner_default.light.png` | the banner 4pt shorter: a "layout" change |
| `AppShellSnapshotTests__test_appShell_feedTab.light.png` | the whole feed tab: both changes at once |
| `summary.md` | the triage table (kind of change and pixel counts per snapshot) |
| `failing-tests.txt` | the 29 failing snapshot names |

These are a committed copy of what `scripts/diff-report.swift` produced on CI. Locally, `make ios-test` on the branch writes the full gallery to `artifacts/ios/diffs/index.html`.

## Reviewer decision

- **Unintended (as here):** fix the code. The goldens stay unchanged.
- **Intended:** add the `record-snapshots` label. CI re-records on the pinned image, proves and pushes the new goldens, and `CODEOWNERS` requires design/QA approval of that golden diff.

Reproduce:

```bash
git checkout demo/regression
make ios-test                              # fails: 29 of 89
open artifacts/ios/diffs/index.html        # golden | this PR | changed pixels
git checkout main
```
