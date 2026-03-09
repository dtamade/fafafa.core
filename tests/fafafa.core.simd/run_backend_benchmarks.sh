#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
LOG_ROOT="${ROOT}/logs"
TS="$(date +%Y%m%d-%H%M%S)-$$"
REPORT_DIR="${LOG_ROOT}/backend-bench-${TS}"
TMP_BUILD_LOG="${REPORT_DIR}/_build.log"
TMP_RUN_LOG="${REPORT_DIR}/_run.log"
RUNNER_LOG="${REPORT_DIR}/runner.log"
SUMMARY_FILE="${REPORT_DIR}/summary.md"
PROJECT="${ROOT}/fafafa.core.simd.test.lpr"
FPC_BIN="${FPC_BIN:-fpc}"
TARGET_CPU="$(${FPC_BIN} -iTP 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
TARGET_OS="$(${FPC_BIN} -iTO 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
TRIPLET="${TARGET_CPU}-${TARGET_OS}"
BIN_DIR="${REPORT_DIR}/bin"
UNIT_DIR="${REPORT_DIR}/lib/${TRIPLET}"
BIN="${BIN_DIR}/fafafa.core.simd.test"
EXTRA_DEFINES_RAW="${SIMD_BENCH_EXTRA_DEFINES:-${SIMD_FPC_EXTRA_DEFINES:-}}"

mkdir -p "${REPORT_DIR}" "${BIN_DIR}" "${UNIT_DIR}"
cd "${ROOT}"

EXTRA_DEFINES=()
if [[ -n "${EXTRA_DEFINES_RAW// }" ]]; then
  read -r -a EXTRA_DEFINES <<< "${EXTRA_DEFINES_RAW}"
fi

build_with_fpc() {
  echo "[BUILD] fpc fafafa.core.simd.test.lpr"
  : >"${TMP_BUILD_LOG}"
  if "${FPC_BIN}" -B -Mobjfpc -Sc -Si -O1 -g -gl -gh -dDEBUG \
    "${EXTRA_DEFINES[@]}" \
    -Fu../../src -Fi../../src \
    -FE"${BIN_DIR}" -FU"${UNIT_DIR}" \
    "${PROJECT}" >"${TMP_BUILD_LOG}" 2>&1; then
    echo "[BUILD] OK"
  else
    local LRC=$?
    echo "[BUILD] FAILED rc=${LRC} (see ${TMP_BUILD_LOG})"
    tail -n 120 "${TMP_BUILD_LOG}" || true
    return "${LRC}"
  fi

  if grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${TMP_BUILD_LOG}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from SIMD units in build log:"
    grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${TMP_BUILD_LOG}" || true
    return 1
  fi

  echo "[CHECK] OK (no SIMD-unit warnings/hints)"
}

if ! command -v "${FPC_BIN}" >/dev/null 2>&1; then
  echo "[BENCH] SKIP (fpc not found)" | tee "${RUNNER_LOG}"
  cat >"${SUMMARY_FILE}" <<EOM
# SIMD Backend Benchmark Evidence (${TS})

- Output: ${REPORT_DIR}
- Host: $(uname -m)

## Bench
[BENCH] SKIP (fpc not found)
EOM
  exit 0
fi

build_with_fpc

if [[ ! -x "${BIN}" ]]; then
  echo "[BENCH] Missing binary: ${BIN}" | tee "${RUNNER_LOG}"
  exit 2
fi

echo "[TEST] Running: ${BIN} --bench-only"
: >"${TMP_RUN_LOG}"
if "${BIN}" --bench-only >"${TMP_RUN_LOG}" 2>&1; then
  printf '%s\n' '[BENCH] Benchmark completed successfully.' >>"${TMP_RUN_LOG}"
else
  LRC=$?
  echo "[BENCH] FAILED rc=${LRC} (see ${TMP_RUN_LOG})" | tee "${RUNNER_LOG}"
  tail -n 120 "${TMP_RUN_LOG}" || true
  exit "${LRC}"
fi

python3 - "${REPORT_DIR}" "${TMP_BUILD_LOG}" "${TMP_RUN_LOG}" "${SUMMARY_FILE}" "${RUNNER_LOG}" "${EXTRA_DEFINES_RAW}" <<'PY'
import re
import sys
from datetime import datetime
from pathlib import Path

