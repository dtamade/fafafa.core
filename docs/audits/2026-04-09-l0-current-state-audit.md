# 2026-04-09 L0 Current State Audit

## Summary

- 当前 strict non-SIMD L0 的权威边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
- 当前 strict non-SIMD L0 的稳定路线图现在固定为 `docs/fafafa.core.l0.roadmap.md`。
- `fafafa.core.span` 现在正式承载最小只读单段 `span` 与双段 `span2` contract。
- 当前 L0 执行面仍然是 `l0-main-tail-cleanup-20260408` worktree。
- 原先混入该 worktree 的 sync/fs/socket runner sidecar 已安全转移到临时 branch `l0-sidecar-handoff-20260409`，不再阻塞 strict L0 继续推进。
- 当前没有新的获批 L0 准入候选；“还缺什么”主要是 merge hygiene、跨平台验证一致性和 compat surface 继续收口，而不是再加模块。

## Current L0 Surface

- 基础语义：`settings.inc`、`base`、`contracts`、`option`、`result`
- 视图表达：`span`、`span2`
- 原始数据语义：`bits`、`platform`、`layout`、`endian`
- 内存模型：`atomic.core`、`atomic.base`、`atomic`、`atomic.compat`
- 分配契约：`mem.allocator.base`

## Current Module Map

| 组 | 当前模块 | 当前判断 |
|----|----------|----------|
| 基础语义 | `fafafa.core.base` / `fafafa.core.contracts` / `fafafa.core.option*` / `fafafa.core.result*` | 已稳定，职责清楚，当前重点不是扩 API，而是继续收紧 compat 叙述 |
| 视图表达 | `fafafa.core.span` | 已稳定承载最小 `span` / `span2` 只读 contract，不再等同于 collections `SliceView` |
| 原始数据语义 | `fafafa.core.bits` / `fafafa.core.platform` / `fafafa.core.layout` / `fafafa.core.endian` | 已形成独立 L0 组，source-of-truth 和测试入口已收口 |
| 内存模型 | `fafafa.core.atomic.core` / `base` / `atomic` / `compat` | 代码面可用，当前主要改进空间在 compat surface 标识和长期波动证据保留 |
| 分配契约 | `fafafa.core.mem.allocator.base` | contract 边界清楚；`foundation` 与具体 backend 已明确退回 mem 域低层 facade / backend 语义 |

## What Is Not Missing

如果问题是“L0 还缺少哪些显然应该补进来的模块”，当前答案是：没有。

当前没有任何主题同时满足下面几条：

- 只依赖 RTL 和已确认的 L0 单元
- 不是容器、服务、runtime dispatch、registry 或 policy
- 能被多个上层模块自然复用
- API 面足够小，且长期稳定

所以，L0 现在不缺“下一个应该立刻并入的模块”。继续硬塞新主题，只会重新制造控制面漂移。

## What Is Still Missing

L0 当前真正还缺的是硬化项，而不是模块数：

### 1. Merge hygiene is still a process task

- 当前 L0 worktree 已整理干净，但根 `main` 工作树仍然是用户脏状态。
- 这意味着 L0 本身已经可以作为独立 merge candidate 准备审阅，但实际并回主线前仍需要一个明确的集成窗口。

### 2. Cross-platform verification is not symmetric yet

- 当前 fresh gate 是在 Linux/macOS shell 路径上完成的。
- Windows `.bat` 路径，尤其是 mem 相关 runner，仍然存在脚本行为差异。
- 这不是当前 L0 文档治理的 blocker，但它仍然是合并到主线前应补的一项 confidence gap。

### 3. Compat surface still needs continued discipline

- `atomic.compat` 仍然存在，必须继续被标成 legacy bridge，而不是 today 推荐入口。
- `result` 侧的兼容 API 仍需继续保持“能用但不鼓励扩散”的文档口径。
- `mem.allocator.foundation` 虽然已经退回 mem 域 facade，但后续文档和测试入口仍要持续防止它重新被误读成 strict L0 本体。

### 4. Verification evidence should stay reproducible

