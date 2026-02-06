# 长期迭代维护（planning-with-files）

本目录用于存放迭代归档与辅助脚本；当前迭代的三文件始终在仓库根目录：
- `task_plan.md`：阶段 + 状态（pending/in_progress/complete）
- `findings.md`：发现、结论、证据指针（路径/链接/命令）
- `progress.md`：执行日志与测试结果（可复现）

## 约定
- 每轮从 `backlog.md` 选 1–3 项进入 `task_plan.md`（控制 WIP）
- 任何重要发现：先写 `findings.md` 再继续操作（2-Action Rule）
- 每个阶段完成：立刻更新 `task_plan.md` 的状态与 Errors 表（避免重复踩坑）
- 迭代结束：将三文件归档到 `plans/archive/YYYY-MM-DD-<topic>/`

## 归档目录
- `plans/archive/`：每轮迭代一个子目录，包含当轮的 `task_plan.md` / `findings.md` / `progress.md`

