# GHASH developer quick reference

Scope: AES‑GCM GHASH implementation in this repo. One‑page summary for developers to build, debug, benchmark, and switch modes/backends locally (no CI changes).

## Backends and modes

- Backends
  - Pure Pascal (Debug default)
  - CLMUL for x86_64 (Release default under macro; Debug gated by env)
  - Override (optional, runtime): `FAFAFA_GHASH_IMPL=auto|pure|clmul`
  - Debug one‑time log: `FAFAFA_GHASH_LOG_BACKEND=1|true`

- Pure‑Pascal modes (Debug)
  - `FAFAFA_GHASH_PURE_MODE=bit|nibble|byte` (default `byte`)
  - Optional API: `GHash_SetPureMode('bit'|'nibble'|'byte')` (affects new contexts; env has precedence in Debug)
  - Lazy precompute by need: bit -> (V); nibble -> (V+Nib); byte -> (V+Nib+Byte)

## Safety and diagnostics (Debug)

- Strict finalize length check: AADLen+CLen must equal bytes fed via Update; else exception
- Optional table zeroization on Reset: `FAFAFA_GHASH_ZEROIZE_TABLES=1|true` (impacts first‑use cost)
- Optional per‑H tiny LRU cache (≤4): `FAFAFA_GHASH_CACHE_PER_H=1|true` (Debug only)

## Tests you likely want

- Run all: `tests\\fafafa.core.crypto\\BuildOrTest.bat test`
- Pure‑mode consistency/sweep: see
  - `Test_ghash_pure_mode_consistency.pas`
  - `Test_ghash_pure_mode_sweep.pas`
- CLMUL vs pure‑byte: `Test_ghash_clmul_vs_pure_byte_bench.pas`
- Multi‑size sweep: `Test_ghash_bench_sizes_sweep.pas`
- Coldstart vs reused (precompute cost): `Test_ghash_precompute_coldstart_bench.pas`
- Include integrity: `Test_include_integrity.pas`

Tips:
- Filter suites with FpcUnit switches (example): `--suite=GHASH_Bench`

## Bench settings

- Verbose throughput: `FAFAFA_BENCH_VERBOSE=1`
- Median‑of‑3: `FAFAFA_BENCH_VERBOSE=2`
- Iteration scaling: `FAFAFA_BENCH_ITERS=<n>` (applies to bench tests that support it)

## Defaults (best‑practice)

- Debug builds: Pure Pascal (byte), CLMUL gated by `FAFAFA_GHASH_USE_EXPERIMENTAL=1|true`
- Release x86_64: Prefer CLMUL (macro), fallback to pure if unavailable；当纯后端被选择时，AES‑GCM 会在 GH.Init 后自动热身一次（WarmUp），降低短消息首用抖动
- No CI changes; all toggles are local, process‑scoped

## Notes

- Memory footprint per context (pure‑byte): V~2KB, Nib~8KB, Byte~64KB (≈74KB total), built lazily
- Debug‑only cache and strict checks are for developer convenience; disable for production benchmarks

