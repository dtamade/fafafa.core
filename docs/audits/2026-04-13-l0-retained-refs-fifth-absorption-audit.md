# 2026-04-13 L0 Retained Refs Fifth Absorption Audit

> 这份审计记录 strict non-SIMD L0 在 retained refs 清理前，继续把下一跳里已经浮出来的 `code/tests drift`、`examples current-entry` 和 `test-artifact hygiene` 收敛成可执行的 inventory 与 today contract。

## Why this wave exists

- 第四波结束后，fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 已经能把 `examples/build drift` 细分成：
  - example source
  - build scripts
  - generated outputs
  - test artifacts
- 但当时 `code_or_tests_paths=` 仍然是一个大桶，里面同时混着：
  - `src/*` 源码
  - `tests/*` 测试源码
  - `.github/*` workflow / CI 控制面
  - `tests/*` 下的 heaptrc / output / log 产物
- 同时，strict L0 examples current-entry 虽然已经固定住了第一批 domain，但 retained-refs 里还继续暴露：
  - `examples/fafafa.core.result/example_result_filters_and_try.lpr`
  - `examples/fafafa.core.platform/example_platform.lpr`
  这说明 `result/platform` 也该进入 current-entry README 口径，而不是继续靠人工翻脚本。

## What this wave changes

这轮继续坚持 docs-first、non-destructive，主要做三件事：

1. 细化 retained-refs inventory 的 `code/tests` 视角
   - `tests/report_strict_l0_retained_refs_inventory.sh --details` 现在额外输出：
     - `src_paths=`
     - `test_source_paths=`
     - `ci_workflow_paths=`
     - `test_artifact_paths=`
   - 同时保留原有 top-level bucket `code_or_tests_paths=`，避免破坏旧口径
2. 把 strict L0 examples current-entry 扩到 `result/platform`
   - 新增：
     - `examples/fafafa.core.result/README.md`
   - 刷新：
     - `examples/fafafa.core.platform/README.md`
     - `docs/EXAMPLES.md`
   - 统一写明：`bin/` / `lib/` 只是生成产物，不是 source-of-truth
3. 刷新第五波审计、latest 入口、worker handoff 和 docs consistency
   - 根入口改为指向本文件
   - worker / docs consistency 现在会把第五波 inventory contract 和 `result/platform` example README 一起锁住

## Why this batch is safe

- 这轮没有修改 strict non-SIMD L0 的 `src/` 行为或测试语义，只补 inventory、README、contract 和 docs navigation。
- Windows exact native evidence 纪律没有变化，仍然只接受 GitHub Actions / 真实 Windows runner。
- 当前 retained refs 仍保持 non-destructive 审计口径，这轮没有删除任何 ref。
- SIMD owner 的边界没有变化，这轮仍只在 L0 current worktree 内推进。

## Fresh inventory snapshot

fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 结果里，`code_or_tests` 现在已经能更细地看：

- `l0-mainline-closeout-20260411`
  - `code_or_tests_paths=78`
  - `src_paths=4`
  - `test_source_paths=73`
  - `ci_workflow_paths=1`
  - `test_artifact_paths=0`
  - `examples_or_build_paths=6`
- `l0-sidecar-handoff-20260409`
  - `code_or_tests_paths=106`
  - `src_paths=2`
  - `test_source_paths=93`
  - `ci_workflow_paths=0`
  - `test_artifact_paths=11`
  - `examples_or_build_paths=107`
- `l0-main-rescue`
  - `code_or_tests_paths=24`
  - `src_paths=12`
  - `test_source_paths=12`
  - `ci_workflow_paths=0`
  - `test_artifact_paths=0`
  - `examples_or_build_paths=11`
- `l0-main-tail-cleanup-20260408-final`
  - `code_or_tests_paths=104`
  - `src_paths=4`
  - `test_source_paths=89`
  - `ci_workflow_paths=0`
  - `test_artifact_paths=11`
  - `examples_or_build_paths=41`

## What these details mean

- `closeout` / `rescue` 继续不是“纯 docs residue”，而是明确混着真实 `src` 和测试源码；这两条仍然不能盲吸。
- `sidecar` / `tail` 虽然仍然带着 archive docs 和 examples/build drift，但现在也能清楚看出：
  - 它们不只是 test artifacts
  - 仍然有少量 `src` 与大量测试源码
  - 因此下一跳更适合继续拆“tests source vs tests artifact”，而不是把 `code_or_tests` 一把并回 mainline
- `result/platform` 进入 current-entry 之后，strict L0 examples 的 today contract 已经从第一批 6 个 domain 扩到 8 个：
  - `base`
  - `option`
  - `env`
  - `atomic`
  - `json`
  - `sync.mutex`
  - `result`
  - `platform`

## Current policy after this wave

- 根索引 `docs/README.md` / `docs/INDEX.md` 的 latest absorption 入口现在固定为本文件。
- retained-refs inventory 的判断顺序继续固定为：
  - 先看 `archive_docs_paths=`
  - 再看 `code_or_tests` 是否主要由 `src/test source/CI workflow/test artifact` 组成
  - 再看 `examples/build` 是 example source 还是 build scripts
- examples current-entry 的判断顺序固定为：
  - README
  - `BuildOrRun*` / `BuildOrTest*`
  - `.lpr` / `.lpi` / `.pas`
- `bin/`、`lib/` 和本地 logs 只代表生成产物，不再当作 today contract 的入口。

## What this wave still did not do

- 没有删除任何 retained ref
- 没有修改 strict non-SIMD L0 代码或测试 surface
- 没有继续吸收 `closeout/rescue` 上的真实 `src` 或测试源码差异
- 没有把 `sidecar/tail` 里的 test source 与 test artifact 再做第六波更细拆分

## Fresh verification

- `bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_code_tests_contract.sh`
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
2. 继续用 `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 判断 `src / test source / test artifact / examples build` 的优先级
3. 如需继续吸收 retained refs，先把 `sidecar/tail` 上的 test artifacts 和真实 test source 进一步拆开
4. `closeout` / `rescue` 仍只适合走更高风险的 code/test/current-entry 专项 review wave，不适合直接一把吸收
