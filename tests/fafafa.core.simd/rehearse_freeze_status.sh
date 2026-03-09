#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
FREEZE_SCRIPT="${ROOT}/evaluate_simd_freeze_status.py"
VERIFY_SCRIPT="${ROOT}/verify_windows_b07_evidence.sh"

if [[ ! -f "${FREEZE_SCRIPT}" ]]; then
  echo "[FREEZE-REHEARSAL] Missing freeze script: ${FREEZE_SCRIPT}"
  exit 2
fi

if [[ ! -x "${VERIFY_SCRIPT}" ]]; then
  echo "[FREEZE-REHEARSAL] Missing verifier script: ${VERIFY_SCRIPT}"
  exit 2
fi

LTmpRoot="$(mktemp -d)"
cleanup() {
  rm -rf "${LTmpRoot}"
}
trap cleanup EXIT

LCaseNotReady="${LTmpRoot}/case_not_ready/tests/fafafa.core.simd"
LCaseReady="${LTmpRoot}/case_ready/tests/fafafa.core.simd"
LCaseLinuxLazy="${LTmpRoot}/case_linux_lazy/tests/fafafa.core.simd"
LCaseLinuxPlatforms="${LTmpRoot}/case_linux_platforms/tests/fafafa.core.simd"

mkdir -p "${LCaseNotReady}/logs" "${LCaseNotReady}/docs" "${LTmpRoot}/case_not_ready/docs/plans"
mkdir -p "${LCaseReady}/logs" "${LCaseReady}/docs" "${LTmpRoot}/case_ready/docs/plans"
mkdir -p "${LCaseLinuxLazy}/logs" "${LCaseLinuxLazy}/docs" "${LTmpRoot}/case_linux_lazy/docs/plans"
mkdir -p "${LCaseLinuxPlatforms}/logs" "${LCaseLinuxPlatforms}/docs" "${LTmpRoot}/case_linux_platforms/docs/plans"

cp "${FREEZE_SCRIPT}" "${LCaseNotReady}/evaluate_simd_freeze_status.py"
cp "${FREEZE_SCRIPT}" "${LCaseReady}/evaluate_simd_freeze_status.py"
cp "${FREEZE_SCRIPT}" "${LCaseLinuxLazy}/evaluate_simd_freeze_status.py"
cp "${FREEZE_SCRIPT}" "${LCaseLinuxPlatforms}/evaluate_simd_freeze_status.py"
cp "${VERIFY_SCRIPT}" "${LCaseNotReady}/verify_windows_b07_evidence.sh"
cp "${VERIFY_SCRIPT}" "${LCaseReady}/verify_windows_b07_evidence.sh"
cp "${VERIFY_SCRIPT}" "${LCaseLinuxLazy}/verify_windows_b07_evidence.sh"
cp "${VERIFY_SCRIPT}" "${LCaseLinuxPlatforms}/verify_windows_b07_evidence.sh"
chmod +x "${LCaseNotReady}/verify_windows_b07_evidence.sh" "${LCaseReady}/verify_windows_b07_evidence.sh" "${LCaseLinuxLazy}/verify_windows_b07_evidence.sh" "${LCaseLinuxPlatforms}/verify_windows_b07_evidence.sh"

# ---------- Case A: NOT READY ----------
cat > "${LCaseNotReady}/logs/gate_summary.md" <<'EOM'
| Time | Step | Status | DurationMs | Event | Detail | Artifacts |
|---|---|---|---|---|---|---|
| 2026-02-10 00:00:12 | gate | PASS | 1000 | NORMAL | all steps passed | - |
EOM

cat > "${LCaseNotReady}/logs/windows_b07_gate.simulated.log" <<'EOM'
[B07] Windows evidence capture
[B07] Command: buildOrTest.bat gate
[GATE] 1/6 Build + check SIMD module
[GATE] 2/6 SIMD list suites
[GATE] 3/6 SIMD AVX2 fallback suite
[GATE] 4/6 CPUInfo portable suites
[GATE] 5/6 CPUInfo x86 suites
[GATE] 6/6 Filtered run_all chain
[GATE] OK
[B07] GATE_EXIT_CODE=0
Total:  3
Passed: 3
Failed: 0
[B07] Total: 3
[B07] Passed: 3
[B07] Failed: 0
EOM

