# SIMD Full-Platform Completeness Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Bring `fafafa.core.simd` from “Linux ready, cross-platform pending” to a state where cross-platform freeze can honestly be reported as ready.

**Architecture:** Keep the current stable shape: public façade + `TSimdDispatchTable` remain the ABI truth, helper/checker scripts remain the enforcement layer, and Windows closeout is completed by supplying real evidence rather than weakening verifiers. The plan assumes Linux-side runtime/gate/helper fixes are already in place and focuses on the remaining Windows evidence gap plus final no-regression verification.

**Tech Stack:** FreePascal, Lazarus `lazbuild`, Bash, Windows batch, Python gate/checker scripts, Markdown closeout docs

---

## Success Criteria

Cross-platform completeness is achieved only when **all** of the following are true:

1. Linux gate remains green.
2. `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux` returns `ready=True`.
3. `tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify` passes on a real Windows host.
4. `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence` produces a real, non-simulated closeout summary.
5. `bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --batch-id SIMD-YYYYMMDD-152` updates the Windows checklist/roadmap artifacts.
6. `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` returns `ready=False` no longer; it must return `ready=True`.

If item 3 is missing, the module is **not** fully complete across platforms.

---

### Task 1: Freeze the current completeness contract

**Files:**
- Review: `docs/fafafa.core.simd.closeout.md`
- Review: `docs/fafafa.core.simd.maintenance.md`
- Review: `src/fafafa.core.simd.STABLE`
- Review: `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
- Review: `tests/fafafa.core.simd/verify_windows_b07_evidence.sh`

**Step 1: Confirm Linux/mainline is already the baseline**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux
```

Expected:
- `gate-strict` ends with `[GATE] OK`
- `freeze-status-linux` reports `ready=True`

**Step 2: Confirm the only blocker is Windows real evidence**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status
```

Expected:
- `ready=False`
- failure/pending items are limited to Windows evidence verification and the Windows closeout docs/checklists

**Step 3: Record the current blocker explicitly**

Write into the working log that cross-platform completeness is blocked by real Windows evidence, not by Linux gate, slot drift, or adapter drift.

---

### Task 2: Keep the Linux-side no-regression path locked

**Files:**
- Verify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Verify: `tests/fafafa.core.simd/buildOrTest.bat`
- Verify: `tests/fafafa.core.simd/run_backend_benchmarks.sh`
- Verify: `tests/fafafa.core.simd/collect_linux_simd_evidence.sh`
- Verify: `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh`
- Verify: `tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh`
- Verify: `tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh`

**Step 1: Re-run helper-level Linux evidence**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux
```

Expected:
- command exits `0`
- a new `tests/fafafa.core.simd/logs/evidence-*/summary.md` is created

**Step 2: Re-run isolated main gate once**

Run:
```bash
SIMD_OUTPUT_ROOT=/tmp/simd-cross-platform-audit bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

Expected:
- command exits `0`
- `cpuinfo` and `cpuinfo.x86` artifacts are created under the isolated root instead of polluting default `bin2/lib2/logs`

**Step 3: Re-run backend bench in isolation**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh backend-bench
```

Expected:
- command exits `0`
- no `DBG_/DEBUGSTART` linker failures recur

---

### Task 3: Validate the Windows evidence collection contract before touching docs

**Files:**
- Verify: `tests/fafafa.core.simd/collect_windows_b07_evidence.bat`
- Verify: `tests/fafafa.core.simd/verify_windows_b07_evidence.bat`
- Verify: `tests/fafafa.core.simd/verify_windows_b07_evidence.sh`
- Verify: `tests/fafafa.core.simd/buildOrTest.bat`
- Review: `docs/fafafa.core.simd.closeout.md`

**Step 1: Check the required evidence fields**

Required lines in the real Windows log:
- `Source: collect_windows_b07_evidence.bat`
- `HostOS: Windows_NT`
- `CmdVer: Microsoft Windows ...`
- `Working dir: C:\...`

