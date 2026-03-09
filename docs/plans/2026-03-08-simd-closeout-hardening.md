# SIMD Closeout Hardening Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Close the remaining `fafafa.core.simd` Windows evidence and QEMU closeout gaps without widening scope beyond the SIMD module.

**Architecture:** Keep the current stable gate shape, but fill the missing closeout scripts and document/checklist artifacts so the Windows evidence path becomes runnable end-to-end. For QEMU, add scenario aliases at the lowest shared entry point instead of duplicating logic in callers.

**Tech Stack:** Bash, Windows batch, Python, Free Pascal test runners, Markdown.

---

### Task 1: Restore Windows evidence script chain

**Files:**
- Create: `tests/fafafa.core.simd/collect_windows_b07_evidence.bat`
- Create: `tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`
- Create: `tests/fafafa.core.simd/finalize_windows_b07_closeout.sh`
- Create: `tests/fafafa.core.simd/run_windows_b07_closeout_finalize.sh`
- Create: `tests/fafafa.core.simd/simulate_windows_b07_evidence.sh`
- Create: `tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh`

**Step 1:** Implement the missing collector/preflight/finalize helpers with the exact filenames expected by `BuildOrTest.sh` and `buildOrTest.bat`.

**Step 2:** Make the collector emit the strict verifier fields (`Source`, `HostOS`, `CmdVer`, Windows-style `Working dir`, `Command`, `GATE_EXIT_CODE`, `run_all` snapshot).

**Step 3:** Make finalize produce `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md` or `.simulated.md` using the current verifier result.

**Step 4:** Make the one-shot runner execute `finalize` → `freeze-status` → `apply`, and block `--apply` on simulated/unfinished closeout.

### Task 2: Restore freeze-status doc anchors

**Files:**
- Create: `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
- Create: `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
- Create: `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`

**Step 1:** Add the minimal checklist rows that `evaluate_simd_freeze_status.py` searches for.

**Step 2:** Keep the initial state conservative (`[ ]`) so Linux-only closeout does not pretend Windows evidence is archived.

### Task 3: Align QEMU scenario names

**Files:**
- Modify: `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh`

**Step 1:** Add aliases for `cpuinfo-nonx86-evidence`, `cpuinfo-nonx86-full-evidence`, `cpuinfo-nonx86-full-repeat`, and `cpuinfo-nonx86-suite-repeat`.

**Step 2:** Map aliases onto existing supported scenarios so `BuildOrTest.sh` no longer drifts from the Docker runner.

### Task 4: Verify the repaired SIMD closeout path

**Files:**
- Verify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Verify: `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh`

**Step 1:** Run missing-entry actions again and confirm they no longer fail with "Missing script" or "Unknown scenario".

**Step 2:** Run the strict verifier and closeout/freeze commands against available local logs.

**Step 3:** Re-run `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict` to confirm the stable gate still passes.

### Task 5: SIMD-only review handoff

**Files:**
- Update: `docs/fafafa.core.simd.closeout.md` (only if the new closeout path needs a wording fix)

**Step 1:** Summarize what was fixed, what remains opt-in, and the next SIMD-only hardening candidates.
