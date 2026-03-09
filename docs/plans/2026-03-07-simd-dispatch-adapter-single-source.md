# SIMD Dispatch Adapter Single Source Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 以 `backend.adapter.map.inc` 为 adapter-managed slots 的事实真相源，增强自动校验，减少 `dispatch` / `backend.iface` / `adapter` 之间的多点同步漏改风险。

**Architecture:** 不做高风险结构重写，也不尝试一次性生成 Pascal 代码；优先增强现有 `check_backend_adapter_sync.py`，让它不仅核对 `backend.iface <-> adapter`，还核对 `adapter.map.inc` 中引用的 slot 是否真实存在于 `TSimdDispatchTable`，以及是否被 `FillBaseDispatchTable` 覆盖。必要时同步补充 `map.inc` 顶部注释，明确它是 adapter-managed slots 的真相源。

**Tech Stack:** Python checker, Pascal source introspection, existing SIMD gate scripts.

---

### Task 1: 增强 adapter-sync checker

**Files:**
- Modify: `tests/fafafa.core.simd/check_backend_adapter_sync.py`
- Read: `src/fafafa.core.simd.dispatch.pas`
- Read: `src/fafafa.core.simd.backend.adapter.map.inc`
- Read: `src/fafafa.core.simd.backend.iface.pas`

**Intent:** 增加 dispatch slot existence / base-fill coverage 校验，并把新字段纳入 summary/json。

### Task 2: 明确 adapter map 口径

**Files:**
- Modify: `src/fafafa.core.simd.backend.adapter.map.inc`

**Intent:** 在注释里明确它是 adapter-managed slots 的事实真相源，checker 会基于它做同步校验。

### Task 3: 定向验证

**Commands:**
- `python3 tests/fafafa.core.simd/check_backend_adapter_sync.py --summary-line`
- `bash tests/fafafa.core.simd/BuildOrTest.sh adapter-sync`
- `bash tests/fafafa.core.simd/BuildOrTest.sh check`

