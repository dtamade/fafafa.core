# Experiments: Walk Flags (Windows only)

Purpose: Evaluate light-weight flags optimizations for directory enumeration without changing public behavior.

Scope
- Windows-only; Unix path is unchanged
- No merges: this is local experiment to inform future decisions
- Compare default vs. experimental flags using existing perf harness

Plan
1) Runner: reuse tests/fafafa.core.fs/perf_fs_bench.lpr
2) Build two binaries via macros:
   - Baseline: default settings
   - Experiment: define FS_WALK_WIN_LARGE_FETCH to enable FindFirstFileEx large fetch
3) Run BuildOrRunPerf.bat for both builds; archive logs and compare

How to run (Windows)
- Baseline (default):
  - tests\fafafa.core.fs\BuildOrRunPerf.bat
- Experiment (set macro before build):
  - set FPCOPT=-dFS_WALK_WIN_LARGE_FETCH
  - tests\fafafa.core.fs\BuildOrRunPerf.bat

Notes
- This does not change repo defaults; only for local evaluation
- If results consistently improve (>=5%), we can propose a guarded default-on-by-platform in a later unfreeze

