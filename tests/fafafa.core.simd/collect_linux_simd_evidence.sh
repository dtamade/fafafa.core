#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
LOG_ROOT="${ROOT}/logs"
TS="$(date +%Y%m%d-%H%M%S)-$$"
REPORT_DIR="${LOG_ROOT}/evidence-${TS}"
SUMMARY_FILE="${REPORT_DIR}/summary.md"
RUNNER_LOG="${REPORT_DIR}/_runner.log"
FPC_BIN="${FPC_BIN:-fpc}"
TARGET_CPU="$(${FPC_BIN} -iTP 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
TARGET_OS="$(${FPC_BIN} -iTO 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
TRIPLET="${TARGET_CPU}-${TARGET_OS}"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"
OVERALL_FAILURES=0

mkdir -p "${REPORT_DIR}"
: >"${RUNNER_LOG}"

append_section() {
  local aTitle
  local aLogFile
  aTitle="$1"
  aLogFile="$2"
  {
    printf '## %s\n' "${aTitle}"
    cat "${aLogFile}"
    printf '\n'
  } >>"${SUMMARY_FILE}"
}

run_and_capture() {
  local aTitle
  local aSlug
  local LLogFile
  local LRC
  aTitle="$1"
  aSlug="$2"
  shift 2
  LLogFile="${REPORT_DIR}/${aSlug}.log"
  printf "[EVIDENCE] >>> %s\n" "${aSlug}" | tee -a "${RUNNER_LOG}" >/dev/null
  if "$@" >"${LLogFile}" 2>&1; then
    append_section "${aTitle}" "${LLogFile}"
    return 0
  else
    LRC=$?
    append_section "${aTitle}" "${LLogFile}"
    echo "[EVIDENCE] FAILED step=${aSlug} rc=${LRC}" >&2
    return "${LRC}"
  fi
}

check_heap_log() {
  local aLogFile
  aLogFile="$1"
  if grep -nE '^[1-9][0-9]* unfreed memory blocks' "${aLogFile}" >/dev/null; then
    echo "[LEAK] FAILED: heaptrc reports unfreed blocks:"
    grep -nE '^[0-9]+ unfreed memory blocks' "${aLogFile}" || true
    return 1
  fi
  echo "[LEAK] OK"
}

check_simd_build_log() {
  local aLogFile
  aLogFile="$1"
  if grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${aLogFile}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from SIMD units in build log:"
    grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${aLogFile}" || true
    return 1
  fi
  echo "[CHECK] OK (no SIMD unit warnings/hints)"
}

run_intrinsics_case() {
  local aProjectDir
  local aProjectFile
  local aBinaryRel
  local aBuildMode
  local LBinaryPath
  local LBuildLog
  local LTestLog
  local LTargetUnitDir

  aProjectDir="$1"
  aProjectFile="$2"
  aBinaryRel="$3"
  aBuildMode="$4"

  LBinaryPath="${aProjectDir}/${aBinaryRel}"
  LBuildLog="${REPORT_DIR}/$(basename "${aProjectDir}").build.log"
  LTestLog="${REPORT_DIR}/$(basename "${aProjectDir}").test.log"
  LTargetUnitDir="${aProjectDir}/lib/${TRIPLET}"

  cd "${aProjectDir}"
  echo "[BUILD] Project: ${aProjectFile}"
  : >"${LBuildLog}"
  if command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
    if "${LAZBUILD_BIN}" --quiet --build-mode="${aBuildMode}" --build-all "${aProjectFile}" >"${LBuildLog}" 2>&1; then
      echo "[BUILD] OK"
    else
      local LRC=$?
      echo "[BUILD] FAILED rc=${LRC} (see ${LBuildLog})"
      return "${LRC}"
    fi
  else
    mkdir -p "$(dirname "${LBinaryPath}")" "${LTargetUnitDir}"
    if "${FPC_BIN}" -B -Mobjfpc -Sc -Si -O1 -g -gl -gh -dDEBUG \
      -Fu../../src -Fi../../src \
      -FE"$(dirname "${LBinaryPath}")" -FU"${LTargetUnitDir}" \
      "${aProjectFile%.lpi}.lpr" >"${LBuildLog}" 2>&1; then
      echo "[BUILD] OK"
    else
      local LRC=$?
      echo "[BUILD] FAILED rc=${LRC} (see ${LBuildLog})"
      return "${LRC}"
    fi
  fi

  check_simd_build_log "${LBuildLog}"

  if [[ ! -x "${LBinaryPath}" ]]; then
    echo "[TEST] Missing binary: ${LBinaryPath}"
    return 2
  fi

  echo "[TEST] Running: ${aBinaryRel}"
  : >"${LTestLog}"
  if "${LBinaryPath}" >"${LTestLog}" 2>&1; then
    cat "${LTestLog}"
    echo "[TEST] OK"
  else
    local LRC=$?
    cat "${LTestLog}"
    echo "[TEST] FAILED rc=${LRC} (see ${LTestLog})"
    return "${LRC}"
  fi

  check_heap_log "${LTestLog}"
}

