# 2026-04-13 L0 Retained Refs Sixth Absorption Audit

> 当前 latest 入口已推进到 `docs/audits/2026-04-13-l0-retained-refs-seventh-absorption-audit.md`。
> 这份审计记录 strict non-SIMD L0 在 retained refs 清理前，继续把 `sidecar/tail` 下一跳里的 tests drift 从“混着源码、记录和产物”收紧成更可执行的 inventory 与 next-focus contract。

## Why this wave exists

- 第五波结束后，fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 已经能把 `code_or_tests` 细分成：
  - `src`
  - `test source`
  - `CI workflow`
  - `test artifact`
- 但 sidecar / tail 里当时的 `test_source_paths=` 仍然混着：
  - 真实 test code / scripts / docs
  - `last-run.txt`
  - `performance-data/*.txt`
  - `.gitignore`
- 也就是说，当时虽然已经知道“不要盲吸 code/tests”，但还不能直接回答：
  - 哪些是值得 review 的真实测试 surface
  - 哪些只是 runtime records / control files
  - 哪些只是 output / binary artifacts
  - 下一跳到底该先做 archive docs 还是 test hygiene

## What this wave changes

这轮继续坚持 docs-first、non-destructive，主要做三件事：

1. 继续细化 retained-refs inventory 的 tests 视角
   - `tests/report_strict_l0_retained_refs_inventory.sh --details` 现在额外输出：
     - `test_code_paths=`
     - `test_script_paths=`
     - `test_doc_paths=`
     - `test_runtime_record_paths=`
     - `test_control_paths=`
     - `test_output_artifact_paths=`
     - `test_binary_artifact_paths=`
   - 同时保留原有：
     - `test_source_paths=`
     - `test_artifact_paths=`
2. 把 `test_source_paths=` 收紧成真实 test source surface
   - 第六波之后，不再把 runtime records / control files 计进 `test_source_paths=`
3. 给 inventory 补上 `next_focus=`
   - 当前固定支持：
     - `archive-docs-first`
     - `test-hygiene-first`
     - `source-review-first`
     - `current-docs-first`
   - 这样 `recommendation=` 继续保留高层吸收建议，而 `next_focus=` 直接给出下一跳 triage 顺序

## Why this batch is safe

- 这轮没有修改 strict non-SIMD L0 的 `src/` 行为或测试语义，只补 inventory、contract、audit 和 docs navigation。
- Windows exact native evidence 纪律没有变化，仍然只接受 GitHub Actions / 真实 Windows runner。
- 当前 retained refs 仍保持 non-destructive 审计口径，这轮没有删除任何 ref。
- SIMD owner 的边界没有变化，这轮仍只在 L0 current worktree 内推进。

## Fresh inventory snapshot

fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 结果里，tests drift 现在已经能更细地看：

- `l0-mainline-closeout-20260411`
  - `code_or_tests_paths=78`
  - `src_paths=4`
  - `test_source_paths=73`
  - `test_code_paths=26`
  - `test_script_paths=35`
  - `test_doc_paths=12`
  - `test_runtime_record_paths=0`
  - `test_control_paths=0`
  - `test_artifact_paths=0`
  - `next_focus=source-review-first`
- `l0-sidecar-handoff-20260409`
  - `code_or_tests_paths=106`
  - `src_paths=2`
  - `test_source_paths=68`
  - `test_code_paths=7`
  - `test_script_paths=56`
  - `test_doc_paths=5`
  - `test_runtime_record_paths=19`
  - `test_control_paths=6`
  - `test_artifact_paths=11`
  - `test_output_artifact_paths=10`
  - `test_binary_artifact_paths=1`
  - `next_focus=test-hygiene-first`
- `l0-main-rescue`
  - `code_or_tests_paths=24`
  - `src_paths=12`
  - `test_source_paths=12`
  - `test_code_paths=7`
  - `test_script_paths=2`
  - `test_doc_paths=3`
  - `test_runtime_record_paths=0`
  - `test_control_paths=0`
  - `test_artifact_paths=0`
  - `next_focus=source-review-first`
- `l0-main-tail-cleanup-20260408-final`
  - `code_or_tests_paths=104`
  - `src_paths=4`
  - `test_source_paths=64`
  - `test_code_paths=21`
  - `test_script_paths=31`
  - `test_doc_paths=12`
  - `test_runtime_record_paths=19`
  - `test_control_paths=6`
  - `test_artifact_paths=11`
  - `test_output_artifact_paths=10`
  - `test_binary_artifact_paths=1`
  - `next_focus=test-hygiene-first`

## What these details mean

- `closeout` / `rescue` 依然是明确的 `source-review-first`
  - 它们主要暴露真实 `src` 与真实测试 surface
  - 不适合拿这轮的低风险 hygiene 逻辑去盲吸
- `sidecar` / `tail` 现在终于能明确看出：
  - 真实 test source 并没有消失
  - 但同时还混着一层 runtime records、control files 和 output/binary artifacts
  - 所以在进入更高风险的 code/test review 前，下一跳最值得先做的是 `test-hygiene-first`
- `recommendation=` 和 `next_focus=` 现在承担不同职责：
  - `recommendation=` 保留高层吸收建议
  - `next_focus=` 固定下一跳 triage 顺序，避免再次靠人工肉眼判断

## Current policy after this wave

- 根索引 `docs/README.md` / `docs/INDEX.md` 的 latest absorption 入口现在固定为本文件。
- retained-refs inventory 的判断顺序继续固定为：
  - 先看 `recommendation=`
  - 再看 `next_focus=`
  - 再看 `sample_*` 里的 representative paths
- `test_source_paths=` 现在只代表真实 test source surface。
- `last-run.txt`、`performance-data/*.txt`、`.gitignore`、`*_output.txt`、`*.log`、无扩展名测试二进制，不再混着算进同一层测试源码。

## What this wave still did not do

- 没有删除任何 retained ref
- 没有修改 strict non-SIMD L0 代码或测试 surface
- 没有继续吸收 `closeout/rescue` 上的真实 `src` 或测试源码差异
- 没有把 `sidecar/tail` 里的 runtime records / control files / output artifacts 做 destructive 清理

## Fresh verification

- `bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_test_hygiene_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_examples_build_docs_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_legacy_docs_layout_contract.sh`
  - 结果：PASS
- `bash tests/check_strict_l0_docs_consistency.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_docs_consistency_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_stable_docs_no_sha_contract.sh`
  - 结果：PASS
- `bash tests/test_update_strict_l0_current_state_docs_contract.sh`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_inventory.sh`
  - 结果：PASS
- `bash tests/report_strict_l0_retained_refs_inventory.sh --details`
  - 结果：PASS
- `bash tests/audit_strict_l0_retained_refs.sh`
  - 结果：PASS
- `bash tests/run_strict_l0_maintenance_loop.sh`
  - 结果：PASS
- `git diff --check`
  - 结果：PASS

## Next move

下一跳更适合这样推进：

1. 继续保留 `bash tests/audit_strict_l0_retained_refs.sh` 的 non-destructive 口径
2. 继续用 `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 的 `next_focus=` 判断优先级
3. 对 `l0-sidecar-handoff-20260409` / `l0-main-tail-cleanup-20260408-final` 继续先做 test-hygiene 专项波次
4. 把 `l0-mainline-closeout-20260411` / `l0-main-rescue` 继续留给更高风险的 source-review wave
