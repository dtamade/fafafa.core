# Findings & Decisions

## Requirements
- 审查 `simd` 模块
- 找出实际问题
- 修复至少一轮已确认问题
- 形成连续的修复与审查计划

## Research Findings
- 最新一轮继续深审 runtime toggle / dispatch helper 合同后，又确认一条新的真实 half-rebuilt snapshot：
  - 本轮原始目标是检查 `GetBestDispatchableBackend` / `GetDispatchableBackendList` / `GetAvailableBackendList` 在 `SetVectorAsmEnabled(False <-> True)` 并发窗口里会不会暴露半重建中间态
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TTestCase_SimdConcurrentFramework.Test_Concurrent_DispatchableHelpers_VectorAsmToggle_ReadConsistency` 后，fresh red 不只打出了新的 helper bug，也把旧 `GetCurrentBackendInfo` 路径的 deeper root cause 一并重新打了出来
  - 第一层新问题在 dispatchable helper：
    - `src/fafafa.core.simd.dispatch.pas` 的 `GetDispatchableBackends` / `GetBestDispatchableBackend` 之前直接逐项调用 `IsBackendDispatchable(...)`
    - 但 `SetVectorAsmEnabled(...)` 会在持锁状态下按 backend 顺序执行 `RebuildBackendsAfterFeatureToggle(...)`
    - 这意味着 reader 在 writer 正从 disabled -> enabled 重建时，会观察到只存在于中间过程的半重建态，例如 `best=SSE2` 或 `dispatchable=[SSE2,Scalar]`
    - 这些结果既不属于 enabled 全量态，也不属于 disabled 全量态，是标准的 helper-level impossible combo
  - 第二层 deeper root cause 在 current dispatch publication：
    - `DoInitializeDispatch` 现在虽然已经通过 `IsBackendMarkedAvailableForDispatch(...)` 按 published backend snapshot 做选择
    - 但旧实现最后仍然 `PublishCurrentDispatchTable(@g_BackendTables[LBestBackend])`
    - 于是只要 writer 在“选中 backend”之后、`PublishCurrentDispatchTable(...)` 之前刚好把该 backend 的 mutable slot 改成 disabled table，reader 仍会看到 “旧 backend id + 新 disabled metadata”
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework`：FAIL
    - 失败点同时命中两条问题：
      - `current backend info mixed snapshot at iter 2224: got=(backend=6 available=False caps=0 priority=80 name=AVX2) expectedA=(backend=6 available=True caps=447 priority=80 name=AVX2) expectedB=(backend=5 available=True caps=415 priority=70 name=SSE4.2)`
      - `dispatchable helper mixed snapshot at iter 0: got=[1,0] expectedEnabled=[6,5,4,3,2,1,0] expectedDisabled=[0]`
      - `best dispatchable backend mixed snapshot at iter 13: got=1 expectedEnabled=6 expectedDisabled=0`
  - 最小修复方式：
    - 将 `src/fafafa.core.simd.dispatch.pas` 的 current dispatch publication 改为：
      - 先 `LBestDispatchTable := GetPublishedBackendDispatchTable(LBestBackend)`
      - 再 `PublishCurrentDispatchTable(LBestDispatchTable)`
    - 将 `GetDispatchableBackends` 与 `GetBestDispatchableBackend` 改为在扫描期间持有 `g_VectorAsmToggleLock`，使 reader 只能看到 toggle 前或 toggle 后的完整态
  - fresh green / 复验证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework`：PASS，`[LEAK] OK`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatchable-helpers-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 23:04:43`
- 最新一轮继续深审 backend adapter / façade helper 合同后，又确认一条新的真实 metadata drift：
  - `src/fafafa.core.simd.backend.adapter.pas` 的 `GetBackendOps(backend)` 在未注册路径下之前只做了：
    - `ClearBackendOps(Result)`
    - `Result.Backend := backend`
  - 但没有把 `Result.BackendInfo` 对齐到 canonical metadata source
  - 结果就是只要 caller 对未注册 backend 调 `GetBackendOps(sbAVX512/sbNEON/sbRISCVV...)`，返回值里的 `BackendInfo.Backend` 会错误留在默认 `sbScalar(0)`，`Priority` 也会错误留在 `0`
  - 这和同一模块已经公开的 `GetBackendInfo(backend)` contract 直接漂移，会把“requested backend id”和“adapter backend info”撕成两份真相
  - 为了先把合同打红，本轮先补一条最小 deterministic regression：
    - `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas` 新增 `Test_BackendAdapter_UnregisteredBackendOps_PreserveCanonicalMetadata`
    - 测试直接枚举一个当前未注册 backend，断言 `GetBackendOps(backend)` 返回的 `BackendInfo.Backend/Priority/Name` 必须与 `GetBackendInfo(backend)` 一致
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots`：FAIL
    - 失败点直接命中 canonical backend id 漂移：
      - `GetBackendOps should preserve BackendInfo.Backend for unregistered backend=7 expected: <7> but was: <0>`
  - 最小修复方式：
    - 将 `src/fafafa.core.simd.backend.adapter.pas` 的未注册路径改为直接 `Result.BackendInfo := GetBackendInfo(backend)`
    - 保留 `Result.Backend := backend`，但不再让 adapter 自己手拼一份零值 `BackendInfo`
  - fresh green / 复验证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots`：PASS，`[LEAK] OK`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-adapter-unregistered-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 22:31:18`
  - 这轮还顺手补了 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 的 `Test_PublicAbi_BackendText_Getters_PreviousPointers_RemainValid_After_Refresh`
  - 该 guard 在当前环境保持绿色，没有打出 fresh red，因此它只是 future lifetime 护栏，不作为本轮主问题 closeout
- 最新一轮继续深审 framework active metadata 并发合同后，又确认一条新的真实 mixed-snapshot：
  - `src/fafafa.core.simd.framework.impl.inc` 的 `GetCurrentBackendInfo` 之前直接做 `GetBackendInfo(GetActiveBackend)`
  - 这意味着只要 writer 并发 `RegisterBackend(...)` 把当前 active backend 在 enabled/disabled table 间切换，helper 就可能先读到“旧 active backend id”，再读到“该 backend 已被重注册为 disabled”的新 metadata
  - 结果就是 façade 层对外返回一个根本不可能代表 current backend 的组合，例如 `backend=AVX2`，但 `Available=False`、`Capabilities=[]`
  - 为了先把合同打红，本轮先补一条独立并发 regression：
    - `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TTestCase_SimdConcurrentFramework`
    - 新增 `Test_Concurrent_CurrentBackendInfo_RegisterBackend_ReadConsistency`
    - writer 复用 `TBackendRegisterToggleWorker`，持续把当前 active backend 在 enabled/disabled 两套 table 间重注册
    - reader 持续断言 `GetCurrentBackendInfo` 只能等于 “enabled current info” 或 “disabled 后真实 fallback current info”，不能出现 disabled target info
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackendinfo-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework`：FAIL
    - 失败点直接命中 impossible combo：
      - `current backend info mixed snapshot at iter 127: got=(backend=6 available=False caps=0 priority=80 name=AVX2) expectedA=(backend=6 available=True caps=447 priority=80 name=AVX2) expectedB=(backend=5 available=True caps=415 priority=70 name=SSE4.2)`
  - 最小修复方式：
    - 将 `src/fafafa.core.simd.framework.impl.inc` 的 `GetCurrentBackendInfo` 改为先取 `GetDispatchTable`
    - 如果当前 dispatch snapshot 存在，就直接返回 `LDispatch^.BackendInfo`
    - 只有极端兜底路径才退回旧的 `GetBackendInfo(GetActiveBackend)`
  - fresh green / 复验证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackendinfo-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework`：PASS，`[LEAK] OK`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackendinfo-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-currentbackendinfo-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 21:54:05`
- 最新一轮继续深审 public ABI backend pod metadata 的并发合同后，又确认一条新的真实 mixed-snapshot：
  - `src/fafafa.core.simd.public_abi.impl.inc` 的 `TryGetSimdBackendPodInfo(...)` 之前会把同一个 `TFafafaSimdBackendPodInfo` 拆成多次观察再拼装：
    - `CapabilityBits` 取自 `GetBackendInfo(...)` / registered backend snapshot
    - `Flags` 却继续走 `SimdBackendToAbiFlags(aBackend)` 的 live `supported_on_cpu/registered/dispatchable/active` 查询
  - 当 writer 并发 `RegisterBackend(...)` 在同一 backend 上切换 `Available/Capabilities` 时，单个 public ABI backend pod 就可能被拼成跨两个时刻的混搭结果
  - 为了先把合同打红，本轮先补一条独立并发 regression：
    - `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `TTestCase_SimdConcurrentPublicAbi`
    - 新增 `Test_Concurrent_PublicAbiPodInfo_RegisterBackend_ReadConsistency`
    - 新增 `TBackendRegisterToggleWorker` / `TPublicAbiPodInfoReadWorker`
    - writer 在 enabled/disabled 两套 synthetic backend table 间持续 `RegisterBackend(...)`
    - reader 持续断言 backend pod info 只能等于 `(原 capability bits, flags=7)` 或 `(0, flags=3)` 两种合法组合
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-podinfo-red3-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi`：FAIL
    - 失败点直接命中 mixed snapshot：
      - `backend pod info mixed snapshot at iter 86: caps=415 flags=3 expectedA=(415,7) expectedB=(0,3)`
      - `backend pod info mixed snapshot at iter 31: caps=0 flags=7 expectedA=(415,7) expectedB=(0,3)`
  - 最小修复方式：
    - 在 `src/fafafa.core.simd.public_abi.impl.inc` 新增 `BuildSimdBackendAbiFlagsFromSnapshot(...)`
    - `TryGetSimdBackendPodInfo(...)` 改为先通过 `TryGetRegisteredBackendDispatchTable(...)` 取单份 published backend snapshot
    - `CapabilityBits`、`dispatchable` 与 registered-state `Priority` 全部从同一份 `LDispatchTable.BackendInfo` 派生
    - 只有 `active` bit 继续从 `GetDispatchTable` 的当前 active snapshot 判定
    - 未注册路径的 `Priority` 改为退回 `GetBackendInfo(aBackend).Priority`，避免为了 canonical priority 再引入额外 unit 可见性耦合
  - fresh green / 复验证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-podinfo-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi`：PASS，`[LEAK] OK`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-podinfo-publicabi-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`：PASS，`[LEAK] OK`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-podinfo-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-podinfo-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 20:26:22`
- 最新一轮继续深审 dispatch/direct 并发发布合同后，又确认一条新的真实 mixed-snapshot 问题：
  - `src/fafafa.core.simd.dispatch.pas` 之前让当前 active dispatch 直接指向 `g_BackendTables[backend]`，而 `RegisterBackend(...)` 会原地覆写同一 backend slot
  - 即使把 `g_CurrentDispatch` 改成 copy-out publication 也还不够，因为复制源仍来自会被另一个 writer 同时改写的 `g_BackendTables[...]`
  - 这意味着 `GetDispatchTable` / `GetDirectDispatchTable` / backend info/query/clone 仍可能在并发重注册下混读两套 table，暴露 A/B 混搭槽位
  - 为了先把合同打红，本轮先补一条独立并发 regression：
    - `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas` 新增 `TTestCase_DirectDispatchConcurrent`
    - 新增 `Test_DirectDispatchTable_Concurrent_ReRegister_SnapshotConsistency`
    - 新增 `TDirectDispatchMutationWorker` / `TDirectDispatchReadWorker`，writer 持续在两套 synthetic table A/B 间重注册，reader 在多组 field 读取之间 `ThreadSwitch`
    - 代表性 witness 槽位覆盖 `AddF32x4`、`ReduceAddF32x4`、`MemEqual`、`SumBytes`、`CountByte`、`BitsetPopCount`
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-direct-concurrent-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatchConcurrent`：FAIL
    - 初版 red 可见 A/B 混搭地址；第一次只修 current active snapshot 后，仍继续 FAIL，布尔 witness 形态表现为：
      - `Add=False/True ReduceAdd=True/False MemEqual=True/False SumBytes=True/False CountByte=True/False BitsetPopCount=True/False`
    - 这条很关键，证明 “current snapshot 从 mutable backend slot 现拷” 仍会撕裂
  - 最小修复方式：
    - 在 `src/fafafa.core.simd.dispatch.pas` 新增 `TSimdDispatchPublishedState`
    - 新增 `g_CurrentDispatchStatePtr`、`g_BackendDispatchStatePtrs`
    - 新增 `CreateDispatchPublishedState`、`PublishBackendDispatchTable`、`PublishCurrentDispatchTable`、`FinalizeDispatchPublishedStates`
    - `RegisterBackend(...)` 改为先发布 immutable backend snapshot，再标记 registered
    - `GetDispatchTable` / `GetDirectDispatchTable` / `IsBackendMarkedAvailableForDispatch` / `GetBackendInfo` / `TryGetRegisteredBackendDispatchTable` / `CloneDispatchTable` 全部切到 published snapshot 读取
    - `tests/fafafa.core.simd/BuildOrTest.sh` 与 `buildOrTest.bat` 的 cross-backend parity 现在都会额外跑 `TTestCase_DirectDispatchConcurrent`
  - fresh green / 复验证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-direct-concurrent-green-20260321d bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatchConcurrent`：PASS，`[LEAK] OK`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-direct-concurrent-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-direct-concurrent-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 19:41:15`
- 最新一轮继续深审 public ABI / concurrent contract 后，又确认一条新的真实 publication tearing：
  - `src/fafafa.core.simd.public_abi.impl.inc` 的 `RebindSimdPublicApi` 之前直接对外暴露 `g_SimdPublicApi`
  - 重绑时会先 `FillChar(g_SimdPublicApi, ...)`，再逐字段写 `StructSize/AbiVersion/ActiveBackendId/ActiveFlags`，同时还会原地改写 `g_SimdPublic*Bound`
  - 这意味着只要 reader 线程并发执行 `GetSimdPublicApi` 或通过 cached table 读 metadata，控制面 `SetVectorAsmEnabled(...)` 触发重绑时就能读到半写入 snapshot，例如 `StructSize=0`、`ActiveFlags=0`，甚至 nil shim pointer
  - 为了先把合同打红，本轮先补一条并发 regression：
    - `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `Test_Concurrent_PublicApiToggle_ReadConsistency`
    - writer 复用既有 `TVectorAsmMultiToggleWorker` 持续触发 vector-asm rebind，reader 持续断言 `GetSimdPublicApi` 的 `StructSize / AbiVersion / ActiveFlags / shim pointers` 自洽并调用 `MemEqual`
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-concurrent-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrent`：FAIL
    - 失败点直接命中 torn publication：
      - `public api StructSize torn at iter 654: expected=152 got=0`
      - `public api ActiveFlags missing registered/dispatchable/active bits at iter 0: 0`
      - 同轮还有多次 `StructSize=0` / `ActiveFlags=0`
  - 最小修复方式：
    - 将 `src/fafafa.core.simd.public_abi.impl.inc` 改为 `TSimdPublicApiBindingState` snapshot 发布模型
    - `RebindSimdPublicApi` 现在先构造完整 state，再通过 `atomic_store_ptr(..., mo_release)` 发布当前 state
    - `PublicAbiMemEqual..MinMaxBytes` shims 不再读原地改写的全局 bound pointer，而是每次从当前 published state 取 bound fast-path
    - `GetSimdPublicApi` 改为返回当前 published snapshot；旧 cached snapshot 不再被后续重绑原地覆写
    - 同步把 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 的旧 “same pointer across rebind” 假设收紧为 “cached snapshot remains callable, fresh getter returns refreshed metadata”
  - fresh green / 复验证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-concurrent-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrent,TTestCase_PublicAbi`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-concurrent-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-concurrent-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 18:16:41`
