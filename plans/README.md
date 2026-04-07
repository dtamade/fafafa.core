# 长期迭代维护（planning-with-files）

本目录用于存放迭代归档与辅助脚本。

自 `2026-04-07` 起，根目录不再长期保留 `task_plan.md`、`findings.md`、`progress.md` 作为 mainline working-log。需要保留的执行镜像，直接归档到 `plans/archive/`。

## 约定
- 每轮从 `backlog.md` 选 1–3 项，在当前 worktree 维护临时计划（控制 WIP）
- 任何重要发现先落在临时记录，稳定后再提升到正式文档
- 每个阶段完成后，优先更新 `docs/plans/`、`docs/audits/`、`workers/`
- 需要保留完整执行镜像时，将三文件归档到 `plans/archive/YYYY-MM-DD-<topic>/`

## 归档目录
- `plans/archive/`：每轮迭代一个子目录，包含当轮的 `task_plan.md` / `findings.md` / `progress.md`
