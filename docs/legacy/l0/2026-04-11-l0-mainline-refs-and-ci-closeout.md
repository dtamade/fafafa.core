# 2026-04-11 L0 Mainline Refs And CI Closeout

> 历史 closeout 记录：本文保留 `l0-linux-maintenance.yml` 还没有进入 default branch 时的 `HTTP 404` 诊断语境。该问题已在后续 mainline CI fresh pass 里得到解决。

## Historical Phase Summary

- 当时唯一 `L0` worktree 仍是 `l0-mainline`，workflow 可见性探测使用的 probe commit 是 `0970b629`。
- 当时 `.github/workflows/l0-linux-maintenance.yml` 只在 `origin/l0-mainline` 上可见，还没有进入 default branch。
- 因此 `gh workflow run l0-linux-maintenance.yml --ref l0-mainline` 返回 `HTTP 404`；这证明 GitHub 尚未注册 dispatch 入口，不是认证错误。
- 当时 4 个残留 `L0` refs 都仍承载独立 patch history，所以 refs cleanup 结论是显式 `no-op`。

## Final Resolution

- 当前 main merge commit：`b9c613fa9abdf40e7bea15d2cee71c70d915faec`
- GitHub Actions `L0 Linux Maintenance` run `24355797501`
  - head sha：`b9c613fa9abdf40e7bea15d2cee71c70d915faec`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence` run `24349338362`
  - head sha：`bb2c4104f098699a9f387800b0688a11a12661c9`
  - 结果：`12/12 PASS`
- Linux shell verifier snapshot：
  - `tests/_windows_l0_native_evidence_gh/L0-20260413-l0-premerge-ci-windows/`

这说明：

- mainline Linux workflow 已可 dispatch 并 fresh 通过
- Windows exact evidence 也已收齐
- 当前 `main` 已推进到 `b9c613fa9abdf40e7bea15d2cee71c70d915faec`，但 latest exact Windows native evidence 仍锚定 `main@bb2c4104f098699a9f387800b0688a11a12661c9`；由于这两者之间只剩 docs / control-plane-only 变更，因此当前 closeout 复用该 exact evidence。
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
- 当前 latest Windows exact evidence run 是 `24349338362`
