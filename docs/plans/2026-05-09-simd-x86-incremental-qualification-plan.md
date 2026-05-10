# SIMD X86 Incremental Families Qualification Plan

**Goal:** 给 `SSE3 / SSSE3 / SSE4.1 / SSE4.2 / AVX-512` 建一条共享的 family qualification 路线，避免它们继续停留在“adapter 已有，但 leaf 状态和验证口径分散在历史脚本里”的状态。

**Architecture:** 这组 family 当前不做大迁移，只做资格化。统一原则是：stable truth source 仍在各自 adapter；只用 representative override + scalar parity + x86 bounded frontier 来判定它们是 `hold isolated`、还是具备继续拆 raw leaf 的资格。

**Tech Stack:** `src/fafafa.core.simd.sse3.pas`、`ssse3.pas`、`sse41.pas`、`sse42.pas`、`avx512.pas`，对应 `intrinsics.*` 单元，`BuildOrTest.sh impl-smoke-x86`，`TTestCase_DispatchAPI` representative suite，`check` / `gate`。

---

## 为什么这组要走共享计划

这几条 x86 family 有一个共同点：

- adapter 已经是 stable 主线
- raw leaf 还没有被 matrix 提升成可默认依赖的 active family
- 当前最有价值的证明，不是“再搬一批 primitive”，而是证明 representative override 的结构与语义没有漂移

所以这组不该一条条临时判断，而应该走同一条 qualification 路线。

## family 分工

### `SSE3`

- stable truth source：`src/fafafa.core.simd.sse3.pas`
- raw leaf：`src/fafafa.core.simd.intrinsics.sse3.pas`
- current disposition：`experimental isolated`
- 当前关键判断：
  - 代表性 override 继续 backend-owned
  - core slots 继续 clone `SSE2`

### `SSSE3`

- stable truth source：`src/fafafa.core.simd.ssse3.pas`
- raw leaf：no dedicated raw leaf target；当前就是 adapter-only in practice
- current disposition：adapter-only in practice
- 当前关键判断：
  - signed-byte representative slots 保持继承 SSE3/SSE2，不再保留冗余 backend-owned override
  - 继承链继续 clone `SSE3`

### `SSE4.1`

- stable truth source：`src/fafafa.core.simd.sse41.pas`
- raw leaf：`src/fafafa.core.simd.intrinsics.sse41.pas`
- current disposition：`experimental isolated`
- 当前关键判断：
  - representative hardware slots 继续 backend-owned
  - inherited reduction path 继续 clone `SSSE3`
  - `SelectF32x4` 现在只是 bitmask wrapper，真正的 native blend kernel 收在 `SSE41BlendVF32x4`

### `SSE4.2`

- stable truth source：`src/fafafa.core.simd.sse42.pas`
- raw leaf：`src/fafafa.core.simd.intrinsics.sse42.pas`
- current disposition：`experimental isolated`
- 当前关键判断：
  - 单槽 dedicated override 保持清晰
  - 其余继承链继续 clone `SSE4.1`

### `AVX-512`

- stable truth source：`src/fafafa.core.simd.avx512.pas`
- raw leaf：`src/fafafa.core.simd.intrinsics.avx512.pas`
- current disposition：`experimental isolated`
- 当前关键判断：
  - wide shift boundary contract 保持 backend-owned
  - maturity 仍受构建配置和验证范围限制

## 统一 qualification 规则

这组 family 暂时都按同一条规则推进：

1. 先守住 today adapter truth source
2. 再证明 representative override 没有漂移
3. 再证明 inherited clone-chain 没被误重绑
4. 如果这三条都稳定，再决定是否值得为某个 family 单独补 raw parity 文档

换句话说，这组当前不是“先 promote”，而是“先 hold green and qualify”。

## 当前 verification lane

### 高频 lane

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-x86
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

### representative source + semantic parity lane

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
```

### experimental isolation lane

```bash
python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line
```

## 这组 family 当前最重要的代表性契约

### `SSE3`

- source truth：
  - `Test_SSE3_RepresentativeOverrides_Reuse_SSE2_CoreSlots`
  - `Test_SSE3_RepresentativeSemanticParity_WithScalar_IfDispatchable`
- 当前目标：
  - hold green
  - fail if representative HADD / reduction ownership 漂移

### `SSSE3`

- source truth：
  - `Test_SSSE3_RepresentativeOverrides_Reuse_SSE3_CoreSlots`
  - `Test_SSSE3_RepresentativeSemanticParity_WithScalar_IfDispatchable`
- 当前目标：
  - hold green
  - 先补 raw-leaf 目标真相，不急着 promote
  - 不再让 MinI8x16 / MaxI8x16 形成独立 owned override，直接复用 SSE3/SSE2 core slots

### `SSE4.1`

- source truth：
  - `Test_SSE41_RepresentativeOverrides_Reuse_SSSE3_CoreSlots`
  - `Test_SSE41_RepresentativeSemanticParity_WithScalar_IfDispatchable`
- 当前目标：
  - hold green
  - keep representative hardware-slot ownership + scalar parity

### `SSE4.2`

- source truth：
  - `Test_SSE42_RepresentativeOverride_Reuse_SSE41_CoreSlots`
  - `Test_SSE42_RepresentativeSemanticParity_WithScalar_IfDispatchable`
- 当前目标：
  - hold green
  - dedicated compare override 不得丢失

### `AVX-512`

- source truth：
  - `Test_AVX512_U32x16_U64x8_ShiftBoundary_Contracts`
- 当前目标：
  - hold green
  - 只在 wide shift boundary / build maturity fresh red 时重开该 family

## Wave 内执行顺序

1. 先跑 `impl-smoke-x86`
2. 再看 `DispatchAPI` representative suite
3. 再跑 `check` / `gate`
4. 只有在 fresh red 明确落到某个 family 时，才单独开该 family 子计划

## 输出物

这轮 qualification 不要求马上新增 leaf。

输出物只要求：

- 每个 family 的 representative contract 清楚
- 继承链是否 clone 清楚
- 是否值得继续 promote / split 有明确下一动作

## 当前下一动作

- `SSE3 / SSE4.1 / SSE4.2 / AVX-512`：继续 `hold green`
- `SSSE3`：先把 raw-leaf 目标补成显式真相，再决定是否需要 leaf 计划

## 完成标准

这份共享计划完成后，这组 family 应该达到：

1. 不再是“分散在历史 smoke 里的隐性状态”
2. 每条 family 都有统一 qualification 入口
3. 只有 fresh red 或 promote 需要时，才继续拆成更细子计划
