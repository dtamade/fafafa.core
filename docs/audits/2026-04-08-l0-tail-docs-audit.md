# 2026-04-08 L0 Tail Docs Audit

> 这是一份 dated audit。
> 当前 L0 长期入口现已固定为 `docs/ARCHITECTURE_LAYERS.md`、`docs/fafafa.core.l0.foundation.md` 和 `docs/fafafa.core.l0.roadmap.md`；本页只保留 2026-04-08 当时的审计语境。

## 结论先行

这轮审计回答的是一个更窄的问题：在 `PR #7` 合并之后，strict non-SIMD L0 的 `docs/` 根层还剩哪些污染面，以及这些尾项应该怎么收口。

结论：

- `docs/reports/` 根已经基本排空，但 `docs/` 根层还残留一批明显属于历史阶段的 `status` / `summary` / `final` / `success` / `implementation` 文档。
- 当前 `docs/INDEX.md` 和部分 mem current-entry 还在承诺 `docs/mem/`、`docs/term/`、`docs/fs/`、`docs/lockfree/`、`docs/simd/` 这类并不存在的目录，属于假导航。
- SIMD 主题仍有大量根层专题文档，但这些材料属于 SIMD owner 的维护边界；L0 只修边界，不接手内容迁移。

## 审计基线

- 执行 worktree：`/home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407`
- 执行分支：`l0-main-tail-cleanup-20260408`
- 对照入口：
  - `docs/INDEX.md`
  - `docs/README.md`
  - `docs/fafafa.core.mem.md`
  - `workers/worker1.md`

## 审计发现

### 1. 根层仍有一批明显不该继续上浮的历史文档

这批文件都带有非常强的阶段性语气，不应继续挂在 `docs/` 根层充当 current-entry：

- `docs/fafafa.core.mem.checklist.md`
- `docs/fafafa.core.mem.development-status.md`
- `docs/fafafa.core.mem.final-status.md`
- `docs/fafafa.core.mem.final-verification.md`
- `docs/fafafa.core.mem.summary.md`
- `docs/fafafa.core.mem.test-summary.md`
- `docs/fafafa.core.mem.ultimate-completion.md`
- `docs/fafafa.core.term.cleanup-success.md`
- `docs/fafafa.core.term.final-success.md`
- `docs/fafafa.core.term.integration-summary.md`
- `docs/fafafa.core.collections.forwardList.ENHANCED_TESTING_REPORT.md`
- `docs/fafafa.core.collections.forwardList.ELITE_REPORT.md`
- `docs/COMPILATION_FIX_REPORT.md`
- `docs/fafafa.core.sync.rwlock.IMPLEMENTATION_SUMMARY.md`

### 2. 当前导航里存在“承诺了但仓库里没有”的主题目录

`docs/INDEX.md` 和 mem 域当前入口仍在引用这些不存在的路径：

- `docs/mem/`
- `docs/term/`
- `docs/fs/`
- `docs/lockfree/`
- `docs/simd/`

这会把后来维护的人带到错误的阅读路径上，也会让清理后的 current-entry 重新漂回历史 closeout 叙述。

### 3. SIMD 仍需保持 owner boundary

这轮没有把 `SIMD_*`、`FPC_RVV_*`、`NEON_*`、`fafafa.core.simd.*` 这些专题文档纳入迁移范围。理由很简单：

- 用户已经明确 SIMD 有独立 owner。
- L0 这批任务的目标是根层 clean closeout，不是替 SIMD 线做专题治理。

## 决策

- 把上述 14 份 non-SIMD 根层历史文档统一迁到 `archive/reports/docs-root/`。
- 不创建新的 `docs/mem/`、`docs/term/`、`docs/fs/`、`docs/lockfree/`、`docs/simd/` 空目录去迎合旧说法。
- 直接修 `docs/INDEX.md`、`docs/README.md` 与 mem current-entry，让它们描述真实仓库结构。
- SIMD 继续保持 handoff / boundary 状态，不在本批展开。