**Step 2: Dry-run the exact operator command text**

Run on Windows:
```bat
tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify
```

Expected:
- the batch script performs collection and verification in one flow
- resulting log satisfies the shell verifier without manual editing

**Step 3: Refuse any shortcut that weakens the verifier**

Do **not**:
- relax `verify_windows_b07_evidence.sh`
- replace missing real fields with simulated lines
- mark docs complete before the real verifier passes

---

### Task 4: Capture real Windows evidence

**Files:**
- Produce: `tests/fafafa.core.simd/logs/windows_b07_gate.log`
- Verify: `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`

**Step 1: Run the real Windows collector/verifier**

Run on Windows:
```bat
tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify
```

Expected:
- exit code `0`
- `tests/fafafa.core.simd/logs/windows_b07_gate.log` is refreshed from a real Windows host

**Step 2: Confirm the log is not simulated**

Inspect the log and verify that it is sourced from `collect_windows_b07_evidence.bat`, not from the simulator.

**Step 3: Preserve the batch id used for final apply**

Choose a real batch id, for example:
```text
SIMD-20260309-152
```

Do not invent one in the doc without matching the summary/apply step.

---

### Task 5: Finalize Windows closeout and update the docs/checklists

**Files:**
- Modify: `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
- Modify: `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`
- Modify: `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
- Verify: `tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh`
- Verify: `tests/fafafa.core.simd/finalize_windows_b07_closeout.sh`

**Step 1: Generate the real closeout summary**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence
```

Expected:
- produces `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`
- summary is not simulated

**Step 2: Apply the Windows closeout doc updates**

Run:
```bash
bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --batch-id SIMD-YYYYMMDD-152
```

Expected:
- roadmap, RC checklist, and completeness matrix are marked complete for Windows evidence
- apply step refuses to run if the summary is simulated

**Step 3: Verify the three docs changed as intended**

Look for:
- Windows evidence marked `[x]`
- batch id recorded
- summary filename recorded

---

### Task 6: Re-evaluate full-platform freeze readiness

**Files:**
- Verify: `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
- Verify: `tests/fafafa.core.simd/logs/freeze_status.json`

**Step 1: Re-run cross-platform freeze status**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status
```

Expected:
- `ready=True`
- no pending Windows checklist items remain

**Step 2: Archive the resulting JSON**

Confirm `tests/fafafa.core.simd/logs/freeze_status.json` reflects the ready state.

**Step 3: Only now call the module fully complete**

The phrase “SIMD is complete across platforms” is only valid after this step passes.

---

### Task 7: Final acceptance report

**Files:**
- Update: `docs/fafafa.core.simd.handoff.md`
- Update: `findings.md`
- Update: `progress.md`

**Step 1: Write the acceptance summary**

Capture:
- interface status
- architecture status
- implementation status
- test validation status
- exact Windows evidence commands used

**Step 2: Record evidence paths**

At minimum record:
- latest Linux evidence summary path
- latest backend bench summary path
- `windows_b07_gate.log`
- `windows_b07_closeout_summary.md`
- `freeze_status.json`

**Step 3: State the final platform claim precisely**

Use one of these exact outcomes:
- `Linux ready, cross-platform pending`
- `Cross-platform ready`

Do not use ambiguous wording.

---

## Risks

- The remaining blocker is operational, not architectural: no Windows real evidence means the closeout cannot be honestly completed.
- Windows batch runners were aligned for automation, but without a real Windows run they remain partially unverified.
- `sbRISCVV` remains experimental and should not be used as the definition of stable/platform-complete support.

## Minimal completion path

If the goal is strictly “make the platform completeness claim true with minimum additional work”, the critical path is:

1. Windows `evidence-win-verify`
2. `FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
3. `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-YYYYMMDD-152`
4. `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`

Everything else is already in place on the Linux side.
