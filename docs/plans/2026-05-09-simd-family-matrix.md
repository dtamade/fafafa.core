# SIMD Family Matrix

这张表服务于 whole-module refactor。

它不替代下面这些文档，而是把它们压成一张能直接排执行顺序的矩阵：

- 总纲：`docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md`
- 分层基线：`docs/SIMD_LAYERING_IMPLEMENTATION.md`
- backend 真相表：`docs/SIMD_BACKEND_TRUTH.md`
- intrinsics 状态表：`docs/SIMD_INTRINSICS_DISPOSITION.md`
- `SSE2` 局部迁移图：`docs/SIMD_SSE2_MIGRATION_MAP.md`
- non-x86 implementation working ledger：`docs/fafafa.core.simd.implementation-matrix.md`

这张矩阵只回答 8 个执行问题：

1. 当前 family 的 stable truth source 是谁
2. raw leaf 当前在哪里
3. raw leaf 当前是什么 disposition
4. 当前有哪些 verification lane
5. 是否进入 default façade
6. 是否进入 default gate
7. 当前处于哪一波
8. 下一动作是什么

## 使用规则

- 先用这张表选 family，再进入对应局部文档。
- 如果某个 family 的 truth source、disposition、verification lane 没写清楚，不允许直接开始“搬代码”。
- 如果局部实现已经变化，先更新这张矩阵，再更新局部迁移图或状态表。

## Family matrix

