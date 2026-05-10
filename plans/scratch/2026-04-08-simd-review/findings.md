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
  这三重身份，债务最集中。
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
  - `SSSE3` raw-leaf target 明确化
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
  - 后续如果计划再扩张，应优先维护 execution index，而不是再让使用者自己从总纲里提取顺序

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
