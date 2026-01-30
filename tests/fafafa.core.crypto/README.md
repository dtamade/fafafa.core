# fafafa.core.crypto tests — quick guide (GHASH modes, env switches, bench)

This guide summarizes how to run the crypto test-suite locally, switch GHASH pure-Pascal modes for debugging/benchmarks, and keep CI untouched (per project policy).

## Build and run

- Windows PowerShell:
  - `tests\fafafa.core.crypto\BuildOrTest.bat test`
- The script builds and runs tests twice (with/without anonymous functions) and writes JUnit XML to `tests/fafafa.core.crypto/reports/`.
- You can filter suites, e.g. only benches:
  - `tests\fafafa.core.crypto\BuildOrTest.bat test --suite=GHASH_Bench` (see FpcUnit switches)

## GHASH backend and pure-mode selection

Two layers of selection:

1) Backend (pure vs CLMUL). Best-practice defaults:
   - x86_64 Release: prefer CLMUL (compile-time macro), fallback to pure if unavailable
   - Debug: default pure (safety); CLMUL guarded by experimental env

   Runtime override (optional): `FAFAFA_GHASH_IMPL=auto|pure|clmul`
   Debug-only one-time log: `FAFAFA_GHASH_LOG_BACKEND=1|true`

2) Pure-Pascal mode (bit/nibble/byte). Default: `byte` for performance.
   - Debug-only: `FAFAFA_GHASH_PURE_MODE=bit|nibble|byte`
   - Optional API: `GHash_SetPureMode('bit'|'nibble'|'byte')` (takes effect for new contexts; env has precedence in Debug)
   - Lazy table build by mode:
     - bit -> FPowV (~2KB)
     - nibble -> FPowV + FPowNib (~10KB)
     - byte -> FPowV + FPowNib + FPowByte (~74KB total)

Notes:
- In Debug, CLMUL requires `FAFAFA_GHASH_USE_EXPERIMENTAL=1|true`.
- Env switches are read per-process; they affect subsequent CreateGHash/Init.

## Mode sweep and consistency tests

- `Test_ghash_pure_mode_consistency.pas` – compare bit/nibble/byte tags; repeatability check
- `Test_ghash_pure_mode_sweep.pas` – loops bit/nibble/byte; runs a trivial KAT and an associativity-like property

Run:
- `tests\fafafa.core.crypto\BuildOrTest.bat test`

Set explicit pure mode (Debug only):
- `$env:FAFAFA_GHASH_PURE_MODE='nibble'`

## Benchmarks (opt-in output)

Enable verbose:
- `$env:FAFAFA_BENCH_VERBOSE=1`

- `Test_ghash_precomp_bench.pas` – pure path micro-bench
- `Test_ghash_pure_mode_bench_sweep.pas` – bit/nibble/byte sweep throughput（`FAFAFA_BENCH_VERBOSE=2` 输出三次中位数）
- `Test_ghash_clmul_vs_pure_byte_bench.pas` – CLMUL vs pure-byte comparison（Debug 下可输出三次中位数）
- `Test_ghash_bench_sizes_sweep.pas` – small/medium/large size sweep for pure-byte and CLMUL
- `Test_ghash_precompute_coldstart_bench.pas` – pure-byte 冷启动（首用建表） vs 复用 对比

Output examples:
- `GHASH pure-bit:          ... MiB/s (bytes in s, iters=n)`
- `GHASH pure-nibble:       ...`
- `GHASH pure-byte:         ...` 或 `... [median of 3]`
- `GHASH clmul-requested:   ...` 或 `... [median of 3]`
- `GHASH pure-byte coldstart: ...` / `reused: ...`
- `Sizes: AAD=..., C=... (iters=...)`

Best practices:
- Close background CPU tasks; run multiple times; compare median/best
- Keep input sizes consistent; avoid extra logs

## Safety and project policy

