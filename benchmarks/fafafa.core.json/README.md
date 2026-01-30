# Benchmarks — fafafa.core.json read/write

Usage
- Build with lazbuild or fpc:
  - lazbuild --build-mode=Release fafafa.core.json.perf_rw.lpr
  - fpc -O2 -S2 -MObjFPC -Fu../../src -FEbin -FUlib fafafa.core.json.perf_rw.lpr
- Options: --arr=NNN --nums=NNN --objKeys=NNN

Notes
- {$UNITPATH ../../src} set inside .lpr; no extra flags required for unit paths.
- This is a quick local microbench; do not wire into CI.

