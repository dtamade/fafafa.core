# fafafa.core.span 候选审查与准入结果

> 该文件已从根 `docs/` 归档到 `docs/legacy/l0/`，避免和 today contract 文档混淆。
> 当前 strict non-SIMD L0 的总边界以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准；后续推进顺序以 `docs/fafafa.core.l0.roadmap.md` 为准。
> 本页记录 `span` 从候选审查到最小准入落地的结果，说明为什么只有当前这个 cut 被允许进入 strict L0。
> 更新：自 `2026-04-09` 起，`TReadOnlySpan2<T>` 已通过单独审查进入 `fafafa.core.span`；本页仍只保留最初“单段 span 准入”那一轮的历史语境。

## 当前结论

`span` 已经进入 strict L0，但只以一个非常克制的形态进入：

- 模块：`src/fafafa.core.span.pas`
- 合同：最小只读单段 `TReadOnlySpan<T>`
- 依赖：RTL + `fafafa.core.base`

理由不是 `span` 本身不基础，而是只有把 today semantics 从 collections 体系里切窄到这个程度，它才足够稳定、足够小，适合进入 L0。

## 已落地的范围

当前已经存在：

- `src/fafafa.core.span.pas`
- `docs/fafafa.core.span.md`
- `tests/fafafa.core.span/BuildOrTest.sh`
- `tests/fafafa.core.span/fafafa.core.span.testcase.pas`

当前稳定 API 是：

- `TReadOnlySpan<T>`
  - `FromPointer`
  - `Count`
  - `IsEmpty`
  - `Get`
  - `TryGet`
  - `GetPtr`
  - `SubSpan`

这些内容已经有独立测试入口和 today contract 文档，不再只是“纸面候选”。

### today semantics 存在于 `fafafa.core.collections.slice`

`src/fafafa.core.collections.slice.pas` 当前定义了两类核心视图：

- `TReadOnlySpan<T>`
  - `FromPointer`
  - `Count`
  - `IsEmpty`
  - `Get`
  - `TryGet`
  - `GetPtr`
  - `SubSpan`
- `TReadOnlySpan2<T>`
  - `FromTwo`
  - `ASpan`
  - `BSpan`
  - `Count`
  - `IsEmpty`
  - `Get`
  - `TryGet`
  - `GetPtr`
  - `GetBlock`
  - `SubSpan`

这已经很接近一个基础视图抽象，但它今天仍然位于 `collections` 命名空间下。

### 容器调用点说明为什么不能整包搬迁

当前显式消费它的代表性调用点包括：

- `TVec.SliceView`
  - 返回 `TReadOnlySpan<T>`
  - 对超界做“裁剪到可视图长度 / 空 span”风格处理
- `TVecDeque` 相关视图测试
  - 使用 `TReadOnlySpan2<T>`
  - 强依赖双段视图、跨 A/B 段 `SubSpan`、`GetBlock`

对应 today evidence：

- `tests/fafafa.core.collections/vec/Test_vec_span.pas`
- `tests/fafafa.core.collections/vecdeque/Test_vecdeque_span.pas`

这说明 today span semantics 不只是“原始只读视图”，还已经带上了容器和 ring-buffer 视角。

## 为什么最后只准入这个最小版本

### 1. 命名空间和职责还绑在 collections

当前模块名就是 `fafafa.core.collections.slice`。

如果把这个单元整包搬进 L0，就会把 collections 域 today behavior 一起带进来。

### 2. 单段与双段语义混在一起

`TReadOnlySpan<T>` 和 `TReadOnlySpan2<T>` 今天同时存在。

这在 collections 里没问题，但如果要进 L0，必须先回答：

- L0 第一版是否真的需要 `Span2`
- 双段视图是不是 ring-buffer / deque 特化
- `GetBlock` 这种 API 是否已经是容器布局优化接口，而不仅仅是基础表达

如果这些问题不先切清楚，`span` 一进入 L0 就会过宽。

### 3. today 行为并不完全等于未来 L0 contract

例如 `TVec.SliceView` 当前对超界采用的是“裁剪 + 空 span”风格，而 `TReadOnlySpan.SubSpan` 自身则是严格抛 `EOutOfRange`。

这说明：

- `SliceView` 是容器 API
- `Span/SubSpan` 是视图 contract

二者不能不加区分地直接合并成 `fafafa.core.span` 的 today contract。

## 当前准入版本怎么切

最终被批准并落地的第一版只包含：

- `TReadOnlySpan<T>`
- `FromPointer`
- `Count`
- `IsEmpty`
- `Get`
- `TryGet`
- `GetPtr`
- `SubSpan`

并明确保持这些边界：

- 只读
- 单段
- 不拥有内存
- 只是表达层 contract

## 当前明确不纳入的内容

当前仍然不纳入 strict L0 的有：

- `TReadOnlySpan2<T>`
- `GetBlock`
- ring-buffer / deque 双段逻辑
- 与容器 `SliceView` 的 today 行为绑定

这些更适合作为：

- collections 内部/上层视图
- 后续单独评估的 `span2` / segmented view

## 依赖切分结果

从 today code 看，`collections.slice` 依赖：

- `fafafa.core.base`
- `fafafa.core.collections.base`

如果未来要进入 strict L0，至少要把候选版本切到：

- 只依赖 RTL + L0
- 不再依赖 `collections.base`

当前 `fafafa.core.span` 已经按这个要求重切，依赖面收敛到了 RTL + `fafafa.core.base`。

## 当前建议

当前最合理的判断是：

- `span` 进入 strict L0 是成立的
- 但只在“最小只读单段 span contract”这个范围内成立
- `collections.slice` 不能直接原样搬进 strict L0
- 后续若要扩张到 `span2` / segmented view，必须重新做候选审查

换句话说：

**`span` 的候选阶段已经结束，但它的准入是一个经过降依赖、缩 API、切边界后的最小版本，而不是把 collections today semantics 直接搬进 L0。**