- Do not modify CI or add CI scripts
- Defaults: correctness/debuggability in Debug; performance in Release
- Tests do not modify persistent state; outputs go to `reports/` and console

## Quick reference

- Backend env: `FAFAFA_GHASH_IMPL=auto|pure|clmul`
- Debug-only:
  - Pure mode: `FAFAFA_GHASH_PURE_MODE=bit|nibble|byte`

## FAQ

- 为什么 Debug 下默认不走 CLMUL？
  - 为了安全与可诊断，Debug 默认使用纯 Pascal；如需 CLMUL，请设置 `FAFAFA_GHASH_USE_EXPERIMENTAL=1` 或在 x86_64 Release 构建（默认启用 CLMUL 宏）。

- 如何切换纯 Pascal 实现（bit/nibble/byte）？
  - Debug 构建：设置 `FAFAFA_GHASH_PURE_MODE=bit|nibble|byte`（默认 `byte`）。三种实现的等价性由 `Test_ghash_pure_mode_consistency`/`Test_ghash_pure_mode_sweep` 覆盖。

- 如何确认当前使用的后端（pure/CLMUL）？
  - Debug 构建：设置 `FAFAFA_GHASH_LOG_BACKEND=1`，首次调用时输出后端信息；也可用 `FAFAFA_GHASH_IMPL=auto|pure|clmul` 覆盖。

- 为什么我的 CLMUL 基准没有明显提升？
  - 可能原因：CPU 不支持 PCLMUL、Debug 未开启实验开关、输入规模偏小/噪声较大。
  - 建议：开启 `FAFAFA_BENCH_VERBOSE=1`，多次运行取中位/较优值；使用更大输入；确认 CPU 支持 CLMUL。

- 表内存占用与构建策略？
  - 纯 Pascal：`FPowV≈2KB`、`FPowNib≈8KB`、`FPowByte≈64KB`；按需构建并缓存于上下文，相同 H 不重复构建。
  - 如需降内存可选择 `bit`/`nibble` 模式以换取性能。

- 如何快速做性能对比？
  - 设置 `FAFAFA_BENCH_VERBOSE=1`，运行：
    - `Test_ghash_pure_mode_bench_sweep`（bit/nibble/byte）
    - `Test_ghash_clmul_vs_pure_byte_bench`（CLMUL vs pure-byte）
    - `Test_ghash_bench_sizes_sweep`（多尺寸分档）

- 可选清零（安全）开关：
  - `FAFAFA_GHASH_ZEROIZE_TABLES=1|true` 在 `Reset` 时清零 FPowV/FPowNib/FPowByte 并重置标志（默认关闭，可能影响后续首用性能）

- 可选缓存（Debug）：
  - `FAFAFA_GHASH_CACHE_PER_H=1|true` 开启按 H 的微型 LRU 表缓存（上限 4 个）；默认关闭，仅 Debug 生效
  - 有助于多次处理相同 H 的场景（例如批量测试），生产构建建议关闭


  - Enable CLMUL experimental: `FAFAFA_GHASH_USE_EXPERIMENTAL=1|true`

## Changelog (tests quick guide)
- Add: pure-mode selector API `GHash_SetPureMode` and docs
- Add: DEBUG strict Finalize length check and mismatch test
- Add: optional zeroize `FAFAFA_GHASH_ZEROIZE_TABLES` and test
- Add: benches with median-of-3 via `FAFAFA_BENCH_VERBOSE=2`
- Add: precompute coldstart vs reuse micro-bench
- Add: optional per-H LRU cache (DEBUG) `FAFAFA_GHASH_CACHE_PER_H`
- Add: `FAFAFA_BENCH_ITERS` to scale bench time

  - Log backend: `FAFAFA_GHASH_LOG_BACKEND=1|true`
- Bench verbose: `FAFAFA_BENCH_VERBOSE=1`


## Further reading
- See docs/crypto_ghash_quick_ref.md for a one‑page developer quick reference.
