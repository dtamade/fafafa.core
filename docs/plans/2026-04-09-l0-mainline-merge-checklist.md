# 2026-04-09 L0 Mainline Merge Checklist

> 这是 strict non-SIMD L0 并回主线前的 dated checklist。
> 当前 L0 的长期边界和推进顺序仍以 `docs/ARCHITECTURE_LAYERS.md`、`docs/fafafa.core.l0.foundation.md` 和 `docs/fafafa.core.l0.roadmap.md` 为准；本页只回答“真正合并到主线前，现在该怎么做”。

## 先看结论

当前 L0 worktree 已经具备独立 merge candidate 的形态，但不适合直接在根 `main` 工作树上做最终合并。

原因有三条：

- 根工作树当前是用户脏状态
- 根 `main` 当前相对 `origin/main` 是 `ahead 2, behind 38`
- 当前 L0 分支不只有 strict L0 语义提交，还带着一段 runner / archive / hygiene 提交，需要明确决定是整段合并还是只摘取 strict L0 核心序列

## 当前执行面

- 当前 L0 worktree：`/home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407`
- 当前 L0 branch：`l0-main-tail-cleanup-20260408`
- 当前 L0 HEAD：`58976e8a`
- 当前 L0 分叉点：`d5187ea4`（`merge-base HEAD origin/main`）

## 当前验证状态

以下结果已经在 L0 worktree fresh 执行：

Run:

```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
git diff --check
```

当前结果：

- strict L0 聚合 gate：PASS，`11/11`
- `git diff --check`：PASS

## 先决定要带哪些提交

从 `origin/main` 分叉点到当前 `HEAD`，这条分支包含两类提交：

### A. strict L0 核心提交

这是当前最值得保留为单独 merge slice 的序列：

- `8570356a` `build(l0): restore lazbuild bootstrap helper`
- `06d4dfd1` `examples(l0): restore strict l0 entrypoints`
- `fde7c4ff` `l0: admit span2 and refresh control plane`
- `4e8774bf` `docs(l0): harden current-state control plane`
- `9216f320` `test(l0): normalize settings include in test entrypoints`
- `e1cf6577` `docs(l0): establish stable roadmap and doc stack`
- `377533a7` `docs(l0): normalize roadmap and module navigation`
- `58976e8a` `docs(l0): capture module gaps and merge readiness`

其中：

- `fde7c4ff` 到 `58976e8a` 是 strict L0 当前边界、测试入口、文档和控制面的核心收口
- `8570356a` 与 `06d4dfd1` 是 supporting fix，主要保证 L0 相关构建入口和示例入口不掉链子

### B. 更早的 hygiene / archive / runner 提交

更早一段提交从 `42a5ead7` 到 `05c6110a`，主要是：

- archive / report 清理
- root docs 清理
- example / benchmark / runner 修复
- sync / socket sidecar 漂移清理

这批提交不是 strict L0 语义本身，但部分提交会影响主线的仓库 hygiene 和 runner 行为。

当前推荐做法不是直接无脑整段并入，而是先把 A 段当成主 merge candidate，B 段单独审阅后再决定是否一起带。

## 推荐合并形态

当前推荐优先使用“新建干净 integration worktree + cherry-pick strict L0 核心提交”，而不是直接把当前 L0 branch merge 到用户脏的根 `main`。

推荐顺序：

1. 基于最新 `origin/main` 新建一个干净 integration worktree
2. 先只 replay A 段 strict L0 核心提交
3. 在 integration worktree 重新跑 strict L0 聚合 gate
4. 如果一切通过，再决定是否需要把 B 段 hygiene / runner 提交一并补上

## 推荐执行步骤

Run:

```bash
git fetch origin
git worktree add -b l0-mainline-integration-20260409 .claude/worktrees/l0-mainline-integration origin/main
git -C .claude/worktrees/l0-mainline-integration cherry-pick 8570356a 06d4dfd1 fde7c4ff 4e8774bf 9216f320 e1cf6577 377533a7 58976e8a
```

然后在 integration worktree 跑：

```bash
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation fafafa.core.platform
git diff --check
```

## Windows smoke 建议

当前没有 fresh Windows 结果，所以主线合并前最好额外补一次最小 smoke。

推荐至少跑：

```bat
tests\fafafa.core.atomic\BuildOrTest.bat test
tests\fafafa.core.platform\BuildOrTest.bat test
tests\fafafa.core.mem.allocator.foundation\BuildOrTest.bat test
tests\fafafa.core.mem\BuildOrTest.bat test
```

原因：

- `atomic` 是最敏感的低层 contract 之一
- `platform` 是这轮新进入 strict L0 的静态表达层
- `mem` / `mem.allocator.foundation` 在 `.bat` 与 shell 路径上仍存在 runner 行为差异

## 当前不要做的事

- 不要直接在根 `main` 工作树上 merge 当前 L0 branch
- 不要把 SIMD worktree 的提交混入这次 L0 主线集成
- 不要在没有新 candidate 审查的前提下顺手再把新模块并入 strict L0
- 不要把 `mem.allocator.foundation`、`atomic.compat` 这类 compat / facade surface 再次写成 strict L0 本体

## 合并放行条件

以下条件全部满足，才适合把这条 L0 线继续往主线推进：

- integration worktree 基于最新 `origin/main`
- strict L0 核心提交 replay 成功
- strict L0 聚合 gate fresh 通过
- `git diff --check` 通过
- 没有把 SIMD owner 的工作混进来
- Windows smoke 至少完成最小路径，或者明确记录为什么本轮暂不做

## 当前 blocker

当前 blocker 不是 L0 设计本身，而是主线集成条件：

- 根 `main` 工作树是用户脏状态
- 根 `main` 相对 `origin/main` 落后较多
- 当前 branch 上存在一段不完全等于 strict L0 本体的 hygiene / runner 提交，需要明确是否同批带走

## 相关文档

- `docs/fafafa.core.l0.foundation.md`
- `docs/fafafa.core.l0.roadmap.md`
- `docs/audits/2026-04-09-l0-current-state-audit.md`
- `docs/plans/2026-04-09-l0-kernel-span2-closeout.md`
- `workers/worker1.md`
