# fafafa.core L0 Roadmap

> 本页是 strict non-SIMD L0 的稳定路线图入口。
> 它回答“L0 接下来按什么原则继续推进”，而不是记录某一轮 dated batch 的执行细节。

## 先看哪几份文档

如果你要判断 L0 当前到底是什么、接下来该怎么动，按这个顺序读：

1. `docs/ARCHITECTURE_LAYERS.md`
2. `docs/fafafa.core.l0.foundation.md`
3. `docs/fafafa.core.l0.roadmap.md`
4. `docs/audits/2026-04-11-l0-current-state-audit.md`
5. 对应模块文档，如 `docs/fafafa.core.span.md`、`docs/fafafa.core.atomic.md`

dated `docs/plans/YYYY-MM-DD-*.md` 只保留执行批次和 closeout 语境，不再承担长期路线图职责。

## 这份路线图的目标

L0 的目标不是继续变大，而是继续变准。

接下来 L0 的工作应当同时满足三件事：

- 让边界更稳定，而不是把更多主题塞进来
- 让 source-of-truth 更清楚，而不是继续依赖 dated plan 导航
- 让验证和 hygiene 更硬，而不是只在 closeout 时临时补救

## 当前稳定 L0 面

当前 strict non-SIMD L0 已稳定覆盖：

- `fafafa.core.settings.inc`
- `fafafa.core.base`
- `fafafa.core.contracts`
- `fafafa.core.option.base` / `fafafa.core.option`
- `fafafa.core.result` / `fafafa.core.result.facade`
- `fafafa.core.span`
- `fafafa.core.bits`
- `fafafa.core.platform`
- `fafafa.core.layout`
- `fafafa.core.endian`
- `fafafa.core.atomic.core` / `fafafa.core.atomic.base` / `fafafa.core.atomic` / `fafafa.core.atomic.compat`
- `fafafa.core.mem.allocator.base`

这条边界以 `docs/fafafa.core.l0.foundation.md` 为准；本页不重复定义模块 API，只定义后续推进方式。

## 当前 L0 文档地图

当前稳定的 L0 文档面可以直接按下面导航：

- 核心文档组
  - `docs/ARCHITECTURE_LAYERS.md`
  - `docs/fafafa.core.l0.foundation.md`
  - `docs/fafafa.core.l0.roadmap.md`
  - `docs/audits/2026-04-11-l0-current-state-audit.md`
- 模块文档
  - `docs/fafafa.core.base.md`
  - `docs/fafafa.core.contracts.md`
  - `docs/fafafa.core.option.md`
  - `docs/fafafa.core.result.md`
  - `docs/fafafa.core.span.md`
  - `docs/fafafa.core.bits.md`
  - `docs/fafafa.core.platform.md`
  - `docs/fafafa.core.layout.md`
  - `docs/fafafa.core.endian.md`
  - `docs/fafafa.core.atomic.md`
  - `docs/fafafa.core.mem.md`
- 对应测试入口
  - `tests/fafafa.core.base/README.md`
  - `tests/fafafa.core.contracts/README.md`
  - `tests/fafafa.core.option/README.md`
  - `tests/fafafa.core.result/README.md`
  - `tests/fafafa.core.span/README.md`
  - `tests/fafafa.core.bits/README.md`
  - `tests/fafafa.core.platform/README.md`
  - `tests/fafafa.core.layout/README.md`
  - `tests/fafafa.core.endian/README.md`
  - `tests/fafafa.core.atomic/README.md`
  - `tests/fafafa.core.mem.allocator.foundation/README.md`

## 当前 post-merge 姿态

- strict non-SIMD L0 已经通过 PR `#9` 合并到 `main`
- 当前唯一 L0 worktree 仍固定为 `l0-mainline`；today head 以 `docs/audits/2026-04-11-l0-current-state-audit.md` 里记录的本地 `main` / `origin/main` / worktree `HEAD` 三者区分为准，不要再简化写成 `l0-mainline -> origin/main`
- 当前 focus 不再是 replay / merge-prep，而是 current-entry 稳定性和 verification hardening
- 当前没有新的 admission 批次；不要为了制造进展感继续扩张 L0 面
- 唯一仍值得保留在路线图里的候选话题，是面向 deque / ring-buffer 语境的更宽 `segmented span` 方向；它现在只处于 evaluation-only 状态，不是 admission in progress，也不等于否认 `fafafa.core.span` 里今天已经落地的最小 `TReadOnlySpan2<T>` cut

## 当前不在路线图里的事情

以下主题当前不属于 strict L0 扩张目标：

- `fafafa.core.simd*`
- `fafafa.core.collections*`
- `fafafa.core.sync*`
- `fafafa.core.fs*`
- `fafafa.core.socket*`
- `fafafa.core.lockfree*`
- `fafafa.core.mem.allocator.foundation` 及具体 allocator backend
- `collections.slice` 的容器 `SliceView` 语义

原因不是这些模块不重要，而是它们已经超出“最小基础内核”的职责边界。

## 路线图设计

### Phase 1: kernel admission

状态：`completed`

