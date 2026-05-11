# SIMD X86 Raw Parity Baseline

**Goal:** 把 `SSE3 / SSE4.1 / SSE4.2 / AVX-512` 的 raw parity 口径写成单独基线，避免这组 x86 incremental family 只停留在“有 smoke、看起来也绿”的状态。

**Scope:** `SSE3`、`SSE4.1`、`SSE4.2`、`AVX-512`。`SSSE3` 仍保持 adapter-only，不进入 dedicated raw leaf 目标。

**Architecture:** 这不是 promote 计划，也不是把这几条 family 直接接成 raw leaf。它只冻结现有 representative parity lane、对应的 source truth、以及未来如果 fresh red 出现时该往哪里看。

---

## 当前 baseline

| Family | Current contract | Raw parity lane | Notes |
| --- | --- | --- | --- |
| `SSE3` | representative overrides continue to clone `SSE2` core slots | `Test_SSE3_RepresentativeSemanticParity_WithScalar_IfDispatchable` | 继续把 HADD / reduction / normalize 这类代表性路径守成 parity baseline |
| `SSSE3` | adapter-only in practice | inherited SSE3/SSE2 core slots | 没有 dedicated raw leaf target，不进入单独 raw parity 计划 |
| `SSE4.1` | representative hardware slots remain backend-owned | `Test_SSE41_RepresentativeSemanticParity_WithScalar_IfDispatchable` | 保持 `MulI32x4 / DotF32x4 / RoundF32x4 / SelectF32x4 / NormalizeF32x4 / NormalizeF32x3 / CmpEqI64x2` 这组代表性 lane |
| `SSE4.2` | dedicated compare override stays explicit | `Test_SSE42_RepresentativeSemanticParity_WithScalar_IfDispatchable` | 继续钉住 `CmpGtI64x2` |
| `AVX-512` | wide shift boundary remains backend-owned | `Test_AVX512_U32x16_U64x8_ShiftBoundary_Contracts` | 只冻结 shift boundary contract，不把它改写成更宽的实验面 |

## 触发规则

这份 baseline 只记录现在的 parity 口径。任何 family 只有在下面情况之一出现时才重新开线：

1. fresh red 直接落到该 family
2. family 状态从 `experimental isolated` 变化成可 promote
3. 代表性 parity lane 需要扩成新的 raw leaf 子集

## 不做什么

- 不把 `SSSE3` 重新写成待补 raw leaf
- 不把 smoke 当成 parity
- 不把 `hold green` 误写成 `active leaf`
- 不因为某个 family 已有 smoke 就删掉 adapter 责任

## Verification lane

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-x86
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

## Completion criteria

这份文档完成时，应该满足：

1. `SSE3 / SSE4.1 / SSE4.2 / AVX-512` 的 representative parity 口径已经单独冻结
2. `family matrix` 可以直接引用这里，而不是只引用 smoke
3. `SSSE3` 继续明确为 adapter-only，不会被误回写成 raw leaf 目标
