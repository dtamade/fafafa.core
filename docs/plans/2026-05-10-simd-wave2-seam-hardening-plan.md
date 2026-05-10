# SIMD Wave 2 Seam Hardening Plan

**Goal:** 在不打开 family migration 的前提下，把 `dispatch / dataplane / public ABI wrapper / direct / façade fast-path` 这一条 `control/publication seam` 收成单一 truth-source、单一 publication path、单一 verification lane 的实现批次。

**Architecture:** 这一波不处理 `SSE2/AVX2/NEON/RISCVV` family 迁移，不改 raw-leaf disposition，不扩 stable backend 依赖面。唯一目标是把 control-plane truth 固定在 `dispatch`，把 published binding truth 固定在 `dataplane`，并让 `public ABI wrapper`、`direct`、façade fast-path 全部退回到“只消费已发布 snapshot”的 companion surface 角色。

**Status:** completed

**Tech Stack:** `src/fafafa.core.simd.dispatch.pas`、`src/fafafa.core.simd.dataplane.pas`、`src/fafafa.core.simd.direct.pas`、`src/fafafa.core.simd.public_abi.impl.inc`、`src/fafafa.core.simd.pas`、`src/fafafa.core.simd.runtime.pas`、`src/fafafa.core.simd.cpuinfo.pas`、`tests/fafafa.core.simd/*dispatchapi*`、`*dataplane*`、`*runtime*`、`*direct*`、`*concurrent*`、release `BuildOrTest.sh` gate/check/test suites。

---

## 为什么先做这波

当前 whole-module 计划里，`Wave 2` 是第一波，不是因为它最“显眼”，而是因为它最容易污染后面所有 family 的实施方式。

如果这一波不先收紧，后面几乎每一类重构都会重复出现同一种坏味道：

- `dispatch` 之外又长出第二套 control truth
- `dataplane` 之外又长出第二套 publication truth
- `public ABI` / `direct` / façade fast-path 各自缓存一套自己的解释
- family-level 计划在错误的 seam 上继续堆 patch

所以这波的意义不是“多写几个 helper”，而是先把中间缝钉死。

## 这波只碰什么

### In scope

- `dispatch` 的 control-plane truth source
- `dataplane` 的 published binding snapshot
- `public ABI wrapper` 的 active metadata / public function table 绑定语义
- `direct` 的 dataplane companion 语义
- façade fast-path 的 rebind 来源
- `runtime / cpuinfo` 对当前 backend / dispatchable / capability 语义的边界
- 对应测试、注释、接口文档

### Out of scope

- backend adapter 家族迁移
- raw leaf promote / split / retire
- `SSE2` debt pilot
- `AVX2` active-leaf 样板推进
- `NEON / RISCVV` qualification
- Windows evidence / future trigger / retire target closeout

## 这波默认要看的文件

### 核心实现面

- `src/fafafa.core.simd.dispatch.pas`
- `src/fafafa.core.simd.dataplane.pas`
- `src/fafafa.core.simd.direct.pas`
- `src/fafafa.core.simd.public_abi.impl.inc`
- `src/fafafa.core.simd.pas`

### 边界辅助面

- `src/fafafa.core.simd.runtime.pas`
- `src/fafafa.core.simd.cpuinfo.pas`
- `src/fafafa.core.simd.framework.intf.inc`
- `src/fafafa.core.simd.framework.impl.inc`

### 当前真相源

- `docs/SIMD_LAYERING_IMPLEMENTATION.md`
- `docs/SIMD_BACKEND_TRUTH.md`
- `docs/fafafa.core.simd.interface.md`

## 开工前 baseline

按仓库约定，默认用 `Release`。

先跑：

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_RuntimeAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework
```

规则：

- baseline 没跑，不开始收 seam
- baseline 红了，先分旧红 / 新红
- 这波优先信 `DispatchAPI / RuntimeAPI / DataPlane / Direct / Concurrent`，不是先冲 family parity

## Task 1: 固定这一波的 truth-source 约束

**Files:**

- Modify: `docs/plans/2026-05-10-simd-wave2-seam-hardening-plan.md`
- Verify only: `docs/SIMD_LAYERING_IMPLEMENTATION.md`
- Verify only: `docs/fafafa.core.simd.interface.md`
- Verify only: `src/fafafa.core.simd.dispatch.pas`
- Verify only: `src/fafafa.core.simd.dataplane.pas`

**Step 1: 写死 control truth**

- backend 选择只认 `dispatch`
- `runtime` / `cpuinfo` / `direct` / `public ABI` 都不能变成第二个 selector

**Step 2: 写死 publication truth**

- published binding 只认 `dataplane`
- façade fast-path / `public ABI` / `direct` 只消费 published snapshot 或 hook-driven bind result

**Step 3: 写死 stop condition**

- 这波只做 truth-source / ownership / publication 约束收紧
- 不借机扩 family migration

## Task 2: 收紧 `dispatch`

**Files:**

- Modify: `src/fafafa.core.simd.dispatch.pas`
- Verify only: `src/fafafa.core.simd.runtime.pas`
- Verify only: `src/fafafa.core.simd.cpuinfo.pas`
- Test: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`

**Step 1: 保持 selector 唯一性**

- 所有 active backend 选择、dispatchability、hook publication 都继续以 `dispatch` 为唯一真相源
- 不允许把“当前 backend 是谁”重新分散到 companion surface 自己推导

**Step 2: 清掉伴生面的控制语义复制**

- 如果 `public ABI` / `direct` / façade fast-path 有自己现算 backend 语义的地方，优先收回到 `dispatch` 已发布结果
- `runtime` / `cpuinfo` 只做 canonical query surface，不做额外控制面

