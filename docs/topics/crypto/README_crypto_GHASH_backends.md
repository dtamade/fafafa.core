# GHASH Backends: Pure vs CLMUL

This document explains how GHASH backend selection works in fafafa.core.crypto, how to control it via environment variables, and summarizes benchmark results.

## Backend selection policy

- Default (auto): choose CLMUL when CPU supports PCLMUL; otherwise fall back to Pure
- Force Pure: set FAFAFA_GHASH_IMPL=pure
- Force CLMUL: set FAFAFA_GHASH_IMPL=clmul

Notes
- Runtime CPU detection is applied; when CLMUL is not available, Pure is used automatically
- DEBUG builds have an optional guard FAFAFA_GHASH_USE_EXPERIMENTAL=1 to explicitly allow experimental paths during development
- One-time backend selection log (DEBUG): set FAFAFA_GHASH_LOG_BACKEND=1

## How to verify

- Run all tests (Pure by default or auto):
  - tests\fafafa.core.crypto\bin\tests_crypto.exe --all --format=plain --progress
- Force CLMUL (if supported):
  - PowerShell: $env:FAFAFA_GHASH_IMPL='clmul'
  - tests\fafafa.core.crypto\bin\tests_crypto.exe --all --format=plain --progress

## Benchmark summary (Windows x86_64, Release-CLMUL)

Representative results from tests\fafafa.core.crypto\bin\reports\ghash_clmul_bench.csv:

- 1MB
  - Pure: 3.56–4.93 MB/s (typical ~4.2 MB/s)
  - CLMUL: 62.5–1000 MB/s (ignore 1000 as timer floor, typical ~62.5–127 MB/s)
- 8MB
  - Pure: 1.30–4.57 MB/s (typical ~4.2 MB/s)
  - CLMUL: 102.6–127.0 MB/s

Throughput uplift (8MB): ~22–25x over Pure.

## Reproducing the benchmark

- Ensure Release-CLMUL build mode is used (tools\lazbuild.bat --build-mode=Release-CLMUL)
- To get CLMUL numbers:
  - $env:FAFAFA_GHASH_IMPL='clmul'
  - tests\fafafa.core.crypto\bin\tests_crypto.exe --format=plain --progress --suite=TTestCase_GHASH_CLMUL_Bench
- The CSV will be appended at tests\fafafa.core.crypto\bin\reports\ghash_clmul_bench.csv

## Implementation notes

- CLMUL path uses PCLMULQDQ for the 256-bit carry-less multiply and a correctness-first reduction to GF(2^128)
- If any inconsistency is detected in DEBUG, the code falls back to the Pure implementation for the current operation and marks the CLMUL path as faulted
- The code zeroizes intermediate buffers and supports safe fallback without affecting API contracts

## Troubleshooting

- If your CPU lacks PCLMUL, the backend will remain Pure even with FAFAFA_GHASH_IMPL=clmul
- If you observe identical Pure/CLMUL numbers in CSV rows, ensure you are on latest tests with explicit backend switching in the benchmark
- For diagnostics in DEBUG, set FAFAFA_GHASH_LOG_BACKEND=1

