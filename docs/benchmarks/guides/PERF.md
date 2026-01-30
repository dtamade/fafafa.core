# fafafa.core.fs · Performance Guide (Baseline + Suggestions)

Status: advisory only (no behavior changes). This document defines how to measure, compare, and reason about non-functional performance without altering public semantics.

## Goals
- Provide a reproducible baseline for WalkDir and TFsFile common paths
- Document toggles that impact performance and their trade-offs
- Offer safe optimization suggestions that do not change external behavior

## Scenarios
- S1: Deep tree (1k dirs, 10k files) with mixed sizes (0B..64KB)
- S2: Errors in tree (unreadable dir, broken symlink) for OnError cost
- S3: Symlink-heavy tree (FollowSymlinks true/false)
- S4: Streaming vs buffered traversal, Sort on/off

Each scenario can be generated in a temp directory. Avoid committing generated data.

## Metrics
- Wall-clock time (ms) for WalkDir (median of N runs, e.g., N=5)
- Items/sec throughput (files + dirs considered)
- Callback invocations (via Stats.* and OnError counters)
- Memory footprint (optional): peak RSS via platform tools

## Controls (Toggles)
- Stats: nil vs non-nil (disable vs enable counters)
- Filters: PreFilter/PostFilter present vs nil
- FollowSymlinks: false (default) vs true
- UseStreaming: false (default) vs true
- Sort: false (default) vs true

## Measurement Method
- Wrap WalkDir in high-resolution timers (e.g., GetTickCount64)
- Run multiple passes, drop warm-up, report median and IQR
- Verify correctness: Stats.* sums, return codes, and OnError counters must match expectations before trusting timing

## Baseline Expectations (Guidance)
- PreFilter is the cheapest pruning stage (avoids stat) — use it aggressively for path/name-based exclusion
- PostFilter still recurses into directories by design — avoid heavy logic there for very large trees
- Stats=nil removes counter updates and is fastest for hot paths; enable only when needed
- FollowSymlinks=false avoids visited-set overhead; enabling adds cycle protection cost
- UseStreaming=true avoids per-directory sorting; if Sort=false this tends to improve throughput on large fan-out trees

## Safe Optimization Suggestions (No API changes)
1) Reduce string churn
   - Prefer reusing short buffers for JoinPath-like operations in inner loops
   - Minimize repeated ExpandFileName when not necessary (call once per root)
2) Visited set implementation (FollowSymlinks=true path)
   - Today: TStringList (Sorted) → IndexOf is O(log N), insert O(N)
   - Option: switch to a hash-set (O(1) avg) if available without heavy deps; otherwise keep as-is
3) Minimal branching
   - Hoist Assigned(...) checks; cache booleans for hot inner loops when it improves readability
4) Error handling fast-paths
   - Keep HandleError minimal; avoid constructing long strings on common success

## Acceptance Criteria
- Any change must preserve existing tests (functionality first)
- Micro-bench improvements should be >= 5% in S1/S4 median to be worth the complexity
- No additional dependencies without explicit approval

## How to Run (Sketch)
- Create tools/perf_walk.pas generating a temp tree per scenario
- Repeat WalkDir with toggles, collect metrics, dump CSV/Markdown summaries under tests/fafafa.core.fs/logs/

## Documentation Pointers
- README_fafafa_core_fs.md → Walk, OnError, Filters, Stats
- docs/EXAMPLES.md → Pre vs Post filters, OnError, FollowSymlinks
- docs/FAQ.md / FAQ.en.md → Expected behaviors

## Next Steps (if approved)
- Provide a tiny harness (no external deps) under tools/ to produce a baseline table
- Evaluate hash-set swap for visited only behind a conditional define
- Document recommended toggle sets for typical workloads



## Running the minimal harness

- Build and run (Windows):
  - lazbuild tools\perf_walk.pas
  - tools\perf_walk.exe

- Build and run (Linux/macOS):
  - lazbuild tools/perf_walk.pas
  - ./tools/perf_walk

Output example:

```
baseline(ms)=42 count=2201
streaming(ms)=36 count=2201
sort(ms)=58 count=2201
stats(ms)=45 count=2201 files=2000 dirs=201
```


### CLI options and CSV output

Usage:

```
# dirs files_per_dir runs [csv_path]
perf_walk 500 20 7 perf.csv
```

- Defaults: dirs=200, files_per_dir=10, runs=5, no csv
- CSV schema: name,ms,count,files,dirs
- Rows: baseline, streaming, sort, stats (median ms of N runs)

- Optional flags (5th arg) to run a custom scenario:
  - follow, stream, sort, stats (comma-separated)
  - Example: `perf_walk 500 20 7 perf.csv follow,stream,stats`
  - CSV adds a `custom` row if provided
- CSV columns extended: name,ms,count,files,dirs,ips


### Multi-scale suite

- Windows: tools\perf_suite.bat
- Linux/macOS: tools/perf_suite.sh (chmod +x)
- 运行后会生成 tests/fafafa.core.fs/logs/walk_*.csv 与 summary.md
- perf_csv_to_md 会将多份 CSV 汇总为 Markdown 表格


## Recommendations (based on current runs)

- Small/medium trees (≤ 500 dirs):
  - Sort=true often improves stability and may improve throughput
  - Streaming (UseStreaming=true) not always faster; measure before enabling
  - Stats=nil in hot path; enable when you need counts/telemetry
- Large trees (≥ 1000 dirs):
  - Baseline vs Sort/Streaming trade-offs depend on platform/FS cache; prefer Sort for deterministic order; avoid Streaming unless measured beneficial
  - FollowSymlinks adds visited-set overhead; enable only if you need to traverse links
- Custom sets:
  - follow,stream,stats tended to reduce items/sec vs baseline/sort on current Windows run; confirm on your target OS

Notes: These are observational and environment-sensitive. Always measure on your deployment target.