- 最新一轮继续深审 dispatch hook / forced-selection 合同后，又确认一条新的真实假成功：
  - `src/fafafa.core.simd.dispatch.pas` 的 `TrySetActiveBackend(requestedBackend)` 之前只做前置判定：requested backend 已注册、`BackendInfo.Available=True`、且 CPU/OS 支持
  - 但 `DoInitializeDispatch -> NotifyDispatchChangedHooks` 会在 API 返回前同步执行 dispatch-changed hook；hook 又可以在通知阶段通过 `RegisterBackend(...)` 触发二次重注册/重建
  - 旧实现下，只要 requested backend 在进入 `TrySetActiveBackend(...)` 时满足前置谓词，函数末尾就无条件 `Result := True`
  - 这意味着只要 hook 在通知阶段把 requested backend 改成 non-dispatchable，最终 active backend / public ABI active backend id 已经偏离 requested，调用方仍会收到 success
  - 为了先把合同打红，本轮先补两条 synthetic regression：
    - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_TrySetActiveBackend_Fails_When_HookReRegister_ReSelects_Away`
    - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicApi_ActiveBackendId_Tracks_FinalState_When_HookReRegister_Overrides_ForcedSelection`
    - 两条测试都显式 `SetVectorAsmEnabled(True)` 后取当前非 scalar active backend，再挂一个“一次 arm、二次把 requested backend 重注册成 `Available=False`” 的 hook
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-hook-reregister-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：FAIL
    - 失败点分别命中：
      - `TrySetActiveBackend should fail when a dispatch-changed hook re-registers the requested backend as non-dispatchable before the call completes`
      - `TrySetActiveBackend should fail when hook-driven re-register makes the requested backend non-dispatchable before the call completes`
  - 最小修复方式：
    - 将 `src/fafafa.core.simd.dispatch.pas` 的 `TrySetActiveBackend` 从“初始化完就返回 True”改成后验校验
    - `InitializeDispatch` 之后以 `g_CurrentDispatch^.Backend = requestedBackend` 作为 success 条件
    - 这样 hook-driven 二次重建若把最终 active backend 改成 `Scalar`，`TrySetActiveBackend(...)` 就会正确返回 `False`
  - fresh green / 复验证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-hook-reregister-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-hook-reregister-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-hook-reregister-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 17:34:56`
- 最新一轮继续深审 dispatch/public ABI 动态重注册合同后，又确认一条新的真实 identity 漂移：
  - `src/fafafa.core.simd.dispatch.pas` 的 `RegisterBackend(backend, dispatchTable)` 之前会原样保存 caller-supplied table
  - 这意味着只要动态重注册时把 `dispatchTable.Backend / dispatchTable.BackendInfo.Backend` 写错，backend slot id 和 table identity 就会分叉
  - 旧实现下，`TrySetActiveBackend(requestedBackend)` 只要前置谓词通过就会返回成功，但 `GetActiveBackend` 实际读的是 `g_CurrentDispatch^.Backend`；public ABI `GetSimdPublicApi.ActiveBackendId` 也同样绑定到当前 dispatch table 的 `Backend`
  - 结果就是：某个 slot 明明是按 `sbAVX2` 强制选中的，外部观察到的 active backend id 却会漂成 `sbScalar`
  - 为了先把合同打红，本轮先补两条 synthetic regression：
    - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_RegisterBackend_Canonicalizes_TableIdentity_For_ForcedSelection`
    - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicApi_ActiveBackendId_Tracks_RegisterSlot_After_ReRegister`
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-identity-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：FAIL
    - 失败点分别命中：
      - `Forced selection should expose the requested backend id, not the stale table Backend field`，`expected: <6> but was: <0>`
      - `Public API active backend id should track the registered backend slot, not the stale table Backend field`，`expected: <6> but was: <0>`
  - 最小修复方式：
    - 将 `src/fafafa.core.simd.dispatch.pas` 的 `RegisterBackend` 改为先生成 `LCanonicalTable`
    - 由注册槽位 id 统一回写 `LCanonicalTable.Backend := backend`
    - 同步回写 `LCanonicalTable.BackendInfo.Backend := backend` 与 `LCanonicalTable.BackendInfo.Priority := GetSimdBackendPriorityValue(backend)`
  - fresh green / 复验证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-identity-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-identity-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-register-identity-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 17:05:43`
- 最新一轮继续深审 benchmark/dispatch contract 后，又确认一条新的真实 activation 漏洞：
  - `tests/fafafa.core.simd/bench_avx512_vs_avx2.lpr`、`tests/fafafa.core.simd/bench_neon_vs_scalar.lpr`、`tests/fafafa.core.simd/bench_riscvv_vs_scalar.lpr` 之前都只用 `IsBackendAvailableOnCPU(...)` 做 gate，然后直接 `SetActiveBackend(...)`
  - 但当前 dispatch 合同里，`supported_on_cpu` 与 `dispatchable` 是明确分层语义；一旦 backend 处于 `CPU 支持但 BackendInfo.Available=False` 的 synthetic/runtime split，`SetActiveBackend(...)` 会安全 fallback，而 benchmark 标签仍会写成目标 backend
  - 这意味着旧 benchmark 程序会把“CPU 支持”误当成“真的测到了该 backend”，在 future runtime toggle / rebuild / registration drift 场景下存在真实假证据风险
  - 为了先把合同打红，本轮先在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 引入 `TryActivateBenchmarkBackend(...)` testcase；fresh red 直接命中：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`：FAIL
    - 失败点：`Identifier not found "TryActivateBenchmarkBackend"`
  - 最小修复方式：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.bench.pas` 新增共享 helper `TryActivateBenchmarkBackend(...)`，统一检查 `IsBackendAvailableOnCPU`、`IsBackendDispatchable`、`TrySetActiveBackend` 与最终 `GetActiveBackend=aBackend`
    - 将 `bench_avx512_vs_avx2.lpr`、`bench_neon_vs_scalar.lpr`、`bench_riscvv_vs_scalar.lpr` 的 backend 选择统一切到该 helper，并用 `try/finally ResetToAutomaticBackend`
  - fresh green / 复验证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-runner-20260321 bash tests/fafafa.core.simd/run_backend_benchmarks.sh`：`AVX2_vs_Scalar PASS`；`AVX512_vs_AVX2 SKIP`
    - `bench_avx512_vs_avx2.run.log` 现在明确输出：`[SKIP] AVX-512 backend is not available on this CPU`
    - `fpc -Mobjfpc -Sh -O3 ... tests/fafafa.core.simd/bench_neon_vs_scalar.lpr`：PASS
    - `fpc -Mobjfpc -Sh -O3 ... tests/fafafa.core.simd/bench_riscvv_vs_scalar.lpr`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-bench-activation-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 16:41:15`
- 最新一轮继续深审 x86 capability/dispatch contract 后，又确认一条新的真实共享谓词缺口：
  - 初始候选曾怀疑 `SSE2` rounding slot 存在大面积 `SSE4.1` masked drift，但继续读实现后确认这条不够硬：
    - `F32x8/F64x4/F32x16/F64x8` 的 floor/ceil/round/trunc 大多已经有真 `SSE2` 实现
    - 只有 `F32x4/F64x2` 仍部分依赖 scalar/common fallback，不适合作为本轮主修问题
  - 更强的真实问题在共享谓词层：
    - `src/fafafa.core.simd.cpuinfo.base.pas` 的 `X86HasAVX512BackendRequiredFeatures(...)` 之前只要求 `AVX2 + AVX512F + AVX512BW + POPCNT`
    - 但 `src/fafafa.core.simd.avx512.f32x16_fma_round.inc` / `src/fafafa.core.simd.avx512.f64x8_fma_round.inc` 的 `AVX512FmaF32x16/F64x8` 直接执行 `vfmadd213ps/pd`，没有 runtime fallback
    - 这意味着一旦遇到“`AVX512F/BW` 在，但 `FMA` 被 mask 掉”的 CPU/虚拟化环境，旧谓词会把 AVX512 backend 误判为 CPU-level supported
  - 由于当前 `qemu-x86_64` TCG 不支持可执行 `AVX512` CPUID/指令，这轮改用纯逻辑 predicate regression 取证，而不是强行做不可执行的 dynamic red
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-predicate-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86BackendPredicates`：FAIL
    - 失败点分别命中：
      - `AVX-512 backend should require FMA because AVX512FmaF32x16/F64x8 use vfmadd* directly`
      - `AVX-512 backend should require FMA even when 512-bit usable state is present`
  - 最小修复方式：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 的 `TTestCase_X86BackendPredicates` 新增 `Test_X86HasAVX512BackendRequiredFeatures_RequiresFMA`
    - 同步把既有 `Test_X86HasAVX512BackendRequiredFeatures_AVX512FOnly_Disabled` / `Test_X86SupportsAVX512BackendOnCPU_RequiresUsable512AndBackendFeatureSet` 更新到新合同
    - 将 `src/fafafa.core.simd.cpuinfo.base.pas` 的 `X86HasAVX512BackendRequiredFeatures(...)` 收紧为要求 `HasFMA=True`
  - fresh green / 复验结果：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-predicate-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86BackendPredicates`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-predicate-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-predicate-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 15:16:11`
- 最新一轮继续深审 x86 capability/dispatch contract 后，又确认一条新的真实漂移：
  - `src/fafafa.core.simd.avx2.register.inc` 已经把 `scFMA` 的宣称收紧到 `LEnableVectorAsm and HasFeature(gfFMA)`，外部 public ABI `CapabilityBits` 也会随之清掉 `scFMA`
  - 但 `RegisterAVX2Backend` 之前仍会在 `LEnableVectorAsm=True` 时无条件把 `FmaF32x4/FmaF64x2/FmaF32x8/FmaF64x4/FmaF32x16/FmaF64x8` 覆写成 `AVX2Fma*` wrapper
  - 这些 wrapper 虽然内部会在 `gfFMA=False` 时回落到 `ScalarFma*`，因此执行结果通常仍对，但 dispatch table 形状已经和 capability/public ABI 合同漂移，外部看起来像“没有 `scFMA`，却又不是 scalar FMA slots”
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx2-no-fma-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh build`：PASS
    - `qemu-x86_64 -cpu Haswell,-fma /tmp/simd-avx2-no-fma-red-20260321/bin2/fafafa.core.simd.test --suite=TTestCase_X86MaskedFmaContract`：FAIL
    - 失败点命中：`AVX2 FmaF32x4 slot should stay scalar when hardware FMA is unavailable`
  - 最小修复方式：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增独立 qemu 回归 suite `TTestCase_X86MaskedFmaContract`
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 把该 suite 接入主 runner manifest
    - 将 `src/fafafa.core.simd.avx2.register.inc` 的 6 个 `FmaF*` slot 覆写改为仅在 `LHasHardwareFma=True` 时生效，保留 `FillBaseDispatchTable(...)` 给出的 scalar FMA slots
  - fresh green / 复验结果：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx2-no-fma-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh build`：PASS
    - `qemu-x86_64 -cpu Haswell,-fma /tmp/simd-avx2-no-fma-green-20260321/bin2/fafafa.core.simd.test --suite=TTestCase_X86MaskedFmaContract`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx2-no-fma-native-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86MaskedFmaContract,TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx2-no-fma-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx2-no-fma-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 14:23:41`
