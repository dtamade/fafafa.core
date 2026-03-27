# Task Plan: SIMD 模块审查、修复与连续计划

## Goal
审查 `fafafa.core.simd` 及其 `cpuinfo` 相关模块，找出可验证的问题并完成至少一轮根因修复，同时产出可连续执行的后续修复与审查计划。

## Current Phase
Phase 106 complete; fresh `Release` `check` and `gate` are green again, Linux/QEMU CPUInfo non-x86 evidence has been refreshed, and `freeze-status` is now blocked only by stale Windows evidence. The active SIMD queue remains `SIMD-B23(candidate)`, but the remaining blocker is operational: dispatching fresh Windows evidence for the current dirty-but-uncommitted worktree requires either a Windows host or a commit/push before `win-evidence-via-gh`.

## Phases

### Phase 1: 范围确认与结构梳理
- [x] 理解用户目标：审查 simd、找问题、修问题、出连续计划
- [x] 识别约束：优先证据驱动、修复前先定位根因、Rust 命令默认 release
- [x] 识别主入口、实现层、测试入口和维护文档
- **Status:** complete

### Phase 2: 证据收集与问题复现
- [x] 运行 simd 快速门禁和定向测试
- [x] 记录失败、可疑警告和不一致行为
- [x] 将问题按严重级别排序
- **Status:** complete

### Phase 3: 根因分析与 TDD 修复
- [x] 为确认的问题补最小失败用例
- [x] 基于根因做最小修复
- [x] 记录影响范围与潜在回归点
- **Status:** complete

### Phase 4: 复验与回归
- [x] 重新运行相关测试和检查
- [x] 验证修复没有引入新回归
- [x] 更新 findings/progress
- **Status:** complete

### Phase 5: 连续修复与审查计划
- [x] 汇总本轮问题类型
- [x] 制定下一轮审查优先级和验证矩阵
- [x] 输出给用户可直接执行的连续计划
- **Status:** complete

### Phase 6: non-x86 opt-in backend compile blocker closeout
- [x] 修复 `RISCVV` opt-in `facade.inc` 条件编译骨架
- [x] 修复 `NEON` opt-in `ifdef/include` 配平错误
- [x] 用 fresh `RISCVV/NEON` opt-in suite 与默认 `gate` 复验
- **Status:** complete

### Phase 7: non-x86 opt-in registration and metadata contract closeout
- [x] 修复 opt-in runner 只编译不注册 backend 的验证盲区
- [x] 用 test-only registration define 让 `NEON/RISCVV` 在非原生主机上进入 dispatch/public ABI 测试面
- [x] 修复 `NEON scShuffle` / `RISCVV scFMA` 在 scalar-fallback 注册态下的 overclaim
- [x] 用 fresh red/green opt-in suites 与默认 `gate` 复验
- **Status:** complete

### Phase 8: non-x86 capability symmetry closeout
- [x] 补 `NEON scFMA` / `RISCVV scShuffle` 的 dispatch/public ABI red 测试
- [x] 修复两处 capability set 继续无条件宣称的问题，使其跟随真实 asm 可用性
- [x] 用 fresh opt-in red/green suites 与默认 `gate` 复验
- **Status:** complete

### Phase 9: non-x86 runtime-toggle rebuild hardening
- [x] 识别 `NEON/RISCVV` asm build 的 runtime toggle 仍可能留下 stale dispatch / stale capability
- [x] 在 asm build + runtime disabled 时，把 `NEON/RISCVV` 重建为 scalar-backed table，并补 native-only regression tests
- [x] 用默认 suite、non-x86 opt-in suite 与默认 `gate` 复验当前主机回归不受影响
- **Status:** complete

### Phase 10: non-x86 opt-in compile smoke gate coverage
- [x] 确认默认 `check/gate` 之前只靠静态 guard，不会 fresh 编译 `NEON/RISCVV` opt-in `--list-suites`
- [x] 新增 `nonx86-optin-list-suites` action，并把它接入默认 `check` 与 shell `gate_step_build_check`
- [x] 为 `nonx86.optin/` 隔离输出补 clean 覆盖，并同步 batch runner / usage / parity guard
- [x] 用 fresh action、`check`、`gate`、`clean -> find` 复验
- **Status:** complete

### Phase 11: Windows evidence preflight billing-block hardening
- [x] 识别 `win-evidence-preflight` 之前过度依赖 annotations，且是手拼 `check-runs/<job-id>` 路径
- [x] 改为优先扫描 `gh run view` 文本，再回退到 jobs JSON 里的 `check_run_url` annotations
- [x] 用 synthetic `gh` harness 复验 `RECENT_BILLING_BLOCK` 与正常 PASS 两条路径
- **Status:** complete

### Phase 12: Windows evidence existing-run reuse hardening
- [x] 识别 `win-evidence-via-gh` 显式传 `run-id` 时，仍被顶部 dirty worktree / remote ref mismatch / git ref lookup 误伤
- [x] 把 dispatch-only 的 git 依赖、ref/sha 解析与 hygiene 守卫全部收进 `if [[ -z "${LRunId}" ]]` 分支
- [x] 用 synthetic harness 复验“显式 run-id 继续下载/校验”“dispatch 仍拒绝 dirty worktree”“run-id 路径不再触发 git 调用”
- **Status:** complete

### Phase 13: Remote Windows evidence failure triage
- [x] 查询最近的 `simd-windows-b07-evidence.yml` workflow runs，确认最新 success/failure 时间点和 run-id
- [x] 下载最新 failure run 的 artifact，并用当前 verifier 复验
- [x] 确认远端最新 failure 仍是旧 `1/6..6/6` 证据口径，下一步需要从包含当前修复的 pushed ref 重新派发 fresh run
- **Status:** complete

### Phase 14: Simulated Windows evidence contract realignment
- [x] 复现 `win-closeout-dryrun` 与 `rehearse_freeze_status.sh` 因模拟日志仍是 `1/6..6/6` 而失败
- [x] 把 `simulate_windows_b07_evidence.sh` 与 `rehearse_freeze_status.sh` 的 PASS 模板升级到 `1/7..7/7`
- [x] 给模拟日志写入不存在的 `GateSummaryJson` sentinel，避免误吸同目录真实 `gate_summary.json`
- [x] 用 direct verifier、`win-closeout-dryrun`、`rehearse_freeze_status.sh` 复验
- **Status:** complete

### Phase 15: Simulated Windows evidence regression guard
- [x] 在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_windows_simulated_evidence_guard`
- [x] 把新 guard 接入默认 `check` 与 `gate_step_build_check`
- [x] 用 fresh `simd check` 复验 guard 不误伤主线
- **Status:** complete

### Phase 16: Manual Windows closeout contract and helper runtime guard
- [x] 识别手工 Windows closeout 文档/helper 漏掉必需的 fail-close cross gate，和 `print_windows_b07_closeout_3cmd.sh` 的反引号命令替换 runtime bug
- [x] 修复 `print_windows_b07_closeout_3cmd.sh`、runbook、closeout doc，以及 roadmap/template/handoff/legacy checklist 的手工路径说明，使其显式包含 `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1` cross gate
- [x] 在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 manual closeout static guard 与 helper runtime guard，并用 fresh `win-closeout-3cmd` / `check` 复验
- **Status:** complete

### Phase 17: Windows evidence minimum push surface mapping
- [x] 读取 `.github/workflows/simd-windows-b07-evidence.yml`，确认 workflow staging 范围与 Windows job 的直接调用链
- [x] 区分“fresh Windows artifact 真正依赖的 runtime-critical 文件”和“仅本地 closeout/helper/doc/guard 使用的文件”
- [x] 记录下一步最小推送策略，避免在脏工作区里把无关 `src/` 改动一起带上远端
- **Status:** complete

### Phase 18: Windows native runtime-critical set refinement
- [x] 继续核对 `tests/fafafa.core.simd.publicabi/BuildOrTest.bat` 与 `BuildOrTest.sh` 的 direct dependency，区分 Windows batch smoke 与 Linux shell harness
- [x] 确认 `publicabi_smoke.c` 只被 shell `BuildOrTest.sh` 调用，不在 `simd-windows-b07-evidence.yml` 的 native batch artifact 生成链上
- [x] 将“fresh Windows artifact 最小推送面”从 5 文件进一步收敛为 4 文件，并生成新的最小补丁工件
- **Status:** complete

### Phase 19: non-x86 `scIntegerOps` fallback overclaim closeout
- [x] 确认 `NEON/RISCVV` 在 non-asm 或 test-only fallback 注册态下仍高报 `scIntegerOps`
- [x] 为 `DispatchAPI/PublicAbi` 补 `NEON/RISCVV scIntegerOps` red tests，并把 native runtime-disabled `SetVectorAsmEnabled(False)` 路径也纳入清零合同
- [x] 将 `src/fafafa.core.simd.neon.register.inc` 与 `src/fafafa.core.simd.riscvv.register.inc` 的 `scIntegerOps` 宣称收紧为仅 `LUseVectorAsm=True` 时成立
- [x] 用 fresh `NEON/RISCVV` opt-in suites、默认 `check`、默认 `gate` 复验
- **Status:** complete

### Phase 20: AVX512 runtime-gated capability/rebuild contract closeout
- [x] 确认 `src/fafafa.core.simd.avx512.register.inc` 之前忽略 `IsVectorAsmEnabled`，在 `SetVectorAsmEnabled(False)` 后仍保留 native `FmaF32x16/AddU32x16` 等宽槽位与 `scFMA/scIntegerOps/scMaskedOps/sc512BitOps`
- [x] 为 `DispatchAPI/PublicAbi` 补 AVX512 runtime-disabled red tests，并把旧 AVX512 native-path 测试改成显式 `SetVectorAsmEnabled(True)` 后再断言 native 映射
- [x] 将 `AVX512` 注册逻辑改为仅在 `LEnableVectorAsm=True` 时覆盖 native 宽槽位与 gated capabilities，runtime-disabled 时保留 fallback table
- [x] 用 fresh `SIMD_ENABLE_AVX512_BACKEND=1` suite、`check`、`gate` 复验
- **Status:** complete

### Phase 21: AVX512 `scShuffle` underclaim closeout
- [x] 确认 `AVX512` 在 `vector asm=True` 且 `SelectF32x16/SelectF64x8` 已经脱离 scalar 时仍低报 `scShuffle`
- [x] 为 `DispatchAPI/PublicAbi` 补 AVX512 `scShuffle` red tests，并把 runtime-disabled 路径扩到检查 `SetVectorAsmEnabled(False)` 后该 bit 必须清零
- [x] 将 `src/fafafa.core.simd.avx512.register.inc` 的 `scShuffle` 宣称改为仅在 `LEnableVectorAsm=True` 时成立，与宽 select 槽位真实映射保持一致
- [x] 用 fresh `SIMD_ENABLE_AVX512_BACKEND=1` suite、`check`、`gate` 复验
- **Status:** complete

### Phase 22: scalar-backed active-backend reselection closeout
- [x] 确认 `SetVectorAsmEnabled(True -> False)` 后，runtime-gated backend 即使已重建成 scalar-backed table，仍因 `BackendInfo.Available=True` 被继续视为 dispatchable/active
- [x] 为 `DispatchAPI/PublicAbi` 补 red tests，要求 scalar-backed 原 backend 在 vector-asm-disabled 路径下失去 dispatchable/active 身份
- [x] 将 x86 runtime-gated backend 的 `Available` 改为跟随 `IsVectorAsmEnabled/LEnableVectorAsm`，并把 `NEON/RISCVV` 收敛为仅在 native asm build 且 runtime disabled 时清掉 `Available`
- [x] 将 backend smoke / public smoke 的 active-backend 预期从 “registered + CPU feature” 收紧为真正的 dispatchable 语义
- [x] 用 fresh targeted suite、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 23: public-smoke default-backend priority closeout
- [x] 确认 `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas` 仍手写 partial x86 priority，只覆盖 `SSE2/AVX2`
- [x] 为 `DispatchAPI` 补 red test，显式制造 `AVX2` non-dispatchable 且 `SSE4.2` 仍 dispatchable 的场景，证明 old predictor 会把默认 backend 误算成 `SSE2`
- [x] 新增 `tests/fafafa.core.simd/fafafa.core.simd.public_smoke_support.pas`，并把 public smoke 改为复用 canonical `GetBestDispatchableBackend`
- [x] 用 fresh `DispatchAPI`、standalone `public_smoke` 编译/运行、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 24: pre-init vector-asm toggle stale-dispatch closeout
- [x] 确认 dispatch-only consumer 在首次 dispatch 初始化之前调用 `SetVectorAsmEnabled(False)` 时，已注册 backend table 不会重建，仍把 `AVX2/SSE*` 视为 dispatchable
- [x] 新增 standalone smoke `tests/fafafa.core.simd/fafafa.core.simd.dispatch_preinit_smoke.pas`，并把 shell/batch `check` 与 shell `gate` 的 build-check 链都接上这条 red/green 护栏
- [x] 将 `src/fafafa.core.simd.dispatch.pas` 的 feature-toggle rebuild 改成 pre-init 也会重建 backend table，但仅在 dispatch 已初始化时才立即重新选主
- [x] 用 fresh red `check`、fresh green `check`、fresh external standalone probe、fresh `gate` 复验
- **Status:** complete

### Phase 25: public ABI backend text getter drift closeout
- [x] 确认 `GetSimdBackendNamePtr` / `GetSimdBackendDescriptionPtr` 会把第一次观察到的 backend text 永久缓存下来，导致 `RegisterBackend(...)` 动态重注册后对外仍返回旧字符串
- [x] 在 `TTestCase_PublicAbi` 补最小 red，先 prime text cache，再重注册当前 backend 并断言 public ABI text getter 必须跟随新的 `BackendInfo.Name/Description`
- [x] 将 `src/fafafa.core.simd.public_abi.impl.inc` 的 backend text cache 改为每次 getter 调用都从最新 `GetBackendInfo(...)` 刷新
- [x] 用 fresh red `TTestCase_PublicAbi`、fresh green `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 26: x86 inherited `scShuffle` capability underclaim closeout
- [x] 确认 `SSE2` 已经把 `Select/Insert/Extract` 等代表性 shuffle 槽位接到非 scalar 实现，`SSE3` 也经由 clone 链继承了这些槽位，但 capability/public ABI 仍低报 `scShuffle`
- [x] 在 `DispatchAPI/PublicAbi` 补最小 red，按“代表性 shuffle 槽位非 scalar 则必须宣称 `scShuffle`”回收 fresh 失败证据
- [x] 将 `src/fafafa.core.simd.sse2.pas`、`src/fafafa.core.simd.sse2.i386.register.inc`、`src/fafafa.core.simd.sse3.register.inc` 的 `scShuffle` 宣称补齐到现有 `IsVectorAsmEnabled` gate，保持 `SSSE3+` 既有语义不变
- [x] 用 fresh red `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh green 定向 suite、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 27: AVX2 masked-`FMA` dispatch-slot drift closeout
- [x] 确认 `AVX2` 在 CPU 仍具备 `AVX2` 但 `gfFMA` 被 mask 掉时，`scFMA` capability/public ABI 已清零，但 `FmaF32x4/FmaF64x2/FmaF32x8/FmaF64x4/FmaF32x16/FmaF64x8` 槽位仍被 `AVX2Fma*` wrapper 覆写
- [x] 在主 test runner 补独立 qemu 回归 suite `TTestCase_X86MaskedFmaContract`，用 `qemu-x86_64 -cpu Haswell,-fma` 回收 fresh red
- [x] 将 `src/fafafa.core.simd.avx2.register.inc` 的 `FmaF*` slot 覆写收紧到 `LHasHardwareFma=True`，保持 scalar fallback slot / capability bits / public ABI 三者一致
- [x] 用 fresh qemu green、fresh release 定向 suite、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 28: AVX512 required-features `FMA` predicate closeout
- [x] 排除 `SSE2` rounding broad-drift 候选，确认宽类型 rounding 大多已有真 `SSE2` 实现，本轮不把它作为主修问题
- [x] 确认 `src/fafafa.core.simd.cpuinfo.base.pas` 的 `X86HasAVX512BackendRequiredFeatures(...)` 漏掉 `HasFMA`，而 `src/fafafa.core.simd.avx512.f32x16_fma_round.inc` / `src/fafafa.core.simd.avx512.f64x8_fma_round.inc` 的 `AVX512Fma*` 直接执行 `vfmadd213ps/pd`
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 的 `TTestCase_X86BackendPredicates` 先补纯逻辑 red，证明“无 `FMA` 仍被判定为 AVX512 backend 可用”是共享谓词层的真实合同缺口
- [x] 将 `X86HasAVX512BackendRequiredFeatures(...)` 收紧为同时要求 `AVX2 + AVX512F + AVX512BW + POPCNT + FMA`
- [x] 用 fresh red `TTestCase_X86BackendPredicates`、fresh green `TTestCase_X86BackendPredicates`、fresh release `check`、fresh release `gate` 复验
- **Status:** complete

### Phase 29: AVX512 raw-usable vs backend-ready execution-gate drift closeout
- [x] 确认 `HasAVX512/simd_has_avx512f` 仍是 raw usable AVX512F 语义，而 `IsBackendSupportedOnCPU(sbAVX512)` / `X86SupportsAVX512BackendOnCPU(...)` 已经是 backend-ready 语义
- [x] 先在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 的 `TTestCase_X86BackendPredicates` 补 pure red，证明 direct AVX512 execution gate 不能只看 raw usable AVX512F
- [x] 将 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 里的 AVX512 direct/helper guard 收口到 backend-ready predicate，并把 `AVX512VectorAsm` suite 的 runtime gate 改成 dispatchable 语义
- [x] 将 `tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.testcase.pas` 的 AVX512 backend presence 断言，以及 `tests/fafafa.core.simd/bench_avx512_vs_avx2.lpr` 的 report 文案，同步到 backend-ready 口径
- [x] 用 fresh red、fresh green、fresh cpuinfo suite、fresh AVX512 opt-in suite、fresh AVX512 opt-in `check`、fresh AVX512 opt-in `gate` 复验
- **Status:** complete

### Phase 30: backend benchmark activation contract closeout
- [x] 确认 `bench_avx512_vs_avx2.lpr` / `bench_neon_vs_scalar.lpr` / `bench_riscvv_vs_scalar.lpr` 之前只看 `IsBackendAvailableOnCPU(...)`，随后直接 `SetActiveBackend(...)`，会在 `supported_on_cpu=True` 但 `dispatchable=False` 时静默 fallback 到别的 backend
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 先补 `TryActivateBenchmarkBackend(...)` 合同 red test，锁定 “CPU 支持但不可 dispatch 的 backend 必须被 benchmark helper 拒绝”
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.bench.pas` 新增共享 helper，并让 `AVX512/NEON/RISCVV` benchmark 程序统一走显式 activation 校验与 `try/finally ResetToAutomaticBackend`
- [x] 用 fresh `TTestCase_DispatchAPI`、fresh backend benchmark runner、fresh `NEON/RISCVV` O3 compile、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 31: dynamic register-backend identity drift closeout
- [x] 确认 `RegisterBackend(backend, dispatchTable)` 之前会原样存下 caller-supplied `dispatchTable.Backend / BackendInfo.Backend`，导致动态重注册时可以把某个 backend slot 的 table identity 漂到别的 backend id
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 和 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 先补 synthetic red，锁定 “`TrySetActiveBackend(requested)` / `GetSimdPublicApi.ActiveBackendId` 必须跟随注册槽位，而不是 stale table Backend field”
- [x] 将 `src/fafafa.core.simd.dispatch.pas` 的 `RegisterBackend` 收紧为以注册槽位 id 为唯一真相源，规范化写回 `Backend` / `BackendInfo.Backend` / canonical priority
- [x] 用 fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 32: hook-driven forced-selection postcondition closeout
- [x] 确认 `TrySetActiveBackend(requested)` 之前只检查前置谓词，dispatch-changed hook 若在通知阶段通过 `RegisterBackend(...)` 把 requested backend 改成 non-dispatchable，API 仍会误报 success
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 和 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 先补 synthetic red，锁定 “hook 二次重建后最终 active backend 已偏离 requested 时，`TrySetActiveBackend` 必须返回 False”
- [x] 将 `src/fafafa.core.simd.dispatch.pas` 的 `TrySetActiveBackend` 收紧为以后验最终 active backend 为准，而不是无条件返回 `True`
- [x] 用 fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 102: Windows evidence automation truth-source reconciliation
- [x] 审查 `collect_windows_b07_evidence` / `verify_windows_b07_evidence` / `finalize-win-evidence` / `win-evidence-via-gh` / runbook 的现态，确认 `SIMD-B20(candidate)` 描述的自动化链已在仓库内落地
- [x] 用 fresh release 入口复验 `verify_windows_b07_evidence.sh` 与 `BuildOrTest.sh finalize-win-evidence`，确认现有 canonical 证据可直接通过
- [x] 运行 `BuildOrTest.sh freeze-status`，确认剩余红项来自 “source newer than archived evidence”，不是 B20 自动化缺口
- [x] 回写 backlog / findings / progress / worker notes，关闭 `SIMD-B20(candidate)` 的真相源漂移
- **Status:** complete

### Phase 33: public ABI concurrent publication hardening
- [x] 确认 `GetSimdPublicApi` 之前直接暴露一块会被 `RebindSimdPublicApi` 原地 `FillChar + 逐字段重写` 的缓存表，控制面并发重绑时 reader 能读到 `StructSize=0` / `ActiveFlags=0`
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 先补并发 red，锁定 “public ABI metadata / shim pointer 在 vector-asm 重绑并发下不能出现 torn snapshot”
- [x] 将 `src/fafafa.core.simd.public_abi.impl.inc` 改成完整 snapshot + 原子发布，并让 shims 经当前 published state 取 bound fast-path；同步把旧 `same pointer across rebind` 测试收紧为 “cached snapshot 仍可调用，fresh getter 提供最新 metadata”
- [x] 用 fresh `TTestCase_SimdConcurrent,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 34: dispatch/direct concurrent publication hardening
- [x] 确认 `g_CurrentDispatch` 之前会直接指向或现拷会被 `RegisterBackend(...)` 原地覆写的 `g_BackendTables[backend]`，导致 `GetDispatchTable` / `GetDirectDispatchTable` 在并发重注册下可能暴露 mixed snapshot
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas` 新增 `TTestCase_DirectDispatchConcurrent` 并先补 synthetic red，锁定 “并发重注册时 direct/current dispatch 不能混读 A/B 两套槽位”
- [x] 将 `src/fafafa.core.simd.dispatch.pas` 改成 backend-level immutable publication：新增 published state，当前 active dispatch 与 backend 查询/clone 都只读已发布 snapshot，而不再直接读 mutable backend slot
- [x] 将新并发 suite 接入主 runner / gate parity，并用 fresh `TTestCase_DirectDispatchConcurrent`、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 35: public ABI backend pod snapshot consistency hardening
- [x] 确认 `TryGetSimdBackendPodInfo(...)` 之前会把 `CapabilityBits` 与 `Flags` 分别从不同 observation point 拼出来，导致并发 `RegisterBackend(...)` 切换同一 backend 时暴露 mixed POD snapshot
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TTestCase_SimdConcurrentPublicAbi` 并先补 synthetic red，锁定 “backend pod info 的 `CapabilityBits/Flags` 不能跨两个注册态混搭”
- [x] 将 `src/fafafa.core.simd.public_abi.impl.inc` 改为优先从单份 published backend snapshot 派生 `CapabilityBits`、`dispatchable` 与 registered-state priority，只把 `active` bit 留给当前 active dispatch 判定
- [x] 用 fresh `TTestCase_SimdConcurrentPublicAbi`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 36: framework current-backend-info snapshot consistency hardening
- [x] 确认 `GetCurrentBackendInfo` 之前直接做 `GetBackendInfo(GetActiveBackend)`，导致并发 `RegisterBackend(...)` 切换当前 active backend 时可能返回“不再是 current backend 的旧 id + 新 disabled metadata”
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TTestCase_SimdConcurrentFramework` 并先补 synthetic red，锁定 “current backend info 只能等于 enabled current info 或 disabled 后的真实 fallback current info”
- [x] 将 `src/fafafa.core.simd.framework.impl.inc` 的 `GetCurrentBackendInfo` 改为直接从 `GetDispatchTable` 的当前 published snapshot 取 `BackendInfo`
- [x] 用 fresh `TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 37: backend adapter unregistered metadata contract closeout
- [x] 确认 `src/fafafa.core.simd.backend.adapter.pas` 的 `GetBackendOps(backend)` 在未注册路径下只回写 `Result.Backend := backend`，但没有把 `Result.BackendInfo` 对齐到 canonical metadata
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas` 新增最小 red，锁定 “未注册 backend 的 `GetBackendOps` 仍必须保留 canonical `BackendInfo.Backend/Priority/Name`”
- [x] 将未注册路径收紧为直接 `Result.BackendInfo := GetBackendInfo(backend)`，避免 adapter 对外暴露 `BackendInfo.Backend=sbScalar`、`Priority=0` 的漂移
- [x] 用 fresh `TTestCase_DispatchAllSlots`、fresh `check`、fresh `gate` 复验，并保留 `public ABI` text getter 的 previous-pointer guard 作为附加绿护栏
- **Status:** complete

