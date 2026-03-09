# SIMD Complete Landing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 让 `fafafa.core.simd` 在 Linux/x86_64 下完整通过 `check/test/gate`（含 wiring-sync + strict coverage + perf-smoke），并把跨平台冻结（Windows 证据）收口动作固化为可复制执行的闭环步骤与证据产物。

**Architecture:** 以 `tests/fafafa.core.simd/BuildOrTest.sh` 作为唯一“门禁入口”，优先修复会导致门禁失败的环境/脚本问题；功能行为变更必须走严格 TDD；Windows 证据闭环不在 Linux 侧造假，只提供一键脚本与校验器链路。

**Tech Stack:** FreePascal/FPC + Lazarus/lazbuild，Bash，Python3。

---

## Agent Team（角色分工）
- **Implementer（代码）**：只做最小改动让门禁恢复绿；所有行为变化必须先写失败测试再修复（严格 TDD）。
- **Reviewer（审查）**：检查是否触碰 `src/fafafa.core.simd.STABLE` 的稳定性约束、是否引入 warning/hint、是否破坏 dispatch table 布局与跨平台语义。
- **Coordinator（推进/计划）**：维护 `task_plan.md/findings.md/progress.md`，确保每一步命令与输出可追溯；遇到 Windows-only 阻塞时立即停下并给“复制即跑”闭环命令。

### Task 1: Linux SIMD Gate（全链路，strict）

**Files:**
- Verify: `tests/fafafa.core.simd/BuildOrTest.sh`
- Logs (ignored): `tests/fafafa.core.simd/logs/`

**Step 1: Baseline check（必须先跑）**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
```

Expected:
- `[BUILD] OK`
- `[CHECK] OK (no SIMD-unit warnings/hints)`

**Step 2: Gate（开启 wiring-sync + strict coverage + perf-smoke）**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

Expected:
- `[GATE] OK`
- wiring-sync summary `missing=0 extra=0 markers_missing=0`
- coverage summary `missing=0 extra=0`
- perf-smoke `OK` 或 Scalar 时 `SKIP`

**Step 3: Freeze status（Linux-only）**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux
```

Expected:
- `ready=True`

**Step 4: Evidence（Linux）**

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux
```

Expected:
- 输出 `EVIDENCE DONE: .../logs/evidence-*/`
- 输出 `EVIDENCE SUMMARY: .../summary.md`

---

### Task 2: Windows Evidence Closeout（跨平台冻结，需 Windows 实机）

**Files:**
- Read: `docs/plans/2026-02-09-simd-windows-closeout-checklist.md`
- Evidence log (generated): `tests/fafafa.core.simd/logs/windows_b07_gate.log`
- Summary (generated): `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`
- Updater: `tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh`
- Verifier: `tests/fafafa.core.simd/verify_windows_b07_evidence.sh`

**Step 1: 输出“复制即跑”三命令**

Run (Linux):
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-<YYYYMMDD>-<NNN>
```

Expected:
- 打印 PowerShell + Git Bash/WSL 3 条命令。

**Step 2: Windows 实机执行（需要用户提供日志产物）**

Run (Windows PowerShell):
```bat
tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify
```

Then (Git Bash / WSL):
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence
bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --batch-id SIMD-<YYYYMMDD>-<NNN>
```

Expected:
- `tests/fafafa.core.simd/logs/windows_b07_gate.log` 存在且包含 `GATE OK`
- `freeze-status`（cross-platform）输出 `ready=True`

**Stop Condition (blocker):**
- 如果没有 Windows 环境或无法产出 `windows_b07_gate.log`，此任务只能保持 PENDING，禁止用 simulated log 关闭 P0。
