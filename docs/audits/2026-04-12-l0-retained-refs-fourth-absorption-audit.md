# 2026-04-12 L0 Retained Refs Fourth Absorption Audit

> 这份审计记录 strict non-SIMD L0 在 retained refs 清理前，继续把下一跳里已经浮出来的 `examples/build drift` 收敛成可执行的 inventory 和 current-entry 约束。
> 当前 latest 入口已推进到 `docs/audits/2026-04-13-l0-retained-refs-fifth-absorption-audit.md`。

## Why this wave exists

- 第三波结束后，fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 已经说明下一跳不该再回头翻 collections dated docs，而是开始直接暴露：
  - `examples/fafafa.core.sync.mutex/example_performance_comparison.lpr`
  - `examples/fafafa.core.env/BuildOrRun.sh`
  - `examples/fafafa.core.json/BuildOrRun.sh`
- 但当时 `--details` 仍只把这些路径笼统地归到 `sample_examples_or_build_paths=`，还不能直接区分：
  - example source
  - build scripts
  - generated outputs
  - test artifacts
- 同时，`base` / `option` / `env` / `sync.mutex` 这些 examples 域还缺少稳定 README current-entry，导致 triage 仍然容易混到 `bin/`、`lib/` 或本地 logs 上。

## What this wave changes

这轮继续坚持 docs-first、non-destructive，主要做两件事：

1. 细化 retained-refs inventory 的 examples/build 视角
   - `tests/report_strict_l0_retained_refs_inventory.sh --details` 现在额外输出：
     - `sample_example_source_paths=`
     - `sample_build_script_paths=`
     - `sample_generated_output_paths=`
     - `sample_test_artifact_paths=`
   - 同时保留原有 top-level bucket，避免破坏前 3 波的口径
2. 固定 examples current-entry
   - 新增：
     - `examples/fafafa.core.base/README.md`
     - `examples/fafafa.core.option/README.md`
     - `examples/fafafa.core.env/README.md`
     - `examples/fafafa.core.sync.mutex/README.md`
   - 刷新：
     - `examples/fafafa.core.atomic/README.md`
     - `examples/fafafa.core.json/README.md`
     - `docs/EXAMPLES.md`
   - 统一写明：`bin/` / `lib/` / 本地 logs 只是生成产物，不是 source-of-truth

## Why this batch is safe

- 这轮没有修改 strict non-SIMD L0 的 `src/` 或测试行为，只补 inventory、README 和 docs contract。
- Windows exact native evidence 纪律没有变化，仍然只接受 GitHub Actions / 真实 Windows runner。
- SIMD owner 的边界没有变化，这轮仍只在 L0 current worktree 内推进。
- examples current-entry 的 today contract 只是被写清楚，并没有把任何生成产物重新提升成主入口。

## Fresh inventory snapshot

fresh `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 结果里，examples/build drift 已经能更细地看：

- `l0-mainline-closeout-20260411`
  - `examples_or_build_paths=6`
  - `example_source_paths=2`
  - `build_script_paths=4`
  - `generated_output_paths=0`
  - `test_artifact_paths=0`
- `l0-sidecar-handoff-20260409`
  - `examples_or_build_paths=107`
  - `example_source_paths=43`
  - `build_script_paths=64`
  - `generated_output_paths=0`
  - `test_artifact_paths=11`
- `l0-main-rescue`
  - `examples_or_build_paths=11`
  - `example_source_paths=5`
  - `build_script_paths=6`
  - `generated_output_paths=0`
  - `test_artifact_paths=0`
- `l0-main-tail-cleanup-20260408-final`
  - `examples_or_build_paths=41`
  - `example_source_paths=15`
  - `build_script_paths=26`
  - `generated_output_paths=0`
  - `test_artifact_paths=11`

## What these details mean

- 现在可以更明确地判断：
  - `sidecar` / `tail` 上真正高 ROI 的下一跳更偏向 example source 与 build scripts
  - 生成产物本身并没有成为当前 retained history 的主样本
  - 但 `tests/*` 下仍然有一层 test artifacts，需要和真正的 test source 分开看
- 也就是说，第四波之后，下一跳已经不是“继续吸 docs residue”，而是“先看 examples source/build scripts，再把 test artifacts 从真实源码里分离开”。

## Current policy after this wave

- 根索引 `docs/README.md` / `docs/INDEX.md` 的 latest absorption 入口现在固定为本文件。
- examples current-entry 的判断顺序固定为：
  - README
  - `BuildOrRun*` / `BuildOrTest*`
  - `.lpr` / `.lpi` / `.pas`
- `bin/`、`lib/` 和本地 logs 只代表生成产物，不再当作 today contract 的入口。
- 如需 retained refs 的高层分类，继续使用：

```bash
bash tests/report_strict_l0_retained_refs_inventory.sh
```

- 如需 retained refs 的细粒度 examples/build 判断，继续使用：

```bash
bash tests/report_strict_l0_retained_refs_inventory.sh --details
```

## What this wave still did not do

- 没有删除任何 retained ref
- 没有修改 strict non-SIMD L0 代码或测试 surface
- 没有处理 `sidecar` / `tail` 上真正的 code/test drift
- 没有把本地生成产物从仓库里做 destructive 清理

## Fresh verification

- `bash tests/test_strict_l0_retained_refs_inventory_details_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_retained_refs_inventory_examples_build_contract.sh`
  - 结果：PASS
- `bash tests/test_strict_l0_examples_build_docs_contract.sh`
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
2. 继续用 `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 判断 example source / build scripts / test artifacts 的优先级
3. 如需继续吸收 retained refs，先看 sidecar / tail 里的 examples source 和 build scripts 差异
4. 把 `l0-mainline-closeout-20260411` / `l0-main-rescue` 继续保留给更高风险的 code/test/current-entry 专项波次
