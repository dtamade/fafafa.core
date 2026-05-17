# SIMD Runtime/Cpuinfo Closeout Implementation Plan

> Status: superseded historical plan.
>
> This document records an older SIMD execution batch or bounded strategy snapshot.
> It is no longer part of the active whole-module execution chain.
> Before starting from any SIMD plan, check `docs/plans/2026-05-10-simd-plan-status-index.md`.

> Current HEAD note (2026-05-17):
> This plan is historical context, not the current repository status. Latest
> `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
> remains `ready=False / mainline-ready=True / cross-ready=False`, with
> `win-evidence-preflight=RECENT_BILLING_BLOCK` and
> `windows_evidence_verify` failing at
> `cmd.exe cannot resolve LAZBUILD command "lazbuild"`. For current operator
> truth, use `docs/fafafa.core.simd.closeout.md` and
> `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md`.

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 `simd` 当前 `runtime / cpuinfo / dataplane / façade` 这一条 bounded frontier 收成可验证、可提交、不会再反复争论接口语义的最小闭环。

**Architecture:** 这轮不再横向重审 backend family，也不继续发散到 Windows evidence。只封边 4 个点：共享 backend-array 类型归属、`fafafa.core.simd` façade 的 canonical CPU-info wrapper、`cpuinfo` vs `runtime` 语义在示例/文档中的边界，以及 data-plane published snapshot 的不可变语义。实现上保持 legacy alias 兼容，但默认入口、示例和内部 wiring 都回到 canonical 语义。

**Tech Stack:** FreePascal/Lazarus, `fafafa.core.simd` / `cpuinfo` / `runtime` / `dispatch` / `dataplane`, FPCUnit runner `tests/fafafa.core.simd`, Markdown docs/examples.

---

### Task 1: 固化当前 bounded frontier 与 stop condition

**Files:**

- Create: `docs/plans/2026-04-15-simd-runtime-cpuinfo-closeout-plan.md`
- Verify only: `docs/fafafa.core.simd.interface.md`
- Verify only: `docs/fafafa.core.simd.api.md`

**Step 1: 写死本轮边界**

- 只处理 `runtime / cpuinfo / dataplane / façade wrapper / docs/example/test wiring`
- 不重开 backend-family implementation review
- 不把 Windows evidence 当成本轮 blocker

**Step 2: 写死 stop condition**

- canonical API 与 legacy alias 的口径一致
- `cpuinfo` / `runtime` 语义不再在文档/示例里混用
- dataplane published snapshot 不再对外暴露后重写
- `TTestCase_RuntimeAPI` / `TTestCase_DataPlane` / `check` / `gate` fresh green

### Task 2: 收口共享类型与 façade canonical wrapper

**Files:**

- Modify: `src/fafafa.core.simd.base.pas`
- Modify: `src/fafafa.core.simd.cpuinfo.pas`
- Modify: `src/fafafa.core.simd.framework.intf.inc`
- Modify: `src/fafafa.core.simd.framework.impl.inc`
- Test: `tests/fafafa.core.simd/fafafa.core.simd.runtime.testcase.pas`

**Step 1: 把 `TSimdBackendArray` 的归属拉回基础层**

- 在 `base` 中定义共享 backend-list 容器
- `cpuinfo` 只保留 compatibility re-export
- 目标：`runtime` 不再在类型所有权上依赖 `cpuinfo`

**Step 2: 给 façade 补 canonical `GetCPUInfo`**

- `fafafa.core.simd` 公开 `GetCPUInfo`
- `GetCPUInformation` 继续保留为 legacy alias
- 测试里同时证明：façade canonical、façade legacy、`cpuinfo` canonical 三者一致

### Task 3: 收口 dataplane published snapshot 语义

**Files:**

- Modify: `src/fafafa.core.simd.dataplane.pas`
- Verify only: `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`
- Verify only: `src/fafafa.core.simd.direct.pas`

**Step 1: 修正 dataplane 节点复用策略**

- 已发布节点永不再写
- `FindOwnedSimdDataPlane` 命中时只重新发布指针，不再逐字段回填
- 首次创建节点时一次性初始化全部 bound slots

**Step 2: 同步注释**

- `direct` 注释改为 canonical control-plane 名称
- 把 dataplane 设计口径对齐到 immutable publication

### Task 4: 收口 docs/example 里的 runtime vs cpuinfo 语义

**Files:**

- Modify: `docs/fafafa.core.simd.interface.md`
- Modify: `docs/fafafa.core.simd.api.md`
- Modify: `docs/fafafa.core.simd.cpuinfo.md`
- Modify: `docs/fafafa.core.simd.md`
- Modify: `src/fafafa.core.simd.README.md`
- Modify: `examples/example_simd_dispatch.pas`

**Step 1: 文档只推荐 canonical 名称**

- façade canonical `GetCPUInfo`
- `dispatch.IsBackendAvailableOnCPU` 明确降级为 low-level compatibility alias
- `GetDispatchableBackendList` 作为默认 runtime getter，`GetAvailableBackendList` 只保留兼容说明

**Step 2: 示例不再把 CPU-supported 写成 active/runtime backend**

- 概念示例明确写成 `CPU-supported` 或 `current runtime backend`
- 如果示例做的是 runtime 选择，就用 `runtime` 入口，不再用 `cpuinfo` 伪装成 active backend

### Task 5: Fresh verification 与 bounded commit

**Files:**

- Verify: `tests/fafafa.core.simd/fafafa.core.simd.runtime.testcase.pas`
- Verify: `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`
- Verify: `tests/fafafa.core.simd/BuildOrTest.sh`

**Step 1: 跑 targeted runtime/data-plane suite**

Run:

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_RuntimeAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane
```

**Step 2: 跑基础门禁**

Run:

```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

**Step 3: 如时间允许，跑 host-local strict closeout**

Run:

```bash
SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local
```

**Step 4: 只提交本 bundle**

Run:

```bash
git add docs/plans/2026-04-15-simd-runtime-cpuinfo-closeout-plan.md \
  docs/fafafa.core.simd.interface.md docs/fafafa.core.simd.api.md docs/fafafa.core.simd.cpuinfo.md docs/fafafa.core.simd.md \
  src/fafafa.core.simd.README.md src/fafafa.core.simd.base.pas src/fafafa.core.simd.cpuinfo.pas \
  src/fafafa.core.simd.dataplane.pas src/fafafa.core.simd.direct.pas \
  src/fafafa.core.simd.framework.intf.inc src/fafafa.core.simd.framework.impl.inc src/fafafa.core.simd.dispatch.pas \
  tests/fafafa.core.simd/fafafa.core.simd.runtime.testcase.pas \
  examples/example_simd_dispatch.pas
```

Expected: 只包含当前 runtime/cpuinfo/dataplane/interface closeout files，不混入其他 SIMD backend 波次。
