# Benchmarks — fafafa.core.collections (OrderedMap)

Usage
- Build with lazbuild or fpc:
  - lazbuild --build-mode=Release orderedmap_perf.lpr
  - fpc -O2 -S2 -MObjFPC -Fu../../src -FEbin -FUlib orderedmap_perf.lpr

Notes
- {$UNITPATH ../../src} is set; no extra flags required for unit paths.
- This is a quick local microbench; do not wire into CI.

