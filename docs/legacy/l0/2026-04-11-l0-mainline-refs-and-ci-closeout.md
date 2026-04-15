# 2026-04-11 L0 Mainline Refs And CI Closeout

> 历史 closeout 记录：本文保留 `l0-linux-maintenance.yml` 还没有进入 default branch 时的 `HTTP 404` 诊断语境。该问题已在后续 mainline CI fresh pass 里得到解决。

## Historical Phase Summary

- 当时唯一 `L0` worktree 仍是 `l0-mainline`，workflow 可见性探测使用的 probe commit 是 `0970b629`。
- 当时 `.github/workflows/l0-linux-maintenance.yml` 只在 `origin/l0-mainline` 上可见，还没有进入 default branch。
- 因此 `gh workflow run l0-linux-maintenance.yml --ref l0-mainline` 返回 `HTTP 404`；这证明 GitHub 尚未注册 dispatch 入口，不是认证错误。
- 当时 4 个残留 `L0` refs 都仍承载独立 patch history，所以 refs cleanup 结论是显式 `no-op`。

## Final Resolution

- 当前本地 main merge commit：`a25acfe4f56bfd021e860aabe09e3cc392ef01ab`
- 当前 `origin/main` head：`84adcf9047b7af1c73528768578755c56cb362e2`
- GitHub Actions `L0 Linux Maintenance` run `24463267969`
  - head sha：`b8b5f719349bc68fc63da7fe51318af8a6af229f`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `24463558794`
  - head sha：`b8b5f719349bc68fc63da7fe51318af8a6af229f`
  - 结果：`12/12 PASS`
- Linux shell verifier snapshot：
  - `tests/_windows_l0_native_evidence_gh/L0-20260415-mainline-postmerge-closeout-windows/`

这说明：

- mainline Linux workflow 已可 dispatch 并 fresh 通过
- Windows exact evidence 也已收齐
- 当前本地 `main` 已推进到 `a25acfe4f56bfd021e860aabe09e3cc392ef01ab`；当前 `origin/main` 仍在 `84adcf9047b7af1c73528768578755c56cb362e2`；latest exact Windows native evidence 仍锚定 `main@b8b5f719349bc68fc63da7fe51318af8a6af229f`。只有在确认 current `main` 相对该证据头没有新增 strict L0 代码或测试入口变化时，才应继续把差异理解为 docs / control-plane-only 增量。
- 这份文档现在只保留 pre-merge `HTTP 404` 的历史解释与 refs no-op 审计背景

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
- 当前 latest Windows exact evidence run 是 `24463558794`