### Phase 38: dispatch selection and dispatchable-helper toggle snapshot hardening
- [x] 确认 `SetVectorAsmEnabled(False <-> True)` 并发窗口里，`GetBestDispatchableBackend` / `GetDispatchableBackendList` / `GetAvailableBackendList` 会暴露半重建中间态；同轮 red 也重新打出 `GetCurrentBackendInfo` 的 deeper root cause：`DoInitializeDispatch` 选中 backend 后仍从 mutable `g_BackendTables[...]` 复制 current snapshot
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 为 `TTestCase_SimdConcurrentFramework` 补 `Test_Concurrent_DispatchableHelpers_VectorAsmToggle_ReadConsistency`，锁定 “dispatchable helper 只能返回 enabled 全量态或 disabled 全量态，不能返回半重建中间态”
- [x] 将 `src/fafafa.core.simd.dispatch.pas` 的 current dispatch publication 改为复用 `GetPublishedBackendDispatchTable(LBestBackend)`，并让 `GetDispatchableBackends` / `GetBestDispatchableBackend` 在扫描期间持有 `g_VectorAsmToggleLock`
- [x] 用 fresh `TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 39: public API active metadata snapshot consistency hardening
- [x] 确认 `src/fafafa.core.simd.public_abi.impl.inc` 的 `RebindSimdPublicApi` 虽已先取 `GetDispatchTable` published snapshot，但旧实现仍用 `SimdBackendToAbiFlags(LDispatch^.Backend)` 做 live `registered/dispatchable/active` 查询，导致 `ActiveBackendId` 与 `ActiveFlags` 仍可能跨两个观察点混搭
- [x] 复用现有并发回归 `TTestCase_SimdConcurrentPublicAbi.Test_Concurrent_PublicApiActiveMetadata_RegisterBackend_ReadConsistency` 先拿 fresh red，而不是先补新测试
- [x] 将 `RebindSimdPublicApi` 的 `ActiveFlags` 收紧为直接基于同一份 `LDispatch^.BackendInfo` + `BuildSimdBackendAbiFlagsFromSnapshot(...)` 派生，确保 current public API metadata 只来自单份 current dispatch snapshot
- [x] 用 fresh `TTestCase_SimdConcurrentPublicAbi,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 40: registered backend list first-registration snapshot hardening
- [x] 确认 `src/fafafa.core.simd.framework.impl.inc` 的 `GetRegisteredBackendList` 之前采用“两遍扫描”：先数 `IsBackendRegisteredInBinary(...)` 的个数，再第二遍填充数组；在 previously-unregistered backend 首次 `RegisterBackend(...)` 的并发窗口里会暴露 impossible list snapshot
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TTestCase_SimdConcurrentRegistration.Test_Concurrent_RegisteredBackendList_FirstRegistration_ReadConsistency`，并把该 stateful suite 接入 `tests/fafafa.core.simd/fafafa.core.simd.test.lpr`
- [x] 将 `GetRegisteredBackendList` 收紧为“按 backend 总数预分配 -> 单遍扫描填充 -> 最后 shrink”，确保单次 helper 调用只基于一个 observation sequence 产出 registered list
- [x] 用 fresh `TTestCase_SimdConcurrentRegistration`、fresh `TTestCase_SimdConcurrentFramework` sanity、fresh `check`、fresh `gate` 复验
- **Status:** complete

## Key Questions
1. 当前 `simd` 模块最先暴露的问题是在主 gate、定向 suite，还是脚本/文档/代码契约不一致？
2. 是否存在可以用最小修改修复且具备回归测试价值的问题？
3. 哪些区域应该纳入下一轮连续审查，例如 dispatch、cpuinfo non-x86、public ABI、intrinsics 覆盖？

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 先用 `tests/fafafa.core.simd/BuildOrTest.sh check` 和关键 suite 做首轮审查 | 比全量严格 gate 更快，先拿到可操作证据 |
| 同时覆盖 `simd` 与 `simd.cpuinfo` 入口 | 文档显示这两层共享后端选择与门禁逻辑，问题容易跨层扩散 |
| 修复遵循 `systematic-debugging` + `test-driven-development` | 避免先改代码后找原因，确保每个修复都有失败-成功证据 |
| 把问题收敛到 runner parity 覆盖缺口 | 现有行为测试全绿，但 gate/parity 实际漏跑 `TTestCase_DirectDispatch`，这是门禁设计与实现不一致的真实风险 |
| runner parity 继续改成“动作集对账 + 显式 allowlist” | 手写签名列表容易漏掉新增 action；显式 shell-only / Windows-only 例外更稳 |
| public ABI external smoke 继续补 consumer-side 状态语义断言 | 文档承诺了 `supported_on_cpu / registered / dispatchable / active` 四层语义，但外部 harness 之前几乎没验证 `ActiveFlags` 和 active backend pod flags |
| benchmark 程序选择 backend 时也必须基于 dispatchable/active 语义，而不是只看 `IsBackendAvailableOnCPU` | `SetActiveBackend(...)` 在 backend 不可 dispatch 时会安全 fallback；如果 benchmark 不显式校验 active backend，就会把标签和实际测到的 backend 混在一起 |
| `RegisterBackend` 的注册槽位 id 必须覆盖 caller-supplied table identity | 动态重注册是当前实现允许的路径；如果继续信任 `dispatchTable.Backend / BackendInfo.Backend`，`TrySetActiveBackend` 与 public ABI `ActiveBackendId` 会被 stale metadata 带偏 |
| `TrySetActiveBackend` 的 success 语义必须以后验最终 active backend 为准 | dispatch-changed hook 允许在通知阶段触发动态重注册/重建；如果只做前置 gate，就会出现返回 success 但最终 active/public ABI 已偏离 requested 的假成功 |
| public ABI table 不能再原地 `FillChar + 重写` 发布 | `GetSimdPublicApi` 对外暴露的是可缓存的 POD table；只要控制面允许并发重绑，原地覆盖就会把 `StructSize/ActiveFlags/function pointers` 暴露成 torn snapshot，必须改成完整 snapshot + 原子发布 |
| current dispatch 与 direct/backend readers 也不能再从 mutable backend slot 取现态 | 只把 `g_CurrentDispatch` 改成 copy-out 还不够；如果复制源仍是会被 `RegisterBackend(...)` 原地覆写的 `g_BackendTables[...]`，并发 reader 仍能读到 mixed snapshot，必须把 backend slot 本身也升级成 immutable publication |
| `TryGetSimdBackendPodInfo` 不能再用多次 live 查询拼装单个 POD 结果 | public ABI backend pod struct 是稳定边界；如果 `CapabilityBits`、`dispatchable/registered` 等字段来自不同时间点，就会在并发 `RegisterBackend(...)` 下暴露自相矛盾的 metadata，必须优先从同一份 published backend snapshot 派生 |
| `GetCurrentBackendInfo` 不能再通过 `GetActiveBackend` 再 `GetBackendInfo(...)` 拼装 active 视图 | 这两个查询之间 current backend 可能已经被重注册重选；如果继续拆两步，framework 层就会返回“不再是 current backend 的旧 backend id + 新 disabled metadata”，必须直接从当前 dispatch snapshot 取 `BackendInfo` |
| alias 语义继续补“强制分叉”回归测试 | 普通机器上 `supported_on_cpu` 与 `dispatchable` 往往同向，若不主动把 `BackendInfo.Available=False` 造出来，future regression 很容易静默漏过 |
| public ABI 动态 flags 语义放在 Pascal regression test，而不是 external smoke | `RegisterBackend`/dispatch hook 驱动的即时重绑是进程内测试场景，external smoke 很难安全制造这个状态切换 |
| Windows public ABI batch runner 改成 `pwsh -> powershell` fallback 且 fail-close | `publicabi-smoke` 是文档和 gate 都承诺的 native Windows 验证层，找不到 runtime 时静默 `SKIP` 会制造假绿 |
| 把 Windows public ABI batch runner 守卫接入 `simd check` | 当前环境不能实跑 PowerShell，所以要用 Linux 可执行的静态 guard 持续守住 Windows 接线 |
| public ABI 子 runner 也必须遵守 `SIMD_OUTPUT_ROOT` 隔离语义 | 主 gate 文档已承诺并发/预演可用隔离根；如果 `publicabi-smoke` 继续写默认目录，就会在并发回归下污染产物并削弱证据链 |
| 隔离根下的 `clean` 必须同时覆盖顶层 `bin/lib` 与 `cpuinfo/cpuinfo.x86/publicabi` 子目录 | `run_all_tests` 会继承 `SIMD_OUTPUT_ROOT` 直接写顶层 `bin/lib`，而 direct 子 runner 会写子目录；只删 `bin2/lib2/logs` 不能形成真正的 clean 闭环 |
| `run_all_tests` 在继承 `SIMD_OUTPUT_ROOT` 时必须按模块拆分子根 | 否则 `fafafa.core.simd` / `cpuinfo` / `cpuinfo.x86` 会共享顶层 `logs/build.txt`，把 gate 证据文件互相覆盖，导致 artifact 自相矛盾 |
| Windows `run_all_tests.bat` 必须显式把 `RUN_ACTION` 传给各模块脚本 | `tests/fafafa.core.simd/buildOrTest.bat` 的 gate 已明确设置 `RUN_ACTION=check`；如果 batch 版过滤链裸 `call "%SCRIPT%"`，Windows gate 会静默回落到各模块默认 action，和 shell 版语义漂移 |
| `experimental-intrinsics-tests` 也必须遵守 `SIMD_OUTPUT_ROOT`，并使用独立 `intrinsics.experimental` 子根 | 这条 helper 会生成自己的 `bin/lib/logs` 与 smoke 源文件；如果继续写默认模块目录，就会破坏并发预演和 clean 闭环，和前面已经修好的 `publicabi` / `intrinsics.sse/mmx` 口径再次分叉 |
| Windows `experimental-intrinsics-tests` 在缺 `bash` 时必须 fail-close | `gate-strict` 把 experimental tests 视为 release-gate 组成部分；如果 batch 入口继续 `SKIP 0`，就会在 direct action 或手动打开 `SIMD_GATE_EXPERIMENTAL_TESTS=1` 时制造假绿 |
| Windows direct experimental batch runner 改成 canonical shell wrapper，而不是继续补第二套 native smoke 逻辑 | 文档和 roadmap 公开承诺的入口一直是 `BuildOrTest.sh`；direct batch runner 原先缺 `check_source_hygiene` 与多条 backend smoke，继续保留本地实现只会制造 direct batch 假绿 |
| Windows evidence collector 必须显式跑 native `publicabi-smoke`，且 verifier 要拒绝旧的 `6/6` 日志 | runbook 已明确承诺 native batch evidence 路径不会绕开 Windows 自己的 `publicabi-smoke`；如果 collector 只跑 6 步并且 verifier 继续接受旧日志，就会把缺关键 external smoke 的证据链误判为有效 |
| Windows `gate-summary-sample` / `gate-summary-rehearsal` / `gate-summary-inject` 在缺运行时时必须 fail-close | release candidate checklist 和 workflow 文档都把它们当成显式维护入口；如果 batch 版继续 `SKIP 0`，维护者会误以为样本/演练/注入已经执行成功 |
| Windows batch `qemu-*` direct actions 在缺 `bash` 时必须 fail-close，并由 shell `check` 持续守住 | 这些 action 已公开暴露在 batch usage 中，且 shell gate/release checklist 把对应 QEMU evidence 当成真实验证面；继续 `SKIP 0` 会把未执行的 non-x86 证据伪装成成功 |
| Windows batch `backend-bench` / `riscvv-opcode-lane` 这类显式 bash-wrapper helper 也必须 fail-close | 这两个 action 同样是 batch usage 公开暴露的维护入口，shell 侧实际依赖 `bash` 执行脚本；继续 `SKIP 0` 会把 benchmark/RVV lane 根本没跑的状态误判为成功 |
| `qemu-experimental-report` / `qemu-experimental-baseline-check` 在 shell/batch 两侧缺 Python 时都必须 fail-close | release candidate checklist 已把它们列为独立 helper 入口；继续 `SKIP 0` 会把 experimental asm 归因报告/基线校验根本没执行的状态误判为完成 |
| 主 `simd` runner 中被 `check` / `gate` 默认依赖的 Python checker 不能在缺运行时时 `SKIP 0` | `register-include`、`contract-signature`、`publicabi-signature`、`adapter-sync`、`coverage`、`wiring-sync` 等步骤本来就是默认护栏；缺 Python 仍返回成功会直接制造主门禁假绿 |
| Linux `publicabi` shell runner 的 `validate-exports` 不能在缺 `readelf/nm` 时 `SKIP 0` | `docs/fafafa.core.simd.publicabi.md` 把 `validate-exports` 和 `test` 明确描述为“校验导出符号”的显式入口；如果缺符号检查工具仍返回成功，就会把“导出校验没执行”伪装成通过 |
| 当显式开启 `SIMD_GATE_SUMMARY_JSON=1` 时，`gate-summary` 的 JSON 导出链必须 fail-close | workflow 和 release checklist 都把 JSON 导出描述为真实能力；缺 Python 仍返回 `0` 甚至继续打印 `json=...`，会把“未导出 machine-readable 摘要”伪装成成功 |
| 当显式开启 `perf-smoke` 时，Scalar backend 不能再以 `SKIP 0` 通过 | `gate-strict` / `evidence-linux` / release checklist 都把 perf-smoke 当成 closeout 证据；如果 active backend 仍是 Scalar，就说明没有拿到 SIMD 性能证据，继续返回成功会把 gate 摘要误写成 `perf-smoke | PASS` |
| Linux `evidence-linux` collector 与其内部 `backend-bench` 子步骤都必须遵守 `SIMD_OUTPUT_ROOT` | checklist / maintenance / closeout 文档已经把 `SIMD_OUTPUT_ROOT=/tmp/... bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux` 作为并发/预演入口；如果 evidence bundle 仍写默认 `logs/evidence-*`、backend-bench 仍写默认 `logs/backend-bench-*`，就会继续污染默认证据目录并破坏隔离 dry-run 契约 |
| public ABI backend text getter 不能把第一次观察到的 `Name/Description` 永久缓存 | `RegisterBackend(...)` 已经是被测试和实现允许的动态刷新路径；如果 `GetSimdBackendNamePtr` / `GetSimdBackendDescriptionPtr` 仍固定返回首个缓存值，就会让外部 consumer 看到的 backend text 与当前 `BackendInfo` 漂移 |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| `parity-suites` / gate 的 cross-backend parity 实际重复执行 `TTestCase_DispatchAPI`，未覆盖 `TTestCase_DirectDispatch` | 1 | 先用 `rg -n "TTestCase_DirectDispatch" tests/fafafa.core.simd/BuildOrTest.sh tests/fafafa.core.simd/buildOrTest.bat` 做失败检查，再修 shell/bat runner 并复验 `check`、`parity-suites`、`gate` |
| `check_windows_runner_parity` 只检查手写签名，无法感知 shell/bat action 集差集 | 1 | 先用动作集静态检查显式打红，再把 parity checker 改成集合对账并声明 shell-only/Windows-only allowlist，最后重跑 `check` |
| public ABI external smoke 没有消费 `ActiveFlags`，也没把 active backend pod flags 和 `GetSimdPublicApi` 返回的元数据做外部对账 | 1 | 先用静态检查把 `publicabi_smoke.c` / `.ps1` 的 coverage 缺口打红，再补 consumer-side 断言并重跑 Linux external smoke 与主 `gate` |
| `supported_on_cpu` 与 `dispatchable` 的分叉场景没有被现有 suite 主动造出来 | 1 | 先用静态检索确认现有测试没有把 `BackendInfo.Available=False` 与 alias 视图断言连起来，再补 `DispatchAPI` 回归测试并重跑 suite/gate |
| benchmark 程序只看 `IsBackendAvailableOnCPU(...)` 就直接 `SetActiveBackend(...)`，会在 CPU 支持但 backend 不可 dispatch 时静默 fallback | 1 | 先在 `DispatchAPI` 引入 `TryActivateBenchmarkBackend(...)` 的 red test，故意制造 `supported_on_cpu=True` 但 `BackendInfo.Available=False` 的 synthetic split；随后在 `fafafa.core.simd.bench.pas` 实现共享 activation helper，并让 `AVX512/NEON/RISCVV` bench 程序统一走 helper，最后重跑 fresh `DispatchAPI`、fresh backend bench runner、fresh `check`、fresh `gate` |
| public ABI Pascal tests 没有验证 `RegisterBackend -> reselect -> RebindSimdPublicApi` 这条即时刷新链 | 1 | 先用静态检查确认 `publicabi` testcase 没覆盖 `RegisterBackend/ActiveFlags` 动态场景，再补最小回归测试并重跑 `TTestCase_PublicAbi` 与主 `gate` |
| Windows public ABI batch runner 只探测 `powershell`，且找不到时会把 `validate-exports` / `test` 静默当成 `SKIP 0` | 1 | 先用静态审查确认主 batch `publicabi-smoke` 会吃到这个假绿，再把 runner 改成 `pwsh -> powershell` fallback + fail-close，并在 `simd check` 里补静态 guard 后重跑 `check` / `gate` |
| `SIMD_OUTPUT_ROOT` 只隔离了主 runner 与 `cpuinfo` 子 runner，`publicabi-smoke` 仍固定写默认目录 | 1 | 先用静态检查把 `publicabi` 父/子 runner 的隔离缺口打红，再为 shell/batch 两侧补 `OUTPUT_ROOT`/子目录传播，并用 isolated `publicabi-smoke`、fresh `check`、fresh `gate` 复验 |
| 主 `clean` 在隔离根下只删 `bin2/lib2/logs`，没清掉顶层 `bin/lib` 和 `cpuinfo/cpuinfo.x86/publicabi` | 1 | 先用 fresh `gate -> clean -> find` 复现残留，再把 shell/batch `clean` 扩到完整隔离产物集，并在 `check` / `build-check` 里补 `check_isolated_clean_coverage` 守卫 |
| `run_all_tests` 过滤链在继承 `SIMD_OUTPUT_ROOT` 时会把 simd 系模块的顶层 `logs/build.txt` 互相覆盖 | 1 | 先用 fresh `gate` 复现顶层 `build.txt` 被 `cpuinfo.x86` 覆盖、而 `test.txt` 仍停留在 `simd` suite 的证据错位，再把 `run_all_tests.sh/.bat` 改成按模块写入 `run_all/<module>/`，补 `check_run_all_output_isolation`，最后重跑 `check` / `gate` / `clean` 闭环 |
| `tests/run_all_tests.bat` 忽略 `RUN_ACTION`，导致 Windows filtered run_all 静默回退到模块默认 action | 1 | 先用静态检查确认 batch 版仍是裸 `call "%SCRIPT%"`、而 shell 版已有 `RUN_ACTION:-test` 转发，再修改 `tests/run_all_tests.bat` 计算 `ACTION` 并显式传参，同时在 `tests/fafafa.core.simd/BuildOrTest.sh` 扩充 `check_run_all_output_isolation` 守卫，最后重跑 fresh `check` / fresh `gate` |
| `experimental-intrinsics-tests` 忽略 `SIMD_OUTPUT_ROOT`，仍把 smoke 源和 `bin/logs` 写回默认模块目录 | 1 | 先用 `SIMD_OUTPUT_ROOT=/tmp/... bash tests/fafafa.core.simd/BuildOrTest.sh experimental-intrinsics-tests` 复现“隔离根只有 `bin2/lib2/logs`、但默认 experimental `logs/*.pas` 与 `test.txt` 被改写”的证据，再修主 shell/batch 传播和 experimental shell/batch 子 runner，补 `check_experimental_intrinsics_output_isolation` 与 clean 覆盖，最后重跑 direct action、fresh `check`、`clean -> find` |
| `tests/fafafa.core.simd/buildOrTest.bat` 的 `experimental-intrinsics-tests` 在缺 `bash` 时静默 `SKIP 0` | 1 | 先用静态检查确认 batch 入口仍保留 `echo [EXPERIMENTAL-TESTS] SKIP (bash not found)`，并结合 `gate-strict` 明确设置 `SIMD_GATE_EXPERIMENTAL_TESTS=1` 的事实收敛为假绿入口，再改成 fail-close，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_windows_experimental_tests_runner_guard`，最后重跑静态复验与 fresh `check` |
| `tests/fafafa.core.simd.intrinsics.experimental/buildOrTest.bat` 自己实现 `check/test/test-all`，缺 shell runner 的 hygiene 与 backend smoke 语义 | 1 | 先确认文档只承诺 `BuildOrTest.sh` 为 canonical 入口，再把 direct batch runner 改成 shell wrapper，新增 `check_windows_experimental_direct_runner_guard` 禁止回退到弱语义 native path，最后重跑 fresh `check` |
| `collect_windows_b07_evidence.bat` 声称 native batch evidence 不绕开 `publicabi-smoke`，但实际 6 步 collector 没有这一步，两个 verifier 还继续接受旧 `6/6` 日志 | 1 | 先用静态检查确认 collector 缺 `publicabi-smoke` 调用、verifier 只认 `6/6 Filtered run_all chain`，再把 collector 升为 `1/7..7/7` 并插入 native `publicabi-smoke`，同步更新 shell/batch verifier 和主 `check` 的 Windows evidence guard，最后重跑 fresh `check` |
| `tests/fafafa.core.simd/buildOrTest.bat` 的 `gate-summary-sample` / `gate-summary-rehearsal` / `gate-summary-inject` 在缺 python/bash 时静默 `SKIP 0` | 1 | 先用静态检查确认这些显式 helper 入口仍保留 `SKIP` 文案，再改成 fail-close，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_windows_gate_summary_helper_guard`，最后重跑 fresh `check` |
| `tests/fafafa.core.simd/buildOrTest.bat` 的 7 个 `qemu-*` direct actions 在缺 `bash` 时静默 `SKIP 0` | 1 | 先用静态检查确认 `qemu-nonx86-evidence` / `qemu-cpuinfo-*` / `qemu-arch-matrix-evidence` / `qemu-nonx86-experimental-asm` 都沿用同一套 `SKIP` 逻辑，再抽出统一 helper 改成 fail-close，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_windows_qemu_runner_guard`；首次 fresh `check` 暴露旧 parity 签名仍要求 `QEMU SKIP` 文案，随后同步更新 `check_windows_runner_parity` 后复验通过 |
| `tests/fafafa.core.simd/buildOrTest.bat` 的 `backend-bench` / `riscvv-opcode-lane` 在缺 `bash` 时静默 `SKIP 0` | 1 | 先用文档和 usage 确认这两个 action 是显式维护入口，再把 batch 侧改成共享 helper 的 fail-close 语义，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_windows_bash_helper_runner_guard`；同步更新 `check_windows_runner_parity` 的 bench/RVV 签名后重跑 fresh `check` 通过 |
| `qemu-experimental-report` / `qemu-experimental-baseline-check` 在 shell/batch 两侧缺 Python 时静默 `SKIP 0` | 1 | 先用 release candidate checklist 确认它们是显式 helper 入口，再把 shell runner 改成 `python3` 缺失时 `return 2`、batch runner 改成 `py/python` 都缺失时 `exit /b 2`，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_qemu_experimental_python_helper_guard`；首次 fresh `check` 因 guard 自己持有旧 `SKIP` 字符串而假红，随后把检查范围收窄到真实函数体后复验通过 |
| `check` / `gate` 默认依赖的 Python checker 在 shell/batch 两侧缺运行时时静默 `SKIP 0` | 1 | 先用 checklist/maintenance/closeout 文档确认这些 checker 是默认护栏，再把 shell 的 `run_register_include_check`、`run_interface_completeness`、`run_dispatch_contract_signature`、`run_public_abi_signature`、`run_backend_adapter_sync`、`run_coverage`、`run_intrinsics_experimental_status`、`run_wiring_sync` 全部改成缺 `python3` 时 fail-close，batch 对应 action 改成 `py/python` 都缺失时 fail-close，并新增 `check_python_checker_runtime_guard`；fresh `check` 通过，说明主门禁已不再允许这批步骤假绿 |
| `tests/fafafa.core.simd.publicabi/BuildOrTest.sh` 的 `validate-exports` 在缺 `readelf/nm` 时静默 `SKIP 0` | 1 | 先用 `docs/fafafa.core.simd.publicabi.md` 确认该入口公开承诺“校验导出符号”，再把 shell publicabi runner 改成缺符号检查工具时 fail-close，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_publicabi_shell_export_guard`；随后重跑 main `check` 与 direct `publicabi validate-exports`，均通过 |
| `gate-summary` 的 JSON 导出链在 shell/batch 两侧缺 Python 时静默成功，shell 还会继续打印 `json=...` | 1 | 先用 workflow/checklist 和 runner 函数体确认 `SIMD_GATE_SUMMARY_JSON=1` 是显式 helper 契约，再把 shell/batch JSON 导出都改成 fail-close、给 `run_gate_summary` 补 `|| return $?`、新增 `check_gate_summary_json_runtime_guard`，最后重跑 fresh `check` 与 direct 正/负向 `gate-summary` 验证 |
| `perf-smoke` 在 shell/batch/Python 三处都把 Scalar backend 当成 `SKIP 0`，会让 `gate-strict` / `evidence-linux` 把缺失的性能证据记成通过 | 1 | 先用 workflow/checklist 与 `run_gate_step` 语义确认 perf-smoke 是显式 closeout 证据，再把 shell `check_perf_log`、batch `:perf_smoke`、`check_perf_smoke_log.py` 全部改成 Scalar 时 fail-close，并新增 `check_perf_smoke_scalar_guard`，最后重跑 fresh `check` 与 synthetic Scalar perf log 负向验证 |
| `evidence-linux` 的 evidence bundle 与 `backend-bench` 子产物都忽略 `SIMD_OUTPUT_ROOT`，会把 `/tmp/...` dry-run 写回默认 `tests/fafafa.core.simd/logs` | 1 | 先用 isolated `evidence-linux` 复现默认 `logs/evidence-*` 与 `logs/backend-bench-*` 被新建，再把 `collect_linux_simd_evidence.sh` 与 `run_backend_benchmarks.sh` 接入 `OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${SCRIPT_DIR}}"`，新增 `check_linux_evidence_output_isolation`，最后重跑 fresh `check`、isolated `backend-bench`、isolated `evidence-linux` 与 `clean -> find` 复验 |
| x86 backend capability metadata 低报 `scIntegerOps`，导致 `BackendInfo.Capabilities` 与 public ABI `CapabilityBits` 对外少报真实整数操作族 | 1 | 先在 `TTestCase_DispatchAPI` 补 underclaim 回归测试，用代表性整数槽位非 scalar 作为证据；随后最小补齐 `SSE2/SSE2-i386/SSE3/AVX2/AVX512` 的 capability set，并重跑 fresh `TTestCase_DispatchAPI`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` |
| `src/fafafa.core.simd.sse2.pas` 的注册表 raw priority 仍写死旧值 `10`，与 canonical priority `30` 发生 contract 漂移；首次修复还因漏引 `fafafa.core.simd.backend.priority` 导致编译失败 | 1 | 先在 `TTestCase_DispatchAPI` 补 `Test_RegisteredBackendPriority_MatchesCanonicalPriority`，再把 `SSE2` raw priority 改为 `GetSimdBackendPriorityValue(sbSSE2)`；首次 fresh `DispatchAPI/check/gate` 因 `Identifier not found \"GetSimdBackendPriorityValue\"` 失败，随后给 `src/fafafa.core.simd.sse2.pas` 补 `backend.priority` 依赖并重跑 fresh `DispatchAPI`、fresh `check`、fresh `gate` 全部通过 |
| runtime 关闭 `vector asm` 后，受该开关控制的 x86 backend 仍继续宣称 `scIntegerOps`，即使代表性整数槽位已经全部退回 scalar | 1 | 先在 `TTestCase_DispatchAPI` 补 `Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled` 打红；确认根因后，把 `SSE2/SSE2-i386/SSE3/SSSE3/SSE41/SSE42/AVX2` 的 `scIntegerOps` 宣称改为跟随实际 `vector asm` gate，再重跑 fresh `DispatchAPI`、fresh `check`、fresh `gate` 全部通过 |
| `AVX2` 在当前 CPU/OS 上已经走 fused `vfmadd*`，但注册表仍低报 `scFMA`，导致 `BackendInfo.Capabilities` 与 public ABI `CapabilityBits` 对外少报真实 fused-FMA 能力 | 1 | 先在 `TTestCase_DispatchAPI` 补 `Test_AVX2_BackendCapabilities_Expose_FMA_When_FusedPathUsable` / `Test_AVX2_BackendCapabilities_Clear_FMA_When_VectorAsmDisabled`，用 fused witness 证明当前 AVX2 FMA 槽位已经是硬件 fused 路径；随后把 `src/fafafa.core.simd.avx2.register.inc` 的 `scFMA` 改为跟随 `vector asm + gfFMA` gate，并重跑 fresh `DispatchAPI`、fresh `check`、fresh `gate` |
| `AVX2` 在 `vector asm` 打开时已经把 `Select/Insert/Extract` 等代表性 shuffle 槽位接到原生实现，但 capability/public ABI 仍低报 `scShuffle` | 1 | 先在 `TTestCase_DispatchAPI` 与 `TTestCase_PublicAbi` 分别补 `...Expose_Shuffle...` red test，确认内部 `BackendInfo.Capabilities` 与外部 `CapabilityBits` 同时少报；随后把 `src/fafafa.core.simd.avx2.register.inc` 的 `scShuffle` 改为跟随 `LEnableVectorAsm`，并重跑 fresh `DispatchAPI`、fresh `PublicAbi`、fresh `check`、fresh `gate` 全部通过 |
| `SetVectorAsmEnabled(True -> False)` 后，已重建成 scalar-backed/fallback 的 backend 仍保留 `BackendInfo.Available=True`，导致 `GetCurrentBackend` / public ABI `ActiveBackendId` 停留在旧 backend id | 1 | 先在 `DispatchAPI/PublicAbi` 补 red tests，锁定 “scalar-backed backend must not remain dispatchable/active” 的合同；随后把 `SSE2/SSE2-i386/SSE3/SSSE3/SSE41/SSE42/AVX2` 的 `Available` 改为跟随 `vector asm` gate，把 `AVX512` 改为 `isAvailable and LEnableVectorAsm`，把 `NEON/RISCVV` 改为 `(not LAsmCapable) or LUseVectorAsm`，并同步把 smoke/public smoke 改成 dispatchable 语义；最终 fresh targeted suite、fresh `check`、fresh `gate` 全部通过 |
| `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas` 手写的默认 backend 预测逻辑只覆盖 `SSE2/AVX2`，当 `AVX2` 被 runtime state 降成 non-dispatchable 而 `SSE4.2` 仍 dispatchable 时会把外部 smoke 误算成 `SSE2` | 2 | 先抽出共享 predictor helper 并在 `DispatchAPI` 里补 red test，显式制造 `AVX2 -> non-dispatchable` / `SSE4.2 -> dispatchable` 的分叉场景；随后把 helper 改为直接复用 `GetBestDispatchableBackend`，再用 fresh `DispatchAPI`、standalone `public_smoke` 编译/运行、fresh `check`、fresh `gate` 全部通过 |
| dispatch-only consumer 在首次 dispatch 初始化之前调用 `SetVectorAsmEnabled(False)` 时，`g_DispatchState=0` 直接短路，导致 unit initialization 时已发布的 backend table 不会重建，`GetBestDispatchableBackend/GetActiveBackend` 仍可能选中 `AVX2/SSE*` | 2 | 先在 `tests/fafafa.core.simd` 新增 standalone pre-init smoke 并把它接入 shell/batch `check` 与 shell `gate` build-check，fresh red 命中 `Best dispatchable backend should be Scalar ... got AVX2`；随后把 `src/fafafa.core.simd.dispatch.pas` 的 `RebuildBackendsAfterFeatureToggle` 改成接受“是否立即重新初始化 dispatch”参数，让 pre-init toggle 也会重建 backend table，但不提前初始化 dispatch；最终 fresh green `check`、fresh external standalone probe、fresh `gate` 全部通过 |
| public ABI backend text getter 在 `RegisterBackend(...)` 动态重注册后仍返回旧 `Name/Description` | 1 | 先在 `TTestCase_PublicAbi` 新增 red，用 `GetSimdBackendNamePtr/GetSimdBackendDescriptionPtr` 先 prime cache，再重注册当前 backend 并断言 getter 必须跟随新文本；确认 `GetBackendInfo(...)` 已经更新、问题只在 public ABI cache 后，把 `EnsureBackendTextCache` 改成每次都从最新 backend metadata 刷新，最后重跑 fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` |
| direct/current dispatch 并发修复第一版只把 active snapshot 改成 copy-out publication，但 red 仍存在 | 1 | 回到并发 red 读数，确认 mixed snapshot 仍来自复制源 `g_BackendTables[...]` 被另一个 writer 原地改写；随后补 backend-level immutable published state，并把 backend info/query/clone 全部切到 published snapshot |
| 并发 red 初版在 helper 抽离时把 testcase 断言留在非 testcase 上下文里，导致编译失败 | 1 | 收口为 worker 只记录 mixed-state 证据，由 testcase 统一断言和报错；随后重新跑 targeted suite 拿到真正的并发 red |
| `public_abi.impl.inc` 初版修复想直接调用 `GetSimdBackendPriorityValue(...)`，但当前 include 作用域拿不到该符号，导致编译失败 | 1 | 改成 registered 路径直接复用 `LDispatchTable.BackendInfo.Priority`，未注册路径退回 `GetBackendInfo(aBackend).Priority`；既避免额外可见性耦合，也继续保证 priority 不会重新回到 mixed-snapshot 拼装 |
## Notes
- 2026-03-21 最新 dispatch selection / dispatchable helper toggle closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework` -> FAIL
  - red 失败点同时命中两条同区问题：
    - `current backend info mixed snapshot at iter 2224: got=(backend=6 available=False caps=0 priority=80 name=AVX2) expectedA=(backend=6 available=True caps=447 priority=80 name=AVX2) expectedB=(backend=5 available=True caps=415 priority=70 name=SSE4.2)`
    - `dispatchable helper mixed snapshot at iter 0: got=[1,0] expectedEnabled=[6,5,4,3,2,1,0] expectedDisabled=[0]`
    - `best dispatchable backend mixed snapshot at iter 13: got=1 expectedEnabled=6 expectedDisabled=0`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 23:04:43`
- 这轮证明 current-dispatch mixed snapshot 之前并没有真正彻底收口：虽然 selection 已改成看 published backend state，但 `DoInitializeDispatch` 仍在最后一步从 mutable `g_BackendTables[LBestBackend]` 复制 current snapshot；只要 writer 在“选中 backend”和“复制 current snapshot”之间完成重注册，reader 仍会看到旧 backend id + 新 disabled metadata。
- 同时，dispatchable helper 也存在 toggle-only 的 reader 合同缺口：`GetDispatchableBackends` / `GetBestDispatchableBackend` 在 `SetVectorAsmEnabled` 顺序重建各 backend 时无锁 live 扫描，会把 `SSE2/SSE3/...` 这类仅存在于 enable 过程中的半重建中间态直接对外暴露。
- 最小修复没有再引入新的全局 snapshot 结构，而是复用了当前已有的控制面同步点和 backend publication：
  - current dispatch 改为从 `GetPublishedBackendDispatchTable(LBestBackend)` 发布
  - dispatchable list/best helper 在扫描期间与 `SetVectorAsmEnabled` 共享 `g_VectorAsmToggleLock`
- 2026-03-21 最新 backend adapter unregistered metadata closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots` -> FAIL (`GetBackendOps should preserve BackendInfo.Backend for unregistered backend=7 expected: <7> but was: <0>`)
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 22:31:18`
- 这轮根因不是 dispatch slot 映射缺失，而是 adapter helper 在“无注册态”上手工拼装了一个不完整结果：`ClearBackendOps(Result)` 之后只把顶层 `Backend` 回写成 requested backend，`BackendInfo` 仍停在默认零值，于是对外把 `sbAVX512/sbNEON/sbRISCVV` 等 canonical metadata 漂成 `sbScalar/priority=0`。
- 最小修复是复用现有 canonical metadata source，而不是再复制一份 adapter 专属默认值：未注册路径直接 `Result.BackendInfo := GetBackendInfo(backend)`，从而把 `Backend/Priority/Name/Description` 一次性对齐到 shared contract。
- 这轮顺手加了 `TTestCase_PublicAbi.Test_PublicAbi_BackendText_Getters_PreviousPointers_RemainValid_After_Refresh` 作为附加护栏；当前环境它是绿的，没有 fresh red，因此不把它记成本轮主问题 closeout。
- 2026-03-20 最新 non-x86 registration/capability closeout 证据：
  - red: `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-red2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL (`NEON should not advertise scShuffle when only scalar fallback shuffle slots are compiled`)
  - red: `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-red2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL (`RISCVV should not advertise scFMA when only scalar fallback FMA slots are compiled`)
  - green: `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS
  - green: `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS
  - green: `SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260320-nonx86-registration-fixes bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS
- 2026-03-20 最新 non-x86 capability symmetry closeout 证据：
  - red: `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-red3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL (`NEON should not advertise scFMA when only scalar/common fallback FMA slots are compiled`)
  - red: `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-red3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL (`RISCVV should not advertise scShuffle when only scalar/common fallback shuffle slots are compiled`)
  - green: `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-green3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS
  - green: `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-green3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS
  - green: `SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260320-nonx86-cap3 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS
- 新确认的根因不是单纯 capability bit 本身，而是 opt-in runner 之前只把 `SIMD_BACKEND_NEON` / `SIMD_BACKEND_RISCVV` 编进测试二进制，却没有绕过各 backend `native CPU only` 的 initialization guard；结果 `TryGetRegisteredBackendDispatchTable(sbNEON/sbRISCVV)` 在 x86_64 opt-in build 里直接失败，旧测试会静默 `Exit`，看起来像“验证通过”。
- 本轮已给 shell/batch runner 都补上 `FAFAFA_SIMD_TEST_REGISTER_NEON_BACKEND` / `FAFAFA_SIMD_TEST_REGISTER_RISCVV_BACKEND`，并让 `neon.register.inc` / `riscvv.register.inc` 在测试专用 define 下把 scalar/common fallback 版本注册进 dispatch，因此 opt-in suite 现在真的能覆盖 backend pod info 和 capability contract，而不只是编译成功。
- 真正跑到注册态后，确认四条 non-x86 对称 capability 里已有四处真实过报风险，其中本轮新增收敛的是 `NEON scFMA` 与 `RISCVV scShuffle`；现在 `NEON scShuffle/scFMA` 与 `RISCVV scFMA/scShuffle` 都改为跟随真实 asm 可用性。
- 继续沿 runtime toggle / rebuild 合同往下查，又确认 `NEON/RISCVV` 与 x86 backend 不同：它们的 asm/fallback 主要还是编译期单路径，而 register.inc 之前又完全不看 `IsVectorAsmEnabled`；这会让 native asm build 在 `SetVectorAsmEnabled(False)` 之后继续保留旧 asm dispatch / capability。
- 本轮已把 `src/fafafa.core.simd.neon.register.inc` 与 `src/fafafa.core.simd.riscvv.register.inc` 改成：
  - 非 asm build 继续保留当前 fallback 注册路径，不影响现有 opt-in suite
  - asm build 且 runtime disabled 时，重建为 scalar-backed table，并清掉 `scFMA/scShuffle` 这些 vector-asm gated bits
  - 同时补了 native-only `DispatchAPI/PublicAbi` regression tests 守住这条合同
- 当前宿主机仍是 x86_64，因此这轮只能 fresh 证明“默认主线和 non-x86 opt-in fallback 路径没有回归”；新加的 native-only `NEON/RISCVV` runtime-toggle tests 还需要后续在 arm64 / riscv64 asm-ready 主机上拿 execution evidence。
- 2026-03-20 最新 non-x86 opt-in closeout 证据：
  - `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-optin-suite-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS
  - `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-optin-suite-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS
  - `SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260320-nonx86-optin-fixes bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS
- `RISCVV` 本轮根因是 `src/fafafa.core.simd.riscvv.facade.inc` 把 `{$ENDIF}` 提前写在 `{$ELSE}` 之前且文件尾缺少真正的收口，导致 opt-in build 直接死在预处理阶段。
- `NEON` 本轮根因是 `src/fafafa.core.simd.neon.pas` / `src/fafafa.core.simd.neon.scalar_fallback.inc` / `src/fafafa.core.simd.neon.scalar.wide_reduce.inc` 之间依赖跨 include 偷闭合 `FAFAFA_SIMD_NEON_ASM_ENABLED`，同时 `wide_reduce.inc` 自己缺 `{$ENDIF}`，最终在 opt-in build 上以 `Unexpected end of file` 爆出。
- 下一轮连续计划优先级已更新为：
  1. 补 fresh Windows native `1/7..7/7` evidence，清掉 closeout 中唯一仍是 optional `SKIP` 的历史证据缺口
  2. 在 arm64 / riscv64 asm-ready 主机上执行新加的 native-only `NEON/RISCVV` runtime-toggle tests，回收真实 execution evidence，而不只停留在 x86_64 compile/regression 证据
  3. 评估是否把 `NEON/RISCVV` opt-in 验证面从当前定向 suite 继续扩到 `check` / `list-suites` / 更小粒度 gate，并补静态 guard 防止 test-only registration define 从 runner 接线中再次丢失
- 完成每个阶段后更新状态与验证证据
- 如果连续三次修复假设失败，停止堆补丁并重新评估架构/边界
- 本轮 closeout 以 fresh isolated `evidence-linux` 全链路结果作为最终收口标准；单独的 `perf-smoke` 或 `freeze-status-linux` PASS 不能证明 closeout 真正闭环，必须同时看到 `gate PASS`、`qemu-cpuinfo-nonx86-evidence PASS` 和 `freeze-status ready=True`
- `perf-smoke` 的 public ABI hot-path 误报已收敛：先用静态 guard 把 benchmark 形状锁成 local-cache hot-loop，再把 benchmark 改成 inner loop + rotated sampling，最后把 Python checker 收敛到稳定的 `PubGet > DispGet` 契约；`PubCache < PubGet` 继续保留为观测项
- `freeze-status-linux` 的隔离输出也已收敛：`run_freeze_status()` 默认改用当前 `LOG_DIR`，并优先消费本轮 `GATE_SUMMARY_LOG`；`collect_linux_simd_evidence.sh` 同时显式传入 freeze summary/json 路径，避免 evidence 收尾时误读默认目录里的旧 gate summary
- 2026-03-20 最新 fresh closeout 证据：`SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-escalated-full-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux` 在提权环境下 `rc=0`；`gate PASS @ 2026-03-20 12:36:58`，`qemu-cpuinfo-nonx86-evidence PASS`，`freeze-status ready=True`
- 当前剩余非阻塞项不是 Linux 代码回归，而是 Windows 历史 evidence 日志在本轮 Linux closeout 中只被记为 optional `SKIP`；下一轮应补 fresh native Windows `1/7..7/7` evidence，避免继续依赖旧 `windows_b07_gate.log`
- AVX-512 CPU 谓词回归现在已接入主 `simd` runner 的默认 x86_64 可达路径：纯逻辑测试已拆到 `TTestCase_X86BackendPredicates`，而真正依赖 backend 编译接线的 `TTestCase_AVX512BackendRequirements` 仍只在 `SIMD_BACKEND_AVX512` 打开时出现
- x86 backend 实现层刚确认并修复了一条真实 wiring 缺陷：`src/fafafa.core.simd.sse42.register.inc` 之前直接 `FillBaseDispatchTable`，没有继承 `SSE4.1`，导致强制 `sbSSE42` 时大量高价值槽位静默退回 scalar；现已改为 `SSE41 -> SSSE3 -> SSE3 -> SSE2 -> scalar` 逐级 clone fallback，并补入 `TTestCase_DispatchAllSlots.Test_SSE42_Inherits_SSE41_DispatchSlots`
- `BackendInfo.Capabilities` 不是装饰字段：`TryGetSimdBackendPodInfo` 会把它直接位图化成 public ABI `CapabilityBits`，所以 capability underclaim / overclaim 都会影响外部 consumer
- x86 capability drift 第一批已收敛：`SSE2/SSE2-i386/SSE3/AVX2/AVX512` 现在都补上了 `scIntegerOps`，并由 `TTestCase_DispatchAPI.Test_BackendCapabilities_DoNotUnderclaim_IntegerOps` 守住
- x86 priority drift 第二批也已收敛：`SSE2` 注册表里的 `BackendInfo.Priority` 不再写死 `10`，现在直接取 `GetSimdBackendPriorityValue(sbSSE2)`，并由 `TTestCase_DispatchAPI.Test_RegisteredBackendPriority_MatchesCanonicalPriority` 守住
- x86 capability drift 第三批也已收敛：runtime 关闭 `vector asm` 后，`SSE2/SSE2-i386/SSE3/SSSE3/SSE41/SSE42/AVX2` 不再继续高报 `scIntegerOps`；这条现在由 `TTestCase_DispatchAPI.Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled` 守住
- x86 capability drift 第四批已收敛：当 `vector asm` 打开且 `gfFMA` 可用时，`AVX2` 现在会对外宣称 `scFMA`；关闭 `vector asm` 后该 capability 也会同步清除。这两条现在分别由 `TTestCase_DispatchAPI.Test_AVX2_BackendCapabilities_Expose_FMA_When_FusedPathUsable` 与 `...Clear_FMA_When_VectorAsmDisabled` 守住
- x86 capability drift 第五批已收敛：当 `vector asm` 打开且 `AVX2` 的代表性 `Select/Insert/Extract` shuffle 槽位已经脱离 scalar 时，`scShuffle` 现在也会同步对外宣称；关闭 `vector asm` 后该 capability 会清除。这条分别由 `TTestCase_DispatchAPI.Test_AVX2_BackendCapabilities_Expose_Shuffle_When_NativeShuffleSlotsUsable`、`...Clear_Shuffle_When_VectorAsmDisabled`，以及 `TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2Shuffle_WhenNativeSlotsPresent` 守住
- x86 runtime rebuild drift 第六批已收敛：`SSE3/SSSE3/SSE41` 现在都会注册 `RegisterBackendRebuilder(...)`，`SSSE3/SSE41/SSE42` 的 `scShuffle` 也改为跟随 `IsVectorAsmEnabled`；`TTestCase_DispatchAPI.Test_X86_BackendCapabilities_Clear_Shuffle_When_VectorAsmDisabled` 与 `TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_X86Shuffle_WhenVectorAsmDisabled` 已守住 `True -> False` feature-toggle 重建路径
- x86/non-x86 dispatch identity drift 第七批已收敛：当 runtime `SetVectorAsmEnabled(True -> False)` 让 backend 重建成 scalar-backed table 时，它现在不会再继续保留 `Available=True`。`SSE2/SSE2-i386/SSE3/SSSE3/SSE41/SSE42/AVX2` 已改为跟随 `vector asm` gate，`AVX512` 改为 `isAvailable and LEnableVectorAsm`，`NEON/RISCVV` 改为仅在 native asm build runtime-disabled 时清掉 `Available`；`TTestCase_DispatchAPI.Test_VectorAsmDisabled_ReSelects_Away_From_ScalarBacked_CurrentBackend` 与 `TTestCase_PublicAbi.Test_PublicApi_Refreshes_WhenVectorAsmDisabled_ReSelects_Away_From_ScalarBacked_CurrentBackend` 已守住 active backend/public ABI 重新选主合同
- 2026-03-21 最新 stale active-backend closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-active-backend-red-rerun-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（`Scalar-backed backend should not remain dispatchable after vector asm disable` / `Vector-asm-disabled reselection should move away from scalar-backed original backend`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-active-backend-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-active-backend-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-active-backend-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 03:14:15`
- AVX-512 opt-in 证据链已补齐到主 runner：`tests/fafafa.core.simd/BuildOrTest.sh` 与 `buildOrTest.bat` 现在都支持 `SIMD_ENABLE_AVX512_BACKEND=1`，可把 `SIMD_BACKEND_AVX512` 编进主 `simd` test runner；fresh opt-in `check`、`test --list-suites`、`TTestCase_AVX512BackendRequirements`、`TTestCase_DispatchAPI`、`TTestCase_PublicAbi`、`gate` 均已通过，因此 `AVX512 scFMA` future guard 不再只是源码级预埋
- 但当前宿主机 `/proc/cpuinfo` 没有 `avx512*` flags，只有 `avx2` / `popcnt`；因此这轮拿到的是 AVX-512 opt-in build/registration/public ABI 证据，不是 native AVX-512 指令执行证据
- benchmark helper 的 contract 现在也已显式化：`tests/fafafa.core.simd/fafafa.core.simd.bench.pas` 新增 `TryActivateBenchmarkBackend(...)`，会同时检查 `IsBackendAvailableOnCPU`、`IsBackendDispatchable`、`TrySetActiveBackend` 与最终 `GetActiveBackend=aBackend`
- 2026-03-21 最新 backend benchmark activation closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` -> FAIL（`Identifier not found "TryActivateBenchmarkBackend"`，说明新 red 已卡到共享 helper 合同）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-runner-20260321 bash tests/fafafa.core.simd/run_backend_benchmarks.sh` -> `AVX2_vs_Scalar PASS`，`AVX512_vs_AVX2 SKIP`，且 run log 明确输出 `[SKIP] AVX-512 backend is not available on this CPU`
  - green: `fpc -Mobjfpc -Sh -O3 ... tests/fafafa.core.simd/bench_neon_vs_scalar.lpr` -> PASS
  - green: `fpc -Mobjfpc -Sh -O3 ... tests/fafafa.core.simd/bench_riscvv_vs_scalar.lpr` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 16:41:15`
- public ABI hot-path 的 FPC codegen 证据已到位：在 FPC 3.3.1 / x86_64 / `-O3` 下，`GetSimdPublicApi` 会被内联成直接加载 `g_SimdPublicApi`，所以 `PubCache` 与 `PubGet` 的汇编形状几乎等价；相反 `GetDispatchTable` 仍保留 init/barrier/current-dispatch 开销
- 这说明下一轮实现层深审不该只盯 AVX-512 / non-x86；x86 backend 链自身也要继续查“注册表继承正确但 capability/priority/dispatchable 语义可能漂移”的问题
- 新暴露并已确认的一条方法论风险：只断言“当前 `vector asm=False`”会漏掉 runtime toggle 的 stale-table bug；后续 `scFMA/scShuffle/scIntegerOps` 以及类似 feature-toggle contract，都应统一覆盖 `SetVectorAsmEnabled(True)` 再 `False` 的真实重建路径
- 既然 codegen 证据已确认 `PubCache` 与 `PubGet` 基本同形，当前不再计划把 `PubCache >= PubGet` 升回 hard gate；后续若 FPC/toolchain 变化，再重新取证
- 下一轮连续计划优先级：
  1. 继续实现层深审，优先找下一条 “fallback 已接线但 dispatchable/active/public ABI 仍误报或漏报” 的真实问题，特别是 x86/non-x86 的 rebuild/toggle 路径，以及其他 helper/runner 是否还把 `supported_on_cpu` 误当成 `dispatchable`
  2. 在 arm64 / riscv64 asm-ready 主机上执行这轮新增的 active-backend reselection 测试，回收 native execution evidence，而不只停留在 x86_64 regression 证据
  3. fresh Windows native evidence `1/7..7/7` 复验，确认 `publicabi-smoke` 已真实进入 closeout 证据链
  4. 若后续进入具备 `avx512f/avx512bw` + OS/XCR0 条件的主机，再补 AVX-512 native execution 证据，并继续判定 `AVX-512` availability predicate 是否漏了前置条件
  5. 若未来升级 FPC/toolchain，再重做 `GetSimdPublicApi` hot-path codegen 取证，而不是继续依赖 benchmark 直觉

### Phase 41: unregistered backend canonical text metadata alignment
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_UnregisteredBackendInfo_PreservesCanonicalTextMetadata`，锁定未注册 backend 上 `GetBackendInfo` 与 public ABI text getter 必须暴露同一份 canonical `Name/Description`
- [x] 用 fresh release `TTestCase_DispatchAPI` 先拿 red，确认问题不是历史猜测
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的 `GetBackendInfo` 未注册路径只回写 `Backend/Available/Priority`，没有补 canonical `Name/Description`
- [x] 在 dispatch 层新增 default backend text helper，并让 `GetBackendInfo` 对 registered/unregistered 两条路径都在空文本时 fallback 到 canonical 默认值，避免 dispatch/public ABI metadata 分叉
- [x] 用 fresh release `TTestCase_DispatchAPI`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 unregistered text metadata closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-unregistered-text-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` -> FAIL（`GetBackendInfo should preserve non-empty name for unregistered backend=7`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-unregistered-text-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-unregistered-text-publicabi-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-unregistered-text-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-unregistered-text-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 03:08:32`
- 这轮根因不在 public ABI text cache，而在 dispatch canonical metadata source 本身：`GetSimdBackendNamePtr/GetSimdBackendDescriptionPtr` 已经会回退到默认 backend 文本，但 `GetBackendInfo` 的未注册路径此前仍把 `Name/Description` 留空，导致同一个 backend 在 dispatch/public ABI 两侧同时存在两份“canonical 文本”。
- 最小修复继续放在 shared dispatch contract，而不是再复制一份 wrapper 专属规则：`GetBackendInfo` 现在统一对空 `Name/Description` 做 default fallback，因此未注册 backend、registered snapshot 缺文本、以及 public ABI text getter 都重新对齐到同一套 canonical backend 文本。
- 下一轮连续计划优先级更新为：
  1. 继续深审 remaining metadata/view helper，优先找下一条 “unregistered/registered 边界上仍由多份真相源拼装”的真实问题，特别是 text/list/pod/helper 组合路径
  2. 继续检查 `SetVectorAsmEnabled` / `RegisterBackend` 相邻 helper 是否还有 stale `Name/Description/CapabilityBits` 视图
  3. 对 public ABI text getter pointer-lifetime / refresh 只接受 fresh red 证据，不再把 speculative 风险误记为已确认问题

## 5-Question Reboot Check (Phase 41 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条新的 metadata drift：`GetBackendInfo` 在未注册 backend 上没有保留 canonical 文本。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “单个 helper/list/pod/public-API 结果仍由多次 live 查询或不一致 fallback 拼装” 的真实问题，重点继续看 unregistered/registered 边界、toggle/re-register 相邻 helper、以及 external-consumer metadata 对齐。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，不只是 capability/flags 会漂移，连 backend 文本 metadata 也可能在 dispatch/public ABI 两侧各自 fallback 成不同 contract。修这类问题最稳的办法仍然是把 canonical 规则收口到 shared dispatch metadata source，而不是在 wrapper 层额外兜底。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 unregistered backend text metadata drift：`GetBackendInfo` 现在统一为空文本回退 canonical 默认值，`TTestCase_DispatchAPI` 已守住这条合同。 |

### Phase 42: current backend info canonical text metadata alignment
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_CurrentBackendInfo_PreservesCanonicalTextMetadata_After_ReRegister`，锁定 active/current backend 被重新注册为空文本 metadata 后，`GetCurrentBackendInfo` 仍必须与 canonical backend info / public ABI text getter 对齐
- [x] 用 fresh release `TTestCase_DispatchAPI` 先拿 red，确认这不是 Phase 41 的重复推测
- [x] 确认 `src/fafafa.core.simd.framework.impl.inc` 的 `GetCurrentBackendInfo` 直接返回 current dispatch snapshot 的 `BackendInfo`，没有对空 `Name/Description` 做 canonical fallback
- [x] 将 `GetCurrentBackendInfo` 收紧为：继续保留 current dispatch snapshot 的实时 `Available/Capabilities`，但在空文本时回退到 `GetBackendInfo(LDispatch^.Backend)` 的 canonical `Name/Description`
- [x] 用 fresh release `TTestCase_DispatchAPI`、fresh `TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 current backend text metadata closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackend-text-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` -> FAIL（`GetCurrentBackendInfo should preserve non-empty name after re-register`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackend-text-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackend-text-concurrent-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackend-text-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackend-text-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 03:26:39`
- 这轮根因位于 façade helper，而不是 dispatch/public ABI core path：current dispatch snapshot 会如实保留当前 active table 的 `BackendInfo`，但 `GetCurrentBackendInfo` 之前把这份 snapshot 直接暴露给调用方，导致一旦 active backend 被重新注册为“空 Name/Description”，framework helper 会再次与 `GetBackendInfo` / public ABI text getter 分叉。
- 最小修复继续遵守“保持 current snapshot 的实时状态位，只对空文本做 canonical fallback”的原则：`Available/Capabilities` 仍来自 current dispatch snapshot，只有 `Name/Description` 在为空时回退到 shared backend metadata source。
- 下一轮连续计划优先级更新为：
  1. 继续深审 remaining façade/framework helper，优先找下一条 “current/registered/unregistered 视图里仍由 snapshot + secondary helper 混拼”的真实问题
  2. 继续检查 `RegisterBackend` / `SetVectorAsmEnabled` 相邻路径里，除了文本字段外，是否还有 `Priority/Capabilities/Flags` 级别的 drift
  3. 对 external consumer / text pointer lifetime 风险仍坚持 fresh red 优先，不再把 speculative 现象提前记为已确认 bug

## 5-Question Reboot Check (Phase 42 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI`、fresh `TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条新的 façade helper drift：`GetCurrentBackendInfo` 在 active backend 被重新注册为空文本 metadata 后会暴露空 `Name/Description`。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “单个 helper/list/pod/public-API 结果仍由多份真相源拼装” 的真实问题，重点继续看 framework/view helper、toggle/re-register 相邻路径，以及 external-consumer metadata 对齐。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，哪怕 current dispatch snapshot 本身是一致的，只要 façade helper 对其中某些字段再缺少 canonical fallback，就仍会把同一个 active backend 拆成“current state 正确、文本 metadata 错误”的半漂移结果。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 `GetCurrentBackendInfo` 的 current-text drift：framework helper 现在在保持 current snapshot 状态位的同时，对空文本回退 canonical backend metadata。 |

### Phase 43: registered backend adapter canonical text metadata alignment
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas` 新增 `Test_BackendAdapter_RegisteredBackendOps_PreserveCanonicalTextMetadata_After_ReRegister`，锁定 registered backend 被空文本重注册后，`GetBackendOps(backend)` 仍必须与 canonical backend text 对齐
- [x] 用 fresh release `TTestCase_DispatchAllSlots` 先拿 red，确认问题不是 Phase 41/42 的重复猜测
- [x] 确认 `src/fafafa.core.simd.backend.adapter.pas` 的 registered 路径此前直接把 `DispatchTableToBackendOps(...)` 的 `BackendInfo` 原样暴露，没有对空 `Name/Description` 做 canonical fallback
- [x] 将 registered adapter 路径收紧为：显式对齐 `Backend/BackendInfo.Backend`，并在空文本时回退到 `GetBackendInfo(backend)` 的 canonical `Name/Description`，同时保留当前 snapshot 的 `Available/Capabilities`
- [x] 用 fresh release `TTestCase_DispatchAllSlots`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 registered adapter text metadata closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-currenttext-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots` -> FAIL（`GetBackendOps should preserve non-empty name for registered backend after re-register`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-currenttext-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-currenttext-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-currenttext-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 03:41:13`
- 这轮根因位于 backend adapter 的 registered-view helper，而不是 shared dispatch metadata source：`GetBackendInfo` / `GetCurrentBackendInfo` 已经统一为空文本做 canonical fallback，但 `GetBackendOps(backend)` 仍会把 published snapshot 里的空 `Name/Description` 直接暴露给 adapter 调用方。
- 最小修复继续遵守“保留当前 snapshot 的状态位，只对文本做 canonical fallback”的原则：registered adapter 仍保留 re-register 后的 `Available/Capabilities`，但不再把空 `Name/Description` 暴露成第三套 contract。
- 下一轮连续计划优先级更新为：
  1. 继续深审 remaining adapter/framework/view helper，优先找下一条 “registered/current/unregistered 视图里仍由 snapshot + secondary helper 混拼”的真实问题
  2. 继续检查 `RegisterBackend` / `SetVectorAsmEnabled` 相邻路径里，除了文本字段外，是否还有 `Priority/Capabilities/Flags` 级别的 drift
  3. 继续核对 public ABI `CapabilityBits` / text getter / helper 返回值在 re-register 与 toggle 后是否还存在 helper 侧漂移

## 5-Question Reboot Check (Phase 43 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAllSlots`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条新的 adapter helper drift：旧 `GetBackendOps(backend)` 会把 registered backend 的空文本 metadata 直接暴露出去。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “adapter/framework/view helper 结果仍由多份真相源拼装” 的真实问题，重点继续看 registered/current/unregistered helper、toggle/re-register 相邻路径，以及 public ABI external-consumer 对齐。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，即使 shared dispatch metadata source 已经收口，helper 层只要继续直接暴露 snapshot 文本，就仍可能在 re-register 后重新裂出第三套 contract。adapter helper 也必须遵守同一份 canonical text fallback 规则。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 registered adapter text drift：`GetBackendOps(backend)` 现在在保留当前 snapshot 状态位的同时，对空文本回退 canonical backend metadata。 |

### Phase 44: registered dispatch snapshot canonical text source alignment
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_RegisteredBackendDispatchTable_PreservesCanonicalTextMetadata_After_ReRegister`，锁定 raw registered snapshot 在空文本重注册后仍必须保留 canonical backend 文本
- [x] 用 fresh release `TTestCase_DispatchAPI` 先拿 red，确认 shared dispatch source 本身还留着空文本，而不是 helper 误判
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的 `RegisterBackend(...)` 之前只 canonicalize `Backend/BackendInfo.Backend/Priority`，没有 canonicalize 空的 `Name/Description`
- [x] 将 canonical text 收口到注册层：`RegisterBackend(...)` 在发布 immutable snapshot 前对空 `Name/Description` 写回 `DefaultBackendName/DefaultBackendDescription`
- [x] 用 fresh release `TTestCase_DispatchAPI`、fresh `TTestCase_DispatchAllSlots`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 registered snapshot text source closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-registeredtable-text-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` -> FAIL（`Registered backend table should preserve non-empty name after re-register`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-registeredtable-text-dispatchapi-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-registeredtable-text-dispatchslots-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-registeredtable-text-publicabi-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-registeredtable-text-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-registeredtable-text-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 03:54:33`
- 这轮根因位于 shared dispatch metadata source 本身，而不再只是 helper 包装层：`GetBackendInfo` / `GetCurrentBackendInfo` / `GetBackendOps` 虽然都能把空文本兜回来，但 raw `TryGetRegisteredBackendDispatchTable(...)` 仍能直接读到空文本 published snapshot，说明注册层没有真正收口 canonical text。
- 最小修复继续遵守“canonical 规则尽量回到共享真相源”的原则：把空文本补齐动作前推到 `RegisterBackend(...)`，这样 raw registered snapshot、current snapshot、adapter helper 和 public ABI text getter 全部复用同一份 canonical backend 文本，而不再靠每个 helper 各自修补。
- 下一轮连续计划优先级更新为：
  1. 继续深审 remaining raw/helper view，优先找下一条 “raw snapshot / helper / public ABI 之间仍由多份真相源拼装” 的真实问题
  2. 继续检查 `CloneDispatchTable`、public ABI text cache、以及 re-register/toggle 相邻路径里是否还有 `Priority/Capabilities/Flags` 级别的底层漂移
  3. 若后续怀疑 pointer lifetime / concurrent text refresh 风险，仍坚持 fresh red 优先，不把 speculative 风险提前记成已确认 bug

## 5-Question Reboot Check (Phase 44 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI`、fresh `TTestCase_DispatchAllSlots`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条新的 shared-source drift：旧 `RegisterBackend(...)` 会把空文本写进 raw registered snapshot。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 “raw snapshot/helper/public ABI 结果仍由多份真相源拼装” 的真实问题，重点继续看 `CloneDispatchTable`、public ABI text cache、registered/current/unregistered helper 与 toggle/re-register 相邻路径。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，只修 helper 还不够。如果 shared dispatch source 本身仍保留空文本或旧状态，底层 raw API 迟早会把问题重新露出来。能前推到 `RegisterBackend(...)` 的 canonicalization，应该尽量前推。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 registered snapshot text source drift：`RegisterBackend(...)` 现在会在发布 immutable snapshot 前补齐 canonical backend 文本。 |

### Phase 45: active dispatch snapshot publication and batch-rebuild consistency hardening
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `Test_Concurrent_PublicApiActiveMetadata_VectorAsmToggle_ReadConsistency` 与 `Test_Concurrent_CurrentBackendInfo_VectorAsmToggle_ReadConsistency`，锁定 vector-asm batch rebuild 期间 active metadata 只能落在 enabled/disabled 两种完整状态
- [x] 用 fresh release `TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework` 先拿 red，确认问题不只是 helper 断言过严，而是 current active dispatch/public API 真的会暴露 `SSE2/SSSE3` 这类半重建 backend；同时已有 `CurrentBackendInfo_RegisterBackend_ReadConsistency` 也重新打出更底层 mixed snapshot
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 存在两层根因：
- [x] `RegisterBackend(...)` 在 batch rebuild 中会让每次中间重注册都尝试重新选主，reader 看到 `g_DispatchState=0` 时也能抢跑 `InitializeDispatch`，从而按半重建 backend 集合选出中间 active backend
- [x] `DoInitializeDispatch` 在选定 `LBestBackend` 后又重新按 backend id 追最新 published state，导致并发 re-register 时可能把“旧 backend id + 新 disabled metadata”重新发布成 current snapshot
- [x] 将 `PublishCurrentDispatchTable(...)` 改为复制传入的精确 snapshot；`DoInitializeDispatch` 扫描时直接捕获并发布 `LBestDispatchTable`
- [x] 为 `SetVectorAsmEnabled(...)` 的 batch rebuild 加入两层控制：
- [x] `g_RegisterBackendReinitializeSuspendDepth` 抑制中间 `RegisterBackend(...)` 的反复 reinitialize，只在 batch 结束后统一选主
- [x] `g_DispatchBatchRebuildState` 让 reader 在 batch rebuild 期间等待，避免按半重建 backend 集合抢跑 `InitializeDispatch`
- [x] 用 fresh release `TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`、fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 active dispatch snapshot / batch rebuild closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-activemeta-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework` -> FAIL（命中 `public api active metadata mixed snapshot ... id=1 flags=15 expectedA=(6,15) expectedB=(0,15)`、`current backend info mixed snapshot ... backend=1/3/4`，以及已有 `CurrentBackendInfo_RegisterBackend_ReadConsistency` 的 `backend=6 available=False caps=0`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-activemeta-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-contract-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 04:22:54`
- 这轮根因已经不再是单个 helper 字段 fallback，而是 current active dispatch publication 本身不具备 batch-safe / snapshot-stable 语义：
  - batch rebuild 期间，reader 会在 `g_DispatchState=0` 时按半重建 backend 集合抢跑 `InitializeDispatch`
  - concurrent re-register 期间，`DoInitializeDispatch` 又会把“先选中的 backend id”与“稍后重新抓到的最新 published state”混成同一份 current snapshot
- 最小修复继续遵守“控制面只在边界重新选主，数据面只读单份已选 snapshot”的原则：
  - batch rebuild 只在末尾统一 reinitialize
  - current dispatch/public API metadata 都绑定到真正被选中的那份 snapshot，而不是 backend id 对应的后续最新状态
- 下一轮连续计划优先级更新为：
  1. 继续深审 remaining current-active readers，优先检查还有没有其它入口在 control-plane batch rebuild 期间绕开等待闸门直接抢跑初始化
  2. 继续核对 `CloneDispatchTable` / `GetActiveBackend` / external consumer smoke 周边是否还存在“先选 backend id，再追最新状态”的类似 pattern
  3. 继续坚持 fresh red 优先，不把 pointer lifetime / invalid-id / external-only 边界猜测提前记成已确认 bug

## 5-Question Reboot Check (Phase 45 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_SimdConcurrentPublicAbi`、fresh `TTestCase_SimdConcurrentFramework`、fresh `TTestCase_DispatchAPI`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 active-dispatch core drift：旧 current snapshot/public API metadata 会在 toggle/re-register 并发窗口里暴露半重建或 latest-state mixed snapshot。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 current-active reader / clone / external-consumer 边界上的真实 snapshot drift，重点继续看 `CloneDispatchTable`、`GetActiveBackend`、public ABI external smoke 和 remaining toggle/re-register 相邻路径。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，单靠 immutable backend snapshot 还不够。如果 current dispatch 的选主、发布和 batch rebuild 节奏不是同一个 observation point，active metadata 仍会裂成“旧选择 + 新状态”或“中间 backend”这类不可能组合。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 active dispatch snapshot/batch rebuild drift：current dispatch 现在发布精确选中 snapshot，vector-asm batch rebuild 也不再让 reader 抢跑到半重建状态。 |

### Phase 46: current active backend public ABI pod snapshot consistency hardening
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `Test_Concurrent_PublicAbiPodInfo_CurrentBackend_RegisterBackend_ReadConsistency`，锁定 current active backend 的 pod info 在 concurrent `RegisterBackend(...)` 下只能落在 `enabled-active` / `enabled-inactive` / `disabled-inactive` 三种完整状态
- [x] 用 fresh release `TTestCase_SimdConcurrentPublicAbi` 先拿 red，确认问题不只是旧 testcase 断言过严，而是 `TryGetSimdBackendPodInfo(current_backend)` 真的会暴露 `disabled-active` 这类 impossible combo
- [x] 确认 `src/fafafa.core.simd.public_abi.impl.inc` 的根因位于 active backend 路径仍混用了两份 snapshot：
- [x] `CapabilityBits` / `dispatchable` / `Priority` 仍来自 registered snapshot
- [x] `active` bit 却来自 current dispatch snapshot
- [x] 将 `TryGetSimdBackendPodInfo(...)` 收紧为：若 `aBackend` 正是当前 active backend，则 `CapabilityBits` / `dispatchable` / `Priority` / `active` 全部从同一份 `GetDispatchTable` current snapshot 派生；只有非 active backend 才继续读取 registered snapshot
- [x] 用 fresh release `TTestCase_SimdConcurrentPublicAbi`、fresh `TTestCase_PublicAbi,TTestCase_SimdConcurrentPublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 current-backend public ABI pod closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentpod-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi` -> FAIL（命中 `backend pod info mixed snapshot at iter 0: caps=447 flags=7 expectedA=(447,15) expectedB=(0,3)` 与更关键的 `backend pod info mixed snapshot at iter 12: caps=0 flags=11 expectedA=(447,15) expectedB=(0,3)`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentpod-green3-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentpod-contract-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi,TTestCase_SimdConcurrentPublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentpod-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentpod-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 12:08:47`
- 这轮根因位于 current active backend 的 public ABI pod getter 仍未绑定到单一 observation point：
  - registered snapshot 给出了 `CapabilityBits/dispatchable/priority`
  - current dispatch snapshot 给出了 `active`
  - 于是 concurrent re-register 时，单个 `TFafafaSimdBackendPodInfo` 仍可能裂成 “disabled snapshot + active bit” 这类根本不可能出现的组合
- 最小修复继续遵守“active reader 只读 current snapshot，non-active reader 才读 registered snapshot”的原则：
  - active backend pod info 现在直接复用 current dispatch snapshot 的 `BackendInfo`
  - 并发测试口径也同步收紧为三态合同：`enabled-active`、`enabled-inactive`、`disabled-inactive`
  - 其中 `disabled-active` 被明确定义为 impossible combo，必须持续禁止
- 下一轮连续计划优先级更新为：
  1. 继续深审 remaining current-active readers，优先检查 `GetActiveBackend`、`CloneDispatchTable` 和 public ABI external consumer 是否还在 “先判 active backend，再跨另一份 snapshot 取字段”
  2. 继续核对 `toggle/re-register` 相邻 helper 是否还有 stale `dispatchable/priority/capabilities` 组合，但仍坚持先补 fresh red 再修
  3. 若 external smoke 需要加强 current-backend metadata 约束，优先补 consumer-side 合同测试，而不是先猜测实现缺陷

## 5-Question Reboot Check (Phase 46 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_SimdConcurrentPublicAbi`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 current-active public ABI pod drift：旧 `TryGetSimdBackendPodInfo(current_backend)` 会在 concurrent re-register 窗口里暴露 mixed pod snapshot。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 current-active reader / clone / external-consumer 边界上的真实 snapshot drift，重点继续看 `GetActiveBackend`、`CloneDispatchTable`、public ABI external smoke 和 remaining toggle/re-register 相邻路径。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，即使 Phase 45 已把 current dispatch/public API metadata 绑定到精确选中的 snapshot，current backend 的 public ABI pod getter 只要还把 registered/current 两份 observation point 拼在一起，仍会重新裂出 impossible combo。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 current active backend pod snapshot drift：active backend 的 `CapabilityBits/dispatchable/priority/active` 现在都从同一份 current dispatch snapshot 派生。 |

### Phase 47: public ABI bound-table data-plane rebind contract closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicApi_Table_Rebinds_DataPlane_FunctionPointers_AfterBackendSwitch`，锁定 “当底层 dispatch slot 已实际切换时，fresh `GetSimdPublicApi` table 的对应 data-plane 函数指针也必须切换”
- [x] 用 fresh release `TTestCase_PublicAbi` 先拿 red，确认问题不是测试口径过严，而是 public API table 真的只刷新了 metadata，没有刷新 data-plane 函数指针
- [x] 确认 `src/fafafa.core.simd.public_abi.impl.inc` 的根因位于 `RebindSimdPublicApi` 虽然先缓存了 `LState^.MemEqualBound/...` 等 snapshot-bound backend 函数，但真正发布到 `TFafafaSimdPublicApi` 的仍统一是 `@PublicAbi*` wrapper
- [x] 将 `RebindSimdPublicApi` 收紧为：在主力 64-bit 目标（`CPUX86_64/CPUAARCH64/CPURISCV64`）上直接发布 snapshot-bound backend entry points；其他目标继续保留现有 wrapper fallback
- [x] 用 fresh release `TTestCase_PublicAbi`、fresh external `tests/fafafa.core.simd.publicabi/BuildOrTest.sh test`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 public ABI data-plane rebind closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicapi-bind-red2-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` -> FAIL（命中 `Fresh public API table should publish rebound function pointer for MemEqual`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicapi-bind-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicapi-bind-external-20260322 bash tests/fafafa.core.simd.publicabi/BuildOrTest.sh test` -> PASS，`[TEST] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicapi-bind-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicapi-bind-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 14:07:47`
- 这轮根因位于 public ABI data-plane 发布层，而不是 metadata getter：
  - `RebindSimdPublicApi` 已经把当前 snapshot-bound backend 函数缓存到 `LState^.MemEqualBound/...`
  - 但旧实现仍把 `TFafafaSimdPublicApi` 的 `MemEqual/MemFindByte/...` 统一写成全局 `@PublicAbi*` wrapper
  - 结果是 backend 切换后 fresh table 的 `ActiveBackendId/ActiveFlags` 会刷新，但 data-plane 指针地址保持不变，违背了文档与设计里“绑定后直调 / 缓存 table 可作为 snapshot data-plane”合同
- 最小修复继续遵守“table metadata 与 data-plane 指向同一份 snapshot-bound backend implementation”的原则：
  - 主力 64-bit 平台直接发布该次 snapshot 的 backend 函数地址
  - 只有其他目标继续保留现有 wrapper fallback，避免扩大 calling-convention 风险面
- 下一轮连续计划优先级更新为：
  1. 继续深审 `GetActiveBackend`、`CloneDispatchTable` 与 public ABI text cache 并发刷新路径，优先找下一条仍跨 observation point 取字段的真实 drift
  2. 继续核对 external-consumer 侧还有没有“metadata 已刷新但 consumer-bound helper 仍未跟随”的 contract gap
  3. 若继续碰到 speculative 并发/lifetime 怀疑点，仍坚持先拿 fresh red，再决定是否收口为真实问题

### Phase 48: failed forced-selection lingering state rollback closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “hook-driven `TrySetActiveBackend(...)` 失败后，不得留下 lingering forced-selection state 并在后续 `RegisterBackend(...)` 时悄悄复活 previously-requested backend”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是测试口径过严，而是 post-failure 的 `g_BackendForced/g_ForcedBackend` 真的会残留
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `TrySetActiveBackend(...)` 先写入 `g_ForcedBackend/g_BackendForced`，但后验最终态若发现 active backend 已偏离 requested，只返回 `False`，没有回滚 forced-selection state
- [x] 将 `TrySetActiveBackend(...)` 收紧为：postcondition failure 时显式清理 `g_BackendForced`，并把 `g_ForcedBackend` 复位为 canonical `sbScalar`，避免后续 re-register/rebuild 误复活旧失败请求
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 failed-forced-selection lingering-state closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-lingering-force-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `A failed TrySetActiveBackend must not leave lingering forced state that revives the requested backend on later re-register` 与 `Public API active backend should return to automatic selection instead of reviving the previously failed requested backend`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-lingering-force-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-lingering-force-direct-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-lingering-force-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-lingering-force-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 15:32:17`
- 这轮根因位于 forced-selection 控制面自己的失败回滚，而不是 dispatch/public ABI reader：
  - `TrySetActiveBackend(...)` 在进入重选前会先写下 requested backend 的 forced-selection intent
  - Phase 32 只把 success 判定收紧为后验最终 active backend，但旧实现仍让失败调用留下了 `g_BackendForced=True`
  - 于是只要后续有 `RegisterBackend(...)` / rebuild 重新让 requested backend 变回 dispatchable，旧失败请求就会在没有新 API 调用的情况下被悄悄复活
- 最小修复继续遵守“返回 False 的控制面调用不得留下继续生效的隐藏意图”原则：
  - failing `TrySetActiveBackend(...)` 现在会在持锁路径内立即回滚 forced-selection state
  - 但这一步只先解决了 delayed revival；Phase 49 又继续确认，failure return 之后 current active/public ABI 仍停在 scalar fallback 也是另一条真实 stale-state bug
  - Phase 49 完成后，failed call 的 immediate final state 也会重新回到 automatic selection，而不会再留下 transient scalar fallback
- 下一轮连续计划优先级更新为：
  1. 继续深审 `GetActiveBackend`、`CloneDispatchTable` 与 remaining control-plane postcondition 路径，优先找下一条“调用已报告失败，但隐藏控制态仍残留”的真实问题
  2. 继续核对 `RegisterBackend(...)` / rebuild / hook 嵌套调用下，direct/public ABI/external-consumer 是否还有“最终态已收敛，但 side-effect state 没回滚”的合同缺口
  3. 若没有 fresh red，再回到 `CloneDispatchTable`、public ABI text cache 与 external smoke 的 snapshot-source 边界继续做证据驱动排查

### Phase 49: failed forced-selection immediate automatic-restore closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “hook-driven `TrySetActiveBackend(...)` 失败后，不仅要回滚 forced intent，还必须立即恢复 automatic best backend，而不能把 active/public ABI 留在 transient scalar fallback”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 lingering-force 的重复表述，而是 post-failure 的 current active/public ABI 确实还停在 stale scalar snapshot
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `TrySetActiveBackend(...)` failure path 之前只清理 `g_BackendForced/g_ForcedBackend`，却没有在同一持锁路径内重新跑 automatic selection
- [x] 将 `TrySetActiveBackend(...)` 收紧为：postcondition failure 回滚 forced state 后，立刻清空初始化状态并重新 `InitializeDispatch`，让 failure return 的最终 active/public ABI 重新对齐 automatic best backend
- [x] 同步把 `Phase 32`/`Phase 48` 中旧的 “失败后停在 Scalar” testcase 口径收敛为 “失败后回到 best dispatchable backend”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 failed-forced-selection immediate-restore closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-failed-hook-auto-restore-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `A failed TrySetActiveBackend should restore automatic best backend instead of leaving scalar forced fallback active` 与 `Public API active backend should immediately return to automatic best backend after failed hook-driven selection`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-failed-hook-auto-restore-green2-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-failed-hook-auto-restore-direct-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-failed-hook-auto-restore-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-failed-hook-auto-restore-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 18:19:32`
- 这轮根因位于 failure rollback 后的 current active/public ABI finalization，而不是 lingering forced intent 本身：
  - Phase 48 修复后，`TrySetActiveBackend(...)` 在 postcondition failure 时已经会清掉 `g_BackendForced/g_ForcedBackend`
  - 但旧实现仍把当前 dispatch 停在 forced path 为这次失败请求临时选出的 `Scalar` fallback snapshot
  - 结果是 API 已经返回 `False` 且 forced intent 已回滚，`GetActiveBackend` / `GetSimdPublicApi.ActiveBackendId` 却还停在 stale scalar，而不是 automatic best backend
- 最小修复继续遵守“失败控制面调用的 return-time final state 必须与 automatic mode 一致”原则：
  - rollback forced state 后立即重新清空 dispatch 初始化状态并执行一次 automatic `InitializeDispatch`
  - 这样 failure return 的最终 active backend、public ABI active backend id、以及 direct/public fast path rebind 都会重新与 best dispatchable backend 对齐
- 下一轮连续计划优先级更新为：
  1. 继续深审 `GetActiveBackend`、`CloneDispatchTable` 与 remaining control-plane postcondition 路径，优先找下一条“failure/rollback 已发生，但 return-time observation point 仍残留 stale snapshot”的真实问题
  2. 继续核对 `RegisterBackend(...)` / rebuild / hook 嵌套调用下，direct/public ABI/external-consumer 是否还有“current state 已应恢复 automatic，但 helper/cache 仍停在旧 snapshot”的合同缺口
  3. 若没有 fresh red，再回到 `CloneDispatchTable`、public ABI text cache 与 external smoke 的 snapshot-source 边界继续做证据驱动排查

### Phase 50: rollback-restore return-value recomputation closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “hook-driven `TrySetActiveBackend(...)` 失败回滚期间如果 automatic restore 在 return 前重新选回 requested backend，返回值必须和 return-time final backend 一致”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 49 的重复表述，而是 failure rollback 之后 final active backend 已恢复 requested，但 API 返回值仍停在旧 `False`
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `TrySetActiveBackend(...)` 先在第一次 forced-attempt `InitializeDispatch` 之后计算一次 `Result`，却没有在 rollback-time automatic reinit 完成后按 return-time final backend 重新计算
- [x] 将 `TrySetActiveBackend(...)` 收紧为：failure rollback 的 `InitializeDispatch` 之后重新读取 published current dispatch，并用 return-time final backend 重算 `Result`
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 rollback-restore return-value closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-rollback-restore-result-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `TrySetActiveBackend should report success when rollback-time restore makes the requested backend active again before return` 与 `TrySetActiveBackend should report success when rollback-time restore makes the requested backend active again before public ABI observation`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-rollback-restore-result-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-rollback-restore-result-direct-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-rollback-restore-result-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-rollback-restore-result-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 19:44:49`
- 这轮根因位于 failure rollback 之后的 return-value observation point，而不是 final active/public ABI state 本身：
  - Phase 49 修复后，rollback automatic reinit 已经能在 failure return 前把 current active/public ABI 收口回最终 backend
  - 但旧实现仍复用第一次 forced-attempt `InitializeDispatch` 之后算出的 `Result`
  - 结果是 return-time final backend 已重新等于 requested backend，`TrySetActiveBackend(...)` 却仍返回 `False`
- 最小修复继续遵守“返回值必须以后验最终状态为准”原则：
  - failure rollback 的 `InitializeDispatch` 之后立即重新读取 published current dispatch
  - 再用 return-time final backend 是否等于 requested backend 重算 `Result`
  - 这样 dispatch API 返回值、`GetActiveBackend` 与 public ABI active backend id 会重新共享同一个 return-time truth source
- 下一轮连续计划优先级更新为：
  1. 继续深审 `GetActiveBackend`、`CloneDispatchTable` 与 remaining rebuild-hook/nested-reinit 路径，优先找下一条“final state 已收口，但 helper/return/cache 仍停在旧 observation point”的真实问题
  2. 重点核对 public ABI text getter/cache、registered/current snapshot adapter，以及 external-consumer helper 是否还存在 return-time state 已更新但返回数据仍取自旧缓存的合同缺口
  3. 若没有 fresh red，再回到 same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

### Phase 51: rollback-restore success forced-intent preservation closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “hook-driven `TrySetActiveBackend(...)` failure rollback 若在 return 前重新选回 requested backend，`True` 不仅要和 return-time active backend 一致，还必须保住后续的 forced-selection intent”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 50 的重复表述，而是 `TrySetActiveBackend(...)` 已经返回 success，但更高优先级 backend 恢复后 active/public ABI 仍会漂回 automatic best backend
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `TrySetActiveBackend(...)` failure rollback 路径先清掉 `g_BackendForced/g_ForcedBackend`，随后只按 return-time final backend 重算 `Result`，却没有在 `Result=True` 时恢复 forced-selection intent
- [x] 将 `TrySetActiveBackend(...)` 收紧为：若 rollback automatic reinit 后 return-time final backend 等于 requested backend，则同步恢复 `g_ForcedBackend/g_BackendForced`，让 success 语义和持续 forced-selection intent 对齐
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 rollback-restore success forced-intent closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-force-success-intent-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `A successful TrySetActiveBackend must keep the requested backend forced even after higher-priority backends are restored` 与 `A successful TrySetActiveBackend must keep the requested backend active in public ABI after higher-priority backends are restored`，`expected: <1> but was: <6>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-force-success-intent-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-force-success-intent-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-force-success-intent-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 20:48:19`
- 这轮根因位于 success path 的 control-plane intent，而不是 return-time final backend / public ABI active backend 的瞬时值：
  - Phase 50 修复后，rollback automatic reinit 已经会在 return 前把 current active/public ABI 重新选回 requested backend，并让 `TrySetActiveBackend(...)` 返回 `True`
  - 但 failure rollback 路径更早已经把 `g_BackendForced := False` 与 `g_ForcedBackend := sbScalar` 清掉
  - 结果是这次 success 只代表 return-time active backend 短暂等于 requested backend；一旦更高优先级 backend 在函数返回后恢复，active/public ABI 就又漂回 automatic best backend
- 最小修复继续遵守“success 既要对齐 return-time final state，也要保住持续 forced-selection intent”原则：
  - rollback automatic reinit 后若 final backend 仍等于 requested backend，就在同一持锁路径内恢复 `g_ForcedBackend/g_BackendForced`
  - 不再额外重建当前 dispatch，因为 return-time active snapshot 已经是 requested backend
  - 这样后续 `RegisterBackend(...)` / rebuild 重新选主时，dispatch API 和 public ABI 都会继续保持在 requested backend，而不会因 automatic mode 漂走
- 下一轮连续计划优先级更新为：
  1. 继续深审 `TrySetActiveBackend` / `SetActiveBackend` / `ResetToAutomaticBackend` 与 rebuild-hook 嵌套路径，优先找下一条“return-time success/active 已对齐，但 helper/cache/持续 intent 仍残留旧 observation point”的真实问题
  2. 重点核对 public ABI text getter/cache、registered/current snapshot adapter、以及 external-consumer helper 在 forced/automatic 切换后的持续一致性
  3. 若没有 fresh red，再回到 `CloneDispatchTable`、same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

## 5-Question Reboot Check (Phase 51 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 rollback-restore success drift：旧 `TrySetActiveBackend(...)` 即使在 return 前已经重新选回 requested backend 并返回 `True`，后续更高优先级 backend 恢复后 active/public ABI 仍会漂回 automatic best backend。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `TrySetActiveBackend/SetActiveBackend/ResetToAutomaticBackend`、public ABI text cache、或 rebuild-hook 嵌套路径上的真实持续一致性问题，尤其是“return-time 状态正确，但后续 helper / cache / intent 又漂走”的问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，`TrySetActiveBackend=True` 的合同不能只停在 return-time active backend 相等。只要 success path 没把 control-plane forced intent 一起保住，后续 unrelated `RegisterBackend(...)` / rebuild 一样会把 active/public ABI 漂回 automatic best backend。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 rollback-restore success forced-intent drift：`TrySetActiveBackend(...)` 现在在 rollback automatic reinit 已重新选回 requested backend 时，会同步恢复 forced-selection intent，不再在后续高优先级 backend 恢复后漂走。 |

### Phase 52: failed late switch restores previous forced backend closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “调用前已经 forced 在 backend A 时，`TrySetActiveBackend(B)` 若在 hook-driven late failure 中失败，必须恢复 A，而不是漂回 automatic best backend”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 49/51 的重复表述，而是 failure rollback 在 pre-existing forced state 下仍一律按 automatic mode 收口
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `TrySetActiveBackend(...)` 进入尝试后直接覆盖 `g_BackendForced/g_ForcedBackend`，而 failure rollback 只会清 forced 并做 automatic `InitializeDispatch`，完全没有保存/恢复调用前 forced state
- [x] 将 `TrySetActiveBackend(...)` 收紧为：在入口保存 pre-call forced state；failure rollback 仍先保留 automatic reinit 的 success-recovery 语义；若 return-time final backend 仍不等于 requested 且调用前本来就是 forced mode，则恢复 pre-call `g_BackendForced/g_ForcedBackend` 并重建 dispatch
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 previous-forced rollback closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-previous-forced-rollback-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `A failed TrySetActiveBackend must restore the previously forced backend instead of reverting to automatic best backend` 与 `Public API active backend must restore the previously forced backend instead of reverting to automatic best backend`，`expected: <5> but was: <6>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-previous-forced-rollback-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-previous-forced-rollback-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-previous-forced-rollback-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 22:23:44`
- 这轮根因位于 failure rollback 的 pre-call state preservation，而不是 requested backend 的后验 success 语义：
  - Phase 49/50/51 已经把 late failure rollback 收紧为：先清 forced、做 automatic reinit、允许 requested backend 在 return 前重新成功
  - 但旧实现默认调用前就是 automatic mode，没有保存 pre-call forced context
  - 结果是当调用前其实已经 forced 在 backend A 时，失败切换到 backend B 之后 rollback 会直接漂回 automatic best backend C，而不是回到 A
- 最小修复继续遵守“失败控制面调用不得破坏调用前已存在的 forced state”原则：
  - 入口先保存 `LPreviousBackendForced/LPreviousForcedBackend`
  - failure rollback 继续先跑 automatic reinit，以保留 Phase 50/51 已验证的 requested-success recovery 语义
  - 只有当 return-time final backend 仍不等于 requested，且调用前本来就是 forced mode 时，才恢复 pre-call forced intent 并重新 `InitializeDispatch`
  - 这样 late-failure return 既不会误报 success，也不会把已有 forced backend 静默降级成 automatic mode
- 下一轮连续计划优先级更新为：
  1. 继续深审 `TrySetActiveBackend` / `SetActiveBackend` / `ResetToAutomaticBackend` / `SetVectorAsmEnabled(True->False)` 在 pre-existing forced state 下的 rebuild/toggle 路径，优先找下一条“失败调用不该破坏调用前控制态”的真实问题
  2. 继续核对 public ABI text getter/cache、registered/current snapshot adapter，以及 external-consumer helper 在 forced/automatic 多次切换后的持续一致性
  3. 若没有 fresh red，再回到 same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

## 5-Question Reboot Check (Phase 52 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 previous-forced rollback drift：旧 `TrySetActiveBackend(...)` 在调用前已经 forced 到 backend A 时，失败切换到 backend B 仍会漂回 automatic best backend，而不是恢复 A。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `TrySetActiveBackend/SetActiveBackend/ResetToAutomaticBackend/SetVectorAsmEnabled` 在 pre-existing forced state、rebuild-hook 嵌套、或 helper/cache 观察点上的真实持续一致性问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，“失败后回到 automatic”只对调用前原本就是 automatic mode 的调用者成立。一旦控制面进入 pre-existing forced state，late-failure rollback 也必须保持调用前状态不变，否则 API 会把已有用户意图静默抹掉。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 previous-forced rollback drift：`TrySetActiveBackend(...)` 现在会在 late failure 仍失败时恢复调用前 forced backend，不再一律漂回 automatic best backend。 |

### Phase 53: SetActiveBackend late-failure preserves previous forced backend closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “调用前已经 forced 在 backend A 时，`SetActiveBackend(B)` 若在 hook-driven late failure 中失败，不能把 A 静默打成 scalar fallback”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 52 的重复表述，而是 `SetActiveBackend(...)` wrapper 自己把 `TrySetActiveBackend(...)` 已恢复好的状态又覆盖成了 scalar forced-selection
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `SetActiveBackend(...)` 对所有 `TrySetActiveBackend(...)` 失败一律执行 `TrySetActiveBackend(sbScalar)`，没有区分 “调用前就不可选” 与 “late failure 才失败”
- [x] 将实现收紧为：`SetActiveBackend(...)` 仅在 requested backend 在调用开始前就不可选时才退到 scalar；若 backend 在尝试期间经历 hook-driven late failure，则保留 `TrySetActiveBackend(...)` 已恢复好的 current state
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-22 最新 SetActiveBackend late-failure closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-setactive-late-failure-red-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `SetActiveBackend should preserve the previous forced backend when a late hook-driven failure rejects the requested backend` 与 `Public API active backend should preserve the previous forced backend when SetActiveBackend hits a late hook-driven failure`，`expected: <5> but was: <0>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-setactive-late-failure-green-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-setactive-late-failure-check-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-setactive-late-failure-gate-20260322 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-22 23:38:36`
- 这轮根因位于 `SetActiveBackend(...)` wrapper 的 failure classification，而不是 `TrySetActiveBackend(...)` 的 rollback 本体：
  - Phase 52 修复后，`TrySetActiveBackend(...)` 在 late failure 仍失败时已经会恢复 pre-call forced backend
  - 但旧 `SetActiveBackend(...)` 继续把所有失败都当成“requested backend 不可用”，无条件再执行一次 `TrySetActiveBackend(sbScalar)`
  - 结果是 wrapper 把 `TrySetActiveBackend(...)` 已经恢复好的 previous forced backend 又静默打成了 scalar forced-selection；由于 `SetActiveBackend(...)` 没有返回值，这条漂移更难被调用方察觉
- 最小修复继续遵守“late failure 不得破坏调用前控制态，但 precondition unavailable 仍保持 scalar fallback”原则：
  - 新增内部 helper 区分 requested backend 是否真正进入了 selection attempt
  - `SetActiveBackend(...)` 只对 `aAttemptedSelection=False` 的 precondition-unavailable 路径保留 scalar fallback
  - 对 `aAttemptedSelection=True` 但最终失败的 late-failure 路径，则保留 `TrySetActiveBackend(...)` 已恢复好的 current state
- 下一轮连续计划优先级更新为：
  1. 继续深审 `SetVectorAsmEnabled(True->False->True)`、`ResetToAutomaticBackend`、以及 `RegisterBackend(...)` 在 pre-existing forced state 下的嵌套 rebuild/toggle 路径，优先找下一条“wrapper/helper 继续覆盖底层已恢复状态”的真实问题
  2. 继续核对 public ABI text getter/cache、registered/current snapshot adapter，以及 external-consumer helper 在 forced/automatic 多次切换后的持续一致性
  3. 若没有 fresh red，再回到 same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

## 5-Question Reboot Check (Phase 53 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 SetActiveBackend wrapper drift：旧 `SetActiveBackend(...)` 在 late failure 后会把 `TrySetActiveBackend(...)` 已恢复好的 previous forced backend 又静默打成 scalar。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `SetVectorAsmEnabled` / `ResetToAutomaticBackend` / `RegisterBackend` / helper wrapper 在 pre-existing forced state、rebuild-hook 嵌套、或 observation-point 漂移上的真实持续一致性问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，只修底层 `TrySetActiveBackend(...)` 还不够。如果 wrapper 继续把所有失败粗暴归类成“直接退 scalar”，它仍然会覆盖掉底层已经恢复好的 caller state。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 SetActiveBackend late-failure drift：wrapper 现在不会再在 hook-driven late failure 后把 previous forced backend 静默降成 scalar fallback。 |

### Phase 54: ResetToAutomaticBackend late-hook automatic-state restoration closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “`ResetToAutomaticBackend(...)` 即使在 dispatch-changed hook 的通知阶段被一次 late `SetActiveBackend(sbScalar)` 重新 force，也必须在 return 时恢复 automatic best backend”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 49/53 的重复表述，而是 `ResetToAutomaticBackend(...)` 自己缺少 hook 之后的 postcondition 收口
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `ResetToAutomaticBackend(...)` 只在入口清一次 `g_BackendForced/g_ForcedBackend`，随后完全信任第一次 `InitializeDispatch`；dispatch-changed hook 若在通知阶段重新 force scalar，函数就会在 return 后留下 stale forced state
- [x] 将 `ResetToAutomaticBackend(...)` 收紧为：入口显式清 `g_BackendForced/g_ForcedBackend`；第一次 automatic `InitializeDispatch` 完成后若发现 hook 期间 forced state 被复活，则在同一持锁路径里再次清 forced 并重建一次 automatic dispatch
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-23 最新 ResetToAutomaticBackend late-hook closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-resetauto-lateforce-red-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `ResetToAutomaticBackend should restore automatic best backend even if a late hook re-forces scalar during notification` 与 `Public API active backend should restore automatic best backend even if a late hook re-forces scalar during reset`，`expected: <6> but was: <0>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-resetauto-lateforce-green-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-resetauto-lateforce-check-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-resetauto-lateforce-gate-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-23 03:46:52`
- 这轮根因位于 `ResetToAutomaticBackend(...)` 的 postcondition closure，而不是 automatic best backend 选择逻辑本身：
  - automatic selection 在首次 `InitializeDispatch` 时本来已经能选出正确的 best backend
  - 但旧实现没有像 `TrySetActiveBackend(...)` / `SetActiveBackend(...)` 那样在 hook 嵌套调用后重新校验控制态
  - 结果是只要 hook 在通知阶段再做一次 `SetActiveBackend(sbScalar)`，`ResetToAutomaticBackend(...)` return-time active/public ABI 就会停在 stale scalar forced fallback
- 最小修复继续遵守“reset-to-automatic 的 return-time state 必须真的处于 automatic mode”原则：
  - 入口先清 `g_BackendForced/g_ForcedBackend`
  - 第一次 automatic `InitializeDispatch` 之后立即检查 forced state 是否被 hook 复活
  - 若已复活，则在同一持锁路径内再次清 forced 并重建一次 automatic dispatch，让 final active/public ABI 回到 best dispatchable backend
- 下一轮连续计划优先级更新为：
  1. 继续深审 `SetVectorAsmEnabled(True->False->True)` 与 `RegisterBackend(...)` 在 pre-existing forced state、automatic reset、以及 rebuild-hook 嵌套路径上的持续一致性，优先找下一条“toggle/register helper 又覆盖 final state”的真实问题
  2. 继续核对 public ABI text getter/cache、registered/current snapshot adapter，以及 external-consumer helper 在 forced/automatic 多次切换后的持续一致性
  3. 若没有 fresh red，再回到 same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

## 5-Question Reboot Check (Phase 54 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 ResetToAutomaticBackend postcondition drift：旧 `ResetToAutomaticBackend(...)` 会在 late hook 重新 force scalar 后返回 stale scalar，而不是 automatic best backend。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `SetVectorAsmEnabled` / `RegisterBackend` / helper wrapper 在 forced/automatic 切换、rebuild-hook 嵌套、或 observation-point 漂移上的真实持续一致性问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，控制面 API 只在入口清状态还不够。只要 dispatch-changed hook 能在 return 前再做一次 nested force，`ResetToAutomaticBackend(...)` 也必须像前几轮的 selection API 一样做 postcondition 收口。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 ResetToAutomaticBackend late-hook drift：reset 现在不会再在通知阶段被一次 scalar re-force 劫持为 stale forced fallback。 |

### Phase 55: SetVectorAsmEnabled late-hook forced-intent preservation closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “调用前已经 forced 在 backend A 时，`SetVectorAsmEnabled(False)` 的 dispatch-changed hook 若 late `ResetToAutomaticBackend(...)`，后续 `SetVectorAsmEnabled(True)` 仍必须恢复 A，而不是漂回 automatic best backend”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 54 的重复表述，而是 vector-asm toggle 自身没有保住 pre-toggle control-plane intent
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `SetVectorAsmEnabled(...)` / `RebuildBackendsAfterFeatureToggle(...)` 只做一次 reinit，没有在 hook 通知之后检查 `g_BackendForced/g_ForcedBackend` 是否被 nested reset 改写
- [x] 将 `SetVectorAsmEnabled(...)` 收紧为：入口保存 pre-toggle forced/automatic 状态；rebuild 完成后若 hook 改写了 control-plane mode，则恢复 pre-toggle intent 并重建一次 dispatch
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

### Phase 56: RegisterBackend late-hook automatic-state restoration closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “automatic mode 下的 `RegisterBackend(...)` 即使在 dispatch-changed hook 通知阶段被一次 late `SetActiveBackend(sbScalar)` 重新 force，也必须在 return 时恢复 automatic best backend”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 54/55 的重复表述，而是 `RegisterBackend(...)` 自身没有做 hook 之后的 control-plane closure
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `RegisterBackend(...)` 只发布 snapshot 并做一次 `InitializeDispatch`，没有在 hook 通知之后检查 `g_BackendForced/g_ForcedBackend` 是否被 late force 改写
- [x] 将 `RegisterBackend(...)` 收紧为：入口保存 pre-call forced/automatic 状态；首次 reinit 完成后若 hook 改写了 control-plane mode，则恢复 pre-call intent 并再做一次 `InitializeDispatch`
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-23 最新 vector-asm late-reset forced-intent closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-latereset-red-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `Re-enabling vector asm should preserve the previously forced backend even if a late hook resets to automatic during disable` 与 `Public API should preserve the previously forced backend after vector-asm re-enable even if a late hook reset to automatic during disable`，`expected: <1> but was: <6>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-latereset-green-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-latereset-check-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-latereset-gate-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-23 04:13:47`
- 这轮根因位于 feature toggle 的 control-plane postcondition，而不是 backend rebuild 本身：
  - toggle 前调用者已经 forced 在 backend A，旧实现也确实会在 `vector asm=False` 期间暂时把 current backend 收到 fallback/automatic 结果
  - 但 `DoInitializeDispatch -> NotifyDispatchChangedHooks` 允许 hook 在 toggle 返回前 nested `ResetToAutomaticBackend(...)`
  - 旧 `SetVectorAsmEnabled(...)` 没有像 Phase 51/54 那样做 return-time closure，导致 pre-toggle forced intent 被静默抹掉；后续重新启用 vector asm 时 active/public ABI 直接漂回 automatic best backend
- 最小修复继续遵守“feature toggle 不得改写调用前控制态”原则：
  - 在 `SetVectorAsmEnabled(...)` 入口保存 `LPreviousBackendForced/LPreviousForcedBackend`
  - rebuild/reinit 完成后检查 hook 是否改写了 forced/automatic mode
  - 若已漂移，则恢复 pre-toggle intent 并再做一次 `InitializeDispatch`
  - 这样 `vector asm=False` 的临时 fallback 仍保留，但 `vector asm=True` 恢复后，dispatch API 与 public ABI 都会重新回到调用前 forced backend，而不会被 late reset 偷偷改成 automatic mode
- 下一轮连续计划优先级更新为：
  1. 继续深审 `SetVectorAsmEnabled` / `RegisterBackend` 在 automatic mode 下的 late hook `SetActiveBackend/RegisterBackend` 路径，优先找下一条“toggle 前后控制态应该保持不变，但 hook/re-register 覆盖了 pre-call intent”的真实问题
  2. 继续核对 `RegisterBackend(...)`、public ABI getter/cache、registered/current snapshot adapter 在 forced/automatic 多次切换后的持续一致性，尤其是 return-time 已收口但后续 helper / cache / external consumer 仍漂走的路径
  3. 若没有 fresh red，再回到 same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

## 5-Question Reboot Check (Phase 55 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 vector-asm toggle control-plane drift：旧 `SetVectorAsmEnabled(False)` 在 late hook nested `ResetToAutomaticBackend(...)` 后会把 pre-toggle forced intent 静默清掉，重新启用 vector asm 时从 forced backend 漂回 automatic best backend。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `SetVectorAsmEnabled` / `RegisterBackend` / helper wrapper 在 forced/automatic 切换、rebuild-hook 嵌套、或 observation-point 漂移上的真实持续一致性问题，尤其是 toggle/register 前后的 pre-call intent 是否被 hook 覆盖。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，`SetVectorAsmEnabled(...)` 也必须像 `TrySetActiveBackend(...)` / `ResetToAutomaticBackend(...)` 一样做 return-time control-plane closure。只要 dispatch-changed hook 能在通知阶段做 nested reset，单次 rebuild 并不能保证 toggle 返回后仍保留调用前 forced intent。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 vector-asm late-reset drift：toggle 现在不会再在通知阶段被一次 automatic reset 静默抹掉 pre-toggle forced backend。 |

- 2026-03-23 最新 RegisterBackend late-force automatic-state closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-lateforce-red-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `RegisterBackend should restore automatic best backend even if a late hook re-forces scalar during notification` 与 `Public API active backend should restore automatic best backend even if a late hook re-forces scalar during RegisterBackend`，`expected: <6> but was: <0>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-lateforce-green-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-lateforce-check-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-lateforce-gate-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-23 19:30:01`
- 这轮根因位于 `RegisterBackend(...)` 的 control-plane postcondition，而不是 backend slot 重注册本身：
  - old path 会 canonicalize table、发布 registered snapshot、再做一次 `InitializeDispatch`
  - 但 `DoInitializeDispatch -> NotifyDispatchChangedHooks` 允许 hook 在 `RegisterBackend(...)` 返回前 nested `SetActiveBackend(sbScalar)`
  - 旧实现没有像 Phase 54/55 那样在 hook 返回后重新核对 forced/automatic mode，导致 return-time active/public ABI 会停在 stale scalar forced fallback
- 最小修复继续遵守“RegisterBackend 不能改写调用前控制态”原则：
  - 入口先保存 `LPreviousBackendForced/LPreviousForcedBackend`
  - 首次 `InitializeDispatch` 后检查 `g_BackendForced/g_ForcedBackend` 是否被 hook 改写
  - 若已漂移，则恢复 pre-call intent 并再做一次 `InitializeDispatch`
  - 这样 `RegisterBackend(...)` 仍会发布新 snapshot 并通知 hook，但不会在 automatic caller 语义下把 return-time state 劫持成 scalar forced fallback
- 下一轮连续计划优先级更新为：
  1. 继续深审 `RegisterBackend(...)` 在 pre-existing forced state 下的 late `ResetToAutomaticBackend(...)` / late `SetActiveBackend(...)` 路径，优先找下一条“重注册返回时控制态应保持调用前 intent，却被 hook 覆盖”的真实问题
  2. 继续核对 `RegisterBackend` / `SetVectorAsmEnabled` / public ABI getter-cache / registered-current adapter 是否还存在“return-time 已收口，但后续 helper / cache / external consumer 仍漂走”的路径
  3. 若没有 fresh red，再回到 same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

## 5-Question Reboot Check (Phase 56 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 `RegisterBackend(...)` control-plane drift：旧实现会在 late hook nested `SetActiveBackend(sbScalar)` 后返回 stale scalar，而不是调用前的 automatic best backend。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `RegisterBackend` / `SetVectorAsmEnabled` / helper wrapper 在 pre-existing forced state、automatic reset、或 rebuild-hook 嵌套路径上的真实持续一致性问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，`RegisterBackend(...)` 也是控制面入口，而不只是数据面 snapshot 发布 helper。只要 dispatch-changed hook 能在通知阶段做 nested force，它同样必须做 return-time control-plane closure。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 RegisterBackend late-force drift：重注册现在不会再在通知阶段被一次 scalar re-force 劫持成 stale forced fallback。 |

### Phase 57: TrySetActiveBackend rollback-restore late-force preservation closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “调用前已经 forced 在 backend A 时，`TrySetActiveBackend(B)` 若在 failure rollback 的最后一次 restore callback 中又被 late `SetActiveBackend(sbScalar)` 劫持，return-time 仍必须恢复 A”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 52/53 的重复表述，而是 `TrySetActiveBackend(...)` 自己的 rollback-restore 分支仍缺少 hook 之后的 control-plane closure
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `TrySetActiveBackendInternal(...)` 在 `LPreviousBackendForced` rollback restore 分支只做一次 `InitializeDispatch`，没有在 hook 通知之后检查 `g_BackendForced/g_ForcedBackend` 是否又被 late force 改写
- [x] 将 `TrySetActiveBackendInternal(...)` 收紧为：previous-forced rollback restore 完成后若 hook 改写了 control-plane mode，则恢复 pre-call forced intent 并再做一次 `InitializeDispatch`
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-23 最新 TrySetActiveBackend rollback-restore late-force closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-rollback-lateforce-red-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `TrySetActiveBackend should preserve the previous forced backend even if a late hook re-forces scalar during rollback restore` 与 `Public API active backend should preserve the previous forced backend even if a late hook re-forces scalar during rollback restore`，`expected: <5> but was: <0>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-rollback-lateforce-green-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-rollback-lateforce-check-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-rollback-lateforce-gate-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-23 20:01:24`
- 这轮根因位于 `TrySetActiveBackendInternal(...)` 的 previous-forced rollback restore postcondition，而不是 earlier failure rollback 本身：
  - Phase 52 已让 `TrySetActiveBackend(...)` 在 late failure 时恢复 pre-call previous forced backend
  - 但旧实现的 `else if LPreviousBackendForced then ... InitializeDispatch` 只做一次 restore reinit
  - 所以 dispatch-changed hook 只要在这最后一次 restore callback 里再 nested `SetActiveBackend(sbScalar)`，return-time current/public ABI 就会再次停在 stale scalar，而不是 previous forced backend A
- 最小修复继续遵守“失败 rollback restore 也不得破坏调用前 forced intent”原则：
  - previous-forced restore reinit 之后立即检查 `g_BackendForced/g_ForcedBackend`
  - 若 hook 再次改写 control-plane mode，则恢复 `LPreviousForcedBackend` 并再做一次 `InitializeDispatch`
  - 这样 `TrySetActiveBackend(...)` 仍保持 Phase 49/50/51/52 的 rollback 语义，但不会在最后一跳 restore callback 里再次被 late scalar force 劫持
- 下一轮连续计划优先级更新为：
  1. 继续深审 `TrySetActiveBackend(...)` failure rollback 的 automatic 分支，优先查还有没有“automatic rollback 已开始恢复，但 hook 在通知阶段又把 current/public ABI 劫持成 stale forced state”的对称问题
  2. 继续核对 `RegisterBackend` / `SetVectorAsmEnabled` / public ABI getter-cache / registered-current adapter 是否还存在“return-time 已收口，但后续 helper / cache / external consumer 仍漂走”的路径
  3. 若没有 fresh red，再回到 same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

## 5-Question Reboot Check (Phase 57 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 `TrySetActiveBackend(...)` rollback-restore drift：旧实现会在 previous forced backend 的最后一次 restore callback 中再次被 late `SetActiveBackend(sbScalar)` 劫持回 scalar。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `TrySetActiveBackend` failure rollback automatic 分支、`RegisterBackend`、或 `SetVectorAsmEnabled` 在 nested hook 路径上的真实持续一致性问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，`TrySetActiveBackend(...)` 的 rollback restore 分支也必须像 `ResetToAutomaticBackend(...)` / `SetVectorAsmEnabled(...)` / `RegisterBackend(...)` 一样做 hook 之后的 control-plane closure。只要 notify callback 里还能 nested force，一次 restore reinit 还不够。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 rollback-restore late-force drift：`TrySetActiveBackend(...)` 现在不会再在 previous forced backend 的最后一次 restore callback 里被再次劫持成 stale scalar forced fallback。 |

### Phase 58: TrySetActiveBackend automatic rollback late-force automatic-state restoration closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “automatic caller 下，`TrySetActiveBackend(B)` 若在 failure rollback 的 automatic callback 中又被 late `SetActiveBackend(sbScalar)` 劫持，return-time 仍必须恢复 automatic best backend”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 54/56/57 的重复表述，而是 `TrySetActiveBackend(...)` 自己的 automatic rollback 分支仍缺少 hook 之后的 control-plane closure
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `TrySetActiveBackendInternal(...)` 在 automatic rollback 分支只做一次 `InitializeDispatch`，没有在 hook 通知之后检查 automatic intent 是否又被 late force 改写
- [x] 将 `TrySetActiveBackendInternal(...)` 收紧为：automatic rollback reinit 完成后，若调用前本来是 automatic mode 且 hook 又把 control-plane 改成 forced mode，则恢复 automatic intent 并再做一次 `InitializeDispatch`
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-23 最新 TrySetActiveBackend automatic rollback late-force closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-automatic-rollback-lateforce-red-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `A failed TrySetActiveBackend in automatic mode must restore the automatic best backend even if a late hook re-forces scalar during rollback` 与 `Public API active backend should restore the automatic best backend even if a late hook re-forces scalar during rollback`，`expected: <6> but was: <0>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-automatic-rollback-lateforce-green-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-automatic-rollback-lateforce-check-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-automatic-rollback-lateforce-gate-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-23 20:36:42`
- 这轮根因位于 `TrySetActiveBackendInternal(...)` 的 automatic rollback postcondition，而不是 previous-forced restore 分支：
  - Phase 49 已让 `TrySetActiveBackend(...)` 在失败回滚时重新跑一次 automatic `InitializeDispatch`
  - 但旧 automatic rollback 分支只发布这一次 rollback snapshot，没有像 Phase 57 的 previous-forced restore 一样在 hook 返回后再次核对 control-plane mode
  - 所以 dispatch-changed hook 只要在 automatic rollback callback 里再 nested `SetActiveBackend(sbScalar)`，return-time current/public ABI 就会再次停在 stale scalar，而不是 automatic best backend
- 最小修复继续遵守“automatic rollback 也不得破坏 automatic caller intent”原则：
  - automatic rollback reinit 之后立即检查 `g_BackendForced`
  - 若调用前本来是 automatic mode 且 hook 再次改写成 forced mode，则清回 automatic intent 并再做一次 `InitializeDispatch`
  - 这样 `TrySetActiveBackend(...)` 仍保持 Phase 49/50/51 的 automatic rollback 语义，但不会在 automatic rollback callback 里再次被 late scalar force 劫持
- 下一轮连续计划优先级更新为：
  1. 继续深审 `RegisterBackend(...)` 在 pre-existing forced state 下若被 late `ResetToAutomaticBackend(...)` / late `SetActiveBackend(...)` 覆盖，return-time 是否还会错误抹掉 pre-call forced intent
  2. 继续核对 `SetVectorAsmEnabled` / public ABI getter-cache / registered-current adapter 是否还存在“return-time 已收口，但后续 helper / cache / external consumer 仍漂走”的路径
  3. 若没有 fresh red，再回到 same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

## 5-Question Reboot Check (Phase 58 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 `TrySetActiveBackend(...)` automatic rollback drift：旧实现会在 automatic rollback callback 中再次被 late `SetActiveBackend(sbScalar)` 劫持回 scalar。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `RegisterBackend` pre-existing forced state、`SetVectorAsmEnabled`、或 public ABI/helper cache 在 nested hook 路径上的真实持续一致性问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，`TrySetActiveBackend(...)` 的 automatic rollback 分支也必须像 previous-forced restore 一样做 hook 之后的 control-plane closure。只要 notify callback 里还能 nested force，一次 automatic reinit 仍然不够。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 automatic rollback late-force drift：`TrySetActiveBackend(...)` 现在不会再在 automatic rollback callback 里被再次劫持成 stale scalar forced fallback。 |

### Phase 59: RegisterBackend previous-forced restore late-reset preservation closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “调用前已经 forced 在 backend A 时，`RegisterBackend(A, ...)` 若在 restore callback 中又被 late `ResetToAutomaticBackend(...)` 劫持，return-time 仍必须恢复 A”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 55/56/58 的重复表述，而是 `RegisterBackend(...)` 自己的 restore reinit 分支仍缺少第二层 hook 之后的 control-plane closure
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `RegisterBackend(...)` 首次 `InitializeDispatch` 后虽然会恢复 pre-call intent，但 restore reinit 完成后没有再次检查 hook 是否又把 forced/automatic mode 改写
- [x] 将 `RegisterBackend(...)` 收紧为：restore reinit 完成后若 hook 再次改写了 forced/automatic mode，则恢复 pre-call intent 并再做一次 `InitializeDispatch`
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-23 最新 RegisterBackend previous-forced restore late-reset closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-restore-latereset-red-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `RegisterBackend should preserve the previous forced backend even if a late hook resets to automatic during restore notification` 与 `Public API active backend should preserve the previous forced backend even if a late hook resets to automatic during RegisterBackend restore notification`，`expected: <5> but was: <6>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-restore-latereset-green-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-restore-latereset-check-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-restore-latereset-gate-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-23 21:22:28`
- 这轮根因位于 `RegisterBackend(...)` 的 previous-forced restore postcondition，而不是首次 late-reset 漂移本身：
  - Phase 56 已让 `RegisterBackend(...)` 在 hook 首次改写 control-plane mode 时恢复 pre-call intent
  - 但旧实现的 restore reinit 仍只做一次，没有像 `TrySetActiveBackend(...)` 那样在 restore callback 之后再次核对 mode
  - 所以 dispatch-changed hook 只要在这次 restore callback 里再 nested `ResetToAutomaticBackend(...)`，return-time current/public ABI 就会再次停在 automatic best backend，而不是 previous forced backend A
- 最小修复继续遵守“RegisterBackend 不得破坏调用前 forced intent”原则：
  - restore reinit 之后立即检查 `g_BackendForced/g_ForcedBackend`
  - 若 hook 再次改写 control-plane mode，则恢复 `LPreviousBackendForced/LPreviousForcedBackend` 并再做一次 `InitializeDispatch`
  - 这样 `RegisterBackend(...)` 仍保持 Phase 56 的 automatic-mode 收口语义，但不会在 previous-forced restore callback 里再次被 late automatic reset 劫持
- 下一轮连续计划优先级更新为：
  1. 继续深审 `RegisterBackend(...)` / `SetVectorAsmEnabled(...)` / public ABI getter-cache 在 nested hook 路径上是否还有“return-time 正确，但 helper/cache/intent 后续仍漂走”的合同缺口
  2. 优先尝试把 `RegisterBackend(...)` previous-forced restore 回调里的 late `SetActiveBackend(sbScalar)` 路径打成独立 regression guard，确认这类二次 force/reset 都被守住
  3. 若没有 fresh red，再回到 same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

## 5-Question Reboot Check (Phase 59 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 `RegisterBackend(...)` previous-forced restore drift：旧实现会在 restore callback 中再次被 late `ResetToAutomaticBackend(...)` 劫持回 automatic best backend。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `RegisterBackend` / `SetVectorAsmEnabled` / public ABI/helper cache 在 nested hook 路径上的真实持续一致性问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，`RegisterBackend(...)` 的 previous-forced restore 分支也必须像 `TrySetActiveBackend(...)` 一样做第二层 hook 之后的 control-plane closure。只要 restore callback 里还能 nested reset，一次 restore reinit 仍然不够。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 RegisterBackend restore late-reset drift：`RegisterBackend(...)` 现在不会再在 previous-forced restore callback 里被再次劫持成 automatic best backend。 |

### Phase 60: SetVectorAsmEnabled previous-forced restore late-reset preservation closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “调用前已经 forced 在 backend A 时，`SetVectorAsmEnabled(False)` 若在 restore callback 中又被 late `ResetToAutomaticBackend(...)` 劫持，后续 `SetVectorAsmEnabled(True)` 仍必须恢复 A”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 55/59 的重复表述，而是 `SetVectorAsmEnabled(...)` 自己的 restore reinit 分支仍缺少第二层 hook 之后的 control-plane closure
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `SetVectorAsmEnabled(...)` 首次 restore reinit 后虽然会恢复 pre-toggle intent，但 restore reinit 完成后没有再次检查 hook 是否又把 forced/automatic mode 改写
- [x] 将 `SetVectorAsmEnabled(...)` 收紧为：restore reinit 完成后若 hook 再次改写了 forced/automatic mode，则恢复 pre-toggle intent 并再做一次 `InitializeDispatch`
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-23 最新 SetVectorAsmEnabled previous-forced restore late-reset closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-restore-latereset-red-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `Re-enabling vector asm should preserve the previously forced backend even if a late hook resets to automatic during restore callback` 与 `Public API should preserve the previously forced backend after vector-asm re-enable even if a late hook resets to automatic during restore callback`，`expected: <1> but was: <6>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-restore-latereset-green-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-restore-latereset-check-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-restore-latereset-gate-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-23 21:49:12`
- 这轮根因位于 `SetVectorAsmEnabled(...)` 的 previous-forced restore postcondition，而不是第一次 late-reset 漂移本身：
  - Phase 55 已让 `SetVectorAsmEnabled(...)` 在 hook 首次改写 control-plane mode 时恢复 pre-toggle forced intent
  - 但旧实现的 restore reinit 仍只做一次，没有像 Phase 59 的 `RegisterBackend(...)` 一样在 restore callback 之后再次核对 mode
  - 所以 dispatch-changed hook 只要在 restore callback 里再 nested `ResetToAutomaticBackend(...)`，后续重新 `SetVectorAsmEnabled(True)` 时 active/public ABI 就会再次停在 automatic best backend，而不是 previous forced backend A
- 最小修复继续遵守“feature toggle 不得破坏调用前 forced intent”原则：
  - restore reinit 之后立即检查 `g_BackendForced/g_ForcedBackend`
  - 若 hook 再次改写 control-plane mode，则恢复 `LPreviousBackendForced/LPreviousForcedBackend` 并再做一次 `InitializeDispatch`
  - 这样 `SetVectorAsmEnabled(...)` 仍保持 Phase 55 的 toggle 语义，但不会在 previous-forced restore callback 里再次被 late automatic reset 劫持
- 下一轮连续计划优先级更新为：
  1. 继续深审 `SetVectorAsmEnabled(...)` / `RegisterBackend(...)` previous-forced restore callback 里的 late `SetActiveBackend(sbScalar)` 路径，确认二次 force/reset 是否都被独立 regression guard 守住
  2. 继续核对 public ABI getter-cache / helper cache 是否还存在“return-time 已收口，但后续 helper / cache / external consumer 仍漂走”的路径
  3. 若没有 fresh red，再回到 same-process concurrent / toggle / re-register 相邻路径，继续做证据驱动排查

## 5-Question Reboot Check (Phase 60 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 `SetVectorAsmEnabled(...)` previous-forced restore drift：旧实现会在 restore callback 中再次被 late `ResetToAutomaticBackend(...)` 劫持回 automatic best backend。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `SetVectorAsmEnabled` / `RegisterBackend` / public ABI/helper cache 在 nested hook 路径上的真实持续一致性问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，`SetVectorAsmEnabled(...)` 的 previous-forced restore 分支也必须像 `RegisterBackend(...)` / `TrySetActiveBackend(...)` 一样做第二层 hook 之后的 control-plane closure。只要 restore callback 里还能 nested reset，一次 restore reinit 仍然不够。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 vector-asm restore late-reset drift：`SetVectorAsmEnabled(...)` 现在不会再在 previous-forced restore callback 里被再次劫持成 automatic best backend。 |

### Phase 61: ResetToAutomaticBackend restore-callback late-force second-layer closure closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “`ResetToAutomaticBackend(...)` 即使在 automatic restore callback 中再次被 late `SetActiveBackend(sbScalar)` 劫持，return-time 仍必须恢复 automatic best backend”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 54 的重复表述，而是 `ResetToAutomaticBackend(...)` 自己的第二次 restore reinit 之后仍缺少对二次 late force 的收口
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `ResetToAutomaticBackend(...)` 只在第一次 automatic reinit 之后做一层 closure；若第二次 restore callback 再次 resurrect forced mode，函数 return-time current/public ABI 仍会停在 scalar
- [x] 将 `ResetToAutomaticBackend(...)` 收紧为：第二次 automatic restore reinit 完成后若 hook 再次改写了 `g_BackendForced/g_ForcedBackend`，则再次清回 automatic intent 并再做一次 `InitializeDispatch`
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-23 最新 ResetToAutomaticBackend restore-callback late-force closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-reset-restore-lateforce-red-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `ResetToAutomaticBackend should still restore automatic best backend even if a late hook re-forces scalar during restore callback` 与 `Public API active backend should still restore automatic best backend even if a late hook re-forces scalar during restore callback`，`expected: <6> but was: <0>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-reset-restore-lateforce-green-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-reset-restore-lateforce-check-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-reset-restore-lateforce-gate-20260323-rerun bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-23 22:18:51`
- 这轮根因位于 `ResetToAutomaticBackend(...)` 的 automatic restore postcondition，而不是第一次 late-force 漂移本身：
  - Phase 54 已让 `ResetToAutomaticBackend(...)` 在第一次 automatic `InitializeDispatch` 之后清掉一次 hook resurrect 的 forced mode
  - 但旧实现没有继续覆盖第二次 restore callback；hook 若在这次通知里再次 nested `SetActiveBackend(sbScalar)`，return-time state 仍会再次停在 scalar
  - 所以 `ResetToAutomaticBackend(...)` 的 automatic caller 语义还需要第二层 closure，不能只相信第一次 restore reinit 的结果
- 最小修复继续遵守“reset-to-automatic 的 return-time state 必须真的处于 automatic mode”原则：
  - 第二次 restore reinit 之后立即检查 `g_BackendForced/g_ForcedBackend`
  - 若 hook 再次 resurrect forced mode，则再次清回 automatic intent 并再做一次 `InitializeDispatch`
  - 这样 automatic restore callback 即使再 late force scalar，也不会把 dispatch API / public ABI 留在 stale scalar forced fallback
- 下一轮连续计划优先级更新为：
  1. 继续深审 `RegisterBackend(...)` previous-forced restore callback 里的 late `SetActiveBackend(sbScalar)` 路径，确认 second-layer closure 是否已被独立 regression guard 守住
  2. 继续深审 `SetVectorAsmEnabled(...)` previous-forced restore callback 里的 late `SetActiveBackend(sbScalar)` 路径，确认 toggle restore 不会再次把 current/public ABI 劫持成 scalar
  3. 若这两条都已被现有 closure 顺带覆盖，则转向 public ABI getter-cache / helper cache，继续查“return-time 已收口，但后续 helper / cache / external consumer 仍漂走”的路径

## 5-Question Reboot Check (Phase 61 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 `ResetToAutomaticBackend(...)` automatic restore drift：旧实现会在第二次 restore callback 中再次被 late `SetActiveBackend(sbScalar)` 劫持回 scalar。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `RegisterBackend` / `SetVectorAsmEnabled` restore callback 里的 late scalar force，或者 public ABI/helper cache 在 nested hook 路径上的真实持续一致性问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，`ResetToAutomaticBackend(...)` 的 automatic restore 分支也需要第二层 hook 之后的 control-plane closure。只要 restore callback 里还能再次 nested force，一次 closure 仍然不够。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 reset-restore late-force drift：`ResetToAutomaticBackend(...)` 现在不会再在第二次 automatic restore callback 里被再次劫持成 stale scalar forced fallback。 |

### Phase 62: TrySetActiveBackend automatic rollback restore-callback late-force second-layer closure closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 red tests，锁定 “automatic caller 下，`TrySetActiveBackend(...)` 若在 rollback restore callback 中再次被 late `SetActiveBackend(sbScalar)` 劫持，return-time 仍必须恢复 automatic best backend”
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先拿 red，确认问题不是 Phase 58/61 的重复表述，而是 `TrySetActiveBackend(...)` automatic rollback 自己的第二次 restore reinit 之后仍缺少对二次 late force 的收口
- [x] 确认 `src/fafafa.core.simd.dispatch.pas` 的根因位于 `TrySetActiveBackendInternal(...)` automatic rollback 分支只在第一次 rollback reinit 之后做一层 closure；若第二次 restore callback 再次 resurrect forced mode，函数 return-time current/public ABI 仍会停在 scalar
- [x] 将 `TrySetActiveBackend(...)` 的 automatic rollback 分支收紧为：第二次 automatic restore reinit 完成后若 hook 再次改写了 `g_BackendForced/g_ForcedBackend`，则再次清回 automatic intent 并再做一次 `InitializeDispatch`
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 复验
- **Status:** complete

- 2026-03-23 最新 TrySetActiveBackend automatic rollback restore-callback late-force closeout 证据：
  - red: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-automatic-rollback-restore-lateforce-red-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> FAIL（命中 `A failed TrySetActiveBackend in automatic mode must still restore automatic best backend even if a late hook re-forces scalar during rollback restore callback` 与 `Public API active backend should still restore automatic best backend even if a late hook re-forces scalar during rollback restore callback`，`expected: <6> but was: <0>`）
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-automatic-rollback-restore-lateforce-green-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - green: `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-automatic-rollback-restore-lateforce-check-20260323 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - green: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/automatic-rollback-restore-lateforce-gate-20260323-rerun bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-23 23:03:40`
- 这轮根因位于 `TrySetActiveBackend(...)` automatic rollback 的 restore postcondition，而不是第一次 late-force 漂移本身：
  - Phase 58 已让 failed `TrySetActiveBackend(...)` 在第一次 automatic rollback callback 之后清掉一次 hook resurrect 的 forced mode
  - 但旧实现没有继续覆盖第二次 restore callback；hook 若在这次通知里再次 nested `SetActiveBackend(sbScalar)`，return-time state 仍会再次停在 scalar
  - 所以 automatic rollback caller 语义也需要 second-layer closure，不能只相信第一次 restore reinit 的结果
- 最小修复继续遵守“automatic rollback 的 return-time state 必须真的处于 automatic mode”原则：
  - 第二次 restore reinit 之后立即检查 `g_BackendForced/g_ForcedBackend`
  - 若 hook 再次 resurrect forced mode，则再次清回 automatic intent 并再做一次 `InitializeDispatch`
  - 这样 failed `TrySetActiveBackend(...)` 的 automatic rollback callback 即使再 late force scalar，也不会把 dispatch API / public ABI 留在 stale scalar forced fallback
- 下一轮连续计划优先级更新为：
  1. 继续深审 `RegisterBackend(...)` previous-forced restore callback 里的 late `SetActiveBackend(sbScalar)` 路径，确认 second-layer closure 是否已被独立 regression guard 守住
  2. 继续深审 `SetVectorAsmEnabled(...)` previous-forced restore callback 里的 late `SetActiveBackend(sbScalar)` 路径，确认 toggle restore 不会再次把 current/public ABI 劫持成 scalar
  3. 继续留意环境层证据链：若 gate 需走大产物链，优先避开满掉的 `/tmp` tmpfs，使用 worktree-local `SIMD_OUTPUT_ROOT/TMPDIR`

## 5-Question Reboot Check (Phase 62 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新又收敛了一条 `TrySetActiveBackend(...)` automatic rollback restore drift：旧实现会在第二次 rollback restore callback 中再次被 late `SetActiveBackend(sbScalar)` 劫持回 scalar。 |
| Where am I going? | 下一轮继续从实现层深审，优先找下一条 `RegisterBackend` / `SetVectorAsmEnabled` restore callback 里的 late scalar force，或者 public ABI/helper cache 在 nested hook 路径上的真实持续一致性问题。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，`TrySetActiveBackend(...)` 的 automatic rollback 分支也需要第二层 hook 之后的 control-plane closure。只要 restore callback 里还能再次 nested force，一次 closure 仍然不够。 |
| What have I done? | 已完成多轮 runner/guard、capability/rebuild、dispatch/public ABI 合同修复，并持续同步计划文件。本轮最新又确认并修复了 automatic-rollback-restore late-force drift：failed `TrySetActiveBackend(...)` 现在不会再在第二次 rollback restore callback 里被再次劫持成 stale scalar forced fallback。 |

### Phase 63: previous-forced restore late-force symmetry regression guard closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增四条 deterministic guards，显式覆盖 `RegisterBackend(...)` / `SetVectorAsmEnabled(...)` 的 previous-forced restore callback 中再次 late `SetActiveBackend(sbScalar)` 的对称路径
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 先验证这四条新护栏是 fresh red 还是即刻 green，避免对已守住的生产代码做重复补丁
- [x] 确认当前 `src/fafafa.core.simd.dispatch.pas` 的 second-layer closure 已经覆盖这两条路径，本轮不修改生产代码
- [x] 用 fresh release `check`、fresh release `gate` 复验新增护栏没有引入回归
- **Status:** complete

- 2026-03-24 最新 previous-forced restore late-force symmetry closeout 证据：
  - targeted suite: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch63-lateforce-restore-red-or-green-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - check: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch63-lateforce-restore-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - gate: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch63-lateforce-restore-gate-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-24 01:03:16`
- 这轮结论是“测试护栏缺口”，不是新的生产 bug：
  - `RegisterBackend(...)` 与 `SetVectorAsmEnabled(...)` 之前虽然已经分别在 previous-forced restore 路径上补过 late-reset second-layer closure
  - 但还缺少一组独立回归护栏来证明“如果 hook 不是 `ResetToAutomaticBackend(...)`，而是再次 `SetActiveBackend(sbScalar)`，return-time state 也不会再被劫持”
  - 新增四条护栏后，fresh targeted suite 直接转绿，说明当前实现里的 second-layer closure 已经把这条对称 late-force 路径守住
- 下一轮连续计划优先级更新为：
  1. 从 `RegisterBackend` / `SetVectorAsmEnabled` 的 late-force 候选切换到 public ABI getter-cache / helper wrapper / external consumer 的 return-after-drift 路径
  2. 优先查 `GetSimdPublicApi` / backend pod info / helper wrapper 在 nested hook 之后是否还存在“控制面已收口，但 consumer 可见 metadata/helper 仍漂移”的 fresh red
  3. 继续维持 worktree-local `SIMD_OUTPUT_ROOT/TMPDIR`，避免 `/tmp` tmpfs 对长链 gate 造成噪音

## 5-Question Reboot Check (Phase 63 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新把 `RegisterBackend(...)` / `SetVectorAsmEnabled(...)` previous-forced restore callback 里的 late scalar force 做成了独立 regression guards。 |
| Where am I going? | 下一轮转向 public ABI getter-cache / helper wrapper / external consumer return-after-drift，优先找 fresh red，而不是继续在已证实闭环的 restore late-force 路径上重复挖。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，`RegisterBackend(...)` / `SetVectorAsmEnabled(...)` 当前 second-layer closure 已经守住 previous-forced restore + late `SetActiveBackend(sbScalar)` 的对称路径，缺的是独立 regression guard，而不是生产代码本身。 |
| What have I done? | 已新增四条对称护栏并完成 fresh release suite/check/gate 复验，把这条候选从“怀疑缺口”收敛成“已证实受保护”，随后可安全切换到新的 public ABI/helper drift 候选。 |

### Phase 64: public ABI backend text getter concurrent snapshot guard closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TPublicAbiBackendTextReadWorker` 与 `Test_Concurrent_PublicAbiBackendText_RegisterBackend_ReadConsistency`，用两套固定长度的 A/B name/description payload 对同一 backend 做持续 `RegisterBackend(...)` 切换，同时并发读取 `GetSimdBackendNamePtr/GetSimdBackendDescriptionPtr`
- [x] 用 fresh release `TTestCase_SimdConcurrentPublicAbi` 先验证这条候选是 fresh red 还是即刻 green，避免把并发怀疑直接误记成生产 bug
- [x] 确认当前 `src/fafafa.core.simd.public_abi.impl.inc` 的 text getter 路径在现有宿主机和压力级别下没有复现新的 nil / torn / mixed text 问题，本轮收口为 regression guard closeout，而不是生产实现补丁
- [x] 继续做 5 轮重复压测，并用 fresh release `check` / `gate` 完整收尾
- **Status:** complete

- 2026-03-24 最新 public ABI backend text concurrent guard closeout 证据：
  - targeted suite: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch64-publicabi-textcache-concurrent-red-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi` -> PASS，`[LEAK] OK`
  - repeated stress: `.simd-output/batch64-publicabi-textcache-repeat-20260324-{1..5}` 共 5 轮，全部 `All tests passed!`
  - check: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch64-publicabi-textcache-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - gate: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch64-publicabi-textcache-gate-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-24 08:57:37`
- 这轮结论仍是“测试护栏缺口”，不是新的生产 bug：
  - Phase 19 已经修过 text getter 的 stale-cache 问题，fresh getter 会刷新到最新 `BackendInfo.Name/Description`
  - 本轮真正缺的是 machine-readable 并发护栏，去证明 `RegisterBackend(...)` 持续切换两套文本快照时，外部 `PAnsiChar` getter 不会吐出 `nil`、残缺字符串、或 A/B 混搭文本
  - 新增 fixed-length payload + `ThreadSwitch` 压测后，fresh targeted suite 与 5 轮重复压测都只观察到完整的 A/B snapshot，因此当前实现至少在现有宿主机上没有暴露新的 text getter 并发缺陷
- 下一轮连续计划优先级更新为：
  1. 继续沿 public ABI getter-cache / helper wrapper / external consumer 路径深审，优先找 `GetBackendOps(backend)`、consumer-side cached table、和 current-active helper 的 fresh red
  2. 继续核对 nested hook / re-register / toggle 之后，是否还存在“控制面 return-time 已收口，但 consumer 可见 getter/helper 仍漂移”的真实问题
  3. 持续使用 worktree-local `SIMD_OUTPUT_ROOT/TMPDIR`，避免 `/tmp` tmpfs 噪音影响长链 gate

## 5-Question Reboot Check (Phase 64 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_SimdConcurrentPublicAbi`、5 轮重复压测、fresh `check`、fresh `gate` 都已重新通过；本轮最新把 public ABI backend text getter 的 concurrent `RegisterBackend(...)` 候选收口成了独立 regression guard。 |
| Where am I going? | 下一轮继续深审 public ABI getter-cache / helper wrapper / external consumer return-after-drift，优先找 `GetBackendOps(backend)`、consumer-side cached table、以及 current-active helper 的 fresh red。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，Phase 19 修过 stale-cache 之后，public ABI backend text getter 在现有宿主机上没有暴露新的并发 text drift；缺的是可持续守住这条语义的 machine-readable guard。 |
| What have I done? | 已为 public ABI backend text getter 补上并发读写护栏，并用 fresh release targeted suite、5 轮重复压测、check、gate 把这条候选收口为“guard green”，随后可继续切到下一条真实 getter/helper drift 候选。 |

### Phase 65: public ABI cached-table snapshot metadata guard closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicApi_CachedTable_Preserves_PreviousSnapshot_Metadata_Across_Rebind`，锁定“重绑后 fresh getter 必须发布新 table，而旧 cached table 的 `ActiveBackendId/ActiveFlags` 仍保持旧 snapshot”
- [x] 用 fresh release `TTestCase_PublicAbi` 先验证这条 cached-table consumer 合同是 fresh red 还是即刻 green，避免在没有证据前改动 `public_abi.impl.inc`
- [x] 确认当前 `src/fafafa.core.simd.public_abi.impl.inc` 的 owned-state 发布模型已经满足这条 cached-table snapshot 语义，本轮不修改生产实现
- [x] 用 fresh release `check`、fresh release `gate` 复验新增护栏没有引入回归
- **Status:** complete

- 2026-03-24 最新 public ABI cached-table snapshot closeout 证据：
  - targeted suite: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch65-publicapi-cachedtable-red-or-green-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - check: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch65-publicapi-cachedtable-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - gate: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch65-publicapi-cachedtable-gate-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-24 09:14:13`
- 这轮结论仍是“测试护栏缺口”，不是新的生产 bug：
  - 文档一直承诺 `GetSimdPublicApi` 在 backend 切换后会发布一张 fresh table，而调用方手里的旧 cached table 仍可作为旧 snapshot 使用
  - 之前已有 `Test_PublicApi_CachedTable_RemainsCallable_Across_Rebind`，但它只证明旧 table 还能调用 data-plane，没有证明 metadata 是否也保持旧 snapshot，更没有证明 fresh getter 会返回不同 table 指针
  - 新增测试后，fresh suite 直接转绿，说明当前 `g_SimdPublicApiStatePtr + g_SimdPublicApiOwnedHead` 的 owned-state 发布模型已经把“fresh table != old cached table，且旧 metadata 不会被原地改写”这条 consumer-side 语义守住
- 下一轮连续计划优先级更新为：
  1. 继续深审 current-active helper / backend adapter / external consumer 边界，优先找 `GetBackendOps(backend)` 并发读取、current-active helper、以及 text-pointer lifetime 的 fresh red
  2. 继续核对 public ABI getter/cache 在 repeated re-register / toggle 之后，是否还存在“旧 pointer 仍可调用，但 helper 语义已悄悄漂移”的真实问题
  3. 持续使用 worktree-local `SIMD_OUTPUT_ROOT/TMPDIR`，并保持“fresh red-or-green -> check -> gate -> 文档 -> commit”的批次节奏

## 5-Question Reboot Check (Phase 65 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新把 public ABI cached-table snapshot metadata 的 consumer-side 合同补成了独立 regression guard。 |
| Where am I going? | 下一轮继续深审 current-active helper / backend adapter / external consumer 边界，优先找 `GetBackendOps(backend)` 并发读取、current-active helper、以及 text-pointer lifetime 的 fresh red。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，当前 public ABI owned-state 发布模型不仅能让旧 cached table 继续 callable，也已经能保证旧 metadata 保持旧 snapshot、fresh getter 返回不同 table 指针。 |
| What have I done? | 已为 public ABI cached-table snapshot metadata 补上更强的 consumer-side guard，并用 fresh release suite/check/gate 把这条候选收口为“guard green”，随后可继续切向更可能是实现缺陷的 helper/pointer lifetime 候选。 |

### Phase 66: public ABI backend text pointer lifetime re-register churn guard closeout
- [x] 将 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 的 `Test_PublicAbi_BackendText_Getters_PreviousPointers_RemainValid_After_Refresh` 从“仅做同尺寸字符串分配 churn”升级为“真实 repeated `RegisterBackendText(...)` refresh churn”
- [x] 用 fresh release `TTestCase_PublicAbi` 先验证这条 pointer-lifetime 候选是 fresh red 还是即刻 green，避免在没有证据前改动 `src/fafafa.core.simd.public_abi.impl.inc`
- [x] 确认当前 owned-state publication 已满足更强语义：latest getter 每轮都刷新到当前 churn 文本，而历史 `PAnsiChar` 指针在 repeated refresh 压力下仍保持有效；本轮不修改生产实现
- [x] 用 fresh release `check`、fresh release `gate` 复验新增护栏没有引入回归
- **Status:** complete

- 2026-03-24 最新 public ABI backend text pointer lifetime churn closeout 证据：
  - targeted suite: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch66-text-pointer-lifetime-red-or-green-rerun-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - check: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch66-text-pointer-lifetime-check-rerun-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - gate: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch66-text-pointer-lifetime-gate-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-24 10:26:49`
- 这轮结论仍是“测试护栏缺口”，不是新的生产 bug：
  - 旧 pointer-lifetime 测试虽然会制造大量 churn 文本，但它没有真实触发 backend text refresh publication，因此只能半证明“堆内存 churn 不会马上打坏旧指针”
  - 新测试把 churn 改成真实 repeated `RegisterBackendText(...)`，并在每轮断言 latest getter 立即看到当前文本、每 32 轮回看一次完整 history，直接覆盖了 consumer 真正关心的 refresh-after-pointer-observe 路径
  - fresh targeted suite、fresh `check`、fresh `gate` 全绿，说明当前 `g_SimdPublicApiOwnedHead` / backend text owned-state 机制在现有宿主机上已经守住“新 getter 跟新文本，旧 pointer 仍有效”这条更强 consumer-side 语义
- 下一轮连续计划优先级更新为：
  1. 从 text-pointer lifetime 候选切回 current-active helper / backend adapter / external consumer 边界，优先找 `GetBackendOps(backend)` 并发读取与 current-active helper 的 fresh red
  2. 继续核对 repeated `RegisterBackend(...)` / toggle / hook 之后，是否还存在“控制面 return-time 已收口，但 helper/public view 仍漂移”的真实问题
  3. 持续使用 worktree-local `SIMD_OUTPUT_ROOT/TMPDIR`，并保持“fresh red-or-green -> check -> gate -> 文档 -> commit”的批次节奏

## 5-Question Reboot Check (Phase 66 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 都已重新通过；本轮最新把 public ABI backend text pointer lifetime 的 refresh-churn 合同补成了真实 repeated re-register regression guard。 |
| Where am I going? | 下一轮继续深审 current-active helper / backend adapter / external consumer 边界，优先找 `GetBackendOps(backend)` 并发读取、current-active helper、以及 helper/public-view stale drift 的 fresh red。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，当前 owned-state publication 不只是能扛住“无害 heap churn”，也能扛住真实 backend text refresh churn：fresh getter 会跟随当前文本，历史 text pointers 仍保持有效。 |
| What have I done? | 已把 pointer-lifetime 测试升级成真实 repeated re-register churn 护栏，并用 fresh release suite/check/gate 把这条候选收口为“guard green”；随后可继续切回更像实现缺陷的 helper/adapter 候选。 |

### Phase 67: backend adapter `GetBackendOps` concurrent register/read guard closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TBackendOpsReadWorker` 与 `Test_Concurrent_BackendOps_RegisterBackend_ReadConsistency`，对同一 backend 持续 `RegisterBackend(...)` 切换 enabled/disabled 两套 table，同时并发读取 `GetBackendOps(backend)`
- [x] 用 fresh release `TTestCase_SimdConcurrentFramework` 先验证这条 adapter/helper 候选是 fresh red 还是即刻 green，避免对已切到 published snapshot 的实现做无证据补丁
- [x] 确认当前 `src/fafafa.core.simd.backend.adapter.pas` + `TryGetRegisteredBackendDispatchTable(...)` 的 published-snapshot 读取路径已经满足这条更强语义：`GetBackendOps` round-trip 回 dispatch table 后，metadata 与代表性 slots 始终落在完整的 enabled/disabled snapshot，而不会混搭
- [x] 用 fresh release `check`、fresh release `gate` 复验新增护栏没有引入回归
- **Status:** complete

### Phase 68: framework helper `GetCurrentBackend` concurrent register/read guard closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TCurrentBackendReadWorker` 与 `Test_Concurrent_CurrentBackend_RegisterBackend_ReadConsistency`，对当前 non-scalar backend 持续 `RegisterBackend(...)` 切换 enabled/disabled 两套 table，同时并发读取 `GetCurrentBackend`
- [x] 用 fresh release `TTestCase_SimdConcurrentFramework` 先验证这条 current-active helper 候选是 fresh red 还是即刻 green，避免把跨 helper 的独立调用漂移误判成 `GetCurrentBackend` 自身 bug
- [x] 确认当前 `src/fafafa.core.simd.framework.impl.inc` 的 `GetCurrentBackend -> GetActiveBackend -> current published dispatch snapshot` 读取链已经满足这条 helper 级语义：reader 只观察到完整的 enabled active backend 或 disabled 后的 fallback backend，不会掉进第三种 impossible backend id
- [x] 用 fresh release `check`、fresh release `gate` 复验新增护栏没有引入回归
- **Status:** complete

- 2026-03-24 最新 `GetCurrentBackend` concurrent guard closeout 证据：
  - targeted suite: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch68-currentbackend-concurrent-red-or-green-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework` -> PASS，`[LEAK] OK`
  - check: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch68-currentbackend-concurrent-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - gate: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch68-currentbackend-concurrent-gate-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-24 10:59:32`
- 这轮结论仍是“测试护栏缺口”，不是新的生产 bug：
  - `GetCurrentBackendInfo`、public ABI active metadata、active backend pod info 之前都已经补过 concurrent snapshot 修复或护栏，但 `GetCurrentBackend` 这个最薄 façade 还没有独立的 machine-readable re-register 压测
  - 新测试显式把当前 active backend 重注册成 disabled table，要求 reader 只能看到“原 active backend”或“真实 fallback backend”两种完整状态
  - fresh targeted suite、fresh `check`、fresh `gate` 全绿，说明当前 active backend selection 已稳定落在 published current dispatch snapshot 上，没有暴露新的 helper-level impossible backend id
- 下一轮连续计划优先级更新为：
  1. 继续沿 current-active helper 边界深审，优先补 `GetCurrentBackend` 在 `SetVectorAsmEnabled(...)` repeated toggle 下的独立 guard，确认 helper 在 batch rebuild 场景下也没有回退到半重建 backend id
  2. 若单 helper 继续全绿，再转向 external consumer/back-to-back helper usage 的文档边界，明确哪些跨 API 独立调用不承诺原子配对，避免把预期外的 pair drift 误记成实现 bug
  3. 持续使用 worktree-local `SIMD_OUTPUT_ROOT/TMPDIR`，并保持“fresh red-or-green -> check -> gate -> 文档 -> commit”的批次节奏

## 5-Question Reboot Check (Phase 68 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 都已重新通过；本轮最新把 framework helper `GetCurrentBackend` 的 concurrent re-register 合同补成了独立 regression guard。 |
| Where am I going? | 下一轮继续深审 current-active helper 边界，优先看 `GetCurrentBackend` 在 vector-asm batch rebuild 下是否也需要独立 guard；若 helper 级别继续全绿，再转向 external consumer/back-to-back helper 的文档边界。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，当前 `GetCurrentBackend -> GetActiveBackend -> current published dispatch snapshot` 读取链已经守住 re-register churn 下的 helper 级一致性：reader 不会掉进第三种 impossible backend id。 |
| What have I done? | 已为 `GetCurrentBackend` 补上 concurrent register/read 护栏，并用 fresh release suite/check/gate 把这条候选收口为“guard green”；当前 worktree 只增加测试证据，没有生产代码改动。 |

### Phase 69: framework helper `GetCurrentBackend` concurrent vector-asm toggle/read guard closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `Test_Concurrent_CurrentBackend_VectorAsmToggle_ReadConsistency`，对 repeated `SetVectorAsmEnabled(True/False)` 并发 churn 下的 `GetCurrentBackend` 做独立 guard
- [x] 用 fresh release `TTestCase_SimdConcurrentFramework` 先验证这条 current-active helper 候选是 fresh red 还是即刻 green，避免对已有 published snapshot 读取链做无证据补丁
- [x] 确认当前 `GetCurrentBackend -> GetActiveBackend -> current published dispatch snapshot` 路径已经满足这条更强语义：reader 只观察到 enabled/disabled 两种完整 active backend 状态，而不会掉进第三种 impossible backend id
- [x] 将这轮结果收口为 closeout roadmap 与 planning/worker 同步的 Phase 69，而不是新的生产修复
- **Status:** complete

- 2026-03-24 最新 Batch 69 证据：
  - targeted suite: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch69-currentbackend-toggle-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework` -> PASS，`[LEAK] OK`
- 这轮结论仍是“测试护栏缺口”，不是新的生产 bug：
  - repeated `SetVectorAsmEnabled(...)` batch rebuild 场景此前已经在 `GetCurrentBackendInfo` / public ABI active metadata 上有护栏，但 `GetCurrentBackend` 自身还缺少独立的 machine-readable toggle/read 压测
  - fresh targeted suite 直接转绿，说明当前 helper 读取链已经守住了 vector-asm toggle 下的 helper-level read consistency

### Phase 70: snapshot-boundary documentation and stable-state parity closeout
- [x] 新建 `docs/plans/2026-03-24-simd-audit-closeout-roadmap.md`，把这轮收口目标、非阻塞项和验收标准写死
- [x] 更新 `docs/fafafa.core.simd.api.md` 与 `docs/fafafa.core.simd.publicabi.md`，明确 single-call snapshot 与 cross-call atomic pairing 的边界
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 deterministic stable-state parity tests，显式守住控制面返回后的稳定态收敛
- [x] 用 fresh release targeted suite、fresh release `check`、fresh release `gate` 复验这一轮 closeout 只引入 docs/test 护栏，没有新回归
- [x] 同步更新 `task_plan.md`、`findings.md`、`progress.md`、`workers/worker0.md`
- **Status:** complete

- 2026-03-24 最新 Batch 70 证据：
  - targeted suite: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch70-stablestate-targeted-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi,TTestCase_SimdConcurrentFramework` -> PASS，`[LEAK] OK`
  - check: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch70-stablestate-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - gate: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch70-stablestate-gate-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-24 11:49:31`
- 这轮结论是 closeout，不是继续深审：
  - 新增测试证明控制面 API 返回后，`GetCurrentBackend` / `GetCurrentBackendInfo` / `GetDispatchTable` / `GetSimdPublicApi` / `TryGetSimdBackendPodInfo(current)` 会重新收敛到同一稳定态
  - 新增文档明确“单次 getter 的 published snapshot”与“并发 control-plane 写入下不承诺跨调用原子配对”的边界
  - 这轮没有生产代码改动，当前 SIMD 审计批次已进入 merge-ready 状态
- 下一轮连续计划优先级更新为：
  1. 先合并/交接当前 `simd-contract-audit` worktree 的 closeout 结果，不再把无限深审当默认路径
  2. 非阻塞 follow-up 只剩外部证据类事项：`arm64` / `riscv64` asm host evidence 与 Windows native evidence
  3. 只有出现 fresh red、明确的新合同问题，或用户明确要求重新深挖时，才重开下一轮实现层深审

### Phase 71: pushed-main external evidence closeout
- [x] 将当前 `main` 推送到 `origin/main`，确认远端头推进到 `ad445cb5`
- [x] 在 `.claude/worktrees/simd-external-evidence` 上派发 fresh Windows `1/7..7/7` native evidence，批次 `SIMD-20260324-152` / workflow run `23475183856`
- [x] 确认 Windows artifact 本身已 fresh 通过，但首次 `freeze-status` 卡在 `qemu-cpuinfo-nonx86-evidence=SKIP`
- [x] 补跑 release `gate` with `SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1`，拿到 `linux/arm/v7 + linux/arm64 + linux/riscv64` PASS 的 fresh QEMU CPUInfo 证据
- [x] 重新执行 `win-closeout-finalize SIMD-20260324-152`，确认 cross-platform `freeze-status` 回到 `ready=True, mainline-ready=True, cross-ready=True`
- [x] 核对当前环境的 native host 通道：本机 `uname -m=x86_64`，唯一已配置 SSH 主机 `888933.xyz` 也为 `x86_64`，因此 `arm64/riscv64` asm-ready host evidence 仍待外部主机
- **Status:** complete

- 2026-03-24 最新 external evidence 证据：
  - push: `git push origin main` -> PASS，`origin/main` 更新到 `ad445cb5fcdc2a5d6889a0bd1cd5459e99a1c5a2`
  - Windows preflight: `FAFAFA_BUILD_MODE=Release SIMD_WIN_EVIDENCE_REF=main bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight` -> `STATUS=PASS CODE=OK`
  - Windows evidence: `FAFAFA_BUILD_MODE=Release SIMD_WIN_EVIDENCE_REF=main bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-20260324-152` -> fresh `windows_b07_gate.log` 下载并校验通过；GH workflow `23475183856` 两个 job 全部 success
  - QEMU CPUInfo gate: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，QEMU summary `tests/fafafa.core.simd/logs/qemu-multiarch-20260324-144555-2749661/summary.md`
  - closeout finalize: `FAFAFA_BUILD_MODE=Release SIMD_WIN_CLOSEOUT_BATCH_DIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/tests/fafafa.core.simd/logs/windows-closeout/SIMD-20260324-152 bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-20260324-152` -> PASS，`freeze-status ready=True`
  - final freeze: `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` -> PASS，`ready=True, mainline-ready=True, cross-ready=True`
- 这轮结论从“Windows evidence pending”推进到“Windows evidence fresh complete + cross freeze ready”：
  - 当前真正完成的是 fresh Windows native evidence 与 cross-platform closeout 重新闭环
  - 当前没有完成的仍是 `arm64/riscv64` asm-ready 真机执行证据；QEMU CPUInfo PASS 只解决 `freeze-status` 的现有门禁依赖，不等同于 NEON/RISCVV native asm host execution evidence
- 下一轮连续计划优先级更新为：
  1. 合并 `simd-external-evidence` worktree 的文档/状态同步回主线，保持主仓库干净
  2. 等待可用的 `arm64` / `riscv64` asm-ready 主机后，再按 targeted `DispatchAPI/PublicAbi + check` 回收 native execution evidence
  3. 若没有真实 host，就不要把 QEMU 或 x86_64 compile-only 证据误写成 native asm host 完成

### Phase 72: ARM64 NEON external evidence closeout sync
- [x] 校正文档基线到真实 refs：`origin/main=90b346ca`，`simd-external-evidence=cff7395c`
- [x] 将 ARM64 external evidence 的收口链 `23480331356 -> 23480706416 -> 23480929101 -> 23481240212` 与失败数 `6 -> 4 -> 1 -> 0` 同步到 planning/worker 文档
- [x] 记录四个新增提交 `002059f9` / `fff1b541` / `49b54aa5` / `cff7395c` 的作用、根因边界与“真实 bug / contract drift / test 假红”分类
- [x] 用 fresh release 本地验证补齐本轮交接证据：`SIMD_ENABLE_NEON_BACKEND=1` 定向 `DispatchAPI/PublicAbi` 与主 `check`
- [x] 将下一轮优先级收束到 `riscv64` asm-ready host evidence 与其他非阻塞 external evidence，不再回头重开已绿的 ARM64 NEON 链
- **Status:** complete

- 2026-03-24 最新 ARM64 NEON external evidence 证据：
  - refs: `git rev-parse --short=12 HEAD/main/origin/main` -> `cff7395c5acf` / `90b346ca33fa` / `90b346ca33fa`
  - remote runs:
    - `23480331356` -> 6 failures
    - `23480706416` -> 4 failures
    - `23480929101` -> 1 failure
    - `23481240212` -> success
  - commits:
    - `002059f9` `fix(simd): stabilize neon select contract`
    - `fff1b541` `test(simd): skip scalar-only hook disable paths`
    - `49b54aa5` `fix(simd): canonicalize scalar availability`
    - `cff7395c` `test(simd): compare neon fallback against base table`
  - fresh local targeted suite: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/verify-phase72-neon-targeted-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - fresh local check: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/verify-phase72-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
- 这轮结论是“fresh ARM64 evidence 已绿 + 文档状态已追平”，而不是再开新的实现层深审：
  - `002059f9` 真正修掉的是 native ARM64 `NEONSelectF32x4` 行为合同 bug，做法是把 select 收回到标量语义实现
  - `fff1b541` 收掉的是 testcase 对 `sbScalar` 的错误 disable 预期，不是生产实现 bug
  - `49b54aa5` 修的是 `sbScalar.Available` 在 dispatch/public ABI 之间的合同漂移
  - `cff7395c` 收掉的是 runtime-disabled fallback 观测方式错误，改为直接对比 `FillBaseDispatchTable(...)`
- 下一轮连续计划优先级更新为：
  1. 将 `simd-external-evidence` 分支合回 `main`，保持主仓库状态干净
  2. 如需继续外部证据，只处理 `riscv64` asm-ready host evidence 或 Windows/native 侧非阻塞证据
  3. 没有 fresh red 或可用真机前，不再回头重开已绿的 ARM64 NEON 链

### Phase 73: merge-back and repo-state hygiene finalize
- [x] 将 `simd-external-evidence` fast-forward 合回本地 `main`
- [x] 在合并后的 `main` 上 fresh 运行 release `SIMD_ENABLE_NEON_BACKEND=1` 定向 suite 与主 `check`
- [x] 将本地 `.simd-output/` 加入共享 `.git/info/exclude`，在不删除证据产物的前提下恢复主仓库和 worktree 的 clean status
- [x] 将 worker 当前状态从“待合回主线”更新为“已合回主线，等待下一轮 external evidence 条件”
- **Status:** complete

- 2026-03-24 最新 merge-back / hygiene 证据：
  - merge: `git -C /home/dtamade/projects/fafafa.core merge --ff-only simd-external-evidence` -> PASS，`main` fast-forward 到 `fe4379bf`
  - merged targeted suite: `TMPDIR=/home/dtamade/projects/fafafa.core/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.simd-output/verify-main-neon-targeted-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi` -> PASS，`[LEAK] OK`
  - merged check: `TMPDIR=/home/dtamade/projects/fafafa.core/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.simd-output/verify-main-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - status cleanup: `.git/info/exclude` 新增 `.simd-output/` 后，`git status --short --branch` 在主仓库与 SIMD worktree 都已不再显示未跟踪产物
- 下一轮连续计划优先级更新为：
  1. 推送 `main`，让这轮 ARM64 NEON closeout 与文档同步进入主线
  2. 如需继续 SIMD 外部证据，只处理 `riscv64` asm-ready host evidence 或其他真实 native host 入口
  3. 没有 fresh red 或可用真机前，不再重开已绿的 ARM64 NEON 链

### Phase 74: non-x86 native evidence entrypoint closeout
- [x] 证实当前仓库虽然已有 `tests/fafafa.core.simd/collect_nonx86_native_evidence.sh`，但 `BuildOrTest.sh` / 文档里没有正式入口，直接 `BuildOrTest.sh native-evidence` 只会掉到 usage
- [x] 将现有 helper 接成正式 shell action `native-evidence`，并补 runner-level static guard，防止以后再次变成隐藏 helper
- [x] 在 `docs/CI.md` 与 `docs/fafafa.core.simd.checklist.md` 补 native host evidence 用法，明确 `arm64/riscv64` 原生主机与 `direct-fpc/backend-asm` 环境变量
- [x] 用 fresh release `check` 复验新 guard 已接入主线，并用 fresh `native-evidence` 运行结果证明入口现在能准确 fail-close 到“当前 host 不支持”
- **Status:** complete

- 2026-03-24 最新 non-x86 native evidence entrypoint 证据：
  - red: `bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence` -> `Usage: ...`，说明 action 未接线而不是 helper 真正执行
  - green-check: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/verify-phase74-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS，包含 `[CHECK] OK (non-x86 native evidence runner guard present)`
  - green-runtime: `bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence` -> `Unsupported host/backend combination: host=x86_64, requested=auto`
- 这轮结论是“入口与文档缺口已收口”，不是新的 SIMD 实现 bug：
  - helper 本身之前已经存在，缺的是主 runner discoverability、usage 文案和 closeout 手册入口
  - 现在真正剩下的阻塞重新回到环境侧：`riscv64` 或其他 native host 什么时候可用
- 下一轮连续计划优先级更新为：
  1. 将 Phase 74 的 runner/doc 接线合回 `main`
  2. 一旦拿到 `riscv64` native host，直接用 `bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence riscvv` 回收真机证据
  3. 若需要 backend-asm 真工具链证据，再叠加 `SIMD_NATIVE_EVIDENCE_RUNNER=direct-fpc` 与 `SIMD_NATIVE_EVIDENCE_ENABLE_BACKEND_ASM=1`

### Phase 75: nightly artifact restore entrypoint closeout
- [x] 复核剩余 helper 候选，确认 `generate_interface_checklist_v2.py` 当前只被计划文档和 completeness matrix 手工引用，不属于主 runner discoverability gap
- [x] 确认 `.github/workflows/simd-nightly-closeout.yml` 长期依赖 `tests/fafafa.core.simd/restore_nightly_evidence_artifacts.sh`，但 `BuildOrTest.sh` / 文档没有正式入口，直接 `BuildOrTest.sh restore-nightly-evidence` 只会掉到 usage
- [x] 将现有 restore helper 接成正式 shell action `restore-nightly-evidence`，补 shell-only allowlist 与 `check_restore_nightly_evidence_runner_guard()`，并在 `docs/CI.md` / `docs/fafafa.core.simd.checklist.md` 补本地复演 nightly freeze audit 的用法
- [x] 用 fresh release `check`、fresh no-arg fail-close、fresh synthetic restore 复验 action 已接线且 helper 语义未变
- **Status:** complete

- 2026-03-24 最新 nightly artifact restore entrypoint 证据：
  - 红证据：
    - `bash tests/fafafa.core.simd/BuildOrTest.sh restore-nightly-evidence` -> `Usage: ...`
    - `bash tests/fafafa.core.simd/restore_nightly_evidence_artifacts.sh` -> `[RESTORE] Missing linux artifact directory`
    - 结论：helper 本身可运行，但主 runner 没有入口，属于 discoverability / automation gap
  - 绿证据：
    - `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/verify-phase75-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS，包含 `[CHECK] OK (nightly evidence restore runner guard present)`
    - `bash tests/fafafa.core.simd/BuildOrTest.sh restore-nightly-evidence` -> `[RESTORE] Missing linux artifact directory`
    - synthetic restore：通过临时 linux/windows artifact 目录运行 `bash tests/fafafa.core.simd/BuildOrTest.sh restore-nightly-evidence <linux-artifact-dir> <windows-artifact-dir>`，已确认 canonical `gate_summary.md/json`、`windows_b07_gate.log` 与 `qemu-multiarch-*` 会被正确恢复
- 这轮结论仍不是新的 SIMD 实现 bug，而是 nightly freeze-audit helper 的入口层缺口：
  - workflow 长期在用 helper
  - 维护者本地却没有正式 runner/docs 入口
  - 现在这层 discoverability 已收口，后续应把优先级切回真实 native host 证据或下一个 capability/dispatch 合同 red
- 下一轮连续计划优先级更新为：
  1. 不再把 `generate_interface_checklist_v2.py` 这类手工报告生成器误判成主 runner gap
  2. 若有 `riscv64` / 其他 non-x86 native host，优先回收 `native-evidence` 真机证据
  3. 若继续本地深审，切回真实 SIMD contract 问题，优先找下一条 capability/dispatch/rebuild 红，而不是继续扩张 helper 入口

## 5-Question Reboot Check (Phase 71 Update)
| Question | Answer |
|----------|--------|
| Where am I? | `main` 已推到 `origin/main@ad445cb5`；fresh Windows batch `SIMD-20260324-152` 已成功归档；补完 `qemu-cpuinfo-nonx86-evidence` 后，当前 `freeze-status` 已重新回到 `ready=True`。 |
| Where am I going? | 下一步不再继续深审实现层，而是把这轮 external evidence 的状态同步合回主线；真正剩下的外部证据只剩 `arm64/riscv64` asm-ready 主机。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明 Windows closeout 的剩余阻塞并不在 Windows runner 本身，而在 closeout 之后消费的 Linux/QEMU CPUInfo gate；只要补上这条 gate，fresh Windows artifact 就能重新把 cross freeze 拉回 ready。 |
| What have I done? | 已按顺序完成 push main、fresh Windows native evidence、QEMU CPUInfo gate replay、fresh closeout finalize 和 final freeze 复验；同时确认当前环境里还没有可用的 `arm64/riscv64` asm-ready 外部主机。 |

## 5-Question Reboot Check (Phase 72 Update)
| Question | Answer |
|----------|--------|
| Where am I? | `simd-external-evidence@cff7395c` 已在 `origin/main@90b346ca` 之上把 ARM64 NEON external evidence 收口到 fresh green；remote run `23481240212` success，且本地 fresh `SIMD_ENABLE_NEON_BACKEND=1` 定向 suite 与 fresh `check` 都已重新通过。 |
| Where am I going? | 先把 Phase 72 的文档/worker 同步合回 `main`；如继续推进，则只剩 `riscv64` asm-ready host evidence 和其他非阻塞 external evidence。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮同时证明了三类问题必须分开看：真实 native bug、shared contract drift、以及 test 观测/预期本身的假红。把它们混在一起只会让 external evidence 收口变慢。 |
| What have I done? | 已把 ARM64 failure 链从 `6 -> 4 -> 1 -> 0` 收口，记录四个新增提交的职责边界，并补上 fresh 本地 release 验证与 planning/worker 同步。 |

## 5-Question Reboot Check (Phase 73 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Phase 72 已经 fast-forward 合回本地 `main`；合并后的 fresh NEON 定向 suite 与 fresh `check` 都已通过，主仓库/worktree 的 `git status` 也已恢复干净。 |
| Where am I going? | 先把 `main` 推到远端；之后默认不再重开 ARM64 NEON 链，只在有真机或 fresh red 时开启新的 external evidence 批次。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 对并行协作来说，证据产物与代码改动要分开处理：`.simd-output/` 这类本地证据最好走本地 exclude，而不是反复制造脏工作区或误删收口材料。 |
| What have I done? | 已完成 merge-back、合并后 fresh release 验证，以及本地 repo hygiene 清理；当前主线只差一次 push。 |

## 5-Question Reboot Check (Phase 74 Update)
| Question | Answer |
|----------|--------|
| Where am I? | non-x86 native evidence helper 现在已经有正式 shell action 和文档入口；fresh `check` 已通过，且 `native-evidence` 在 x86_64 上会准确报“不支持的 host/backend 组合”，不再掉回 usage。 |
| Where am I going? | 把这轮 runner/doc 接线合回 `main`；之后等待真实 `riscv64` 或其他 native host，再直接跑 `native-evidence` 回收真机证据。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | external evidence 的常见阻塞不只是“没有主机”，也可能是仓库里其实已有 helper，但因为没接 runner/文档而不可发现。这个层次的问题值得先收掉。 |
| What have I done? | 已将 `collect_nonx86_native_evidence.sh` 接到 `BuildOrTest.sh native-evidence`，补上 static guard 与文档用法，并用 fresh red/green 证明入口从“未接线”变成“准确 fail-close”。 |

## 5-Question Reboot Check (Phase 70 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi,TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 都已重新通过；本轮最新把 toggle/read guard、snapshot-boundary 文档和 stable-state parity 护栏一起收口了。 |
| Where am I going? | 默认下一步不再继续无限深审，而是合并/交接当前 closeout；仅把外部 evidence 当作后续非阻塞项。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 当前剩余风险不在 single-call snapshot 自洽性，而在“调用方是否把并发 control-plane 写入下的跨调用 pair drift 误读成 bug”；这已经通过文档边界和 deterministic stable-state parity tests 明确收口。 |
| What have I done? | 已实现 closeout roadmap：补齐 `GetCurrentBackend` toggle/read guard、补齐 stable-state parity regression、补齐 snapshot-boundary 文档，并用 fresh release targeted/check/gate 复验，当前批次 merge-ready。 |

- 2026-03-24 最新 backend adapter concurrent guard closeout 证据：
  - targeted suite: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch67-backendops-concurrent-red-or-green-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework` -> PASS，`[LEAK] OK`
  - check: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch67-backendops-concurrent-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check` -> PASS
  - gate: `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-contract-audit/.simd-output/batch67-backendops-concurrent-gate-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh gate` -> PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-24 10:43:07`
- 这轮结论仍是“测试护栏缺口”，不是新的生产 bug：
  - 之前 deterministic adapter 测试已经补齐了 unregistered metadata 与 registered empty-text drift，但还没有 machine-readable 证据去证明 `GetBackendOps(backend)` 在 concurrent `RegisterBackend(...)` churn 下不会把 metadata 和 representative slots 拼成 mixed snapshot
  - 新测试显式选择一个当前 non-scalar backend，把 disabled table 的 `Available/Capabilities` 和 `AddF32x4/MulF32x4/AddI32x4/SelectF32x4` 收紧到 scalar-backed 代表态，再让 reader 把 `GetBackendOps` round-trip 回 dispatch table 只接受完整 A/B 两态
  - fresh targeted suite、fresh `check`、fresh `gate` 全绿，说明当前 published backend snapshot + adapter round-trip 读取路径在现有宿主机上没有暴露新的 adapter mixed snapshot
- 下一轮连续计划优先级更新为：
  1. 从 `GetBackendOps(backend)` guard closeout 继续切到 current-active helper / public-view pair drift，优先找 `GetCurrentBackend`、`GetCurrentBackendInfo`、public ABI active metadata 三者之间在 repeated control-plane churn 下的 fresh red
  2. 继续核对 external consumer cached table / helper 在 repeated `RegisterBackend(...)` / hook / toggle 之后，是否还存在“控制面已收口，但 helper/public-view pair 仍漂移”的真实问题
  3. 持续使用 worktree-local `SIMD_OUTPUT_ROOT/TMPDIR`，并保持“fresh red-or-green -> check -> gate -> 文档 -> commit”的批次节奏

## 5-Question Reboot Check (Phase 67 Update)
| Question | Answer |
|----------|--------|
| Where am I? | Linux fresh `TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 都已重新通过；本轮最新把 backend adapter `GetBackendOps(backend)` 的 concurrent register/read 合同补成了独立 regression guard。 |
| Where am I going? | 下一轮继续深审 current-active helper / public-view pair drift，优先找 `GetCurrentBackend`、`GetCurrentBackendInfo`、以及 public ABI active metadata 在 repeated control-plane churn 下的 fresh red。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | 这轮证明，当前 published backend snapshot + adapter round-trip 读取链已经能守住 `GetBackendOps` 的并发一致性：helper 可见 metadata 与代表性 slots 不会在 `RegisterBackend(...)` churn 下混搭。 |
| What have I done? | 已为 `GetBackendOps(backend)` 补上 concurrent re-register 护栏，并用 fresh release suite/check/gate 把这条候选收口为“guard green”；随后可继续切到 current-active helper / public-view pair 的更深层 drift 候选。 |

### Phase 76: x86 `scMaskedOps` capability underclaim closeout
- **Status:** complete
- Actions taken:
  - 从 `scMaskedOps` 候选开始先收语义，而不是直接改 capability：
    - 确认 `TSimdDispatchTable` 中真正对应的可观测 contract 是 `Mask2/4/8/16(All/Any/None/PopCount/FirstSet)` helper family
    - 确认 `SSE2/AVX2` 以及继承它们的 `SSE3/SSSE3/SSE4.1/SSE4.2/AVX512` 都有 native x86 mask helper wiring
    - 同时确认 `NEON` 当前 `Mask*` 仍落在 `src/fafafa.core.simd.neon.scalar.utility.inc` 的 scalar wrapper，不能把这轮结论错误外推到 non-x86
  - 先按 TDD 补 fresh red，而不是先改实现：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增
      - `Test_X86_BackendCapabilities_DoNotUnderclaim_MaskedOps`
      - `Test_X86_BackendCapabilities_Keep_MaskedOps_When_VectorAsmDisabled`
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增
      - `Test_PublicApi_BackendPodInfo_CapabilityBits_DoNotUnderclaim_X86MaskedOps`
      - `Test_PublicApi_BackendPodInfo_CapabilityBits_Keep_X86MaskedOps_WhenVectorAsmDisabled`
    - 同时把旧 `AVX512 vector asm=False -> scMaskedOps should clear` 断言移除，因为 `AVX512` 的 runtime-disabled 路径会继承 `AVX2` 的 x86 native mask helpers，这条旧断言本身就是错误合同
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-maskedops-red-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - 失败点直接命中：
      - `scMaskedOps missing while representative x86 mask helper slots are non-scalar: SSE2`
      - `scMaskedOps should stay set while representative x86 mask helper slots remain non-scalar after vector asm disable: SSE2`
      - public ABI 对应两条 `CapabilityBits` 断言同步打红
  - 根因确认后，做最小实现修复：
    - `scMaskedOps` 之前只在 `src/fafafa.core.simd.avx512.register.inc` 里宣称，导致 `SSE2` family / `AVX2` / `AVX512 runtime-disabled` 全部低报
    - 已把以下 x86 backend capability set 补齐为显式包含 `scMaskedOps`：
      - `src/fafafa.core.simd.sse2.pas`
      - `src/fafafa.core.simd.sse3.register.inc`
      - `src/fafafa.core.simd.ssse3.register.inc`
      - `src/fafafa.core.simd.sse41.register.inc`
      - `src/fafafa.core.simd.sse42.register.inc`
      - `src/fafafa.core.simd.avx2.register.inc`
      - `src/fafafa.core.simd.avx512.register.inc`
    - `AVX512` 的 `scMaskedOps` 也改成不再跟随 `LEnableVectorAsm` 清零，因为 runtime-disabled fallback 仍继承 x86 native mask helpers
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-maskedops-green-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-maskedops-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-maskedops-gate-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi` PASS，`[LEAK] OK`
    - fresh `check` PASS
    - fresh `gate` 最终 `[GATE] OK`
    - run-all summary 时间：`2026-03-24 18:51:26`
- 这轮结论是新的真实 capability/public-ABI 合同 bug，不是测试假红：
  - 真实 x86 native `Mask*` helper family 已经长期存在
  - capability/public ABI 却只在 `AVX512` 上零散宣称，且在 `AVX512 vector asm=False` 路径还错误清零
  - 这会让外部 consumer 把仍可用的 x86 native mask helper 误判成“不支持”
- 下一轮连续计划优先级更新为：
  1. 若能拿到 `riscv64` asm-ready host，优先验证 `RISCVV` asm path 是否也应宣称 `scMaskedOps`
  2. 继续深审 non-x86 capability 语义，重点区分“backend-local scalar wrapper”与“真实 native helper family”，避免把 `NEON` 这类 wrapper 误报成 capability
  3. 保持 release + fresh red/green/check/gate 的节奏，不再继续扩 helper discoverability

## 5-Question Reboot Check (Phase 76 Update)
| Question | Answer |
|----------|--------|
| Where am I? | `simd-external-evidence@2359adfd` 之上，本轮 fresh `TTestCase_DispatchAPI,TTestCase_PublicAbi`、fresh `check`、fresh `gate` 已全部重新通过；最新收口的是 x86 `scMaskedOps` capability/public-ABI underclaim。 |
| Where am I going? | 下一步回到 non-x86/native evidence 与 capability 语义边界，优先验证 `RISCVV` asm host；本地继续审时重点防止把 scalar wrapper 误判成 native capability。 |
| What's the goal? | 审查 simd，修复确认问题，并输出连续修复/审查方案 |
| What have I learned? | `scMaskedOps` 不能按“凡是有 `Mask*` 符号就算支持”粗暴判定；`NEON` 当前仍是 scalar wrapper，而 x86 `SSE2..AVX512` 则确实有 native helper family。 capability 语义必须贴着真实 helper 实现层落。 |
| What have I done? | 已先用 fresh red 证明 x86 `scMaskedOps` 低报，再把 `SSE2..SSE42/AVX2/AVX512` capability set 补齐，并修正 `AVX512 vector asm=False` 的错误旧断言；最后用 fresh release targeted/check/gate 全链复验通过。 |

### Phase 77: RVV fallback rollback-restore success cleanup pollution closeout
- **Status:** complete
- Actions taken:
  - 继续沿 riscv64 fallback lane 的 historical `TTestCase_DispatchAPI` broad failure 深挖后，先补 fresh red，而不是直接改生产实现：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_RISCVFallbackDispatchContract.Test_RollbackRestoreSuccess_Keep_RepresentativeWideSlots_Assigned`
    - 这条 regression 直接守住：执行 `Test_TrySetActiveBackend_RollbackRestore_Success_Preserves_ForcedSelection` 后，registered scalar table 与 current dispatch 的 representative wide slots 仍必须保持 assigned
  - fresh red 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_RISCVFallbackDispatchContract SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - 失败点直接命中：
      - `Registered scalar AndNotI64x2 should remain assigned after rollback-restore success probe`
    - 同时 historical broad suite 也已被证明命中同区：
      - `TTestCase_DispatchAPI.Test_VecI64x2_DispatchAssigned_And_Parity: Dispatch.AndNotI64x2 should be assigned`
  - 根因确认后，做最小实现修复：
    - 问题不在生产 dispatch/rebuild，而在 `Test_TrySetActiveBackend_RollbackRestore_Success_Preserves_ForcedSelection`
    - 旧测试在 fallback 早退路径里仍无条件执行 `RegisterBackend(GDispatchHookRollbackForceSuccessTarget, GDispatchHookRollbackForceSuccessTargetTable)`
    - 此时 global target 仍是默认 `sbScalar`，target table 仍是 `Default(TSimdDispatchTable)`，从而把 scalar 注册表直接冲坏
    - 现已将 testcase 收紧为：
      - 入口显式清理 rollback-force-success globals
      - 仅在 `LTargetTableCaptured=True` 时才执行 restore 回写
  - fresh green / release 复验：
    - `python3 tests/fafafa.core.simd/check_suite_manifest_sync.py --summary-line`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchapi-host-20260324-b bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_RISCVFallbackDispatchContract SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_DispatchAPI SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
- 这轮结论是新的真实 test-cleanup bug，不是新的生产 dispatch bug：
  - broad RVV failure 之前是被 testcase 自己的 early-exit restore 污染放大的
  - 生产 dispatch 表并没有在这条路径里真实丢 wide slots
  - 这轮收口后，后续 non-x86 capability/dispatch 深审应先排除 test-only 污染，再判断是否存在真正实现缺陷

### Phase 78: RVV public ABI rollback forced-success cleanup pollution closeout
- **Status:** complete
- Actions taken:
  - 继续沿 `RVV asm + OPCODE_READY` 的 fresh `TTestCase_PublicAbi` red 深挖后，先补失败点定位，而不是直接改实现：
    - 同一条 red 命令：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_PublicAbi SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - 先把 `Test_PublicApi_DataPlane_Parity` 的 AV 缩到 `MemEqual(facade)`，随后确认 failure 时：
      - `VectorAsm=False`
      - `CurrentBackend=Scalar`
      - `Dispatch.MemEqual=nil`
      - `Scalar.MemEqual=nil`
    - 这说明不是 RVV public ABI direct-bind 本身炸，而是更早的 testcase restore 已经把 scalar slot 污染成空表
  - 根因确认后，做最小实现修复：
    - 问题不在 `src/` 生产实现，而在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 的
      `Test_PublicApi_RollbackRestore_Success_Preserves_ForcedSelection`
    - 旧测试在 RVV lane 只有 `Scalar + RISCVV` 两个 dispatchable backend 时会 early-exit，但 `finally` 里仍无条件执行：
      - `RegisterBackend(GPublicAbiHookRollbackForceSuccessTarget, GPublicAbiHookRollbackForceSuccessTargetTable)`
    - 此时 global target 仍是默认 `sbScalar`，target table 仍是 `Default(TSimdDispatchTable)`，于是把 scalar registered/current snapshot 直接冲成零值表，后续 `DataPlane_Parity` 才会在 `MemEqual(facade)` 处 AV
    - 现已将这条 public ABI testcase 收紧为：
      - 入口显式清理 rollback-force-success globals
      - 新增 `LTargetTableCaptured`
      - 仅在真正捕获过 requested backend 原表时才执行 restore 回写
    - 同时撤回上一轮错误假设修改，把 `src/fafafa.core.simd.public_abi.impl.inc` 的 64-bit direct-bind 范围恢复为重新包含 `CPURISCV64`
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_PublicAbi SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_DispatchAPI SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 记录关键运行结果：
    - fresh `TTestCase_PublicAbi` PASS，`[LEAK] OK`
    - fresh `TTestCase_DispatchAPI` PASS，`[LEAK] OK`
    - 两条 lane 最终都输出 `[RVV-LANE] PASS`
- 这轮结论是新的真实 test-cleanup bug，不是新的生产 RVV/public-ABI bug：
  - `MemEqual(facade)` AV 只是 scalar slot 被测试自己提前污染后的后继症状
  - `CPURISCV64` public ABI direct-bind 之前被怀疑是根因，但 fresh 证据已证伪
  - 后续 non-x86 capability / dispatch / rebuild 深审仍应先排除 suite 自身 restore 污染，再判断是否存在真实实现缺陷
- 下一轮连续计划优先级更新为：
  1. 回到真正的 non-x86 capability 语义审查，优先验证 `RISCVV/NEON` 还有没有“native helper 已接线但 capability 漏报 / 误报”的真实问题
  2. 若能拿到 native `arm64/riscv64` asm host，继续补 external evidence，尤其是 `RISCVV scMaskedOps` / opcode-ready 路径
  3. 保持 worktree-local release 验证节奏，先排除 testcase cleanup 污染，再扩大 `check/gate` 面

### Phase 79: RVV native lane real-enable and `scMaskedOps` underclaim closeout
- **Status:** complete
- Actions taken:
  - 先梳理当前 `DispatchAPI/test.lpr` 候选改动，确认 `TTestCase_RISCVVMaskedOpsContract` 之前并没有真的覆盖到 native asm 路径：
    - testcase 里使用了 `{$IFNDEF RISCVV_ASSEMBLY}` 守卫
    - 但这个宏只在 `src/fafafa.core.simd.riscvv.pas` 单元内部定义，测试单元不可见，所以 suite 一直是直接 `Exit` 的伪绿
  - 先按 TDD 把 masked-ops suite 收紧为真正 native-target contract：
    - 将 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 里的 `TTestCase_RISCVVMaskedOpsContract` 改成仅在 `CPURISCV64/CPURISCV32` target 上启用
    - 去掉 `SetVectorAsmEnabled(True)` 后的 silent early-exit，改成显式断言 vector-asm flag 与 backend registration
  - fresh red 第 1 层并没有先打到 capability，而是暴露 native evidence harness 本身是假绿：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_RISCVVMaskedOpsContract SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - 失败点直接命中：
      - `RISCVV backend should be registered in mask capability contract test`
      - `RISCVV backend should be registered for public ABI mask contract test`
    - 根因确认：`tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh` 的默认 define 链漏了 `-dSIMD_EXPERIMENTAL_RISCVV`，导致 `src/fafafa.core.simd.pas` 根本没把 `fafafa.core.simd.riscvv` unit 编进 umbrella unit；之前的 RVV `DispatchAPI/PublicAbi` lane PASS 之所以成立，只是因为那些 testcase 在 backend 未注册时会直接 `Exit`
  - 做最小 native-lane wiring 修复后，fresh red 第 2 层继续暴露真正的编译阻断：
    - `src/fafafa.core.simd.riscvv.pas` 之前在 `RISCVV_ASSEMBLY` build 下仍无条件 include `riscvv.helpers.inc`，会与主文件里的 asm implementation 重复声明
    - 同时 `src/fafafa.core.simd.riscvv.register.inc` 还会在 asm build 里引用一批只有 fallback facade 才存在的 wide helper symbol
    - 最小修复方式：
      - `tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh` 默认 compile/runtime define 集补入 `-dSIMD_EXPERIMENTAL_RISCVV`
      - `src/fafafa.core.simd.riscvv.pas` 把 `riscvv.helpers.inc` 收紧为 non-asm only include
      - `src/fafafa.core.simd.riscvv.register.inc` 在 `RISCVV_ASSEMBLY` 下保留 `FillBaseDispatchTable(...)` 的 scalar base wiring，不再覆写 `DotF32x8/DotF64x2/DotF64x4` 与 `I16x32/I8x64/U8x64/U32x16/U64x8` 这批 asm-visible 不存在的 fallback-only helper slot
    - 这样 native RVV opcode lane 才第一次真正进入“backend 已编进且可构建”的状态
  - 在 compile-only 真正转绿后，再次 fresh red，终于命中目标 capability bug：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_RISCVVMaskedOpsContract SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - 失败点直接命中：
      - `RISCVV scMaskedOps should be set while representative mask helper slots are native`
      - `Public ABI CapabilityBits should expose RISCVV scMaskedOps while representative mask helper slots are native`
    - 根因确认：`src/fafafa.core.simd.riscvv.register.inc` 在 `LUseVectorAsm=True` 时已把 `Mask2All/Mask8PopCount/Mask16FirstSet` 等代表性 mask helper slot 绑到 RVV asm implementation，但 `BackendInfo.Capabilities` 仍缺 `scMaskedOps`
  - 做最小生产修复：
    - `src/fafafa.core.simd.riscvv.register.inc` 现已把 `scMaskedOps` 收紧为与 `scIntegerOps/scShuffle/scFMA` 同一语义，只在 `LUseVectorAsm=True` 时宣称
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_RISCVVMaskedOpsContract SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-rvv-maskedops-check-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 记录关键运行结果：
    - fresh RVV `TTestCase_RISCVVMaskedOpsContract` PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check` PASS，`[CHECK] OK`
- 这轮结论包含两层重要事实：
  - 之前的 RVV native opcode-ready lane 并没有把 experimental backend 真正编进来，所以那部分 broad PASS 不能再直接当作 native capability evidence 使用
  - 在 native lane 真正接通之后，`RISCVV` 的 `Mask*` helper family 确实已经是 asm-backed native implementation，因此 `scMaskedOps` 少报是新的真实 capability/public-ABI underclaim
- 下一轮连续计划优先级更新为：
  1. 系统性替换 `DispatchAPI/PublicAbi` 里剩余依赖 `RISCVV_ASSEMBLY` 的 testcase 宏守卫，避免 native RVV suite 继续出现伪绿
  2. 在真实 native RVV lane 上重新验证 `scIntegerOps/scShuffle/scFMA` 与 runtime-disabled rebuild 合同，把之前因 harness 假绿失真的证据链补真
  3. 继续沿 non-x86 capability 语义审查，但保持“先修 native evidence harness，再判定生产 bug”的顺序

### Phase 80: RVV native broad contract de-pseudogreen and wide rounding wiring closeout
- **Status:** complete
- Actions taken:
  - 延续 Phase 79 之后的 RVV native evidence 收口，先把 broad suite 里剩余的伪守卫和 runtime 前置条件补真，而不是先碰生产实现：
    - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
    - 两个 testcase 单元顶部都补了测试可见的 `FAFAFA_SIMD_TEST_RISCVV_ASM_COMPILED`
    - `RISCVV scIntegerOps/scFMA/scShuffle` expose 合同和 non-x86 native wide floor/ceil 合同，统一改成显式 `SetVectorAsmEnabled(True)` 后再断言，避免默认 scalar-backed 注册态造成假红/假绿
  - fresh RVV native broad suite 继续收窄后，真正暴露出的生产问题不是 capability metadata，而是宽 rounding 槽位 stale wiring：
    - fresh red 代表命令：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_DispatchAPI,TTestCase_PublicAbi,TTestCase_VecF32x8,TTestCase_VecF64x4 SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - 失败点收敛到：
      - `TTestCase_DispatchAPI.Test_NonX86_NativeWideFloorCeil_Slots_NotScalar_IfAvailable`
      - `FloorF32x8 unexpectedly falls back to scalar slot: RISCVV`
    - 根因确认：
      - `src/fafafa.core.simd.riscvv.register.inc` 在 `RISCVV_ASSEMBLY` 分支里仍把 `Ceil/Floor/Round/Trunc` 的 `F32x16/F32x8/F64x2/F64x4/F64x8` 槽位绑到 `Scalar*`
      - 但 `src/fafafa.core.simd.riscvv.pas` 已经存在对应的 `RISCVV*` asm implementation，所以这是注册层 stale wiring，而不是实现缺失
  - 做最小生产修复：
    - `src/fafafa.core.simd.riscvv.register.inc` 现在已把上述宽 rounding 槽位在 `RISCVV_ASSEMBLY` 下改回绑定 `RISCVV*`
    - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 同步挂入 `TTestCase_RISCVVMaskedOpsContract` 与 `TTestCase_RISCVFallbackDispatchContract`，避免 runner 列表与 testcase 注册继续漂移
  - fresh green / release 复验：
    - x86 host fallback spot-check：
      - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-shuffle-red-20260324 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
    - native RVV broad lane：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_DispatchAPI,TTestCase_PublicAbi,TTestCase_RISCVVMaskedOpsContract,TTestCase_RISCVFallbackDispatchContract,TTestCase_VecF32x8,TTestCase_VecF64x4 SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260324-continue bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260324-phase80 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fallback host `TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS，`[TEST] OK`、`[LEAK] OK`
    - broad RVV lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：PASS，`[CHECK] OK`
    - fresh release `gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-24 23:59:32`
- 这轮结论包含两层关键信息：
  - summary 里怀疑的 generic shuffle underclaim 假红在当前 worktree 已不再复现，当前 x86 host fallback suite 直接为绿，因此这轮不需要继续改 generic shuffle testcase 口径
  - 真实生产问题是 `RISCVV` native asm 注册层把宽 rounding 槽位误接回 `Scalar*`，一旦 broad suite 的 testcase 守卫和 runtime 前置条件补真，就会稳定暴露出来
- 下一轮连续计划优先级更新为：
  1. 继续沿 non-x86 capability / rebuild 合同往下审，优先找下一条“native helper 已接线但 capability 漏报/误报”的真实问题
  2. 保持 worktree-local release 验证节奏，继续坚持 `suite -> check -> gate` 的闭环，而不是只拿单条 lane 结果
  3. 先区分 testcase cleanup/harness 问题与生产 wiring/capability 问题，再决定是否改 `src/`

### Phase 81: RVV narrow `F64x2` rounding native garbage-value closeout
- **Status:** complete
- Actions taken:
  - 先继续按 TDD 收紧 native RVV IEEE754 证据，而不是先改生产实现：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas` 新增 `TTestCase_NonX86IEEE754.Test_NonX86_NarrowF64x2_RoundTruncFloorCeil_Finite_IfAvailable`
    - testcase 使用固定 finite 非整数输入 `1.25/-1.25/1.75/-1.75/2.5/-2.5`
    - 同时显式 `SetVectorAsmEnabled(True)`，避免默认 `vectorAsm=False` 再次把 narrow native lane 误测成 scalar-backed 伪绿
  - fresh red 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86IEEE754 SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 失败点稳定命中：
    - `TTestCase_NonX86IEEE754.Test_NonX86_NarrowF64x2_RoundTruncFloorCeil_Finite_IfAvailable`
    - `9 Case 0 RoundF64x2[0] finite compare expected: <1> but was: <6.9e-310>`
    - 连续 3 次 retry 都是同类 garbage-value failure，不是一次性噪音
  - 根因确认与最小修复策略：
    - 当前 fresh 证据已经足够证明 `RISCVV_ASSEMBLY` 下 native `F64x2` 窄 rounding slot 不满足对外合同
    - 在没有 fresh asm-level ABI/语义证明前，最保守且最小的修复是不再把这四个 slot 暴露给 native lane
    - `src/fafafa.core.simd.riscvv.register.inc` 现已把 `Ceil/Floor/Round/TruncF64x2` 在 `RISCVV_ASSEMBLY` 下收回到 `Scalar*`
    - `F32x4` 的同类窄 rounding slot 之前已经采用同一安全策略，因此这次收口把 `F64x2` 也对齐回同一口径
  - fresh green / release 复验：
    - fresh RVV narrow IEEE754 lane：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86IEEE754 SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260325-phase81 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260325-phase81-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh RVV narrow IEEE754 lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：PASS，`[CHECK] OK`
    - fresh release `gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-25 08:38:12`
    - 首次并行触发的 `gate` 失败已确认为本地 `lazbuild` fallback 到共享 `bin2/lib2` 后的链接竞争噪音，不是代码回归；串行重跑后已转绿
- 这轮结论包含两层关键信息：
  - `TTestCase_NonX86IEEE754` 之前对 narrow RVV path 缺少显式 `vector asm=True` 前置条件，因此这部分 native 合同一直处在伪绿盲区
  - 一旦把 narrow finite case 真正压到 RVV asm lane，`F64x2` rounding slot 会直接返回 garbage value；因此当前 native asm 实现不能继续对外暴露
- 下一轮连续计划优先级更新为：
  1. 继续沿 RVV narrow surface 往下审，优先确认 `F64x2` 之外是否还有同类 native asm slot 仍在以错误 ABI/输入指针语义暴露
  2. 把 `NonX86IEEE754` 里其余 narrow/wide native evidence 逐步补齐显式 `vector asm=True` 前置条件，继续压缩伪绿面
  3. 在确认更多 red 之前，保持“先收紧注册层暴露面，再决定是否深入改 asm 本体”的最小风险策略

### Phase 82: RVV narrow `F32x4/F64x2` float core ABI wrapper closeout
- **Status:** complete
- Actions taken:
  - 继续沿 Phase 81 之后的 RVV narrow asm surface 往下钻，没有先动生产代码，而是先把 native narrow float core parity 真正补真：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeNarrowFloatCoreParity_WithVectorAsm_IfAvailable`
    - testcase 显式 `SetVectorAsmEnabled(True)`，并要求 `RISCVV/NEON` 的 `Add/Abs/Fma/ClampF32x4` 与 `Add/Abs/Fma/ClampF64x2` slot 在 asm lane 上既非 scalar，又要与 scalar reference 保持 parity
  - fresh red 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 失败点稳定命中：
    - `TTestCase_NonX86BackendParity.Test_NativeNarrowFloatCoreParity_WithVectorAsm_IfAvailable`
    - `AddF32x4 parity lane 0: RISCVV expected: <-2.75> but was: <1.42746747382458E-24>`
    - 同条 lane 连续 3 次 retry 都命中不同 garbage value，不是一次性噪音
  - 根因确认与最小生产修复：
    - 对照 `src/fafafa.core.simd.riscvv.pas` 里已有的 `Load/Splat/Select` 以及 `tests/test_riscvv_wrapper_unit.pas` 的 working sample 后，确认问题不只是某个算术指令，而是 `fpc/riscv64` 下窄向量 `function(...): TVec*; assembler; nostackframe` 返回 ABI 不稳定
    - 当前已验证可靠的模式是：内部 asm 使用 `procedure(...; var r)`，外层再用普通 Pascal wrapper 暴露原有 `function` 签名
    - 因此把 `src/fafafa.core.simd.riscvv.pas` 中 `F32x4/F64x2` 的代表性 narrow float vector-return core ops 改为 wrapper 模式：
      - `Add/Sub/Mul/Div`
      - `Abs/Sqrt/Min/Max/Neg`
      - `Fma`
      - `Clamp`
      - 以及 `Rcp/RsqrtF32x4`
    - 同时将 `FmaF32x4/FmaF64x2` 收敛到与 working wrapper sample 一致的 `vfmacc` 累加写法，避免继续依赖不确定的 direct-return 语义
  - fresh green / release 复验：
    - fresh RVV narrow parity lane：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - fresh RVV narrow parity + IEEE754 lane：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86IEEE754,TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260325-phase82 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260325-phase82-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh RVV narrow parity lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh RVV `NonX86IEEE754,TTestCase_NonX86BackendParity` combined lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：PASS，`[CHECK] OK`
    - fresh release `gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-25 09:52:25`
- 这轮结论包含两层关键信息：
  - `RVV` narrow float core path 的真实问题不是单个 `AddF32x4` 指令接错，而是 direct vector-return asm ABI 本身不稳定；只改结果寄存器位置会继续落到 garbage/AV
  - 已有仓内 working sample 已经证明 wrapper 模式能稳住这类调用，所以这轮选择把代表性 `F32x4/F64x2` float core surface 迁回 wrapper，而不是继续暴露不稳定的 direct-return asm
- 下一轮连续计划优先级更新为：
  1. 继续沿 RVV narrow surface 往下审，优先确认 `I32x4/I64x2/U32x4/U64x2` 等 integer/vector-return core ops 是否也存在同类 direct-return ABI drift
  2. 若 integer narrow surface 继续命中同根因，优先按同一 wrapper 模式迁移，而不是再做寄存器猜测式修补
  3. 保持 `RVV lane -> release check -> serial gate` 的闭环，避免只靠 host 路径把 experimental backend 数据面问题误收成绿

### Phase 83: RVV narrow `I32x4/I64x2/U32x4/U64x2` integer core ABI wrapper closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeNarrowIntegerCoreParity_WithVectorAsm_IfAvailable`，显式 `SetVectorAsmEnabled(True)`，并要求 `Add/And/ShiftLeft/ShiftRightArithI32x4`、`Add/AndI64x2`、`AddU32x4`、`AddU64x2` 在 native asm lane 上既非 scalar 又与 scalar parity
- [x] 用 fresh RVV opcode-ready lane 连续 3 次复现同一条 `AddI32x4` narrow integer red，确认不是编译噪音而是稳定 garbage-value 数据面错误
- [x] 将 `src/fafafa.core.simd.riscvv.pas` 中代表性的 narrow integer core ops 迁到 `procedure(...; var r)` + Pascal wrapper 模式，覆盖：
  - `I32x4`：`Add/Sub/Mul/And/Or/Xor/Not/AndNot/Min/Max/ShiftLeft/ShiftRight/ShiftRightArith`
  - `I64x2`：`Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith`
  - `U32x4`：`Add/Sub/Mul/Min/Max/And/Or/Xor/Not/ShiftLeft/ShiftRight`
  - `U64x2`：`Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight`
- [x] 用 fresh RVV narrow parity lane、fresh combined `NonX86IEEE754 + NonX86BackendParity` lane、fresh release `check`、fresh serial `gate` 复验
- **Status:** complete
- Notes:
  - fresh red 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 失败点稳定命中：
    - `TTestCase_NonX86BackendParity.Test_NativeNarrowIntegerCoreParity_WithVectorAsm_IfAvailable`
    - `AddI32x4 parity lane 0: RISCVV expected: <358326759> but was: <-1547910192>`
    - 同条 lane 连续 3 次 retry 都命中 `AddI32x4`，但 bad value 每次不同，说明问题仍是 direct-return ABI/data-plane 漂移，不是一次性运行噪音
  - 根因确认：
    - 这次 red 与 Phase 82 的 narrow float red 形态一致，继续证明 `fpc/riscv64` 下 direct `function(...): TVec*; assembler; nostackframe` 不是 narrow vector-return core path 的稳定 ABI
    - 对照 `tests/test_riscvv_wrapper_unit.pas` 的 working sample，以及 Phase 82 已经验证过的 float wrapper 路径后，当前可靠模式仍然是 `procedure(...; var r)` + Pascal wrapper
  - fresh green / release 复验：
    - fresh RVV narrow parity lane：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - fresh RVV narrow parity + IEEE754 lane：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86IEEE754,TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260325-phase83 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260325-phase83-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh RVV narrow parity lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh RVV `TTestCase_NonX86IEEE754,TTestCase_NonX86BackendParity` combined lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：PASS，`[CHECK] OK`
    - fresh release `gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-25 10:40:19`
- 这轮结论包含两层关键信息：
  - `RVV` narrow integer core path 与 narrow float core path 一样，真实问题不是某条整数指令接错，而是 direct vector-return asm ABI 本身不稳定
  - 这轮只收口了已有 native parity 证据覆盖到的代表性 integer core surface；`Load/Splat/Select/Insert/AndNot` 等 helper-like narrow integer surface 仍需下一轮继续审
- 下一轮连续计划优先级更新为：
  1. 继续沿 `RISCVV` narrow integer helper surface 往下审，优先确认 `Load/Splat/Select/Insert` 等 still-direct-return slot 是否也需要 wrapper 化
  2. 若 helper surface 继续命中同根因，再补最小 red 把这些路径从“core 已绿”推进到“narrow integer surface 更完整”
  3. 继续保持 `RVV lane -> release check -> serial gate` 的闭环，不在同一 worktree 并行跑共享 `bin2/lib2` 的构建

### Phase 84: RVV narrow `InsertI32x4/InsertI64x2` helper lane-preservation closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeNarrowIntegerHelperParity_WithVectorAsm_IfAvailable`，显式 `SetVectorAsmEnabled(True)`，并要求 `InsertI32x4/InsertI64x2` 的 dispatch-table / facade 路径与 scalar parity，同时补 `ExtractI32x4/ExtractI64x2` 基线
- [x] 用 fresh RVV opcode-ready lane 连续复现 `InsertI32x4` helper red，确认 Phase 83 之后暴露出来的已不是 direct-return ABI 噪音，而是稳定的 lane 污染
- [x] 将 `src/fafafa.core.simd.riscvv.pas` 中 `RISCVVInsertI32x4Asm` / `RISCVVInsertI64x2Asm` 从 `vslideup.vx` 序列改为“整向量复制到结果 + 单 lane 标量覆写”，并在 Pascal wrapper 中补 index clamp，保持与 scalar 语义一致
- [x] 用 fresh targeted RVV lane、fresh combined `NonX86IEEE754 + NonX86BackendParity` lane、fresh release `check`、fresh serial `gate` 复验
- **Status:** complete
- Notes:
  - fresh red 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 失败点稳定命中：
    - `TTestCase_NonX86BackendParity.Test_NativeNarrowIntegerHelperParity_WithVectorAsm_IfAvailable`
    - `InsertI32x4 dispatch-table parity lane 3: RISCVV expected: <-404> but was: <0>`
    - 说明 `InsertI32x4(index=2)` 会把原本应保留的 lane 3 一起写坏，不再是 ABI 级 garbage-value / AV
  - 根因确认：
    - `RISCVVInsertI32x4Asm` / `RISCVVInsertI64x2Asm` 之前用 `vslideup.vx` 从只初始化了首 lane 的临时向量拷贝数据
    - 在 `index > 0` 时，目标位置之后的 lane 会继续从临时向量的后续元素取值，导致未初始化/零值把原始 lane 覆盖掉
    - 因此这轮问题属于真实 helper 算法错误，而不是 Phase 82/83 已经收口过的 direct-return ABI 漂移
  - 最小生产修复：
    - `RISCVVInsertI32x4Asm` / `RISCVVInsertI64x2Asm` 现已改成先 `vle*.v` / `vse*.v` 整向量复制到结果，再用 `sw` / `sd` 只覆写目标 lane
    - 对外函数 `RISCVVInsertI32x4` / `RISCVVInsertI64x2` 现会先 clamp `index`，保持与 scalar fallback 一致
    - `InsertI64x2` 这轮虽然没有单独 fresh 打红，但与 `InsertI32x4` 共用同一错误模式，因此一起按同一最小修复收口
  - fresh green / release 复验：
    - fresh RVV narrow parity lane：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - fresh RVV narrow parity + IEEE754 lane：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86IEEE754,TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260325-phase84 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260325-phase84-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh RVV narrow parity lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh RVV `TTestCase_NonX86IEEE754,TTestCase_NonX86BackendParity` combined lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：PASS，`[CHECK] OK`
    - fresh release `gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-25 11:38:38`
- 这轮结论包含两层关键信息：
  - Phase 83 之后，RVV narrow integer helper surface 暴露出的下一条真实问题已经从 ABI 漂移切换成 helper 算法错误
  - `vslideup.vx` 不能拿来做“只插一 lane、其余 lane 保持不变”的实现，除非源向量的后续元素也被正确初始化
- 下一轮连续计划优先级更新为：
  1. 继续沿 RVV helper surface 往下审，优先确认 `InsertF32x4/InsertF64x2` 以及其余 `Insert*` 宽度是否也存在同类 `vslideup` lane 污染
  2. 再看 `Load/Splat/Select/Extract` 这批 helper-like narrow surface 是否还有 direct-return ABI 或 stale slot 问题
  3. 继续保持 `RVV lane -> release check -> serial gate` 的闭环，不在同一 worktree 并行跑共享 `bin2/lib2` 的构建

### Phase 85: RVV narrow `InsertF32x4/InsertF64x2` float helper ABI wrapper closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeNarrowFloatHelperParity_WithVectorAsm_IfAvailable`，显式 `SetVectorAsmEnabled(True)`，并要求 `InsertF32x4/InsertF64x2` 的 dispatch-table / facade 路径与 scalar parity，同时继续保留 `ExtractF32x4/ExtractF64x2` 基线
- [x] 用 fresh RVV opcode-ready lane 复现 `Test_NativeNarrowFloatHelperParity_WithVectorAsm_IfAvailable` 的稳定 `Access violation`，确认 narrow float insert helper 仍落在 direct-return vector-return ABI 风险上
- [x] 将 `src/fafafa.core.simd.riscvv.pas` 中 `RISCVVInsertF32x4` / `RISCVVInsertF64x2` 改为 `procedure(...; var r)` + Pascal wrapper，并补 index clamp，保持与 scalar 语义一致
- [x] 用 fresh targeted RVV lane 复验 narrow float helper surface 转绿
- **Status:** complete
- Notes:
  - fresh red 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 失败点稳定命中：
    - `TTestCase_NonX86BackendParity.Test_NativeNarrowFloatHelperParity_WithVectorAsm_IfAvailable: Access violation`
  - 根因确认：
    - `InsertF32x4/InsertF64x2` 仍保留 narrow vector-return direct asm 入口，而 Phase 82 已证明 `fpc/riscv64` 下这类入口 ABI 不稳定
    - 最小可靠模式仍然是 `procedure(...; var r)` + Pascal wrapper
  - fresh green / release 复验：
    - fresh RVV narrow parity lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`

### Phase 86: RVV wider `Insert*` helper ABI wrapper closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeWideInsertHelperParity_WithVectorAsm_IfAvailable`，把 widened insert helper surface 拉进 fresh native evidence
- [x] 用 fresh RVV opcode-ready lane 复现 `Test_NativeWideInsertHelperParity_WithVectorAsm_IfAvailable` 的稳定 `Access violation`，确认 wider insert family 也存在同类 direct-return ABI 风险
- [x] 将 `src/fafafa.core.simd.riscvv.pas` 中 `RISCVVInsertF32x8`、`RISCVVInsertF32x16`、`RISCVVInsertF64x4`、`RISCVVInsertI32x8`、`RISCVVInsertI32x16`、`RISCVVInsertI64x4` 统一迁到 `procedure(...; var r)` + Pascal wrapper，并补 index clamp
- [x] 用 fresh targeted RVV lane 复验 wider insert helper surface 转绿
- **Status:** complete
- Notes:
  - fresh red 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 失败点稳定命中：
    - `TTestCase_NonX86BackendParity.Test_NativeWideInsertHelperParity_WithVectorAsm_IfAvailable: Access violation`
  - 根因确认：
    - wider insert family 与 Phase 85 的 narrow float insert 共用 direct-return vector-return 模式，根因仍是 `fpc/riscv64` ABI 不稳定，而不是新算法错误
  - fresh green / release 复验：
    - fresh RVV narrow parity lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`

### Phase 87: RVV narrow helper surface dispatch-contract shrink + ABI wrapper closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeNarrowHelperSurfaceParity_WithVectorAsm_IfAvailable`，尝试覆盖 narrow `Load/Splat/Select/Extract` helper surface
- [x] 用 fresh RVV opcode-ready lane 先复现 compile red，确认 testcase 初版把不存在于 `TSimdDispatchTable` 的 internal/helper-like symbol 当成 dispatch contract：`LoadI32x4`、`SplatI32x4`、`LoadI64x2`、`SplatI64x2`、`SelectI64x2`
- [x] 将 Phase 87 测试面收缩到真实公开的 dispatch slots：
  - `F32x4`：`Load/Splat/Select/Extract`
  - `F64x2`：`Load/Splat/Select/Extract`
  - `I32x4`：`Select/Extract`
  - `I64x2`：`Extract`
- [x] 用 fresh RVV opcode-ready lane 再次复现 runtime red：`Test_NativeNarrowHelperSurfaceParity_WithVectorAsm_IfAvailable: Access violation`
- [x] 将本轮测试实际覆盖到、且仍保留 direct-return vector-return asm 的 6 个 helper 收口到 `procedure(...; var r)` + wrapper：
  - `RISCVVLoadF32x4`
  - `RISCVVSplatF32x4`
  - `RISCVVSelectF32x4`
  - `RISCVVLoadF64x2`
  - `RISCVVSplatF64x2`
  - `RISCVVSelectF64x2`
- [x] 用 fresh targeted RVV lane、fresh combined `NonX86IEEE754 + NonX86BackendParity` lane、fresh release `check`、fresh serial `gate` 复验
- **Status:** complete
- Notes:
  - fresh compile red 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 第 1 层失败点：
    - `Identifier idents no member "LoadI32x4"`
    - `Identifier idents no member "SplatI32x4"`
    - `Identifier idents no member "LoadI64x2"`
    - `Identifier idents no member "SplatI64x2"`
    - `Identifier idents no member "SelectI64x2"`
  - 第 2 层失败点：
    - `TTestCase_NonX86BackendParity.Test_NativeNarrowHelperSurfaceParity_WithVectorAsm_IfAvailable: Access violation`
  - 根因确认：
    - 第 1 层不是生产 bug，而是测试自己把不属于 `TSimdDispatchTable` 的符号误当成公开 dispatch contract
    - 真正的 production red 来自 Phase 87 剩余 narrow helper surface 里的 direct-return asm；其实现形态与 Phase 82/85/86 已验证不稳定的 wrapper 前状态一致
  - fresh green / release 复验：
    - fresh RVV narrow parity lane：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - fresh RVV narrow parity + IEEE754 lane：
      - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86IEEE754,TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260325-phase85-87 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260325-phase85-87-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 记录关键运行结果：
    - fresh RVV narrow parity lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh RVV `TTestCase_NonX86IEEE754,TTestCase_NonX86BackendParity` combined lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：PASS，`[CHECK] OK`
    - fresh release `gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-25 12:53:56`
- 这轮结论包含两层关键信息：
  - non-x86 helper surface 审查必须先守住 `TSimdDispatchTable` 的真实 contract，不能把 backend unit 里的 internal helper 符号误当成 public dispatch slot
  - `RVV` narrow helper surface 里剩余的 `Load/Splat/Select` float helper，根因与前几轮 core/insert path 一样，仍是 direct-return vector-return asm ABI 不稳定
- 下一轮连续计划优先级更新为：
  1. 继续做 RVV helper surface 扫描，优先看 `LoadF32x4Aligned`、`ZeroF32x4/ZeroF64x2` 以及不在 dispatch contract 里的 direct helper 是否还需要同类 wrapper 收口
  2. 把视角从 RVV 扩到 x86/non-x86 runtime rebuild/toggle 路径，继续找 `SetVectorAsmEnabled(True -> False)` 后的 stale dispatch / stale capability 证据
  3. 若下一条真实问题不再落在 RVV narrow ABI，就回到 capability/public ABI 漂移审查，优先查 `BackendInfo.Capabilities` 与 `CapabilityBits` 是否还有 host-specific 偏移

### Phase 88: RVV aligned-load and zero helper ABI wrapper closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeAlignedLoadAndZeroParity_WithVectorAsm_IfAvailable`，把 `LoadF32x4Aligned`、`ZeroF32x4`、`ZeroF64x2` 纳入 native asm parity guard
- [x] 用 fresh RVV opcode-ready lane 复现 runtime red：`TTestCase_NonX86BackendParity.Test_NativeAlignedLoadAndZeroParity_WithVectorAsm_IfAvailable: Access violation`
- [x] 将 `src/fafafa.core.simd.riscvv.pas` 中 `RISCVVLoadF32x4Aligned`、`RISCVVZeroF32x4`、`RISCVVZeroF64x2` 统一迁到 `procedure(...; var r)` + Pascal wrapper
- [x] 用 fresh targeted RVV lane、fresh release `check`、fresh serial `gate` 复验
- **Status:** complete
- Notes:
  - fresh red / green 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 第 1 次 fresh red 失败点：
    - `TTestCase_NonX86BackendParity.Test_NativeAlignedLoadAndZeroParity_WithVectorAsm_IfAvailable: Access violation`
  - 根因确认：
    - `LoadF32x4Aligned` 与 `ZeroF32x4/ZeroF64x2` 仍保留 Phase 82/85/86/87 已多次证明不稳定的 direct-return vector asm 形态
    - 这说明 RVV helper surface 的 ABI 风险并没有在公开 narrow contract 收口后自然消失，而是继续残留在 aligned-load/zero 这类小 helper 上
  - fresh green / release 复验：
    - fresh RVV targeted lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260325-phase88 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260325-phase88-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-25 19:53:28`
- 这轮结论：
  - RVV helper ABI 风险继续证明是“direct-return vector asm 模式本身不稳”，而不是只集中在 insert/load/select 那几组高频 helper
  - 在 aligned-load/zero 这组三个 slot 收口后，下一轮应该优先转向其余不在公开 dispatch contract 中的 internal helper，或直接切到 toggle/rebuild stale state 审查

### Phase 89: RVV wide load/zero helper ABI wrapper closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeWideLoadAndZeroParity_WithVectorAsm_IfAvailable`，把 `LoadF32x8/F32x16/F64x4/F64x8/I64x4` 与 `ZeroF32x8/F32x16/F64x4/F64x8/I64x4` 纳入 native asm parity guard
- [x] 用 fresh RVV opcode-ready lane 复现 runtime red；失败点在 retry 中先后命中 `LoadI64x4 facade parity` 与 `LoadF32x16 facade parity`
- [x] 将 `src/fafafa.core.simd.riscvv.pas` 中 wide `Load*/Zero*` helper 全部迁到 `procedure(...; var r)` + Pascal wrapper
- [x] 用 fresh targeted RVV lane、fresh release `check`、fresh serial `gate` 复验
- **Status:** complete
- Notes:
  - fresh red / green 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - fresh red 关键失败点：
    - `TTestCase_NonX86BackendParity.Test_NativeWideLoadAndZeroParity_WithVectorAsm_IfAvailable: "LoadI64x4 facade parity lane 0: RISCVV" expected: <0> but was: <140263427446688>`
    - retry 后仍继续命中 `LoadF32x16 facade parity lane 0` garbage-value red
  - 根因确认：
    - RVV wide `Load*/Zero*` helper 仍保留 Phase 82/85/86/87/88 已多次证明不稳定的 direct-return vector asm 形态
    - 这说明 helper ABI 风险并不只停留在 narrow helper 或 aligned-load 小 helper，而是同样延伸到公开 dispatch contract 中的 wide load/zero 家族
  - fresh green / release 复验：
    - fresh RVV targeted lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260325-phase89 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260325-phase89-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-25 21:12:07`
