# SIMD Full Closure Wave Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Close SIMD interface/implementation/test completeness with machine-verifiable evidence across x86 and non-x86 lanes.

**Architecture:** Add a dispatch-wide slot assignment suite, wire it into the SIMD test runner, close completeness scanner P2 items, and produce fresh multi-arch QEMU evidence for arm/arm64/riscv64.

**Tech Stack:** FreePascal/FPCUnit, Lazarus `lazbuild`, Bash + Docker Buildx, project scripts under `tests/fafafa.core.simd`.

---

### Task 1: Dispatch Full-Slot Contract Suite

**Files:**
- Create: `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas`
- Modify: `tests/fafafa.core.simd/fafafa.core.simd.test.lpr`

**Steps:**
1. Generate full-slot assertions from `TSimdDispatchTable` declarations.
2. Run `TTestCase_DispatchAllSlots` and ensure all selectable backends pass.
3. Verify `TTestCase_DispatchAPI` regression remains green.

### Task 2: Completeness Scanner Closure

**Files:**
- Use: `tests/fafafa.core.simd/check_interface_implementation_completeness.py`

**Steps:**
1. Run strict completeness scan.
2. Confirm `P0=0 / P1=0 / P2=0`.

### Task 3: Multi-arch Evidence (arm/arm64/riscv64)

**Files:**
- Modify: `tests/fafafa.core.simd/docker/Dockerfile`
- Use: `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh`

**Steps:**
1. Fix Docker arm base stage (`base-arm`) for `linux/arm` builds.
2. Run `qemu-nonx86-evidence` on `linux/arm linux/arm64 linux/riscv64`.
3. Ensure summary marks all requested platforms `PASS`.

### Task 4: Gate + Documentation Closure

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

**Steps:**
1. Run `gate-strict` after test/code changes.
2. Append a new step entry with commands and evidence paths.
