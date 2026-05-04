# SIMD Review Task Plan

## Goal

审查 `fafafa.core.simd` 当前结构、验证基线和成熟度边界，输出一份可直接执行的整改方案。

## Scope

- `src/fafafa.core.simd*`
- `tests/fafafa.core.simd*`
- `docs/fafafa.core.simd*`
- 相关 `docs/plans/*simd*`

## Phases

| Phase | Status | Notes |
| --- | --- | --- |
| 1. 建立审查上下文与工作台 | in_progress | 使用 worktree-local scratch，避免覆盖仓库根归档文件 |
| 2. 收集结构、测试、文档与 gate 证据 | pending | 重点核对文档承诺与代码现实是否一致 |
| 3. 提炼问题并按严重度排序 | pending | 以架构风险、验证缺口、维护复杂度为主 |
| 4. 形成成熟整改方案 | pending | 输出审查结论 + 分阶段落地路径 |

## Constraints

- 默认使用仓库现有脚本与文档，不做无审批的大规模架构改写
- 审查优先关注 stable surface、dispatch/cpuinfo 语义、非 x86 成熟度、验证闭环
- 若根目录 `task_plan.md/findings.md/progress.md` 与仓库约定冲突，优先使用 worktree-local scratch

## Errors Encountered

| Error | Attempt | Resolution |
| --- | --- | --- |
| `mcp__ace_tool__search_context` 首次返回 499 | 1 | 缩窄查询后重试成功 |
| `CLAUDE_PLUGIN_ROOT` 未注入，无法直接调用 planning skill 辅助脚本 | 1 | 改为使用已知 skill 安装路径和 worktree-local scratch |