report_dir = Path(sys.argv[1])
build_log = Path(sys.argv[2])
run_log = Path(sys.argv[3])
summary_file = Path(sys.argv[4])
runner_log = Path(sys.argv[5])
extra_defines = sys.argv[6].strip()
run_text = run_log.read_text(encoding='utf-8', errors='ignore')
arch = 'unknown'
backend = 'Unknown'
for line in run_text.splitlines():
    m = re.search(r'^=== SIMD Benchmark \(([^/]+)/([^)]+)\) ===$', line.strip())
    if m:
        arch = m.group(1).strip()
        backend = m.group(2).strip()
        break

slug_map = {
    'RISC-V V': 'RISCVV',
    'AVX-512': 'AVX512',
    'SSE4.1': 'SSE41',
    'SSE4.2': 'SSE42',
}
label_backend = slug_map.get(backend, re.sub(r'[^A-Za-z0-9]+', '', backend.upper()) or 'UNKNOWN')
slug_lower = label_backend.lower()
case_name = f'{label_backend}_vs_Scalar'
build_final = report_dir / f'bench_{slug_lower}_vs_scalar.build.log'
run_final = report_dir / f'bench_{slug_lower}_vs_scalar.run.log'
build_log.rename(build_final)
run_log.rename(run_final)

rows = []
for raw_line in run_final.read_text(encoding='utf-8', errors='ignore').splitlines():
    line = raw_line.rstrip()
    if not line or line.startswith('===') or line.startswith('---') or line.startswith('[BENCH]'):
        continue
    if line.startswith('Operation'):
        continue
    parts = re.split(r'\s{2,}', line.strip())
    if len(parts) == 5 and parts[-1].endswith('x'):
        try:
            speedup = float(parts[-1][:-1])
        except ValueError:
            continue
        rows.append({
            'operation': parts[0],
            'size': parts[1],
            'scalar': parts[2],
            'active': parts[3],
            'speedup': speedup,
        })

avg_speedup = sum(row['speedup'] for row in rows) / len(rows) if rows else 0.0
report_file = report_dir / f'{case_name}_Benchmark_Report.md'
report_lines = [
    f'# {backend} vs Scalar Performance Benchmark Report',
    '',
    f'**Generated**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}',
    f'**Platform**: {arch}',
    '',
    '## Performance Results',
    '',
    f'| Operation | Size | Scalar ops/s | {backend} ops/s | Speedup |',
    '|-----------|------|--------------|-----------------|---------|',
]
for row in rows:
    report_lines.append(
        f"| {row['operation']} | {row['size']} | {row['scalar']} | {row['active']} | {row['speedup']:.2f}x |"
    )
report_lines.extend([
    '',
    '## Summary',
    '',
    f'- **Average Speedup**: {avg_speedup:.2f}x',
    f'- **Total Operations Tested**: {len(rows)}',
    '',
    '## Conclusion',
    '',
    f'{backend} backend benchmark evidence captured successfully.',
])
report_file.write_text('\n'.join(report_lines) + '\n', encoding='utf-8')

interesting = []
for raw_line in run_final.read_text(encoding='utf-8', errors='ignore').splitlines():
    line = raw_line.strip()
    if line.startswith('===') or line.startswith('Average Speedup:') or line.startswith('[BENCH]'):
        interesting.append(line)

summary_lines = [
    f'# SIMD Backend Benchmark Evidence ({report_dir.name.split("backend-bench-")[-1]})',
    '',
    f'- Output: {report_dir}',
    f'- Host: {arch}',
    '',
    f'## {case_name}',
    f'- Build log: {build_final}',
    f'- Run log: {run_final}',
]
summary_lines.extend(interesting or [f'Average Speedup: {avg_speedup:.2f}x', '[BENCH] Benchmark completed successfully.'])
summary_file.write_text('\n'.join(summary_lines) + '\n', encoding='utf-8')

runner_lines = [f'[BENCH] >>> {case_name}', f'[BENCH] PASS {case_name}']
if extra_defines:
    runner_lines.append(f'[BENCH] extra-defines={extra_defines}')
runner_lines.append(f'[BENCH] DONE: {report_dir}')
runner_lines.append(f'[BENCH] SUMMARY: {summary_file}')
runner_text = '\n'.join(runner_lines) + '\n'
runner_log.write_text(runner_text, encoding='utf-8')
print(runner_text, end='')
PY
