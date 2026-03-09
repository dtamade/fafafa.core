# SIMD Stabilization Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore `fafafa.core.simd` buildability, close stale-gate gaps, and realign docs/runtime boundaries for the current stable surface.

**Architecture:** Keep `TSimdDispatchTable` as the current authoritative ABI surface, patch the missing slots so existing backend registrations compile again, harden the test gate so stale binaries cannot mask source regressions, and update docs/runtime exposure to match the actual supported surface. Avoid broad refactors; fix root-cause drift and tighten guardrails.

**Tech Stack:** Free Pascal, Lazarus build scripts, Python gate checker, Markdown docs.

---

### Task 1: Patch dispatch-table schema drift
- Modify: `src/fafafa.core.simd.dispatch.pas`
- Verify: `src/fafafa.core.simd.avx2.pas`, `src/fafafa.core.simd.pas`, `src/fafafa.core.simd.STABLE`
- Goal: Add the missing `TSimdDispatchTable` fields and scalar base assignments for the slots already used by AVX2/public facade.

### Task 2: Harden gate freshness
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/buildOrTest.bat`
- Goal: Ensure `adapter-sync` rebuilds before running checks so stale binaries cannot hide compile failures.

### Task 3: Realign experimental backend exposure
- Modify: `src/fafafa.core.simd.pas`
- Verify: `src/fafafa.core.simd.base.pas`
- Goal: Require an explicit opt-in macro before wiring `sbRISCVV` into the umbrella unit.

### Task 4: Fix doc drift
- Modify: `src/fafafa.core.simd.README.md`
- Modify: `docs/fafafa.core.simd.md`
- Modify: `docs/fafafa.core.simd.maintenance.md`
- Create: `docs/fafafa.core.simd.map.md`
- Create: `docs/fafafa.core.simd.handoff.md`
- Goal: Make referenced docs exist and remove references to non-existent include files.

### Task 5: Validate the repair
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh check`
- Run: `bash tests/fafafa.core.simd/BuildOrTest.sh adapter-sync`
- Run: `bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh`
- Goal: Confirm build, gate freshness, and cpuinfo regression are all green.
