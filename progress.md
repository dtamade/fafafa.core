# Progress Log

## Session: 2026-03-20

### Phase 1: 范围确认与结构梳理
- **Status:** in_progress
- **Started:** 2026-03-20
- Actions taken:
  - 读取 `using-superpowers`、`planning-with-files`、`systematic-debugging`、`test-driven-development`、`verification-before-completion` 等 skill
  - 建立本轮 simd 审查/修复的持久化计划文件
  - 通过语义搜索定位 simd 主入口、cpuinfo 子模块、测试脚本和维护文档
  - 检查 `git status`，确认 simd 相关文件存在未提交修改
  - 读取 `tests/fafafa.core.simd/BuildOrTest.sh` 与 `docs/fafafa.core.simd.checklist.md`，确认首轮快门禁顺序与默认 `Release` 模式
- Files created/modified:
  - `task_plan.md` (created)
  - `findings.md` (created)
  - `progress.md` (created)

### Phase 2: 证据收集与问题复现
- **Status:** complete
- Actions taken:
  - 运行 `simd` 主线 `check`
  - 运行 `DispatchAPI`、`DirectDispatch`、`PublicAbi`、`cpuinfo` 定向 suite
  - 执行 `win-closeout-dryrun` 确认 closeout dryrun 冷门路径未回归
  - 通过 `rg`/`git diff` 审查 runner 与 cpuinfo/publicabi 相关改动
  - 用 `rg -n "TTestCase_DirectDispatch" tests/fafafa.core.simd/BuildOrTest.sh tests/fafafa.core.simd/buildOrTest.bat` 发现 runner 中完全缺少 `DirectDispatch` 覆盖
- Files created/modified:
  - `tests/fafafa.core.simd/BuildOrTest.sh` (reviewed)
  - `tests/fafafa.core.simd/buildOrTest.bat` (reviewed)
  - `tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.testcase.pas` (reviewed, no changes)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (reviewed, no changes)

### Phase 3: 根因分析与 TDD 修复
- **Status:** complete
- Actions taken:
  - 将 runner 漏检问题归因为 copy/paste：cross-backend parity 第二个 suite 被错误写成再次执行 `DispatchAPI`
  - 修改 shell runner 的 `gate_step_cross_backend_parity`
  - 修改 shell runner 的 `check_windows_runner_parity` 预期签名
  - 修改 batch runner 的 `:parity_suites` 与 gate parity 段
- Files created/modified:
  - `tests/fafafa.core.simd/BuildOrTest.sh` (modified)
  - `tests/fafafa.core.simd/buildOrTest.bat` (modified)

### Phase 4: 复验与回归
- **Status:** complete
- Actions taken:
  - 重新运行 `rg -n "TTestCase_DirectDispatch" ...`，确认静态失败检查转绿
  - 重新运行 `SIMD_OUTPUT_ROOT=/tmp/simd-review-fix-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-review-fix-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh parity-suites`
  - 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-review-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- Files created/modified:
  - `tests/fafafa.core.simd/BuildOrTest.sh` (verified)
  - `tests/fafafa.core.simd/buildOrTest.bat` (verified)

### Phase 5: 连续修复与审查计划
- **Status:** complete
- Actions taken:
  - 用脚本对比 shell/bat action 集合，确认 `BuildOrTest.sh` 53 个 action 与 `buildOrTest.bat` 47 个 action 存在差集
  - 识别这批差集里既有 intentional shell-only helper，也有 Windows-only alias，但旧 `check_windows_runner_parity` 不会显式核对它们
  - 先运行静态失败检查，证明 parity checker 确实没有覆盖这些差集
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，加入 shell/bat action 集合对账和 allowlist 守卫
  - 重新运行静态检查和 `simd check`
  - 继续审查 `public_abi.impl.inc`、`publicabi` Pascal tests 和 external smoke harness，确认四层状态语义的缺口主要落在 external consumer 侧
  - 先用静态检查把 `publicabi_smoke.c` / `publicabi_smoke.ps1` 对 `ActiveFlags` 和 active backend pod info 的缺口打红
  - 修改 `tests/fafafa.core.simd.publicabi/publicabi_smoke.c`，补充 scalar baseline、active backend flags、pod-vs-public-api metadata 对账
  - 修改 `tests/fafafa.core.simd.publicabi/publicabi_smoke.ps1`，补充对等的 PowerShell consumer-side 元数据断言
  - fresh 运行 Linux external smoke 和主 `gate`，确认 public ABI smoke 增强后无回归
  - 继续静态审查 `supported_on_cpu / dispatchable` alias 语义，确认现有 suite 没有主动制造 `BackendInfo.Available=False` 后的分叉场景
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增定向回归测试，显式验证 CPU-only alias 保持不变，而 dispatchable/available 视图收缩
  - 首次编译因 testcase 未引入 `fafafa.core.simd.cpuinfo` 而失败，补最小 `uses` 后重新跑通
  - fresh 运行 `TTestCase_DispatchAPI` suite 与主 `gate`，确认 alias 语义护栏已接入日常门禁
  - 继续静态审查 `RegisterBackend`、dispatch-changed hook 和 `RebindSimdPublicApi`，确认实现链理论上已经支持即时刷新
  - 先用静态检查确认 `publicabi` testcase 还没有覆盖 `RegisterBackend/BackendInfo.Available=False/ActiveFlags` 这条动态路径
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增最小回归测试，验证 active backend 变成 non-dispatchable 后 public ABI metadata 会立即刷新
  - fresh 运行 `TTestCase_PublicAbi` suite 与主 `gate`，确认新动态护栏已接入日常门禁
  - 继续静态审查 Windows public ABI batch runner，确认 `tests/fafafa.core.simd.publicabi/BuildOrTest.bat` 只探测 `powershell`，且缺失时会把 `validate-exports` / `test` 静默当成 `SKIP 0`
  - 修改 `tests/fafafa.core.simd.publicabi/BuildOrTest.bat`，加入 `:resolve_powershell`，优先 `pwsh` 回退 `powershell`，并在两者都缺失时 fail-close；同时统一加上 `-NoProfile`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，新增 `check_windows_publicabi_runner_guard`，把 Windows public ABI runner 的 PowerShell fallback / fail-close 约束接入 `check` 与 `gate_step_build_check`
  - 运行静态 guard 脚本、fresh `simd check` 和 fresh `simd gate`，确认新的 Windows public ABI guard 已纳入日常门禁
  - 同步更新 public ABI 稳定性文档，写明 Windows external smoke 现在是 `pwsh -> powershell` 且缺失时 fail-close
  - 继续静态审查 `SIMD_OUTPUT_ROOT` 隔离语义，确认 `publicabi-smoke` 仍固定写 `tests/fafafa.core.simd.publicabi/bin|lib|logs`，与主 gate 的并发/预演承诺不一致
  - 修改 `tests/fafafa.core.simd.publicabi/BuildOrTest.sh` 与 `BuildOrTest.bat`，让 direct `publicabi` runner 支持 `SIMD_OUTPUT_ROOT`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh` 与 `buildOrTest.bat`，让主 runner 在隔离根下把 `publicabi-smoke` 映射到 `publicabi/` 子目录；shell gate summary 也同步指向隔离后的 `publicabi/logs/test.txt`
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_publicabi_output_isolation`，把父/子 runner 的隔离接线纳入 `check` 与 `build-check`
  - 首次静态 guard 因负向字符串匹配命中 guard 自身而误报，随后收窄实现并重新跑通
  - 运行 isolated `publicabi-smoke`，确认产物实际落到 `/tmp/.../publicabi/{bin,lib,logs}`；随后 fresh 运行 `simd check` 与 `simd gate`
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-clean-gap-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` 后，再执行同根 `clean` 并顺序 `find`，确认隔离根仍残留顶层 `bin/lib` 与 `cpuinfo/cpuinfo.x86/publicabi`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，抽出 `run_clean` 并让 isolated clean 覆盖 `bin/lib/cpuinfo/cpuinfo.x86/publicabi`；同时新增 `check_isolated_clean_coverage` 并接入 `check` 与 `gate_step_build_check`
  - 修改 `tests/fafafa.core.simd/buildOrTest.bat` 的 `:clean`，补齐等价的隔离根清理目录集
  - 同步更新 `docs/fafafa.core.simd.checklist.md` 与 `docs/fafafa.core.simd.maintenance.md`，写明 isolated `clean` 现在会回收顶层 `bin/lib` 和各子 runner 目录
  - fresh 运行 `simd check`、fresh 运行 `simd gate`，最后对同一隔离根执行 `clean` 并再次 `find`，确认根目录已清空
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-runall-log-clobber-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate`，随后检查顶层 `logs/build.txt` / `logs/test.txt`，确认 `build.txt` 已被 `cpuinfo.x86` 的 `check` 覆盖，而 `test.txt` 仍来自 earlier `simd` suite，artifact 根内部出现跨模块错位
  - 审查 `tests/run_all_tests.sh` 与 `tests/run_all_tests.bat`，确认 `gate_step_filtered_run_all` 继承同一个 `SIMD_OUTPUT_ROOT` 时，两者都不会为 simd 模块拆分子根
  - 修改 `tests/run_all_tests.sh` 与 `tests/run_all_tests.bat`，让 simd 系模块在 `SIMD_OUTPUT_ROOT` 打开时自动写到 `run_all/<module>/`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，新增 `check_run_all_output_isolation` 并接入 `check` 与 `gate_step_build_check`
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-runall-isolation-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-runall-isolation-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate`，随后检查顶层 `logs/build.txt` 已回到 `fafafa.core.simd.test` 构建日志，且 `run_all/fafafa.core.simd*` 子树出现
  - 为避免新引入的 `run_all/` 再次成为 clean 残留，进一步补齐 shell/batch `clean` 对 `run_all/` 的回收，并重跑 fresh `check`
  - 对 `/tmp/simd-runall-isolation-gate-20260320` 执行 `clean` 后再次顺序 `find`，确认 `run_all/` 也已被回收
  - 针对上一轮 intrinsics isolation 修复，顺序重跑 `SIMD_OUTPUT_ROOT=/tmp/simd-intrinsics-clean-recheck-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate -> clean -> find`，确认隔离根为空，排除了此前并发观测导致的假残留
  - 继续静态审查 Windows `run_all` 过滤链，确认 `tests/fafafa.core.simd/buildOrTest.bat` 在 gate 第 6 步显式 `set "RUN_ACTION=check"`，但 `tests/run_all_tests.bat` 的 `:run_one` 仍是裸 `call "%SCRIPT%"`，没有把 action 传给模块脚本
  - 修改 `tests/run_all_tests.bat`，增加 `ACTION=%RUN_ACTION%`、默认回落 `test`、日志记录 `Action:`，并把 `!ACTION!` 显式传给模块脚本
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_run_all_output_isolation`，把 batch `RUN_ACTION` 默认值、显式传参与“拒绝裸 call”一起纳入静态守卫
  - 运行静态复验、fresh `simd check` 和 fresh `simd gate`，确认新的 Windows run_all action guard 已接入日常门禁且未破坏 fast-gate
  - 继续沿 helper 隔离语义审查 `experimental-intrinsics-tests`，确认 `SIMD_OUTPUT_ROOT=/tmp/simd-experimental-isolation-gap-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh experimental-intrinsics-tests` 仍会把 smoke 源和 `build/test` 日志写回默认模块目录，而隔离根只出现主 runner 的 `bin2/lib2/logs`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，新增 `experimental_intrinsics_output_root`，让 `run_experimental_intrinsics_tests` 在隔离根下映射到 `intrinsics.experimental/`，同时把 gate summary artifact 和 `run_clean` 覆盖面同步到该子目录
  - 修改 `tests/fafafa.core.simd/buildOrTest.bat`，给 `:experimental_intrinsics_tests` 增加 `EXPERIMENTAL_OUTPUT_ROOT` 传播与 `SIMD_OUTPUT_ROOT` 恢复逻辑，并让 batch `clean` 回收 `intrinsics.experimental`
  - 修改 `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh` 与 `buildOrTest.bat`，接入 `OUTPUT_ROOT` 语义，让 `bin/lib/logs` 与 smoke 临时文件一起落到隔离根
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_experimental_intrinsics_output_isolation`，把主传播、direct shell/bat 子 runner 和 clean 覆盖纳入日常 `check`
  - 运行静态复验、isolated `experimental-intrinsics-tests`、fresh `simd check` 和 `clean -> find`，确认新的 experimental isolation 修复已闭环
  - 继续静态审查 Windows experimental tests 主入口，确认 `tests/fafafa.core.simd/buildOrTest.bat` 的 `gate-strict` 显式启用 `SIMD_GATE_EXPERIMENTAL_TESTS=1`，但 `:experimental_intrinsics_tests` 在缺 `bash` 时仍会 `SKIP 0`
  - 修改 `tests/fafafa.core.simd/buildOrTest.bat`，将 `bash not found` 分支从 `SKIP 0` 改为 fail-close `exit /b 2`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，新增 `check_windows_experimental_tests_runner_guard`，把 batch experimental tests 入口的 fail-close 约束接入 `check` 与 `build-check`
  - 运行静态复验和 fresh `simd check`，确认新的 Windows experimental tests guard 已纳入日常门禁且不误伤主线
  - 继续静态审查 `tests/fafafa.core.simd.intrinsics.experimental/buildOrTest.bat`，确认 direct batch runner 仍自带一套弱语义 `check/test/test-all`，缺少 shell canonical runner 的 `check_source_hygiene` 与多条 backend smoke
  - 再次检索 roadmap / docs，确认公开承诺的 experimental suite 入口仍是 `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test-all`，没有把 direct batch runner 作为正式契约
  - 修改 `tests/fafafa.core.simd.intrinsics.experimental/buildOrTest.bat`，把 `build/check/test/test-experimental/test-all` 全部改成 canonical shell wrapper，仅保留本地 `clean`，并在缺 `bash` 时 fail-close
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，新增 `check_windows_experimental_direct_runner_guard`，显式要求 direct batch runner 代理到 `BuildOrTest.sh`，同时禁止回退到旧的 native `build_core/check_build_log/run_tests` 路径
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-experimental-direct-runner-guard-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新 guard 与现有 gate/check 守卫全部通过
  - 继续静态审查 Windows closeout evidence 链，发现 `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md` 已承诺 native batch evidence 路径不会绕开 Windows 自己的 `publicabi-smoke`，但 `tests/fafafa.core.simd/collect_windows_b07_evidence.bat` 实际只有 `1/6..6/6` 六步，根本没跑 `publicabi-smoke`

  - 用静态失败检查确认另一个联动缺口：`tests/fafafa.core.simd/verify_windows_b07_evidence.bat` 与 `.sh` 仍只接受旧的 `6/6 Filtered run_all chain` 日志，因此即使 evidence collector 漏掉 public ABI smoke，旧日志也可能被 verifier 视为有效
  - 修改 `tests/fafafa.core.simd/collect_windows_b07_evidence.bat`，把 native batch collector 升为 `1/7..7/7`，在 CPUInfo x86 之后新增 `6/7 Windows public ABI smoke`，调用 `tests\\fafafa.core.simd.publicabi\\BuildOrTest.bat test`
  - 修改 `tests/fafafa.core.simd/verify_windows_b07_evidence.bat` 与 `verify_windows_b07_evidence.sh`，把无 `gate_summary.json` 时的 fallback step 校验同步升级为 `1/7..7/7`，显式要求 `6/7 Windows public ABI smoke`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，新增 `check_windows_evidence_collector_guard`，静态约束 collector 与两个 verifier 必须包含 native `publicabi-smoke` 步骤，并禁止旧的 `6/6` marker 回归
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-win-evidence-publicabi-guard-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 Windows evidence collector guard 已接入日常 `check`
  - 继续审 `gate-summary` helper，确认 `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md` 与 `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md` 都把 `gate-summary-sample` / `gate-summary-rehearsal`（以及 inject/rollback/backups）当作 Windows 脚本层入口，但 batch runner 在缺 python/bash 时仍是 `SKIP 0`
  - 用静态失败检查确认 `tests/fafafa.core.simd/buildOrTest.bat` 的 `gate-summary-sample`、`gate-summary-rehearsal`、`gate-summary-inject` 都仍保留 silent skip 文案
  - 修改 `tests/fafafa.core.simd/buildOrTest.bat`，把这三条显式 helper 入口统一改成 fail-close：sample/inject 缺 python 时 `exit /b 2`，rehearsal 缺 bash 时 `exit /b 2`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，同步收紧 `check_windows_runner_parity` 的预期签名，并新增 `check_windows_gate_summary_helper_guard`，显式禁止旧的 `SKIP 0` 文案回归
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-win-gatesummary-helper-guard-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 Windows gate-summary helper guard 已接入日常 `check`
  - 继续审 Windows `qemu-*` direct actions，确认 `qemu-nonx86-evidence`、`qemu-cpuinfo-nonx86-evidence/full-evidence/full-repeat/suite-repeat`、`qemu-arch-matrix-evidence`、`qemu-nonx86-experimental-asm` 在缺 `bash` 时都仍是 `SKIP 0`
  - 修改 `tests/fafafa.core.simd/buildOrTest.bat`，抽出统一的 `:require_qemu_bash_runtime` helper，让 7 个 `qemu-*` batch 入口全部改成缺 `bash` 时 fail-close
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，新增 `check_windows_qemu_runner_guard` 并接入 `check` / `gate_step_build_check`
  - 首次 fresh `check` 暴露 `check_windows_runner_parity` 仍要求旧的 `echo [QEMU] SKIP (bash not found)` 签名；随后同步更新 parity 预期为新的 helper/fail-close 语义
  - 再次 fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-win-qemu-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 Windows qemu guard 与 parity 签名都已接入日常 `check`
  - 继续沿 batch 直连 helper 审查，确认 `backend-bench` 与 `riscvv-opcode-lane` 也仍是“脚本存在 -> 缺 `bash` 时 `SKIP 0`”的假绿包装
  - 修改 `tests/fafafa.core.simd/buildOrTest.bat`，分别补 `:require_backend_bench_bash_runtime` 与 `:require_rvv_lane_bash_runtime`，让两个入口统一在缺 `bash` 时 fail-close
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，新增 `check_windows_bash_helper_runner_guard`，并同步把 `check_windows_runner_parity` 的 bench/RVV 签名改成新的 helper/fail-close 预期
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-win-bash-helper-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 Windows bash helper guard 与更新后的 parity 签名都已接入日常 `check`
  - 继续沿显式 helper 审查，确认 `qemu-experimental-report` 与 `qemu-experimental-baseline-check` 在 shell/batch 两侧都仍是缺 Python 时 `SKIP 0`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，把两条 shell helper 改成缺 `python3` 时 fail-close；修改 `tests/fafafa.core.simd/buildOrTest.bat`，把两条 batch helper 改成 `py/python` 都缺失时 fail-close
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_qemu_experimental_python_helper_guard`，初版因整文件负向匹配命中 guard 自己持有的旧 `SKIP` 字符串而假红，随后收窄到真实函数体与 batch runner 文件范围
  - 再次 fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-qemu-experimental-python-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 QEMU experimental python helper guard 已接入日常 `check`
  - 继续沿“缺运行时不能假绿”下钻到默认 `check` / `gate` 护栏，确认 `register-include`、`interface-completeness`、`contract-signature`、`publicabi-signature`、`adapter-sync`、`coverage`、`experimental-intrinsics`、`wiring-sync` 在 shell/batch 两侧都仍会因缺 Python 而 `SKIP 0`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，把这 8 条 shell helper 全部改成缺 `python3` 时 fail-close；修改 `tests/fafafa.core.simd/buildOrTest.bat`，把对应 8 条 batch action 统一改成 `py/python` 都缺失时 fail-close
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_python_checker_runtime_guard`，用函数体级别的静态检查同时守住 shell helper 与 batch action 的新 fail-close 语义
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-python-checker-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 Python checker runtime guard 已接入日常 `check`
  - 继续审 `publicabi` 子 runner，确认 `tests/fafafa.core.simd.publicabi/BuildOrTest.sh` 的 `validate-exports` 在 `readelf/nm` 都缺失时仍是 `SKIP 0`
  - 修改 `tests/fafafa.core.simd.publicabi/BuildOrTest.sh`，把 `validate_exports` 改成缺符号检查工具时 fail-close
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，新增 `check_publicabi_shell_export_guard` 并接入主 `check`
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-shell-export-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 shell export guard 已接入日常 `check`
  - 直接运行 `SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-validate-exports-20260320 bash tests/fafafa.core.simd.publicabi/BuildOrTest.sh validate-exports`，确认当前 Linux 环境下真实导出符号校验仍可通过
  - 继续沿显式 helper 审查 `gate-summary` JSON 导出链，确认 `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md` 与 `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md` 都把 `SIMD_GATE_SUMMARY_JSON=1` 视为真实能力，但 shell `write_gate_summary_json()` 与 batch `gate_summary` JSON 分支都仍会在缺 Python 时 `SKIP 0`
  - 确认 shell 侧还存在二次误导：`run_gate_summary()` 在 JSON 导出被跳过后仍会继续打印 `json=...`，形成“未导出 JSON”与“JSON 路径已生成”并存的假成功信号
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，把 `write_gate_summary_json()` 改成缺 `python3` 时 fail-close，并让 `run_gate_summary()` 对 JSON 导出显式 `|| return $?`
  - 修改 `tests/fafafa.core.simd/buildOrTest.bat`，把 `gate_summary` 的 JSON 分支改成 `py/python` 都缺失时 fail-close
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_gate_summary_json_runtime_guard`，用函数体 / JSON block 级别的静态检查同时守住 shell 与 batch 的新语义
  - 同步更新 `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md` 与 `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`，写明 `SIMD_GATE_SUMMARY_JSON=1` 缺 Python 时会 fail-close
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-gate-summary-json-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 gate-summary JSON runtime guard 已接入日常 `check`
  - 在 `/tmp/simd-gate-summary-json-direct-20260320/logs/gate_summary.md` 构造最小 gate summary 样本，direct 运行 `gate-summary` + `SIMD_GATE_SUMMARY_JSON=1`，确认正常环境下能真实生成 JSON
  - 构造不含 `python` 的最小 PATH（`/tmp/simd-no-python-path-20260320`），再次 direct 运行同一命令，确认现在会以 `exit 2` 显式失败，而不是假绿
  - 继续沿 closeout 证据链审 `perf-smoke`，确认 `docs/fafafa.core.simd.checklist.md` 与 `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md` 都把它当成显式 closeout 证据，但 shell `check_perf_log`、batch `:perf_smoke`、`check_perf_smoke_log.py` 仍把 Scalar backend 当成 `SKIP 0`
  - 结合 `run_gate_step` 只按返回码记 `PASS/FAIL` 的实现，确认这会让 `gate-strict` / `evidence-linux` 在 Scalar backend 上把“没有拿到 SIMD 性能证据”的 perf-smoke 误记成 `PASS`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`、`tests/fafafa.core.simd/buildOrTest.bat`、`tests/fafafa.core.simd/check_perf_smoke_log.py`，把 Scalar backend 统一改成 fail-close
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_perf_smoke_scalar_guard`，用静态检查同时守住 shell/batch/Python 三处实现
  - 同步更新 `docs/fafafa.core.simd.checklist.md` 与 `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md`，写明 active backend 落到 Scalar 时 perf-smoke 视为 closeout 证据缺失而失败
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-perf-smoke-scalar-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 perf-smoke scalar guard 已接入日常 `check`
  - 构造 synthetic Scalar perf log `/tmp/simd-perf-smoke-scalar-log-20260320.txt`，direct 运行 `python3 tests/fafafa.core.simd/check_perf_smoke_log.py ...`，确认现在会以 non-zero 失败，而不是 `SKIP 0`
  - 为 public ABI hot-path benchmark 先加 TDD 静态护栏：在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_perf_smoke_public_abi_shape_guard`，要求 `PUBLIC_ABI_HOT_INNER`、local `LApi := GetSimdPublicApi` hot-loop 与固定 `Result := PUBLIC_ABI_HOT_INNER`；随后 fresh `check` 先按预期打红
  - 修改 `tests/fafafa.core.simd/fafafa.core.simd.bench.pas`，删除全局 `g_PublicAbiApi`，把 8 个 public ABI hot-path benchmark 统一改成 inner loop；`PubCache` 改为 callback 内局部缓存 `LApi`
  - 初版 inner-loop 修复后，6 轮 direct benchmark 仍出现 `PubCache < PubGet` 波动；继续回到根因分析，确认固定测量顺序与 FPC 对 `GetSimdPublicApi` inline getter 的代码生成共同削弱了 `Cache >= Getter` 这个门槛的可信度
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.bench.pas` 新增 `MeasureRotatedPublicAbiTriplet`，把 `Cache/Get/Dispatch` 三元组改成轮转采样平均，尽量消掉固定顺序偏置
  - 修改 `tests/fafafa.core.simd/check_perf_smoke_log.py`，收敛为仅把稳定的 `PubGet > DispGet` 保留为 hard fail，把 `PubCache < PubGet` 降为 `NOTE`；同步更新 `docs/fafafa.core.simd.publicabi.md`
  - 复验 6 轮 direct benchmark 旧日志与两次 fresh `perf-smoke`，确认新的 checker 会保留 `NOTE` 但不再把 inline getter 的样本波动误判成失败
  - 重新运行 `evidence-linux`，确认前置 `perf-smoke` 与 `gate-strict` 内置 perf step 都通过；最终失败点转移到 sandbox 内 `qemu-cpuinfo-nonx86-evidence` 访问 Docker 权限
  - 对 `qemu-cpuinfo-nonx86-evidence` 单独提权重跑，3 个 non-x86 目标全部通过，确认 `evidence-linux` 的剩余阻塞来自环境权限而非代码回归
  - 继续对提权后的完整 `evidence-linux` 做端到端复验，发现 `gate-strict` 已整体 PASS，但末尾 `freeze_status_linux` 仍误读默认 `tests/fafafa.core.simd/logs/gate_summary.md`，把本轮 isolated run 的 QEMU 证据误判成旧 gate 的 `SKIP`
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `run_freeze_status()`，让默认 `freeze_status.json` 走 `${LOG_DIR}`，并把当前 `GATE_SUMMARY_LOG` 通过 `SIMD_FREEZE_GATE_SUMMARY_FILE` 显式传给 `evaluate_simd_freeze_status.py`
  - 修改 `tests/fafafa.core.simd/collect_linux_simd_evidence.sh`，让 `freeze_status_linux` step 显式继承本轮 `${OUTPUT_ROOT}/logs/gate_summary.md` 与 `${OUTPUT_ROOT}/logs/freeze_status.json`
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_freeze_status_output_isolation`，把 freeze-status 的输出隔离契约接入日常 `check`
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-freeze-isolation-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 freeze-status isolation guard 已接入主线
  - 直接复用 `/tmp/simd-evidence-linux-escalated-full-20260320` 这轮产物运行 `freeze-status-linux`，确认现在会命中本轮 `2026-03-20 12:16:09` gate PASS 与 `qemu-cpuinfo-nonx86-evidence` PASS，返回 `ready=True`
  - 持续轮询长时间运行的提权 `evidence-linux` 会话，确认 full closeout 没有在 QEMU `arm64` / `riscv64` 阶段卡死
  - 获取 fresh full closeout 结果：`SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-escalated-full-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux` 最终 `rc=0`
  - 记录最终 gate 摘要关键点：`gate PASS @ 2026-03-20 12:36:58`、`qemu-cpuinfo-nonx86-evidence PASS @ 2026-03-20 12:36:58`
  - 记录最终 freeze 结果：`freeze-status-linux` 输出 `ready=True, mainline-ready=True`
  - 确认同一次 full closeout 中的 Windows evidence 校验仍是 optional `SKIP`，根因是当前 Linux run 只能消费历史 `windows_b07_gate.log`，不是新的 Linux 代码失败
- Files created/modified:
  - `tests/fafafa.core.simd/BuildOrTest.sh` (modified)
  - `tests/fafafa.core.simd/buildOrTest.bat` (modified)
  - `tests/fafafa.core.simd/check_perf_smoke_log.py` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.bench.pas` (modified)
  - `tests/fafafa.core.simd/collect_linux_simd_evidence.sh` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified)
  - `tests/fafafa.core.simd.publicabi/BuildOrTest.sh` (modified)
  - `tests/fafafa.core.simd.publicabi/publicabi_smoke.c` (modified)
  - `tests/fafafa.core.simd.publicabi/publicabi_smoke.ps1` (modified)
  - `tests/fafafa.core.simd.publicabi/BuildOrTest.bat` (modified)
  - `docs/fafafa.core.simd.checklist.md` (modified)
  - `docs/fafafa.core.simd.maintenance.md` (modified)
  - `docs/fafafa.core.simd.publicabi.md` (modified)
  - `docs/fafafa.core.simd.publicabi.stability.md` (modified)
  - `tests/run_all_tests.bat` (modified)
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh` (modified)
  - `tests/fafafa.core.simd.intrinsics.experimental/buildOrTest.bat` (modified)
  - `tests/fafafa.core.simd/collect_windows_b07_evidence.bat` (modified)
  - `tests/fafafa.core.simd/verify_windows_b07_evidence.bat` (modified)
  - `tests/fafafa.core.simd/verify_windows_b07_evidence.sh` (modified)
  - `tests/fafafa.core.simd/buildOrTest.bat` (modified again)
  - `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md` (modified)
  - `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md` (modified)

### Phase 10: non-x86 opt-in compile smoke gate coverage
- **Status:** complete
- Actions taken:
  - 继续深审 non-x86 opt-in closeout 后，确认默认 `check` 和 shell `gate_step_build_check` 仍只依赖静态 `check_nonx86_optin_runner_guard`，不会 fresh 编译 `SIMD_ENABLE_NEON_BACKEND=1` / `SIMD_ENABLE_RISCVV_BACKEND=1` 的 `test --list-suites`
  - 评估两条 opt-in `test --list-suites` smoke 的实际成本，确认在当前 x86_64 主机上分别约 7 秒且稳定通过，足以纳入默认快门禁
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh`，新增 `nonx86-optin-list-suites` action、`nonx86_optin_output_root()`、`run_nonx86_optin_list_suites()`，并把 fresh opt-in smoke 接入默认 `check` 与 `gate_step_build_check`
  - 修改 `tests/fafafa.core.simd/buildOrTest.bat`，同步新增 `nonx86-optin-list-suites` action、`check` 接线与 `nonx86.optin` 清理逻辑
  - 首次 fresh `check` 被 `check_windows_runner_parity` 打红，原因是 parity 预期 usage/action 签名仍停留在旧版；随后同步更新 shell parity guard 的 batch usage / action / `check` 调用签名
  - 修改 `docs/fafafa.core.simd.checklist.md`，写明默认 `check/gate` 现在已经覆盖 non-x86 opt-in compile smoke，并说明 `nonx86.optin` 隔离输出语义