- 当前 gate 已通过，但后续若出现新的聚合波动，尤其是 `atomic`，要优先保留失败日志和 testcase 顺序。
- L0 不需要“感觉上稳定”；L0 需要的是能重复拿出证据的稳定性。

## Current Findings

### 1. span2 is now small enough for L0

- 新增的是 read-only segmented view contract，不是 container API。
- 依赖面保持在 RTL + `fafafa.core.base`。
- `collections.slice` 继续保留 Layer 1 的 container `SliceView` 语义。

### 2. atomic/result/mem allocator boundary needed wording cleanup more than code churn

- `atomic.compat` 继续存在，但只能被视作 legacy bridge。
- `AndResult` / `OrResult` 继续存在，但只能被视作 deprecated compatibility API。
- `mem.allocator.foundation` 继续是 mem 域 low-level facade，不回退成 strict L0 source-of-truth。

### 3. Control-plane drift was real

- `workers/worker1.md` 在本轮之前仍携带过多 tail-cleanup / non-L0 historical noise。
- `docs/INDEX.md` 之前曾把 `2026-04-07` rescue 文档当作当前 follow-up 入口；现在已改为稳定的 `foundation + roadmap + audit` 三件套。
- dated closeout 现在只保留批次执行语境，不再继续承担长期路线图职责。

### 4. Quality has room to improve, but it is no longer architecture confusion

当前剩下的提升空间主要是 hygiene 和一致性，不再是“L0 到底是什么”的架构级混乱：

- 继续压缩 compat surface 的误读空间
- 继续减少 mem 测试脚本在不同平台上的行为分叉
- 继续让模块文档、测试 README、worker 控制面和 audit 同步更新
- 保持新候选只能走 candidate-driven admission，而不是靠 dated closeout 偷渡

## Merge Readiness

如果问题是“L0 当前能不能作为一个独立工作面准备合并审阅”，当前答案是：可以。

当前满足：

- 边界已经固定在 `foundation + roadmap + audit`
- strict L0 模块文档和测试 README 已按统一口径收口
- 当前 worktree 已从 sidecar 污染中分离
- 基于 `origin/main` 的 integration branch 已建立
- fresh strict L0 聚合 gate 通过

当前还不应跳过的事情：

- 不要直接在用户脏的根 `main` 工作树上做最终合并动作
- 如果要给主线更高置信度，合并前最好补一次 Windows 路径 smoke
- 在没有新候选审查之前，不要再把更多模块并入 strict L0
- 具体执行单见 `docs/plans/2026-04-09-l0-mainline-merge-checklist.md`，并继续遵守“只保留一个 L0 worktree”的约束

## Verification Snapshot

- `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform`
- 上述聚合 gate 当前 fresh 结果：PASS，`11/11`
- `git diff --check`：PASS
- 当前执行分支：`l0-mainline-integration-20260409`
- `wine cmd /c "cd /d Z:\\...\\tests\\fafafa.core.platform && BuildOrTest.bat test"`
- 结果：未进入模块测试；当前环境缺少 `tools\\lazbuild.bat` 且 Windows PATH 下无 `lazbuild`

## Remaining Risks

- 根 `main` 工作树仍然是用户脏状态，不应拿来直接承载 L0 收口。
- 临时 branch `l0-sidecar-handoff-20260409` 只是 sidecar 交接面，不应再并回当前 L0 实施面。
- SIMD 仍由 SIMD owner 负责；L0 这里只处理边界和非 SIMD contract。
- Windows `.bat` 路径与 shell 路径在 mem runner 上仍有行为差异；这更像合并前的 confidence gap，而不是当前 L0 边界 blocker。
- 当前 Linux 环境虽然有 `wine`，但没有 Windows `lazbuild` bootstrap，所以 `.bat` smoke 现在先卡在环境层，而不是卡在 strict L0 模块逻辑。
- `atomic` 早先只出现过一次未复现的聚合波动；当前没有足够证据支持生产代码修复，若后续再次出现应优先保留失败日志并锁定具体 testcase 顺序。
