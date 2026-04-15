# 2026-04-15 L0 Premerge Branch Evidence Audit

> 这份审计只记录 strict non-SIMD L0 在 `l0-mainline` 上的 branch-scoped pre-merge evidence，不把 branch closeout 误写成 merged `main` closeout。

## Scope

- 当前分支仍然是 `l0-mainline`
- 当前 **Windows-CI-covered branch head** 是 `35689d91c5e7cb0ba859f5400aeb991b19510946`
- 当前这份 audit 所在的本地 docs 记录头可以继续领先于该 evidence-covered head，但只允许是 docs / handoff bookkeeping；这里固定记录“已被 evidence 覆盖的 branch head”，不把 docs bookkeeping 误写成新的 exact-evidence head
- 这轮证据只覆盖 branch-visible code/test/control-plane head，不覆盖 merged `origin/main` 的后续语义

## Why this audit exists

- `retained-ref no-absorb` 收口、`sidecar async runner slice` 与 shortlist skip-table hardening 这一波已经在 `l0-mainline` 收口，但仍未 merge 到 `main`
- 这轮包含真实测试 / runner 变化，因此不能继续复用旧的 exact Windows evidence
- 按当前执行纪律，Linux x64 上的 non-Windows 证据继续由本地 `bash tests/run_strict_l0_maintenance_loop.sh` 提供；Windows exact evidence 只能通过 GitHub Actions 收集
- 在真正 merge 之前，当前最重要的 blocker 是“当前 branch head 是否已经拿到 exact Windows native evidence”，而不是提前把 merged-main current-state 写假

## Evidence collected for `l0-mainline`

- Local Linux x64 `strict L0 maintenance loop`
  - 命令：`bash tests/run_strict_l0_maintenance_loop.sh`
  - head sha：`35689d91c5e7cb0ba859f5400aeb991b19510946`
  - 结果：PASS
- GitHub Actions `L0 Windows Native Evidence`
  - run id：`24459867453`
  - head sha：`35689d91c5e7cb0ba859f5400aeb991b19510946`
  - 结果：`12/12 PASS`
  - URL：`https://github.com/dtamade/fafafa.core/actions/runs/24459867453`
- Linux shell-side Windows verifier snapshot：
  - `tests/_windows_l0_native_evidence_gh/L0-20260415-l0-premerge-retained-closeout-windows/`

## What this proves

- 当前 `l0-mainline` 的这波 retained-ref closeout / async runner slice 代码与测试 head，已经具备 local Linux + exact Windows evidence
- 当前 branch-visible head `35689d91...` 已经不再受“Windows exact evidence 还停留在旧 head”这一 blocker 影响
- merged-main current-state 仍保持锚定 `main@c4fcfcf744b87cb1f8b67ad84beccce6b22b9af8` 是正确的；这轮只新增 branch-scoped pre-merge evidence

## What this does not prove

- 这不是 merged `main` closeout
- 这不意味着 `docs/audits/2026-04-11-l0-current-state-audit.md` 可以直接改写成“当前 `origin/main` 已收齐 fresh Linux / Windows evidence”
- 这不改变 retained refs 的 today policy：`closeout/rescue` 仍然只能 shortlist-first，`sidecar/tail` 仍然保持 `keep-both`

## Explicit non-action

这轮明确 **没有** 调用：

```bash
bash tests/update_strict_l0_current_state_docs.sh --apply ...
```

原因：

- 该脚本会写入 `origin/main` merged-state 语义
- 当前我们仍在 `l0-mainline` pre-merge 阶段
- 正确做法是先保留 branch-scoped audit，等真正 merge 后再做 main-state backfill

## Fresh verification tied to this wave

- `bash tests/check_strict_l0_docs_consistency.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_stable_docs_no_sha_contract.sh`
  - 结果：PASS
- `bash tests/test_update_strict_l0_current_state_docs_contract.sh`
  - 结果：PASS
- `bash tests/test_l0_option_result_runner_hygiene.sh`
  - 结果：PASS
- `bash tests/test_l0_async_test_runner_hygiene.sh`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_source_review_shortlist_contract.sh`
  - 结果：PASS
- `bash tests/run_strict_l0_maintenance_loop.sh`
  - 结果：PASS
- `git diff --check`
  - 结果：PASS

## Next move

1. 继续保持 strict non-SIMD L0 / no broad absorb / no SIMD 边界不变
2. 把当前 `l0-mainline@35689d91...` 当作 branch-scoped merge-ready head
3. 真正 merge 到 `main` 之后，再决定是否调用 `bash tests/run_strict_l0_mainline_closeout.sh --apply-docs` 回填 merged-main current-state 文档