| Family | Stable truth source | Raw leaf / low-level unit | Current disposition | Verification lane | Default façade | Default gate | Wave | Next action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Scalar` | `src/fafafa.core.simd.scalar.pas` | `intrinsics.base` | `active leaf` foundation | `check`, `gate`, façade/runtime suites | yes | yes | Wave 3 sample | 保持基线；不作为主要债务点 |
| `MMX` | 通过 x86 adapter 链消费 | `src/fafafa.core.simd.intrinsics.mmx.pas` | `active leaf` | `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh` 的 `check_mmx_backend_smoke`, `experimental-intrinsics` isolation | indirect | no direct gate ownership | Wave 3 sample | 维持 leaf 健康；不扩默认依赖面 |
| `SSE` | 通过 x86 adapter 链消费 | `src/fafafa.core.simd.intrinsics.sse.pas` | `active leaf` | `check_sse_backend_smoke`, `experimental-intrinsics` isolation | indirect | no direct gate ownership | Wave 3 sample | 作为 x86 active-leaf 正样板之一 |
| `SSE2` | `src/fafafa.core.simd.sse2.pas` | `src/fafafa.core.simd.intrinsics.sse2.pas`, `src/fafafa.core.simd.intrinsics.x86.sse2.pas` | `transitional` + `experimental isolated` | `sse2-structure-check`, `impl-smoke-sse2`, `check`, `gate`, `experimental-intrinsics` isolation | yes | yes | Wave 3 debt pilot | 先补 raw-leaf qualification，再做 promote / split / retire 判断 |
| `SSE3` | `src/fafafa.core.simd.sse3.pas` | `src/fafafa.core.simd.intrinsics.sse3.pas` | `experimental isolated` | `check_sse3_backend_smoke`, `experimental-intrinsics` isolation | yes | yes via adapter | Wave 3 qualification | 先建 family-specific raw tests 与准入判定，不直接默认接线 |
| `SSSE3` | `src/fafafa.core.simd.ssse3.pas` | no dedicated raw leaf yet in current truth docs | adapter-only in practice | adapter suites only; no explicit raw lane matrix yet | yes | yes via adapter | Wave 3 qualification | 先补 matrix truth 和 raw-leaf 目标，再决定是否拆 leaf |
| `SSE4.1` | `src/fafafa.core.simd.sse41.pas` | `src/fafafa.core.simd.intrinsics.sse41.pas` | `experimental isolated` | `experimental-intrinsics` isolation; adapter suites | yes | yes via adapter | Wave 3 qualification | 补 raw tests / lane，再决定是否 promote |
| `SSE4.2` | `src/fafafa.core.simd.sse42.pas` | `src/fafafa.core.simd.intrinsics.sse42.pas` | `experimental isolated` | `experimental-intrinsics` isolation; adapter suites | yes | yes via adapter | Wave 3 qualification | 补 raw tests / lane，再决定是否 promote |
| `AVX2` | `src/fafafa.core.simd.avx2.pas` | `src/fafafa.core.simd.intrinsics.avx2.pas` | `active leaf` | `check_avx2_backend_smoke`, intrinsics coverage, `check`, `gate` | yes | yes | Wave 3 sample | 明确提炼为 whole-module 正样板，形成可复制 adapter->active leaf 模式 |
| `AVX-512` | `src/fafafa.core.simd.avx512.pas` | `src/fafafa.core.simd.intrinsics.avx512.pas` | `experimental isolated` | `check_avx512_backend_smoke`, adapter suites, release closeout evidence | yes | yes via adapter | Wave 3 qualification | 先补 raw qualification，不直接默认依赖 leaf |
| `NEON` | `src/fafafa.core.simd.neon.pas` | `src/fafafa.core.simd.intrinsics.neon.pas` | `experimental isolated` | `nonx86-optin-list-suites`, `check_nonx86_register_truthfulness.py --backend neon`, `impl-smoke-nonx86`, `impl-audit-nonx86`, `closeout-host-local` | yes | adapter yes, leaf no | Wave 4 qualification | 先把 adapter truth / leaf status / non-x86 evidence 串成可复验 lane，再决定 leaf promote |
| `RISCVV` | `src/fafafa.core.simd.riscvv.pas` | `src/fafafa.core.simd.intrinsics.rvv.pas` | `experimental isolated` | `nonx86-optin-list-suites`, `check_nonx86_register_truthfulness.py --backend riscvv`, `impl-smoke-nonx86`, `impl-audit-nonx86`, `riscvv-opcode-lane`, `closeout-host-local` | opt-in only | no default gate as stable family | Wave 4 qualification | 继续保持 opt-in；先做 qualification，不急着进入 default stable 路径 |
| `AES` | no stable adapter target | `src/fafafa.core.simd.intrinsics.aes.pas` | `experimental isolated` | `experimental-intrinsics` isolation only | no | no | Wave 4 hold | 保持隔离，除非出现明确 stable use-case |
| `SHA` | no stable adapter target | `src/fafafa.core.simd.intrinsics.sha.pas` | `experimental isolated` | `experimental-intrinsics` isolation only | no | no | Wave 4 hold | 保持隔离，除非出现明确 stable use-case |
| `AVX` | no stable adapter target | `src/fafafa.core.simd.intrinsics.avx.pas` | `experimental isolated` | `experimental-intrinsics` isolation only | no | no | Wave 4 hold | 保持隔离，不作为当前主线焦点 |
| `FMA3` | no stable adapter target | `src/fafafa.core.simd.intrinsics.fma3.pas` | `experimental isolated` | `check_fma3_backend_smoke`, `experimental-intrinsics` isolation | no | no | Wave 4 hold | 保持隔离，等待明确 family 计划 |
| `SVE` | no stable adapter target | `src/fafafa.core.simd.intrinsics.sve.pas` | `experimental isolated` | `experimental-intrinsics` isolation only | no | no | Wave 4 hold | 先保留为 future lane，不拉入 stable refactor 主线 |
| `SVE2` | no stable adapter target | `src/fafafa.core.simd.intrinsics.sve2.pas` | `experimental isolated` | `experimental-intrinsics` isolation only | no | no | Wave 4 hold | 先保留为 future lane，不拉入 stable refactor 主线 |
| `LASX` | no stable adapter target | `src/fafafa.core.simd.intrinsics.lasx.pas` | `experimental isolated` | `experimental-intrinsics` isolation only | no | no | Wave 4 hold | 先保留为 future lane，不拉入 stable refactor 主线 |

## 现在还不完整的地方

这张矩阵已经够开工，但还没有彻底闭环。

目前还缺：

1. `SSSE3` 的 raw-leaf 目标没有在当前真相文档里被显式写死。
2. `SSE3/SSE4.1/SSE4.2/AVX-512` 只有 isolation / smoke，但缺 family-specific raw parity 文档。
3. `NEON/RISCVV` 的 non-x86 working ledger 已存在，但还没被提升成和 `SSE2` 一样的 family-level migration doc。
4. `AES/SHA/AVX/FMA3/SVE/SVE2/LASX` 目前还只有“继续隔离”的判断，没有明确的 future trigger。

因此它是 **execution-ready**，但还不是 **closeout-complete**。

## 下一步文档动作

1. 给 `AVX2` 补一页 family sample 文档，明确为什么它是 active-leaf 正样板。
2. 给 `NEON` 和 `RISCVV` 各补一页 family qualification plan。
3. 给 `x86 incremental families` 补一页共享 qualification plan，覆盖 `SSE3/SSSE3/SSE4.1/SSE4.2/AVX-512`。
4. 等 `SSE2` 进入 promote / split 决策时，再补 `retire target` 清单。
