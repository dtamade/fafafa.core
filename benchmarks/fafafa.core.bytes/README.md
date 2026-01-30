# Benchmarks — fafafa.core.bytes / ByteBuf

Usage
- Build with lazbuild or fpc using the .lpr here. Example:
  - lazbuild --build-mode=Release fafafa.core.bytes.bench.lpr
  - fpc -O2 -S2 -MObjFPC -Fu../../src -FEbin -FUlib fafafa.core.bytes.bench.lpr
- Output prints three quick sections: concat vs builder, EnsureWritable growth, Read/Compact

Notes
- {$UNITPATH ../../src} is set inside .lpr so the units resolve without extra flags.
- Keep this microbench light and non-CI; it is for local quick checks.

