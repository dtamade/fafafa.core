# SIMD Review Findings

## Structural Observations

- `fafafa.core.simd` 已有较完整的文档体系，包含 `map`、`maintenance`、`checklist`、`handoff`、`publicabi` 和 `cpuinfo` 专项文档。
- 模块分层清晰地围绕 `public facade -> dispatch -> backend -> infra(cpuinfo/base/memutils)` 展开。
- 仓库明确区分了 stable surface 与 experimental surface，尤其强调 `sbRISCVV` 为显式 opt-in。
- 当前维护文档反复强调：真正成熟的主线是 `simd/dispatch/cpuinfo/avx2/avx512/neon` 的“按需修正”，而不是继续做大规模结构拆分。
- `SSE2` 被仓库显式标记为“稳定边界但不宜继续硬拆”的特殊区，说明其历史包袱和编译器敏感性仍是核心维护风险。

## Initial Risks To Validate

- 文档成熟度是否高于代码和测试现实，特别是 non-x86 / AVX-512 / public ABI 的验证闭环。
- `dispatch/cpuinfo/publicabi` 语义是否在代码、测试、文档三处完全同步。
- `BuildOrTest.sh gate` 与 evidence 脚本是否已成为可靠的发布门禁，还是仍依赖人工补洞。

## Program State Signals

- `backlog.md` 中 SIMD 长期板的当前未完成主项已明显收敛到 `SIMD-B23(candidate)`：fresh Linux/Windows evidence refresh，把 `freeze-status` 从 freshness/source-newer-than-evidence 红态拉回绿态。
- 历史上大量 SIMD 批次已经标记为完成，说明当前问题更像“成熟化收尾”和“证据闭环”而不是“核心能力缺失”。
- 维护文档与 backlog 一致传递同一方向：`gate` 适合作为日常快门禁，`gate-strict/freeze-status/native-evidence/win-evidence-via-gh` 才是发布级收口链路。

## Source/Gate Truth Signals

- 当前 worktree 存在未提交的 SIMD 相关改动，至少涉及 `src/fafafa.core.simd.pas`、`src/fafafa.core.simd.dispatch.pas`、`src/fafafa.core.simd.direct.pas`、`src/fafafa.core.simd.public_abi.impl.inc`，审查必须覆盖增量 diff，而不能只看静态现状。
- `tests/fafafa.core.simd/BuildOrTest.sh` 已形成较强的多层门禁骨架：`check -> suite smoke -> gate -> gate-strict -> freeze-status/native-evidence`。
- `BuildOrTest.sh` 明确把 `contract-signature`、`publicabi-signature`、non-x86 opt-in smoke、Windows evidence、freeze-status` 等纳入收口链路，说明成熟度瓶颈更可能在证据新鲜度与跨平台执行成本，而非缺少门禁入口。

## Diff Review Notes

- 当前 diff 仅做原子 API 统一替换：把 `atomic_load_ptr/atomic_store_ptr` 切到 `atomic_load/atomic_store` 的 `Pointer` 重载。
- `src/fafafa.core.atomic.pas` 已直接提供 `Pointer` 的重载实现，显式 `mo_acquire/mo_release` 路径与旧接口语义一致；仓库文档也把 `_ptr` 后缀视为可收敛的冗余接口。
- 到目前为止，增量 diff 未显示新的状态机、边界语义或 ABI 形状变更，更像一次 API 口径统一而非行为修改。

## Verification Notes

- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 通过。
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 通过。
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch` 通过。
- 当前尚未发现这次 atomic API 替换导致的编译、dispatch、direct dispatch 回归。
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 通过。
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` 失败，但失败项集中在发布级证据链，而非代码行为。

## Fake-Red Closeout Already Landed

- `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 已修复 dispatch API 源码形状审计对输出目录的路径假设。
- `tests/test_windows_simd_cpuinfo_x86_batch_build_success_criteria.sh` 已修复为先 probe wine runtime，可用性不足时显式 `SKIP(rc=159)`，不再把“命令存在”误判为“运行时可用”。
- `tests/check_repo_hygiene.sh` 的执行位问题已修复，`run_all_tests.sh` 不再误报脚本缺失。

## Newly Exposed Real Failures

- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test` 仍失败，`rc=217`。
- 真实失败面当前收敛到两类：
  1. 并发 runtime/public ABI 读写时的 `Access violation` / `Invalid pointer operation`
  2. SSE2/AVX2 IEEE754 `round/floor/ceil/trunc` 在 `NaN/Inf/signed-zero/randomized` 条件下不一致

## Current Root-Cause Track A: Public ABI Backend Text Publication

- 最小失败已压缩到：
  - `TTestCase_SimdConcurrentPublicAbi.Test_Concurrent_PublicAbiBackendText_RegisterBackend_ReadConsistency`
- 失败点不是抽象的“并发不安全”，而是：
  - `src/fafafa.core.simd.public_abi.impl.inc`
  - `EnsureBackendTextCache`
  - `g_SimdBackendNameCache`
  - `g_SimdBackendDescriptionCache`
- 这套实现用无锁全局 `AnsiString` cache 承接 `GetBackendInfo(...)` 的最新文本，然后把 `PAnsiChar` 指针直接暴露给调用方。
- 在 `RegisterBackend(...)` 并发切长文本时，这种“可变 managed string cache + 裸指针返回”设计天然存在 refcount / pointer 生命周期风险。
- 这与 public ABI 文档承诺存在张力：
  - 文档明确要求 `public ABI` 避免把 Pascal managed string 本身暴露成 ABI 面
  - 但当前实现仍把裸 `PAnsiChar` 绑定到可变 `AnsiString` cache 上，读者拿到指针后并没有 snapshot ownership
- 更合理的实现语义应是：
  - backend text 来自 process-lifetime published snapshot
  - 或来自 immutable default storage
  - 而不是来自可被后续注册覆盖的共享 cache

## Current Root-Cause Track B: Runtime Snapshot Publication

- `src/fafafa.core.simd.runtime.pas` 当前仍使用单个全局 `g_SimdRuntimeState`，内部含：
  - `TSimdRuntimeSnapshot`
  - `TSimdBackendInfo`（含 `Name/Description` managed string）
  - `TSimdBackendArray` 动态数组
- `GetCurrentRuntimeSnapshot` 在锁外构建 `LBuiltState`，再在锁内执行 `g_SimdRuntimeState := LBuiltState`。
- 这种“可变全局 record，内部含 managed string/动态数组”的发布模型，仍然需要保守维护；不要把它简化成 lockless / cacheless rebuild。
- 2026-05-11 这轮已先去掉只服务 `IsBackendRegisteredInBinary` 的内部 `RegisteredFlags`，让注册成员资格直接从已发布的 `RegisteredBackends` snapshot 推导，减少了 runtime 内部重复状态。
- 这条线后续如果继续动，只能沿着 invalidation + rebuild + publish 语义做进一步收口，不能把 `runtime` 再写成第二套 control-plane source of truth。

## Current Root-Cause Track C: IEEE754 Rounding Correctness

- 现有 archive 文档里已经自认：
  - SSE2 `Round` 使用的是简化算法
  - 非真正 IEEE754 banker rounding
- 这与当前失败现象吻合：
  - `NaN -> expected sentinel/int behavior but got NaN`
  - signed zero sign-bit 漂移
  - randomized finite case 出现 lane 级 `expected -1 but was 0`
- 说明这个问题不是“测试太严”，而是舍入语义本身没有被严格实现。

## 2026-05-08 Review Refresh: Interface vs Implementation

### Interface Completeness

- `python3 tests/fafafa.core.simd/check_interface_implementation_completeness.py --strict` 当前为绿：
  - `dispatch_slots_total=558`
  - `severity_counts={P0:0, P1:0, P2:0}`
- `python3 tests/fafafa.core.simd/check_dispatch_contract_signature.py --summary-line` 与 `check_public_abi_signature.py --summary-line` 当前都通过。
- 这说明 `simd` 在“公开 façade -> dispatch -> backend -> tests` 的接口挂接完整度上，已经不是缺入口、缺 wiring 的状态。
- 但它同时也说明：当前剩余问题已经从“接口不完整”转成“实现语义不完整”。

### Interface Design Remaining Friction

- `fafafa.core.simd.framework.intf.inc` 仍同时暴露 canonical façade 与 legacy alias：
  - canonical：`GetCPUInfo`、`GetCurrentRuntimeSnapshot`、`GetSupportedBackendList`、`GetDispatchableBackendList`、`TrySetCurrentBackend`
  - legacy：`GetCPUInformation`、`GetAvailableBackendList`、`TryForceBackend`、`ForceBackend`、`ResetBackendSelection`
- `src/fafafa.core.simd.cpuinfo.pas` 也仍保留 `GetAvailableBackends` / `GetBestBackendOnCPU` 这类历史命名。
- 测试已经覆盖这些 alias 与 canonical 结果一致，但接口层“太宽、别名太多”的问题仍客观存在：
  - 优点：兼容稳定
  - 代价：调用方继续有机会把 `supported_on_cpu` / `dispatchable` / `active` 三层语义混用
- 结论：接口设计当前更适合做“降噪和分级推荐”，而不是继续加新别名。
- 2026-05-11 复核后确认：`cpuinfo` legacy aliases 与 `framework` 转发层仍只是 compatibility thin shells，没有形成新的实现 truth source；这块不再阻塞 `Wave 2` 完成。

### Confirmed Implementation Gap

- 当前最小并发/public ABI 测试面已经通过：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`
  - 结果：`[TEST] OK`、`[LEAK] OK`
- 当前最小 IEEE754 测试面仍失败 5 项：
  - `TTestCase_IEEE754EdgeCases.Test_Wide_RoundTrunc_NaNInf_SSE2: SSE2 F64x2[0] Round(NaN)`
  - `AVX2 vs SSE2 RoundF64x4[0] finite compare`
  - `AVX2 vs SSE2 FloorF64x4[0] finite compare`
  - `AVX2 vs SSE2 RoundF64x4[1] finite compare`
  - `AVX2 vs SSE2 TruncF64x4[1] zero sign bit`
- 对照源码后，根因已经非常具体：
  - `src/fafafa.core.simd.sse2.pas` 的 `SSE2FloorF64x2/SSE2CeilF64x2/SSE2RoundF64x2/SSE2TruncF64x2` 仍直接走 `Math.Floor/Ceil/Round/Trunc`
  - `src/fafafa.core.simd.sse2.pas` 的 `SSE2FloorF64x4/SSE2CeilF64x4/SSE2RoundF64x4/SSE2TruncF64x4` x64 快路径仍基于旧的 `cvttpd2dq/cvtdq2pd` 方案
- 这两类实现共同导致：
  - `NaN/Inf` 语义与当前测试期望不一致
  - `signed zero` 不能稳定保真
  - `Round` 仍不是稳定的 banker-rounding 一致实现

### Overall Judgment

- 如果只看接口完整度：当前 `simd` 已经接近完整，主要剩“别名面降噪”这种接口优雅度问题。
- 如果看当前工作树成熟度：`SSE2 F64 round/floor/ceil/trunc` 与 Windows `cpuinfo.x86` batch success-criteria 合同缺口都已被当前工作树修复，Linux fast-gate 已重新回到绿态。
- 因而当前剩余问题已经从“stable surface 还不完整”转成“release 级跨平台证据是否足够新、环境能力是否满足 strict closeout”。

## 2026-05-08 Gate Closeout Update

- `tests/fafafa.core.simd.cpuinfo.x86/buildOrTest.bat` 现已补齐两个关键合同：
  - `LAZBUILD` 指向 batch wrapper 时，用 `call` 保证执行返回父批处理。
  - `lazbuild` 返回非零但 `build.txt` 已出现 compile/link summary 时，输出 `WARN ... compile/link summary is present` 并接受为 `BUILD OK`。
- 对应的真实 smoke 已通过：
  - `bash tests/test_windows_simd_cpuinfo_x86_batch_build_success_criteria.sh`
- Linux 侧 full test 也已回到绿态：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test`
- 最终 `Release gate` 已通过，且最后的 `filtered run_all check chain` 现为 5/5 绿：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前判断更新为：
  - stable interface completeness：绿
  - stable implementation behavior：绿
  - remaining release closeout gaps：仍主要是 `freeze-status/gate-strict` 所依赖的跨平台证据刷新与环境能力，不是 stable surface 再补接口或再补基础实现

## 2026-05-08 Runtime Snapshot Consistency Closure

- 为了把 `runtime snapshot` 本身的并发完整度补成直接证据，本轮新增：
  - `TTestCase_SimdConcurrentFramework.Test_Concurrent_RuntimeSnapshot_VectorAsmToggle_ReadConsistency`
- fresh release 运行这条新回归时，首次直接抓到真实 mixed snapshot：
  - `CurrentBackend=sbAVX2`
  - `CurrentBackendInfo=AVX2`
  - `BestDispatchableBackend=sbAVX2`
  - 但 `DispatchableBackends=[sbScalar]`
- 这不是“两个独立 helper 分别跨代读取”的已知文档边界，而是 `GetCurrentRuntimeSnapshot` 自己仍可能发布跨代拼接结果。
- 根因非常具体：
  - `src/fafafa.core.simd.runtime.pas` 旧实现只在发布前校验 `Dispatch` 指针是否仍等于 target
  - `SetVectorAsmEnabled(True/False)` 在构建期间可以经历多次 dispatch 重建
  - 即使最终又回到同一个 active dispatch 指针，中途也可能让 `DispatchableBackends` / `BestDispatchableBackend` 来自另一代状态
  - 因而“只看最终 dispatch 指针是否相等”不足以证明整份 snapshot 同代
- 最小修复已落地：
  - 在 runtime cache 中引入 `TargetVersion`
  - `dispatch-changed hook` 每次 dispatch publication 后递增 `g_SimdRuntimeTargetVersion`
  - `GetCurrentRuntimeSnapshot` 只有在“预构建版本 == 发布前复核版本”且 `Dispatch` 指针未漂移时才接受 `LBuiltState`
- 修复后 fresh 证明：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - `python3 tests/fafafa.core.simd/check_interface_implementation_completeness.py --strict`
  - `python3 tests/fafafa.core.simd/check_dispatch_contract_signature.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_public_abi_signature.py --summary-line`
  - 结果：全部通过

## Release-Readiness Gaps

- `2026-05-17 10:47:10` 的 canonical gate 已确认 Linux 主 gate 新鲜且通过，`qemu-cpuinfo-nonx86-evidence` 对 `linux/arm/v7`、`linux/arm64`、`linux/riscv64` 全部 PASS；`freeze-status-linux` 已是 `ready=True` / `mainline-ready=True`。
- full `freeze-status` 仍为 `ready=False`，但当前红项已经收敛成：
  - `cross_gate_required_steps: evidence-verify=SKIP`
  - `windows_b07_gate.log` / `windows_b07_closeout_summary.md` 的 freshness、source-newer-than-evidence 与 verify
- `2026-05-17` fresh `win-evidence-preflight` 再次返回 `RECENT_BILLING_BLOCK`；因此 `freeze-status` 现在也会显式展示 `windows_preflight_latest`，并把 next-actions 收敛到 “先处理 billing / 或切到手工 Windows runner 路径”，不再机械推荐 `win-evidence-via-gh` / fail-close gate / stale verify。
- 这说明当前 SIMD 的成熟度问题不再是 Linux/QEMU 证据缺口，也不是“当前 diff 有 bug”，而是“发布级 Windows evidence 还没有按当前源码时间线刷新”。

## Evidence Sources

- `docs/fafafa.core.simd.md`
- `docs/fafafa.core.simd.cpuinfo.md`
- `docs/fafafa.core.simd.checklist.md`
- `docs/fafafa.core.simd.handoff.md`
- `src/fafafa.core.simd.README.md`
- `tests/fafafa.core.simd/BuildOrTest.sh`

## 2026-05-12 Redundancy Survey Start

- 当前最强的冗余信号不是源码层的新重复体，而是 `docs/plans/*simd*` 和顶层 SIMD 文档面仍然很厚。
- `plan status index`、`execution index`、`family matrix`、`global architecture plan`、`wave2 seam hardening plan` 已经构成当前 active spine。
- 其余大量 `simd` 计划更偏历史基线、阶段记录或已吸收的专题笔记，后续需要按 `active / historical baseline / superseded / deletion candidate` 分类。
- 初步看源码层的重复实现比文档层少很多，当前更可能的“卫生问题”是重复 truth source、重复政策说明和重复计划入口，而不是大面积同构函数体还没收口。
- 复核后确认：`docs/plans/2026-02-06-zero-warnings-hints-fs-simd.md` 并非漏索引，它在 `plan status index` 里已有 `superseded historical plan` 头。
- 更真实的源码冗余密度在 fallback/compatibility 薄壳上：`NEON` 相关文件仍有大量 `Result := Scalar...` 转发，`RISCVV` facade 也保留大量同类转发，但这些多数是有意的 adapter 面，不是新的 truth source。
- 目前更值得关注的代码层 residual 是少数仍保留本地 loop 的 semantic-sensitive 路径，尤其 `RISCVV` 的 `Min/Max/Round/Trunc/Clamp` 一类，它们是“暂缓合并”而不是“忘了去重”。

## 2026-05-12 Redundancy Survey Classification

### Active truth sources

- `docs/plans/2026-05-10-simd-plan-status-index.md`
- `docs/plans/2026-05-10-simd-execution-index.md`
- `docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md`
- `docs/plans/2026-05-09-simd-family-matrix.md`
- `docs/plans/2026-05-11-simd-family-decision-baseline.md`
- `docs/SIMD_LAYERING_IMPLEMENTATION.md`
- `docs/SIMD_BACKEND_TRUTH.md`
- `docs/SIMD_INTRINSICS_DISPOSITION.md`
- `docs/SIMD_SSE2_MIGRATION_MAP.md`
- `docs/fafafa.core.simd.map.md`

### Historical but keep for provenance

- `docs/plans/2026-02-*simd*.md` 到 `docs/plans/2026-04-*simd*.md` 这批旧执行计划已经被 `plan status index` 降级为 historical / superseded。
- `docs/SIMD_MODULE_ANALYSIS.md`
- `docs/SIMD_COMPREHENSIVE_AUDIT_REPORT.md`
- `docs/SIMD_QUALITY_ITERATION_PLAN.md`
- `docs/SIMD_ITERATIVE_OPTIMIZATION_PLAN.md`
- `docs/SIMD_QUALITY_ITERATION_5.1_REPORT.md`
- `docs/legacy/simd/fafafa.core.simd.next-steps.md`（由 `src/fafafa.core.simd.next-steps.md` 迁入）

这些文件当前不该再进入 active reading path；如果要进一步卫生整理，优先移动/归档，而不是先删除。

## 2026-05-15 Register Truthfulness Allowlist Hygiene Gap

- 当前最值当的新问题不在 `NEON` backend 代码本身，而在 `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 的 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 仍保留了过多旧豁免。
- 实测当前 `NEON` allowlist 有 `134` 项，但按 checker 自己的实时分类口径，真实 `wrapper_only` 只有 `108` 个唯一 slot；两者之间多出的 `26` 项全部是已经在前几批里收正过的名字。
- 这 26 个 stale allowlist 名字是：
  - `ClampF32x8/F32x16`
  - `LoadF32x8/F32x16/F64x4/F64x8`
  - `MinF32x8/F64x4`
  - `MaxF32x8/F64x4`
  - `SplatF32x8/F32x16/F64x4/F64x8`
  - `SqrtF32x8/F32x16/F64x4/F64x8`
  - `StoreF32x8/F32x16/F64x4/F64x8`
  - `ZeroF32x8/F32x16/F64x4/F64x8`
- `RISCVV` allowlist 当前是干净的：`26` 个允许项和 `26` 个真实 `wrapper_only` slot 完全一致，没有 stale allowlist。
- 这类 stale allowlist 的风险不是“数字难看”，而是 checker 会继续把已经修掉的 `NEON` fake backend-owned slot 视为合法例外；后续若有人把这些名字重新绑回 wrapper，truthfulness checker 可能第一时间抓不出来。
- 因此 checker 自己也需要 fail-close：

## 2026-05-17 Closeout Entry Rehearsal Gap Closed

- 当前高价值 residual 已不在 SIMD 实现层，而在 closeout 入口是否会把已知外部 blocker 诚实前置。
- `print_windows_b07_closeout_3cmd.sh` 和 `buildOrTest.bat` 虽然已经会提示 `RECENT_BILLING_BLOCK`，但此前缺少一条 Linux 侧 machine-check，无法保证这类 warning 以后不会静默漂移。
- 本轮新增的 `rehearse_windows_closeout_3cmd.sh` 让这个提示具备了两面证明：
  - blocked case 必须出现 warning banner + do-not-run 提示
  - pass case 必须不出现 billing warning
- 这条 rehearsal 现已并入 `gate-summary-selfcheck`，同时 `runner-parity` 也会静态断言 batch 侧仍保留同一 warning 签名。
- 因而当前 closeout 叙事层的最小结论是：
  - repo 内入口已 fail-close 到位
  - 剩余 blocker 继续诚实收敛到 Windows external evidence，而不是重新打开 SIMD 泛审查

## 2026-05-17 Active Docs Still Needed A Preflight Caveat

- 在入口脚本已经把 `RECENT_BILLING_BLOCK` 前置成 warning 之后，active 文档层还残留一类更隐蔽的误导：
  - `closeout-release` / `win-evidence-via-gh` 仍在多个入口文档里以“当前推荐主线”的口吻出现
  - `simd_completeness_matrix.md` 还保留一句未加限定的“Windows 实机证据也已闭环”
- 这些句子单看都不算假，但在当前 `HEAD` 的 `freeze-status=ready=False` 背景下，会把“历史入口存在/历史归档已闭环”和“当前就能继续收口”混写。
- 最小修法不是删入口，而是把前提写死：
  - 先过 `win-evidence-preflight`
  - 若 latest 结果仍是 `RECENT_BILLING_BLOCK`，就在 preflight 处 fail-close
  - 历史 “Windows 已闭环” 只能按 archive fact 理解，不是当前 readiness signal
- 这类修法的价值在于继续把 repo 内剩余工作收窄成：
  - 真正 blocker 只在 Windows external evidence
  - repo 内还可做的，只剩真相源同步和误导点消除

## 2026-05-17 Windows Runbook Needed A Header-Level Stop Note

- `windows_b07_closeout_runbook.md` 的流程本身没有错，但它的页头仍停在旧时间线，也没有把 latest `RECENT_BILLING_BLOCK` 升到顶层。
- 这会导致一个很具体的误读：
  - 读者进入专门的 Windows closeout runbook 时，会先看到 “cross-ready 目标”
  - 却不一定先意识到当前 `HEAD` 还处在 preflight blocked 状态
- 最小修法依旧不是改流程，而是把 stop note 前移到标题区下面：
  - 当前只按流程 runbook 理解
  - Billing/额度恢复或真实 Windows runner 就绪前，不把它当当前可执行主线
- 这让 repo 内 active 文档链的最前几屏都统一回到了同一个事实：
  - 当前代码主线绿
  - 当前发布主线红在 Windows external evidence

## 2026-05-17 Closeout-Release Needed Runtime Fail-Close, Not Just Docs

- 在 docs / helper 都已经写清楚 blocked reality 后，`closeout-release` 主入口本身仍有一个真实缺口：
  - 第 3 步 `win-evidence-preflight` 一旦因为 `RECENT_BILLING_BLOCK` 失败
  - 主入口只会把 rc 往外抛，不会顺手把 “现在应停止” / “当前状态” / “下一步命令” 打给操作者
- 这类缺口的坏处很具体：
  - 文档读者也许已经知道 stop condition
  - 但真正直接执行 `closeout-release` 的人，仍要自己去猜当前失败是不是“继续 GH evidence”还是“先处理 billing”
- 本轮因此把 fail-close 逻辑下沉到主入口本身，而不是继续依赖外围文档。
- focused rehearsal 还顺手抓到一个真实 shell 细节 bug：
  - `if ! cmd; then rc=$?` 在这里拿到的是反转后的 `0`
  - 如果不修，新的 stop note 分支实际永远不会命中
- 所以这批不是单纯的 wording polish，而是：
  - 审出主入口 fail-close 缺口
  - 实现修复
  - 用轻量 rehearsal 把 shell 退出码语义也钉住了
  - 允许项必须是“当前真实仍然 unavoidable 的 wrapper-only slot”
  - `allowed_wrapper_slots - current_wrapper_only_slots` 只要非空，就说明 allowlist 落后于源码真相，应该直接报错而不是悄悄放过
- 这批修完后，`unused_allowlist_count` 应回到 `0`；以后这项也应该作为 summary 和 human report 的固定输出，避免 allowlist 又悄悄膨胀。
- fresh 修复后，`NEON` 与 `RISCVV` 的 truthfulness summary 都已回到 `unused_allowlist=0`；说明 allowlist 已重新与当前真实 slot ownership 对齐。

## 2026-05-15 NEON Narrow Shift Residual

- 在 allowlist hygiene 收口之后，`ALLOWED_ALWAYS_ASM_HELPER_SLOTS_BY_BACKEND` 这条线已经是干净的；下一处真正有价值的残余落在 `NEON` 当前 `wrapper_only` 分布里最后 5 个 `no-asm + scalar_forwarder` slot。
- 这 5 个 slot 是：
  - `ShiftLeftI16x8`
  - `ShiftLeftU16x8`
  - `ShiftRightArithI16x8`
  - `ShiftRightI16x8`
  - `ShiftRightU16x8`
- 它们的结构和之前已收掉的 `Fma/Rcp/F32x8 arithmetic` 很像，但更干净：
  - no-asm 实现都只是 exact `ScalarShift*` forwarder
  - 全仓没有任何更宽 no-asm source consumer 再引用这些 wrapper
  - asm build 里同名函数仍有真实 `neon.pas` owner
- 这意味着它们在 no-asm 下继续占着 `NEON` dispatch slot 没有真实语义价值，只会让 published ownership 比 runtime truth 更松。
- 收完这 5 个之后，一个重要里程碑是：
  - 当前 `NEON wrapper_only` 分组里不再剩 `no-asm + scalar_forwarder`
  - 也就是 `NEON` 当前 residual 已从“死转发占 slot”收窄到真正 unavoidable 的 `pascal_owned` / asm companion 类别

### Cleanup candidates

- `docs/INDEX.md` 先前声称 `simd` 专题文档已归位到 `docs/simd/`，这已经修正为模块级顶层文档 + `docs/legacy/simd/` 历史草案入口。
- 顶层 `SIMD_*` 历史快照虽然都有 internal / historical note，但仍和 active docs 同目录并列，容易在搜索结果里压过当前主链。
- `src/fafafa.core.simd.next-steps.md` 已迁入 `docs/legacy/simd/`，原路径现仅保留跳转 stub。

### Code redundancy judgment

- 当前代码层没有发现新的大面积“多重实现都算真源”的问题。
- `NEON` / `RISCVV` fallback 仍有很多 `Scalar*` thin forwarder，这是 adapter compatibility surface；不是当前最大债务。
- 真正要继续清理代码，应只挑 `replacement + parity evidence + checker guard` 三者齐全的 exact-contract fallback。
- `RISCVV` 当前保留的 local loop / branch 主要卡在 `Min/Max/Round/Trunc/Clamp` 等语义敏感路径，下一批不能只凭“看起来像 scalar”直接合并。

## 2026-05-12 Historical Snapshot Archive Findings

- 已把顶层 `SIMD_MODULE_ANALYSIS.md`、`SIMD_COMPREHENSIVE_AUDIT_REPORT.md`、`SIMD_QUALITY_ITERATION_PLAN.md`、`SIMD_ITERATIVE_OPTIMIZATION_PLAN.md`、`SIMD_QUALITY_ITERATION_5.1_REPORT.md`、`NEON_ASM_IMPLEMENTATION_STATUS.md`、`NEON_MATH_OPTIMIZATION_ITERATION_2.5.md` 迁入 `docs/legacy/simd/`，并补了 `docs/legacy/simd/README.md` 作为归档索引。
- 原位置现在只保留跳转占位，不再承载正文。
- `docs/fafafa.core.simd.md` 与 `src/fafafa.core.simd.README.md` 已补充 legacy 导流，避免读者再次把历史快照当成 active truth source。

## 2026-05-15 NEON No-Asm Wide Sqrt Findings

- `NEON` wide `Sqrt` 这批不能机械套用上一批 `Add/Sub/Mul/Div` 的模式，必须先区分“dead wrapper”和“仍被 source graph 消费的 companion”。
- `NEONSqrtF32x8`、`NEONSqrtF32x16`、`NEONSqrtF64x8` 在 no-asm 下都只是 exact scalar/leaf 组合，而且全仓没有其他 live source consumer；它们既不该继续占据 `NEON` runtime slot，也没有继续保留 no-asm wrapper 的必要。
- `NEONSqrtF64x4` 则不同：虽然它的 no-asm runtime slot 同样不该继续伪装成 backend-owned，但 `NEONSqrtF64x8` 的 no-asm source graph 仍会消费它，所以它不是 dead wrapper，只能收回 slot ownership，不能把 source companion 一并删掉。
- 这批再次证明“删 wrapper”和“slot 回 scalar”是两件不同的事：
  - `F32x8/F32x16/F64x8`：dead wrapper，可删源码壳，slot 也回落到 scalar
  - `F64x4`：source companion 仍有消费面，只能把 no-asm published slot 收回 scalar
- 正确收法是让 `src/fafafa.core.simd.neon.register.inc` 中 `SqrtF32x8/F32x16/F64x4/F64x8` 只在 `FAFAFA_SIMD_NEON_ASM_ENABLED` 下绑定，同时把 `scalar.autowrap.inc` 中 3 个 dead wrapper 删掉，保留 `NEONSqrtF64x4`。
- `dispatchapi` 两处旧 capability 断言此前把这 4 个 wide `Sqrt` 一概视为 native-slot，这和当前更诚实的 no-asm truth 冲突；现在已统一改成“NEON 复用 scalar、其余 backend 仍要求 native”。
- fresh 现场数据继续支持这是实质性收正，不是只改注释：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=601 status=ok`
  - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon assignments=357 asm_exact=233 asm_suffix_only=10 wrapper_only=114 scalar_passthrough=0 no_def=0 miswired=0 strict=1`
  - `backend=riscvv` 继续保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 miswired=0`
- `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
- Release `check` / `gate` 全部通过，`gate` 最终明确到 `GATE OK`
- 下一批仍不建议直接机械扩到 `Round/Trunc/Clamp`；`Min/Max` 如果要继续做，也必须先重新审 `NaN/compare/ordering` 语义，而不是按 `Sqrt` 套模板。

## 2026-05-15 NEON No-Asm Wide MinMax Findings

- `NEON` wide `Min/Max` 这批最开始看上去像 `Sqrt` 的同类，但真正的审查重点不是 wrapper 拓扑，而是 no-asm 下的浮点选择语义。
- 先做的本地 Pascal probe 已确认：`Math.Min/Max` 与 no-asm 的 `if a < b then a else b` / `if a > b then a else b` 在以下关键场景上结果一致：
  - `NaN, x`
  - `x, NaN`
  - `-0, +0`
  - `+0, -0`
  - 相等普通值
- 这意味着 `NEONMin/MaxF32x4` 与 `NEONMin/MaxF64x2` 虽然源码上不是 `ScalarMin/Max` 单行转发，但它们当前并不构成额外的 published semantic truth source；wide `Min/Max` 的 no-asm slot 可以像 `Sqrt` 一样回落到 scalar，而不会把 `NaN/±0` 语义悄悄改坏。
- 这批仍然要分清三类角色：
  - `NEONMin/MaxF32x8`：no-asm dead wrapper，可删
  - `NEONMin/MaxF32x16`：asm build 仍需要的 source wrapper，保留
  - `NEONMin/MaxF64x4/F64x8`：更宽 source graph 或 asm build 仍会消费的 wrapper，保留
- 因此正确修法不是“所有 wide Min/Max 都删掉”，而是：
  - `register.inc` 中 `Min/MaxF32x8/F32x16/F64x4/F64x8` 改成 asm-only binding
  - `scalar.autowrap.inc` 中仅删除 `NEONMin/MaxF32x8`
  - 其余 `F32x16/F64x4/F64x8` wrapper 继续保留
- fresh 结果继续证明这批是实质性收正，不是只改测试文案：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=603 status=ok`
  - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon assignments=357 asm_exact=237 asm_suffix_only=10 wrapper_only=110 scalar_passthrough=0 no_def=0 miswired=0 strict=1`
  - `backend=riscvv` 继续保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 miswired=0`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `check` / `gate` 全部通过，`gate` 最终明确到 `GATE OK`
- 这批也再次说明一个规则：`wrapper_only` 的治理不能只按“看起来像宽 wrapper”分组，必须先做最小语义 probe，确认 `NaN/ordering` 没有隐含分歧，再决定是否把 published slot 收回 scalar。

## 2026-05-13 Mid/Wide Integer Facade Guard Findings

- `VecI64x4AndNot/CmpLe/CmpGe/CmpNe`、`VecI32x16AndNot/CmpLe/CmpGe/CmpNe`、`VecU32x16AndNot/CmpLe/CmpGe/CmpNe` 都是当前 `src/fafafa.core.simd.pas` 真实公开的 façade contract，不是误补 API。
- 这几组在本轮之前已经有 `dispatchapi` parity 或 `direct` multi-backend 旁证，但还缺“固定 `sbScalar`、不借 dispatch parity 旁证”的 direct guard；因此当前缺口属于证据层，而不是实现层。
- `TTestCase_IntegerFacadeGuards` 已经是仓库现成的 scalar-forced façade direct suite，继续扩这一个 suite 比再造一条平行 suite 更低风险，也不会再碰 runner manifest。
- `simd.utils` 里存在与 façade 同名的 `VecI32x16CmpEq/Lt/Gt` helper，返回类型是 `TMaskI32x16`；通用 testcase 若不显式写 `fafafa.core.simd.VecI32x16Cmp*`，编译期就可能误绑到 utils surface。
- 因而后续继续补 `I32x16` façade 相关 guard 时，应该把“显式限定到 `fafafa.core.simd`”视为固定写法，而不是偶发修补。

## 2026-05-13 Wide Tail Integer Facade Guard Findings

- `VecU64x8CmpLe/CmpGe/CmpNe`、`VecI16x32AndNot`、`VecI8x64AndNot` 都是当前 `src/fafafa.core.simd.pas` 的真实 façade surface，不是补到了不存在的 API。
- 这三项此前的覆盖主要停留在 `dispatchapi.testcase` 的 façade-vs-scalar parity；也就是说调用面已经被证明“能连上”，但还缺固定 `sbScalar`、不依赖 parity 的 direct contract 证据。
- `TTestCase_IntegerFacadeGuards` 继续证明自己适合作为整数 façade direct guard 的统一承载点：同一套 `ForceBackend(sbScalar)` / `ResetBackendSelection` 生命周期足以覆盖 128/256/512-bit 整数 façade，不需要再复制出 family-local guard suite。
- 目前整数 façade direct guard 的剩余缺口已经明显收窄；后续如果继续深扫，更值得优先看的是是否还存在公开 surface 只有 parity 证据，而不是继续扩已经足够密集的 multi-backend parity 测试。

## 2026-05-13 U64x4 Facade Direct Guard Findings

- `VecU64x4CmpEq/Lt/Gt/Le/Ge/Ne` 是当前 `src/fafafa.core.simd.pas` 的真实 façade compare surface；在本轮之前，它仍然主要依赖 `dispatchapi/direct` parity，而没有 scalar-forced direct guard。
- `U64x4` 当前没有 family-local façade testcase，因此继续把它收进 `TTestCase_IntegerFacadeGuards` 是比新建 `vecu64x4` suite 更低风险的落点。
- 本轮再次证明：当前整数 façade 的剩余工作大多已经不是“发现实现 bug”，而是“把公开 contract 的 direct evidence 补齐，并把测试预期写准”。

## 2026-05-12 Narrow Compare Guard Findings

- 当前窄整型 compare 的真实缺口不是“没有实现”，而是“缺少直接 guard”：
  - `src/fafafa.core.simd.scalar.pas` 与 `src/fafafa.core.simd.dispatch.pas` 已存在 `I16x8/I8x16/U16x8/U8x16` 的 `CmpLe/CmpGe/CmpNe`；
  - 但旧测试基本只通过 parity 间接覆盖，没有在 `narrowintegerops` 里直测这些 contract。
- 这批 contract 的 API 边界必须区分清楚：
  - `I16x8/I8x16/U16x8/U8x16` 的 `CmpLe/CmpGe/CmpNe` 不是 `fafafa.core.simd` façade 公共 API；
  - 它们属于 dispatch table / scalar truth；
  - `U32x4` 的 `AndNot/CmpLe/CmpGe` 才属于 façade 层，适合继续用 `VecU32x4*` 直接守语义。
- `tests/fafafa.core.simd/fafafa.core.simd.narrowintegerops.testcase.pas` 的 `SetUp` 已经固定 `ForceBackend(sbScalar)`，因此新增的 dispatch-level compare 测试不是在打“某个活动 SIMD backend”，而是在对 scalar active table 做直接 guard。
- 这批补测后，窄整型 compare contract 的覆盖形态更完整了：
  - façade 缺口不会被误补成不存在的 API；
  - dispatch/scalar 合同不再只靠 backend parity 间接路过；
  - `U32x4` 的 façade `AndNot/CmpLe/CmpGe` 也不再只在 `DispatchAPI` 里有 parity 证据。

## 2026-05-13 Low-Width Integer Facade Guard Findings

- `I32x4`、`I64x2`、`U64x2` 这三组 128-bit 低宽整数 façade 之前也有同类证据空档：
  - `src/fafafa.core.simd.pas` 已公开暴露这些函数；
  - 但测试面主要只有 `dispatchapi.testcase` 的 façade-vs-dispatch parity；
  - 缺少 family-local、scalar-forced 的 direct guard。
- 这批边界必须按真实 public surface 区分：
  - `I32x4/I64x2` 的公开合同是 `AndNot + Eq/Lt/Gt/Le/Ge/Ne`
  - `U64x2` 的公开合同只有 `AndNot + Eq/Lt/Gt`
  - 不能像上批 narrow compare 一样误补不存在的 façade API。
- 新增的 `TTestCase_IntegerFacadeGuards` 证明了一点很重要的 runner 事实：
  - 在这个仓库里，单纯 `RegisterTest(TSuiteClass)` 不足以让 `--suite=...` 可选；
  - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 的 `ProcessAllSuites` 共享清单也必须同步；
  - 否则 targeted run 会出现“Tests run: 0 / suite filter matched no tests”的假红。
- 收口后，这三组低宽整数 façade contract 已不再只剩 parity 旁证：
  - `I32x4/I64x2/U64x2` 的位运算与 compare 公开语义现在都有 scalar-forced direct proof；
  - runner suite manifest 也同步维持 `registered_suites=handled_suites`，不会让新增 suite 变成隐形测试。

## 2026-05-12 Scalar AndNot Hidden Drift

- `AndNot` 在当前仓库的公开合同是稳定且明确的：
  - `tests/fafafa.core.simd/fafafa.core.simd.narrowintegerops.testcase.pas` 明确写了 `AndNot(a, b) = (NOT a) AND b`
  - `scalar` 里多处旧注释也明确写成 “与 SIMD 指令 `PANDN` 语义一致”
  - `riscvv` fallback / facade 以及 `simd.pas` 自身 fallback 也都按 `(not a) and b` 实现
- 但 `scalar` 真源内部之前实际存在一簇隐藏漂移：
  - `ScalarAndNotU16x8` 与 `ScalarAndNotU32x8` 写反成了 `a and (not b)`
  - `ScalarAndNotI8x16` 与 `ScalarAndNotU8x16` 缺失，导致 base dispatch 只能临时挂本地 wrapper
- 真正掩盖问题的是 `FillBaseDispatchTable`：
  - `AndNotI8x16` / `AndNotU16x8` / `AndNotU8x16` 之前并没有直接绑到 `Scalar*`
  - 而是绑到 `dispatch.pas` 里的 `DispatchAndNot*` 本地 loop
  - 所以大量 “backend vs scalar table parity” 只能证明各 backend 与 dispatch wrapper 一致，不能证明 `scalar.pas` 内部实现本身正确
- 这解释了为什么该漂移能在现有 gate 下长期潜伏：
  - `U16x8/U8x16/I8x16` 缺少强制 scalar backend 的直接语义测试
  - `U32x8` 也缺 `VecU32x8AndNot` 的直测，导致写反的 `ScalarAndNotU32x8` 没有被单独打到
- 收口原则应保持为：
  - `Scalar*` 才是基础真源
  - `FillBaseDispatchTable` 不再持有补洞式第二份局部 truth
  - direct semantic tests 必须覆盖那些“看起来只是 bitwise 小函数、但其实容易被 parity 测试掩盖”的槽位

## 2026-05-12 Source Reachability Findings

- 先前“NEON scalar 散文件可能未引用”的初扫里有一批假阳性：
  - `fafafa.core.simd.neon.scalar.compare.inc`
  - `fafafa.core.simd.neon.scalar.math.inc`
  - `fafafa.core.simd.neon.scalar.ext_math.inc`
  - `fafafa.core.simd.neon.scalar.vector_math.inc`
  - `fafafa.core.simd.neon.scalar.reduction.inc`
  - `fafafa.core.simd.neon.scalar.memory.inc`
  - `fafafa.core.simd.neon.scalar.utility.inc`
  - `fafafa.core.simd.neon.scalar.autowrap.inc`
  - `fafafa.core.simd.neon.facade_scalar.inc`
- 它们不是死文件，而是通过 `fafafa.core.simd.neon.scalar_fallback.inc` 的嵌套 `{$I ...}` 间接进入 `src/fafafa.core.simd.neon.pas`。
- `src/fafafa.core.simd.neon.scalar.wide_memory.inc` 目前不在 live compile 链，但它不是垃圾文件：
  - 现有 `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 直接读取它，作为 non-x86 helper semantics / wide slot 审计样本。
  - 因而它当前应被归类为 `audit-only retained source`，而不是 `delete candidate`。
- 真正确认可删的 unreachable 源码只有 10 个：
  - `src/fafafa.core.simd.cpuinfo.x86.asm.pas`
  - `src/fafafa.core.simd.neon.scalar.wide_reduce.inc`
  - `src/fafafa.core.simd.sse2.ext_math.inc`
  - `src/fafafa.core.simd.sse2.f32x8_arith.inc`
  - `src/fafafa.core.simd.sse2.f32x8_compare.inc`
  - `src/fafafa.core.simd.sse2.facade_extra.inc`
  - `src/fafafa.core.simd.sse2.i64x2_arith.inc`
  - `src/fafafa.core.simd.sse2.mask.inc`
  - `src/fafafa.core.simd.sse2.memory.inc`
  - `src/fafafa.core.simd.sse2.saturating.inc`
- 这批 SSE2 `.inc` 不是“尚未挂接的将来实现”，而是和 `src/fafafa.core.simd.sse2.pas` 内现有 live 定义重叠的历史残片；删除它们能减少“第二份实现看起来存在但实际上永远不编译”的误导。
- `src/fafafa.core.simd.cpuinfo.x86.asm.pas` 也是死单元，而且质量信号更差：
  - 仓库内没有任何 `uses` / source entry 引它。
  - 文件内部仍保留明显残缺和不自洽代码，继续留着只会制造“也许还有另一套 x86 asm CPUID 真源”的假象。
- 当前更有价值的缺守卫不是再写一篇文档，而是机器化 reachability：
  - 新增 `check_simd_source_reachability.py` 后，可以稳定拦住未来再出现 unreachable private include。
  - 允许保留的特例目前只剩 `fafafa.core.simd.neon.scalar.wide_memory.inc`，并且理由已经冻结为 audit-only checker input。

## 2026-05-12 Deep Review Refresh

### Live guardrail status

- `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line` 当前为绿：
  - `experimental_units=15`
  - `leaked_units=0`
  - `missing_guard_markers=0`
- `python3 tests/fafafa.core.simd/check_dispatch_read_scope.py --summary-line` 当前为绿：
  - `allowed_files=3`
  - `forbidden_hits=0`
  - `facade_issues=0`
- `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line` 当前为绿：
  - `checks=459`
  - `status=ok`
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86` 当前为绿：
  - `helper-semantics / wiring-sync / riscvv-abi-shape / register-truthfulness(neon,riscvv) / key-slot-audit / targeted-release-suites` 全部通过
  - native evidence verifier 仍为显式 `SKIP`，因为本地没有提供 `SIMD_NONX86_NATIVE_EVIDENCE_ROOT`

结论：

- 当前没有新的 seam 回退、experimental 泄漏或 non-x86 helper/wiring 漂移。
- “继续深挖 SIMD 缺失”时，默认不该再回头怀疑 `dispatch/dataplane/public ABI/direct` 主链是否重新变坏。

### Confirmed current missing pieces

- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` 仍失败，但失败形态已经很具体：
  1. `qemu-cpuinfo-nonx86-evidence=SKIP`
  2. Linux 最新 gate artifact 旧于最新源码：`src/fafafa.core.simd.neon.compare.inc`
  3. Windows evidence log / closeout summary 已过 freshness 阈值
- 这说明当前最真实的缺失不是 stable surface 再补接口，也不是 non-x86 helper 再补大批代码，而是：
  - 发布级跨平台 evidence refresh
  - gate artifact freshness 跟上最新源码
  - Windows closeout 重新跑到新鲜时间线
- `framework/cpuinfo` 层目前仍缺一个正式的“alias visibility / deprecation policy”：
  - `src/fafafa.core.simd.framework.intf.inc`
  - `src/fafafa.core.simd.cpuinfo.pas`
  - 现在虽然 canonical 和 legacy 行为一致，但仓库还没有把“哪些名字推荐继续用、哪些只是 compatibility shell”冻结成单独规则。
- experimental hold 家族当前只有统一的 reopen baseline：
  - `docs/plans/2026-05-11-simd-family-decision-baseline.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
  - 这已经够防止误开线，但还没有 family-specific trigger granularity；对 `AES/SHA/AVX/FMA3/SVE/SVE2/LASX` 来说，这仍是一种“治理层缺失”，不是实现 bug。

### Confirmed current redundancies

- API 命名层的重复仍在：
  - `framework.intf.inc` 同时保留 canonical façade 与 legacy alias
  - `cpuinfo.pas` 同时保留 `GetSupportedBackendList/GetSupportedBackends/GetAvailableBackends`、`GetBestSupportedBackend/GetBestBackendOnCPU/GetBestBackend`
  - 这些不是实现 truth-source 冗余，但仍是接口认知冗余，会继续放大 `supported_on_cpu / dispatchable / active` 三层语义混用风险
- 文档入口层的重复噪音仍在：
  - `docs/NEON_ASM_IMPLEMENTATION_STATUS.md`
  - `docs/NEON_MATH_OPTIMIZATION_ITERATION_2.5.md`
  - `docs/SIMD_MODULE_ANALYSIS.md`
  - `docs/SIMD_COMPREHENSIVE_AUDIT_REPORT.md`
  - 这些文件现在都只是历史快照占位，但仍与 active `docs/SIMD_*` 真相表同目录并列，搜索/目录浏览时仍会制造视觉竞争

### Non-issues to stop re-litigating

- `dispatch -> dataplane -> façade/public ABI/direct` 的 publication seam 现在已有 live guardrail 证明，不应再按“可能还有第二套 truth source”反复重开。
- `NEON/RISCVV` 当前剩下的非 thin-wrapper 局部实现，大多属于语义敏感区或 backend-owned slot，不应只因为“看起来像 scalar loop”就继续机械合并。
- 当前更高价值的后续审查，不是继续统计 wrapper 数量，而是：
  1. release evidence freshness
  2. alias visibility policy
  3. hold family trigger granularity

## 2026-05-12 Plan Implementation Closeout

### What landed

- alias visibility / canonical-first policy 已正式落在：
  - `src/fafafa.core.simd.framework.intf.inc`
  - `src/fafafa.core.simd.cpuinfo.pas`
  - `docs/fafafa.core.simd.interface.md`
  - `docs/fafafa.core.simd.md`
  - `docs/fafafa.core.simd.cpuinfo.md`
  - `src/fafafa.core.simd.README.md`
- `experimental hold` 当前不再只有统一 reopen prose：
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md` 现已补成 family-specific trigger table
  - `AES/SHA/AVX/FMA3/SVE/SVE2/LASX` 都各自写明了 reopen 条件、required lane 和伪触发条件
  - `docs/plans/2026-05-11-simd-family-decision-baseline.md` 与 `docs/plans/2026-05-09-simd-family-matrix.md` 现已改成引用这张细化表，而不是各自重写一份 hold policy
- 顶层历史占位页现在统一升级成“保路径 + 强导流”模板：
  - 所有顶层 `docs/SIMD_*.md` / `docs/NEON_*.md` 历史快照占位都明确回指 `docs/legacy/simd/README.md`
  - `docs/legacy/simd/README.md` 也已显式说明这些顶层单页只是 path-preserving stubs，不是当前真相源
- active closeout 文档已同步当前 evidence blocker 口径：
  - `docs/fafafa.core.simd.closeout.md`
  - `docs/fafafa.core.simd.checklist.md`
  - `docs/fafafa.core.simd.handoff.md`
  - `src/fafafa.core.simd.STABLE`

### Fresh verification after landing

- `git diff --check` 通过
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 通过
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 通过
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` 仍失败，但失败已重新收敛成：
  1. `qemu-cpuinfo-nonx86-evidence=SKIP`
  2. `windows_b07_gate.log` / `windows_b07_closeout_summary.md` stale
- 重要的是：这次 fresh `gate` 之后，`linux_sources_not_newer_than_gate` 已转绿。
- 结论：本轮仓库内 policy / docs / source-comment 落地没有引入任何新的 gate 回归；剩余红点继续只属于 cross-platform evidence lane。

## 2026-05-11 NEON Vector Math Exact-Contract Finding

- `src/fafafa.core.simd.neon.scalar.vector_math.inc` 的 non-ASM `Dot / Cross / Length / Normalize` fallback 与 `src/fafafa.core.simd.scalar.pas` 中的 `Scalar*` vector-math 实现同合同。
- 这批属于安全的 duplicate truth-source cleanup：可以把 fallback body 收成 `Scalar*` forwarder，并用 `check_nonx86_helper_semantics.py` 锁住。
- 这不改变 `src/fafafa.core.simd.neon.pas` 里的 ARM64 asm fast path，也不改变 register ownership；它只是让 fallback 不再维护第二份标量真源。
- 后续继续扫重复体时仍要遵守当前边界：rounding、clamp、浮点 min/max、native compare/select 等语义敏感路径必须先有独立 parity 证据，不能只因为“长得像”就合并。

## 2026-05-09 Interface Truth Closeout

- 当前最大的认知债不是“SIMD 是否还能跑”，而是 `SSE2` 的接口层归属之前没有被一份当前真相表写死。
- 代码真相非常明确：
- `src/fafafa.core.simd.sse2.pas` 当前承载 backend registration、`TVec*` / `TMask*` façade 语义、`wide_emulation`、mem/text/stat helper 与多寄存器组合语义。
- `src/fafafa.core.simd.intrinsics.sse2.pas` 和 `src/fafafa.core.simd.intrinsics.x86.sse2.pas` 都仍带 experimental guard，不能再被描述成当前发布真相源。
- 这意味着此前“不要继续硬拆 SSE2”并不等于“不要再定义归属”；真正缺的是：
  - backend truth table
  - intrinsics disposition table
  - SSE2 migration bucket map
- 本轮落地后，`SSE2` 的最短判断已经可以收敛成一句：
  - `simd.sse2` 是当前 backend adapter truth source
  - `intrinsics.sse2` 是 transitional wrapper
  - `intrinsics.x86.sse2` 是 future raw-leaf target，但当前仍是 experimental isolated
- 新的 `check_sse2_structure.py` 已经把这条判断写进机器护栏，不再只靠口头记忆：
  - 反向依赖禁令：`simd.sse2` uses clause 里不得出现 `fafafa.core.simd.intrinsics.sse2`

## 2026-05-11 AVX2 Sample Noise Cleanup

- `src/fafafa.core.simd.avx2.pas` 与 `src/fafafa.core.simd.avx2.register.inc` 当前的主要噪音不是语义重复，而是历史批次遗留的 `NEW / Iteration / milestone` 标记。
- 这些标记删掉之后，AVX2 的真实结构更清楚：adapter 继续承担 façade / registration / composition，intrinsics 继续只承接 raw primitive。
- 这轮没有引入新实现分支，也没有改变 dispatch wiring。
- 复验已通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AVX2IntrinsicsFallback`

## 2026-05-11 X86 Incremental Noise Cleanup

- `src/fafafa.core.simd.sse3.pas` / `src/fafafa.core.simd.sse3.register.inc` / `src/fafafa.core.simd.ssse3.pas` / `src/fafafa.core.simd.ssse3.register.inc` 里的历史标记属于同一类噪音，不是新架构层。
- 这些文件的真实角色没有变化：`SSE3` 继续是 SSE2 的增量 backend adapter，`SSSE3` 继续通过 `CloneDispatchTable` 继承 `SSE3` 再加少量 override。
- 这轮同样没有改 dispatch wiring，也没有引入新的 truth source。
- 进一步核对后，`SSSE3MinI8x16 / SSSE3MaxI8x16` 现在只保留 direct helper 兼容面，没有新的 owned override 需要保留。
- 复验已通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`

## 2026-05-11 SSE2 F32 Vector Math Helper Consolidation

- `SSE2LengthF32x4 / SSE2LengthF32x3` 和 `SSE2NormalizeF32x4 / SSE2NormalizeF32x3` 也是同一条 zero-w + length + divide 控制流，适合像 SSE3 / AVX2 / SSE4.1 一样收进 shared helper。
- 这批补了 SSE2 代表性证据：`DispatchAPI` 现在直接覆盖 `LengthF32x4/F32x3`、`NormalizeF32x4/F32x3`、zero-vector fallback 与 `F32x3` 的 `w=0` 语义，不再只看 Round/Dot/Cross。
- `src/fafafa.core.simd.sse2.vector_math.inc` 没有任何 `include` 或测试引用，是一份不参与构建的镜像重复源；删掉后，仓库里少了一份会误导后续判断的旧文本。
- `check` 首轮冒出的 `inline` hints 说明 new helper 只是局部 refactor，还没完全贴合 stable-unit 检查口径；去掉 `inline` 后 `check/gate` 重新归绿。
- 验证链路：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - raw-leaf 边界：`intrinsics.x86.sse2` 不得出现 `TVec*`、`TMask*`、`TSimdDispatchTable`、`RegisterSSE2Backend`、`runtime/cpuinfo/dispatch` 依赖
  - 文档真相漂移：三张真相表缺行、改 status、删 sentinel 会直接让结构检查失败

## 2026-05-09 Architecture Review Closure

- 三层主设计本身是正确的：对这个仓库，`façade -> intrinsics` 两层直通仍然不成立，`public/control surface -> backend adapter -> raw leaf` 继续是最稳的骨架。
- 上一版主文档剩下的不是“核心分层错误”，而是“全局反映还不够完整”：
  - `public ABI wrapper` 是真实存在的外部稳定包装面，但此前没有在主设计文档里被显式安置。
  - `src/fafafa.core.simd.direct.pas` 是真实存在的 direct dataplane companion，但此前也没有被明确放进架构图。
- 这两个面都不应被误判成新 layer：
  - `public ABI wrapper` 逻辑上属于第一层旁的 external stable wrapper，物理上通过 `simd.pas` 的 `public_abi` include 实现。
  - `direct` 逻辑上属于第一层旁的 fast-path companion，只读取已发布 dataplane snapshot，不拥有 control-plane 真相。
- 因而本轮文档修正的关键不是推翻三层，而是把“三层骨架 + 两个伴生出口”的全局口径写完整。
- 修正后可以更明确地区分 3 件事：
  - Pascal façade / runtime / cpuinfo / dispatch 是主公开与控制面
  - public ABI wrapper 是外部 ABI 包装面，不等于 `TSimdDispatchTable`
  - direct dispatch companion 是仓库内热点入口，不等于 backend adapter
- 继续顺着阅读链复核后，又确认 `src/fafafa.core.simd.architecture.md` 和 `src/fafafa.core.simd.README.md` 的旧层图如果不同步，会继续把读者带回过度简化的旧心智模型；因此本轮也已把这两处高层图改成与正式实施基线兼容的版本，并显式回指 `docs/SIMD_LAYERING_IMPLEMENTATION.md`。

## 2026-05-09 Publication Seam Closeout

- 继续从整个模块视角复核后，发现“最优雅终态”还差最后一个关键命名：`dataplane` 之前虽然已经在代码里承担真实角色，但还没有在主设计文档里被正式提升成 `publication seam`。
- 代码证据已经足够明确：
  - `src/fafafa.core.simd.pas` 的 façade fast-path 会从 `dataplane` 取 bound pointers
  - `src/fafafa.core.simd.public_abi.impl.inc` 会从 `dataplane` 取 bound API table 成员
  - `src/fafafa.core.simd.direct.pas` 直接读取 `dataplane` 已发布 dispatch snapshot
- 因而当前最优雅、也最贴近代码现实的全局形态应写成：
  - `public surface`
  - `control/publication seam`
  - `companion surfaces`
  - `backend adapters`
  - `raw leaves`
- 其中：
  - `dispatch` 负责 control-plane truth
  - `dataplane` 负责 published binding seam
  - `public ABI wrapper` / `direct` / façade fast-path 都只是 seam 的消费者
- 这次文档收口的核心价值不是再发明新层，而是把已经存在的共享结构从“实现细节”提升成“正式架构位”，这样下一会话才不会重新把它拆散或误判成局部缓存技巧。
- 仅靠三张真相表还不够，因为它们主要回答“谁是谁”，不直接回答“为什么不能做成两层”。
- 对这个仓库来说，两层 `façade -> intrinsics` 不成立的根因很具体：
  - 公开 contract 是 `TVec*` / `TMask*`，不是 `TM128`
  - compare 结果需要 façade 级 mask 压缩/翻译
  - `wide_emulation`、多寄存器组合与 helper 不是单条 intrinsic 直通
  - runtime / dispatch / backend registration 属于控制面，不应污染 raw leaf
  - experimental intrinsics 默认隔离，不能被 stable façade 默认穿透引用
- 因此这里正确的最终形态不是“删掉中间层”，而是：
  - stable façade / control-plane
  - thin backend adapter
  - raw intrinsics leaf
- 新增 `docs/SIMD_LAYERING_IMPLEMENTATION.md` 的意义，就是把这条判断从口头说明变成后续实施时的正式裁决基线。
- 但第一版主文档还有 3 个会误导后续实施的矛盾：
  - 把 `fafafa.core.simd.*` 写得过宽，容易让人把 `dispatch` 也误判成 backend adapter
  - 把“SSE2 现在先只迁 128-bit”偷换成全仓库全局规则，和 `intrinsics.avx2` 这个 `active leaf` 例外不一致
  - 把 `experimental isolated` 写成概念边界，却没有把“stable adapter 只允许新增依赖 active leaf”写成硬准入规则
- 这些矛盾现在已经在设计文档里被收口：
  - 三个逻辑层：public/control surface -> backend adapter -> raw leaf
  - 四类单元：public surface、dispatch infra、backend adapter、raw leaf family
  - 四种 intrinsics 状态：`active leaf`、`experimental isolated`、`transitional`、`retire target`
  - 一条实施准入规则：default stable backend adapter 只允许新增依赖 `active leaf`
- 对下一轮实施最关键的新增结论是：
  - `SSE2_MIGRATION_MAP` 的 A 桶现在只是目标归属图
  - 只要 `intrinsics.x86.sse2` 仍是 `experimental isolated`，stable `simd.sse2` 就不应新增对它的默认依赖
  - 下一轮真正的第一个动作，不是直接让 adapter 委托过去，而是先把目标 leaf 做到“可准入判断”：补 raw tests，然后做 promote 或 split 决策

## 2026-05-09 Whole-Module Refactor Pivot

- 如果目标是“整个 simd 模块重构好，不要冗余，正确架构”，那么当前 `SSE2` 计划必须降级成局部子计划，不能再被当成总规划。
- `SSE2` 之所以先被详细写，是因为它同时带着：
  - 当前 stable adapter truth source
  - transitional wrapper
  - future raw leaf target
- 这三重身份让它的债务最集中。
- 但其他 ISA family 并不是没被考虑，而是状态不同：
  - `Scalar/MMX/SSE/AVX2` 更接近“可作为正样板”的状态
  - `SSE3/SSSE3/SSE4.1/SSE4.2/AVX-512/NEON/RISCVV` 属于“已有 adapter，但 raw leaf 还没完成准入”的一组
  - `AES/SHA/AVX/FMA3/SVE/SVE2/LASX` 仍应停留在 opt-in experimental lane
- 因此整体重构不应按“一个 family 一个例外规则”推进，而应按统一治理模型推进：
  - 先统一层次：`public/control surface -> seam -> companion -> adapter -> raw leaf`
  - 再统一状态：`active leaf / experimental isolated / transitional / retire target`
  - 再统一准入：stable adapter 只允许新增依赖 `active leaf`
- 对“冗余”的最新定义已经收敛成 4 类，而不只是“文件太多”：
  - 真相源冗余：同一 family 同时有多个 current truth source
  - 语义冗余：同一 raw primitive 在 adapter / wrapper / leaf 长期复制
  - 入口冗余：backend 选择、published binding、ABI/direct 各自维护第二套真相
  - 状态冗余：每个 family 自己发明能否进入 stable adapter 的规则
- 全模块的正确推进顺序应是：
  1. 冻结 global refactor plan
  2. 建立全 ISA family matrix
  3. 先收紧 `dispatch/dataplane/public ABI/direct` 的统一边界
  4. 再按 family 分波次做 qualification / promote / split / retire
- 这意味着：
  - `AVX2` 应作为正样板，被显式提炼成可复制模式
  - `SSE2` 应作为高债务试点，被放在 Wave 3，而不是继续充当整个模块的代名词
  - `NEON/RISCVV/AVX-512` 等 family 后续也必须进矩阵，而不是留在“以后再说”的状态

## 2026-05-09 Plan Completeness Review

- 我对当前重构计划的判断更新为：
  - 在补 matrix 之前，它是 `architecture-correct`
  - 在补完 matrix、文档分工、Wave exit criteria 之后，它才进入 `execution-ready`
- 这次补完后的关键改进不是“多写了一份表”，而是把 3 个常见失控点堵上了：
  - 不再让 `SSE2` 子计划冒充全模块主线
  - 不再让阅读地图、状态表、总纲互相抢 source-of-truth
  - 不再让每个 family 的下一动作只存在于聊天上下文里
- 但它仍然没有到 `closeout-complete`，因为下面几类文档还没单独展开：
  - `SSE2` promote / split / retire 决策文档
  - `SSSE3` adapter-only / `no dedicated raw leaf target` 口径统一
  - `AES/SHA/AVX/FMA3/SVE/SVE2/LASX` future trigger 文档
- 所以“这份计划完善了吗”的准确回答是：
  - **已经够启动 whole-module refactor**
  - **但还没完整到可以一口气收所有 family**
  - **接下来应继续按 matrix 推进 family-level 执行与剩余 closeout 文档，而不是回头重写总纲**

## 2026-05-09 Family-Level Plan Expansion

- 现在 whole-module 文档链已经不只停在总纲和 matrix：
  - `AVX2` 已单独被写成 active-leaf 正样板
  - `NEON` 已单独被写成 family qualification plan
  - `RISCVV` 已单独被写成 family qualification plan
  - `SSE3/SSSE3/SSE4.1/SSE4.2/AVX-512` 已被收口到共享 x86 incremental qualification plan
- 这意味着当前文档系统已经回答了两类不同问题：
  - “整个 simd 模块该怎么重构”
  - “到了某个 family，这一波具体按什么口径执行”
- 计划完善度因此进一步更新为：
  - **planning/documentation: execution-ready with main family plans present**
  - **implementation/refactor rollout: still pending actual code waves**

## 2026-05-10 Execution Index Addition

- 当前最大的“实施摩擦”已经不是缺总纲，而是：
  - 文档链变完整之后，新会话很容易不知道第一步该进哪一页
  - 使用者需要自己从 `global plan -> matrix -> family plan -> scratch` 手动解压执行顺序
- 这类摩擦不会靠再补架构原则解决，所以新增了单页执行索引：
  - `docs/plans/2026-05-10-simd-execution-index.md`
- 这页的作用不是替代总纲，而是把 whole-module 计划压成一条固定起手顺序：
  - 先看当前波次
  - 再看 family matrix
  - 再进对应 family plan
  - 先跑 baseline
  - 改完后只更新 family plan / matrix / scratch
- 结论：
  - **现在已经存在一个可以让总计划正常实施的执行索引**

## 2026-05-11 SSE4.1 Dword Multiply Cleanup

- `SSE41MulI32x4` 与 `SSE41MulU32x4` 当前是同一个 `PMULLD` 语义的双份实现；`PMULLD` 取低 32-bit 乘积，signed / unsigned 只影响解释方式，不影响结果 bit pattern。
- `TVecI32x4` 与 `TVecU32x4` 是两种不同 record 类型，但 payload 都是 16 bytes；最干净的收口方式不是把 dispatch slot 混绑成不匹配的函数指针，而是在 `SSE4.1` 单元内引入一个私有 shared dword multiply kernel，让两个 typed wrapper 各自保持签名。
- `SSE4.1` 源码和 register include 仍残留 `✅ / NEW / Task` 历史标记；这属于实现噪音，不是语义文档，应和这次 `PMULLD` 收口一起清掉。
- FPC 对“把 `Result` 通过 untyped `var` helper 传给 asm kernel”会产生 `parameter unused / result uninitialized` false-positive hint；当前采用 raw pointer kernel + typed `out` wrapper 的形态，既保留单一实现，又能通过 strict no-hints check。
  - 后续如果计划再扩张，应优先维护 execution index，而不是再让使用者自己从总纲里提取顺序

## 2026-05-11 AVX2 Dword/Word Multiply Cleanup

- `AVX2MulI32x4 / AVX2MulU32x4` 与 `AVX2MulI16x8 / AVX2MulU16x8` 也是同码低位乘法：signed / unsigned 只改变解释，不改变 `vpmulld / vpmullw` 的结果 bit pattern。
- 这类实现不该继续以两份完整 asm body 维护；更合理的收口是把 raw kernel 收在 `AVX2MulDwordVecRaw` / `AVX2MulWordVecRaw`，再让 typed wrapper 保持各自 dispatch 签名。
- 这次没有触碰 dispatch ownership 或 register 结构，`AVX2` 仍然是样板 active leaf，只是把重复 multiply kernel 收回单一真源。
- release 验证已通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 AVX2 128-bit Bitwise Cleanup

- `AVX2` 的 128-bit integer bitwise 组之前同时按 signed/unsigned 和 lane width 写了多份同构实现，核心都是同一组 `vpand / vpor / vpxor / vpandn / all-ones-xor`。
- 这类函数必须保留 typed wrapper 和 dispatch slot，但实现真源不需要重复；现在所有 `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2` 的 `And / Or / Xor / Not / AndNot` 都走共享 raw helper。
- `AVX2NotVecRaw` 使用 dword all-ones mask 生成 128-bit 全 1 payload，这对 8/16/32/64-bit lane 都是同一 bitwise 语义。
- 这次没有改变 dispatch ownership，也没有把 AVX2 adapter 推向 raw leaf；它只是把同一 adapter 内的 repeated body 收回单一 kernel。
- release 验证已通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-10 SIMD Plan Hygiene

- 当前新的主要干扰已经不是“没有入口”，而是：
  - `docs/plans/` 中堆积了大量旧 `simd` 计划
  - 其中很多名字带 `final`、`closeout`、`roadmap`、`phase2`、`frontier`
  - 它们虽然当时真实有效，但现在已经不是当前 whole-module refactor 的 active queue
- 这类文档如果不显式退役，即使入口页已经正确，也会在搜索结果、目录列表、旧聊天引用里继续制造干扰。
- 因此当前正确动作不是“先删”，而是先做 `plan hygiene`：
  - 新增单页状态索引：`docs/plans/2026-05-10-simd-plan-status-index.md`
  - 把真正 active 的链路固定为：
    - `execution index`
    - `global refactor plan`
    - `family matrix`
    - 4 份 family-level plan
  - 把更早的 `2026-02 ~ 2026-04` 执行计划整体降为 `historical baseline` 或 `superseded historical plan`
- 结论：
  - **已完成 plan 与冲突 plan 需要清，但优先级是“退役出主链”高于“物理删除文件”**
  - **active 入口必须单一，历史计划必须显式标状态，否则继续干扰实施**

## 2026-05-10 Wave 2 Active Plan Completion

- `plan hygiene` 完成之后，当前 whole-module 文档链已经足够判断“谁该看、谁不该看”，但还差最后一层：
  - 当前默认第一波是 `Wave 2 / seam hardening`
  - 但 active 链里还没有一份 fresh 作战单，能把这波的文件边界、红线、baseline 和完成标准单独写死
- 旧文档虽然有可复用内容，例如：
  - `2026-04-15 runtime/cpuinfo/dataplane closeout`
  - `2026-03-11 public ABI wrapper implementation`
  - 但它们都已经被降为历史文档，不能再直接当 active plan 用
- 因此当前新增：
  - `docs/plans/2026-05-10-simd-wave2-seam-hardening-plan.md`
- 这份文档的作用不是重写总纲，而是把当前第一波实现收敛成一个 bounded batch：
  - control-plane truth 只认 `dispatch`
  - published binding truth 只认 `dataplane`
  - `public ABI` / `direct` / `façade fast-path` 都退回 companion consumer 角色
  - 明确不夹带 `SSE2/AVX2/NEON/RISCVV` family migration
- 结论：
  - **当前 whole-module SIMD 文档链已经达到实施级完备**
  - **下一步如果继续，不该再补总纲，而该直接按 `Wave 2 seam hardening` 开始改代码**

## 2026-05-11 Current Seam Audit

- 当前代码面还存在一个明显的残余：`src/fafafa.core.simd.pas` 里的大量 façade wrapper 仍直接调用 `GetDispatchTable`，而不是显式读取 `dataplane` 发布的 snapshot dispatch。
- `src/fafafa.core.simd.dataplane.pas` / `direct.pas` / `public_abi.impl.inc` 已经在消费 published snapshot；剩余不一致主要集中在主 façade 的普通 vector/memory wrapper。
- 这意味着下一步最有价值的代码动作，不是继续补总纲，而是把主 façade 的 dispatch 读取路径统一到 published dataplane seam，顺手把这条 seam 写进可验证测试。
- 已完成这一步的统一后，`check`、`TTestCase_DataPlane,TTestCase_PublicAbi`、`TTestCase_DispatchAPI,TTestCase_RuntimeAPI`、`TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework` 以及 `gate` 都已通过，说明 façade/public ABI/direct 的 published snapshot 收口没有把现有门禁打坏。

## 2026-05-11 Companion Surface Unification

- 继续把剩余消费面收口后，`src/fafafa.core.simd.api.pas`、`src/fafafa.core.simd.ops.pas`、`src/fafafa.core.simd.arrays.pas` 已统一改为读取 `GetDirectDispatchTable`，不再直接摸 `GetDispatchTable`。
- 同步移除了 `src/fafafa.core.settings.inc` 里已失效的 `SIMD_USE_DIRECT_DISPATCH` 开关说明与宏定义，避免保留一条实际不再分叉的配置路径。
- 这次改动把 public façade / operator overloads / array math 三条消费面统一到同一条已发布 dispatch 入口，减少了重复 getter 和“控制面真源”直读残留。
- 验证结果：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_VectorOps,TTestCase_OperatorOverloads,TTestCase_VecF32x8,TTestCase_VecI32x8,TTestCase_VecF64x4,TTestCase_Vec512Types,TTestCase_DispatchAPI,TTestCase_DataPlane,TTestCase_PublicAbi,TTestCase_DirectDispatch,TTestCase_RuntimeAPI`
  - `tests/fafafa.core.math/bin/tests_math --suite=TTestMathArray`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- `tests/fafafa.core.math/BuildOrTest.sh` 的全量运行里还有一个与本次改动无关的既存规则失败，指向 `TTestMathRules` 检出的旧仓库问题，不属于这批数组/dispatch 收口回归。

## 2026-05-11 Dispatch Read Scope Guard

- 当前 `src` 里的 `GetDispatchTable` 直接读只剩 6 处，而且都在 `src/fafafa.core.simd.dispatch.pas`、`src/fafafa.core.simd.dataplane.pas`、`src/fafafa.core.simd.runtime.pas` 这 3 个内部单元里。
- 这和当前架构口径一致：`dispatch` 负责 control-plane truth，`dataplane` 负责 published binding，`runtime` 负责 control-plane snapshot；消费者面不该再直接摸 `GetDispatchTable`。
- 已新增 `tests/fafafa.core.simd/check_dispatch_read_scope.py`，并接入 `tests/fafafa.core.simd/BuildOrTest.sh` / `buildOrTest.bat` 的 `check` 主线，用机器检查封住未来回退。
- Release 复验结果：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 结果：通过，`DISPATCH_READ_SCOPE symbol=GetDispatchTable scanned_files=157 allowed_files=3 allowed_hits=6 forbidden_hits=0`

## 2026-05-10 Wave 2 Batch 1 Implementation Findings

- 当前第一批真正需要先收的冗余，不在 family，而在 `public ABI wrapper` 自己那套“已发布 metadata state + target dispatch ptr + invalidate hook + raw dispatch fallback”组合。
- 这套实现虽然之前测试是绿的，但它在结构上仍然保留了第二条 publication/control 解释路径：
  - 绑定复用按 `Dispatch` 指针判断
  - 失效触发靠自己的 `g_SimdPublicApiTargetDispatchPtr`
  - cdecl wrapper 在绑定缺失时会直接回退到 `GetDispatchTable`
- 这与当前文档已经冻结的 `dispatch = control truth`、`dataplane = publication truth` 口径不一致。
- 本轮已把 `public ABI` 收回到真正的 companion surface 语义：
  - `TSimdPublicApiBindingState` 现在直接记住 `DataPlane`
  - 绑定状态按 `PSimdDataPlane` 复用，而不是再额外发明一套 target dispatch 状态
  - `GetLiveSimdPublicApiBindingState` 直接跟随 `GetCurrentSimdDataPlane`
  - `PublicAbi*` 的兜底路径不再直读 `GetDispatchTable`，而是回到当前 published `dataplane` 槽位
- 这意味着当前 public ABI 的生命周期语义变成：
  - `dispatch` 只负责控制面选择
  - `dataplane` 只负责发布当前 snapshot
  - `public ABI` 只负责把这份 snapshot 包装成稳定 cdecl table，并按同一 published snapshot 复用
- 相关 seam 约束已通过测试固化：
  - `TTestCase_DataPlane.Test_DataPlane_ExplicitRebind_WithoutDispatchMutation_PreservesSnapshot` 现在同时断言 `dataplane snapshot` 与 `public API table` 都会在 same-dispatch rebind 下复用同一已发布对象
- 本轮未处理的部分仍然明确保留：
  - façade fast-path 仍是 dataplane 的只读镜像，但还没进一步统一成“按 dataplane snapshot 判等”的更强 mirror 语义
  - `TryGetSimdBackendPodInfo` 这类 metadata query 仍主要走 control-plane registry/query 口径，后续如需更彻底对齐，再单开 batch

## 2026-05-11 X86 Incremental Redundancy Collapse

- 继续向 `SSE3 / SSSE3` 线做重复实现清理时，确认 `SSSE3MinI8x16 / SSSE3MaxI8x16` 和 `SSE2MinI8x16 / SSE2MaxI8x16` 语义完全同构，都是 `pcmpgtb + pand/pandn + por` 的 compare+blend 路径。
- 这意味着 `SSSE3` 的这两个 dispatch override 没有带来新的指令优势，只是在 `dispatch` 层重复维护了一套同义实现。
- 更合理的收口方式是让 `SSSE3` 直接继承 `SSE3/SSE2` core slots，保留 direct helper 兼容面，但不再让 dispatch table 绑定冗余 owned override。
- 这次收口的边界已经明确：`SSSE3` 仍保留 direct helper 名字，方便兼容和直调，但 dispatch ownership 不再落在 SSSE3 上。
- 这条收口已被 `DispatchAPI`、`check`、`impl-smoke-x86`、`gate` 四条 release 线验证为绿。

## 2026-05-11 Public ABI Metadata Query Cleanup

- `TryGetSimdBackendPodInfo` 的 active backend 与 registered backend 分支仍会分别从 published dataplane / registered dispatch table 取事实，但两条路径现在共享同一个局部 dispatch-to-POD 填充 helper。
- 这没有把 metadata query 伪装成 dataplane 的职责；它只是消掉同一组 `CapabilityBits / dispatchable / Priority` 赋值模板，避免后续维护时一个分支改了另一个分支漏掉。
- 回归已覆盖 public ABI suite、`check` 和 `gate`，其中 `gate` 同时经过 public ABI signature、public ABI smoke、并发回归链、`DispatchAPI`、`DataPlane` 与 `DirectDispatch`。

## 2026-05-12 Facade Hot-Path Dispatch Mirror

- `src/fafafa.core.simd.pas` 的普通 façade wrapper 已不再逐次调用 `GetCurrentSimdDataPlaneDispatch`，而是读取本地 `g_FastSimdDispatchPtr` mirror。
- 这份 mirror 只在 `RebindSimdFacadeFastPaths` 中从当前 `PSimdDataPlane.Dispatch` 发布，dispatch hook invalidate 时同步清空；因此它是 `dataplane` snapshot 的只读热路径镜像，不是新的 control-plane truth source。
- `VecF32x4Add` 等少量已绑定函数指针 fast-path 仍保持专用 bound pointer；普通 wrapper 则通过同一个 local dispatch mirror 减少每次调用穿过 `dataplane` getter 的层级。
- `check_dispatch_read_scope.py` 现在同时封住两类回退：消费者直读 `GetDispatchTable`，以及 `simd.pas` 回退到 per-call `GetCurrentSimdDataPlaneDispatch`。
- Release 验证结果：`git diff --check`、Release `check`、两组 focused seam suites、Release `gate` 全部通过，`DISPATCH_READ_SCOPE ... facade_issues=0`。

## 2026-05-12 NEON Comment Hygiene

- `src/fafafa.core.simd.neon.compare.inc`、`src/fafafa.core.simd.neon.scalar.utility.inc`、`src/fafafa.core.simd.neon.scalar.reduction.inc` 仍残留 `✅`、`Task 6.2`、`Iteration 2.4`、`P2/P3/P4` 这类过程标记。
- 这类注释不承载实现语义，只是历史批次痕迹，适合单独收一波卫生，不要和 NEON 功能改动混写。
- 这批的目标是把标题改回中性、可长期保留的实现描述，让 NEON include 更像稳定源码，不像项目日志。
- 清理后这些文件只保留语义化标题，`git diff --check` 和 Release `check` 都通过，说明卫生整理没有引入新问题。

## 2026-05-11 AVX2 Lane Helper Consolidation

- `AVX2SelectF32x4 / AVX2ExtractF32x4 / AVX2InsertF32x4 / AVX2SelectF64x2` 原来只是把和 scalar 完全相同的 lane 选择与边界截断逻辑在 AVX2 里又写了一遍。
- 现在这四个函数都改成 thin wrapper，直接委托 `ScalarSelectF32x4 / ScalarExtractF32x4 / ScalarInsertF32x4 / ScalarSelectF64x2`，把重复实现收回单一 reference truth。
- AVX2 的 dispatch-owned slot 仍然保留，`DispatchAPI` 里要求的 capability / non-scalar ownership 语义不受影响。
- 下一步要做的是 release 验证和继续扫其他 family 里是否还有同类“只改了名字、没改语义”的重复实现。
- `check`、`TTestCase_DispatchAPI`、`gate` 都已通过，说明这批 thin wrapper 收口没有破坏 AVX2 结构或 release 门禁。

## 2026-05-11 AVX2 CmpEq Redundancy Scan

- `CmpEq` 家族也呈现出和 bitwise 一样的同宽重复形状：`I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2` 只是 compare + mask extraction 重复了一遍。
- `F32x4` 与 `F64x2` 仍然各自保持独立语义，不能硬并到整数 helper。
- 这批更适合抽成 width-specific raw helper，再让 typed wrappers 保持签名和 dispatch 入口不变。
- `Lt/Gt/Le/Ge/Ne` 暂时不碰，因为它们含有 swap / not / unsigned-adjust 之类的语义差异，不是同一类重复实现。

## 2026-05-11 AVX2 256-bit CmpEq Redundancy Scan

- 继续扫 256-bit compare 面时，`I32x8/U32x8` 与 `I64x4/U64x4` 也只是同宽 compare + mask extraction 的重复实现。
- `F32x8/F64x4` 仍然保持独立的浮点 compare 语义，不适合硬并到整数 helper。
- 这一批更适合和 128-bit 同类一样抽成 256-bit width-specific raw helper，再让 typed wrappers 保持原签名。
- `I32x16/I64x8` 这类 wide-emulation wrapper 会顺着底层 256-bit helper 自然收获，不需要单独再写一层重复 compare 核心。
- 已完成 release 验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 AVX2 Integer CmpNe Scan

- 整数 `CmpNe` 和整数 `CmpEq` 的关系非常直接：在相同 mask 宽度里做反相即可，不需要再维护一套 compare + not + mask extraction。
- 这条收口只适用于整数 family；`F32/F64` 的 `CmpNe` 仍然要保留它们自己的浮点比较语义。
- 这一批最适合先收 `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2`、`I32x8/U32x8`、`I64x4/U64x4`，再让 `I32x16/I64x8` 跟着底层 wrapper 自然继承。
- release 验证已通过：`git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`。

## 2026-05-11 AVX2 Integer CmpLe/CmpGe Thin Wrapper Scan

- 整数 `CmpLe/CmpGe` 和 `CmpGt/CmpLt` 的关系同样直接：前者只是后者的反相薄封装，不应该继续维护两套 compare + NOT + mask extraction。
- 这条收口只适用于整数 family；`F32/F64` 的 `CmpLe/CmpGe` 仍然保留它们自己的浮点比较语义。
- 这一批最适合一起收 `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2`、`I32x8/U32x8`、`I64x4/U64x4` 的 `CmpLe/CmpGe`，把每个 family 里只剩一套真比较语义。
- 其中 `CmpGe` 现在也直接落到 `CmpGt(b, a)`，不再多绕一层 `CmpLt`，把薄壳收得更直。
- 为了不搬动大量函数体，只给这些后定义的 `CmpGt` 补了 forward declarations；`git diff --check` 和 Release `gate` 复验都已通过。
- release 验证已通过：`git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`。

## 2026-05-11 AVX2 I64x2 Min/Max Selection Scan

- `MinI64x2 / MaxI64x2 / MinU64x2 / MaxU64x2` 的 lane selection 其实是同一段 mask 驱动的 if/else 分支，只是 compare 语义不同。
- 这组不适合再各自维护四份 lane 赋值体；更合理的是把选择动作收成一个 raw helper，再让 typed wrapper 只保留各自的 `CmpLt/CmpGt` 语义。
- 这次没有碰 `I64x4/U64x4`，因为它们当前并没有同类 min/max duplicate body。
- `git diff --check` 和 Release `gate` 已通过，说明这个 raw helper 收口没有破坏 compare/min/max 的签名或结果。
- 继续在 AVX2 上往下扫后，没有再发现新的同构重复体，`Wave 3A` 已可以收口。

## 2026-05-11 SSE2 Lane Helper Consolidation

- `SSE2SelectF32x4 / SSE2ExtractF32x4 / SSE2InsertF32x4` 与 scalar helper 只是同一套 lane 选择/边界逻辑的重复实现，现在也收成了 thin wrapper。
- 这次没有动 `SSE2SelectF64x2`，也没有碰 wide-emulation 的 `F64x2` extract/insert，因为那些路径本来就不是和 scalar 完全同构的重复代码。
- SSE2 的 dispatch ownership 仍然保留，所以测试里对 slot 归属和结构检查的预期不需要改。
- 这批改动的风险点主要在编译和 dispatch 回归，不在算法语义本身。
- `check`、`TTestCase_DispatchAPI`、`gate` 已通过，说明 SSE2 thin wrapper 收口没有破坏结构检查、dispatch contract 或 release 门禁。

## 2026-05-11 SSE2 Narrow Compare Thin Wrapper Scan

- `SSE2CmpLe/CmpGe/CmpNe` 在 `I16x8/I8x16/U16x8/U8x16` 四组窄整型上不是独立比较语义，只是对 `CmpGt` 或 `CmpEq` 的同 mask 宽度反相。
- 这批适合收成 thin wrapper，而不是抽新 raw leaf：`sse2.pas` 仍是当前 backend adapter truth source，`Eq/Gt` ASM 仍负责真实比较和当前 mask extraction。
- 对 word-lane family 要保守：当前 `TMask8` contract 来自已有 `SSE2CmpEq/Gt...` 返回值，本批只翻转该返回值，不重解释 `pmovmskb` 的 lane layout。
- 收口后 release 证据已覆盖 `NarrowIntegerOps`、`DispatchAPI`、`check` 和 `gate`，说明 wrapper 化没有破坏窄整型测试、dispatch parity 或结构护栏。

## 2026-05-11 SSE2 Integer Compare Thin Wrapper Completion

- `I32x4/U32x4` 的 `Lt` 也只是 `Gt(b, a)` 的同合同重复体，不需要继续维护独立 ASM compare 核心。
- 这批进一步把 `I32x4/U32x4` 的 `Le/Ge/Ne` 收齐成和 `I16x8/I8x16/U16x8/U8x16` 同一套薄壳模式：`Lt` 走参数交换，`Le/Ge/Ne` 走 `MASK4_ALL_SET xor ...`。
- 这样 `SSE2` 的整数比较族就和 `AVX2` 的收口思路一致了：保留 `Eq/Gt` 的真实比较体，其余关系都当作语义薄壳，而不是分散维护多份 ASM。
- `NarrowIntegerOps` 和 `DispatchAPI` 已经足够覆盖这类 wrapper 重写的行为风险，`check` 与 `gate` 进一步证明结构、dispatch 和 release 门禁都没被破坏。

## 2026-05-11 SSE2 128-bit Bitwise Kernel Consolidation

- `SSE2` 的 128-bit integer bitwise 组本质上只有一份语义：`pand / por / pxor / pandn / all-ones-xor`，lane width 和 signedness 都不该再拥有独立 kernel。
- 这次把 `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2` 的 `And / Or / Xor / Not / AndNot` 全部收成共享 raw helper，再让 typed wrapper 只保留 dispatch 签名。
- `SSE2NotVecRaw` 直接用 `pcmpeqd xmm1, xmm1` 造全 1 掩码，避免继续维护多份 `AllOnes` 常量表。
- `src/fafafa.core.simd.sse2.i64x2_compare.inc` 没有任何 include 引用，属于不会进构建的孤立旧文件；删除后，active truth source 更集中地回到 `src/fafafa.core.simd.sse2.pas` 和 `sse2.register.inc`。
- 本批没有把 `U64x2` 拉进 active SSE2 backend；它仍在 base fallback 路径，等后续需要时再单独决定是否升级为 backend-owned slot，避免把“去重”混成新的架构扩散。

## 2026-05-11 SSE2 Wide Emulation Boundary Normalization

- `src/fafafa.core.simd.sse2.wide_emulation.inc` 的 wide extract/insert helper 原来统一用 `index and N`，这会形成 wrap-around 语义。
- scalar reference、non-x86 parity 测试和 direct-dispatch wide parity 都把 out-of-range lane 解释成 clamp，因此 `SSE2` wide-emulation 这组实现属于边界语义漂移，而不是一个值得保留的优化层。
- 本轮把 `F64x2 / I32x4 / I64x2 / F32x8 / F64x4 / I32x8 / I64x4 / F32x16 / I32x16` 的 extract/insert 全部改为委托 scalar reference helper。
- 这样保留了 `SSE2` dispatch-owned slot，同时消掉一整组重复索引逻辑和潜在 out-of-range 行为分叉。
- `TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent` 和 `gate` 都已通过，说明这批 wide-emulation clamp 收口同时满足 direct dispatch / facade / release 门禁。

## 2026-05-11 AVX512 Frontier Reconfirmation

- 重新核对 `AVX512` 的 wide_loadstore、math、facade 和 register 面后，没有发现可继续合并的 thin-wrapper 或重复实现。
- `SelectF32x16 / SelectF64x8 / ClampF32x16 / ClampF64x8` 现在保持 native AVX-512 最优实现，不应为了“统一风格”降成 scalar 或 AVX2 wrapper。
- `Utf8Validate / MemReverse / MemDiffRange / BytesIndexOf` 继续保持为故意继承的 AVX2 slots，不是 AVX512 的实现缺口。
- 因此 `AVX512` 当前应继续 hold green；下一轮重复实现清理不应优先从这条线开刀。

## 2026-05-11 SSE4.1 Blend Kernel Consolidation

- `SSE41SelectF32x4` 之前把 mask 展开和 `blendvps` 调用都自己写了一遍，和同单元里的 `SSE41BlendVF32x4` 形成了重复的选择逻辑。
- 现在 `SSE41SelectF32x4` 只负责把 `TMask4` 展开成 `TMaskF32x4`，真正的 native blend kernel 统一收在 `SSE41BlendVF32x4`。
- 这样保留了 `SelectF32x4` 这个 dispatch-owned slot 的语义，同时把 SSE4.1 的 bitmask selection 逻辑收成单一实现。
- release 验证已通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 SSE4.2 String Helper Consolidation

- `FindFirstOf_SSE42` 与 `FindFirstNotOf_SSE42` 原来维护了两份同构 `PCMPESTRI` chunk scanner；这属于真实重复实现，不只是风格相似。
- 共享 scanner 后，direct helper 的差异只剩入口语义：`FindFirstOf` 使用 positive polarity，`FindFirstNotOf` 使用 negative polarity，空字符集合仍按原契约返回 0。
- 回归测试暴露了一个原有边界 bug：negative polarity 会把 explicit-length chunk 后面的 synthetic tail index 当成 not-in-set 命中，导致全字符串都在集合里时返回 `len` 而不是 `-1`。
- 当前修复把 negative-polarity 命中限制在 `index < explicit_chunk_len`，保留 SSE4.2 direct helper 语义，同时消掉重复循环。
- release 验证已通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendSmoke`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 RISCVV Facade Scalar Reference Consolidation

- `riscvv.facade.inc` 里一批 exact-contract fallback 还在重复维护 select / extract / insert 的边界逻辑；这批实现和 `ScalarSelect* / ScalarExtract* / ScalarInsert*` 完全同合同，没必要继续保留第二份真源。
- 本轮把 `RISCVVSelectF32x4`、`RISCVVSelectF32x16`、`RISCVVSelectF64x8`、`RISCVVSelectF32x8(TVecU32x8)`、`RISCVVSelectF64x2`、`RISCVVSelectF64x4(TVecU64x4)`、`RISCVVSelectI32x4` 以及全部 exact extract / insert fallback 都收回 scalar reference helper。
- 这样 `RISCVV` facade fallback 不再自己维护一套重复的 clamp / lane 选择逻辑；只有不对应现成 scalar helper 的少数重载还保留本地循环。
- release 验证已通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- non-x86 implementation audit 也已通过：`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`

## 2026-05-11 NEON Scalar Fallback Consolidation

- `src/fafafa.core.simd.neon.scalar.utility.inc` 里仍有一组 non-ASM fallback 在手写与 `Scalar*` 完全同合同的 lane / U64x2 逻辑：`SelectF32x4`、`ExtractF32x4`、`InsertF32x4`、`SelectF64x2`，以及 `U64x2` 的 add/sub/bitwise/compare/min/max。
- `src/fafafa.core.simd.neon.scalar.autowrap.inc` 的 non-ASM `ExtractF64x2 / InsertF64x2` 也还手写了同一套 clamp 边界逻辑。
- 这些都属于 fallback exact-contract redundancy，不是 backend-owned NEON asm leaf；可以收回 `ScalarSelect* / ScalarExtract* / ScalarInsert* / Scalar*U64x2`。
- `src/fafafa.core.simd.neon.pas` 里的 asm-enabled `NEONSelectF32x4` 继续保持显式 per-lane body，因为现有 helper checker 用它表达 backend-owned slot 的源码归属，不纳入这批。
- 已完成收口：utility / autowrap fallback 已改成 thin wrapper，`check_nonx86_helper_semantics.py` 也补了对应 source-side 断言，防止同合同重复实现再回长回来。

## 2026-05-11 NEON Scalar Fallback Core Arithmetic Consolidation

- `src/fafafa.core.simd.neon.scalar_fallback.inc` 开头那组基础算术 wrapper 也都是和 `Scalar*` 完全同合同的逐 lane loop：`Add/Sub/Mul/DivF32x4`、`Add/Sub/Mul/DivF32x8`、`Add/Sub/Mul/DivF64x2`、`Add/Sub/MulI32x4`。
- 这批更适合直接委托 scalar truth，而不是在 NEON fallback 再维护一份相同 loop。
- 计划同步会把这批加入 helper checker，保持 exact-contract 收口可追踪。
- 当前这批已全部收口完成，`scalar_fallback.inc` 不再保留这组重复的逐 lane 基础算术体。
- 验证时曾因 `check` / `gate` 并发占用同一输出目录触发临时失败，串行重跑后确认门禁绿。

## 2026-05-11 SSE2 Shift Raw Helper Consolidation

- `SSE2` 的 shift 家族是真重复，但重复点不在 dispatch contract，而在每个宽度都各自维护一份 load-shift-store 体。
- `I16x8/I32x4/U16x8/U32x4` 可以收成同一组 `word / dword` raw helper；`I32x8/I32x16/U32x8/U64x4/I64x4/I64x8` 则可以顺着同一套 128-bit chunk helper 自然展开。
- 这批不需要改动 `dispatch` / `dataplane` / `public ABI` 的语义，只需要把宽度展开逻辑从“复制 ASM”收回到“共享 raw helper + 逐 chunk 调用”。
- 现有 dispatch / direct / wide parity 测试已经覆盖了这些 shift 入口，适合作为收口后验证基线。
- 收口后保留的重复边界是有意的：typed wrapper 继续承担 dispatch slot 与类型合同，raw helper 才承担同宽 load/shift/store 真实现；这符合当前 `sse2.pas` 作为 backend adapter truth source 的边界。

## 2026-05-11 RISCVV Integer MinMax Fallback Consolidation

- `RISCVV` 的 real asm 路径已经有 `vmin/vmax/vminu/vmaxu` native 实现；本轮发现的重复体只在 non-ASM fallback facade 里。
- `RISCVVMin/MaxU32x8`、`RISCVVMin/MaxI16x8`、`RISCVVMin/MaxI8x16`、`RISCVVMin/MaxU16x8`、`RISCVVMin/MaxU32x4`、`RISCVVMin/MaxU8x16` 的 fallback 逐 lane loop 与对应 `ScalarMin/Max*` 完全同合同，可以安全委托 scalar reference helper。
- `MinU32x8` 等 backend-owned slot 的 register contract 不应该因为 fallback 去重而改变；本轮只消掉重复代码，不把 backend-owned 槽位改成 base scalar pointer。
- 浮点 `Min/Max` 暂不收口到 `ScalarMin/MaxF*`，因为 NaN 和 signed-zero 语义需要单独证明，不能按循环相似度直接合并。
- `check_nonx86_helper_semantics.py` 已加 source-side 断言，锁住这批 RISCVV fallback 的 `ScalarMin/Max*` 委托路径，避免后续再长回逐 lane loop。
- release 复验证明这次只是 fallback 去重，不是 contract 漂移：`git diff --check`、`impl-smoke-nonx86`、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿。

## 2026-05-11 RISCVV Facade Arithmetic/Bitwise/Compare Consolidation

- `riscvv.facade.inc` 里 `I32x4 / I64x2 / I32x8 / U32x8` 仍有一批 exact-contract fallback 在手写 lane loop，和同名 `Scalar*` helper 完全同合同。
- 本轮收口只改 non-asm fallback body：`Add/Sub/Mul/And/Or/Xor/Not/AndNot/Cmp*` 以及 `I32x4/I32x8` 的 `Min/Max` 已改为直接委托 `Scalar*`；`Shift`、`float min/max`、`select/extract/insert`、`register.inc` ownership 都没动。
- checker 层面已经补了对应 source-side 断言，下一步重点是 release verification，不是继续扩语义范围。

## 2026-05-11 NEON Scalar Math/Utility Forwarder Consolidation

- `NEON` non-ASM fallback 里仍有一批基础 math / utility 函数在维护与 `Scalar*` 完全同合同的逐 lane 体，主要是 `Splat / Abs / Sqrt / Fma / Rcp / Rsqrt`。
- 本轮把这些 exact-contract wrapper 收回 scalar truth，同时保留 `NEON` asm-enabled 路径和 register ownership 不变。
- fallback-only wide `Abs/Fma` 原来只是递归拆到较窄 NEON fallback；现在直接委托 wide `ScalarAbs/Fma*`，避免再维护宽度拆分的第二份真源。
- 本批刻意不碰浮点 `Min/Max`、`Floor/Ceil/Round/Trunc`、`Clamp`，因为这些路径涉及 NaN、Inf、signed-zero 或 `Math.Min/Max` 差异，不能只凭循环形状合并。
- release 复验证明这次是 fallback 去重而非 contract 漂移：`git diff --check`、helper checker、`impl-smoke-nonx86`、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿。

## 2026-05-11 NEON Scalar Floor/Ceil Wide Forwarder Consolidation

- 宽向量 `NEONFloor/CeilF32x8/F32x16/F64x4/F64x8` 已有和 `ScalarFloor/Ceil*` 一致的 NaN / Inf guard，因此属于 exact-contract duplicate，可以安全委托 scalar truth。
- 窄 `F32x4 / F64x2` 的 `Floor/Ceil` fallback 仍和 scalar helper 不完全同构，本轮不合并，避免把语义修复伪装成去重。
- `Round/Trunc` 也继续保留，因为 scalar helper 额外做 signed-zero normalize；后续如要收口，应该先补明确语义测试。
- release 复验证明这次只收宽向量 exact fallback：helper checker、`impl-smoke-nonx86`、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿。

## 2026-05-11 SSSE3 Raw-Leaf Wording Harmonization

- 通过比对 `global architecture plan`、`execution index` 和 `family matrix`，发现 `SSSE3` 只有文档口径冲突，不是代码实现缺口。
- `family matrix` 已明确 `SSSE3` 是 adapter-only in practice，没有 dedicated raw leaf target；active 入口里那句“raw-leaf target 明确化”的表述已改成 hold adapter-only，避免未来会话误把它当成待办实现。
- `execution index` 顶部已经写明 `Wave 2 / seam hardening` 完成，但底部未完成项仍保留旧句“代码实施还没开始”；这是同一类 active-doc drift，已同步删除。

## 2026-05-11 SSE2 Retire Target Baseline

- `SSE2` 的 migration map 已经把 A/B/C 桶写死，但还缺一份专门的 retire baseline 来冻结 C 桶，避免后续把临时桥接或兼容壳和真正的生产导出混在一起。
- 当前这份新文档只负责定义 retire bucket 的准入条件和非目标，不会把任何稳定 adapter 责任误列进删表。
- `check_sse2_structure.py` 继续通过，说明格式化和新增 retire baseline 没有破坏 migration map 的 A/B/C section 与 token 护栏。
- `check_intrinsics_experimental_status.py` 继续通过，说明新增文档没有改变 experimental intrinsics 的默认入口隔离判断。

## 2026-05-11 Experimental Hold Future Trigger Baseline

- `AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX` 目前已经有 generic hold baseline，但还缺一份专门冻结 future-trigger 规则的 closeout 文档。
- 这份文档的作用是把“什么时候该重开 family 计划”与“什么不算触发条件”写成统一口径，避免后续再靠聊天上下文临场判断。
- `check_sse2_structure.py` 继续通过，说明新增文档和 active 入口没有破坏 SSE2 migration map 的 A/B/C 护栏。
- `check_intrinsics_experimental_status.py` 继续通过，说明新增文档没有把任何 experimental unit 拉进默认入口链。

## 2026-05-11 X86 Raw Parity Baseline

- `SSE3 / SSE4.1 / SSE4.2 / AVX-512` 的 shared raw parity baseline 现在已经单独落成，不再让 smoke 叙述继续充当 parity 结论。
- 这条 baseline 不是 promote 计划，而是把代表性 parity lane 冻结下来，交给 `x86 incremental qualification plan` 去消费。
- 之前 family matrix 里那句“还缺 family-specific raw parity 文档”已经过时，当前应改读为“baseline 已有，但 promote / split 决策还没细分完”。
- 轻量结构校验继续通过，说明这次只是在主链上补齐入口，没有引入新的 active-doc 冲突。

## 2026-05-11 AVX2 256-bit Dword Shared Kernel Consolidation

- `I32x8/U32x8` 的 `Add/Sub/Mul/And/Or/Xor/Not/AndNot/ShiftLeft/ShiftRight(logical)` 是 exact-contract 重复体，位模式完全一致，适合统一到共享 raw helper。
- 共享 helper 放在 `avx2.i32x8_family.inc` 后，typed wrapper 只剩签名和 dispatch 入口，`Cmp*`、`Min/Max`、`ShiftRightArithI32x8` 仍保持独立语义，不做误合并。
- 这次验证已经确认：`TTestCase_VecI32x8`、`TTestCase_VecU32x8`、`TTestCase_DispatchAPI`、`TTestCase_DirectDispatch`、`check`、`gate` 都是绿的。

## 2026-05-11 AVX2 256-bit Qword Shared Kernel Consolidation

- `I64x4/U64x4` 的 `Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight(logical)` 也是 exact-contract 重复体，和 dword 批次一样，真正可收口的是 raw kernel，不是 dispatch contract。
- 已新增 `AVX2AddQwordVecRaw256`、`AVX2SubQwordVecRaw256`、`AVX2AndQwordVecRaw256`、`AVX2OrQwordVecRaw256`、`AVX2XorQwordVecRaw256`、`AVX2NotQwordVecRaw256`、`AVX2AndNotQwordVecRaw256`、`AVX2ShiftLeftQwordVecRaw256`、`AVX2ShiftRightQwordVecRaw256`。
- `src/fafafa.core.simd.avx2.pas` 里的 `I64x4` / `U64x4` 入口已全部变成 thin wrapper，`Cmp*`、`Min/Max` 与别的语义边界没有被这批合并误伤。
- 第一次同时起跑 `check` 与 `gate` 时，`check` 因输出目录竞争出现 `rc=2`；串行重跑后通过，说明这只是门禁调度问题，不是实现回归。

## 2026-05-11 AVX2 128-bit Arithmetic/Shift Shared Kernel Consolidation

- `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16` 的 add/sub 与同宽 logical shift 是和前两批 256-bit 收口同类的 exact-contract 重复体：signedness 只改变解释，不改变硬件结果 bit pattern。
- 本批把 128-bit dword/word/byte add-sub 收进共享 raw helper，把 dword/word logical shift 收进共享 raw helper；typed wrapper 继续保留 dispatch slot 和类型签名。
- `ShiftRightArithI32x4`、`ShiftRightArithI16x8`、`Cmp*`、`Min/Max` 没有被合并；这些路径仍是当前 AVX2 adapter 内的独立语义边界。
- release 复验证明这次是重复实现收口而不是 contract 漂移：`NarrowIntegerOps`、`AVX2VectorAsm`、`DispatchAPI`、`DirectDispatch`、`DataPlane`、`check`、`gate` 全绿。

## 2026-05-11 SIMD Active Plan Status Sync

- 重新核对代码、commit history 和 scratch 以后，没有再找到一块“可安全合并、且不碰语义敏感路径”的新增重复体；继续硬扫只会增加误合并风险。
- 真正需要修的是 active plan 状态漂移：`execution-index` 仍把 `Wave 3C / Wave 4A / Wave 4B` 当默认起手，和当前已落地的 code batches 不一致。
- 已把 `execution-index` 与 `global architecture plan` 同步到当前事实：默认执行队列现在应切到 `Wave 5 / retire + redundancy cleanup`，Wave 4 的 non-x86 代码批次只保留为 hold / evidence / drift watch 参考。

## 2026-05-11 Current Validation Snapshot

- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test` 当前通过，说明当前树里的 SIMD 实现和并发回归面已经回到绿态。
- `TTestCase_SimdConcurrentPublicAbi`、`TTestCase_IEEE754EdgeCases` 和 full `gate` 也都通过，说明先前的 public ABI text publication 与 IEEE754 rounding 失败面在当前树里不再是活跃 blocker。
- `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight` 现在返回 `RECENT_BILLING_BLOCK`，所以 fresh Windows evidence refresh 目前被 GitHub billing 挡住，剩余 release gap 是外部证据链，而不是 SIMD 代码本身。

## 2026-05-11 Family Decision Baseline

- 这轮再扫 active docs 后，新的结论不是“还剩一批代码没收”，而是“还剩一批 family 决策没冻住”：`SSE3 / SSE4.1 / SSE4.2 / AVX-512`、`NEON / RISCVV`、`AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX`。
- 这些 family 的重复噪音主要来自 policy judgment 分散在 `family matrix`、`execution index` 和各自 family plan 里，而不是源码里还有新的同合同重复体。
- 新增的 `docs/plans/2026-05-11-simd-family-decision-baseline.md` 把这三类判断拆成 single-source baseline：
  - x86 资格化组继续 qualification，不在没有 fresh red 的情况下 reopen promote / split
  - non-x86 资格化组继续 opt-in / qualification，不因为 fallback wrapper 变薄就默认 promote
  - experimental hold 组继续 `experimental isolated` / hold，不因为 smoke 绿就默认 reopen
- `SSSE3` 也被再次明确成 adapter-only，不再作为待补 raw leaf 项；这点现在由 family matrix 和 decision baseline 一起维护，后续不应再回到“是不是还要补 raw leaf”的老争论。
- 当前的真实收益是让 active docs 只保留一层政策判断，不再让同一结论在多个入口重复一遍。

## 2026-05-11 AVX512 Placeholder Helper Consolidation

- `src/fafafa.core.simd.intrinsics.avx512.pas` 里的 `load / loadu / store / storeu / set1 / add / sub / mul / div / mask_add / maskz_add` 都是同一宽度的 exact-contract placeholder body，只有 load/store 命名和 op / mask fallback 分支不同。
- 这批适合收成文件内 helper：公开 API、experimental opt-in gate 语义都不变，只减少重复循环体与重复搬运体。
- `mask_add` 与 `maskz_add` 可以共用同一个 masked-add helper；zeroing 语义由 `aUseSourceForUnmasked = False` 保留，不需要第二份 loop。
- 本批必须停在 placeholder math layer，不能顺手扩展新的 intrinsic surface，也不能把 AVX-512 family 状态误判成 promote。
- `git diff --check`、experimental check、Release `check`、Release `gate` 已经全绿，所以这次收口可以按稳定 batch 处理。

## 2026-05-11 Generic Intrinsics Load/Set Candidate

- `src/fafafa.core.simd.intrinsics.pas` 里 `simd_load_si128 / simd_loadu_si128`、`simd_store_si128 / simd_storeu_si128` 是明显的 exact-contract duplicate，适合收成单一文件内 helper。
- `simd_set1_epi32 / simd_set1_epi16 / simd_set1_epi8` 也是同类 placeholder 填充逻辑，只是 lane 宽度不同，可以继续收成局部 helper，但本批先不碰 compare/min/max/shift 这些边界敏感路径。
- 这份文件当前还是混合换行，适合在同一批里顺手整理成 LF，避免继续把格式噪音留在源码里。

## 2026-05-11 Runtime Getter Snapshot Fallback Closure

- `GetCurrentBackendInfo` / `GetDispatchableBackendList` / `GetBestDispatchableBackend` / `GetRegisteredBackendList` 的旧 fallback 直接回到 active state 或 nil，会在并发 `RegisterBackend` 读写下吐出 mixed snapshot。
- 这次 gate 红点里，`TTestCase_SimdConcurrentFramework` 稳定抓到两类失败：`current backend info mixed snapshot` 和 `dispatchable helper mixed snapshot`，都指向同一条 fallback 路径。
- 修复后这些 getter 在 snapshot publish 失败时改为回到 `GetCurrentRuntimeSnapshot`，让 fallback 也维持同代视图，而不是把 transient control-plane 状态直接吐给读者。
- full Release `gate` 已通过，本轮没有再观察到 runtime getter/helper 的跨代拼接输出。

## 2026-05-11 AVX Placeholder Helper Consolidation

- `src/fafafa.core.simd.intrinsics.avx.pas` 里 `load/loadu`、`store/storeu`、`set1_ps/set1_pd` 以及一组纯占位 `cmp/blend/shuffle/permute/unpack/testz/testc/testnzc/extract/insert` 都是同合同重复体。
- 这份文件已经有独立 experimental smoke 入口，所以适合用文件内 helper 收口，而不是新开更大的架构层。
- 这批只改 placeholder 体，不碰真正的数值语义函数，目标是先把 AVX experimental 面的重复噪音压下去。
- `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`、Release `check`、Release `gate` 已通过，说明 helper 收口没有把 AVX experimental smoke 或默认门禁打坏。

## 2026-05-11 SSE3/SSE41 Experimental Intrinsics Cleanup

- `sse3_loaddup_pd` 之前的真实问题不是“语义不优雅”，而是 `value := PDouble(Ptr)^;` 被注释吞掉，导致函数直接读未初始化局部变量。
- `sse41_dp_pd`、`sse41_round_ps`、`sse41_insert_ps` 都属于 comment-swallow / 逻辑残缺的同类问题，适合这批一起收掉，不再让实验性 helper 继续悬空。
- 新增的 `TTestCase_SimdIntrinsicsExperimentalX86` 不是只为让 `check` 绿，它必须在 `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1` 下实际跑到，才能证明注册和条件编译都没断。
- 一个容易踩的点是 experimental 测试脚本默认还是 `experimental=0`，所以新 suite 只能靠显式 `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1` 跑；否则会出现“编过了但没测到”的假绿。
- 本批最终验证通过后，`check` / targeted experimental suite / Release `check` / Release `gate` 形成了完整收口链。

## 2026-05-11 SSE4.1 Rounding Helper Consolidation

- `sse41_round_ps / sse41_round_pd / sse41_round_ss / sse41_round_sd` 原来重复维护同一套 `round / Int` case 分支；这正是上一批 comment-swallow 曾经打中的高风险形态。
- 这批只把 rounding decision 收成 `SSE41RoundScalar`，不改变 placeholder rounding 语义，也不把 SSE4.1 family 状态提升成 stable default path。
- `round_ss` / `round_sd` 的关键合同不是只看 lane0 结果，还要保持其他 lane 来自第一个参数；新增回归专门覆盖这一点。
- `TTestCase_SimdIntrinsicsExperimentalX86` 当前在显式 experimental 模式下跑 6 个测试，说明这次新增的 rounding 回归和上一批 load/dp/insert 回归都被真实执行。

## 2026-05-11 SSE4.1 Conversion Helper Consolidation

- `sse41_cvtepi*` / `sse41_cvtepu*` 的重复体是纯 lane 扩展 loop，和 round 那批一样，属于 exact-contract 的结构性重复，而不是语义差异。
- 用少量私有 helper 收口后，公开 wrapper 仍然是 thin shell，`SSE4.1` 的外部 contract 没变，只是减少了 12 份几乎同形的 loop。
- 这里最需要盯的点是 unsigned 64-bit 扩展的高 32 位必须为 0，所以回归专门检查了 `cvtepu32_epi64` 的高低 32 位。
- 这批的实验性回归现在已经把 `SSE4.1` 的 `loaddup / dp / round / insert / convert` 五类 helper 覆盖起来了，后面再扫 `SSE4.1` 时就能更容易发现真正的新增重复体，而不是继续在旧模板里反复打转。

## 2026-05-11 SSE4.1 Min/Max Helper Consolidation

- `sse41_max/min` 的 `epi8 / epi32 / epu16 / epu32` 八个 wrapper 之前都在维护同一类逐 lane 选择 loop，属于 exact-contract structural redundancy。
- 这批没有把 signed 与 unsigned 比较强行塞进一个模糊 helper，而是按 lane type 保留 4 个私有 helper；公开 wrapper 只负责函数名、signedness 和 min/max 入口，重复选择逻辑不再散落 8 份。
- 新增回归使用负数和高位 unsigned 值一起覆盖，能防止后续把 `epu16/epu32` 误退化成 signed 比较，也能证明最后一个 lane 没有被漏掉。
- `TTestCase_SimdIntrinsicsExperimentalX86` 必须继续用显式 `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1` 运行；本批 targeted experimental suite、Release `check`、Release `gate` 已全部通过。

## 2026-05-11 SSE4.1 Blend Helper Consolidation

- `sse41_blend_ps / blend_pd / blendv_ps / blendv_pd / blendv_epi8` 都是 lane selection 的重复壳，最值得收的部分是前四个 float/double pair，它们能按 immediate-mask 和 sign-mask 分成两组私有 helper。
- 这批保持了原本的 imm8 / sign-bit contract，没有引入新的 mask 解释层，也没有把 blend 逻辑推广成更抽象的泛型接口。
- `blendv_epi8` 也一并退到单一 helper，避免 byte sign-mask 继续维护独立循环体。
- 新增的 `Test_SSE41_Blend_ImmediateAndVariableMasks` 让 immediate mask、float sign-mask 和 byte sign-mask 三种形态都在显式 experimental 模式下被证明过。

## 2026-05-11 SSE4.1 Insert/Extract Lane Clamp Consolidation

- `SSE41InsertF32x4` 和 `SSE41ExtractF32x4` 共享同一段 lane index clamp，原来在两个函数里各写了一遍。
- 把 clamp 收成 `SSE41ClampF32x4Index` 之后，公共 contract 仍然是 saturation，不是 wrap-around，也没有碰 asm 指令本身。
- 这批把 insert/extract 的 SSE4.1 代表性 parity 也补上了，低位 / 高位 clamp 都用 scalar truth 交叉确认过。

## 2026-05-11 SSE4.1 Normalize Helper Consolidation

- `SSE41NormalizeF32x4` 和 `SSE41NormalizeF32x3` 其实是同一条 length-divide 控制流，只是 `F32x3` 需要额外把 `w` lane 清零；最干净的收口是抽一个 shared `SSE41NormalizeByLength`，让两个 wrapper 只保留 length source 和 lane policy。
- 这次的真实风险点不是语义漂移，而是临时重构时漏写了两个 wrapper 的 `var` 声明，编译器立刻把它打回来了；补回后 `DispatchAPI / check / gate` 已经全绿。
- 这也说明 `SSE4.1` 这条线现在更适合继续做“exact-contract helper consolidation”，而不是再去碰语义边界更敏感的 float math policy。

## 2026-05-11 AVX2 Normalize Helper Consolidation

- `AVX2LengthF32x4 / AVX2LengthF32x3` 以及 `AVX2NormalizeF32x4 / AVX2NormalizeF32x3` 也是同一条 length-divide 控制流，只是 `F32x3` 额外需要把 `w` lane 清零；这次把它们收成 `AVX2LengthWithOptionalZeroW` 和 `AVX2NormalizeByLength` 两个私有 helper，四个 wrapper 只保留 contract 选择。
- 这批没有改变公开 dispatch 签名，也没有碰 AVX2 其它 arithmetic / compare / shuffle 路径；`TTestCase_AVX2VectorAsm` 和 release gate 已经把 normalize 随机一致性和门禁链路一起确认过。
- 这也给后面继续扫 `SSE2 / SSE3 / AVX2` 的 vector-math 文件提供了统一形状：先把 zero-w / divide / sqrt 的重复骨架抽出来，再看还有没有真正值得单独保留的变体。

## 2026-05-11 SSE3 Normalize Helper Consolidation

- `SSE3LengthF32x4 / SSE3LengthF32x3` 和 `SSE3NormalizeF32x4 / SSE3NormalizeF32x3` 也是同一条 zero-w + length + divide 控制流；这次把它们收成 `SSE3LengthWithOptionalZeroW` 和 `SSE3NormalizeByLength`，让四个 wrapper 都只保留自己的 lane policy。
- 这批保持了现有 `SSE3` 代表性 parity 和 direct dispatch 路径，`DispatchAPI / DirectDispatch / check / gate` 全都绿了，说明 helper consolidation 没把 `F32x3` 的 `w=0` contract 弄丢。
- 现在 `SSE3/AVX2/SSE4.1` 的 vector-math normalize 面都已经是同一套 helper 形状了，后面继续扫 `SSE2` 时可以直接复用这条整理思路，而不是再写第三套看起来像、其实重复的分支树。

## 2026-05-11 NEON Scalar Memory/Reduction Forwarder Finding

- `src/fafafa.core.simd.neon.scalar.memory.inc` 的 `Load/StoreF32x4` / `Load/StoreF32x4Aligned` 只是 `ScalarLoad/Store*` 的薄壳，适合直接转发，不必继续维护第二份逐 lane 搬运体。
- `src/fafafa.core.simd.neon.scalar.reduction.inc` 里 `ReduceAddF32x4 / ReduceMulF32x4` 也是同类 exact-contract duplicate；`ReduceMin/ReduceMax` 与整数 reduction 仍保留 local 实现，因为这次不碰 floating min/max 语义边界。
- 这两块之前没有进入 `check_nonx86_helper_semantics.py`，所以它们正好是当前 NEON fallback 面上比较新的、值得继续清理的重复体。
- release 复验证明这次只是 exact-contract forwarder 收口，不是 reduction / memory contract 漂移：`git diff --check`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿。

## 2026-05-12 Public ABI Dataplane Doc Guard

- `src/fafafa.core.simd.public_abi.impl.inc` 当前已经通过 `TSimdPublicApiBindingState.DataPlane`、`GetCurrentSimdDataPlane` 和 `GetSimdPublicApiFallbackDataPlane` 消费 published dataplane，public ABI 不再是第二条 dispatch publication path。
- `docs/fafafa.core.simd.publicabi.md` 仍保留“兜底路径回读当前 dispatch table”的旧句子，这会和 `dispatch = control truth / dataplane = publication seam` 的当前架构口径冲突。
- 最小修复不是重写 public ABI 文档，而是把这条 active 文档口径改回 dataplane fallback，并把 `dispatch-read-scope` 扩成 active-doc guard：源码禁止 consumer 直读 `GetDispatchTable`，文档也禁止把 public ABI fallback 描述成 dispatch table fallback。
- 当前 targeted guard 已通过：`DISPATCH_READ_SCOPE ... forbidden_hits=0 active_doc_issues=0`。
- Release `check` 和 `gate` 已通过，说明这次 guard 扩展没有破坏主 SIMD runner、public ABI smoke、adapter sync、wiring sync 或 filtered `run_all` 链路。

## 2026-05-12 RISCVV Helper Include Forwarder Hygiene

- `src/fafafa.core.simd.riscvv.helpers.inc` 仍有一小批 live helper 在 no-ASM 分支里手写第二份整数逻辑，而当前 `check_nonx86_helper_semantics.py` 主要锁的是 `riscvv.facade.inc` forwarder，并没有直接读取 helper include。
- 本批可安全收口的 exact-contract 重复体只有 8 个：`RISCVVAdd/Sub/And/Or/Xor/NotU64x2` 与 `RISCVVAndNotI64x2/U64x2`；它们都已有现成 `Scalar*` 真源，且不涉及 NaN、signed-zero、unsigned compare、shift count 或 reduction contract。
- `RISCVVMin/MaxI64x2`、`RISCVVMin/MaxU64x2`、`RISCVVCmpLt/GtU64x2`、`RISCVVShift*`、`RISCVVReduce*`、`RISCVVLoad/Store/Splat/Zero/Select*` 仍然保留当前实现：
  - 前两类仍属于用户已明确要求谨慎的 `Min/Max` / unsigned compare 面。
  - shift / reduction 虽然能看到潜在替代，但这轮不为了去重扩大合同面。
- `Load/Store/Splat/Zero/Select*` 当前也没有现成同名 scalar API 可直接回收，不值得为了“去重”新造抽象。
- 已新增 `RISCVV_HELPERS_FILE` checker 输入并把这 8 个 helper 直接纳入 source-side 断言，因此后续即便 `riscvv.pas` 继续通过 `{$I fafafa.core.simd.riscvv.helpers.inc}` 挂接，这些 wrapper 也不会轻易回长成第二份手写逻辑。
- 复验结果已确认：`git diff --check`、`py_compile`、helper checker、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全绿；helper summary 从 `checks=459` 扩到 `checks=467`。

## 2026-05-12 RISCVV Helper Compare/Shift Forwarder Hygiene

- `src/fafafa.core.simd.riscvv.helpers.inc` 里剩余的 `RISCVVCmpEq/Lt/GtU64x2`、`RISCVVMin/MaxU64x2`、`RISCVVShiftLeft/Right/RightArithI64x2` 都已经有现成 scalar 真源，而且 dispatch/parity 测试已覆盖它们的合同，所以这批现在也可以安全收掉。
- 这些 helper 原先只是用另一种写法重复表达同一合同：
  - `CmpEqU64x2` 是逐 lane 比较；
  - `CmpLt/GtU64x2` 用 sign-bit xor 转成 signed compare；
  - `Min/MaxU64x2` 再基于该 mask 做 lane 选择；
  - `I64x2` 三个 shift 则手写与 `ScalarShift*I64x2` 相同的负数/越界归零语义。
- 这 8 个 helper 改成 scalar forwarder 后，`riscvv.helpers.inc` 不再维护第二份 unsigned compare / minmax / signed shift 逻辑。
- `U64x2` shift 这轮仍然不动，因为当前没有现成 `ScalarShiftLeft/RightU64x2` 可直接回收；为了去重新造 scalar API 不属于这批“最小安全收口”。
- `AVX512ShiftRightArithI32x16` 的 invalid-count contract 复核结果也已经明确：
  - 当前 `dispatchapi` 测试已覆盖 `c=-1`、`c=32`、`c=64`，以及 `ShiftLeftI32x16` 的 `c=64`。
  - 因而它目前不是“缺测试/缺护栏”的最高优先级缺口，这一轮不需要改 AVX-512 源码或额外补重复断言。
- 复验结果已确认：`git diff --check`、`py_compile`、helper checker、Release `impl-audit-nonx86`、Release `check`、Release `gate` 全绿；helper summary 从 `checks=467` 扩到 `checks=475`。

## 2026-05-12 RISCVV Integer Fallback Forwarder Expansion

- `src/fafafa.core.simd.riscvv.facade.inc` 里一批 non-ASM integer fallback 仍在手写逐 lane arithmetic / bitwise 体，和 `Scalar*` 真源完全同合同，适合继续收口。
- 这次收掉的是 `I16x8/I64x4/I64x8/I8x16/U16x8/U32x4/U64x4/U8x16` 的 `Add/Sub/And/Or/Xor/Not`，以及 `I16x8/U16x8/U32x4` 的 `Mul` 和 `I16x8/I64x4/U32x4` 的 `AndNot`；没有碰 compare、shift、float、register ownership。
- `check_nonx86_helper_semantics.py` 已扩到 `checks=251`，说明这批 forwarder 已被 source-side 护栏接住，不会再轻易长回重复实现。
- 这轮已经完成“代码 + 护栏 + release 复验”三步，当前只剩提交收口。

## 2026-05-12 RISCVV Integer Compare Forwarder Expansion

- `src/fafafa.core.simd.riscvv.facade.inc` 里 `I16x8/I8x16/I32x16/I64x4/I64x8/U16x8/U32x4/U64x4/U8x16` 的 integer compare 仍在手写逐 lane 比较，属于与 `ScalarCmp*` 完全同合同的重复壳。
- 这次把这些 compare wrapper 全部收回 `ScalarCmp*`，但保留了 float compare 和 register ownership，不把语义敏感或 backend-owned 路径混进来。
- `check_nonx86_helper_semantics.py` 的 summary 从 `251` 扩到 `304`，说明新增 forwarder 已被护栏完整接住。
- `impl-audit-nonx86 / check / gate` 也都绿了，所以这批 compare 收口属于可提交的完成态。

## 2026-05-12 RISCVV I32x16 MinMax Tail Completion

- 重新扫 RISCVV integer min/max 后，发现历史 min/max 批次已基本收完，当前只剩 `RISCVVMinI32x16 / RISCVVMaxI32x16` 两个手写逐 lane 分支。
- 这两个函数与 `ScalarMinI32x16 / ScalarMaxI32x16` 完全同合同，适合直接收回 scalar truth；float min/max 仍然不碰。
- `check_nonx86_helper_semantics.py` 现在把这两个尾巴也纳入 source-side 断言，summary 变成 `checks=306`。
- `impl-audit-nonx86 / check / gate` 全部通过，说明这个尾巴收口没有改变 backend-owned slot 或公开 contract。

## 2026-05-12 RISCVV I32x16 Arithmetic/Bitwise Tail Completion

- `src/fafafa.core.simd.riscvv.facade.inc` 的 `I32x16` non-ASM arithmetic / bitwise fallback 仍有 8 个手写逐 lane loop：`Add/Sub/Mul/And/Or/Xor/Not/AndNot`。
- 这些 wrapper 与 `ScalarAdd/Sub/Mul/And/Or/Xor/Not/AndNotI32x16` 完全同合同，属于 Wave 5 可以继续收掉的 exact-contract redundancy。
- 本批只收 no-ASM facade fallback，不改变 `src/fafafa.core.simd.riscvv.pas` 的 RVV asm 实现，也不改 `riscvv.register.inc` 的 backend-owned slot。
- `check_nonx86_helper_semantics.py` 已新增这 8 个 source-side forwarder 断言，验证通过后 summary 应从 `checks=306` 增加到 `checks=314`。
- release 级验证已通过：`git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿；说明这批是纯 fallback 去重，没有把 register ownership 或语义边界拧歪。

## 2026-05-12 RISCVV Wide Float Arithmetic Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里的 `F32x16/F64x8` no-ASM `Add/Sub/Mul/Div` fallback 仍是逐 lane loop，和 `ScalarAdd/Sub/Mul/DivF32x16/F64x8` 完全同合同。
- 本批只收基础四则运算；浮点 `Min/Max`、rounding、clamp、FMA 仍然保留当前实现边界，因为这些路径涉及 NaN、signed-zero、rounding 或 fused / non-fused 语义，不能按循环相似度合并。
- `riscvv.pas` 的 RVV asm 实现与 `riscvv.register.inc` slot ownership 不变，这次只是 no-ASM fallback 的第二份真源回收。
- `check_nonx86_helper_semantics.py` 已新增 8 个 source-side forwarder 断言，验证通过后 summary 应从 `checks=314` 增加到 `checks=322`。
- release 复验证明这批只是 wide float arithmetic fallback 去重：`git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过。

## 2026-05-12 RISCVV Narrow Float Arithmetic/Compare Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里的 `F32x4/F64x2` no-ASM `Add/Sub/Mul/Div` 与 `CmpEq/Lt/Gt/Le/Ge/Ne` fallback 仍是逐 lane loop，和 `Scalar*F32x4/F64x2` 完全同合同。
- 本批只收基础 arithmetic / compare；浮点 `Min/Max`、rounding、clamp、FMA 仍然保留当前实现边界，因为这些路径不属于“只是四则运算或 compare 壳”的 exact-contract 去重面。
- `riscvv.pas` 的 RVV asm 实现与 `riscvv.register.inc` slot ownership 不变，这次只是 no-ASM fallback 的第二份真源回收。
- `check_nonx86_helper_semantics.py` 已新增 20 个 source-side forwarder 断言，验证通过后 summary 应从 `checks=322` 增加到 `checks=342`。
- 复验结果已确认：`git diff --check`、`py_compile`、`check_nonx86_helper_semantics.py --summary-line`、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿，helper summary 为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=342 status=ok`。

## 2026-05-12 RISCVV Mid Float Arithmetic/Compare Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里还剩 `F32x8/F64x4` 的基础 arithmetic loop，以及 `F32x8/F64x4/F64x8/F32x16` 的 compare loop，它们也都有现成 `Scalar*` helper，属于可以继续收的 exact-contract 重复体。
- 这批仍然只碰 no-ASM facade fallback，不碰 `Min/Max`、rounding、clamp、FMA、asm path 或 `riscvv.register.inc` 的 slot ownership。
- `check_nonx86_helper_semantics.py` 需要把这 32 个 forwarder 收进护栏，summary 预期会从 `checks=342` 扩到 `checks=374`。
- 复验结果已确认：`git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿，helper summary 为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=374 status=ok`。

## 2026-05-12 RISCVV Abs/Sqrt Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里还有一组 `Abs/Sqrt` unary loop，覆盖 `F32x4/F64x2/F32x8/F64x4/F32x16/F64x8`，它们也都有对应 `Scalar*` helper，可继续收成 thin forwarder。
- 这批仍然只碰 no-ASM facade fallback，不碰 `Min/Max`、rounding、clamp、FMA、`Rcp/Rsqrt`、asm path 或 `riscvv.register.inc` 的 slot ownership。
- `check_nonx86_helper_semantics.py` 需要把这 12 个 forwarder 收进护栏，summary 预期会从 `checks=374` 扩到 `checks=386`。
- 复验结果已确认：`git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿，helper summary 为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=386 status=ok`。

## 2026-05-12 RISCVV Fma/Rcp/Rsqrt Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里 `F32x4/F64x2/F32x8/F64x4/F32x16/F64x8` 的 `Fma` 仍是与 `ScalarFma*` 完全同合同的逐 lane loop；`F32x4` 的 `Rcp/Rsqrt` 也与 `ScalarRcp/ScalarRsqrt` 完全同合同。
- `RcpF64x4` 先保留本地实现，因为它对零有显式特判，不属于和 `ScalarRcpF64x4` 完全同合同的薄壳。
- 这批只改 no-ASM facade fallback，不碰 `riscvv.pas` 的 RVV asm path，也不动 `riscvv.register.inc` 的 backend-owned slot。
- `check_nonx86_helper_semantics.py` 已补这 8 个 source-side 断言，helper summary 扩到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=394 status=ok`。
- release 复验已完成：`git diff --check`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿。

## 2026-05-12 RISCVV Floor/Ceil Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里 `F32x4/F64x2/F32x8/F64x4/F32x16/F64x8` 的 `Floor/Ceil` no-ASM fallback 仍是逐 lane 调用 `Floor/Ceil` 的重复体，已经有对应 `ScalarFloor/Ceil*` 真源。
- 本批只收 `Floor/Ceil`，不把 `Round/Trunc/Clamp` 混进来；后者仍牵涉 signed-zero 与 NaN ordering，必须另开证据线。
- `riscvv.pas` 的 RVV asm path 与 `riscvv.register.inc` slot ownership 不变，这次只是 no-ASM facade 的第二份真源回收。
- `check_nonx86_helper_semantics.py` 已补这 12 个 source-side 断言，helper summary 扩到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=406 status=ok`。
- release 复验已完成：`git diff --check`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿。

## 2026-05-12 RISCVV Splat Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里 `F32x4/F32x8/F32x16/F64x2/F64x4/F64x8/I64x4` 的 `Splat` no-ASM fallback 仍是逐 lane 写入同一个 `value` 的重复体，已经有对应 `ScalarSplat*` 真源。
- 这批只收纯构造器，不把 `Zero/Select/Extract/Insert`、rounding、clamp 或 float min/max 混进来；`riscvv.pas` 的 RVV asm path 与 `riscvv.register.inc` slot ownership 不变。
- `check_nonx86_helper_semantics.py` 已补 7 个 RISCVV `Splat` source-side 断言，helper summary 扩到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=413 status=ok`。
- release 复验已完成：`git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿。

## 2026-05-12 RISCVV Zero Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里 `F32x4/F32x8/F32x16/F64x2/F64x4/F64x8/I64x4` 的 `Zero` no-ASM fallback 仍是 `Default(TVec*)` 纯构造器，已经有对应 `ScalarZero*` 真源。
- 这批只收纯构造器，不把 `Select/Extract/Insert`、asm path 或 register ownership 混进来；`riscvv.pas` 的 RVV asm path 与 `riscvv.register.inc` slot ownership 不变。
- `check_nonx86_helper_semantics.py` 已补 7 个 RISCVV `Zero` source-side 断言，helper summary 扩到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=420 status=ok`。
- 首轮把 `ScalarZero*` 写成无参标识符时被 helper checker 抓到，已改成显式 `ScalarZero*()` 调用后复验通过。
- release 复验已完成：`git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿。

## 2026-05-12 RISCVV Shift Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里 11 个 `ShiftLeft/ShiftRight/ShiftRightArith` no-ASM fallback 现在都直调 `ScalarShift*`，去掉了第二份逐 lane truth source。
- 这批 shift 的合同由 `ScalarShift*` 统一承接，包括负数和高位 count 的归零语义；这比继续保留手写 loop 更不容易漂移。
- 这次没有碰 `RcpF64x4`、rounding、clamp、Min/Max、asm path 或 `riscvv.register.inc` 的 slot ownership，边界仍然干净。
- `check_nonx86_helper_semantics.py` 的护栏已经更新到 `checks=431 status=ok`，release `check` 和 `gate` 也都通过了。

## 2026-05-12 RISCVV I32x4 Shift Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里 `I32x4` 的 `ShiftLeft/ShiftRight/ShiftRightArith` 现在都直调 `ScalarShift*`，把手写 count 边界和逐 lane loop 收回统一真源。
- 这 3 个 shift 的合同和 scalar 侧完全一致，包括负 count、高位 count 的归零语义，以及算术右移的符号扩展语义。
- 这次没有碰 `Cmp*`、`Min/Max`、`Select/Extract/Insert`、asm path 或 `riscvv.register.inc` 的 slot ownership，边界仍然干净。
- `check_nonx86_helper_semantics.py` 的护栏已经更新到 `checks=434 status=ok`，release `check` 和 `gate` 也都通过了。

## 2026-05-12 RISCVV Mask Helper Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里 `Mask2/Mask4/Mask8/Mask16` 的 `All/Any/None/PopCount/FirstSet` 现在都直调 `ScalarMask*`，把手写 bit-twiddling 收回统一真源。
- 这 20 个 mask helper 的合同和 scalar 侧完全一致，属于纯壳收口，不涉及 NaN、signed-zero、fused 运算或其它高风险语义。
- 这次没有碰 bitwise mask ops、select、extract/insert、asm path 或 `riscvv.register.inc` 的 slot ownership，边界仍然干净。
- `check_nonx86_helper_semantics.py` 的护栏已经更新到 `checks=454 status=ok`，release `check` 和 `gate` 也都通过了。

## 2026-05-12 RISCVV Vector Math Exact Forwarder Consolidation

- `src/fafafa.core.simd.riscvv.facade.inc` 里 `DotF32x4/F32x3`、`CrossF32x3`、`LengthF32x4/F32x3` 现在都直调 `Scalar*`，把手写公式收回统一真源。
- `NormalizeF32x4/F32x3` 明确不纳入本批，因为 RISCVV 当前使用 `1e-10` 阈值，而 scalar 使用 `0.0` 阈值，不能当成 exact-contract 重复体。
- `DotF64x2/F64x4` 后来被 release 测试证明不能直接 scalar forward，已回退到本地实现；最终只保留 F32 dot/cross/length 的 5 个 forwarder。
- 这次没有碰 reduction、float min/max、rounding/trunc、load/store、asm path 或 `riscvv.register.inc` 的 slot ownership，边界仍然干净。
- `check_nonx86_helper_semantics.py` 的护栏已经更新到 `checks=459 status=ok`，release `check` 和 `gate` 也都通过了。

## 2026-05-13 I64x8 Facade Direct Guard Findings

- `VecI64x8CmpEq/Lt/Gt/Le/Ge/Ne` 是当前 `src/fafafa.core.simd.pas` 的真实公开 façade compare surface，不是 family-local helper。
- 这组函数在本轮之前已经有两类旁证：
  - `tests/fafafa.core.simd/fafafa.core.simd.vec512types.testcase.pas` 的 compare mask 测试；
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 的 dispatch/facade parity。
- 但 `vec512types` 没有 `ForceBackend(sbScalar)`，也没有 `SetUp/TearDown` 生命周期控制，因此它并不等价于 `TTestCase_IntegerFacadeGuards` 这种 scalar-forced direct guard。
- 所以 `I64x8` 当前缺的仍然是证据层，而不是实现层；继续扩现有 `TTestCase_IntegerFacadeGuards` 比新增 `veci64x8` family-local suite 更低风险，也不会碰 runner manifest。
- 本轮还再次证明了一个操作纪律：`check` 和 `gate` 在这个仓库里必须串行跑；共享输出目录下并行执行会出现 build 阶段 `rc=2` 的假红，不能误判为代码回归。

## 2026-05-15 RISCVV I64x2 MinMax Helper Exact-Contract Consolidation

- 在前面的 `RISCVV helper` 收口批次之后，当前还能安全继续下刀的 helper 级 exact-contract redundancy 只剩很小一块：`src/fafafa.core.simd.riscvv.helpers.inc` 里的 `RISCVVMinI64x2 / RISCVVMaxI64x2`。
- 这两个 helper 原先仍保留逐 lane `if/else` 逻辑，但合同与 `ScalarMinI64x2 / ScalarMaxI64x2` 完全一致：
  - 没有 NaN / signed-zero / rounding mode 问题；
  - 也不属于 `dispatchapi` 明确要求 backend-owned 的 slot。
- 这批刻意没有继续扩大范围：
  - `Round/Trunc/Clamp` 仍牵涉 signed-zero 与 NaN ordering，不属于“看起来像 loop 就能合并”的面；
  - `NormalizeF32x4/F32x3` 仍与 scalar 存在零阈值差异；
  - `DotF64x2 / DotF64x4` 仍被 `dispatchapi` 守成 backend-owned / not-direct-scalar-forward 的路径。
- 因而本批的正确收口方式不是再造新 helper，而是直接把 `RISCVVMinI64x2 / RISCVVMaxI64x2` 收回 scalar 真源，并同步把 checker 的 source-side 护栏补上。
- `check_nonx86_helper_semantics.py` 现已新增这 2 个 helper 断言；复验后 summary 更新为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=477 status=ok`。
- 串行 release 证据已补齐：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果全部为绿，说明这批确实只是 helper 真源去重，没有碰坏 non-x86 wiring、RISCVV ABI shape、key-slot ownership 或 fast-gate 主链。

## 2026-05-15 RISCVV AndNot Helper Exact-Contract Consolidation

- `RISCVVMin/MaxI64x2` 收完后，再往 `src/fafafa.core.simd.riscvv.helpers.inc` 深看，剩余还能继续安全收口的 helper 级 exact-contract redundancy 只剩 3 个 `AndNot`：
  - `RISCVVAndNotI8x16`
  - `RISCVVAndNotU16x8`
  - `RISCVVAndNotU8x16`
- 这 3 个 helper 原先仍写成 `RISCVVNot(...)` 再 `RISCVVAnd(..., b)` 的组合式本地逻辑，但 scalar 侧已经有现成 `ScalarAndNot*` 真源，因此继续保留第二份逻辑只会增加漂移面。
- 这批之所以安全：
  - 它们是纯 bitwise exact-contract，不牵涉 NaN、signed-zero、rounding 或阈值语义；
  - `dispatchapi` 虽然要求 `AndNotU8x16` 这类 slot 继续保持 backend-owned pointer ownership，但并不要求 helper 体内部继续手写第二份逻辑；
  - `key-slot` 审计与 `RISCVV ABI shape` 都继续通过，说明“slot ownership 不变、helper 真源回收到 scalar”这一点是成立的。
- 这批仍然刻意没有扩大到其它剩余 helper：
  - `Neg/Load/Store/Splat/Zero` 多数没有现成同名 scalar helper 可直接回收；
  - `Select/Reduce` 会把这轮收口扩到更宽的合同面；
  - float unary / rounding / clamp / normalize 仍然属于已知语义敏感区。
- `check_nonx86_helper_semantics.py` 的 helper 护栏已补这 3 条断言；复验后 summary 更新为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=480 status=ok`。
- 串行 release 证据链继续为绿：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-15 RISCVV I64x4 Arithmetic-Shift Helper Exact-Contract Consolidation

- 继续往 `riscvv.helpers.inc` 收口后，第三刀里仍属同风险等级的 exact-contract helper 实际上只剩 1 个：
  - `RISCVVShiftRightArithI64x4`
- 这条 helper 之所以还能安全继续收：
  - scalar 侧已经有现成 `ScalarShiftRightArithI64x4`；
  - 它对 `shift < 0`、`shift >= 64` 的归零处理，以及有效范围内的 `SarInt64` 逻辑，与 helper 原先本地实现完全一致；
  - `dispatchapi` / `key-slot` 守的是 backend-owned slot ownership，而不是要求 helper 体内部继续手写那段循环。
- 与它相邻但这轮仍然不动的区域也更明确了：
  - `RISCVVShiftLeftU64x2 / ShiftRightU64x2` 当前没有同级别 scalar 真源可直接回收；
  - `Reduce*`、`Select*` 会把这轮 helper 收口扩大到更宽的合同面；
  - 因此 `ShiftRightArithI64x4` 收掉后，这一类“helpers.inc 中已有 scalar 真源的 exact-contract 尾巴”基本就见底了。
- `check_nonx86_helper_semantics.py` 已补上 `RISCVVShiftRightArithI64x4 -> ScalarShiftRightArithI64x4(a, shift)` 断言；复验后 summary 更新为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=481 status=ok`。
- 串行 release 证据链继续保持为绿：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-15 RISCVV CmpNeU32x4 Internal Contract Drift Fix

- 在把 `helpers.inc` 里现成 scalar 真源能回收的尾巴基本清完之后，继续深审发现一个更像真实 bug 的内部合同漂移：
  - `src/fafafa.core.simd.riscvv.pas` 中 `RISCVVCmpNeU32x4` asm 版本返回 `TMask4`
  - 但 `src/fafafa.core.simd.riscvv.helpers.inc` 中同名 no-ASM helper 却错误地返回 `TVecU32x4`
- 继续追消费面后，真实结论更明确：
  - `dispatch.pas` 没有 `CmpNeU32x4` 槽位；
  - `riscvv.register.inc` 也没有给它赋值；
  - `riscvv.facade.inc` 没有公开同名 façade；
  - `sse2.register.inc` 还明确写了 `CmpNeU32x4 not in dispatch table`。
- 这说明这里不该被误判成“缺一条公开 API”，而应该被视为：
  - dispatch 外的内部 helper 残留；
  - 但即便是内部 helper，也必须和同名 asm 路径保持自洽一致，不能一边返回 mask，一边返回 vector。
- 本批修法因此非常克制：
  - 不把 `CmpNeU32x4` 擅自补进 dispatch；
  - 只把 `riscvv.helpers.inc` 的 fallback 签名改回 `TMask4`；
  - 并把 loop 语义改成按 lane 置位 `Result := Result or (1 shl i)` 的 mask 生成方式，与 asm 路径对齐。
- 为了避免以后再次漂移，`check_nonx86_helper_semantics.py` 这次不只是看 helper 名字，还显式守住：
  - `function RISCVVCmpNeU32x4(const a, b: TVecU32x4): TMask4;`
  - `Result := 0;`
  - `if a.u[i] <> b.u[i] then`
  - `Result := Result or (1 shl i);`
- fresh 复验结果继续为绿：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=482 status=ok`
  - `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`
  - Release `check` 通过
  - Release `gate` 通过
- 这批收口后，`RISCVV` 剩余值得继续看的重点已不再是这类 helper-return-contract 漂移；后续更像是：
  - 是否还存在别的 helper/asm 同名签名不一致残留；
  - 以及 `U64x2 shift / reduce / select` 这类没有现成 scalar 真源的 helper 是否值得单独建立统一真源。

## 2026-05-13 512-bit Integer Compare Tail Findings

- `VecI16x32CmpEq/Lt/Gt`、`VecI8x64CmpEq/Lt/Gt`、`VecU8x64CmpEq/Lt/Gt` 都是当前 `src/fafafa.core.simd.pas` 的真实公开 façade compare surface，不是 backend-only 或 dispatch-only contract。
- 这 3 组在本轮之前的显性覆盖主要停留在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 的 façade-vs-scalar parity；没有像 `I64x8` 那样的 family-local direct mask 测试，也没有进入 `TTestCase_IntegerFacadeGuards`。
- `tests/fafafa.core.simd/fafafa.core.simd.narrowintegerops.testcase.pas` 虽然固定 `ForceBackend(sbScalar)`，但它的 contract 范围只到 `I16x8/I8x16/U16x8/U8x16/U32x4`，不能替代这 3 组 512-bit façade compare 的 direct evidence。
- 因此这批剩余问题仍然是证据层，而不是实现层；继续扩现有 `TTestCase_IntegerFacadeGuards` 仍是最低风险落点，不需要新建 `vec512` 平行 suite。
- 对于 32/64-lane compare，动态按 lane 累积期望 mask 比继续维护超长十六进制常量更稳，也更不容易把测试 bug 误判成实现 bug。

## 2026-05-13 I32x8 Facade Direct Guard Findings

- `VecI32x8AndNot/CmpEq/CmpLt/CmpGt/CmpLe/CmpGe/CmpNe` 是当前 `src/fafafa.core.simd.pas` 的真实公开 façade contract。
- `tests/fafafa.core.simd/fafafa.core.simd.veci32x8.testcase.pas` 虽然已经有一整套 family-local contract 测试，但它的 `SetUp/TearDown` 不固定 `sbScalar`；与之对应，`tests/fafafa.core.simd/fafafa.core.simd.vecu32x8.testcase.pas` 明确固定了 `ForceBackend(sbScalar)` / `ResetBackendSelection`。
- 这意味着 `I32x8` 当前已有的是“默认后端 family-local 行为回归”，不是“固定 scalar 真源的 façade direct guard”；它在证据层上更接近前面刚收掉的 `I64x8`，而不是已经收实的 `U32x8`。
- 因此这批也更适合继续补进 `TTestCase_IntegerFacadeGuards`，而不是直接改写现有 `veci32x8` suite 的生命周期语义。

## 2026-05-13 Wide Float Facade Guard Findings

- `src/fafafa.core.simd.pas` 当前真实公开的 512-bit 浮点 façade 包含两簇：
  - `VecF32x16Add/Sub/Mul/Div`、`VecF32x16CmpEq/Lt/Le/Gt/Ge/Ne_Mask`、`VecF32x16Fma/Floor/Ceil/Round/Trunc/Clamp/Reduce*/Load/Store/Splat/Zero/Select`
  - `VecF64x8Add/Sub/Mul/Div`、`VecF64x8CmpEq/Lt/Le/Gt/Ge/Ne`、`VecF64x8Fma/Floor/Ceil/Round/Trunc/Clamp/Reduce*/Load/Store/Splat/Zero/Select`
- `tests/fafafa.core.simd/fafafa.core.simd.vec512types.testcase.pas` 虽然已经覆盖了大量 512-bit float 行为，但它不等价于 public façade scalar direct guard：
  - 没有 `SetUp/TearDown`，不固定 `ForceBackend(sbScalar)`
  - `Add/Sub/Mul` 走的是 operator surface（`a + b` / `a - b` / `a * b`），不是直接命中 `VecF32x16Add` / `VecF64x8Add`
  - `F32x16` compare 用的是 `VecF32x16CmpEq/CmpLt` 返回 `TMaskF32x16` 的 vector-mask surface，不是公开 façade 的 `_Mask` contract
- `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas` 在这两族上已经有一批 scalar/direct parity，但它证明的是“façade 与 direct dispatch 一致”，不是“固定 scalar 真源、直接断言 public façade 输出”。
- 因而当前缺口仍然是证据层，而不是实现层；最低风险落点是继续留在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 这一条主 runner 里，新增并列的 `TTestCase_FloatFacadeGuards`，而不是改写 `vec512types` 生命周期或再开 family-local suite。
- 新 suite 首次 targeted run 抓到的两处红灯都来自测试预期计算错误：
  - `VecF32x16ReduceAdd` 真实期望应为 `13.5`，不是 `14.5`
  - `VecF64x8ReduceAdd` 真实期望应为 `5.5`，不是 `4.5`
- 修正预期后，`TTestCase_FloatFacadeGuards`、Release `check`、串行 Release `gate` 全绿，说明这批确实只是 public façade direct-evidence closeout，不是实现补丁。

## 2026-05-13 Wide Float Remaining API Guard Findings

- 在上一批 wide-float guard 落地后，`F32x16/F64x8` 公开 façade 里剩下最真实的 direct-evidence 空档是：
  - `VecF32x16Abs/Sqrt/Min/Max/Extract/Insert`
  - `VecF64x8Abs/Sqrt/Min/Max`
- 这批在本轮之前已经有 `dispatchapi` 的 façade-vs-scalar parity，但仍不等价于固定 `sbScalar` 的 direct guard：
  - `dispatchapi` 更像 wiring/parity proof
  - `vec512types` 也没有固定 `sbScalar`，而且没有覆盖 `F64x8` 这组剩余 math API
- 因而继续扩现有 `TTestCase_FloatFacadeGuards` 仍是最低风险路径，不需要再改 `vec512types` 生命周期，也不需要新建 family-local suite。
- 这次直接把 wide-float 剩余公开 API 收到同一条 scalar-forced suite 后，`F32x16/F64x8` 的 stable façade direct evidence 已经明显完整得多；当前若继续深扫，更值得转去看 wide-integer 的 `Add/Sub/bitwise/shift/minmax` 是否仍只剩 parity 旁证。

## 2026-05-13 Wide Integer Remaining Ops Guard Findings

- 继续从“公开 façade 只有 parity 旁证、还没有固定 `sbScalar` 的 direct evidence”往下扫后，当前最值钱的一批缺口落在：
  - `VecI32x16Add/Sub/Mul/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max/Extract/Insert`
  - `VecU32x16Add/Sub/Mul/And/Or/Xor/Not/ShiftLeft/ShiftRight/Min/Max`
  - `VecI64x8Add/Sub/And/Or/Xor/Not`
  - `VecU64x8Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight`
- 这批在本轮之前并不是“没有测试”，而是主要停留在两类旁证：
  - `dispatchapi.testcase` 的 façade-vs-scalar parity
  - `direct.testcase` 的 façade-vs-direct 多 backend parity
- 这两类旁证都不等价于 `TTestCase_IntegerFacadeGuards` 这种 `ForceBackend(sbScalar)` 的 public façade direct guard，因此继续把它们收进现有 suite 是更低风险的收口方式，不需要改 runner，也不需要碰实现文件。
- 这次首次 targeted run 抓到的唯一红灯也再次证明当前问题是证据层而不是实现层：
  - `VecU32x16Sub` 在 lane0 上真实 public contract 是 `UInt32` 回绕，`0 - High(UInt32)` 应该得到 `1`
  - 失败原因只是测试期望没有显式钉回 `UInt32`，被更宽的整数解释成了负值
  - 把期望显式收成 `UInt32(...)` 后，targeted suite、Release `check`、串行 Release `gate` 全绿
- 因而这批结论很干净：当前补的是 stable public façade 的 scalar direct evidence，不是 SIMD 实现修复。
- 本轮收完后，512-bit 宽整数里更像“仍只剩 parity 旁证”的残余已经进一步收窄；下一批如果继续深扫，更值得优先看 `I16x32/I8x64/U8x64` 的非 compare/AndNot 公开操作是否要补同类 direct guard。

## 2026-05-13 Wide Narrow-Lane Integer Remaining Ops Guard Findings

- 继续沿上一条线往下扫后，`I16x32/I8x64/U8x64` 的“非 compare/AndNot 公开 façade”就是当前最自然的下一批：
  - `VecI16x32Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max`
  - `VecI8x64Add/Sub/And/Or/Xor/Not/Min/Max`
  - `VecU8x64Add/Sub/And/Or/Xor/Not/Min/Max`
- 这批在本轮之前的证据主要还是 `dispatchapi.testcase` 的 façade-vs-scalar parity；本地搜索没有找到对应的 `direct.testcase` 多 backend façade parity，因此更说明它们尚未进入固定 `ForceBackend(sbScalar)` 的 direct guard。
- `TTestCase_IntegerFacadeGuards` 在这三簇上此前只覆盖：
  - `I16x32`：`AndNot + CmpEq/Lt/Gt`
  - `I8x64`：`AndNot + CmpEq/Lt/Gt`
  - `U8x64`：`CmpEq/Lt/Gt`
- 因而继续扩这一个 suite 仍然是最低风险路径：不改 runner，不改实现，只把已知公开 contract 从 parity 旁证补成 scalar direct evidence。
- 本轮首次 targeted run 暴露的唯一红灯再次是测试层期望，而不是实现问题：
  - `VecI16x32ShiftLeft lane 0` 的真实 lane 语义应回收到 16-bit
  - 失败原因只是测试期望直接拿了更宽整数的移位结果，没有显式钉回 `Word`
  - 把期望收成 `Word(...)` 后，targeted suite、Release `check`、串行 Release `gate` 全绿
- 这批结论也很干净：补的是 stable public façade 的 scalar direct evidence，不是实现修复。
- 当前如果继续深扫整数 façade，优先级已经开始从“明显的大缺口”转向“少量尾部剩余 API 的证据完整度”，收益会比前几批更偏收口和证据密实化。

## 2026-05-13 I64x4 U64x4 Remaining Ops Guard Findings

- `VecI64x4Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith` 与 `VecU64x4Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight` 都是当前 `src/fafafa.core.simd.pas` 的真实公开 façade surface，不是 backend-only helper。
- 这两簇在本轮之前已有的显性覆盖主要停留在两类旁证：
  - `dispatchapi.testcase` 的 façade-vs-scalar parity
  - `direct.testcase` 的 façade-vs-direct / backend parity
- 现有 `TTestCase_IntegerFacadeGuards` 只覆盖：
  - `I64x4`：`AndNot + CmpEq/Lt/Gt/Le/Ge/Ne`
  - `U64x4`：`CmpEq/Lt/Gt/Le/Ge/Ne`
- 因而这批缺口依旧是证据层，不是实现层；继续扩现有 `TTestCase_IntegerFacadeGuards` 仍是最低风险落点，不需要新建 256-bit family-local suite。
- 这次新增两条 remaining-ops guard 后，targeted suite 没有抓到测试期望 bug，也没有暴露实现回归；和前几批相比，这说明整数 façade 上“明显的大缺口”正在继续收窄，剩余问题更偏尾部证据密实化。

## 2026-05-13 I32x8 I64x2 U64x2 Remaining Ops Guard Findings

- `VecI32x8Add/Sub/Mul/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max/Extract/Insert`、`VecI64x2Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max/Extract/Insert`、`VecU64x2Add/Sub/And/Or/Xor/Not/Min/Max` 都是当前 `src/fafafa.core.simd.pas` 的真实公开 façade surface。
- `I32x8` 这簇当前最大的真假边界在于：
  - `tests/fafafa.core.simd/fafafa.core.simd.veci32x8.testcase.pas` 确实覆盖了大量行为
  - 但它的 `SetUp/TearDown` 不固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 因而它更像默认后端 family-local 回归，不等价于 scalar 真源的 public façade direct guard
- `I64x2/U64x2` 则和前面几批 wide-integer 的形状一致：
  - 已有 `dispatchapi.testcase` 的 façade-vs-scalar parity
  - 已有 `direct.testcase` 的 façade-vs-direct / backend parity
  - 但 `TTestCase_IntegerFacadeGuards` 之前只覆盖 `AndNot + compare`
- 因而这三簇的剩余缺口依旧是证据层，不是实现层；继续扩现有 `TTestCase_IntegerFacadeGuards` 仍然是最低风险的统一收口方式。
- 这次新增 3 条 remaining-ops guard 后，targeted suite、Release `check`、串行 Release `gate` 全绿，且没有暴露新的测试期望错误；这说明当前整数 façade 的主线问题正在从“大块缺口”进一步转向“少量尾部 contract 的证据密实化”。

## 2026-05-14 I32x4 Remaining Ops Guard Findings

- `VecI32x4Add/Sub/Mul/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max/Extract/Insert` 都是当前 `src/fafafa.core.simd.pas` 的真实公开 façade surface。
- 这簇在本轮之前已有的显性覆盖主要停留在：
  - `dispatchapi.testcase` 的 façade-vs-scalar parity
  - 若干普通行为测试 / AVX2 consistency 测试
- 但这些都不等价于固定 `ForceBackend(sbScalar)` 的 public façade direct guard；现有 `TTestCase_IntegerFacadeGuards` 在 `I32x4` 上此前只覆盖 `AndNot + compare`。
- 因而 `I32x4` 的 remaining ops 缺口仍然是证据层，而不是实现层；继续扩现有 `TTestCase_IntegerFacadeGuards` 仍然是最低风险落点，不需要再造 128-bit family-local guard suite。
- 这次新增 `Test_VecI32x4_RemainingOps_Basic` 后，targeted suite、Release `check`、串行 Release `gate` 全绿，且没有暴露新的测试期望错误；这说明整数 façade 的明显尾巴正在继续收窄，当前收益越来越偏向 contract 证据的最终密实化。

## 2026-05-14 F64x2 Direct Float Facade Guard Findings

- `VecF64x2Add/Sub/Mul/Div`、`VecF64x2CmpEq/Lt/Le/Gt/Ge/Ne`、`VecF64x2ReduceAdd/ReduceMin/ReduceMax/ReduceMul`、`VecF64x2Load/Store/Splat/Zero/Select`、`VecF64x2Abs/Sqrt/Min/Max/Extract/Insert` 都是当前 `src/fafafa.core.simd.pas` 的真实公开 façade surface。
- `F64x2` 的真假边界此前比整数面更容易被“看起来已经测过了”误导，因为它的证据被拆散在三处：
  - `TTestCase_VectorOps` 固定 `sbScalar`，但只覆盖 `Floor/Ceil/Round/Trunc/Fma`
  - `TTestCase_OperatorOverloads` 固定 `sbScalar`，但只覆盖 `+/-/*//`
  - `dispatchapi.testcase` 与 `direct.testcase` 的 `F64x2` 覆盖很密，但本质上仍是 façade-vs-scalar / façade-vs-direct parity
- 这些覆盖都不等价于 `TTestCase_FloatFacadeGuards` 这种固定 `ForceBackend(sbScalar)` 的 public façade direct contract guard，因此 `F64x2` 当前真实缺口仍然是证据层，而不是实现层。
- 继续扩现有 `TTestCase_FloatFacadeGuards` 是最低风险路径：
  - 不需要新建 128-bit family-local float suite
  - 不需要修改 `VectorOps` / `OperatorOverloads` 的生命周期和职责
  - 也不需要碰任何生产实现文件
- 这次新增 4 条 `F64x2` guard 后，Release targeted suite、`check`、串行 `gate` 全绿，说明这块问题确实是 public façade evidence gap，而不是实现缺陷。
- 这也意味着浮点 façade 上这一块“看似有很多测试、其实缺 direct guard”的尾巴已经开始被实证收口；后续再继续深扫时，收益会更偏向少量 residual API 的 contract 密实化，而不是发现大块新缺口。

## 2026-05-14 Float Utility Facade Tail Findings

- `F32x8/F64x4` 这两族之前最容易被误判成“已经够了”，因为它们确实已有 family-local scalar suite；但复核后发现 utility 面仍有真假边界：
  - 两边都还缺 `Dot/Select/ExtractInsert` 的 scalar-direct public façade 证据；`F64x4` 还额外缺 `Rcp`
- 回源码后又进一步确认了一条边界真相：
  - `src/fafafa.core.simd.pas` 对 `F32x8/F64x4` 并没有公开 `Load/Store/Splat/Zero` façade
  - 因而这几项不应再被误记成 public contract 缺口；它们属于 dispatch/scalar helper 面，而不是当前 façade 审查范围
- 这意味着 `SetUp/TearDown` 虽然已经固定 `sbScalar`，但还不能直接等价成“utility façade 也被 guard 住了”；对 public contract 来说，调用路径本身也要被钉住。
- `F64x2` 这边则是另一种尾巴：主 guard 已经覆盖了 arithmetic、compare、reduce、select、load-store、math、extract-insert，但还漏了 `Dot` 这一条公开 façade。
- 这批最合理的收口方式不是新开 suite，也不是改生产实现，而是：
  - 在已有 `F64x2` guard 上补 `Dot`
  - 在 `vecf32x8/vecf64x4` 已固定 `sbScalar` 的 family-local suite 里各补 1 条 public utility façade 测试
- 这批 targeted suite、Release `check`、串行 Release `gate` 最终都为绿，说明这次判断是准的：补的是 `F64x2/F32x8/F64x4` float utility public façade 的 direct-evidence 尾巴，不是实现层修复。
- 这也让 256-bit 浮点 façade 的剩余问题进一步从“真假混杂的证据层”收缩成少量 residual contract 密实化，而不是大块缺实现。

## 2026-05-14 F32x4 Utility Facade Tail Findings

- `F32x4` 这族之前也容易被误判成“已经够了”，因为 `TTestCase_VectorOps` 本身就固定 `ForceBackend(sbScalar)`，而且覆盖了不少直接调用；但复核后发现它的 utility 面仍有一块空档：
  - `Zero/LoadAligned/StoreAligned/Select` 主要还停留在 `dispatchapi.testcase` 的 façade-vs-scalar parity
  - `Extract/Insert` 则主要落在 `ShuffleSWizzle` 和 `EdgeCases`，不等价于同一条 scalar-direct public façade contract 证据
- 这和 `F32x8/F64x4` 的问题很像，但落点更轻：
  - 不需要新建 `family-local scalar suite`
  - 也不需要再开新的 `FloatFacadeGuards` 分支
  - 因为 `TTestCase_VectorOps` 自己已经具备 `SetUp/TearDown -> ForceBackend(sbScalar)/ResetBackendSelection` 的生命周期
- 因而这批最合理的收口方式就是继续扩 `TTestCase_VectorOps`：
  - 新增 `Test_VecF32x4_UtilityFacade_Basic`
  - 在一条测试里把 `VecF32x4Zero`、`VecF32x4LoadAligned/StoreAligned`、`VecF32x4Select`、`VecF32x4Extract/Insert` 一起钉住
- 这批 Release `TTestCase_VectorOps`、Release `check`、串行 Release `gate` 最终都为绿，说明判断同样是准的：补的是 `F32x4` utility public façade 的 scalar-direct evidence，不是实现层修复。
- 这也说明 128-bit 浮点 façade 的剩余问题继续朝“少量 utility/contract 尾巴密实化”收缩，而不是重新暴露出新的大块缺实现。

## 2026-05-14 Shuffle Swizzle Facade Scalarization Findings

- `shuffle/swizzle` 这簇之前同样容易被误判成“已经够了”，因为 `TTestCase_ShuffleSWizzle` 自身已经覆盖了很多公开 façade：
  - `F32x4`：`Shuffle/Shuffle2/Blend/Unpack/Broadcast/Reverse/Rotate/Insert/Extract`
  - `F64x2`：`Blend`
  - `I32x4`：`Shuffle/Blend/Unpack/Broadcast/Reverse/Rotate/Insert/Extract`
- 但复核后发现它和前几批 family-local suite 的问题本质一致：
  - 覆盖面存在
  - 公开 façade 也是真的 public surface
  - 可 suite 本身没有 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 因而它更像普通行为回归，不等价于 scalar 真源的 façade direct guard
- 这批最优雅的收口方式不是复制这些 testcase 到新 suite，而是直接 scalarize 现有 suite：
  - 给 `TTestCase_ShuffleSWizzle` 增加 `SetUp/TearDown`
  - 保留现有 testcase 不动
  - 让整个 suite 自动升级成 fixed-`sbScalar` 的 façade direct evidence
- 这批 Release `TTestCase_ShuffleSWizzle`、Release `check`、串行 Release `gate` 最终都为绿，说明这个做法风险很低，而且证据价值很高：我们没有新增实现，也没有新增重复测试，却把整簇 utility public surface 一次性收成了 direct contract guard。
- 这也意味着当前 `simd` 测试层的剩余问题越来越少是“缺测试本身”，而更多是“现有测试还没被正确放进 fixed-`sbScalar` contract 语义里”；后续继续深扫时，优先级应继续偏向这类 suite-level scalarization 或少量 residual API 的补钉。

## 2026-05-14 Gather Scatter Facade Scalarization Findings

- `VecF32x4Gather/VecI32x4Gather/VecF32x4Scatter/VecI32x4Scatter` 都是当前 `src/fafafa.core.simd.pas` 的真实公开 façade surface，不是 backend-only helper。
- `TTestCase_GatherScatter` 在本轮之前其实已经有不错的覆盖面：
  - `Gather`：顺序、跨步、随机、负值
  - `Scatter`：顺序、跨步
  - 边界：零索引、大跨步
- 但它和上一批 `ShuffleSWizzle` 的问题本质一致：
  - 覆盖面存在
  - 调用的确是公开 façade
  - 可 suite 本身没有 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 因而它更像普通行为回归，不等价于 scalar 真源的 façade direct guard
- 复核 `GatherScatter` 的 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”语义：
  - 它们全部只断言 gather/scatter 的公开 contract 结果
  - 没有断言当前 backend 文本、backend 能力、自动降级或跨 backend 行为差异
  - 因此 suite-level scalarization 的风险很低
- 这批最优雅的收口方式也不是复制 testcase 到新 suite，而是直接 scalarize 现有 suite：
  - 给 `TTestCase_GatherScatter` 增加 `SetUp/TearDown`
  - 保留现有 testcase 不动
  - 让整个 suite 自动升级成 fixed-`sbScalar` 的 façade direct evidence
- 这批 Release `TTestCase_GatherScatter`、Release `check`、串行 Release `gate` 最终都为绿，说明当前补的是 public façade evidence gap，而不是 gather/scatter 实现缺陷。
- 这也进一步说明：当前 `simd` 审查的高价值剩余问题，越来越集中在“现有 suite 还没进入 fixed-`sbScalar` contract 语义”这一类，而不是重新暴露出新的实现 bug；下一批若继续深扫，`TTestCase_MathFunctions` 会是更自然的候选。

## 2026-05-14 Math Functions Facade Scalarization Findings

- `VecF32x4Sin/Cos/SinCos/Tan/Exp/Exp2/Log/Log2/Log10/Pow/Asin/Acos/Atan/Atan2` 都是当前 `src/fafafa.core.simd.pas` 的真实公开 façade surface，不是 backend-only helper。
- `TTestCase_MathFunctions` 在本轮之前其实已经有很完整的覆盖面：
  - 三角：`Sin/Cos/SinCos/Tan`
  - 指数/对数：`Exp/Exp2/Log/Log2/Log10/Pow`
  - 反三角：`Asin/Acos/Atan/Atan2`
- 但它和前两批 `ShuffleSWizzle`、`GatherScatter` 的问题本质一致：
  - 覆盖面存在
  - 调用的确是公开 façade
  - 可 suite 本身没有 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 因而它更像普通行为回归，不等价于 scalar 真源的 façade direct guard
- 复核 `MathFunctions` 的 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”语义：
  - 它们全部只断言 math façade 的公开 contract 结果和误差容忍
  - 没有断言当前 backend 文本、自动降级、跨 backend 结果差异或向量汇编路径
  - 因此 suite-level scalarization 的风险很低
- 这批最优雅的收口方式同样不是复制 testcase 到新 suite，而是直接 scalarize 现有 suite：
  - 给 `TTestCase_MathFunctions` 增加 `SetUp/TearDown`
  - 保留现有 testcase 不动
  - 让整个 suite 自动升级成 fixed-`sbScalar` 的 façade direct evidence
- 这批 Release `TTestCase_MathFunctions`、Release `check`、串行 Release `gate` 最终都为绿，说明当前补的是 public math façade evidence gap，而不是 math 实现缺陷。
- 这也进一步说明：当前 `simd` 审查里最有价值的残余，仍然优先是“现有公开 façade suite 还没进入 fixed-`sbScalar` contract 语义”这一类；下一批若继续深扫，`TTestCase_AdvancedAlgorithms` 会是更自然的候选。

## 2026-05-14 Advanced Algorithms Facade Scalarization Findings

- `SortNet4I32/SortNet4F32/SortNet8I32`、`PrefixSumI32x4/F32x4`、`PrefixSumArrayI32/F32`、`StrFindChar` 都是当前 `src/fafafa.core.simd.pas` 的真实公开 façade surface，不是 backend-only helper。
- `TTestCase_AdvancedAlgorithms` 在本轮之前其实已经有很完整的覆盖面：
  - 排序网络：`SortNet4I32/SortNet4F32/SortNet8I32`
  - 前缀和：`PrefixSumI32x4/F32x4`、`PrefixSumArrayI32/F32`
  - 字符搜索：`StrFindChar`
- 但它和前三批 `ShuffleSWizzle`、`GatherScatter`、`MathFunctions` 的问题本质一致：
  - 覆盖面存在
  - 调用的确是公开 façade
  - 可 suite 本身没有 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 因而它更像普通行为回归，不等价于 scalar 真源的 façade direct guard
- 复核 `AdvancedAlgorithms` 的 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”语义：
  - 它们全部只断言算法 façade 的公开 contract 结果
  - 没有断言当前 backend 文本、自动降级、跨 backend 差异或向量汇编路径
  - 因此 suite-level scalarization 的风险很低
- 这批最优雅的收口方式同样不是复制 testcase 到新 suite，而是直接 scalarize 现有 suite：
  - 给 `TTestCase_AdvancedAlgorithms` 增加 `SetUp/TearDown`
  - 保留现有 testcase 不动
  - 让整个 suite 自动升级成 fixed-`sbScalar` 的 façade direct evidence
- 这批 Release `TTestCase_AdvancedAlgorithms`、Release `check`、串行 Release `gate` 最终都为绿，说明当前补的是 public algorithm façade evidence gap，而不是算法实现缺陷。
- 这也进一步说明：当前 `simd` 审查里高价值剩余问题仍主要是“现有公开 façade suite 还没进入 fixed-`sbScalar` contract 语义”。下一轮应优先重新扫一遍 remaining public suites，确认是否还存在同类未 scalarize 的尾巴，而不是急着回到实现层。

## 2026-05-14 Global Facade Scalarization Findings

- `MemEqual/MemFindByte/MemDiffRange/MemCopy/MemSet/MemReverse`、`SumBytes/MinMaxBytes/CountByte`、`Utf8Validate/AsciiIEqual/ToLowerAscii/ToUpperAscii`、`BytesIndexOf`、`BitsetPopCount` 都是当前 `src/fafafa.core.simd.pas` 的真实公开全局 façade surface，不是 backend-only helper。
- `TTestCase_Global` 在本轮之前其实已经有很完整的覆盖面：
  - 内存函数：`MemEqual/MemFindByte/MemDiffRange/MemCopy/MemSet/MemReverse`
  - 统计函数：`SumBytes/MinMaxBytes/CountByte`
  - 文本函数：`Utf8Validate/AsciiIEqual/ToLowerAscii/ToUpperAscii`
  - 搜索/位集：`BytesIndexOf/BitsetPopCount`
- 但它和前几批 suite-level scalarization 的问题本质一致：
  - 覆盖面存在
  - 调用的确是公开 façade
  - 可 suite 本身没有 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 因而它更像普通行为回归，不等价于 scalar 真源的 façade direct guard
- 这批比 `MathFunctions/AdvancedAlgorithms` 还多一层有利证据：
  - `TTestCase_BackendConsistency` 已经单独承担了这簇全局函数的跨 backend 旁证
  - 因而把 `TTestCase_Global` 自身 scalarize，不会削弱这簇函数的 backend parity 覆盖职责
- 复核 `Global` 的 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”语义：
  - 它们全部只断言全局 façade 的公开 contract 结果
  - 没有断言当前 backend 文本、自动降级、跨 backend 差异或向量汇编路径
  - 因此 suite-level scalarization 的风险很低
- 这批最优雅的收口方式同样不是复制 testcase 到新 suite，而是直接 scalarize 现有 suite：
  - 给 `TTestCase_Global` 增加 `SetUp/TearDown`
  - 保留现有 testcase 不动
  - 让整个 suite 自动升级成 fixed-`sbScalar` 的 façade direct evidence
- 这批 Release `TTestCase_Global`、Release `check`、串行 Release `gate` 最终都为绿，说明当前补的是 public global façade evidence gap，而不是全局 helper 实现缺陷。
- 继续深扫剩余 public suites 后，下一块更自然的候选已经收敛到 `TTestCase_TypeConversion`：它同样没有 `SetUp/TearDown`，而且覆盖的是公开转换 façade 本身；相比之下 `LargeData` 更像默认 backend 集成/边界面，优先级反而没它高。

## 2026-05-14 Type Conversion Facade Scalarization Findings

- `VecF32x4IntoBits/VecI32x4FromBitsF32`、`VecF64x2IntoBits/VecI64x2FromBitsF64`、`VecF32x4CastToI32x4/VecI32x4CastToF32x4`、`VecF64x2CastToI64x2/VecI64x2CastToF64x2`、`VecI16x8WidenLoI32x4/VecI16x8WidenHiI32x4/VecI32x4NarrowToI16x8`、`VecF32x4ToF64x2Lo/VecF64x2ToF32x4` 都是当前 `src/fafafa.core.simd.pas` 的真实公开类型转换 façade，不是 backend-only helper。
- `TTestCase_TypeConversion` 在本轮之前其实已经有很完整的覆盖面：
  - 位级重解释：`IntoBits/FromBits`
  - 元素级转换：`CastToI32x4/CastToF32x4/CastToI64x2/CastToF64x2`
  - 宽窄变换：`WidenLo/WidenHi/Narrow`
  - 精度转换：`F32x4ToF64x2Lo/F64x2ToF32x4`
- 但它和前几批 suite-level scalarization 的问题本质一致：
  - 覆盖面存在
  - 调用的确是公开 façade
  - 可 suite 本身没有 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 因而它更像普通行为回归，不等价于 scalar 真源的 façade direct guard
- 复核 `TypeConversion` 的 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”语义：
  - 它们全部只断言转换 façade 的公开 contract 结果
  - 没有断言当前 backend 文本、自动降级、跨 backend 差异或平台特化路径
  - 因此 suite-level scalarization 的风险很低
- 这批最优雅的收口方式同样不是复制 testcase 到新 suite，而是直接 scalarize 现有 suite：
  - 给 `TTestCase_TypeConversion` 增加 `SetUp/TearDown`
  - 保留现有 testcase 不动
  - 让整个 suite 自动升级成 fixed-`sbScalar` 的 façade direct evidence
- 这批 Release `TTestCase_TypeConversion`、Release `check`、串行 Release `gate` 最终都为绿，说明当前补的是 public type-conversion façade evidence gap，而不是转换实现缺陷。

## 2026-05-14 Vector Mask Facade Scalarization Findings

- `MaskF32x4AllTrue/AllFalse/Set/Test/ToBitmask/Any/All/None`、`MaskI32x4AllTrue/ToBitmask`、`MaskF64x2AllTrue/ToBitmask` 与 `MaskF32x4Select` 都是当前 `src/fafafa.core.simd.pas` 的真实公开 mask façade，不是 backend-only helper。
- `TTestCase_VectorMaskTypes` 在本轮之前其实已经有很完整的覆盖面：
  - `MaskF32x4`：构造、查询、bitmask、布尔归约、逻辑运算
  - `MaskI32x4`：`AllTrue/ToBitmask`
  - `MaskF64x2`：`AllTrue/ToBitmask`
  - 选择器：`MaskF32x4Select`
- 但它和前几批 suite-level scalarization 的问题本质一致：
  - 覆盖面存在
  - 调用的确是公开 façade
  - 可 suite 本身没有 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 因而它更像普通行为回归，不等价于 scalar 真源的 façade direct guard
- 复核 `VectorMaskTypes` 的 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”语义：
  - 掩码 layout/bitmask/逻辑运算断言的是稳定类型 contract
  - `MaskF32x4Select` 也只断言公开 façade 结果
  - 没有断言当前 backend 文本、自动降级或跨 backend 差异
  - 因此 suite-level scalarization 的风险很低
- 这批最优雅的收口方式同样不是复制 testcase 到新 suite，而是直接 scalarize 现有 suite：
  - 给 `TTestCase_VectorMaskTypes` 增加 `SetUp/TearDown`
  - 保留现有 testcase 不动
  - 让整个 suite 自动升级成 fixed-`sbScalar` 的 façade direct evidence
- 这批 Release `TTestCase_VectorMaskTypes`、Release `check`、串行 Release `gate` 最终都为绿，说明当前补的是 public mask façade evidence gap，而不是 mask helper/selector 实现缺陷。

## 2026-05-14 Large Data Global Facade Scalarization Findings

- `TTestCase_LargeData` 虽然名字偏“集成/边界”，但实际调用的是当前 `simd` 公共全局 façade：
  - `MemEqual`
  - `SumBytes`
  - `MemFindByte`
  - `CountByte`
- 它覆盖的不是性能或自动 backend 选择，而是公开 contract 的大尺寸/边界语义：
  - 1MB 相等/差异缓冲区
  - 1MB 累加求和
  - 大缓冲区尾部/中部查找
  - 非对齐指针访问
  - odd-size 与 15/16/17 等边界尺寸
- 因而在当前剩余候选里，它比 `TTestCase_UnsignedVectorTypes` 更值得优先收口：
  - `LargeData` 是真实 façade contract
  - `UnsignedVectorTypes` 主要是 typedef/layout/raw-access 断言，backend 语义价值明显更低
- 复核 `LargeData` 的 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”语义：
  - 没有断言当前 backend 文本
  - 没有断言自动降级或跨 backend parity
  - 只断言公开全局 façade 在大尺寸/边界条件下的结果 contract
  - 因此 suite-level scalarization 的风险仍然很低
- 这批最优雅的收口方式同样不是复制 testcase 到新 suite，而是直接 scalarize 现有 suite：
  - 给 `TTestCase_LargeData` 增加 `SetUp/TearDown`
  - 保留现有 testcase 不动
  - 让整个 suite 自动升级成 fixed-`sbScalar` 的 façade direct evidence
- 这批 Release `TTestCase_LargeData`、Release `check`、串行 Release `gate` 最终都为绿，说明当前补的是 public global façade 的大尺寸/边界 evidence gap，而不是大数据路径实现缺陷。

## 2026-05-14 Saturating Arithmetic Facade Scalarization Findings

- `VecI8x16SatAdd/SatSub`、`VecI16x8SatAdd/SatSub`、`VecU8x16SatAdd/SatSub`、`VecU16x8SatAdd/SatSub` 都是当前 `src/fafafa.core.simd.pas` 的真实公开饱和算术 façade，不是 backend-only helper。
- `TTestCase_SaturatingArithmetic` 在本轮之前已经有很完整的边界覆盖：
  - 正常加减
  - 上溢/下溢饱和
  - 有符号/无符号边界值
- 在当前剩余未 scalarize suite 里，它比以下候选更值得优先收口：
  - `dispatch/dataplane/publicabi/runtime/concurrent`：这些是控制面、并发面或发布面，不应强制套进 `sbScalar`
  - `memutils.aliases`：混合了 aligned 分配工具与别名/type-size 断言，backend 语义密度更低
  - `vec512types`：虽然夹有部分公开运算，但 suite 中也混有大量类型/布局断言，收口优先级次于纯 façade contract 的 `SaturatingArithmetic`
- 复核 `SaturatingArithmetic` 的 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”语义：
  - 它们全部只断言饱和算术 façade 的公开结果 contract
  - 没有断言当前 backend 文本、自动降级、跨 backend parity 或向量汇编路径
  - 因此 suite-level scalarization 的风险很低
- 这批最优雅的收口方式同样不是复制 testcase 到新 suite，而是直接 scalarize 现有 suite：
  - 给 `TTestCase_SaturatingArithmetic` 增加 `SetUp/TearDown`
  - 保留现有 testcase 不动
  - 让整个 suite 自动升级成 fixed-`sbScalar` 的 façade direct evidence
- 这批在首轮验证时还暴露出一个 testcase 依赖陷阱：
  - `TTestCase_SaturatingArithmetic` 之前只 `uses fafafa.core.simd`
  - 一旦补 `ForceBackend(sbScalar)`，编译期就会报 `Identifier not found "sbScalar"`
  - 最小修复是补齐与同类 scalarized 独立 testcase 一致的 `fafafa.core.simd.base` / `fafafa.core.simd.dispatch` 依赖，而不是改测试语义或退回不 scalarize
- 这批 Release `TTestCase_SaturatingArithmetic`、Release `check`、串行 Release `gate` 最终都为绿，说明当前补的是 public saturating façade evidence gap，而不是饱和算术实现缺陷。

## 2026-05-14 Vec512 Mixed-Suite Findings

- `TTestCase_Vec512Types` 不是一个适合“整包 scalarize”的纯 façade suite；它混合了三类不同价值的断言：
  - 类型/布局：`Create/LoHi/SizeOf/TMask64`
  - 已有 direct/parity 证据的 512-bit façade 算术与 plain-mask contract：`VecF32x16Add/Sub/Mul/Neg`、`VecF64x8Add`、`VecI32x16Add`、`VecI64x8Add`、`VecI64x8CompareMasks`、`VecF32x16/F64x8 ExtendedAPI`
  - 真正还缺 fixed-`sbScalar` direct evidence 的对象掩码 façade：`TMaskF32x16` 及 `VecF32x16CmpEq/CmpLt` 返回对象掩码这一层
- 交叉核对后确认，`FloatFacadeGuards` 与 `IntegerFacadeGuards` 已经收掉大量 512-bit façade，但它们覆盖的是另一层 contract：
  - `FloatFacadeGuards` 主要覆盖 `VecF32x16CmpEq_Mask` 这类返回 `TMask16` 的 plain-mask façade，以及 `VecF32x16Select(TMask16, ...)`
  - `IntegerFacadeGuards` 已覆盖 `VecI32x16` / `VecI64x8` 的比较与剩余算术 façade
  - 因而 `vec512types` 里“返回 `TMaskF32x16` 的对象掩码 façade”不应被误判为完全重复
- 对这类 mixed suite，当前最优雅的收口方式不是：
  - 给整个 `TTestCase_Vec512Types` 加 `SetUp/TearDown`
  - 或复制一份 testcase 到新 runner
- 当前更合理的方式是“拆职责”：
  - 保留 `TTestCase_Vec512Types` 的类型/布局和历史混合断言职责
  - 单独抽出 `TTestCase_Vec512MaskFacadeGuards`
  - 只把对象掩码 façade 的 8 个高价值测试迁进去，并固定 `sbScalar`
- 这也再次证明本轮剩余工作要避免机械化策略：
  - `dispatch/dataplane/publicabi/runtime/concurrent` 不能被当成普通 `sbScalar` façade suite
  - `vec512types` 也不能因为名字看起来“像 public family”就整包收编
- 这批还额外暴露出一个 runner 层事实：
  - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 不是纯靠 `RegisterTest(...)` 自动发现 suite
  - 它维护一份显式 `HandleSuite(...)` manifest
  - 因而 future batch 若新增独立 suite，必须同步这份 manifest，否则 `--suite=<name>` 会出现 “suite filter matched no tests”

## 2026-05-14 ImageProc Scalarization Findings

- `fafafa.core.simd.imageproc.pas` 暴露的是一整簇真实 public surface，而不是测试专用 helper：
  - `CreateImage/FreeImage`
  - `GetPixelRGB/SetPixelRGB`
  - `ImageAdd/ImageSubtract/ImageMultiply/ImageBlend`
  - `RGBToGrayscale/GrayscaleToRGB`
  - `ApplyBrightness/ApplyContrast/ApplyGamma`
  - `ApplyConvolution3x3/ApplyGaussianBlur/ApplySharpen/ApplyEdgeDetection`
- `TTestCase_ImageProc` 在本轮之前已经有很完整的 contract 覆盖：
  - 饱和/裁剪、alpha 模式、银行家舍入、small image/no-change、alpha preserve、异常与越界、卷积/模糊/锐化/边缘检测
  - 但 suite 的 `SetUp/TearDown` 只做 fixture 生命周期管理和 blend alpha mode 恢复，没有固定 backend 语义
- 复核 testcase 形状后，没有发现任何一条测试显式依赖默认 backend 自动选择：
  - 没有断言 backend 名称、dispatch 结果或 runtime snapshot
  - 没有断言跨 backend parity
  - 只断言公开图像 API 的结果 contract
  - 因而这批缺口仍然是证据层，而不是实现层
- 在当前剩余候选里，`ImageProc` 明显比以下几类更值得优先收口：
  - `UnsignedVectorTypes` / `RustStyleAliases`：主要是 typedef/layout/alias 断言
  - `Memutils`：更偏 aligned allocation 工具 contract，而不是 SIMD façade 计算 contract
  - `dispatch/dataplane/publicabi/runtime/concurrent`：控制面或并发面，不能机械套入 `sbScalar`
- 这批最优雅的修复方式依旧不是复制 testcase，而是直接 scalarize 现有 suite：
  - 保留原有 fixture 生命周期和 alpha-mode 恢复逻辑
  - 只补 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 补齐编译依赖 `fafafa.core.simd.base` / `fafafa.core.simd.dispatch`
- Release `TTestCase_ImageProc`、Release `check`、串行 Release `gate` 全绿，说明这批补的是 public image façade 的 scalar-direct evidence gap，而不是图像实现缺陷。

## 2026-05-14 Builder Scalarization Findings

- `src/fafafa.core.simd.builder.pas` 暴露的是一层真实 public builder façade，而不是测试内 helper：
  - `FromValues/Splat/Load/From/Zero`
  - `Add/Sub/Mul/Div_`
  - `AddScalar/SubScalar/MulScalar/DivScalar`
  - `Normalize/Clamp/Lerp`
  - `ReduceAdd/ReduceMin/ReduceMax/Length`
- `TTestCase_Builder` 在本轮之前已经有完整的结果 contract 覆盖：
  - `FromValues/Splat/Load/Build`
  - `Add/MulScalar/AddScalar`
  - `Normalize/Clamp`
  - `ReduceAdd/ReduceMin/ReduceMax`
  - `DotProduct/Lerp`
  - 但 suite 的 `SetUp/TearDown` 是空壳，没有固定 backend 语义
- 复核 testcase 形状后，没有发现任何一条测试显式依赖默认 backend 自动选择：
  - 没有断言 backend 名称、dispatch 结果或 runtime snapshot
  - 没有断言跨 backend parity
  - 只断言公开 builder façade 的结果 contract
  - 因而这批缺口仍然是证据层，而不是实现层
- 在当前剩余候选里，`Builder` 明显比以下几类更值得优先收口：
  - `UnsignedVectorTypes` / `RustStyleAliases`：主要是 typedef/layout/alias 断言
  - `Memutils`：更偏 aligned allocation 工具 contract，而不是 SIMD builder 计算 contract
  - `dispatch/dataplane/publicabi/runtime/concurrent`：控制面或并发面，不能机械套入 `sbScalar`
- 这批最优雅的修复方式依旧不是复制 testcase，而是直接 scalarize 现有 suite：
  - 保留现有 testcase 不动
  - 不新增 suite，也不修改 runner manifest
  - 只补 `ForceBackend(sbScalar)` / `ResetBackendSelection`
- Release `TTestCase_Builder`、Release `check`、串行 Release `gate` 全绿，说明这批补的是 public builder façade 的 scalar-direct evidence gap，而不是 builder 实现缺陷。

## 2026-05-14 EdgeCases Scalarization Findings

- `TTestCase_EdgeCases` 不是纯类型/别名测试，而是一组真实 contract 的边界语义集合：
  - `VecF32x4` 的 NaN / Infinity / divide-by-zero / invalid-domain
  - `SortNet4F32` 的 NaN 放尾约定
  - `VecI32x4` / `PrefixSumI32` 的 wraparound overflow 语义
  - `MemEqual/MemFindByte/SumBytes` 的极端非对齐、odd-size、跨页边界
  - `VecF32x4Extract/Insert` 与 `MaskF32x4Test` 的 index saturation
- 它虽然混有少量 `utils` helper 边界，但整体语义价值仍明显高于以下候选：
  - `UnsignedVectorTypes` / `RustStyleAliases`：主要是 typedef/layout/alias 断言
  - `Memutils`：更偏 aligned allocation 工具 contract
  - `dispatch/dataplane/publicabi/runtime/concurrent`：控制面或并发面，不能机械套入 `sbScalar`
- `TTestCase_EdgeCases` 在本轮之前已经有专门的 fixture 语义：
  - `SetUp` 保存并放宽 FPU exception mask
  - `TearDown` 恢复原 mask
  - 但没有固定 backend 语义
- 复核 testcase 形状后，没有发现任何一条测试显式依赖默认 backend 自动选择：
  - 没有断言 backend 名称、dispatch 结果或 runtime snapshot
  - 没有断言跨 backend parity
  - 只断言公开 façade / utility contract 的边界行为
  - 因而这批缺口仍然是证据层，而不是实现层
- 这批最优雅的修复方式仍然不是复制 testcase，而是在现有 fixture 上叠加 backend 固定：
  - 保留原有 FPU exception mask 生命周期不动
  - 不新增 suite，也不改 runner manifest
  - 只补 `ForceBackend(sbScalar)` / `ResetBackendSelection`
- Release `TTestCase_EdgeCases`、Release `check`、串行 Release `gate` 全绿，说明这批补的是边界 contract 的 scalar-direct evidence gap，而不是 edgecase 实现缺陷。

## 2026-05-14 VecI32x8 Family Scalarization Findings

- `TTestCase_VecI32x8` 是独立的 public 256-bit family suite，不是控制面或别名层测试：
  - `Add/Sub/Mul/Neg`
  - `And/Or/Xor/Not/AndNot`
  - `ShiftLeft/ShiftRight`
  - `CmpEq/Lt/Gt/Le/Ge/Ne`
  - `Min/Max`
  - `Splat/Zero/LoadStore/SizeOf`
  - overflow / max-min 边界
- 它和已经 fixed-`sbScalar` 的 `VecU32x8` / `VecF32x8` / `VecF64x4` 属于同一类“family-local public contract”：
  - 前三者已经固定 `sbScalar`
  - `VecI32x8` 却仍停在 “确保使用默认后端”
  - 因而当前缺口是证据层口径不一致，不是实现层空缺
- 在当前剩余候选里，它明显比以下几类更值得优先收口：
  - `UnsignedVectorTypes` / `RustStyleAliases`：主要是 typedef/layout/alias 断言
  - `Memutils`：更偏 aligned allocation 工具 contract
  - `PublicAbi`：published ABI / control-plane suite
  - `SSE2Contracts`：backend-owned / scalar-parity contract，不应机械改成 public scalar-direct suite
- 复核 testcase 形状后，没有发现任何一条测试显式依赖默认 backend 自动选择：
  - 没有断言 backend 名称、dispatch 结果或 runtime snapshot
  - 没有断言跨 backend parity
  - 只断言公开 `VecI32x8` façade 的结果 contract
- 这批最优雅的修复方式仍然不是复制 testcase，而是直接 scalarize 现有 suite：
  - 不新增 suite，也不改 runner manifest
  - 补齐 `fafafa.core.simd.base` 依赖
  - 只补 `ForceBackend(sbScalar)` / `ResetBackendSelection`
- Release `TTestCase_VecI32x8`、Release `check`、串行 Release `gate` 全绿，说明这批补的是 `VecI32x8` family contract 的 scalar-direct evidence gap，而不是 `VecI32x8` 实现缺陷。

## 2026-05-14 IEEE754 Fixture Mask Restore Findings

- `ieee754.testcase` 当前有一类真实 fixture 泄漏，不是“还没 scalarize”的证据层问题：
  - `TTestCase_IEEE754_F64.SetUp`
  - `TTestCase_IEEE754EdgeCases.SetUp`
  - `TTestCase_AVX2RoundTruncIEEE754.SetUp`
  - 这三处都会直接 `SetExceptionMask([...])`
  - 但本轮之前对应 `TearDown` 只做 `ResetToAutomaticBackend`
  - 原始 FPU exception mask 没有恢复
- 这和仓库中已有的安全模式明显不一致：
  - `TTestCase_EdgeCases` 已通过 `FSavedExceptionMask` 成对保存/恢复
  - `vecf32x8.testcase` 与 `testcase.pas` 多处局部 NaN/Inf 测试也都用 `oldMask/savedMask` 包住 `SetExceptionMask`
  - 因而这里不是“项目默认就不恢复 mask”，而是 `ieee754.testcase` 的 fixture 缺口
- `IEEE754EdgeCases` 与 `AVX2RoundTruncIEEE754` 都是 mixed suite：
  - 内部有 scalar / SSE2 / AVX2 对照
  - 还有 `TrySetActiveBackend` / `SetActiveBackend` 的显式切换
  - 所以它们本来就不适合像普通 public façade suite 那样整体 fixed-`sbScalar`
  - 这也说明本轮最值得修的不是 backend 选择，而是 test fixture 自身的状态恢复
- 最小正确修复方式是：
  - 每个相关 suite 各自持有 `FSavedExceptionMask`
  - `SetUp` 中先 `GetExceptionMask`
  - `TearDown` 中在 backend reset 后恢复原始 mask
  - 不改 test body 的 backend 切换语义，不改 mixed suite 设计
- Release `TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754`、Release `check`、串行 Release `gate` 全绿，说明这批修的是 IEEE754 fixture 生命周期泄漏，而不是 IEEE754 算法/舍入实现缺陷。

## 2026-05-14 Fixture Backend Restore Symmetry Findings

- 这轮继续审查 mixed/control-plane/high-value suite 后，抓到的真实问题不是“还缺更多 scalarization”，而是多个测试夹具都在静默污染全局 backend 选择：
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
  - `tests/fafafa.core.simd/fafafa.core.simd.sse2contracts.testcase.pas`
  - `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`
  - `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas`
- `publicabi.testcase` 的问题最直接：
  - `TTestCase_PublicAbi.SetUp/TearDown` 只调用 `ResetPublicAbiSyntheticHookState`
  - 而这个 helper 内部会 `SetVectorAsmEnabled(False)` + `ResetToAutomaticBackend`
  - 结果是 suite 每跑完一条测试，都会把进入测试前的真实 backend 选择强行丢成 automatic
- 其余高价值 suite 也有同类不对称：
  - `TTestCase_SSE2Contracts.TearDown`
  - `TTestCase_DataPlane` 内部若切 backend，最终常只回到 automatic
  - `TTestCase_SimdConcurrent*` 四类 suite 普遍只保存/恢复 `vector asm`，但没有恢复进入测试前的 `GetCurrentBackend`
- 这类问题和 `IEEE754` 的 FPU mask 泄漏是同一层级的 fixture 生命周期缺口：
  - 不一定立刻让当前 suite 自己失败
  - 但会污染后续 suite 的控制面起点
  - 尤其当上游测试刻意强制 `sbScalar/sbSSE2/sbAVX2` 时，后续 suite 会在不知情下从 automatic 开始
- 最小正确修复方式不是改生产实现，也不是给这些 suite 机械加 `sbScalar`：
  - 只在 fixture 层保存进入测试前的 `IsVectorAsmEnabled` 与 `GetCurrentBackend`
  - `TearDown` 时先恢复原始 `vector asm`
  - 再 `ResetToAutomaticBackend`
  - 如果当前 backend 仍不等于保存值，再 `TrySetActiveBackend(savedBackend)`
- 具体落地：
  - `TTestCase_PublicAbi` 增加 `FSavedVectorAsm/FSavedBackend`
  - `TTestCase_SSE2Contracts` 增加 `FOldBackend`
  - `TTestCase_DataPlane` 增加 fixture 级 `SetUp/TearDown`
  - `concurrent.testcase` 提取 `TSimdStatefulTestCase`，统一给 `TTestCase_SimdConcurrent`、`TTestCase_SimdConcurrentPublicAbi`、`TTestCase_SimdConcurrentFramework`、`TTestCase_SimdConcurrentRegistration` 使用
- Release `TTestCase_PublicAbi,TTestCase_DataPlane,TTestCase_SSE2Contracts,TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_SimdConcurrentRegistration`、Release `check`、Release `gate` 全绿，说明这批修的是测试夹具状态恢复不对称，而不是 SIMD 生产实现缺陷。

## 2026-05-14 IEEE754 Fixture State Restore Symmetry Findings

- `ieee754.testcase` 在上一批修完 FPU exception mask 后，仍然残留第二层真实 fixture 泄漏：backend/vector-asm 恢复不对称。
- 具体表现：
  - `TTestCase_IEEE754_F64.SetUp` 会直接 `SetActiveBackend(sbScalar)`，但 `TearDown` 之前只做 `ResetToAutomaticBackend`
  - `TTestCase_IEEE754EdgeCases`、`TTestCase_AVX2RoundTruncIEEE754` 里的多条 mixed test 会切 `SetVectorAsmEnabled(...)` 与 `SetActiveBackend(...)`
  - `TTestCase_NonX86IEEE754` 也会在多条测试中切非 x86 backend 和 `vector asm`
  - 文件级 fixture 结束时却没有恢复进入测试前的 `GetCurrentBackend/IsVectorAsmEnabled`
- 这说明上一批的 `FSavedExceptionMask` 修复虽然必要，但还不完整：
  - FPU mask 已经成对恢复
  - backend/vector-asm 状态却仍可能污染后续 suite
  - 本质上是和 `publicabi/sse2contracts/dataplane/concurrent` 同类的全局状态恢复缺口
- 最小正确修复方式仍然只动测试夹具，不碰 mixed suite 的测试目标：
  - 给 `TTestCase_IEEE754_F64`、`TTestCase_IEEE754EdgeCases`、`TTestCase_AVX2RoundTruncIEEE754` 增加 `FSavedVectorAsm/FSavedBackend`
  - `SetUp` 里先保存进入测试前状态，再保存 exception mask
  - `TearDown` 里先恢复 `vector asm`，再 `ResetToAutomaticBackend`，必要时 `TrySetActiveBackend(savedBackend)`，最后恢复 exception mask
  - `TTestCase_NonX86IEEE754` 补齐 fixture 级 `SetUp/TearDown`，做同样的 backend/vector-asm 恢复
- 这轮刻意没有改动：
  - scalar / SSE2 / AVX2 / non-x86 的比较语义
  - mixed suite 内部的 backend 切换路径
  - 任何生产实现
- Release `TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`、Release `check`、Release `gate` 全绿，说明这批修的是 IEEE754 测试夹具状态恢复不对称，而不是舍入算法或 backend 逻辑缺陷。

## 2026-05-14 Direct Fixture State Restore Symmetry Findings

- `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas` 也存在和前几批同类的真实 fixture 泄漏：
  - `TTestCase_DirectDispatch` 没有 fixture 级 `SetUp/TearDown`
  - 文件里大量 multi-backend parity 测试会 `TrySetActiveBackend(...)`、`SetActiveBackend(sbScalar)`、`SetVectorAsmEnabled(True/False)`
  - 但绝大多数方法 `finally` 只做 `ResetToAutomaticBackend`
  - `TTestCase_DirectDispatchConcurrent` 通过 `RunDirectDispatchConcurrentReRegisterSnapshotConsistency` 修改 backend/register 状态后，最后也只回到 automatic
- 这意味着 direct suite 自己虽然通常能通过，但会把进入测试前的强制 backend 选择静默丢掉：
  - 如果上游 suite 刻意把当前 backend 固定到 `sbScalar/sbSSE2/...`
  - direct suite 跑完后会把全局状态冲成 automatic
  - 本质上仍是测试夹具生命周期问题，不是 direct dispatch 生产实现问题
- 这批最小正确修复方式仍然是夹具层统一收口，而不是逐个改几十个 test body：
  - 新增 `TDirectDispatchStatefulTestCase`
  - 在 `SetUp` 保存进入测试前的 `IsVectorAsmEnabled/GetCurrentBackend`
  - 在 `TearDown` 里先恢复 `vector asm`，再 `ResetToAutomaticBackend`，必要时 `TrySetActiveBackend(savedBackend)`
  - 让 `TTestCase_DirectDispatch` 与 `TTestCase_DirectDispatchConcurrent` 都继承它
- 这轮刻意没有改动：
  - direct dispatch 的任何生产实现
  - multi-backend parity 的测试目标
  - synthetic re-register 并发测试的内部流程
- Release `TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿，说明这批修的是 direct suite 的测试夹具状态恢复不对称，而不是 direct dispatch 逻辑缺陷。

## 2026-05-14 Backend Consistency Helper State Restore Findings

- `tests/fafafa.core.simd/fafafa.core.simd.backend.consistency.testcase.pas` 是当前 SIMD 测试树里一个很隐蔽但真实的 helper-style 泄漏点：
  - 它不是普通 `TTestCase` fixture，而是 `RunAllConsistencyTests` + `TestF32x4Arithmetic/TestF32x4Math/...` 这类可单独调用的 helper 函数组合
  - 每个 helper 都会先 `TrySetActiveBackend(backend)`，随后在一次测试里多次 `SetActiveBackend(sbScalar)` / `SetActiveBackend(backend)`
  - 但退出时都只 `ResetToAutomaticBackend`
  - 这会把进入 helper 前的强制 backend 选择静默丢掉
- 外层 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 的 `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 也有同类问题：
  - 它最终只 `ResetToAutomaticBackend`
  - 即使 helper 层都单独修好，wrapper 末尾仍可能把上游强制 backend 冲回 automatic
- 这批最小正确修复分两层收口：
  - 在 `backend.consistency.testcase` 提取 `SaveBackendConsistencyState/RestoreBackendConsistencyState`
  - 让 7 个 helper-style consistency 测试都恢复进入前的 backend
  - 让 `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 也恢复进入前 backend
- 这批额外补了两个高价值回归点，而不是只做“静默修复”：
  - `Test_VectorOps_Helper_Preserves_PreviousForcedBackend`
  - `Test_VectorOps_Consistency_Preserves_PreviousForcedBackend`
  - 两者都先强制 `sbScalar`，再验证 standalone helper / 外层 wrapper 跑完后不会把先前强制 backend 冲掉
- 这轮刻意没有改动：
  - 任何 SIMD 生产实现
  - consistency 比对矩阵本身
  - dispatch/runtime 的生产控制面逻辑
- Release `TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 全绿，说明这批修的是 backend consistency 测试层的状态恢复不对称，并且新增回归测试已经能覆盖“前序强制 backend 被冲掉”的场景。

## 2026-05-14 DispatchAPI Fixture State Restore Findings

- `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 是当前 SIMD 测试树里另一处高密度的真实 fixture 泄漏面：
  - `TTestCase_DispatchAPI` 本身没有 fixture 级 `SetUp/TearDown`
  - 大量测试方法都会先记 `LOldVectorAsm := IsVectorAsmEnabled`，中间再跑 `TrySetActiveBackend(...)`、`ResetToAutomaticBackend`、`SetVectorAsmEnabled(True/False)`、hook 触发的 re-register/rollback 流程
  - 但绝大多数方法结尾只会恢复 `vector asm` 或回到 `automatic`
  - 这意味着一旦上游 suite 以强制 backend 进入，`dispatchapi` 整个类跑完后很容易把先前 backend 选择静默冲掉
- 这类文件不适合继续逐个 test body 打补丁：
  - 单文件测试数量极大
  - 绝大多数问题形态相同，都是“测试内局部 finally 只管把状态收回到一个默认值”
  - 更高价值的修法是给整个 `TTestCase_DispatchAPI` 加统一 fixture 恢复层
- 本轮最小正确修复：
  - 提取 `TDispatchAPIStatefulTestCase`
  - 在 `SetUp` 保存进入测试前的 `IsVectorAsmEnabled/GetCurrentBackend`
  - 在 `TearDown` 里先恢复 `vector asm`，再 `ResetToAutomaticBackend`，必要时 `TrySetActiveBackend(savedBackend)`
  - 让 `TTestCase_DispatchAPI` 继承它，而不是大面积改写现有 test body
- 这轮刻意没有改动：
  - dispatch 控制面生产实现
  - hook 行为语义
  - `TTestCase_X86MaskedFmaContract` / `TTestCase_RISCVVMaskedOpsContract` / `TTestCase_RISCVFallbackDispatchContract` / `TTestCase_NonX86BackendParity` 等其他类
- Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿，说明这批修的是 `dispatchapi` 测试夹具层的 backend/vector-asm 恢复对称性，而不是 dispatch/hook 生产逻辑缺陷。

## 2026-05-14 DispatchAPI Companion Classes Fixture State Restore Findings

- 在 `TTestCase_DispatchAPI` 收口后，`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 里还有 4 个 companion 类仍然裸继承 `TTestCase`：
  - `TTestCase_X86MaskedFmaContract`
  - `TTestCase_RISCVVMaskedOpsContract`
  - `TTestCase_RISCVFallbackDispatchContract`
  - `TTestCase_NonX86BackendParity`
- 这几类不是无状态 smoke：
  - `X86MaskedFmaContract` / `RISCVVMaskedOpsContract` 会切 `SetVectorAsmEnabled(True/False)`
  - `RISCVFallbackDispatchContract` 会直接 `ResetToAutomaticBackend`
  - `NonX86BackendParity` 大量测试会 `SetVectorAsmEnabled(True/False)`、`TrySetActiveBackend(LBackend)`，有些 finally 只 `ResetToAutomaticBackend`
- 因而即使主类 `TTestCase_DispatchAPI` 已经有 fixture 恢复层，这 4 支 companion 类仍会把进入测试前的 backend/vector-asm 状态静默冲掉。
- 这批最小正确修复不需要新发明第二套机制：
  - 直接让上述 4 个类复用已有的 `TDispatchAPIStatefulTestCase`
  - 统一在 fixture 层恢复进入测试前的 `vector asm + current backend`
  - 避免继续在大量 test body 里做重复且不完整的局部收尾
- 这轮刻意没有改动：
  - 任何 dispatch 控制面生产实现
  - 这些 companion 类各自的断言语义
  - `TTestCase_RISCVFallbackDispatchContract` 里 direct-call probe 的业务检查流程
- Release `TTestCase_X86MaskedFmaContract,TTestCase_RISCVVMaskedOpsContract,TTestCase_RISCVFallbackDispatchContract,TTestCase_NonX86BackendParity`、Release `check`、Release `gate` 全绿，说明这批修的是 `dispatchapi` companion 测试夹具状态恢复不对称，而不是 x86/RISCV/non-x86 语义回归。

## 2026-05-14 DispatchSlots Fixture Backend Restore Findings

- `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas` 是当前剩余较小但真实的 backend 状态泄漏点：
  - 文件只有一个 `TTestCase_DispatchAllSlots`
  - 其中 `Test_AllSelectableBackends_AllDispatchSlots_Assigned` / `Test_BackendAdapter_ActiveBackend_RoundTrip_NoNilAndCorePointersStable` 会遍历 `TrySetActiveBackend(LBackend)`
  - `Test_BackendAdapter_RegisteredBackendOps_PreserveCanonicalTextMetadata_After_ReRegister` 与其他测试也会直接 `ResetToAutomaticBackend`
  - 但类本身没有 fixture 级 `SetUp/TearDown`
  - 所以这些测试结束后只会回到 `automatic`，无法恢复进入测试前的强制 backend 选择
- 这批最小正确修复不需要再抽公共基类：
  - 直接在 `TTestCase_DispatchAllSlots` 上保存 `FSavedBackend`
  - `SetUp` 保存进入测试前的 `GetActiveBackend`
  - `TearDown` 统一 `ResetToAutomaticBackend`，必要时 `TrySetActiveBackend(savedBackend)`
- 这轮刻意没有改动：
  - dispatch slot contract 本身
  - backend adapter 生产实现
  - 任何 vector-asm 逻辑
- Release `TTestCase_DispatchAllSlots`、Release `check`、Release `gate` 全绿，说明这批修的是 `dispatchslots` 测试夹具 backend 恢复不对称，而不是 slot 绑定或 adapter 行为缺陷。

## 2026-05-14 Simd.TestCase Stateful Fixture Consolidation Findings

- `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 仍然是当前主 runner 里最大的一块真实 fixture 泄漏源：
  - `TTestCase_Global` 在 `SetUp` 里 `ForceBackend(sbScalar)`，退出时只 `ResetBackendSelection`
  - `TTestCase_BackendSmoke` 多个 test body 会 `ForceBackend(...)`，类级 `TearDown` 也只回 `automatic`
  - `TTestCase_AVX2VectorAsm` / `TTestCase_AVX512VectorAsm` 会切 `SetVectorAsmEnabled(True)`、重新注册 backend，再 `ForceBackend(sbAVX2/sbAVX512)`，但退出时只恢复 `vector asm` 并 `ResetBackendSelection`
  - `TTestCase_VectorOps`、`TTestCase_IntegerFacadeGuards`、`TTestCase_FloatFacadeGuards`、`TTestCase_LargeData`、`TTestCase_OperatorOverloads`、`TTestCase_VectorMaskTypes`、`TTestCase_TypeConversion`、`TTestCase_Builder`、`TTestCase_GatherScatter`、`TTestCase_ShuffleSWizzle`、`TTestCase_MathFunctions`、`TTestCase_AdvancedAlgorithms` 也都重复着“强制 `sbScalar` + 只回 `automatic`”的同构夹具
- 这类问题继续逐个类补 `SetUp/TearDown` 已经不划算：
  - 问题形态完全同构
  - 文件本身已经有大量历史样板
  - 继续逐个打补丁只会让重复夹具越来越多
- 本轮最小正确修复是把“恢复进入测试前状态”提升成共享 fixture contract：
  - 提取 `TSimdBackendStatefulTestCase`，统一保存进入测试前的 `GetCurrentBackend`
  - 提取 `TScalarBackendStatefulTestCase`，统一承接“先保存状态，再强制 `sbScalar`”
  - 提取 `TSimdVectorAsmBackendStatefulTestCase`，统一承接“先恢复 `vector asm`，再恢复 backend”，并把 backend re-register 留给具体子类覆盖
  - 让 `TTestCase_Global`、`TTestCase_BackendSmoke`、`TTestCase_AVX2VectorAsm`、`TTestCase_AVX512VectorAsm` 与整串 scalar façade suite 全部切到共享基类
- 这批修复同时解决了两类债务：
  - 真实 fixture/state leak
  - 重复 `SetUp/TearDown` 冗余
- `AVX2/AVX512VectorAsm` 这次没有去改任何向量实现或测试语义：
  - 只把“恢复 `vector asm` 后需要重新注册 backend”收进基类协议
  - `RefreshVectorAsmBackendRegistration` 仍由具体 suite 自己覆盖调用 `RegisterAVX2Backend/RegisterAVX512Backend`
- 这轮刻意没有改动：
  - 任何 SIMD 生产实现
  - suite manifest / runner 注册逻辑
  - `UnsignedVectorTypes` / `RustStyleAliases` 这类低价值 alias/layout 噪音
- 额外流程发现也需要保留：
  - 并行启动多个 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=...` 会共享同一个 Lazarus 输出树
  - 这会导致 `Text file busy` 或 `rc=2` 之类的假红，不应误判成代码回归
  - 这个 runner 在本仓库应继续保持串行验证
- Release `TTestCase_Global`、Release `TTestCase_BackendSmoke`、Release `TTestCase_AVX2VectorAsm`、Release `TTestCase_IntegerFacadeGuards`、Release `check`、Release `gate` 全绿，说明这批修的是主 testcase 文件里的夹具恢复不对称，并且共享基类没有引入 suite 回归。

## 2026-05-14 Scalarized Small Suites Backend Restore Findings

- 在主 testcase 文件收口后，`tests/fafafa.core.simd/` 里还残留一串分散的小 suite，问题模式完全一致：
  - `fafafa.core.simd.edgecases.testcase.pas`
  - `fafafa.core.simd.vecf32x8.testcase.pas`
  - `fafafa.core.simd.vecf64x4.testcase.pas`
  - `fafafa.core.simd.veci32x8.testcase.pas`
  - `fafafa.core.simd.vecu32x8.testcase.pas`
  - `fafafa.core.simd.narrowintegerops.testcase.pas`
  - `fafafa.core.simd.imageproc.testcase.pas`
  - `fafafa.core.simd.saturating.testcase.pas`
  - `fafafa.core.simd.vec512types.testcase.pas` 里的 `TTestCase_Vec512MaskFacadeGuards`
- 它们并不是“还没 scalarize”的问题，而是已经为了稳定 contract 测试把 `SetUp` 改成了 `ForceBackend(sbScalar)`，却仍保留旧式 `TearDown`：
  - 只 `ResetBackendSelection`
  - 不恢复进入测试前的真实 backend 选择
  - 一旦上游用强制 backend 进入，这些 suite 跑完后就会把先前选择静默冲掉
- 这批文件虽然分散，但修法不适合再发明新的共享单元：
  - 每个文件都已经有自己的轻量 fixture 语义
  - `EdgeCases` 还带 `FSavedExceptionMask`
  - `ImageProc` 还带 `FreeImage` 和 `SetImageBlendAlphaMode` 清理顺序
  - 最小正确修复就是在各自现有夹具上补 `FSavedBackend`
- 本轮统一落下的 contract 是：
  - `SetUp`：`GetDispatchTable` -> 保存 `FSavedBackend` -> 再 `ForceBackend(sbScalar)`
  - `TearDown`：保留原有资源/异常状态清理顺序，同时 `ResetBackendSelection`，必要时 `TrySetActiveBackend(FSavedBackend)`，最后断言恢复成功
- 其中两处需要保留额外注意事项：
  - `TTestCase_EdgeCases` 不能丢掉原有 `FPU exception mask` 生命周期
  - `TTestCase_ImageProc` 不能打乱 `blend alpha mode` 与 `FreeImage` 的清理顺序
- 这轮刻意没有改动：
  - 任何公开 façade 语义
  - `ImageProc` 算法实现
  - `Vec512Types` 本体的纯类型/布局测试
  - runner manifest / suite 注册
- 定向 Release 验证覆盖了全部 9 个受影响 suite，再加 Release `check`、Release `gate` 全绿，说明这批修的是分散小 suite 的 backend 恢复不对称，而不是 vector family/ImageProc/edge-case 生产逻辑缺陷。

## 2026-05-14 Direct Local Restore Consolidation Findings

- `direct.testcase` 的大头类级 fixture 已在前几批存在，但 method-level 仍残留大量“局部 `finally` 只 `ResetToAutomaticBackend`”的收尾；这会把进入该 test 前的 forced backend 语义抹掉。
- 当前最小且最高价值的残余切口就是：
  - `Test_DirectDispatchTable_Rebind_AfterForceBackend`
  - `Test_DirectDispatchTable_AutoRebind_AfterDispatchSetActiveBackend`
  - 一串 multi-backend parity test 的统一 `finally`
- 这批不值得继续逐个 test body 手写 `savedBackend` 样板；更干净的修法是在 `TDirectDispatchStatefulTestCase` 提取 `RestoreFixtureDirectDispatchState`，统一做：
  - 恢复 `FSavedVectorAsm`
  - `ResetToAutomaticBackend`
  - 必要时 `TrySetActiveBackend(FSavedBackend)`
  - `RebindDirectDispatch`
- `direct` 面和其它 stateful fixture 的关键差异就在最后这步 `RebindDirectDispatch`：
  - `GetDirectDispatchTable` 读取的是 dataplane 已发布的 dispatch 指针
  - 只恢复 backend 还不够，必须把 direct dataplane snapshot 重新绑定到当前 dispatch
- `Rebind_AfterForceBackend` 与 `AutoRebind_AfterDispatchSetActiveBackend` 现在都会在 test path 结束后显式断言：
  - `GetDispatchTable/GetDirectDispatchTable` 仍已赋值
  - backend 恢复到进入测试前选择
  - direct dispatch backend 与 dispatch backend 重新同步
- `WideIntegerHelperMatrix_Parity` 里原来的 `LOldVectorAsm` 已经变成冗余样板，因为共享 helper 已统一恢复 `vector asm + backend + direct rebind`。
- 这批刻意没有改动：
  - `src/fafafa.core.simd.direct.pas`
  - dispatch/runtime/control-plane 生产逻辑
  - 并发重注册 helper 的业务断言
- Release `TTestCase_DirectDispatch`、Release `TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿，说明修复点仍然是 direct 测试层的局部状态恢复不对称，而不是 direct dataplane 生产实现缺陷。

## 2026-05-14 PublicAbi Local Restore Consolidation Findings

- `publicabi.testcase` 和 `direct` 很像：类级 fixture 已经保存了 `FSavedVectorAsm/FSavedBackend`，但大量 test body 的外层 `finally` 仍重复写：
  - `SetVectorAsmEnabled(LOldVectorAsm);`
  - `ResetToAutomaticBackend;`
- 这种写法至少有两个问题：
  - 它重复表达了一套已经存在于 fixture 的恢复语义，形成测试层冗余样板
  - 它只回到 automatic，不会显式复用进入测试前保存下来的 backend 选择
- 这批最小高价值修法不是继续逐个 test body 发明新样板，而是把“本地恢复到进入测试前状态”提升成类内 helper：
  - 在 `TTestCase_PublicAbi` 提取 `RestorePublicAbiLocalState(aOriginalVectorAsm, aOriginalBackend)`
  - `TearDown` 也改为复用这个 helper
  - 第一批先替换完全同构、没有额外清理副作用的外层 `finally`
- 本轮已收掉的热点集中在：
  - `VectorAsmRoundTrip`
  - `ActiveBackendId/StableState`
  - `FailedHookMutation*`
  - `RollbackRestore*`
  - 一批 `HookLateForce/AutomaticReset` 路径
- 继续第二次同文件收口后，`publicabi.testcase` 里剩余的 simple exact-pattern 外层 finally 也已清掉，补到了：
  - `DataPlane_Parity`
  - 后段 `SetVectorAsmEnabled_*`
  - `RegisterBackend_*`
  - 几个带 `LRequestedTableCaptured/LPreviousTableCaptured` 的 restore-path 测试
- 这批刻意没有一次性全扫完 `publicabi.testcase`：
  - 文件后段仍有几处更复杂的 finally，不只是两行 exact pattern
  - 这些块常常还夹着额外 hook/table/vector-asm 语义，下一批应逐段读证据后再收
- 这批仍然完全没有改动：
  - `src/` 下任何 public ABI / dataplane / dispatch 生产实现
  - hook 业务断言本身
  - ABI smoke contract / exported table 形状
- Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿，并且 gate 中 `public ABI smoke` 与 `TTestCase_PublicAbi,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework` 也通过，说明这批收的是 public ABI 测试层局部恢复冗余/不对称，而不是 public ABI 生产逻辑回归。

## 2026-05-14 Concurrent Local Restore Consolidation Findings

- `concurrent.testcase` 的形态和刚收完的 `publicabi/direct` 很接近，但更适合先做一层窄收口：
  - `TSimdStatefulTestCase.SetUp` 已经保存 `FSavedVectorAsm/FSavedBackend`
  - `TSimdStatefulTestCase.TearDown` 也已经负责恢复进入测试前状态
  - 真正的冗余来自各个 test body 外层 `finally` 还在重复写 `SetVectorAsmEnabled(LOldVectorAsm); ResetToAutomaticBackend;`
- 这种并发测试层样板有两个坏处：
  - 它重复表达了本来就存在于 stateful fixture 的恢复 contract
  - 它只回 `automatic`，不会显式复用进入测试前保存下来的 backend 选择
- 本轮最小正确修法是把“本地恢复到进入测试前状态”提升成 `TSimdStatefulTestCase` 的共享 helper：
  - 提取 `RestoreSimdLocalState(aOriginalVectorAsm, aOriginalBackend)`
  - `TearDown` 改为复用它，避免 fixture 自己也保留重复恢复体
  - method-level 先只替换完全同构、没有额外清理副作用的 outer finally
- 本轮已收掉的 14 个命中覆盖了：
  - `TTestCase_SimdConcurrentPublicAbi` 的 register/vector-asm 读写一致性路径
  - `TTestCase_SimdConcurrentFramework` 的 current-backend/current-backend-info/backend-ops/runtime-snapshot/dispatchable-helper 路径
  - `TTestCase_SimdConcurrentRegistration.Test_Concurrent_RegisteredBackendList_FirstRegistration_ReadConsistency`
  - `TTestCase_SimdConcurrent.Test_Concurrent_DispatchMixed_ControlPlane`
- 这批刻意没有继续碰两类剩余点：
  - 只保存 `LOldVectorAsm`、本身不切 backend 的纯 toggle 测试
  - 每轮/每分支内部还要显式 `ResetToAutomaticBackend` 才能做下一步断言的状态机块
- 因而当前 `concurrent.testcase` 的剩余 `ResetToAutomaticBackend` 命中并不都代表冗余；下一批应优先逐段审读这些内部轮次级恢复块，而不是做全文件盲替换。
- Release 定向 suite、Release `check`、Release `gate` 全绿，说明这次收的是 concurrent 测试层的恢复样板和状态对称性，而不是 concurrent/public-framework/dataplane 的生产实现问题。

## 2026-05-14 DispatchAPI Local Restore Consolidation Findings

- `dispatchapi.testcase` 在前几批已经补上了类级 `TDispatchAPIStatefulTestCase`，但 method-level 仍留着最厚的一层历史样板：
  - 前半段 control-plane / hook / metadata 测试大量 outer finally 手写 `SetVectorAsmEnabled(LOldVectorAsm); ResetToAutomaticBackend;`
  - 后半段 SSE2/AVX/SSE3/SSSE3/SSE4.x 语义 parity 测试则常写成反序 `ResetToAutomaticBackend; SetVectorAsmEnabled(LOldVectorAsm);`
- 这类样板的问题和前几批完全同构：
  - 重复表达了本来就存在于 stateful fixture 的恢复 contract
  - 只回 automatic，不会显式复用进入测试前保存下来的 backend 选择
- 这批最小正确修法不是继续扩散手写 finally，而是把“本地恢复到进入测试前状态”提升成 `TDispatchAPIStatefulTestCase` 的共享 helper：
  - 提取 `RestoreDispatchApiLocalState(aOriginalVectorAsm, aOriginalBackend)`
  - `TearDown` 改为复用这个 helper
  - method-level 只替换明确位于 procedure 末尾的 outer finally，不去碰内部 rollback / hook 状态机块
- 本轮已收掉两簇命中：
  - 前半段 control-plane / metadata 区 26 处 exact-pattern outer finally
  - 后半段 SSE2/AVX/SSE3/SSSE3/SSE4.x parity 区 8 处反序 outer finally
- 这批之后，`dispatchapi.testcase` 里明确的两行式 outer finally 形态已清空：
  - `SetVectorAsmEnabled(LOldVectorAsm); ResetToAutomaticBackend;`
  - `ResetToAutomaticBackend; SetVectorAsmEnabled(LOldVectorAsm);`
- 这批刻意没有继续碰：
  - 内层 `try/finally` 里为了下一步断言而保留的 `ResetToAutomaticBackend`
  - 只恢复 `LOldVectorAsm`、本身不切 backend 的纯 vector-asm 审计/structural test
  - `src/` 下任何 dispatch / backend / runtime 生产实现
- Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿，并且 `gate` 里的 `TTestCase_DispatchAPI`、`PublicAbi` concurrent chain、`DataPlane`、`DirectDispatch` 和 filtered run_all 也都通过，说明这批收的是 DispatchAPI 测试层 outer finally 样板与状态对称性，而不是 dispatch 生产逻辑回归。

## 2026-05-14 DispatchAPI Pure VectorAsm Outer Finally Cleanup Findings

- 在前两批 `dispatchapi` local-restore 收口后，`TTestCase_DispatchAPI` 本体里还残留第三类更隐蔽的历史样板：
  - outer finally 只写 `SetVectorAsmEnabled(LOldVectorAsm);`
  - 它们虽然不像前两批那样显式 `ResetToAutomaticBackend`，但同样绕开了类级 fixture 已保存的 `FSavedBackend`
  - 一旦测试是在非 automatic / 非默认 forced backend 语义下进入，这种恢复方式仍然会让局部路径与 fixture contract 不一致
- 这批最小正确修法仍然不是新增第四套样板，而是继续复用已存在的共享 helper：
  - `RestoreDispatchApiLocalState(aOriginalVectorAsm, aOriginalBackend)`
  - 让 procedure 末尾的 outer finally 回到和 `TearDown` 一致的恢复顺序
- 本轮只收 `TTestCase_DispatchAPI` 本体里明确的 15 处 pure `vector asm` outer finally：
  - 包括 `RISCVV` capability/public-ABI contract 末尾恢复
  - 以及 `AVX512/AVX2/SSE4.x` capability 与 parity 路径里那批 procedure 末尾的单行恢复
- 这批刻意继续不碰三类点：
  - companion 类里仍然只切 `vector asm`、但局部语义还需要逐段判定的路径
  - 纯 toggle / structural 审计测试
  - 内层为了下一步断言保留的 rollback / backend mutation 状态机块
- 收完之后，当轮锁定的 15 处 `TTestCase_DispatchAPI` pure `SetVectorAsmEnabled(LOldVectorAsm)` procedure-level outer finally 已清掉；继续复核后又在 capability/override 后段与两条 companion mask-contract 路径里发现了另一簇同类命中。
- Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 再次全绿，说明这批继续收的是 DispatchAPI 测试层恢复 contract 的缺失/冗余，而不是 backend capability / public ABI / dispatch 生产行为回归。

## 2026-05-14 DispatchAPI Capability And Companion Pure Outer Finally Cleanup Findings

- 继续按源码逐段复核后，确认上一轮对 `dispatchapi` pure `vector asm` 残余的边界判断仍偏乐观：
  - `TTestCase_DispatchAPI` 的后段 `AVX512/NEON/RISCVV/AVX2/SSE3/SSSE3/SSE4.x` capability/override 路径还留着一簇 procedure 末尾纯 `SetVectorAsmEnabled(LOldVectorAsm)` outer finally
  - 另外 `TTestCase_RISCVVMaskedOpsContract` 两条 mask capability/public-ABI contract 也还在用同样的单行恢复
- 这批的最小正确修法依然不是重新发明样板，而是继续复用已有的 `RestoreDispatchApiLocalState(aOriginalVectorAsm, aOriginalBackend)`：
  - 让 companion contract 与 `DispatchAPI` capability/override 路径统一回到同一个 fixture 恢复 contract
  - 避免继续把“只恢复 vector asm、不复用保存 backend”这一历史写法扩散下去
- 本轮新收掉的 simple outer finally 共 20 处：
  - `TTestCase_RISCVVMaskedOpsContract` 2 处
  - `TTestCase_DispatchAPI` 后段 capability/public-ABI/override 路径 18 处
- 这批之后，`dispatchapi.testcase` 里剩余的裸 `SetVectorAsmEnabled(LOldVectorAsm)` 命中已经不再是顶层 test outer finally，而是长方法内部 local helper / nested procedure 自己的局部 finally。
- 因而下一批如果继续沿 `dispatchapi.testcase` 深审，机械替换价值已经明显下降；更值得看的是真正带语义的内部 helper finally，以及尚未统一的复杂 rollback/backend mutation 块。
- Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 再次全绿，说明这批仍然只是在收 `dispatchapi` 测试层恢复 contract 的缺失/冗余，没有触碰 dispatch/backend/public-ABI 生产行为。

## 2026-05-14 NonX86BackendParity Local Restore Cleanup Findings

- 在 `DispatchAPI` 本体和前两条 companion contract 收完后，`dispatchapi.testcase` 里剩余的顶层裸 `SetVectorAsmEnabled(LOldVectorAsm)` 实际上全部集中到了 `TTestCase_NonX86BackendParity`：
  - 共 16 处
  - 都是顶层 test outer finally
  - 语义上仍属于“vector-asm parity test 结束时没有复用已保存 backend”的同一类历史样板
- 这批仍然适合用最小修法，而不该新建专用 helper：
  - `TTestCase_NonX86BackendParity` 已经继承 `TDispatchAPIStatefulTestCase`
  - 直接复用 `RestoreDispatchApiLocalState(aOriginalVectorAsm, aOriginalBackend)` 就能回到与 fixture 一致的恢复 contract
- 其中少数测试在 finally 里还带本地资源收尾：
  - `FreeAligned(LAligned)`
  - `FreeAligned(LAlignedBlock)`
  - 局部 buffer 复位
  - 本轮只是在这些清理语句前补统一 helper，没有打乱它们各自的本地资源清理顺序
- 收完之后，`dispatchapi.testcase` 里的顶层 test outer finally 已不再残留裸 `SetVectorAsmEnabled(LOldVectorAsm)`；剩余命中已经缩到内部 local helper / nested procedure 自己的局部 finally。
- 这意味着后续如果继续沿这个文件深审，盲扫 value 已经明显下降，下一步应改成逐段审 helper 内部语义，重点看复杂 rollback/backend mutation 块是否真的需要进一步统一。
- Release `TTestCase_DispatchAPI,TTestCase_NonX86BackendParity`、Release `check`、Release `gate` 全绿，说明这批继续只是在收 companion parity 测试层恢复冗余/不对称，而不是 non-x86 backend 或 dispatch 生产语义回归。

## 2026-05-14 NonX86BackendParity Backend Restore Cleanup Findings

- 在上一批把 `TTestCase_NonX86BackendParity` 的 pure `SetVectorAsmEnabled(LOldVectorAsm)` 顶层 outer finally 清空之后，继续逐段复核同一类测试，发现还残留一簇更隐蔽但同样不对称的历史样板：
  - 顶层 `finally` 里直接 `ResetToAutomaticBackend;`
  - 共 12 处
  - 都位于 test body 末尾，不属于内部 helper / nested procedure 的局部恢复
- 这类写法的问题和前几批一致，只是形态更窄：
  - 它仍然绕开了 `TDispatchAPIStatefulTestCase` 已保存的 `FSavedVectorAsm/FSavedBackend`
  - 一旦测试是在非默认 backend 语义下进入，只回 automatic 仍然与 fixture contract 不一致
- 本轮最小正确修法仍然不是新建专用 helper，而是继续复用现有的：
  - `RestoreDispatchApiLocalState(aOriginalVectorAsm, aOriginalBackend)`
  - 这次直接用保存下来的 `FSavedVectorAsm + FSavedBackend`，让顶层收口与 fixture `TearDown` 完全同源
- 12 处命中全部在 `TTestCase_NonX86BackendParity`，覆盖：
  - `MinimalDispatchParity`
  - `ExtendedFloatParity`
  - `NarrowAndNotParity`
  - `DotParity`
  - `I16x32_CoreParity`
  - `I8x64_CoreParity`
  - `U32x16_U64x8_CoreParity`
  - `WideInteger_FuzzSeed_Parity`
  - `WideCompareMaskParity`
  - `I32x4_BitwiseShiftParity`
  - `WideSignedBitwiseShiftParity`
  - `WideIntegerArithmeticMinMaxParity`
- 其中 `Test_WideInteger_FuzzSeed_Parity_IfAvailable` 有额外顺序要求：
  - `RandSeed := LOriginalSeed;` 仍需保留在 helper 调用之前
  - 本轮没有改变这条测试的随机种子恢复顺序
- 收完之后，`TTestCase_NonX86BackendParity` 顶层 outer finally 里已经不再残留 `ResetToAutomaticBackend`。
- 当前 `dispatchapi.testcase` 剩余的 `ResetToAutomaticBackend` 命中，已经主要是复杂 rollback/backend mutation/helper 状态机块；这些块不适合再做机械替换，后续要按语义逐段审。
- Release `TTestCase_DispatchAPI,TTestCase_NonX86BackendParity`、Release `check`、Release `gate` 全绿，说明这批继续收的是 companion parity 测试层 restore contract 的缺失/冗余，而不是 non-x86 dispatch/backend 生产语义。

## 2026-05-14 DispatchAPI Tail Reset Redundancy Cleanup Findings

- 在 `NonX86BackendParity` 那批之后，`dispatchapi.testcase` 里剩余的 `ResetToAutomaticBackend` 命中已经不再适合按“看到 reset 就改”处理。
- 逐段复核后，剩余命中可以清晰分成四类：
  - fixture/helper 本体自己的 reset
  - 测试前置条件里显式建立 automatic 起点的 reset
  - hook/rollback/state-machine 过程中承担语义断言的中途 reset
  - 恢复原 backend table 后、下一步马上返回给 `TDispatchAPIStatefulTestCase.TearDown` 的尾声重复 reset
- 本轮只处理第四类，因为这类 reset 同时满足三个条件：
  - 它发生在 `RegisterBackend(..., LOriginalTable)` 之后
  - 后面没有新的断言依赖 automatic 状态
  - 方法返回后 fixture `TearDown` 本来就会恢复进入测试前的 `FSavedVectorAsm/FSavedBackend`
- 因此这批删掉的不是“建立语义前提”的 reset，而是“退出前重复切换一次 automatic”的噪音。
- 本轮共删 20 处，覆盖几类路径：
  - `TrySetActiveBackend_*` hook mutation / rollback restore 结尾
  - `RegisterBackend_*` metadata / snapshot round-trip 结尾
  - `BenchmarkActivation_Rejects_CpuSupportedButNonDispatchable_Backend`
  - 一串 `Vec*Facade_Tracks_CurrentDispatchTable_After_ReRegister`
- 这些删除都保留了原始的表恢复动作：
  - `RegisterBackend(..., LOriginalTable)` 仍在
  - 只去掉其后的尾声 `ResetToAutomaticBackend`
- 这批通过后可以更有把握地说：
  - 当前 `dispatchapi.testcase` 剩余的 `ResetToAutomaticBackend`，更多是 setup/mid-test/hook-state-machine 的真实语义点
  - 后续再往下收，必须按“是否仍有断言依赖该 reset”逐段读，而不是继续按形状盲删
- Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿，说明这批删掉的确实是测试层尾声冗余，而不是 dispatch/backend 生产逻辑的隐性依赖。

## 2026-05-14 RISCV Fallback Probe Fixture Hardening Findings

- 在继续审 `7999/8006/9316/9329` 这组复杂点时，真正更值得修的不是另一个尾声 reset，而是 `TTestCase_RISCVFallbackDispatchContract.Test_RollbackRestoreSuccess_Keep_RepresentativeWideSlots_Assigned` 的 inner fixture 边界。
- 这条 probe 原本的模式是：
  - `LCase := TTestCase_DispatchAPI.Create;`
  - 直接调用 `LCase.Test_TrySetActiveBackend_RollbackRestore_Success_Preserves_ForcedSelection;`
  - 块尾再 `ResetToAutomaticBackend;`
- 但被调用的 inner test 的 finally 明确会走：
  - `RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)`
  - 也就是说，它依赖 `TDispatchAPIStatefulTestCase.SetUp` 已经正确填好了 `FSavedVectorAsm/FSavedBackend`
- 在没有显式 `SetUp/TearDown` 的前提下，这条 probe 的正确性实际上依赖两件脆弱事实：
  - 测试类字段的零值碰巧不会把恢复逻辑带偏太远
  - 外层块尾的 `ResetToAutomaticBackend` 会把状态重新拉回去
- 这是比“冗余 reset”更实在的风险，因为它把测试方法当普通 helper 调用，却没有带上它自己的 fixture contract。
- 本轮修法不是去改生产实现，也不是继续清空 reset，而是把这条 cross-test probe 的 inner fixture 显式化：
  - 增加 `LInnerSetupDone`
  - `LCase.SetUp`
  - 调用 inner `Test_*`
  - `LCase.TearDown`
  - 最后 `LCase.Free`
- 同时删掉块尾那个原本用于“手工拉回 automatic”的 reset，让 probe 自己真的验证 inner fixture 可以把状态恢复到外层预期，而不是继续靠外层兜底。
- 全文件复核后，当前这类“手工 new 测试类并直接调测试方法”的模式只发现这一处，所以这是一次高价值、低扩散面的边界修复。
- Release `TTestCase_RISCVFallbackDispatchContract,TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿，说明这条 probe 现在已经从“隐式依赖零值 + 外层 reset”切回了明确的 fixture 契约。

## 2026-05-14 PublicAbi Double Restore Cleanup Findings

- 在 `publicabi.testcase` 前两批 local-restore helper 收口之后，继续逐段复核剩余的尾声恢复，发现新的高价值点已经不再是 `ResetToAutomaticBackend`，而是 `RestoreOriginalActiveBackend(...)` 的双恢复冗余：
  - 先恢复回某个“原 backend”
  - 然后马上 `RestorePublicAbiLocalState(...)` 或直接结束测试
  - 中间没有新的断言依赖那个中间态
- 这类写法的问题不是“语义错误”，而是测试尾声多维护了一层没有消费方的中间恢复状态：
  - 它让读代码的人误以为“先恢复原 backend”本身是断言前提
  - 但真实的 restore contract 仍然是类级保存的 `FSavedVectorAsm/FSavedBackend`，或者方法直接结束交给 fixture
- 本轮逐段确认后，真正可以删掉的双恢复点共有 9 处，覆盖：
  - `Test_PublicApi_CachedTable_RemainsCallable_Across_Rebind`
  - `Test_PublicApi_CachedTable_Preserves_PreviousSnapshot_Metadata_Across_Rebind`
  - `Test_PublicApi_Table_Uses_Stable_Cdecl_EntryPoints_AfterBackendSwitch`
  - `Test_PublicApi_BackendRoundTrip_Reuses_PreviouslyPublishedMetadataTable`
  - `Test_PublicApi_BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable`
  - `Test_PublicApi_ActiveBackendId_Tracks_RegisterSlot_After_ReRegister`
  - `Test_PublicApi_ActiveBackendId_Tracks_FinalState_When_HookReRegister_Overrides_ForcedSelection`
  - `Test_PublicApi_FailedHookMutation_Restores_AutomaticBackend_Immediately`
  - `Test_PublicApi_RollbackRestore_ReSelects_RequestedBackend_Before_Return`
- 这些删除都满足同一个判定标准：
  - 后面没有断言依赖“恢复后的中间 backend”
  - 或者紧接着就会由 `RestorePublicAbiLocalState(...)` 把状态恢复到进入测试前保存的 `vector asm + backend`
- 仅有 1 处 `RestoreOriginalActiveBackend(...)` 需要保留：
  - `Test_PublicApi_Table_Refreshes_AfterBackendSwitch`
  - 因为它在 finally 之后还有断言 `Public API active backend should track the restored backend`
  - 这里的“先恢复回 `LOriginalBackend`”是后续断言语义的一部分，不是噪音
- 当前判断也更清楚了：
  - `publicabi.testcase` 里简单两行式 restore 样板和这批双恢复尾声已经基本收完
  - 下一批若继续沿 public ABI 深审，重点应转向还夹带 hook/state-machine 语义、且确实需要逐段判断断言依赖的复杂 finally
- Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿，说明这批删掉的确实只是 public ABI 测试层尾声冗余，而不是 public ABI / dataplane / dispatch 生产语义依赖。

## 2026-05-14 PublicAbi Capability Pure Outer Finally Cleanup Findings

- 在上一批双恢复清理之后，`publicabi.testcase` 里剩余最整齐的一簇 restore contract 缺口，转成了 capability/pod-info 用例的顶层 pure `vector asm` outer finally：
  - `finally`
  - `SetVectorAsmEnabled(LOldVectorAsm);`
  - `end;`
- 这类写法看起来比 `ResetToAutomaticBackend` 温和，但本质问题相同：
  - 测试过程中会显式 `SetVectorAsmEnabled(True/False)`
  - 这些切换本身可能触发 active backend 重选
  - 末尾只恢复 `vector asm`，却没有回到类级 fixture 已保存的 `FSavedBackend`
- 逐段确认后，这批可安全统一的命中共 14 处，全部位于 `BackendPodInfo_CapabilityBits_*` 路径，覆盖：
  - `x86 shuffle / masked ops / always-on integer ops`
  - `AVX2 shuffle`
  - `AVX512 FMA / shuffle / vector-asm-gated bits`
  - `NEON vector-asm-gated bits / integer ops / FMA / shuffle`
  - `RISCVV integer ops / FMA / shuffle / vector-asm-gated bits`
- 这些点适合统一收回 helper，而不该继续保留单行恢复，原因是：
  - 它们都是顶层 test outer finally，不是内层 helper / nested procedure 的局部清理
  - 没有后续断言依赖“只恢复 `vector asm`、不恢复 backend”的中间态
  - `TTestCase_PublicAbi` 已经有现成的 `RestorePublicAbiLocalState(aOriginalVectorAsm, aOriginalBackend)`，而且 `TearDown` 本身也复用它
- 因而本轮最小正确修法仍然不是引入新 helper，而是把这 14 处统一切到：
  - `RestorePublicAbiLocalState(LOldVectorAsm, FSavedBackend)`
- 收完之后，`publicabi.testcase` 里顶层裸 `SetVectorAsmEnabled(LOldVectorAsm)` 已经清零；剩余 restore/reset 命中主要是：
  - helper 本体
  - 作为前置条件建立 automatic 基线的 reset
  - hook/state-machine 过程中确实承担断言语义的中途 reset
- 这也意味着下一批若继续沿 public ABI 深审，已经不适合再做形状扫描；要转成逐段判断复杂 hook/rollback/failure 路径是否真的有“退出前重复 reset/restore”。
- Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿，说明这批收掉的确实只是 capability/pod-info 测试层恢复 contract 的缺失，而不是 public ABI / runtime rebuild / backend capability 生产行为依赖。

## 2026-05-14 PublicAbi Empty Finally And Duplicate Table Restore Cleanup Findings

- 在 capability/pod-info 顶层恢复收完之后，继续往复杂 hook/rollback/failure 路径深审，最确定的真冗余反而不是新的 `ResetToAutomaticBackend`，而是两类更机械的 exact-contract 噪音：
  - 空 `finally` 壳
  - 正常流已经恢复原 table，outer finally 还会再做一遍同样的 `RegisterBackend(...original...)`
- 空 `finally` 这次一共确认了 3 处：
  - `Test_PublicApi_CachedTable_RemainsCallable_Across_Rebind`
  - `Test_PublicApi_CachedTable_Preserves_PreviousSnapshot_Metadata_Across_Rebind`
  - `Test_PublicApi_BackendRoundTrip_Reuses_PreviouslyPublishedMetadataTable`
- 这些壳都是前几轮删掉尾声恢复后留下来的历史骨架：
  - 没有 cleanup 逻辑
  - 没有后续状态恢复责任
  - 保留它们只会增加读者对“这里是不是还该有恢复语义”的误判
- 另一簇更有价值的冗余是 duplicate table restore：
  - 方法主体在正常流里已经显式 `RegisterBackend(...original...)`
  - 后面还会立刻用恢复后的状态做断言
  - outer finally 同时还保留了 `if *TableCaptured then RegisterBackend(...original...)`
  - 这样一来，正常路径总会对同一张原 table 连续恢复两次
- 本轮收口方式保持最小化，没有删除 outer finally 的兜底职责，而是只在“显式恢复原 table 成功后”立刻清掉 capture 状态：
  - `LRequestedTableCaptured := False`
  - `LPreviousTableCaptured := False`
  - 或在重注册双层测试里用 `LOriginalTableRestored` 标出“已经恢复过”
- 这样做的好处是：
  - 异常路径仍然由 outer finally 兜底
  - 正常路径不再重复 re-register 同一张原 table
  - 中途 hook/rollback/failure 的断言语义完全不动
- 这批具体覆盖了：
  - `CachedTable_Cdecl_EntryPoints_Follow_CurrentDataPlane_After_ReRegister`
  - `FailedHookMutation_Restores_PreviousForcedBackend`
  - `SetActiveBackend_HookLateFailure_Preserves_PreviousForcedBackend`
  - `RollbackRestore_LateForce_Restores_AutomaticBackend`
  - `RollbackRestore_LateForce_DuringRestore_Restores_AutomaticBackend`
  - `RollbackRestore_LateForce_Preserves_PreviousForcedBackend`
  - `RegisterBackend_HookLateAutomaticReset_Preserves_PreviousForcedBackend`
  - `RegisterBackend_HookLateForce_DuringRestore_Preserves_PreviousForcedBackend`
- 当前判断也进一步收紧了：
  - `publicabi.testcase` 里 easy shape 的空壳与 duplicate table restore 已经又清掉一层
  - 剩余更值得继续查的，主要是那些中途 reset/restore 本身就是测试主题的一部分的 hook/state-machine 路径，后续必须逐段看断言依赖，不能再按形状批量删
- Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿，说明这批收掉的确实只是 public ABI 测试层 cleanup 冗余，而不是 register/hook/rollback 生产语义依赖。

## 2026-05-14 PublicAbi Failed Hook Fixture Restore Guard Findings

- 在上一批 duplicate cleanup 收完之后，继续沿 `publicabi` 的 failure 路径逐段看异常兜底，发现一个比“重复恢复”更实在的夹具缺口：
  - `Test_PublicApi_FailedHookMutation_DoesNotRevive_PreviouslyRequestedBackend_AfterRestore`
  - 会通过 hook 把 `requested backend` 改成 non-dispatchable
  - 正常流末尾会手工 `RegisterBackend(LRequestedBackend, LOriginalTable)` 恢复原 table
  - 但 outer finally 只有 `RestorePublicAbiLocalState(...)`，没有 table-restore guard
- 这意味着如果中途发生异常，尤其是：
  - `AssertFalse(...)` 失败
  - `TrySetActiveBackend(...)` 异常
  - 或正常流恢复前新增其他异常
  那么 requested backend table 的恢复会被跳过，和后面那些已经带 `LRequestedTableCaptured` 的同类路径不一致。
- 对照同文件其它 hook/rollback 路径后，这条测试显然是一个漏网的 fixture 兜底缺口，而不是设计上故意不同：
  - `FailedHookMutation_Restores_PreviousForcedBackend`
  - `SetActiveBackend_HookLateFailure_Preserves_PreviousForcedBackend`
  - `RollbackRestore_LateForce_*`
  都已经有 outer restore guard
- 本轮修法保持最小且与现有风格对齐：
  - 增加 `LRequestedTableCaptured`
  - 捕获原 table 后置 `True`
  - 正常流 `RegisterBackend(LRequestedBackend, LOriginalTable)` 成功后置 `False`
  - outer finally 中在 `Captured=True` 时兜底恢复
- 这次修的不是“尾声噪音”，而是实打实的异常路径安全性：
  - 正常流行为不变
  - 中途 hook/断言语义不变
  - 但测试一旦半路失败，不会把被 hook 改坏的 backend table 留给后续用例
- 当前判断继续收紧：
  - `publicabi.testcase` 里最明显的 easy cleanup 已经大多收完
  - 剩余更值得继续查的，是其它 complex hook/state-machine 路径是否还存在这种“正常流能恢复，异常流却没有 outer guard”的少量漏点
- Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿，说明这条修的是 public ABI 测试层 fixture safety，而不是 public ABI / dispatch 生产语义依赖。

## 2026-05-14 PublicAbi RollbackForceSuccess Higher-Restore Dedup Findings

- 继续往 `publicabi` 的 state-machine 路径深读后，`RollbackForceSuccess` 这条成功流里还有一处更隐蔽的 duplicate restore：
  - `PublicAbiHookRollbackForceSuccessWithoutForcedIntent` 会先把 target table 标 unavailable，再恢复 target table，同时把一批 higher-priority backend tables 标 unavailable
  - 测试成功返回后，normal path 已显式执行一轮 `for ... RegisterBackend(higher, original_table)`
  - 但 outer finally 仍会根据 `GPublicAbiHookRollbackForceSuccessHigherCount` 再跑一轮相同恢复
- 这和前几批 duplicate cleanup 的判断标准一致：
  - 恢复动作已经在正常流完成
  - 后续只剩状态断言，没有新的步骤依赖“再恢复一次”
  - outer finally 仍然应该保留异常路径兜底，但不该在成功流里重复跑
- 这条路径比普通 `RegisterBackend(...original...)` 更难一眼看出，因为：
  - 恢复对象不是单个 backend，而是一组 `higher-priority backends`
  - capture/restore 状态散在全局 helper 变量里：`GPublicAbiHookRollbackForceSuccessHigherCount`、`...HigherBackends`、`...HigherTables`
  - target table 的恢复又是通过 hook 第二阶段隐式完成的，不是测试主体里显式写一行
- 本轮最小修法没有碰 hook 过程本身，而是在“成功流已经恢复完成”之后把 outer finally 的重复恢复条件关掉：
  - `LTargetTableCaptured := False`
  - `GPublicAbiHookRollbackForceSuccessHigherCount := 0`
- 这样做的效果是：
  - 如果 `TrySetActiveBackend(...)` 或后续断言在恢复前失败，outer finally 仍会兜底
  - 如果成功流已经完成恢复，outer finally 就不再对 target/higher tables 再跑一遍相同 restore
  - 中途 hook/stage 语义完全不变
- 当前判断继续收紧：
  - `publicabi.testcase` 里显而易见的 duplicate restore 又少了一层
  - 剩余 complex 路径更值得关注的，主要是其它多对象/多阶段 hook 流里是否还有类似“normal path 已恢复，outer finally 仍重复恢复”的隐藏点
- Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿，说明这批修的是 public ABI 测试层成功流 cleanup 冗余，而不是 rollback force-success 语义依赖。

## 2026-05-14 DataPlane And IEEE754 Local Restore Alignment Findings

- 把视野从 `publicabi` 稍微放宽后，`dataplane` 和 `ieee754` 里还残留一批和前几轮同类的顶层 fixture 恢复旧形状：
  - `dataplane.testcase` 的 `Test_DataPlane_VectorAsmRoundTrip_Reuses_PreviouslyPublishedSnapshot` 在 finally 里只做 `SetVectorAsmEnabled(LOldVectorAsm); ResetToAutomaticBackend;`
  - `ieee754.testcase` 的 4 个 test class tearDown 以及 6 个方法级 finally 也还是同类模式
  - `TTestCase_NonX86IEEE754.Test_NonX86_RoundTruncFloorCeil_NaNInf_IfAvailable` 的 outer finally 更明显，只恢复了 `vector asm`，把 backend 恢复完全留给后续 fixture
- 这类点的共同问题不是功能断言错，而是测试夹具恢复契约继续分叉：
  - 类级 fixture 已经保存了 `FSavedBackend/FOldBackend`
  - 但 method-level finally 还停留在“回到 automatic backend 即可”的旧假设
  - 一旦测试后续再插入断言、局部 cleanup 或更多状态机步骤，这种分叉会把真实 backend drift 藏到 TearDown 才暴露
- 本轮修法保持测试层最小闭环，不碰生产实现：
  - 在 `dataplane` 补 `RestoreDataPlaneLocalState(...)`
  - 在 `ieee754` 补 `RestoreIEEE754LocalState(...)`
  - helper 统一执行：恢复 `vector asm` -> `ResetToAutomaticBackend` -> 如有需要 `TrySetActiveBackend(saved_backend)`
- 本轮还踩到一个真实但低风险的 Pascal 作用域细节：
  - 首版 helper 直接在顶层 procedure 里调用 `AssertTrue`
  - FPC 编译报 `Identifier not found "AssertTrue"`
  - 原因不是测试语义问题，而是顶层 helper 不在 `TTestCase` 方法作用域里
  - 最终改成 helper 返回 `Boolean`，把断言留回各个 tearDown / finally 调用点，语义更清楚也更符合 Pascal 作用域事实
- 收完之后的状态是：
  - `dataplane` 不再保留“只恢复 automatic backend”的尾声旧形状
  - `ieee754` 的 tearDown 与方法级 finally 对“恢复保存 backend”的契约重新对齐
  - 这批属于测试层 fixture hardening / redundancy cleanup，不改变 SIMD dataplane 或 IEEE754 算法语义
- Release `TTestCase_DataPlane`、Release `TTestCase_IEEE754EdgeCases`、Release `TTestCase_AVX2RoundTruncIEEE754`、Release `TTestCase_NonX86IEEE754`、Release `TTestCase_IEEE754_F64`、Release `check`、Release `gate` 全绿，说明改动只影响测试恢复契约，没有引入行为回归。

## 2026-05-14 DispatchSlots And SSE2Contracts Restore Alignment Findings

- 继续沿剩余小 testcase 文件往下扫后，`dispatchslots` 和 `sse2contracts` 里还留着另一簇更老的恢复形状：
  - `dispatchslots.testcase` 的 `TearDown` 仍手写 `ResetToAutomaticBackend` 后再 `TrySetActiveBackend(FSavedBackend)`
  - 同文件 3 条方法尾声也还只做 `ResetToAutomaticBackend`
  - `sse2contracts.testcase` 的 `TearDown` 仍手写 `SetVectorAsmEnabled(FOldVectorAsm); ResetToAutomaticBackend; TrySetActiveBackend(FOldBackend)`
- 这批和上一轮 `dataplane / ieee754` 是同一类问题，只是分成了两个更小的 companion 文件：
  - 测试夹具事实上都保存了原始 backend
  - 但尾声恢复仍在重复旧的手写样板
  - `dispatchslots` 的 method-level finally 尤其明显，会把 backend 临时留在 automatic 上，直到更外层 tearDown 才回到保存状态
- 本轮修法仍然只动测试层：
  - 在 `dispatchslots` 补 `RestoreDispatchSlotsLocalState(...)`
  - 在 `sse2contracts` 补 `RestoreSSE2ContractsLocalState(...)`
  - 两个 helper 都返回 `Boolean`，把断言保留在 `TTestCase` 方法作用域内，延续上一轮已经验证过的 Pascal 作用域安全做法
- 收完后的效果是：
  - `dispatchslots` 不再在类级 tearDown 和 3 条方法尾声里重复手写 restore 样板
  - `sse2contracts` 的 fixture 恢复契约也和其它测试文件重新对齐
  - 这批仍属于 fixture hardening / redundancy cleanup，不触碰 dispatch slot 或 SSE2 生产逻辑
- Release `TTestCase_DispatchAllSlots`、Release `TTestCase_SSE2Contracts`、Release `check`、Release `gate` 全绿，说明这批只是在 companion testcase 层消除恢复分叉，没有引入行为回归。

## 2026-05-14 Concurrent VectorAsm Restore Alignment Findings

- 继续沿 `direct / concurrent` 缩小范围后，`concurrent` 里还剩最后两条同类顶层 old-shape finally：
  - `Test_Concurrent_VectorAsmToggle_DispatchReadConsistency`
  - `Test_Concurrent_VectorAsmToggle_MultiWriter_DispatchRead`
  两者都在 finally 里只做 `SetVectorAsmEnabled(LOldVectorAsm)`。
- 这两条和前几轮收掉的 `dataplane / ieee754 / dispatchslots / sse2contracts` 是同一类问题：
  - 类级 fixture 已保存 `FSavedBackend`
  - 同文件也已经有 `RestoreSimdLocalState(...)`
  - 但这两条并发测试还把 backend 恢复留给更外层 tearDown，而不是在方法尾声自己回到保存状态
- 本轮修法是目前最小、也最确定的一种：
  - 不引入新 helper
  - 直接复用现成的 `RestoreSimdLocalState(LOldVectorAsm, FSavedBackend)`
  - 只改两条 finally，不碰线程逻辑、worker 生命周期和 round-level 并发断言
- 之所以这轮没有顺手把 `direct` 一起收掉，是因为 `direct` 那个残点落在全局过程 `RunDirectDispatchConcurrentReRegisterSnapshotConsistency`，要彻底对齐需要先补原始 backend 捕获；它不像这里这样有现成 helper 和类级保存状态，所以风险边界不同，适合下一批单独做。
- 收完后的状态是：
  - `concurrent` 中最明显的“只恢复 vector asm、不恢复保存 backend”的顶层 finally 已清零
  - 这批仍属于测试层 fixture hardening / redundancy cleanup，不改变并发 dispatch/vector-asm 语义
- Release `TTestCase_SimdConcurrent`、Release `check`、Release `gate` 全绿，说明改动只影响并发测试夹具恢复契约，没有引入行为回归。

## 2026-05-14 Direct Concurrent Snapshot Cleanup Restore Alignment Findings

- 顺着上一轮留下的 stop-point 继续看 `direct` 后，最值得动的残点就是全局过程 `RunDirectDispatchConcurrentReRegisterSnapshotConsistency`：
  - 进入过程前没有保存原 backend
  - finally 只做 `RegisterBackend(sbScalar, LOriginalTable); ResetToAutomaticBackend; RebindDirectDispatch;`
  - 这意味着该过程返回时 direct/dispatch 状态只回到 automatic，而不是回到调用前真实 backend
- 这条和之前几轮所有 testcase 层 restore 分叉的本质一致，只是位置更隐蔽：
  - 它不在 `TTestCase` 方法里，而在全局过程里
  - 没有现成 `FSavedBackend`
  - 所以不能直接套前几轮的类级 helper，而要先补 entry capture
- 本轮修法保持最小：
  - 新增 `LOriginalBackend := GetCurrentBackend`
  - finally 中恢复 scalar 原表后，若当前 backend 不是原 backend，就 `TrySetActiveBackend(LOriginalBackend)`
  - 若恢复失败，抛出明确异常，避免静默把 drift 留给外层 fixture
  - 之后再 `RebindDirectDispatch`
- 这样做的效果是：
  - 全局过程自己闭合自己的 cleanup 契约
  - `TTestCase_DirectDispatchConcurrent` 不再需要依赖更外层 tearDown 才把 backend 拉回调用前状态
  - synthetic table 并发测试语义和 direct dispatch publication 逻辑都不变
- Release `TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿，说明这批仍然只是测试层 cleanup hardening，没有引入 direct dispatch 行为回归。

## 2026-05-14 DispatchAPI Basic Restore And BackendConsistency Entry-State Alignment Findings

- 继续沿剩余 `ResetToAutomaticBackend` 命中做分类后，最稳的一批残点不在复杂 hook/state-machine，而在两簇更基础的测试尾声：
  - `dispatchapi.testcase` 的 `Test_TryForceBackend_*` / `Test_TrySetActiveBackend_*` 前 4 条基础 API 测试
  - 根 `testcase` 的 `TTestCase_BackendVectorConsistency` 包装/元测试
- `dispatchapi` 这簇的问题很直接：
  - 类级 `TDispatchAPIStatefulTestCase` 已经有 `FSavedVectorAsm`、`FSavedBackend` 和 `RestoreDispatchApiLocalState(...)`
  - 同文件后面绝大多数需要局部 cleanup 的测试也已经复用这个 helper
  - 但最前面的 4 条老测试方法级 finally 仍只做 `ResetToAutomaticBackend`
  - 这会把方法级 cleanup 契约继续停留在“回到 automatic 就够了”的旧假设上，而不是尽早回到进入测试时保存的 backend
- 根 `testcase` 这簇更隐蔽一点：
  - `TTestCase_BackendVectorConsistency` 不是 stateful testcase，而是 plain `TTestCase`
  - `Test_VectorOps_Consistency` 自己会保存入口 backend 并在 finally 里手写 restore
  - 但它下面两条“preserves previous forced backend”元测试在执行过程中会主动 force 到 scalar，再调用 helper / wrapper 验证局部语义，测试退出时却只做 `ResetToAutomaticBackend`
  - 结果是：测试内部断言的是“调用过程保持 forced backend”，但测试结束后的真实全局状态仍被留在 automatic，而不是恢复到进入元测试前的 backend
- 本轮修法仍然只动测试层 restore 契约：
  - `dispatchapi` 的 4 条基础测试全部切到 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`
  - 根 `testcase` 新增 `RestoreBackendVectorConsistencyLocalState(...)`
  - `Test_VectorOps_Consistency` 用这个 helper 取代手写 restore 样板
  - 两条 backend-consistency 元测试额外捕获 `LEntryBackend`，在 finally 中恢复到进入测试前真实 backend，而不是停在 automatic
- 这批修法的价值在于把“局部语义断言”和“测试退出 cleanup”彻底拆开：
  - 测试内部仍然验证 helper / wrapper 是否保住 forced backend
  - 但测试方法本身退出时不再把全局 backend 状态漂移留给后续用例或更外层 fixture
- Release `TTestCase_DispatchAPI`、Release `TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 全绿，说明改动只影响测试层 cleanup hardening，没有改变 dispatch API 或 backend consistency 生产语义。

## 2026-05-14 DispatchAPI BackendOnly Metadata Restore Alignment Findings

- 继续沿 `dispatchapi` 剩余命中往下分类后，又浮出一簇更适合单独收口的 backend-only / metadata 测试：
  - `Test_SetActiveBackend_Unavailable_FallsBackToScalar`
  - `Test_BackendInfoAvailableFalse_IsNotSelectable`
  - `Test_SupportedAliases_StayCpuOnly_WhenBackendBecomesNonDispatchable`
  - `Test_RegisteredBackendDispatchTable_PreservesCanonicalTextMetadata_After_ReRegister`
  - `Test_CurrentBackendInfo_PreservesCanonicalTextMetadata_After_ReRegister`
- 这 5 条的共同点是：
  - 测试内部都会主动 `ResetToAutomaticBackend`，或者显式围绕“当前 backend”做重注册/metadata 断言
  - 但退出测试时要么只回到 `automatic`，要么根本不做方法级 restore，而把状态恢复完全留给外层 `TearDown`
  - 它们和之前已经收口的 `dispatchslots`、`dispatchapi` 前 4 条基础测试属于同一类“method-level cleanup 契约落后于类级 saved-state fixture”的问题
- 这批和复杂 hook/state-machine 路径的边界很清楚：
  - 中途的 `ResetToAutomaticBackend` 仍然是测试主题步骤本身，不动
  - 改动只发生在最外层退出态
  - 内层 `RegisterBackend(..., LOriginalTable)` 恢复表语义保持不变
- 本轮修法因此保持最小：
  - `SetActiveBackend_Unavailable_FallsBackToScalar` 直接把 finally 从 `ResetToAutomaticBackend` 切到 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`
  - 其余 4 条测试补 outer `try...finally`，让它们在内部仍从 automatic/current-backend 场景出发做断言，但退出时统一恢复类级 `FSavedVectorAsm + FSavedBackend`
  - 顺手把 `Test_BackendInfoAvailableFalse_IsNotSelectable` 的局部变量改成 `L*` 形状，和仓库约定对齐
- 这批修法的价值在于进一步缩小 `dispatchapi` 内“backend-only current-state tests 仍把全局状态漂给 TearDown”的范围：
  - table/metadata 断言本身不变
  - current-backend / alias / availability 语义不变
  - 变化只在测试方法退出时更早恢复 saved state
- Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿，说明这批仍然只是 `dispatchapi` 测试层 cleanup hardening，没有影响 dispatch/public ABI 生产行为。

## 2026-05-14 DispatchAPI Facade CurrentDispatch Restore Alignment Findings

- 继续沿 `dispatchapi` 后段往下缩时，最值得先收的是一簇 facade/current-dispatch easy wins：
  - `Test_VecF32x4ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF64x2ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF64x2MathFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF32VectorMathFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecWideFloatDotFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF64x4ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF32x8ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF64x8ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF32x16ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
- 这 9 条的共同点很明确：
  - 测试内部都会先切到 automatic/current-backend 场景，再对当前 dispatch table 重注册 synthetic slots
  - 内层已经有 `RegisterBackend(LBackend, LOriginalTable)` 负责把被改写的表恢复回去
  - 但最外层退出时仍完全依赖类级 `TearDown` 才把 `FSavedVectorAsm + FSavedBackend` 拉回保存状态
  - 也就是说，table rollback 是方法内闭合的，global state rollback 却还滞后到更外层 fixture
- 这一簇和前面已经收掉的 backend-only / metadata tests 边界也很清楚：
  - 中途 `ResetToAutomaticBackend` 仍然是建立“当前 backend / 当前 dispatch table”场景的测试主题步骤，不动
  - 内层 `RegisterBackend(LBackend, LOriginalTable)` 的回滚语义不动
  - 本轮只补最外层 method-exit restore，让 facade 测试本身退出时也回到类级保存状态
- 本轮修法因此保持最小：
  - 9 条测试全部包 outer `try...finally`
  - finally 统一改成 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`
  - synthetic Reduce/Math/Dot slot 注入、`GetDispatchTable^` 断言、以及 facade 是否跟踪 current dispatch table 的断言完全不变
- 这批收完后的价值是：
  - `dispatchapi` 后段 facade/current-dispatch tests 不再把 backend drift 留给 outer `TearDown`
  - current dispatch table 与 facade 跟踪语义仍只由内层 re-register/assert 路径决定，没有把 cleanup 逻辑和被测语义混在一起
  - 这批仍属于测试层 fixture hardening / redundancy cleanup，不触碰 SIMD 生产实现
- 已有验证链保持全绿：`git diff --check`、Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 均通过；说明这批改动只收方法级退出态 restore，没有引入 dispatch/facade 行为回归。

## 2026-05-14 PublicAbi Cached Publication Restore Alignment Findings

- 继续从 `dispatchapi` 切到 `publicabi` 后，最值得先收的不是 hook-heavy rollback state machine，而是一簇 current-publication easy wins：
  - `Test_PublicApi_CachedTable_RemainsCallable_Across_Rebind`
  - `Test_PublicApi_CachedTable_Preserves_PreviousSnapshot_Metadata_Across_Rebind`
  - `Test_PublicApi_BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable`
- 这 3 条的共同点很明确：
  - 测试内部都会改变当前 active backend 或 public ABI 当前发布态
  - 但最外层退出时仍没有回到类级 `FSavedVectorAsm + FSavedBackend`
  - 其中前两条 cached/publication tests 在 rebind 后直接结束；后一条虽然内层会把 `RegisterBackend(LOriginalBackend, LOriginalTable)` 回滚掉，但 active backend 已经因为 unavailable 重注册而发生 re-selection，退出时仍把 drift 留给 `TearDown`
- 这批和复杂 hook/state-machine 路径的边界也很清楚：
  - 不碰 `PublicAbiHook*` 相关状态机
  - 不改中途 control-plane 步骤和 `GetSimdPublicApi` / cached table 语义断言
  - 只补 method-exit restore，让测试本身在退出时恢复到类级保存状态
- 本轮修法因此保持最小：
  - `CachedTable_RemainsCallable_Across_Rebind` 与 `CachedTable_Preserves_PreviousSnapshot_Metadata_Across_Rebind` 都补 outer `try...finally`
  - finally 统一调用 `RestorePublicAbiLocalState(FSavedVectorAsm, FSavedBackend)`
  - `BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable` 也补 outer restore，但保留内层 `RegisterBackend(LOriginalBackend, LOriginalTable)` 继续只负责恢复被改写的 backend table
- 这批修法的价值在于把 `publicabi` 的两个恢复层级重新拆开：
  - backend table rollback 仍由内层 `RegisterBackend(..., LOriginalTable)` 闭合
  - active backend / vector-asm saved-state rollback 则在方法退出时统一回到 `RestorePublicAbiLocalState(...)`
  - 从而不再依赖类级 `TearDown` 才把 current-publication 场景收干净
- Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿，说明这批仍然只是 `publicabi` 测试层 cleanup hardening，没有影响 public ABI 发布、cached table 或 hook 行为语义。

## 2026-05-14 DispatchAPI AVX512 Cleanup Dedup And Hook Restore Alignment Findings

- 继续沿 `dispatchapi` 更后段审查时，浮出的不是新的 missing coverage，而是两种测试层 cleanup 结构问题：
  - 4 条 AVX512 parity/contract tests 里，内层已经有 `ResetToAutomaticBackend`，外层又统一 `RestoreDispatchApiLocalState(...)`，形成重复 method-exit cleanup
  - `Test_DispatchChangedHooks_MultiSubscriber_Dedup_And_Remove` 的 finally 则相反，只回到 automatic，仍把 saved-state 恢复留给类级 `TearDown`
- 这 4 条 AVX512 tests 是：
  - `Test_AVX512_U32x16_U64x8_MappingAndParity`
  - `Test_AVX512_U32x16_U64x8_ShiftBoundary_Contracts`
  - `Test_AVX512_I16x32_I8x64_U8x64_MappingAndParity`
  - `Test_AVX512_F32x16_F64x8_IEEE754_MappingAndParity`
- 它们的共同点很清楚：
  - active backend 只在方法里切到 `sbAVX512`
  - 后续没有任何依赖“先回 automatic 再继续断言”的代码
  - 最外层已经统一用 `RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)` 收尾
  - 因此 inner `finally ResetToAutomaticBackend` 只是在 method-exit 再做一层重复 cleanup，没有额外语义价值
- hook 多订阅测试的边界也需要单独说明：
  - 测试体里的 `ResetToAutomaticBackend` 是被测控制面步骤本身，因为它负责触发第二轮 hook 通知，这一条不能动
  - 真正该收的是 finally 里的 cleanup；那里在 hook 已经移除后，只回 automatic 不回 saved backend，属于典型“把恢复留给 `TearDown`”的旧形状
- 本轮修法因此分成两类：
  - 对 4 条 AVX512 tests，直接删掉 inner `finally ResetToAutomaticBackend`，只保留外层 `RestoreDispatchApiLocalState(...)`
  - 对 hook 多订阅测试，保留中途 `ResetToAutomaticBackend` 作为测试主题步骤，把 finally 改成 `RemoveDispatchChangedHook(...)` 后接 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`
- 这批修法的价值在于把“测试主题动作”和“退出态 cleanup”重新拆开：
  - AVX512 tests 不再重复做两层 method-exit backend reset
  - hook 测试也不再在 finally 里停留在 automatic，而是回到类级保存态
  - 变化仍然只在测试层 cleanup 契约，不触碰 SIMD/AVX512 生产实现或 hook 语义
- Release `TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿，说明这批既没有影响 AVX512 parity/contract 语义，也没有影响 dispatch hook 行为。

## 2026-05-14 IEEE754 EdgeCases Restore Alignment Findings

- 继续把搜索面扩到 `ieee754` 后，最稳的一批残点集中在 `TTestCase_IEEE754EdgeCases` 的 3 条 edge-case tests：
  - `Test_F32x4_RoundTrunc_NaNInf_Scalar`
  - `Test_F32x4_RoundTrunc_NaNInf_SSE2`
  - `Test_Wide_RoundTrunc_NaNInf_Scalar`
- 这 3 条的共同点很明确：
  - 都属于同一个已经具备 `FSavedVectorAsm`、`FSavedBackend` 和 `RestoreIEEE754LocalState(...)` 的 stateful testcase
  - 但退出态仍然沿用旧样板：要么只做 `ResetToAutomaticBackend`，要么手写 `SetVectorAsmEnabled(oldVectorAsm); ResetToAutomaticBackend`
  - 它们和同文件前面已经收过的 helper-based restore 形状继续分叉
- 这批与同文件其它 `ResetToAutomaticBackend` 命中的边界也需要说明：
  - 非 x86 property/loop tests 里的 inner `ResetToAutomaticBackend` 更像 iteration-level control-plane 隔离
  - 那些路径不只是 method-exit cleanup，贸然删改容易把“每轮回到 automatic 再切下一个 backend”的测试编排语义一起动掉
  - 所以这轮只收最纯粹的 method-exit old-shape finally，不扩到 loop 内 reset
- 本轮修法因此保持最小：
  - `F32x4 ... Scalar` 与 `Wide ... Scalar` 的 finally 统一改成 `AssertTrue(..., RestoreIEEE754LocalState(FSavedVectorAsm, FSavedBackend))`
  - `F32x4 ... SSE2` 的 finally 改成 `AssertTrue(..., RestoreIEEE754LocalState(oldVectorAsm, FSavedBackend))`
  - 没有改断言体、没有改 backend 选择步骤，也没有改 SSE2 / scalar 的被测语义
- 这批修法的价值在于：
  - `ieee754.edgecases` 中最明显的 method-exit old-shape finally 又少了一层
  - 同一个 testcase 文件内的 cleanup 形状重新向现成 helper 对齐
  - 仍然只是测试层 fixture hardening / redundancy cleanup，不触碰 IEEE754 实现逻辑
- Release `TTestCase_IEEE754EdgeCases`、Release `check`、Release `gate` 全绿，说明这批只是在 edge-case tests 的退出态恢复上收口，没有引入 IEEE754 行为回归。

## 2026-05-14 Scalar Backend Fixture Base-Class Consolidation Findings

- 继续从“method-exit cleanup”往外一层看时，simd 测试目录里还留着一类更粗粒度的冗余：多个小 testcase 文件各自复制了一整套 scalar backend fixture。
- 当前最适合先收的 6 份是：
  - `fafafa.core.simd.vecf32x8.testcase`
  - `fafafa.core.simd.veci32x8.testcase`
  - `fafafa.core.simd.vecu32x8.testcase`
  - `fafafa.core.simd.narrowintegerops.testcase`
  - `fafafa.core.simd.vecf64x4.testcase`
  - `fafafa.core.simd.saturating.testcase`
- 它们的共同点很明确：
  - testcase 都直接继承 `TTestCase`
  - 都自己声明 `FSavedBackend`
  - 都重复写 `GetDispatchTable; FSavedBackend := GetCurrentBackend; ForceBackend(sbScalar);`
  - 以及配套的 `ResetBackendSelection; TrySetActiveBackend(FSavedBackend); AssertTrue(...)`
- 仓内其实已经有现成、等价的统一基类：
  - `fafafa.core.simd.testcase`
  - `TSimdBackendStatefulTestCase`
  - `TScalarBackendStatefulTestCase`
  - 其中 `TScalarBackendStatefulTestCase` 正是“保存当前 backend + 强制 scalar + 退出时恢复 saved backend”的标准契约
- 因而这批冗余的正确修法不是再造 helper，也不是继续复制 `SetUp/TearDown`，而是让这些 testcase 直接继承 `TScalarBackendStatefulTestCase`。
- 这批里还验证到一个容易误判的依赖事实：
  - `vecf32x8` 与 `vecf64x4` 不只是“需要 scalar backend 被注册”
  - 它们的测试体里还显式调用 `ScalarSplatF32x8/ScalarDotF32x8`、`ScalarClampF64x4/ScalarRoundF64x4/ScalarDotF64x4` 等 helper 作为期望值来源
  - 所以把 fixture 收回基类之后，不能顺手把 `fafafa.core.simd.scalar` 都删光；至少这两份文件还要继续 `uses` 该 unit
- 相反，其余几份当前没有显式 `Scalar*` helper 依赖，说明“是否能删掉 `scalar/dispatch` uses”必须按文件内真实符号引用判断，而不是按“已经改继承基类”一刀切。
- 这批修法的价值在于：
  - simd 测试层“文件级 backend fixture 重复实现”显著收缩
  - backend 保存/恢复契约进一步集中到一处基类实现
  - 同时没有碰生产实现、没有改变 suite/runner 结构，也没有机械误改带额外清理语义的复杂 testcase
- Release 定向 suites、Release `check`、Release `gate` 全绿，说明这次基类收敛只是在测试夹具层去冗余，没有改变向量测试的行为期望。

## 2026-05-14 Vec512 Mask Guard Fixture Consolidation Findings

- `vec512types` 文件里有两类 testcase：
  - `TTestCase_Vec512Types`：普通类型/算术 smoke，不需要 backend-stateful fixture
  - `TTestCase_Vec512MaskFacadeGuards`：固定 `sbScalar` 的 façade direct guard，正好重复了一整套 scalar backend fixture
- `TTestCase_Vec512MaskFacadeGuards` 的旧形状与前一批 6 个 pure scalar testcase 本质相同：
  - 直接继承 `TTestCase`
  - 自带 `FSavedBackend`
  - `SetUp` 里 `GetDispatchTable; FSavedBackend := GetCurrentBackend; ForceBackend(sbScalar);`
  - `TearDown` 里 `ResetBackendSelection; TrySetActiveBackend(FSavedBackend); AssertTrue(...)`
- 这说明 `vec512types` 不是“整文件都该统一改基类”，而是只该收其中真正 stateful 的那个 guard suite；这一点很关键，避免把普通类型测试也强行绑到 backend-stateful lifecycle。
- 这条线也再次验证了一个经验：
  - “是否能切到 `TScalarBackendStatefulTestCase`”要按 testcase 级别判断
  - 而不是按文件名或模块主题判断
  - 同一文件里完全可以同时存在无状态 smoke suite 和需要统一 scalar fixture 的 guard suite
- 本轮修法因此保持单点最小：
  - 只把 `TTestCase_Vec512MaskFacadeGuards` 改成继承 `TScalarBackendStatefulTestCase`
  - 文件新增 `fafafa.core.simd.testcase`
  - 删除本地重复的 `FSavedBackend/SetUp/TearDown`
  - 顺手拿掉仅被旧夹具使用的 `fafafa.core.simd.dispatch`
- 这批修法的价值在于：
  - `vec512` façade direct guard 不再自带一份重复 backend fixture
  - 同时保住了 `vec512types` 文件内“stateful guard / stateless smoke”这条边界
  - 也为后续审 `edgecases/imageproc` 这种复杂 fixture 文件提供了反例：不是所有剩余 stateful testcase 都能像这批这样机械切基类
- Release `TTestCase_Vec512MaskFacadeGuards`、Release `check`、Release `gate` 全绿，说明这次仍然只是测试夹具层去冗余，没有改变 vec512 mask façade guard 的行为期望。

## 2026-05-14 EdgeCases And ImageProc Fixture Consolidation Findings

- `edgecases` 和 `imageproc` 这两份文件证明了一类比 pure scalar fixture 更细的情况：
  - backend 保存/恢复是重复的
  - 但 testcase 自己还挂着额外的生命周期状态
  - 所以不能简单地用“要么原样保留、要么整套删掉”来处理
- `edgecases` 的真实结构是：
  - 旧样板里既有 `FSavedBackend`，又有 `FSavedExceptionMask`
  - backend 生命周期只是为 `ForceBackend(sbScalar)` 服务
  - 真正 testcase 特有的是 `GetExceptionMask / SetExceptionMask(...)`
  - 而且当前顺序要求仍然是：先保存 backend，再保存/修改 FPU mask，再 `ForceBackend(sbScalar)`
- 因此 `edgecases` 最合适的落点不是 `TScalarBackendStatefulTestCase`，而是 `TSimdBackendStatefulTestCase`：
  - 让公共基类接管 backend save/restore
  - 本地继续保留 `ForceBackend(sbScalar)`，同时保住 FPU mask 的设置顺序
  - 这样既减少重复，又不把 FPU 语义顺序悄悄改乱
- `imageproc` 则是另一种形状：
  - backend lifecycle 完全是标准的 fixed `sbScalar`
  - testcase 自己真正特有的是 image zero-init、blend alpha mode 保存/恢复，以及 `FreeImage(FSrc1/FSrc2/FDest)`
  - 所以它正好适合直接切到 `TScalarBackendStatefulTestCase`
  - 然后把本地生命周期缩到“image/blend 专属清理”
- 这批修法还有一个额外信号：
  - 两个文件里的 `fafafa.core.simd.dispatch` 都只是给旧 backend fixture 用的
  - 一旦把 backend 保存/恢复收回公共基类，这个依赖就自然消失
  - 说明有些 `uses` 冗余其实是 fixture 冗余的伴生物，不需要单独再开一轮“清理 unused units”
- 这批修法的价值在于：
  - 复杂 stateful testcase 也能做“部分 fixture 去重”
  - 去重颗粒度可以细到“只抽 backend 生命周期，保留本地专属状态”
  - 这为继续审 `direct/dataplane/runtime/sse2contracts` 提供了方法论：先拆清哪些状态是通用 backend fixture，哪些才是 testcase 专属语义
- Release `TTestCase_EdgeCases,TTestCase_ImageProc`、Release `check`、Release `gate` 全绿，说明这批仍然只是测试夹具层去冗余，没有破坏 FPU edge-case 和 imageproc 行为期望。

## 2026-05-14 DataPlane And SSE2Contracts Fixture Consolidation Findings

- `dataplane` 和 `sse2contracts` 又展示出一类不同于 pure scalar fixture、但也没复杂到必须引入专门 vector-asm 基类的 testcase：
  - 它们确实自带 backend save/restore
  - 也确实自带 `vector-asm` 开关 save/restore
  - 但并不需要 `RefreshVectorAsmBackendRegistration` 这类更重的专属生命周期
- 两个文件的旧形状都很接近：
  - testcase 直接继承 `TTestCase`
  - 本地同时声明 `FOldBackend` 与 `FOldVectorAsm`
  - `SetUp` 里重复 `GetDispatchTable; FOldVectorAsm := IsVectorAsmEnabled; FOldBackend := GetCurrentBackend`
  - `TearDown` 里手写 `SetVectorAsmEnabled(...) + ResetToAutomaticBackend/TrySetActiveBackend + AssertTrue(...)`
- 这批复核确认了最关键的结构事实：
  - 仓内现成 `TSimdBackendStatefulTestCase` 已经完整承接 backend 生命周期
  - `TSimdVectorAsmBackendStatefulTestCase` 虽然更“全”，但它受 `UNIX + CPUX86_64` 条件存在，并要求 testcase 提供 `RefreshVectorAsmBackendRegistration`
  - 对 `dataplane/sse2contracts` 这种“只需保留一个 `vector-asm` 布尔状态”的文件来说，直接套这个更重的基类反而会把平台条件和额外 contract 带进来
- 因而这批 testcase 的正确收法不是“继续保留整套旧样板”，也不是“机械切到 vector-asm 基类”，而是：
  - 让类级 backend 生命周期回到 `TSimdBackendStatefulTestCase`
  - 本地只保留 `FOldVectorAsm`
  - `TearDown` 先恢复 `vector-asm`，再 `inherited TearDown` 恢复 backend，最后断言 `IsVectorAsmEnabled = FOldVectorAsm`
- `dataplane` 里还暴露了一个细节风险点：
  - 文件内部有一条方法级 local restore 之前仍调用 `RestoreDataPlaneLocalState(LOldVectorAsm, FOldBackend)`
  - 一旦类级 `FOldBackend` 被删掉，这种调用必须同步切到 `FSavedBackend`
  - 否则 testcase 会悄悄变成“fixture 已改基类，但方法级 cleanup 仍偷吃旧字段”的半收口状态
- 这批修法的价值在于：
  - simd 测试层的 stateful fixture 又少了一类重复 backend 样板
  - 同时保住了 `vector-asm` 这部分 testcase 专属语义，不把它硬塞进更重、更窄条件的通用基类
  - 也给下一轮继续审 `concurrent/direct/dispatchslots` 提供了更清晰的判别规则：先分清 backend 生命周期、vector-asm 状态和 testcase 专属 hook/rebind 语义分别属于哪一层
- Release `TTestCase_SSE2Contracts,TTestCase_DataPlane`、Release `check`、Release `gate` 全绿，说明这批仍然只是测试夹具层去冗余，没有改变 dataplane 或 SSE2 contract 的被测行为。

## 2026-05-14 Concurrent And Direct Stateful Base Consolidation Findings

- `concurrent` 与 `direct` 进一步暴露出另一层测试冗余：
  - 它们不是单个 testcase 重复 `SetUp/TearDown`
  - 而是各自先造了一层本地 stateful 基类
  - 然后这层本地基类里又重复了一遍仓内已有的 backend 生命周期
- 两份文件的共同点很明确：
  - 都自带 `FSavedBackend + FSavedVectorAsm`
  - `SetUp` 里重复 `GetDispatchTable; ... := GetCurrentBackend`
  - `TearDown` 里重复 `ResetToAutomaticBackend/TrySetActiveBackend`
  - 而仓内现成 `TSimdBackendStatefulTestCase` 已经把这套 backend save/restore 契约固定好了
- 但它们与 `dataplane/sse2contracts` 也有一个关键差异：
  - `concurrent` 仍需要方法级 `RestoreSimdLocalState(...)` 帮助测试在中途恢复 local control-plane
  - `direct` 的 fixture restore 和大量方法级 cleanup 还需要 `RebindDirectDispatch`
  - 所以正确收法不是删除本地基类，而是让本地基类只保留 testcase 专属状态与动作，把 backend 生命周期回收到公共基类
- 因而这批最合适的落点是：
  - `TSimdStatefulTestCase = class(TSimdBackendStatefulTestCase)`
  - `TDirectDispatchStatefulTestCase = class(TSimdBackendStatefulTestCase)`
  - 两者本地只再维护 `FSavedVectorAsm`
  - `concurrent` 在 `TearDown` 里先恢复 vector-asm，再交给 inherited restore backend，最后断言 vector-asm 已回到进入态
  - `direct` 同样先恢复 vector-asm，再交给 inherited restore backend，之后补 `RebindDirectDispatch`
- 这批复核也顺便确认了一个重要的停止点：
  - `dispatchslots` 虽然表面也有保存/恢复 backend 的重复体
  - 但它保存的是 `GetActiveBackend`，而公共基类保存的是 `GetCurrentBackend`
  - 在没先核实 active/current 是否对这个 suite 完全等价前，不能为了“继续去重”就直接套基类
- 这批修法的价值在于：
  - simd 测试层的冗余不只在 testcase 级别，连文件内自建 stateful 基类也开始向统一 backend lifecycle 收口
  - 同时把 `concurrent/direct` 的 testcase 专属语义完整留下：前者保留方法级 restore helper，后者保留 direct dispatch rebind
  - 也为后续 `dispatchslots` 的只读审查建立了清晰前提：先判定 active/current 语义，再决定是否值得收公共基类
- Release `TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_SimdConcurrentRegistration,TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿，说明这批仍然只是测试夹具层去冗余，没有改变并发回归或 direct dispatch 的被测语义。

## 2026-05-14 DispatchSlots Backend Fixture Consolidation Findings

- `dispatchslots` 之前之所以一直没动，不是因为它没冗余，而是因为它带着一条必须先核实的语义前提：
  - suite 保存/恢复的是 `GetActiveBackend`
  - 公共基类保存/恢复的是 `GetCurrentBackend`
  - 如果这两者在这份 suite 的 truth source 上不完全等价，直接套基类就会把测试主题偷换掉
- 这轮只读复核把这个前提补实了：
  - `GetActiveBackend` 在 `dispatch.pas` 里直接读取当前 published dispatch table 的 `Backend`
  - `runtime.pas` 的 `BuildSimdRuntimePublishedState` 在 `LDispatch <> nil` 时也是 `Snapshot.CurrentBackend := LDispatch^.Backend`
  - 换句话说，当前实现里 `CurrentBackend` 与 `ActiveBackend` 最终都锚在同一个 published dispatch backend truth 上
- 这就把 `dispatchslots` 分成了两层：
  - 类级 fixture 只是保存/恢复“当前 backend 是谁”
  - suite 内部真正要断言的仍然是 raw dispatch-level 语义：`GetActiveBackend`、`TrySetActiveBackend`、`ResetToAutomaticBackend`
- 因而这批的正确修法是：
  - 只把类级 fixture 收回 `TSimdBackendStatefulTestCase`
  - 删除本地 `FSavedBackend/SetUp/TearDown`
  - 继续保留 `RestoreDispatchSlotsLocalState(...)`
  - 继续保留测试体里所有 `GetActiveBackend` 相关断言，不把它们改成 façade/runtime 名称
- 这批修法的价值在于：
  - 把最后一个“因为 active/current 语义不明而暂缓”的 raw dispatch slot suite 也安全纳入统一 backend lifecycle
  - 同时证明这轮工作不是机械替换，而是先补足语义证据，再决定哪些层能抽、哪些层必须保留
  - 也让后续继续审余下 testcase 时有了更清晰的方法：只要先找到真正的 published truth source，就能判断公共基类是否适配
- Release `TTestCase_DispatchAllSlots`、Release `check`、Release `gate` 全绿，说明这批仍然只是测试夹具层去冗余，没有改变 dispatch slot 合同或 backend adapter 的被测语义。

## 2026-05-14 PublicAbi And DispatchApi Fixture Consolidation Findings

- `publicabi` 和 `dispatchapi` 是这条线上最需要谨慎的一批，因为它们不只是“大文件”，更是 hook-heavy / rollback-heavy 的 control-plane 回归面。
- 这也是为什么这批之前虽然明显有冗余，但一直没急着动：
  - 两边都自带 `FSavedBackend + FSavedVectorAsm`
  - 两边都还有大量方法级 restore helper
  - `publicabi` 还有额外的 synthetic hook state reset
  - 如果没分清“类级 fixture”和“方法级控制面语义”两层，机械替换很容易把 hook/rollback 测试主题一起改坏
- 这轮复核后确认，它们的类级基类其实仍然和前几批同构：
  - `SetUp` 里重复 `GetDispatchTable; FSavedBackend := GetCurrentBackend`
  - `TearDown` 里重复 backend restore
  - 真正 testcase 专属的类级剩余状态都只剩 `vector-asm`
- 因而这批最合适的收法不是删 helper，也不是改测试体，而是：
  - 让 `publicabi/dispatchapi` 的类级 lifecycle 都回到 `TSimdBackendStatefulTestCase`
  - 本地只继续维护 `FSavedVectorAsm`
  - 方法级 `RestorePublicAbiLocalState(...)` / `RestoreDispatchApiLocalState(...)` 全部保留原样
  - `publicabi` 继续在 `TearDown` 最前面先 `ResetPublicAbiSyntheticHookState`，确保恢复 backend 前不会残留 hook side effect
- 这批修法的价值在于：
  - 我们现在已经验证，哪怕是最复杂的 hook-heavy suite，也可以把“类级 backend lifecycle”和“测试主题控制面语义”拆开处理
  - 这说明之前的去重不是只适合轻量 smoke/guard suite，而是已经覆盖到 simd 测试层的核心 control-plane 回归面
  - 同时也给后续 `ieee754` 留下了一个清晰标准：先分清 exception mask / vector-asm / backend 三种状态分别属于哪一层，再决定哪些能收进公共基类
- Release `TTestCase_PublicAbi,TTestCase_DispatchAPI`、Release `check`、Release `gate` 全绿，说明这批仍然只是测试夹具层去冗余，没有改变 public ABI / dispatch API 的被测 hook、rollback 或 publication 语义。

## 2026-05-14 IEEE754 Fixture Consolidation Findings

- `ieee754` 是这条线上另一块必须谨慎处理的区域，因为它的 testcase 不只是保存 backend，还夹带 IEEE754 专属状态：
  - `TFPUExceptionMask`
  - `vector-asm` 切换
  - `F64` suite 里的 class-level scalar force
- 这也意味着它不适合“看见 `FSavedBackend` 就机械切到 `TScalarBackendStatefulTestCase`”。
- 这轮复核后确认，更稳的拆法是：
  - backend lifecycle 是公共的
  - exception mask 是 IEEE754 testcase 专属的
  - `F64` 的 `SetActiveBackend(sbScalar)` 是 suite 语义，不是单纯 fixture 噪音
  - `RestoreIEEE754LocalState(...)` 则仍是大量方法级 local restore 的公共 helper，不能顺手删
- 因而这批最合适的收法是：
  - 4 个 IEEE754 testcase 全部改继承 `TSimdBackendStatefulTestCase`
  - 只删除类级 `FSavedBackend + GetDispatchTable/GetCurrentBackend` 重复体
  - 保留 `FSavedVectorAsm`、`FSavedExceptionMask` 和 `F64` 里的 scalar force
  - 让 `TearDown` 统一先恢复 vector-asm，再交给 inherited restore backend，然后再恢复 exception mask（如有）
- 这批修法的价值在于：
  - IEEE754 这种“状态比普通 backend fixture 更复杂”的 suite 也被成功拆成了“公共 backend 生命周期 + 本地数值测试语义”
  - 进一步证明当前 cleanup 线已经覆盖到了 simd 测试层最容易误伤的几个主题区：control-plane hook、dispatch slot、IEEE754
  - 也为最后的全量复扫提供了更清晰标准：不是看文件大小或主题，而是逐个拆出 backend / vector-asm / exception-mask / testcase 语义四层
- Release `TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`、Release `check`、Release `gate` 全绿，说明这批仍然只是测试夹具层去冗余，没有改变 IEEE754 行为测试的被测语义。

## 2026-05-14 Restore-State Helper Consolidation Findings

- 当前 `simd` 测试层去冗余已经推进到一个更细的阶段：
  - 类级 backend fixture 大片重复体已经被前几批连续压下去
  - 但多个 testcase 文件里还各自留着完全同构的 “`vector-asm + backend` local restore” helper
  - 如果继续让这些 helper 各自复制实现，后面改 restore 契约时就又会回到多点同步
- 这轮复核后确认，更稳的抽象点不是再造一个新 testcase 基类，而是只上提那段真正完全同构的 restore 体：
  - `SetVectorAsmEnabled(aOriginalVectorAsm)`
  - `ResetToAutomaticBackend`
  - `if GetCurrentBackend = aOriginalBackend then Exit(True)`
  - `Result := TrySetActiveBackend(aOriginalBackend)`
- 这批涉及的 testcase 文件虽然主题不同，但 helper 体已经足够同构：
  - `dataplane`
  - `publicabi`
  - `dispatchapi`
  - `concurrent`
  - `ieee754`
- 同时也确认了必须保留的本地层：
  - `publicabi / dispatchapi / concurrent` 的 restore 调用点还带着 suite 专属断言和 control-plane 语义
  - `ieee754` 的 helper 名称本身仍服务大量数值测试编排，可读性比“全部直接调公共 helper”更重要
  - 所以正确收法是“共享实现 + 保留本地语义壳”，而不是把所有 helper 名称都删光
- 这批修法的价值在于：
  - backend lifecycle 冗余之外，连 method-level local restore 这层也开始有统一 truth source
  - 未来若需要调整 restore 契约，只需改公共 testcase helper，不必再跨多个 suite 同步复制体
  - 同时又没有把 suite 专属断言、hook rollback 或 IEEE754 语义包装抹平
- Release `check` 与 Release `gate` 全绿，说明这批仍然只是测试 helper 层去冗余，没有改变 `DataPlane / PublicAbi / DispatchAPI / Concurrent / IEEE754` 的被测行为。

## 2026-05-14 Backend-Only Restore Helper Consolidation Findings

- 继续往下复扫后，`simd` 测试层剩余 restore helper 可以明显分成两类：
  - backend-only restore
  - control-plane aware restore
- `runtime.testcase` 属于第二类，而不是遗漏的普通样板：
  - 它在 finally 里根据 `original backend` 与 `best dispatchable backend` 的关系，决定是 `ResetCurrentBackendSelection` 还是 `TrySetCurrentBackend(...)`
  - 这不是单纯恢复 backend 值，而是在保留“automatic vs forced”这层 control-plane 语义
  - 因此当前把它留在本地是对的，不能为了去重硬套通用 restore helper
- 真正还能继续统一的是 backend-only restore 这层：
  - `RestoreBackendVectorConsistencyLocalState(...)`
  - `dispatchslots` 里的 `RestoreDispatchSlotsLocalState(...)`
  - 它们都共享同一段 `ResetToAutomaticBackend -> TrySetActiveBackend(...)` 主体
- 这轮最稳的抽象点因此是新加一个 backend-only 公共 helper，而不是继续拉高 testcase 基类：
  - `RestoreSavedBackendState(aOriginalBackend): Boolean`
  - `RestoreSavedBackendAndVectorAsmState(...)` 也顺势复用它
  - `dispatchslots` 保留本地壳，继续追加 `GetActiveBackend = aOriginalBackend`，这样 raw dispatch 语义仍然显式可见
- 这批修法的价值在于：
  - restore helper 的统一不再只覆盖 `vector-asm + backend` 组合态，也开始覆盖 backend-only 这条线
  - 同时把 `runtime` 这种“看起来像 restore，实际上是 control-plane 语义测试”的文件明确排除出当前去重目标，减少后续误动风险
  - 下一轮若继续深挖，最值得评估的是 `backend.consistency.testcase` 的 standalone helper 是否还能在不制造单元循环的前提下继续减薄
- Release `TTestCase_DispatchAllSlots,TTestCase_BackendVectorConsistency`、Release `check`、Release `gate` 全绿，说明这批仍然只是测试 helper 层去冗余，没有改变 dispatch slot 或 backend consistency 的被测语义。

## 2026-05-14 PublicAbi Active-Backend Restore Helper Findings

- 在 backend-only restore helper 已经开始统一之后，`publicabi` 里还残留着一条非常典型的本地复制体：
  - `RestoreOriginalActiveBackend(...)`
- 这条 helper 和 `runtime.testcase` 的 finally 不同：
  - 它不需要区分 automatic / forced backend 的恢复策略
  - 也不承担 vector-asm、synthetic hook state 或 publication lifecycle 的恢复职责
  - 它只是一个普通的 backend-only restore 壳
- 因而这轮最稳的处理方式不是删除 helper 名称，而是：
  - 保留 `RestoreOriginalActiveBackend(...)`，让 `publicabi` 调用点继续读起来像“恢复 original active backend”
  - 只把实现收回到公共的 `RestoreSavedBackendState(...)`
- 这批修法的价值在于：
  - backend-only restore helper 的统一不再只覆盖 `dispatchslots` / `backend consistency`
  - 连 `publicabi` 里语义上更贴近调用点命名的本地 helper，也能保留壳、统一实现
  - 说明当前这条 cleanup 线已经开始从“大块 fixture 去重”进入“保留领域语义名、抽掉实现复制体”的更细粒度阶段
- Release `TTestCase_PublicAbi`、Release `check`、Release `gate` 全绿，说明这批仍然只是测试 helper 层去冗余，没有改变 public ABI 的被测 active-backend / hook / restore 语义。

## 2026-05-14 Shared Fixture Helper Unit Findings

- `backend.consistency.testcase` 之前之所以一直保留本地 save/restore helper，不是因为它有更特殊的语义，而是因为依赖方向：
  - `testcase.pas` 反向 `uses` `backend.consistency.testcase`
  - 所以它不能直接依赖 `testcase.pas` 里的公共 helper，否则会形成循环
- 这说明当前剩余的一块结构性冗余，根因已经从“没人整理”变成了“helper 所在单元位置不对”。
- 最合适的修法因此不是继续复制 wrapper，也不是把 `backend.consistency` 强塞进 `testcase`，而是抽一个只负责 fixture state 的 test-only 共享单元：
  - `fafafa.core.simd.fixturehelpers`
  - 只承载 backend/vector-asm state helper
  - 不承载 fpcunit testcase、suite 注册或业务断言
- 这批抽取后的结构更清楚了：
  - `fixturehelpers`：稳定共享的底层状态 helper
  - `testcase.pas`：公共 testcase 基类 + 面向现有 suite 的兼容 wrapper
  - `backend.consistency.testcase.pas`：保留自身的 active-backend 校验和异常语义，但不再复制底层 helper 主体
- 这批修法的价值在于：
  - 真正解除了一条由单元循环造成的 helper 孤岛
  - 让后续再审 `backend.consistency` 时，焦点可以回到测试语义本身，而不是继续被组织结构卡住
  - 也证明当前 `simd` 测试层已经可以从“局部 fixture 去重”进一步上升到“共享 test-only 基础设施整理”
- Release 定向大覆盖 suites、Release `check`、Release `gate` 全绿，说明这批仍然只是测试 helper/组织结构层去冗余，没有改变 `backend consistency / dispatchslots / publicabi / dataplane / dispatchapi / concurrent / ieee754` 的被测行为。

## 2026-05-14 Direct Dispatch Fixture Restore Findings

- 在 `fixturehelpers` 抽出来之后，`direct.testcase` 里还留着一块很典型的“共享主体 + 局部动作”组合体：
  - `RestoreFixtureDirectDispatchState`
- 这条 helper 的分层已经很清楚：
  - backend/vector-asm restore 主体现在和别处一样，属于共享 fixture 基础设施
  - `RebindDirectDispatch` 则是 direct surface 自己的局部语义，不能被抽平
- 因而这轮最稳的收法不是删 helper，也不是把 `RebindDirectDispatch` 塞进共享层，而是：
  - 保留 `RestoreFixtureDirectDispatchState` 名称
  - 让它内部先调用 `RestoreSavedBackendAndVectorAsmState(...)`
  - 再执行 `RebindDirectDispatch`
  - 最后保留 direct 专属断言
- 这批修法的价值在于：
  - 它验证了当前 shared fixture helper 体系已经足够稳定，连 direct 这种“共享 restore + 局部 rebind”的测试面也可以安全复用
  - 同时也给后续 completion audit 一个更清楚的信号：如果某个本地 helper 仍保留，那应该是因为它真的有 surface-specific 语义，而不是因为共享层还不够完整
- Release `TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、Release `check`、Release `gate` 全绿，说明这批仍然只是测试 helper 层去冗余，没有改变 direct dispatch 的被测 rebind / parity / concurrent 语义。

## 2026-05-14 Freeze Closeout Findings

- 当前 helper cleanup 线已经不是发布收口的真实阻塞面。
- 最新 release 证据复核后，Linux 侧已经补回完整 closeout 语义：
  - `gate_summary.md` 现在存在 terminal `gate | PASS | all steps passed`
  - `qemu-cpuinfo-nonx86-evidence` 在同一轮 gate 中 PASS
  - `linux/arm/v7`、`linux/arm64`、`linux/riscv64` 的 `cpuinfo-nonx86-evidence` summary 全部 PASS
  - `freeze-status` 对 Linux 的 `gate_summary / required steps / qemu platform coverage / freshness / source-newer-than-gate` 已全部转绿
- 这说明此前的 `linux_gate_summary` 红灯不是 gate/freeze 规则错误，而是那次 cross gate 没真正收口到 terminal row。

- 现在 `freeze-status` 剩余的红项已纯化为 Windows evidence freshness：
  - `windows_evidence_freshness`
  - `linux_sources_not_newer_than_windows_evidence`
  - `windows_closeout_freshness`
- 本轮还继续验证了 Windows 刷新主线本身是通的：
  - `win-evidence-preflight` PASS
  - GH token / workflow scope 正常
  - 用临时远端分支 `simd-win-evidence-20260514-0cbc7204` 可以让 `win-evidence-via-gh` 精确指向当前 `HEAD`，避免误用落后的 `origin/main`

- 但最终阻塞已经明确不是仓库内代码，而是 GitHub Actions 外部计费状态：
  - workflow run `25860032794`
  - failure annotation: `The job was not started because recent account payments have failed or your spending limit needs to be increased.`
  - `run_windows_b07_closeout_via_github_actions.sh` 已把这类输出识别成 billing block，并以 `exit=31` fail-close
- 因而当前最真实的结论是：
  - `simd` 模块本地代码/测试链没有再暴露新的可修缺陷
  - Linux closeout 已恢复到最新源码
  - Windows freshness 仍未闭环，但原因是外部 runner/billing 不可用，而不是仓库内部还遗漏了更多 helper cleanup 或 gate 修复

## 2026-05-14 Single-Use Wrapper Cleanup Findings

- 在 Windows freshness 外部阻塞被坐实之后，继续回到 `tests/fafafa.core.simd` 做剩余冗余扫描，发现还有一小批比前面更细的 exact wrapper：
  - `dataplane.testcase` 的 `RestoreDataPlaneLocalState(...)`
  - `publicabi.testcase` 的 `RestoreOriginalActiveBackend(...)`
  - `backend.consistency.testcase` 的 `SaveBackendConsistencyState(...)`
- 这 3 个点和之前保留的语义壳不同：
  - `RestoreDataPlaneLocalState(...)` 是单定义 + 单调用的完全直通 `RestoreSavedBackendAndVectorAsmState(...)`
  - `RestoreOriginalActiveBackend(...)` 也是单定义 + 单调用的完全直通 `RestoreSavedBackendState(...)`
  - `SaveBackendConsistencyState(...)` 只是把 `SaveActiveBackendState(...)` 换了个名字，没有附加任何本地约束或断言
- 因而这轮最稳的修法不是再发明新 helper，而是直接删掉这些 exact pass-through 壳：
  - `dataplane` 直接调用共享 restore helper
  - `publicabi` 直接调用共享 backend-only restore helper
  - `backend.consistency` 的 7 处入口保存直接改用 `SaveActiveBackendState(...)`
- 同时保留的边界也很明确：
  - `backend.consistency` 的 `RestoreBackendConsistencyState(...)` 继续保留，因为它追加了 `GetActiveBackend = saved backend` 的本地断言，这是 suite-specific 语义，不是纯复制体
  - `ieee754` 这轮扫到的几条 inner `ResetToAutomaticBackend` 更像 per-backend 迭代流程，不属于安全的机械删改目标，所以本轮没有误动
- Release 定向 suite、Release `check`、Release `gate` 全绿，说明这批继续只是在测试层移除单次转发 wrapper，没有改变 dataplane/public ABI/backend consistency 的被测行为。

## 2026-05-14 Freeze Snapshot Fallback Findings

- `freeze-status` 当前有一条真实的 closeout 易碎点：
  - `BuildOrTest.sh gate` 默认会 `reset_gate_summary`
  - 也就是说，fresh cross gate 之后再跑一轮普通 fast gate，canonical `tests/fafafa.core.simd/logs/gate_summary.md` 会直接被后者覆盖
  - 旧版 `evaluate_simd_freeze_status.py` 又只消费这一份 canonical 摘要，因此会把 `qemu-cpuinfo-nonx86-evidence` / `evidence-verify` 这类 closeout 证据错判回缺失
- 这个问题本质上不是“release 语义要不要放松”，而是：
  - `freeze-status` 需要找到“最近一份仍然代表当前源码的 closeout gate 摘要”
  - 同时又不能拿旧快照掩盖一个真正更新、更差的基础 gate 回归
- 因而最稳的选择规则应当是：
  - 如果最新 gate 连基础步骤（`REQUIRED_GATE_STEPS_BASE`）都没通过，必须直接 fail-close，不能回退旧 snapshot
  - 只有当最新 gate 的基础步骤仍绿，缺的只是 closeout 附加证据步骤时，才允许回退到最近一份满足当前 freeze 约束的 closeout snapshot
- 这条规则能精确覆盖当前真实痛点：
  - “后来又跑了一次普通 fast gate，只是没再附带 qemu/windows 证据” -> 允许 fallback
  - “后来跑出来的是新的 build / wiring / cpuinfo 基础回归” -> 不允许 fallback，继续红
- 另一个结构性缺口是 batch snapshot 保留不稳定：
  - `logs/windows-closeout/<batch-id>/` 里原本不总能稳定留住实际 freeze 使用的 `gate_summary.md`
  - 这会让 `freeze-status` 即使想 fallback，也不一定有可用快照
- 因而 closeout 脚本也需要同步修：
  - `run_windows_b07_closeout_finalize.sh` 应保留实际 freeze 使用的 `gate_summary.md/json`
  - 这样 batch 目录才能成为后续 `freeze-status` 的可靠历史输入，而不是只留 Windows log / closeout summary
- 新增的 `case_batch_fallback` rehearsal 已把这条策略直接锁住：
  - 最新 canonical gate 只保留基础 fast-gate 步骤
  - 早一轮 closeout snapshot 才包含 `qemu-cpuinfo-nonx86-evidence` + `evidence-verify`
  - 结果必须仍为 `ready=True`
  - 并且输出里明确出现 `selected fallback closeout gate snapshot ...`

## 2026-05-14 Shared VectorAsm Fixture Base Findings

- 当前 `simd` 测试层里，backend lifecycle 的大块重复体已经基本压完后，还剩一类更轻的重复体：
  - 只保存/恢复 `vector-asm` 状态
  - 不附带 backend re-registration
  - 也不附带 public ABI / direct / dispatchapi 那类 local restore 语义
- `dataplane.testcase` 与 `sse2contracts.testcase` 正好都落在这类：
  - 本地 `FOldVectorAsm`
  - `SetUp` 里读取 `IsVectorAsmEnabled`
  - `TearDown` 里恢复并断言
  - 除此之外没有额外 fixture 语义
- 现有 `TSimdVectorAsmBackendStatefulTestCase` 并不能直接代表这类轻量需求，因为它还承载了另一层更专门的语义：
  - `RefreshVectorAsmBackendRegistration`
  - 这层只对 `AVX2/AVX512 vectorasm` 专项合理
  - 如果让普通 suite 也继承它，会把“刷新 backend 注册表”错误提升成所有 vector-asm suite 的通用 contract
- 因而更优雅的结构不是继续复制 `FOldVectorAsm`，而是把层级拆开：
  - `TSimdVectorAsmStatefulTestCase`
    - 只负责 `IsVectorAsmEnabled` 的保存/恢复
  - `TSimdVectorAsmBackendStatefulTestCase`
    - 继承上述薄基类
    - 只在恢复阶段追加 `RefreshVectorAsmBackendRegistration`
- 这样做后，类层次的职责边界变得更干净：
  - 普通需要 vector-asm fixture 的 suite -> 继承薄基类
  - 真正需要“恢复状态后再刷新 backend 注册”的 suite -> 继承厚基类
- 这批修法的价值不只是少了两个 `FOldVectorAsm` 字段：
  - 它把当前 test infrastructure 里的一个“混合语义基类”拆成了基础层和专门层
  - 让后续 completion audit 更容易判断：某个 suite 如果还在 override `RestoreVectorAsmState`，那大概率就是真的有额外语义，而不是历史复制残留

## 2026-05-14 EdgeCases Scalar Fixture Alignment Findings

- `edgecases.testcase` 这一类 suite 的真实 fixture 语义已经很明确：
  - backend 必须固定为 `sbScalar`
  - 额外只需要屏蔽并恢复 FPU exception mask
  - 没有 vector-asm 状态、runtime snapshot、public ABI 文本缓存、dispatch rebind 一类额外生命周期
- 因而它继续继承 `TSimdBackendStatefulTestCase` 并在 `SetUp` 手动 `ForceBackend(sbScalar)`，属于“语义已经被公共基类表达，但 suite 还保留旧写法”的轻度冗余。
- 把它改成直接继承 `TScalarBackendStatefulTestCase` 的价值有两层：
  - 代码层：删掉重复 `ForceBackend(sbScalar)`，避免未来基类 fixture 行为变化时出现双重表达
  - 结构层：类继承关系本身就能传达“这是 scalar-only edge-case suite”，后续继续扫 testcase 时更容易识别异常点
- 这也进一步说明当前 `tests/fafafa.core.simd` 里剩余更值得继续抓的目标，不再是这种纯 scalar fixture 小残点，而应优先寻找：
  - 仍手写 backend/vector-asm 保存恢复且尚未下沉到公共基类的 suite
  - 或者保留 single-use wrapper，但其实不再附加 suite-specific 断言/编排语义的 helper

## 2026-05-14 Concurrent Fixture Base Alignment Findings

- `concurrent.testcase` 证明当前 SIMD 测试层还残留一类“基类已经抽出来，但 suite 还没回接”的尾部冗余：
  - `TSimdVectorAsmStatefulTestCase` 已经提供 `backend + vector-asm` 的标准 fixture 生命周期
  - `TSimdStatefulTestCase` 却还保留一份完全同构的 `FSavedVectorAsm + SetUp/TearDown`
- 这类冗余和前面的 `edgecases` 有一个共同点：
  - 不在被测逻辑里
  - 不在断言矩阵里
  - 而是在测试 infrastructure 的“语义表达层”里继续重复已有公共 contract
- 把 `TSimdStatefulTestCase` 改挂到 `TSimdVectorAsmStatefulTestCase` 后，当前结构边界更清晰：
  - 公共基类负责统一 fixture 生命周期
  - `RestoreSimdLocalState(...)` 保留给并发 suite 的中途恢复断言
  - worker、hook、runtime/public ABI 并发读写路径完全不受影响
- 这也给下一轮 completion audit 一个更明确的筛选规则：
  - 如果某个 suite 的 `SetUp/TearDown` 只是在保存/恢复 `backend`、`vector-asm`、`scalar` 这些公共状态，那优先怀疑它应该对齐现有基类
  - 只有当本地 helper 还附加 rebind、hook reset、per-test backend choreography、exception-mask 等额外语义时，才值得继续保留自定义 fixture

## 2026-05-14 DispatchAPI Fixture Base Alignment Findings

- `dispatchapi.testcase` 进一步坐实了一个模式：
  - 当前剩余的 test-layer 冗余已经越来越像“suite-local lifecycle 壳没挂回公共基类”
  - 而不是“还缺新的共享 helper”
- `TDispatchAPIStatefulTestCase` 的本地 `FSavedVectorAsm + SetUp/TearDown` 与公共 `TSimdVectorAsmStatefulTestCase` 完全同构；保留价值只落在 `RestoreDispatchApiLocalState(...)` 上，因为它承载 suite-specific 的 backend-restore 断言。
- 这类点一旦对齐，收益不只是少代码：
  - fixture 语义会更一致
  - 以后公共 `vector-asm` 生命周期如果再补断言或收口策略，`dispatchapi` 不会继续漂在旧壳上
  - completion audit 更容易把真正“有必要保留本地 fixture”的 suite 和历史残留区分开
- 目前已经可以把剩余候选按更清晰的风险等级分组：
  - 低风险继续清理：仅复制公共 lifecycle、但仍保留 suite-specific restore helper 的基类壳
  - 中风险暂缓：还附带 hook reset、rebind、FPU mask、per-test backend choreography 的本地 fixture
  - 高风险暂缓：直接嵌在 `ieee754` 等语义敏感 suite 里的 backend/vector-asm 切换流程

## 2026-05-14 PublicAbi Fixture Base Alignment Findings

- `publicabi.testcase` 进一步把“低风险可继续清理”的边界压实了：
  - 即使 suite 自己还带 hook reset 顺序，只要这个顺序能保持在 override 里
  - 公共的 `backend + vector-asm` 生命周期仍然应该回收给 `TSimdVectorAsmStatefulTestCase`
- 这也让剩余候选的判别标准更具体：
  - 如果本地 fixture 只是在公共生命周期前后加一层 reset/cleanup，而不改恢复主体，就仍可能是安全可收点
  - 如果本地 fixture 已经把 `restore` 主体和 suite-specific 行为缠在一起，例如 rebind 之后再断言、恢复时还要触发 hook、或者依赖异常 mask/舍入流程，那么就不该继续机械合并
- 到目前为止，`TSimdVectorAsmStatefulTestCase` 已经实际吸收了多个不同重量级入口，说明这个公共基类的抽象层次是对的，不再只是 `dataplane/sse2contracts` 的局部便利壳。
- 因而下一步最合理的策略不是盲目继续“搜 `FSavedVectorAsm` 然后全删”，而是：
  - 把 `direct`、`ieee754` 这类剩余候选当成中风险/高风险目标重新分类
  - 只在确认 suite-specific 额外语义和 restore 主体可分离时再下手

## 2026-05-14 Direct Fixture Base Alignment Findings

- `direct.testcase` 说明“中风险候选”里还可以继续再细分：
  - 如果额外语义只是 `restore` 之后再做一个 suite-local action，例如 `RebindDirectDispatch`
  - 而公共 `backend + vector-asm` restore 主体本身没有被改写
  - 那么它仍属于可安全下沉的范围
- 这类点和 `publicabi` 的差别在于：
  - `publicabi` 的额外语义是 reset hook state 的前后顺序
  - `direct` 的额外语义是 restore 之后 rebind direct table
  - 但两者都没有把公共 lifecycle 主体打散成不可分离的流程
- 因而现在剩余真正更高风险的，主要就集中在 `ieee754` 这种会同时混入：
  - exception mask
  - scalar forcing
  - non-x86 / AVX2 / rounding path 编排
  - 中途切换 vector-asm/backend 的 property-like 测试流程
- 这进一步支持下一步策略：
  - 停止只按 `FSavedVectorAsm` 搜索做机械清理
  - 对 `ieee754` 先做“可分离语义”梳理，再决定是否要抽本地专用基类

## 2026-05-14 IEEE754 Fixture Base Alignment Findings

- `ieee754.testcase` 最终证明确实不是“不能动”，而是“不能按前几批那样直接拿全局公共基类硬套”：
  - 它有自己专属的异常 mask 生命周期
  - `F64` 还多一层 scalar forcing
  - `NonX86IEEE754` 又只需要其中一半语义
- 因而这轮最稳的结构不是继续把规则塞回 `fafafa.core.simd.testcase.pas`，而是在 `ieee754.testcase.pas` 内部建立局部专用基类。
- 这条处理方式给后续审查一个更重要的判断标准：
  - 如果冗余已经跨进“领域专用 fixture contract”，优先考虑在该专题 testcase 文件内部抽局部基类
  - 只有当 contract 已经被多个独立专题共享时，才值得再往全局 testcase infrastructure 提升
- 这也意味着当前 `simd` 测试层的冗余治理已经进入更成熟的后期阶段：
  - 低风险：直接对齐全局公共基类
  - 中风险：保留 suite-specific post-restore action，再对齐公共 lifecycle
  - 高一点但可控：在专题 testcase 内抽局部专用基类
- 经过 `edgecases/concurrent/dispatchapi/publicabi/direct/ieee754` 这一串收口后，剩余更像“必要的 suite-specific fixture”，而不再是明显的历史重复壳。

## 2026-05-14 VectorAsm Backend Setup Sharing Findings

- `AVX2/AVX512 vectorasm` 两组 suite 证明，当前 test-layer 剩余冗余已经不再只藏在专题 testcase 文件里，也可能残留在共享 infrastructure 自己的 contract 边界上：
  - `TSimdVectorAsmBackendStatefulTestCase` 已经统一了承载 restore 期的 vector-asm/backend re-registration 语义
  - 但 setup 期的同一套 contract 还没有一起提升到基类
  - 于是 `TTestCase_AVX2VectorAsm` 与 `TTestCase_AVX512VectorAsm` 各自保留了完全同构的 `SetUp`
- 这轮对齐后，可以更清楚地定义这个基类的职责：
  - 共享层负责 `vector asm enabled + backend registration refresh + target backend force`
  - suite-specific 层只负责“目标 backend 是谁”和“如何注册该 backend”
- 这比继续把两份 `SetUp` 留在 suite 里更稳，因为：
  - 如果以后 `vectorasm` setup contract 再补断言或前置步骤，只需要改一处
  - `AVX2` / `AVX512` 不会再因为历史复制而悄悄漂出不同语义
  - 读者看到类层次就能理解：这是一个“backend-aware vectorasm fixture”，而不是两个各自维护 setup 协议的重型 suite
- 更重要的是，这批收口也给后续审查划出一个新的分水岭：
  - 明显的“共享 contract 未完全提升”型冗余基本已经扫平
  - 接下来继续深查 `simd`，重点应从“机械 fixture 去重”切换到“源码/测试/门禁层是否还有真正多余 truth source、局部 helper 漂移、或薄壳没有表达清楚语义”

## 2026-05-14 Fixture Helper Truth-Source Consolidation Findings

- `fafafa.core.simd.testcase` 里那两个 restore helper façade 暴露出一类比 suite-local fixture 更深的冗余：
  - 真实 helper 已经独立存在于 `fafafa.core.simd.fixturehelpers`
  - `testcase` 再包一层同名函数，只会制造“helper 真相源到底看哪里”的歧义
  - 调用者如果长期只依赖 `testcase`，后续很容易把“基类 contract”和“状态函数 helper”继续混成一个大入口
- 这批收掉之后，基础设施层次更清楚了：
  - `fixturehelpers` 负责共享 save/restore 语义
  - `testcase` 负责共享 suite 基类和 suite-level helper
  - 专题 testcase 负责各自的 restore 断言、hook reset、rebind、exception mask 等本地语义
- 这条调整的价值并不只在于少两层转发：
  - 它消除了测试基础设施里的重复 truth source
  - 让后续如果继续收口 helper 行为、补 restore 断言或追踪状态回滚语义时，不会再在 `fixturehelpers` 和 `testcase` 两层之间来回改
  - 也让新的审查标准更明确：如果一个 helper 没有本地语义，就不该继续挂在更高层 façade 单元里
- 经过这轮以后，剩余值得继续深入审查的点会更偏向：
  - 生产/测试层真正重复的 thin wrapper 是否还在 backend/register/runtime seam 上残留
  - 某些 suite-local helper 是否名义上“本地”，实际上已经没有额外断言或编排价值

## 2026-05-14 Runtime Backend Fixture Alignment Findings

- `runtime.testcase` 证明当前 test-layer 的残余冗余已经不只表现为 helper façade 或生命周期基类壳，也可能表现为“suite 自己还在手工 cleanup，而公共 fixture 已经足够表达这层 contract”：
  - `RuntimeAPI` 的 3 个控制面测试此前各自保存/恢复 backend
  - 但 suite 全局并没有任何超出 `TSimdBackendStatefulTestCase` 的 fixture 语义
- 这批对齐后，边界更清楚了：
  - backend 生命周期由共享基类保证
  - 测试体只表达 runtime/facade 在 switch/reset 过程中的语义断言
  - cleanup finally 不再和被测逻辑混在一起
- 它也补充了一个后续审查标准：
  - 如果某个 suite 只是在局部测试里手工恢复 backend，但没有超出 backend-stateful 基类的额外 contract，那优先怀疑它应该回接公共基类
  - 只有当 cleanup 本身还承载额外断言、hook、rebind 或跨状态 choreography 时，才值得继续保留手写 finally

## 2026-05-14 Verified Restore Helper Consolidation Findings

- 这轮证明当前 `simd` 测试层剩余冗余已经可以继续下探到 helper contract 本身：
  - 不是所有重复都长得像 `SetUp/TearDown`
  - 也有很多残点只是“restore helper 最后再手写一次 backend getter 校验”
  - 如果这层不收，测试基础设施仍会在多个 testcase 单元里分叉出不同的标准写法
- `fixturehelpers` 补上 verified restore helper 后，层次更完整了：
  - `RestoreSavedBackendState` / `RestoreSavedBackendAndVectorAsmState` 表达“只负责恢复”
  - `...AndVerify` 表达“恢复后还要把 backend getter 校验回原值”
  - testcase 单元只保留真正需要的本地语义，而不再重复拼接 `and (GetCurrentBackend = ...)`
- 这也给后续审查提供了更细的边界：
  - 如果某个 local helper 只是包装共享 restore helper 再接一个 getter 比较，它大概率应该下沉
  - 如果 local helper 还带 rebind、hook reset、异常 mask、late-force rollback 等额外步骤，那才是真正的 suite-specific contract

## 2026-05-14 Direct Restore Helper Alignment Findings

- `direct.testcase` 这轮把 verified helper 的边界又验证清楚了一步：
  - `RebindDirectDispatch` 这类 suite-local 后处理动作确实应该继续留在 `direct`
  - 但 restore state 与 restore 后 backend 校验的主体，已经不该继续散落在 `direct` 自己的 helper/cleanup 里
- 这说明后续判断 local restore helper 是否该保留时，可以更精细地拆成两层：
  - “本地后处理动作是否必要” 和
  - “restore 本体是否仍需要手写”
  - 只要后者答案是否定的，就应尽量把 restore contract 收回共享 helper
- `direct` 现在形成了一个更干净的模式：
  - suite-local contract：`RegisterBackend(...)` / `RebindDirectDispatch`
  - shared contract：`RestoreSavedBackendStateAndVerify(...)` / `RestoreSavedBackendAndVectorAsmStateAndVerify(...)`
- 这批也意味着，`simd` 测试层剩余的 high-value 冗余已经越来越少地表现为“整个 helper 都多余”，而更多是：
  - helper 里只有一半动作是本地语义
  - 另一半 restore/verify 主体其实早就应该下沉
- 因而下一轮继续深查时，更值得找的是这种“本地后处理动作 + 共用 restore 主体”仍混写的残点，而不是再去机械搜索所有 `Restore*LocalState` 名字。

## 2026-05-14 Backend Fixture Restore Contract Alignment Findings

- 这轮确认了一类更高优先级的冗余来源：不是某个专题 suite 的 local helper，而是共享基类自己还在保留旧版 restore choreography。
- 一旦 `fixturehelpers` 已经提供 verified helper，共享 `TSimdBackendStatefulTestCase` 继续手写 restore 流程就会变成新的 competing truth source：
  - helper 层说标准写法是 `RestoreSavedBackendStateAndVerify(...)`
  - 基类层却还保留 `ResetBackendSelection + TrySetActiveBackend + getter compare`
  - 这会让后续读代码的人再次分不清哪份才是 canonical contract
- `publicabi` 那个 finally cleanup 也属于同一类问题，只是影响面更小：
  - 它不再是功能 bug
  - 但它会让 stable test path 上保留一个“只恢复、不校验”的孤岛
- 因而后续继续深查时，优先级应该这样看：
  - 先抓共享基类/共享 contract 自己是否还残留旧写法
  - 再抓单个 suite 的 message-bearing wrapper
  - 因为前者一旦收掉，整个测试层的语义标准会更统一
- 经过这批后，stable `simd` test path 上最显眼的 raw backend-restore choreography 已经基本收平；剩余更多是 suite-local 断言包装，而不是共享 contract 级别的分叉。

## 2026-05-14 DispatchSlots Redundant Finally Cleanup Removal Findings

- `dispatchslots.testcase` 这批确认了另一类值得优先删除的冗余：不是“局部 wrapper 还在用共享 helper”，而是“suite 自己在测试尾部重复执行了基类 already-guaranteed cleanup”。
- 判断这类点时，一个很实用的标准已经更清楚了：
  - 如果测试类本身继承了 `TSimdBackendStatefulTestCase`
  - 手工 restore 又只发生在方法尾部
  - 而 finally 之后没有依赖“已恢复 backend”的额外断言
  - 那么这层 restore 很可能就是 teardown contract 的重复体
- `dispatchslots` 里的 3 处恰好都满足这个条件，所以这轮可以直接删，而不是继续换成别的 helper 调用。
- 这也把下一轮审查方向进一步收窄了：
  - 优先找“只在方法尾部、且被共享 fixture contract 覆盖”的残余 cleanup
  - 低优先级才是那些虽然也调用共享 helper，但仍承载中途恢复语义、hook/reset/rebind 时序或 suite 专属消息边界的 wrapper
- 经过这批后，stable test path 里“方法尾部重复 restore 已由公共 teardown 保证的 backend state”这一类冗余基本又少了一块。

## 2026-05-15 Concurrent Tail Restore Cleanup Removal Findings

- `concurrent.testcase` 这轮把“尾部 restore 被 teardown 覆盖”这条判定标准再坐实了一层：
  - 不只是单个测试里的一两处 finally
  - 而是可以形成整个 suite-local wrapper 都应被删除的情况
- 判断关键点不在于 wrapper 名字，而在于调用位置和后续用途：
  - 如果所有调用都只发生在 `finally` 最后
  - 且调用后测试立即结束
  - 那么这个 wrapper 很可能只是把共享 teardown contract 又手工执行了一次
- 这也说明后续继续深查时，可以优先找两类模式：
  - “方法尾部 restore + 调用后立刻 end”
  - “wrapper 只服务这种 tail restore，而没有中途恢复语义”
- `concurrent` 这批删除后，剩余更值得谨慎看的点主要就会偏向：
  - 尾部 restore 之外，还伴随 hook/reset/rebind/register rollback 的 case
  - 或者恢复后仍有同一测试内 post-restore 断言的 case
- 因而下一步如果继续扫 `publicabi/dispatchapi`，最需要先分辨的就是：哪些 `Restore*LocalState(...)` 仍是“中途恢复再继续观察”，哪些也已经退化成纯尾部 cleanup。

## 2026-05-15 PublicAbi Tail Restore Cleanup Removal Findings

- `publicabi.testcase` 这轮进一步证明：当 local restore wrapper 的所有调用点都已经退化成“调用后立刻结束测试”，它就不再是 suite 语义，而只是共享 teardown contract 的历史复制体。
- 和 `concurrent` 相比，`publicabi` 提供了一个额外判断信号：
  - 即便 suite 自己还带 hook reset、register rollback、metadata/public-table 专题断言
  - 只要某个 local restore wrapper 本身不参与这些时序，而只是 finally 尾部收口
  - 它依然可以整块删除，而不需要因为 suite 更复杂就保留
- 这让下一步继续扫 `dispatchapi` 时，筛选标准更完整了：
  - 先看调用后是否立刻结束
  - 再看 wrapper 本身是否真的承载 hook/reset/rebind/register rollback 的一部分
  - 如果两者都不是，那就应该优先删，而不是继续保留一层消息文案壳
- 经过这批后，stable test path 中 `publicabi` 也不再维护第二套尾部 backend/vector-asm restore 入口；剩余最值得继续看的，基本只剩 `dispatchapi` 这类更大、但已经出现同样调用形状的文件。

## 2026-05-15 DispatchApi Tail Restore Cleanup Removal Findings

- `dispatchapi.testcase` 这轮把“尾部 local restore 已经退化成 teardown contract 复制体”的模式放大到了更大的 suite：
  - 本地 wrapper `RestoreDispatchApiLocalState(...)` 自己不承载任何 suite-specific choreography
  - 它只包一层 `RestoreSavedBackendAndVectorAsmStateAndVerify(...)` 再换一句消息文案
  - 文件里对 `fixturehelpers` 的唯一直接依赖，也正是这一个 wrapper
- 这批最关键的判断信号有两个：
  - 调用点数量虽大，但形状高度统一：`FSavedVectorAsm` 31 处、`LOldVectorAsm` 86 处
  - 机械扫描后可以看到，调用后要么直接 `end;`，要么只剩 `FreeAligned(...)`、局部缓存清零、`if LChecked = 0 then ...` 这种与“是否已经恢复 backend/vector-asm”无关的收尾
- 这说明复杂 suite 并不自动意味着 local restore 必须保留：
  - `dispatchapi` 里真正复杂的部分是 hook reset、late-force rollback、register rollback、non-x86 parity 与 capability 断言
  - 但这些语义都不在 `RestoreDispatchApiLocalState(...)` 里
  - 因而 wrapper 本身只是把共享 teardown contract 又手工执行了一次
- 删除后，`dispatchapi` 的边界更清楚了：
  - 共享 fixture 负责 backend/vector-asm restore
  - `dispatchapi` 只保留自己的 hook/register/resource rollback 与 contract 断言
  - `fixturehelpers` 不再作为这个文件的第二条 restore 真相源存在
- 这批也把后续继续深查的筛选标准再压实了一步：
  - 不是看 suite 大不大，而是看 local restore helper 是否真的携带额外语义
  - 如果 helper 只剩“共享 restore + 本地消息文案”，而调用点又全是尾部 cleanup，它就应该优先删除
  - 因而下一步更值得继续找的，将是那些名字仍像 `Restore*LocalState`，但实际上已经只剩 suite-local rollback/resource cleanup 混写的残点，而不是继续在 `dispatchapi/publicabi/concurrent` 这种已清过的纯尾部模式上反复停留

## 2026-05-15 DataPlane And IEEE754 Tail Verified-Restore Cleanup Findings

- `dataplane` 和 `ieee754` 这轮补充了一个更细的结论：
  - 就算已经没有 local wrapper 了
  - 只要 direct caller 仍然是在 `TSimdVectorAsmStatefulTestCase` 派生类里、位于 `finally` 尾部、调用后立刻结束测试
  - 它本质上仍然可能只是 teardown contract 的历史复制体
- 这批和前面 `publicabi/dispatchapi/concurrent` 的区别在于：
  - 之前删的是“wrapper + tail call”
  - 这次删的是“direct verified helper tail call”
  - 因而筛选标准从“helper 名字像不像 local restore”进一步升级成“调用位置和调用后是否还存在状态敏感逻辑”
- 证据也更机械、更好复用：
  - `dataplane` 仅 1 处
  - `ieee754` 共 10 处
  - 所有调用点后面统一直接 `end;`
  - 两个文件对 `fixturehelpers` 的唯一依赖也都正是这些 direct tail caller
- 这意味着后续继续深查时，不能只搜 `Restore*LocalState` 名字了：
  - 还要搜 direct `RestoreSavedBackendAndVectorAsmStateAndVerify(...)`
  - 再结合类继承层次和调用后控制流，判断它是不是也已经被公共 teardown contract 完全覆盖
- 经过这批后，stable `vector-asm` 派生 suite 里的“尾部再执行一次 backend/vector-asm restore 并校验”这类重复路径又少了一块：
  - `dataplane` 只保留 snapshot/publication 语义断言
  - `ieee754` 只保留 rounding/NaN/Inf/signed-zero/non-x86 parity 断言
  - `fixturehelpers` 不再被这两份文件当成第二套尾部 cleanup 入口

## 2026-05-15 Direct Tail Restore Split Findings

- `direct.testcase` 这轮说明：有些 local helper 不是“全留”或“全删”，而是需要按调用点语义拆分。
- 关键差异不在 helper 本身，而在调用后控制流：
  - `Test_DirectDispatchTable_Rebind_AfterForceBackend`
  - `Test_DirectDispatchTable_AutoRebind_AfterDispatchSetActiveBackend`
  - 这两处 finally 之后还会继续读取 `GetDispatchTable / GetDirectDispatchTable`，验证 direct table 是否已经随恢复状态重新对齐，所以必须保留 `RestoreFixtureDirectDispatchState(...)`
- 其余 26 处调用则提供了相反证据：
  - 调用后直接 `end;`
  - 或只跟 `FreeAligned(...)` 这种不依赖 backend/direct 状态的资源释放
  - 这些点已经不再需要 helper 里的 `RebindDirectDispatch + verified restore` 组合语义
- 这批把筛选标准又向前推进了一步：
  - 不能只看 helper 有没有本地语义
  - 还要看“该 helper 的哪些调用点真的消费了这层语义”
  - 如果只有少数调用点需要，就应把 helper 保留，但把尾部 cleanup caller 清掉
- 因而后续继续深查时，更值得优先找的是这种“helper 本身有意义，但大量 caller 已经退化成尾部 cleanup”的混合场景；这类点比“全文件统一删除”更隐蔽，也更容易长期遗留

## 2026-05-15 Backend Consistency Setup Helper Findings

- 这轮确认下一类高价值冗余已经不再是“尾部 restore 被 teardown 覆盖”，而是 free helper 级别的 setup/skip boilerplate。
- `backend.consistency.testcase` 里至少 7 个 free helper 在重复同一段前置流程：
  - 初始化 `TConsistencyTestResult`
  - `SaveActiveBackendState(...)`
  - `IsBackendRegistered(...)` 跳过分支
  - `TrySetActiveBackend(...)` 跳过分支
- 这里和前几批最大的区别在于：
  - 这些 helper 不是 `TSimdBackendStatefulTestCase` / `TSimdVectorAsmStatefulTestCase` 的方法尾部 cleanup
  - 因而不能简单删除或完全依赖 inherited teardown
  - 共享 contract 更适合落在“开始测试前”的 helper，而不是“测试结束后”的 fixture
- 这批也暴露出一个容易被忽略的状态语义：
  - 早退 `Exit(False)` 不只是“标记 skipped”
  - 如果前面已经 `SaveActiveBackendState(...)`，却不在 skip 路径里恢复，free helper 会把 backend 泄漏给后续测试
  - 因而共享 helper 必须把“未注册 / 当前 CPU/OS 不可用”这两个 skip 分支中的 restore 一起内建进去
- `TrySetActiveBackend(...)` 这条语义这次明确保留，而没有换成 `SetActiveBackend(...)`：
  - 原因仍然是避免 backend fallback 被误当成该 backend 自身通过
  - 所以这轮的目标不是“把 setup 写短”，而是“把 canonical setup contract 收成一份，并维持原来的 strict 选择语义”
- 经过这批后，`backend.consistency` 的冗余形态也更清楚了：
  - 之前那类纯尾部 restore 重复基本已经扫得差不多
  - 现在更值得继续找的是 free helper / meta helper 层里重复的 control-flow、result shell、message shell，而不是继续盲搜 restore caller

## 2026-05-15 Backend Consistency Name And Matrix Truth Findings

- 这轮往下看时，发现 `backend.consistency` 还留着一处“不是代码算错，但输出与控制面已经分叉”的真实问题：
  - `RunAllConsistencyTests(...)` 会跑 `SSE2/SSE3/SSSE3/SSE4.1/SSE4.2/AVX2/AVX-512/NEON/RISCVV`
  - 但 `PrintTestSummary(...)` 只给 `Scalar/SSE2/AVX2/AVX512/NEON/RISCVV` 映射了名字
  - 结果 `SSE3/SSSE3/SSE4.1/SSE4.2` 在摘要里都会落成 `Unknown`
- 这不是单点漏写那么简单，因为同一主题已经分裂出多份真相源：
  - `backend.consistency.testcase` 里有一份 backend 执行矩阵
  - `PrintTestSummary(...)` 里有一份 backend name 映射
  - `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 里又嵌了一份本地 `BackendName(...)`
  - helper meta-test 还单独保留了一份 `CBackendCandidates`
- 这些重复体已经开始产生实际漂移：
  - 摘要里缺了 4 个中间 x86 tier
  - root wrapper 的标签写法和摘要也不完全一致，例如 `AVX512` vs `AVX-512`、`RISCVV` vs `RISC-V V`
- 这批最安全的收口点因此不是再 patch 一处 `case`，而是把这层 test-only truth source 正式收成一份：
  - `CONSISTENCY_BACKENDS`
  - `GetConsistencyBackendName(...)`
  - `RunAllConsistencyTests(...)` 内部的 function-array
- 这样做的价值有三层：
  - 先把已经存在的摘要输出 bug 修掉
  - 再让执行矩阵长度和执行顺序不必继续靠“手写 7 次函数调用 + 手写 9 个 backend”
  - 最后让 root wrapper / meta-test 和 summary 共享同一套名称语义，避免下一次又在另一个局部 `case` 上漂移
- 这轮也说明后续继续深查时，优先级已经从“状态 restore 冗余”进一步推进到“test-only control/report truth source 是否多份并开始漂移”：
  - 一旦同一个 suite 既有 execution matrix，又有 local name helper，又有 wrapper 内嵌名称映射
  - 即使功能测试还绿，也值得优先收掉，因为它已经会直接污染失败信息和人工诊断面

## 2026-05-15 Backend Consistency Meta-Test Candidate Reuse Findings

- 统一 `CONSISTENCY_BACKENDS` 与 `GetConsistencyBackendName(...)` 之后，`backend consistency` 这条线上还剩一个很小但方向不对的副本：
  - `TTestCase_BackendVectorConsistency.Test_VectorOps_Helper_Preserves_PreviousForcedBackend` 仍保留本地 `CBackendCandidates`
  - 失败时也还只打印 `Ord(LTargetBackend)`，没有复用刚刚统一好的 backend 名称 helper
- 这类点看起来小，但它正好说明“统一真相源”如果不一路收到底，很容易在 meta-test 层又长回去：
  - 主执行矩阵已经共享了
  - 摘要名称已经共享了
  - 但候选 backend 列表和失败信息如果还停在局部副本上，后续扩 backend 或调整名称时又会重新漂移
- 因而这批最合适的收口方式不是再加一层 helper，而是直接让 meta-test 也回到同一真相源：
  - 候选 backend 遍历走 `CONSISTENCY_BACKENDS`
  - 失败信息走 `GetConsistencyBackendName(...)`
- 这也补强了一个继续深查的判断标准：
  - 一旦某个 helper/constant 已经被确认为 test-only canonical truth source
  - 就要顺着调用链把 meta-test / diagnostics 里的最后几份局部副本也清干净
  - 否则“代码已统一、诊断仍分叉”的问题会比实现 bug 更难被第一时间看出来

## 2026-05-15 Backend Consistency Dispatch-Truth Name And Report Helper Findings

- 再往下看一层后，`backend consistency` 里还剩一个更底层的重复 truth source：
  - `GetConsistencyBackendName(...)` 虽然已经被 root wrapper / summary / meta-test 统一复用
  - 但它自己仍维护一份本地 backend name `case` 表
  - 而 `dispatch.GetBackendInfo(...)` 早就为 registered/unregistered backend 提供了 canonical `Name/Description`
- 这意味着如果继续保留本地 `case` 表，问题只会换个位置存在：
  - 之前是多份局部名称表互相漂移
  - 现在会变成“测试 helper 名称表”与 dispatch canonical metadata 漂移
  - 尤其像 `AVX-512`、`RISC-V V` 这种带格式差异的名字，最容易再次分叉
- 因而这批最稳的收口方式，不是再维护“唯一的一份测试名称表”，而是直接承认 dispatch 才是这类 metadata 的真相源：
  - `GetConsistencyBackendName(...)` 只做 `GetBackendInfo(aBackend).Name` 的薄封装
  - 让 tests 依然有自己的稳定 helper 名称
  - 但 helper 不再重复存储 backend label 本体
- 这轮还顺手确认了另一类更细的 report-shell 重复：
  - `PrintTestSummary(...)` 和 `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency`
  - 都在各自用 `Pos('skipped', LowerCase(...))` 判定 skip
  - 都在各自拼接 failure line / max diff 细节
- 这类重复当前虽未造成 bug，但已经具备典型 drift 条件：
  - 结果 record 语义一旦变化
  - summary 与 root wrapper 很可能不会同时改
  - 人工看日志和单测失败时就会得到两套略有差异的解释
- 所以这批的合理边界是：
  - 名称真相源下沉到 dispatch metadata
  - 结果解释壳上提到 `IsConsistencyTestSkipped(...)` / `FormatConsistencyFailureText(...)`
  - 让 summary / root wrapper 都只消费同一份 result-interpretation helper

## 2026-05-15 Smoke Tool Canonical Name And Standalone Build Findings

- 继续从 `backend consistency` 往外围扫后，发现 `tests/fafafa.core.simd` 里两个独立 smoke 工具还留着很典型的 test-only 薄壳冗余：
  - `fafafa.core.simd.dispatch_preinit_smoke.pas`
  - `fafafa.core.simd.public_smoke.pas`
  - 它们都各自维护了 `BackendName(...)`，而名字本体其实早已由 `dispatch.GetBackendInfo(...)` 提供 canonical metadata。
- 这里不只是“本地 helper 有点多”这么简单，`public_smoke` 还暴露了一个真实编译合同缺口：
  - 文件顶部缺少 `{$mode objfpc}{$H+}`
  - 在独立 `fpc` 编译时，`Result := ...` 会直接报错
  - 说明这个 smoke 之前更像“被主工程顺带编进来时没出事”，而不是“可以独立作为最小入口自证”
- 这批也顺手暴露出一个验证层陷阱：
  - 如果直接用 raw `fpc -Fu./tests/fafafa.core.simd -Fu./src ...` 去编 `public_smoke`
  - `.o/.ppu` 会默认落进 `src/`
  - 随后的 `BuildOrTest.sh gate` 会在最后的 `run_all` hygiene 检查里红掉
  - 这种红灯是验证产物污染，不是代码回归
- 因而这轮的正确收口方式有两个要点：
  - 代码上，把名称真相源直接下沉到 `GetBackendInfo(...).Name`，不要继续留一层 smoke-local `BackendName(...)`
  - 验证上，用临时输出目录跑独立 `fpc` smoke，既证明 standalone compile contract 已补齐，也不再往 `src/` 树里写生成物
- 这批说明后续继续深查时，不能只盯“大测试用例里有没有重复 helper”：
  - 小型 standalone/smoke 工具也可能藏着真实合同缺口
  - 而且这类文件一旦少了 `{$mode ...}` / `uses` 依赖，主工程未必马上暴露，往往要到独立 smoke 或 hygiene gate 才显形

## 2026-05-15 Bench Canonical Backend Label Findings

- 顺着同一条线继续往下看，`fafafa.core.simd.bench` 也还留着一份明显的本地 metadata 副本：
  - `GetBenchmarkBackendName(...)`
  - `GetBackendName`
  - 它们只负责 benchmark skip/fallback 文案和标题标签，不参与任何测量逻辑
- 这类 helper 的问题不在于“代码多几行”，而在于 bench 已经天然处在人工诊断面上：
  - backend 不可用时，第一眼看到的就是 skip/fallback 文案
  - benchmark 输出标题也会直接展示 backend label
  - 如果这里继续自己维护一份名称表，就会把之前刚清掉的 drift 风险重新带回 perf-smoke/bench 面
- 因而这批最稳的收口方式和 smoke 工具一致：
  - 不再把“bench 专用 backend 名称表”当成测试层本地真相源
  - 直接承认 `dispatch.GetBackendInfo(...).Name` 才是 canonical metadata
  - 让 bench 只保留“如何测量/如何展示”这层职责，而不再重复存储 label 本体
- 这批还强化了一个继续深查的筛选标准：
  - 只要某个小型 runner/unit 里的本地 helper 既不承载 suite 语义、也不承载算法语义，而只是转发 canonical metadata
  - 就优先把它收掉
  - 因为这类点改动最小、验证成本低、却能持续减少日志/标题/skip 文案再次漂移的机会

## 2026-05-15 Standalone Program Entry Contract Findings

- 继续往 `tests/fafafa.core.simd` 的独立入口看时，发现一类和主 `BuildOrTest` 完全不同的真实问题：
- 这些 program 文件不一定被主 runner/gate 真实编到
- 因而很容易长期带着“看上去像能用、实际上没单独自证过”的入口合同缺口
- 这轮已经确认的具体问题有 4 个：
  - `test_backend_ops.pas` 缺 `fafafa.core.settings.inc`
  - `test_simd_boundary.pas` 缺 `fafafa.core.settings.inc`
  - `test_backend_ops.lpi` 主单元错误指向 `fafafa.core.simd.test.lpr`
  - `test_simd_boundary.pas` 还写着当前 `uses` 面并不存在的 `NegInfinity`
- `test_backend_ops.lpi` 这一点尤其值得记下来，因为它不是“文档约定没跟上”，而是实际行为已经跑偏：
  - `lazbuild -B tests/fafafa.core.simd/test_backend_ops.lpi`
  - 修复前会去编整套 `fafafa.core.simd.test.lpr`
  - 并在主 testcase 里炸出完全无关的 `Asm: word value exceeds bounds ...`
  - 这类失败会把真正的问题掩盖掉，让人误以为 `test_backend_ops` 自己坏了
- `test_simd_boundary` 这条线也说明了“独立入口真相”不能只看能不能过主工程编译：
  - standalone `fpc` 编译第一次就卡在 `NegInfinity`
  - 修掉后，断言主体其实全部通过
  - 但 banner/summary 几行输出又暴露出旧编码污染，落盘后真值是 `?` 而不是中文
  - 最后需要把这些字面量显式收成 `UTF8String(...)`，才真正恢复 UTF-8 输出真相
- 这批给后续 SIMD 深查又补了一个新的优先级标准：
  - 不只要扫主 suite / helper / bench
  - 还要扫 repo 里那些“平时不在主 gate 上、但被留下来作为独立入口/示例/调试程序”的 program/lpi
  - 因为它们最容易积累配置漂移、主单元误指向和 source-encoding 污染这类隐性问题

## 2026-05-15 DispatchAPI Canonical Backend Name Reuse Findings

- `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 里这轮残留的 4 处局部 `BackendName(...)` 并不是 capability truth source，而只是断言消息文本来源：
  - `Test_BackendCapabilities_DoNotUnderclaim_Shuffle`
  - `Test_X86_BackendCapabilities_DoNotUnderclaim_MaskedOps`
  - `Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled`
  - `Test_X86_BackendCapabilities_Keep_MaskedOps_When_VectorAsmDisabled`
- 这点必须先确认清楚，因为同一文件里确实还混有真正承载语义边界的局部 helper：
  - `IsX86MaskedOpsBackend(...)`
  - `IsVectorAsmGatedX86Backend(...)`
  - 以及其他 `case aBackend of` capability membership 判断
- 换句话说，本轮能安全统一的是“名字消息源”，不能把所有 `case aBackend of` 都误判成冗余表一起清掉。
- 文件级 `DispatchApiBackendName(...)` 现在已经作为 canonical 薄封装落地：
  - `Result := GetBackendInfo(aBackend).Name;`
  - 这让 `dispatchapi.testcase` 当前已清掉的几簇断言文案，都直接复用 dispatch metadata，而不再自己维护 `Scalar/SSE2/AVX2/...` 的局部名称表。
- 这批还确认了一个很实用的继续筛选原则：
  - 如果某个 helper 只参与 `AssertTrue/AssertFalse` 的消息文本
  - 而 backend 归类/slot ownership/capability membership 另有独立 helper 负责
  - 那它就是优先级很高、风险很低的真冗余收口点
- 目前 `dispatchapi.testcase` 里仍剩下一簇同类局部 `BackendName(...)`，大致在：
  - `10613`
  - `10788`
  - `10821`
  - `10925`
  - `10962`
- 另有文件级 `NonX86BackendName(...)` 继续服务 non-x86 测试消息面；它不适合和这次 x86/capability 小批次混做，后续应单开 non-x86 批次再收。

## 2026-05-15 DispatchAPI Canonical Backend Name Reuse Batch 2 Findings

- 上一批留下的下一簇局部 `BackendName(...)` 已继续复核清楚，分别落在：
  - `Test_X86_BackendCapabilities_Clear_Shuffle_When_VectorAsmDisabled`
  - `Test_NonX86_DispatchTable_WiringChecklist_Grouped`
  - `Test_X86_DispatchTable_WiringChecklist_Grouped`
  - `Test_NonX86_DispatchTable_WiringChecklist`
  - `Test_NonX86_NativeWideFloorCeil_Slots_NotScalar_IfAvailable`
- 这 5 个过程虽然覆盖面比上一批更杂，但局部 `BackendName(...)` 的职责依然很纯：
  - 只给 `AssertEquals/AssertTrue/AssertFalse` 提供 backend 名称
  - 不参与 `x86 shuffle` capability gating
  - 不参与 `non-x86 asm compiled` 的 `{$IFNDEF ...}` 选择
  - 不参与 `LBackends[...]` 的 backend 集合定义
- 这意味着它们仍然属于“消息真相源冗余”，而不是“测试语义真相源冗余”。
- 其中最容易混淆的一点是 non-x86 两个 checklist / parity 过程：
  - `dispatchapi.testcase` 里的这批局部 `BackendName(...)` 和后面文件级 `NonX86BackendName(...)` 作用域不同
  - 前者只是 procedure-local 副本，可以安全收掉
  - 后者仍被 `TTestCase_NonX86BackendParity` 等另一组测试共享使用，适合后续单独批次处理
- 本批收完后，`dispatchapi.testcase` 已经不再有局部 `BackendName(...)`。
- 当前在这个文件里剩下的明确名称 helper 只剩：
  - 文件级 `DispatchApiBackendName(...)`，它现在是统一的 canonical 薄封装
  - 文件级 `NonX86BackendName(...)`，它仍服务 non-x86 parity / slot 断言消息面
- 因而下一步的优先级已经更清楚了：
  - 不再需要继续在 `dispatchapi.testcase` 里扫 procedure-local `BackendName(...)`
  - 下一批应转向 `NonX86BackendName(...)` 是否也能安全下沉到 canonical metadata，前提是先核清它所在的 `TTestCase_NonX86BackendParity` 族是否没有额外的 label policy 语义

## 2026-05-15 NonX86BackendName Thin Wrapper Findings

- 文件级 `NonX86BackendName(...)` 的特殊点不在于“它是不是副本”，而在于它的调用面非常广：
  - `TTestCase_NonX86BackendParity` 里大量 slot-not-scalar、dispatch-table parity、facade parity、lane-tag parity、shift parity 断言都复用它
  - 因此如果贸然全量改调用点，虽然风险不高，但 diff 会显著膨胀
- 复核后确认它依旧只是纯消息 helper：
  - backend 集合由各测试里的 `LBackends[...]` 控制
  - `{$IFNDEF FAFAFA_SIMD_TEST_NEON_ASM_COMPILED}` / `{$IFNDEF FAFAFA_SIMD_TEST_RISCVV_ASM_COMPILED}` 决定参与性
  - `TrySetActiveBackend(...)` / dispatch-table 调用决定真实执行路径
  - `NonX86BackendName(...)` 本身不参与任何判断
- 所以最优解不是“把一百多处调用全改成 `DispatchApiBackendName(...)`”，而是：
  - 保留 `NonX86BackendName(...)` 这个 non-x86 测试语义上可读的 helper 名
  - 但把它的实现体收成 `DispatchApiBackendName(...)` 的 thin wrapper
  - 这样既消除了重复名称表，也避免无意义的大 diff
- 这批说明后续继续深查时，可以把重复真相源分成两类来处理：
  - `调用点很少` 的，直接删 helper、改调用点
  - `调用点很多但 helper 仍纯` 的，优先改 helper 本体为 canonical thin wrapper
- 当前 `dispatchapi.testcase` / `TTestCase_NonX86BackendParity` 这条线上的 backend 名称 helper 已经完成去副本：
  - `DispatchApiBackendName(...)` 是 canonical 薄封装
  - `NonX86BackendName(...)` 现在只是对前者的语义别名，不再维护自己的名字表

## 2026-05-15 PublicAbi Canonical Backend Label Findings

- `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 里这轮最值得收的，不是 capability 判断本身，而是失败消息还在把 backend 当数字编号输出：
  - `IntToStr(Ord(LBackend))`
  - 它分散在 `Test_PublicApi_BackendPodInfo_Flags_AreSelfConsistent` 以及一组 `CapabilityBits_*` 断言里
- 这里如果只看表面，很容易误判同文件里的 `case aBackend of` 也该一起删掉，但复核后边界很清楚：
  - `IntToStr(Ord(LBackend))` 只是消息壳
  - 若干 `case aBackend of` 仍承担 `shuffle/masked/integer-ops` capability membership 语义
  - 所以这批只能统一 label truth source，不能动 semantic truth source
- 最稳的收口方式和 `dispatchapi` 前几批一致：
  - 保留 `publicabi.testcase` 自己的语义可读性
  - 新增文件级 `PublicAbiBackendName(...)`
  - 但把它的实现直接收成 `GetBackendInfo(aBackend).Name`
- 这样做的诊断收益比“只把数字换成字符串”更实在：
  - `public ABI` 这组失败本来就覆盖 pod flags、capability bits、vector-asm-disabled 分支
  - 一旦断言失败，直接显示 `AVX2/NEON/RISCVV/...` 比 backend ordinal 更快定位问题
  - 同时也避免 `publicabi` 测试面重新维护一份和 dispatch metadata 平行的 backend 名称真相源
- 这批再次强化了一个后续深查纪律：
  - 对测试文件中的 `case aBackend of`，先分清它是在“决定语义”还是“只生成文本”
  - 只有后者才适合直接下沉到 canonical metadata helper

## 2026-05-15 IEEE754 Canonical Backend Label Findings

- `tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas` 里还留着一簇非常集中的 backend ordinal 文案：
  - 总计 76 处
  - 全部是 `IntToStr(Ord(LBackend))`
  - 分布在 `Round/Trunc/Floor/Ceil` 的 edge-case、signed-zero、property-like/invariant 断言上下文字符串里
- 这里的关键判断也必须先做清楚：
  - `LBackend` 只用于失败消息前缀
  - expected/actual 值仍由 `LDispatch^....(...)` 与 scalar baseline 生成
  - `LRound/LIndex/LCaseIndex` 才参与测试场景定位
  - 所以这批是纯 report shell 冗余，不是 IEEE754 语义冗余
- 这一类文件比 `dispatchapi/publicabi` 更容易让人误判成“只是换好看文案”，但其实收益很实：
  - `ieee754` 失败时最需要的是快速知道到底是 `Scalar/SSE2/AVX2/NEON/RISCVV` 哪个 backend 失真
  - 仅看 backend ordinal，会迫使排障者再回头映射一次 enum
  - 尤其在 randomized/property-like 断言里，`backend 名称 + round 次数 + lane/case` 才是足够快的定位组合
- 因而最稳的收口方式仍然是：
  - 文件级保留一个 `IEEE754BackendName(...)` 语义 helper
  - helper 本体直接下沉到 `GetBackendInfo(aBackend).Name`
  - 不动数值逻辑、不动期望生成、不动 backend 遍历集合
- 这批还把下一步优先级进一步压实了：
  - 如果某个测试文件还在大面积用 `IntToStr(Ord(aBackend))` 只生成 slot/assert 消息
  - 它就仍属于高信号、低风险的“诊断真相源”收口对象
  - 当前下一个明显候选就是 `dispatchslots.testcase`

## 2026-05-15 DispatchSlots Canonical Backend Label Findings

- `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas` 里的 backend ordinal 文案密度比前两批都高：
  - 总计 562 处
  - 其中 557 处集中在 `AssertAllDispatchSlotsAssigned(...)`
  - 另外 5 处在 `Test_BackendAdapter_UnregisteredBackendOps_PreserveCanonicalMetadata`
- 但这块恰恰也是很纯的诊断层冗余，不是 slot 合同冗余：
  - `AssertAllDispatchSlotsAssigned(...)` 只是逐槽 `Assigned(...)`
  - backend 只出现在 `'Backend=... slot ... should be assigned'` 前缀
  - `GetBackendOps` 那 5 条也只是给 metadata 断言补上下文，期望值仍来自 `GetBackendInfo(...)`
- 这类文件适合用“helper + prefix”方式收，而不是盲目把 500 多行拆成更复杂的测试结构：
  - 文件级 `DispatchSlotsBackendName(...)` 下沉到 `GetBackendInfo(aBackend).Name`
  - `AssertAllDispatchSlotsAssigned(...)` 只多一个 `LBackendSlotPrefix`
  - 这样既把 557 处重复编号前缀一次性收平，也不改变每条 slot 断言的直读性
- 这批再次验证了一个很实用的收口策略：
  - 当重复内容是“同一前缀 + 不同 slot 名”时，优先把前缀收成共享字符串
  - 不要为了“看起来更抽象”去把整份 slot checklist 重构成循环/元数据表
  - 否则会增加 review 成本，反而不利于 dispatch 合同文件的可审查性
- 当前这一批收完后，`dispatchslots.testcase` 的 backend ordinal 文案已经清零。
- 下一步如果继续沿同类线深查，就应该转向别的 `report shell / canonical metadata` 冗余点，而不是再回头重扫 `publicabi/ieee754/dispatchslots` 这三份文件。

## 2026-05-15 DirectDispatch Canonical Backend Label Findings

- `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas` 是这条线当前最大的残余点：
  - 总计 493 处 backend ordinal 文案
  - 覆盖 direct dispatch slot assigned、direct/facade parity、mem/text/search edge matrix、mask helper、wide integer helper、extract/insert 等多类断言
- 但这 493 处虽然分布很广，性质却非常统一：
  - 都是 `+ IntToStr(Ord(LBackend))` 或 `+ IntToStr(Ord(aBackend))`
  - 只参与断言上下文文本
  - direct/facade 真实结果、lane 期望值、随机矩阵输入、concurrent 行为完全不依赖这个 ordinal 字符串
- 这类文件不适合像 `dispatchslots` 一样做“单前缀收口”，因为 direct 测试消息形状很多：
  - `backend ...`
  - `backend=...`
  - `case=... backend ...`
  - `lane ... backend ...`
  所以最稳的做法反而是更简单的 helper 替换：
  - 文件级 `DirectBackendName(...)`
  - 然后机械地把所有 `+ IntToStr(Ord(LBackend/aBackend))` 收成 `+ DirectBackendName(...)`
- 这批再次验证了一个新的筛选标准：
  - 如果某个测试文件里的 backend 文案形状很多，不存在一个共享前缀能干净抽出来
  - 那就优先做“canonical helper 替换”，而不是为了少几行 helper 去引入复杂格式化函数
- 当前这批收完后，`direct.testcase` 的 backend ordinal 文案也已经清零。
- 现在全目录里这类 residual 已经压缩到很小：
  - `dispatchapi.testcase` 约 13 处
  - `fafafa.core.simd.testcase` 1 处

## 2026-05-15 Backend Ordinal Tail Cleanup Findings

- `direct.testcase` 收口后，再做按文件聚合的余量盘点，backend ordinal 文案只剩最后 14 处：
  - `dispatchapi.testcase`：13
  - `fafafa.core.simd.testcase`：1
- 这说明之前的判断是对的：
  - 真正高密度的大块都已经被清掉
  - 剩下的只是零散尾差
  - 最优策略不再是“开新结构”，而是直接复用文件里已经存在的 canonical helper
- 这批的两个改动点都非常纯：
  - `dispatchapi.testcase` 已经有 `DispatchApiBackendName(...)`
  - `simd.testcase` 已经有 `GetConsistencyBackendName(...)`
  - 因而不需要再新增任何 helper 或 wrapper
- 这轮最关键的收口证据不是某一个 suite，而是目录级 grep：
  - `rg -n "IntToStr\\(Ord\\((L|a)Backend\\)\\)" tests/fafafa.core.simd --glob '*.pas'`
  - 结果为空
  - 这代表“backend ordinal 只服务断言消息”这条特定冗余线，在当前 `tests/fafafa.core.simd` Pascal 测试文件里已经被清空
- 这批也说明后续如果继续做“加强审查”，就该换问题类型了：
  - 这条 backend label 冗余线已经收平
  - 后续更值得找的是别的 report shell、重复 truth source、或者行为/覆盖缺口
  - 不需要再回头在同一条 ordinal 文案线上反复扫

## 2026-05-15 Concurrent Canonical Backend Label Findings

- 目录级 `rg -n "IntToStr\\(Ord\\((L|a)Backend\\)\\)" tests/fafafa.core.simd --glob '*.pas'` 清零之后，`concurrent.testcase` 仍暴露出另一类更隐蔽的 report-shell 冗余：
  - `DescribeBackendInfoLocal` / `DescribeRuntimeSnapshotLocal` 通过 `Format(... backend=%d ...)` 输出 backend ordinal
  - `DescribeBackendArrayLocal` 仍把 backend 数组打印成 `[0,1,2]` 这种枚举编号串
  - mixed snapshot 错误文本仍显示 `got=%d expectedA=%d expectedB=%d`
  - synthetic first-registration metadata 仍拼 `ConcurrentFirstRegister_<ordinal>`
- 这些点和前一批 tail cleanup 的共性在于：
  - 都只影响诊断壳、描述文本和 synthetic metadata
  - 不参与 backend 切换、dispatch 选择、并发同步或随机矩阵期望值计算
  - 一旦失败，显示 `AVX2/NEON/RISCVV/...` 比再次回头映射 enum 编号更直接
- 但 `concurrent.testcase` 也更容易误伤真实数值语义：
  - `AssertEquals(..., Ord(LBackend), Ord(GetCurrentBackend))` 这种比较必须保留 ordinal
  - `QWord(Ord(LBackend))` 这类 seed 也属于行为输入，不能因为“看起来像 backend 编号”就替掉
  - 因而这批的关键不是“全删 `Ord(...)`”，而是先把消息层和行为层分清
- 最稳的收口方式是复用 runtime 已公开的 canonical metadata：
  - 新增 `ConcurrentBackendName(const aBackend: TSimdBackend): string`
  - 直接返回 `GetBackendInfo(aBackend).Name`
  - 让描述函数、mixed snapshot 错误文本与 synthetic metadata 都只依赖这一个 truth source
- 本轮 `Release gate` 最相关的证据链继续保持稳定：
  - `TTestCase_PublicAbi` / `TTestCase_SimdConcurrentPublicAbi` / `TTestCase_SimdConcurrentFramework` 通过
  - `TTestCase_DirectDispatchConcurrent` 通过
  - filtered `run_all` summary 为 `Passed 5 / Failed 0`
  - `[GATE] OK`

## 2026-05-15 Public Smoke Canonical Backend Output Findings

- 在 testcase 层的 backend label 冗余基本收平后，独立 program 入口里还留着一个更直接的 user-facing 残点：
  - `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas`
  - 运行输出是 `Backend:    6 (AVX2)`
  - 这不是断言消息，而是用户第一眼就会看到的 smoke banner
- 这个点和前面几批不完全一样，因为它还带着“验证覆盖缺口”：
  - `public_smoke.pas` 不是主 `fafafa.core.simd.test.lpi` runner 的一部分
  - 也不在当前 `BuildOrTest.sh gate` 的既有 smoke 链里
  - 所以不能只靠“主 gate 绿”就假设这个入口一直健康
- 先做的是真运行，而不是静态猜：
  - 独立 `fpc` 编译并运行 `fafafa.core.simd.public_smoke.pas`
  - 修复前的真实输出明确包含 ordinal：`Backend:    6 (AVX2)`
  - 这证明它确实还在对外暴露 enum 编号，而不是仅仅在源码里“看着有点冗余”
- 这类输出最稳的收口方式和 bench / concurrent 一致：
  - 不再让 smoke program 自己拼一份 “ordinal + name” 混合视图
  - 新增文件级 `PublicSmokeBackendName(...)`
  - 统一直接使用 `GetBackendInfo(...).Name`
- 修完后再次独立运行，输出已变成：
  - `Backend:    AVX2`
  - `[PASS] Default backend is AVX2`
- 这批还给后续深审补了一个筛选标准：
  - 只要是 repo 里的独立 program 入口，就不能假设它天然被主 gate 覆盖
  - 对这类文件，除了修代码本身，还应补一次独立编译运行证据

## 2026-05-15 Public Smoke Check Coverage Wiring Findings

- `public_smoke` 的更深一层问题不是输出里多了一个 ordinal，而是它在修复前仍然属于“手动才会跑到”的孤岛入口：
  - `BuildOrTest.sh check`
  - `buildOrTest.bat check`
  - 都没有任何 `public_smoke` runner
- 这次还顺手澄清了一个脚本真相，后续非常值得记住：
  - shell 里确实有一段很像 `run_check` 的辅助块
  - 但真正被 `ACTION=check` 走到的是底部 `case` 里的内联 `check)` 分支
  - 因而第一次把 `run_public_smoke` 调用只补进辅助块时，`Release check` 虽然仍然是绿的，但日志里完全没有 `[PUBLIC-SMOKE]`
  - 只有把调用补到 `case` 的真实执行路径里，runner 才会真的生效
- 最稳的修法不是新开 CLI 动作，而是直接补内部 runner：
  - shell：`PUBLIC_SMOKE_SRC`、`public_smoke_output_root()`、`run_public_smoke()`
  - batch：`PUBLIC_SMOKE_SRC`、`:run_public_smoke_internal`
  - 两边都把 child output root 统一定到 `public.smoke`
  - `clean` 也同步清理这个 child root，避免 standalone smoke 输出长期堆在 repo 里
- fresh `Release check` 的关键证据已经从“人工单独跑”升级成“日常链路自动跑”：
  - `[PUBLIC-SMOKE] Building standalone smoke: ...fafafa.core.simd.public_smoke.pas`
  - `[PUBLIC-SMOKE] Running standalone smoke: .../public.smoke/bin/fafafa.core.simd.public_smoke`
  - `Backend:    AVX2`
  - `[PASS] Default backend is AVX2`
  - 之后 `dispatch preinit smoke`、experimental isolation 仍继续通过
- 这批说明一个很实用的继续审查原则：
  - 发现 standalone 入口问题时，修文件本身只解决“当前对”
  - 把它接进现有验证链，才解决“以后不容易再悄悄坏掉”

## 2026-05-15 BackendOps And Boundary Check Coverage Wiring Findings

- `public_smoke` 接进 `check` 之后，再往同类入口看，剩下最明显的两个 manual-only 程序就是：
  - `tests/fafafa.core.simd/test_backend_ops.pas`
  - `tests/fafafa.core.simd/test_simd_boundary.pas`
- 这次先确认的不是“要不要接”，而是它们当前是否真的值得接：
  - `test_backend_ops` fresh 独立运行结果是 `Passed: 15 / Failed: 0`
  - `test_simd_boundary` fresh 独立运行结果是 `通过: 44 / 失败: 0`
  - 这说明当前问题不是程序坏了，而是它们修好后仍然没有被 daily `check` / fast `gate` 自动覆盖
- 这批和 `public_smoke` 的区别在于：不只是 `case check)` 要接，`gate_step_build_check()` 也要接
  - 否则 `Release check` 会绿，但 `Release gate` 的 build-check 仍然可能漏掉这两个入口
  - 因而 shell 这次同步改了两条真实执行路径：
    - `gate_step_build_check()`
    - `case "${ACTION}" in ... check)`
- fresh 证据已经从“手动单跑”升级成“主链自动跑”：
  - Release `check` 中真实出现：
    - `[BACKEND-OPS] Building standalone program: .../test_backend_ops.pas`
    - `Passed: 15`
    - `[SIMD-BOUNDARY] Building standalone program: .../test_simd_boundary.pas`
    - `通过: 44`
  - Release `gate` 的 `1/6 Build + check SIMD module` 中也真实出现同样两段，再接着跑 `PUBLIC-SMOKE` 与 `DISPATCH-PREINIT`
- 这次也暴露了一个当前仍需诚实记录的边界：
  - shell 侧 `check` / `gate` 已经过 fresh release 实跑
  - batch 侧 runner 虽然做了同构接线和清理路径补齐，但本轮没有真实 Windows 执行证据
  - 因而当前最准确的结论是：Linux 主闭环已经覆盖，Windows batch 仍有“源码已对齐、真实运行待补证”的残余风险

## 2026-05-15 Daily Standalone Runner Guard Findings

- 在把两个 standalone program 真正接进 `check/gate` 之后，新的风险已经从“没覆盖”切到“以后是否会悄悄漂移”：
  - shell / batch runner 现在各有一套 source、output root、调用点
  - 如果后续只改一边、或删掉某个调用点，主逻辑本身未必立刻报错
  - 这种情况下，最有效的防线不是等 Windows 侧人工发现，而是在 Linux 主链里先做 source-safe guard
- 仓库里已经有成熟先例：
  - `check_dispatch_preinit_smoke_runner_guard()`
  - 它就是用 grep/source sentinel 的方式，同时校验 shell、batch 和目标 smoke 源文件
- 因而这批最稳的修法是复用同一模式，而不是现在就去大改 runner 结构：
  - 新增 `check_daily_standalone_runner_guard()`
  - 校验 shell/bat 两边是否都保留了 `BACKEND_OPS_SRC`、`SIMD_BOUNDARY_SRC`
  - 校验 output root、runner 定义和 `check`/`gate build-check` 调用点是否还在
  - 再给 `test_backend_ops.pas` / `test_simd_boundary.pas` 各加几条关键 sentinel，防止脚本指错源文件却不自知
- fresh 证据已经明确表明 guard 生效：
  - Release `check` 中真实出现 `[CHECK] OK (daily standalone runner guard present)`
  - 之后同一次 `check` 仍然继续完成 `BACKEND-OPS`、`SIMD-BOUNDARY`、`PUBLIC-SMOKE`、`DISPATCH-PREINIT`
- 这批的价值不在于多跑了一次程序，而在于把“已补进去的 coverage”也纳入了防回退机制：
  - 以后如果有人只改 shell/bat 一边
  - 或者把某个 standalone runner 从 `check` 移掉
  - Linux 主链就更早暴露这个 drift，而不必等人工记忆兜底

## 2026-05-15 Standalone Guard Coverage Tightening Findings

- 继续深看之后，前一批 guard 还有三个很具体的遗漏点：
  - `check_daily_standalone_runner_guard()` 只覆盖了 `backend_ops/simd_boundary`，`public_smoke` 仍然在 guard 外
  - `check_isolated_clean_coverage()` 还停留在 `dispatch.preinit.smoke`，没有把后来新增的 `public.smoke/backend.ops/simd.boundary` child output 清理路径纳入约束
  - `check_dispatch_preinit_smoke_runner_guard()` 对 batch 侧只校验了 source/runner/build line，还没守住 `DISPATCH_PREINIT_OUTPUT_ROOT` 和 root override
- 这说明当前最值钱的一刀不是再去改 runner 本体，而是把 guard 的“覆盖面”补齐：
  - `public_smoke` 一旦从 batch 的 `check` 调用点或 clean 路径漂移出去，旧 guard 不会响
  - 三个 child output 如果未来从 `clean` 漏删，旧 `isolated clean coverage` 也抓不到
  - `dispatch_preinit` 的 batch output-root 若被改坏，旧 guard 同样可能放过
- 这批修完后的 fresh Release `check` 已给出比上一轮更完整的证据：
  - `[CHECK] OK (isolated clean coverage present)`
  - `[CHECK] OK (dispatch preinit smoke guard present)`
  - `[CHECK] OK (daily standalone runner guard present)`
  - 随后 `BACKEND-OPS`、`SIMD-BOUNDARY`、`PUBLIC-SMOKE`、`DISPATCH-PREINIT` 继续全部真实通过
- fresh Release `gate` 也再次通过，说明这次 tightening 没把 fast-gate 主链焊死：
  - `Run-all summary ... Passed: 5 Failed: 0`
  - `[GATE] OK`
- 我还专门尝试了把 Windows batch 真实运行证明往前推一小步：
  - 本机 `wine cmd` 能跑
  - 临时 PATH wrapper 也能让 `where fpc` 看到 `fpc.bat`
  - 但 `fpc -iTP` 没有形成可靠可收口的完成证据，并伴随 `wine` 剪贴板超时噪音
  - 所以当前最准确的结论仍然是：
    - Linux 主闭环：fresh runtime-proved
    - Windows batch：guard 更强了，但 runtime-proof 仍未真正拿到

## 2026-05-15 Windows Evidence Contract Tightening Findings

- 继续往下审，真正的问题已经不是“有没有 Windows log”，而是“verifier 会不会把旧 log 误判成当前证据”：
  - 仓库里的 `tests/fafafa.core.simd/logs/windows_b07_gate.log` 仍停留在 2026-04-18 的旧 gate shape
  - 它没有 `BACKEND-OPS / SIMD-BOUNDARY / PUBLIC-SMOKE / DISPATCH-PREINIT` 四段 standalone 日志，也仍然是 `1/7` 步骤编号
  - 但修补前的 `verify_windows_b07_evidence.sh` 依然会把它判成 `OK`
- 这批真正要修的不是 SIMD 实现，而是证据合同：
  - shell/batch verifier 现在都要求 current gate 文案 `1/6 + optional public ABI smoke + 6/6 Filtered run_all check chain`
  - 它们同时要求四个 standalone runner 的 build/run/OK 痕迹
  - 这样 `windows_b07_gate.log` 只有在真的包含新的 daily standalone coverage 时才会过
- 为了让 evidence layer 真正闭环，我把采集/模拟/演练一起同步了：
  - `collect_windows_b07_evidence.bat` 现在在 `1/6` 直接调用 `buildOrTest.bat check`
  - `simulate_windows_b07_evidence.sh`、`rehearse_freeze_status.sh` 的 PASS 夹具都按 current contract 更新
  - `BuildOrTest.sh` 里守这些文件的 source-safe guard 也一起收紧
- 真实验证结果现在非常明确：
  - 旧 `windows_b07_gate.log` 在 shell verifier 下会 fail
  - 旧 `windows_b07_gate.log` 在 `wine cmd /c ...verify_windows_b07_evidence.bat ...` 下也会 fail
  - 合成的 current-contract Windows log 则能被 shell/batch verifier 都接受
  - `bash tests/fafafa.core.simd/rehearse_freeze_status.sh` 继续 OK
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 也继续 OK，但现在会把旧 Windows log 诚实降级为 optional evidence `SKIP`，不再误报 `OK`
- 这批留下的最重要结论是：
  - Windows evidence 的真实含义终于和当前 SIMD daily coverage 对上了
  - 以后如果 evidence 里没有新接入的 standalone runner，脚本会直接说不，不再悄悄放行

## 2026-05-15 Gate Label Harmonization Findings

- 进一步扫尾时，我发现还有一处纯文案漂移：
  - shell `BuildOrTest.sh gate` 仍写着 `3/6 SIMD AVX2 fallback suite`
  - batch/evidence/rehearsal 已经统一成 `3/6 SIMD AVX2 stable vector suites`
- 这不是行为问题，但会让同一条 gate contract 在不同入口上看起来像两条路：
  - 入口命名不一致会增加后续审查成本
  - 尤其是在追 Windows evidence 时，label 不统一会让人误以为 gate 语义不同
- 因而我把 shell 的 `3/6` label 也统一成了 `stable vector suites`
- 真实验证已经确认：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 继续 `OK`
  - 日志里出现了新的 `3/6 SIMD AVX2 stable vector suites`
  - 旧 Windows `windows_b07_gate.log` 仍然会被 evidence verifier fail 掉
- 这一步的价值是把 contract 口径收紧，而不是放松证据：
  - 同一条 gate 在 shell/batch/evidence/rehearsal 里终于说同一种话

## 2026-05-15 Windows Evidence GH Preflight Blocked

- 我继续复核 fresh Windows evidence 的外部前提，结果仍然是阻塞：
  - `gh auth status` 正常
  - 仓库 workflow 也能解析到 `simd-windows-b07-evidence.yml`
  - 但 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight` 返回 `RECENT_BILLING_BLOCK`
- 这个 blocker 的含义很明确：
  - GitHub 直接拒跑相关 workflow run
  - 原因是 recent account payments failed 或 spending limit 需要提高
  - 这不是本地 `simd` 代码、脚本或 gate 逻辑可修的问题
- 当前最准确的结论是：
  - fresh Windows runtime proof 仍被外部账单/额度挡住
  - 后续只有先恢复 GitHub Billing/额度，才能继续往下刷新 evidence

## 2026-05-15 RISCVV Dead Load/Store/Splat/Zero Residue Removal

- 在修完 `RISCVVCmpNeU32x4` 的内部合同漂移之后，继续深审 `RISCVV` 余项时，最强的新信号已经不是“同名 helper 是否签名漂移”，而是有一组明显的双轨死残留：
  - `RISCVVLoadI32x4`
  - `RISCVVStoreI32x4`
  - `RISCVVSplatI32x4`
  - `RISCVVZeroI32x4`
  - `RISCVVLoadI64x2`
  - `RISCVVStoreI64x2`
  - `RISCVVSplatI64x2`
  - `RISCVVZeroI64x2`
- fresh 全仓检索确认，这 8 个符号只剩两类定义点：
  - `src/fafafa.core.simd.riscvv.pas`
  - `src/fafafa.core.simd.riscvv.helpers.inc`
- 更重要的是，完全没有命中：
  - `src/fafafa.core.simd.riscvv.register.inc`
  - `src/fafafa.core.simd.riscvv.facade.inc`
  - `src/fafafa.core.simd.dispatch.pas`
  - `tests/fafafa.core.simd*`
  - `docs/*simd*`
- 这说明它们不是“忘了接线的能力缺口”，而是：
  - 没有消费面的 internal residue；
  - 并且同时保留了 asm 版本和 fallback 版本，属于双轨死代码。
- 本批收法因此很直接，也比前几批更干净：
  - 从 `riscvv.pas` 删除 8 个 asm 定义；
  - 从 `riscvv.helpers.inc` 删除 8 个 fallback 定义；
  - 不去给它们补 façade / dispatch / register，因为那会把 dead residue 错误升级成新 contract。
- 为了防止后续“又被某次复制粘贴带回来”，`check_nonx86_helper_semantics.py` 这次新增了 source-side 缺席护栏：
  - `require_routine_absent(...)`
  - 明确要求这 8 个名字在 `riscvv.pas` 和 `riscvv.helpers.inc` 中都不存在。
- fresh 结果继续是干净的：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=498 status=ok`
  - `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`
  - Release `check` 通过
  - Release `gate` 通过
- `gate` 末尾仍然只有旧 `windows_b07_gate.log` 的 optional evidence verify 缺模式，这继续是历史 Windows 证据过期问题，不是本批 residue removal 引入的实现回归。

## 2026-05-15 RISCVV Dead Shift/Reduce/Select Residue Removal

- 在收掉 `Load/Store/Splat/Zero` 那组死残留之后，我继续往 `RISCVV` 里追第二组边缘 helper，结果发现：
  - `RISCVVShiftLeftU64x2`
  - `RISCVVShiftRightU64x2`
  - `RISCVVReduceAddI32x4`
  - `RISCVVReduceMinI32x4`
  - `RISCVVReduceMaxI32x4`
  - `RISCVVReduceMinU32x4`
  - `RISCVVReduceMaxU32x4`
  - `RISCVVSelectI64x2`
  - `RISCVVSelectI32x8`
  - `RISCVVSelectI32x16`
  这 10 组也只剩 `riscvv.pas` 和 `riscvv.helpers.inc` 两处定义。
- fresh 复核更进一步确认，它们不仅“不在当前 checker 重点里”，而是根本没有接进任何真实 contract：
  - `riscvv.register.inc` 没有对应 `table.* := @RISCVV...`
  - `riscvv.facade.inc` 没有同名 façade
  - `dispatch.pas` / `simd.pas` 没有公开 generic slot 消费
  - `tests/fafafa.core.simd*` 没有针对这些名字的 runtime/source 证明
- 因此，之前把其中一部分临时归类为“没有现成 scalar 真源，所以先不机械回收”，现在看已经不是最准判断。
- 更准确的结论是：
  - 它们不是“待统一的 fallback helper”；
  - 而是第二组没有消费面的 internal dead residue。
- 本批收法因此也从“考虑改成 scalar 真源”转为“直接移除错误保留的双轨死代码”：
  - 从 `riscvv.pas` 删除这 10 组 asm/assembler wrapper；
  - 从 `riscvv.helpers.inc` 删除对应 fallback 定义；
  - 不给它们补 register/facade，因为那会把 dead residue 硬升级成新 contract。
- 护栏同步继续扩严：
  - `check_nonx86_helper_semantics.py` 把这 10 组名字一并纳入 `require_routine_absent(...)`
  - 现在 source-side 会显式守住“这些名字必须不存在”
- fresh 复验结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=518 status=ok`
  - `RISCVV_ABI_SHAPE_SUMMARY direct_functions=121 explicit_checks=10 missing_result_store=0 suspicious_a0_loads=0 status=ok`
  - `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`
  - Release `check` 通过
  - Release `gate` 通过
- `gate` 尾部仍旧只有历史 `windows_b07_gate.log` 的 optional evidence 缺模式；这依然是旧 Windows 证据新鲜度问题，不是本批删减引入的实现或 contract 回归。

## 2026-05-15 RISCVV Dead Neg Residue Removal

- 在前两组清理之后，我专门又跑了一轮“只看非 `Asm` 名字”的 `RISCVV` 残留筛查。
- fresh 结果只剩最后两条：
  - `RISCVVNegF32x4`
  - `RISCVVNegF64x2`
- 继续追真实消费面后，结论和前两组一致：
  - `riscvv.pas` 里有 asm + wrapper
  - `riscvv.helpers.inc` 里有 fallback
  - 但 `riscvv.register.inc`、`riscvv.facade.inc`、`dispatch.pas`、`simd.pas`、`tests/fafafa.core.simd*` 都没有任何公开 contract 或验证消费
- 这说明它们不是“漏了一条负号公开 API”，而是最后两条保留下来的内部双轨死残留。
- 本批处理因此继续保持克制：
  - 从 `src/fafafa.core.simd.riscvv.pas` 删除 `RISCVVNegF32x4Asm/RISCVVNegF32x4` 与 `RISCVVNegF64x2Asm/RISCVVNegF64x2`
  - 从 `src/fafafa.core.simd.riscvv.helpers.inc` 删除对应 fallback
  - 不往 `register/facade/dispatch` 补新接线
- 这次额外做了一步收口审计：
  - fresh 扫描 `riscvv.pas + riscvv.helpers.inc` 中全部非 `Asm` 例程名
  - 再与 `register/facade/dispatch/simd.pas/tests/docs/plans` 交叉
  - 结果：`RESIDUE_COUNT=0`
- 护栏也同步补齐：
  - `check_nonx86_helper_semantics.py` 继续把 `RISCVVNegF32x4` 与 `RISCVVNegF64x2` 纳入 `require_routine_absent(...)`
- fresh 验证结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=522 status=ok`
  - `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`
  - `RISCVV_ABI_SHAPE_SUMMARY direct_functions=121 explicit_checks=10 missing_result_store=0 suspicious_a0_loads=0 status=ok`
  - Release `check` 通过
  - Release `gate` 通过
- 到这一刀为止，`RISCVV` 的“非 `Asm` internal residue”在 source-side 已被清到 `0`；剩余需要继续审的，就不再是这类同形死残留，而该转向别的 contract 面或别的 backend/文档层问题。

## 2026-05-15 NEON Dead Compare/Reduction/MinMax Residue Removal

- 在 `RISCVV` source-side residue 清到 `0` 之后，继续对 `NEON` 做同一口径的“只有定义、没有消费面”审查，fresh zero-ref 候选收敛为：
  - `NEONCmpNeU32x4`
  - `NEONReduceAddI32x4`
  - `NEONReduceMinI32x4`
  - `NEONReduceMaxI32x4`
  - `NEONReduceAddU32x4`
  - `NEONReduceMinU32x4`
  - `NEONReduceMaxU32x4`
  - `NEONMinI64x2`
  - `NEONMaxI64x2`
- 这批名字的共同点已经很明确：
  - 只出现在 `src/fafafa.core.simd.neon.compare.inc`
  - 或 `src/fafafa.core.simd.neon.scalar.reduction.inc`
  - 或 `src/fafafa.core.simd.neon.scalar.utility.inc`
  - 没有 `register/facade/runtime/simd.pas/tests/docs/plans` 的消费面
- 因此它们不是“NEON 缺一块能力没接上”，而是保留下来的 dead residue：
  - `compare.inc` 同时保留了 `CmpNeU32x4` 与 `I32x4/U32x4 reduction` 的 no-consumer 实现
  - `scalar.reduction.inc` 还维护着同名 fallback 第二份实现
  - `scalar.utility.inc` 还保留了 `Min/MaxI64x2` fallback 第二份实现
- 本批处理保持克制，只做 dead residue removal，不扩 contract：
  - 从 `neon.compare.inc` 删除 `NEONCmpNeU32x4`
  - 从 `neon.compare.inc` 删除 `NEONReduce(Add/Min/Max)I32x4/U32x4`
  - 从 `neon.scalar.reduction.inc` 删除对应 scalar fallback
  - 从 `neon.scalar.utility.inc` 删除 `NEONMinI64x2/NEONMaxI64x2`
- 为了防回流，`check_nonx86_helper_semantics.py` 本批新增：
  - `NEON_COMPARE_FILE`
  - 针对上述 15 个 `NEON` 名字的 `require_routine_absent(...)` source-side 缺席断言
- fresh 删除后再次扫 `NEON` 非 `_ASM` 零调用残留，只剩 7 个内部支撑名字：
  - `NEONCmpGeU64x2Wrapper`
  - `NEONCmpLeU64x2Wrapper`
  - `NEONCmpNeU32x4Wrapper`
  - `NEONCmpNeU64x2Wrapper`
  - `NEONCombineMask2To4`
  - `NEONCombineMask4To8`
  - `NEONCombineMask8To16`
- 这 7 个名字不是同类 dead residue：
  - 前 4 个是 `compare` 内部 wrapper/bridge
  - 后 3 个是 mask packing 支撑 helper
  - 它们不属于“total == defs 的零接线死代码”
- fresh 验证结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=537 status=ok`
  - `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`
  - Release `check` 通过
  - Release `gate` 通过
- `gate` 尾部仍然只把旧 `windows_b07_gate.log` 诚实降级为 optional `SKIP`；这继续是历史 Windows evidence 新鲜度问题，不是本批 `NEON` residue removal 引入的实现或 contract 回归。

## 2026-05-15 NEON Single-Use Compare Wrapper Inline Cleanup

- 上一批删完 `NEON` 零调用残留后，source-side 只剩 7 个内部 helper：
  - `NEONCmpGeU64x2Wrapper`
  - `NEONCmpLeU64x2Wrapper`
  - `NEONCmpNeU32x4Wrapper`
  - `NEONCmpNeU64x2Wrapper`
  - `NEONCombineMask2To4`
  - `NEONCombineMask4To8`
  - `NEONCombineMask8To16`
- fresh 交叉检索后，这 7 个名字其实分成两类，不能再一刀切：
  - `NEONCombineMask2To4/4To8/8To16` 在 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 内被大量 `I32/I64/U32/U64` 宽比较聚合复用，是真正的 live support helper
  - `NEONCmpLeU64x2Wrapper`、`NEONCmpGeU64x2Wrapper`、`NEONCmpNeU64x2Wrapper`、`NEONCmpNeU32x4Wrapper` 都只是 `MASK*_ALL_SET xor NarrowCmp*` 的单行反相薄壳，而且各自只服务一个聚合调用点
- 这说明第二类不是“死代码”，但仍然是低价值冗余：
  - 它们没有独立 contract
  - 不在 `register/facade/tests` 单独出现
  - 只是把一条一眼能读懂的反相表达式多包了一层局部函数
- 因此本批处理方式与上一批不同：
  - 保留 `NEONCombineMask2To4/4To8/8To16`
  - 删除 4 个 `Cmp*Wrapper`
  - 在 `NEONCmpGeU64x4`、`NEONCmpLeU64x4`、`NEONCmpNeU32x8`、`NEONCmpNeU64x4` 的 `NEONCombineMask*` 调用点直接内联 `TMask*(Byte(MASK*_ALL_SET) xor Byte(...))`
- 为了把“这些 wrapper 不该再回流”写成长期护栏，`check_nonx86_helper_semantics.py` 本批继续补了 source-side 缺席断言：
  - `NEONCmpLeU64x2Wrapper`
  - `NEONCmpGeU64x2Wrapper`
  - `NEONCmpNeU64x2Wrapper`
  - `NEONCmpNeU32x4Wrapper`
- fresh 验证结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=541 status=ok`
  - `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`
  - Release `check` 通过
  - Release `gate` 通过
- `gate` 最终尾部结论没有变化：
  - `run_all` 为 5/5 通过
  - non-x86 native evidence 仍因 root 不存在而 optional `SKIP`
  - `windows_b07_gate.log` 仍因历史缺模式而 optional `SKIP`
  - 因此这批 inline cleanup 仍然没有引入新的实现或 contract 回归。

## 2026-05-15 NEON Wide Float Memory Utility Asm Binding Repair

- 继续往 `NEON` 深审时，抓到的是一个真实接线缺口，不是新的抽象争论：
  - wide-float memory/utility 的 `_ASM` helper 早已存在
  - 但 asm 分支的 `register` 没有把这 16 个 slot 直接绑定过去
- `src/fafafa.core.simd.neon.scalar.wide_memory.inc` 已有以下 helper：
  - `NEONLoad/Store/Splat/ZeroF32x8_ASM`
  - `NEONLoad/Store/Splat/ZeroF32x16_ASM`
  - `NEONLoad/Store/Splat/ZeroF64x4_ASM`
  - `NEONLoad/Store/Splat/ZeroF64x8_ASM`
- `src/fafafa.core.simd.neon.register.inc` 原本只在 asm 分支直绑了 `I64x4` 同类 slot，wide-float 这批却还停留在 scalar companion 面。
- 这会让 asm build 下的 wide-float slot 继续被 scalar wrapper 阴影，和 `I64x4` 的 register truth 不一致。
- 本批修复保持最小范围：
  - 在 `neon.register.inc` 的 asm 分支新增 16 条 `table.* := @..._ASM`
  - 不改 no-asm policy
  - 不扩大到 façade/source companion 清理
- 为了把这个缺口写成长期护栏，`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 已新增 `Test_NEON_WideFloatMemoryUtilitySlots_Bind_AsmHelpers_When_Available`：
  - source-shape：断言 16 条 `@..._ASM` 绑定存在
  - runtime expectation：`FAFAFA_SIMD_TEST_NEON_ASM_COMPILED` 下 backend slot 必须 `<>` scalar slot，否则必须 `==`
- fresh 验证结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=541 status=ok`
  - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon assignments=427 asm_exact=224 asm_suffix_only=10 wrapper_only=193 miswired=0 strict=1`
  - Release `check` 通过
  - Release `gate` 通过
- `gate` 尾部结论保持诚实不变：
  - `run_all` 为 5/5 通过
  - non-x86 native evidence root 缺失仍是 optional `SKIP`
  - `windows_b07_gate.log` 仍是历史 Windows evidence 的 optional `SKIP`

## 2026-05-15 NEON Wide Float Asm Shadowing Fix

- 继续复核上一批 wide-float asm 接线后，发现前一版其实还没真正闭环：
  - `neon.register.inc` 前半段 321-336 已经新增了 `@NEON..._ASM`
  - 但后半段 465-548 又无条件把同一批 `Load/Store/Splat/Zero F32x8/F32x16/F64x4/F64x8` 重绑回 `@NEON...`
- 这意味着上一版 source-shape 虽然能证明“某处存在 `_ASM` binding”，却还抓不到“后面又被 wrapper 覆盖”的真实 shadowing。
- 进一步全仓检索后，16 个 `NEONLoad/Store/Splat/Zero` wide-float wrapper 也已被坐实成 dead code：
  - 只剩 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 定义
  - 加上 `src/fafafa.core.simd.neon.register.inc` 的 rebinding
  - 没有任何其他 `src/tests/docs/plans` 消费面
- 因此这批的正确修法不是再补一层 `_ASM` 赋值，而是：
  - 删除 `neon.register.inc` 后半段的 16 条 wrapper rebinding
  - 让 asm build 保留前半段 `_ASM` owned slot
  - 让 no-asm build 直接继承 `FillBaseDispatchTable` 的 base scalar slot
  - 从 `neon.scalar.autowrap.inc` 删除这 16 个已成 dead code 的 scalar-forwarder wrapper
- 这也把 wide-float slot 的 no-asm policy 对齐到了现有 `NEON_WideFallbackOnlySlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders` 的治理口径：
  - 只有纯 scalar forwarder 时，不再伪装成 backend-owned slot
- 为防止以后再出现“前面绑对、后面又覆盖”的回归，这批把护栏补到了两个层面：
  - `dispatchapi` 现在既断言 `_ASM` binding 存在，也断言后段 `@NEON...` rebinding 缺席，还断言 16 个 dead wrapper 已从 autowrap 删除
  - `check_nonx86_helper_semantics.py` 现在也把这 16 个名字纳入 absent guard
- fresh 验证结果说明这次不是纯文本清理，而是真正收掉了虚假的 backend-owned wrapper：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=557 status=ok`
  - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon assignments=411 asm_exact=224 asm_suffix_only=10 wrapper_only=177 scalar_passthrough=0 no_def=0 miswired=0 strict=1`
  - 相比上一版 `assignments=427 / wrapper_only=193`，正好少掉这批 16 个 shadowing wrapper assignment
- Release 级别结果仍保持稳定：
  - `impl-audit-nonx86` 通过
  - `check` 通过
  - `gate` 通过
- 当前 `freeze-status` 重新核实后依旧只红在发布证据链：
  - `qemu-cpuinfo-nonx86-evidence=SKIP`
  - `windows_b07_gate.log` / `windows_b07_closeout_summary.md` stale
  - `windows evidence verify` 失败
- `win-evidence-preflight` 仍返回 `RECENT_BILLING_BLOCK`，因此当前剩余 release gap 继续是外部 Windows runner/billing 问题，而不是 SIMD 代码面还有新的 active bug。

## 2026-05-15 Register Truthfulness Shadowing Guard Upgrade

- 上一批 `NEON` wide-float shadowing bug 已经修掉，但它也暴露了一个更深的审计盲点：
  - `check_nonx86_register_truthfulness.py` 之前只逐条给 assignment 做 `asm_exact / wrapper_only / scalar_passthrough / ...` 分类
  - 只要每一条单独看都“像是合法 target”，脚本就可能继续给出 `miswired=0`
  - 因此“前面先绑对、后面又被另一个 target 覆盖”的 overlapping rebinding，过去是可能漏过的
- 这次把那条经验升成了通用 fail-close 护栏，而不是继续靠人工肉眼扫 `register.inc`：
  - `check_nonx86_register_truthfulness.py` 新增 `contexts_overlap(...)`
  - 规则很保守：`always` 与所有上下文重叠；其余只有相同 context 才算重叠
  - `build_report(...)` 现在会先保留同一 slot 的全部 assignment record，再按 slot 交叉检查“不同 target + 重叠 context”
  - 一旦命中，会同时：
    - 给两条 record 都补 `overlapping-slot-rebinding`
    - 在 human 输出里打印 `conflicting assign`
    - 把对方行号/target/context 填进 `conflicts=...`
- 为了把这类回归稳定固化，新增了 fixture：
  - `tests/fafafa.core.simd/fixtures/nonx86_register_truthfulness/shadowed/mock.backend.register.inc`
  - `tests/fafafa.core.simd/fixtures/nonx86_register_truthfulness/shadowed/mock.backend.pas`
  - 模式就是这次 `NEON` 真实 bug 的抽象版：
    - `{$IFDEF MOCK_ASM}` 先把 slot 绑到 `@MOCKSuffix_ASM`
    - 后面再无条件绑回 `@MOCKWrapper`
  - 旧 checker 只会看到“两条 assignment 都有定义”；新 checker 现在会 fail-close 报 overlapping rebinding
- 这批的价值在于，它把“source-side 有 `_ASM` binding”提升成“最终有效 slot ownership 没有被后续冲掉”：
  - 不再只证明“某处绑过”
  - 而是开始证明“不会在同一生效上下文里被另一个 target 重绑”
- 这也解释了为什么上一批 `NEON` 修复之后，下一步不是继续删 wrapper，而是先补 checker：
  - 真正高价值的是防住同类型 bug 再次溜过
  - 这比继续做又一轮 family-local 手工扫尾更能提升整个 non-x86 审计链的可信度
- fresh 复验目标也很清晰：
  - fixture `good` 继续 PASS，避免误伤已有合法模式
  - fixture `bad` 继续 FAIL，保住旧 fail-close 语义
  - fixture `shadowed` 必须新失败，证明 overlapping rebinding 已被稳定抓住
  - 真实 `neon` / `riscvv` 后端继续保持 `miswired=0` 且 `conflicting assign=0`
  - Release `impl-audit-nonx86`、`check`、`gate` 继续全绿，说明这批是审计护栏升级，不是运行时行为变更
- fresh 结果与预期一致：
  - `fixture-good`：PASS，`miswired=0 conflicting assign=0`
  - `fixture-bad`：FAIL，`miswired=2 conflicting assign=0`
  - `fixture-shadowed`：FAIL，`miswired=2 conflicting assign=2`，两条 assignment 都会带上 `overlapping-slot-rebinding`
  - `backend=neon`：`assignments=411 ... miswired=0 conflicting assign=0`
  - `backend=riscvv`：`assignments=473 ... miswired=0 conflicting assign=0`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `check` / `gate` 继续通过，`gate` 尾部仍只剩 optional non-x86 native evidence skip 与历史 Windows evidence skip

## 2026-05-15 NEON No-Asm Float Compare Scalar-Forwarder Cleanup

- 下一层真实冗余并不在 asm path，而是在 `NEON` 的 no-asm compare fallback 面：
  - `src/fafafa.core.simd.neon.register.inc` 里有 24 条 `CmpEq/Ge/Gt/Le/Lt/Ne × {F32x16,F32x8,F64x4,F64x8}` assignment
  - 这些 assignment 都落在 no-asm 分支
  - 对应 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 函数体全部只是单行 `Result := ScalarCmp...`
- 这意味着它们和前面已经清掉的 wide-fallback dead wrapper 属于同一种“伪 backend-owned”问题：
  - backend 没有提供本地 no-asm compare 行为
  - wrapper 也没有额外语义，只是在 register 里换了个 `NEON...` 名字
  - 真正的 published truth 仍然来自 `FillBaseDispatchTable` 里的 scalar slot
- 进一步全仓交叉检索后，信号更强：
  - 大多数名字全仓只剩 `register + autowrap` 两处
  - 少数额外命中也只是 legacy docs/plan snapshot，不是活代码消费面
  - 与之相对，`F64x2` compare 仍保留 no-asm 本地 loop 语义，不属于这批 dead scalar-forwarder
- 因此正确修法不是继续把它们保留在 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']`，而是把 no-asm compare policy 收回 base scalar：
  - 从 `neon.register.inc` 删除 24 条 no-asm compare assignment
  - 从 `neon.scalar.autowrap.inc` 删除对应 24 个 dead scalar-forwarder wrapper
  - 保留 `Cmp*F64x2` 作为 backend-owned 例外
- 这批同时把护栏补成了三层：
  - `dispatchapi`：新增 `Test_NEON_NoAsmFloatCompareSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`，同时断言 register 缺席、dead wrapper 缺席、运行时 slot 仍与 scalar 相等
  - `check_nonx86_helper_semantics.py`：新增 24 个 absent guard，防止 wrapper 又被带回来
  - `check_nonx86_register_truthfulness.py`：把这 24 个 slot 从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 中移除，防止 future rebinding 再被“允许 wrapper”静默放过
- fresh 结果说明这次不是简单删代码，而是真正收缩了 non-x86 truthfulness 冗余面：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=581 status=ok`
  - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon assignments=387 asm_exact=224 asm_suffix_only=10 wrapper_only=153 scalar_passthrough=0 no_def=0 miswired=0 strict=1`
  - 相比上一批 `assignments=411 / wrapper_only=177`，正好少掉这 24 个 no-asm float compare scalar-forwarder assignment
  - `backend=riscvv` 保持 `assignments=473 / wrapper_only=26 / miswired=0`
  - `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`
  - Release `check` / `gate` 继续通过，`gate` 尾部仍只剩 optional non-x86 native evidence skip 与历史 Windows evidence skip

## 2026-05-15 NEON Wide Rcp/Reduction Scalar-Forwarder Cleanup

- `NEON` 的 `wrapper_only` 余量里还有一簇更隐蔽的假 backend-owned slot：
  - `RcpF64x4`
  - `ReduceAdd/Max/Min/Mul × {F32x16,F32x8,F64x4,F64x8}`
  - 对应 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 函数体全部只是直接转发到 `Scalar*`
- 这批与前一批 compare 不同的点在于：其中多数 assignment 不是 no-asm 专属，而是始终在 `neon.register.inc` 里绑定 `NEON...` 名字。
  - 也就是说，即使在 asm 编译路径下，这些 wide slot 仍只是“靠 wrapper 名字伪装成 backend-owned”，不代表真的有 NEON-local 行为。
  - `F64x2` reductions 仍保留 backend-local 实现，不属于这批 dead wrapper。
- 进一步复核后确认 `RcpF64x4` 在当前 `NEON` 上也没有额外合同：
  - `NEONRcpF64x4` 只是 `Result := ScalarRcpF64x4(a);`
  - `ScalarRcpF64x4` 当前也只是逐 lane `1.0 / a.d[i]`
  - 因此它和这批 wide reductions 一样，都应回落到 base scalar truth
- 这批同时暴露出一处测试口径偏乐观：
  - `TTestCase_NonX86BackendParity.Test_NativeF64ReduceAddSeedParity_WithVectorAsm_IfAvailable` 之前会对 `NEON` 和 `RISCVV` 一起断言 `ReduceAddF64x4/F64x8` slot “不应等于 scalar”
  - 但对 `NEON` 来说，这只是 wrapper 身份假象，并非真实 backend-owned 行为
  - 因此测试也应改成“`NEON` 诚实复用 scalar slot，`RISCVV` 仍要求 native slot”
- 正确修法为四层联动：
  - 从 `neon.register.inc` 删除 `RcpF64x4` 与 16 个 wide reduction assignment
  - 从 `neon.scalar.autowrap.inc` 删除对应 17 个 dead scalar-forwarder wrapper
  - `dispatchapi` 新增 `Test_NEON_WideRcpAndReductionSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
  - 同步修正 `Test_NativeF64ReduceAddSeedParity_WithVectorAsm_IfAvailable` 的 ownership 断言口径
  - `check_nonx86_helper_semantics.py` 增加这 17 个 absent guard
  - `check_nonx86_register_truthfulness.py` 把这 17 个 slot 从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 中移除
- fresh 结果继续证明这是“真收缩”而不是只改名字：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=598 status=ok`
  - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon assignments=370 asm_exact=224 asm_suffix_only=10 wrapper_only=136 scalar_passthrough=0 no_def=0 miswired=0 strict=1`
  - 相比上一批 `assignments=387 / wrapper_only=153`，正好又少掉这 17 个 wide scalar-forwarder assignment
  - `backend=riscvv` 继续保持 `assignments=473 / wrapper_only=26 / miswired=0`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86BackendParity` 通过
  - Release `check` / `gate` 继续通过，`gate` 尾部结论不变：只剩 optional non-x86 native evidence skip 与历史 Windows evidence skip

## 2026-05-15 NEON No-Asm Abs/Wide FloorCeil Scalar-Forwarder Cleanup

- `NEON wrapper_only` 继续往下收时，下一簇真实假 backend-owned slot 出现在 no-asm 的 `Abs` / wide `Floor/Ceil`：
  - `Abs × {F32x16,F32x8,F64x2,F64x4,F64x8}`
  - `Ceil × {F32x16,F32x8,F64x4,F64x8}`
  - `Floor × {F32x16,F32x8,F64x4,F64x8}`
- 这 13 个名字在 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 里都只是 exact `Scalar*` 单行转发，因此和前两批 compare / reduction 一样，不该继续伪装成 backend-owned slot。
- 这批唯一需要显式停手的例外是：
  - `NEONCeilF64x2`
  - `NEONFloorF64x2`
- 它们在 no-asm 路径里仍然保留 backend-local loop：
  - `Result.d[0] := Ceil/Floor(a.d[0])`
  - `Result.d[1] := Ceil/Floor(a.d[1])`
  - 因此它们不是 dead scalar-forwarder，不能和 wide family 一起机械删除。
- 正确修法仍是“回落 published truth，而不是硬造新 helper”：
  - 从 `src/fafafa.core.simd.neon.register.inc` 删除 13 条 no-asm assignment
  - 从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除对应 13 个 dead wrapper
  - 保留 `CeilF64x2` / `FloorF64x2`
- 这批还暴露出旧测试口径偏乐观的问题：
  - `TTestCase_DispatchAPI.Test_NonX86_NativeWideFloorCeil_Slots_NotScalar_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeWideFloorCeilSlots_NotScalar_IfAvailable`
- 上述两条旧测试之前会把 `NEON` 的 wide `Floor/Ceil` 与 `Abs` 统一当成 native-slot。
- 但源码事实已经表明：
  - `NEON` 在这些 no-asm slot 上只是 scalar forwarder，应断言 `scalar-slot reuse`
  - `RISCVV` 的对应 wide `Floor/Ceil` 仍保留 native/backend-local 路径，应继续断言 `backend slot <> scalar slot`
- 因此这批不是单纯删函数，而是把三层真相一起收正：
  - `dispatchapi` 新增 `Test_NEON_NoAsmAbsAndWideFloorCeilSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
  - 两条旧 `wide Floor/Ceil` 测试改成“NEON 复用 scalar，否则 native”
  - `check_nonx86_helper_semantics.py` 把这 13 个名字从 routine expectation 改成 absent guard
  - `check_nonx86_register_truthfulness.py` 把这 13 个 slot 从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 中移除
- fresh 结果继续证明这批是“真收缩 truthfulness 冗余”，不是只改文案：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=598 status=ok`
  - `backend=neon`：`assignments=357 asm_exact=224 asm_suffix_only=10 wrapper_only=123 miswired=0 conflicting assign=0`
  - 相比上一批 `assignments=370 / wrapper_only=136`，正好少掉这 13 个 no-asm `Abs/Floor/Ceil` scalar-forwarder assignment
  - `backend=riscvv` 继续保持 `assignments=473 ... wrapper_only=26 ... miswired=0`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86BackendParity` 通过
  - Release `check` / `gate` 继续通过，`gate` 末尾仍只剩 optional non-x86 native evidence skip 与历史 Windows evidence skip

## 2026-05-15 NEON No-Asm FMA Scalar-Forwarder Cleanup

- `NEON wrapper_only` 再往下看时，`Fma` 家族的治理边界和前两批不一样：
  - `NEONFmaF32x4` 在 `src/fafafa.core.simd.neon.scalar.ext_math.inc` 的 no-asm 版本只是 `Result := ScalarFmaF32x4(a, b, c);`
  - `NEONFmaF32x16/F32x8/F64x2/F64x4/F64x8` 在 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 的 no-asm 版本也都只是 exact `ScalarFma*` forwarder
- 但它们不是纯 dead name，因为同名符号在 `src/fafafa.core.simd.neon.pas` 里仍有真实 asm 实现：
  - `NEONFmaF32x4`
  - `NEONFmaF32x8`
  - `NEONFmaF64x2`
  - `NEONFmaF64x4`
  - `NEONFmaF32x16`
  - `NEONFmaF64x8`
- 这意味着这批不能像 compare / reduction / abs-floor-ceil 一样简单“删 assignment”：
  - asm build 仍需要这些 `register` binding 去连真实 backend-local helper
  - no-asm build 才应该回落到 `FillBaseDispatchTable` 的 base scalar slot
- 所以这批的正确修法是“asm-only binding”，不是“全局删掉 slot 名字”：
  - 把 `register.inc` 中 `FmaF32x4/F32x16/F32x8/F64x2/F64x4/F64x8` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - 删除 `scalar.ext_math.inc` / `scalar.autowrap.inc` 中那 6 个 no-asm dead scalar-forwarder wrapper
  - 让 no-asm `NEON` backend 直接继承 base scalar `Fma` slot
- 这批同时说明 `register truthfulness` 统计值不一定只看 assignment 总数：
  - assignment 仍是 `357`
  - 但 `asm_exact` 从 `224` 升到 `229`
  - `wrapper_only` 从 `123` 降到 `118`
- 原因正是这 5 个 wide `Fma` slot 没有被“删出 register 文件”，而是从“wrapper-only/上下文不诚实”改成了“asm-only/exact asm owner”。
- `FmaF32x4` 之前就不在 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 里，这次仍然说明同一个 slot 的治理方式要看 `asm/no-asm` 双轨真相，而不是只看 no-asm body。
- 因此这批补的护栏也和前两批不同：
  - `dispatchapi` 新增 `Test_NEON_NoAsmFMASlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
  - 这条测试在 no-asm 编译下断言：
    - `scalar.ext_math.inc` / `scalar.autowrap.inc` 里的 6 个 dead wrapper 缺席
    - `register.inc` 里 asm binding source 仍然存在
    - 运行时 `sbNEON` 的 `FmaF32x4/F32x16/F32x8/F64x2/F64x4/F64x8` slot 全部与 scalar slot 相等
  - `check_nonx86_helper_semantics.py` 把这 6 个名字从 routine expectation 改成 absent guard
  - `check_nonx86_register_truthfulness.py` 把 wide `Fma` slot 从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 中移除
- fresh 结果表明这批不是只做条件编译整理，而是真把 no-asm ownership 收正了：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=598 status=ok`
  - `backend=neon`：`assignments=357 asm_exact=229 asm_suffix_only=10 wrapper_only=118 miswired=0 conflicting assign=0`
  - 相比上一批 `assignments=357 asm_exact=224 wrapper_only=123`，正好把 5 个 wide `Fma` slot 从 `wrapper_only` 收进了 `asm_exact`
  - `backend=riscvv` 继续保持 `assignments=473 ... wrapper_only=26 ... miswired=0`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `check` / `gate` 继续通过，`gate` 末尾仍只剩 optional non-x86 native evidence skip 与历史 Windows evidence skip

## 2026-05-15 NEON No-Asm Narrow Reciprocal Scalar-Forwarder Cleanup

- `Rcp/RsqrtF32x4` 是比窄 `Add/Sub/Mul/Div/Abs/Sqrt` 更干净的下一刀：
  - `NEONRcpF32x4`
  - `NEONRsqrtF32x4`
- 它们在 `src/fafafa.core.simd.neon.scalar.ext_math.inc` 的 no-asm 版本都只是 exact `ScalarRcp/RsqrtF32x4` forwarder。
- 同时，这两个名字在 `src/fafafa.core.simd.neon.pas` 里仍然有真实 asm owner：
  - `frecpe v0.4s, v0.4s`
  - `frsqrte v0.4s, v0.4s`
- 更重要的是，这两个名字没有像 `NEONAddF32x4` / `NEONSqrtF32x4` 那样被宽向量 no-asm 组合路径复用。
- 这让它们可以采用最干净的 `Fma` 式治理，而不用保留 no-asm source companion：
  - `register.inc` 把 `RcpF32x4/RsqrtF32x4` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `scalar.ext_math.inc` 里的 2 个 no-asm dead wrapper 可以直接删除
  - no-asm runtime 下由 `FillBaseDispatchTable` 直接提供 scalar slot
- 这批和上一批 `Fma` 的一个细节差异也需要记住：
  - `register truthfulness` 汇总数值没有变化，仍是 `assignments=357 asm_exact=229 wrapper_only=118`
  - 说明这 2 个 slot 在 checker 的当前分类里本来就没有形成额外的 `wrapper_only` 计数
  - 但 runtime/source truth 仍然是值得修的，因为 no-asm 下它们之前确实还占着 `NEON` dispatch slot
- 因此这批价值主要体现在“补 runtime truth 护栏”，而不是再压低 summary 数字：
  - `dispatchapi` 新增 `Test_NEON_NoAsmNarrowReciprocalSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
  - 这条测试在 no-asm 编译下断言：
    - `scalar.ext_math.inc` 中 `NEONRcpF32x4/NEONRsqrtF32x4` dead wrapper 缺席
    - `register.inc` 中 asm binding source 仍在
    - 运行时 `sbNEON` 的 `RcpF32x4/RsqrtF32x4` slot 都与 scalar slot 相等
  - `check_nonx86_helper_semantics.py` 把这 2 个名字改成 absent guard，防止以后又把 dead wrapper 带回来
- fresh 结果说明这批确实把 no-asm ownership 收正了，而不是只删文本：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=598 status=ok`
  - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon assignments=357 asm_exact=229 asm_suffix_only=10 wrapper_only=118 scalar_passthrough=0 no_def=0 miswired=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `check` / `gate` 继续通过
  - `gate` 尾部结论没有变化：仍只剩 optional non-x86 native evidence skip 与历史 Windows evidence skip

## 2026-05-15 NEON No-Asm F32x8 Arithmetic Dead-Wrapper Cleanup

- `Add/Sub/Mul/DivF32x8` 是比 `Add/Sub/Mul/DivF32x4` 更适合马上下手的一簇：
  - `src/fafafa.core.simd.neon.scalar_fallback.inc` 里的 no-asm 版本都只是 exact `Scalar*F32x8` forwarder
  - `src/fafafa.core.simd.neon.pas` 里同名函数仍然有真实 asm owner
  - 全仓源码检索确认没有任何更宽 no-asm 组合路径继续消费 `NEONAdd/Sub/Mul/DivF32x8`
- 这和 `NEONAdd/Sub/Mul/DivF32x4` 的关键差别在于：
  - `F32x4` 仍被 `NEONAdd/Sub/Mul/DivF32x16` no-asm 组合路径引用
  - `F32x8` 则已经是 no-asm source graph 的叶子，slot 之外再无 live consumer
- 因此这批可以采用和 `Fma/Rcp` 相同的最干净治理：
  - `register.inc` 中 `Add/Sub/Mul/DivF32x8` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `scalar_fallback.inc` 中 4 个 no-asm dead wrapper 直接删除
  - no-asm runtime 下由 `FillBaseDispatchTable` 提供 scalar slot
- 这批还暴露出一个之前漏收的测试口径问题：
  - `dispatchapi` 两处通用 capability 断言此前仍把 `Add/Sub/Mul/DivF32x8` 写成“non-x86 总是 native slot”
  - 这与当前更诚实的 no-asm truth 冲突
  - 已同步改成和 `Abs/Floor/Ceil` 一样的口径：
    - `NEON` 在 no-asm 下复用 scalar slot
    - 其他 backend 仍要求 native slot
- 专门护栏也已补上：
  - `Test_NEON_NoAsmWideF32x8ArithmeticSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
  - 它断言：
    - `scalar_fallback.inc` 中 4 个 dead wrapper 缺席
    - `register.inc` 中 asm binding source 仍在
    - 运行时 `sbNEON` 的 `Add/Sub/Mul/DivF32x8` slot 都与 scalar slot 相等
- fresh 结果表明这批是 runtime/source/checker 三线一致的收正：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=598 status=ok`
  - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon assignments=357 asm_exact=229 asm_suffix_only=10 wrapper_only=118 scalar_passthrough=0 no_def=0 miswired=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 通过
  - Release `check` / `gate` 继续通过，尾部仍只剩 optional non-x86 native evidence skip 与历史 Windows evidence skip

## 2026-05-15 NEON No-Asm Wide Leaf Float Arithmetic Slot-Ownership Cleanup

- `Add/Sub/Mul/DivF32x16` 与 `Add/Sub/Mul/DivF64x8` 是下一层值得收正的 wide leaf arithmetic slot：
  - 它们在 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 里始终存在
  - 不像 `F32x8` 那样是 no-asm dead wrapper，因为 asm build 也需要这些组合 wrapper 作为宽向量 owner
  - 但在 no-asm build 下，它们只是组合更小宽度 helper，没有独立 backend-local 语义
- 这批和上一批 `F32x8` 的治理差别必须明确：
  - `F32x8`：wrapper 可以删，slot 也回落到 scalar
  - `F32x16/F64x8`：wrapper 不能删，只能把 no-asm runtime slot ownership 收正到 scalar
- 因此这批的正确治理是：
  - `register.inc` 中 `Add/Sub/Mul/DivF32x16`
  - `register.inc` 中 `Add/Sub/Mul/DivF64x8`
  - 都改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `scalar.autowrap.inc` 中 8 个 wrapper 继续保留
- 这批还补了一个和上一批不同类型的护栏：
  - `Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar`
  - 它在 no-asm 编译下断言：
    - `scalar.autowrap.inc` 中 8 个 wrapper 仍然存在
    - `register.inc` 中 asm binding source 仍在
    - 运行时 `sbNEON` 的 `Add/Sub/Mul/DivF32x16` 与 `Add/Sub/Mul/DivF64x8` slot 都与 scalar slot 相等
- 通用 capability 断言也已同步收正：
  - 两处 `DispatchAPI` 宽浮点 capability 断言原先都把这些 slot 写成“总是 native”
  - 现在已改成“NEON 在 no-asm 下复用 scalar，其他 backend 仍要求 native”
- fresh 结果说明这批没有破坏 source/runtime contract：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 通过
  - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon assignments=357 asm_exact=229 asm_suffix_only=10 wrapper_only=118 scalar_passthrough=0 no_def=0 miswired=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `check` / `gate` 继续通过，尾部仍只剩 optional non-x86 native evidence skip 与历史 Windows evidence skip

## 2026-05-15 NEON No-Asm Wide Clamp Findings

- `Clamp` 这批的真实分界不在“宽度”，而在底层叶子 helper 是否仍携带 backend-local fallback 语义：
  - `NEONClampF32x8/F32x16` 在 no-asm 下只是 `NEONClampF32x4` 的分段 forwarder，而 `NEONClampF32x4` 本身又是 exact `ScalarClampF32x4`
  - `NEONClampF64x2` 则仍是本地 `if/else` loop，不是 `ScalarClampF64x2` 的单行转发
- 本地 Pascal probe 已把 `F64x2` 的语义差异钉实：
  - `a=NaN, min=0, max=10` 时，scalar `Clamp` 会折到 `max`
  - no-asm `NEONClampF64x2` 会保留 `NaN`
  - `a=-0, min=0, max=0` 时，scalar `Clamp` 会归一成 `+0`
  - no-asm `NEONClampF64x2` 会保留 `-0`
- 因此这批不能像 `Sqrt/MinMax` 一样把 `F64x4/F64x8` 一起回到 scalar：
  - `F32x8/F32x16`：dead wrapper，可删，slot 应回 scalar truth
  - `F64x2/F64x4/F64x8`：仍携带或消费本地 `F64x2` fallback 语义，继续 backend-owned
- 正确收法已经落地成三条护栏：
  - `src/fafafa.core.simd.neon.register.inc` 中 `ClampF32x8/F32x16` 改成 asm-only binding，`F64x2/F64x4/F64x8` 保持 backend-owned
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 `NEONClampF32x8/F32x16` dead wrapper，保留 `NEONClampF64x2/F64x4/F64x8`
  - `dispatchapi` 新增 no-asm witness 测试，用 `ClampF64x2` 的 `NaN/-0` case 直接证明为什么 `F64` 链不能回 scalar
- fresh 现场数据继续支持这是实质性收正，而不是只动注释：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=605 status=ok`
  - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon assignments=357 asm_exact=239 asm_suffix_only=10 wrapper_only=108 scalar_passthrough=0 no_def=0 miswired=0 strict=1`
  - `backend=riscvv` 继续保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 miswired=0`
- `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
- Release `check` / `gate` 全部通过，`gate` 最终明确到 `GATE OK`
- 这批同时再次验证了后续审查纪律：
  - 不能只看 wrapper 形状决定去重
  - 必须先证明 helper contract 是否与 scalar truth 等价
  - `Clamp/Round/Trunc` 仍是比 `Sqrt/MinMax` 更容易藏语义例外的族

## 2026-05-15 Register Truthfulness Mixed-Body Classification Findings

- `check_nonx86_register_truthfulness.py` 这次暴露出的高价值问题，不在 backend 源码，而在 checker 自己对 mixed body 的分类模型：
  - `collect_symbol_facts(...)` 会把同名非 assembler 定义全部收进 `SymbolFacts.bodies`
  - 旧版 `detect_wrapper_kind(...)` 却把这些 body 直接拼成一个大字符串
  - 结果只要其中任一 body 调用了 `Scalar*`，整个 target 就会被误判成 `scalar_forwarder`
- `NEONSelectF32x4` 是真实仓库里的直接 witness：
  - `src/fafafa.core.simd.neon.pas` 中有本地 per-lane `NEONSelectF32x4` 实现
  - `src/fafafa.core.simd.neon.scalar.utility.inc` 中又有同名 `NEONSelectF32x4`，其 body 为 `Result := ScalarSelectF32x4(mask, a, b);`
  - 旧 checker 会因为拼接后的大字符串里看到了 `ScalarSelectF32x4(`，把整个 target 误报成 `('wrapper_only', 'scalar_forwarder', None)`
  - 但更真实的分类应是 `('wrapper_only', 'pascal_owned', None)`，因为它至少有一份 body 明确是 backend-local Pascal owner，而不是纯 forwarder
- 这说明当前 residual 图不能只看“slot 名字是否 mixed”，更要看 mixed 的哪一份 body 才代表该 target 的 owner 语义：
  - “任一 body 是 scalar” 不代表 “整个 target 只是 scalar forwarder”
  - 真正需要 fail-close 的，是“所有可生效 body 都只是 scalar forwarder”或“只有 asm helper forwarder”
- 因此新的分类优先级必须是逐 body、而不是拼接后扫关键字：
  - 只要任一 body 是非 scalar 的本地实现，整 target 就应回到 `pascal_owned`
  - 若没有 `pascal_owned`，但存在调用 `*_ASM` / `*Asm` 的 body，才归到 `asm_helper_forwarder`
  - 只有在所有 body 都只是 `Scalar*` 转发时，才归到 `scalar_forwarder`
- 新增的 `mixed` fixture 不是为了把报告“做漂亮”，而是为了锁住这类真实误判：
  - `mock.backend.pas` 人工制造一份本地 body 和一份 `ScalarMixed` forwarder body
  - `mock.backend.register.inc` 故意把 `@MOCKMixed` 绑在 `{$IFDEF MOCK_ASM}` 分支里
  - 在新逻辑下，它应继续 FAIL，但失败原因必须是 `wrapper-only-bound-inside-asm-block`
  - 如果以后分类又退回“拼 body 扫关键字”，这个 fixture 就会把错误行为重新抓出来
- 这批修复的价值是把 residual 图重新对准“源码真实 owner”，而不是让 summary 数字更好看：
  - `NEONSelectF32x4` 已从误判的 `scalar_forwarder` 回到 `pascal_owned`
  - 当前 `NEON` 的 `asm-only + scalar_forwarder` 分组从 `16` 降到 `15`
  - 这减少的是 checker 误报，不是运行时 slot 语义被偷偷改写

## 2026-05-15 NEON Extract/Insert/Select Scalar-Only Slot Findings

- mixed-body 分类修正后，`NEON` 残余的 `asm-only + scalar_forwarder` 正好只剩 15 个 slot：
  - `ExtractF32x16/F32x8/F64x4/I32x4/I64x2`
  - `InsertF32x16/F32x8/F64x4/I32x4/I64x2`
  - `SelectF32x16/F32x8/F64x4/F64x8/I32x4`
- 这 15 个名字的 source truth 非常干净：
  - 全仓只命中 `src/fafafa.core.simd.neon.register.inc`
  - 以及 `src/fafafa.core.simd.neon.scalar.autowrap.inc`
  - `autowrap` 里的 body 全部是 exact `Result := Scalar...`
  - 没有任何更宽 no-asm source graph 或其他单元继续消费它们
- 因此这批和 earlier `Clamp/Sqrt/MinMax` 的“保留 source companion”不同：
  - 这里不是“no-asm slot 不该 backend-owned，但 wrapper 仍有 source 价值”
  - 而是“wrapper 本身已经彻底 dead，slot truth 和 source truth 都该一起收回 scalar”
- `dispatchapi` 这轮暴露出的阻塞并非行为回归，而是 testcase 局部 helper 作用域被误插入到了相似模板过程里：
  - `Test_NativeNarrowHelperSurfaceParity_WithVectorAsm_IfAvailable`
  - `Test_NativeWideInsertHelperParity_WithVectorAsm_IfAvailable`
  - `Test_NativeNarrowIntegerCoreParity_WithVectorAsm_IfAvailable`
  - `Test_NativeNarrowIntegerHelperParity_WithVectorAsm_IfAvailable`
  - 都需要各自拥有本地 `AssertBackendOwnedSlotIfExpected` / `AssertBackendOwnedFloatSlotIfExpected`
- 另外，新 testcase 收尾时直接调用 `InvalidateSimdDataPlane` 也暴露出一条边界纪律：
  - `InvalidateSimdDataPlane` 是 `fafafa.core.simd.dataplane` 的实现细节，不在接口面
  - 测试应调用公开的 `RebindSimdDataPlane`，而不是碰内部 invalidation hook
- 本批收正后，checker/runtime/test 三线重新对齐：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=625 status=ok`
  - `backend=neon` truthfulness：`assignments=342 asm_exact=244 asm_suffix_only=10 wrapper_only=88 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `DispatchAPI` / `check` / `gate` 全绿
- 关键结论：
  - mixed-body 修正后残留的 `NEON asm-only + scalar_forwarder` 已归零
  - `backend=neon wrapper_only` 已从上一批的 `103` 降到 `88`
  - 这一批收掉的是“已无 source consumer 的真死壳”，不是仅仅把 allowlist 做漂亮

## 2026-05-15 NEON Narrow F64x2 Memory/Construction Slot Findings

- 当前最干净的下一簇 residual 是 4 个 narrow `F64x2` memory/construction slot：
  - `LoadF64x2`
  - `StoreF64x2`
  - `SplatF64x2`
  - `ZeroF64x2`
- 这 4 个名字的 source truth 比 `Clamp/Sqrt/MinMax` 更简单：
  - 全仓 `src/` 内只命中 `src/fafafa.core.simd.neon.pas`
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
  - `src/fafafa.core.simd.neon.register.inc`
  - 没有其他 live source consumer
- 因此这批不属于“保留 source companion 但回收 runtime slot”的类型，而是更纯粹的 dead wrapper 清理：
  - asm build 里真实 owner 仍是 `src/fafafa.core.simd.neon.pas` 的 assembler leaf
  - no-asm build 里的 `autowrap` body 已经没有独立存在价值
  - 发布后的 `sbNEON` slot 也不该继续伪装成 backend-owned
- 这批还有一个行为层面的额外收益：
  - `ScalarLoadF64x2/ScalarStoreF64x2` 自带 `Assert(p <> nil, ...)`
  - 旧 no-asm `NEONLoadF64x2/StoreF64x2` 本地 body 没有显式 nil assert
  - 当 runtime slot 回到 scalar 后，no-asm 下的 `Load/StoreF64x2` 会自然继承 base scalar 的指针契约，而不是继续保留一份较弱的本地副本
- `DispatchAPI` 这批除了 dedicated test，还同步收正了两个通用 capability 判断：
  - `Test_NativeNarrowHelperSurfaceParity_WithVectorAsm_IfAvailable` 中 `LoadF64x2/SplatF64x2`
  - `Test_NativeAlignedLoadAndZeroParity_WithVectorAsm_IfAvailable` 中 `ZeroF64x2`
  - 它们都不再把 NEON 写死为“总是 native”，而是跟随当前 backend truth
- fresh 结果证明这 4 个 slot 已真正从 residual 集合里退出：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=629 status=ok`
  - `backend=neon` truthfulness：`assignments=342 asm_exact=248 asm_suffix_only=10 wrapper_only=84 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - 相比上一批 `wrapper_only=88`，这批正好又减少了 4 个 slot
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `DispatchAPI` / `check` / `gate` 全绿，`gate` 最终仍是 `GATE OK`
- 关键结论：
  - 这批收掉的是“已无 source consumer 的 narrow F64x2 memory/construction 死壳”
  - 不是只改 checker allowlist，也不是只改 capability 注释
  - runtime no-asm truth、source truth、checker truth 已重新对齐

## 2026-05-15 NEON No-Asm F64x4 Wide Leaf Arithmetic Slot Findings

- `Add/Sub/Mul/DivF64x4` 和上一批 `F64x2` 最大的区别，不在语义，而在 source graph：
  - `NEONAdd/Sub/Mul/DivF64x4` 的 no-asm body 都只是两次 `NEON*F64x2`
  - 但 `NEONAdd/Sub/Mul/DivF64x8` 仍通过 `Result.lo := NEON*F64x4(...); Result.hi := NEON*F64x4(...);` 继续消费这些 wrapper
  - 所以这批不能像 `Load/Store/Splat/ZeroF64x2` 那样删 wrapper，只能回收 runtime slot ownership
- 这使它们和此前 `F32x16/F64x8` 那一批 wide leaf arithmetic 完全同型：
  - wrapper 继续作为 asm build / 更宽 no-asm graph 的 source companion
  - no-asm published `sbNEON` slot 不再占着 fake backend-owned truth
- 现有 `DispatchAPI` 里已经有最合适的 dedicated truth test：
  - `Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar`
  - 这次不需要新增新 testcase，只需把 `F64x4` 的 12 个断言补进去：
    - wrapper 仍在
    - asm binding source 仍在
    - runtime slot 与 scalar slot 相等
- 通用 capability 断言也需要同步，不然会出现“dedicated test 说应复用 scalar，但 generic test 还写死必须 native”的内部矛盾：
  - 两处 `DispatchAPI` 宽浮点 capability 段里，`Add/Sub/Mul/DivF64x4` 之前都还是 `AssertNativeSlotNotScalar(...)`
  - 这次已全部改成 `AssertNeonReusesScalarOtherwiseNative(...)`
- fresh 结果说明这 4 个 slot 已经真正退出 `wrapper_only` 发布集：
  - `backend=neon` truthfulness：`assignments=342 asm_exact=252 asm_suffix_only=10 wrapper_only=80 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - 相比上一批 `wrapper_only=84`，这批再次正好减少了 4 个 slot
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=629 status=ok`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `DispatchAPI / check / gate` 继续全绿，`gate` 尾部仍只剩 optional non-x86 native evidence skip 与历史 `windows_b07_gate.log` evidence skip
- 关键结论：
  - 这批收掉的不是 dead wrapper，而是“仍有 source companion 价值、但不该继续 no-asm backend-owned 的 mid-width `F64x4` arithmetic slot”
  - `NEON` 当前残余 `wrapper_only` 已进一步降到 `80`

## 2026-05-15 NEON No-Asm Wide Round/Trunc Slot Findings

- 这批 residual 比 `F64x4` arithmetic 更适合再细分成两种 source role：
  - `Round/TruncF32x8/F32x16/F64x8`：no-asm wrapper 已无 live source consumer，属于真 dead wrapper
  - `Round/TruncF64x4`：虽然 runtime slot 不该继续 no-asm backend-owned，但它仍被 `Round/TruncF64x8` no-asm graph 消费，必须保留成 source companion
- `src/fafafa.core.simd.neon.scalar.autowrap.inc` 的真实调用链已经把这个差异写得很清楚：
  - `RoundF32x8` 只是两次 `NEONRoundF32x4`
  - `RoundF32x16` 直接展开到四个 `NEONRoundF32x4`
  - `RoundF64x8` 调两次 `NEONRoundF64x4`
  - `RoundF64x4` 自己才是 `RoundF64x8` 的 no-asm source companion
  - `Trunc` 家族完全同型
- 因此这批不能简单一刀切成“全部删 wrapper”或“全部只回收 runtime slot”：
  - 删 `Round/TruncF64x4` 会直接断掉 `F64x8` 的 no-asm source graph
  - 保留 `Round/TruncF32x8/F32x16/F64x8` 则只是继续养死壳，并让 `sbNEON` 在 no-asm 下假装自己仍有 backend-local owner
- `dispatchapi` 这批 dedicated 护栏的必要性也很高，因为 generic capability 断言此前还是旧口径：
  - 新增 `Test_NEON_NoAsmWideRoundTruncSlots_Keep_Only_Consumed_Companions_And_Reuse_BaseScalar`
  - 两处 `DispatchAPI` wide `Round/Trunc` 段都已从“总是 native”收正为 `AssertNeonReusesScalarOtherwiseNative(...)`
  - 这样 dedicated truth 和 generic parity 不会再次互相打架
- fresh checker/runtime/test 结果说明这批回收吃到了完整收益：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=635 status=ok`
  - `backend=neon` truthfulness：`assignments=342 asm_exact=260 asm_suffix_only=10 wrapper_only=72 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `DispatchAPI / check / gate` 全绿；`gate` 尾部仍只诚实保留 optional non-x86 native evidence skip 与历史 `windows_b07_gate.log` evidence skip
- 关键结论：
  - 这批真正收掉的是 6 个 dead wrapper 加 8 个 no-asm fake backend-owned wide `Round/Trunc` slot
  - `Round/TruncF64x4` 继续保留为 source companion，但它们的 published slot 已回到 base scalar truth
  - `NEON` 当前残余 `wrapper_only` 已从上一批的 `80` 进一步降到 `72`

## 2026-05-15 NEON No-Asm Narrow F64 Compare/Simple Reduction Findings

- 这批 residual 里最干净的一簇，不是 `Clamp/Max/Min` 这种仍带本地 fallback 语义的 `F64x2`，而是 8 个“没有 source consumer 且与 scalar 逐字同义”的窄壳：
  - `CmpEqF64x2`
  - `CmpGeF64x2`
  - `CmpGtF64x2`
  - `CmpLeF64x2`
  - `CmpLtF64x2`
  - `CmpNeF64x2`
  - `ReduceAddF64x2`
  - `ReduceMulF64x2`
- 它们之所以比 `ReduceMax/MinF64x2`、`Max/MinF64x2` 更适合先收，有两个硬证据：
  - source graph 上，这 8 个名字在 `src/` 内只剩 `neon.pas + register.inc + scalar.autowrap.inc`，没有任何更宽 no-asm consumer
  - 语义上，`NEONCmp*F64x2` 与 `ScalarCmp*F64x2`、`NEONReduceAdd/ReduceMulF64x2` 与 `ScalarReduceAdd/ReduceMulF64x2` 是逐字同义；不像 `ClampF64x2` 或 `ReduceMax/MinF64x2` 那样仍可能保留 NaN/signed-zero 或 `Math.Min/Max` 相关的本地次序差异
- 因而这批属于最纯粹的 dead wrapper + fake backend-owned slot 回收：
  - no-asm wrapper 已没有 source companion 价值
  - runtime published `sbNEON` slot 也不该继续占着 backend-local owner 的名义
- `dispatchapi` 这批之前并没有专门的 ownership 护栏，只有“assigned + parity”覆盖：
  - `CmpLtF64x2` / `ReduceAddF64x2` 只在 generic parity 段里验证过结果
  - 所以这次新增 `Test_NEON_NoAsmNarrowF64CompareAndSimpleReductionSlots_Reuse_BaseScalar_When_Wrappers_Have_No_SourceConsumers` 是必要的，它把“wrapper 已删 + asm binding source 仍在 + runtime slot 复用 scalar” 三件事一次钉死
- fresh checker/runtime/test 结果说明这批 8 个槽位已完整退出 residual：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok`
  - `backend=neon` truthfulness：`assignments=342 asm_exact=268 asm_suffix_only=10 wrapper_only=64 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `DispatchAPI / check / gate` 全绿；`gate` 尾部仍只诚实保留 optional non-x86 native evidence skip 与历史 `windows_b07_gate.log` evidence skip
- 关键结论：
  - 这批收掉的是 8 个真正的窄 `F64x2` compare/simple reduction dead wrapper
  - 当前 `NEON` 残余 `wrapper_only` 已从上一批的 `72` 再降到 `64`
  - fresh residual 已明显收敛到“仍带本地 fallback 语义或仍充当 source companion 的 `F64` 家族”，而不是这类纯同义窄壳

## 2026-05-15 NEON No-Asm Narrow F64 Sqrt Slot Findings

- `SqrtF64x2` 是 compare/simple reduction 之后最干净的下一项 residual，但它和前一批窄壳仍有一个关键区别：
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc` 中 `NEONSqrtF64x2` 的 no-asm body 只是逐 lane `Sqrt`
  - `src/fafafa.core.simd.scalar.pas` 中 `ScalarSqrtF64x2` 也是逐 lane `Sqrt`
  - 语义上它们是同义的
  - 但 `NEONSqrtF64x4` 的 no-asm graph 仍通过两次 `NEONSqrtF64x2` 消费这个 wrapper
- 因此这批的正确修法不是“删 wrapper + 回 scalar”，而是更精细的“保留 source companion，但回收 published slot ownership”：
  - `src/fafafa.core.simd.neon.register.inc` 中 `table.SqrtF64x2 := @NEONSqrtF64x2;` 只在 `FAFAFA_SIMD_NEON_ASM_ENABLED` 下绑定
  - `NEONSqrtF64x2` / `NEONSqrtF64x4` 继续留在 `src/fafafa.core.simd.neon.scalar.autowrap.inc`
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 删除 `SqrtF64x2`
  - `dispatchapi` 新增 `Test_NEON_NoAsmNarrowF64SqrtSlot_Keep_SourceCompanion_But_Reuse_BaseScalar`，同时钉住 wrapper/source/runtime 三层 truth
- 这批也顺手把当前最容易误收的边界再次钉死了：
  - `ScalarFloorF64x2` / `ScalarCeilF64x2` 明确带 `IsNan/IsInfinite` guard
  - `ScalarRoundF64x2` / `ScalarTruncF64x2` 除了 `NaN/Inf` guard，还会走 `ScalarNormalizeSignedZeroDouble(...)`
  - 而 no-asm `NEONFloor/Ceil/Round/TruncF64x2` 只是直接 `Floor/Ceil/Round/Trunc`
  - 所以 `Ceil/Floor/Round/TruncF64x2` 不能像 `SqrtF64x2` 这样按“纯形状同义”继续回收
- 本批 fresh 结果：
  - `backend=neon` truthfulness：`assignments=342 asm_exact=269 asm_suffix_only=10 wrapper_only=63 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `DispatchAPI` / `check` / `gate` 全绿；`gate` 尾部仍只诚实保留 optional non-x86 native evidence skip 与历史 `windows_b07_gate.log` evidence skip
- 另一个这批实际踩到的坑也值得记下来：
  - 为了验证 `Ceil/FloorF64x2` 的语义差异，临时 `fpc` probe 曾把 `.o/.ppu` 落进 `src/`
  - 这会直接让 `gate` 的 `6/6 Filtered run_all check chain` 在源码树卫生检查处失败
  - 当前已清掉这些派生产物，fresh `gate` 里 `src tree hygiene` 已重新通过
- 关键结论：
  - `SqrtF64x2` 属于“published slot 应回 scalar，但 wrapper 仍保留 source companion 价值”的窄 `F64` 场景
  - 当前 `NEON wrapper_only` 已从上一批的 `64` 再降到 `63`
  - 接下来的高价值残余不再是这种纯同义 sqrt，而是 `Ceil/Floor/Round/Trunc` 与 `Clamp/Max/Min/ReduceMax/ReduceMin` 这类带更强标量语义或次序边界的 `F64x2`

## 2026-05-16 NEON No-Asm Narrow F64 Round-Family Findings

- `Ceil/Floor/Round/TruncF64x2` 这一组在进入实现前，必须先拆成两种 source role，不能再把它们混成一个“round-family residual”：
  - `NEONRoundF64x2` / `NEONTruncF64x2` 仍被 `NEONRoundF64x4` / `NEONTruncF64x4` 的 no-asm graph 消费，所以它们不是 dead wrapper
  - `NEONCeilF64x2` / `NEONFloorF64x2` 则已经没有任何 no-asm source consumer；wide `F64` floor/ceil wrapper 早在前一批就收掉了，所以这两个窄 wrapper 已经是纯死壳
- 因此这批真正优雅的修法不是“4 个一起保留 source companion”，而是两段式收口：
  - `Floor/CeilF64x2`：直接删除 no-asm dead wrapper，并把 published slot 收回 scalar
  - `Round/TruncF64x2`：保留窄 wrapper 给 `F64x4` no-asm graph 用，但 body 改成 exact `ScalarRound/TruncF64x2` forwarder，再把 published slot 收回 scalar
- 这批也把上一批刚钉住的语义边界，真的从“风险说明”变成了“源码收正”：
  - 之前 `ScalarFloor/CeilF64x2` 自带 `NaN/Inf` guard，而 no-asm `NEONFloor/CeilF64x2` 只是直接 `Floor/Ceil`
  - 之前 `ScalarRound/TruncF64x2` 还会做 signed-zero 归一化，而 no-asm `NEONRound/TruncF64x2` 只是直接 `Round/Trunc`
  - 现在 `Round/TruncF64x2` 已直接走 `ScalarRound/TruncF64x2`
  - `Floor/CeilF64x2` 则不再保留一份较弱的本地 no-asm 副本
- `dispatchapi` 这批的 dedicated 护栏价值很高，因为它同时固定了三层 truth：
  - `NEONCeilF64x2` / `NEONFloorF64x2` dead wrapper 已从 `autowrap` 消失
  - `NEONRoundF64x2` / `NEONTruncF64x2` 仍在 `autowrap`，且源码中明确是 `Result := ScalarRound/TruncF64x2(a);`
  - `NEONRoundF64x4` / `NEONTruncF64x4` 仍继续消费窄 companion
  - no-asm runtime 下 `sbNEON` 的 `Ceil/Floor/Round/TruncF64x2` slot 全部复用 base scalar
- 本批 fresh 结果：
  - `backend=neon` truthfulness：`assignments=342 asm_exact=273 asm_suffix_only=10 wrapper_only=59 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `TTestCase_DispatchAPI`、`TTestCase_IEEE754EdgeCases`、`check`、`gate` 全绿；`gate` 最终仍是 `GATE OK`
- 关键结论：
  - 这批收掉的不只是 4 个 narrow `F64x2` published slot，更是把 `Floor/Ceil` 与 `Round/Trunc` 的 no-asm fallback 架构真正拆回了“dead wrapper vs necessary source companion”的正确边界
  - `NEON wrapper_only` 已从上一批的 `63` 再降到 `59`
  - 接下来的高价值残余更集中在 `Clamp/Max/Min/ReduceMax/ReduceMinF64x2` 这条真正还带本地次序/NaN/signed-zero 语义争议的链上

## 2026-05-16 NEON No-Asm Narrow F64 Min/Max Findings

- `Max/MinF64x2` 和上一批 `Round/TruncF64x2` 的结构相似，但又比 `ReduceMax/ReduceMinF64x2` 更适合先收：
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc` 里，`NEONMax/MinF64x4` 仍明确消费 `NEONMax/MinF64x2`
  - 所以 `Max/MinF64x2` 不是 dead wrapper，只能做“保留 source companion、收回 published slot ownership”
  - 相比之下，`ReduceMax/ReduceMinF64x2` 仍是单点 reduction 语义，不适合和 `Min/Max` 一批混改
- 这批的正确收法不是继续保留一份本地 `if a > b then ... else ...` / `if a < b then ... else ...` no-asm 副本，而是把窄 wrapper 直接收正成 exact scalar truth：
  - `NEONMaxF64x2` -> `Result := ScalarMaxF64x2(a, b);`
  - `NEONMinF64x2` -> `Result := ScalarMinF64x2(a, b);`
  - 然后把 `table.MaxF64x2` / `table.MinF64x2` 收回 asm-only 绑定，让 no-asm runtime 自动复用 base scalar slot
- dedicated `DispatchAPI` 护栏的价值在于同时固定三层 truth：
  - `NEONMaxF64x2/NEONMinF64x2` wrapper 仍在 `autowrap` 中，说明 source companion 没断
  - 它们的 body 已精确对齐 `ScalarMax/MinF64x2`
  - `NEONMax/MinF64x4` 仍继续消费窄 companion，而 no-asm runtime 下 `sbNEON.Max/MinF64x2` 已复用 scalar slot
- 本批 fresh 结果：
  - `backend=neon` truthfulness：`assignments=342 asm_exact=275 asm_suffix_only=10 wrapper_only=57 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `TTestCase_DispatchAPI`、`TTestCase_IEEE754EdgeCases`、`check`、`gate` 全绿；`gate` 最终仍是 `GATE OK`
- 关键结论：
  - `NEON wrapper_only` 已从上一批的 `59` 再降到 `57`
  - `Max/MinF64x2` 这对已从 no-asm fake backend-owned published slot 收口完毕
  - 下一批最高价值 residual 可以继续锁定 `ReduceMaxF64x2/ReduceMinF64x2`，但应单独审它们和 scalar `Math.Max/Min` 的 NaN/次序边界，不要再和 `Min/Max` 混批

## 2026-05-16 NEON No-Asm Narrow F64 Extrema Reduction Findings

- `ReduceMax/ReduceMinF64x2` 这对和上一批 `Max/MinF64x2` 的关键差异，不在语义复杂度本身，而在 source role：
  - `NEONMax/MinF64x2` 仍被 `NEONMax/MinF64x4` no-asm graph 消费，所以只能保留成 source companion
  - `NEONReduceMax/ReduceMinF64x2` 在 `src/` 里已经没有任何更宽 no-asm consumer，因此如果语义能对齐 scalar，它们就属于纯 dead wrapper
- 这批在真正动源码前，先补了一个本地 Pascal probe 来核当前 FPC truth，而不是只凭直觉回收：
  - `NaN, 3.0`：`ScalarReduceMin/MaxF64x2` 与 no-asm `if` 版本都返回 `3.0`
  - `3.0, NaN`：两者都返回 `NaN`
  - `+0, -0`：两者都保留 `-0` 的符号位
  - `-0, +0`：两者都保留 `+0` 的符号位
  - `5.0, 5.0`：两者都返回 `5.0`
- 既然 source role 是 dead wrapper，语义又和 scalar truth 对齐，这批最优雅的修法就不是“保留 exact scalar forwarder”，而是直接删壳：
  - 从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 `NEONReduceMaxF64x2/NEONReduceMinF64x2`
  - 把 `table.ReduceMaxF64x2` / `table.ReduceMinF64x2` 收回 asm-only 绑定
  - 让 no-asm runtime 下 `sbNEON` 自动复用 base scalar slot
- 这批还顺手把 repo 内的“当前 scalar truth”固化成了测试，而不是只留在会话推理里：
  - `tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas` 新增 `Test_F64_ReduceMinMax_SpecialCases`
  - 它直接验证 `ScalarReduceMin/MaxF64x2` 在 `NaN` 次序和 `+0/-0` 符号位上的当前行为
  - 这样下次即使有人想再改 `ReduceMin/Max`，也不会把现在这个 order-sensitive truth 默默改掉
- dedicated `DispatchAPI` 护栏这次也补成了“删壳型”版本：
  - `NEONReduceMaxF64x2/NEONReduceMinF64x2` dead wrapper 必须从 `autowrap` 消失
  - `register.inc` 里 asm binding source 仍必须存在
  - no-asm runtime 下 `sbNEON.ReduceMax/ReduceMinF64x2` 必须和 scalar slot 指针完全一致
- 本批 fresh 结果：
  - `backend=neon` truthfulness：`assignments=342 asm_exact=277 asm_suffix_only=10 wrapper_only=55 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `TTestCase_DispatchAPI`、`TTestCase_IEEE754_F64`、`check`、`gate` 全绿；`gate` 最终仍是 `GATE OK`
- 关键结论：
  - `NEON wrapper_only` 已从上一批的 `57` 再降到 `55`
  - `ReduceMaxF64x2/ReduceMinF64x2` 已从 no-asm fake backend-owned published slot 收口完毕
  - 当前高价值 residual 更集中到 `ClampF64x2/ClampF64x4/ClampF64x8` 这一条仍保留本地 fallback 语义的链，而不是 `ReduceMax/ReduceMin` 这种已证实可直接删壳的 extrema reduction

## 2026-05-16 NEON No-Asm F64 Sqrt/Round/Trunc Dead-Wrapper Findings

- 这 6 个 no-asm wrapper：
  - `NEONRoundF64x2/F64x4`
  - `NEONSqrtF64x2/F64x4`
  - `NEONTruncF64x2/F64x4`
  在当前仓库里已经不再承担 source companion 角色；全仓窄搜索确认它们只剩 `scalar.autowrap.inc` 自供、`register.inc` 的 asm 绑定源码，以及 `DispatchAPI` 旧护栏引用。
- `src/fafafa.core.simd.neon.pas` 里的同名 assembler routine 仍是 asm build 的真实 owner，因此正确修法不是碰 asm 叶子，而是直接删除 no-asm wrapper，让 no-asm runtime 回落到 base scalar slot。
- 这批和 `ClampF64*` 的性质完全不同：
  - `Sqrt/Round/Trunc F64`：dead wrapper，可删壳
  - `ClampF64*`：现有专门护栏已经证明仍保留本地 `NaN/signed-zero` fallback 语义，当前不应混改
- `DispatchAPI` 原先还在用“保留 source companion / consumed companion”的口径保护这几条链；那已经落后于源码真相。现在 dedicated 护栏都已切到更诚实的三层事实：
  - no-asm wrapper 必须从 `autowrap` 消失
  - asm binding source 仍必须存在于 `register.inc`
  - no-asm runtime 下 `sbNEON` 对应 slot 必须与 scalar slot 指针完全一致
- fresh 结果显示这批不是只改测试文案，而是继续收紧了 published ownership：
  - `backend=neon assignments=342 asm_exact=277 asm_suffix_only=10 wrapper_only=55 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
- Release `DispatchAPI`、`IEEE754EdgeCases`、`check`、`gate` 全绿，`gate` 仍只保留两条历史已知的 optional skip：
  - non-x86 native evidence root not present
  - 历史 `windows_b07_gate.log` evidence verify fail

## 2026-05-16 Next Residual After F64 Sqrt/Round/Trunc Cleanup

- 这批收完后，`NEON` 当前高价值 residual 继续集中在“仍保留本地 fallback 语义”而不是“纯 dead wrapper”：
  - `ClampF64x2/F64x4/F64x8` 暂时不要动
- 如果继续沿“缺失与冗余”主线推进，下一批更值得审的是其余 `wrapper_only=55` 里仍可能存在的 orphaned no-asm forwarder，而不是回头重碰已经证实必须保留本地语义的 `Clamp` 链。

## 2026-05-16 NEON No-Asm Wide Integer Compare Findings

- `CmpEq/Ge/Gt/Le/Lt/Ne` 的 `I32x8/I32x16/I64x4/I64x8/U32x8/U64x4` 共 36 个 wide integer compare slot，之前在 `src/fafafa.core.simd.neon.register.inc` 里是无条件 backend-owned；这让 no-asm runtime 也继续挂着 `NEONCmp*` published slot。
- 但 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 的 wide compare no-asm body，并没有新的 backend-local truth：
  - `I32x16` 只是 `NEONCombineMask8To16(NEONCmp*I32x8(lo), NEONCmp*I32x8(hi))`
  - `I32x8/U32x8` 只是组合 `*32x4`
  - `I64x4/U64x4` 只是组合或派生 `*64x2`
  - `I64x8` 再继续消费 `I64x4`
- 因而这 36 个名字的真实边界不是“删 wrapper”，而是：
  - asm build：仍可保留 backend-owned source/binding
  - no-asm runtime：published slot 应复用 base scalar
  - source file：wide compare wrapper 仍保留，给 narrower-helper fallback graph 用
- 这批也暴露了 checker 自己的旧盲区：
  - 只把 compare binding 改成 `asm-only` 之后，`check_nonx86_register_truthfulness.py` 首轮把 16 个既有的 NEON `asm-only wrapper_only` float slot 一并误报成 miswired
  - 根因是旧 checker 只区分 generic `ALLOWED_WRAPPER_SLOTS_BY_BACKEND`，不知道“某些 wrapper_only 只允许出现在 asm-only 上下文”
  - 现在已经把 wide compare 单独收进 `ALLOWED_ASM_ONLY_WRAPPER_SLOTS_BY_BACKEND['neon']`，并允许旧 wrapper allowlist 在 asm-only 上下文继续合法命中
- `DispatchAPI` 现在也不再把这 36 个 compare slot 混在“大整数 fallback 混合护栏”里，而是有了 dedicated truth：
  - wide compare source companion 必须仍在 `neon.scalar.autowrap.inc`
  - asm binding source 必须仍在 `neon.register.inc`
  - no-asm runtime 下 `sbNEON.Cmp*` slot 必须和 scalar slot 指针完全一致
- fresh 结果说明这批收口的是 ownership truth，而不是继续删 companion：
  - `backend=neon assignments=342 asm_exact=277 asm_suffix_only=10 wrapper_only=55 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `DispatchAPI`、`check`、`gate` 继续全绿

## 2026-05-16 Next Residual After Wide Integer Compare Ownership Cleanup

- `ClampF64x2/F64x4/F64x8` 仍然不要动；现有 dedicated 护栏已经证明它们保留本地 `NaN/signed-zero` fallback 语义，不属于这类 published ownership cleanup。
- wide float arithmetic/minmax 也不是下一刀；当前 register/test 已经明确：
  - wrapper/source companion 仍需保留给 asm/wider graph
  - no-asm runtime slot 已经复用 scalar
- 在当前 `NEON wrapper_only=55` 的残余里，更值得继续扫的是其余可能还停留在“always backend-owned 但 no-asm 只是 narrower-helper composition”的簇，而不是回头重开已经固定边界的 `Clamp` 或宽浮点 arithmetic/minmax。

## 2026-05-16 Non-x86 Wrapper Context Truthfulness Checker Hardening Findings

- 当前这批发现的真实问题不在 `NEON`/`RISCVV` backend 代码，而在 `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 自身：旧模型只区分“generic wrapper allowlist”与“asm-only allowlist”，表达不了 `wrapper_only` 在不同 publication branch 下的合法性差异。
- 这个盲区会同时制造两类风险：
  - 误放过：把只应在 `no-asm` 合法出现的 slot，当成任意上下文都可豁免
  - 误报错：把只应在 `asm-only` 合法出现的 source companion wrapper，误判成 miswired/backend-owned
- 当前已经核清的三类真实上下文是：
  - `always wrapper-only`
    - `RISCVV` 的 `AndNotI64x2/AndNotI8x16/AndNotU16x8/AndNotU64x2/AndNotU8x16`
    - `CmpEqU64x2/CmpGtU64x2/CmpLtU64x2`
    - `DotF64x2/DotF64x4`
    - `MaxI64x2/MaxU64x2/MinI64x2/MinU64x2`
  - `asm-only wrapper-only`
    - `NEON` wide integer compare 36 项
    - `NEON SelectF32x4`
    - `NEON` wide float arithmetic/minmax：`Add/Sub/Mul/DivF32x16/F64x8`、`Max/MinF32x16/F64x8`
    - `NEON AndNotI8x16/AndNotU16x8/AndNotU8x16`
    - `RISCVV SelectF32x8/SelectF64x4/SelectI32x4`
  - `no-asm wrapper-only`
    - `NEON ClampF64x2/ClampF64x4/ClampF64x8`
    - `RISCVV ExtractF32x8/F32x16/F64x2/F64x4/I32x4/I32x8/I32x16/I64x2/I64x4`
- 因而这批最正确的修法不是继续膨胀一个总 allowlist，而是 fail-close：
  - `build_reason_list()` 必须按 assignment `context` 去对照不同 allowlist
  - `unused_allowlist` 仍必须保持 `0`
  - report 必须能直接看出 `always / asm-only / no-asm` 三个桶各自的真实数量
- fresh strict 结果已经证明三态模型与当前源码真相一致：
  - `neon`
    - `assignments=342`
    - `asm_exact=277`
    - `asm_suffix_only=10`
    - `wrapper_only=55`
    - `miswired=0`
    - `unused_allowlist=0`
    - context split：`always=0 / asm-only=52 / no-asm=3`
  - `riscvv`
    - `assignments=473`
    - `asm_exact=330`
    - `asm_suffix_only=117`
    - `wrapper_only=26`
    - `miswired=0`
    - `unused_allowlist=0`
    - context split：`always=14 / asm-only=3 / no-asm=9`
- 关键结论：
  - 这批修的是 checker 精度，不是 backend 行为
  - `ClampF64x2/F64x4/F64x8` 现在被明确归类为合法 `no-asm wrapper-only`，不该再被当作“下一刀 residual”
  - `RISCVV Extract*` 也同理，后续不应再把它们误当成 published ownership 漏洞

## 2026-05-16 RISCVV Helper-Owned Exact-Scalar Slot Ownership Guard Findings

- 继续往 `RISCVV` 当前 `always wrapper-only=14` 深挖后，发现一个真实的审查缺口不在源码行为，而在测试真相层：
  - `DotF64x2/F64x4` 已有 dedicated 护栏，明确“no-asm source 不直接 scalar-forward，published slot 继续 backend-owned”
  - 但另外一簇 exact-scalar helper slot 之前没有同等级的 `source + register + runtime ownership` 三层护栏
- 这簇缺口具体是 12 个名字：
  - `AndNotI64x2`
  - `MinI64x2`
  - `MaxI64x2`
  - `AndNotU64x2`
  - `CmpEqU64x2`
  - `CmpLtU64x2`
  - `CmpGtU64x2`
  - `MinU64x2`
  - `MaxU64x2`
  - `AndNotI8x16`
  - `AndNotU16x8`
  - `AndNotU8x16`
- 它们的真实结构和前面很多“应回收到 scalar”的 residual 不同：
  - `src/fafafa.core.simd.riscvv.helpers.inc` 中，这 12 个函数在 no-asm 侧确实都是 exact `Scalar*` forwarder
  - 但 `src/fafafa.core.simd.riscvv.register.inc` 仍无条件把相应 slot 绑定到 `RISCVV*`
  - 这表示当前仓库的有意策略是：helper body 可以是 scalar truth，但 published slot ownership 仍属于 `RISCVV`
- 如果没有 dedicated 护栏，这里会有两种后续风险：
  - 有人看到 helper 是 exact scalar，就把 register 静悄悄收回到 base scalar，改掉 published ownership 却不自知
  - 或者有人改了 helper body / register 绑定，allowlist 仍会说“合法”，但仓库已经没人固定这 12 个 slot 的 policy
- 因而这批最正确的修法不是动 backend，而是把策略写成测试事实：
  - helper source 仍必须包含 exact scalar body
  - register source 仍必须保持 backend-owned assignment
  - runtime `sbRISCVV` dispatch table 上这些 slot 的指针仍必须不同于 scalar
- 这批修完后，`RISCVV` 这类“exact-scalar helper 但故意 backend-owned”的槽位终于不再只靠口头理解或 checker allowlist 存活，而有了可执行的 dedicated truth。

## 2026-05-16 Non-x86 Key-Slot Audit Coverage Expansion Findings

- 刚补完 `DispatchAPI` 之后继续收口时，立刻暴露出下一层真实缺口：
  - Pascal testcase 已经知道那 12 个 `RISCVV` helper-owned slot
  - 但 `check_nonx86_key_slot_audit.py` 还停留在旧的 10 个 key slot，完全不知道它们
- 这意味着如果只看 `Release check` 里的 Python 审计视角，仓库仍然会漏掉这 12 个名字；新的 ownership truth 只活在单个 testcase 里，还没有进入“检查器级别”的常规门禁。
- 当前脚本缺口有两个具体面：
  - 仍使用单一 `KEY_SLOTS`，表达不了 backend-specific key slot 集
  - 解析器只认识 `AssertRegisterKeepsBaseScalar/AssertRegisterHasAsmOwnedSlot/AssertRegisterOwnsBackendSlot`，认不出新 testcase 里的 `AssertHelperOwnedExactScalarSlot`
- 因而这批的正确修法不是再补一个 testcase，而是把 Python 审计模型补齐：
  - 改成 `KEY_SLOTS_BY_BACKEND`
  - `riscvv` 明确把 12 个 helper-owned slot 纳入 key-slot audit
  - 解析器显式把 `AssertHelperOwnedExactScalarSlot` 视为 `backend_owned` truth source
  - `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['riscvv']` 也同步要求这 12 个 slot 必须有 dedicated assert
- 修完后最关键的变化不是“数字变大”，而是门禁层次对齐了：
  - 以前：`DispatchAPI` 知道，Python key-slot audit 不知道
  - 现在：`DispatchAPI` 与 `key-slot audit` 都知道
  - 以后这 12 个 slot 的 register/source drift 会先被日常 `check` 抓住，而不是等人去读 testcase 才发现

## 2026-05-16 RISCVV Select Key-Slot Explicit Ownership Coverage Findings

- 沿着上一批 `key-slot` 对齐继续往下看，新的真实缺口已经很具体：
  - `check_nonx86_register_truthfulness.py` 早就把 `RISCVV SelectF32x8/SelectF64x4/SelectI32x4` 归类成合法 `asm-only wrapper-only`
  - 但 `check_nonx86_key_slot_audit.py` 之前完全不跟踪这 3 个 slot
  - 现有 `DispatchAPI` dedicated test 里也只显式固定了 `SelectF64x4`，`SelectF32x8/SelectI32x4` 仍只靠 generic parity 间接覆盖
- 这类缺口的风险不在“当前实现错误”，而在 drift 过于容易漏报：
  - 一旦有人把 `table.SelectF32x8` 或 `table.SelectI32x4` 静悄悄收回 scalar，register-truthfulness 仍可能先把它当成“合法 wrapper-only”
  - 由于 `key-slot audit` 与 dedicated `DispatchAPI` 没有同时点名，这种 ownership 漂移不容易在日常小批次里被第一时间抓住
- 这 3 个 slot 的真实结构也支持把它们提升成显式 truth source：
  - `src/fafafa.core.simd.riscvv.register.inc` 在 `{$IFDEF RISCVV_ASSEMBLY}` 分支里明确把 `table.SelectF32x8/SelectF64x4/SelectI32x4` 绑定到 `@RISCVVSelect*`
  - `src/fafafa.core.simd.riscvv.pas` 里对应实现是 backend-local Pascal loop，不是 dead scalar wrapper
  - 因而当前正确 policy 是：asm-enabled register wiring 下，这 3 个 slot 应继续 backend-owned
- 本批最小修法因此很集中，也没有扩散到新 testcase：
  - 把 `SelectF32x8/SelectF64x4/SelectI32x4` 纳入 `KEY_SLOTS_BY_BACKEND['riscvv']`
  - 同步加入 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['riscvv']`
  - 直接在现有 `Test_RISCVV_WideFallbackOnlySlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders` 中补齐这 3 个 slot 的 `AssertRegisterOwnsBackendSlot` 与 runtime ownership 断言
- 修完后的关键变化不是单纯计数增加，而是三层真相终于对齐：
  - truthfulness checker 显式知道
  - key-slot audit 显式知道
  - dedicated `DispatchAPI` 也显式知道
  - fresh summary 现为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=35 issues=0 status=ok`，其中 `riscvv` slot 总数从 `22` 提升到 `25`

## 2026-05-16 RISCVV Extract Companion Ownership Coverage Findings

- 把 `Select*` 收口后继续往下看，真正更值得补的不是再扩大 generic parity，而是 `RISCVV Extract*` 这 9 个 slot 的 truth 还没有被 `key-slot audit` 正确表达：
  - `check_nonx86_register_truthfulness.py` 已明确它们属于合法 `no-asm wrapper-only`
  - `check_nonx86_helper_semantics.py` 也知道 asm 侧 wrapper 会做索引饱和并调用 `RISCVVExtract*Asm`
  - 但旧 `key-slot audit` 既不跟踪这 9 个 slot，也不理解“同一个 backend-owned slot 同时存在 asm-only helper wrapper 与 no-asm exact scalar companion wrapper”这种 mixed-context 合法形态
- 这说明缺口已经不在 backend 行为，而在审计模型：
  - `src/fafafa.core.simd.riscvv.facade.inc` 中 9 个 `Extract*` 在 no-asm 侧都只是 exact `ScalarExtract*` companion wrapper
  - `src/fafafa.core.simd.riscvv.pas` 中同名函数在 asm-enabled 侧继续做索引饱和并调用 `RISCVVExtract*Asm`
  - `src/fafafa.core.simd.riscvv.register.inc` 对每个 slot 都保留了显式 `{$IFDEF RISCVV_ASSEMBLY}` / `{$ELSE}` 双分支绑定
  - 因而真实 policy 是：published slot 继续 backend-owned，但其 source truth 在 asm/no-asm 两个分支上是不同的 companion shape
- 第一轮最小验证已经直接证明旧模型不够：
  - 只跑 `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend riscvv --summary-line`
  - 就立刻抓到 `issues=9`
  - 问题不是 register 漏绑，而是旧模型把这 9 个 `no-asm scalar_forwarder companion wrapper` 全误判成异常
- 因而这批的正确修法必须同时补两层：
  - 在 `DispatchAPI` 新增 dedicated testcase，显式固定 `facade no-asm source + asm source + register 双分支 + runtime ownership`
  - 在 `check_nonx86_key_slot_audit.py` 里显式允许 `riscvv` 这 9 个 slot 以“backend-owned + no-asm scalar companion wrapper”的 mixed-context 合法形态通过
- 修完后最大的收益不是又多了 9 个名字，而是 audit 真相终于和源码真相对齐：
  - 以前：truthfulness checker 知道，helper-semantics 知道，但 key-slot audit 不理解
  - 现在：truthfulness checker、helper-semantics、key-slot audit、dedicated `DispatchAPI` 四层都知道
  - fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=44 issues=0 status=ok`，其中 `riscvv` slot 总数从 `25` 提升到 `34`

## 2026-05-16 RISCVV Dot Key-Slot Audit Lift Findings

- 把 `Extract*` 收口后继续盘点 `riscvv current_wrapper_only_slots`，发现剩下还没被 `key-slot audit` 追踪的 `wrapper_only` policy 位点已经只剩：
  - `DotF64x2`
  - `DotF64x4`
- 这两个名字和前面的 `Extract*` 不同，它们并不存在审计模型误解：
  - dedicated `DispatchAPI` 早就显式固定了它们
  - `check_nonx86_register_truthfulness.py` 也早就知道它们属于合法 `always wrapper-only`
  - 唯一缺口只是它们还没进 Python 常规 `check` 的 `key-slot audit`
- 因而这批正确修法不该再新起 testcase，也不该动 backend：
  - 只要把 `DotF64x2/F64x4` 纳入 `KEY_SLOTS_BY_BACKEND['riscvv']`
  - 同步纳入 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['riscvv']`
  - 让现有 `Test_RISCVV_FacadeSlots_Reuse_BaseScalar_When_Wrappers_Are_ScalarPassThrough` 继续作为显式 truth source 即可
- 这批的收益很朴素但很值当：
  - 以前：`DotF64x2/F64x4` 只在 dedicated suite 里被守住
  - 现在：`Release check` 也会通过 `key-slot audit` 直接守住
  - fresh summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=46 issues=0 status=ok`，其中 `riscvv` slot 总数从 `34` 提升到 `36`

## 2026-05-16 NEON Clamp Key-Slot Audit Lift Findings

- 继续把 non-x86 ownership truth 往 `check` 常规门禁里抬时，`NEON` 这边最小且最独立的 residual 已经很清楚：
  - `check_nonx86_register_truthfulness.py --backend neon --json --strict`
  - 显示当前 `wrapper_only=55`
  - 其中唯一的 `no-asm wrapper-only` 只剩：
    - `ClampF64x2`
    - `ClampF64x4`
    - `ClampF64x8`
- 这 3 个名字和之前已收掉的 fake backend-owned residual 不同，它们当前是合法 policy，而不是待删除代码：
  - `src/fafafa.core.simd.neon.register.inc` 仍保留 `table.ClampF64x2/F64x4/F64x8 := @NEONClamp...`
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc` 里 `NEONClampF64x2/F64x4/F64x8` 仍存在，且宽版本继续消费窄版本
  - `dispatchapi` 的 `Test_NEON_NoAsmWideClampSlots_Reuse_BaseScalar_Only_For_F32Forwarders_And_Keep_F64LocalFallback` 已显式钉住：
    - `F32x8/F32x16` 回 scalar
    - `F64x2/F64x4/F64x8` 因本地 `NaN/signed-zero` fallback 语义而继续 backend-owned
- 当前缺口不在 backend 行为，而在 Python 审计层的“识字率”：
  - 旧 `check_nonx86_key_slot_audit.py` 没把 `ClampF64x2/F64x4/F64x8` 纳入 `KEY_SLOTS_BY_BACKEND['neon']`
  - 旧解析器也不认识 `AssertAsmBindingStillPresent(...)`，所以现成 dedicated testcase 里的 source truth 进不了常规 key-slot audit
- 因而这批正确修法仍然是 checker-level lift，而不是动 Pascal backend：
  - 把这 3 个 slot 提升进 `KEY_SLOTS_BY_BACKEND['neon']`
  - 把现成的 clamp dedicated testcase 纳入 `EXPECTATION_PROCEDURES['neon']`
  - 让解析器显式把 `AssertAsmBindingStillPresent` 识别为 `backend_owned`
  - 同时要求 `ClampF64x2/F64x4/F64x8` 必须有 dedicated explicit assert，避免以后又退回“allowlist 知道、常规 audit 不知道”的状态
- 修完后的关键变化不是行为变更，而是门禁层次对齐：
  - 以前：truthfulness checker 知道，dedicated `DispatchAPI` 知道，key-slot audit 不知道
  - 现在：truthfulness checker、dedicated `DispatchAPI`、key-slot audit 三层都知道
  - fresh summary 已更新为 `backend=neon ok slots=13`，全局 summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=49 issues=0 status=ok`

## 2026-05-16 NEON Wide MinMax Key-Slot Audit Lift Findings

- 继续对账 `NEON wrapper_only` 与 `key-slot audit` 覆盖差异后，当前最小的现成 lift 簇是：
  - `MaxF32x16`
  - `MaxF64x8`
  - `MinF32x16`
  - `MinF64x8`
- 这 4 个名字的真实形态已经被现成 `DispatchAPI` testcase 充分固定：
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - `Test_NEON_NoAsmWideMinMaxSlots_Keep_Necessary_Wrappers_But_Reuse_BaseScalar`
  - 已显式包含：
    - `AssertAsmBindingStillPresent('MaxF32x16'/'MaxF64x8'/'MinF32x16'/'MinF64x8', ...)`
    - `AssertSlotReusesScalar(...)`
- 这说明它们和上一批 `ClampF64*` 一样，问题不在 backend 行为，而在常规 Python 审计没有把这层 truth 接进来：
  - `check_nonx86_register_truthfulness.py` 已把它们归类为合法 `asm-only wrapper-only`
  - dedicated `DispatchAPI` 已知道它们为什么合法
  - 旧 `check_nonx86_key_slot_audit.py` 还不知道
- 因而这批最正确的修法仍然是 checker-level lift：
  - 把这 4 个 slot 纳入 `KEY_SLOTS_BY_BACKEND['neon']`
  - 把现成 min/max dedicated testcase 纳入 `EXPECTATION_PROCEDURES['neon']`
  - 把这 4 个 slot 纳入 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 修完后的关键变化不是行为变更，而是门禁层次继续向前推进了一小步：
  - 以前：truthfulness checker 知道，dedicated `DispatchAPI` 知道，key-slot audit 不知道
  - 现在：这 4 个 `NEON wide Min/Max` slot 也被 `key-slot audit` 正式接管
  - fresh summary 已更新为 `backend=neon ok slots=17`，全局 summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=53 issues=0 status=ok`

## 2026-05-16 NEON Wide Leaf Float Arithmetic Key-Slot Audit Lift Findings

- 继续对账 `NEON wrapper_only` 与 `key-slot audit` 覆盖差异后，下一簇最适合直接 lift 的 residual 是 8 个 wide leaf float arithmetic slot：
  - `AddF32x16`
  - `AddF64x8`
  - `SubF32x16`
  - `SubF64x8`
  - `MulF32x16`
  - `MulF64x8`
  - `DivF32x16`
  - `DivF64x8`
- 这 8 个名字的真实形态也已经被现成 `DispatchAPI` testcase 充分固定：
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - `Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar`
  - 已显式包含：
    - `AssertAsmBindingStillPresent(...)`
    - `AssertSlotReusesScalar(...)`
- 这说明它们与上一批 `NEON wide Min/Max` 一样，问题不在 backend 行为，而在 Python 常规审计没有接住这层 truth：
  - `check_nonx86_register_truthfulness.py` 已把它们归类为合法 `asm-only wrapper-only`
  - dedicated `DispatchAPI` 已知道它们为什么合法
  - 旧 `check_nonx86_key_slot_audit.py` 还不知道
- 因而这批最正确的修法仍然是 checker-level lift：
  - 把这 8 个 slot 纳入 `KEY_SLOTS_BY_BACKEND['neon']`
  - 把现成 wide arithmetic dedicated testcase 纳入 `EXPECTATION_PROCEDURES['neon']`
  - 把这 8 个 slot 纳入 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 修完后的关键变化不是行为变更，而是 `NEON` 这条 asm-only wrapper-owned truth 线继续往常规门禁里推进：
  - 以前：truthfulness checker 知道，dedicated `DispatchAPI` 知道，key-slot audit 不知道
  - 现在：这 8 个 `NEON wide leaf float arithmetic` slot 也被 `key-slot audit` 正式接管
  - fresh summary 已更新为 `backend=neon ok slots=25`，全局 summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=61 issues=0 status=ok`

## 2026-05-16 NEON SelectF32x4 Dedicated Truth Lift Findings

- 继续往下切 residual 时，`SelectF32x4` 是一个比 32 个 integer-compare 更值当的单点缺口：
  - `check_nonx86_register_truthfulness.py` 已把它归类为合法 `asm-only wrapper-only`
  - `src/fafafa.core.simd.neon.pas` 里的 `NEONSelectF32x4` 是 asm-enabled backend-local lane loop
  - `src/fafafa.core.simd.neon.scalar.utility.inc` 里的 `NEONSelectF32x4` 则是 no-asm `ScalarSelectF32x4` companion wrapper
  - `src/fafafa.core.simd.neon.register.inc` 仅在 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 下绑定 `table.SelectF32x4 := @NEONSelectF32x4;`
- 这说明它的真实性质并不是“应删的 wrapper”，而是一个需要被 dedicated truth 明确守住的双相 policy slot：
  - asm-enabled：backend-owned
  - no-asm：回落 scalar
- 旧测试的问题不在于完全没覆盖，而在于覆盖太分散：
  - 原有 `Test_NEON_SelectF32x4_AsmEnabledSource_Does_Not_ScalarForward` 只看 asm source
  - 其余 runtime 事实散落在 capability / representative parity 一类泛化测试里
  - `key-slot audit` 因此没有一个可直接消费的 dedicated truth source
- 因而这批正确修法不是改 backend，而是把真相收拢成一个 dedicated testcase，再交给 checker：
  - 扩展 `Test_NEON_SelectF32x4_AsmEnabledSource_Does_Not_ScalarForward`
  - 让它同时钉住 asm source、no-asm scalar companion、register asm-only binding、runtime ownership/fallback
  - 再把 `SelectF32x4` 纳入 `KEY_SLOTS_BY_BACKEND['neon']`、`EXPECTATION_PROCEDURES['neon']` 与 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 修完后的关键变化不是行为变更，而是 `SelectF32x4` 不再只靠分散的理解存活：
  - 以前：truthfulness checker 知道，零散泛化测试知道，key-slot audit 不知道
  - 现在：`SelectF32x4` 已有 dedicated truth source，且被 `key-slot audit` 正式接管
  - fresh summary 已更新为 `backend=neon ok slots=26`，全局 summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=62 issues=0 status=ok`

## 2026-05-16 NEON AndNot Ownership Lift Findings

- 继续沿 `NEON` residual 往下切时，`AndNotI8x16/AndNotU16x8/AndNotU8x16` 是下一簇最小但真实的缺口：
  - `check_nonx86_register_truthfulness.py` 已把它们归类为合法 `asm-only wrapper-only`
  - `src/fafafa.core.simd.neon.compare.inc` 中对应实现不是 scalar-forward，而是 backend-local composition：
    - `NEONAndNotI8x16` = `NEONAndI8x16(NEONNotI8x16(a), b)`
    - `NEONAndNotU16x8` = `NEONAndU16x8(NEONNotU16x8(a), b)`
    - `NEONAndNotU8x16` = `NEONAndU8x16(NEONNotU8x16(a), b)`
  - `src/fafafa.core.simd.neon.register.inc` 也在 asm-enabled 下显式发布这 3 个 slot
- 这说明它们不是“应回 scalar”的 stale wrapper，而是 asm-enabled 时故意 backend-owned、vector asm 关闭时回落 scalar 的双相 policy slot。
- 当前真正缺的是 dedicated truth source：
  - 旧测试里只有 generic parity / presence 断言
  - 没有一个 dedicated testcase 同时固定 source、register、runtime 三层事实
  - `key-slot audit` 也无法直接消费它们
- 因而这批正确修法不是改 backend，而是补 dedicated testcase 再 lift：
  - 新增 `Test_NEON_AndNotSlots_Keep_AsmOwnedCompositions_And_RuntimeOwnership`
  - 让它同时钉住 backend-local composition、register asm binding、runtime ownership/fallback
  - 再把这 3 个 slot 纳入 `KEY_SLOTS_BY_BACKEND['neon']`、`EXPECTATION_PROCEDURES['neon']` 与 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 修完后的关键变化不是行为变更，而是这 3 个 `AndNot*` 位点不再只靠 truthfulness allowlist 活着：
  - 以前：truthfulness checker 知道，generic parity 知道，key-slot audit 不知道
  - 现在：它们已有 dedicated truth source，且被 `key-slot audit` 正式接管
  - fresh summary 已更新为 `backend=neon ok slots=29`，全局 summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=65 issues=0 status=ok`

## 2026-05-16 NEON Wide Integer Compare Key-Slot Audit Lift Findings

- 把 `AndNot*` 收口后再次对账，`NEON` 侧剩余 `missing_from_key` 已经收敛成一整簇、而且只有一整簇：
  - `CmpEq*`
  - `CmpGe*`
  - `CmpGt*`
  - `CmpLe*`
  - `CmpLt*`
  - `CmpNe*`
  - 共 `36` 个，全部是合法 `asm-only wrapper-only`
- 这簇的价值在于它已经具备“整簇一次 lift”的条件：
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - `Test_NEON_NoAsmWideIntegerCompareSlots_Keep_SourceCompanions_But_Reuse_BaseScalar`
  - 已经现成固定了：
    - source companion 仍存在
    - 关键 composition witness 仍存在
    - register asm binding 仍存在
    - runtime no-asm 时复用 scalar
- 因而这批不该再拆成六小刀，也不该改 Pascal backend：
  - 问题不在行为
  - 问题只在 Python 常规门禁还没把这组现成 truth 接进来
- 这批的正确修法因此就是一次纯 checker-level lift：
  - 把 36 个 `Cmp*` slot 全纳入 `KEY_SLOTS_BY_BACKEND['neon']`
  - 把现成 compare dedicated testcase 纳入 `EXPECTATION_PROCEDURES['neon']`
  - 对这 36 个 slot 全开 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 修完后的关键变化不是代码行为变更，而是 `NEON` 这条 non-x86 ownership 审查线在当前 checker 模型下已经收口：
  - 以前：`NEON missing_from_key=36`
  - 现在：`NEON missing_from_key=0`
  - fresh summary 已更新为 `backend=neon ok slots=65`，全局 summary 已更新为 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=101 issues=0 status=ok`

## 2026-05-16 Non-x86 Key-Slot Cluster Dedup Findings

- 在 `NEON missing_from_key=0` 收口后继续做 completion audit，当前更真实的问题已经不再是 coverage 缺口，而是 checker 自身的结构冗余：
  - 同一批 slot 名字同时散落在 `KEY_SLOTS_BY_BACKEND`
  - `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS`
  - 个别 backend 例外集
- 这种重复在近几轮已经开始危险，最明显的是：
  - `NEON` 36 个 `wide compare` slot
  - `RISCVV` 9 个 `Extract*` slot
  - `RISCVV` 12 个 helper-owned exact-scalar slot
- 风险不在今天的行为错误，而在未来很容易出现“改了一处、漏了一处”的 drift：
  - key-slot 集合更新了，explicit-assert 必须集没更新
  - 或者 backend mixed-context 例外还留着旧名字
- 因而这批最合适的修法不是再开新 testcase，而是把 checker 的 shared truth 收回单点：
  - 提炼 `NEON_*` / `RISCVV_*` slot 簇
  - 让 `KEY_SLOTS_BY_BACKEND` 与 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS` 组合式复用
  - `RISCVV` 的 no-asm scalar companion 例外直接复用 `Extract*` 共享簇
- 这样做的收益很直接：
  - 本批不改变任何 backend/source/runtime 语义
  - 但后续继续扩 ownership 门禁时，不必再在多处手工同步同一簇名字
  - checker 自己的 drift 风险会明显下降
- fresh 复验也证明这次是“真去冗余、零语义漂移”：
  - `backend=neon ok slots=65`
  - `backend=riscvv ok slots=36`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=101 issues=0 status=ok`
  - Release `check` 继续通过

## 2026-05-16 Check Optional Non-x86 Opt-In Listing Findings

- 继续做 completion audit 时，当前最真实的新问题不在 SIMD backend 语义，而在审查工具本身的重路径：
  - `tests/fafafa.core.simd/BuildOrTest.sh check`
  - `tests/fafafa.core.simd/buildOrTest.bat check`
  - 都会无条件执行 `nonx86-optin-list-suites`
- 这和当前工作方式已经开始冲突：
  - 很多批次只改 Python checker / scratch / docs
  - 但 `check` 仍会额外触发 `neon` 与 `riscvv` 的 opt-in 构建与 `--list-suites`
  - 导致“验证目标很窄、构建代价却偏大”
- 更关键的是，这一步和 `wiring-sync` / `experimental isolation` 不同，之前没有现成开关：
  - 现有脚本只给了 `SIMD_CHECK_WIRING_SYNC`
  - 以及 `SIMD_CHECK_EXPERIMENTAL`
  - `nonx86 opt-in list-suites` 没有对应的显式 skip knob
- 因而本批最正确的修法不是删掉这条检查，而是把它降成可显式跳过的 optional lane：
  - 默认值保持开启，避免日常 `check` 的覆盖面无声缩水
  - 当批次只涉及 Python/checker/文档时，可用 `SIMD_CHECK_NONX86_OPTIN=0` 跳过
  - shell 与 batch 入口都要同步，不然会形成平台行为分叉
- 这批收益主要体现在工作流效率，而不是 backend 行为变化：
  - 它不会改变 SIMD 语义
  - 但能减少后续继续深审时不必要的 non-x86 opt-in 构建成本
  - 也让“默认全查”与“窄批跳过”之间的边界变得明确可控
- fresh 验证已经证明新开关是活的，而不是死配置：
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 日志中明确出现 `[CHECK] SKIP optional non-x86 opt-in suite listing (set SIMD_CHECK_NONX86_OPTIN=1 to enable)`
  - 同一条 Release `check` 其余门禁继续通过，说明这是“可控缩窄验证成本”，不是误删覆盖

## 2026-05-16 Windows Check Non-x86 Audit Parity Findings

- 继续做 completion audit 时，真正更硬的 runner 缺口不在文档，而在 batch `check` 的实际覆盖面：
  - shell `check` 默认会跑：
    - `helper-semantics`
    - `key-slot-audit`
    - `riscvv-abi-shape`
    - `source-reachability`
  - 但 `buildOrTest.bat check` 之前没有这 4 条
- 这不是抽象上的“shell/batch 不完全同实现”，而是具体的门禁漂移：
  - `key-slot-audit` 在 batch 里虽然有公开 action，但 `check` 主线并没有调用
  - `helper-semantics` / `riscvv-abi-shape` / `source-reachability` 连 batch 内部入口都没有
  - 结果就是 Windows 用户执行 `buildOrTest.bat check` 时，会少看掉一块已经被 Linux 默认守住的 non-x86 审查面
- 本批最合适的修法不是把 batch `check` 再桥接回 shell，也不是重写 shell 逻辑：
  - 直接在 `buildOrTest.bat` 里补最小原生 Python 入口
  - 避免把新的 bash 依赖强行引入 Windows `check`
  - 让 batch `check` 自己具备这 4 条检查的执行能力
- 同时只补 batch 还不够，因为之后最容易再次退化成“源码补了，未来又掉线”：
  - 所以 `BuildOrTest.sh` 里守 Windows runner 的 source-safe parity guard 也要同步点名这些新入口与调用点
  - 这样 Linux 主链会更早暴露未来的 batch drift
- fresh 复验也证明这批不是“只把文本补齐”，而是已经回到 Linux 主链的守护范围里：
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 日志明确出现：
    - `[CHECK] OK (windows runner parity signatures present)`
    - `[CHECK] OK (Python checker runtime guard present)`
    - `NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok`
    - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=101 issues=0 status=ok`
    - `RISCVV_ABI_SHAPE_SUMMARY direct_functions=121 explicit_checks=10 missing_result_store=0 suspicious_a0_loads=0 status=ok`
    - `SIMD_SOURCE_REACHABILITY_SUMMARY tracked_includes=84 reachable_includes=83 allowed_unreachable=1 unexpected_unreachable=0 missing_include_refs=0`
- 这次仍需诚实保留一个边界：
  - 我们已经证明 shell 主门禁会守住新补的 batch 路径
  - 但还没有 Windows 实机直接执行 `buildOrTest.bat check` 的 fresh 运行时证据
  - 所以当前最准确的说法是：source-safe parity 已补齐，Windows runtime 证据仍待后续补实

## 2026-05-16 Targeted Python Audit Actions Exposure Findings

- 在把 batch `check` 漏跑面补齐之后，下一个真实低效点就暴露出来了：
  - `helper-semantics`
  - `source-reachability`
  - `riscvv-abi-shape`
  - 这 3 条都已经是成熟的独立 Python 审查，但此前只能作为 `check` 内部步骤存在
- 这会直接拖慢后续继续深审的节奏：
  - 明明只是想验证一条 Python 审查
  - 但没有公开 action，就只能再绕回整条 `check`
  - 最终把“验证范围很窄”和“执行成本很高”绑死在一起
- 因而这批最值钱的改法不是再补 checker 本体，而是把 runner 的操作面收正：
  - shell 公开 case 要补齐
  - batch 顶部 dispatch / usage / help 要同步补齐
  - `check_windows_runner_parity()` 还要把这些 action 名字纳入 required pattern，避免刚公开完又被未来改动悄悄删回去
- 这批中途也抓到一个很典型的 drift 证据：
  - 首轮只改 shell/batch action 表后，`Release check` 并没有红在功能上
  - 它直接红在 `check_windows_runner_parity()` 里仍匹配旧 usage 字符串
  - 说明 runner 现在的真实风险已经不只是“功能缺失”，而是“护栏自身也会滞后于 action 表”
- 这也解释了为什么工作方式必须收窄成小闭环：
  - 先做 action 暴露
  - 立即跑 targeted action
  - 再跑一条 `check` 把 parity guard 逼出来
  - 出现旧签名漂移后当场收正
  - 这样比一上来继续大范围扫 SIMD family 更容易快速产出确定性结果
- fresh 证据已经表明这批修复是真闭环，而不是只补帮助文本：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh helper-semantics`
    - `NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh source-reachability`
    - `SIMD_SOURCE_REACHABILITY_SUMMARY tracked_includes=84 reachable_includes=83 allowed_unreachable=1 unexpected_unreachable=0 missing_include_refs=0`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh riscvv-abi-shape`
    - `RISCVV_ABI_SHAPE_SUMMARY direct_functions=121 explicit_checks=10 missing_result_store=0 suspicious_a0_loads=0 status=ok`
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `[CHECK] OK (windows runner parity signatures present)`
    - 三条 Python 审查继续在主门禁下通过
- 当前最准确的阶段结论：
  - 这批修的不是 SIMD 算法语义，而是 runner 操作面和 parity 护栏的真实漂移
  - 收完以后，后续继续深审 non-x86 Python 审查时终于可以按单条 action 快速执行，而不必默认重跑整条 `check`

## 2026-05-16 Windows Closeout Wrapper Parity Findings

- 在把 targeted Python 审查 action 暴露完以后，我继续做 completion audit，不再扫 backend，而是直接比对 shell/batch runner 的公开 action 差集。
- 差集结果很明确，且不是设计上“理应缺失”的一团模糊状态：
  - shell 已公开但 batch 缺入口的核心收口动作是：
    - `win-evidence-via-gh`
    - `win-closeout-dryrun`
    - `win-closeout-snippets`
    - `freeze-status`
    - `freeze-status-linux`
    - `freeze-status-rehearsal`
  - 这几条都属于 release closeout / freeze readiness 的公开操作面
  - 与之相比，`evidence-linux`、`native-evidence`、`verify-nonx86-native-evidence`、`restore-nightly-evidence`、`gate-summary-selfcheck` 还更像仍然可接受的 shell-only 留白
- 这说明 batch 当前的问题已经不是“个别 Python checker 少一个入口”，而是 Windows closeout 路径本身的公开 action 表不完整：
  - `win_closeout_3cmd` 文本里已经多次引导用户去跑 `freeze-status`
  - shell usage/help 也已经把这几条写成正式 action
  - 但 batch 顶部 dispatch 和 usage/help 却没有对应入口
  - 这会让 Windows/CMD 用户看到一套文案、手里却拿不到同名入口
- 这批最正确的修法不是把 batch 重写成原生实现，而是明确承认这些动作的 canonical 执行面仍在 shell：
  - batch 只补 `bash %ROOT%BuildOrTest.sh ...` wrapper
  - 这样不会分叉实现
  - 但可以把 Windows 侧的公开操作面收正
- 这批还抓到了一个更高价值的 runner 治理结论：
  - `check_windows_runner_parity()` 之前把这几条列进 `LAllowedShellOnly`
  - 所以即使 batch usage/help 和 dispatch 一直缺失，主门禁也不会红
  - 也就是说，这不是单纯的 batch 少几行 wrapper，而是 parity guard 自己在给这组公开 closeout action 开“长期豁免”
- 因而真正的修复必须同时做两件事：
  - batch 补入口
  - shell 的 parity guard 撤掉这 6 条的 shell-only allow，并把 dispatch / usage / help / wrapper run-line 纳入 required pattern
- fresh 证据也说明这批不是只做文案同步：
  - action 差集脚本 fresh 结果已经缩小为：
    - shell-only: `evidence-linux`、`gate-summary-selfcheck`、`native-evidence`、`restore-nightly-evidence`、`verify-nonx86-native-evidence`、`verify-win-evidence` 加上批处理内联处理的 `debug/release`
    - batch-only: `evidence-win`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-dryrun`
    - `[CLOSEOUT] DRYRUN OK: simulated summary stayed preview-only`
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - `[CHECK] OK (windows runner parity signatures present)`
    - 说明主门禁已经把这组新 wrapper 纳回真相源
- 当前最准确的阶段结论：
  - 这批修到的是 Windows closeout runner 的公开操作面缺口，以及 parity guard 对这组缺口的长期豁免
  - 现在 batch 至少能桥接 shell 已公开的 freeze / closeout 入口，不再让文档、shell usage 与 batch action 表长期分叉
  - 仍未完成的是 Windows 实机运行时证据；但源码和 source-safe parity 这层已经收口

## 2026-05-16 Remaining Evidence Action Parity Findings

- 把 closeout/freeze 入口补齐后，我没有假设 runner parity 已经完成，而是继续做 fresh action diff。
- diff 结果比上一批更干净，也更能说明问题：
  - shell-only 已缩到：
    - `evidence-linux`
    - `gate-summary-selfcheck`
    - `native-evidence`
    - `restore-nightly-evidence`
    - `verify-nonx86-native-evidence`
    - 外加 batch 内联/特例的 `debug`、`release`、`verify-win-evidence`
  - batch-only 则只剩 Windows 原生 alias：`evidence-win`
- 这说明 runner 公开操作面的真实尾巴已经只剩一小组同构动作：
  - 都是 shell 已公开的 evidence/selfcheck 入口
  - 都还被 `check_windows_runner_parity()` 当作 shell-only 豁免
  - 都可以用和上一批同样的 bash-delegate wrapper 方式收掉
- 因而本批最值钱的判断，不是“还能不能继续补”，而是“剩余差集是不是已经收敛到足够统一的一组动作”。
  - 答案是肯定的
  - 这 5 条不是散乱的偶发缺口，而是最后一组同类 evidence/selfcheck 公开入口
- 这批也进一步证明了一个 runner 治理规律：
  - 如果 `LAllowedShellOnly` 长期放着这些公开 action
  - shell usage/help 与 batch action 表就会一直可以分叉而不被 `Release check` 抓到
  - 所以最后的真正收口，不只是补 wrapper，而是持续缩减 allowlist 到只剩确实必须 shell-only 的动作
- fresh 证据已经把这点说得很清楚：
  - `python3 ...` action diff 现在只剩：
    - shell-only：`debug`、`release`、`verify-win-evidence` 这类内联/特例
    - batch-only：`evidence-win` 这类 Windows alias
  - 说明 runner 公共 action 表基本已经收拢完毕
- 本批用 `gate-summary-selfcheck` 做轻量烟测也很合适，因为它正好覆盖了这轮 runner 设计里最敏感的一条线：
  - gate-summary 导出
  - filter 行为
  - JSON 自检
  - `freeze-status-rehearsal`
  - 这条通过，意味着新 wrapper 并不是“能跳进去就算完”，而是背后关键自检链条仍然有效
- 当前最准确的阶段结论：
  - `simd` runner 的公开 action parity 已经从“大量 shell-only 漂移”收缩到“只剩内联控制流和平台别名差异”
  - 后续如果还要继续深审 runner，这条线应从“继续补 action 表”转向“验证剩余特例是否值得保持特例”

## 2026-05-16 Batch Inline Action Normalization Findings

- 在把最后一组 evidence/selfcheck wrapper 补齐后，我没有把“只剩少量差异”直接当完成，而是继续对差异本身做分类。
- fresh action diff 给出的关键信号是：
  - shell-only 已经不再是功能缺口，而只剩 batch 顶部的内联控制流：
    - `debug`
    - `release`
    - `verify-win-evidence`
  - batch-only 则是 Windows alias：
    - `evidence-win`
    - `evidence-win-verify`
- 这说明 runner parity 线已经进入最后一个更细的阶段：
  - 不再是“缺动作”
  - 而是“同一个动作是否还要以特殊分支存在”
- 因而这批最合适的修法不是继续补 wrapper，而是把 batch 顶部剩余的内联特例收成显式 label dispatch：
  - `debug -> :debug_action`
  - `release -> :release_action`
  - `verify-win-evidence -> :verify_win_evidence`
  - `evidence-win-verify -> :evidence_win_verify`
- 这批的价值主要在可审计性，而不是行为变化：
  - 顶部 action 表终于能被同一种 `goto` 结构完整扫描
  - `check_windows_runner_parity()` 不用再对 `verify-win-evidence` 这类动作写特殊 inline 模式
  - 后续再做 action diff 时，结果可以直接收敛到“只剩 Windows alias”
- fresh 证据也正好验证了这一点：
  - 标准化前：
    - shell-only 还会显示 `debug`、`release`、`verify-win-evidence`
  - 标准化后：
    - `remaining shell_only: []`
    - `remaining batch_only: ['evidence-win', 'evidence-win-verify']`
  - 这说明 runner 的公开 action parity 现在已经不是“基本一致”，而是“公共 action 表完全收平，剩余差异只剩平台 alias”
- `Release check` 继续通过也很关键，因为它证明这次不是“为了好看去改 dispatch 表”，而是：
  - parity guard 继续为绿
  - 主门禁仍能完整穿过 adapter/checker/standalone smoke/selfcheck 链
  - 说明这次结构标准化没有把 batch 调度行为改坏
- 当前最准确的阶段结论：
  - runner parity 这条线现在已经真正收到了“只剩 alias，不剩隐藏特例”的状态
  - 后续若继续审 `simd` runner，更值得看的将不是 dispatch 表，而是 Windows alias 是否还要长期保留双名字入口

## 2026-05-16 Runner Parity Quick Path

- 当前剩余的 `evidence-win` / `evidence-win-verify` 不是“忘删的 drift action”，而是仓库显式允许的 `Windows-only` native evidence alias：
  - `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_windows_runner_parity()` 已把它们放进 `LAllowedWindowsOnly`
  - runbook / checklist / freeze evaluator / closeout helper 仍真实引用这两条入口
- 因而这条线的真实问题已经不再是“删 alias”，而是“证明 runner parity 没坏的成本过高”：
  - 之前每次改 batch/shell dispatch/help，都要借道 `BuildOrTest.sh check` 大链顺带跑到 parity guard
  - 这会把一个 source-safe 静态问题，拖成一次耗时的 release-style 验证
- 本轮修法应是补轻量入口，而不是继续扩大 alias 面或重跑大链：
  - 新增 `runner-parity` 后，后续 runner 批次可以直接用它证明 shell/batch/cpuinfo parity
  - `evidence-win` / `evidence-win-verify` 继续保留为有意的 Windows-only alias，不再把它们当成待消灭的差集

## 2026-05-16 Runner Parity Call-Site Unification

- `runner-parity` 入口补完后，`BuildOrTest.sh` 里仍有一层轻微漂移：
  - `check` case 自己直调一次 `check_windows_runner_parity()` 与 `check_cpuinfo_runner_parity()`
  - `gate_step_build_check()` 也再直调一次同一对函数
- 这不再是功能 bug，但属于典型“同一证明链已经封装、主门禁却继续保留旧入口”的调用面冗余。
- 这类冗余的真实风险不是运行结果错误，而是后续如果 `run_runner_parity()` 再补额外 guard，`check` / gate 若忘记同步，就会重新出现“action 绿了但主门禁没跟上”的次级漂移。
- 因而最小正确修法就是：
  - 保留 `run_runner_parity()` 作为唯一封装入口
  - `check` 与 `gate_step_build_check()` 都只调它，不再各自拼同一对底层函数

## 2026-05-16 Gate Build-Check Static Guard Parity

- `run_runner_parity()` 调用面收平后，再对 `check` case 和 `gate_step_build_check()` 做清单比对，暴露出一处更实质的 coverage drift：
  - gate 后续确实会单独跑 `experimental intrinsics isolation`
  - gate 也会在 opt-in backend 打开时单独跑 `register truthfulness`
  - 但 `helper-semantics`、`key-slot-audit`、`source-reachability`、`sse2-structure`，以及 `windows cpuinfo.x86 batch success-criteria smoke` 没有任何后续 gate step 补跑
- 这意味着之前的 `gate` 绿灯并不真正覆盖这一组已经被 `check` 视为默认静态门禁的审查项。
- 这些项的共同点正好说明它们应补进 `gate_step_build_check()`，而不是另开新的 gate phase：
  - 都是 source-safe / 低成本检查
  - 不会引入新的 artifact branch 或复杂摘要维度
  - 语义上都属于 “build + static guard” 同一阶段

## 2026-05-16 Shared Static Build-Check Core

- 继续往下看后，coverage 缺口虽然已经补上，但结构性根因还在：
  - `check` case 与 `gate_step_build_check()` 仍分别维护一整段几乎相同的静态 guard/smoke 清单
  - 这正是本轮连续出现 runner parity drift、coverage drift 的根源
- fresh 对比后，当前这两段已经缩到只剩“有意差异”：
  - `check` 独有：adapter-sync 提示、`SIMD_CHECK_NONX86_OPTIN` 条件分支、`wiring-sync`、`register truthfulness`、experimental isolation
  - `gate` 独有：在 build-check 阶段无条件跑一次 `run_nonx86_optin_list_suites`
  - 其余从 `run_runner_parity` 到 `run_dispatch_preinit_smoke` 的静态 core 已完全同构
- 因而最小正确修法不再是继续补单点，而是把这段共同 core 提成共享 helper，让未来再加/删静态 guard 时默认只改一处

## 2026-05-16 IEEE754 Empty Finally Cleanup

- 在用户明确要求改进工作方法后，我没有再继续围绕 runner 线做大范围只读深挖，而是重新选择一个证据更硬的小目标：`tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas` 中仍残留一组顶层空 `finally`。
- 这批命中的共同特征非常明确：
  - 都是 top-level test body 的 outer `try/finally`
  - `finally` 体完全为空
  - 其中多处还保留 `oldVectorAsm/LOldVectorAsm := IsVectorAsmEnabled`，但后续没有任何读取
- 这些块与前面已经保留的真实恢复点不同：
  - `NonX86IEEE754` 每后端迭代里的 `finally ResetToAutomaticBackend` 仍然有真实状态语义
  - 当前保留下来的 `finally` 命中，也都仍是这种 non-empty restore 块
  - 所以这轮不该再按 `finally` 形状盲扫，而应只删除“空壳 cleanup”
- 这批清理的真实价值不只是少几行代码：
  - 去掉了“看起来像手工恢复、实际上什么也没做”的误导结构
  - 去掉了未使用的状态捕获，降低以后继续误以为这里还依赖 method-local restore 的概率
  - 同时完全不触碰 `TearDown` 与 inner restore 语义，风险边界很清楚
- fresh 验证也证明这是纯冗余清理，不是行为变更：
  - `git diff --check` 通过
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754EdgeCases --suite=TTestCase_AVX2RoundTruncIEEE754 --suite=TTestCase_NonX86IEEE754`
  - 输出为 `[BUILD] OK`、`[TEST] OK`、`[LEAK] OK`

## 2026-05-16 DataPlane Empty Finally Cleanup

- 这轮没有重新扩散扫描，而是延续上一批的高确定性冗余线，只收 `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas` 中一个 dataplane 用例的空壳 cleanup。
- fresh 复核后，这个点和前一批 `ieee754` 的纯空 `finally` 属于同类，但判断依据更明确：
  - `TTestCase_DataPlane = class(TSimdVectorAsmStatefulTestCase)`
  - `TSimdVectorAsmStatefulTestCase.TearDown` 负责恢复 `FSavedVectorAsm`
  - `TSimdBackendStatefulTestCase.TearDown` 负责恢复 `FSavedBackend`
  - 因而 `Test_DataPlane_VectorAsmRoundTrip_Reuses_PreviouslyPublishedSnapshot` 外层的空 `finally` 并不承担任何 method-local 状态恢复职责
- 该用例里同时还残留一个失效信号：
  - `LOldVectorAsm := IsVectorAsmEnabled`
  - 后续没有任何读取
  - 这会制造“这里似乎还依赖局部 restore”的错觉
- 本轮已完成的源码收口：
  - 删除 `LOldVectorAsm` 局部变量与赋值
  - 删除对应纯空 outer `try/finally`
  - 保留 `SetVectorAsmEnabled(True/False)` 切换、`ResetToAutomaticBackend`、backend 分支提前退出和 dataplane 快照断言不变
- fresh 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批仍是纯测试层冗余清理，没有改 dataplane 发布逻辑或 SIMD 生产实现
  - `dataplane.testcase` 这个 round-trip 用例里“假装在做 cleanup、实际上没有任何恢复语义”的外层壳已经去掉；后续若继续沿这条线深审，应优先挑类似小范围、高置信度的空壳 cleanup，而不是重新铺开大文件盲扫

## 2026-05-16 PublicAbi Early Empty Finally Cleanup

- 这轮继续保持“小闭环直收口”，没有重新铺开 `dispatchapi`/`direct` 这种超大文件，而是先拿 `publicabi.testcase` 前部两处最早命中做 fresh 复核。
- 这两处之所以能归到和 `dataplane/ieee754` 同类，不只是因为形状相似，而是因为它们共享同一个基类恢复前提：
  - `TTestCase_PublicAbi = class(TSimdVectorAsmStatefulTestCase)`
  - `TSimdVectorAsmStatefulTestCase.TearDown` 负责恢复 `FSavedVectorAsm`
  - `TSimdBackendStatefulTestCase.TearDown` 负责恢复 `FSavedBackend`
  - 因而 method body 外层的空 `finally` 并不承担额外 restore 职责
- fresh 读到的两个前部命中点都符合高确定性冗余特征：
  - `Test_PublicApi_Table_Uses_Stable_Cdecl_EntryPoints_AfterBackendSwitch`
  - `Test_PublicApi_VectorAsmRoundTrip_Reuses_PreviouslyPublishedMetadataTable`
  - 都保留 `LOldVectorAsm := IsVectorAsmEnabled`，但后续没有任何读取
  - 都有纯空 outer `try/finally`
- 本轮已完成的源码收口：
  - 删除上述两个用例中的 `LOldVectorAsm` 局部变量与赋值
  - 删除对应纯空 outer `try/finally`
  - 保留 `SetVectorAsmEnabled`、`ResetToAutomaticBackend`、backend 选择、public ABI metadata table / cdecl entry-point 断言不变
- fresh 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批仍是纯测试层冗余清理，没有改 public ABI 发布逻辑或 SIMD 生产实现
  - `publicabi.testcase` 前部这两处“伪 cleanup”已经收掉；如果下一轮继续沿这条线推进，应优先找同一文件里仍具备相同基类恢复前提、且语义简单的前部命中，而不是马上跳去 hook/rollback 深水区

## 2026-05-16 PublicAbi CapabilityBits Empty Finally Cleanup

- 在前部两处 `publicabi` 命中收口后，我没有切回别的文件，而是继续沿同一文件前部做分段复核，这次锁定的是 capability-bits 测试簇。
- 这组命中之所以适合成批处理，是因为它们共享四个关键特征：
  - 都属于 `TTestCase_PublicAbi = class(TSimdVectorAsmStatefulTestCase)`
  - 都只围绕 `SetVectorAsmEnabled(True/False)`、代表性 slot 对比和 capability bit 断言展开
  - 都保留 `LOldVectorAsm := IsVectorAsmEnabled`，但没有任何读取
  - 都有纯空 outer `try/finally`
- fresh 复核后，这一串里前部 9 个用例都符合“空壳 cleanup”而非“隐藏 restore”：
  - `...DoNotUnderclaim_Shuffle`
  - `...DoNotUnderclaim_X86MaskedOps`
  - `...Expose_AVX2Shuffle_WhenNativeSlotsPresent`
  - `...Clear_X86Shuffle_WhenVectorAsmDisabled`
  - `...Keep_X86IntegerOps_When_AlwaysOn_NarrowSlots_Remain_NonScalar`
  - `...Expose_AVX512FMA_WhenNativeSlotsPresent`
  - `...Expose_AVX512Shuffle_WhenNativeSlotsPresent`
  - `...Clear_AVX512VectorAsmGatedBits_WhenVectorAsmDisabled`
  - `...Keep_X86MaskedOps_WhenVectorAsmDisabled`
- 本轮已完成的源码收口：
  - 删除上述 9 个用例中的 `LOldVectorAsm` 局部变量与赋值
  - 删除对应纯空 outer `try/finally`
  - 保留所有 capability bit 判定、dispatch slot 对比、vector-asm enable/disable 路径与 backend 范围筛选不变
- fresh 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依然是纯测试层冗余清理，没有改 public ABI 发布逻辑或 SIMD 生产实现
  - `publicabi` 前部 capability-bits 簇里最整齐的一段“死状态捕获 + 空 finally”已经收掉；后续如果继续深审同文件，优先级应继续沿“前部简单语义段”往下，而不是立刻切到 hook/rollback 段

## 2026-05-16 PublicAbi NEON RISCVV Empty Finally Cleanup

- 这轮继续沿同一文件、同一条 capability-bits 冗余线往下推进，但没有把后续整段一起扫掉，而是先按语义分层。
- fresh 复核后，这一段里真正和前两批同类的只有 5 个用例：
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_NEONVectorAsmGatedBits_WhenVectorAsmDisabled`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVIntegerOps_WhenNativeSlotsPresent`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVFMA_WhenNativeSlotsPresent`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVShuffle_WhenNativeSlotsPresent`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_RISCVVVectorAsmGatedBits_WhenVectorAsmDisabled`
- 它们共同满足的安全前提依旧成立：
  - 仍处于 `TTestCase_PublicAbi = class(TSimdVectorAsmStatefulTestCase)` 下
  - `TearDown` 继续统一恢复 vector-asm/backend 状态
  - 方法体只做 capability bit / representative slot / runtime rebuild 断言
  - `LOldVectorAsm` 统一只赋值不读取，outer `finally` 统一为空
- 同时也明确识别了边界：
  - 紧随其后的 `Test_PublicApi_BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable`
  - 外层 `try/finally` 虽也存在，但内部有真实 `RegisterBackend(LOriginalBackend, LOriginalTable)` restore 链
  - 所以这一轮明确不碰它
- 本轮已完成的源码收口：
  - 删除上述 5 个用例中的 `LOldVectorAsm` 局部变量与赋值
  - 删除对应纯空 outer `try/finally`
  - 保留 NEON/RISCVV capability 判定、runtime rebuild 路径与 backend 查询断言不变
- fresh 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批仍然是纯测试层冗余清理，没有改 public ABI 发布逻辑或 SIMD 生产实现
  - `publicabi` capability-bits 段里 NEON/RISCVV 这组同形态“死状态捕获 + 空 finally”也已经收掉；后续继续深审同文件时，下一步要更谨慎地区分“空 finally”与“包着真实 restore 的 finally”

## 2026-05-16 PublicAbi PostCapability Empty Finally Cleanup

- 这轮继续沿 `publicabi.testcase` 往后推进，但没有再把“空 finally”当成单一形状问题，而是先精确区分谁的真实 restore 在哪里。
- fresh 复核后，这一段里适合继续清理的只有 4 个方法：
  - `Test_PublicApi_ActiveBackendId_Tracks_RegisterSlot_After_ReRegister`
  - `Test_PublicApi_StableState_Tracks_CurrentBackend_After_ControlPlaneSwitches`
  - `Test_PublicApi_ActiveBackendId_Tracks_FinalState_When_HookReRegister_Overrides_ForcedSelection`
  - `Test_PublicApi_FailedHookMutation_Restores_AutomaticBackend_Immediately`
- 它们之所以仍然属于高确定性冗余，是因为：
  - `LOldVectorAsm := IsVectorAsmEnabled` 后没有任何读取
  - 外层 `finally` 为空
  - 真正 restore 已由内层 `finally` 承担，例如 `RegisterBackend(...)` / `DisablePublicAbiDisableBackendHook`
  - 或由 `TSimdVectorAsmStatefulTestCase.TearDown` / `TSimdBackendStatefulTestCase.TearDown` 统一恢复
- 同时这轮也明确踩住了边界，没有误清后续更复杂的路径：
  - `Test_PublicApi_FailedHookMutation_DoesNotRevive_PreviouslyRequestedBackend_AfterRestore`
  - `Test_PublicApi_FailedHookMutation_Restores_PreviousForcedBackend`
  - 这类方法的外层 `finally` 自身带条件 restore，例如 `if LRequestedTableCaptured then RegisterBackend(...)`
  - 所以不能按“空 finally”同类处理
- 本轮已完成的源码收口：
  - 删除上述 4 个方法中的 `LOldVectorAsm` 局部变量与赋值
  - 删除对应纯空 outer `try/finally`
  - 保留 identity re-register、stable-state、hook disable/restore、automatic backend 回退断言不变
- fresh 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧是纯测试层冗余清理，没有改 public ABI 发布逻辑或 SIMD 生产实现
  - 现在 `publicabi` 中最危险的误判点已经从“空 finally”本身转成“外层 finally 是否还承担条件 restore”；后续继续深审时必须沿这个边界做

## 2026-05-16 PublicAbi Automatic Restore Empty Finally Cleanup

- 这轮继续沿 `publicabi.testcase` 向后推进，但只拿 automatic backend / vector-asm late-force 这一小组开刀，没有把后面更复杂的 previous-forced preserve 路径一起带上。
- fresh 复核后，这一组里 5 个方法仍然满足同样的高确定性冗余模式：
  - `Test_PublicApi_ResetToAutomaticBackend_HookLateForce_Restores_AutomaticBackend`
  - `Test_PublicApi_Refreshes_WhenVectorAsmDisabled_ReSelects_Away_From_ScalarBacked_CurrentBackend`
  - `Test_PublicApi_ResetToAutomaticBackend_HookLateForce_DuringRestore_Restores_AutomaticBackend`
  - `Test_PublicApi_SetVectorAsmEnabled_HookLateForce_Restores_AutomaticBackend`
  - `Test_PublicApi_SetVectorAsmEnabled_HookLateForce_DuringRestore_Restores_AutomaticBackend`
- 这 5 个点可安全清理的依据：
  - `LOldVectorAsm := IsVectorAsmEnabled` 后没有任何读取
  - 外层 `finally` 为空
  - 真正的 hook remove / flag reset 仍在内层 `finally`
  - 剩余 vector-asm/backend 状态仍由 `TSimdVectorAsmStatefulTestCase.TearDown` 和 `TSimdBackendStatefulTestCase.TearDown` 统一恢复
- 这轮也继续保持边界意识：
  - 没有把后面 `SetVectorAsmEnabled_HookLateAutomaticReset_Preserves_PreviousForcedBackend` 及同族 previous-forced preserve 测试一起带上
  - 那一串虽然形态相似，但语义上更强调“保留先前强制后端”的稳定性路径，适合单独分层再处理
- 本轮已完成的源码收口：
  - 删除上述 5 个方法中的 `LOldVectorAsm` 局部变量与赋值
  - 删除对应纯空 outer `try/finally`
  - 保留 automatic backend、scalar precondition、dispatch hook cleanup、public ABI active-backend 断言不变
- fresh 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧是纯测试层冗余清理，没有改 public ABI 发布逻辑或 SIMD 生产实现
  - `publicabi` 后半段里 automatic/vector-asm late-force 这一组同形态空壳 cleanup 也已收掉；后续继续深审时，最值得看的下一层就是 previous-forced preserve 那串是否也能按同一边界安全拆分

## 2026-05-16 PublicAbi Previous Forced Empty Finally Cleanup

- 这轮继续沿 `publicabi.testcase` 的 same-file 路径向后推进，但只收 previous-forced preserve 段里最干净的 4 个点，没有把整串一口吞下。
- fresh 复核后，这 4 个方法仍然满足与前几批一致的安全前提：
  - `Test_PublicApi_SetVectorAsmEnabled_HookLateAutomaticReset_Preserves_PreviousForcedBackend`
  - `Test_PublicApi_SetVectorAsmEnabled_HookLateAutomaticReset_DuringRestore_Preserves_PreviousForcedBackend`
  - `Test_PublicApi_SetVectorAsmEnabled_HookLateForce_DuringRestore_Preserves_PreviousForcedBackend`
  - `Test_PublicApi_RegisterBackend_HookLateForce_Restores_AutomaticBackend`
- 之所以能安全清理，是因为：
  - `LOldVectorAsm := IsVectorAsmEnabled` 后没有任何读取
  - 外层 `finally` 为空
  - 真正的 hook remove / stage reset 仍在内层 `finally`
  - 其余 vector-asm/backend 状态仍由基类 `TearDown` 统一恢复
- 同时这轮继续明确保留边界，没有误清更危险的同段路径：
  - `Test_PublicApi_RegisterBackend_HookLateAutomaticReset_Preserves_PreviousForcedBackend`
  - `Test_PublicApi_RegisterBackend_HookLateForce_DuringRestore_Preserves_PreviousForcedBackend`
  - 它们的外层 `finally` 仍承担 `if LPreviousTableCaptured then RegisterBackend(...)` 这一类条件 restore
  - 所以这轮明确不碰
- 本轮已完成的源码收口：
  - 删除上述 4 个方法中的 `LOldVectorAsm` 局部变量与赋值
  - 删除对应纯空 outer `try/finally`
  - 保留 previous forced backend 断言、dispatch hook cleanup、RegisterBackend late-force 行为断言不变
- fresh 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧是纯测试层冗余清理，没有改 public ABI 发布逻辑或 SIMD 生产实现
  - 现在 `publicabi` 里剩下最值得继续深审的，就是那些外层 finally 已开始承担条件 table restore 的路径；它们不能再按当前模式机械推进

## 2026-05-16 PublicAbi Remaining Empty Finally Cleanup Repair

- 本轮最后 4 个 `publicabi` 同类命中里，真正值得警惕的不是“还有没有空 finally”，而是“前一轮把 empty `finally` 删掉后，outer `try` 是否也同步消失”。
- fresh 现场已证明这一点会直接变成 Pascal 结构错误：
  - `Test_PublicApi_BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable`
  - `Test_PublicApi_RollbackRestore_ReSelects_RequestedBackend_Before_Return`
  - 两处都曾留下孤立 outer `try`，从而触发 `Syntax error, "EXCEPT" expected but "END" found`
- 这轮修复后再次确认：
  - `CachedTable_RemainsCallable_Across_Rebind`
  - `CachedTable_Preserves_PreviousSnapshot_Metadata_Across_Rebind`
  - 这两处只是纯空 outer `try/finally`，删除后没有额外 restore 责任残留
- 同时确认 `RollbackRestore_ReSelects_RequestedBackend_Before_Return` 中的 `LOldVectorAsm` 也是死变量：
  - 只赋值 `IsVectorAsmEnabled`
  - 后续没有任何读取
  - 真正的 hook remove / stage reset / `RegisterBackend(...)` restore 仍在内层 `finally`
- `rg -n -U "finally\\s*\\n\\s*end;" tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 本轮已无命中，说明这批“纯空 finally”残余已经从当前 `publicabi.testcase` 清干净。
- 当前最重要的审查边界进一步收紧为：
  - 可以继续收：外层 `finally` 为空，且真实 restore 由内层 `finally` 或基类 `TearDown` 承担
  - 不能机械收：外层 `finally` 还承担 `if ...Captured then RegisterBackend(...)` 之类的条件 restore

## 2026-05-16 PublicAbi Remaining Dead VectorAsm Capture Cleanup

- 当前 `publicabi.testcase` 在清完纯空 `finally` 后，剩余最高确定性的冗余已经进一步收敛成：`LOldVectorAsm := IsVectorAsmEnabled` 的死状态捕获。
- 这轮用 `rg -n "LOldVectorAsm"` 复核后，当前文件剩余 9 组命中都满足同一个事实：
  - 只有局部变量声明
  - 只有一次 `IsVectorAsmEnabled` 赋值
  - 文件内没有任何对应读取
- 这 9 个方法之所以前一轮没有一起删，不是因为变量还有语义，而是因为它们的 outer `finally` 仍承担真实 restore：
  - `if LRequestedTableCaptured then RegisterBackend(...)`
  - `if LPreviousTableCaptured then RegisterBackend(...)`
  - 或 rollback higher-priority backend 的恢复
- 因此这轮新的安全边界是：
  - 只删 `LOldVectorAsm` 这个死变量
  - 不动这些方法现有的 inner/outer `finally`
  - 不再把“有 restore 的 finally”误当成“空壳 cleanup”
- fresh 复核后，`publicabi.testcase` 里已经没有任何 `LOldVectorAsm` 残留；这说明同一条“无读取状态捕获”冗余线在当前文件里也已收干净。

## 2026-05-16 DispatchApi Front Empty Finally And Dead VectorAsm Cleanup

- 把同样的审查法扩到 `dispatchapi.testcase` 前段后，前 `990..1675` 区间也出现了和 `publicabi` 类似的双重冗余：
  - 一批简单 API smoke 用例包着纯空 outer `try/finally`
  - 一批 hook / rollback / previous-forced 用例的 `LOldVectorAsm := IsVectorAsmEnabled` 只赋值不读取
- 这一段最重要的边界和 `publicabi` 一致：
  - `Test_TrySetActiveBackend_FailedHookMutation_Restores_PreviousForcedBackend`
  - `Test_TrySetActiveBackend_RollbackRestore_Success_Preserves_ForcedSelection`
  - `Test_TrySetActiveBackend_RollbackRestore_LateForce_Restores_AutomaticBackend`
  - `...Preserves_PreviousForcedBackend`
  - 这些方法的 outer `finally` 仍承担条件 `RegisterBackend(...)` restore，因此只能删死变量，不能机械删掉 `finally`
- 与此同时，前部这些方法则是纯空壳，可直接去掉 outer `try/finally`：
  - `Test_TryForceBackend_Scalar_ReturnsTrue`
  - `Test_TryForceBackend_Unavailable_NoChange`
  - `Test_TrySetActiveBackend_Scalar_ReturnsTrue`
  - `Test_TrySetActiveBackend_Unavailable_NoChange`
  - `Test_SetActiveBackend_Unavailable_FallsBackToScalar`
  - 以及几条真正 restore 已由 inner `finally` 承担的 hook/rollback 用例
- 这说明当前 `dispatchapi` 也能沿同样的 fail-close 准则推进：
  - 先分清“真空壳 finally”和“承担 restore 的 finally”
  - 再把“只声明 + 只赋值”的 vector-asm 状态捕获单独剥离

## 2026-05-16 DispatchApi Mid Empty Finally And Dead VectorAsm Cleanup

- `dispatchapi.testcase` 的下一段 `1684..2328` 继续证明了上一批的判断：真正该防止误删的，不是 `try/finally` 语法本身，而是 outer `finally` 有没有承担 restore 职责。
- 这段里可以直接删壳的空 outer `finally` 主要集中在：
  - `Test_BackendInfoAvailableFalse_IsNotSelectable`
  - `Test_ResetToAutomaticBackend_HookLateForce_Restores_AutomaticBackend`
  - `Test_ResetToAutomaticBackend_HookLateForce_DuringRestore_Restores_AutomaticBackend`
  - `Test_SetVectorAsmEnabled_HookLateForce_Restores_AutomaticBackend`
  - `Test_SetVectorAsmEnabled_HookLateForce_DuringRestore_Restores_AutomaticBackend`
  - `Test_SetVectorAsmEnabled_HookLateAutomaticReset_Preserves_PreviousForcedBackend`
  - `Test_SetVectorAsmEnabled_HookLateAutomaticReset_DuringRestore_Preserves_PreviousForcedBackend`
  - `Test_SetVectorAsmEnabled_HookLateForce_DuringRestore_Preserves_PreviousForcedBackend`
  - `Test_RegisterBackend_HookLateForce_Restores_AutomaticBackend`
  - `Test_RegisterBackend_Canonicalizes_TableIdentity_For_ForcedSelection`
- 与之相对，这几条方法虽然也带未读取的 `LOldVectorAsm`，但 outer `finally` 还承担条件 table restore，因此只能删变量，不能删壳：
  - `Test_SetActiveBackend_HookLateFailure_Preserves_PreviousForcedBackend`
  - `Test_RegisterBackend_HookLateAutomaticReset_Preserves_PreviousForcedBackend`
  - `Test_RegisterBackend_HookLateForce_DuringRestore_Preserves_PreviousForcedBackend`
- 这轮新的实证结论是：
  - `dispatchapi` 里“纯空 outer finally”与“死 vector-asm 状态捕获”并不是随机散点，而是沿 hook/rollback/restore 家族成簇出现
  - 但这些簇内部仍必须按 restore 责任再分层，不能整簇机械删除

## 2026-05-16 DispatchApi Metadata And Snapshot Empty Finally Cleanup

- `dispatchapi.testcase` 的再下一簇 `2277..2810` 说明，高确定性冗余不只存在于 hook/rollback 家族，也存在于 metadata / snapshot round-trip 这类“断言链长但 restore 简单”的测试。
- 这簇里最干净的纯空 outer `finally` 命中是：
  - `Test_SupportedAliases_StayCpuOnly_WhenBackendBecomesNonDispatchable`
  - `Test_RegisteredBackendDispatchTable_PreservesCanonicalTextMetadata_After_ReRegister`
  - `Test_CurrentBackendInfo_PreservesCanonicalTextMetadata_After_ReRegister`
- 同时，这几个方法既有纯空 outer `finally`，也带未读取的 `LOldVectorAsm`：
  - `Test_PublicSmokeDefaultBackendPredictor_Tracks_CanonicalDispatchPriority`
  - `Test_VectorAsmDisabled_ReSelects_Away_From_ScalarBacked_CurrentBackend`
  - `Test_RegisterBackend_SameBackendRoundTrip_Reuses_PreviouslyPublishedDispatchSnapshot`
  - `Test_SetVectorAsmEnabled_RoundTrip_Reuses_PreviouslyPublishedDispatchSnapshot`
- 这批之所以仍然安全，是因为它们的真实 restore 责任都在内层 `finally`：
  - `RegisterBackend(LOriginalBackend, LOriginalTable)`
  - `RegisterBackend(sbAVX2, LAVX2Table)`
  - `RegisterBackend(LBackend, LOriginalTable)`
  - 外层 `finally` 本身完全为空
- 新的判断更新为：
  - `dispatchapi` 里“空 outer finally + 死状态捕获”已经从控制流类测试扩展到 metadata / snapshot consistency 测试
  - 但只要 restore 责任仍明确落在内层 `finally`，这类冗余同样可以安全拆掉

## 2026-05-16 DispatchApi Facade Dispatch Tracking Empty Finally Cleanup

- `dispatchapi.testcase` 的 `2796..3445` 进一步证明，纯空 outer `finally` 还广泛存在于“facade 必须跟随 current dispatch table”的追踪测试簇里。
- 这一簇的形态非常统一：
  - 外层只是 `ResetToAutomaticBackend` 后改造当前 backend table
  - 真正的 restore 都在内层 `finally` 里做 `RegisterBackend(LBackend, LOriginalTable)`
  - 外层 `finally` 为空
- 当前可直接删壳的代表包括：
  - `Test_VecF32x4ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF64x2ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF64x2MathFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF32VectorMathFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecWideFloatDotFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF64x4ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF32x8ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF64x8ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
  - `Test_VecF32x16ReduceFacade_Tracks_CurrentDispatchTable_After_ReRegister`
- 同簇里的 `Test_CurrentBackendHelpers_StayAligned_After_ControlPlaneSwitches` 还额外带了一个未读取的 `LOldVectorAsm`，但同样不承担 restore 责任，因此也可以一起安全剥离。
- 这轮的新增判断是：
  - 当测试目的只是验证“facade 是否跟随当前 dispatch snapshot”，而 restore 明确由内层 `RegisterBackend(...)` 承担时，外层 `try/finally` 几乎都是机械遗留
  - `dispatchapi` 里的高确定性冗余已经从 control-plane / metadata 簇进一步扩到了 façade tracking 簇

## 2026-05-16 DispatchApi SSE2 Impl Audit Empty Finally Cleanup

- `dispatchapi.testcase` 的 `5128..5459` 证明，高确定性冗余并不只出现在 rollback / snapshot / facade tracking 测试里，连带 source-shape 审计的 SSE2 parity 测试也出现了同一种机械壳。
- 这次确认可安全清理的 3 条方法是：
  - `Test_SSE2_I32x4_U32x4_Mul_Use_NonScalar_Impl_And_Keep_Parity`
  - `Test_SSE2_I64x2_Compare_Use_NonScalar_Impl_And_Keep_Parity`
  - `Test_SSE2_F32VectorMath_Use_NonScalar_Impl_And_Keep_Parity`
- 它们的共同边界非常一致：
  - 前半段只做 SSE2 源码/实现形态审计，真实资源释放仅由 `LSourceLines.Free` 这种内层 `finally` 承担
  - 后半段只是 `SetVectorAsmEnabled(True)`、选择 `sbSSE2`、再做 dispatch/parity 断言
  - outer `finally` 体完全为空
  - `LOldVectorAsm := IsVectorAsmEnabled` 仅被捕获，从未参与 restore 或断言
- 这进一步收紧了当前准则：
  - 只要 outer `finally` 不承担 `RegisterBackend(...)`、hook cleanup 或其他真实 restore，哪怕测试本身同时包含 source-shape 审计和 runtime parity，也仍然可以按同一 fail-close 规则剥掉空壳
  - `dispatchapi` 当前的冗余分布已覆盖 control-plane、metadata/snapshot、facade tracking，以及 SSE2 implementation audit 四类测试簇

## 2026-05-16 DispatchApi RISCVV And AVX512 Empty Finally Cleanup

- `dispatchapi.testcase` 的 `9358..10471` 说明，空 outer `finally` 与死 `LOldVectorAsm` 还继续分布在 `RISCVV` register-source 审计和一组 `AVX512` mapping/parity 测试里，不只存在于 earlier SSE2 和 façade tracking 簇。
- 这次确认可安全清理的 5 条方法是：
  - `Test_RISCVV_RegisterSource_Deduplicates_WideRoundingAssignments_And_Keeps_F64x2_Exception`
  - `Test_AVX512_U32x16_U64x8_MappingAndParity`
  - `Test_AVX512_U32x16_U64x8_ShiftBoundary_Contracts`
  - `Test_AVX512_I16x32_I8x64_U8x64_MappingAndParity`
  - `Test_AVX512_F32x16_F64x8_IEEE754_MappingAndParity`
- 它们的共同边界和前几批完全一致：
  - source file 的真实资源释放仍只由内层 `LSourceLines.Free` 一类 `finally` 承担
  - 运行期部分只做 `SetVectorAsmEnabled(True)`、选择 backend、做 mapping/capability/parity 断言
  - outer `finally` 本身完全为空
  - `LOldVectorAsm := IsVectorAsmEnabled` 只是机械捕获，没有 restore、没有断言、也没有后续读取
- 新的收敛判断是：
  - 当测试只是验证 published slot / parity / source-shape 合同，而 outer `finally` 不承担任何 restore 时，可以继续机械剥离这类空壳
  - `dispatchapi` 当前的高确定性冗余已经从 SSE2 和 façade tracking，继续扩展到了 `RISCVV` rounding register-source audit 与 `AVX512` family mapping/parity 簇

## 2026-05-16 DispatchApi Capability And AVX2 FMA Empty Finally Cleanup

- `dispatchapi.testcase` 的 `10549..10944` 说明，空 outer `finally` 与死 `LOldVectorAsm` 还继续分布在 backend capability 合同测试和 `AVX2` FMA 能力位合同测试里，不只存在于 earlier parity/source-shape 簇。
- 这次确认可安全清理的 8 条方法是：
  - `Test_BackendCapabilities_DoNotUnderclaim_Shuffle`
  - `Test_X86_BackendCapabilities_DoNotUnderclaim_MaskedOps`
  - `Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled`
  - `Test_X86_BackendCapabilities_Keep_IntegerOps_When_AlwaysOn_NarrowSlots_Remain_NonScalar`
  - `Test_X86_BackendCapabilities_Keep_MaskedOps_When_VectorAsmDisabled`
  - `Test_AVX2_BackendCapabilities_Expose_FMA_When_FusedPathUsable`
  - `Test_AVX2_BackendCapabilities_Clear_FMA_When_VectorAsmDisabled`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2FMA_When_FusedPathUsable`
- 它们的共同边界和前几批仍然一致：
  - 运行期部分只做 `SetVectorAsmEnabled(True/False)`、读取 backend table、再做 capability 或 FMA witness 合同断言
  - outer `finally` 本身完全为空
  - `LOldVectorAsm := IsVectorAsmEnabled` 只是机械捕获，没有 restore、没有断言、也没有后续读取
- 这再次强化当前准则：
  - 即使测试主题从 parity/source-shape 切换成 capability bits、public ABI pod info 或 fused-FMA witness，只要 outer `finally` 不承担真实恢复职责，就仍然可以按同一 fail-close 规则剥掉机械空壳
  - `dispatchapi` 当前的高确定性冗余已经覆盖 control-plane、metadata/snapshot、facade tracking、SSE2 审计、RISCVV/AVX512 parity，以及 capability/FMA 合同测试六类簇

## 2026-05-16 DispatchApi WideFma WideSelect And BackendCapability Empty Finally Cleanup

- `dispatchapi.testcase` 的 `10946..11435` 说明，空 outer `finally` 与死 `LOldVectorAsm` 还继续分布在更混合的测试形态里：既有带 source-shape 审计内层释放的 `AVX2` wide-FMA / wide-select，也有 `X86MaskedFmaContract`、`RISCVVMaskedOpsContract`、`AVX512` capability 合同测试。
- 这次确认可安全清理的 8 条方法是：
  - `Test_AVX2_WideFma_ExactInputs_FollowsHalfComposition`
  - `Test_AVX2_WideSelect_Parity_WithScalar_When_VectorAsmEnabled`
  - `TTestCase_X86MaskedFmaContract.Test_AVX2_FmaSlots_StayScalar_When_HardwareFmaUnavailable`
  - `TTestCase_RISCVVMaskedOpsContract.Test_RISCVV_BackendCapabilities_Expose_MaskedOps_When_MaskSlots_AreNative`
  - `TTestCase_RISCVVMaskedOpsContract.Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_RISCVVMaskedOps_When_MaskSlots_AreNative`
  - `Test_AVX512_BackendCapabilities_Expose_FMA_When_WideFmaSlots_AreNative`
  - `Test_AVX512_BackendCapabilities_Expose_Shuffle_When_WideSelectSlots_AreNative`
  - `Test_AVX512_BackendCapabilities_Clear_VectorAsmGatedBits_When_VectorAsmDisabled`
- 它们的共同边界比前几批更清楚了：
  - `AVX2` wide/source-shape 测试虽然有 `TStringList` 资源释放，但真实释放只由内层 `LSourceLines.Free` 承担，外层 `finally` 仍是纯空壳
  - 其余合同测试只做 `SetVectorAsmEnabled(True/False)`、读取 backend/public-ABI 信息、再做 capability 或 slot parity 断言
  - 所有目标方法中的 `LOldVectorAsm := IsVectorAsmEnabled` 都只是机械捕获，没有 restore、没有断言、也没有后续读取
- 这进一步强化当前准则：
  - “测试里有内层真实 `finally`” 不等于 “外层 `finally` 也有价值”；必须按层判断职责，保留真实释放，剥离空 outer 壳
  - `dispatchapi` 当前的高确定性冗余已扩展到 source-shape + runtime parity 混合测试、hardware-unavailable 合同、RISCVV public-ABI mask 合同，以及 AVX512 capability rebuild 合同

## 2026-05-16 DispatchApi Neon Riscvv And AVX2 Shuffle Capability Empty Finally Cleanup

- `dispatchapi.testcase` 的 `11485..11825` 说明，空 outer `finally` 与死 `LOldVectorAsm` 还继续分布在 `NEON` capability rebuild、`RISCVV` capability expose/rebuild，以及 `AVX2` shuffle capability/public-ABI 合同测试里。
- 这次确认可安全清理的 9 条方法是：
  - `Test_NEON_BackendCapabilities_Clear_VectorAsmGatedBits_When_VectorAsmDisabled`
  - `Test_RISCVV_BackendCapabilities_Expose_IntegerOps_When_IntegerSlots_AreNative`
  - `Test_RISCVV_BackendCapabilities_Expose_FMA_When_FmaSlots_AreNonScalar`
  - `Test_RISCVV_BackendCapabilities_Expose_Shuffle_When_RepresentativeSlots_AreNonScalar`
  - `Test_RISCVV_BackendCapabilities_Clear_VectorAsmGatedBits_When_VectorAsmDisabled`
  - `Test_AVX2_BackendCapabilities_Expose_Shuffle_When_NativeShuffleSlotsUsable`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2Shuffle_When_NativeShuffleSlotsUsable`
  - `Test_AVX2_BackendCapabilities_Clear_Shuffle_When_VectorAsmDisabled`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_AVX2VectorAsmGatedBits_When_VectorAsmDisabled`
- 它们的共同边界和前几批一致：
  - 运行期部分只做 `SetVectorAsmEnabled(True/False)`、读取 backend table / public ABI pod info、再做 capability 或 slot fallback 合同断言
  - outer `finally` 本身完全为空
  - `LOldVectorAsm := IsVectorAsmEnabled` 只是机械捕获，没有 restore、没有断言、也没有后续读取
- 这继续强化当前准则：
  - 即使测试主题从 wide/source-shape 混合流切回 capability expose/clear 与 public-ABI capability bits，只要 outer `finally` 不承担真实恢复职责，就仍然可以按同一 fail-close 规则剥掉机械空壳
  - `dispatchapi` 当前的高确定性冗余已继续扩展到 `NEON` vector-asm-gated capability rebuild、`RISCVV` capability surface，以及 `AVX2` shuffle/public-ABI 合同簇

## 2026-05-16 DispatchApi X86 Override Reuse And Semantic Parity Empty Finally Cleanup

- `dispatchapi.testcase` 的 `11960..12580` 说明，空 outer `finally` 与死 `LOldVectorAsm` 还继续分布在 `SSSE3/SSE41/SSE42` cloned-slot/source-shape 审计，以及 `SSE3/SSSE3/SSE41/SSE42` runtime semantic parity 测试里。
- 这次确认可安全清理的 7 条方法是：
  - `Test_SSSE3_RepresentativeOverrides_Reuse_SSE3_CoreSlots`
  - `Test_SSE41_RepresentativeOverrides_Reuse_SSSE3_CoreSlots`
  - `Test_SSE42_RepresentativeOverride_Reuse_SSE41_CoreSlots`
  - `Test_SSE3_RepresentativeSemanticParity_WithScalar_IfDispatchable`
  - `Test_SSSE3_RepresentativeSemanticParity_WithScalar_IfDispatchable`
  - `Test_SSE41_RepresentativeSemanticParity_WithScalar_IfDispatchable`
  - `Test_SSE42_RepresentativeSemanticParity_WithScalar_IfDispatchable`
- 它们的共同边界比前几批又进一步清晰：
  - override/source-shape 审计虽然有 `TStringList` 资源释放，但真实释放只由内层 `LSourceLines.Free` 承担，外层 `finally` 仍是纯空壳
  - runtime semantic parity 测试只做 `SetVectorAsmEnabled(True)`、读取 backend、尝试 `TrySetActiveBackend(...)`、再做 parity 断言
  - 所有目标方法中的 `LOldVectorAsm := IsVectorAsmEnabled` 都只是机械捕获，没有 restore、没有断言、也没有后续读取
- 这进一步强化当前准则：
  - 当测试主题切到 x86 clone-reuse/source-shape 或 dispatchable semantic parity，只要 outer `finally` 不承担真实恢复职责，仍然可以按同一 fail-close 规则剥掉机械空壳
  - `dispatchapi` 当前的高确定性冗余已继续扩展到 x86 family override-reuse 与 runtime semantic parity 合同簇

## 2026-05-16 DispatchApi AVX512 PassThrough And X86 Shuffle Capability Empty Finally Cleanup

- `dispatchapi.testcase` 的 `12548..12692` 说明，空 outer `finally` 与死 `LOldVectorAsm` 还继续分布在 `AVX512` pass-through facade/source-shape 审计，以及 x86 shuffle capability rebuild 合同测试里。
- 这次确认可安全清理的 2 条方法是：
  - `Test_AVX512_PassThroughFacadeSlots_Reuse_AVX2_When_Wrappers_Are_Just_Forwarders`
  - `Test_X86_BackendCapabilities_Clear_Shuffle_When_VectorAsmDisabled`
- 它们的共同边界和前几批保持一致：
  - `AVX512` pass-through 测试虽然有 `TStringList` 资源释放，但真实释放只由内层 `LSourceLines.Free` 承担，外层 `finally` 仍是纯空壳
  - x86 shuffle capability rebuild 测试只做 `SetVectorAsmEnabled(True/False)`、读取 backend table、再做 scalar fallback / capability clear 合同断言
  - 两个目标方法里的 `LOldVectorAsm := IsVectorAsmEnabled` 都只是机械捕获，没有 restore、没有断言、也没有后续读取
- 这继续强化当前准则：
  - 即使测试主题切到 pass-through wrapper/source-shape 与 grouped x86 capability rebuild，只要 outer `finally` 不承担真实恢复职责，就仍然可以按同一 fail-close 规则剥掉机械空壳
  - `dispatchapi` 当前的高确定性冗余已继续扩展到 AVX512 facade/source-shape 与 x86 grouped capability clear 合同簇

## 2026-05-16 DispatchApi NonX86 Wide Slot Contract Empty Finally Cleanup

- `dispatchapi.testcase` 的 `12945..13340` 说明，空 outer `finally` 与死 `LOldVectorAsm` 还继续分布在 `non-x86 wide slot` 合同测试里。
- 这次确认可安全清理的 2 条方法是：
  - `Test_NonX86_NativeWideFloorCeil_Slots_NotScalar_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeWideFloorCeilSlots_NotScalar_IfAvailable`
- 它们的共同边界和前几批保持一致：
  - 运行期部分只做 `SetVectorAsmEnabled(True)`、筛选 `NEON/RISCVV` backend、再做 wide slot native/scalar-reuse 合同断言
  - outer `finally` 本身完全为空
  - `LOldVectorAsm := IsVectorAsmEnabled` 只是机械捕获，没有 restore、没有断言、也没有后续读取
- 这继续强化当前准则：
  - 即使测试主题切到 non-x86 backend 可达性筛选和 wide slot 合同，只要 outer `finally` 不承担真实恢复职责，就仍然可以按同一 fail-close 规则剥掉机械空壳
  - `dispatchapi` 当前的高确定性冗余已继续扩展到 non-x86 wide slot 合同簇

## 2026-05-16 NonX86 Runtime Parity Empty Finally Cleanup

- `dispatchapi.testcase` / `TTestCase_NonX86BackendParity` 的 `13343..14054` 说明，空 outer `finally` 与死 `LOldVectorAsm` 还继续分布在 non-x86 runtime parity 合同测试里。
- 这次确认可安全清理的 3 条方法是：
  - `TTestCase_NonX86BackendParity.Test_NativeNarrowFloatCoreParity_WithVectorAsm_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeNarrowHelperSurfaceParity_WithVectorAsm_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeWideLoadAndZeroParity_WithVectorAsm_IfAvailable`
- 它们的共同边界和前几批保持一致：
  - 运行期部分只做 `SetVectorAsmEnabled(True)`、筛选 `NEON/RISCVV` backend、可能 `TrySetActiveBackend(...)`、再做 dispatch-table 与 facade parity 断言
  - outer `finally` 本身完全为空
  - `LOldVectorAsm := IsVectorAsmEnabled` 只是机械捕获，没有 restore、没有断言、也没有后续读取
- 这继续强化当前准则：
  - 即使测试主题切到 non-x86 runtime parity 和 facade parity，只要 outer `finally` 不承担真实恢复职责，就仍然可以按同一 fail-close 规则剥掉机械空壳
  - `FreeAligned(...)` 这类真实清理仍然必须保留，因此相邻 `memory edge` 测试不在本批范围内

## 2026-05-16 NonX86 Wide Splat Dot Reduce Normalize Empty Finally Cleanup

- `dispatchapi.testcase` / `TTestCase_NonX86BackendParity` 的 `14232..14865` 说明，空 outer `finally` 与死 `LOldVectorAsm` 还继续分布在更后段的 non-x86 wide/runtime parity 合同测试里。
- 这次确认可安全清理的 4 条方法是：
  - `TTestCase_NonX86BackendParity.Test_NativeWideSplatParity_WithVectorAsm_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeF64DotParity_WithVectorAsm_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeF64ReduceAddSeedParity_WithVectorAsm_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeNormalizeEdgeParity_WithVectorAsm_IfAvailable`
- 它们的共同边界和前几批保持一致：
  - 运行期部分只做 `SetVectorAsmEnabled(True)`、筛选 `NEON/RISCVV` backend、可能 `TrySetActiveBackend(...)`、再做 dispatch-table 与 facade parity 或 slot 合同断言
  - outer `finally` 本身完全为空
  - `LOldVectorAsm := IsVectorAsmEnabled` 只是机械捕获，没有 restore、没有断言、也没有后续读取
- 这次也额外确认了两类必须跳过的相邻测试：
  - `Test_NativeVectorMathParity_WithVectorAsm_IfAvailable` 的 `finally` 非空，当前准则下不机械删除
  - `Test_NativeWideIntegerMemoryEdgeParity_WithVectorAsm_IfAvailable` 带 `FreeAligned(...)` 真实清理，必须保留
- 这继续强化当前准则：
  - 即使测试主题切到 non-x86 wide splat、F64 dot、seeded reduce 与 normalize edge parity，只要 outer `finally` 不承担真实恢复职责，就仍然可以按同一 fail-close 规则剥掉机械空壳
  - 相邻的非空 `finally` 与资源释放路径依然要按“真实职责优先”保留，不能为了统一样式机械收平

## 2026-05-16 NonX86 Helper And Core Parity Empty Finally Cleanup

- `dispatchapi.testcase` / `TTestCase_NonX86BackendParity` 的 `14847..16921` 说明，空 outer `finally` 与死 `LOldVectorAsm` 还继续成片分布在后段的 helper/core parity 测试里。
- 这次确认可安全清理的 12 条方法是：
  - `TTestCase_NonX86BackendParity.Test_NativeWideInsertHelperParity_WithVectorAsm_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeWideIntegerExtractEdgeParity_WithVectorAsm_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeNarrowFloatHelperParity_WithVectorAsm_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeNarrowIntegerCoreParity_WithVectorAsm_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NativeNarrowIntegerHelperParity_WithVectorAsm_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_MinimalDispatchParity_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_ExtendedFloatParity_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_NarrowAndNotParity_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_DotParity_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_I16x32_CoreParity_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_I8x64_CoreParity_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_U32x16_U64x8_CoreParity_IfAvailable`
- 它们的共同边界比前几批更清楚：
  - 前 5 条测试都带 `LOldVectorAsm := IsVectorAsmEnabled`，但后续完全不读取，同时 outer `finally` 为空
  - 后 7 条虽然没有 `LOldVectorAsm`，但 outer `try/finally` 同样只包裹 backend 循环，`finally` 体完全为空
  - 这 12 条都只做 backend 注册/激活筛选、dispatch-table/facade parity、slot presence、lane/mask/shift 合同断言，不承担任何 restore、hook cleanup 或资源释放职责
- 这次也额外确认了新的停点：
  - 当前批次明确停在 `Test_WideInteger_FuzzSeed_Parity_IfAvailable` 之前，不把 `16923+` 的 fuzz/mask 长段和后续更重的 wide integer parity 混进同一批
- 这继续强化当前准则：
  - 即使测试主题切到 non-x86 narrow/wide helper、core arithmetic、mask parity 或 minimal dispatch，只要 outer `finally` 不承担真实恢复职责，就仍然可以按同一 fail-close 规则剥掉机械空壳
  - 当连续区段只剩同构空壳时，可以适度扩大同批处理范围提升效率，但仍要用明确停点避免重新扩散 scope

## 2026-05-16 NonX86 Mask And Shift Empty Finally Cleanup

- `dispatchapi.testcase` / `TTestCase_NonX86BackendParity` 的 `17092..19067` 说明，空 outer `finally` 仍继续分布在更后段的 compare/mask/shift/minmax parity 测试里。
- 这次确认可安全清理的 4 条方法是：
  - `TTestCase_NonX86BackendParity.Test_WideCompareMaskParity_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_I32x4_BitwiseShiftParity_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_WideSignedBitwiseShiftParity_IfAvailable`
  - `TTestCase_NonX86BackendParity.Test_WideIntegerArithmeticMinMaxParity_IfAvailable`
- 它们的共同边界和当前准则完全一致：
  - 运行期部分只做 backend 注册/激活筛选、compare mask/helper parity、exact shift probe、bitwise/arithmetic/minmax parity 和 facade/helper 合同断言
  - outer `finally` 本身完全为空，不承担任何 restore、hook cleanup 或资源释放
- 这次也额外确认了一个必须继续跳过的相邻测试：
  - `Test_WideInteger_FuzzSeed_Parity_IfAvailable` 的 `finally` 会恢复 `RandSeed`，这是明确的真实状态清理，不能机械删除
- 实施时又暴露出两个结构性事实，后续继续扫尾时必须记住：
  - `WideInteger_FuzzSeed` 不是“只保留 finally 就行”，它要求成对保留 outer `try/finally`；去掉 `try` 会直接把 `finally` 变成孤立语法错误
  - `WideCompareMaskParity` 在当前工作树里仍残留一个空 outer `try`，不能只看方法尾部；继续推进时要同时搜方法体里的 `try/finally` 关键字，避免留下半截结构
- 这继续强化当前准则：
  - 即使测试主题切到更长的 compare-mask、bitwise-shift 和 wide integer arithmetic/minmax parity，只要 outer `finally` 不承担真实恢复职责，就仍然可以按同一 fail-close 规则剥掉机械空壳
  - 任何显式状态回滚（这里是 `RandSeed`）都必须继续视为真实职责，而不是“样板代码”

## 2026-05-16 Completion Audit Reset Findings

- 本轮 completion audit 复核后，`dispatchapi.testcase` 继续机械扫空壳 `finally` 的收益已经很低：
  - `17092..19067` 是这条线最后一批高确定性命中
  - `WideInteger_FuzzSeed` 的真实 `RandSeed` restore 已明确保留
  - 同文件后续已没有值得继续靠这条线机械推进的新残点
- 当前真实绿态已经足够说明 SIMD 主实现和非 x86 checker 基本稳定：
  - `git diff --check`
  - Release `TTestCase_DispatchAPI`
  - `check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `check_nonx86_key_slot_audit.py`
  - `check_nonx86_helper_semantics.py`
  - `check_nonx86_wiring_sync.py`
  - Release `check`
- 这轮 closeout 继续验证后，Linux 侧的真实剩余点已经被补平：
  - `qemu-cpuinfo-nonx86-evidence` 首次失败并不是 SIMD 代码或脚本语义问题，而是 Docker socket 权限不足
  - 提权后同一动作在 `linux/arm/v7`、`linux/arm64`、`linux/riscv64` 全平台 PASS
  - 再按 `freeze-status` 官方 next-action 重跑 canonical `gate` 后，`linux_gate_required_steps_mainline` 与 `linux_qemu_cpuinfo_nonx86_evidence` 都已转绿
- 最新 `freeze-status` 已把问题压缩成纯 Windows evidence closeout：
  - `ready=False`
  - `mainline-ready=False`
  - `cross-ready=False`
  - `cross_gate_required_steps` 现在只剩 `evidence-verify=FAIL`
  - 红点全部收敛到旧 `windows_b07_gate.log` / `windows_b07_closeout_summary.md` 的 freshness、source-newer-than-evidence 与 verify
- `win-evidence-preflight` 当前返回 `STATUS=PASS CODE=OK EXIT=0`，说明当前并不是 workflow 入口、账单预检或最近失败 run 在阻塞。
- 当前 GH Windows evidence 的真实挡板已经进一步缩小为本地 hygiene：
  - `win-evidence-via-gh SIMD-20260516-152` 被脚本主动拒绝
  - 原因是 `Refuse dispatch: local worktree has uncommitted changes.`
  - 也就是说，下一步不该再盲修 SIMD，而是先把这轮 scratch 更新和 `__pycache__` 生成物清干净、提交，然后重试 GH dispatch
- 本轮把 hygiene 挡板清掉以后，Windows closeout 的最终根因也已经拿到真实远端证据：
  - 清理工作树、提交 `731cc0d7`、推送 `origin/main` 之后，`win-evidence-via-gh SIMD-20260516-152` 已成功 dispatch
  - GitHub Actions run id 为 `25967172435`
  - 该 run 在 `Prepare Windows SIMD Source` 阶段即失败，Windows 收集 job 未真正启动
  - 失败注解为：`The job was not started because recent account payments have failed or your spending limit needs to be increased`
- 这说明当前 freeze-status 的唯一剩余红态已经被定性为外部平台 blocker：
  - 不是本地 worktree hygiene
  - 不是 SIMD gate / qemu / runner parity
  - 不是 `win-evidence-preflight` 自身逻辑
  - 而是 GitHub Actions billing/runner 配额问题

## 2026-05-17 Closeout Doc Truth-Sync Findings

- 在继续加强 SIMD 审查时，active closeout 文档里出现了一个真实误导点：
  - `docs/fafafa.core.simd.closeout.md` / `docs/fafafa.core.simd.checklist.md` 仍把 `qemu-nonx86-evidence` 和 `qemu-cpuinfo-nonx86-evidence` 混写成同一类 “Linux QEMU 已完成”
  - 但脚本真实行为已经分成双轨：
    - `closeout-host-local` / `gate-strict` 的 host-local strict closeout 主要消费 `qemu-nonx86-evidence`
    - canonical `gate` / `freeze-status` / `win-closeout-finalize` 另外要求 `qemu-cpuinfo-nonx86-evidence`
- 这不是纯文案风格问题，而是会直接误导后续实施顺序：
  - 只看到 `closeout-host-local` 绿，不能推出 `freeze-status` 会绿
  - 只刷新 runtime parity summary，也不能代替 CPUInfo cross evidence 写回 canonical `gate_summary.md`
- 当前最值得修的不是再碰 SIMD 生产实现，而是把 active 真相源同步到最新 stop-point：
  - Linux 侧 `qemu-cpuinfo-nonx86-evidence` 已在 `2026-05-16 20:43:40` 随 canonical gate 刷成 PASS
  - `freeze-status` 当前唯一剩余 cross red item 是旧 Windows evidence 的 `evidence-verify=FAIL`
  - Windows GH run `25967172435` 的真实失败原因是 billing / spending limit，而不是 workflow 入口、repo hygiene 或 SIMD 代码回归
- 因此本轮文档修正的真实价值是：
  - 把 host-local implementation closeout 和 release freeze closeout 的证据语义重新拉开
  - 把最新 Windows external blocker 固定成可复述的 run id / failure mode
  - 防止后续会话再次因为旧文档而回到“为什么 Linux 都绿了 freeze-status 还红”的重复排障

## 2026-05-17 SSE2 Transitional Non-x86 Runtime Drift

- `src/fafafa.core.simd.intrinsics.sse2.pas` 在 `CPUX86/CPUX86_64` 下会走 `fafafa.core.simd.intrinsics.sse2.x86.inc`，而现有 `experimental` 测试也只在 `x86_64` 下对这条路径施加语义约束。
- 同一个单元的 non-x86 分支仍保留大量 `Result := a` / `Result := 0` / `Result := simd_add_*` 这类 placeholder body；一旦有人在 non-x86 上打开 `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS`，这些假语义会静默运行。
- 这不属于“允许的实验口径”：
  - disposition / migration map 都把 `intrinsics.sse2` 定义成 x86 迁移中的 transitional wrapper，而不是 non-x86 experimental runtime surface；
  - 当前也没有任何 non-x86 runtime parity / suite / smoke 证明这些 placeholder body 可以被当成 contract。
- 因而更正确的收口不是去补全这批 non-x86 placeholder，而是显式 fail-close：
  - compile 可以继续留给结构检查或未来 bring-up；
  - runtime 必须在 initialization 阶段直接拒绝 non-x86 experimental 执行，避免“可编译”被误读成“有语义”。

## 2026-05-17 AVX Hold-Lane Truth Drift

- `src/fafafa.core.simd.intrinsics.avx.pas` 的文件头仍写着 “It remains available as an internal bridge for AVX2-focused tests”，但全仓对 `fafafa.core.simd.intrinsics.avx` 的命中只剩：
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh` 的 `check_avx_backend_smoke`
  - 若干 checker / docs / status 脚本
  - 没有任何实际源码 consumer 或 AVX2 测试桥接依赖。
- 这说明当前更真实的定位是 hold family 的 isolated opt-in leaf，而不是“仍在被 AVX2-focused tests 消费的内部桥”。
- 同时它和刚处理过的 `intrinsics.sse2` 有同类风险：
  - `AVX` 是 x86 ISA；
  - 但当前 non-x86 若打开 `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS`，仍可静默执行 placeholder / Pascal 近似实现；
  - 仓库没有任何 non-x86 runtime 证据把这条路径定义成有效 contract。
- 因而这条线的正确修复仍然不是补 placeholder，而是：
  - 把源文件头从“AVX2-focused bridge”收正为“no current in-repo consumer beyond isolated smoke / opt-in bring-up”
  - 在 initialization 阶段对 non-x86 experimental runtime fail-close
  - 同步 `docs/SIMD_INTRINSICS_DISPOSITION.md` 与 `docs/plans/2026-05-09-simd-family-matrix.md`，避免 docs 继续把 `AVX` 说成只有 isolation lane 或隐含 bridge 角色

## 2026-05-17 X86 Experimental Lane Missing Fail-Close Batch

- 在 `SSE2/AVX` 收口之后继续复核发现，同类问题并不是孤点：
  - `src/fafafa.core.simd.intrinsics.sse3.pas`
  - `src/fafafa.core.simd.intrinsics.sse41.pas`
  - `src/fafafa.core.simd.intrinsics.sse42.pas`
  - `src/fafafa.core.simd.intrinsics.avx512.pas`
  - `src/fafafa.core.simd.intrinsics.fma3.pas`
  这 5 个 x86-only experimental 单元当前都只有 `EnsureExperimentalIntrinsicsEnabled`，没有 non-x86 runtime fail-close。
- 现有验证 lane 也都支持这一判断：
  - `SSE3` 有 `check_sse3_backend_smoke`
  - `AVX-512` 有 `check_avx512_backend_smoke`
  - `FMA3` 有 `check_fma3_backend_smoke`
  - `SSE4.1/4.2` 当前走 representative parity + isolation lane
  - 没有任何 non-x86 runtime parity/evidence 把这些 raw leaf 定义成非 x86 可执行 contract。
- 因而这批的正确修复仍然不是给 non-x86 补伪语义，而是把边界说死：
  - non-x86 只允许保留 compile scaffolding
  - runtime 必须 fail-close
  - `check_intrinsics_experimental_status.py` 也要把这条规则升成静态护栏，防止以后回退成“有 experimental guard 但没有 target guard”

## 2026-05-17 AES SHA Hold-Lane Truth Drift

- `docs/plans/2026-05-09-simd-family-matrix.md` 目前把 `AES/SHA` 的 verification lane 写成了 `experimental-intrinsics isolation only`。
- 但仓库里的真实实验测试更宽：
  - `TTestCase_SimdIntrinsicsExperimental.Test_Default_AES_SHA_Rejects`
  - `TTestCase_SimdIntrinsicsExperimental.Test_Experimental_AES_SHA_PlaceholderSemantics`
  这两条都在 `tests/fafafa.core.simd.intrinsics.experimental/fafafa.core.simd.intrinsics.experimental.testcase.pas` 里，前者锁默认拒绝，后者锁 opt-in placeholder semantics。
- 这说明 `AES/SHA` 和刚收口的 `SSE3/SSE4.1/SSE4.2/AVX-512/FMA3` 不是同一类 experimental lane：
  - 后者是真正的 x86-only runtime lane，non-x86 应 fail-close；
  - `AES/SHA` 当前则保留了一条跨平台 experimental placeholder-semantics lane。
- 因而更正确的文档口径应该是：
  - `AES/SHA` 继续 hold / experimental isolated
  - 当前实验验证 lane 包含 `experimental-intrinsics` isolation + default-reject + placeholder semantics tests
  - 但这仍然不是 stable adapter / stable leaf contract，更不能据此 reopen

## 2026-05-17 SVE SVE2 LASX Missing Runtime Qualification

- `src/fafafa.core.simd.intrinsics.sve.pas`、`src/fafafa.core.simd.intrinsics.sve2.pas`、`src/fafafa.core.simd.intrinsics.lasx.pas` 当前都只有 generic `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS` guard，没有 target-specific runtime fail-close。
- 这意味着在非目标主机上，只要打开 experimental define，这几个 hold leaf 也会像“可用 experimental 语义”一样静默装载：
  - `SVE/SVE2` 在 `x86_64` 等非 `AArch64` 主机上如此；
  - `LASX` 在非 `LoongArch64` 主机上如此；
  - `SVE/SVE2` 甚至在 `AArch64` 下原先也不要求 `cpuinfo` 真的报告 `SVE`。
- 这和前面已经收紧的 `AVX/SSE2/SSE3/SSE4.1/SSE4.2/AVX-512/FMA3` 边界不一致：
  - 那批 x86-only hold / experimental lane 已明确把 non-qualified host 收成 runtime fail-close；
  - `SVE/SVE2/LASX` 当时还留着“只要开宏就可装载”的漏口。
- 现有仓库证据也支持把它们收紧，而不是补伪语义：
  - current active docs 把它们定义成 hold family / `experimental isolated`
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh` 之前没有任何 dedicated smoke 覆盖这条边界
  - `cpuinfo` 已经能给出 `ARM.HasSVE`，足以先把 `SVE/SVE2` 的 base qualification 收紧
  - `LASX` 还没有独立 `cpuinfo` feature bit，因此当前最安全的收口是：先对非 `LoongArch64` 主机 fail-close，并在 docs 里诚实记录 feature-level gap

## 2026-05-17 LASX Cpuinfo Feature-Level Qualification Feasibility

- `LASX` 和 `SVE2` 不同，之前真正缺的是一条最小 LoongArch `cpuinfo` 骨架，而不是再补一个现成 feature bit。
- 这条缺口仍然可以控制在小面：
  - `settings.inc` 只新增 `SIMD_LOONGARCH_AVAILABLE`
  - `cpuinfo.base/pas/lazy/diagnostic` 只新增 `caLoongArch`、`TLoongArchFeatures` 和 `HasLASX`
  - 新的 `cpuinfo.loongarch` 只做 `LASX` feature detection 与 vendor/model best-effort
  - 不新增 stable backend、不改 dispatch priority、不改 adapter qualification contract
- Linux 头文件已有直接证据：`HWCAP_LOONGARCH_LASX (1 << 5)`，因此最小实现可以优先基于 `auxv`，再用 `/proc/cpuinfo` token 作为补充证据。
- 这条补完后，`intrinsics.lasx` 的真实 contract 会变成：
  - experimental define 仍然必需
  - 非 `LoongArch64` 主机 runtime fail-close
  - `LoongArch64` 但 `cpuinfo` 未报告 `LASX` 也 runtime fail-close
  - 这仍然不是 stable `LASX` adapter/leaf promote

## 2026-05-17 NEON RVV Qualification Leaf Missing Runtime Qualification

- `src/fafafa.core.simd.intrinsics.neon.pas` 和 `src/fafafa.core.simd.intrinsics.rvv.pas` 也存在同类缺口：
  - 当前都只有 generic experimental guard；
  - 在非 ARM / 非 RISC-V 主机上，只要打开 `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS`，unit initialization 就会静默通过；
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh` 之前对这条边界没有 dedicated smoke。
- 这条问题和 `NEON/RISCVV` 的 adapter qualification lane 需要明确分开：
  - `simd.neon` / `simd.riscvv` 的 qualification / opt-in / evidence 路线继续由 `family matrix` 现有 lane 决定；
  - 这轮收的只是 `intrinsics.neon` / `intrinsics.rvv` experimental leaf 本身，不再允许 any-host opt-in runtime。
- 仓库现成能力位也足以支持这次收口，而不必扩架构模型：
  - `fafafa.core.simd.cpuinfo.HasNEON`
  - `fafafa.core.simd.cpuinfo.HasRISCVV`
- 因而这批最正确的修法不是再给 cross-host placeholder 找语义，而是：
  - runtime 只允许 `cpuinfo` 已确认对应 ISA 的目标主机放行；
  - checker 和 experimental smoke 同步 fail-close；
  - 文档明确写清：这是 qualification-family leaf runtime 收紧，不是 stable adapter promote

## 2026-05-17 SVE2 Base-SVE Approximation Gap

- `intrinsics.sve2` 在上一批里虽然已经从 any-host opt-in 收紧成了 `AArch64` + `HasSVE` 才放行，但这仍然只是 base-`SVE` 近似资格，不是 `SVE2` 精确资格。
- 这条 residual 现在有直接证据可修：
  - 仓库 `cpuinfo.arm` 还没有 `HasSVE2`
  - 但本机 Linux 头文件里存在 `HWCAP2_SVE2`
  - `ParseARMFeaturesFromCpuInfo` 也已经有 token 通道，补 `sve2` 分支即可
- 因而这批的正确修法不是继续在文档里承认“近似”，而是：
  - 给 `TARMFeatures` 和 façade helper 补 `HasSVE2`
  - 把 `intrinsics.sve2` 的 runtime guard 切到 `HasSVE2`
  - 同步 checker / smoke / docs
- 一个需要诚实记账的验证细节是：
  - `intrinsics.sve2` 依赖 `intrinsics.sve`
  - 在完全非 `AArch64` 主机上导入 `sve2` 时，unit initialization 可能先被 `intrinsics.sve` 的 fail-close 拦下
  - 这不影响 “non-qualified host 必须 reject” 的目标，但意味着 `SVE2` reject smoke 在这类主机上要允许匹配上游 `SVE` token

## 2026-05-17 Experimental X86 Header Truth Drift And Python Cache Noise

- 当前 `sse3/sse41/sse42/avx512/fma3` 这 5 个 x86 experimental intrinsics 单元，在实现层都已经有两层真实护栏：
  - `EnsureExperimentalIntrinsicsEnabled`
  - `EnsureExperimental*TargetSupported` 的 non-x86 runtime fail-close
- 但它们的 interface/file-header 区域仍主要在讲 ISA 特性与“兼容性”，没有像 `intrinsics.avx` 那样显式写出当前 experimental/placeholder/runtime-fail-close 口径。
- 这会制造一类低级 truth drift：
  - disposition/docs/checker 都已经把这些单元定义成 `experimental isolated`
  - 源码头读起来却像“稳定叶子能力介绍”
  - 后续审查时容易再次浪费时间去确认“这些是不是已经准备 promote 了”
- 因而这里最合适的修法不是继续补测试，也不是重开 family promote 讨论，而是把源码头直接收正到当前 contract：
  - experimental x86 intrinsics lane
  - not a default stable raw leaf
  - non-x86 branch is compile scaffolding and intentionally fail-close at runtime
- 另一个直接的仓库卫生问题是：`.gitignore` 还没忽略 `__pycache__/`。
  - 当前仅跑 Python checker 就已在 `tests/fafafa.core.simd/__pycache__/` 留下未跟踪目录
  - 这类噪音会持续污染 `git status`，降低下一批“小闭环”判断效率
  - 该问题与本轮 SIMD review 工具链直接相关，值得顺手一次收掉

## 2026-05-17 SIMD Generated Artifact Hygiene Gap

- `tests/fafafa.core.simd/` 当前还有一类比 `__pycache__` 更重的 hygiene 问题：真实生成产物已经被跟踪进 Git。
- 已确认的 4 个 tracked artifacts：
  - `tests/fafafa.core.simd/simd_test`
  - `tests/fafafa.core.simd/qemu_fafafa.core.simd.test_20260220-232704_195.core`
  - `tests/fafafa.core.simd/bin2-smoke/link60.res`
  - `tests/fafafa.core.simd/bin2-smoke/ppas.sh`
- 文件级证据直接表明它们都不是源码资产：
  - `simd_test` 是 `ELF 64-bit LSB executable, x86-64`
  - `qemu_...core` 是 `ELF 64-bit LSB core file, ARM aarch64`
  - `ppas.sh` / `link60.res` 是 `rvv_opcode_smoke` 交叉编译生成的 shell/linker 产物
- git 历史也说明这是误带入，而不是刻意 fixture：
  - `simd_test` 在 `5d2c8751 simd-only: update SIMD implementations` 被加入
  - 其余 3 个产物在 `0c42875e Merge preserved unrelated workspace changes` 被加入
- `tests/fafafa.core.simd/.gitignore` 之前只忽略了 `/bin2/`、`/lib2/`、`/logs/`，没有覆盖：
  - `/bin2-smoke/`
  - `/simd_test`
  - `/*.core`
- 因而这不是“当前工作树脏了”的问题，而是“仓库历史已经收进了明显的生成垃圾”，值得优先清掉。

## 2026-05-17 Register Truthfulness Default-Gate Gap

- 当前 `tests/fafafa.core.simd/BuildOrTest.sh check` 和 `buildOrTest.bat check` 还有一个真实 coverage gap：
  - `register truthfulness` 明明是纯 Python 静态审查
  - 但 runner 仍把它绑在 `SIMD_ENABLE_NEON_BACKEND=1` / `SIMD_ENABLE_RISCVV_BACKEND=1` 这类 opt-in 编译开关上
- 这条约束现在已经与 checker 真相脱节：
  - 直接运行
    - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
    - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
    都能在当前源码上稳定通过
  - 说明它不需要把 `NEON/RISCVV` backend 编进测试二进制，也不依赖运行期 opt-in host
- 因而现状的真正问题不是“这个检查太重”，而是“默认主门禁无声少守了一层”：
  - `helper-semantics`、`key-slot-audit`、`riscvv-abi-shape` 已经在默认 `check` 里
  - `register truthfulness` 却还停在 opt-in 条件下才运行
  - 导致最核心的 non-x86 register ownership truth 仍可能在日常 `check` 里被跳过
- 这批最正确的修法不是再补新的 checker，而是把 runner 自己收正：
  - shell `run_register_truthfulness_check()` 默认同时跑 `neon` + `riscvv`
  - batch `:register_truthfulness_check` 同步改成默认同时跑两边
  - `gate` 不再把这一步当成“只有开了 opt-in backend 才启用”的可选步骤
- 这样改的性质是“覆盖面提升”，不是“验证成本爆炸”：
  - 它不引入新的编译
  - 只把已存在、已成熟、已 cheap 的 Python truth checker 抬进默认门禁

## 2026-05-17 Metadata Query Scope Guard Gap

- 在 `register-truthfulness` 收口之后，当前 `simd` 默认门禁里还剩一个更细的护栏空洞：
  - `dispatch-read-scope` 已经在守 `GetDispatchTable`
  - 但 `GetBackendInfo` / `TryGetRegisteredBackendDispatchTable` / `GetBackendNameTextPtr` / `GetBackendDescriptionTextPtr` 这些 metadata-query helpers 还没有对应的默认 checker
- 当前源码状态虽然还没漂：
  - production 命中只落在
    - `src/fafafa.core.simd.dispatch.pas`
    - `src/fafafa.core.simd.runtime.pas`
    - `src/fafafa.core.simd.public_abi.impl.inc`
    - `src/fafafa.core.simd.backend.adapter.pas`
  - 也就是边界事实上还在
- 但真正的问题是“边界没被固化”：
  - façade / direct / 其他 companion surface 以后如果直接回读这些 metadata helpers
  - 现在默认 `check` 不会第一时间报红
  - 这会让 `dispatch-read-scope` 之外又悄悄长出第二条 metadata truth path
- 所以这批的正确修法不是重构 runtime/public ABI 语义，而是补一条与 `dispatch-read-scope` 同级的静态护栏：
  - 新增 `check_metadata_query_scope.py`
  - 扫描 `src/fafafa.core.simd*.pas/inc`
  - 把 4 个 metadata-query helpers 的 production 允许面固定在 `dispatch/runtime/public ABI/backend adapter`
  - 并把它接进 shell/batch 的默认 `check`

## 2026-05-17 Dataplane Consumer Scope Guard Gap

- 在 `metadata-query-scope` 收口之后，默认门禁里还剩一条同层但更贴近 publication seam 的缺口：
  - `dispatch-read-scope` 已经守 `GetDispatchTable`
  - `metadata-query-scope` 已经守 metadata helper
  - 但 `GetCurrentSimdDataPlane` / `GetCurrentSimdDataPlaneDispatch` / `RebindSimdDataPlane` 这些 dataplane consumer helper 还没有独立 checker 固化其 production 边界
- 当前 production 真相仍然干净：
  - `GetCurrentSimdDataPlane`
    - `src/fafafa.core.simd.dataplane.pas`
    - `src/fafafa.core.simd.public_abi.impl.inc`
    - `src/fafafa.core.simd.pas`
  - `GetCurrentSimdDataPlaneDispatch`
    - `src/fafafa.core.simd.dataplane.pas`
    - `src/fafafa.core.simd.public_abi.impl.inc`
    - `src/fafafa.core.simd.direct.pas`
  - `RebindSimdDataPlane`
    - `src/fafafa.core.simd.dataplane.pas`
    - `src/fafafa.core.simd.direct.pas`
- 这说明问题不在“当前已经漂了”，而在“边界还没被默认门禁 fail-close 固化”：
  - façade / companion / 其他 surface 以后如果直接消费这些 helper
  - 目前默认 `check` 不会第一时间报红
  - 这会让 `dataplane` seam 之外悄悄长出第二条 publication-consumer path
- 因而这批最正确的修法不是继续改 `dataplane` 语义，而是补一条与 `dispatch-read-scope` / `metadata-query-scope` 同级的静态护栏：
  - 新增 `check_dataplane_consumer_scope.py`
  - 扫描 `src/fafafa.core.simd*.pas/inc`
  - 把 3 个 dataplane consumer helper 的 production 允许面固定在 `dataplane/direct/public ABI/facade companion`
  - 并把它接进 shell/batch 的默认 `check`

## 2026-05-17 Direct Dispatch Scope Guard Gap

- 在 `dataplane-consumer-scope` 收口之后，默认门禁里还剩一条同层 companion fast-path 缺口：
  - `dispatch-read-scope` 已经守 `GetDispatchTable`
  - `dataplane-consumer-scope` 已经守 `GetCurrentSimdDataPlane*`
  - 但 `GetDirectDispatchTable` 这条 direct companion getter 还没有独立 checker 固化其 production 边界
- 当前 production 真相已经很清楚，而且命中面比 dataplane 更窄：
  - `src/fafafa.core.simd.api.pas`
  - `src/fafafa.core.simd.arrays.pas`
  - `src/fafafa.core.simd.ops.pas`
  - `src/fafafa.core.simd.direct.pas`
- 文档真相也支持这是一个应当冻结的 companion 边界，而不是任意 public helper：
  - `docs/SIMD_LAYERING_IMPLEMENTATION.md` 明确把 `direct` 定义成 `direct dispatch companion`
  - `docs/fafafa.core.simd.maintenance.md` 明确写着它只给“仓库内热点路径、测试和 wiring”提供 direct pointer 访问
- 这说明问题不在“当前用错了”，而在“边界还没被默认门禁 fail-close 固化”：
  - 以后如果其他模块也开始直接抓 `GetDirectDispatchTable`
  - 当前默认 `check` 不会第一时间报红
  - 这会让 `direct` 从 companion fast-path 慢慢漂成新的随处可读 truth path
- 因而这批最正确的修法不是去重写 `api/arrays/ops`，而是补一条同级静态护栏：
  - 新增 `check_direct_dispatch_scope.py`
  - 扫描 `src/fafafa.core.simd*.pas/inc`
  - 把 `GetDirectDispatchTable` 的 production 允许面固定在 `api/arrays/ops/direct`
  - 并把它接进 shell/batch 的默认 `check`

## 2026-05-17 Check Default Wiring-Sync Gap

- 在 `direct-dispatch-scope` 收口之后，默认 `check` 主链里还剩一个更窄但真实的覆盖缺口：
  - `tests/fafafa.core.simd/BuildOrTest.sh check`
  - `tests/fafafa.core.simd/buildOrTest.bat check`
  - 仍把 `wiring-sync` 放在 `SIMD_CHECK_WIRING_SYNC=1` 的 opt-in 分支里
- 这和当前 `wiring-sync` 的真实成熟度已经不一致：
  - `check_nonx86_wiring_sync.py` 是纯 Python 静态对账，不依赖额外 Pascal 构建
  - 直接跑 `python3 tests/fafafa.core.simd/check_nonx86_wiring_sync.py --summary-line --strict-extra` 已稳定返回 `missing=0 extra=0 markers_missing=0`
  - 把 `SIMD_CHECK_WIRING_SYNC=1` 打开后再跑 Release `check` 也已通过，说明这条 lane 已经足够成熟，不该再默认漏掉
- 因而本批最正确的修法不是再加一个更复杂的开关，而是把语义收正成：
  - `check` 默认执行 `wiring-sync`
  - 只有显式设置 `SIMD_CHECK_WIRING_SYNC=0` 时才跳过
  - shell 与 batch runner 必须同步，不然会形成平台行为分叉
- 这也意味着前面那条“`wiring-sync` 只是现成 optional lane”的判断只适用于当时比较 `nonx86-optin-list-suites` 是否已有 skip knob 的上下文；到 2026-05-17 这一步，它已经是过时结论，不能再当作当前真相。

## 2026-05-17 Freeze Gate-Summary Fallback Gap

- 在 `check` 主链缺口继续收紧之后，closeout 侧出现了一个更偏 runner/artifact 的真实漂移：
  - `2026-05-16` 的 cross gate 确实把 `qemu-cpuinfo-nonx86-evidence` 刷成过 PASS
  - 但 `2026-05-17` 再跑 routine `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 后，`logs/gate_summary.md` 被新的 fast-gate 摘要覆盖，里面这一步回到了 `SKIP`
  - 随后 `freeze-status` 就重新把 `linux_gate_required_steps_mainline` / `cross_gate_required_steps` 打红
- 这说明当前问题不在 SIMD 语义，而在 closeout artifact 的保留与选择：
  - `evaluate_simd_freeze_status.py` 虽然已经支持从 `logs/windows-closeout/<batch>/gate_summary.md` 回退
  - 但仓库当前没有这类 batch gate summary 可用
  - `logs/rehearsal/backups/` 也只有 sample-inject 相关脚手架，没有真实 gate 覆盖前自动备份
- 因而本批最正确的修法不是把 `qemu-cpuinfo-nonx86-evidence` 强行抬进所有日常 `gate`，而是把 artifact 链路收正：
  - `reset_gate_summary` 在覆盖前自动备份旧的真实 gate summary
  - `freeze-status` 把 `logs/rehearsal/backups/gate_summary.backup.*.md` 也纳入候选
  - 这样 latest fast-gate 只要只是“缺少 closeout-only step”，`freeze-status` 就能回退到较早但仍有效的 closeout snapshot
- 这条修法的收益是：
  - 不改变日常 `gate` 的默认成本
  - 不把 closeout 口径重新绑死到“最后一次 gate 恰好是 cross gate”
  - 也不必把 docs 继续写成“canonical gate_summary.md 永远等于 Linux closeout 真相”

## 2026-05-17 Implementation Matrix Sync Guard

- `docs/fafafa.core.simd.implementation-matrix.md` 当前是 active working ledger，不是 `check_nonx86_key_slot_audit.py` 的全量 key-slot 总表。
- 首版 `check_implementation_matrix_sync.py` 之所以一上来报出 `issues=83`，根因不是文档真的漏了 83 行，而是规则面错了：
  - 它把 `collect_expected_slot_modes_from_dispatchapi()` 的全量 `NEON/RISCVV` key-slot 期望，错误地当成了“implementation matrix 必须逐行覆盖”的要求。
  - 但 active matrix 现在只刻意保留 22 条 non-x86 row，用于当前 ownership / bounded frontier 主线，而不是把所有 helper-owned / wrapper-owned / qualification row 都塞进去。
- 因而这个 checker 的正确职责应是：
  - fail-close 当前 active row 集合是否缺失或多出；
  - fail-close 这些 active rows 的 `expected contract` 是否与真相源漂移；
  - fail-close x86 bounded frontier 的 10 条 row prefix 是否缺失或重复。
- `RISCVV.ShiftLeftU32x8` / `RISCVV.ShiftRightU32x8` 是 active matrix 的两个真实例外：
  - 它们的 truth source 在 `riscvv.facade.inc` 的显式 `ScalarShift*U32x8`
  - 不属于 `key-slot-audit` 当前扫描的 dispatchapi ledger
  - 因此 `implementation-matrix-sync` 需要为这两行保留本地 manual contract，而不是硬逼 `key-slot-audit` 去吞掉它们
- 修正后，新 checker 的信号已收干净：
  - `python3 tests/fafafa.core.simd/check_implementation_matrix_sync.py --summary-line`
  - 结果：`IMPLEMENTATION_MATRIX_SYNC nonx86_slots=22 x86_rows=10 issues=0 status=ok`
- 这批的核心价值不是新增 SIMD 算法验证，而是把 active implementation matrix 真正纳入默认 `check`，避免后续 active ledger 和 key-slot / x86 frontier 真相源长期漂移。

## 2026-05-17 SIMD Tracked Res Artifact Hygiene

- `git ls-files tests/fafafa.core.simd tests/fafafa.core.simd.* | rg '\.res$'` 当前只命中 3 个路径：
  - `tests/fafafa.core.simd/fafafa.core.simd.test.res`
  - `tests/fafafa.core.simd/test_backend_ops.res`
  - `tests/fafafa.core.simd.intrinsics.mmx/fafafa.core.simd.intrinsics.mmx.test.res`
- 它们的文件级证据都指向“生成物而不是源码资源”：
  - `file ...` 三个文件都显示为 `Microsoft Visual C binary resource file`
  - 对应入口源码 `fafafa.core.simd.test.lpr`、`test_backend_ops.pas`、`fafafa.core.simd.intrinsics.mmx.test.lpr` 都没有 `{$R *.res}` / `{$R xxx.res}` 引用
  - `test_backend_ops.pas` 甚至是直接 `fpc` 构建的 standalone smoke，并不需要仓库里预置一个 `.res`
- 这意味着当前问题不是“构建会生成 `.res`”本身，而是“这些生成物仍被 Git 跟踪”：
  - 继续保留会把 Lazarus/FPC 输出伪装成源码资产
  - 后续任何 build 都可能再次让 review 偏离到无意义的资源二进制 diff
- 当前最小正确修法是：
  - 在 `tests/fafafa.core.simd/.gitignore` 增加 `/*.res`
  - 给 `tests/fafafa.core.simd.intrinsics.mmx/` 补一个局部 `.gitignore`
  - 把这 3 个 `.res` 从 Git 索引移除
- 验证上有两个真实结论：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 通过，说明删掉 tracked `fafafa.core.simd.test.res` / `test_backend_ops.res` 不会破坏主 `simd` runner 或 standalone smoke
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.intrinsics.mmx/BuildOrTest.sh test` 通过，且 `intrinsics.mmx.test.res` 会被重新生成；配合新 ignore 后，它不再回流成工作树噪音

## 2026-05-17 Task2/Task3 Doc Truth Resync

- 当前浮出的不是新的 SIMD 实现缺陷，而是一条真实的 active-doc / scratch drift：
  - `docs/fafafa.core.simd.checklist.md` 仍保留“`Task 2` 已收口、`Task 3` 暂时 `pending fresh Task 3 run`”的旧维护指令
  - `docs/fafafa.core.simd.closeout.md` 的 `Task 2 / Task 3 closeout facts` 标题和 evidence 仍停在 `2026-04-14 fresh`
  - `plans/scratch/.../task_plan.md` 还残留上一批 docs truth-sync 已经 commit 之后的 `in_progress`
- 这些旧状态已经被当前实证推翻：
  - `python3 tests/fafafa.core.simd/check_implementation_matrix_sync.py --summary-line` 返回 `issues=0 status=ok`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh implementation-matrix-sync` fresh 通过
  - `docs/fafafa.core.simd.implementation-matrix.md` 已明确写明 `Task 2 / Task 3` 都有 `2026-04-19 fresh evidence`
  - `tests/fafafa.core.simd/logs/qemu-multiarch-20260419-012508-1690172/summary.md` 与 `...013630-1748481/summary.md` 真实存在
- 因而这批最小正确修法不是再重跑大链，也不是回退 `Task 3` 状态，而是把恢复点同步到当前真相：
  - checklist 改成“当前已回填完成”的维护顺序
  - closeout 的 `Task 2 / Task 3` fresh 事实改用 `2026-04-19` 证据
  - scratch `task_plan` 里上一批已经提交的 docs truth-sync 正式收成 `completed`
- 这批的价值在于避免下次继续从错误的 `pending` / `in_progress` 恢复点重新开工。

## 2026-05-17 Windows Alias Help Truth Sync

- 当前 runner 线已经不再存在“还要不要删 `evidence-win` / `evidence-win-verify`”这个结构问题；真实问题缩到了 help/runbook 口径：
  - 源码已经明确它们是刻意保留的 Windows-only alias
  - 但 batch help 之前没有单独解释这两条入口
  - active closeout 手册也直接用了 `evidence-win-verify`，却没点明它和 canonical `verify-win-evidence` 的关系
- 这条真相可以直接从源码里读出来：
  - `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_windows_runner_parity()` 注释已明确写着 `These aliases are intentionally Windows-only entry points for native evidence capture.`
  - `LAllowedWindowsOnly` 里只保留：
    - `evidence-win`
    - `evidence-win-verify`
- fresh `bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity` 继续通过，进一步证明：
  - 当前不需要再动 alias 行为本身
  - 真正该收口的是“活跃帮助文案是否把这个例外解释清楚”
- 因而这批最小正确修法不是继续改 dispatch 或删 alias，而是把结论同步到用户看得到的入口：
  - batch help 增加两条 alias 说明
  - closeout 文档解释 `evidence-win-verify` 是 Windows native 路径上的 alias，而 canonical verifier 名字仍是 `verify-win-evidence`
  - maintenance 明确 runner parity 当前只允许这两条 Windows-only batch alias
- 这批的价值在于把“有意例外”从源码内部注释推进到 active help/runbook，避免后续反复把同一事实当成新 gap。

## 2026-05-17 Windows Closeout Help Surface Fill

- 在把 alias 真相讲清楚之后，batch help 里还剩一个更具体、也更适合小闭环处理的缺口：
  - usage/action 表已经公开了 canonical Windows closeout 动作
  - 但 help block 仍没列出：
    - `win-evidence-preflight`
    - `verify-win-evidence`
    - `finalize-win-evidence`
    - `win-closeout-3cmd`
    - `win-closeout-finalize`
- 这会带来一个实际体验问题：
  - 用户在 `buildOrTest.bat` help 里能看到 alias
  - 却看不到 canonical Windows closeout 主线的 5 条动作说明
  - 于是 help surface 会错误地放大 alias、弱化正式收口入口
- 因而这批最小正确修法不是“补完整个 help 世界”，而是只补这 5 条同簇动作：
  - 它们都属于 Windows closeout 主线
  - 都已存在于 usage/action 表
  - 现在只差 help 文案没有对齐
- 轻量验证也足够直接：
  - `git diff --check`
  - `rg` 命中 5 条新 help
  - 小脚本确认这 5 个 action 名字都已进入 `echo   ...` help surface
- 这批的价值在于把 batch help 从“知道别名、不知道主线”收正成“alias 和 canonical Windows closeout 入口都说清楚”。

## 2026-05-17 Daily Audit Help Surface Guard

- 在补完 Windows closeout 主线 help 之后，剩下最像“真实日常使用痛点”的缺口，不是又一组 Windows 入口，而是 batch help 对日常审查主线的可见性仍明显不足：
  - action 表里已经有一整簇高频动作
  - 但 help block 仍缺：
    - `cpuinfo-lazy-repeat`
    - `implementation-matrix-sync`
    - `interface-completeness`
    - `dispatch-read-scope`
    - `dataplane-consumer-scope`
    - `direct-dispatch-scope`
    - `metadata-query-scope`
    - `contract-signature`
    - `publicabi-signature`
    - `publicabi-smoke`
    - `adapter-sync-pascal`
    - `adapter-sync`
    - `coverage`
    - `wiring-sync`
    - `experimental-intrinsics`
    - `experimental-intrinsics-tests`
- 这批之所以值得单独收，不只是“help 少几行”，而是因为它正好落在当前 SIMD 日常审查主链上：
  - `implementation-matrix-sync`、四条 `scope/signature`、`adapter-sync*`、`coverage`、`wiring-sync` 都是近几轮持续收口后的高频证据入口
  - 它们已经影响真实恢复点和日常审查节奏，不该继续只躲在 usage/action 表里
- 单补 help 还不够，真正的 repo 内问题是“help 回退没有 guard”：
  - 现有 `check_windows_runner_parity()` 会守 action 表、usage、若干 help 文案
  - 但之前并没有把这 16 条日常审查动作的 help 文案纳入 required pattern
  - 结果就是以后即便有人把 help 又删掉，`runner-parity` 也未必第一时间报红
- 因而这批最小正确修法是双收口：
  - batch help 增加这 16 条动作说明
  - `BuildOrTest.sh` 里的 parity required pattern 同步守住这组 help surface
- fresh `runner-parity` + Release `check` 通过之后，这条线的结论就很明确了：
  - 现在不是只有 action 表“存在”这些动作
  - 而是 help surface 也被主检查链真实保护起来了

## 2026-05-17 Evidence Help Surface Completion

- 在补完日常审查主线那 16 条 help 后，batch help 剩下的缺口已经很干净地收敛成最后一簇：
  - `import-nonx86-native-evidence`
  - `closeout-host-local-from-import`
  - `parity-suites`
  - `gate-summary*`
  - `perf-smoke`
  - `nonx86-optin-list-suites`
  - `nonx86-ieee754`
  - `backend-bench`
  - `qemu*`
  - `riscvv-opcode-lane`
  - `qemu-experimental-*`
- 这簇比上一批更适合一次性收完，因为它们本身就是同一种“证据/报告/基准/多架构执行入口”：
  - 不再像前几轮那样横跨 public ABI、scope guard、contract、coverage 几类不同话题
  - 而是天然共享同一条使用场景：evidence / summary / QEMU / perf closeout
- 这批也适合把验证成本刻意降下来：
  - 改动只落在 shell/batch help 文案和 parity required pattern
  - 没有碰任何执行分支、环境变量判断或 runner 行为
  - 因此没必要再重跑整条 Release `check`
- 当前最小正确验证组合是：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - help 缺口计数脚本重新统计
- fresh 结果把这条线真正收平了：
  - `runner-parity` 继续为绿
  - shell 脚本语法通过
  - `MISSING_HELP_COUNT 0`
- 因而这批的价值，不只是“又补了几行说明”，而是：
  - `buildOrTest.bat` 的 action 表和 help surface 终于没有系统性遗漏
  - 这条 help completeness 线可以真正从“持续补漏”转成“后续只在新增 action 时跟进”

## 2026-05-17 Intrinsics Coverage Evidence Normalization

- 当前 `intrinsics coverage` 的检查逻辑本身已经能给出正确信号，但在 runner 层仍有一个真实卫生缺口：
  - shell `coverage` 过去只把结果打到 stdout
  - batch `coverage` 也没有稳定的 JSON 证据落盘
  - 下次如果要对比 coverage 真相，仍然要手工从控制台日志里摘 summary
- 这不是算法 correctness 问题，而是证据形态不稳定：
  - 缺少固定的 `txt/json` 产物，导致 closeout、回归对比、后续脚本消费都不够稳
  - shell / batch 两边也缺少同一口径的 `summary line`，容易重新长出 runner parity 漂移
- 当前最小正确修法不是再扩 coverage 范围，而是把现有 checker 产物标准化：
  - `check_intrinsics_coverage.py` 增加 `--summary-line` / `--json-file`
  - shell `run_coverage()` 默认写 `tests/fafafa.core.simd/logs/intrinsics_coverage.{txt,json}`
  - batch `coverage` 同步输出 `--summary-line --json-file`
- fresh `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh coverage` 已证明这条修法是有效的：
  - `INTRINSICS_COVERAGE_SUMMARY modules=5 missing_required=0 missing_optional=0 extra=0 ... status=ok`
  - JSON 已稳定落到 `tests/fafafa.core.simd/logs/intrinsics_coverage.json`
- 因而这批的本质，是把 `intrinsics coverage` 从“人工阅读型日志”收正成“runner 默认可复用证据”。

## 2026-05-17 Windows Closeout Historical-vs-Current Truth Drift

- 当前最真实的新问题不在 SIMD 实现层，而在 closeout 文档叙事：
  - latest `freeze-status` 明确仍是 `freeze_ready=false / cross_ready=false`
  - 红点集中在 `evidence-verify=SKIP`、Windows evidence freshness / verify，以及 `RECENT_BILLING_BLOCK`
  - 但 active closeout 文档后段、RC checklist 当前结论、以及 completeness matrix 的 Windows 行仍然容易让人读成“当前 HEAD 已完成跨平台收口”
- 这不是简单的“旧文档没更新日期”，而是会误导后续审查路径：
  - 维护者可能把“历史 Windows 实机证据已归档”误读成“当前 HEAD 仍 cross-ready”
  - 然后继续围绕实现层空转，而不是老老实实把状态记成 `code-green / release-evidence-blocked`
- 最小正确修法不是把所有历史 `[x]` 都直接撤销：
  - `freeze-status` 的 optional doc check 目前就是依赖这些历史归档标记
  - 直接改成 `[ ]` 会改变现有 evaluator 口径，而不是单纯纠正文案
- 因此更稳的修法是：
  - 保留“历史归档”标记
  - 但在 active closeout / handoff / RC checklist / completeness matrix 上补显式注释：
    - 历史批次曾闭环 != 当前 HEAD 仍满足 latest `freeze-status`
    - 当前真实状态仍以 latest `freeze-status` 为准

## 2026-05-17 Freeze-Status Optional Doc Detail Ambiguity

- 在 closeout 文档 truth-sync 之外，`evaluate_simd_freeze_status.py` 还保留了一个更小的提示语问题：
  - `roadmap_windows_closed`
  - `rc_windows_closed`
  - `matrix_windows_closed`
  - 这三项都是 optional doc signal，但 detail 文案仍然只写成了 `checkbox is [x]` / `row is [x]` / `marks ... archived`
- 逻辑上它们没错，问题在输出语义：
  - 用户或维护者在快速扫 `freeze-status` 时，很容易把这些 PASS detail 误读成“当前 HEAD 的 Windows closeout 也已经绿了”
  - 尤其当前同一份输出里又同时存在 `windows_evidence_freshness FAIL` / `windows_evidence_verify FAIL`
- 最小正确修法仍然不是改判定，而是改 detail：
  - 保持 optional PASS/PENDING 结构不变
  - 但把 detail 明确写成 `historical Windows archive marker` / `not a current readiness signal`

## 2026-05-17 Entry-Point Docs Missing Current Stop-Point

- 在 active closeout/checklist/handoff 已经收正之后，第一入口文档层还残留一个真实缺口：
  - `docs/fafafa.core.simd.md`
  - `src/fafafa.core.simd.README.md`
  - `docs/fafafa.core.simd.maintenance.md`
  - 这些文件都能把维护者正确导向模块入口，但还没有在最前面讲清“当前是不是还该继续改实现”
- 风险不是文案不够新，而是入口路径会误导动作选择：
  - 读者可能因为 README 里直接写了 `closeout-release` 主入口，就默认觉得当前环境下只差执行
  - 也可能因为模块总览/维护指南没有写停点，重新回到泛审查或结构辩论
- 当前最小正确修法不是把这些文档都重写成 closeout 手册，而是补一条共享停点：
  - 当前 canonical 事实是 `code-green / release-evidence-blocked`
  - full `freeze-status` 仍红在 Windows evidence freshness / verify + Billing block
  - 没有 fresh red 落回实现层之前，默认不要再重开 SIMD 泛审查

## 2026-05-17 Summary-Refresh Follow-Up Drift

- 在 `windows_b07_closeout_summary.md` 被刷新成当前 honest FAIL 之后，active 文档顶部又暴露了一个新的轻量 drift：
  - `closeout.md` / `checklist.md` / `handoff.md` 仍把 `windows_b07_closeout_summary.md` 当成当前红项
  - 但 latest `freeze-status` 里它已经是 `PASS`，只是“summary matches verifier FAIL”
- 这类 drift 的风险不在实现层，而在 triage 顺序：
  - 维护者会把时间花在已经 honest 的 summary 上
  - 而不是直接面对真正剩余的三件事：旧 `windows_b07_gate.log`、`windows_evidence_verify` 和 `RECENT_BILLING_BLOCK`
- 最小正确修法就是把顶部“当前红项”摘要改成最新事实，而不是再重写整篇 closeout 手册

## 2026-05-17 Local Wine Is Not Yet a Real Windows Evidence Runner

- 这一轮 completion audit 专门检查了一个容易被想当然的替代路径：本机 `wine` 是否已经足够承担 Windows evidence 收口。
- 结果不是“完全不可用”，而是一个更窄也更重要的边界：
  - `wine` runtime 本身可用
  - Windows batch success-criteria smoke 也能通过
  - 但真实 `evidence-win-verify` 进入 batch gate 后，会在 build 第 1 步就死在 `lazbuild` 调用上
- 这意味着当前 Wine 只证明了：
  - batch runner 语义/返回码 contract 可以被 smoke
  - 不能证明当前环境真的具备 fresh Windows evidence 采集能力
- 我还额外验证了几条常见桥接假设：
  - `cmd` 不能直接执行 `Z:\usr\bin\lazbuild`
  - `start /unix` 在最小 `true` 探针上能返回，但没有形成可复用的 `lazbuild` bridge
  - 临时 wrapper 也没变成稳定可用方案
- 因而当前不要把“本机装了 Wine”误读成“已经有真实 Windows runner 兜底”：
  - 这条线在当前环境下仍然只到 smoke，不到 closeout
  - 最新剩余 blocker 继续是 fresh Windows evidence 本身，而不是 repo 内实现/文档再缺一层

## 2026-05-17 Runner-Parity Allowlist Drift

- `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_windows_runner_parity()` 曾保留 `LAllowedShellOnly=(import-nonx86-native-evidence)`。
- 但 fresh action diff 已证明当前真实差集是：
  - shell-only = none
  - windows-only = `evidence-win`, `evidence-win-verify`
- 这意味着 `import-nonx86-native-evidence` 已经不再是 shell-only 例外；继续保留 allowlist 会削弱未来回归检测：
  - 如果后续 batch 入口被删掉，这个历史例外可能把缺口静默吃掉
  - 旧 allowlist 也没有继续验证“例外是否仍然只存在单边”
- 最小正确修法不是再补文档，而是收紧 guard 本身：
  - 移除 stale shell-only allowlist 项
  - 让 shell-only / windows-only allowlist 都额外校验“是否已经出现在对侧 action 集”
- 这类问题属于 guard truth drift，不是 SIMD 算法或 Windows external blocker。

## 2026-05-17 Default `check` Still Used Non-Strict Register Truthfulness

- 当前 fresh `check` 路径之前仍把 `register-truthfulness` 跑在 non-strict 模式：
  - shell: `run_register_truthfulness_check "0"`
  - batch: `call :register_truthfulness_check 0`
- 这和当前仓库的实际 closeout/triage 口径已经有轻度漂移：
  - 手工 checklist 已明确使用 `--strict`
  - `impl-audit-nonx86` / release closeout 近几轮也都是 strict truth source
  - 但日常 `check` 仍可能放过新的 always-context `wrapper_only` backend-owned drift
- 先做 fresh strict proof 后确认这不是“会把当前树打红”的冒险改动：
  - `backend=neon ... miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv ... miswired=0 unused_allowlist=0 strict=1`
- 因而最小正确修法是把默认 `check` 直接升级到 strict，并同步 batch parity 与维护文档，而不是继续保留两套口径。

## 2026-05-17 Runner-Parity Did Not Yet Guard The Default `check` Lane

- 在把默认 `check` 收正为 `register-truthfulness --strict` 之后，`runner-parity` 仍有一层更细的覆盖缺口：
  - 它已经守 action/help/alias，也守了一部分 batch `check` 默认分支
  - 但还没有要求 batch `check` 明确保留：
    - `Backend adapter sync (python-only)` 那组 python-only 收口
    - `call :register_truthfulness_check 1`
    - experimental isolation 分支
- 这类缺口的风险不是当前执行错，而是将来 batch 默认 `check` 退回旧口径时，`runner-parity` 仍可能继续通过。
- 因而最小正确修法不是再改执行逻辑，而是补齐 parity required patterns，让这几条默认 lane 也进入 fail-close 保护。

## 2026-05-17 More Default `check` Guards Were Still Invisible To Runner-Parity

- 在补完 `adapter-sync / register-truthfulness / experimental` 之后，机器对账继续显示 `runner-parity` 还漏着同类位点：
  - dataplane / dispatch / SSE2 / suite-manifest 这组静态 guard
  - `implementation-matrix-sync`
  - `backend_ops / simd_boundary / public_smoke / dispatch_preinit_smoke`
  - `SIMD_CHECK_NONX86_OPTIN` 的 batch 默认分支
- 这些位点的共同点很清楚：
  - 都已经属于 batch 默认 `check`
  - 都是当前 repo 真实依赖的 cheap static guard 或 standalone smoke
  - 但 parity 之前不会因为它们被删掉而直接报红
- 因而最小正确修法仍然不是动执行逻辑，而是继续补 parity required patterns，把这组高价值默认 `check` 位点纳入 fail-close 保护。

## 2026-05-17 Batch Usage Synopsis Missed `riscvv-opcode-lane`

- 沿着 `runner/check/gate/help` 一致性继续收 residual 时，又发现一个更小但真实的 help drift：
  - `riscvv-opcode-lane` 已经有 shell action、batch action 与独立帮助行
  - shell `Usage: ...` synopsis 也已经列出它
  - 但 batch 总 synopsis 仍漏掉它
- 风险不在执行分支，而在于：
  - Windows 侧 CLI 总览会给出不完整入口面
  - `check_windows_runner_parity()` 当前把这条 stale batch synopsis 当成 expected pattern，自身也不会因为这处 help drift 报红
- 因而最小正确修法是把 batch synopsis 与 parity required synopsis 一起补齐，而不是扩大到其他实现面。

## 2026-05-17 Synopsis Guard Itself Was Redundant

- 在补上 `riscvv-opcode-lane` 之后，继续回看 `runner-parity` 本身，会发现更深一层的问题：
  - 当前 synopsis 守卫依赖一整条硬编码 `echo Usage: ...` expected pattern
  - 这意味着每次 action 面扩展时，都要手工同步一次长字符串
  - 这正是刚才 batch synopsis 漂移能够存活下来的冗余来源之一
- 更稳妥的修法不是继续扩那条长字符串，而是：
  - 直接从 shell/batch runner 的 `Usage:` 行提取 synopsis action 集
  - 再与各自真实 action 路由集合做双向对账
- 这样能同时抓住两类问题：
  - synopsis 漏列真实 action
  - synopsis 列出已经不存在的 stale action

## 2026-05-17 Shell Detailed Help Was Still Missing Real Actions

- 继续沿 `runner/check/gate/help` 链做动作面与 help 面对账时，新的真实缺口不在 batch，而在 shell runner：
  - batch 的详细帮助行已经基本覆盖当前 action 面
  - shell 的 `Usage:` synopsis 虽然已经列出很多 action，但详细帮助行仍漏着一串已经实现的真实入口
- 典型漏项包括：
  - `cpuinfo-lazy-repeat`
  - `interface-completeness` / `dispatch-read-scope` / `dataplane-consumer-scope` / `direct-dispatch-scope` / `metadata-query-scope`
  - `contract-signature` / `publicabi-signature` / `publicabi-smoke`
  - `adapter-sync-pascal` / `adapter-sync`
  - `gate-summary-selfcheck`
  - `evidence-linux` / `native-evidence` / `verify-nonx86-native-evidence` / `restore-nightly-evidence`
  - `win-evidence-preflight` / `win-evidence-via-gh` / `verify-win-evidence` / `finalize-win-evidence`
  - `win-closeout-*` / `freeze-status*`
- 风险不是执行错，而是：
  - shell 帮助面对当前入口面仍然不完整
  - 之前的 parity 也没有结构化检查“详细帮助行是否覆盖真实 action”
- 因而最小正确修法不是再补一条字符串，而是：
  - 补齐 shell 详细帮助行
  - 再让 `runner-parity` 直接对账 shell/batch `详细帮助 action 集` 与真实 action 路由集

## 2026-05-17 CPUInfo Parity Still Ignored The Real Windows Runner

- 在主 `simd` runner 的 synopsis/help parity 结构化之后，我回头检查 `check_cpuinfo_runner_parity()`，发现它还有一个更直接的覆盖遗漏：
  - 名字叫 `cpuinfo runner parity`
  - 但实际只检查了 `fafafa.core.simd.cpuinfo/BuildOrTest.sh` 与 `fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh`
  - 并没有把真实存在、真实在 Windows 上承担入口面的 `tests/fafafa.core.simd.cpuinfo.x86/buildOrTest.bat` 纳进来
- 这意味着以前即使 `cpuinfo.x86` batch 的 action/synopsis 漂移了，主 `runner-parity` 也不一定会报红。
- 因而最小正确修法不是重写 `cpuinfo` runner，而是：
  - 把 `cpuinfo.x86` batch 纳入 `check_cpuinfo_runner_parity()`
  - 至少对它的 `--list-suites` 归一化、Invalid option / leak fail-close、以及 action/synopsis 集合做结构化对账
- fresh 落地时还顺手暴露出一个真实解析细节：
  - `cpuinfo.x86` batch 是 CRLF 文件
  - 原先的 Windows synopsis action 提取器没有先去掉 `\r`
  - 结果最后一个 token 会被看成 `release\r`，从而假报 “missing action / unknown action”
- 因而这个批次还需要把 Windows synopsis 提取统一做 CR stripping，避免 parity 因为行尾格式而误报。

## 2026-05-17 Optional Windows Evidence Verify Was Noisy Instead Of Cleanly Skipping

- 继续把审查切到更高层 `gate` 后，门禁本身虽然最终通过，但它暴露了一个新的真实 UX/guard residual：
  - 当 `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0` 且 `windows_b07_gate.log` 存在但内容不完整/过期时
  - `gate` 会先把 verifier 整段输出直接打到终端
  - 然后才把这次 evidence verify 记成 optional `SKIP`
- 结果就是用户会先看到一串 `Missing pattern:` 噪音，再看到 `SKIP optional evidence verify`，阅读体验和信号质量都不好。
- 这里不该削弱 required 模式的 fail-close 细节，所以最小正确修法是：
  - 只在 optional 分支里捕获 verifier 输出
  - 成功时照常回显
  - 失败时不再刷 verifier 的逐条 missing 明细，而是直接打印一条干净的 stale/incomplete skip 提示

## 2026-05-17 Freeze Status Wrapper Was Short-Circuiting Gate Fallback Discovery

- 在继续往 `freeze-status` 收口时，fresh 现象不是 SIMD 实现回归，而是状态选择链本身还有一个真实 bug：
  - Python 侧 `evaluate_simd_freeze_status.py` 已经具备从 `logs/rehearsal/backups/` 或 `logs/windows-closeout/` 回退到更强 gate snapshot 的能力
  - 但 shell 侧 `run_freeze_status()` 默认也会强行导出 `SIMD_FREEZE_GATE_SUMMARY_FILE=<logs/gate_summary.md>`
  - 这样 Python 会把当前 `gate_summary.md` 误当成“显式 override”，从而只看最新一个 summary，不再发现 backup / closeout candidate
- 结果就是：
  - 一次日常 fast gate 即使只是为了验证别的小修复
  - 也会把更早、证据更强的 `qemu-cpuinfo-nonx86-evidence=PASS` gate snapshot 完全遮掉
  - 让 cross 模式 `freeze-status` 错误退化成 `mainline-ready=False`
- 这里的最小正确修法分两层：
  - `run_freeze_status()` 只有在调用者显式设置 `SIMD_FREEZE_GATE_SUMMARY_FILE` / `SIMD_GATE_SUMMARY_FILE` 时才传 override
  - Python 选择器在 cross 模式下，如果最新 snapshot 只覆盖了 base gate，而历史里有 `mainline-ready` 但还不 `cross-ready` 的更强 snapshot，也要能回退到它，保住 Linux 主线 truth

## 2026-05-17 GH Windows Evidence Import Was Polluting Canonical Logs Before Verify

- 继续沿 Windows closeout/evidence 链往下看后，又暴露出一条真实的状态污染 bug：
  - `run_windows_b07_closeout_via_github_actions.sh` 下载 artifact 后，会先把 `windows_b07_gate.log` 直接覆写到 canonical `tests/fafafa.core.simd/logs/windows_b07_gate.log`
  - 然后才调用 `verify_windows_b07_evidence.sh`
- 这意味着只要下载回来的 artifact 本身无效：
  - verifier 虽然会失败退出
  - 但 canonical `windows_b07_gate.log` 已经先被坏 artifact 污染了
  - 当前仓库顶层那份 `windows_b07_gate.log` 就是这种状态：它记录的是 Windows 侧 `lazbuild` 调起失败的 batch，而不是一份 verifier 可接受的 closeout evidence
- 这里的最小正确修法是：
  - artifact 下载后先只写入 batch snapshot
  - 只有在 verifier 对 batch snapshot 返回 PASS 之后，才把 evidence log promote 到 canonical 指针
  - Windows artifact 自带的 `gate_summary.{md,json}` 也不应在 verify 前先覆写 canonical；cross backfill gate 自己会生成更可信的 canonical gate summary

## 2026-05-17 Windows Batch Fallback Was Still Invoking Bare lazbuild Through The Fragile Quoted Form

- 当前 canonical `windows_b07_gate.log` 里还有一条更接近根因的 Windows batch 失败形态：
  - `[BUILD] FAILED ... Can't recognize '"lazbuild" --build-mode=Release ...' as an internal or external command`
  - `[B07] GATE_EXIT_CODE=1`
- 对照当前 batch runner 后，发现 `tests/fafafa.core.simd/buildOrTest.bat` 以及 `simd.intrinsics.{sse,mmx}/buildOrTest.bat` 仍在直接执行：
  - `" %LAZBUILD_EXE% " ...`
- 当 `%LAZBUILD_EXE%` 回退成裸命令 `lazbuild` 时，这种“直接带引号调用”的形态明显比 `call "%LAZBUILD_EXE%" ...` 更脆弱：
  - `cpuinfo.x86` 的 batch runner 已经在用 `call "%LAZBUILD_EXE%" ...`
  - 当前坏日志命中的正是 SIMD main batch 这条未统一的调用形态
- 因而这一批的最小修法是：
  - 把 SIMD main / intrinsics.sse / intrinsics.mmx 这 3 个 Windows batch runner 的 `lazbuild` 调起方式统一成 `call "%LAZBUILD_EXE%" ...`
  - 先消掉这条已被真实 Windows evidence 命中的易碎路径

## 2026-05-17 Freeze Status Was Still Surfacing Windows Verifier Noise Before The Real Root Cause

- 在 `freeze-status` 已经只剩 Windows closeout/evidence 链红项后，输出层面还存在一个真实的可读性问题：
  - `windows_evidence_verify` 失败时，默认会直接把 verifier 的第一串 `Missing pattern:` 噪音塞进 detail
  - 但当前 canonical `windows_b07_gate.log` 里的真实根因其实更直接：Windows batch 在主 build 阶段就已经 `GATE_EXIT_CODE=1`
  - 当前最有价值的提示不是“缺了哪些 gate marker”，而是日志里已经明确出现的 root cause，例如 `Can't recognize '"lazbuild"' ...`
- 这类情况如果继续只刷 verifier missing 明细，会把真正 hot path 藏起来，让下一轮审查又回到“看症状不看边界”。
- 因而最小正确修法是：
  - `evaluate_simd_freeze_status.py` 在 `windows_evidence_verify` fail 时，先从真实 Windows log 抽取 root-cause hint
  - 若能定位到 `BUILD FAILED` / `Can't recognize` / `GATE_EXIT_CODE!=0` 这类早期失败信号，就把它放到 detail 最前面
  - verifier 输出仍保留，但只保留 `first verifier issue`，不再把整串 missing 明细原样塞进 `freeze-status`

## 2026-05-17 Closeout-Release Still Needed Cached Billing-Block Failover At The Top-Level Entry

- 在把 `freeze-status` 信号收清后，`closeout-release` 顶层入口又暴露出一个更窄但更真实的残差：
  - fresh `win-evidence-preflight` 可以稳定返回 `RECENT_BILLING_BLOCK`
  - 但直接执行 `closeout-release` 时，live preflight 里的 workflow 查询偶发会先炸成 `WORKFLOW_QUERY_FAILED`
  - 如果主入口只把这个 `24` 原样抛出，操作者看到的就会是“查询失败”，而不是当前真正应该停下来的 blocked reality
- 这类缺口的坏处很直接：
  - repo 明明已经有一份 fresh 的 billing-block 证据
  - 但顶层主入口还是会把人引回“是不是 workflow / repo / gh 又坏了”的噪音路径
  - 于是真正的 stop condition 没有被主入口保住
- 这批最小正确修法分两层：
  - `preflight_windows_b07_evidence_gh.sh` 不再只依赖 `gh repo view`，而是允许从 `git remote origin` 解析 `owner/repo`，避免在 closeout 主链里被 `REPO_RESOLVE_FAILED` 过早打断
  - `BuildOrTest.sh::run_closeout_release()` 在 live preflight 前先记住“是否已有 fresh 的 `RECENT_BILLING_BLOCK` cache”；若 live 查询返回 `24`，就复用这份 fresh cache，把顶层结果稳定收敛成 `31 + STOP latest preflight is RECENT_BILLING_BLOCK`
- 所以这批不是“把失败文案改好看”：
  - 而是把顶层入口的 fail-fast 语义重新接到真实 blocked evidence 上
  - 让 `closeout-release` 在 GitHub 查询抖动下仍能保持正确的 operator truth

## 2026-05-17 Win-Preflight Latest Report Was Still Being Polluted By Query Noise

- 在 `closeout-release` 顶层 fail-fast 已经收正后，我又顺手回看了真实 `freeze-status` 输出，发现还有一条更细的状态污染残差：
  - 真实 `win-evidence-preflight` 能返回 `RECENT_BILLING_BLOCK`
  - 但之后只要 `closeout-release` 里的 live preflight 再次撞到 `WORKFLOW_QUERY_FAILED`
  - `tests/fafafa.core.simd/logs/win_preflight_latest.json` 就会被新的 `24` 直接覆写
  - 结果 `freeze-status` 又会重新对外显示 `windows_preflight_latest = WORKFLOW_QUERY_FAILED`
- 这类污染的坏处很具体：
  - 顶层 `closeout-release` 本身已经知道要按 cached billing-block 停机
  - 但 `freeze-status` 这种真正给人看的聚合状态，却会因为瞬时 GitHub 查询抖动而退回到 transport noise
  - 于是 operator truth 在主入口和聚合入口之间重新分裂
- 这里的最小正确修法不是继续在 `freeze-status` 里猜，而是收紧 preflight report 的语义：
  - `win_preflight_latest.{json,md}` 继续代表当前 operator truth
  - 若当前已有 fresh `RECENT_BILLING_BLOCK`，而新的 live 查询只是 `WORKFLOW_QUERY_FAILED`
  - 就把这次瞬时查询失败写到 diagnostic sidecar，而不是覆写 latest truth
- 这样收口后：
  - `closeout-release` 仍能按 `24 -> cached 31` fail-fast
  - `freeze-status` 重新稳定看到 `RECENT_BILLING_BLOCK`
  - 瞬时 query noise 仍保留在 sidecar，便于后续诊断，但不会再污染主状态文件

## 2026-05-17 Standalone Win-Preflight Stdout Was Still Diverging From Preserved Billing Truth

- 在把 latest report 保住后，我继续做 completion audit，又发现还有最后一层 operator-truth 分裂：
  - `win_preflight_latest.{json,md}` 已经不会再被瞬时 `WORKFLOW_QUERY_FAILED` 覆写
  - 但 standalone `win-evidence-preflight` 自己的 stdout / exit code 仍会直接把这次 live query failure 暴露成 `24`
  - 也就是说，同一次执行里：
    - 落盘 truth 是 `RECENT_BILLING_BLOCK`
    - 终端 truth 却还是 `WORKFLOW_QUERY_FAILED`
- 这会让直接手跑 preflight 的操作者再次被 transport noise 带偏，即使 `closeout-release` / `freeze-status` 已经回到了正确 blocked reality。
- 这一层的最小正确修法是：
  - 只在 fresh cache 窗口内（与 `closeout-release` 一样默认 2h）启用 preserved billing truth
  - 如果 live query 失败但 latest 仍是 fresh `RECENT_BILLING_BLOCK`
  - stdout 也直接按 `STATUS=FAIL CODE=RECENT_BILLING_BLOCK EXIT=31` 对外表态
  - 同时把真实 live query 失败写进 diagnostic sidecar，保留诊断面
- 这样收口后，3 个主要入口就重新对齐了：
  - standalone `win-evidence-preflight`
  - `closeout-release`
  - `freeze-status`

## 2026-05-17 Preflight Diagnostic Sidecar Could Linger After A Later Direct Billing-Block Result

- 在把 standalone preflight 的 stdout 也收正后，我继续检查真实落盘产物，又发现一个更小但仍然会误导后续审查的残差：
  - preserved branch 现在会把瞬时 query noise 写入 `win_preflight_latest.diagnostic.{json,md}`
  - 但后面如果再跑一次 direct preflight，而且这次直接返回真实 `RECENT_BILLING_BLOCK`
  - `win_preflight_latest.{json,md}` 会更新
  - 旧 diagnostic sidecar 却还会残留在旁边
- 这类残留不会影响 `closeout-release` / `freeze-status` 判断，但会让人工读日志的人误以为“当前 latest 旁边还挂着新的 query failure”，属于典型的 tracked artifact 噪音。
- 这里的最小正确修法是：
  - preserved branch 继续保留 diagnostic sidecar
  - 但一旦后续进入 normal main-report write path（PASS、直接 billing-block、或其他 normal fail）
  - 就先清掉旧 diagnostic sidecar，再写新的 latest report
- 这样收口后：
  - diagnostic sidecar 只在“当前 latest 是被 preserve 的 cached truth”这一瞬间存在
  - 后续 direct preflight 一旦回到正常主路径，就不会继续带着陈旧 query noise

## 2026-05-17 Freeze Status Was Still Treating A Pre-Runner-Fix Windows Failure Log As Current Truth

- 在把 preflight artifact hygiene 收完之后，我继续对当前 `freeze-status` 做 completion audit，又发现一条更接近“真相判定边界”的残差：
  - 当前 `windows_b07_gate.log` 的 mtime 的确还在 freshness 窗口内
  - `src/fafafa.core.simd*` 也没有比它更新
  - 但真正负责生成这份 Windows log 的 `tests/fafafa.core.simd/buildOrTest.bat` 却比它新很多
  - 也就是说，这份失败日志实际上是“旧 runner 语义下产出的历史失败”，而不是当前 runner truth
- 这类误导的坏处很直接：
  - `freeze-status` 会继续把旧 log 的 verifier fail 直接展示成当前 `windows_evidence_verify` 失败
  - `windows_b07_closeout_summary.md` 也会继续被当成“honest current summary”
  - 但当前更准确的说法应该是：这两者都已经 stale，需要重新跑 Windows evidence，而不是继续对旧失败日志做语义判断
- 这批最小正确修法是：
  - 在 `freeze-status` 里新增一条 machine-check：
    - `windows_evidence_inputs_not_newer_than_log`
  - 它不看 `src/`，而是看真正的 Windows evidence producer inputs（当前先收紧到 `buildOrTest.bat` / `collect_windows_b07_evidence.bat`）
  - 一旦 producer 新于 `windows_b07_gate.log`
    - `windows_evidence_verify` 就明确变成 `stale evidence log: ... historical verifier detail: ...`
    - `windows_closeout_summary` 也一起降格为 stale historical summary
- 这样收口后，`freeze-status` 对当前仓库的 Windows 链解释会更接近真实因果：
  - 外部 blocker 仍然是 billing / runner
  - 但仓库里那份旧 Windows 失败日志，也不再被误当成“当前 runner 下仍复现的失败”

## 2026-05-17 Current Wine Batch Evidence Refresh Proved The Runner-Quoting Fix But Exposed The Remaining Wine Bridge Limit

- 在把 stale historical evidence 规则补上后，我没有停在“旧 log 不再误导”这个层面，而是又重新跑了一次真实本机 Wine batch：
  - `wine cmd /c tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify`
- 这次得到的结论很关键：
  - canonical `windows_b07_gate.log` 的确被 fresh 刷新到了当前 runner 版本
  - 所以前一条关于 stale historical evidence 的判断，在当前 `HEAD` 上已经不再命中
  - 同时，Windows 失败边界也从旧的 `'"lazbuild"'` / `call` 误导，推进成了更真实的：
    - `Can't recognize 'lazbuild --build-mode=Release ...'`
- 这说明两件事：
  - repo-local batch quoting / call 形态里的一个真实 bug 已经被收掉
  - 但本机 Wine 仍不能把 Linux 侧的 bare `lazbuild` 当成 Windows batch 可执行命令
- 所以当前剩余问题的性质也更清楚了：
  - 它已经不是“旧历史日志污染 freeze-status”
  - 也不再是“batch runner 还把命令拼错”
  - 而是“本机 Wine bridge 仍不足以替代真实 Windows runner / GH runner”

## 2026-05-17 Closeout Summary Was Still Being Trusted Even After A Fresh Current Windows Log Replaced The Old Evidence

- 在 fresh current `windows_b07_gate.log` 已经刷回来之后，我继续对真实 `freeze-status` 做 completion audit，发现还有最后一个相邻的 truth-split：
  - 当前 log 已经是 17:27 的 fresh current evidence
  - 但 `windows_b07_closeout_summary.md` 仍是 12:34 的旧 summary
  - 之前 `freeze-status` 只看 summary 里有没有 `- Result: FAIL`
  - 于是即使 summary 已经明显旧于当前 log，仍会把它当成 `summary matches verifier FAIL`
- 这类误导的坏处也很直接：
  - 读者会误以为 closeout summary 已经同步到了当前 fresh log
  - 但实际上当前更准确的下一步应该是先重跑 `finalize-win-evidence`
  - 否则 current log 和 current summary 会继续不对齐
- 这批最小正确修法是：
  - 新增 `windows_closeout_summary_not_older_than_log`
  - 一旦 summary 旧于当前 log：
    - 这条 freshness check 直接 FAIL
    - `windows_closeout_summary` 也明确变成 `stale summary: closeout summary is older than current windows evidence log`
    - next-actions 补上 `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence`

## 2026-05-17 QEMU Retry Rehearsal Surface Drift

- 当前 repo 内 closeout/rehearsal 链继续往下压后，最后一个仍值得修的 residual 已经不是实现缺陷，而是 runner surface drift：
  - shell `BuildOrTest.sh` 已经公开 `qemu-cpuinfo-retry-rehearsal`
  - batch `buildOrTest.bat` 却还没把同名 action 的 route / usage / help / fail-close label 对齐
- 这类 drift 的风险不是功能跑错，而是：
  - Windows 用户从 batch 入口看不到这条 action
  - `runner-parity` 守护很容易被“shell 已有 / batch 未暴露”的细小漏口绕过去
  - 后续 closeout/rehearsal 的 operator surface 会再次出现 shell truth 和 batch truth 不一致
- 修复后 fresh 证明：
  - `runner-parity` 继续绿
  - Wine batch 对缺 `bash` 的 fail-close 输出也已与 shell 约定一致
- 结论：
  - repo 内 runner parity 现在已进一步压到真正只剩 Windows 外部能力差异
  - 当前不该再把注意力放回 repo 内继续找新的 parity 漏洞，除非出现新的 live 证据