- 这轮结论：
  - RVV direct-return vector asm 风险继续扩展到 wide `Load*/Zero*` 公开 dispatch slots，证明这不是少数 helper 的偶发问题，而是一类实现形态级缺陷
  - 在 wide load/zero 收口后，下一轮优先级应转到同一区块的 wide `Splat*`，以及 backend unit 中不在当前 dispatch contract 里的 internal helper；随后再切回 toggle/rebuild stale state 审查

### Phase 90: RVV wide splat helper ABI wrapper closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeWideSplatParity_WithVectorAsm_IfAvailable`，把 `SplatF32x8/F32x16/F64x4/F64x8/I64x4` 纳入 native asm parity guard
- [x] 用 fresh RVV opcode-ready lane 复现 runtime red：`TTestCase_NonX86BackendParity.Test_NativeWideSplatParity_WithVectorAsm_IfAvailable: Access violation`
- [x] 将 `src/fafafa.core.simd.riscvv.pas` 中 wide `Splat*` helper 全部迁到 `procedure(...; var r)` + Pascal wrapper
- [x] 用 fresh targeted RVV lane、fresh release `check`、fresh serial `gate` 复验
- **Status:** complete
- Notes:
  - fresh red / green 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 第 1 次 fresh red 失败点：
    - `TTestCase_NonX86BackendParity.Test_NativeWideSplatParity_WithVectorAsm_IfAvailable: Access violation`
  - 根因确认：
    - RVV wide `Splat*` helper 仍保留前几轮已反复证明不稳定的 direct-return vector asm 形态
    - 这说明 RVV helper ABI 风险已经覆盖到同一区块的 `Load/Zero/Splat` 三类公开 dispatch slot，而不是局部小面
  - fresh green / release 复验：
    - fresh RVV targeted lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260326-phase90 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260326-phase90-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-26 07:32:06`
- 这轮结论：
  - RVV direct-return vector asm 风险继续被证明为实现形态级问题；wide `Splat*` 收口后，公开 dispatch contract 中同一区块的高频 helper 已基本从这类风险中清掉
  - 下一轮优先级应转向 backend unit 中不在当前 dispatch contract 的 internal helper，或直接切到 `SetVectorAsmEnabled(True -> False)` rebuild stale-state 审查

### Phase 91: RVV vector-math ABI and reduction-seed closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeVectorMathParity_WithVectorAsm_IfAvailable`，把 `CrossF32x3`、`NormalizeF32x3`、`NormalizeF32x4` 纳入 native asm parity guard
- [x] 用 fresh RVV opcode-ready lane 复现真实 production red，并继续沿根因逐层收窄
- [x] 将 `src/fafafa.core.simd.riscvv.pas` 中 `CrossF32x3/NormalizeF32x3/NormalizeF32x4` 先收口到 `procedure(...; var r)` + Pascal wrapper，再修正 vector-math 族的算法/seed 语义
- [x] 用 fresh targeted RVV lane、fresh release `check`、fresh serial `gate` 复验
- **Status:** complete
- Notes:
  - fresh red / green 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 第 1 次 fresh red 失败点：
    - `TTestCase_NonX86BackendParity.Test_NativeVectorMathParity_WithVectorAsm_IfAvailable: Access violation`
  - 第 2 层 fresh red 失败点：
    - `CrossF32x3 dispatch-table parity lane 1: RISCVV expected: <-26.375> but was: <1285.25>`
  - 第 3 层 fresh red 失败点：
    - `NormalizeF32x3 dispatch-table parity lane 0: RISCVV expected: <0.233713164925575> but was: <Nan>`
  - 根因确认：
    - `CrossF32x3/NormalizeF32x3/NormalizeF32x4` 初始仍保留 direct-return vector-return asm，先继续命中与前几轮一致的 `fpc/riscv64` ABI 风险
    - ABI 收口后，`CrossF32x3` 暴露出原有 shuffle/rotate 算法本身语义错误
    - 继续收窄后，`NormalizeF32x3` 暴露出 `Dot/Length/Normalize` 这一小簇共享的 reduction seed 错误：把未定义的 `f10` 当作零初值，导致和约不稳定，进而打出 `NaN`
  - 最小生产修复：
    - `src/fafafa.core.simd.riscvv.pas` 中以下 vector-return 入口已迁到 `procedure(...; var r)` + Pascal wrapper：
      - `RISCVVCrossF32x3`
      - `RISCVVNormalizeF32x3`
      - `RISCVVNormalizeF32x4`
    - `RISCVVCrossF32x3Asm` 已改为直接按 `ax/ay/az`、`bx/by/bz` 公式计算并写回结果，去掉错误的 rotate/shuffle 序列
    - `RISCVVDotF32x3/F32x4`、`RISCVVLengthF32x3/F32x4`、`RISCVVNormalizeF32x3/F32x4` 已统一改为显式零 seed，不再依赖未初始化的 `f10`
    - `NormalizeF32x3/F32x4` 的零长度分支也已显式收口到 `feq.s ... zero` 判定，避免 fresh lane 中的 `NaN` 扩散
  - fresh green / release 复验：
    - fresh RVV targeted lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260326-phase91 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260326-phase91-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-26 08:11:32`
- 这轮结论：
  - RVV vector math 这组公开 dispatch slot 证明不止存在 direct-return ABI 风险；ABI 收口之后，算法正确性与 reduction seed 初始化也会继续暴露真实生产缺陷
  - 现在更适合把后续路线收窄为：
    1. 继续检查 vector math 剩余 contract，优先看零向量/极小向量 normalize 与 F64 vector math 是否还有合同漂移
    2. 然后切回 `SetVectorAsmEnabled(True -> False)` rebuild stale-state 审查，继续查 stale dispatch / stale capability

### Phase 92: RVV F64 dot native-slot closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeF64DotParity_WithVectorAsm_IfAvailable`，把 `DotF64x2`、`DotF64x4` 纳入 native asm parity guard
- [x] 用 fresh RVV opcode-ready lane 复现真实 production red，并收窄到 slot wiring 与实现稳定性
- [x] 将 `src/fafafa.core.simd.riscvv.register.inc` 中 `DotF64x2/DotF64x4` 接入 asm build 注册，并把 `src/fafafa.core.simd.riscvv.pas` 中这两个入口收口为 backend-local 稳定实现
- [x] 用 fresh targeted RVV lane、fresh release `check`、fresh serial `gate` 复验
- **Status:** complete
- Notes:
  - fresh red / green 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - 第 1 次 fresh red 失败点：
    - `DotF64x2 unexpectedly falls back to scalar slot: RISCVV`
  - 第 2 层 fresh red 失败点：
    - `TTestCase_NonX86BackendParity.Test_NativeF64DotParity_WithVectorAsm_IfAvailable: Access violation`
  - 根因确认：
    - `src/fafafa.core.simd.riscvv.register.inc` 在 `RISCVV_ASSEMBLY` 下根本没有把 `DotF64x2/DotF64x4` 接到 RVV backend，导致公开 dispatch slot 在 asm build 里仍静默沿用 scalar base slot
    - 把两者直接接到新写的 RVV reduce-style asm 后，fresh lane 继续稳定打出 `Access violation`，说明这两个 F64 dot 入口在当前形态下仍不适合继续走那版直写 asm
  - 最小生产修复：
    - `src/fafafa.core.simd.riscvv.register.inc` 现在会在 asm build 下注册 `DotF64x2/DotF64x4`
    - `src/fafafa.core.simd.riscvv.pas` 中 `RISCVVDotF64x2/RISCVVDotF64x4` 已收口为 backend-local Pascal 实现，先保证公开 contract 的非-scalar wiring 与语义正确性
  - fresh green / release 复验：
    - fresh RVV targeted lane：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260326-phase92 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260326-phase92-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-26 08:55:03`
- 这轮结论：
  - `F64` vector math 至少在 dot 这一支上，之前不是“结果可能不准”，而是 asm build 下根本没有 native slot wiring；fresh red 先把这个公开 contract 空洞钉了出来
  - 在当前阶段，先用 backend-local 稳定实现把 contract 补齐是更稳的做法；下一轮应回到 zero/tiny normalize edge contract，再决定是否要把 `DotF64x2/DotF64x4` 继续下沉成真正的 RVV reduce 实现

### Phase 93: RVV normalize edge tail-lane closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeNormalizeEdgeParity_WithVectorAsm_IfAvailable`，把 `NormalizeF32x3/NormalizeF32x4` 的 zero / tiny 输入纳入 native asm parity guard
- [x] 用 fresh RVV opcode-ready lane 复现真实 production red，并确认问题不是 compile noise
- [x] 将 `src/fafafa.core.simd.riscvv.pas` 中 `RISCVVNormalizeF32x3` 的 Pascal wrapper 收紧为显式零初始化并钉死 `w=0`
- [x] 用 fresh targeted RVV lane、fresh release `check`、fresh serial `gate` 复验
- **Status:** complete
- Notes:
  - fresh red / green 代表命令：
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
  - fresh red 失败点：
    - `NormalizeF32x3 zero dispatch-table parity lane 3: RISCVV expected: <0> but was: <4.55e-41>`
    - 同一条 lane 连续 3 次重试都稳定失败，只是脏值不同，说明这不是算法误差，而是 tail lane 未定义
  - 根因确认：
    - `ScalarNormalizeF32x3` 的稳定合同一直是 `w=0`
    - `RISCVVNormalizeF32x3Asm` 的 zero-length 分支只在 `vl=3` 下写回 3 个 lane，导致 wrapper 返回时 `Result.f[3]` 保留未初始化脏值
  - 最小生产修复：
    - `src/fafafa.core.simd.riscvv.pas` 中 `RISCVVNormalizeF32x3` 现在会先把 `Result` 四个 lane 清零，再调用 asm，并在返回后再次显式 `Result.f[3] := 0.0`
    - 这样把 `NormalizeF32x3` 的尾 lane 合同固定在 wrapper 层，不再依赖 RVV zero branch 是否完整写回第 4 个 lane
  - fresh green / release 复验：
    - fresh RVV targeted lane：
      - `tests/fafafa.core.simd/logs/rvv-opcode-lane-20260326-100140/summary.md`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - fresh release `check`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260326-phase93 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
    - fresh release `gate`：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260326-phase93-serial bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-26 10:06:28`
- 这轮结论：
  - 前一轮已经把 normalize 的算法/seed 语义收口，但 zero-length 边界仍然能继续暴露“返回值组装合同”层面的真实 bug
  - 现在这条 vector math edge 已经补齐；下一轮更值得回到 `SetVectorAsmEnabled(True -> False)` rebuild stale-state 审查，而不是继续在同一个 normalize slice 上重复深挖

### Phase 94: vector-asm automatic-mode late-force coverage closeout
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_SetVectorAsmEnabled_HookLateForce_Restores_AutomaticBackend` 与 `Test_SetVectorAsmEnabled_HookLateForce_DuringRestore_Restores_AutomaticBackend`
- [x] 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增对应 public ABI guard，锁定 automatic-mode `SetVectorAsmEnabled(False -> True)` 不得被 late scalar force 劫持
- [x] 用 fresh release `TTestCase_DispatchAPI,TTestCase_PublicAbi` 验证本地主机 contract
- [x] 用 fresh RVV opcode-ready lane 验证同一组 contract 在 native RISCVV lane 上仍保持 green
- [x] 用 fresh release `check` 确认 suite manifest / static gate 未被新 guard 破坏
- **Status:** complete
- Notes:
  - 这轮是 coverage closeout，不是生产修复；新增 testcase 没有打出 fresh red
  - fresh verification：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-toggle-auto-guard-20260326 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_DispatchAPI,TTestCase_PublicAbi SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
      - summary：`tests/fafafa.core.simd/logs/rvv-opcode-lane-20260326-103401/summary.md`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260326-phase94 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
