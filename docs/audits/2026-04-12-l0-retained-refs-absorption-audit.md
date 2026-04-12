# 2026-04-12 L0 Retained Refs Absorption Audit

> 这份审计记录 strict non-SIMD L0 在 retained refs 清理前，先吸收 low-risk archive history 的第一波结果。
> 当前最新波次请改看 `docs/audits/2026-04-12-l0-retained-refs-third-absorption-audit.md`。

## Why this wave exists

- `bash tests/audit_strict_l0_retained_refs.sh` 已经证明 4 条 retained refs 仍承载独立 patch history，当前不能盲删。
- 但 retained refs 里混着多种历史：archive docs、current-entry docs、code/tests、examples/build。
- 如果不先做 inventory，就只能继续靠人工猜哪一类最适合先吸收，效率太低。

## Inventory snapshot

来自 `bash tests/report_strict_l0_retained_refs_inventory.sh` 的真实结果：

- `l0-mainline-closeout-20260411`
  - `unique_commit_count=45`
  - `archive_docs_paths=0`
  - `docs_current_entry_paths=44`
  - `code_or_tests_paths=78`
  - `examples_or_build_paths=6`
  - `recommendation=review-code-before-absorb`
- `l0-sidecar-handoff-20260409`
  - `unique_commit_count=26`
  - `archive_docs_paths=56`
  - `docs_current_entry_paths=22`
  - `code_or_tests_paths=106`
  - `examples_or_build_paths=107`
  - `recommendation=absorb-archive-first`
- `l0-main-rescue`
  - `unique_commit_count=3`
  - `archive_docs_paths=0`
  - `docs_current_entry_paths=24`
  - `code_or_tests_paths=24`
  - `examples_or_build_paths=11`
  - `recommendation=review-code-before-absorb`
- `l0-main-tail-cleanup-20260408-final`
  - `unique_commit_count=33`
  - `archive_docs_paths=56`
  - `docs_current_entry_paths=50`
  - `code_or_tests_paths=104`
  - `examples_or_build_paths=41`
  - `recommendation=absorb-archive-first`

结论很直接：

- `sidecar` / `tail` 两条 ref 虽然还混着代码与测试历史，但它们已经明确包含一大批可先吸收的 archive docs。
- `mainline-closeout` / `main-rescue` 当前更像 code/test/current-entry 混合历史，不适合先做机械吸收。

## What this wave absorbed

本轮先吸收 low-risk historical reports，把它们从 `docs/` 主入口下沉到 archive：

- `archive/reports/docs-benchmarks/`
  - 吸收 2 份 benchmark campaign 报告
- `archive/reports/docs-collections/`
  - 吸收 13 份 collections campaign 报告
- `archive/reports/docs-root/`
  - 吸收 13 份 `docs/reports/` 下的 dated root reports
  - 吸收 22 份原本堆在 `docs/` 根目录的历史 module/status/completion reports

合计：本轮下沉了 **50** 份历史报告。

同时补齐：

- `docs/benchmarks/reports/README.md`
- `docs/collections/reports/README.md`
- `docs/reports/README.md`

这样原目录只保留 archive pointer，不再继续冒充 current-entry。

## Retained refs status after this wave

fresh `bash tests/audit_strict_l0_retained_refs.sh` 结果仍然是：

- `l0-mainline-closeout-20260411`
  - `unique_patch_count=45`
  - `decision=retain-unique-history`
- `l0-sidecar-handoff-20260409`
  - `unique_patch_count=26`
  - `decision=retain-unique-history`
- `l0-main-rescue`
  - `unique_patch_count=3`
  - `decision=retain-unique-history`
- `l0-main-tail-cleanup-20260408-final`
  - `unique_patch_count=33`
  - `decision=retain-unique-history`

也就是说，这一波的目标是先把 low-risk archive history 吸收到 mainline，让后续 retained refs 清理从“口头判断”变成“有 inventory、有吸收顺序”的持续工程；它不是一次性把 refs 直接删干净。

## What this wave did not do

- 没有删除任何 retained ref
- 没有扩 strict non-SIMD L0 module surface
- 没有把 SIMD / sidecar 主题重新混回当前 L0 worktree
- 没有把 Windows native evidence 从 GitHub Actions 纪律放松到本地 Linux 假证据

## Next move

下一批仍应按这个顺序走：

1. 继续保留 `bash tests/audit_strict_l0_retained_refs.sh` 的 non-destructive 审计口径
2. 继续用 `bash tests/report_strict_l0_retained_refs_inventory.sh` 识别哪类 history 值得先吸收
3. 在 `l0-sidecar-handoff-20260409` / `l0-main-tail-cleanup-20260408-final` 上继续做 archive/docs-first 吸收
4. 把 `l0-mainline-closeout-20260411` / `l0-main-rescue` 留到 code/test/current-entry 专项波次处理
