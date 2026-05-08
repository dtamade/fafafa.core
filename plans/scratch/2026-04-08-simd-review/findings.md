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
- 这种“可变全局 record，内部含 managed string/动态数组”的发布模型，在高频 control-plane mutation 下仍有较高的生命周期风险。
- 这条线还未修，但优先级次于 public ABI backend text，因为当前最小可复现已经先卡在 text getter。

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
