# 2026-04-11 L0 Mainline Refs And CI Closeout

> 历史 closeout 记录：本文保留 `l0-linux-maintenance.yml` 还没有进入 default branch 时的 `HTTP 404` 诊断语境。该问题已在同日通过 PR `#13` 和后续 mainline CI fresh pass 得到解决。

## Historical Phase Summary

- 当时唯一 `L0` worktree 仍是 `l0-mainline`，workflow 可见性探测使用的 probe commit 是 `0970b629`。
- 当时 `.github/workflows/l0-linux-maintenance.yml` 只在 `origin/l0-mainline` 上可见，还没有进入 default branch。
- 因此 `gh workflow run l0-linux-maintenance.yml --ref l0-mainline` 返回 `HTTP 404`；这证明 GitHub 尚未注册 dispatch 入口，不是认证错误。
- 当时 4 个残留 `L0` refs 都仍承载独立 patch history，所以 refs cleanup 结论是显式 `no-op`。

## Historical Evidence

当时实际执行过的命令：

```bash
git push origin HEAD:refs/heads/l0-mainline
gh workflow run l0-linux-maintenance.yml --ref l0-mainline
gh api 'repos/dtamade/fafafa.core/contents/.github/workflows/l0-linux-maintenance.yml?ref=l0-mainline'
gh api repos/dtamade/fafafa.core/actions/workflows/l0-linux-maintenance.yml
```

当时结论：

- `git push`：成功；远端已存在 `origin/l0-mainline`
- `gh api contents ...?ref=l0-mainline`：成功；证明 workflow 文件已经在远端分支可见
- `gh workflow run ...`：失败，返回 `HTTP 404`
- `gh api repos/.../actions/workflows/l0-linux-maintenance.yml`：失败，返回 `HTTP 404`

## Final Resolution

同日后续收口结果：

- PR `#13` 已合并到 `main`
  - merge commit：`54a7ae056679c251a8a1f53442cfd20601b6f08f`
- GitHub Actions `L0 Linux Maintenance`
  - branch run：`24283828586`
  - main run：`24283947269`
  - 结果：均为 PASS
- GitHub Actions `L0 Windows Native Evidence`
  - run：`24284111799`
  - head sha：`54a7ae056679c251a8a1f53442cfd20601b6f08f`
  - 结果：`12/12 PASS`
- Linux shell verifier 已对该 Windows artifact 做下载复核：
  - local snapshot：`tests/_windows_l0_native_evidence_gh/L0-20260411-native-gha-r11/`

因此这份文档的当前用途只有两个：

- 保留“为什么 pre-merge 会返回 `HTTP 404`”的历史解释
- 保留“为什么 refs cleanup 在那个时间点必须是 `no-op`”的历史审计结论

## Retained Refs

当前继续保留：

- `l0-mainline`
- `l0-mainline-closeout-20260411`
- `l0-sidecar-handoff-20260409`
- `l0-main-rescue`
- `l0-main-tail-cleanup-20260408-final`

## Present-Day Interpretation

现在不应再把这份文档里的 `HTTP 404` 结论当 current blocker：

- 它只描述 workflow 进入 default branch 之前的历史状态
- 当前 mainline Linux workflow 已可 dispatch 并 fresh 通过
- 当前 main merge commit 也已拿到 exact Windows native evidence
