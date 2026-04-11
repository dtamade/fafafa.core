# 2026-04-11 L0 Mainline Refs And CI Closeout

> 这份 closeout 记录当前唯一 `L0` worktree 在 post-merge 维护阶段，对残留 `L0` refs 和 Linux maintenance CI 入口做出的最终判断。

## Summary

- 当前唯一 `L0` worktree 仍是 `l0-mainline`；本次 workflow 可见性探测使用的 probe commit 为 `0970b629`。
- `origin/main` 仍停在 `f6585dd9`；为了让 GitHub 看见 `.github/workflows/l0-linux-maintenance.yml`，当前 `HEAD` 已推送到 `origin/l0-mainline`。
- GitHub content API 已确认远端分支 `l0-mainline` 上存在 `.github/workflows/l0-linux-maintenance.yml`。
- 但 `gh workflow run l0-linux-maintenance.yml --ref l0-mainline` 当前返回 `HTTP 404`；这说明 GitHub 还没有把这份新 workflow 注册成可 dispatch 的仓库级入口。
- 当前 4 个残留 `L0` refs 都仍承载独立 patch history；这一步没有任何“可证明冗余”的 ref，因此 refs 清理结论是显式 `no-op`。

## CI Evidence

本轮实际执行过的命令和结论：

```bash
git push origin HEAD:refs/heads/l0-mainline
gh workflow run l0-linux-maintenance.yml --ref l0-mainline
gh api 'repos/dtamade/fafafa.core/contents/.github/workflows/l0-linux-maintenance.yml?ref=l0-mainline'
gh api repos/dtamade/fafafa.core/actions/workflows/l0-linux-maintenance.yml
```

结论：

- `git push`：成功；远端已存在 `origin/l0-mainline`
- `gh api contents ...?ref=l0-mainline`：成功；证明 workflow 文件已经在远端分支可见
- `gh workflow run ...`：失败，返回 `HTTP 404`
- `gh api repos/.../actions/workflows/l0-linux-maintenance.yml`：失败，返回 `HTTP 404`

这组结果指向同一个判断：

- workflow 文件已经存在于远端分支
- 但它还没有进入 default branch
- 因此 GitHub 还没有把它注册成可 dispatch 的 workflow id / workflow file 入口

所以，当前 pre-merge 阶段的 Linux CI 结论是：

- workflow 文件已经准备好
- 但 GitHub 还不能直接调度它
- Linux x64 的 fresh evidence 仍以本地 `bash tests/run_strict_l0_maintenance_loop.sh` 为准

## Residual L0 Refs Audit

本轮使用的判断命令：

```bash
for b in l0-main-rescue l0-main-tail-cleanup-20260408-final l0-mainline-closeout-20260411 l0-sidecar-handoff-20260409; do
  echo "== $b =="
  git cherry -v HEAD "$b"
done
```

审计结论：

- `l0-main-rescue`
  - 仍有独立 patch history，承载本地 main rescue snapshot，不能盲删
- `l0-main-tail-cleanup-20260408-final`
  - 仍有大量独立 patch history，承载 docs/archive/runner cleanup 历史，不能盲删
- `l0-mainline-closeout-20260411`
  - 仍有独立 windows closeout 与 merge-prep lineage，不能盲删
- `l0-sidecar-handoff-20260409`
  - 仍保留 sidecar runner cleanup 历史，不能盲删

因此这一步的 refs cleanup 结论是：

- 没有任何一个 ref 达到了“已被 `HEAD` 吸收且内容冗余”的删除条件
- 本轮不执行 `git branch -d ...`
- 当前 refs 保留决策是有意保守，而不是遗漏清理

## Retained Refs

当前继续保留：

- `l0-mainline`
- `l0-mainline-closeout-20260411`
- `l0-sidecar-handoff-20260409`
- `l0-main-rescue`
- `l0-main-tail-cleanup-20260408-final`

## Next Trigger

后续只有在以下条件满足时，才继续推进下一步：

- `.github/workflows/l0-linux-maintenance.yml` 进入 default branch，然后再用 `gh workflow run l0-linux-maintenance.yml --ref <ref>` 取 GitHub-side Linux 证据
- 或者残留 refs 中出现新的 patch-equivalence 证据，能证明某个历史 ref 已经完全冗余

在此之前：

- 不继续盲删 `L0` refs
- 不把 `HTTP 404` 误读成认证错误
- 不把 Linux 本地验证冒充成 GitHub-side workflow evidence
