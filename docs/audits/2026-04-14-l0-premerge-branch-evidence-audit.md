# 2026-04-14 L0 Premerge Branch Evidence Audit

> 这份审计只记录 strict non-SIMD L0 在 `l0-mainline` 上的 branch-scoped pre-merge evidence，不把 branch closeout 误写成 merged `main` closeout。

## Scope

- 当前分支仍然是 `l0-mainline`
- 当前 **CI-covered branch head** 是 `334219275c1d9474b310ac74e1f6f03a7a8ab488`
- 当前这份 audit 所在的本地 docs 记录头可能继续领先于该 CI-covered head，但只允许是 docs / handoff bookkeeping；这里固定记录“已被 CI 覆盖的 branch head”，不把 docs bookkeeping 误写成新的 exact-evidence head
- 这轮证据只覆盖 branch-visible code/test/control-plane head，不覆盖 merged `origin/main` 的后续语义

## Why this audit exists

- `atomic` today contract、post-merge closeout contract、workflow noise reduction 和 `span2 / segmented span` 文档口径这一波都已经在 `l0-mainline` 收口，但仍未 merge 到 `main`
- 首轮 branch CI 证据尝试里，Linux `24374210674` 与 Windows `24374255839` 都在 checkout post-step 失败，根因不是 strict L0 代码本身，而是仓库里残留了一个坏掉的 gitlink：`3rd/mimalloc`
- 该 gitlink没有 `.gitmodules` 元数据，`actions/checkout@v4` 在 `Removing auth` 阶段执行 `git submodule foreach --recursive ...` 时会直接报 `fatal: No url found for submodule path '3rd/mimalloc' in .gitmodules`
- 随后本地用 `bash tests/check_repo_submodule_hygiene.sh` 复现同一根因，移除了 stale gitlink，并把 submodule metadata hygiene contract 接入 `run_strict_l0_maintenance_loop.sh`
- 在真正 merge 之前，最重要的 blocker 仍然是“当前 branch head 是否有 remote-visible Linux / Windows exact evidence”，而不是把 `main` state docs 提前写假

## Evidence collected for `l0-mainline`

- GitHub Actions `L0 Linux Maintenance`
  - run id：`24375118487`
  - head sha：`334219275c1d9474b310ac74e1f6f03a7a8ab488`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence`
  - run id：`24375119781`
  - head sha：`334219275c1d9474b310ac74e1f6f03a7a8ab488`
  - 结果：`12/12 PASS`
- Linux shell-side Windows verifier snapshot：
  - `tests/_windows_l0_native_evidence_gh/L0-20260414-l0-premerge-atomic-windows-r2/`

## What this proves

- 当前 `l0-mainline` 的代码 / 测试 / workflow-control-plane head 已经不再受 remote ref 落后或 broken gitlink checkout blocker 的影响
- Linux maintenance 与 Windows exact native evidence 现在都已经覆盖同一个 branch-visible head：`33421927...`
- 当前 branch head 已经具备 merge-ready 的 CI evidence；后续如果只继续补 docs / handoff bookkeeping，不需要把这份 branch evidence 误写成 merged-main evidence

## What this does not prove

- 这不是 merged `main` closeout
- 这不意味着 `docs/audits/2026-04-11-l0-current-state-audit.md` 可以直接改写成“当前 `origin/main` 已收齐 fresh Linux / Windows evidence”
- 这不改变 retained refs 的 today policy：`closeout/rescue` 仍然只能 shortlist-first，不能 broad absorb

## Explicit non-action

这轮明确 **没有** 调用：

```bash
bash tests/update_strict_l0_current_state_docs.sh --apply ...
```

原因：

- 该脚本会写入 `origin/main` merged-state 语义
- 当前我们仍在 `l0-mainline` pre-merge 阶段
- 正确做法是先保留 branch-scoped audit，等真正 merge 后再做 main-state backfill

## Fresh local verification tied to the fix

- `bash tests/check_repo_submodule_hygiene.sh`
  - 结果：PASS
- `bash tests/test_repo_submodule_hygiene_guard.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_maintenance_loop_contract.sh`
  - 结果：PASS
- `bash tests/run_strict_l0_maintenance_loop.sh`
  - 结果：PASS

## Next move

1. 继续保持 strict non-SIMD L0 / no broad absorb / no SIMD 边界不变
2. 把当前 `l0-mainline@33421927...` 当作 branch-scoped merge-ready head
3. 真正 merge 到 `main` 之后，再决定是否调用 `bash tests/run_strict_l0_mainline_closeout.sh --apply-docs` 回填 merged-main current-state 文档
