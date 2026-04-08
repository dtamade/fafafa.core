# 2026-04-08 L0 Tail Docs Closeout

> Status: completed in `l0-main-tail-cleanup-20260408` after fresh verification.
> 当前 L0 长期路线图入口已固定为 `docs/fafafa.core.l0.roadmap.md`；本页只保留这一批 dated closeout 语境。

## 目标

把 strict non-SIMD L0 在 `docs/` 根层剩下的最后一批历史尾项压回 archive，并修掉 current-entry 对不存在目录的错误承诺。

## 执行边界

- 执行 worktree：`/home/dtamade/projects/fafafa.core/.claude/worktrees/l0-main-promotion-20260407`
- 执行分支：`l0-main-tail-cleanup-20260408`
- 只处理 non-SIMD 根层历史文档与当前导航
- 不创建新的 `docs/<domain>/` 空目录
- 不迁移 SIMD 专题文档；SIMD 继续由对应 owner 维护

## 本批动作

1. 下沉根层历史文档
   - 将 `mem` / `term` / `forwardList` / `sync.rwlock` / `COMPILATION_FIX_REPORT` 这批明显阶段性文档迁到 `archive/reports/docs-root/`
2. 修 current-entry
   - 刷新 `docs/INDEX.md`
   - 刷新 `docs/README.md`
   - 刷新 `docs/fafafa.core.mem.md`
   - 刷新 `docs/fafafa.core.mem.guide.md`
   - 刷新 `docs/fafafa.core.mem.quickstart.md`
   - 刷新 `docs/fafafa.core.mem.architecture.md`
3. 同步控制面
   - 刷新 `backlog.md`
   - 刷新 `workers/worker1.md`

## 验收标准

- `docs/` 根层不再保留上述 14 份 non-SIMD 历史文档
- `docs/INDEX.md` 和 mem current-entry 不再把 `docs/mem/`、`docs/term/`、`docs/fs/`、`docs/lockfree/`、`docs/simd/` 当现存目录
- `backlog.md` 与 `workers/worker1.md` 能描述这批 closeout 的真实状态
- `git diff --check` 通过
- `./tests/test_repo_hygiene_guard.sh` 通过

## 本批结果

- 14 份 non-SIMD 根层历史文档已迁到 `archive/reports/docs-root/`
- `docs/INDEX.md`、`docs/README.md` 与 mem current-entry 已改成真实仓库口径，不再承诺不存在的主题目录
- `docs/topics/sync/api/SYNC_API_REFERENCE.md` 里对 `SYNC_PRODUCTION_READINESS_REPORT.md` 和 `rwlock` 实现总结的链接已切到 archive 路径
- `backlog.md` 与 `workers/worker1.md` 已同步到这一批状态
