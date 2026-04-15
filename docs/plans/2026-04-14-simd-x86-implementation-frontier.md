# SIMD X86 Implementation Frontier Plan

**Goal:** 在 `simd` 接口层已经收口的前提下，只做一轮 bounded x86 implementation 专审，优先尝试命中 `AVX512 U32x16/U64x8` 的真实实现红点；如果没有高信号红点，就补最小 implementation proof 并明确 stop condition，避免继续横向发散。

**Scope:**

- 只看 x86 backend implementation
- 不改 public API / ABI
- 不再讨论 available / dispatchable / active 命名
- 不回头重做 non-x86 审查

## Execution Order

1. 先用现有 `DispatchAPI` 跑 `AVX512 U32x16/U64x8` triage
2. 如果没有 fresh red point，补一个最小 implementation-proof test
3. 用 release 命令验证
4. 把结论同步到 closeout 文档
5. 停止继续扩面

## Primary Frontier

**Files:**

- `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- `src/fafafa.core.simd.avx512.register.inc`
- `src/fafafa.core.simd.avx512.u32x16_family.inc`
- `src/fafafa.core.simd.avx512.u64x8_family.inc`

**Bounded target:**

- `U32x16/U64x8` 的 shift boundary / invalid-count contract
- 只允许补 implementation proof，不顺手改别的 family

## Stop Condition

- 如果现有 parity/mapping 没有 fresh red point，就不继续翻 AVX512 全家桶
- 如果 `shift boundary` proof 补完且 fresh 验证通过，就把本轮 implementation frontier 视为收口完成
- 下一轮若还要继续，只能另开新的 bounded frontier

## Required Verification

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
git diff --check -- \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  docs/plans/2026-04-14-simd-x86-implementation-frontier.md \
  docs/fafafa.core.simd.closeout.md
```

## Execution Update (2026-04-14)

- fresh bounded triage 没有直接打出新的 AVX512 implementation red point
- 当前最高 ROI 的实现证据缺口是：`U32x16/U64x8` 的 shift boundary 只测了正常位移，没有把 `0 / width-1 / width` 和 invalid-count -> zero contract 显式钉住
- 本轮收口策略因此改为：补最小 implementation-proof test，而不是强行制造大范围实现改动
- 已落地 `Test_AVX512_U32x16_U64x8_ShiftBoundary_Contracts`，把 source truth 和运行时 `0 / width-1 / width` 边界一起钉住
- backup frontier 也已 bounded 收口：`AVX2 wide implementation` 没有 fresh red point，转而补了 `Test_AVX2_WideSelect_Parity_WithScalar_When_VectorAsmEnabled`
- 最后一个值得补齐的薄弱点也已收口：`DispatchAPI` 新增 `Test_AVX2_WideFma_ExactInputs_FollowsHalfComposition`，把 `FmaF32x16/FmaF64x8` 从“wide facade 自证”升级为“register source truth + wide-emulation half composition + exact-input runtime parity”
- 当前这轮 x86 implementation frontier 的结论是：**没有新的 bounded implementation bug 被 fresh 复现，但 implementation proof 已显著加强，可以停止继续扩面**
