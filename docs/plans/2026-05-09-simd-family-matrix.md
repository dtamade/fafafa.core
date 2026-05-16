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

| Family    | Stable truth source               | Raw leaf / low-level unit                                                                  | Current disposition                      | Verification lane                                                                                                                                                           | Default façade | Default gate                     | Wave                 | Next action                                                                                              |
| --------- | --------------------------------- | ------------------------------------------------------------------------------------------ | ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | -------------------------------- | -------------------- | -------------------------------------------------------------------------------------------------------- |
| `Scalar`  | `src/fafafa.core.simd.scalar.pas` | `intrinsics.base`                                                                          | `active leaf` foundation                 | `check`, `gate`, façade/runtime suites                                                                                                                                      | yes            | yes                              | Wave 3 sample        | 保持基线；不作为主要债务点                                                                               |
| `MMX`     | 通过 x86 adapter 链消费           | `src/fafafa.core.simd.intrinsics.mmx.pas`                                                  | `active leaf`                            | `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh` 的 `check_mmx_backend_smoke`, `experimental-intrinsics` isolation                                           | indirect       | no direct gate ownership         | Wave 3 sample        | 维持 leaf 健康；不扩默认依赖面                                                                           |
| `SSE`     | 通过 x86 adapter 链消费           | `src/fafafa.core.simd.intrinsics.sse.pas`                                                  | `active leaf`                            | `check_sse_backend_smoke`, `experimental-intrinsics` isolation                                                                                                              | indirect       | no direct gate ownership         | Wave 3 sample        | 作为 x86 active-leaf 正样板之一                                                                          |
| `SSE2`    | `src/fafafa.core.simd.sse2.pas`   | `src/fafafa.core.simd.intrinsics.sse2.pas`, `src/fafafa.core.simd.intrinsics.x86.sse2.pas` | `transitional` + `experimental isolated` | `sse2-structure-check`, `impl-smoke-sse2`, `check`, `gate`, `experimental-intrinsics` isolation                                                                             | yes            | yes                              | Wave 3 debt pilot    | 先补 raw-leaf qualification，再做 promote / split / retire 判断                                          |
| `SSE3`    | `src/fafafa.core.simd.sse3.pas`   | `src/fafafa.core.simd.intrinsics.sse3.pas`                                                 | `experimental isolated`                  | `check_sse3_backend_smoke`, `Test_SSE3_RepresentativeSemanticParity_WithScalar_IfDispatchable`, `experimental-intrinsics` isolation                                         | yes            | yes via adapter                  | Wave 3 qualification | 按 shared raw parity baseline 冻结 representative parity lane，再做 family-specific raw tests / 准入判定 |
| `SSSE3`   | `src/fafafa.core.simd.ssse3.pas`  | no dedicated raw leaf target; adapter-only in practice                                     | adapter-only in practice                 | adapter suites only; no explicit raw lane matrix yet                                                                                                                        | yes            | yes via adapter                  | Wave 3 qualification | 保持 adapter-only；暂不拆 dedicated raw leaf                                                             |
| `SSE4.1`  | `src/fafafa.core.simd.sse41.pas`  | `src/fafafa.core.simd.intrinsics.sse41.pas`                                                | `experimental isolated`                  | `experimental-intrinsics` isolation; `Test_SSE41_RepresentativeSemanticParity_WithScalar_IfDispatchable`; adapter suites                                                    | yes            | yes via adapter                  | Wave 3 qualification | 按 shared raw parity baseline 冻结 representative parity lane，再决定是否 promote                        |
| `SSE4.2`  | `src/fafafa.core.simd.sse42.pas`  | `src/fafafa.core.simd.intrinsics.sse42.pas`                                                | `experimental isolated`                  | `experimental-intrinsics` isolation; `Test_SSE42_RepresentativeSemanticParity_WithScalar_IfDispatchable`; adapter suites                                                    | yes            | yes via adapter                  | Wave 3 qualification | 按 shared raw parity baseline 冻结 representative parity lane，再决定是否 promote                        |
| `AVX2`    | `src/fafafa.core.simd.avx2.pas`   | `src/fafafa.core.simd.intrinsics.avx2.pas`                                                 | `active leaf`                            | `check_avx2_backend_smoke`, intrinsics coverage, `check`, `gate`                                                                                                            | yes            | yes                              | Wave 3 sample        | 明确提炼为 whole-module 正样板，形成可复制 adapter->active leaf 模式                                     |
| `AVX-512` | `src/fafafa.core.simd.avx512.pas` | `src/fafafa.core.simd.intrinsics.avx512.pas`                                               | `experimental isolated`                  | `check_avx512_backend_smoke`, `Test_AVX512_U32x16_U64x8_ShiftBoundary_Contracts`, adapter suites, release closeout evidence                                                 | yes            | yes via adapter                  | Wave 3 qualification | 按 shared raw parity baseline 冻结边界 contract，再决定是否需要更细 raw qualification                    |
| `NEON`    | `src/fafafa.core.simd.neon.pas`   | `src/fafafa.core.simd.intrinsics.neon.pas`                                                 | `experimental isolated`                  | `nonx86-optin-list-suites`, `check_nonx86_register_truthfulness.py --backend neon`, `impl-smoke-nonx86`, `impl-audit-nonx86`, `closeout-host-local`                         | yes            | adapter yes, leaf no             | Wave 4 qualification | 先把 adapter truth / leaf status / non-x86 evidence 串成可复验 lane，再决定 leaf promote                 |
| `RISCVV`  | `src/fafafa.core.simd.riscvv.pas` | `src/fafafa.core.simd.intrinsics.rvv.pas`                                                  | `experimental isolated`                  | `nonx86-optin-list-suites`, `check_nonx86_register_truthfulness.py --backend riscvv`, `impl-smoke-nonx86`, `impl-audit-nonx86`, `riscvv-opcode-lane`, `closeout-host-local` | opt-in only    | no default gate as stable family | Wave 4 qualification | 继续保持 opt-in；先做 qualification，不急着进入 default stable 路径                                      |
| `AES`     | no stable adapter target          | `src/fafafa.core.simd.intrinsics.aes.pas`                                                  | `experimental isolated`                  | `experimental-intrinsics` isolation, `Test_Default_AES_SHA_Rejects`, `Test_Experimental_AES_SHA_PlaceholderSemantics`                                                       | no             | no                               | Wave 4 hold          | 继续 hold；当前实验 lane 只锁 default-reject + placeholder semantics；具体 reopen 触发条件看 `simd-experimental-hold-future-trigger-plan` 的 `AES` 行 |
| `SHA`     | no stable adapter target          | `src/fafafa.core.simd.intrinsics.sha.pas`                                                  | `experimental isolated`                  | `experimental-intrinsics` isolation, `Test_Default_AES_SHA_Rejects`, `Test_Experimental_AES_SHA_PlaceholderSemantics`                                                       | no             | no                               | Wave 4 hold          | 继续 hold；当前实验 lane 只锁 default-reject + placeholder semantics；具体 reopen 触发条件看 `simd-experimental-hold-future-trigger-plan` 的 `SHA` 行 |
| `AVX`     | no stable adapter target          | `src/fafafa.core.simd.intrinsics.avx.pas`                                                  | `experimental isolated`                  | `check_avx_backend_smoke`, `experimental-intrinsics` isolation                                                                                                             | no             | no                               | Wave 4 hold          | 继续 hold；当前无 in-repo bridge consumer；具体 reopen 触发条件看 `simd-experimental-hold-future-trigger-plan` 的 `AVX` 行        |
| `FMA3`    | no stable adapter target          | `src/fafafa.core.simd.intrinsics.fma3.pas`                                                 | `experimental isolated`                  | `check_fma3_backend_smoke`, `experimental-intrinsics` isolation                                                                                                             | no             | no                               | Wave 4 hold          | 继续 hold；具体 reopen 触发条件看 `simd-experimental-hold-future-trigger-plan` 的 `FMA3` 行            |
| `SVE`     | no stable adapter target          | `src/fafafa.core.simd.intrinsics.sve.pas`                                                  | `experimental isolated`                  | `experimental-intrinsics` isolation only                                                                                                                                    | no             | no                               | Wave 4 hold          | 继续 hold；具体 reopen 触发条件看 `simd-experimental-hold-future-trigger-plan` 的 `SVE` 行             |
| `SVE2`    | no stable adapter target          | `src/fafafa.core.simd.intrinsics.sve2.pas`                                                 | `experimental isolated`                  | `experimental-intrinsics` isolation only                                                                                                                                    | no             | no                               | Wave 4 hold          | 继续 hold；具体 reopen 触发条件看 `simd-experimental-hold-future-trigger-plan` 的 `SVE2` 行            |
| `LASX`    | no stable adapter target          | `src/fafafa.core.simd.intrinsics.lasx.pas`                                                 | `experimental isolated`                  | `experimental-intrinsics` isolation only                                                                                                                                    | no             | no                               | Wave 4 hold          | 继续 hold；具体 reopen 触发条件看 `simd-experimental-hold-future-trigger-plan` 的 `LASX` 行            |

