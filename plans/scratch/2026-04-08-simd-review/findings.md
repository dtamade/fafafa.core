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
