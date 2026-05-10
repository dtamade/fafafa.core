# SIMD X86 Smoke Closeout Implementation Plan

> Status: superseded historical plan.
>
> This document records an older SIMD execution batch or bounded strategy snapshot.
> It is no longer part of the active whole-module execution chain.
> Before starting from any SIMD plan, check `docs/plans/2026-05-10-simd-plan-status-index.md`.


> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把当前 `simd` x86 bounded frontier 收成可复跑、可提交、可阶段性封板的最小闭环，避免下轮再靠口头回忆“哪些 x86 proof 已经补过”。

**Architecture:** 不再扩 public API / ABI，也不再横向翻 x86 family。只新增一个 `impl-smoke-x86` 高频入口，把当前 bounded x86 proof 固化成单条 runner 命令；同时把 checklist / closeout / patch bundle 对齐到同一个最小提交集合，并用 host-local strict closeout 做 fresh 收口验证。Windows/native 外部证据继续保留为独立外部边界，不在本轮本地伪造完成。

**Tech Stack:** FreePascal/Lazarus, Bash/Batch runners, existing `DispatchAPI` proof tests, Markdown closeout docs, git pathspec-based bundle staging.

---

### Task 1: 落盘 x86 smoke / closeout 计划

**Files:**
- Create: `docs/plans/2026-04-14-simd-x86-smoke-closeout-plan.md`

**Step 1: 写清当前波次边界**

- 只收 `x86 bounded frontier`
- 不重开 broad x86 review
- 不伪造 Windows/native 外部证据完成

**Step 2: 写清本轮必须完成的本地动作**

- 新增 `impl-smoke-x86`
- 更新 checklist / closeout / bundle 文档
- 跑 fresh release 验证
- 安全提交 Bundle A

---

### Task 2: 在 runner 增加 `impl-smoke-x86`

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/buildOrTest.bat`

**Step 1: 新增 shell runner 入口**

要求：

- 输出独立 log summary
- 使用 release 口径
- 目标 suite 固定为 `TTestCase_DispatchAPI`
- 保持 binary rooted under `tests/fafafa.core.simd/bin2`，避免 source-truth tests 的 `../../../src` 相对路径失效

**Step 2: 新增 batch proxy 入口**

要求：

- Windows 继续只做 bash 代理，不重复实现逻辑
- help / usage 同步出现 `impl-smoke-x86`

---

### Task 3: 同步 checklist / closeout / patch bundle

**Files:**
- Modify: `docs/fafafa.core.simd.checklist.md`
- Modify: `docs/fafafa.core.simd.closeout.md`
- Modify: `docs/plans/2026-04-14-simd-only-patch-bundle.md`
- Modify: `docs/fafafa.core.simd.implementation-matrix.md`

**Step 1: checklist 加入 x86 高频 smoke 命令**

要求：

- 明确 `impl-smoke-x86` 适用场景：当前 x86 bounded frontier / DispatchAPI implementation proof 收口

**Step 2: closeout 加入 x86 smoke 说明**

要求：

- 写清 `impl-smoke-x86` 与 `impl-smoke-nonx86` 的分工
- 不把它写成 full closeout 替代品

**Step 3: patch bundle 更新为当前真实最小集合**

要求：

- 把 runner / checklist / plan 文档纳入当前 Bundle A
- 验证命令改成 current bundle 的 fresh 命令矩阵

**Step 4: implementation matrix 保持 x86 ledger 为真相源**

- 继续保留 `AVX512 shift boundary`
- 继续保留 `AVX2 wide select`
- 继续保留 `AVX2 wide FMA composition`

---

### Task 4: 跑 fresh release 验证并收口

**Files:**
- Verify only

**Step 1: 先跑 x86 高频 smoke**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-x86
```

Expected:

- `X86_IMPL_SMOKE_SUMMARY ... status=ok`

**Step 2: 跑基础 release 验证**

Run:
```bash
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check
```

Expected:

- `[TEST] OK`
- `[LEAK] OK`
- `[CHECK] OK`

**Step 3: 跑 host-local strict closeout**

Run:
```bash
SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' \
SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 \
FAFAFA_BUILD_MODE=Release \
bash tests/fafafa.core.simd/BuildOrTest.sh closeout-host-local
```

Expected:

- `[CLOSEOUT-HOST-LOCAL] OK`

**Step 4: 跑 diff 健康检查**

Run:
```bash
git diff --check -- \
  tests/fafafa.core.simd/BuildOrTest.sh \
  tests/fafafa.core.simd/buildOrTest.bat \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  docs/fafafa.core.simd.checklist.md \
  docs/fafafa.core.simd.closeout.md \
  docs/fafafa.core.simd.implementation-matrix.md \
  docs/plans/2026-04-14-simd-x86-implementation-frontier.md \
  docs/plans/2026-04-14-simd-x86-smoke-closeout-plan.md \
  docs/plans/2026-04-14-simd-only-patch-bundle.md
```

Expected:

- 无 whitespace / conflict marker 问题

---

### Task 5: 安全提交 Bundle A

**Files:**
- Stage only current Bundle A files

**Step 1: stage**

```bash
git add \
  tests/fafafa.core.simd/BuildOrTest.sh \
  tests/fafafa.core.simd/buildOrTest.bat \
  tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas \
  docs/fafafa.core.simd.checklist.md \
  docs/fafafa.core.simd.closeout.md \
  docs/fafafa.core.simd.implementation-matrix.md \
  docs/plans/2026-04-14-simd-x86-implementation-frontier.md \
  docs/plans/2026-04-14-simd-x86-smoke-closeout-plan.md \
  docs/plans/2026-04-14-simd-only-patch-bundle.md
```

**Step 2: commit**

```bash
git commit -m "simd: add x86 impl smoke and seal bounded frontier"
```

**Step 3: 说明外部边界**

- Windows / native external evidence 仍是外部环境话题
- 本轮本地收口以 `closeout-host-local` 为准
