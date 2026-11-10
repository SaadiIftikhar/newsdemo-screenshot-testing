# Fixtures: the fake data every test uses

These JSON files mimic the feed API response. The app's **production decoder** reads them, so one fixture = one UI state, and the tests exercise the real parsing code. They are plain JSON on purpose: an Android app (or any other client) can use the very same files.

| File | State it pins down |
|---|---|
| `feed/feed_default.json` | Typical feed of **real public headlines** (WELT/BILD RSS, fetched 2026-11-05): breaking banner, live ticker, teaser with and without image, a real WELTplus (PLUS) teaser, ad slot, video teaser, plus one **unknown item type** (must be ignored). Every item has a `url` (opened in-app) and a `source` credit |
| `feed/feed_long_headlines.json` | Worst-case German compound words + long kicker; PLUS badge under pressure |
| `feed/feed_edge_cases.json` | **Decoding contract**: malformed item, item without `type`, duplicate id → dropped; teaser without `premium` → free; ad without fill → collapsed; ended live ticker; image that fails to load; timestamps "gerade eben", > 24 h and with fractional seconds |
| `feed/feed_hostile_content.json` | **Messy editorial text** (exact cleaned result asserted in `EdgeCaseScenarioTests`): HTML entities (`&amp;`, `&#8222;`, `&#x1F3AC;`), stray line breaks and tabs, whitespace-only kicker and summary, soft hyphens in long compounds, emoji and non-Latin names, an item reusing the banner's id, a ticker with no entries yet, a 1:02:03 video, a timestamp in the daylight-saving night and one in the future. Synthetic, not real articles |
| `feed/feed_empty.json` | Empty feed state |
| `images/*.png` | Local stand-ins for CDN images (no network in tests) |

Error and offline states are not data: they are injected as client failures (`FeedError.offline`, `FeedError.server`).

## Conventions
- **Fixed clock:** all tests use `now = 2026-11-05T14:13:20Z` (epoch `1_793_888_000`), locale `de_DE`, time zone `Europe/Berlin`. Timestamps in fixtures are relative to that, so "vor 9 Min." never goes stale.
- **Content rules:** headlines and links are real and public. Teaser sentences are our own and only restate the headline. Article text is never copied. Images and video durations are placeholders. `feed_long_headlines.json` and `feed_hostile_content.json` are synthetic stress data.
- **Adding a state** = add or extend a fixture here, then reference it by name in a test (see README, "Add a new screenshot").
- **Image names include the file extension** (`politics.png`). `UIImage(contentsOfFile:)` silently finds `politics` without it, other loaders don't; a contract test checks every fixture's image names against the exact files.
- **Content changes, goldens don't:** fixtures are frozen snapshots of the API. When the real API changes, refresh the fixture from an anonymised real response in its own PR; that PR shows exactly which goldens it re-baselines.
- **Fixtures are reviewed like API contracts** (CODEOWNERS: QA): if the backend changes shape, a fixture changes, and the decoder is exercised by it.
