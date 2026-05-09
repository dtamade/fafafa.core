# SIMD AVX2 Active-Leaf Sample Plan

**Goal:** 把 `AVX2` 明确固化成 whole-module refactor 的正样板，说明“backend adapter + active leaf” 这条路径在本仓库里到底怎样才算优雅、稳定、可复制。

**Architecture:** `AVX2` 不是要继续扩成新的例外层，而是要作为“stable adapter 正常依赖 active leaf”的样板。`src/fafafa.core.simd.avx2.pas` 继续是 stable truth source，`src/fafafa.core.simd.intrinsics.avx2.pas` 继续是 active raw leaf；这条 family 的任务不是大迁移，而是把“正确模式”写清楚并守住。

**Tech Stack:** `src/fafafa.core.simd.avx2.pas`、`src/fafafa.core.simd.intrinsics.avx2.pas`、`tests/fafafa.core.simd/BuildOrTest.sh`、`tests/fafafa.core.simd/fafafa.core.simd.intrinsics.avx2.testcase.pas`、coverage / gate / x86 smoke 文档链。

---

## 为什么 AVX2 要先补成样板

当前 whole-module 计划里，`AVX2` 是最接近“目标形态已经成立”的 family：

- stable truth source 清楚：`src/fafafa.core.simd.avx2.pas`
- raw leaf 状态清楚：`src/fafafa.core.simd.intrinsics.avx2.pas` 已经是 `active leaf`
- 有专门测试与 coverage 文档，不只是隔离 smoke
- 已被 `check`、`gate`、`impl-smoke-x86` 和 bounded frontier 一起覆盖

这意味着 `AVX2` 最适合回答一个关键问题：

> 当某个 family 已经允许 stable adapter 默认依赖 raw leaf 时，仓库里正确的结构样板应该长什么样？

## 当前稳定判断

### truth source

- stable truth source：`src/fafafa.core.simd.avx2.pas`
- active leaf：`src/fafafa.core.simd.intrinsics.avx2.pas`

### 这条 family 当前已经证明了什么

- adapter 仍然是 today contract 的唯一对外真相源
- raw leaf 可以活跃维护，但不会反客为主变成 public/control surface
- `AVX2` 已经证明“active leaf` 不等于 `public truth source`，两者可以稳定共存

### 当前 verification lane

- `check_avx2_backend_smoke`
- `coverage`
- `check`
- `gate`
- `impl-smoke-x86`
- `TTestCase_DispatchAPI` bounded frontier
- `TTestCase_AVX2IntrinsicsFallback`

## 这条样板要守住什么

### 1. adapter 仍然是 today contract

`src/fafafa.core.simd.avx2.pas` 必须继续承担：

- façade 级 `TVec*` / `TMask*` 语义
- backend 注册
- dispatch slot 填充
- wide emulation / half composition
- façade helper

不要因为 `intrinsics.avx2` 已是 active leaf，就把对外语义直接迁去 leaf。

### 2. active leaf 只承接 raw ISA 语义

`src/fafafa.core.simd.intrinsics.avx2.pas` 应继续只承接：

- `TM256` 风格 raw primitive
- raw load/store
- raw set/zero/broadcast
- raw arithmetic / bitwise / compare building block
- raw pack/unpack/shuffle/cast

它不应开始承接：

- backend 注册
- runtime / dispatch
- façade helper
- `TVec*` / `TMask*` contract

### 3. AVX2 继续作为可复制模式，而不是再变成特例

这里最重要的不是“AVX2 已经很好”，而是后续别的 family 要知道：

- 什么情况下可以 promote 成 `active leaf`
- promote 后 adapter 和 leaf 的职责如何分账
- 如何用 coverage + smoke + gate 持续守住这条边界

## 当前最有价值的证据

### source-side

- `docs/SIMD_BACKEND_TRUTH.md`：`AVX2` 已列为 stable backend truth source
- `docs/SIMD_INTRINSICS_DISPOSITION.md`：`intrinsics.avx2` 已列为 `active leaf`
- `docs/fafafa.core.simd.intrinsics.avx2.md`：已有 raw API 与 fallback 语义说明

### runtime-side

- `docs/fafafa.core.simd.implementation-matrix.md` 已把 `AVX2 wide select` 与 `AVX2 wide FMA composition` 记成 bounded frontier
- `impl-smoke-x86` 当前默认会覆盖：
  - `SelectF32x16 / SelectF64x8`
  - `FmaF32x16 / FmaF64x8`

## 这条样板的执行目标

## Task 1：固定 AVX2 的样板定位

输出：

- 这份文档本身
- `family matrix` 中 `AVX2` 行保持为 `Wave 3 sample`

完成标准：

- 后续不会再有人把 `AVX2` 理解成“只是又一个 adapter”
- 也不会把它误写成“leaf 已经可以替代 adapter”

## Task 2：把验证口径固定成可复制模式

Run:

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh coverage
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-x86
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

说明：

- `coverage` 保证 raw API 与测试映射没有漂移
- `check` / `gate` 保证 stable lane 还绿
- `impl-smoke-x86` 保证 bounded frontier 没跑丢

## Task 3：把 AVX2 作为其他 family 的 promote 参照物

后续如果 `SSE2`、`NEON` 或 `RISCVV` 有子集想进入 `active leaf`，先回答：

1. 它有没有像 `AVX2` 一样的 raw tests
2. 它有没有自己的 bounded frontier proof
3. 它有没有把 adapter 和 raw leaf 的 today contract 分开

只要这 3 条答不出来，就还不能说“像 AVX2 一样 promote”。

## 不做什么

- 不因为它已经是 active leaf，就把 `AVX2` 再重构成“adapter 几乎为空壳”
- 不重开泛 AVX2 审查，除非 fresh red 落到它
- 不把 `AVX2` 当前样板偷换成整个仓库的唯一范式

## 完成标准

这份样板文档完成后，`AVX2` 在 whole-module refactor 中应被理解为：

- 一个已经成立的正样板
- 一个后续 family promote 时的参照物
- 一个需要守住边界，而不是继续大拆的 family
