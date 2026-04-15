# L0 Segmented Span Evaluation Plan

> 这是一个 **evaluation-only** 设计计划，不代表 deque / ring-buffer 语境下更宽的 `segmented span` 方向已经进入 strict non-SIMD L0。
> 它也不否认 `fafafa.core.span` 里今天已经存在的最小 `TReadOnlySpan2<T>` current-entry cut。

## 目标

把 `segmented span` 从“历史上反复被提起的候选词”收束成一个可以被审查的评估对象：

- 它到底试图解决什么基础表达问题
- 它和 `collections.slice` / deque 双段视图到底怎么切边界
- 在什么条件下它才值得进入 future admission

## 当前结论

今天不做实现，也不做 admission。

当前只做三件事：

1. 承认它是唯一还值得继续保留在路线图里的候选话题
2. 明确它现在仍然是 **evaluation-only**
3. 防止历史 closeout 语境把“当前最小 `TReadOnlySpan2<T>` cut”与“未来更宽的 segmented-span 扩张”混写成一件事

## 必须满足的准入条件

如果未来要把它从 evaluation 推进到 admission，至少要同时满足：

- 只依赖 RTL 和已确认的 strict L0 单元
- 不依赖 `collections.slice` 的容器 API 才能成立
- 不携带 deque / ring-buffer 的 policy、block layout 或 mutation helper
- API 面只保留“最小双段只读视图 contract”
- 能被多个上层域复用，而不是只为某个容器局部问题服务
- 能补齐代码、测试、模块文档、foundation、roadmap、audit 的整套 current-entry

## 明确不接受的方向

下面这些方向即使和 `span2` / segmented view 有关，也不应借机进入 strict L0：

- 容器 `SliceView`
- deque block 管理辅助
- ring-buffer policy helper
- 面向特定容器的 cursor / iterator sugar
- 依赖 runtime dispatch 或 service registry 的视图封装

## 后续评估顺序

1. 先确定最小语义模型：它是不是“两个只读段 + 总长度 + 最小索引语义”
2. 再确认和 `collections.slice` 的边界：哪些保留在 collections，哪些才可能属于 strict L0
3. 再决定是否值得写 prototype / contract tests
4. 只有前三步都通过，才值得立新的 admission plan

## 候选命名 / API 草图（仅供评估）

为了避免把 today current-entry 的 `TReadOnlySpan2<T>` 和 future candidate 混写，后续如果真的要继续设计，更适合先用一个**占位候选名**来讨论，比如：

- `TSegmentedReadOnlySpan<T>`（仅作设计讨论名，不代表最终命名）

它如果成立，候选 API 也只能先从下面这些最小点开始审查：

- `FromTwo`
- `Count`
- `IsEmpty`
- `TryGet`
- `GetPtr`
- `GetBlock`
- `SubSpan`

默认不把任何容器 cursor、mutation helper、layout policy 或 `SliceView` 风格 sugar 放进这个候选草图里。

## 现在不做什么

- 不新增 deque / ring-buffer 导向的 segmented-span 代码
- 不扩写当前 `fafafa.core.span` 里的最小 `TReadOnlySpan2<T>` cut
- 不移动 `collections.slice` 现有语义
- 不把历史候选文档重新抬升为 current-entry
- 不因为“路线图里需要新东西”就人为扩大 strict L0
