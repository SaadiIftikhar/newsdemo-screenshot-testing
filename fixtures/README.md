# Shared fixtures (single source of truth for both platforms)

These JSON files mimic the feed API response. **iOS and Android decode the exact same files**
with their production decoders, so one fixture == one UI state on both platforms.

| File | State it pins down |
|---|---|
| `feed/feed_default.json` | Typical feed: breaking banner, live ticker, teaser with/without image, premium teaser, ad slot, video teaser, plus one **unknown item type** (must be ignored) |
| `feed/feed_long_headlines.json` | Worst-case German compound words + long kicker, premium badge under pressure |
| `feed/feed_empty.json` | Empty feed state |
| `images/*.png` | Local stand-ins for CDN images (no network in tests) |

Error/offline states are not data — they are injected as client failures (`FeedError.offline`, `FeedError.server`).

Conventions
- **Fixed clock:** all tests use `now = 2023-11-14T22:13:20Z` (epoch `1_700_000_000`), locale `de_DE`, time zone `Europe/Berlin`. Timestamps in fixtures are relative to that.
- **Adding a state** = add/extend a fixture here, then reference it by name in both test suites. Snapshot names are kept identical across platforms (`FeedScreenSnapshotTests/test_feed_default.light.png`, ...).
- Fixtures are reviewed like API contracts: if the backend changes shape, a fixture changes, and both platforms' decoders are exercised by it.
