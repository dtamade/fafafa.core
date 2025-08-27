# fafafa.core.fs Performance Baseline (2025-08-14)

Harness: tests/fafafa.core.fs/BuildOrRunPerf.(bat|sh) -> perf_fs_bench.exe

Machine: Windows x86_64 (FPC 3.3.1 trunk)

Results:
- Sequential write: 64 MB in 80 ms  =>  800 MB/s
- Sequential read:  64 MB in 72 ms  =>  888 MB/s
- Random read:      5000 ops in 603 ms => 8291 ops/s

Notes:
- Default payloads: 64MB sequential (128KB blocks); 4KB random read x 5000
- Store under tests/fafafa.core.fs/performance-data/*.txt for history; compare with baseline.txt

Regression guard (manual):
- Alert if throughput drops >10% or latency rises >10% against baseline
- If regression observed, open a note in report and do not optimize in freeze window; just flag it