- 这轮结论：
  - automatic-mode 的 vector-asm re-enable 路径，在本地主机和 native RVV lane 上都已被 machine-readable guard 证明不会被 late scalar force 留在 stale fallback
  - 下一轮更值得转向新的 fresh native red，而不是继续在这条 toggle automatic-mode 合同上加同类变体；当前最优先候选是 `F64` vector-math surface beyond `Dot*`

### Phase 95: `VecF64x4Reduce*` façade/current-dispatch drift closeout
- [x] 先对 `F64` vector-math 后续候选做 fresh 证据分流，确认 `ReduceAdd` seed-contamination 假设不是当前 RVV blocker
- [x] 用 synthetic `RegisterBackend(...)` current-dispatch testcase 打红 `VecF64x4ReduceAdd/Min/Max/Mul` façade 仍绕开 dispatch table 的合同漂移
- [x] 将 `src/fafafa.core.simd.pas` 中 `VecF64x4Reduce*` 收口为 dispatch-first + scalar fallback，并用 fresh release `DispatchAPI/check/gate` 复验
- **Status:** complete
- Notes:
  - 先补的 fresh RVV native guard：
    - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_NonX86BackendParity.Test_NativeF64ReduceAddSeedParity_WithVectorAsm_IfAvailable`
    - `FAFAFA_BUILD_MODE=Release SIMD_RVV_COMPILE_TARGET=project SIMD_RVV_LANE_SUITE=TTestCase_NonX86BackendParity SIMD_RVV_LANE_SKIP_BENCH=1 SIMD_RVV_RUNTIME_DEFINES='-dSIMD_EXPERIMENTAL_RISCVV -dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY' SIMD_RVV_SUITE_USE_PREBUILT_COMPILER=1 SIMD_RVV_COMPILE_USE_PREBUILT_COMPILER=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
    - 结果：PASS，说明“`ReduceMax` 返回值自然污染 `f10` 进而拖偏 `ReduceAdd`”这条假设在当前 RVV lane 上没有 fresh red，不应据此改生产实现
  - 真正的 fresh red 改为 stable-boundary contract drift：
    - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `TTestCase_DispatchAPI.Test_VecF64x4ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-f64x4-reduce-facade-red-20260326 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
    - 失败点：
      - `VecF64x4ReduceAdd should track current dispatch table after re-register expected: <401.25> but was: <-2>`
  - 根因确认：
    - `src/fafafa.core.simd.pas` 中 `VecF64x4ReduceAdd/ReduceMin/ReduceMax/ReduceMul` 仍直接执行手写 scalar reduction
    - 与同文件里已经 dispatch-first 的多数 façade，以及 `VecF64x8Reduce*` 的 current-dispatch 语义发生漂移；synthetic current-backend re-register 后，`GetDispatchTable^.Reduce*F64x4` 已切到新 slot，但 façade 仍返回旧 scalar 结果
  - 最小生产修复：
    - `src/fafafa.core.simd.pas` 中 `VecF64x4ReduceAdd`
    - `src/fafafa.core.simd.pas` 中 `VecF64x4ReduceMin`
    - `src/fafafa.core.simd.pas` 中 `VecF64x4ReduceMax`
    - `src/fafafa.core.simd.pas` 中 `VecF64x4ReduceMul`
    - 现已统一改成 `GetDispatchTable -> Assigned(slot) -> dispatch slot`，仅在 dispatch 缺失时回退到原来的 scalar 公式
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-f64x4-reduce-facade-green-20260326 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-f64x4-reduce-gate-20260326 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-26 22:59:30`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-f64x4-reduce-check-serial-20260326 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK]` 链与 non-x86 opt-in smoke 全绿
  - 注意：
    - 本轮第一次 `check` 失败来自我把 `check` 和 `gate` 并行跑，互踩了同一 worktree 的 `bin2/lib2`；不是代码回归
    - 之后按 `worker0` 既有约束改为串行复验，问题消失

### Phase 96: `VecF32x8Reduce*` façade/current-dispatch drift closeout
- [x] 复用 `F64x4` 的 synthetic re-register contract 方法，为 `VecF32x8ReduceAdd/Min/Max/Mul` 补 fresh red
- [x] 将 `src/fafafa.core.simd.pas` 中 `VecF32x8Reduce*` 收口为 dispatch-first + scalar fallback
- [x] 用 fresh release `DispatchAPI/DirectDispatch/check/gate` 复验，并同步最小 roadmap 真相源
- **Status:** complete
- Notes:
  - fresh red：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
    - 失败点：
      - `VecF32x8ReduceAdd should track current dispatch table after re-register expected: <123.5> but was: <-3.25>`
  - 根因确认：
    - `src/fafafa.core.simd.dispatch.pas` 已存在 `ReduceAdd/Min/Max/MulF32x8` slot
    - `GetDispatchTable^.Reduce*F32x8` 在 synthetic re-register 后已切到新 slot
    - 但 `src/fafafa.core.simd.pas` 中 `VecF32x8ReduceAdd/ReduceMin/ReduceMax/ReduceMul` 仍直接执行手写 scalar reduction，没有读取 current dispatch snapshot
  - 计划中的最小修复：
    - 只改 `VecF32x8ReduceAdd/ReduceMin/ReduceMax/ReduceMul`
    - 与 `VecF64x4Reduce*` 保持一致：`GetDispatchTable -> Assigned(slot) -> dispatch slot`，仅在 dispatch 缺失时回退到原公式
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`
    - `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/phase96-direct bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`
    - `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/phase96-check bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
    - `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/phase96-gate bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`
  - roadmap truth-source 最小同步：
    - `backlog.md` 不再把 `SIMD-B07` 作为 active queue 项
    - 新增 `SIMD-B21(candidate)`，明确当前 active 话题已经切换为 reduction façade / current-dispatch contract sweep

### Phase 97: `VecF64x2Reduce*` façade/current-dispatch drift closeout
- [x] 复用 `F64x4/F32x8` 的 synthetic re-register contract 方法，为 `VecF64x2ReduceAdd/Min/Max/Mul` 补 fresh red
- [x] 将 `src/fafafa.core.simd.pas` 中 `VecF64x2Reduce*` 收口为 dispatch-first + scalar fallback
- [x] 用 fresh release `DispatchAPI/DirectDispatch/check/gate` 复验，并同步最小 roadmap 真相源
- **Status:** complete
- Notes:
  - fresh red：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
    - 失败点：
      - `VecF64x2ReduceAdd should track current dispatch table after re-register expected: <77.5> but was: <5.25>`
  - 根因确认：
    - `src/fafafa.core.simd.dispatch.pas` 已存在 `ReduceAdd/Min/Max/MulF64x2` slot
    - synthetic re-register 后，`GetDispatchTable^.Reduce*F64x2` 已切到新 slot
    - 但 `src/fafafa.core.simd.pas` 中 `VecF64x2ReduceAdd/ReduceMin/ReduceMax/ReduceMul` 仍直接执行手写 scalar reduction，没有读取 current dispatch snapshot
  - 计划中的最小修复：
    - 只改 `VecF64x2ReduceAdd/ReduceMin/ReduceMax/ReduceMul`
    - 与 `VecF64x4Reduce*` / `VecF32x8Reduce*` 保持一致：`GetDispatchTable -> Assigned(slot) -> dispatch slot`，仅在 dispatch 缺失时回退到原公式
  - fresh green / release 复验：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`
    - `TMPDIR=/tmp/simd-f64x2-reduce-directdispatch-20260327 FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-f64x2-reduce-directdispatch-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`
    - `TMPDIR=/tmp/simd-f64x2-reduce-check-20260327 FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-f64x2-reduce-check-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
    - `TMPDIR=/tmp/simd-f64x2-reduce-gate-20260327 FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-f64x2-reduce-gate-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`
  - roadmap truth-source 最小同步：
    - `backlog.md` 中 `SIMD-B21(candidate)` 的已收口范围补入 `VecF64x2Reduce*`

### Phase 98: RVV opcode-lane contract and roadmap truth-source hygiene
- [x] 修正 `run_riscvv_opcode_lane.sh` 默认 define 链，使 runtime 默认口径与 compile/lane 都保持 opcode-ready 对齐
- [x] 收掉 `tests/fafafa.core.simd/nonx86.optin/` 的 worktree 污染风险，并把它明确纳入忽略规则
- [x] 将 `docs/plans/2026-03-24-simd-audit-closeout-roadmap.md` 降级为历史批次记录，并用 fresh release `check` 复验主线未回归
- **Status:** complete
- Notes:
  - 问题确认：
    - `tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh` 之前的默认 define 组合存在 contract drift：
      - `LANE_DEFINES` / `COMPILE_DEFINES` 默认包含 `-dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY`
      - `RUNTIME_DEFINES` 默认却只到 `-dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY`
    - 但当前 testcase / lane 语义已经把 `FAFAFA_SIMD_TEST_RISCVV_ASM_COMPILED` 与 opcode-ready 视为同一可运行合同，所以默认 runtime lane 比 compile lane 更弱会制造脚本级假分叉
  - 最小修复：
    - `tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
      - 新增 `RISCV_EXPERIMENTAL_DEFINE`
      - 让 `LANE_DEFINES` 默认显式包含 `SIMD_EXPERIMENTAL_RISCVV`
      - 让 `RUNTIME_DEFINES` 默认直接继承 `LANE_DEFINES`，只把“降级 runtime lane”保留给显式 override
    - `.gitignore`
      - 新增 `tests/fafafa.core.simd/nonx86.optin/`，避免 fresh `check/gate` 的隔离产物再次回流到 worktree
    - `docs/plans/2026-03-24-simd-audit-closeout-roadmap.md`
      - 补 `Status: completed historical batch`
      - 明确当前 active queue 以 `backlog.md` / `task_plan.md` / `workers/worker0.md` 为准
  - fresh release / hygiene 复验：
    - `bash -n tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
      - 结果：PASS
    - `git check-ignore -v tests/fafafa.core.simd/nonx86.optin/riscvv/logs/test.txt`
      - 结果：PASS，命中新增 `.gitignore` 规则
    - `TMPDIR=/tmp/simd-check-20260327-phase98-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260327-phase98 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
      - 关键信号：`NONX86-OPTIN neon/riscvv` 两条 compile smoke 都在隔离根下 fresh 运行并通过
    - `TMPDIR=/tmp/simd-gate-20260327-phase98-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260327-phase98 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`
      - 备注：末尾 Windows evidence verify 仍按默认口径 `SKIP optional`，因为本轮没有设置 `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1`

