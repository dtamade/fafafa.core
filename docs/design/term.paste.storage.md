# Term Paste Storage: Ring Buffer + Chunked Index Design (Draft)

## Goals
- Bounded memory: configurable total byte cap; predictable trimming cost
- Fast operations: O(1) amortized append; O(1) or O(log n) trimming; O(1) get-latest
- Compatibility: keep current API surface (set/get max_bytes, auto_keep_last, defaults/profile)
- Diagnostics: counters for dropped bytes/items; total bytes maintained accurately

## Current Issues (Summary)
- Unlimited by default (0) may cause unbounded growth in burst paste scenarios
- Trimming can be O(n) due to string copies; fastpath divisor helps but not sufficient under heavy load
- Storage as array of strings lacks compact representation and quick prefix trimming

## Proposed Data Structures
- Fixed-capacity ring buffer of chunks
  - Chunk: small buffer (e.g., 4–16 KB) storing UTF-8 segments of paste text
  - Metadata per chunk: used size, start offset, end offset
- Chunked index
  - Head/Tail indices; total_bytes; items_count
  - Optional item index if “per-paste item” semantic must be preserved

## Operations
- append(text):
  - Encode to UTF-8 bytes; append into tail chunk; if overflow, allocate/advance to next chunk (reusing freed chunk via ring)
  - Update total_bytes; if cap exceeded, evict from head chunk(s) until total_bytes <= cap
- trim_by_keep_last(N):
  - If keeping last N items: maintain a simple deque of item boundaries; drop from head by item boundary
  - If item-less mode: rely purely on total_bytes cap
- get_text(range or latest):
  - Iterate chunks from tail backward or head forward, collecting into destination buffer; avoid concatenation into giant string unless caller asks

## Complexity
- append: amortized O(1)
- trim: O(1) amortized per evicted chunk
- get-latest K bytes: O(#chunks covering K)

## Configuration
- max_bytes: total cap (0 = unlimited, kept for backward compatibility)
- auto_keep_last: optional item cap
- chunk_size: default 8 KB; env override FAFAFA_TERM_PASTE_CHUNK
- ring_capacity: derived from max_bytes/chunk_size, min floor

## Diagnostics
- counters: total_bytes, total_items, dropped_bytes, dropped_items
- expose via getters for tests/monitoring

## Migration Strategy
- Internal replacement only; keep existing public API
- Honor current defaults/profile: if max_bytes=0 and defaults enabled, set a conservative cap (e.g., 1–8 MB) unless explicitly turned off
- Provide feature flag to switch old/new backend during rollout for testing
- Behind-a-flag in production: default 'legacy', enable 'ring' via FAFAFA_TERM_PASTE_BACKEND=ring or term_paste_use_backend('ring')
- Semantics parity: term_paste_set_max_bytes enforces immediately; single item over cap results in empty storage

## Tests
- Storage correctness under mixed-size appends
- Trimming behavior at boundaries (exact cap, off-by-one)
- Keep-last interaction
- Performance microbenchmarks (append 1e5 items)

## Risks
- Complexity increase; mitigate via small, well-documented module and invariants
- Large get_text allocations; mitigate by providing chunked iterators later