cat > "${LCaseNotReady}/logs/windows_b07_closeout_summary.simulated.md" <<'EOM'
# simulated summary
EOM

cat > "${LTmpRoot}/case_not_ready/docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md" <<'EOM'
- [ ] **Windows 实机证据未归档**
EOM

cat > "${LCaseNotReady}/docs/simd_release_candidate_checklist.md" <<'EOM'
- [ ] Windows 实机证据日志已归档（当前缺口）
EOM

cat > "${LCaseNotReady}/docs/simd_completeness_matrix.md" <<'EOM'
- Windows 证据：脚本入口 + 校验入口已就绪（待 Windows 实机日志）
EOM

set +e
python3 "${LCaseNotReady}/evaluate_simd_freeze_status.py" --root "${LCaseNotReady}" --json-file "${LCaseNotReady}/logs/freeze_status.json" > "${LCaseNotReady}/logs/freeze_stdout.txt" 2>&1
LNotReadyRc=$?
set -e
if [[ "${LNotReadyRc}" -eq 0 ]]; then
  echo "[FREEZE-REHEARSAL] FAILED: case_not_ready should return non-zero"
  cat "${LCaseNotReady}/logs/freeze_stdout.txt"
  exit 1
fi

if ! grep -F -- "ready=False" "${LCaseNotReady}/logs/freeze_stdout.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_not_ready missing ready=False"
  cat "${LCaseNotReady}/logs/freeze_stdout.txt"
  exit 1
fi

python3 - "${LCaseNotReady}/logs/freeze_status.json" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("ready") is not False:
    print("[FREEZE-REHEARSAL] FAILED: case_not_ready json ready should be false")
    sys.exit(1)
if payload.get("freeze_ready") is not False:
    print("[FREEZE-REHEARSAL] FAILED: case_not_ready json freeze_ready should be false")
    sys.exit(1)
if payload.get("linux_only") is not False:
    print("[FREEZE-REHEARSAL] FAILED: case_not_ready json linux_only should be false")
    sys.exit(1)
PY

# ---------- Case B: READY ----------
cat > "${LCaseReady}/logs/gate_summary.md" <<'EOM'
| Time | Step | Status | DurationMs | Event | Detail | Artifacts |
|---|---|---|---|---|---|---|
| 2026-02-10 00:00:00 | gate | START | - | START | mode=Debug | - |
| 2026-02-10 00:00:01 | build-check | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:02 | interface-completeness | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:03 | cross-backend-parity | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:04 | wiring-sync | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:05 | coverage | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:06 | simd-list-suites | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:07 | simd-avx2-fallback | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:08 | cpuinfo-portable | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:09 | cpuinfo-x86 | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:10 | run-all-chain | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:11 | evidence-verify | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:00 | gate | PASS | 1000 | NORMAL | all steps passed | - |
EOM

cat > "${LCaseReady}/logs/windows_b07_gate.log" <<'EOM'
[B07] Windows evidence capture
[B07] Source: collect_windows_b07_evidence.bat
[B07] HostOS: Windows_NT
[B07] CmdVer: Microsoft Windows [Version 10.0.22631.4602]
[B07] Started: 2026/02/10 00:00:00.00
[B07] Working dir: C:\simd\tests\fafafa.core.simd\
[B07] Command: buildOrTest.bat gate
[GATE] 1/6 Build + check SIMD module
[GATE] 2/6 SIMD list suites
[GATE] 3/6 SIMD AVX2 fallback suite
[GATE] 4/6 CPUInfo portable suites
[GATE] 5/6 CPUInfo x86 suites
[GATE] 6/6 Filtered run_all chain
[GATE] OK
[B07] GATE_EXIT_CODE=0
Total:  3
Passed: 3
Failed: 0
[B07] Total: 3
[B07] Passed: 3
[B07] Failed: 0
EOM