### Phase 99: wide reduction sibling guard sweep
- [x] 为尚未纳入 re-register contract 的 wide sibling façade 补 fresh guard evidence
- [x] 用 fresh release `DispatchAPI` 验证 `VecF64x8Reduce*` / `VecF32x16Reduce*` 是否仍跟随 current dispatch table
- [x] 将 B21 的剩余范围从“未知是否有 wide sibling 遗漏”收窄到“已确认两组 wide sibling 正常，仅剩其他未审 sibling”
- **Status:** complete
- Notes:
  - 先做 sibling sweep 定位后，确认当前还没有 machine-readable 守住的公开 reduction façade 主要是：
    - `VecF64x8ReduceAdd/Min/Max/Mul`
    - `VecF32x16ReduceAdd/Min/Max/Mul`
  - 静态代码检查结果：
    - `src/fafafa.core.simd.pas` 中这两组 façade 已经是 direct dispatch 形式：
      - `VecF64x8Reduce* -> GetDispatchTable^.Reduce*F64x8`
      - `VecF32x16Reduce* -> GetDispatchTable^.Reduce*F32x16`
    - 因此这轮先不假设有新的 production bug，而是按 guard 扩面处理
  - 最小测试扩面：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增：
      - `TTestCase_DispatchAPI.Test_VecF64x8ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
      - `TTestCase_DispatchAPI.Test_VecF32x16ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
    - 同时新增对应 synthetic sentinel：
      - `SyntheticReduceAdd/Min/Max/MulF64x8CurrentDispatch`
      - `SyntheticReduceAdd/Min/Max/MulF32x16CurrentDispatch`
  - fresh release 复验：
    - `TMPDIR=/tmp/simd-b21-sibling-dispatchapi-20260327-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-b21-sibling-dispatchapi-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`
      - 结论：`VecF64x8Reduce*` / `VecF32x16Reduce*` 在 synthetic re-register 后仍与 current dispatch table 保持一致，没有打出新的 façade drift
    - `TMPDIR=/tmp/simd-b21-sibling-check-20260327-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-b21-sibling-check-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
  - roadmap truth-source 同步：
    - `backlog.md` 中 `SIMD-B21(candidate)` 已补充这两组 wide sibling 的 fresh guard 结论

### Phase 100: `VecF32x4Reduce*` coverage audit closeout
- [x] 复查 `VecF32x4Reduce*` 是否仍是 B21 未覆盖 sibling
- [x] 用 fresh release `DispatchAPI` / `check` 复验当前 guard 与主门禁都保持绿态
- [x] 将结论同步回 backlog / worker：公开 float reduction façade 已全部进入“已修复或已守卫”状态
- **Status:** complete
- Notes:
  - sibling sweep 原计划是继续为 `VecF32x4Reduce*` 补一条 current-dispatch re-register contract
  - 但在实际落手时确认：
    - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 里早就已经存在
      `TTestCase_DispatchAPI.Test_VecF32x4ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
    - 对应的 `SyntheticReduce*F32x4CurrentDispatch` sentinel 也早已存在并被当前 suite 使用
  - 本轮中途误补了一份重复定义，随后立即通过 build log 诊断并移除；最终没有新增生产代码，也没有净新增测试逻辑
  - fresh release 复验：
    - `TMPDIR=/tmp/simd-b21-f32x4-dispatchapi-20260327-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-b21-f32x4-dispatchapi-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`
    - `TMPDIR=/tmp/simd-b21-f32x4-checkfix3-20260327-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-b21-f32x4-checkfix3-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
  - 结论：
    - 公开 float reduction façade：`VecF32x4/F64x2/F32x8/F64x4/F64x8/F32x16 Reduce*`
      现在都已经处于“之前 bug 已修”或“已有 machine-readable guard”状态

### Phase 101: `SIMD-B21(candidate)` closeout
- [x] 用 fresh release `gate` 为 B21 提供最终关闭证据
- [x] 将 `SIMD-B21(candidate)` 从 active queue 正式移入 done
- [x] 将 worker / findings / progress 同步到“公开 float reduction façade 已全部收口”的状态
- **Status:** complete
- Notes:
  - 范围确认：
    - `src/fafafa.core.simd.pas` 中公开 `ReduceAdd/Min/Max/Mul` façade 仅存在于 float 家族：
      - `VecF32x4`
      - `VecF64x2`
      - `VecF32x8`
      - `VecF64x4`
      - `VecF64x8`
      - `VecF32x16`
    - 没有额外的公开 non-float reduction façade 需要继续按 B21 路径收口
  - fresh release closeout 复验：
    - `TMPDIR=/tmp/simd-b21-closeout-gate-20260327-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-b21-closeout-gate-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`
      - 关键信号：
        - `DispatchAPI` / `DirectDispatch` / `DirectDispatchConcurrent` 全绿
        - public ABI smoke 全绿
        - `nonx86.optin neon/riscvv` smoke 全绿
        - Windows evidence verify 仍按默认口径 `SKIP optional`
  - closeout 结论：
    - `SIMD-B21(candidate)` 可以视为完成，不再保留为 active SIMD queue 项
    - 下一轮 SIMD 选题应切换到新的 candidate，而不是继续围绕 reduction façade sibling sweep

### Phase 103: `SIMD-B22(candidate)` F64x2 math façade current-dispatch closeout
- [x] 用 TDD 为 `VecF64x2Abs/Sqrt/Min/Max` 补 re-register contract red test
- [x] 以最小实现修复 `src/fafafa.core.simd.pas` 中 4 个 façade 的 dispatch drift
- [x] 收掉 `DispatchAPI` 中两条已声明未实现的 guard，并用 fresh release `DispatchAPI` / `check` / `gate` 完成复验
- **Status:** complete
- Notes:
  - 新 candidate 范围：
    - `src/fafafa.core.simd.dispatch.pas` 已明确定义 `AbsF64x2`、`SqrtF64x2`、`MinF64x2`、`MaxF64x2` slot
    - 但 `src/fafafa.core.simd.pas` 的 `VecF64x2Abs/Sqrt/Min/Max` 在修复前仍直接执行本地标量实现，没有读取 current dispatch snapshot
  - fresh red：
    - `TMPDIR=/tmp/simd-b22-f64x2math-red-20260327-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-b22-f64x2math-red-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
      - 结果：FAIL
      - 命中点：
        - `VecF64x2Abs should track current dispatch table after re-register lane 0`
        - `expected: <17.25> but was: <9.5>`
  - 最小修复：
    - `src/fafafa.core.simd.pas`
      - `VecF64x2Abs`
      - `VecF64x2Sqrt`
      - `VecF64x2Min`
      - `VecF64x2Max`
    - 这 4 个 façade 现在统一改为 dispatch-first，并在 `dispatch=nil` 或 slot 未绑定时才回退到原先标量实现
  - 顺手收口的测试治理缺口：
    - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 里原先已经声明、但未实现的两条 guard：
      - `Test_VecF32VectorMathFacade_Tracks_CurrentDispatchTable_After_ReRegister`
      - `Test_VecWideFloatDotFacade_Tracks_CurrentDispatchTable_After_ReRegister`
    - 本轮补齐后，它们现在也随 `DispatchAPI` fresh 绿；中途误补出重复实现，随后已通过 build log 诊断并移除重复体
  - fresh release 复验：
    - `TMPDIR=/tmp/simd-b22-f64x2math-green-20260327-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-b22-f64x2math-green-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`
    - `TMPDIR=/tmp/simd-b22-f64x2math-check-20260327-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-b22-f64x2math-check-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，`[CHECK] OK`
    - `TMPDIR=/tmp/simd-b22-f64x2math-gate2-20260327-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-b22-f64x2math-gate2-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`

### Phase 104: RVV opcode lane compile/runtime contract guard
- [x] 将 `run_riscvv_opcode_lane.sh` 的默认 opcode-ready define 合同转成 machine-readable static guard
- [x] 把 guard 接入默认 release `check` / `gate_step_build_check`
- [x] 用 fresh release `check` 验证 guard 生效且不破坏现有 non-x86 smoke
- **Status:** complete
- Notes:
  - 选题依据：
    - `Phase 98` 已确认真实风险不在 RVV lane 脚本“有没有修过”，而在“修过之后有没有持续 guard”
    - 现态 `run_riscvv_opcode_lane.sh` 已经把 `RUNTIME_DEFINES` 默认对齐到 `LANE_DEFINES`
    - 但此前默认 `check/gate` 并不会静态验证这个合同，因此后续很容易再次回退成“compile opcode-ready、runtime 非 opcode-ready”的静默漂移
  - 最小实现：
    - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_riscvv_opcode_lane_contract_guard()`
    - guard 固定校验以下 contract 片段仍存在：
      - `SIMD_EXPERIMENTAL_RISCVV` 默认已进入 `LANE_DEFINES`
      - `FAFAFA_SIMD_RISCVV_ASM_OPCODE_READY` 默认已进入 `LANE_DEFINES`
      - `COMPILE_DEFINES` / `RUNTIME_DEFINES` 默认都从 `LANE_DEFINES` 派生
      - suite / bench runtime 继续显式消费 `${RUNTIME_DEFINES}`
    - 同时把这条 guard 接入 `gate_step_build_check()` 与 `check` action 主链
  - 中途诊断：
    - 首次 fresh `check` 被 `set -u` 打红，根因是 guard 内的 pattern 字符串错误展开了 `${RUNTIME_DEFINES}`
    - 随后已把 pattern 改成字面量匹配，重新复验通过
  - fresh release 复验：
    - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
      - 结果：PASS
    - `bash -n tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
      - 结果：PASS
    - `TMPDIR=/tmp/simd-check-20260327-phase104b-tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-check-20260327-phase104b bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS，关键输出包含：
        - `[CHECK] OK (RVV opcode lane compile/runtime contract guard present)`
        - `NONX86-OPTIN neon/riscvv` smoke 仍然全绿

