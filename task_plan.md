# Task Plan: SIMD 模块审查、修复与连续计划

## Goal
审查 `fafafa.core.simd` 及其 `cpuinfo` 相关模块，找出可验证的问题并完成至少一轮根因修复，同时产出可连续执行的后续修复与审查计划。

## Current Phase
Phase 61 complete; ResetToAutomaticBackend no longer returns stale scalar after a second late hook scalar re-force during automatic restore

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