- 上一轮继续深审 x86 capability contract 后，又确认一条新的真实 underclaim：
  - `src/fafafa.core.simd.sse2.pas` 已经在 `vector asm=True` 时把 `SelectF32x4/InsertF32x4/ExtractF32x4/SelectF32x8/SelectF64x4` 等代表性 shuffle 槽位接到 SSE2 非 scalar 实现，`src/fafafa.core.simd.sse3.register.inc` 也会通过 clone 链继承这些槽位
  - 但 `SSE2` 与 `SSE3` 的 capability set 之前仍只宣称 `scBasicArithmetic/scComparison/scMathFunctions/scReduction/scLoadStore(+scIntegerOps)`，漏掉了已经真实存在的 `scShuffle`
  - 这会让内部 `BackendInfo.Capabilities` 与外部 public ABI `CapabilityBits` 同步低报 x86 基线/继承链的 shuffle 能力；对外 consumer 看起来像 “SSE2/SSE3 没有 shuffle/select capability”，但 dispatch table 实际已经不是 scalar
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-shuffle-underclaim-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：FAIL
    - 失败点分别命中：
      - `scShuffle missing while representative shuffle slots are non-scalar: SSE2`
      - `Public ABI CapabilityBits missing scShuffle while representative shuffle slots are non-scalar for backend=1`
  - 最小修复方式：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_BackendCapabilities_DoNotUnderclaim_Shuffle`
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicApi_BackendPodInfo_CapabilityBits_DoNotUnderclaim_Shuffle`
    - 将 `src/fafafa.core.simd.sse2.pas`、`src/fafafa.core.simd.sse2.i386.register.inc`、`src/fafafa.core.simd.sse3.register.inc` 的 `scShuffle` 宣称补齐到现有 `IsVectorAsmEnabled` gate；`SSSE3` 已有该 bit，不做语义变更
  - fresh green / 复验结果：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-shuffle-underclaim-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-shuffle-underclaim-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-x86-shuffle-underclaim-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 05:10:26`
- 最新 public ABI backend text getter drift closeout 结果：
  - 新确认的问题在 `src/fafafa.core.simd.public_abi.impl.inc` 的 text cache，而不在 dispatch metadata 本身：
    - `RegisterBackend(...)` 会立刻更新 `GetBackendInfo(aBackend).Name/Description`
    - 但 `EnsureBackendTextCache` 之前只在 cache 为空时才填充一次
    - 结果就是外部 consumer 一旦先调用过 `GetSimdBackendNamePtr` / `GetSimdBackendDescriptionPtr`，之后即使 backend 被动态重注册，public ABI 仍会继续返回第一次观察到的旧字符串
  - fresh red：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-textcache-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
    - FAIL 命中：`Public ABI backend name getter should refresh after RegisterBackend`，`expected: <MutatedBackendName> but was: <Scalar>`
  - 最小修复方式：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicAbi_BackendText_Getters_Refresh_After_RegisterBackend`
    - 把 `src/fafafa.core.simd.public_abi.impl.inc` 的 `EnsureBackendTextCache` 改成每次 getter 调用都从最新 `GetBackendInfo(...)` 刷新 cache，而不是钉死首个观测值
  - fresh green：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-textcache-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-textcache-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-publicabi-textcache-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 04:32:13`
- 最新 pre-init `SetVectorAsmEnabled(False)` stale-dispatch closeout 结果：
  - 新确认的问题不在既有 `DispatchAPI/PublicAbi` 进程内 toggle 路径里，而在 dispatch-only consumer 的 pre-init 路径：
    - backend table 会在各 backend unit `initialization` 时按当时的 `IsVectorAsmEnabled` 发布
    - `src/fafafa.core.simd.dispatch.pas` 的 `SetVectorAsmEnabled` 之前在 `g_DispatchState = 0` 时直接 `Exit`
    - 结果就是如果 consumer 只引用 `dispatch + backend units`，并在首次 `GetBestDispatchableBackend/GetActiveBackend` 之前调用 `SetVectorAsmEnabled(False)`，表已经建好但不会重建，runtime 仍会把 `AVX2/SSE*` 当成 dispatchable
  - fresh external 最小复现证据：
    - 用只引用 `dispatch + scalar + sse2/sse3/ssse3/sse41/sse42/avx2` 的 standalone probe，在修复前得到：
      - `VectorAsm=False`
      - `Best=6`
      - `Active=6`
      - `AVX2.Available=True`
    - 这说明外部 consumer 明明已经把 vector asm 关掉，但 canonical dispatchable/active 视图仍停在 `AVX2`
  - 为避免这条路径继续只靠手工 probe 才能发现，本轮新增：
    - `tests/fafafa.core.simd/fafafa.core.simd.dispatch_preinit_smoke.pas`
    - 并把它接入 `tests/fafafa.core.simd/BuildOrTest.sh check`、shell `gate` 的 build-check 链，以及 `tests/fafafa.core.simd/buildOrTest.bat check`
  - fresh red：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatch-preinit-red2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`
    - FAIL 命中：`Best dispatchable backend should be Scalar after pre-init SetVectorAsmEnabled(False), got AVX2`
  - 最小修复方式：
    - `src/fafafa.core.simd.dispatch.pas` 的 `RebuildBackendsAfterFeatureToggle` 改为接受 `aReinitializeDispatch`
    - `SetVectorAsmEnabled` 不再在 `g_DispatchState = 0` 时直接跳过 rebuild，而是执行 `RebuildBackendsAfterFeatureToggle(g_DispatchState <> 0)`
    - 这样 pre-init toggle 也会刷新 backend table 的 `Available/capabilities/slots` 视图，但不会强行提前初始化 dispatch
  - fresh green：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatch-preinit-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - fresh external probe 重新编译后输出：
      - `VectorAsm=False`
      - `Best=0`
      - `Active=0`
      - `AVX2.Available=False`
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-dispatch-preinit-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 04:21:08`
- 最新 manual Windows closeout contract / helper runtime 修复结果：
  - `tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh` 原先虽然只是打印说明，但一直用未引用 heredoc 直接承载反引号，bash 会把 `` `win-evidence-via-gh` ``、`` `run-id` ``、`` `win-closeout-finalize` `` 等片段当成命令替换
  - 实际表现是 `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-20260320-152` 会刷出多条 `command not found` / 空白占位，说明 helper 自身一直是 runtime-broken，而不是单纯文案过时
  - 同时又确认手工 Windows closeout 文档链存在真实合同漂移：
    - `tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh`
    - `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md`
    - `docs/fafafa.core.simd.closeout.md`
    - `docs/plans/2026-02-09-simd-windows-closeout-checklist.md`
    - `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
    - `docs/plans/2026-02-09-simd-windows-postrun-fill-template.md`
    - `docs/fafafa.core.simd.handoff.md`
    - 都曾把 `evidence-win-verify -> win-closeout-finalize` 写成可直接闭环，却漏掉必需的 `FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 这是真问题，不只是“文档口气不一致”：
    - `run_windows_b07_closeout_finalize.sh` 自己只做 `finalize -> freeze-status -> apply`
    - native batch evidence 路径又明确不会生成 fresh `gate_summary.md/json`
    - 所以手工 Windows 路径如果少了 fail-close cross gate，`freeze-status` 只会继续消费旧 gate summary，无法可靠收口到 `cross-ready=True`
  - 当前已收口为两层护栏：
    - 文档/helper 对齐：所有手工 Windows closeout 入口都显式要求先跑 fail-close cross gate，再执行 `win-closeout-finalize`
    - 主线 guard：`tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_windows_manual_closeout_guard` 与 `check_windows_closeout_helper_runtime_guard`
  - 最新验证证据：
    - `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-20260320-152`：PASS，输出已包含手工路径 `2.2 回灌 cross gate` 与完整 backticked helper 文案
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-manual-closeout-guard-check-20260320-r4 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS，日志包含
      - `OK (Windows manual closeout guard present)`
      - `OK (Windows closeout helper runtime guard present)`
- 最新 Windows evidence minimum push-surface mapping：
  - `.github/workflows/simd-windows-b07-evidence.yml` 本身当前没有本地 diff；remote workflow 会先 stage 整个 `src/`、`docs/`、以及这些测试目录：
    - `tests/fafafa.core.simd`
    - `tests/fafafa.core.simd.cpuinfo`
    - `tests/fafafa.core.simd.cpuinfo.x86`
    - `tests/fafafa.core.simd.publicabi`
    - `tests/fafafa.core.simd.intrinsics.sse`
    - `tests/fafafa.core.simd.intrinsics.mmx`
    - `tests/fafafa.core.simd.intrinsics.experimental`
    - `tests/run_all_tests.bat`
    - `tests/run_all_tests.sh`
  - 第 18 轮继续下钻 `publicabi` 直接依赖后，进一步确认 Windows job 真正直接执行且会改变 fresh artifact 合同的最小 runtime-critical 改动集其实只有 4 个文件：
    - `tests/fafafa.core.simd/collect_windows_b07_evidence.bat`
    - `tests/fafafa.core.simd/verify_windows_b07_evidence.bat`
    - `tests/fafafa.core.simd.publicabi/BuildOrTest.bat`
    - `tests/fafafa.core.simd.publicabi/publicabi_smoke.ps1`
  - `tests/fafafa.core.simd.publicabi/publicabi_smoke.c` 虽然仍属于 public ABI contract 的重要 consumer harness，但当前只被 shell `tests/fafafa.core.simd.publicabi/BuildOrTest.sh` 的 Linux external smoke 链调用：
    - shell `BuildOrTest.sh test` 会 `build_project -> validate_exports -> build_harness -> run_harness`
    - 其中 `build_harness` 直接编译 `publicabi_smoke.c`
    - Windows `BuildOrTest.bat test` 则只会 `build -> resolve_powershell -> publicabi_smoke.ps1`
    - 因此 `publicabi_smoke.c` 对 Linux closeout 很重要，但不是 `simd-windows-b07-evidence.yml` 的 native batch artifact 生成链所必需
  - collector 的 `1/7..7/7` 路径是 native batch 直驱，不依赖 Linux-side helper/doc：
    - `1/7` 虽会调 `tests/fafafa.core.simd/buildOrTest.bat build`，但当前本地 `buildOrTest.bat` diff 里没有 workflow 必需的 Windows artifact 合同修复；相关大 diff 主要落在本地 guard、opt-in smoke、QEMU/summary helper、closeout wrapper 上
    - `2/7-3/7` 直接运行主 test runner `--list-suites` / `--suite=TTestCase_Vec*`
    - `4/7-5/7` 调 cpuinfo / cpuinfo.x86 子 runner
    - `6/7` 调 `tests/fafafa.core.simd.publicabi/BuildOrTest.bat test`
    - `7/7` 只写 filtered `run_all_tests_summary.txt`，当前不调用 `tests/run_all_tests.bat`
  - 这意味着当前很多 closeout 修复虽然对本地 `win-evidence-via-gh` / `freeze-status` / 文档一致性是必须的，但**不是** remote Windows artifact 生成的最小必需推送面：
    - Linux-side helper / finalize / preflight：`run_windows_b07_closeout_via_github_actions.sh`、`run_windows_b07_closeout_finalize.sh`、`finalize_windows_b07_closeout.sh`、`preflight_windows_b07_evidence_gh.sh`、`print_windows_b07_closeout_3cmd.sh`
    - local verifier / rehearsal / guard / docs：`verify_windows_b07_evidence.sh`、`simulate_windows_b07_evidence.sh`、`rehearse_freeze_status.sh`、`docs/**`
  - 对“如何从脏工作区切最小可推送 branch”的直接结论：
    - 不需要把当前未提交的 `src/fafafa.core.simd*` 大量实现改动一起带上远端，除非它们属于 Windows collector 直接依赖的真实修复
    - 若目标只是拿到 fresh `1/7..7/7` Windows artifact，当前最小候选提交面可先收敛为上面 4 个文件；`publicabi_smoke.c` 可保留在后续 Linux/public ABI contract 同步提交中，不必阻塞这轮 Windows native evidence 刷新
  - 已额外生成更精确的最小补丁工件：
    - `/tmp/simd-win-evidence-runtime-minimal.patch`
    - 当前大小：`468` 行
- 最新 simulated Windows evidence regression guard 结果：
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`：PASS
  - `SIMD_OUTPUT_ROOT=/tmp/simd-simulated-evidence-guard-check-20260320 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
  - 日志中新增 `OK (Windows simulated evidence guard present)`，说明 simulator/rehearsal 漂移已被默认 `check` 守住
- 为避免这条问题下次再次只在 dryrun/rehearsal 才暴露，本轮又补了一条主线静态 guard：
  - `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_windows_simulated_evidence_guard`
  - 它会同时检查：
    - `simulate_windows_b07_evidence.sh` 保持 `1/7..7/7` 与 `GateSummaryJson` sentinel
    - `rehearse_freeze_status.sh` 的 PASS-template cases 也保持同一 contract
    - 两个文件中都不再出现旧 `1/6` / `6/6` 标记
  - guard 已接入默认 `check` 和 `gate_step_build_check`，因此以后只要 simulator/rehearsal 再退回旧口径，日常快门禁就会先红掉
- 最新 simulated Windows evidence realignment 结果：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-dryrun`：之前 `RC=1`，报 `No rows in summary json` + verifier FAIL；修复后 PASS，输出 `DRYRUN OK: simulated summary stayed preview-only`
  - `bash tests/fafafa.core.simd/rehearse_freeze_status.sh`：之前 `RC=1`；修复后 PASS，并输出各 case 的预期非零返回
  - `bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh --allow-simulated /tmp/.../windows_b07_gate.simulated.log`：修复后 PASS
- 这轮又确认了一条真实脚本漂移，不只是文档旧描述：
  - `tests/fafafa.core.simd/simulate_windows_b07_evidence.sh` 仍生成旧的 `1/6..6/6` 模拟 log，没有 `6/7 Windows public ABI smoke`
  - `tests/fafafa.core.simd/rehearse_freeze_status.sh` 的 ready / source-fresh / simulated case 也内嵌了同样的旧模板
  - 与此同时，当前 `verify_windows_b07_evidence.sh` / `.bat` 已经按 `1/7..7/7` 验证 Windows evidence
  - 结果就是：`win-closeout-dryrun` 和 `freeze-status` rehearsal 虽然是“模拟/预演”路径，但实际上已经被真实 verifier 契约漂移打坏
- 还确认了第二层根因：
  - dryrun 默认把模拟 log 写到 `tests/fafafa.core.simd/logs/windows_b07_gate.simulated.log`
  - verifier 在没显式 summary json 参数时，会优先读取同目录 `gate_summary.json`
  - 当前仓库 `tests/fafafa.core.simd/logs/gate_summary.json` 恰好是一个简化的 `{\"status\":\"PASS\"}`，会先被 `verify_gate_summary_json.py` 判成 `No rows in summary json`
  - 所以 dryrun 之前同时受两件事影响：旧 `1/6..6/6` 模板，以及 sibling `gate_summary.json` 污染
- 已把这条 dryrun/rehearsal 漂移收口：
  - `simulate_windows_b07_evidence.sh` 现在生成 `1/7..7/7` 模拟 log，补上 `6/7 Windows public ABI smoke`
  - 同时在模拟 log 中写入一个不存在的 `GateSummaryJson` sentinel path，让 verifier 不再 fallback 到同目录真实 `gate_summary.json`
  - `rehearse_freeze_status.sh` 的 PASS-template cases 也同步升级到 `1/7..7/7`
- 这意味着当前 closeout 辅助链已经重新一致：
  - real Windows evidence：collector/verifier 走 `1/7..7/7`
  - simulated dryrun / rehearsal：也按同一 contract 预演，而不是继续用历史 `1/6..6/6`
- 最新 remote Windows evidence triage 结果：
  - `gh run list --workflow simd-windows-b07-evidence.yml --limit 10 --json ...` 显示：
    - 最新 success：`run 23087698632`，创建时间 `2026-03-14T12:11:46Z`
    - 最新 failure：`run 23089541215`，创建时间 `2026-03-14T14:08:46Z`
    - `2026-03-14 12:11:46Z` 之后到 `14:08:46Z` 之间存在多次连续 failure，因此当前并没有比 2026-03-14 更新的成功 Windows evidence
  - `gh run view 23089541215 --json jobs,...` 显示失败 job 是 `Collect Windows B07 Evidence`（job `67071702598`），失败步骤是 `Collect and Verify Windows Evidence`
  - 下载 failure run `23089541215` 的 artifact 后，得到：
    - `fafafa.core.simd/logs/windows_b07_gate.log`
    - `fafafa.core.simd/logs/gate_summary.md`
    - `fafafa.core.simd/logs/build.txt`
    - `fafafa.core.simd/logs/test.txt`
    - `run_all_tests_summary.txt`
  - artifact 内的 `windows_b07_gate.log` 明确还是旧口径：
    - `[GATE] 1/6 ... 6/6`
    - `publicabi-smoke=0`
    - `cross-backend parity` 仍重复执行 `TTestCase_DispatchAPI`
  - 用当前 `verify_windows_b07_evidence.sh` 直接复验该 artifact：
    - 返回 `RC=1`
    - 报告缺少 `[GATE] 1/7` 到 `[GATE] 7/7` 全套模式，尤其缺 `6/7 Windows public ABI smoke`
- 这说明最新远端 failure 并不是“当前工作区引入了新的未知 Windows 回归”，而是 GitHub 上最近可用 artifact 仍来自 `2026-03-14` 的旧 6-step collector / verifier 契约。
- 因此当前主路径结论变得更明确：
  - 现在已经能安全复用既有 `run-id`
  - 但历史 success/failure run 都不能充当最终 closeout 证据
  - 要真正清掉 Windows native evidence pending，必须先把当前修复推到远端 ref，再派发 fresh `simd-windows-b07-evidence.yml` run，生成新的 `1/7..7/7` artifact
- 最新 Windows evidence existing-run reuse hardening 结果：
  - `bash -n tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh`：PASS
  - `bash -n tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh`：PASS
  - synthetic harness（fake `gh/git/bash`，dirty worktree + remote mismatch，同时显式传 `run-id=424242`）：
    - `REUSE_RC=0`
    - 日志包含 `Reuse existing workflow run: 424242`、`Verify downloaded evidence`、`Backfill cross gate`、`Run closeout finalize`
  - 同一 synthetic harness 下，不传 `run-id` 直接走 dispatch：
    - `DISPATCH_RC=2`
    - 日志包含 `Refuse dispatch: local worktree has uncommitted changes.`
  - 更强 synthetic harness（把 `git` 改成“只要被调用就 `exit 88`”）：
    - 显式 `run-id` 仍 `REUSE_NOGIT_RC=0`
    - 日志未出现 `UNEXPECTED_GIT_CALL`
- 本轮继续深审 Windows evidence 主路径后，又确认一条显式 `run-id` 复用的真实阻塞：
  - `tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh` 原先在读取 `RUN_ID_INPUT` 之后、进入 dispatch 分支之前，就无条件执行 `git status` dirty worktree 检查和 `remote ref != local HEAD` 检查
  - 同一段顶部初始化还会无条件执行 `git branch --show-current`、`git rev-parse`、`git ls-remote`
  - 这会把“只想消费既有 GH workflow run、下载 artifact、复验 closeout”的旁路错误耦合到 dispatch-only hygiene 约束上，导致本地仍在修脚本时即使手里有现成 `run-id` 也无法继续
- 已将这个缺口收口为真正的 branch-specific 语义：
  - `run_windows_b07_closeout_via_github_actions.sh` 现在只有在 `LRunId` 为空、准备 dispatch 新 workflow 时，才会要求 `git` 存在，并执行 `ref/sha` 解析、dirty worktree 检查和 remote/local 一致性检查
  - 若显式传入 `run-id`，脚本会直接打印 `Reuse existing workflow run: <id>`，随后进入 `wait -> download -> verify -> backfill cross gate -> finalize`
  - 这让“复用已有 Windows artifact 收口当前 Linux closeout”与“从当前本地分支派发新 Windows runner”两条路径重新解耦
- runbook / 3cmd helper 已同步更新：
  - `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md` 现在明确写出 `win-evidence-via-gh <batch-id> <run-id>` 的复用途径，并注明它不会再因为本地 dirty worktree / remote ref mismatch 被误拒
  - `tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh` 也同步提示可复用现成 `run-id`
- 最新 Windows evidence preflight hardening 结果：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`：PASS，输出 `workflow=simd-windows-b07-evidence.yml, repo=dtamade/fafafa.core, note=no failed run in 24h window`
  - `bash -n tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`：PASS
  - synthetic `gh` harness（failed run + `gh run view` 含 `Recent account payments have failed.`）：`RC=31`，输出 `STATUS=FAIL CODE=RECENT_BILLING_BLOCK`
  - synthetic `gh` harness（failed run + Windows job `check_run_url` annotations 含 `Job was not started because spending limit needs to be increased.`）：`RC=31`，输出 `STATUS=FAIL CODE=RECENT_BILLING_BLOCK`
  - synthetic `gh` harness（无 run history）：`RC=0`，输出 `STATUS=PASS CODE=OK`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight --help`：PASS
- 本轮继续深审 Windows evidence 链后，确认 `win-evidence-preflight` 还有一条会把真实阻塞误判成 PASS 的风险：
  - 旧实现只扫描最近 failed run 的 Windows job annotations，而且直接把 Actions `job id` 手拼成 `check-runs/<job-id>/annotations`
  - 一旦 billing / quota block 只出现在 `gh run view` 文本里，或者 jobs API 给出了 `check_run_url` 但 `job id == check_run_id` 这个隐含假设不成立，preflight 就可能放过本应 fail-close 的 `RECENT_BILLING_BLOCK`
- 已把 preflight 收紧为两层探测：
  - `tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh` 现在先扫 `gh run view <run-id>` 文本里的 billing/runner block 关键词
  - 若 run view 没命中，再读取 `actions/runs/<id>/jobs` 返回的 `check_run_url`，规范化成 API endpoint 后去取 annotations；只有缺少 `check_run_url` 时才回退旧的 `check-runs/<job-id>` 拼接路径
  - 这让 `win-evidence-via-gh` 在 dispatch 前更容易提前 fail-close，避免把已知 GitHub Billing/runner 阻塞误当成“可以继续派发 Windows runner”
- 最新 non-x86 opt-in compile smoke closeout 结果：
  - `SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-optin-action-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh nonx86-optin-list-suites`：PASS
  - `SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-optin-check-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
  - `SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-optin-gate-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS
  - `SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-optin-action-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh clean` 后 `find /tmp/simd-nonx86-optin-action-20260320 -mindepth 1 -maxdepth 3`：无输出
- 本轮又确认了一条 shell gate / check 的真实 coverage gap：
  - 之前虽然已有 `check_nonx86_optin_runner_guard` 静态守卫，也手动跑过 targeted `NEON/RISCVV` opt-in suite
  - 但默认 `check` 和 shell `gate_step_build_check` 本身并不会 fresh 编译 `SIMD_ENABLE_NEON_BACKEND=1` / `SIMD_ENABLE_RISCVV_BACKEND=1` 的 `test --list-suites`
  - 这意味着像前几轮出现过的 non-x86 opt-in compile/preprocessor drift，仍可能重新躲过日常门禁，直到有人手动运行 opt-in 路径
- 已将这个缺口收口为默认门禁的一部分：
  - `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `nonx86-optin-list-suites` action，在 `SIMD_OUTPUT_ROOT/nonx86.optin/{neon,riscvv}` 下 fresh 运行两条 opt-in `test --list-suites`
  - shell `check` 与 `gate_step_build_check` 现在都会执行这条 smoke，因此默认快门禁已能直接打到 non-x86 opt-in compile drift
  - `tests/fafafa.core.simd/buildOrTest.bat` 同步新增对应 action、`check` 接线与 `nonx86.optin` clean 覆盖；`check_windows_runner_parity` / `check_nonx86_optin_runner_guard` 也同步更新，避免 batch 接线静默漂移
- 最新 non-x86 runtime-toggle rebuild closeout 结果：
  - green: `SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-toggle-default2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
  - green: `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-toggle-neon2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
  - green: `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-nonx86-toggle-riscvv2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
  - green: `SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260320-nonx86-toggle bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS
- 最新 non-x86 capability symmetry closeout 结果：
  - red: `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-red3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：FAIL，命中 `NEON should not advertise scFMA when only scalar/common fallback FMA slots are compiled`
  - red: `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-red3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：FAIL，命中 `RISCVV should not advertise scShuffle when only scalar/common fallback shuffle slots are compiled`
  - green: `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-green3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
  - green: `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-green3-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
  - green: `SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260320-nonx86-cap3 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS
- 最新 non-x86 registration/capability closeout 结果：
  - red: `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-red2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：FAIL，命中 `NEON should not advertise scShuffle when only scalar fallback shuffle slots are compiled`
  - red: `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-red2-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：FAIL，命中 `RISCVV should not advertise scFMA when only scalar fallback FMA slots are compiled`
  - green: `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-capability-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
  - green: `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-capability-green-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
  - green: `SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260320-nonx86-registration-fixes bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS
- 本轮又确认了一条比 compile blocker 更深的验证盲区：
  - `SIMD_ENABLE_NEON_BACKEND=1` / `SIMD_ENABLE_RISCVV_BACKEND=1` 之前只会把 backend 单元编进主 test binary
  - 但 `src/fafafa.core.simd.neon.register.inc` 仍要求 `FAFAFA_SIMD_NEON_ASM_ENABLED + CPUAARCH64/CPUARM` 才注册，`src/fafafa.core.simd.riscvv.register.inc` 仍要求 `CPURISCV*` 才注册
  - 因此 x86_64 opt-in build 上 `TryGetRegisteredBackendDispatchTable(sbNEON/sbRISCVV)` 会直接失败，旧 testcase 里的 `if not TryGet... then Exit;` 让 suite 看起来是绿的，实际上根本没验证到 metadata
- 为了让非原生主机上的 opt-in suite 真正覆盖 dispatch/public ABI，本轮给 shell/batch runner 补了测试专用 define：
  - `FAFAFA_SIMD_TEST_REGISTER_NEON_BACKEND`
  - `FAFAFA_SIMD_TEST_REGISTER_RISCVV_BACKEND`
  - 并让两个 backend 在这些 define 打开时注册 scalar/common fallback 版本进入 dispatch，再由 testcase 显式断言 “opt-in test registration should be present”
- 真正进入注册态后，确认之前新增的两条 non-x86 capability expose 结论是假的：
  - `NEON` 在非 asm 构建下仍注册了 backend，但 representative shuffle slots 来自 scalar fallback，因此不该宣称 `scShuffle`
  - `RISCVV` 在非 asm 构建下仍注册了 backend，但 representative FMA slots 来自 scalar/common fallback，因此不该宣称 `scFMA`
  - 已把 `src/fafafa.core.simd.neon.register.inc` 的 `scShuffle` 和 `src/fafafa.core.simd.riscvv.register.inc` 的 `scFMA` 都改成跟随真实 asm 可用性
- 继续做对称审查后，又确认此前还剩两处同类 overclaim：
  - `NEON` 在非 asm 构建下虽然 `FmaF32x4/FmaF32x8/FmaF64x2/FmaF64x4` 都已注册，但实现来自 `neon.scalar.ext_math.inc` / `neon.scalar.autowrap.inc` 的 scalar/common fallback，因此不该继续宣称 `scFMA`
  - `RISCVV` 在非 asm 构建下虽然 `Select/Insert/ExtractF32x4` 等 shuffle 族已注册，但实现来自 `riscvv.facade.inc` 的 scalar/common fallback，因此不该继续宣称 `scShuffle`
  - 已补 `DispatchAPI` 与 `PublicAbi` 对称 red tests，并把 `src/fafafa.core.simd.neon.register.inc` 的 `scFMA`、`src/fafafa.core.simd.riscvv.register.inc` 的 `scShuffle` 都改成仅在对应 asm 宏可用时加入 capability set
- 再往下一层查 runtime toggle / rebuild 合同后，确认 `NEON/RISCVV` 还有一条不同于 x86 的 stale-state 风险：
  - 两个 backend 的 asm/fallback 主体仍然是编译期单路径，不像 `AVX2/SSE41/...` 那样在 register.inc 里同时拥有 runtime-gated fast path 与 fallback clone
  - 但它们又已经注册了 `RegisterBackendRebuilder(...)`，所以在 native asm build 上执行 `SetVectorAsmEnabled(False)` 时，旧实现会“重建同一张 asm-backed table”，而不是切回 scalar-backed dispatch
  - 已将 `src/fafafa.core.simd.neon.register.inc` 与 `src/fafafa.core.simd.riscvv.register.inc` 改成：仅当 asm capable 且 runtime 开启时才保留 asm-backed registration；若 asm capable 但 runtime disabled，则重建为 `FillBaseDispatchTable(...)` 的 scalar-backed table，并清掉 `scFMA/scShuffle` 这些 runtime-gated capability bits
  - 同时新增 native-only regression tests：
    - `TTestCase_DispatchAPI.Test_NEON_BackendCapabilities_Clear_VectorAsmGatedBits_When_VectorAsmDisabled`
    - `TTestCase_DispatchAPI.Test_RISCVV_BackendCapabilities_Clear_VectorAsmGatedBits_When_VectorAsmDisabled`
    - `TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_NEONVectorAsmGatedBits_WhenVectorAsmDisabled`
    - `TTestCase_PublicAbi.Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_RISCVVVectorAsmGatedBits_WhenVectorAsmDisabled`
  - 当前 x86_64 主机无法真实执行这些 native asm 路径，因此本轮拿到的是“编译 + 现有回归链不退化”的证据；真正的 native execution evidence 仍需后续在 arm64 / riscv64 asm-ready 主机上回收
- 最新 non-x86 opt-in closeout 结果：
  - `SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-optin-suite-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
  - `SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-optin-suite-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
  - `SIMD_OUTPUT_ROOT=/tmp/simd-gate-20260320-nonx86-optin-fixes bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS
- `RISCVV` opt-in 的真实 blocker 不是行为错误，而是 `src/fafafa.core.simd.riscvv.facade.inc` 的条件编译骨架写坏了：
  - `{$IFDEF RISCVV_ASSEMBLY}` 分支里把 `{$ENDIF}` 提前放在 `{$ELSE}` 之前
  - 文件尾同时缺真正的 `{$ENDIF}` 收口
  - 最小修复后，opt-in `DispatchAPI/PublicAbi` suite 直接转绿，说明这轮没有继续暴露实现层 bug
- `NEON` opt-in 的真实 blocker 是跨 include 的条件编译边界漂移，而不是 capability regression 本身：
  - `src/fafafa.core.simd.neon.pas` 打开了 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`，但主单元没有显式在本文件收口
  - `src/fafafa.core.simd.neon.scalar_fallback.inc` 同时混放了纯 scalar fallback、`scalar.autowrap.inc` 以及 `_ASM` wide helper includes，依赖额外 `{$ENDIF}` 从 include 内偷关父级条件块
  - `src/fafafa.core.simd.neon.scalar.wide_reduce.inc` 自己还缺少 `{$ENDIF}`
  - 将主单元显式收口、把 `scalar.autowrap` 移到 IFNDEF 外、让 wide helper 只在 asm-enabled 时编译后，opt-in suite 转绿
- `docs/fafafa.core.simd.md` 给出的结构是：`fafafa.core.simd` facade -> `dispatch` -> backend 实现（scalar/sse2/avx2/neon...）-> `base/cpuinfo/memutils` 基础设施。
- `docs/fafafa.core.simd.checklist.md` 明确建议日常维护先跑：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- `docs/fafafa.core.simd.cpuinfo.md` 显示 `cpuinfo` 对外契约包括 `GetCPUInfo`、`IsBackendSupportedOnCPU`、`GetSupportedBackendList`、`GetBestSupportedBackend`、`ResetCPUInfo`。
- `tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh` 支持 `check|test|release`，默认 `test` 也会先 build + 检查日志 + 跑测试。
- `tests/fafafa.core.simd.publicabi/BuildOrTest.sh` 额外校验导出符号和 C harness，可作为后续稳定性审查面。
- 当前工作区存在大量与 `simd` 直接相关的未提交修改，包括：
  - `src/fafafa.core.simd.cpuinfo.pas`
  - `src/fafafa.core.simd.cpuinfo.backends.impl.inc`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.testcase.pas`
  - 删除的 `src/fafafa.core.simd.sse2.register.inc`
  - 新增未跟踪脚本 `tests/fafafa.core.simd/check_backend_register_include_consistency.py`
- `tests/fafafa.core.simd/BuildOrTest.sh` 默认 `MODE="${FAFAFA_BUILD_MODE:-Release}"`，且 `check` 的价值不只是编译，还包括稳定 `src/` warning/hint 检查。
- `docs/fafafa.core.simd.checklist.md` 已将 `backend_slot_counts` 下降`/`include 漂移列为首要排查项之一，这与当前工作区里 `sse2.register.inc` 被删除、新增 register consistency 检查脚本形成直接关联。
- 首轮行为验证结果：
  - `SIMD_OUTPUT_ROOT=/tmp/simd-review-main-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
  - `SIMD_OUTPUT_ROOT=/tmp/simd-review-dispatch-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`：PASS
  - `SIMD_OUTPUT_ROOT=/tmp/simd-review-direct-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch`：PASS
  - `SIMD_OUTPUT_ROOT=/tmp/simd-review-publicabi-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`：PASS
  - `SIMD_OUTPUT_ROOT=/tmp/simd-review-cpuinfo-20260320 bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test`：PASS
- 最新 full closeout 复验结果：
  - `SIMD_OUTPUT_ROOT=/tmp/simd-evidence-linux-escalated-full-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux`：PASS（提权环境）
  - `gate PASS @ 2026-03-20 12:36:58`
  - `qemu-cpuinfo-nonx86-evidence PASS @ 2026-03-20 12:36:58`
  - `freeze-status-linux`: `ready=True, mainline-ready=True`
  - 同一次 closeout 中，`evidence-verify` 对 `tests/fafafa.core.simd/logs/windows_b07_gate.log` 的旧模式校验仍是 optional `SKIP`，这说明当前剩余问题是 Windows 新鲜证据缺口，而不是 Linux 代码回归
- 主 `simd` runner 并不直接消费 `testregistry` 里的 `RegisterTest(...)` 结果，而是由 `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 的 `ProcessAllSuites -> HandleSuite(...)` 手工维护 suite manifest。
  - 这意味着“类里已经 `RegisterTest`”不等于“主 runner 的 `--list-suites` / `--suite=` 一定可达”。
  - 当前默认 `src/fafafa.core.settings.inc` 仍关闭 `SIMD_BACKEND_AVX512`，所以把纯逻辑 CPU 谓词测试塞进 `{$IFDEF SIMD_BACKEND_AVX512}` 的 suite，会在默认 x86_64 构建里被整个吞掉。
  - 已将纯逻辑回归拆到新的 `TTestCase_X86BackendPredicates`，让它在默认 x86_64 主 runner 中可达；依赖 AVX-512 backend 注册表的 dispatch-table 测试继续留在 `TTestCase_AVX512BackendRequirements` 的宏门后。
- 虽然关键 suite 全绿，但 runner 代码审查发现 `cross-backend parity` 路径是复制错误：
  - `tests/fafafa.core.simd/BuildOrTest.sh` 的 `gate_step_cross_backend_parity` 连续执行两次 `TTestCase_DispatchAPI`
  - `tests/fafafa.core.simd/buildOrTest.bat` 的 `:parity_suites` 与 gate 对应段也重复执行 `TTestCase_DispatchAPI`
  - 这与维护清单中“dispatch / direct 两个关键回归 suite”不一致，会让 `DirectDispatch` 回归在 gate/parity-suites 中被静默漏检
- 第二轮 runner 审查发现另一个结构问题：
  - shell runner 当前有 53 个 action，batch runner 有 47 个 action
  - 差集里既有明确 shell-only helper（如 `evidence-linux`、`freeze-status*`、`gate-summary-selfcheck`、`win-closeout-dryrun`、`win-closeout-snippets`、`win-evidence-via-gh`），也有 Windows-only alias（`evidence-win`、`evidence-win-verify`）
  - 但 `check_windows_runner_parity` 之前只做手写字符串匹配，不做 action 集合对账，所以即使将来新增 action 漏同步，也可能继续误报为“parity signatures present”
- 第三轮沿“四层后端状态语义”继续下钻后，确认 external public ABI smoke 存在真实 coverage 缺口：
  - `src/fafafa.core.simd.public_abi.impl.inc` 已把 `supported_on_cpu / registered / dispatchable / active / experimental` 填进 `TFafafaSimdBackendPodInfo.Flags`，并把当前 backend 的 flags 写进 `TFafafaSimdPublicApi.ActiveFlags`
  - Pascal 层 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 已对所有 backend 的 flags、自洽关系和 `GetSimdPublicApi` 元数据刷新做了断言
  - 但 external consumer harness `tests/fafafa.core.simd.publicabi/publicabi_smoke.c` 与 `publicabi_smoke.ps1` 之前只校验了 scalar backend 的 `registered` bit、ABI version/signature 和 data-plane function pointer，几乎没有消费 `ActiveFlags`，也没有对 active backend pod flags 做 consumer-side 对账
  - 这意味着 public ABI 文档承诺的四层语义如果只在 external wrapper/consumer 侧发生漂移，Pascal 层可能仍然全绿，而 external smoke 无法及时打红
- 第四轮继续审 alias 语义后，确认还有一处门禁缺口：
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 里虽然分别测试了 `BackendInfo.Available=False` 不可选、`GetSupportedBackendList` 自洽、`GetAvailableBackendList` 别名 dispatchable 视图
  - 但它们之前没有组合成一个“强制制造 supported_on_cpu != dispatchable”的回归场景
  - 在大多数常见机器上，CPU 支持的后端也往往正好已注册且可派发，所以如果 future regression 把 façade 的 `GetSupportedBackendList` / cpuinfo 的 `GetAvailableBackends` 错误绑到 dispatchable 视图，普通绿机上可能继续静默通过
- 第五轮继续下钻 public ABI 动态语义后，确认实现链本身是通的，但回归护栏缺口仍然存在：
  - `src/fafafa.core.simd.dispatch.pas` 的 `RegisterBackend` 在 dispatch 已初始化时会立即 `InitializeDispatch`，而 `InitializeDispatch` 结束后会调用 dispatch-changed hooks
  - `src/fafafa.core.simd.public_abi.impl.inc` 里的 `RebindSimdPublicApi` 已挂在 dispatch-changed hook 上，因此理论上 `RegisterBackend` 触发的重选应该立刻刷新 `TFafafaSimdPublicApi.ActiveBackendId/ActiveFlags`
  - 但 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 之前只测了 `TrySetActiveBackend` / `ResetToAutomaticBackend` 路径，没有覆盖 “当前 active backend 被重新注册为 `Available=False` 后，public ABI flags 和 backend pod flags 是否立即刷新”
  - 这不是当前实现 bug，而是缺少一条能守住 `RegisterBackend -> reselect -> RebindSimdPublicApi` 的动态 regression guard
- 第六轮继续静态审查 Windows public ABI runner 后，确认还有一处 native batch gate 假绿风险：
  - `tests/fafafa.core.simd.publicabi/BuildOrTest.bat` 之前只探测 `powershell`，对 `pwsh` 无感知
  - 更严重的是，`validate-exports` 与 `test` 在找不到 `powershell` 时都会 `SKIP` 并返回 `0`
  - `docs/fafafa.core.simd.publicabi.stability.md` 又明确把 `tests\\fafafa.core.simd.publicabi\\BuildOrTest.bat test` 列为 Windows external smoke 验证层之一，所以这种 `SKIP 0` 会让 native batch `publicabi-smoke` / `gate` 在缺失 runtime 的机器上静默漏掉 external smoke
  - `tests/fafafa.core.simd/BuildOrTest.sh` 之前也没有任何静态 guard 去约束这个 Windows public ABI runner 的行为
- 第七轮继续沿隔离输出语义审查后，确认 `publicabi-smoke` 还存在并发/预演污染风险：
  - `docs/fafafa.core.simd.checklist.md` 与 `docs/fafafa.core.simd.maintenance.md` 都把 `SIMD_OUTPUT_ROOT` 描述为并发跑多个 SIMD helper / dry-run closeout 时的隔离根
  - 主 `simd` shell / batch runner 都已经把 `cpuinfo`、`cpuinfo.x86` 子 runner 映射到 `OUTPUT_ROOT/cpuinfo`、`OUTPUT_ROOT/cpuinfo.x86`
  - 但 `tests/fafafa.core.simd.publicabi/BuildOrTest.sh` 与 `BuildOrTest.bat` 之前都只写固定的模块目录 `bin` / `lib` / `logs`
  - `tests/fafafa.core.simd/BuildOrTest.sh` 的 `publicabi-smoke` gate artifacts 也硬编码到默认 `tests/fafafa.core.simd.publicabi/logs/test.txt`
  - 这意味着即使主 gate 带了 `SIMD_OUTPUT_ROOT=/tmp/...`，`publicabi-smoke` 仍会把 external smoke 产物落回默认目录，和并发预演的文档承诺不一致
- 第八轮继续审隔离输出的回收语义后，确认主 `clean` 还存在真实闭环缺口：
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-clean-gap-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` 后，再执行同根 `clean`，`find /tmp/simd-clean-gap-20260320 -mindepth 1 -maxdepth 2` 仍残留顶层 `bin/`、`lib/`，以及 `cpuinfo/`、`cpuinfo.x86/`、`publicabi/`
  - 根因是主 shell / batch runner 的 `clean` 之前只删除自己的 `bin2/lib2/logs`
  - 但 `gate` 的 direct 子 runner 会把产物写进 `cpuinfo/`、`cpuinfo.x86/`、`publicabi/`，而 `run_all_tests` 过滤链又会继承同一个 `SIMD_OUTPUT_ROOT`，额外生成顶层 `bin/`、`lib/`
  - 这会让隔离根在预演后无法彻底回收，削弱 `SIMD_OUTPUT_ROOT` 作为并发/closeout 沙箱的价值
- 第九轮继续顺着 `run_all_tests` 过滤链下钻后，确认还有一个更直接的 artifact 污染问题：
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-runall-log-clobber-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate` 后，顶层 `/tmp/.../logs/build.txt` 已变成 `fafafa.core.simd.cpuinfo.x86.test` 的构建日志
  - 同一时刻顶层 `/tmp/.../logs/test.txt` 仍然保留着 `fafafa.core.simd` façade suite 的测试结果
  - 这说明 `gate` 的 artifact 根里，`build.txt` 与 `test.txt` 已经不再属于同一个步骤/模块，证据包内部自相矛盾
  - 根因是 `gate_step_filtered_run_all` 调用 `tests/run_all_tests.sh` 时直接继承了同一个 `SIMD_OUTPUT_ROOT`，而 `run_all_tests.sh/.bat` 之前没有按模块拆分子根，导致 `fafafa.core.simd`、`cpuinfo`、`cpuinfo.x86` 在过滤链里共享顶层 `logs/`
- 针对上一轮 intrinsics isolation 修复，我又做了顺序 `gate -> clean -> find` 复验，确认此前“clean 后仍残留”的怀疑只是并发观测竞态：
  - fresh 运行 `SIMD_OUTPUT_ROOT=/tmp/simd-intrinsics-clean-recheck-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS
  - 随后顺序执行同根 `clean`
  - 最后 `find /tmp/simd-intrinsics-clean-recheck-20260320 -mindepth 1 -maxdepth 4 | sort` 无输出，说明 `run_all/`、`publicabi/`、`cpuinfo*` 和顶层 `bin/lib/logs` 均被正常回收
- 第十轮继续静态审查 Windows `run_all` 过滤链后，又确认一处真实 batch-only 语义漂移：
  - `tests/fafafa.core.simd/buildOrTest.bat` 的 gate 路径在 filtered run_all 前明确 `set "RUN_ACTION=check"`
  - shell 版 `tests/run_all_tests.sh` 会先计算 `local action="${RUN_ACTION:-test}"`，再执行 `bash "./$(basename "$script")" "$action"`
  - 但 batch 版 `tests/run_all_tests.bat` 的 `:run_one` 之前仍是裸 `call "%SCRIPT%"`，既没有从 `RUN_ACTION` 生成默认 action，也没有把 action 显式传给模块脚本
  - 结果是 Windows filtered run_all 会静默回落到各模块默认 action，而不是像 shell 版那样稳定执行 `check`，这会让 batch `gate` 的第 6 步与设计语义发生偏移
- 第十一轮继续沿 helper 隔离语义下钻后，又确认 `experimental-intrinsics-tests` 仍有真实输出污染缺口：
  - `tests/fafafa.core.simd/BuildOrTest.sh` 的 `run_experimental_intrinsics_tests` 之前只是直接 `bash "${LRunner}" test-all`，没有给 experimental 子 runner 显式传 `SIMD_OUTPUT_ROOT`
  - `tests/fafafa.core.simd/buildOrTest.bat` 的 `:experimental_intrinsics_tests` 之前也只是直接 `bash "%EXPERIMENTAL_TESTS_RUNNER%" test-all`
  - direct 子 runner `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh` 与 `buildOrTest.bat` 之前都把 `BIN_DIR/LIB_DIR/LOG_DIR` 固定在模块目录自身
  - 运行证据也吻合这一点：`SIMD_OUTPUT_ROOT=/tmp/simd-experimental-isolation-gap-20260320 bash tests/fafafa.core.simd/BuildOrTest.sh experimental-intrinsics-tests` 时，日志直接打印 `tests/fafafa.core.simd.intrinsics.experimental/logs/*.pas`，隔离根里只有主 runner 自己的 `bin2/lib2/logs`，而默认 experimental `logs/build.txt`、`logs/test.txt` 和多个 smoke 源文件 mtime 被更新
- 第十二轮继续静态审查 Windows experimental 主入口后，又确认一处 batch-only 假绿风险：
  - `tests/fafafa.core.simd/buildOrTest.bat` 的 `gate-strict` 明确 `set "SIMD_GATE_EXPERIMENTAL_TESTS=1"`，说明 release-gate 口径把 experimental tests 视为启用项
  - 同一个 batch runner 的 `:experimental_intrinsics_tests` 在缺 `bash` 时之前却是 `echo [EXPERIMENTAL-TESTS] SKIP (bash not found)` 并返回 `0`
  - shell 版 `require_release_gate_prereqs` 已把“开启 `SIMD_GATE_EXPERIMENTAL_TESTS` 时缺 `bash`”视为前置失败；batch 版 direct action 若继续 `SKIP 0`，就会在手动调用 `experimental-intrinsics-tests` 或手动打开 `SIMD_GATE_EXPERIMENTAL_TESTS=1` 的场景里制造假绿
  - 现阶段 native batch experimental 子 runner 也还没有补齐 shell runner 的 hygiene/backend smoke parity，因此更不能把缺 `bash` 的情况静默视为成功
- 第十三轮继续下钻 direct Windows experimental 子 runner 后，又确认一处更隐蔽的 parity 假绿入口：
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh` 的 `check`/`test`/`test-all` 会执行 `check_source_hygiene`，并覆盖 `x86/mmx/sse/sse3/avx/avx2/avx512/fma3` smoke
  - 但 `tests/fafafa.core.simd.intrinsics.experimental/buildOrTest.bat` 之前仍是独立的 native `build_core/check_build_log/run_tests` 实现，只做最基本的编译、日志和 leak 检查
  - docs / roadmap 公开引用的实验入口依旧是 `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test-all`，没有把 direct batch runner 承诺为稳定入口
  - 这意味着 direct batch runner 如果继续保留“看起来能跑、但语义比 shell runner 弱”的实现，就会形成新的 Windows-only 假绿旁路
- 第十四轮继续审 Windows closeout evidence 链后，又确认一处 runbook/collector/verifier 三方不一致：
  - `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md` 已明确承诺 `collect_windows_b07_evidence.bat` / `buildOrTest.bat evidence-win-verify` 默认优先走 native batch gate，以避免静默绕开 Windows 自己的 `publicabi-smoke`
  - 但 `tests/fafafa.core.simd/collect_windows_b07_evidence.bat` 之前的 native collector 实际只有 `1/6..6/6` 六步：build/check、suite list、AVX2 fallback、cpuinfo、cpuinfo.x86、filtered run_all；完全没有 `publicabi-smoke`
  - 更糟的是，`tests/fafafa.core.simd/verify_windows_b07_evidence.bat` 与 `.sh` 在缺 `gate_summary.json` 时仍只要求旧的 `6/6 Filtered run_all chain` 标记，因此这条缺关键 external smoke 的旧 evidence log 仍可能被 verifier 接受
  - 这会把“文档以为 native batch 路径已覆盖 Windows public ABI smoke、实际证据链没覆盖”的状态静默包装成有效 closeout evidence
- 第十五轮继续审 `gate-summary` helper 后，又确认一组低频 direct-action 假绿入口：
  - `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md` 明确写着 Windows 脚本层具备 `gate-summary-sample` / `gate-summary-rehearsal` 入口，`docs/.../intrinsics_coverage_workflow.md` 也直接给了 Windows 调用示例
  - 但 `tests/fafafa.core.simd/buildOrTest.bat` 之前在缺 runtime 时仍是：
    - `gate-summary-sample` -> `SKIP (python runtime not found)`
    - `gate-summary-rehearsal` -> `SKIP (bash not found)`
    - `gate-summary-inject` -> `SKIP (python runtime not found)`
  - 这些并不是 gate 内部的“可选步骤”，而是显式 helper 入口；继续返回 `0` 会把“根本没执行样本生成/阈值演练/注入预演”伪装成成功
- 第十六轮继续审 Windows `qemu-*` direct actions 后，确认又一组非 x86 证据入口存在同类假绿：
  - `tests/fafafa.core.simd/buildOrTest.bat` 的 usage 直接暴露了 `qemu-nonx86-evidence`、`qemu-cpuinfo-nonx86-evidence/full-evidence/full-repeat/suite-repeat`、`qemu-arch-matrix-evidence`、`qemu-nonx86-experimental-asm`
  - 这些 label 之前全部共享同一模式：先检查 `docker\\run_multiarch_qemu.sh` 是否存在，然后在缺 `bash` 时输出 `echo [QEMU] SKIP (bash not found)` 并返回 `0`
  - 与此同时，`docs/CI.md`、`docs/fafafa.core.simd.cpuinfo.md` 和 `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md` 都把对应 QEMU evidence 当成真实的 shell 验证路径；即使这些文档主要展示 shell 命令，batch usage 既然公开暴露同名 action，就不能把“未执行 QEMU”包装成成功
  - 这意味着 Windows 维护者若直接调用这些 batch actions，在缺 `bash` 的机器上会得到假绿，进而误判 non-x86 evidence / arch matrix / experimental asm 证据已经生成
- 第十七轮沿同一模式继续审 `backend-bench` / `riscvv-opcode-lane` 后，又确认两条 bash-wrapper helper 仍是假绿：
  - `tests/fafafa.core.simd/buildOrTest.bat` 的 usage 同样公开暴露了 `backend-bench` 与 `riscvv-opcode-lane`
  - 这两个 label 之前也都是“脚本存在 -> 缺 `bash` 时 `SKIP 0` -> 否则直接 `bash script`”的薄封装
  - 对照 shell runner，`run_backend_bench()` 与 `run_riscvv_opcode_lane()` 都是直接执行对应 shell 脚本，并没有“缺 `bash` 也算成功”的语义；同时文档里已经存在 backend benchmark summary 与 RVV opcode lane 的证据引用
  - 因此 batch 侧继续 `SKIP 0` 只会把“benchmark / RVV lane 根本没跑”误判成维护入口成功执行
- 第十八轮继续审 `qemu-experimental-report` / `qemu-experimental-baseline-check` 后，确认它们在 shell/batch 两侧都仍是假绿：
  - `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md` 已把这两个 helper 作为独立 closeout 命令列出，并关联 `experimental_asm_blockers.md` 与 expected-failures baseline
  - 但 shell runner 之前在缺 `python3` 时直接 `SKIP (python3 not found)` 返回 `0`；batch runner 之前在 `py` / `python` 都缺失时也会 `SKIP (python runtime not found)` 并返回 `0`
  - 这不是 gate 内的“未开启可选步骤”，而是维护者主动调用的显式 helper；继续静默成功会把 experimental asm 归因报告或 baseline 校验根本没执行的状态包装成完成
  - 因为 shell guard 与实现写在同一个文件里，新增静态检查时还暴露了一个二次问题：如果直接在整个 `BuildOrTest.sh` 上搜旧 `SKIP` 文案，guard 会命中自己的禁止列表文本，必须收窄到真实函数体范围
- 第十九轮把问题继续下钻到主 `check` / `gate` 默认依赖的 Python checker 后，确认这里存在更高优先级的假绿：
  - `docs/fafafa.core.simd.maintenance.md` 明确写着 `check` 负责“默认启用的轻量静态检查”，`gate` 默认包含 `contract-signature` / `publicabi-signature` 等结构护栏；`docs/fafafa.core.simd.closeout.md` 又把 `adapter-sync` / `wiring-sync` / `coverage` 作为 closeout 结构证据的一部分
  - 但 shell runner 之前的 `run_register_include_check`、`run_interface_completeness`、`run_dispatch_contract_signature`、`run_public_abi_signature`、`run_backend_adapter_sync`、`run_coverage`、`run_intrinsics_experimental_status`、`run_wiring_sync` 在缺 `python3` 时都返回 `0`
  - batch runner 对应的 `register_include_check`、`interface_completeness`、`contract_signature`、`publicabi_signature`、`adapter_sync`、`coverage`、`experimental_intrinsics`、`wiring_sync` 也都是 `py/python` 都缺失时 `SKIP 0`
  - 这意味着不只是 direct helper 会误导维护者，连默认 `check` 和默认 `gate` 都可能在缺 Python 的机器上继续绿掉，直接把结构护栏静默绕开
- 第二十轮继续审 `publicabi` 子 runner 后，又确认一处独立 direct-action 假绿：
  - `docs/fafafa.core.simd.publicabi.md` 把 `bash tests/fafafa.core.simd.publicabi/BuildOrTest.sh validate-exports` 明确描述为“只验证导出符号”的显式入口，并说明 `test` 也会先做导出符号校验
  - 但 `tests/fafafa.core.simd.publicabi/BuildOrTest.sh` 之前在 `readelf` 与 `nm` 都不存在时会输出 `echo "[EXPORT] SKIP (readelf/nm not found)"` 并返回 `0`
  - 这不会像前一轮那样直接把主 `check` / `gate` 放绿，但会把 `validate-exports` 或 `test` 中“导出符号已校验”的结论说得过强，尤其在极简 Linux 环境或定制容器里可能直接掩盖工具链缺失
  - 该问题与 Windows `publicabi` batch runner 已经收紧成 fail-close 的语义也不一致，形成 Linux/Windows 对同一显式 helper 的行为漂移
- 第二十一轮继续下钻 `gate-summary` JSON 导出链后，确认这里仍有一处显式 helper 假绿：
  - `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md` 直接把 `SIMD_GATE_SUMMARY_JSON=1` 描述成 machine-readable 摘要导出能力，`tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md` 也把 Linux/Windows JSON 导出列为已具备的 closeout 能力
  - 但 `tests/fafafa.core.simd/BuildOrTest.sh` 之前的 `write_gate_summary_json()` 在缺 `python3` 时会输出 `SKIP JSON export (python3 not found)` 并返回 `0`
  - 更糟的是，`run_gate_summary()` 在调用该函数后还会继续打印 `echo "[GATE-SUMMARY] json=..."`，于是显式打开 `SIMD_GATE_SUMMARY_JSON=1` 的维护者会同时看到“未导出 JSON”和“json 路径已生成”这组自相矛盾的假成功信号
  - `tests/fafafa.core.simd/buildOrTest.bat` 的 `gate_summary` JSON 分支也存在同类问题：`py` / `python` 都缺失时输出 `SKIP JSON export (python runtime not found)` 后仍然 `exit /b 0`
  - 由于 shell guard 与实现共享同一文件，这条静态约束也必须像前面的 QEMU experimental helper 一样限定在真实函数体 / JSON block 范围内，避免 guard 自命中旧 `SKIP` 文案
- 第二十二轮继续下钻 `perf-smoke` closeout 证据链后，确认这里也存在一条更隐蔽的假绿：
  - `docs/fafafa.core.simd.checklist.md` 已明确写着若要把 `perf-smoke` 纳入 closeout 门禁，应显式设置 `SIMD_GATE_PERF_SMOKE=1`，或者直接走 `evidence-linux`
  - `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md` 又进一步说明 `evidence-linux` 内部固定启用了 `SIMD_GATE_PERF_SMOKE=1`，并把 `perf-smoke` 放进 `gate-strict` 摘要口径；release checklist 也明确记录了 `perf-smoke` 通过（non-scalar backend healthy）
  - 但 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_perf_log()`、`tests/fafafa.core.simd/buildOrTest.bat` 的 `:perf_smoke`、以及 `tests/fafafa.core.simd/check_perf_smoke_log.py` 之前都把 `/Scalar)` 视为 `SKIP` 并返回 `0`
  - `run_gate_step()` 对 perf-smoke 只看返回码；只要 helper 返回 `0`，`gate-strict` / `evidence-linux` 就会把这一步写成 `PASS`。这意味着“没有拿到 SIMD 性能证据”的 Scalar 场景会被 gate 摘要和 closeout 证据链误包装成成功
- 最新一轮继续深审 non-x86 capability/dispatch 合同后，又确认一条和前面 `scFMA/scShuffle` 同型的真实 overclaim：
  - `src/fafafa.core.simd.neon.register.inc` 与 `src/fafafa.core.simd.riscvv.register.inc` 之前把 `scIntegerOps` 绑定成“非 asm 或 vector asm 开启都算”，导致 non-asm build、test-only registration fallback，甚至 native asm build 里 `SetVectorAsmEnabled(False)` 之后仍会继续对外宣称整数向量能力
  - 这和实际 dispatch 状态不一致：这些路径下代表性整数槽位已经来自 scalar/common fallback，不应再把 scalar integer 路径包装成 vector integer capability
  - 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 补 `NEON/RISCVV scIntegerOps` 合同测试，并把 native runtime-disabled 路径扩到检查 `SetVectorAsmEnabled(False)` 后 `scIntegerOps` 必须清零
  - 最小修复是把两处 register.inc 的 `scIntegerOps` 宣称统一收紧为仅在 `LUseVectorAsm=True` 时成立；这样 non-asm fallback、test-only registration 和 runtime-disabled rebuild 三条路径都会回到与真实 dispatch 一致的 capability 视图
  - fresh 验证结果：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_NEON_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-neon-intops-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_RISCVV_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-riscvv-intops-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-intops-check2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-intops-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，日志最终为 `[GATE] OK @ 2026-03-21 00:40:00`
- 最新一轮继续深审 x86 runtime-toggle/rebuild 合同后，又确认一条新的真实 drift：
  - `src/fafafa.core.simd.avx512.register.inc` 之前完全忽略 `IsVectorAsmEnabled`，无论 runtime `vector asm` 是否关闭，都会继续覆写 native AVX512 宽槽位，并静态宣称 `scFMA/scIntegerOps/scMaskedOps/sc512BitOps`
  - 这导致 `SetVectorAsmEnabled(False)` 后，`AVX512` 的 `BackendInfo.Capabilities` 与 public ABI `CapabilityBits` 仍高报向量宽能力，同时 dispatch table 里的 `FmaF32x16/AddU32x16` 等 representative slots 也不会回退到 fallback
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-vectorasm-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：FAIL
    - 失败点分别命中：
      - `AVX512 FmaF32x16 should fall back to scalar when vector asm is disabled`
      - `Public ABI CapabilityBits should clear AVX512 scFMA when vector asm is disabled`
  - 最小修复方式：
    - `src/fafafa.core.simd.avx512.register.inc` 新增 `LEnableVectorAsm := IsVectorAsmEnabled`
    - 仅在 `LEnableVectorAsm=True` 时覆写 AVX512 native slots，并加入 `scFMA/scIntegerOps/scMaskedOps/sc512BitOps`
    - `vector asm=False` 时保留 clone/base fallback table，避免 stale AVX512 dispatch/public ABI
  - 这轮还顺手暴露了一条测试层假设漂移：多条 AVX512 正向测试一直默认“native path 总是打开”，之前之所以是绿的，是依赖了上面这条 bug；现已把这些 testcase 改成显式 `SetVectorAsmEnabled(True)` 后再验证 native slot/capability
  - fresh green / 复验结果：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-vectorasm-green2-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-vectorasm-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-vectorasm-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 02:15:21`
- 最新一轮继续深审 x86 capability contract 后，又确认一条新的真实 underclaim：
  - `src/fafafa.core.simd.avx512.register.inc` 虽然在 `vector asm=True` 时已经把 `SelectF32x16` / `SelectF64x8` 覆写到 AVX512 原生实现，但 capability set 仍漏掉 `scShuffle`
  - 这会让内部 `BackendInfo.Capabilities` 与外部 public ABI `CapabilityBits` 同步低报 shuffle 能力；对外 consumer 看起来像“AVX512 没有 wide select/shuffle capability”，但 dispatch table 实际已经不是 scalar/fallback
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-shuffle-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：FAIL
    - 失败点分别命中：
      - `AVX512 should advertise scShuffle once wide select slots are non-scalar`
      - `Public ABI CapabilityBits should expose AVX512 scShuffle when wide select slots are non-scalar`
  - 最小修复方式：
    - 在 `src/fafafa.core.simd.avx512.register.inc` 的 `if LEnableVectorAsm then` gated capability block 中补 `Include(Capabilities, scShuffle)`
    - 保持 `vector asm=False` 时不宣称该 bit，因此 `True -> False` 重建后 public ABI / dispatch capability 仍会一起清零
  - 同时把 AVX512 clear-path 测试扩到 `scShuffle`，确保 runtime toggle 不会再次留下 stale shuffle capability
  - fresh green / 复验结果：
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-shuffle-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-shuffle-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-shuffle-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 02:51:22`
- 最新一轮继续深审 x86 capability/dispatch contract 后，又确认一条新的真实 execution-gate 漂移：
  - `src/fafafa.core.simd.cpuinfo.pas` 的 `HasAVX512` 与 `src/fafafa.core.simd.intrinsics.pas` 的 `simd_has_avx512f` 仍是 raw usable AVX512F 语义：只要求 `AVX512F + OS/XCR0` 可用
  - 但 `IsBackendSupportedOnCPU(sbAVX512)` / `X86SupportsAVX512BackendOnCPU(...)` 已经是 backend-ready 语义，当前要求 `AVX2 + AVX512F + AVX512BW + POPCNT + FMA + usable 512-bit state`
  - `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 里多处 AVX512 direct helper / vector-asm 测试此前仍直接拿 `HasAVX512` 做执行 gate；`tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.testcase.pas` 也还把 AVX512 backend presence 绑定到 `simd_has_avx512f`
  - 这在 “raw usable AVX512F 在，但 backend 所需 `AVX512BW/POPCNT/FMA` 缺失” 的 CPU/虚拟化场景下会漂移：
    - direct helper 侧会把 `MemEqual_AVX512/MemFindByte_AVX512/SumBytes_AVX512/CountByte_AVX512/MinMaxBytes_AVX512/BitsetPopCount_AVX512` 误当成可执行
    - cpuinfo test/bench report 侧会把 raw usable feature 误读成 backend-ready support
  - fresh red 证据：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-red-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86BackendPredicates`：FAIL
    - 失败点命中：`Direct AVX-512 execution gates must require backend-supported feature set, not just raw usable AVX512F`
  - 最小修复方式：
    - 在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 引入 `X86AllowsDirectAVX512Execution(...)`，并把它收口到 `X86SupportsAVX512BackendOnCPU(...)`
    - `BackendConsistency` 里的 AVX512 direct helper guard 改为 current-CPU backend-ready 语义
    - `AVX512VectorAsm` suite 的 runtime gate 改为 `IsBackendDispatchable(sbAVX512)` 口径
    - `tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.testcase.pas` 的 AVX512 backend presence 断言改为 backend-supported predicate，不再绑定 `simd_has_avx512f`
    - `tests/fafafa.core.simd/bench_avx512_vs_avx2.lpr` 的 report 改为同时区分 `AVX-512 Backend Support` 与 `Usable AVX-512F`
  - fresh green / 复验结果：
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-green-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86BackendPredicates`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-cpuinfo-20260321 bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_Global,TTestCase_PlatformSpecific`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-optin-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendConsistency,TTestCase_AVX512VectorAsm`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-check-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh check`：PASS
    - `FAFAFA_BUILD_MODE=Release SIMD_ENABLE_AVX512_BACKEND=1 SIMD_OUTPUT_ROOT=/tmp/simd-avx512-gate-gate-20260321 bash tests/fafafa.core.simd/BuildOrTest.sh gate`：PASS，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 15:45:37`
- 当前宿主机依旧没有 `avx512*` flags，因此这轮拿到的是 AVX512 raw-vs-backend 语义护栏、opt-in build 和 regression 证据，不是 native AVX512 指令执行证据

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| 先按维护清单跑 simd 快门禁，再决定是否扩大到 gate-strict | 能更快区分“立即可修”与“重型环境/矩阵问题” |
| 重点关注 `dispatch`、`cpuinfo`、脚本/文档契约一致性 | 这三处最容易产生用户可见回归和维护误判 |
| 本轮优先修 runner 覆盖缺口，而不是继续扩展更多随机 suite | 这是已经确认的真实 gate 漏检点，修复收益高且风险低 |
| shell/bat 差集不要求全部消灭，但必须被 parity checker 显式记账 | 这能区分“故意 Linux-only/Windows-only”与“忘了同步” |
| public ABI smoke 的增强点放在 consumer-side 元数据断言，而不是改 public ABI 本身 | 实现层和 Pascal 测试层已经有四层语义，真实缺口是 external smoke 没把承诺消费出来 |
| benchmark 程序选择 backend 时也必须显式证明“真的激活了目标 backend” | `supported_on_cpu` 只说明 CPU/OS 能力，`SetActiveBackend(...)` 在 backend 不可 dispatch 时会安全 fallback；如果 benchmark 不校验 active backend，就会把标签和实际测量对象混在一起 |
| alias 语义的增强点放在 `DispatchAPI` 强制分叉测试，而不是改实现 | 当前实现本身没发现错误，真正缺的是把 `supported_on_cpu` 与 `dispatchable` 人为拉开后的 regression guard |
| public ABI 动态 flags 的增强点放在 `TTestCase_PublicAbi`，而不是 external smoke | external harness 适合校验 consumer contract，不适合进程内篡改 backend registry 并观察 hook 驱动的即时重绑 |
| Windows public ABI batch runner 采用 `pwsh -> powershell` fallback，并在两者都缺失时 fail-close | 这能同时覆盖现代 PowerShell Core 环境，并避免把 native Windows external smoke 静默降级成假绿 |
| 新增 `check_windows_publicabi_runner_guard` 并接入 `simd check` / `gate` 的 build-check | 当前 Linux 环境不能执行 PowerShell，需要一个可持续运行的静态护栏来守住 Windows runner 接线 |
| `publicabi` 隔离输出语义采用与 `cpuinfo` 相同的子目录策略 | 当主 runner 使用隔离根时，把 external smoke 放到 `OUTPUT_ROOT/publicabi` 最直观，也最符合现有 `cpuinfo` / `cpuinfo.x86` 口径 |
| 为 `publicabi` 隔离输出新增静态守卫，而不是只靠文档约束 | 这个问题主要发生在 shell/batch 脚本接线层，最稳的是把父 runner 传播和子 runner 目录约束都纳入 `check` |
| 主 `clean` 在隔离根下同时删除顶层 `bin/lib` 与 `cpuinfo/cpuinfo.x86/publicabi` | 这批目录都属于同一次 isolated run 的真实产物集，不一并清掉就会留下假残留 |
| 为 `clean` 新增 shell 侧静态守卫 `check_isolated_clean_coverage` | 当前 Linux 环境更适合用 shell guard 持续约束 shell/batch 两个 runner 的 `clean` 覆盖面，避免未来继续只修一侧 |
| `run_all_tests` 在 `SIMD_OUTPUT_ROOT` 打开时，对 simd 系模块使用 `run_all/<module>/` 子根 | 这是最小侵入的隔离方式，既不改主 gate 的顶层 artifact 口径，也能把 `run_all` 过滤链产生的 build/log/test 文件完全剥离出来 |
| `run_all_tests` 隔离修复完成后，主 `clean` 同时回收 `run_all/` | 否则新的隔离子树会再次变成 clean 残留，形成半修复状态 |
| 为 `run_all_tests` 隔离补 `check_run_all_output_isolation` 静态守卫 | 当前 Linux 环境无法执行 batch 版 `run_all_tests.bat` 全链路，所以需要 shell guard 持续守住两侧接线 |
| Windows `run_all_tests.bat` 的 action 传递语义直接对齐 shell 版 | 让 batch 侧显式执行 `RUN_ACTION:-test`，比依赖各模块默认 action 更稳，也能保证 `gate` 的 filtered run_all 在 shell/batch 两侧语义一致 |
| 把 batch `RUN_ACTION` 转发约束并入现有 `check_run_all_output_isolation` | 当前环境无法实跑 Windows batch，全靠 Linux 上的静态 guard 守住 `run_all` 两侧接线；把“子根隔离”和“action 转发”放在同一守卫里最直接 |
| experimental tests 在隔离根下使用专用 `intrinsics.experimental` 子目录 | 这条 helper 会产出默认/experimental 两轮 smoke 源、日志和二进制；单独放在 `intrinsics.experimental/` 下最容易和 `cpuinfo` / `publicabi` / `run_all` 现有模式保持一致 |
| experimental tests 的输出隔离与 clean 覆盖一起纳入静态 guard | 当前环境无法实跑 Windows batch，所以要用 shell `check` 同时守住主传播、direct shell/bat 子 runner 以及主 clean 对 `intrinsics.experimental/` 的回收 |
| Windows experimental tests 入口先做 fail-close，再考虑 native batch parity | 当前最紧急的风险是 `bash not found -> SKIP 0` 假绿；相比直接切到能力不等价的 native batch runner，先把缺 runtime 变成显式失败更稳 |
| 为 Windows experimental tests 增加独立静态 guard | 这条风险不属于普通 action 集 parity，而是 batch 主入口的运行时策略问题；单独守卫更清晰，也更容易持续约束 `SKIP 0` 不得回归 |
| direct Windows experimental batch runner 改为 shell canonical wrapper | 既然文档和主 runner 都把 `BuildOrTest.sh` 当成唯一 authoritative 路径，就不应该再维护一套缺 hygiene/backend smoke 的 batch 实现；薄包装 + fail-close 能最小成本封住 direct batch 假绿 |
| 为 direct Windows experimental batch runner 增加独立静态 guard | 当前 Linux 环境不能执行 batch，所以需要 shell `check` 去强制约束 wrapper 形态，并禁止未来把 `build_core/check_build_log/run_tests` 弱语义本地实现偷偷加回来 |
| Windows native evidence collector 必须把 `publicabi-smoke` 纳入 evidence log，而不能只靠 runbook 文案声明 | closeout/verifier 最终消费的是 `windows_b07_gate.log`；如果关键 external smoke 不在日志里，就不应把这份 evidence 视为 Windows public ABI 路径已覆盖 |
| Windows evidence verifier 要拒绝旧 `6/6` collector 日志 | 只有把 fallback step 校验升级到 `1/7..7/7`，旧的“无 public ABI smoke” evidence 才不会继续被误判为有效 |
| 为 Windows evidence collector 增加独立静态 guard | 当前 Linux 环境不能执行 Windows collector，所以需要 shell `check` 持续守住 collector + shell verifier + batch verifier 三边契约，防止 future regression 再次漏掉 `publicabi-smoke` |
| Windows `gate-summary-sample` / `gate-summary-rehearsal` / `gate-summary-inject` 这类显式 helper 入口必须 fail-close | 它们不是 gate 里的可选 step，而是维护者主动调用的工具；缺 python/bash 时返回 `0` 只会制造“预演已完成”的错觉 |
| 为 Windows gate-summary helper 增加独立静态 guard | 当前 Linux 环境不能实跑 batch helper，所以需要 shell `check` 去守住这几个入口的 fail-close 策略，并禁止旧 `SKIP 0` 文案回归 |
| Windows `qemu-*` batch direct actions 统一改成共享 helper 的 fail-close 语义 | 这 7 个入口本质上都是 shell `docker/run_multiarch_qemu.sh` 的薄封装，最稳的做法是统一依赖同一个 `bash` 运行时检查，而不是让每个入口继续各自 `SKIP 0` |
| 为 Windows qemu batch 行为增加独立静态 guard，而不是只靠现有 runner parity | `check_windows_runner_parity` 负责动作集和关键签名对账，不适合单独表达“QEMU direct action 缺 bash 必须失败”这类运行时策略；单独 guard 更清晰，也便于持续禁止旧 `QEMU SKIP` 文案回归 |
| Windows `backend-bench` / `riscvv-opcode-lane` 也按 bash-wrapper helper 收紧为 fail-close | 这两个入口和 `qemu-*` 一样，本质上只是 batch 对 shell 脚本的包装；缺运行时时返回成功没有任何正当语义，只会制造假绿 |
| 为 bench/RVV helper 增加合并静态 guard | 它们共享同一类“公开暴露的 bash-wrapper helper”约束，用一个 `check_windows_bash_helper_runner_guard` 同时守住两条入口，比继续把要求散落在 parity 签名里更容易维护 |
| `qemu-experimental-report` / `qemu-experimental-baseline-check` 在 shell/batch 两侧统一改为 fail-close | 这两个动作直接产出 closeout 归因报告与 baseline 校验结果，缺 Python 时返回成功没有任何可接受的语义 |
| QEMU experimental Python helper 的静态 guard 必须限定在真实函数体/runner 文件范围内 | 这类 guard 的禁止字符串与 guard 自己共处同一文件；如果直接对整文件做负向匹配，会产生自命中假红 |
| 主 `simd` runner 中默认启用的 Python checker 一律 fail-close | 既然这些 checker 已经被 `check` / `gate` / closeout 文档定义为默认护栏，缺 Python 时就不应当继续返回成功；否则门禁的“通过”不具备可信度 |
| 为默认 Python checker 增加合并静态 guard | 这批 checker 横跨 shell 函数与 batch action，且都属于同一类“缺运行时不得假绿”的契约；用一个 guard 统一守住更稳，也便于后续继续扩展 |
| `publicabi` shell runner 的 `validate-exports` 在缺符号检查工具时必须 fail-close | 既然文档把它定义为“校验导出符号”的显式入口，就不能在 `readelf/nm` 都缺失时继续给出成功返回码 |
| 为 `publicabi` shell export guard 单独加静态检查 | 这个问题发生在子 runner，不属于主 runner 的 Python/Bash helper 类；独立 guard 更容易表达“shell publicabi validate-exports 不能 silent skip”这一契约 |
| 显式启用 `SIMD_GATE_SUMMARY_JSON=1` 后，`gate-summary` JSON 导出必须 fail-close | 这是维护者主动开启的 machine-readable export 模式，不是“没开可选步骤”；缺 Python 仍返回成功只会把未导出的摘要伪装成可消费证据 |
| 为 `gate-summary` JSON 导出增加独立静态 guard，并同时约束 shell 函数与 batch JSON block | 当前 Linux 环境不能实跑 Windows batch；同时 shell guard 与实现共处一个文件，必须用函数体级检查才能防止自命中假红 |
| 显式启用 `perf-smoke` 后，Scalar backend 必须 fail-close | 文档和 closeout 证据链都把 perf-smoke 当成“拿到非 scalar SIMD 性能证据”的显式动作；如果 active backend 仍是 Scalar，就不应继续返回成功 |
| 为 `perf-smoke` 增加独立静态 guard，并同时约束 shell/batch/Python 三处实现 | 当前 Linux 环境无法实跑 Windows batch perf 路径；而 perf 的核心判定同时散落在 shell fallback、batch direct helper 和 Python checker，必须一起守住，才能防止 future regression 只修一侧 |
| Linux 侧以 fresh isolated `evidence-linux` 作为本轮收口标准 | 单条 targeted replay 只能证明某一段链路；只有 full closeout `rc=0` 且同时覆盖 gate、QEMU CPUInfo non-x86、freeze-status，才能证明 Linux closeout 已重新闭环 |
| 对 runtime-gated backend 而言，`dispatchable/active` 语义必须跟随真实可派发向量槽位，而不是只看“backend 仍已注册” | 一旦 `SetVectorAsmEnabled(False)` 把代表性槽位重建成 scalar-backed table，继续保留 `BackendInfo.Available=True` 只会让 `GetCurrentBackend` / public ABI `ActiveBackendId` 漂移到陈旧 backend id |
| backend/public smoke 对 active backend 的预期必须基于 `IsBackendDispatchable`，不能继续基于 `HasFeature + IsBackendRegistered` | `registered` 只说明二进制里有这张表，不说明它在当前 CPU/OS 和 runtime toggle 状态下真的可选；把 smoke 建在 registered 语义上会把 stale active backend 漏成假绿 |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| 当前工作区是脏的，不能假设问题只来自历史稳定代码 | 后续只做最小修复，不回退用户已有改动 |
| direct/current dispatch 并发修复第一版只把 active snapshot 改成 copy-out publication，但 targeted red 仍继续失败 | 回到 mixed witness 读数后确认复制源仍来自 mutable backend slot；随后补 backend-level immutable publication，并把 backend info/query/clone 一并切到 published snapshot，fresh targeted suite/check/gate 全部通过 |
| 并发 red 初版在 helper 抽离时把 testcase 断言遗留在非 testcase 上下文，导致先遇到编译失败而不是并发 red | 收口为 worker 只收集 mixed-state 证据、由 testcase 统一断言；随后重新跑 targeted suite，拿到真正的并发 red 再做根因修复 |
| gate/parity-suites 的 cross-backend parity 实际没有覆盖 `DirectDispatch` | 已在 shell/bat runner 中把第二个 suite 改为 `TTestCase_DirectDispatch`，并用 `check`、`parity-suites`、`gate` 复验通过 |
| `check_windows_runner_parity` 对 shell/bat action 差集无感知 | 已在 `BuildOrTest.sh` 中加入 `collect_*_runner_actions` + allowlist 对账，并用静态检查与 `check` 复验通过 |
| external public ABI smoke 没有覆盖 `ActiveFlags` / active backend pod flags 的 consumer 语义 | 已在 `publicabi_smoke.c` 和 `publicabi_smoke.ps1` 中补上 scalar baseline、active backend flags、name/description、pod-vs-public-api metadata 对账，并用静态检查、Linux smoke、主 `gate` 复验通过 |
| `supported_on_cpu` 与 `dispatchable` 的 alias 语义缺少“强制分叉”回归保护 | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增回归测试，显式把当前 active backend 标记为 `BackendInfo.Available=False`，随后断言 CPU-only 视图保持不变，而 dispatchable / available 视图收缩，并用 `DispatchAPI` suite 与主 `gate` 复验通过 |
| backend benchmark 程序之前只看 CPU support，没有验证目标 backend 是否真的被激活 | 已在 `tests/fafafa.core.simd/fafafa.core.simd.bench.pas` 新增 `TryActivateBenchmarkBackend(...)`，并让 `bench_avx512_vs_avx2.lpr`、`bench_neon_vs_scalar.lpr`、`bench_riscvv_vs_scalar.lpr` 统一走 helper；同时在 `DispatchAPI` 新增 synthetic split 回归测试，并用 fresh `DispatchAPI`、fresh backend bench runner、fresh `check`、fresh `gate` 复验通过 |
| public ABI Pascal tests 缺少 `RegisterBackend -> reselect -> RebindSimdPublicApi` 动态刷新护栏 | 已在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增回归测试，验证 active backend 被重新注册为 non-dispatchable 后，`GetSimdPublicApi` 的 `ActiveBackendId/ActiveFlags` 与 backend pod flags 会同步刷新，并用 `TTestCase_PublicAbi` suite 与主 `gate` 复验通过 |
| Windows public ABI batch runner 只认 `powershell` 且缺失时静默 `SKIP 0`，会让 native batch `publicabi-smoke` 假绿 | 已在 `tests/fafafa.core.simd.publicabi/BuildOrTest.bat` 改成 `pwsh -> powershell` fallback + fail-close，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_windows_publicabi_runner_guard`，随后用静态检查、fresh `check`、fresh `gate` 复验通过 |
| `publicabi-smoke` 不遵守 `SIMD_OUTPUT_ROOT`，会让并发/预演 run 污染默认 external smoke 产物目录 | 已在 `tests/fafafa.core.simd.publicabi/BuildOrTest.sh` 与 `BuildOrTest.bat` 增加 `OUTPUT_ROOT` 支持，在主 shell/batch runner 把 `publicabi-smoke` 映射到 `OUTPUT_ROOT/publicabi`，并新增 `check_publicabi_output_isolation`；随后用静态失败检查、isolated `publicabi-smoke`、fresh `check`、fresh `gate` 复验通过 |
| 主 `clean` 在隔离根下没有回收 `bin/lib/cpuinfo/cpuinfo.x86/publicabi`，导致 isolated run 后仍残留产物 | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 抽出 `run_clean` 并覆盖完整目录集，在 `tests/fafafa.core.simd/buildOrTest.bat` 做等价修复，并新增 `check_isolated_clean_coverage`；随后用 fresh `check`、fresh `gate` 和 `gate -> clean -> find` 复验通过，隔离根已清空 |
| `run_all_tests` 过滤链会覆盖顶层 gate `build.txt`，使 `build.txt`/`test.txt` 指向不同模块 | 已在 `tests/run_all_tests.sh` 与 `tests/run_all_tests.bat` 增加 simd 模块专用的 `run_all/<module>/` 子根隔离，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_run_all_output_isolation`；随后用 fresh `check`、fresh `gate` 复验，确认顶层 `logs/build.txt` 回到 `fafafa.core.simd.test` 构建日志，而 `run_all` 产物落到 `run_all/fafafa.core.simd*`，最后 `clean` 也已能回收 `run_all/` |
| `tests/run_all_tests.bat` 忽略 `RUN_ACTION`，会让 Windows filtered run_all 回退到模块默认 action，而不是设计要求的 `check` | 已在 `tests/run_all_tests.bat` 增加 `ACTION=%RUN_ACTION%` / `if not defined ACTION set "ACTION=test"` / `call "%SCRIPT%" "!ACTION!"`，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_run_all_output_isolation` 中追加 action-forwarding guard；随后用静态检查、fresh `check`、fresh `gate` 复验通过 |
| `experimental-intrinsics-tests` 不遵守 `SIMD_OUTPUT_ROOT`，会让 experimental smoke 产物和二进制污染默认模块目录 | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 和 `buildOrTest.bat` 增加 `intrinsics.experimental` 子根传播，在 `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh` 与 `buildOrTest.bat` 接入 `OUTPUT_ROOT` 语义，并把主 `clean` 扩到 `intrinsics.experimental/`；随后用 isolated `experimental-intrinsics-tests`、fresh `check` 和 `clean -> find` 复验通过，默认模块目录 mtime 未再变化 |
| Windows `experimental-intrinsics-tests` 在缺 `bash` 时静默 `SKIP 0`，会让 batch direct action 与手动 experimental gate 配置出现假绿 | 已在 `tests/fafafa.core.simd/buildOrTest.bat` 把该分支改成 fail-close，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_windows_experimental_tests_runner_guard`；随后用静态检查和 fresh `check` 复验通过 |
| direct Windows experimental batch runner 自带弱语义 `check/test/test-all`，缺 shell canonical runner 的 hygiene/backend smoke | 已在 `tests/fafafa.core.simd.intrinsics.experimental/buildOrTest.bat` 改成 canonical shell wrapper，仅保留本地 `clean`；同时在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_windows_experimental_direct_runner_guard`，随后用 fresh `check` 复验通过 |
| Windows native closeout evidence collector 漏跑 `publicabi-smoke`，而两个 verifier 仍接受旧 `6/6` evidence log | 已在 `tests/fafafa.core.simd/collect_windows_b07_evidence.bat` 把 native collector 升为 `1/7..7/7` 并补 `6/7 Windows public ABI smoke`，同时在 `tests/fafafa.core.simd/verify_windows_b07_evidence.bat` 与 `.sh` 把 fallback step 校验同步升级；再在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_windows_evidence_collector_guard`，随后用静态检查和 fresh `check` 复验通过 |
| Windows `gate-summary-sample` / `gate-summary-rehearsal` / `gate-summary-inject` 在缺 runtime 时静默 `SKIP 0` | 已在 `tests/fafafa.core.simd/buildOrTest.bat` 把三者改成 fail-close，并在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 `check_windows_gate_summary_helper_guard`；随后用静态检查和 fresh `check` 复验通过 |
| Windows `qemu-*` direct actions 在缺 `bash` 时静默 `SKIP 0`，会把 non-x86/QEMU 证据伪装成成功 | 已在 `tests/fafafa.core.simd/buildOrTest.bat` 抽出 `:require_qemu_bash_runtime`，让 7 个 `qemu-*` 入口统一在缺 `bash` 时 `exit /b 2`；同时在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_windows_qemu_runner_guard`，并同步更新 `check_windows_runner_parity` 的 QEMU 签名预期，随后用 fresh `check` 复验通过 |
| Windows `backend-bench` / `riscvv-opcode-lane` 在缺 `bash` 时静默 `SKIP 0`，会把 benchmark/RVV lane 误判成已执行 | 已在 `tests/fafafa.core.simd/buildOrTest.bat` 为两者分别补 `:require_backend_bench_bash_runtime` / `:require_rvv_lane_bash_runtime`，改成缺 `bash` 时 `exit /b 2`；同时在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_windows_bash_helper_runner_guard` 并同步更新 `check_windows_runner_parity`，随后用 fresh `check` 复验通过 |
| `qemu-experimental-report` / `qemu-experimental-baseline-check` 在 shell/batch 两侧缺 Python 时静默 `SKIP 0`，会把归因报告/基线校验误判成已完成 | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 把两条 shell helper 改成缺 `python3` 时 `return 2`，在 `tests/fafafa.core.simd/buildOrTest.bat` 把两条 batch helper 改成 `py/python` 都缺失时 `exit /b 2`，并新增 `check_qemu_experimental_python_helper_guard`；首次静态 guard 因自命中旧字符串而假红，收窄到函数体后 fresh `check` 复验通过 |
| 默认 Python checker 在 shell/batch 两侧缺运行时时静默 `SKIP 0`，会把 `check` / `gate` / closeout 结构护栏误判成已执行 | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 把 `register-include`、`interface-completeness`、`contract-signature`、`publicabi-signature`、`adapter-sync`、`coverage`、`experimental-intrinsics`、`wiring-sync` 的 shell helper 统一改成缺 `python3` 时 `return 2`，在 `tests/fafafa.core.simd/buildOrTest.bat` 把对应 action 统一改成 `py/python` 都缺失时 `exit /b 2`，并新增 `check_python_checker_runtime_guard`；随后用 fresh `check` 复验通过 |
| `publicabi` shell runner 的 `validate-exports` 在缺 `readelf/nm` 时静默 `SKIP 0`，会把导出符号已校验误判成成立 | 已在 `tests/fafafa.core.simd.publicabi/BuildOrTest.sh` 把该分支改成 `FAILED (readelf/nm not found; validate-exports requires a symbol inspection tool)` 并返回非零，同时在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_publicabi_shell_export_guard`；随后用 fresh main `check` 与 direct `publicabi validate-exports` 复验通过 |
| `gate-summary` 的 JSON 导出链在 shell/batch 两侧缺 Python 时静默成功，shell 还会继续打印 `json=...` | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 把 `write_gate_summary_json` 改成缺 `python3` 时 `return 2`，并让 `run_gate_summary` 显式传播失败；在 `tests/fafafa.core.simd/buildOrTest.bat` 把 JSON 分支改成 `py/python` 都缺失时 `exit /b 2`；同时新增 `check_gate_summary_json_runtime_guard` 并同步更新 workflow/checklist 文档，随后用 fresh `check`、direct 正向导出与 no-python 负向验证复验通过 |
| `perf-smoke` 在 shell/batch/Python 三处都把 Scalar backend 当成 `SKIP 0`，会让 `gate-strict` / `evidence-linux` 把缺失的性能证据误判为通过 | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 把 `check_perf_log` 改成 Scalar 时 `return 1`，在 `tests/fafafa.core.simd/buildOrTest.bat` 把 `:perf_smoke` 改成 Scalar 时 `exit /b 1`，在 `tests/fafafa.core.simd/check_perf_smoke_log.py` 把 `/Scalar)` 改成显式失败；同时新增 `check_perf_smoke_scalar_guard` 并同步更新 checklist/workflow 文档，随后用 fresh `check` 与 synthetic Scalar perf log 负向验证复验通过 |
| `evidence-linux` collector 固定把 evidence bundle 写到默认 `logs/evidence-*`，内部 `backend-bench` 也固定写默认 `logs/backend-bench-*`，与 `SIMD_OUTPUT_ROOT` 隔离契约漂移 | 已在 `tests/fafafa.core.simd/collect_linux_simd_evidence.sh` 与 `tests/fafafa.core.simd/run_backend_benchmarks.sh` 接入 `OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${SCRIPT_DIR}}"`，让 evidence bundle、backend-bench 子目录和 perf 用到的 test binary 都落隔离根；同时在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_linux_evidence_output_isolation`，随后用 fresh `check`、isolated `backend-bench`、isolated `evidence-linux` 与 `clean -> find` 复验，确认默认 `tests/fafafa.core.simd/logs` 未再新建目录 |
| public ABI `perf-smoke` 把 `PubCache >= PubGet` 当成 hard fail，但在 benchmark 改成 local-cache hot-loop、inner loop 和 rotated sampling 后，`GetSimdPublicApi` 这条极薄 inline getter 在 FPC 下仍会在部分样本里等价甚至略快，导致机器门禁继续假阳性 | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 新增 `check_perf_smoke_public_abi_shape_guard`，在 `tests/fafafa.core.simd/fafafa.core.simd.bench.pas` 新增 `PUBLIC_ABI_HOT_INNER` 与 `MeasureRotatedPublicAbiTriplet`，并把 `tests/fafafa.core.simd/check_perf_smoke_log.py` 收敛为仅对稳定的 `PubGet > DispGet` 做 hard fail、将 `PubCache < PubGet` 降为 `NOTE`；同步更新 `docs/fafafa.core.simd.publicabi.md`。随后用 fresh `check`、6 轮 direct benchmark log replay、两次 fresh `perf-smoke` 复验通过；`evidence-linux` 的 perf step 也已通过，后续剩余阻塞仅是 sandbox 内 Docker 权限，单独提权重跑 `qemu-cpuinfo-nonx86-evidence` 后通过 |
| `freeze-status-linux` 默认仍读 `tests/fafafa.core.simd/logs/gate_summary.md`，导致 isolated /tmp evidence run 在尾段误吃旧 gate summary 并把本轮 QEMU 证据判成 `SKIP` | 已在 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `run_freeze_status()` 把默认 `freeze_status.json` 路径改到 `${LOG_DIR}`，并新增 `SIMD_FREEZE_GATE_SUMMARY_FILE="${SIMD_FREEZE_GATE_SUMMARY_FILE:-${SIMD_GATE_SUMMARY_FILE:-${GATE_SUMMARY_LOG}}}"`；同时在 `tests/fafafa.core.simd/collect_linux_simd_evidence.sh` 显式传入本轮 `gate_summary.md` / `freeze_status.json` 路径，并新增 `check_freeze_status_output_isolation`。随后用 fresh `check` 复验通过，再对 `/tmp/simd-evidence-linux-escalated-full-20260320` 直接运行 `freeze-status-linux`，确认 `ready=True` 且命中了本轮 `2026-03-20 12:16:09` 的 gate PASS |
| `freeze-status-linux` 修复后仍需要 full closeout 级别的 fresh 证据，而不能停在 targeted replay | 已持续轮询提权 full rerun，最终 `evidence-linux rc=0`，并确认 `gate PASS @ 2026-03-20 12:36:58`、`qemu-cpuinfo-nonx86-evidence PASS`、`freeze-status ready=True`；这说明 Linux closeout 链已重新闭环，剩余缺口转为 Windows fresh evidence |
| AVX-512 CPU 谓词回归测试最初被放进 `SIMD_BACKEND_AVX512` gated suite，导致默认 x86_64 主 runner 的 `--list-suites` / `--suite=` 根本不可达 | 已把纯逻辑测试从 `TTestCase_AVX512BackendRequirements` 拆到新的 `TTestCase_X86BackendPredicates`，并在 `fafafa.core.simd.test.lpr` 的 `ProcessAllSuites` 中显式接入；fresh `test --list-suites` 已出现该 suite，fresh `test --suite=TTestCase_X86BackendPredicates` 通过 |
| `src/fafafa.core.simd.sse42.register.inc` 之前直接从 scalar baseline 起步，没有继承 `SSE4.1` 已注册的 dispatch table，导致强制 `sbSSE42` 时一批本应复用的高价值槽位静默退回 scalar | 已先在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas` 写入 `Test_SSE42_Inherits_SSE41_DispatchSlots` 打出红灯，随后把 `RegisterSSE42Backend` 改成 `CloneDispatchTable(sbSSE41)` 并逐级回退到 `sbSSSE3/sbSSE3/sbSSE2/scalar`；fresh `TTestCase_DispatchAllSlots`、fresh `check`、fresh `gate` 全部通过，确认这是实现层真实 bug 而不是测试误报 |
| x86 backend capability metadata 低报 `scIntegerOps`，会让 `BackendInfo.Capabilities` 与 public ABI `CapabilityBits` 对外少报真实整数操作族 | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_BackendCapabilities_DoNotUnderclaim_IntegerOps`，以代表性整数槽位非 scalar 作为 contract 证据；随后把 `src/fafafa.core.simd.sse2.pas`、`src/fafafa.core.simd.sse2.i386.register.inc`、`src/fafafa.core.simd.sse3.register.inc`、`src/fafafa.core.simd.avx2.register.inc`、`src/fafafa.core.simd.avx512.register.inc` 的 capability set 补入 `scIntegerOps`；fresh `TTestCase_DispatchAPI`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 全部通过 |
| x86 backend raw registered priority 与 canonical priority 漂移，`SSE2` 仍写死旧值 `10`，导致 `TryGetRegisteredBackendDispatchTable(...).BackendInfo.Priority` 与 `GetBackendInfo/GetSimdBackendPriorityValue` 自相矛盾 | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_RegisteredBackendPriority_MatchesCanonicalPriority`；把 `src/fafafa.core.simd.sse2.pas` 的 raw priority 改成 `GetSimdBackendPriorityValue(sbSSE2)`；首次 fresh suite 因 `sse2` 缺 `fafafa.core.simd.backend.priority` 依赖而编译失败，补依赖后 fresh `TTestCase_DispatchAPI`、fresh `check`、fresh `gate` 全部通过 |
| runtime 关闭 `vector asm` 后，受该开关控制的 x86 backend 仍继续高报 `scIntegerOps`，即使代表性整数槽位已经全部退回 scalar | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled`，先在 fresh `DispatchAPI` 打出 `SSE2` 失败；随后把 `src/fafafa.core.simd.sse2.pas`、`src/fafafa.core.simd.sse2.i386.register.inc`、`src/fafafa.core.simd.sse3.register.inc`、`src/fafafa.core.simd.ssse3.register.inc`、`src/fafafa.core.simd.sse41.register.inc`、`src/fafafa.core.simd.sse42.register.inc`、`src/fafafa.core.simd.avx2.register.inc` 的 `scIntegerOps` 宣称改为跟随实际 vector-asm gate；fresh `TTestCase_DispatchAPI`、fresh `check`、fresh `gate` 全部通过 |
| `AVX2` 在当前机器上已满足 `gfFMA` 且 `vector asm` 打开后确实执行 fused `vfmadd*`，但注册表仍未宣称 `scFMA`，导致 capability metadata 与真实 fused-FMA 路径不一致 | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_AVX2_BackendCapabilities_Expose_FMA_When_FusedPathUsable` 与 `Test_AVX2_BackendCapabilities_Clear_FMA_When_VectorAsmDisabled`：前者强制开启 `vector asm`、用经典 fused witness 证明 `AVX2.FmaF32x4` 当前返回 `2^-46` 而非 `0`，后者验证关闭 `vector asm` 后 capability 会清除；随后把 `src/fafafa.core.simd.avx2.register.inc` 的 `scFMA` 宣称改为跟随 `LEnableVectorAsm and HasFeature(gfFMA)`，fresh `DispatchAPI`、fresh `check`、fresh `gate` 全部通过 |
| `AVX2` 在 CPU 仍有 `AVX2` 但 `gfFMA` 被 mask 掉时，`scFMA` capability/public ABI 已清零，但 `FmaF*` 槽位仍被 `AVX2Fma*` wrapper 覆写，导致 dispatch slot wiring 与 capability contract 漂移 | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增独立 qemu 回归 suite `TTestCase_X86MaskedFmaContract`，并接入 `tests/fafafa.core.simd/fafafa.core.simd.test.lpr`；fresh red `qemu-x86_64 -cpu Haswell,-fma ... --suite=TTestCase_X86MaskedFmaContract` 命中 `AVX2 FmaF32x4 slot should stay scalar when hardware FMA is unavailable`。随后把 `src/fafafa.core.simd.avx2.register.inc` 的 `FmaF32x4/FmaF64x2/FmaF32x8/FmaF64x4/FmaF32x16/FmaF64x8` 覆写收紧到 `LHasHardwareFma=True`；fresh qemu green、fresh release 定向 suite、fresh `check`、fresh `gate` 全部通过，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 14:23:41` |
| `AVX2` 在 `vector asm` 打开时已经把 `Select/Insert/Extract` 等代表性 shuffle 槽位绑到原生实现，但注册表仍未宣称 `scShuffle`，导致 public ABI `CapabilityBits` 同步低报 shuffle 能力 | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_AVX2_BackendCapabilities_Expose_Shuffle_When_NativeShuffleSlotsUsable` 与 `...Clear_Shuffle_When_VectorAsmDisabled`，并在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 新增 `Test_PublicApi_BackendPodInfo_CapabilityBits_Expose_AVX2Shuffle_WhenNativeSlotsPresent`；fresh `DispatchAPI` red 命中 `AVX2 should advertise scShuffle once representative shuffle slots are non-scalar`，fresh `PublicAbi` red 命中 `CapabilityBits` 漏报；随后把 `src/fafafa.core.simd.avx2.register.inc` 的 `scShuffle` 宣称改为跟随 `LEnableVectorAsm`，fresh `DispatchAPI`、fresh `PublicAbi`、fresh `check`、fresh `gate` 全部通过 |
| x86 clone backend 在 runtime `SetVectorAsmEnabled(True -> False)` 后没有完整重建链：`SSE3/SSSE3/SSE41` 缺 `RegisterBackendRebuilder`，且 `SSSE3/SSE41/SSE42` 的 `scShuffle` 未跟 `vector asm` gate 绑定，导致 `SSE41/SSE42` 的 representative shuffle 槽位与 capability/public ABI 状态漂移 | 先用 fresh `TTestCase_DispatchAPI` red 命中 `SSE41 SelectF32x4 should fall back to scalar when vector asm is disabled`；补上 `src/fafafa.core.simd.sse3.register.inc`、`src/fafafa.core.simd.ssse3.register.inc`、`src/fafafa.core.simd.sse41.register.inc` 的 rebuilder 注册后，第二次 red 前移到 `SSE41` 的 `scShuffle` 假绿；随后把 `src/fafafa.core.simd.ssse3.register.inc`、`src/fafafa.core.simd.sse41.register.inc`、`src/fafafa.core.simd.sse42.register.inc` 的 `scShuffle` 改为跟随 `IsVectorAsmEnabled`，并将 `Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled` 升级为真实 `True -> False` 切换路径；最终 fresh `TTestCase_DispatchAPI`、fresh `TTestCase_PublicAbi`、fresh `check`、fresh `gate` 全部通过 |
| `SSE2` 已经直接注册了非 scalar `Select/Insert/Extract` 等代表性 shuffle 槽位，`SSE3` 也通过 clone 链继承了这些槽位，但 capability metadata / public ABI `CapabilityBits` 仍低报 `scShuffle` | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 补 x86 inherited shuffle underclaim 合同测试；fresh red 命中 `SSE2` 的内部 capability 与 public ABI 位图同时漏报；随后将 `src/fafafa.core.simd.sse2.pas`、`src/fafafa.core.simd.sse2.i386.register.inc`、`src/fafafa.core.simd.sse3.register.inc` 的 `scShuffle` 宣称补齐到现有 `IsVectorAsmEnabled` gate；fresh `DispatchAPI/PublicAbi`、fresh `check`、fresh `gate` 全部通过，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 05:10:26` |
| `GetBackendOps(backend)` 在未注册 backend 路径上只回写顶层 `Backend`，但没有同步 canonical `BackendInfo`，导致 adapter 返回 `BackendInfo.Backend=sbScalar`、`Priority=0` 这类默认零值 | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas` 补 `Test_BackendAdapter_UnregisteredBackendOps_PreserveCanonicalMetadata` 打红；fresh red 直接命中 `expected: <7> but was: <0>`。随后把 `src/fafafa.core.simd.backend.adapter.pas` 的未注册路径改为直接 `Result.BackendInfo := GetBackendInfo(backend)`，并用 fresh `TTestCase_DispatchAllSlots`、fresh `check`、fresh `gate` 全部复验通过 |
| `SetVectorAsmEnabled(False <-> True)` 并发窗口里，dispatchable helper 会暴露半重建中间态；同时 `DoInitializeDispatch` 选中 backend 后仍从 mutable `g_BackendTables[...]` 复制 current snapshot，导致 `GetCurrentBackendInfo` 继续可能读到旧 backend id + 新 disabled metadata | 已在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增 `Test_Concurrent_DispatchableHelpers_VectorAsmToggle_ReadConsistency`，fresh red 同时命中 `best dispatchable backend mixed snapshot`、`dispatchable helper mixed snapshot` 和旧 `current backend info mixed snapshot`。随后把 `src/fafafa.core.simd.dispatch.pas` 的 current dispatch publication 改为复用 `GetPublishedBackendDispatchTable(LBestBackend)`，并让 `GetDispatchableBackends` / `GetBestDispatchableBackend` 在扫描期间持有 `g_VectorAsmToggleLock`；fresh `TTestCase_SimdConcurrentFramework`、fresh `check`、fresh `gate` 全部复验通过 |
| `NEON/RISCVV` 在 non-asm build、test-only fallback 注册态，以及 native asm build 的 runtime-disabled rebuild 路径下仍高报 `scIntegerOps`，把 scalar/common fallback 整数槽位误包装成 vector integer capability | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 补 `NEON/RISCVV` 的 `scIntegerOps` red/green 合同测试，并把 native `SetVectorAsmEnabled(False)` 路径也纳入清零断言；随后将 `src/fafafa.core.simd.neon.register.inc` 与 `src/fafafa.core.simd.riscvv.register.inc` 的 `scIntegerOps` 宣称改为仅在 `LUseVectorAsm=True` 时成立；fresh `NEON`/`RISCVV` opt-in suite、fresh `check`、fresh `gate` 全部通过 |
| `AVX512` 在 runtime `SetVectorAsmEnabled(False)` 后仍保留 native 宽槽位与 `scFMA/scIntegerOps/scMaskedOps/sc512BitOps`，导致 dispatch/public ABI 双侧 stale capability | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 补 AVX512 runtime-disabled red/green 合同测试；随后将 `src/fafafa.core.simd.avx512.register.inc` 改为仅在 `LEnableVectorAsm=True` 时覆写 native AVX512 slots 并加入 gated capabilities，`vector asm=False` 时保留 fallback table；同时把旧 AVX512 native-path testcase 改成显式 `SetVectorAsmEnabled(True)` 后再断言 native 映射；fresh opt-in suite、fresh opt-in `check`、fresh opt-in `gate` 全部通过 |
| `AVX512` 在 `vector asm=True` 时已把 `SelectF32x16/SelectF64x8` 接到原生实现，但 capability metadata / public ABI `CapabilityBits` 仍低报 `scShuffle` | 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 补 AVX512 `scShuffle` expose/clear 合同测试；随后将 `src/fafafa.core.simd.avx512.register.inc` 的 `scShuffle` 宣称改为跟随 `LEnableVectorAsm`；fresh opt-in suite、fresh opt-in `check`、fresh opt-in `gate` 全部通过 |
| `SetVectorAsmEnabled(True -> False)` 后，多个 backend 即使已重建成 scalar-backed/fallback table，仍继续保留 `BackendInfo.Available=True`，导致 dispatch/public ABI 的 active backend identity 停留在旧 backend id | 已先在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 补 red tests，锁定 “scalar-backed backend must not remain dispatchable/active” 合同；随后把 `src/fafafa.core.simd.sse2.pas`、`src/fafafa.core.simd.sse2.i386.register.inc`、`src/fafafa.core.simd.sse3.register.inc`、`src/fafafa.core.simd.ssse3.register.inc`、`src/fafafa.core.simd.sse41.register.inc`、`src/fafafa.core.simd.sse42.register.inc`、`src/fafafa.core.simd.avx2.register.inc` 的 `Available` 改为跟随 `IsVectorAsmEnabled/LEnableVectorAsm`，把 `src/fafafa.core.simd.avx512.register.inc` 改为 `isAvailable and LEnableVectorAsm`，再把 `src/fafafa.core.simd.neon.register.inc` 与 `src/fafafa.core.simd.riscvv.register.inc` 收敛为 `(not LAsmCapable) or LUseVectorAsm`，最后把 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 与 `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas` 的旧 smoke 预期改成 dispatchable 语义；fresh targeted `DispatchAPI/PublicAbi`、fresh `check`、fresh `gate` 全部通过，最终 `[GATE] OK`，run-all summary 时间 `2026-03-21 03:14:15` |
| `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas` 手写的默认 backend 预测逻辑只覆盖 `SSE2/AVX2`，会在 `AVX2` 失去 dispatchable 身份而 `SSE4.2` 仍可派发时把外部 smoke 误算成 `SSE2` | 已先抽出 `tests/fafafa.core.simd/fafafa.core.simd.public_smoke_support.pas` 并在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_PublicSmokeDefaultBackendPredictor_Tracks_CanonicalDispatchPriority` 打红；fresh red 命中 `expected: <5> but was: <1>`，证明 canonical `GetBestDispatchableBackend` 已切到 `sbSSE42`，而旧 predictor 还停在 `sbSSE2`。随后把 helper 改为直接复用 `GetBestDispatchableBackend`，并用 fresh `DispatchAPI`、standalone `public_smoke` 编译/运行、fresh `check`、fresh `gate` 全部通过 |
| `GetSimdPublicApi` vs local cache 的 FPC codegen 之前缺少机器级证据，导致 `PubCache >= PubGet` 是否值得做 hard gate 不清楚 | 已用 `/tmp/simd_publicapi_codegen_probe.pas` 在 FPC 3.3.1 / x86_64 / `-O3` 下取证：`CallPublicCached` 与 `CallPublicGetter` 都直接加载 `g_SimdPublicApi` 后调用对应函数指针，汇编形状只差寄存器装载顺序；`CallDispatchGetter` / `SumDispatchGetter` 则保留 `g_DispatchState` 检查、`InitializeDispatch/ReadBarrier` 和 `g_CurrentDispatch` 读取。结论：`PubGet > DispGet` 作为 hard gate 有证据支撑，而 `PubCache >= PubGet` 仍应只做观测项 |
- 默认 `src/fafafa.core.settings.inc` 仍关闭 `SIMD_BACKEND_AVX512`，所以当前 fresh Linux `DispatchAPI/PublicAbi/check/gate` 证据链不会直接编译或执行 `src/fafafa.core.simd.avx512.register.inc`
- 基于源码检查，`src/fafafa.core.simd.avx512.register.inc` 已注册 `FmaF32x16/FmaF64x8` 到 `AVX512Fma*`，而 `src/fafafa.core.simd.avx512.f32x16_fma_round.inc` / `f64x8_fma_round.inc` 真实使用 `vfmadd213ps/pd`；因此把 `scFMA` 补入 AVX-512 capability set 是源码层一致性修复，但仍需在显式启用 `SIMD_BACKEND_AVX512` 的构建里补 fresh red/green 证据
- `tests/fafafa.core.simd/BuildOrTest.sh` / `buildOrTest.bat` 之前没有显式 opt-in 通道把 `SIMD_BACKEND_AVX512` 编进主 `simd` test runner，导致 AVX-512 future guard 只能靠手工 `lazbuild --opt=-dSIMD_BACKEND_AVX512` 验证，不符合当前模块 runner/guard 的常规证据链 | 已给 shell/batch runner 都补上 `SIMD_ENABLE_AVX512_BACKEND=1` -> `--opt=-dSIMD_BACKEND_AVX512` 的编译通道，并新增 `check_avx512_optin_runner_guard` 静态守卫；随后用 fresh `SIMD_ENABLE_AVX512_BACKEND=1` 的 `check`、fresh `test --list-suites`、fresh `TTestCase_AVX512BackendRequirements`、fresh `TTestCase_DispatchAPI`、fresh `TTestCase_PublicAbi`、fresh `gate` 全部通过，确认 AVX-512 opt-in 编译/注册/public ABI 证据链已打通 |
- 当前宿主机 `/proc/cpuinfo` 只有 `avx2` / `popcnt`，没有任何 `avx512*` flags，因此今天拿到的是 **AVX-512 opt-in build + registration/capability/public ABI** fresh 证据，不是 native AVX-512 指令执行证据 | 后续若要把 AVX-512 从“opt-in contract 已验证”推进到“真机执行已验证”，仍需在具备 `avx512f`/`avx512bw` 且 OS/XCR0 可用的主机上补 fresh native 运行证据 |
- parity guard 修复后 fresh `gate` 仍需确认 | 已运行隔离目录 `gate`，完整 PASS |
- `evidence-linux` 最新一轮在 sandbox 内已不再卡 `perf-smoke`，真正失败点是 `qemu-cpuinfo-nonx86-evidence` 访问 `/var/run/docker.sock` 的权限限制；同一步骤提权后通过，说明代码侧回归已清掉，剩余差异来自环境权限

## Resources
- `docs/fafafa.core.simd.md`
- `docs/fafafa.core.simd.checklist.md`
- `docs/fafafa.core.simd.cpuinfo.md`
- `src/fafafa.core.simd.README.md`
- `tests/fafafa.core.simd/BuildOrTest.sh`
- `tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh`
- `tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh`
- `tests/fafafa.core.simd.publicabi/BuildOrTest.sh`

## Visual/Browser Findings
- 无
