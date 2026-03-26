# fafafa.core.span 候选审查

> 当前 strict non-SIMD L0 的总边界以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
> 本页不代表 `fafafa.core.span` 已经存在；它只负责审查“如果要做，这个候选是否值得进入 strict L0”。

## 当前结论

`span` 有继续评估的价值，但今天还不能直接进入 strict L0。

理由不是它不基础，而是 today semantics 仍然绑在 collections 体系里，还没有被切成一个独立、足够小的基础表达层。

## 现有证据

### 仓库里没有现成的 `fafafa.core.span`

当前没有发现：

- `src/fafafa.core.span.pas`
- `tests/fafafa.core.span/BuildOrTest.sh`
- 对应 README / 模块文档 / 测试入口

这意味着 `span` 仍然只是一个候选方向。

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

### 容器调用点也说明它还带有 collections 语义

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

## 为什么它现在还不适合直接进 strict L0

### 1. 命名空间和职责还绑在 collections

当前模块名就是 `fafafa.core.collections.slice`。

只要它还留在这个结构里，就说明它的 today contract 仍然属于 collections 域，而不是 strict L0 foundation kernel。

### 2. 单段与双段语义混在一起

`TReadOnlySpan<T>` 和 `TReadOnlySpan2<T>` 今天同时存在。

这在 collections 里没问题，但如果要进 L0，必须先回答：

- L0 第一版是否真的需要 `Span2`
- 双段视图是不是 ring-buffer / deque 特化
- `GetBlock` 这种 API 是否已经是容器布局优化接口，而不仅仅是基础表达

如果这些问题没先切清楚，`span` 很容易一上来就太宽。

### 3. today 行为并不完全等于未来 L0 contract

例如 `TVec.SliceView` 当前对超界采用的是“裁剪 + 空 span”风格，而 `TReadOnlySpan.SubSpan` 自身则是严格抛 `EOutOfRange`。

这说明：

- `SliceView` 是容器 API
- `Span/SubSpan` 是视图 contract

二者不能不加区分地直接合并成未来 `fafafa.core.span` 的 today contract。

## 如果未来要做，推荐怎么切

### 推荐第一版只做最小只读单段 span

第一版若要评估进入 strict L0，推荐只包含：

- `TReadOnlySpan<T>`
- `FromPointer`
- `Count`
- `IsEmpty`
- `Get`
- `TryGet`
- `GetPtr`
- `SubSpan`

并明确：

- 只读
- 单段
- 不拥有内存
- 只是表达层 contract

### 第一版暂不纳入的内容

先不要带：

- `TReadOnlySpan2<T>`
- `GetBlock`
- ring-buffer / deque 双段逻辑
- 与容器 `SliceView` 的 today 行为绑定

这些更适合作为：

- collections 内部/上层视图
- 后续单独评估的 `span2` / segmented view

## 依赖与阻塞点

从 today code 看，`collections.slice` 依赖：

- `fafafa.core.base`
- `fafafa.core.collections.base`

如果未来要进入 strict L0，至少要把候选版本切到：

- 只依赖 RTL + L0
- 不再依赖 `collections.base`

这意味着不能直接复制当前单元，而需要做“降依赖重切”。

## 当前建议

当前最合理的判断是：

- `span` 值得继续推进准入设计
- 但只能从“最小只读单段 span contract”开始
- `collections.slice` 不能直接原样搬进 strict L0

换句话说：

**`span` 是有潜力的下一轮候选，但前提是先把它从 collections today semantics 中切出来，而不是直接搬运。**
