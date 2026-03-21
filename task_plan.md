# Task Plan: SIMD 模块审查、修复与连续计划

## Goal
审查 `fafafa.core.simd` 及其 `cpuinfo` 相关模块，找出可验证的问题并完成至少一轮根因修复，同时产出可连续执行的后续修复与审查计划。

## Current Phase
Phase 38 complete; `DoInitializeDispatch` now publishes current dispatch from the immutable backend snapshot it selected, and dispatchable helper scans are serialized with runtime toggle rebuilds, so `GetCurrentBackendInfo` and dispatchable list/best helpers no longer expose half-rebuilt toggle state

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