- Files created/modified:
  - `tests/fafafa.core.simd/BuildOrTest.sh` (modified)
  - `tests/fafafa.core.simd/buildOrTest.bat` (modified)
  - `docs/fafafa.core.simd.checklist.md` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 11: Windows evidence preflight billing-block hardening
- **Status:** complete
- Actions taken:
  - 继续转向 Windows native evidence 主路径，审查 `preflight_windows_b07_evidence_gh.sh`、`run_windows_b07_closeout_via_github_actions.sh`、workflow 和 runbook 的契约
  - 识别到 preflight 之前只扫描 failed run 的 Windows job annotations，且直接把 `job id` 手拼成 `check-runs/<job-id>/annotations`；这会让 `RECENT_BILLING_BLOCK` 在某些真实返回形态下被误判成 PASS
  - 修改 `tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`，新增 `extract_billing_block_message()`，把探测顺序改成 `gh run view` 文本优先、`check_run_url` annotations 次之、手拼 `check-runs/<job-id>` 最后兜底
  - 首次 synthetic harness 发现 helper 自己把 stdin 吃空，导致 run-view 文本没有进入 matcher；随后将 helper 改成显式参数传值并重跑验证
  - 再次收紧 `check_run_url` 调用方式：先规范化为 `repos/.../check-runs/...` endpoint 再传给 `gh api`，避免依赖 full URL 形态
  - 用三个 fake `gh` harness 分别验证：
    - recent billing message 仅出现在 `gh run view` 文本时，preflight 返回 `RECENT_BILLING_BLOCK`
    - run view 文本不命中，但 Windows job `check_run_url` annotations 命中时，preflight 同样返回 `RECENT_BILLING_BLOCK`
    - 无 run history 时仍保持 `STATUS=PASS CODE=OK`
  - 额外通过 `BuildOrTest.sh win-evidence-preflight --help` 确认外层入口未被破坏
  - 真实运行 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`，确认当前 24 小时窗口没有 GH Windows evidence 失败记录，预检口径保持 PASS
- Files created/modified:
  - `tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh` (modified)
  - `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 12: Windows evidence existing-run reuse hardening
- **Status:** complete
- Actions taken:
  - 继续深审 `tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh`，确认显式 `run-id` 路径仍被顶部 dispatch-only hygiene 误伤：在进入 `if [[ -z "${LRunId}" ]]` 之前就无条件执行 `git status` dirty worktree 检查、remote/local ref mismatch 检查，以及 `branch/rev-parse/ls-remote` 解析
  - 修改 `tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh`：
    - 将 `require_cmd git`、`LRef/LHeadSha*` 解析收进 dispatch 分支
    - 将 dirty worktree / remote ref mismatch 拒绝也收进 dispatch 分支
    - 显式 `run-id` 路径新增 `Reuse existing workflow run: <id>` 日志，表明只复用既有 run 做下载/校验/收口
  - 修改 `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md`，写明 `win-evidence-via-gh <batch-id> <run-id>` 可复用现成 workflow run，且不会再因本地 dirty worktree / remote ref mismatch 被误拒
  - 修改 `tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh`，同步补充现成 `run-id` 的复用途径说明
  - 运行 `bash -n tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh`
  - 运行 `bash -n tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh`
  - 用 fake `gh/git/bash` synthetic harness 验证：
    - 显式 `run-id=424242` 且 dirty/mismatch 同时存在时，脚本返回 `REUSE_RC=0`，顺利走到 `Verify downloaded evidence`、`Backfill cross gate`、`Run closeout finalize`
    - 不传 `run-id` 的 dispatch 路径仍返回 `DISPATCH_RC=2`，并保持 `Refuse dispatch: local worktree has uncommitted changes.`
  - 进一步把 harness 里的 `git` 改成“被调用即 `exit 88`”，确认显式 `run-id` 路径仍 `REUSE_NOGIT_RC=0`，说明 reuse flow 已不再依赖本地 git ref 查询
