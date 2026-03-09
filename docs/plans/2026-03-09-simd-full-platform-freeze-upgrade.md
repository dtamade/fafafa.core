# SIMD Full-Platform Freeze Upgrade Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把当前只覆盖 Linux+Windows closeout 的 `freeze-status` 升级成同时能回答 `cross-platform` 与 `full-platform` 的正式状态入口。

**Architecture:** 保留现有 `cross-platform` 逻辑不变，新增 `full-platform` 模式和最小 required 集合：fresh stable QEMU arch matrix、fresh non-x86 CPUInfo full evidence、fresh RISCVV dedicated lane。实现上优先扩展现有 evaluator/BuildOrTest，而不是另起一套平行脚本。

**Tech Stack:** Python evaluator、Bash/Batch wrappers、Markdown docs/checklists、SIMD evidence summaries under `tests/fafafa.core.simd/logs/`.

---

### Task 1: Freeze current evaluator contract

**Files:**
- Review: `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
- Review: `tests/fafafa.core.simd/BuildOrTest.sh`
- Review: `docs/fafafa.core.simd.handoff.md`
- Review: `docs/fafafa.core.simd.closeout.md`

**Step 1: Record current modes and outputs**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux
```

Expected:
- existing `cross-platform` output stays unchanged
- linux-only output still reports current Linux gate readiness

**Step 2: Identify required inputs for new full-platform mode**

Required evidence:
- latest PASS `qemu-arch-matrix-evidence`
- latest PASS `qemu-cpuinfo-nonx86-full-evidence`
- latest PASS `riscvv-opcode-lane` with compile PASS and stable smoke PASS
- existing real Windows evidence remains required only for `cross-platform ready`

### Task 2: Extend evaluator with `--mode full-platform`

**Files:**
- Modify: `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
- Verify: `tests/fafafa.core.simd/logs/qemu-multiarch-20260309-092825-2802652/summary.md`
- Verify: `tests/fafafa.core.simd/logs/qemu-multiarch-20260309-085950-2782967/summary.md`
- Verify: `tests/fafafa.core.simd/logs/rvv-opcode-lane-20260309-091241/summary.md`

**Step 1: Add mode parser support**
- Accept `--mode cross-platform|linux|full-platform`
- Keep default as `cross-platform`

**Step 2: Add evidence readers**
- Reuse current log scanning style to locate latest matching summary
- Parse PASS/FAIL from QEMU summary tables
- Parse RVV lane layered acceptance table and require:
  - `compile-only=PASS`
  - `stable-smoke/suite=PASS`
  - `bench` may be `SKIP`

**Step 3: Emit explicit full-platform checks**
- `qemu_arch_matrix`
- `qemu_cpuinfo_nonx86_full`
- `riscvv_opcode_lane`
- overall `ready=True/False`

### Task 3: Add wrapper entry points

**Files:**
- Modify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Modify: `tests/fafafa.core.simd/buildOrTest.bat`

**Step 1: Add `freeze-status-full-platform` action**
- shell + batch both expose it
- call evaluator with `--mode full-platform`

**Step 2: Keep current actions stable**
- `freeze-status` stays cross-platform
- `freeze-status-linux` stays linux-only

### Task 4: Update docs to use the new status vocabulary

**Files:**
- Modify: `docs/fafafa.core.simd.handoff.md`
- Modify: `docs/fafafa.core.simd.closeout.md`
- Modify: `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
- Modify: `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`

**Step 1: State both statuses clearly**
- `cross-platform ready`
- `full-platform ready`

**Step 2: Make RVV bench opt-in wording explicit**
- do not imply bench PASS is required for full-platform mode yet

### Task 5: Verify the upgraded status model

**Files:**
- Verify: `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`

**Step 1: Run legacy modes**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux
```

Expected:
- old outputs still work

**Step 2: Run new mode**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-full-platform
python3 tests/fafafa.core.simd/evaluate_simd_freeze_status.py --mode full-platform
```

Expected:
- reports `ready=True`
- shows explicit PASS lines for fresh QEMU arch matrix / CPUInfo full / RVV lane

