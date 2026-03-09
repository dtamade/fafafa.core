#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
EVAL_SCRIPT="${ROOT}/evaluate_simd_freeze_status.py"
TMP_WORK="$(mktemp -d)"
TMP_ROOT="${TMP_WORK}/tests/fafafa.core.simd"
TMP_REPO_ROOT="${TMP_WORK}"
trap 'rm -rf "${TMP_WORK}"' EXIT

if [[ ! -f "${EVAL_SCRIPT}" ]]; then
  echo "[FREEZE-REHEARSAL] Missing evaluator: ${EVAL_SCRIPT}"
  exit 2
fi

mkdir -p "${TMP_ROOT}/logs" "${TMP_ROOT}/docs" "${TMP_REPO_ROOT}/docs/plans"
cp "${ROOT}/verify_windows_b07_evidence.sh" "${TMP_ROOT}/verify_windows_b07_evidence.sh"

cat > "${TMP_ROOT}/logs/gate_summary.md" <<'EOM'
# SIMD Gate Summary

| Time | Step | Status | Duration(ms) | Event | Detail | Artifacts |
|---|---|---|---:|---|---|---|
| 2026-03-08 08:08:17 | gate | PASS | 171624 | SLOW_CRIT | all steps passed | gate_summary.md |
EOM

cat > "${TMP_ROOT}/logs/windows_b07_gate.log" <<'EOM'
[B07] Windows evidence capture
[B07] Source: collect_windows_b07_evidence.bat
[B07] HostOS: Windows_NT
[B07] CmdVer: Microsoft Windows [Version 10.0.22631.4890]
[B07] Started: 2026-03-08 08:10:00 +0800
[B07] Working dir: C:\repo\fafafa.core\tests\fafafa.core.simd
[B07] Command: buildOrTest.bat gate

[GATE] OK

[B07] GATE_EXIT_CODE=0
[B07] Total: 4
[B07] Passed: 4
[B07] Failed: 0
EOM

cat > "${TMP_ROOT}/logs/windows_b07_closeout_summary.md" <<'EOM'
# SIMD Windows B07 Closeout Summary

- Generated: 2026-03-08 08:12:00 +0800
- Batch Id: SIMD-20260308-152
- Evidence Log: tests/fafafa.core.simd/logs/windows_b07_gate.log
- [B07] Started: 2026-03-08 08:10:00 +0800
- [B07] GATE_EXIT_CODE=0
EOM

cat > "${TMP_ROOT}/docs/simd_completeness_matrix.md" <<'EOM'
# SIMD completeness matrix
- [x] Windows 实机证据已归档（batch=SIMD-20260308-152，summary=windows_b07_closeout_summary.md）
EOM

cat > "${TMP_ROOT}/docs/simd_release_candidate_checklist.md" <<'EOM'
# SIMD release candidate checklist
- [x] Windows 实机证据日志已归档（batch=SIMD-20260308-152，summary=windows_b07_closeout_summary.md）
EOM

cat > "${TMP_REPO_ROOT}/docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md" <<'EOM'
- [x] Windows 实机证据（batch=SIMD-20260308-152，summary=windows_b07_closeout_summary.md）
EOM

JSON_PATH="${TMP_ROOT}/logs/freeze_status.rehearsal.json"
set +e
OUTPUT="$(python3 "${EVAL_SCRIPT}" --root "${TMP_ROOT}" --json-file "${JSON_PATH}" 2>&1)"
RC=$?
set -e
if [[ "${RC}" != "0" ]]; then
  printf '%s\n' "${OUTPUT}"
  echo "[FREEZE-REHEARSAL] FAILED: evaluator returned rc=${RC}"
  exit "${RC}"
fi

if ! printf '%s\n' "${OUTPUT}" | grep -q '^\[FREEZE\] mode=cross-platform, ready=True$'; then
  printf '%s\n' "${OUTPUT}"
  echo "[FREEZE-REHEARSAL] FAILED: ready=True not observed"
  exit 1
fi

if ! python3 - "${JSON_PATH}" <<'PY2'
import json, sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
assert payload['freeze_ready'] is True
checks = {item['name']: item['status'] for item in payload['checks']}
required = {
    'linux_gate_summary': 'PASS',
    'windows_evidence_log': 'PASS',
    'windows_evidence_verify': 'PASS',
    'windows_closeout_summary': 'PASS',
}
for key, value in required.items():
    assert checks.get(key) == value, (key, checks.get(key), value)
PY2
then
  echo "[FREEZE-REHEARSAL] FAILED: JSON contract mismatch"
  exit 1
fi

echo "[FREEZE-REHEARSAL] OK"
