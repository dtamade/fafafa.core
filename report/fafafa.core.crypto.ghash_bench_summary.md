# GHASH Benchmark Summary — Pure vs CLMUL

Source CSV: tests/fafafa.core.crypto/bin/reports/ghash_clmul_bench.csv
Date: 2025-08-19

## Latest representative results

- 1MB
  - Pure: 3.56–4.93 MB/s (typical ~4.2 MB/s)
  - CLMUL: 62.5–127.0 MB/s (ignore 1000 MB/s entries due to 1 ms timer floor)
  - Uplift: ~15–30x depending on exact sample

- 8MB
  - Pure: 1.30–4.57 MB/s (typical ~4.2 MB/s)
  - CLMUL: 102.6–127.0 MB/s
  - Uplift: ~22–25x

## How to reproduce

- Build: tools/lazbuild.bat --build-mode=Release-CLMUL tests/fafafa.core.crypto/tests_crypto.lpi
- Run (auto mode uses CLMUL if CPU supports; you can also force):
  - PowerShell: $env:FAFAFA_GHASH_IMPL='clmul'
  - tests/fafafa.core.crypto/bin/tests_crypto.exe --format=plain --progress --suite=TTestCase_GHASH_CLMUL_Bench
- CSV path: tests/fafafa.core.crypto/bin/reports/ghash_clmul_bench.csv

## Notes

- The benchmark test now explicitly switches backend for each run to avoid duplicating identical results
- DEBUG builds can emit a one-time backend selection log when FAFAFA_GHASH_LOG_BACKEND=1
- CLMUL path includes correctness‑first reduction and safe fallback to Pure on any inconsistency (DEBUG)