## 决策基线

`docs/plans/2026-05-11-simd-family-decision-baseline.md` 现在负责把剩下的 family-level `promote / hold / future-trigger` 判断冻住。

对应结论已经固定为：

- `SSE3 / SSE4.1 / SSE4.2 / AVX-512` 继续 qualification，不在没有 fresh red 的情况下重新打开 promote / split 争论
- `NEON / RISCVV` 继续 qualification / opt-in，不因为 fallback wrapper 变薄就默认 promote
- `AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX` 继续 hold / experimental isolated，不因为 smoke 绿就默认 reopen；family-specific trigger 统一看 `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
- `SSSE3` 继续 adapter-only，不再作为待补 raw leaf 项

因此这张矩阵现在负责“当前状态 + 下一动作”，而不再负责重复 policy judgment。

## 下一步文档动作

1. 继续维护 `docs/plans/2026-05-09-simd-avx2-active-leaf-sample.md`，把 `AVX2` 作为 active-leaf 正样板守住。
2. 继续维护 `docs/plans/2026-05-09-simd-neon-qualification-plan.md` 与 `docs/plans/2026-05-09-simd-riscvv-qualification-plan.md`，把 non-x86 family 的 qualification 入口固定下来。
3. 继续维护 `docs/plans/2026-05-09-simd-x86-incremental-qualification-plan.md` 与 `docs/plans/2026-05-09-simd-x86-raw-parity-plan.md`，把 `SSE3 / SSE4.1 / SSE4.2 / AVX-512` 的 representative parity 约束继续守住。
4. `SSE2` 的 retire target 基线已经落盘；后续如果进入 promote / split，再刷新 `retire target` 清单。
