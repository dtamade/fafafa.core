# Workers Directory

这个目录放共享的 worker 协作文档，直接跟随主线。

目的：
- 让每个并行 worker 都有一个固定入口，避免“当前谁在做什么”只存在聊天上下文里
- 让其他同学能快速看到负责人、工作目录、分支、验证状态和下一步
- 减少多人并行时对同一模块的重复碰撞

约定：
- 每个 worker 一个文件：`workers/workerN.md`
- `workerN.md` 只写当前有效信息，不写长篇历史；历史细节继续放各自模块的计划/进度文件
- 开始接手一个工作流时先创建或更新自己的 worker 文件
- 负责人、分支、worktree、当前状态、验证命令、下一步必须写清楚

建议模板：

```md
# workerN

- Owner:
- Scope:
- Status:
- Branch:
- Worktree:
- Base commit:
- Current focus:
- Source of truth:
- Fresh verification:
- Risks / blockers:
- Next step:
- Last updated:
```

说明：
- `Scope` 写当前负责的模块或子系统
- `Status` 建议使用：`active` / `blocked` / `handoff-ready` / `done`
- `Source of truth` 写该 worker 主要维护的计划/进度文件
- `Fresh verification` 只记录最近一轮真正执行过的命令和结果