### Phase 105: RVV opcode lane prebuilt compiler default parity
- [x] 用默认 `Release` RVV opcode lane fresh 复现真实失败，不先猜实现层问题
- [x] 先把 suite/bench prebuilt 编译器继承关系写进静态 guard，拿到 red
- [x] 收口脚本默认值，并用 fresh `check` / default RVV lane / default `gate` 完成 green 复验
- **Status:** complete
- Notes:
  - fresh red：
    - `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_RVV_LANE_SKIP_BENCH=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
      - 结果：FAIL
      - 失败点：
        - suite 阶段用到 `/usr/local/bin/ppcrv64`
        - `fafafa.core.simd.riscvv.pas` 多处报 `Error: Unrecognized opcode vsetivli`
  - 根因确认：
    - `tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh` 修复前只有 compile-only 默认继承 `SIMD_RVV_USE_PREBUILT_COMPILER=1`
    - `SUITE_USE_PREBUILT_COMPILER` / `BENCH_USE_PREBUILT_COMPILER` 却仍默认 `0`
    - 结果是 compile-only 用带 RVV opcode patch 的 prebuilt compiler，suite/bench 却回退到容器内默认 `ppcrv64`，从而制造脚本级假红
  - TDD / guard red：
    - `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_riscvv_opcode_lane_contract_guard()` 先新增两条必需 pattern：
      - `SUITE_USE_PREBUILT_COMPILER="${SIMD_RVV_SUITE_USE_PREBUILT_COMPILER:-${USE_PREBUILT_COMPILER}}"`
      - `BENCH_USE_PREBUILT_COMPILER="${SIMD_RVV_BENCH_USE_PREBUILT_COMPILER:-${USE_PREBUILT_COMPILER}}"`
    - fresh `check`：
      - `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/red-rvv-prebuilt-guard-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：FAIL
      - 命中 guard 缺失上述两条 pattern
  - 最小修复：
    - `tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
      - `SUITE_USE_PREBUILT_COMPILER` 默认改为继承 `${USE_PREBUILT_COMPILER}`
      - `BENCH_USE_PREBUILT_COMPILER` 默认改为继承 `${USE_PREBUILT_COMPILER}`
      - 补注释说明：默认 suite/bench 必须与 compile-only 保持同一条 RVV-capable toolchain；需要降级时只能显式 override
  - fresh release 复验：
    - `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/green-rvv-prebuilt-guard-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS
    - `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_RVV_LANE_SKIP_BENCH=1 bash tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
      - 结果：PASS，`[TEST] OK`、`[LEAK] OK`、`[RVV-LANE] PASS`
    - `TMPDIR=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/tmp FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/postfix-rvv-prebuilt-gate-20260327 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`

### Phase 106: `SIMD-B23(candidate)` Linux evidence refresh and Windows blocker confirmation
- [x] 用 fresh `Release` `check` / `gate` 先确认当前 SIMD 主线没有新的代码级红点
- [x] 按 `freeze-status` 提示补齐 `qemu-cpuinfo-nonx86-evidence`，验证 Linux 主线 evidence 恢复为 PASS
- [x] 确认当前 cross freeze 剩余 blocker 仅为 stale Windows evidence，并核实 `win-evidence-via-gh` 对 dirty worktree 的 dispatch 拒绝条件
- **Status:** complete
- Notes:
  - fresh 主线复验：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/review-20260327-check bash tests/fafafa.core.simd/BuildOrTest.sh check`
      - 结果：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/review-20260327-gate bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS，最终 `[GATE] OK`
  - fresh freeze red（补 Linux evidence 之前）：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/review-20260327-gate bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
      - 结果：FAIL
      - 首要失败点：
        - `linux_qemu_cpuinfo_nonx86_evidence: step status=SKIP`
        - `windows_evidence_freshness: stale`
        - `linux_sources_not_newer_than_windows_evidence`
  - 环境预检：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
      - 结果：PASS，`workflow=simd-windows-b07-evidence.yml, repo=dtamade/fafafa.core`
    - `docker info --format '{{.ServerVersion}}'`
      - 结果：PASS，Docker daemon 可用
    - `gh auth status`
      - 结果：PASS，账号 `dtamade` 已登录且具备 `workflow` scope
  - Linux/QEMU evidence refresh：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/review-20260327-qemu-gate SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
      - 结果：PASS
      - fresh summary：`tests/fafafa.core.simd/logs/qemu-multiarch-20260327-215104-1405094/summary.md`
    - 随后复跑：
      - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/home/dtamade/projects/fafafa.core/.claude/worktrees/simd-external-evidence/.simd-output/review-20260327-qemu-gate bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
      - 结果：FAIL，但失败只剩：
        - `windows_evidence_freshness: stale mtime=2026-03-24 13:55:04`
        - `linux_sources_not_newer_than_windows_evidence`
  - 剩余 blocker 结论：
    - `tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh` 在未传 `run-id` 的 dispatch 路径下会显式检查：
      - `git status --short --untracked-files=no` 非空时拒绝：`Refuse dispatch: local worktree has uncommitted changes.`
      - remote ref 与 local HEAD 不一致时拒绝：`Refuse dispatch: remote ref does not match local HEAD.`
    - 当前 `git rev-list --left-right --count @{u}...HEAD` 为 `0 0`，说明 branch 已跟踪 `origin/simd-external-evidence`
    - 但 worktree 仍有大量未提交修改（含 `src/fafafa.core.simd.pas` / `src/fafafa.core.simd.riscvv*.pas` / tests），所以 fresh Windows evidence 现在不是“脚本坏了”，而是“需要先把当前本地状态变成可 dispatch 的 ref”，或者改走真实 Windows 实机
