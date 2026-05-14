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

- `freeze-status` 已确认 Linux 主 gate 新鲜且通过，但 `qemu-cpuinfo-nonx86-evidence` 在最近 gate 里为 `SKIP`，因此 mainline/cross ready 仍为 `False`。
- Windows evidence 已存在且 verifier 通过，但 `windows_b07_gate.log` 与 `windows_b07_closeout_summary.md` 均已超过 freshness 阈值，且旧于最新 SIMD 源码。
- 这说明当前 SIMD 的成熟度问题不是“没有测试”或“当前 diff 有 bug”，而是“发布级跨平台证据没有按当前源码时间线刷新”。

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