cat > "${LCaseReady}/logs/windows_b07_closeout_summary.md" <<'EOM'
# SIMD Windows B07 Closeout Summary

## Verification

- Verifier: verify_windows_b07_evidence.sh
- Command: bash verify_windows_b07_evidence.sh "logs/windows_b07_gate.log"
- Result: PASS
EOM

cat > "${LTmpRoot}/case_ready/docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md" <<'EOM'
- [x] **Windows 实机证据已归档**
EOM

cat > "${LCaseReady}/docs/simd_release_candidate_checklist.md" <<'EOM'
- [x] Windows 实机证据日志已归档
EOM

cat > "${LCaseReady}/docs/simd_completeness_matrix.md" <<'EOM'
- Windows 证据：实机日志已归档（脚本入口 + 校验入口）
EOM

python3 "${LCaseReady}/evaluate_simd_freeze_status.py" --root "${LCaseReady}" --json-file "${LCaseReady}/logs/freeze_status.json" > "${LCaseReady}/logs/freeze_stdout.txt" 2>&1

if ! grep -F -- "ready=True" "${LCaseReady}/logs/freeze_stdout.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_ready missing ready=True"
  cat "${LCaseReady}/logs/freeze_stdout.txt"
  exit 1
fi

python3 - "${LCaseReady}/logs/freeze_status.json" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("ready") is not True:
    print("[FREEZE-REHEARSAL] FAILED: case_ready json ready should be true")
    sys.exit(1)
if payload.get("freeze_ready") is not True:
    print("[FREEZE-REHEARSAL] FAILED: case_ready json freeze_ready should be true")
    sys.exit(1)
if payload.get("linux_only") is not False:
    print("[FREEZE-REHEARSAL] FAILED: case_ready json linux_only should be false")
    sys.exit(1)
PY

# ---------- Case C: STALE SUMMARY (must fail) ----------
cat > "${LCaseReady}/logs/windows_b07_closeout_summary.md" <<'EOM'
# SIMD Windows B07 Closeout Summary

## Verification

- Verifier: verify_windows_b07_evidence.sh
- Command: bash verify_windows_b07_evidence.sh "logs/windows_b07_gate.log"
- Result: FAIL
EOM

set +e
python3 "${LCaseReady}/evaluate_simd_freeze_status.py" --root "${LCaseReady}" --json-file "${LCaseReady}/logs/freeze_status_stale.json" > "${LCaseReady}/logs/freeze_stdout_stale.txt" 2>&1
LStaleRc=$?
set -e

if [[ "${LStaleRc}" -eq 0 ]]; then
  echo "[FREEZE-REHEARSAL] FAILED: case_stale_summary should return non-zero"
  cat "${LCaseReady}/logs/freeze_stdout_stale.txt"
  exit 1
fi

if ! grep -F -- "summary missing '- Result: PASS'" "${LCaseReady}/logs/freeze_stdout_stale.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_stale_summary missing expected stale reason"
  cat "${LCaseReady}/logs/freeze_stdout_stale.txt"
  exit 1
fi

# ---------- Case D: VERIFY FAIL + SUMMARY FAIL MARKER (summary check should pass) ----------
cat > "${LCaseReady}/logs/windows_b07_gate.log" <<'EOM'
[B07] Windows evidence capture
[B07] Started: 2026/02/10 00:00:00.00
[B07] Command: buildOrTest.bat gate
[B07] GATE_EXIT_CODE=0
[B07] Total: 3
[B07] Passed: 3
[B07] Failed: 0
EOM

cat > "${LCaseReady}/logs/windows_b07_closeout_summary.md" <<'EOM'
# SIMD Windows B07 Closeout Summary

## Verification

- Verifier: verify_windows_b07_evidence.sh
- Command: bash verify_windows_b07_evidence.sh "logs/windows_b07_gate.log"
- Result: FAIL (rc=1)
EOM