这一阶段已经完成的事情：

- `contracts`、`bits`、`layout`、`endian` 进入 strict L0
- `platform` 以最小静态表达层进入 strict L0
- `fafafa.core.span` 以最小只读 view contract 进入 strict L0；当前模块内已经落地的 `TReadOnlySpan2<T>` 也只按“最小双段只读 cut”来理解，而不是更宽的 segmented-span 扩张许可
- `atomic` / `result` / `mem allocator contract` 的 today contract 已重新定锚

### Phase 2: source-of-truth hardening

状态：`active`

这是当前唯一合理的主线。

目标：

- 建立稳定的 L0 文档组，不再让 dated closeout 充当长期导航
- 保持 `foundation`、模块文档、`INDEX`、`README`、`worker` 叙述一致
- 继续下沉或标记历史文档，避免历史候选结论重新上浮成 current-entry
- 在主线合并完成之后，及时把 merge-prep 文档降级成历史 closeout，而不是继续让它们占据快速入口

完成标准：

- L0 长期入口固定为 `ARCHITECTURE_LAYERS` + `foundation` + `roadmap`
- 最新 audit 只负责描述现状，不承担路线设计
- dated plans 只保留执行批次语境

### Phase 3: verification and hygiene hardening

状态：`active`

目标：

- 把 strict L0 的 gate、测试入口、include 规则和文档边界持续保持在可验证状态
- 对偶发波动先保留证据，再决定是否值得动生产代码

当前要求：

- strict L0 聚合 gate 持续可运行
- `git diff --check` 持续为通过状态
- strict L0 的源码和测试入口持续遵守 `settings.inc` 单源规则
- compat surface 必须在模块文档里明确标注，不得伪装成 today recommended API
- Windows exact native evidence 只接受 GitHub Actions 作为证据来源
- 只有当 strict L0 出现非文档代码/测试变化，或有人明确要求 exact `HEAD` 证据时，才重新触发 GH native evidence
- 当前日常维护闭环固定为：strict L0 gate + `git diff --check` + runtime matrix + native closeout stack

### Phase 4: candidate-driven admission only

状态：`conditional`

当前没有新的 admission-in-progress 候选。

唯一保留在路线图中的候选话题，是 `fafafa.core.span` 之外更宽的 `segmented span` 方向。它当前只满足“值得写设计、值得审查”，还不满足“应立刻实现 / 应立刻准入”；今天已经落地在 `fafafa.core.span` 里的最小 `TReadOnlySpan2<T>` cut 仍按 current-entry 对待，不应和这个未来候选方向混写。

只有在它能够同时证明下面这些条件时，才值得从 evaluation 进入新的 admission 批次：

- 不依赖 `collections.slice` 的容器切片行为才能成立
- 不把 deque / ring-buffer 的 policy、block layout 和 consumer convenience 一起带进 strict L0
- 可以被多个上层域自然复用，而不是只解决 deque 双段视图这一个 consumer 问题
- 可以定义成小而硬的双段只读 contract，并补齐代码、测试、模块文档、foundation、roadmap 和 audit

后续只有在出现真正满足条件的新主题时，才进入新的 admission 批次。准入必须同时满足：

- 只依赖 RTL 和已确认的 L0 单元
- 不是容器、服务、runtime dispatch、registry 或 policy
- 能被多个上层模块自然复用
- API 面足够小，且长期稳定
- 能同时补齐代码、测试、模块文档、foundation、roadmap、audit

只要其中一条不满足，就不该进入 strict L0。

## 未来如果再开新批次，应按这个顺序

1. 先写 candidate/admission 设计，说明为什么它值得进 L0。
2. 再写最小 cut，不接受“先放进来以后再收缩”。
3. 再补测试和模块文档。
4. 再更新 `foundation`、`roadmap` 和最新 audit。
5. 最后才做聚合验证和 closeout。

这五步缺一不可。否则只是在制造下一轮控制面漂移。

## L0 文档组的职责分工

为了避免继续混乱，L0 相关文档从现在起按下面分工维护：

- `docs/ARCHITECTURE_LAYERS.md`
  - 回答：L0 在全仓分层里处于哪里
- `docs/fafafa.core.l0.foundation.md`
  - 回答：L0 当前包含什么，不包含什么
- `docs/fafafa.core.l0.roadmap.md`
  - 回答：L0 接下来按什么顺序推进
- `docs/audits/YYYY-MM-DD-l0-*.md`
  - 回答：某个时点上实际状态是什么
- `docs/plans/YYYY-MM-DD-l0-*.md`
  - 回答：某一轮批次当时是怎么执行的
- `docs/legacy/l0/*`
  - 回答：历史候选、历史 closeout 当时是怎么判断的

## 当前结论

L0 现在最需要的不是“再收更多模块”，而是把已经确定的边界、文档和验证口径长期稳定下来。

因此，这份路线图的结论很简单：

- 当前继续做 L0，优先做文档治理、hygiene、验证稳定性
- 当前不要为了制造进展感而继续扩张 L0 面
- 未来若再开 admission，必须走完整的 candidate-driven 流程
