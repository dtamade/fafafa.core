#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SAMPLE_SCRIPT="${ROOT}/generate_gate_summary_sample.py"
BUILD_SCRIPT="${ROOT}/BuildOrTest.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

LSample="${TMP_DIR}/gate_summary.sample.mixed.md"
LJson="${TMP_DIR}/gate_summary.sample.mixed.json"

python3 "${SAMPLE_SCRIPT}" --scenario mixed --warn-ms 20000 --fail-ms 120000 --output "${LSample}"
SIMD_GATE_SUMMARY_FILE="${LSample}" bash "${BUILD_SCRIPT}" gate-summary >/dev/null
SIMD_GATE_SUMMARY_FILE="${LSample}" SIMD_GATE_SUMMARY_FILTER=FAIL bash "${BUILD_SCRIPT}" gate-summary >/dev/null
SIMD_GATE_SUMMARY_FILE="${LSample}" SIMD_GATE_SUMMARY_FILTER=SLOW SIMD_GATE_SUMMARY_JSON=1 SIMD_GATE_SUMMARY_JSON_FILE="${LJson}" bash "${BUILD_SCRIPT}" gate-summary >/dev/null

python3 - "${LJson}" <<'PY'
import json, sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
assert payload['filter'] == 'SLOW'
assert payload['matched_rows'] >= 1
PY

echo "[GATE-SUMMARY-REHEARSAL] OK"
