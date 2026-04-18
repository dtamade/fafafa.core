# strict L0 候选审查：platform / span

> 当前 strict non-SIMD L0 的正式边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
> 本页只负责回答一个问题：`platform` / `span` 这两个名字，是否已经具备进入 strict L0 的实施条件。

## 审查结论

当前结论很明确：

- `platform`：**尚未形成可直接准入的单独模块**
- `span`：**已按批准 cut 落地为 strict L0 的最小只读单段模块**

也就是说，这轮评审最终得到了两个不同结果：

1. `platform` 继续 deferred
2. `span` 只以最小 read-only single-segment contract 的形态准入并实现

## 证据摘要

### `platform`

当前仓库里没有发现明确的 `src/fafafa.core.platform.pas` 或对应测试入口：

- 未发现 `src/fafafa.core.platform*.pas`
- 未发现 `tests/fafafa.core.platform/BuildOrTest.sh`
- 现有命中主要是：
  - `src/fafafa.core.os.pas` 里的 `TPlatformInfo` 与 `os_platform_info`
  - `tests/fafafa.core.os/BuildOrTest.sh` 与 `fafafa.core.os.testcase.pas`
  - 平台差异 include / 平台实现细节
  - `docs/fafafa.core.platform.candidate.md`

这说明 `platform` 现在更像一个横切关注点，而不是一个已经收敛成“可稳定暴露的小 API 模块”的候选。更重要的是，today 仓库里的现实承载者其实是 `fafafa.core.os` 这种 system facade，而不是一个极小 platform contract。

### `span`

当前已经存在独立的 `span` strict L0 模块与测试入口：

- `src/fafafa.core.span.pas`
- `docs/fafafa.core.span.md`
- `tests/fafafa.core.span/BuildOrTest.sh`
- `tests/fafafa.core.span/fafafa.core.span.testcase.pas`

当前落地的 API 严格限制为：

- `TReadOnlySpan<T>`
  - `FromPointer`
  - `Count`
  - `IsEmpty`
  - `Get`
  - `TryGet`
  - `GetPtr`
  - `SubSpan`

这说明 `span` 已经完成从 collections today semantics 到 strict L0 基础视图 contract 的最小切分。

## 为什么只有这个 cut 能进 L0

根据 `docs/ARCHITECTURE_LAYERS.md` 与 `docs/fafafa.core.l0.foundation.md` 的准入规则，一个模块进入 L0 至少要满足：

- 只依赖 RTL 和已确认 L0
- 解决的是全框架共用的基础表达问题
- API 面足够小、长期稳定
- 不是容器、服务、dispatch 或 registry

### `platform` 当前的主要阻塞

- 还没有明确模块边界
- 很容易把“平台实现细节集合”误做成“大而泛”的工具箱
- 如果直接准入，风险是把 OS / runtime / feature detection 之类非 L0 语义一起带进来
- 现有测试入口覆盖的是 env/path/system probe/capability 行为，不是独立的最小 platform contract

### `span` 被切窄后，阻塞已经解除

- 新模块只依赖 RTL + `fafafa.core.base`
- 只承认最小只读单段视图，不接管容器策略
- API 面已经收缩到稳定的小合同
- 越界异常合同被测试入口锁定，具备 today contract 的可验证性

## 当前仍然不进入 L0 的 `span` 相关内容

以下内容继续留在 collections 域或后续候选审查里：

- `TReadOnlySpan2<T>`
- `GetBlock`
- deque / ring-buffer 双段视图
- `TVec` / `TVecDeque` 的 `SliceView` today behavior
- 直接把 `fafafa.core.collections.slice` 改名搬迁进 `fafafa.core.span`

换句话说，这轮准入通过的不是“整个 span 世界”，而只是一个够小、够硬的基础表达层 cut。

## 如果未来还要推进，该怎么切

### `platform` 的推荐切法

不要先做“大一统 platform”。

更合理的方式是先回答三个问题：

1. 到底要暴露哪一类平台信息？
2. 这些信息是否真的是跨模块、跨域共用的基础语义？
3. 这些 API 能否只依赖 RTL + L0，而不把 IO / env / time / sync 的实现细节带进来？

只有当答案收敛成一个极小且稳定的 API 面时，才值得产生 `fafafa.core.platform`。

如果后续真要从 deferred 变成可实施，最少也要先满足：

- 独立源码入口：`src/fafafa.core.platform.pas`
- 独立测试入口：`tests/fafafa.core.platform/BuildOrTest.*`
- API 只锁定静态平台表达，不混入 env/path/system probe
- 不复用 `fafafa.core.os` 作为“伪 platform 模块”

### `span` 的后续推荐切法

当前第一版已经按这个原则落地。后续如果还要扩展，只能单独评估：

- `span2` / segmented view 是否真的属于 L0
- 可写视图是否需要独立合同
- collections 容器接口与 L0 视图合同之间的边界是否仍然清晰

## 当前建议

### 现在不该直接做的

- 直接新建 `fafafa.core.platform`
- 直接把 `TReadOnlySpan2<T>` / `GetBlock` / 容器 `SliceView` 一起塞进 `fafafa.core.span`
- 未经新的准入审查继续扩大 strict L0 范围

## 下一步建议

下一轮如果继续推进，建议目标改成：

- **Task A：platform 候选 API 壳面收敛**
- **Task B：segmented span / span2 是否值得独立候选**
- **Task C：只在新的批准后扩张 `span` 边界**

换句话说，当前该收口的已经收口；`platform` 这边也已经完成“为什么继续 deferred”的证据闭环。下一轮如果还想推进，重点不该是直接写原型，而是先把 API 壳面压到足够小。
