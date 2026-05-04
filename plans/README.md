# 长期迭代维护（planning-with-files）

本目录用于存放迭代归档与辅助脚本。

根目录 `task_plan.md`、`findings.md`、`progress.md` 不再作为长期 mainline 工作日志使用；当前主线只保留短指针文件，把最后一次快照指向归档目录。

如果一轮工作需要详细 scratch 文档：

- 可以先保留在当前 worktree 的临时文件中
- 需要入库时，直接归档到 `plans/archive/YYYY-MM-DD-<topic>/`
- 稳定结论再提升到 `docs/plans/`、`docs/audits/` 或 `workers/`

## 约定
- 每轮从 `backlog.md` 选 1–3 项，先在当前 worktree 维护临时计划（控制 WIP）
- 任何重要发现先落到临时记录，再继续操作
- 每个阶段完成后，把稳定结论同步到正式文档，而不是让临时日志长期挂在主线根目录
- 需要保留完整执行镜像时，将三文件归档到 `plans/archive/YYYY-MM-DD-<topic>/`

## 归档目录
- `plans/archive/`：每轮迭代一个子目录，包含当轮的 `task_plan.md` / `findings.md` / `progress.md`