set +e
python3 "${LCaseReady}/evaluate_simd_freeze_status.py" --root "${LCaseReady}" --json-file "${LCaseReady}/logs/freeze_status_verifyfail.json" > "${LCaseReady}/logs/freeze_stdout_verifyfail.txt" 2>&1
LVerifyFailRc=$?
set -e

if [[ "${LVerifyFailRc}" -eq 0 ]]; then
  echo "[FREEZE-REHEARSAL] FAILED: case_verify_fail should return non-zero"
  cat "${LCaseReady}/logs/freeze_stdout_verifyfail.txt"
  exit 1
fi

if ! grep -F -- "windows_closeout_summary: summary matches verifier FAIL" "${LCaseReady}/logs/freeze_stdout_verifyfail.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_verify_fail summary consistency check not PASS"
  cat "${LCaseReady}/logs/freeze_stdout_verifyfail.txt"
  exit 1
fi

# ---------- Case E: LINUX-ONLY + REQUIRE CPUINFO LAZY REPEAT ----------
cat > "${LCaseLinuxLazy}/logs/gate_summary.md" <<'EOM'
| Time | Step | Status | DurationMs | Event | Detail | Artifacts |
|---|---|---|---|---|---|---|
| 2026-02-10 00:00:00 | gate | START | - | START | mode=Release | - |
| 2026-02-10 00:00:01 | build-check | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:02 | interface-completeness | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:03 | cross-backend-parity | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:04 | wiring-sync | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:05 | coverage | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:06 | simd-list-suites | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:07 | simd-avx2-fallback | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:08 | cpuinfo-portable | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:09 | cpuinfo-x86 | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:10 | run-all-chain | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:11 | gate | PASS | 1000 | NORMAL | all steps passed | - |
EOM

cat > "${LTmpRoot}/case_linux_lazy/docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md" <<'EOM'
- [ ] **Windows 实机证据未归档**
EOM

cat > "${LCaseLinuxLazy}/docs/simd_release_candidate_checklist.md" <<'EOM'
- [ ] Windows 实机证据日志已归档（当前缺口）
EOM

cat > "${LCaseLinuxLazy}/docs/simd_completeness_matrix.md" <<'EOM'
- Windows 证据：脚本入口 + 校验入口已就绪（待 Windows 实机日志）
EOM

set +e
SIMD_FREEZE_REQUIRE_CPUINFO_LAZY_REPEAT=1 \
python3 "${LCaseLinuxLazy}/evaluate_simd_freeze_status.py" --linux-only --root "${LCaseLinuxLazy}" --json-file "${LCaseLinuxLazy}/logs/freeze_status_lazy_missing.json" > "${LCaseLinuxLazy}/logs/freeze_stdout_lazy_missing.txt" 2>&1
LLazyMissingRc=$?
set -e

if [[ "${LLazyMissingRc}" -eq 0 ]]; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_lazy missing-step should return non-zero"
  cat "${LCaseLinuxLazy}/logs/freeze_stdout_lazy_missing.txt"
  exit 1
fi

if ! grep -F -- "linux_cpuinfo_lazy_repeat" "${LCaseLinuxLazy}/logs/freeze_stdout_lazy_missing.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_lazy missing-step should report linux_cpuinfo_lazy_repeat"
  cat "${LCaseLinuxLazy}/logs/freeze_stdout_lazy_missing.txt"
  exit 1
fi

cat > "${LCaseLinuxLazy}/logs/gate_summary.md" <<'EOM'
| Time | Step | Status | DurationMs | Event | Detail | Artifacts |
|---|---|---|---|---|---|---|
| 2026-02-10 00:00:00 | gate | START | - | START | mode=Release | - |
| 2026-02-10 00:00:01 | build-check | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:02 | interface-completeness | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:03 | cross-backend-parity | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:04 | wiring-sync | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:05 | coverage | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:06 | simd-list-suites | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:07 | simd-avx2-fallback | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:08 | cpuinfo-portable | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:09 | cpuinfo-x86 | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:10 | run-all-chain | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:11 | cpuinfo-lazy-repeat | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:12 | gate | PASS | 1000 | NORMAL | all steps passed | - |
EOM