- Files created/modified:
  - `tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh` (modified)
  - `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md` (modified)
  - `tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 13: Remote Windows evidence failure triage
- **Status:** complete
- Actions taken:
  - 查询 `gh run list --workflow simd-windows-b07-evidence.yml --limit 10 --json databaseId,status,conclusion,createdAt,url,event,headBranch,headSha`，确认最近 success/failure 分布：
    - 最新 success：`23087698632`（`2026-03-14T12:11:46Z`）
    - 最新 failure：`23089541215`（`2026-03-14T14:08:46Z`）
  - 运行 `gh run view 23089541215 --json jobs,name,displayTitle,conclusion,createdAt,event,headBranch,headSha,url`，确认失败 job 为 `Collect Windows B07 Evidence`，失败步骤为 `Collect and Verify Windows Evidence`
  - 下载 failure run `23089541215` 的 artifact 到 `/tmp/simd-win-gh-real-run/`，确认包含 `windows_b07_gate.log`、`gate_summary.md`、`build.txt`、`test.txt`
  - 检查 artifact 内 `windows_b07_gate.log` 与 `gate_summary.md`，确认这是旧的 `1/6..6/6` gate 口径，`publicabi-smoke=0`，而不是当前仓库已经修过的新 `1/7..7/7` 口径
  - 使用当前 `bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh /tmp/simd-win-gh-real-run/fafafa.core.simd/logs/windows_b07_gate.log` 复验，得到 `RC=1`，缺失模式正是 `1/7..7/7` 和 `6/7 Windows public ABI smoke`
  - 由此确认：最近远端 failure 仍是历史旧 artifact，不足以作为当前 closeout 证据；下一步必须在包含当前修复的 pushed ref 上重新 dispatch fresh Windows run
- Files created/modified:
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)
  - `/tmp/simd-win-gh-real-run/fafafa.core.simd/logs/windows_b07_gate.log` (downloaded for inspection)
  - `/tmp/simd-win-gh-real-run/fafafa.core.simd/logs/gate_summary.md` (downloaded for inspection)

### Phase 14: Simulated Windows evidence contract realignment
- **Status:** complete
- Actions taken:
  - 发现 `tests/fafafa.core.simd/simulate_windows_b07_evidence.sh` 仍产出旧 `1/6..6/6` 模拟 log，而 `verify_windows_b07_evidence(.sh/.bat)` 已升级为 `1/7..7/7` 契约
  - 复现 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-dryrun` 失败，首次报错是同目录 `logs/gate_summary.json` 被误吸后触发 `No rows in summary json`
  - 进一步用隔离 `/tmp` 路径复验，确认就算绕开 sibling `gate_summary.json` 污染，旧模拟 log 仍会因缺 `1/7..7/7` 模式而失败
  - 修改 `tests/fafafa.core.simd/simulate_windows_b07_evidence.sh`：
    - 将模拟 gate step 升级到 `1/7..7/7`
    - 补入 `6/7 Windows public ABI smoke`
    - 将 summary metrics 从 `3/3/0` 调整到与当前 Windows collector 更一致的 `5/5/0`
    - 写入一个不存在的 `GateSummaryJson` sentinel path，避免 verifier fallback 到同目录真实 `gate_summary.json`
  - 修改 `tests/fafafa.core.simd/rehearse_freeze_status.sh`，把所有预期 PASS 的 Windows evidence 模板同步升级到 `1/7..7/7`，并同样写入 `GateSummaryJson` sentinel
  - 运行 `bash -n tests/fafafa.core.simd/simulate_windows_b07_evidence.sh`
  - 运行 `bash -n tests/fafafa.core.simd/rehearse_freeze_status.sh`
  - 运行 direct simulated verifier：
    - `bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh --allow-simulated /tmp/.../windows_b07_gate.simulated.log`
  - 重新运行 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-dryrun`
  - 重新运行 `bash tests/fafafa.core.simd/rehearse_freeze_status.sh`
- Files created/modified:
  - `tests/fafafa.core.simd/simulate_windows_b07_evidence.sh` (modified)
  - `tests/fafafa.core.simd/rehearse_freeze_status.sh` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 15: Simulated Windows evidence regression guard
- **Status:** complete
- Actions taken:
  - 继续从“修复已生效”前进到“修复会被日常门禁守住”，在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_windows_simulated_evidence_guard`
  - 新 guard 同时检查：
    - `simulate_windows_b07_evidence.sh` 保持 `1/7..7/7` + `GateSummaryJson` sentinel
    - `rehearse_freeze_status.sh` 的 PASS-template cases 保持相同 contract
    - 两个文件都不再残留旧 `1/6` / `6/6` 标记
  - 将该 guard 接入 `gate_step_build_check()` 与默认 `check)` 入口
  - 运行 `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-simulated-evidence-guard-check-20260320 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- Files created/modified:
  - `tests/fafafa.core.simd/BuildOrTest.sh` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

## Test Results
| Test | Input | Expected | Actual | Status |
|------|-------|----------|--------|--------|
| simulated evidence guard syntax | `bash -n tests/fafafa.core.simd/BuildOrTest.sh` | 新 guard 不应破坏 shell runner 语法 | PASS | ✓ |
| simulated evidence guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-simulated-evidence-guard-check-20260320 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 guard 应进入默认 `check` 且不误伤主线 | PASS；日志包含 `OK (Windows simulated evidence guard present)` | ✓ |
| simulated verifier isolated | `bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh --allow-simulated /tmp/.../windows_b07_gate.simulated.log` | 模拟 evidence 在 `--allow-simulated` 下应通过当前 `1/7..7/7` verifier | PASS | ✓ |
| win-closeout dryrun | `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-dryrun` | dryrun 应通过 verify/finalize，但 apply 仍被 simulated gate 阻止 | PASS；输出 `DRYRUN OK: simulated summary stayed preview-only` | ✓ |
| freeze-status rehearsal | `bash tests/fafafa.core.simd/rehearse_freeze_status.sh` | rehearsal 应整体 PASS，并为各负例保留预期非零 | PASS；`case_not_ready_rc=1`、`case_stale_summary_rc=1`、`case_verify_fail_rc=1`、`case_linux_lazy_missing_rc=1`、`case_linux_platform_missing_rc=1`、`case_source_newer_rc=1` | ✓ |
| remote run list triage | `gh run list --workflow simd-windows-b07-evidence.yml --limit 10 --json ...` | 找到最近 success/failure run，判断能否直接复用 fresh evidence | 最新 success=`23087698632 @ 2026-03-14T12:11:46Z`；最新 failure=`23089541215 @ 2026-03-14T14:08:46Z` | ✓ |
| remote failed job triage | `gh run view 23089541215 --json jobs,...` | 精确定位失败 job/step | `Collect Windows B07 Evidence` job `67071702598`，失败 step=`Collect and Verify Windows Evidence` | ✓ |
| remote failed artifact verifier replay | `bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh /tmp/simd-win-gh-real-run/fafafa.core.simd/logs/windows_b07_gate.log` | 当前 verifier 应明确指出旧 artifact 为什么不能用于 closeout | `RC=1`；缺 `[GATE] 1/7..7/7`，特别缺 `6/7 Windows public ABI smoke` | ✓ |
| preflight syntax | `bash -n tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh` | 脚本语法正确 | PASS | ✓ |
| run-id reuse syntax | `bash -n tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh` | 脚本语法正确 | PASS | ✓ |
| win-closeout 3cmd syntax | `bash -n tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh` | helper 脚本语法正确 | PASS | ✓ |
| run-id reuse synthetic dirty worktree bypass | fake `gh/git/bash` harness: dirty worktree + remote mismatch + `run-id=424242` | 显式 `run-id` 应继续 download/verify/finalize，而不是被 dispatch-only hygiene 拒绝 | `REUSE_RC=0`；日志包含 `Reuse existing workflow run: 424242`、`Verify downloaded evidence`、`Backfill cross gate`、`Run closeout finalize` | ✓ |
| dispatch synthetic dirty worktree refusal | 同一 fake harness，但不传 `run-id` | dispatch 新 workflow 时仍应拒绝 dirty worktree | `DISPATCH_RC=2`；日志包含 `Refuse dispatch: local worktree has uncommitted changes.` | ✓ |
| run-id reuse synthetic no-git | fake harness: `git` 被替换为 `exit 88` bomb wrapper + `run-id=424242` | 显式 `run-id` 路径不应再触发任何 git 调用 | `REUSE_NOGIT_RC=0`；日志未出现 `UNEXPECTED_GIT_CALL` | ✓ |
| preflight synthetic billing via run-view | fake `gh` harness: failed run + `gh run view` 包含 `Recent account payments have failed.` | 应 fail-close 为 `RECENT_BILLING_BLOCK` | `STATUS=FAIL CODE=RECENT_BILLING_BLOCK`, `RC=31` | ✓ |
| preflight synthetic billing via check_run_url annotations | fake `gh` harness: failed run + Windows job `check_run_url` annotations 包含 `spending limit needs to be increased` | 应 fail-close 为 `RECENT_BILLING_BLOCK` | `STATUS=FAIL CODE=RECENT_BILLING_BLOCK`, `RC=31` | ✓ |
| preflight synthetic no-history | fake `gh` harness: `gh run list -> []` | 应继续 PASS | `STATUS=PASS CODE=OK`, `RC=0` | ✓ |
| preflight wrapper help | `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight --help` | 外层入口仍可达 | PASS | ✓ |
| preflight real GH status | `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight` | 当前环境下应能返回真实 GH 预检状态 | PASS；`note=no failed run in 24h window` | ✓ |
| non-x86 opt-in smoke action | `SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-optin-action-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh nonx86-optin-list-suites` | 两条 opt-in `--list-suites` 都应 fresh 编译并通过 | PASS；`neon` / `riscvv` 都输出 `TEST OK + LEAK OK` | ✓ |
| non-x86 opt-in smoke 接线 check | `SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-optin-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 默认快门禁应包含两条 non-x86 opt-in compile smoke | 首次因旧 parity usage 签名失败；同步修 guard 后 PASS | ✓ |
| non-x86 opt-in smoke 接线 gate | `SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-optin-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | 默认 gate 不应回归，且应在 build-check 阶段执行 non-x86 opt-in smoke | PASS；日志显示 `NONX86-OPTIN neon/riscvv` 两条 `test --list-suites` 都执行成功 | ✓ |
| non-x86 opt-in isolation clean | `SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-optin-action-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh clean` -> `find /tmp/simd-nonx86-optin-action-20260320 -mindepth 1 -maxdepth 3` | `clean` 应回收新增 `nonx86.optin/` 子树 | `find` 无输出 | ✓ |
| 结构语义搜索 | `simd` 模块入口/测试定位 | 获得主入口、测试入口、维护文档 | 已定位 `simd`/`dispatch`/`cpuinfo`/BuildOrTest 脚本 | ✓ |
| 主线 check | `SIMD_OUTPUT_ROOT=/tmp/simd-review-main-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 快门禁通过 | PASS | ✓ |
| DispatchAPI | `SIMD_OUTPUT_ROOT=/tmp/simd-review-dispatch-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` | suite 通过 | PASS | ✓ |
| DirectDispatch | `SIMD_OUTPUT_ROOT=/tmp/simd-review-direct-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` | suite 通过 | PASS | ✓ |
| PublicAbi | `SIMD_OUTPUT_ROOT=/tmp/simd-review-publicabi-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` | suite 通过 | PASS | ✓ |
| cpuinfo | `SIMD_OUTPUT_ROOT=/tmp/simd-review-cpuinfo-20260320 bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test` | suite 通过 | PASS | ✓ |
| closeout dryrun | `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-dryrun` | dryrun 通过且 simulated summary 不会误 apply | PASS | ✓ |
| runner 静态失败检查 | `rg -n "TTestCase_DirectDispatch" tests/fafafa.core.simd/BuildOrTest.sh tests/fafafa.core.simd/buildOrTest.bat` | 修复前应失败，修复后应找到 direct suite | 修复前 rc=1；修复后找到 4 处 | ✓ |
| 修复后 check | `SIMD_OUTPUT_ROOT=/tmp/simd-review-fix-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | parity + register include + experimental isolation 均通过 | PASS | ✓ |
| 修复后 parity-suites | `SIMD_OUTPUT_ROOT=/tmp/simd-review-fix-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh parity-suites` | 依次执行 DispatchAPI / DirectDispatch | PASS，日志显示两个 suite 都执行 | ✓ |
| 修复后 gate | `SIMD_OUTPUT_ROOT=/tmp/simd-review-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | gate 通过且 cross-backend parity 覆盖 direct suite | PASS | ✓ |
| parity checker 静态失败检查 | `python3 - <<'PY' ...` 比较 shell/bat action 差集是否被 checker 显式记账 | 修复前应失败 | 修复前列出 8 个 `UNCOVERED_SHELL_ONLY` 并 rc=1 | ✓ |
| parity checker 静态复验 | `python3 - <<'PY' ...` 比较 shell/bat action 差集是否被 checker 显式记账 | 修复后应通过 | `UNCOVERED_SHELL_ONLY []`, `UNCOVERED_WINDOWS_ONLY []` | ✓ |
| parity guard 修复后 check | `SIMD_OUTPUT_ROOT=/tmp/simd-review-parityguard-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 parity guard 不应误伤现有 shell-only / Windows-only 差集 | PASS | ✓ |
| parity guard 修复后 gate | `SIMD_OUTPUT_ROOT=/tmp/simd-review-parityguard-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | 新 parity guard 不应破坏 fast-gate 全链路 | PASS | ✓ |
| public ABI smoke active-flags 静态失败检查 | `python3 - <<'PY' ...` 检查 `publicabi_smoke.c` / `.ps1` 是否消费 `ActiveFlags` 与 active backend pod info | 修复前应失败 | 两个 harness 都缺 `ActiveFlags` 消费和 active backend query，rc=1 | ✓ |
| public ABI smoke active-flags 静态复验 | `python3 - <<'PY' ...` 检查 `publicabi_smoke.c` / `.ps1` 是否消费 `ActiveFlags` 与 active backend pod info | 修复后应通过 | `SMOKE_ACTIVE_FLAGS_COVERAGE_OK` | ✓ |
| public ABI Linux smoke | `bash tests/fafafa.core.simd.publicabi/BuildOrTest.sh test` | external consumer harness 通过 | PASS | ✓ |
| public ABI smoke 增强后 gate | `SIMD_OUTPUT_ROOT=/tmp/simd-review-publicabi-flags-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | 主 gate 中的 `publicabi-smoke` 步骤与全链路均通过 | PASS | ✓ |
| alias 分叉静态证据 | `rg -n "Available := False|GetSupportedBackendList|GetAvailableBackends|GetAvailableBackendList|GetDispatchableBackendList" ...` | 现有 suite 分别测试这些点，但缺少组合场景 | 已确认 `BackendInfo.Available=False` 测试与 alias 视图断言分散存在 | ✓ |
| alias 分叉回归测试存在性 | `python3 - <<'PY' ...` 检查新 testcase 是否同时覆盖 `BackendInfo.Available := False` 与 supported/available/dispatchable aliases | 新 regression test 已落地 | `ALIAS_DISTINCTION_REGRESSION_TEST_PRESENT` | ✓ |
| alias 分叉回归 suite | `SIMD_OUTPUT_ROOT=/tmp/simd-review-alias-distinction-suite-20260320b bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` | 定向 suite 通过 | PASS | ✓ |
| alias 分叉回归 gate | `SIMD_OUTPUT_ROOT=/tmp/simd-review-alias-distinction-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | 新 regression test 不应破坏主 gate | PASS | ✓ |
| public ABI 动态 flags 静态证据 | `python3 - <<'PY' ...` 检查 `publicabi` testcase 是否覆盖 `RegisterBackend` / `BackendInfo.Available := False` / `ActiveFlags` | 修复前应缺失 | 四个 needle 全部 `MISSING` | ✓ |
| public ABI 动态 flags 测试存在性 | `python3 - <<'PY' ...` 检查新 testcase 是否覆盖 `RegisterBackend` 与 `ActiveFlags` 动态场景 | 新 regression test 已落地 | `PUBLICABI_DYNAMIC_FLAGS_TEST_PRESENT` | ✓ |
| public ABI 动态 flags suite | `SIMD_OUTPUT_ROOT=/tmp/simd-review-publicabi-dynamic-flags-suite-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` | 定向 suite 通过 | PASS | ✓ |
| public ABI 动态 flags gate | `SIMD_OUTPUT_ROOT=/tmp/simd-review-publicabi-dynamic-flags-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | 新 regression test 不应破坏主 gate | PASS | ✓ |
| Windows public ABI runner guard 静态复验 | `python3 - <<'PY' ...` 检查 `BuildOrTest.bat` 是否具备 `pwsh -> powershell` fallback、fail-close 和 `-NoProfile` | 修复后应通过 | `WINDOWS_PUBLICABI_GUARD_OK` | ✓ |
| Windows public ABI guard 接线 check | `SIMD_OUTPUT_ROOT=/tmp/simd-review-win-publicabi-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `Windows public ABI runner guard present` | ✓ |
| Windows public ABI guard 接线 gate | `SIMD_OUTPUT_ROOT=/tmp/simd-review-win-publicabi-guard-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | 新 static guard 应进入日常 gate 而不破坏全链路 | PASS，build-check 与全链路均通过 | ✓ |
| public ABI isolation 静态失败检查 | `python3 - <<'PY' ...` 检查父/子 runner 是否都具备 `SIMD_OUTPUT_ROOT` 隔离接线 | 修复前应失败 | 列出 shell/batch parent 与 publicabi 子 runner 的多项缺口，rc=1 | ✓ |
| isolated publicabi smoke | `SIMD_OUTPUT_ROOT=/tmp/simd-review-publicabi-isolation-run-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh publicabi-smoke` | external smoke 应把产物写到隔离根下的 `publicabi/` | PASS，产物位于 `/tmp/simd-review-publicabi-isolation-run-20260320/publicabi/{bin,lib,logs}` | ✓ |
| public ABI isolation guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-review-publicabi-isolation-check-20260320c bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 isolation guard 不应误伤主线 check | PASS，日志包含 `public ABI output isolation present` | ✓ |
| public ABI isolation guard gate | `SIMD_OUTPUT_ROOT=/tmp/simd-review-publicabi-isolation-gate-20260320b bash tests/fafafa.core.simd/BuildOrTest.sh gate` | `publicabi-smoke` 在隔离根下运行且全链路通过 | PASS，日志显示 `/tmp/.../publicabi/bin/libfafafa.core.simd.publicabi.so` | ✓ |
| isolated clean 缺口复现 | `SIMD_OUTPUT_ROOT=/tmp/simd-clean-gap-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> `clean` -> `find /tmp/simd-clean-gap-20260320 -mindepth 1 -maxdepth 2` | 修复前应残留证据 | 残留 `bin/lib/cpuinfo/cpuinfo.x86/publicabi` | ✓ |
| isolated clean guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-clean-fix-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 clean guard 不应误伤主线 check | PASS，日志包含 `isolated clean coverage present` | ✓ |
| isolated clean 闭环复验 | `SIMD_OUTPUT_ROOT=/tmp/simd-clean-fix-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> `clean` -> `find /tmp/simd-clean-fix-gate-20260320 -mindepth 1 -maxdepth 2` | 修复后隔离根应被完全清空 | gate PASS；clean 后 `find` 无输出 | ✓ |
| run_all 顶层日志污染复现 | `SIMD_OUTPUT_ROOT=/tmp/simd-runall-log-clobber-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` 后读取 `/tmp/.../logs/build.txt` 与 `/tmp/.../logs/test.txt` | 修复前应证明 artifact 根内部错位 | `build.txt` 变成 `fafafa.core.simd.cpuinfo.x86.test` 构建日志，而 `test.txt` 仍是 `fafafa.core.simd` suite 输出 | ✓ |
| run_all isolation guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-runall-isolation-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 run_all guard 不应误伤主线 check | PASS，日志包含 `run_all output isolation present` | ✓ |
| run_all isolation gate 复验 | `SIMD_OUTPUT_ROOT=/tmp/simd-runall-isolation-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` 后读取 `/tmp/.../logs/build.txt` 与 `find /tmp/.../run_all -maxdepth 3 -type f` | 修复后顶层 gate logs 不再被 run_all 过滤链覆盖，run_all 产物进入子根 | PASS；顶层 `build.txt` 回到 `fafafa.core.simd.test` 构建日志；`run_all/fafafa.core.simd*` 子树存在 | ✓ |
| run_all isolation clean 闭环 | `SIMD_OUTPUT_ROOT=/tmp/simd-runall-isolation-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh clean` -> `find /tmp/simd-runall-isolation-gate-20260320 -mindepth 1 -maxdepth 3` | clean 应连同 `run_all/` 一起清空 | PASS；`find` 无输出 | ✓ |
| intrinsics isolation clean 顺序复验 | `SIMD_OUTPUT_ROOT=/tmp/simd-intrinsics-clean-recheck-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> `clean` -> `find /tmp/simd-intrinsics-clean-recheck-20260320 -mindepth 1 -maxdepth 4` | 需要确认上一轮 clean 没有真实回归 | gate PASS；clean 后 `find` 无输出 | ✓ |
| run_all batch action 静态失败检查 | `python3 - <<'PY' ...` 检查 `tests/run_all_tests.bat` 是否仍是裸 `call "%SCRIPT%"`，且缺少 `ACTION=%RUN_ACTION%` 默认链 | 修复前应失败 | `bare_call=True`, `run_action_forwarding=False`, `action_default=False` | ✓ |
| run_all batch action 静态复验 | `python3 - <<'PY' ...` 检查 `tests/run_all_tests.bat` 是否具备 `RUN_ACTION -> ACTION -> call script` 链 | 修复后应通过 | `action_default=True`, `action_fallback=True`, `action_logged=True`, `action_forwarded=True`, `bare_call_removed=True` | ✓ |
| run_all batch action guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-runall-action-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `run_all output isolation present` | ✓ |
| run_all batch action guard gate | `SIMD_OUTPUT_ROOT=/tmp/simd-runall-action-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | 新 static guard 应进入日常 gate 而不破坏 fast-gate | PASS，filtered run_all 5 个模块全绿，整条 gate PASS | ✓ |
| experimental isolation 缺口复现 | `SIMD_OUTPUT_ROOT=/tmp/simd-experimental-isolation-gap-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh experimental-intrinsics-tests` 后读取日志与 `find /tmp/... -mindepth 1 -maxdepth 4` | 修复前应证明 experimental helper 未使用隔离根 | 运行日志直接写 `tests/fafafa.core.simd.intrinsics.experimental/logs/*.pas`；隔离根只有 `bin2/lib2/logs`；默认 experimental `logs/build.txt` / `test.txt` / smoke 源 mtime 被更新 | ✓ |
| experimental isolation 静态复验 | `python3 - <<'PY' ...` 检查 main shell/batch 与 experimental shell/batch 是否都具备 `OUTPUT_ROOT` 接线 | 修复后应通过 | shell/batch 关键 pattern 全为 `True` | ✓ |
| isolated experimental tests | `SIMD_OUTPUT_ROOT=/tmp/simd-experimental-isolation-fix-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh experimental-intrinsics-tests` | 修复后 experimental smoke 产物应进入隔离根下的 `intrinsics.experimental/` | PASS；日志显示 `/tmp/.../intrinsics.experimental/logs/*.pas` 与 `/tmp/.../intrinsics.experimental/bin/...` | ✓ |
| experimental isolation guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-experimental-isolation-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `experimental intrinsics output isolation present` | ✓ |
| experimental isolation clean 闭环 | `SIMD_OUTPUT_ROOT=/tmp/simd-experimental-isolation-fix-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh clean` -> `find /tmp/simd-experimental-isolation-fix-20260320 -mindepth 1 -maxdepth 4` | clean 应连同 `intrinsics.experimental/` 一起清空 | PASS；`find` 无输出 | ✓ |
| Windows experimental tests guard 静态复验 | `python3 - <<'PY' ...` 检查 batch 入口是否去掉 `SKIP (bash not found)` 并改成 fail-close | 修复后应通过 | `fail_close_message=True`, `skip_removed=True`, `exit_code_2=True` | ✓ |
| Windows experimental tests guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-win-experimental-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `Windows experimental tests runner guard present` | ✓ |
| Windows evidence collector public ABI 静态失败检查 | `python3 - <<'PY' ...` 检查 collector 是否调用 native `publicabi-smoke`，以及 shell/batch verifier 是否仍只认旧 `6/6` marker | 修复前应失败 | `collector_calls_publicabi_test=False`，两个 verifier 都缺 `6/7 Windows public ABI smoke`，`STATUS=FAIL` | ✓ |
| Windows evidence collector public ABI guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-win-evidence-publicabi-guard-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `Windows evidence collector public ABI guard present` | ✓ |
| Windows qemu runner 静态复验 | `rg -n ":require_qemu_bash_runtime|call :require_qemu_bash_runtime|FAILED \\^\\(bash runtime not found; qemu multiarch actions require bash to preserve shell parity\\^\\)|SKIP \\^\\(bash not found\\^\\)" tests/fafafa.core.simd/buildOrTest.bat` | 新 helper/fail-close 文案应存在，旧 `QEMU SKIP` 文案应消失 | 命中 `:require_qemu_bash_runtime`、7 处 `call :require_qemu_bash_runtime`、新的 `FAILED` 文案；剩余 `SKIP (bash not found)` 仅属于 `BENCH` / `RVV-LANE` | ✓ |
| Windows qemu runner guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-win-qemu-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 与更新后的 parity 签名不应误伤主线 check | PASS，日志包含 `Windows qemu runner guard present` 与 `windows runner parity signatures present` | ✓ |
| Windows bash helper 静态复验 | `rg -n ":require_backend_bench_bash_runtime|call :require_backend_bench_bash_runtime|backend-bench requires bash to preserve shell parity|:require_rvv_lane_bash_runtime|call :require_rvv_lane_bash_runtime|riscvv-opcode-lane requires bash to preserve shell parity|\\[BENCH\\] SKIP \\^\\(bash not found\\^\\)|\\[RVV-LANE\\] SKIP \\^\\(bash not found\\^\\)" tests/fafafa.core.simd/buildOrTest.bat` | bench/RVV 新 helper/fail-close 文案应存在，旧 `SKIP` 文案应消失 | 命中 bench/RVV helper 与新的 `FAILED` 文案；旧 `BENCH` / `RVV-LANE` `SKIP` 文案已消失 | ✓ |
| Windows bash helper guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-win-bash-helper-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 与更新后的 parity 签名不应误伤主线 check | PASS，日志包含 `Windows bash helper runner guard present` 与 `windows runner parity signatures present` | ✓ |
| QEMU experimental python helper 静态复验 | `rg -n "QEMU-EXPERIMENTAL-(REPORT|BASELINE).*FAILED|QEMU-EXPERIMENTAL-(REPORT|BASELINE).*SKIP" tests/fafafa.core.simd/buildOrTest.bat tests/fafafa.core.simd/BuildOrTest.sh` | 新 `FAILED` 文案应存在；旧 `SKIP` 文案只允许出现在 guard 的禁止列表里，不允许留在真实 helper 实现中 | 命中 shell/batch 的新 `FAILED` 文案；旧 `SKIP` 文案只存在于 guard 的 forbidden 列表 | ✓ |
| QEMU experimental python helper guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-qemu-experimental-python-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `QEMU experimental python helper guard present` | ✓ |
| 默认 Python checker 静态复验 | `rg -n "SKIP \\(python3 not found\\)|SKIP \\(python runtime not found\\)|FAILED \\(python3 runtime not found|FAILED \\(python runtime not found; tried py and python\\)|check_python_checker_runtime_guard|Python checker runtime guard present" tests/fafafa.core.simd/BuildOrTest.sh tests/fafafa.core.simd/buildOrTest.bat` | shell/batch 新 `FAILED` 文案应存在；旧 `SKIP` 文案只允许出现在 guard 的 forbidden 列表 | 命中 shell/batch 8 条 checker 的新 `FAILED` 文案；旧 `SKIP` 文案仅存在于 guard 的禁止列表 | ✓ |
| 默认 Python checker guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-python-checker-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `Python checker runtime guard present` | ✓ |
| publicabi shell export guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-shell-export-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `public ABI shell export guard present` | ✓ |
| publicabi validate-exports direct 复验 | `SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-validate-exports-20260320 bash tests/fafafa.core.simd.publicabi/BuildOrTest.sh validate-exports` | 真实导出符号校验在当前 Linux 环境下仍应通过 | PASS，日志显示 `readelf --wide --dyn-syms ...` 后 `[EXPORT] OK` | ✓ |
| gate-summary JSON runtime guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-gate-summary-json-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `gate-summary JSON runtime guard present` | ✓ |
| gate-summary JSON direct 正向导出 | `SIMD_OUTPUT_ROOT=/tmp/simd-gate-summary-json-direct-20260320 SIMD_GATE_SUMMARY_FILTER=FAIL SIMD_GATE_SUMMARY_JSON=1 SIMD_GATE_SUMMARY_JSON_FILE=/tmp/simd-gate-summary-json-direct-20260320/logs/gate_summary.fail.json bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary` | 正常环境下应生成 JSON 且 filter=FAIL | PASS，输出包含 `json=/tmp/.../gate_summary.fail.json`；导出文件中 `filter=\"FAIL\"`、`matched_rows=1` | ✓ |
| gate-summary JSON direct 无 Python 负向验证 | `env -i PATH=/tmp/simd-no-python-path-20260320 SIMD_OUTPUT_ROOT=/tmp/simd-gate-summary-json-direct-20260320 SIMD_GATE_SUMMARY_FILTER=FAIL SIMD_GATE_SUMMARY_JSON=1 SIMD_GATE_SUMMARY_JSON_FILE=/tmp/simd-gate-summary-json-direct-20260320/logs/gate_summary.fail.nopython.json /usr/bin/bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary` | 缺 Python 时应显式失败，不得继续打印假 `json=...` 成功信号 | rc=2，输出以 `[GATE-SUMMARY] FAILED (python3 runtime not found; SIMD_GATE_SUMMARY_JSON=1 requires python3)` 结束，未再打印 `json=...` | ✓ |
| perf-smoke scalar guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-perf-smoke-scalar-guard-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `perf-smoke scalar guard present` | ✓ |
| perf-smoke synthetic Scalar 负向验证 | `python3 tests/fafafa.core.simd/check_perf_smoke_log.py /tmp/simd-perf-smoke-scalar-log-20260320.txt` | Scalar backend 应视为缺失 SIMD 性能证据并失败，而不是 `SKIP 0` | rc=1，输出为 `[PERF] FAILED (active backend is Scalar; perf-smoke requires non-scalar backend evidence)` | ✓ |
| Linux evidence isolation guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-isolation-fix-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `Linux evidence output isolation present` | ✓ |
| isolated backend-bench | `SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-isolation-fix-bench-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh backend-bench` | `backend-bench-*` 应落到隔离根，默认模块 `logs/` 不应新增目录 | PASS，产物位于 `/tmp/.../logs/backend-bench-20260320-100249/`；默认 `tests/fafafa.core.simd/logs` 最新 backend-bench 目录仍停留在修复前 `20260320-095524` | ✓ |
| isolated evidence-linux 落点复验 | `SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-isolation-fix-run-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux` | evidence bundle 与内部 `backend-bench-*` 都应落到隔离根，默认模块 `logs/` 不应新增新目录 | rc=1（后续 `gate-strict` optional perf-smoke 失败）；但 `/tmp/.../logs/evidence-20260320-100349/` 与 `/tmp/.../logs/backend-bench-20260320-100409/` 已生成，默认 `tests/fafafa.core.simd/logs` 最新 evidence/backend-bench 目录仍停留在修复前时间戳 | ✓ |
| isolated evidence clean 闭环 | `SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-isolation-fix-run-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh clean` -> `find /tmp/simd-evidence-linux-isolation-fix-run-20260320 -mindepth 1 -maxdepth 3` | 新 evidence/backend-bench 隔离产物应随主 `clean` 一起清空 | PASS；`find` 无输出 | ✓ |
| perf-smoke direct repeat R1 | `SIMD_OUTPUT_ROOT=/tmp/simd-perf-instability-r1-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh perf-smoke` | 如果 gate-strict 失败来自稳定实现问题，direct 复跑应可帮助判断是否可重复 | PASS，`[PERF] OK (non-scalar backend benchmark looks healthy; public ABI hot-path ordering preserved)` | ✓ |
| perf-smoke direct repeat R2 | `SIMD_OUTPUT_ROOT=/tmp/simd-perf-instability-r2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh perf-smoke` | 再次 direct 复跑用于判断是否是单次噪声 | PASS，`[PERF] OK (non-scalar backend benchmark looks healthy; public ABI hot-path ordering preserved)` | ✓ |
| perf-smoke public ABI shape guard red | `SIMD_OUTPUT_ROOT=/tmp/simd-perf-shape-guard-red-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新静态 guard 应先把旧的单次调用 / 全局缓存 benchmark 形状打红 | rc=1；日志命中缺失 `PUBLIC_ABI_HOT_INNER`、`LApi := GetSimdPublicApi` 和旧 `g_PublicAbiApi` stale patterns | ✓ |
| perf-smoke public ABI shape guard green | `SIMD_OUTPUT_ROOT=/tmp/simd-perf-shape-green-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | benchmark 改成 local-cache hot-loop 后，静态 guard 与编译都应恢复通过 | PASS，日志包含 `perf-smoke public ABI benchmark shape present` | ✓ |
| rotated public ABI benchmark 6-run replay | `python3 tests/fafafa.core.simd/check_perf_smoke_log.py /tmp/simd-perf-rotated-samples-20260320/log-captures/run{1..6}.txt` | 新 checker 应保留 cache/getter 波动为 `NOTE`，但不再把它误记成失败 | 6/6 rc=0；`NOTE` 仅在部分样本出现，`PubGet > DispGet` 始终保持 | ✓ |
| perf-smoke final R1 | `SIMD_OUTPUT_ROOT=/tmp/simd-perf-smoke-final-r1-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh perf-smoke` | 调整后的 perf-smoke 主链应通过；如有 cache/getter 波动仅输出 `NOTE` | PASS；输出包含 `NOTE: cached public ABI table was not faster...` 与最终 `OK` | ✓ |
| perf-smoke final R2 | `SIMD_OUTPUT_ROOT=/tmp/simd-perf-smoke-final-r2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh perf-smoke` | 再次 direct 复跑确认主链稳定 | PASS；直接 `OK` | ✓ |
| evidence-linux final (sandbox) | `SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-final-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux` | `perf-smoke` 与 `gate-strict` 内置 perf step 都应通过；若失败，预期只剩环境权限问题 | rc=1；前置 `perf_smoke` 与 `gate_strict` 内置 `perf-smoke` 均 PASS，最终仅在 `qemu-cpuinfo-nonx86-evidence` 访问 `/var/run/docker.sock` 时因 sandbox 权限失败 | ✓ |
| qemu cpuinfo non-x86 evidence escalated | `SIMD_OUTPUT_ROOT=/tmp/simd-qemu-cpuinfo-evidence-escalated-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh qemu-cpuinfo-nonx86-evidence` | 提权后应证明剩余失败点只是 Docker 权限，而不是代码回归 | PASS；`[DONE] All platforms passed` | ✓ |
| evidence-linux full escalated | `SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-escalated-full-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux` | 完整 closeout 链应至少通过 `gate-strict` 与 QEMU CPUInfo non-x86 evidence；若失败，需定位是否是收尾 helper 误读产物 | rc=1；`gate` PASS、`qemu-cpuinfo-nonx86-evidence` PASS，但末尾 `freeze_status_linux` 误读默认 gate summary，触发新的 isolation bug | ✓ |
| freeze-status isolation guard check | `SIMD_OUTPUT_ROOT=/tmp/simd-freeze-isolation-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 新 static guard 不应误伤主线 check | PASS，日志包含 `freeze-status output isolation present` | ✓ |
| freeze-status linux targeted replay | `SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-escalated-full-20260320 SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` | 应读取本轮 isolated gate summary，而不是默认目录旧产物 | PASS；输出 `ready=True`，并命中 `gate PASS at 2026-03-20 12:16:09` 与 `linux_qemu_cpuinfo_nonx86_evidence: PASS` | ✓ |
| evidence-linux full escalated final rerun | `SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-escalated-full-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux` | 修复 `freeze-status` 隔离后，完整 closeout 链应以 fresh isolated artifacts 完整通过 | PASS；`rc=0`，`gate PASS @ 2026-03-20 12:36:58`，`qemu-cpuinfo-nonx86-evidence PASS`，`freeze-status ready=True`，`evidence-verify` 仅对旧 `windows_b07_gate.log` 记 optional `SKIP` | ✓ |
| x86 predicate suite list | `SIMD_OUTPUT_ROOT=/tmp/simd-x86-pred-list-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --list-suites` | 主 runner 默认 x86_64 构建应列出新的纯逻辑 suite | PASS；`logs/test.txt` 含 `TTestCase_X86BackendPredicates` | ✓ |
| x86 predicate suite | `SIMD_OUTPUT_ROOT=/tmp/simd-x86-pred-suite-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86BackendPredicates` | 纯逻辑 AVX-512 CPU 谓词回归应在默认 x86_64 主 runner 中通过 | PASS；`Tests run: 2, Failures: 0, Errors: 0` | ✓ |
| x86 predicate follow-up check | `SIMD_OUTPUT_ROOT=/tmp/simd-x86-pred-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | 拆分 suite 后主 `check` 仍应通过 | PASS | ✓ |
| SSE4.2 inheritance red | `SIMD_OUTPUT_ROOT=/tmp/simd-sse42-red-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots` | 新增 `SSE4.2 <- SSE4.1` dispatch 继承断言应先打红 | FAILED；`Test_SSE42_Inherits_SSE41_DispatchSlots` 报 `MulI32x4` 指针不等 | ✓ |
| SSE4.2 inheritance green | `SIMD_OUTPUT_ROOT=/tmp/simd-sse42-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots` | 修复 `RegisterSSE42Backend` 后定向 suite 应转绿 | PASS | ✓ |
| SSE4.2 inheritance check | `SIMD_OUTPUT_ROOT=/tmp/simd-sse42-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | x86 backend 注册链修复后主 `check` 仍应通过 | PASS | ✓ |
| SSE4.2 inheritance gate | `SIMD_OUTPUT_ROOT=/tmp/simd-sse42-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | x86 backend 注册链修复后 fast-gate 全链路应通过 | PASS；`[GATE] OK` | ✓ |
| capability integer underclaim suite | `SIMD_OUTPUT_ROOT=/tmp/simd-cap-intops-dispatchapi-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` | 新增 `scIntegerOps` underclaim 回归后，主 DispatchAPI suite 应保持通过 | PASS | ✓ |
| capability integer underclaim publicabi | `SIMD_OUTPUT_ROOT=/tmp/simd-cap-intops-publicabi-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` | capability metadata 直接映射到 public ABI pod info，public ABI suite 不应回归 | PASS | ✓ |
| capability integer underclaim check | `SIMD_OUTPUT_ROOT=/tmp/simd-cap-intops-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | capability metadata 最小修复后主 `check` 仍应通过 | PASS | ✓ |
| capability integer underclaim gate | `SIMD_OUTPUT_ROOT=/tmp/simd-cap-intops-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | capability metadata 最小修复后 fast-gate 全链路应通过 | PASS；`[GATE] OK`，Windows evidence 仍只记 optional `SKIP` | ✓ |
| public ABI codegen probe | `fpc -O3 -Fu/home/dtamade/projects/fafafa.core/src -Fi/home/dtamade/projects/fafafa.core/src -FU/tmp/simd-codegen-probe/units -FE/tmp/simd-codegen-probe/bin /tmp/simd_publicapi_codegen_probe.pas` + `objdump -dr -Mintel /tmp/simd-codegen-probe/units/simd_publicapi_codegen_probe.o` | 需要拿到 `GetSimdPublicApi` vs local cache vs `GetDispatchTable` 的 FPC codegen 证据，决定 `PubCache >= PubGet` 是否值得升回 hard gate | PASS；`CallPublicCached` 与 `CallPublicGetter` 都直接加载 `g_SimdPublicApi` 后调函数指针，`DispatchGetter` 路径明显更重 | ✓ |
| priority canonical compile failure root-cause | `sed -n '1,220p' /tmp/simd-priority-dispatchapi-20260320/logs/build.txt` + `sed -n '1,220p' /tmp/simd-priority-check-20260320/logs/build.txt` | 首次 priority 修复失败时，需要先定位是否为测试误报还是实现单元真实编译错误 | 已定位为 `src/fafafa.core.simd.sse2.pas(10528,17) Error: Identifier not found \"GetSimdBackendPriorityValue\"`，根因是 `sse2` 单元漏依赖 `fafafa.core.simd.backend.priority` | ✓ |
| priority canonical DispatchAPI | `SIMD_OUTPUT_ROOT=/tmp/simd-priority-dispatchapi-20260320b bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` | 补齐 `sse2` 依赖后，新加的 raw-priority contract 回归和整组 `DispatchAPI` 应通过 | PASS | ✓ |
| priority canonical check | `SIMD_OUTPUT_ROOT=/tmp/simd-priority-check-20260320b bash tests/fafafa.core.simd/BuildOrTest.sh check` | `SSE2` raw priority 改成 canonical helper 后，主 `check` 不应回归 | PASS | ✓ |
| priority canonical gate | `SIMD_OUTPUT_ROOT=/tmp/simd-priority-gate-20260320b bash tests/fafafa.core.simd/BuildOrTest.sh gate` | priority contract 修复后 fast-gate 全链路应通过 | PASS；`[GATE] OK`，Windows evidence 仍只记 optional `SKIP` | ✓ |
| vector-asm capability red | `SIMD_OUTPUT_ROOT=/tmp/simd-vectorasm-cap-red-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` | 新增 runtime-toggle capability 回归应先证明问题真实存在 | FAILED；`Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled` 命中 `SSE2` 仍高报 `scIntegerOps` | ✓ |
| vector-asm capability green | `SIMD_OUTPUT_ROOT=/tmp/simd-vectorasm-cap-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` | `scIntegerOps` 应跟随受控 x86 backend 的 vector-asm gate 收缩 | PASS | ✓ |
| vector-asm capability check | `SIMD_OUTPUT_ROOT=/tmp/simd-vectorasm-cap-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | runtime-toggle capability 修复后主 `check` 不应回归 | PASS | ✓ |
| vector-asm capability gate | `SIMD_OUTPUT_ROOT=/tmp/simd-vectorasm-cap-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | runtime-toggle capability 修复后 fast-gate 全链路应通过 | PASS；`[GATE] OK`，Windows evidence 仍只记 optional `SKIP` | ✓ |
| AVX2 `scFMA` red | `SIMD_OUTPUT_ROOT=/tmp/simd-fma-cap-red3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` | 新增 AVX2 fused-FMA capability 回归应先证明 underclaim 真实存在 | FAILED；`Test_AVX2_BackendCapabilities_Expose_FMA_When_FusedPathUsable` 命中 `AVX2 should advertise scFMA once FmaF32x4 is using fused hardware instructions` | ✓ |
| AVX2 `scFMA` green | `SIMD_OUTPUT_ROOT=/tmp/simd-fma-cap-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` | `scFMA` 应跟随 `vector asm + gfFMA` 真 fused 路径对外暴露 | PASS | ✓ |
| AVX2 `scFMA` publicabi | `SIMD_OUTPUT_ROOT=/tmp/simd-fma-cap-publicabi-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` | `scFMA` 修复后 public ABI `CapabilityBits` 不应回归 | PASS | ✓ |
| AVX2 `scFMA` check | `SIMD_OUTPUT_ROOT=/tmp/simd-fma-cap-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | AVX2 `scFMA` capability 修复后主 `check` 不应回归 | PASS | ✓ |
| AVX2 `scFMA` gate | `SIMD_OUTPUT_ROOT=/tmp/simd-fma-cap-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | AVX2 `scFMA` capability 修复后 fast-gate 全链路应通过 | PASS；`[GATE] OK`，Windows evidence 仍只记 optional `SKIP` | ✓ |
| AVX2 `scShuffle` red | `SIMD_OUTPUT_ROOT=/tmp/simd-avx2-shuffle-cap-red-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` | 新增 AVX2 shuffle capability 回归应先证明 underclaim 真实存在 | FAILED；`Test_AVX2_BackendCapabilities_Expose_Shuffle_When_NativeShuffleSlotsUsable` 命中 `AVX2 should advertise scShuffle once representative shuffle slots are non-scalar` | ✓ |
| AVX2 `scShuffle` publicabi red | `SIMD_OUTPUT_ROOT=/tmp/simd-avx2-shuffle-publicabi-red-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` | public ABI `CapabilityBits` 应同步暴露 AVX2 shuffle capability | FAILED；`Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2Shuffle_WhenNativeSlotsPresent` 命中 `CapabilityBits` 漏报 | ✓ |
| AVX2 `scShuffle` green | `SIMD_OUTPUT_ROOT=/tmp/simd-avx2-shuffle-cap-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` | `scShuffle` 应跟随 `vector asm` 下真实原生 shuffle 槽位对外暴露 | PASS | ✓ |
| AVX2 `scShuffle` publicabi green | `SIMD_OUTPUT_ROOT=/tmp/simd-avx2-shuffle-publicabi-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` | AVX2 shuffle capability 修复后 public ABI `CapabilityBits` 不应回归 | PASS | ✓ |
| AVX2 `scShuffle` check | `SIMD_OUTPUT_ROOT=/tmp/simd-avx2-shuffle-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check` | AVX2 `scShuffle` capability 修复后主 `check` 不应回归 | PASS | ✓ |
| AVX2 `scShuffle` gate | `SIMD_OUTPUT_ROOT=/tmp/simd-avx2-shuffle-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` | AVX2 `scShuffle` capability 修复后 fast-gate 全链路应通过 | PASS；`[GATE] OK`，Windows evidence 仍只记 optional `SKIP` | ✓ |

## Error Log
| Timestamp | Error | Attempt | Resolution |
|-----------|-------|---------|------------|
| 2026-03-20 | runner 覆盖缺口：`DirectDispatch` 未进入 parity/gate | 1 | 通过静态失败检查定位并修复 shell/bat runner，随后重跑 check/parity-suites/gate |
| 2026-03-20 | parity checker 对 action 差集无感知 | 1 | 为 `check_windows_runner_parity` 增加动作集对账和 allowlist，并重跑静态检查与 `check` |
| 2026-03-20 | external public ABI smoke 没有验证 `ActiveFlags` / active backend pod flags | 1 | 先用静态检查打红，再补 C / PowerShell harness 的 consumer-side 断言，并重跑 Linux smoke 与主 `gate` |
| 2026-03-20 | alias 分叉回归测试首次编译失败：`Identifier not found "cpuinfo"` | 1 | 给 `fafafa.core.simd.dispatchapi.testcase.pas` 补 `fafafa.core.simd.cpuinfo` 到 `uses`，随后重跑 suite/gate |
| 2026-03-20 | Windows public ABI batch runner 只探测 `powershell`，找不到时把 external smoke 静默 `SKIP 0` | 1 | 改成 `pwsh -> powershell` fallback + fail-close，并把静态 guard 接到 `check` / `gate` 后重跑通过 |
| 2026-03-20 | public ABI isolation guard 首次实现误匹配到自身字符串，导致 `check` 假红 | 1 | 删除过宽的负向字符串检查，只保留正向 isolation 签名约束，然后重跑 `check` / `gate` 通过 |
| 2026-03-20 | isolated `clean` 只删 `bin2/lib2/logs`，导致 `SIMD_OUTPUT_ROOT` 预演后仍残留 `bin/lib/cpuinfo/cpuinfo.x86/publicabi` | 1 | 先用 fresh `gate -> clean -> find` 固化证据，再扩 shell/batch clean 目录集并增加 `check_isolated_clean_coverage`，最后重跑 `check` / `gate` / `clean` 验证通过 |
| 2026-03-20 | `run_all_tests` 过滤链共享顶层 `SIMD_OUTPUT_ROOT/logs`，把 gate 的 `build.txt` 覆盖成 `cpuinfo.x86` 构建日志 | 1 | 先用 fresh `gate` + 直接读顶层 `build.txt`/`test.txt` 固化错位证据，再把 shell/batch `run_all_tests` 改成 simd 模块专用 `run_all/<module>/` 子根，补 `check_run_all_output_isolation`，最后重跑 `check` / `gate` / `clean` 闭环 |
| 2026-03-20 | `tests/run_all_tests.bat` 忽略 `RUN_ACTION`，让 Windows filtered run_all 静默回落到模块默认 action | 1 | 先用静态检查确认 batch 版缺少 `ACTION=%RUN_ACTION%` / 显式传参，再修改 `tests/run_all_tests.bat` 并扩充 `check_run_all_output_isolation` 守卫，最后重跑静态检查、fresh `check`、fresh `gate` 通过 |
| 2026-03-20 | `experimental-intrinsics-tests` 忽略 `SIMD_OUTPUT_ROOT`，让 experimental smoke 产物继续污染默认模块目录 | 1 | 先用 isolated direct action 固化“隔离根缺产物、默认日志被改写”的证据，再补主 shell/batch 传播与 experimental shell/batch 子 runner 的 `OUTPUT_ROOT`，增加 `check_experimental_intrinsics_output_isolation` 并扩展 clean，最后重跑 direct action、fresh `check`、`clean -> find` 通过 |
| 2026-03-20 | Windows `experimental-intrinsics-tests` 在缺 `bash` 时静默 `SKIP 0`，会让 direct action 或手动 experimental gate 配置出现假绿 | 1 | 先用静态检查和 `gate-strict` 配置证据确认该入口是 release-gate 组成部分，再改成 fail-close 并增加 `check_windows_experimental_tests_runner_guard`，最后重跑静态检查与 fresh `check` 通过 |
| 2026-03-20 | Windows native closeout evidence collector 漏跑 `publicabi-smoke`，而 verifier 仍接受旧 `6/6` evidence log | 1 | 先用静态检查固化 collector/verifier 缺口，再把 collector 升为 `1/7..7/7` 并补 native `publicabi-smoke`，同步更新 shell/batch verifier 与 `check_windows_evidence_collector_guard`，最后重跑 fresh `check` 通过 |
| 2026-03-20 | Windows `qemu-*` batch direct actions 在缺 `bash` 时静默 `SKIP 0`，会把 non-x86 evidence 伪装成成功 | 1 | 抽出 `:require_qemu_bash_runtime` 统一改成 fail-close，并新增 `check_windows_qemu_runner_guard`；首次 fresh `check` 因旧 parity 仍要求 `QEMU SKIP` 文案而假红，随后同步更新 `check_windows_runner_parity` 后重跑通过 |
| 2026-03-20 | Windows `backend-bench` / `riscvv-opcode-lane` 在缺 `bash` 时静默 `SKIP 0`，会把 benchmark/RVV lane 根本没跑伪装成成功 | 1 | 为两者分别补 `:require_*_bash_runtime` helper，新增 `check_windows_bash_helper_runner_guard`，并同步更新 `check_windows_runner_parity` 的 bench/RVV 签名；fresh `check` 通过 |
| 2026-03-20 | `qemu-experimental-report` / `qemu-experimental-baseline-check` 在 shell/batch 两侧缺 Python 时静默 `SKIP 0`，会把归因报告/基线校验根本没跑伪装成成功 | 1 | shell/batch 两侧都改成 fail-close，并新增 `check_qemu_experimental_python_helper_guard`；首次 fresh `check` 因 guard 自命中旧 `SKIP` 字符串而假红，随后把匹配范围收窄到真实函数体后重跑通过 |
| 2026-03-20 | 默认 `check` / `gate` 依赖的 Python checker 在缺运行时时静默 `SKIP 0`，会把主门禁结构护栏伪装成通过 | 1 | shell/batch 两侧 8 条 checker 全部改成 fail-close，并新增 `check_python_checker_runtime_guard`；fresh `check` 通过 |
| 2026-03-20 | `publicabi` shell runner 的 `validate-exports` 在缺 `readelf/nm` 时静默 `SKIP 0`，会把导出符号已校验伪装成成立 | 1 | 改成 fail-close，并新增 `check_publicabi_shell_export_guard`；main `check` 与 direct `validate-exports` 均通过 |
| 2026-03-20 | `SIMD_GATE_SUMMARY_JSON=1` 在 shell/batch 两侧缺 Python 时仍会成功返回，shell 甚至继续打印 `json=...` | 1 | shell/batch 两侧都改成 fail-close，给 `run_gate_summary` 补显式错误传播，并新增 `check_gate_summary_json_runtime_guard`；随后用 fresh `check`、direct 正向导出与 no-python 负向验证复验通过 |
| 2026-03-20 | `perf-smoke` 在 shell/batch/Python 三处都把 Scalar backend 当成 `SKIP 0`，会让 `gate-strict` / `evidence-linux` 把缺失的性能证据误判成通过 | 1 | shell/batch/Python 三处都改成 Scalar 时 fail-close，并新增 `check_perf_smoke_scalar_guard`；随后用 fresh `check` 与 synthetic Scalar perf log 负向验证复验通过 |
| 2026-03-20 | `evidence-linux` collector 与其内部 `backend-bench` 子步骤忽略 `SIMD_OUTPUT_ROOT`，会把 isolated dry-run 产物写回默认 `tests/fafafa.core.simd/logs` | 1 | collector/bench 脚本都改成 `OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${SCRIPT_DIR}}"`，新增 `check_linux_evidence_output_isolation`，随后用 fresh `check`、isolated `backend-bench`、isolated `evidence-linux` 与 `clean -> find` 复验通过 |
| 2026-03-20 | public ABI `perf-smoke` 旧 checker 把 `PubCache >= PubGet` 当成 hard gate，但 benchmark 形状修正后仍会被 FPC inline getter 代码生成打出假阳性 | 1 | 先用 `check_perf_smoke_public_abi_shape_guard` 固化 local-cache hot-loop benchmark 形状，再把 `bench.pas` 改成 inner loop + rotated sampling，最后把 Python checker 收敛为仅对稳定的 `PubGet > DispGet` 做 hard fail、`PubCache < PubGet` 只记 `NOTE`；fresh `check`、6 轮 log replay、两次 `perf-smoke` 与 `evidence-linux` perf step 均通过 |
| 2026-03-20 | `evidence-linux` 最后一处失败是 sandbox 内 `qemu-cpuinfo-nonx86-evidence` 无权访问 Docker，而不是代码回归 | 1 | 保留 sandbox 内失败日志作为环境证据，并对同一步骤提权重跑；3 个 non-x86 目标全部通过，确认剩余阻塞来自环境权限 |
| 2026-03-20 | 提权后的完整 `evidence-linux` 仍在 `freeze_status_linux` 尾段误读默认 `tests/fafafa.core.simd/logs/gate_summary.md`，导致 isolated run 的当前 gate PASS / qemu PASS 被旧 summary 覆盖 | 1 | 把 `run_freeze_status()` 的默认 json/gate summary 路径改到当前 `LOG_DIR` / `GATE_SUMMARY_LOG`，并让 evidence collector 显式传入 freeze env；新增 `check_freeze_status_output_isolation` 后 fresh `check` 通过，targeted `freeze-status-linux` replay 也已 `ready=True` |
| 2026-03-20 | `freeze-status` 修复后仍需证明 full `evidence-linux` 端到端没有残余问题，而不只是 targeted replay 通过 | 1 | 持续轮询提权 full rerun 到 `rc=0`，确认 `gate PASS @ 2026-03-20 12:36:58`、`qemu-cpuinfo-nonx86-evidence PASS`、`freeze-status ready=True`；剩余仅是 Windows 历史 evidence 在 Linux closeout 中记 optional `SKIP` |
| 2026-03-20 | AVX-512 CPU 谓词回归最初挂在 `SIMD_BACKEND_AVX512` gated suite，默认 x86_64 主 runner 虽已 `RegisterTest` 但仍不可达 | 1 | 将纯逻辑测试拆到新的 `TTestCase_X86BackendPredicates` 并接入 `fafafa.core.simd.test.lpr` 的 `ProcessAllSuites`；fresh `--list-suites` 已出现该 suite，fresh 定向 suite 与 fresh `check` 均通过 |
| 2026-03-20 | `RegisterSSE42Backend` 直接从 scalar baseline 起步，没有继承 `SSE4.1` 已注册 dispatch table，导致强制 `sbSSE42` 时高价值槽位静默退回 scalar | 1 | 先在 `TTestCase_DispatchAllSlots` 新增指针级继承断言并跑出 red，再把 `src/fafafa.core.simd.sse42.register.inc` 改成 `SSE41 -> SSSE3 -> SSE3 -> SSE2 -> scalar` 逐级 clone fallback；随后 fresh 定向 suite、fresh `check`、fresh `gate` 全部通过 |
| 2026-03-20 | x86 backend capability metadata 少报 `scIntegerOps`，会让 public ABI `CapabilityBits` 对外低报真实整数操作族 | 1 | 在 `TTestCase_DispatchAPI` 增加 underclaim 回归测试，以代表性整数槽位非 scalar 作为证据；随后给 `SSE2/SSE2-i386/SSE3/AVX2/AVX512` capability set 补入 `scIntegerOps`，并用 fresh `DispatchAPI`、`PublicAbi`、`check`、`gate` 复验通过 |
| 2026-03-20 | 首次 priority 修复后的 fresh `DispatchAPI/check/gate` 编译失败：`sse2` 单元找不到 `GetSimdBackendPriorityValue` | 1 | 先读两份 fresh build log，确认不是测试逻辑问题，而是 `src/fafafa.core.simd.sse2.pas` 漏引 `fafafa.core.simd.backend.priority`；随后补依赖并重跑 fresh `DispatchAPI`、fresh `check`、fresh `gate` 全部通过 |
| 2026-03-20 | runtime 关闭 `vector asm` 后，受该开关控制的 x86 backend 仍继续高报 `scIntegerOps`，与实际整数槽位已退回 scalar 的状态不一致 | 1 | 先在 `DispatchAPI` 增加 red test，确认失败点就是 `SSE2` 的 capability 假绿；随后把 `SSE2/SSE2-i386/SSE3/SSSE3/SSE41/SSE42/AVX2` 的 `scIntegerOps` 改为跟随各自实际 vector-asm gate，并用 fresh `DispatchAPI`、fresh `check`、fresh `gate` 复验通过 |
| 2026-03-20 | 首次 AVX2 `scFMA` 回归测试编译失败：测试文件未引入 `gfFMA`，且直接复用了另一个 testcase 私有的 `SingleFromBits` helper | 1 | 给 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 补 `fafafa.core.simd.cpuinfo.base` 到 `uses`，并在新 testcase 内加入局部 `SingleFromBitsLocal` helper；随后重跑 fresh `DispatchAPI`，拿到真正的 underclaim red |
| 2026-03-20 | `AVX2` 在当前 CPU/OS 上已经走 fused `vfmadd*`，但注册表 capability 仍低报 `scFMA` | 1 | 先在 `DispatchAPI` 增加两条回归测试，强制开启/关闭 `vector asm` 证明 fused witness 与 capability 的真实漂移；随后把 `src/fafafa.core.simd.avx2.register.inc` 的 `scFMA` 改为跟随 `LEnableVectorAsm and HasFeature(gfFMA)`，并用 fresh `DispatchAPI`、fresh `check`、fresh `gate` 复验通过 |
| 2026-03-20 | `AVX2 scFMA` 修复完成后还缺一份 fresh public ABI 复验，无法确认 `CapabilityBits` 是否已同步 | 1 | 回收 `SIMD_OUTPUT_ROOT=/tmp/simd-fma-cap-publicabi-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`，`rc=0`；确认 AVX2 `scFMA` 修复已透传到 public ABI pod info |
| 2026-03-20 | `AVX2` 在 `vector asm` 打开时已经把 `Select/Insert/Extract` 等代表性 shuffle 槽位绑到原生实现，但 capability/public ABI 仍低报 `scShuffle` | 1 | 先在 `DispatchAPI` / `PublicAbi` 各补一条 red test，拿到 fresh red；随后把 `src/fafafa.core.simd.avx2.register.inc` 的 `scShuffle` 改为跟随 `LEnableVectorAsm`，并用 fresh `DispatchAPI`、fresh `PublicAbi`、fresh `check`、fresh `gate` 复验通过 |
| 2026-03-20 | `SetVectorAsmEnabled(True -> False)` 后 `SSE3/SSSE3/SSE41` 没有参与 runtime rebuild，导致 `SSE41/SSE42` 继续继承旧表；补完 rebuilder 后又暴露 `SSE41/SSE42` 的 `scShuffle` metadata 仍未随 toggle 清除 | 1 | fresh `DispatchAPI` red 先命中 `SSE41 SelectF32x4 should fall back to scalar when vector asm is disabled`；补 `src/fafafa.core.simd.sse3.register.inc`、`src/fafafa.core.simd.ssse3.register.inc`、`src/fafafa.core.simd.sse41.register.inc` 的 `RegisterBackendRebuilder(...)` 后，第二次 red 前移到 `SSE41` 的 `scShuffle` 假绿；随后把 `src/fafafa.core.simd.ssse3.register.inc`、`src/fafafa.core.simd.sse41.register.inc`、`src/fafafa.core.simd.sse42.register.inc` 的 `scShuffle` 改为跟随 `IsVectorAsmEnabled`，并把 `Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled` 升级成 `True -> False` 路径，最终 fresh `DispatchAPI`、fresh `PublicAbi`、fresh `check`、fresh `gate` 全部通过 |
| 2026-03-20 | 主 `simd` shell/batch runner 之前没有公开的 AVX-512 opt-in 编译通道，导致 `SIMD_BACKEND_AVX512` future guard 只能靠手工 `lazbuild --opt=-dSIMD_BACKEND_AVX512` 验证，无法纳入常规 fresh runner 证据链 | 1 | 先用直接 `lazbuild --opt=-dSIMD_BACKEND_AVX512` 预演，确认 opt-in 编译能成功且 `--list-suites` 会出现 `TTestCase_AVX512BackendRequirements` / `TTestCase_AVX512VectorAsm`；随后给 `tests/fafafa.core.simd/BuildOrTest.sh` 与 `buildOrTest.bat` 补上 `SIMD_ENABLE_AVX512_BACKEND=1` -> `--opt=-dSIMD_BACKEND_AVX512` 通道，并新增 `check_avx512_optin_runner_guard`；最终 fresh 默认 `check`、fresh opt-in `check`、fresh opt-in `test --list-suites`、fresh opt-in `TTestCase_AVX512BackendRequirements`、fresh opt-in `TTestCase_DispatchAPI`、fresh opt-in `TTestCase_PublicAbi`、fresh opt-in `gate` 全部通过 |
| 2026-03-20 | 当前默认 settings 仍关闭 `SIMD_BACKEND_AVX512`，导致 fresh Linux 主门禁无法直接验证 `AVX512 scFMA` capability 修复 | 1 | 先确认 `src/fafafa.core.settings.inc` 的默认宏仍注释掉 `SIMD_BACKEND_AVX512`；因此本轮只把 `avx512.register.inc` 的 `scFMA` 源码级一致性修复和 future guard 保留下来，后续需在显式启用该 backend 的构建中单独取 fresh red/green 证据 |
| 2026-03-20 | 首次尝试用 `-al` 直接导出汇编时，`fafafa.core.simd.sse42` 会在 GNU as 上因 `crc32` inline asm 语法报错，阻塞 codegen 取证 | 1 | 放弃外部 assembler 源输出，改走正常 `-O3` 编译后直接反汇编 `/tmp/simd-codegen-probe/units/simd_publicapi_codegen_probe.o`，成功拿到 `PubCache/PubGet/DispGet` 的机器级证据 |

### Phase 6: non-x86 opt-in compile blocker closeout
- **Status:** complete
- Actions taken:
  - 读取 `src/fafafa.core.simd.riscvv.pas`、`src/fafafa.core.simd.riscvv.facade.inc`、`src/fafafa.core.simd.riscvv.helpers.inc`，确认主单元已在 include 前关闭 asm 分支，而 `facade.inc` 仍残留 `{$ENDIF}` 提前于 `{$ELSE}` 的骨架错误
  - 修改 `src/fafafa.core.simd.riscvv.facade.inc`，删除多余的中途 `{$ENDIF}`，并在文件尾补上真正的 `{$ENDIF}`
  - fresh 运行 `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-optin-suite-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`，确认 `RISCVV` opt-in suite PASS
  - 读取 `src/fafafa.core.simd.neon.pas`、`src/fafafa.core.simd.neon.scalar_fallback.inc`、`src/fafafa.core.simd.neon.scalar.wide_reduce.inc`、`src/fafafa.core.simd.neon.scalar.wide_memory.inc`，确认 `FAFAFA_SIMD_NEON_ASM_ENABLED` 依赖跨 include 偷闭合，且 `wide_reduce.inc` 自己缺少 `{$ENDIF}`
  - 修改 `src/fafafa.core.simd.neon.pas`，让主单元在 `neon.facade_asm.inc` 后显式 `{$ENDIF}` 收口 asm 分支
  - 修改 `src/fafafa.core.simd.neon.scalar_fallback.inc`，把纯 scalar fallback 与 `scalar.autowrap` / wide helper 的条件编译边界拆开，避免继续从 include 内偷关父级 `IFDEF`
  - 修改 `src/fafafa.core.simd.neon.scalar.wide_reduce.inc`，补上缺失的 `{$ENDIF}`
  - fresh 运行 `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-optin-suite-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`，确认 `NEON` opt-in suite PASS
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260320-nonx86-optin-fixes bash tests/fafafa.core.simd/BuildOrTest.sh gate`，确认默认主线 gate 未被上述 backend 修复破坏
- Files created/modified:
  - `src/fafafa.core.simd.riscvv.facade.inc` (modified)
  - `src/fafafa.core.simd.neon.pas` (modified)
  - `src/fafafa.core.simd.neon.scalar_fallback.inc` (modified)
  - `src/fafafa.core.simd.neon.scalar.wide_reduce.inc` (modified)

### Phase 7: non-x86 opt-in registration and fallback-capability closeout
- **Status:** complete
- Actions taken:
  - 继续深审 `NEON/RISCVV` capability contract 时，确认上一轮 opt-in suite 之所以是绿的，并不是 metadata 正确，而是 backend 根本没注册：`neon.register.inc` 仍只在 `FAFAFA_SIMD_NEON_ASM_ENABLED + CPUAARCH64/CPUARM` 下初始化，`riscvv.register.inc` 仍只在 `CPURISCV*` 下初始化，而 testcase 里还是 `if not TryGetRegisteredBackendDispatchTable(...) then Exit;`
  - 先把 `DispatchAPI/PublicAbi` 两组 non-x86 testcase 升级成正确合同：在测试专用 registration define 存在时，必须显式断言 backend/pod info 已注册；同时把断言从“只要函数指针不同就 expose”改成“asm 可用时 expose，只有 scalar fallback 时 clear”
  - 修改 `tests/fafafa.core.simd/BuildOrTest.sh` 与 `buildOrTest.bat`，让 `SIMD_ENABLE_NEON_BACKEND=1` / `SIMD_ENABLE_RISCVV_BACKEND=1` 除了 backend define 之外，也传入 `FAFAFA_SIMD_TEST_REGISTER_NEON_BACKEND` / `FAFAFA_SIMD_TEST_REGISTER_RISCVV_BACKEND`
  - 修改 `src/fafafa.core.simd.neon.register.inc` 与 `src/fafafa.core.simd.riscvv.register.inc`，增加 test-only registration 路径，使非原生主机上的 opt-in suite 能把 scalar/common fallback backend 注册进 dispatch/public ABI 视图，而不影响默认 stable 路径
  - 回收 fresh red：
    - `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-red2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-red2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
  - red 结果确认了真实 overclaim：
    - `NEON should not advertise scShuffle when only scalar fallback shuffle slots are compiled`
    - `RISCVV should not advertise scFMA when only scalar fallback FMA slots are compiled`
  - 修改 `src/fafafa.core.simd.neon.register.inc`，把 `scShuffle` 改成仅在 `FAFAFA_SIMD_NEON_ASM_ENABLED` 时加入 capability set
  - 修改 `src/fafafa.core.simd.riscvv.register.inc`，把 `scFMA` 改成仅在 `RISCVV_ASSEMBLY` 时加入 capability set
  - 回收 fresh green：
    - `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
  - 最后 fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260320-nonx86-registration-fixes bash tests/fafafa.core.simd/BuildOrTest.sh gate`，确认新增 test-only define 接线和 capability 修复未破坏默认主线
- Files created/modified:
  - `tests/fafafa.core.simd/BuildOrTest.sh` (modified)
  - `tests/fafafa.core.simd/buildOrTest.bat` (modified)
  - `src/fafafa.core.simd.neon.register.inc` (modified)
  - `src/fafafa.core.simd.riscvv.register.inc` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified)

### Phase 8: non-x86 capability symmetry closeout
- **Status:** complete
- Actions taken:
  - 继续对 `NEON/RISCVV` 做 capability 对称审查时，发现上一轮只收敛了 `NEON scShuffle` 与 `RISCVV scFMA`，而 `NEON scFMA`、`RISCVV scShuffle` 仍然是无条件宣称
  - 读取 `src/fafafa.core.simd.neon.scalar.ext_math.inc` / `src/fafafa.core.simd.neon.scalar.autowrap.inc` 与 `src/fafafa.core.simd.riscvv.facade.inc` 后确认：这两组能力在非 asm 路径下虽然有 backend-local 函数名，但本质仍是 scalar/common fallback，不能再用“函数指针不等于 Scalar”当能力位依据
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_NEON_BackendCapabilities_Expose_FMA_When_FmaSlots_AreNative` 与 `Test_RISCVV_BackendCapabilities_Expose_Shuffle_When_RepresentativeSlots_AreNonScalar`
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_NEONFMA_WhenNativeSlotsPresent` 与 `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVShuffle_WhenNativeSlotsPresent`
  - 回收 fresh red：
    - `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-red3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-red3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
  - red 结果确认两处真实 overclaim：
    - `NEON should not advertise scFMA when only scalar/common fallback FMA slots are compiled`
    - `RISCVV should not advertise scShuffle when only scalar/common fallback shuffle slots are compiled`
  - 修改 `src/fafafa.core.simd.neon.register.inc`，把 `scFMA` 改成仅在 `FAFAFA_SIMD_NEON_ASM_ENABLED` 时加入 capability set
  - 修改 `src/fafafa.core.simd.riscvv.register.inc`，把 `scShuffle` 改成仅在 `RISCVV_ASSEMBLY` 时加入 capability set
  - 回收 fresh green：
    - `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-green3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-green3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
  - 最后 fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260320-nonx86-cap3 bash tests/fafafa.core.simd/BuildOrTest.sh gate`，确认新增对称能力测试与 capability 修复没有破坏默认主线
- Files created/modified:
  - `src/fafafa.core.simd.neon.register.inc` (modified again)
  - `src/fafafa.core.simd.riscvv.register.inc` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)

### Phase 9: non-x86 runtime-toggle rebuild hardening
- **Status:** complete
- Actions taken:
  - 顺着 `SetVectorAsmEnabled(True -> False)` 合同继续深审时，确认 `NEON/RISCVV` 与 x86 backend 不同：它们的 asm/fallback 主路径主要由编译期开关决定，而 `register.inc` 之前又完全不看 `IsVectorAsmEnabled`
  - 这意味着在 native asm build 上，即使用户运行时关闭 vector asm，rebuilder 也只会重新注册同一套 asm-backed table，留下 stale dispatch / stale capability 风险
  - 先对照 `AVX2/SSE41/SSSE3` 的 register 写法，收敛出最小修复策略：不去重构整套双实现，而是在“asm capable 且 runtime disabled”时把 backend 重建为 scalar-backed table；非 asm build 继续保留当前 fallback 注册，不影响 opt-in suite
  - 修改 `src/fafafa.core.simd.neon.register.inc`：
    - 引入 `LAsmCapable` / `LUseVectorAsm`
    - 非 asm build 继续走当前 fallback 注册
    - asm build 且 runtime disabled 时，直接注册 base scalar table，并清掉 `scFMA/scShuffle`
  - 修改 `src/fafafa.core.simd.riscvv.register.inc`，按同样模式处理 `scFMA/scShuffle`
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 native-only runtime-toggle tests，要求 `NEON/RISCVV` 在 vector asm 关闭后把代表性 `Fma/Select/Insert/Extract` 槽位退回 scalar，并清掉 `scFMA/scShuffle`
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增对应的 native-only public ABI tests，要求 `CapabilityBits` 在 vector asm 关闭后同步清零这些 gated bits
  - 首版修复把 `LUseVectorAsm` 默认成 `True`，导致 non-asm opt-in fallback suite 又重新高报 `scFMA/scShuffle`；fresh `SIMD_ENABLE_NEON_BACKEND=1 ...` 与 `SIMD_ENABLE_RISCVV_BACKEND=1 ...` 都打出 red
  - 复盘后确认根因是把“asm capable”和“当前 runtime 开启 asm”混成了一个布尔；将 `LUseVectorAsm` 改为默认 `False`，只在 asm capable 分支读取 `IsVectorAsmEnabled` 后，fresh 默认 suite、fresh NEON opt-in suite、fresh RISCVV opt-in suite 全部恢复通过
  - 最后 fresh 运行默认 `gate`，确认当前主线没有回归
  - 备注：当前宿主机仍是 x86_64，所以新加的 native-only `NEON/RISCVV` runtime-toggle tests 这轮只完成了编译接线验证，没有拿到 arm64 / riscv64 上的真实执行证据
- Files created/modified:
  - `src/fafafa.core.simd.neon.register.inc` (modified for runtime-toggle rebuild)
  - `src/fafafa.core.simd.riscvv.register.inc` (modified for runtime-toggle rebuild)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)

### Phase 16: Manual Windows closeout contract and helper runtime guard
- **Status:** complete
- Actions taken:
  - 继续审查 Windows native evidence 主路径时，确认 `run_windows_b07_closeout_finalize.sh` 本身不会补跑 cross gate，只会执行 `finalize -> freeze-status -> apply`
  - 结合 `evaluate_simd_freeze_status.py` 与 runbook 说明，确认手工 Windows 路径若只跑 `evidence-win-verify -> win-closeout-finalize`，会把 `freeze-status` 暴露给旧 `gate_summary.md`，因为 native batch evidence 明确不生成 fresh `gate_summary.md/json`
  - 修改 `tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh`，把手工路径显式改成：
    - Windows `evidence-win-verify`
    - Git Bash / WSL `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 ... gate`
    - 再执行 `win-closeout-finalize`
  - 同时修复 `print_windows_b07_closeout_3cmd.sh` 的真实 runtime bug：原先未引用 heredoc 中的反引号会触发 bash 命令替换，导致 helper 自身输出残缺并伴随 `command not found`
  - 修改 `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md`、`docs/fafafa.core.simd.closeout.md`、`docs/plans/2026-02-09-simd-windows-closeout-checklist.md`、`docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`、`docs/plans/2026-02-09-simd-windows-postrun-fill-template.md` 与 `docs/fafafa.core.simd.handoff.md`，统一写明手工 Windows closeout 在 finalize 前必须先跑 fail-close cross gate；legacy checklist 的“单命令闭环”也改回 `win-evidence-via-gh`
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增：
    - `check_windows_manual_closeout_guard`：静态检查 helper/runbook/closeout doc/legacy checklist 的手工路径合同
    - `check_windows_closeout_helper_runtime_guard`：直接运行 `win-closeout-3cmd` helper，确保 batch id 占位替换和 backticked 说明都保持可执行输出
  - 首次 helper 复验暴露 heredoc/backtick bug，随后修复后重新跑通
  - 首次 runtime guard 误把 helper 当成必须 `+x` 的可执行文件，随后改成用 `bash <script>` 调用，并重新复验
  - fresh 运行 `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-20260320-152`，确认输出完整且包含手工 cross gate 步骤
  - fresh 运行 `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-manual-closeout-guard-check-20260320-r4 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认新的 static/runtime guard 已接入主线且未误伤
- Files created/modified:
  - `tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh` (modified)
  - `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md` (modified)
  - `docs/fafafa.core.simd.closeout.md` (modified)
  - `docs/plans/2026-02-09-simd-windows-closeout-checklist.md` (modified)
  - `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md` (modified)
  - `docs/plans/2026-02-09-simd-windows-postrun-fill-template.md` (modified)
  - `docs/fafafa.core.simd.handoff.md` (modified)
  - `tests/fafafa.core.simd/BuildOrTest.sh` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 17: Windows evidence minimum push surface mapping
- **Status:** complete
- Actions taken:
  - 读取 `.github/workflows/simd-windows-b07-evidence.yml`，确认 remote workflow 自身无本地 diff，且 prepare job 会 stage 整个 `src/`、`docs/` 与 `tests/fafafa.core.simd*`/`tests/run_all_tests.*`
  - 继续顺着 `collect_windows_b07_evidence.bat` 和 `buildOrTest.bat` 下钻，确认 Windows job 的 artifact 生成并不依赖 Linux-side closeout helper/doc，而是 native batch 直驱：
    - `buildOrTest.bat build`
    - 主 runner `--list-suites` / `--suite=TTestCase_Vec*`
    - cpuinfo / cpuinfo.x86 子 runner
    - public ABI batch smoke
    - filtered run_all summary
  - 据此把当前本地 diff 分成两类：
    - remote fresh Windows artifact minimum runtime-critical candidate set：`collect_windows_b07_evidence.bat`、`verify_windows_b07_evidence.bat`、`tests/fafafa.core.simd.publicabi/BuildOrTest.bat`、`publicabi_smoke.c`、`publicabi_smoke.ps1`
    - local closeout/helper/doc/guard：`run_windows_b07_closeout_via_github_actions.sh`、`run_windows_b07_closeout_finalize.sh`、`finalize_windows_b07_closeout.sh`、`preflight_windows_b07_evidence_gh.sh`、`print_windows_b07_closeout_3cmd.sh`、`verify_windows_b07_evidence.sh`、`simulate_windows_b07_evidence.sh`、`rehearse_freeze_status.sh` 及各类 closeout 文档
  - 进一步复核后确认：`buildOrTest.bat` 当前大 diff 主要是本地 guard / opt-in smoke / QEMU & gate-summary helper / closeout wrapper；workflow 的 `1/7` 只借它做 `build`，并不依赖这些新增合同
  - 同样，collector 的 `7/7` 只写 `run_all_tests_summary.txt`，当前不调用 `tests/run_all_tests.bat`；因此它也不在 fresh artifact 的最小必需提交面里
  - 结论是：要从当前脏工作区切一个“只为 fresh Windows artifact” 的最小 branch，不必把当前大量 `src/fafafa.core.simd*` 实现改动一起带上远端；优先整理上面 5 个 batch/publicabi 文件即可
  - 同时又顺手清掉了剩余几份会误导执行顺序的二线文档：
    - `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`
    - `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
    - `docs/fafafa.core.simd.checklist.md`
    - `docs/plans/2026-03-09-simd-full-platform-completeness.md`
  - 再次 fresh 运行 `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-manual-closeout-guard-check-20260320-r6 bash tests/fafafa.core.simd/BuildOrTest.sh check`，确认扩大的文档 guard 仍通过
- Files created/modified:
  - `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md` (modified)
  - `tests/fafafa.core.simd/docs/simd_completeness_matrix.md` (modified)
  - `docs/fafafa.core.simd.checklist.md` (modified)
  - `docs/plans/2026-03-09-simd-full-platform-completeness.md` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 18: Windows native runtime-critical set refinement
- **Status:** complete
- Actions taken:
  - 继续沿 `.github/workflows/simd-windows-b07-evidence.yml -> collect_windows_b07_evidence.bat -> tests/fafafa.core.simd.publicabi/BuildOrTest.bat test` 下钻 direct dependency
  - 重新审查 `tests/fafafa.core.simd.publicabi/BuildOrTest.bat`，确认 Windows batch `test/validate-exports` 只依赖：
    - Pascal shared library 构建
    - `publicabi_smoke.ps1`
    - `pwsh -> powershell` runtime 解析
  - 对照 `tests/fafafa.core.simd.publicabi/BuildOrTest.sh`，确认 shell `test` 才会 `build_harness -> run_harness`，其中 `HARNESS_SRC` 明确是 `publicabi_smoke.c`
  - 用 `rg -n "publicabi_smoke\\.c|publicabi_smoke\\.ps1|publicabi_smoke\\.h"` 再次核对引用，确认 Windows workflow native batch evidence 路径并不会直接触达 `publicabi_smoke.c`
  - 据此把“fresh Windows artifact 最小 runtime-critical candidate set”从 5 文件再收敛为 4 文件：
    - `tests/fafafa.core.simd/collect_windows_b07_evidence.bat`
    - `tests/fafafa.core.simd/verify_windows_b07_evidence.bat`
    - `tests/fafafa.core.simd.publicabi/BuildOrTest.bat`
    - `tests/fafafa.core.simd.publicabi/publicabi_smoke.ps1`
  - 生成新的更精确补丁工件：`/tmp/simd-win-evidence-runtime-minimal.patch`
  - 记录补丁大小：`468` 行；旧的 `/tmp/simd-win-evidence-minimal.patch` 仍保留作为较宽候选面
- Files created/modified:
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 19: non-x86 `scIntegerOps` fallback overclaim closeout
- **Status:** complete
- Actions taken:
  - 继续深审 `NEON/RISCVV` 的 capability contract 时，确认前几轮虽然已收敛 `scFMA/scShuffle`，但 `scIntegerOps` 仍保留同类 overclaim：在 non-asm build、test-only fallback 注册态，以及 native asm build 的 runtime-disabled rebuild 路径下，backend 仍继续对外宣称整数向量能力
  - 对照 dispatch 实际状态复盘根因：这些路径下代表性整数槽位已经落回 scalar/common fallback，因此 `BackendInfo.Capabilities` 与 public ABI `CapabilityBits` 不应再保留 `scIntegerOps`
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `NEON/RISCVV scIntegerOps` 合同测试，显式覆盖 opt-in fallback 注册态
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增对应的 public ABI capability bits 测试，并把 native runtime-disabled 路径扩到检查 `SetVectorAsmEnabled(False)` 后 `scIntegerOps` 必须清零
  - 回收 fresh red 后，修改 `src/fafafa.core.simd.neon.register.inc` 与 `src/fafafa.core.simd.riscvv.register.inc`，把 `scIntegerOps` 宣称从“非 asm 或 vector asm 开启都算”收紧为仅在 `LUseVectorAsm=True` 时成立
  - 回收 fresh green：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-intops-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-intops-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
  - 继续用默认 release 快门禁复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-intops-check2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-intops-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK @ 2026-03-21 00:40:00`
- Files created/modified:
  - `src/fafafa.core.simd.neon.register.inc` (modified again)
  - `src/fafafa.core.simd.riscvv.register.inc` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 20: AVX512 runtime-gated capability/rebuild contract closeout
- **Status:** complete
- Actions taken:
  - 继续深审 x86 capability/dispatch/rebuild 合同时，确认 `src/fafafa.core.simd.avx512.register.inc` 之前完全不看 `IsVectorAsmEnabled`；因此 `SetVectorAsmEnabled(False)` 后，`AVX512` 仍保留 native `FmaF32x16/AddU32x16` 等宽槽位与 `scFMA/scIntegerOps/scMaskedOps/sc512BitOps`
  - 先按 TDD 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 AVX512 runtime-disabled 回归测试，要求 `True -> False` 后 dispatch slot 回退到 fallback，且 public ABI `CapabilityBits` 同步清零
  - 回收 fresh red：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-vectorasm-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - 失败点命中：
      - `AVX512 FmaF32x16 should fall back to scalar when vector asm is disabled`
      - `Public ABI CapabilityBits should clear AVX512 scFMA when vector asm is disabled`
  - 根因确认后，修改 `src/fafafa.core.simd.avx512.register.inc`：
    - 引入 `LEnableVectorAsm := IsVectorAsmEnabled`
    - 仅在 `LEnableVectorAsm=True` 时覆写 native AVX512 slots
    - `scFMA/scIntegerOps/scMaskedOps/sc512BitOps` 也改为只在 `LEnableVectorAsm=True` 时宣称
    - `vector asm=False` 时保留 clone/base fallback table，避免 stale AVX512 dispatch/public ABI
  - 修复后又暴露一层旧测试假设漂移：多条 AVX512 mapping/FMA expose testcase 一直默认 native path 总是打开，之前之所以是绿的，是依赖了上面这条 bug
  - 同步把 `DispatchAPI/PublicAbi` 里的 AVX512 正向 testcase 改成显式 `SetVectorAsmEnabled(True)` 后再验证 native slots/capability；`sc512BitOps` 对账也收紧为跟随实际 wide integer slots 是否非 scalar
  - 回收 fresh green：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-vectorasm-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
  - 继续补 fresh release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-vectorasm-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-vectorasm-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 02:15:21)`
- Files created/modified:
  - `src/fafafa.core.simd.avx512.register.inc` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 21: AVX512 `scShuffle` underclaim closeout
- **Status:** complete
- Actions taken:
  - 继续深审 AVX512 capability/public ABI contract 时，确认 `src/fafafa.core.simd.avx512.register.inc` 虽已在 `vector asm=True` 时把 `SelectF32x16` / `SelectF64x8` 绑定到原生实现，但 capability set 仍漏掉 `scShuffle`
  - 先按 TDD 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 AVX512 `scShuffle` expose red tests，并把 runtime-disabled 路径扩到检查 `SetVectorAsmEnabled(False)` 后该 bit 必须清零
  - 回收 fresh red：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-shuffle-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - 失败点命中：
      - `AVX512 should advertise scShuffle once wide select slots are non-scalar`
      - `Public ABI CapabilityBits should expose AVX512 scShuffle when wide select slots are non-scalar`
  - 根因确认后，修改 `src/fafafa.core.simd.avx512.register.inc`，把 `scShuffle` 纳入现有 `if LEnableVectorAsm then` gated capability block，使 capability metadata 与 wide select 槽位的真实非 scalar 映射保持一致
  - 同步扩展 AVX512 clear-path 断言，确保 `SetVectorAsmEnabled(True -> False)` 后 `scShuffle` 也会跟随 capability/public ABI 一起清零
  - 回收 fresh green：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-shuffle-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
  - 继续补 fresh release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-shuffle-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-shuffle-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 02:51:22)`
- Files created/modified:
  - `src/fafafa.core.simd.avx512.register.inc` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 22: scalar-backed active-backend reselection closeout
- **Status:** complete
- Actions taken:
  - 继续深审 `SetVectorAsmEnabled(True -> False)` 的 dispatch/public ABI 动态语义时，确认前几轮虽然已经收敛多条 capability drift，但 active backend identity 还有一条新的真实漂移：多个 backend 在 runtime-disabled rebuild 后已经退成 scalar-backed/fallback table，却仍继续保留 `BackendInfo.Available=True`
  - 先按 TDD 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增两条 red tests：
    - `TTestCase_DispatchAPI.Test_VectorAsmDisabled_ReSelects_Away_From_ScalarBacked_CurrentBackend`
    - `TTestCase_PublicAbi.Test_PublicApi_Refreshes_WhenVectorAsmDisabled_ReSelects_Away_From_ScalarBacked_CurrentBackend`
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-active-backend-red-rerun-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - 失败点命中：
      - `Scalar-backed backend should not remain dispatchable after vector asm disable`
      - `Vector-asm-disabled reselection should move away from scalar-backed original backend`
  - 根因确认后，统一收敛 backend `Available` 语义：
    - `src/fafafa.core.simd.sse2.pas`、`src/fafafa.core.simd.sse2.i386.register.inc`、`src/fafafa.core.simd.sse3.register.inc`、`src/fafafa.core.simd.ssse3.register.inc`、`src/fafafa.core.simd.sse41.register.inc`、`src/fafafa.core.simd.sse42.register.inc` 改为 `Available := IsVectorAsmEnabled`
    - `src/fafafa.core.simd.avx2.register.inc` 改为 `Available := LEnableVectorAsm`
    - `src/fafafa.core.simd.avx512.register.inc` 改为 `Available := isAvailable and LEnableVectorAsm`
    - `src/fafafa.core.simd.neon.register.inc` 与 `src/fafafa.core.simd.riscvv.register.inc` 改为 `Available := (not LAsmCapable) or LUseVectorAsm`，保证 non-asm build 继续可派发，而 native asm build runtime-disabled 时不再保留 stale active identity
  - 同步修正旧 smoke 合同漂移：
    - `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 的 backend smoke 不再用 `HasFeature + IsBackendRegistered` 断言 active backend，而是改为 `IsBackendDispatchable`
    - `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas` 的默认 backend 预期也改成 dispatchable 语义
  - 回收 fresh green：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-active-backend-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
  - 继续补 fresh release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-active-backend-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-active-backend-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 03:14:15)`
- Files created/modified:
  - `src/fafafa.core.simd.sse2.pas` (modified again)
  - `src/fafafa.core.simd.sse2.i386.register.inc` (modified again)
  - `src/fafafa.core.simd.sse3.register.inc` (modified again)
  - `src/fafafa.core.simd.ssse3.register.inc` (modified again)
  - `src/fafafa.core.simd.sse41.register.inc` (modified again)
  - `src/fafafa.core.simd.sse42.register.inc` (modified again)
  - `src/fafafa.core.simd.avx2.register.inc` (modified again)
  - `src/fafafa.core.simd.avx512.register.inc` (modified again)
  - `src/fafafa.core.simd.neon.register.inc` (modified again)
  - `src/fafafa.core.simd.riscvv.register.inc` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 23: public-smoke default-backend priority closeout
- **Status:** complete
- Actions taken:
  - 继续深审 consumer/public smoke 合同后，确认 `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas` 仍手写一份 partial x86 priority predictor，只覆盖 `SSE2/AVX2`
  - 先为这条 drift 抽出共享 helper `tests/fafafa.core.simd/fafafa.core.simd.public_smoke_support.pas`，暂时保持旧逻辑不变，让测试能直接调用同一 predictor
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_PublicSmokeDefaultBackendPredictor_Tracks_CanonicalDispatchPriority`，显式制造 `AVX2` 被重注册成 `BackendInfo.Available=False`、而 `SSE4.2` 仍 dispatchable 的场景
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-public-smoke-priority-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
    - 失败点命中：`Public smoke default backend predictor should follow canonical dispatch priority after AVX2 becomes non-dispatchable`，`expected: <5> but was: <1>`
  - 根因确认后，把 `tests/fafafa.core.simd/fafafa.core.simd.public_smoke_support.pas` 改为直接复用 canonical `GetBestDispatchableBackend`
  - 同步让 `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas` 使用共享 helper，而不是继续复制 backend 选择逻辑
  - fresh green 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-public-smoke-priority-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - 额外做 standalone 编译/运行验证，因为 `public_smoke` 没有现成 runner：
    - `fpc -B -Mobjfpc -Scghi -O3 -Fi./src -Fu./src -Fu./tests/fafafa.core.simd -FE/tmp/simd-public-smoke-standalone-20260321/bin -FU/tmp/simd-public-smoke-standalone-20260321/lib tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas`
    - `/tmp/simd-public-smoke-standalone-20260321/bin/fafafa.core.simd.public_smoke`
    - 结果：`[PASS] Default backend is AVX2`
  - 继续补 fresh release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-public-smoke-priority-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-public-smoke-priority-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 03:56:10)`
- Files created/modified:
  - `tests/fafafa.core.simd/fafafa.core.simd.public_smoke_support.pas` (created)
  - `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 24: pre-init vector-asm toggle stale-dispatch closeout
- **Status:** complete
- Actions taken:
  - 继续深审 runtime toggle/rebuild 合同后，确认现有 `DispatchAPI/PublicAbi` 测到的都是“dispatch 已初始化后再 toggle”的路径，还没覆盖 dispatch-only consumer 的 pre-init 场景
  - 用只引用 `dispatch + scalar + x86 backend units` 的 standalone probe 复现真实外部问题：
    - 先 `SetVectorAsmEnabled(False)`
    - 再第一次调用 `GetBestDispatchableBackend/GetActiveBackend`
    - 修复前得到 `VectorAsm=False / Best=6 / Active=6 / AVX2.Available=True`
  - 根因确认在 `src/fafafa.core.simd.dispatch.pas`：
    - backend table 会在各 backend unit `initialization` 时发布
    - `SetVectorAsmEnabled` 之前在 `g_DispatchState = 0` 时直接返回，错误地把“dispatch 尚未初始化”当成“没有东西需要重建”
  - 先补 red 护栏，而不是先改实现：
    - 新增 `tests/fafafa.core.simd/fafafa.core.simd.dispatch_preinit_smoke.pas`
    - 把这条 standalone smoke 接到 `tests/fafafa.core.simd/BuildOrTest.sh check`、shell `gate` 的 build-check，以及 `tests/fafafa.core.simd/buildOrTest.bat check`
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatch-preinit-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - FAIL 命中：`Best dispatchable backend should be Scalar after pre-init SetVectorAsmEnabled(False), got AVX2`
  - 做最小修复：
    - 将 `src/fafafa.core.simd.dispatch.pas` 的 `RebuildBackendsAfterFeatureToggle` 改为接受 `aReinitializeDispatch`
    - `SetVectorAsmEnabled` 现在统一执行 rebuild；如果 dispatch 之前已经初始化，则立即重新选主；如果还没初始化，则只刷新 backend table，不提前初始化 dispatch
  - fresh green 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatch-preinit-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - fresh external probe 重编译后输出：
      - `VectorAsm=False`
      - `Best=0`
      - `Active=0`
      - `AVX2.Available=False`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatch-preinit-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 04:21:08)`
- Files created/modified:
  - `src/fafafa.core.simd.dispatch.pas` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatch_preinit_smoke.pas` (created)
  - `tests/fafafa.core.simd/BuildOrTest.sh` (modified again)
  - `tests/fafafa.core.simd/buildOrTest.bat` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 25: public ABI backend text getter drift closeout
- **Status:** complete
- Actions taken:
  - 继续深审 public ABI 动态刷新合同后，确认 `GetSimdBackendNamePtr` / `GetSimdBackendDescriptionPtr` 走的是一次性 cache，而 `RegisterBackend(...)` 已经允许在进程内动态重注册 backend metadata
  - 先在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 补最小 red：
    - 新增 `Test_PublicAbi_BackendText_Getters_Refresh_After_RegisterBackend`
    - 先调用 text getter prime cache，再重注册当前 backend 并断言 public ABI text getter 必须跟随新的 `BackendInfo.Name/Description`
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-textcache-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
    - 失败点命中：`Public ABI backend name getter should refresh after RegisterBackend`，`expected: <MutatedBackendName> but was: <Scalar>`
  - 根因确认：
    - `GetBackendInfo(LBackend)` 已经正确返回新名字/描述
    - 真正陈旧的是 `src/fafafa.core.simd.public_abi.impl.inc` 的 `EnsureBackendTextCache`，它在 cache 非空后直接 `Exit`
  - 做最小修复：
    - 删除一次性 cache 早退逻辑，让 getter 每次都从最新 backend metadata 刷新 name/description cache
  - fresh green 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-textcache-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-textcache-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-textcache-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 04:32:13)`
- Files created/modified:
  - `src/fafafa.core.simd.public_abi.impl.inc` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 26: x86 inherited `scShuffle` capability underclaim closeout
- **Status:** complete
- Actions taken:
  - 继续深审 x86 capability contract 时，顺着此前 `AVX2/AVX512 scShuffle` underclaim 的模式继续往低阶 backend 查，确认 `SSE2` 虽然早已把 `SelectF32x4/InsertF32x4/ExtractF32x4/SelectF32x8/SelectF64x4` 接到非 scalar 实现，`SSE3` 也通过 clone 链继承了这些槽位，但 capability/public ABI 仍没有宣称 `scShuffle`
  - 先按 TDD 补最小 red，而不是先改实现：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_BackendCapabilities_DoNotUnderclaim_Shuffle`
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicApi_BackendPodInfo_CapabilityBits_DoNotUnderclaim_Shuffle`
    - 两条测试都显式 `SetVectorAsmEnabled(True)`，避免默认 runtime state 造成假绿
  - 首次 fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-shuffle-underclaim-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - 失败点命中：
      - `scShuffle missing while representative shuffle slots are non-scalar: SSE2`
      - `Public ABI CapabilityBits missing scShuffle while representative shuffle slots are non-scalar for backend=1`
  - 根因确认后，做最小实现修复：
    - `src/fafafa.core.simd.sse2.pas` 的 capability set 补 `scShuffle`
    - `src/fafafa.core.simd.sse2.i386.register.inc` 做对称补齐
    - `src/fafafa.core.simd.sse3.register.inc` 也补 `scShuffle`，与其 clone 继承到的真实 shuffle 槽位保持一致
    - `src/fafafa.core.simd.ssse3.register.inc` 已经宣称 `scShuffle`，保持不变
  - fresh green 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-shuffle-underclaim-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
  - 继续补 fresh release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-shuffle-underclaim-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-shuffle-underclaim-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 05:10:26)`
- Files created/modified:
  - `src/fafafa.core.simd.sse2.pas` (modified again)
  - `src/fafafa.core.simd.sse2.i386.register.inc` (modified again)
  - `src/fafafa.core.simd.sse3.register.inc` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 27: AVX2 masked-`FMA` dispatch-slot drift closeout
- **Status:** complete
- Actions taken:
  - 继续深审 x86 capability/dispatch contract 时，确认 `AVX2` 还有一条不同于此前 `scFMA` underclaim 的真实漂移：当 CPU 仍有 `AVX2` 但 `gfFMA` 被 mask 掉时，capability/public ABI 已清掉 `scFMA`，但 `FmaF*` 槽位仍被 `AVX2Fma*` wrapper 覆写
  - 先按 TDD 补最小 red，而不是先改实现：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增独立 qemu 回归 suite `TTestCase_X86MaskedFmaContract`
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 把该 suite 接入主 runner manifest，保证 `--list-suites` / `--suite=` 可达
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx2-no-fma-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh build`
    - `qemu-x86_64 -cpu Haswell,-fma /tmp/simd-avx2-no-fma-red-20260321/bin2/fafafa.core.simd.test --suite=TTestCase_X86MaskedFmaContract`
    - 失败点命中：`AVX2 FmaF32x4 slot should stay scalar when hardware FMA is unavailable`
  - 根因确认后，做最小实现修复：
    - `src/fafafa.core.simd.avx2.register.inc` 新增 `LHasHardwareFma`
    - 将 `FmaF32x4/FmaF64x2/FmaF32x8/FmaF64x4/FmaF32x16/FmaF64x8` 的 slot 覆写统一收紧到 `LHasHardwareFma=True`
    - 保持 `FillBaseDispatchTable(...)` 提供的 scalar FMA slots 不被无条件覆写
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx2-no-fma-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh build`
    - `qemu-x86_64 -cpu Haswell,-fma /tmp/simd-avx2-no-fma-green-20260321/bin2/fafafa.core.simd.test --suite=TTestCase_X86MaskedFmaContract`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx2-no-fma-native-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86MaskedFmaContract,TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx2-no-fma-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx2-no-fma-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 14:23:41)`
- Files created/modified:
  - `src/fafafa.core.simd.avx2.register.inc` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 28: AVX512 required-features `FMA` predicate closeout
- **Status:** complete
- Actions taken:
  - 继续沿 x86 capability/dispatch contract 下钻时，先重新核对 `SSE2` rounding 候选，确认 `F32x8/F64x4/F32x16/F64x8` 已有真 `SSE2` rounding 实现，只有少数窄槽仍挂 fallback；因此没有把这条“不够硬的 broad drift”当成本轮主修问题
  - 转向更强的共享谓词缺口：确认 `src/fafafa.core.simd.cpuinfo.base.pas` 的 `X86HasAVX512BackendRequiredFeatures(...)` 漏掉了 `HasFMA`，而 `src/fafafa.core.simd.avx512.f32x16_fma_round.inc` / `src/fafafa.core.simd.avx512.f64x8_fma_round.inc` 的 `AVX512Fma*` 直接执行 `vfmadd213ps/pd`
  - 由于当前 `qemu-x86_64` TCG 不支持可执行 `AVX512` 特性，改走纯逻辑 TDD 路线，而不是停在不可执行的 qemu red 上
  - 先按 TDD 只改测试：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 的 `TTestCase_X86BackendPredicates` 新增 `Test_X86HasAVX512BackendRequiredFeatures_RequiresFMA`
    - 同步把既有 `Test_X86HasAVX512BackendRequiredFeatures_AVX512FOnly_Disabled` / `Test_X86SupportsAVX512BackendOnCPU_RequiresUsable512AndBackendFeatureSet` 扩到 `FMA` 合同
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-predicate-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86BackendPredicates`
    - 失败点命中：
      - `AVX-512 backend should require FMA because AVX512FmaF32x16/F64x8 use vfmadd* directly`
      - `AVX-512 backend should require FMA even when 512-bit usable state is present`
  - 根因确认后，做最小实现修复：
    - 将 `src/fafafa.core.simd.cpuinfo.base.pas` 的 `X86HasAVX512BackendRequiredFeatures(...)` 收紧为 `AVX2 + AVX512F + AVX512BW + POPCNT + FMA`
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-predicate-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86BackendPredicates`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-predicate-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-predicate-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 15:16:11)`
- Files created/modified:
  - `src/fafafa.core.simd.cpuinfo.base.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 29: AVX512 raw-usable vs backend-ready execution-gate drift closeout
- **Status:** complete
- Actions taken:
  - 继续沿 x86 capability/dispatch contract 下钻时，确认 `HasAVX512/simd_has_avx512f` 和 AVX512 backend-ready 语义已经分叉：
    - 前者仍是 raw usable AVX512F（只看 `AVX512F + OS/XCR0`）
    - 后者已经要求 `AVX2 + AVX512F + AVX512BW + POPCNT + FMA + usable 512-bit state`
  - 先按 TDD 只改测试，不先碰现有 guard：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 新增纯逻辑 helper `X86AllowsDirectAVX512Execution(...)`
    - 在 `TTestCase_X86BackendPredicates` 新增 `Test_X86DirectAVX512ExecutionGate_RequiresBackendSupportedPredicate`
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86BackendPredicates`
    - 失败点命中：`Direct AVX-512 execution gates must require backend-supported feature set, not just raw usable AVX512F`
  - 根因确认后，做最小实现修复：
    - 将 `X86AllowsDirectAVX512Execution(...)` 收口到 `X86SupportsAVX512BackendOnCPU(...)`
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 新增 `AVX512DirectOpsAvailableOnCurrentCPU` 与 `AVX512BackendDispatchableForVectorAsmTests`
    - `BackendConsistency` 中 `MemEqual/MemFindByte/SumBytes/CountByte/MinMaxBytes/BitsetPopCount` 的 AVX512 direct helper guard 改为 current-CPU backend-ready 语义
    - `AVX512VectorAsm` suite 里的 runtime gate 全部改为 `AVX512BackendDispatchableForVectorAsmTests`
    - `tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.testcase.pas` 的 AVX512 backend presence 断言改为 `X86SupportsAVX512BackendOnCPU(...)`，不再绑定 `simd_has_avx512f`
    - `tests/fafafa.core.simd/bench_avx512_vs_avx2.lpr` 的 report 文案改为同时输出 `AVX-512 Backend Support` 与 `Usable AVX-512F`
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86BackendPredicates`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-cpuinfo-20260321 bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_Global,TTestCase_PlatformSpecific`
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-optin-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendConsistency,TTestCase_AVX512VectorAsm`
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 15:45:37)`
- Files created/modified:
  - `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` (modified again)
  - `tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/bench_avx512_vs_avx2.lpr` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

### Phase 30: backend benchmark activation contract closeout
- **Status:** complete
- Actions taken:
  - 继续沿 `supported_on_cpu / dispatchable / active` 三层语义往下查时，确认 `bench_avx512_vs_avx2.lpr`、`bench_neon_vs_scalar.lpr`、`bench_riscvv_vs_scalar.lpr` 仍停在旧合同：
    - 先看 `IsBackendAvailableOnCPU(...)`
    - 然后直接 `SetActiveBackend(...)`
    - 但 `SetActiveBackend(...)` 在目标 backend 不可 dispatch 时会安全 fallback，因此 benchmark 标签可能和真实 active backend 漂移
  - 先按 TDD 补最小 red，而不是先改 bench 实现：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_BenchmarkActivation_Rejects_CpuSupportedButNonDispatchable_Backend`
    - 在 testcase 里显式制造 `supported_on_cpu=True` 但 `BackendInfo.Available=False` 的 synthetic split，并把新 helper 命名锁成 `TryActivateBenchmarkBackend(...)`
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
    - 失败点命中：`Identifier not found "TryActivateBenchmarkBackend"`
  - 根因确认后，做最小实现修复：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.bench.pas` 新增共享 helper `TryActivateBenchmarkBackend(...)`
    - helper 统一检查 `IsBackendAvailableOnCPU`、`IsBackendDispatchable`、`TrySetActiveBackend` 与最终 `GetActiveBackend=aBackend`
    - 将 `tests/fafafa.core.simd/bench_avx512_vs_avx2.lpr`、`tests/fafafa.core.simd/bench_neon_vs_scalar.lpr`、`tests/fafafa.core.simd/bench_riscvv_vs_scalar.lpr` 的 backend 选择统一切到 helper，并用 `try/finally ResetToAutomaticBackend`
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-runner-20260321 bash tests/fafafa.core.simd/run_backend_benchmarks.sh`
    - `fpc -Mobjfpc -Sh -O3 -Fi./src -Fu./src -Fu./tests/fafafa.core.simd -FE/tmp/simd-bench-neon-compile-20260321/bin -FU/tmp/simd-bench-neon-compile-20260321/lib tests/fafafa.core.simd/bench_neon_vs_scalar.lpr`
    - `fpc -Mobjfpc -Sh -O3 -Fi./src -Fu./src -Fu./tests/fafafa.core.simd -FE/tmp/simd-bench-riscvv-compile-20260321/bin -FU/tmp/simd-bench-riscvv-compile-20260321/lib tests/fafafa.core.simd/bench_riscvv_vs_scalar.lpr`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - backend bench runner 在当前 x86_64 主机上得到 `AVX2_vs_Scalar PASS`
    - `AVX512_vs_AVX2` 不再只靠标签推断，而是明确输出 `[SKIP] AVX-512 backend is not available on this CPU`
    - 最终 gate 结果：`[GATE] OK`，`run_all summary (2026-03-21 16:41:15)`
- Files created/modified:
  - `tests/fafafa.core.simd/fafafa.core.simd.bench.pas` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/bench_avx512_vs_avx2.lpr` (modified again)
  - `tests/fafafa.core.simd/bench_neon_vs_scalar.lpr` (modified)
  - `tests/fafafa.core.simd/bench_riscvv_vs_scalar.lpr` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

## 5-Question Reboot Check
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `DispatchAPI`、backend bench runner、`check`、`gate` 都仍是通过态；本轮最新又收敛了一条新的 benchmark activation 合同缺口：旧 bench 程序把 `supported_on_cpu` 误当成“真的激活了目标 backend”。当前 x86_64 主机已 fresh 证明 `TryActivateBenchmarkBackend(...)` 合同、AVX2 backend bench 实跑、NEON/RISCVV bench 编译和主门禁都没有回归，但 native arm64/riscv64 runtime-toggle 与 native AVX512 执行证据仍待补齐 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “fallback 已接线但 dispatchable/active/public ABI 仍误报或漏报” 的真实问题，重点看 x86/non-x86 的 rebuild/toggle 路径，以及其他 helper/runner 是否还把 `supported_on_cpu` 错当成 `dispatchable`；同时继续保留 fresh Windows native evidence、arm64/riscv64 native runtime-toggle 证据，以及具备 `avx512f/avx512bw` 条件主机上的 AVX512 native execution 证据作为后续收口项 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 除了脚本/closeout 层，helper/benchmark 程序本身也会把四层语义偷混。`supported_on_cpu` 只说明 CPU/OS 能力，不等于 backend 在当前 binary/runtime state 下真的 dispatchable，更不等于 benchmark 实际已经测到了这个 backend。`SetActiveBackend(...)` 的安全 fallback 对正常产品语义是对的，但对 benchmark/evidence 场景反而要求更严格的显式校验；否则 label、report 和真实 active backend 很容易漂移。之前确认的另一条方法论风险仍成立：只测“当前 `vector asm=False`”会漏掉 runtime `True -> False` rebuild bug，后续 feature-toggle 合同都要显式覆盖重建路径 |
| What have I done? | 已完成多轮 runner/guard 修复，补强 external public ABI smoke、alias/public ABI 动态回归护栏，修复 perf/freeze isolation 假阳性，拿到 fresh Linux full closeout PASS，并修复 SSE4.2 dispatch 继承缺陷、`scIntegerOps` / AVX2 `scFMA` / AVX2 `scShuffle` / AVX512 `scShuffle` capability 漂移、`SSE3/SSSE3/SSE41` runtime rebuild 漏注册及 `SSE41/SSE42` shuffle capability 假绿；同时把 AVX-512 opt-in build 通道接进主 shell/batch runner，并补齐对应 fresh check/suite/gate 证据与 public ABI hot-path 的 codegen 证据。本轮最新又确认并修复了 backend benchmark activation 漂移：`fafafa.core.simd.bench.pas` 现在提供 `TryActivateBenchmarkBackend(...)`，`AVX512/NEON/RISCVV` bench 程序已改为显式验证 active backend，不再只靠 CPU support 标签推断。 |

<!-- SIMD-WIN-CLOSEOUT-2026-03-21 -->
### 批次
- SIMD-20260320-152

### 执行动作
- 在 Windows 实机完成 buildOrTest.bat evidence-win-verify。
- 生成并归档收口摘要：finalize-win-evidence。
- 回填 roadmap / matrix / progress，关闭跨平台证据缺口。

### 命令与结果
| Command | Result |
|---|---|
| tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify | PASS |
| bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence | PASS |
| bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status | PASS |
| bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --freeze-json tests/fafafa.core.simd/logs/freeze_status.json | PASS |

### 关键证据
- Log: tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260320-152/windows_b07_gate.log
- Summary: tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260320-152/windows_b07_closeout_summary.md

### 阶段状态
- 跨平台冻结条件满足。

### Phase 31: dynamic register-backend identity drift closeout
- **Status:** complete
- Actions taken:
  - 继续沿 dispatch/public ABI 动态重注册语义往下查时，确认 `RegisterBackend(backend, dispatchTable)` 之前没有把“注册槽位 id”当成唯一真相源：
    - caller 可以把 `dispatchTable.Backend / dispatchTable.BackendInfo.Backend` 写成别的 backend
    - `TrySetActiveBackend(...)` 虽然按 slot id 强制选中对应 table，但 `GetActiveBackend` / `GetSimdPublicApi.ActiveBackendId` 实际读的却是 table 里自带的 stale backend id
  - 先按 TDD 补最小 red，而不是先改 dispatch 核心：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_RegisterBackend_Canonicalizes_TableIdentity_For_ForcedSelection`
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicApi_ActiveBackendId_Tracks_RegisterSlot_After_ReRegister`
    - 两条测试都显式把当前非 scalar active backend 的 table identity 改坏成 `sbScalar`，再断言 forced selection/public ABI active id 仍必须保持注册槽位 id
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-identity-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - 失败点分别命中：
      - `Forced selection should expose the requested backend id, not the stale table Backend field`，`expected: <6> but was: <0>`
      - `Public API active backend id should track the registered backend slot, not the stale table Backend field`，`expected: <6> but was: <0>`
  - 根因确认后，做最小实现修复：
    - `src/fafafa.core.simd.dispatch.pas` 的 `RegisterBackend` 改为构造 `LCanonicalTable`
    - 用注册槽位 id 统一回写 `LCanonicalTable.Backend` 与 `LCanonicalTable.BackendInfo.Backend`
    - 同步把 `LCanonicalTable.BackendInfo.Priority` 也收口到 `GetSimdBackendPriorityValue(backend)`
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-identity-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-identity-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-identity-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - targeted suite 从 2 failures 转为 PASS
    - fresh `gate` 最终 `[GATE] OK`
    - run-all summary 时间：`2026-03-21 17:05:43`
- Files created/modified:
  - `src/fafafa.core.simd.dispatch.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

## 5-Question Reboot Check (Phase 31 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都仍是通过态；本轮最新又收敛了一条新的 dynamic re-register identity 漂移：旧 `RegisterBackend` 会让 table identity 脱离注册槽位，进而把 `TrySetActiveBackend` / public ABI `ActiveBackendId` 带偏。当前 x86_64 主机已 fresh 证明该合同现在被 `RegisterBackend` canonicalization 守住，但 native arm64/riscv64 runtime-toggle 与 native AVX512 执行证据仍待补齐 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “dynamic re-register / rebuild / toggle 后，dispatchable/active/public ABI 仍误报或漏报” 的真实问题，重点看 x86/non-x86 的 runtime rebuild 路径，以及还有没有别的 raw `TSimdDispatchTable` metadata 被外部可观察 API 直接信任；同时继续保留 fresh Windows native evidence、arm64/riscv64 native runtime-toggle 证据，以及具备 `avx512f/avx512bw` 条件主机上的 AVX512 native execution 证据作为后续收口项 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 不只是 `supported_on_cpu / dispatchable / active` 会被混用，backend identity 自身也会漂。只要允许动态 `RegisterBackend(...)`，注册槽位 id 就必须压过 caller-supplied raw table metadata；否则 `GetActiveBackend` / `GetSimdPublicApi.ActiveBackendId` 这种外部可观察视图会被 stale `dispatchTable.Backend` 带偏。之前确认的两条方法论风险仍成立：1) benchmark/evidence/helper 不能把 CPU support 当成 active backend；2) 只测“当前 `vector asm=False`”会漏掉 runtime `True -> False` rebuild bug |
| What have I done? | 已完成多轮 runner/guard 修复，补强 external public ABI smoke、alias/public ABI 动态回归护栏，修复 perf/freeze isolation 假阳性，拿到 fresh Linux full closeout PASS，并修复 SSE4.2 dispatch 继承缺陷、`scIntegerOps` / AVX2 `scFMA` / AVX2 `scShuffle` / AVX512 `scShuffle` capability 漂移、`SSE3/SSSE3/SSE41` runtime rebuild 漏注册及 `SSE41/SSE42` shuffle capability 假绿；同时把 AVX-512 opt-in build 通道接进主 shell/batch runner，并补齐对应 fresh check/suite/gate 证据与 public ABI hot-path 的 codegen 证据。本轮最新又确认并修复了 dynamic register-backend identity 漂移：`RegisterBackend` 现在会 canonicalize `Backend` / `BackendInfo.Backend` / priority，`TrySetActiveBackend` 与 public ABI `ActiveBackendId` 不再能被 stale table identity 带偏。 |

### Phase 32: hook-driven forced-selection postcondition closeout
- **Status:** complete
- Actions taken:
  - 继续往 dispatch-changed hook / forced-selection 交界面深挖后，确认 `TrySetActiveBackend(requested)` 还有一条新的真实假成功：
    - 旧实现只在进入函数时检查 requested backend 是否 registered / dispatchable / supported_on_cpu
    - 但 `InitializeDispatch` 结束前会同步跑 `NotifyDispatchChangedHooks`
    - hook 若在通知阶段通过 `RegisterBackend(...)` 把 requested backend 改成 `BackendInfo.Available=False`，最终 active backend 会被 forced-path 回退到 `Scalar`
    - `TrySetActiveBackend(...)` 却仍无条件返回 `True`
  - 先按 TDD 补最小 red，而不是先改 dispatch 实现：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_TrySetActiveBackend_Fails_When_HookReRegister_ReSelects_Away`
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicApi_ActiveBackendId_Tracks_FinalState_When_HookReRegister_Overrides_ForcedSelection`
    - 两条测试都显式 `SetVectorAsmEnabled(True)` 后取当前非 scalar backend，再挂一个“一次 arm、二次把 requested backend 重注册成 non-dispatchable” 的 hook
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-hook-reregister-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - 失败点分别命中：
      - `TrySetActiveBackend should fail when a dispatch-changed hook re-registers the requested backend as non-dispatchable before the call completes`
      - `TrySetActiveBackend should fail when hook-driven re-register makes the requested backend non-dispatchable before the call completes`
  - 根因确认后，做最小实现修复：
    - `src/fafafa.core.simd.dispatch.pas` 的 `TrySetActiveBackend` 改为在 `InitializeDispatch` 之后读取最终 `g_CurrentDispatch`
    - 只有 `g_CurrentDispatch^.Backend = requestedBackend` 时才返回 success
    - 这样 hook-driven 二次重建若把最终 active backend 改成 `Scalar`，返回值就不会再假绿
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-hook-reregister-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-hook-reregister-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-hook-reregister-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - targeted suite 从 2 failures 转为 PASS
    - fresh `gate` 最终 `[GATE] OK`
    - run-all summary 时间：`2026-03-21 17:34:56`
- Files created/modified:
  - `src/fafafa.core.simd.dispatch.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

## 5-Question Reboot Check (Phase 32 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都仍是通过态；本轮最新又收敛了一条新的 hook-driven forced-selection 假成功：旧 `TrySetActiveBackend` 会在最终 active backend 已被 hook 二次改写后仍返回 success。当前 x86_64 主机已 fresh 证明后验校验已经把这条假绿关掉，但 native arm64/riscv64 runtime-toggle 与 native AVX512 执行证据仍待补齐 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “dynamic re-register / rebuild / toggle / hook 交互后，dispatchable/active/public ABI 仍误报或漏报” 的真实问题，重点看 x86/non-x86 runtime rebuild 路径，以及还有没有别的返回值或 helper 只做前置 gate、没有校验最终状态；同时继续保留 fresh Windows native evidence、arm64/riscv64 native runtime-toggle 证据，以及具备 `avx512f/avx512bw` 条件主机上的 AVX512 native execution 证据作为后续收口项 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 不只是 capability bits、backend identity、benchmark label 会漂，dispatch API 自己的 success/failure 返回值也会漂。只要 `dispatch-changed hook` 允许在通知阶段触发动态重注册/重建，就不能只靠调用前的 dispatchable 谓词来判断 `TrySetActiveBackend` 是否成功，必须以后验最终 active backend 为准。另一个仍成立的方法论是：测试里如果需要触发非 scalar runtime 路径，不能假设 runner 默认就是 `vector asm=True`，要显式设定。 |
| What have I done? | 已完成多轮 runner/guard 修复，补强 external public ABI smoke、alias/public ABI 动态回归护栏，修复 perf/freeze isolation 假阳性，拿到 fresh Linux full closeout PASS，并修复 SSE4.2 dispatch 继承缺陷、`scIntegerOps` / AVX2 `scFMA` / AVX2 `scShuffle` / AVX512 `scShuffle` capability 漂移、`SSE3/SSSE3/SSE41` runtime rebuild 漏注册及 `SSE41/SSE42` shuffle capability 假绿；同时把 AVX-512 opt-in build 通道接进主 shell/batch runner，并补齐对应 fresh check/suite/gate 证据与 public ABI hot-path 的 codegen 证据。本轮最新又确认并修复了 hook-driven forced-selection 假成功：`TrySetActiveBackend` 现在会以后验最终 active backend 判定 success，`TrySetActiveBackend=True` 与最终 `GetActiveBackend/GetSimdPublicApi.ActiveBackendId` 不会再分叉。 |

### Phase 33: public ABI concurrent publication hardening
- **Status:** complete
- Actions taken:
  - 继续深审 `GetSimdPublicApi` / `RebindSimdPublicApi` 的并发合同后，确认 public ABI 还有一条新的真实 publication tearing：
    - 旧 `src/fafafa.core.simd.public_abi.impl.inc` 直接对外暴露 `g_SimdPublicApi`
    - `RebindSimdPublicApi` 每次重绑都会先 `FillChar(g_SimdPublicApi, ...)`，再逐字段重写 metadata 和 shim pointers，同时还会原地改写 `g_SimdPublic*Bound`
    - 结果是只要控制面线程并发 `SetVectorAsmEnabled(...)` 触发重绑，reader 线程就能观察到 `StructSize=0`、`ActiveFlags=0` 这类 torn snapshot
  - 先按 TDD 补最小 red，而不是先改实现：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `Test_Concurrent_PublicApiToggle_ReadConsistency`
    - writer 复用 `TVectorAsmMultiToggleWorker` 持续制造 vector-asm rebind
    - reader 持续断言 `GetSimdPublicApi` 的 `StructSize / AbiVersion / ActiveFlags / shim pointers` 自洽，并直接调用 `MemEqual`
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-concurrent-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrent`
    - 失败点直接命中：
      - `public api StructSize torn at iter 654: expected=152 got=0`
      - `public api ActiveFlags missing registered/dispatchable/active bits at iter 0: 0`
      - 同轮还有多次 `StructSize=0` / `ActiveFlags=0`
  - 根因确认后，做最小实现修复：
    - `src/fafafa.core.simd.public_abi.impl.inc` 新增 `TSimdPublicApiBindingState`
    - `RebindSimdPublicApi` 改为先构造完整 snapshot，再用 `atomic_store_ptr(..., mo_release)` 发布当前 state
    - `PublicAbiMemEqual..MinMaxBytes` shims 不再读原地改写的全局 bound pointer，而是每次从当前 published state 取 bound fast-path
    - `GetSimdPublicApi` 改为返回当前 published snapshot；旧 cached snapshot 不再被后续重绑原地覆写
    - `src/fafafa.core.simd.pas` 新增 public ABI binding init/finalize 接线
    - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 把旧 “same pointer across rebind” 合同收紧为 “cached snapshot remains callable, fresh getter returns refreshed metadata”
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-concurrent-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrent,TTestCase_PublicAbi`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-concurrent-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-concurrent-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh concurrent/publicabi targeted suite PASS
    - fresh `check` PASS
    - fresh `gate` 最终 `[GATE] OK`
    - run-all summary 时间：`2026-03-21 18:16:41`
- Files created/modified:
  - `src/fafafa.core.simd.public_abi.impl.inc` (modified)
  - `src/fafafa.core.simd.pas` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified)
  - `docs/fafafa.core.simd.publicabi.md` (modified)
  - `docs/fafafa.core.simd.publicabi.stability.md` (modified)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

## 5-Question Reboot Check (Phase 33 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_SimdConcurrent,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条新的 public ABI publication tearing：旧 `RebindSimdPublicApi` 会把对外 table 原地清零重写，导致并发 reader 读到 `StructSize=0 / ActiveFlags=0`。当前 x86_64 主机已 fresh 证明 snapshot + atomic publication 已把这条并发假绿关掉，但 native arm64/riscv64 runtime-toggle 与 native AVX512 执行证据仍待补齐 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “cached public view / direct dispatch / control-plane helper 在并发或重建后仍误报/漏报” 的真实问题，重点看 x86/non-x86 runtime rebuild 路径、public ABI metadata 与 direct fast-path 之间是否还有 stale 对称性缺口，以及还有没有别的对外 helper 仍在信任可被动态重写的 raw shared state；同时继续保留 fresh Windows native evidence、arm64/riscv64 native runtime-toggle 证据，以及具备 `avx512f/avx512bw` 条件主机上的 AVX512 native execution 证据作为后续收口项 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | public ABI 的问题不只在 flags/capability 语义，连“怎么发布这张可缓存 table”本身也会变成合同缺口。只要 table 对外可被并发 reader 缓存，`FillChar + 原地重写` 就和 direct dispatch 的原子指针模型不对称，迟早会把 metadata 或 shim pointers 撕裂出来。另一个重要结论是：如果为了并发安全改成 snapshot 发布，就不能再把 “same pointer across rebind” 当成必须合同，真正该守住的是 “fresh getter 给最新 snapshot，旧 cached snapshot 仍可安全调用”。 |
| What have I done? | 已完成多轮 runner/guard 修复，补强 external public ABI smoke、alias/public ABI 动态回归护栏，修复 perf/freeze isolation 假阳性，拿到 fresh Linux full closeout PASS，并修复 SSE4.2 dispatch 继承缺陷、`scIntegerOps` / AVX2 `scFMA` / AVX2 `scShuffle` / AVX512 `scShuffle` capability 漂移、`SSE3/SSSE3/SSE41` runtime rebuild 漏注册及 `SSE41/SSE42` shuffle capability 假绿，以及 hook-driven forced-selection 假成功。本轮最新又确认并修复了 public ABI concurrent publication tearing：`GetSimdPublicApi` 现在返回的是完整构造后再原子发布的 snapshot，shims 走当前 published state，不会再在并发重绑时暴露 `StructSize=0 / ActiveFlags=0 / nil shim pointer`。 |

### Phase 34: dispatch/direct concurrent publication hardening
- **Status:** complete
- Actions taken:
  - 继续深审 dispatch/direct 并发合同后，确认当前 active snapshot 还有一条新的真实 mixed-snapshot：
    - 旧 `src/fafafa.core.simd.dispatch.pas` 会让 `g_CurrentDispatch` 直接指向 `g_BackendTables[backend]`
    - `RegisterBackend(...)` 又会原地覆写 `g_BackendTables[backend]`
    - 所以 `GetDispatchTable` / `GetDirectDispatchTable` 与其他 backend readers 在并发重注册下可以混读两套 table
  - 先按 TDD 补独立并发 red，而不是先改实现：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas` 新增 `TTestCase_DirectDispatchConcurrent`
    - 新增 `Test_DirectDispatchTable_Concurrent_ReRegister_SnapshotConsistency`
    - 新增 `TDirectDispatchMutationWorker` / `TDirectDispatchReadWorker`
    - writer 在两套 synthetic table A/B 间持续 `RegisterBackend(...)`，reader 在多组 field 读取之间 `ThreadSwitch`
    - witness 槽位覆盖 `AddF32x4`、`ReduceAddF32x4`、`MemEqual`、`SumBytes`、`CountByte`、`BitsetPopCount`
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-direct-concurrent-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatchConcurrent`
    - 初版 red 先看到 A/B 地址混搭；第一次只把 current active snapshot 改成 copy-out publication 后，仍继续 FAIL，布尔 witness 变成：
      - `Add=False/True ReduceAdd=True/False MemEqual=True/False SumBytes=True/False CountByte=True/False BitsetPopCount=True/False`
    - 这一步把根因收紧到第二层：复制源 `g_BackendTables[...]` 本身仍是 mutable slot
  - 根因确认后，做最小实现修复：
    - `src/fafafa.core.simd.dispatch.pas` 新增 `TSimdDispatchPublishedState`
    - 新增 `g_CurrentDispatchStatePtr`、`g_CurrentDispatchOwnedHead`、`g_BackendDispatchStatePtrs`
    - 新增 `CreateDispatchPublishedState`、`PublishBackendDispatchTable`、`PublishCurrentDispatchTable`、`FinalizeDispatchPublishedStates`
    - `RegisterBackend(...)` 改成先发布 immutable backend snapshot，再标记 registered
    - `GetDispatchTable` / `GetDirectDispatchTable` / `IsBackendMarkedAvailableForDispatch` / `GetBackendInfo` / `TryGetRegisteredBackendDispatchTable` / `CloneDispatchTable` 全部切到 published snapshot
  - 同步 runner/gate parity：
    - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 把 `TTestCase_DirectDispatchConcurrent` 接进 `ProcessAllSuites`
    - `tests/fafafa.core.simd/BuildOrTest.sh` 与 `buildOrTest.bat` 的 cross-backend parity 现在都会额外跑这条 suite
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-direct-concurrent-green-20260321d bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatchConcurrent`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-direct-concurrent-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-direct-concurrent-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh targeted concurrent suite PASS，`[LEAK] OK`
    - fresh `check` PASS
    - fresh `gate` 最终 `[GATE] OK`
    - run-all summary 时间：`2026-03-21 19:41:15`
- Files created/modified:
  - `src/fafafa.core.simd.dispatch.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` (modified)
  - `tests/fafafa.core.simd/BuildOrTest.sh` (modified again)
  - `tests/fafafa.core.simd/buildOrTest.bat` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

## 5-Question Reboot Check (Phase 34 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DirectDispatchConcurrent`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条新的 dispatch/direct concurrent publication tearing：旧 `g_CurrentDispatch` 即使改成 copy-out publication，只要复制源仍来自 mutable `g_BackendTables[...]`，reader 仍会混读 A/B table。当前 x86_64 主机已 fresh 证明 backend-level immutable publication 已把这条并发假绿关掉，但 native arm64/riscv64 runtime-toggle 与 native AVX512 执行证据仍待补齐 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “shared mutable table / cached metadata / rebuild helper 在 toggle、re-register 或并发读写后仍误报或漏报” 的真实问题，重点看 x86/non-x86 `SetVectorAsmEnabled(True -> False)` 重建链、public ABI `CapabilityBits` 与 `BackendInfo.Capabilities` 是否还有漂移，以及还有没有别的 reader 仍在直接信任会被原地改写的 shared state；同时继续保留 fresh Windows native evidence、arm64/riscv64 native runtime-toggle 证据，以及具备 `avx512f/avx512bw` 条件主机上的 AVX512 native execution 证据作为后续收口项 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 并发 publication 的关键不只是 “当前 active 指针怎么发布”，还包括 “active snapshot 是从哪里拷出来的”。如果复制源本身仍是会被 writer 原地改写的 mutable backend slot，那么即使 current pointer 改成 snapshot publication，也还是会读到 mixed table。另一个结论是：direct dispatch 的并发护栏不能只守 `GetDispatchTable`，backend info/query/clone 这些旁路 reader 也必须一起切到同一套 immutable publication。 |
| What have I done? | 已完成多轮 runner/guard 修复，补强 external public ABI smoke、alias/public ABI 动态回归护栏，修复 perf/freeze isolation 假阳性，拿到 fresh Linux full closeout PASS，并修复多轮 capability/rebuild/dispatch/public ABI 合同问题。本轮最新又确认并修复了 dispatch/direct concurrent publication tearing：`src/fafafa.core.simd.dispatch.pas` 现在对 current dispatch 与 backend slot 都使用 immutable published snapshots，`TTestCase_DirectDispatchConcurrent` 已接入主 runner/gate parity，`RegisterBackend(...)` 的并发重注册不再把 direct/current readers 撕成 mixed snapshot。 |

### Phase 35: public ABI backend pod snapshot consistency hardening
- **Status:** complete
- Actions taken:
  - 继续深审 public ABI backend pod metadata 并发合同后，确认 `TryGetSimdBackendPodInfo(...)` 还有一条新的真实 mixed-snapshot：
    - 旧实现会先从 `GetBackendInfo(...)` / registered snapshot 取 `Capabilities`
    - 再通过 `SimdBackendToAbiFlags(aBackend)` 做 live `supported_on_cpu/registered/dispatchable/active` 查询
    - 结果是在并发 `RegisterBackend(...)` 切换同一 backend 的 `Available/Capabilities` 时，单个 `TFafafaSimdBackendPodInfo` 会被拼成跨两个注册态的混搭结果
  - 先按 TDD 补最小 red，而不是先改实现：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TTestCase_SimdConcurrentPublicAbi`
    - 新增 `Test_Concurrent_PublicAbiPodInfo_RegisterBackend_ReadConsistency`
    - 新增 `TBackendRegisterToggleWorker` / `TPublicAbiPodInfoReadWorker`
    - writer 在 enabled/disabled 两套 synthetic table 间持续 `RegisterBackend(...)`
    - reader 持续断言 backend pod info 只能落在两种合法组合，而不能出现 `caps=415 flags=3` / `caps=0 flags=7` 这类 mixed snapshot
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-podinfo-red3-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi`
    - 失败点直接命中：
      - `backend pod info mixed snapshot at iter 86: caps=415 flags=3 expectedA=(415,7) expectedB=(0,3)`
      - `backend pod info mixed snapshot at iter 31: caps=0 flags=7 expectedA=(415,7) expectedB=(0,3)`
  - 根因确认后，做最小实现修复：
    - `src/fafafa.core.simd.public_abi.impl.inc` 新增 `BuildSimdBackendAbiFlagsFromSnapshot(...)`
    - `TryGetSimdBackendPodInfo(...)` 改为先 `TryGetRegisteredBackendDispatchTable(...)` 取单份 published backend snapshot
    - `CapabilityBits`、`dispatchable` 与 registered-state `Priority` 全部从 `LDispatchTable.BackendInfo` 派生
    - `active` bit 继续从当前 active dispatch snapshot 判定
    - 初版修复曾尝试直接调用 `GetSimdBackendPriorityValue(...)`，但当前 include 作用域拿不到该符号；最终收口为 registered 路径直接复用 snapshot priority、未注册路径退回 `GetBackendInfo(aBackend).Priority`
  - 同步 runner/gate parity：
    - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 现已接入 `TTestCase_SimdConcurrentPublicAbi`
    - 新并发 suite 可以被主 runner 的 targeted suite 路径直接调用
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-podinfo-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-podinfo-publicabi-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-podinfo-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-podinfo-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh concurrent public ABI targeted suite PASS，`[LEAK] OK`
    - fresh `TTestCase_PublicAbi` PASS，`[LEAK] OK`
    - fresh `check` PASS
    - fresh `gate` 最终 `[GATE] OK`
    - run-all summary 时间：`2026-03-21 20:26:22`
- Files created/modified:
  - `src/fafafa.core.simd.public_abi.impl.inc` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

## 5-Question Reboot Check (Phase 35 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_SimdConcurrentPublicAbi`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条新的 public ABI backend pod mixed-snapshot：旧 `TryGetSimdBackendPodInfo(...)` 会把 `CapabilityBits` 和 `Flags` 从不同 observation point 拼起来。当前 x86_64 主机已 fresh 证明单份 published backend snapshot 已把这条并发假绿关掉，但 native arm64/riscv64 runtime-toggle 与 native AVX512 执行证据仍待补齐 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “public ABI / dispatch helper / rebuild path 在 toggle、re-register 或并发读写后仍误报或漏报” 的真实问题，重点看 `GetSimdPublicApi.ActiveFlags`、其他 metadata getter、以及 x86/non-x86 `SetVectorAsmEnabled(True -> False)` 重建链是否还有 reader 仍在跨多个 live 查询拼装单个对外结果；同时继续保留 fresh Windows native evidence、arm64/riscv64 native runtime-toggle 证据，以及具备 `avx512f/avx512bw` 条件主机上的 AVX512 native execution 证据作为后续收口项 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | public ABI metadata 的问题不只在“字段语义对不对”，还在“这些字段是不是来自同一个时间点”。即使 `GetBackendInfo(...)` 和 `TryGetRegisteredBackendDispatchTable(...)` 已经改成读 published snapshot，只要 `TryGetSimdBackendPodInfo(...)` 还继续夹杂 live `SimdBackendToAbiFlags(...)` 查询，最终对外的 POD struct 仍会变成 mixed snapshot。另一个结论是：priority 这种看起来稳定的字段也不该为了取 canonical 值重新绕回额外 live helper，否则修并发时很容易顺手引入新的可见性或一致性耦合。 |
| What have I done? | 已完成多轮 runner/guard 修复，补强 external public ABI smoke、alias/public ABI 动态回归护栏，修复 perf/freeze isolation 假阳性，拿到 fresh Linux full closeout PASS，并修复多轮 capability/rebuild/dispatch/public ABI 合同问题。本轮最新又确认并修复了 public ABI backend pod mixed-snapshot：`TryGetSimdBackendPodInfo(...)` 现在会优先从同一份 published backend snapshot 派生 `CapabilityBits`、`dispatchable` 与 registered priority，`TTestCase_SimdConcurrentPublicAbi` 已守住这条并发合同。 |

### Phase 36: framework current-backend-info snapshot consistency hardening
- **Status:** complete
- Actions taken:
  - 继续深审 framework active metadata 并发合同后，确认 `GetCurrentBackendInfo` 还有一条新的真实 mixed-snapshot：
    - 旧 `src/fafafa.core.simd.framework.impl.inc` 直接做 `GetBackendInfo(GetActiveBackend)`
    - 当 writer 并发 `RegisterBackend(...)` 把当前 active backend 在 enabled/disabled table 间切换时，helper 可能先观察到“旧 active backend id”，再读到“该 backend 已被重注册为 disabled”的新 metadata
    - 结果是对外返回一个不可能代表 current backend 的组合，例如 `backend=AVX2` 但 `Available=False`、`Capabilities=[]`
  - 先按 TDD 补最小 red，而不是先改 framework helper：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TTestCase_SimdConcurrentFramework`
    - 新增 `Test_Concurrent_CurrentBackendInfo_RegisterBackend_ReadConsistency`
    - writer 复用 `TBackendRegisterToggleWorker`
    - reader 持续断言 `GetCurrentBackendInfo` 只能等于 enabled current info，或 disabled 后真实 fallback current info，不能出现 disabled target info
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackendinfo-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework`
    - 失败点直接命中：
      - `current backend info mixed snapshot at iter 127: got=(backend=6 available=False caps=0 priority=80 name=AVX2) expectedA=(backend=6 available=True caps=447 priority=80 name=AVX2) expectedB=(backend=5 available=True caps=415 priority=70 name=SSE4.2)`
  - 根因确认后，做最小实现修复：
    - `src/fafafa.core.simd.framework.impl.inc` 的 `GetCurrentBackendInfo` 改为直接读取 `GetDispatchTable` 的当前 published snapshot
    - 如果当前 dispatch snapshot 不为 nil，就直接返回 `LDispatch^.BackendInfo`
    - 只有兜底路径才退回 `GetBackendInfo(GetActiveBackend)`
  - 同步 runner/gate parity：
    - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 现已接入 `TTestCase_SimdConcurrentFramework`
    - fresh `check` 的 suite manifest 已更新为 `registered_suites=45 handled_suites=45`
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackendinfo-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackendinfo-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackendinfo-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh concurrent framework targeted suite PASS，`[LEAK] OK`
    - fresh `check` PASS
    - fresh `gate` 最终 `[GATE] OK`
    - run-all summary 时间：`2026-03-21 21:54:05`
- Files created/modified:
  - `src/fafafa.core.simd.framework.impl.inc` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

## 5-Question Reboot Check (Phase 36 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条新的 framework active metadata mixed-snapshot：旧 `GetCurrentBackendInfo` 会把 active backend id 与 backend metadata 分两次 live 查询拼起来。当前 x86_64 主机已 fresh 证明直接读取 current dispatch snapshot 已把这条并发假绿关掉，但 native arm64/riscv64 runtime-toggle 与 native AVX512 执行证据仍待补齐 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “framework/public ABI/dispatch helper 在 toggle、re-register 或并发读写后仍误报或漏报” 的真实问题，重点看 `GetSimdPublicApi.ActiveFlags`、`GetCurrentBackend` 相关 helper、以及 x86/non-x86 `SetVectorAsmEnabled(True -> False)` 重建链是否还有单个对外结果仍由多次 live 查询拼装；同时继续保留 fresh Windows native evidence、arm64/riscv64 native runtime-toggle 证据，以及具备 `avx512f/avx512bw` 条件主机上的 AVX512 native execution 证据作为后续收口项 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮再次证明：哪怕没有 capability bits，普通 façade helper 也会掉进同一种坑。只要一个“当前状态” helper 还是 `GetX` 再 `GetY(GetX)` 这种双读拼装，在 active backend 可以被重注册重选的系统里，就迟早会返回 impossible combo。另一个结论是：修这类问题时不一定都要新建复杂 publication 结构，很多时候直接复用已经存在的 current dispatch published snapshot 就够了。 |
| What have I done? | 已完成多轮 runner/guard 修复，补强 external public ABI smoke、alias/public ABI 动态回归护栏，修复 perf/freeze isolation 假阳性，拿到 fresh Linux full closeout PASS，并修复多轮 capability/rebuild/dispatch/public ABI 合同问题。本轮最新又确认并修复了 framework current-backend-info mixed-snapshot：`GetCurrentBackendInfo` 现在直接返回 current dispatch snapshot 的 `BackendInfo`，`TTestCase_SimdConcurrentFramework` 已守住这条并发合同。 |

### Phase 37: backend adapter unregistered metadata contract closeout
- **Status:** complete
- Actions taken:
  - 继续深审 backend adapter / façade helper 合同时，确认 `src/fafafa.core.simd.backend.adapter.pas` 的 `GetBackendOps(backend)` 在“未注册 backend”路径上还有一条新的真实 metadata drift：
    - 旧实现先 `ClearBackendOps(Result)`
    - 然后只回写 `Result.Backend := backend`
    - 但没有把 `Result.BackendInfo` 对齐到 canonical metadata
    - 结果是 `GetBackendOps(sbAVX512/sbNEON/sbRISCVV...)` 这类未注册 backend 会把 `BackendInfo.Backend` 错误留在默认 `sbScalar(0)`，`Priority` 也错误留在 `0`
  - 先按 TDD 补最小 deterministic red，而不是先改 adapter：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas` 新增 `Test_BackendAdapter_UnregisteredBackendOps_PreserveCanonicalMetadata`
    - 测试直接选取当前未注册 backend，断言 `GetBackendOps(backend)` 返回的 `BackendInfo.Backend/Priority/Name` 必须与 `GetBackendInfo(backend)` 完全一致
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots`
    - 失败点直接命中：
      - `GetBackendOps should preserve BackendInfo.Backend for unregistered backend=7 expected: <7> but was: <0>`
  - 根因确认后，做最小实现修复：
    - `src/fafafa.core.simd.backend.adapter.pas` 的未注册路径保留 `Result.Backend := backend`
    - 同时新增 `Result.BackendInfo := GetBackendInfo(backend)`，不再让 adapter 自己暴露零值 `BackendInfo`
  - 顺手补了一条 future guard，但没有把它算成主问题 closeout：
    - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicAbi_BackendText_Getters_PreviousPointers_RemainValid_After_Refresh`
    - 该 guard 当前为绿，说明这轮没有 fresh 复现 text-pointer lifetime bug
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh `TTestCase_DispatchAllSlots` PASS，`[LEAK] OK`
    - fresh `check` PASS
    - fresh `gate` 最终 `[GATE] OK`
    - run-all summary 时间：`2026-03-21 22:31:18`
- Files created/modified:
  - `src/fafafa.core.simd.backend.adapter.pas` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas` (modified)
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

## 5-Question Reboot Check (Phase 37 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAllSlots`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条新的 backend adapter metadata drift：旧 `GetBackendOps(backend)` 在未注册路径上会把 `BackendInfo.Backend/Priority` 留成零值默认态，而不是 canonical backend metadata。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “helper/façade 在 unregistered/registered 切换、runtime toggle 或 re-register 后仍把单个对外结果拆成多次 live 查询再拼装” 的真实问题，重点继续看 `backend.adapter`、`framework/public_abi`、registered-list/helper readers，以及 x86/non-x86 `SetVectorAsmEnabled(True -> False)` 重建链是否还有 stale metadata / stale dispatch。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮问题证明，哪怕没有并发，adapter/helper 也会因为“自己补默认值”而漂移出第二套 contract。对于 unregistered path 这种兜底分支，最稳的做法不是手抄 metadata 默认值，而是直接复用现有 canonical source `GetBackendInfo(backend)`。另外，public ABI text getter 的 previous-pointer lifetime 目前没有 fresh red，现阶段应把它当 guard，而不是误记成已确认 bug。 |
| What have I done? | 已完成多轮 runner/guard 修复、capability/rebuild/dispatch/public ABI 合同修复，并拿到 fresh Linux closeout 证据。本轮最新又确认并修复了 backend adapter unregistered metadata drift：`GetBackendOps(backend)` 现在会在未注册路径直接复用 canonical `GetBackendInfo(backend)`，`TTestCase_DispatchAllSlots` 已守住这条 adapter 合同。 |

### Phase 38: dispatch selection and dispatchable-helper toggle snapshot hardening
- **Status:** complete
- Actions taken:
  - 继续深审 runtime toggle / dispatch helper 合同时，先补了一条新的并发 red：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 的 `TTestCase_SimdConcurrentFramework` 新增 `Test_Concurrent_DispatchableHelpers_VectorAsmToggle_ReadConsistency`
    - 目标是锁定 `GetDispatchableBackendList` / `GetAvailableBackendList` / `GetBestDispatchableBackend` 在 `SetVectorAsmEnabled(False <-> True)` 并发窗口里只能返回 enabled 全量态或 disabled 全量态，不能暴露半重建中间态
  - fresh red 并没有只打出新 helper 问题，还顺手把旧 `GetCurrentBackendInfo` 路径的更深根因也重新打了出来：
    - `current backend info mixed snapshot at iter 2224: got=(backend=6 available=False caps=0 priority=80 name=AVX2) ...`
    - `dispatchable helper mixed snapshot at iter 0: got=[1,0] expectedEnabled=[6,5,4,3,2,1,0] expectedDisabled=[0]`
    - `best dispatchable backend mixed snapshot at iter 13: got=1 expectedEnabled=6 expectedDisabled=0`
  - 复盘后把问题拆成两层同区根因：
    - `src/fafafa.core.simd.dispatch.pas` 的 `DoInitializeDispatch` 虽已按 published backend state 选择 `LBestBackend`，但旧实现最后仍 `PublishCurrentDispatchTable(@g_BackendTables[LBestBackend])`，会把 mutable backend slot 的新 disabled metadata 重新带进 current dispatch snapshot
    - `GetDispatchableBackends` / `GetBestDispatchableBackend` 在 `SetVectorAsmEnabled` 顺序重建各 backend 时无锁 live 扫描，因此会把 enable 过程中的 `SSE2/SSE3/...` 半重建中间态直接暴露给 helper 调用方
  - 根因确认后，做最小实现修复：
    - `DoInitializeDispatch` 新增 `LBestDispatchTable := GetPublishedBackendDispatchTable(LBestBackend)`，current dispatch publication 改为复用 immutable published backend snapshot
    - `GetDispatchableBackends` 与 `GetBestDispatchableBackend` 在扫描期间持有 `g_VectorAsmToggleLock`，与 `SetVectorAsmEnabled` 共享控制面同步点
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh `TTestCase_SimdConcurrentFramework` PASS，`[LEAK] OK`
    - fresh `check` PASS
    - fresh `gate` 最终 `[GATE] OK`
    - run-all summary 时间：`2026-03-21 23:04:43`
- Files created/modified:
  - `src/fafafa.core.simd.dispatch.pas` (modified again)
  - `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` (modified again)
  - `task_plan.md` (modified)
  - `findings.md` (modified)
  - `progress.md` (modified)

## 5-Question Reboot Check (Phase 38 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条新的 runtime-toggle helper drift：旧 dispatchable helper 会在 `SetVectorAsmEnabled(False <-> True)` 期间暴露半重建中间态，而 current dispatch publication 也还残留一处 mutable-slot 复制点。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “helper/list/metadata 仍在 runtime toggle、re-register 或 unregistered/registered 迁移里观察到多份真相源” 的真实问题，重点继续看 registered-view helpers、public ABI text/name getter 生命周期、以及 non-x86/x86 toggle 路径里是否还有 list/pod/helper 没有统一到单份稳定 snapshot。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，仅把 selection predicate 切到 published snapshot 还不够；只要最后一步 publication 还从 mutable slot 复制，reader 仍能拿到 impossible combo。另外，`SetVectorAsmEnabled` 这种多-backend 顺序重建路径下，list/best helper 不加同步就天然会把中间态暴露出去，哪怕单个 backend snapshot 自己已经是 immutable publication。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续把计划文件与 fresh 证据同步到位。本轮最新又确认并修复了 dispatch selection / dispatchable helper toggle snapshot drift：`DoInitializeDispatch` 现在从 selected backend 的 published snapshot 发布 current dispatch，`GetDispatchableBackends/GetBestDispatchableBackend` 也已被 `g_VectorAsmToggleLock` 保护，`TTestCase_SimdConcurrentFramework` 已守住这条合同。 |
