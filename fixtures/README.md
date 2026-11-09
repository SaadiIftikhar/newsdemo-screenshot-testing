# Shared fixtures (single source of truth for both platforms)

These JSON files mimic the feed API response. **iOS and Android decode the exact same files**
with their production decoders, so one fixture == one UI state on both platforms.

| File | State it pins down |
|---|---|
| `feed/feed_default.json` | Typical feed of **real public headlines** (WELT/BILD RSS, fetched 2026-11-05): breaking banner, live ticker, teaser with/without image, a real WELTplus (premium) teaser, ad slot, video teaser, plus one **unknown item type** (must be ignored). Every item has a `url` (opened in-app) and a `source` credit |
| `feed/feed_long_headlines.json` | Worst-case German compound words + long kicker, premium badge under pressure |
| `feed/feed_edge_cases.json` | **Shared decoding contract** (asserted identically on iOS and Android): malformed item, item without `type`, duplicate id → dropped; teaser without `premium` → free; ad without fill → collapsed; ended live ticker; image that fails to load; timestamps "gerade eben", > 24 h and with fractional seconds |
| `feed/feed_hostile_content.json` | **Messy editorial text, cleaned identically on both platforms** (shared literal in the contract tests): HTML entities (`&amp;`, `&#8222;`, `&#x1F3AC;`), stray line breaks/tabs, whitespace-only kicker and summary, soft hyphens in long compounds, emoji and non-Latin names, an item reusing the banner's id, a ticker with no entries yet, a 1:02:03 video, a timestamp in the daylight-saving night and one in the future. Synthetic, not real articles |
| `feed/feed_empty.json` | Empty feed state |
| `images/*.png` | Local stand-ins for CDN images (no network in tests) |

Error/offline states are not data — they are injected as client failures (`FeedError.offline`, `FeedError.server`).

Conventions
- **Fixed clock:** all tests use `now = 2026-11-05T14:13:20Z` (epoch `1_793_888_000`), locale `de_DE`, time zone `Europe/Berlin`. Timestamps in fixtures are relative to that.
- **Content rules:** headlines and links are real and public. Teaser sentences are our own and only restate the headline. Article text is never copied. Images and video durations are placeholders. `feed_long_headlines.json` is synthetic stress-test data.
- **Adding a state** = add/extend a fixture here, then reference it by name in both test suites. Snapshot names are kept identical across platforms (`FeedScreenSnapshotTests/test_feed_default.light.png`, ...).
- **Image names include the file extension** (`politics.png`). iOS silently found `politics` without it, Android didn't; a contract test on both platforms now checks every fixture's image names against the exact files.
- **Content changes, goldens don't:** fixtures are frozen snapshots of the API. When the real API changes, refresh the fixture from an anonymised real response in its own PR; that PR shows exactly which goldens it re-baselines.
- Fixtures are reviewed like API contracts: if the backend changes shape, a fixture changes, and both platforms' decoders are exercised by it.