SIMD_FREEZE_REQUIRE_CPUINFO_LAZY_REPEAT=1 \
python3 "${LCaseLinuxLazy}/evaluate_simd_freeze_status.py" --linux-only --root "${LCaseLinuxLazy}" --json-file "${LCaseLinuxLazy}/logs/freeze_status_lazy_pass.json" > "${LCaseLinuxLazy}/logs/freeze_stdout_lazy_pass.txt" 2>&1

if ! grep -F -- "ready=True" "${LCaseLinuxLazy}/logs/freeze_stdout_lazy_pass.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_lazy pass-step missing ready=True"
  cat "${LCaseLinuxLazy}/logs/freeze_stdout_lazy_pass.txt"
  exit 1
fi

if ! grep -F -- "linux_cpuinfo_lazy_repeat: step PASS" "${LCaseLinuxLazy}/logs/freeze_stdout_lazy_pass.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_lazy pass-step missing linux_cpuinfo_lazy_repeat PASS"
  cat "${LCaseLinuxLazy}/logs/freeze_stdout_lazy_pass.txt"
  exit 1
fi

python3 - "${LCaseLinuxLazy}/logs/freeze_status_lazy_pass.json" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("ready") is not True:
    print("[FREEZE-REHEARSAL] FAILED: case_linux_lazy pass-step json ready should be true")
    sys.exit(1)
if payload.get("freeze_ready") is not True:
    print("[FREEZE-REHEARSAL] FAILED: case_linux_lazy pass-step json freeze_ready should be true")
    sys.exit(1)
if payload.get("linux_only") is not True:
    print("[FREEZE-REHEARSAL] FAILED: case_linux_lazy pass-step json linux_only should be true")
    sys.exit(1)
PY

# ---------- Case F: LINUX-ONLY + REQUIRE QEMU CPUINFO NONX86 PLATFORM COVERAGE ----------
cat > "${LCaseLinuxPlatforms}/logs/gate_summary.md" <<'EOM'
| Time | Step | Status | DurationMs | Event | Detail | Artifacts |
|---|---|---|---|---|---|---|
| 2026-02-10 00:00:00 | gate | START | - | START | mode=Release | - |
| 2026-02-10 00:00:01 | build-check | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:02 | interface-completeness | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:03 | cross-backend-parity | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:04 | wiring-sync | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:05 | coverage | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:06 | simd-list-suites | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:07 | simd-avx2-fallback | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:08 | cpuinfo-portable | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:09 | cpuinfo-x86 | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:10 | run-all-chain | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:11 | qemu-cpuinfo-nonx86-evidence | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:12 | qemu-cpuinfo-nonx86-full-evidence | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:13 | qemu-cpuinfo-nonx86-full-repeat | PASS | 100 | NORMAL | ok | - |
| 2026-02-10 00:00:14 | gate | PASS | 1000 | NORMAL | all steps passed | - |
EOM

cat > "${LTmpRoot}/case_linux_platforms/docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md" <<'EOM'
- [ ] **Windows 实机证据未归档**
EOM

cat > "${LCaseLinuxPlatforms}/docs/simd_release_candidate_checklist.md" <<'EOM'
- [ ] Windows 实机证据日志已归档（当前缺口）
EOM

cat > "${LCaseLinuxPlatforms}/docs/simd_completeness_matrix.md" <<'EOM'
- Windows 证据：脚本入口 + 校验入口已就绪（待 Windows 实机日志）
EOM

mkdir -p "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000010"
mkdir -p "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000011"
mkdir -p "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000012"
cat > "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000010/summary.md" <<'EOM'
# SIMD QEMU Multiarch Report

- time: 2026-02-10T00:00:10+08:00
- scenario: cpuinfo-nonx86-evidence
- platforms: linux/arm64 linux/riscv64