**Step 3: 保持 hook 语义单一**

- dispatch-changed hook 仍由 `dispatch` 统一发布
- 不允许 companion surface 自己再引入第二套 rebind 触发协议

## Task 3: 收紧 `dataplane`

**Files:**

- Modify: `src/fafafa.core.simd.dataplane.pas`
- Verify only: `src/fafafa.core.simd.pas`
- Verify only: `src/fafafa.core.simd.direct.pas`
- Verify only: `src/fafafa.core.simd.public_abi.impl.inc`
- Test: `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`

**Step 1: published snapshot 只在这里形成**

- `dataplane` 负责当前 dispatch 的 published binding snapshot
- companion surface 不再自己现拼“等价 snapshot”

**Step 2: 保持发布后不可变**

- 已发布节点不再被 consumer 二次改写
- 复用旧 snapshot 时，只允许重新发布指针或复用已绑定结果，不允许悄悄回填字段

**Step 3: 让 consumer 只读**

- façade fast-path、`public ABI`、`direct` 只能读取 `dataplane` 已发布结果
- 不允许 consumer 侧继续长 helper cache 去改写 dataplane 语义

## Task 4: 收紧 `public ABI wrapper`

**Files:**

- Modify: `src/fafafa.core.simd.public_abi.impl.inc`
- Verify only: `src/fafafa.core.simd.public_abi.intf.inc`
- Verify only: `src/fafafa.core.simd.pas`
- Test: `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas`
- Test: `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`

**Step 1: active metadata 不再自成 control truth**

- `public ABI` 里 active backend / capability / dispatchable 相关 metadata 只反映当前已发布状态
- 不允许 wrapper 自己再去解释一遍 backend 选择

**Step 2: function table 继续保持 bound-table 语义**

- `GetSimdPublicApi` 返回的是已绑定 table
- 绑定触发来自 dispatch publication / dataplane published state
- 不允许 `GetSimdPublicApi` 每次重走第二套 dispatch lookup

**Step 3: backend text / pod info 继续走稳定生命周期**

- 文字/metadata getter 继续保持 stable snapshot ownership
- 不把 managed string 生命周期重新暴露成 ABI 面

## Task 5: 收紧 `direct`

**Files:**

- Modify: `src/fafafa.core.simd.direct.pas`
- Test: `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`
- Test: `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`

**Step 1: `direct` 继续只做 companion**

- `direct` 读取的是当前已发布 dataplane snapshot
- 它不是 control-plane truth source，也不是 publication builder

**Step 2: 防止 direct 变成第二套 bind layer**

- 不允许 `direct` 自己维护另一份与 dataplane 脱钩的 dispatch table 解释逻辑
- 如果要 rebind，也必须跟随同一套 publication 事件

## Task 6: 收口 façade fast-path / runtime / cpuinfo 边界

**Files:**

- Modify: `src/fafafa.core.simd.pas`
- Modify: `src/fafafa.core.simd.runtime.pas`
- Modify: `src/fafafa.core.simd.cpuinfo.pas`
- Modify: `docs/fafafa.core.simd.interface.md`
- Test: `tests/fafafa.core.simd/fafafa.core.simd.runtime.testcase.pas`

**Step 1: façade fast-path 只消费已发布绑定**

- façade hot-path 不能脱离 `dataplane` 单独解释 active backend
- 如果有 local cache，它也必须只是 published binding 的只读镜像

**Step 2: runtime / cpuinfo 不再混成第二套控制面**

- `runtime` 负责当前运行态 query/control 语义
- `cpuinfo` 负责 capability / availability 视图
- 不允许文档、示例、wrapper 再把它们混成“另一个 backend selector”

## 红线

这波永远不要做：

- 不把 `public ABI` / `direct` / façade fast-path 重新写成独立控制面
- 不把 family-level 迁移夹带进 seam hardening
- 不借机把 `SSE2` 局部策略升级成全局规则
- 不把 `dataplane` 降回“只是局部 helper”
- 不让 consumer 端继续持有第二套 truth cache

## 完成标准

这波完成，不看“感觉已经更整洁”，只看下面这些：

1. backend 选择只认 `dispatch`
2. published binding 只认 `dataplane`
3. `public ABI wrapper` / `direct` / façade fast-path 不再私自拥有第二套 truth
4. `runtime / cpuinfo` 的语义边界在代码、测试、文档里一致
5. 下面这些 verification lane fresh 通过：

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_RuntimeAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework
```

## 改完后默认只更新哪里

这波做完，默认更新：

1. 这份 `Wave 2` 计划
2. `plans/scratch/2026-04-08-simd-review/` 下的 `task_plan.md / progress.md / findings.md`
3. `docs/plans/2026-05-10-simd-execution-index.md`，如果这一波的完成状态改变了默认执行队列

只有在全局规则变化时，才回写：

- `docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md`
- `docs/SIMD_LAYERING_IMPLEMENTATION.md`

## Current implementation notes

- 2026-05-11: `Wave 2` 已完成。`public ABI`、façade fast-path、`direct` companion、`api/ops/arrays` dispatch 读取路径，以及 `dispatch-read-scope` 机器护栏已完成并通过 release `check` / targeted suites / `gate`。
- 2026-05-11: `runtime` 内部已移除只服务 `IsBackendRegisteredInBinary` 的 `RegisteredFlags`，并把多个 runtime getter 收成共用 published-snapshot 读取 helper，减少内部重复状态与重复读取模板。
- `cpuinfo` legacy aliases 和 `framework` 转发层已确认只是 compatibility thin shells，不是第二套 truth source；默认下一波转入 `Wave 3A / AVX2`。