run_main_fpc_case() {
  local -a LArgs
  local LBuildLog
  local LTestLog
  local LBinDir
  local LUnitDir
  local LBinary

  LArgs=("$@")
  LBuildLog="${REPORT_DIR}/main.build.log"
  LTestLog="${REPORT_DIR}/main.test.log"
  LBinDir="${REPORT_DIR}/bin"
  LUnitDir="${REPORT_DIR}/lib/${TRIPLET}"
  LBinary="${LBinDir}/fafafa.core.simd.test"

  cd "${ROOT}"
  mkdir -p "${LBinDir}" "${LUnitDir}"
  echo "[BUILD] Project: ${ROOT}/fafafa.core.simd.test.lpr (mode=FPC)"
  : >"${LBuildLog}"
  if "${FPC_BIN}" -B -Mobjfpc -Sc -Si -O1 -g -gl -gh -dDEBUG \
    -Fu../../src -Fi../../src \
    -FE"${LBinDir}" -FU"${LUnitDir}" \
    fafafa.core.simd.test.lpr >"${LBuildLog}" 2>&1; then
    echo "[BUILD] OK"
  else
    local LRC=$?
    echo "[BUILD] FAILED rc=${LRC} (see ${LBuildLog})"
    return "${LRC}"
  fi

  check_simd_build_log "${LBuildLog}"

  if [[ ! -x "${LBinary}" ]]; then
    echo "[TEST] Missing binary: ${LBinary}"
    return 2
  fi

  echo "[TEST] Running: ${LBinary} ${LArgs[*]}"
  : >"${LTestLog}"
  if "${LBinary}" "${LArgs[@]}" >"${LTestLog}" 2>&1; then
    cat "${LTestLog}"
    echo "[TEST] OK"
  else
    local LRC=$?
    cat "${LTestLog}"
    echo "[TEST] FAILED rc=${LRC} (see ${LTestLog})"
    return "${LRC}"
  fi

  check_heap_log "${LTestLog}"
}

run_skip() {
  echo "$1"
}

run_main_buildortest_action() {
  local -a LArgs
  LArgs=("$@")
  cd "${ROOT}"
  SIMD_OUTPUT_ROOT="${REPORT_DIR}" bash BuildOrTest.sh "${LArgs[@]}"
}

mark_failure() {
  OVERALL_FAILURES=$((OVERALL_FAILURES + 1))
}

{
  echo "# SIMD Linux Evidence (${TS})"
  echo
  echo "- Root: ${REPO_ROOT}"
  echo "- Output: ${REPORT_DIR}"
  echo
} >"${SUMMARY_FILE}"

if [[ "${TARGET_CPU}" == "x86_64" || "${TARGET_CPU}" == "i386" ]]; then
  run_and_capture "SSE intrinsics" "sse_intrinsics" run_intrinsics_case \
    "${REPO_ROOT}/tests/fafafa.core.simd.intrinsics.sse" \
    "fafafa.core.simd.intrinsics.sse.test.lpi" \
    "bin/fafafa.core.simd.intrinsics.sse.test" \
    "Default" || mark_failure

  run_and_capture "MMX intrinsics" "mmx_intrinsics" run_intrinsics_case \
    "${REPO_ROOT}/tests/fafafa.core.simd.intrinsics.mmx" \
    "fafafa.core.simd.intrinsics.mmx.test.lpi" \
    "bin/fafafa.core.simd.intrinsics.mmx.test" \
    "Debug" || mark_failure
else
  run_and_capture "SSE intrinsics" "sse_intrinsics" run_skip "[SSE] SKIP (target=${TRIPLET}, x86 only)" || mark_failure
  run_and_capture "MMX intrinsics" "mmx_intrinsics" run_skip "[MMX] SKIP (target=${TRIPLET}, x86 only)" || mark_failure
fi

run_and_capture "Coverage" "coverage" bash -lc "cd '${ROOT}' && python3 check_intrinsics_coverage.py" || mark_failure
run_and_capture "Coverage Strict" "coverage_strict" bash -lc "cd '${ROOT}' && python3 check_intrinsics_coverage.py --strict-extra" || mark_failure
run_and_capture "Wiring Sync Strict" "wiring_sync_strict" bash -lc "cd '${ROOT}' && python3 check_nonx86_wiring_sync.py --strict-extra --summary-line" || mark_failure

if command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  run_and_capture "AdvancedAlgorithms" "advanced" run_main_buildortest_action test --suite=TTestCase_AdvancedAlgorithms || mark_failure
  run_and_capture "Perf Smoke" "perf_smoke" run_main_buildortest_action perf-smoke || mark_failure
else
  run_and_capture "AdvancedAlgorithms" "advanced" run_main_fpc_case --suite=TTestCase_AdvancedAlgorithms || mark_failure
  run_and_capture "Perf Smoke" "perf_smoke" run_main_fpc_case --bench-only || mark_failure
fi

if [[ ( "${TARGET_CPU}" == "x86_64" || "${TARGET_CPU}" == "i386" ) && -x "$(command -v "${LAZBUILD_BIN}" 2>/dev/null || true)" ]]; then
  run_and_capture "Gate" "gate" run_main_buildortest_action gate || mark_failure
else
  run_and_capture "Gate" "gate" run_skip "[GATE] SKIP (requires host x86 lazbuild toolchain; target=${TRIPLET})" || mark_failure
fi

if [[ "${OVERALL_FAILURES}" != "0" ]]; then
  echo "[EVIDENCE] Completed with failures: ${OVERALL_FAILURES}"
else
  echo "[EVIDENCE] Completed without failures"
fi

echo "[EVIDENCE] DONE: ${REPORT_DIR}"
echo "[EVIDENCE] SUMMARY: ${SUMMARY_FILE}"
exit 0