| Platform | Status | Log |
|---|---|---|
| linux/arm64 | PASS | `arm64.log` |
| linux/riscv64 | PASS | `riscv64.log` |
EOM
cat > "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000011/summary.md" <<'EOM'
# SIMD QEMU Multiarch Report

- time: 2026-02-10T00:00:11+08:00
- scenario: cpuinfo-nonx86-full-evidence
- platforms: linux/arm64 linux/riscv64

| Platform | Status | Log |
|---|---|---|
| linux/arm64 | PASS | `arm64.log` |
| linux/riscv64 | PASS | `riscv64.log` |
EOM
cat > "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000012/summary.md" <<'EOM'
# SIMD QEMU Multiarch Report

- time: 2026-02-10T00:00:12+08:00
- scenario: cpuinfo-nonx86-full-repeat
- platforms: linux/arm64 linux/riscv64

| Platform | Status | Log |
|---|---|---|
| linux/arm64 | PASS | `arm64.log` |
| linux/riscv64 | PASS | `riscv64.log` |
EOM

set +e
SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_EVIDENCE=1 \
SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=1 \
SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_FULL_REPEAT=1 \
python3 "${LCaseLinuxPlatforms}/evaluate_simd_freeze_status.py" --linux-only --root "${LCaseLinuxPlatforms}" --json-file "${LCaseLinuxPlatforms}/logs/freeze_status_platform_missing.json" > "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_missing.txt" 2>&1
LPlatformMissingRc=$?
set -e

if [[ "${LPlatformMissingRc}" -eq 0 ]]; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_platforms missing arm-v7 should return non-zero"
  cat "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_missing.txt"
  exit 1
fi

if ! grep -F -- "linux_qemu_cpuinfo_nonx86_full_evidence_platforms" "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_missing.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_platforms missing platform-check output for full-evidence"
  cat "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_missing.txt"
  exit 1
fi

if ! grep -F -- "linux_qemu_cpuinfo_nonx86_evidence_platforms" "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_missing.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_platforms missing platform-check output for nonx86-evidence"
  cat "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_missing.txt"
  exit 1
fi

if ! grep -F -- "linux_qemu_cpuinfo_nonx86_full_repeat_platforms" "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_missing.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_platforms missing platform-check output for full-repeat"
  cat "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_missing.txt"
  exit 1
fi

cat > "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000010/summary.md" <<'EOM'
# SIMD QEMU Multiarch Report

- time: 2026-02-10T00:00:10+08:00
- scenario: cpuinfo-nonx86-evidence
- platforms: linux/arm/v7 linux/arm64 linux/riscv64

| Platform | Status | Log |
|---|---|---|
| linux/arm/v7 | PASS | `arm-v7.log` |
| linux/arm64 | PASS | `arm64.log` |
| linux/riscv64 | PASS | `riscv64.log` |
EOM
cat > "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000011/summary.md" <<'EOM'
# SIMD QEMU Multiarch Report

- time: 2026-02-10T00:00:11+08:00
- scenario: cpuinfo-nonx86-full-evidence
- platforms: linux/arm/v7 linux/arm64 linux/riscv64

| Platform | Status | Log |
|---|---|---|
| linux/arm/v7 | PASS | `arm-v7.log` |
| linux/arm64 | PASS | `arm64.log` |
| linux/riscv64 | PASS | `riscv64.log` |
EOM
cat > "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000012/summary.md" <<'EOM'
# SIMD QEMU Multiarch Report

- time: 2026-02-10T00:00:12+08:00
- scenario: cpuinfo-nonx86-full-repeat
- platforms: linux/arm/v7 linux/arm64 linux/riscv64

| Platform | Status | Log |
|---|---|---|
| linux/arm/v7 | PASS | `arm-v7.log` |
| linux/arm64 | PASS | `arm64.log` |
| linux/riscv64 | PASS | `riscv64.log` |
EOM

SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_EVIDENCE=1 \
SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=1 \
SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_FULL_REPEAT=1 \
python3 "${LCaseLinuxPlatforms}/evaluate_simd_freeze_status.py" --linux-only --root "${LCaseLinuxPlatforms}" --json-file "${LCaseLinuxPlatforms}/logs/freeze_status_platform_pass.json" > "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_pass.txt" 2>&1

if ! grep -F -- "ready=True" "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_pass.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_platforms full coverage should produce ready=True"
  cat "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_pass.txt"
  exit 1
fi

# Newer incomplete summaries must not override gate-step aligned evidence.
mkdir -p "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000020"
mkdir -p "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000021"
mkdir -p "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000022"
cat > "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000020/summary.md" <<'EOM'
# SIMD QEMU Multiarch Report

- time: 2026-02-10T00:00:20+08:00
- scenario: cpuinfo-nonx86-evidence
- platforms: linux/arm64 linux/riscv64

| Platform | Status | Log |
|---|---|---|
| linux/arm64 | PASS | `arm64.log` |
| linux/riscv64 | PASS | `riscv64.log` |
EOM
cat > "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000021/summary.md" <<'EOM'
# SIMD QEMU Multiarch Report

- time: 2026-02-10T00:00:21+08:00
- scenario: cpuinfo-nonx86-full-evidence
- platforms: linux/arm64 linux/riscv64

| Platform | Status | Log |
|---|---|---|
| linux/arm64 | PASS | `arm64.log` |
| linux/riscv64 | PASS | `riscv64.log` |
EOM
cat > "${LCaseLinuxPlatforms}/logs/qemu-multiarch-20260210-000022/summary.md" <<'EOM'
# SIMD QEMU Multiarch Report

- time: 2026-02-10T00:00:22+08:00
- scenario: cpuinfo-nonx86-full-repeat
- platforms: linux/arm64 linux/riscv64

| Platform | Status | Log |
|---|---|---|
| linux/arm64 | PASS | `arm64.log` |
| linux/riscv64 | PASS | `riscv64.log` |
EOM

SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_EVIDENCE=1 \
SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=1 \
SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_FULL_REPEAT=1 \
python3 "${LCaseLinuxPlatforms}/evaluate_simd_freeze_status.py" --linux-only --root "${LCaseLinuxPlatforms}" --json-file "${LCaseLinuxPlatforms}/logs/freeze_status_platform_anchor.json" > "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_anchor.txt" 2>&1

if ! grep -F -- "ready=True" "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_anchor.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_platforms anchor check should stay ready=True"
  cat "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_anchor.txt"
  exit 1
fi

if grep -F -- "qemu-multiarch-20260210-000020" "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_anchor.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_platforms anchor check selected newer incomplete nonx86-evidence summary"
  cat "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_anchor.txt"
  exit 1
fi

if grep -F -- "qemu-multiarch-20260210-000021" "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_anchor.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_platforms anchor check selected newer incomplete nonx86-full-evidence summary"
  cat "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_anchor.txt"
  exit 1
fi

if grep -F -- "qemu-multiarch-20260210-000022" "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_anchor.txt" >/dev/null; then
  echo "[FREEZE-REHEARSAL] FAILED: case_linux_platforms anchor check selected newer incomplete nonx86-full-repeat summary"
  cat "${LCaseLinuxPlatforms}/logs/freeze_stdout_platform_anchor.txt"
  exit 1
fi

echo "[FREEZE-REHEARSAL] OK"
echo "[FREEZE-REHEARSAL] case_not_ready_rc=${LNotReadyRc}"
echo "[FREEZE-REHEARSAL] case_stale_summary_rc=${LStaleRc}"
echo "[FREEZE-REHEARSAL] case_verify_fail_rc=${LVerifyFailRc}"
echo "[FREEZE-REHEARSAL] case_linux_lazy_missing_rc=${LLazyMissingRc}"
echo "[FREEZE-REHEARSAL] case_linux_platform_missing_rc=${LPlatformMissingRc}"
