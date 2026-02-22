#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJ="${ROOT}/fafafa.core.simd.test.lpi"
BIN="${ROOT}/bin2/fafafa.core.simd.test"
LOG_DIR="${ROOT}/logs"
BUILD_LOG="${LOG_DIR}/build.txt"
TEST_LOG="${LOG_DIR}/test.txt"
COVERAGE_SCRIPT="${ROOT}/check_intrinsics_coverage.py"
INTERFACE_COMPLETENESS_SCRIPT="${ROOT}/check_interface_implementation_completeness.py"
ADAPTER_SYNC_SCRIPT="${ROOT}/check_backend_adapter_sync.py"
EXPERIMENTAL_INTRINSICS_SCRIPT="${ROOT}/check_intrinsics_experimental_status.py"
WIRING_SYNC_SCRIPT="${ROOT}/check_nonx86_wiring_sync.py"
QEMU_EXPERIMENTAL_REPORT_SCRIPT="${ROOT}/report_qemu_experimental_blockers.py"
QEMU_EXPERIMENTAL_BASELINE_SCRIPT="${ROOT}/check_experimental_failure_baseline.py"
INTERFACE_COMPLETENESS_JSON_LOG="${LOG_DIR}/interface_completeness.json"
INTERFACE_COMPLETENESS_MD_LOG="${ROOT}/docs/interface_implementation_completeness.md"
ADAPTER_SYNC_LOG="${LOG_DIR}/backend_adapter_sync.txt"
ADAPTER_SYNC_JSON_LOG="${LOG_DIR}/backend_adapter_sync.json"
WIRING_SYNC_LOG="${LOG_DIR}/wiring_sync.txt"
WIRING_SYNC_JSON_LOG="${LOG_DIR}/wiring_sync.json"
GATE_SUMMARY_LOG="${LOG_DIR}/gate_summary.md"
GATE_SUMMARY_JSON_LOG="${LOG_DIR}/gate_summary.json"
GATE_SUMMARY_EXPORT_SCRIPT="${ROOT}/export_gate_summary_json.py"
GATE_SUMMARY_SAMPLE_SCRIPT="${ROOT}/generate_gate_summary_sample.py"
GATE_SUMMARY_REHEARSAL_SCRIPT="${ROOT}/rehearse_gate_summary_thresholds.sh"
GATE_SUMMARY_INJECT_SCRIPT="${ROOT}/inject_gate_summary_sample.sh"
GATE_SUMMARY_ROLLBACK_SCRIPT="${ROOT}/rollback_gate_summary_sample.sh"
GATE_SUMMARY_BACKUPS_SCRIPT="${ROOT}/list_gate_summary_backups.sh"
WIN_CLOSEOUT_3CMD_SCRIPT="${ROOT}/print_windows_b07_closeout_3cmd.sh"
FREEZE_STATUS_SCRIPT="${ROOT}/evaluate_simd_freeze_status.py"
WIN_CLOSEOUT_FINALIZE_SCRIPT="${ROOT}/run_windows_b07_closeout_finalize.sh"
FREEZE_REHEARSAL_SCRIPT="${ROOT}/rehearse_freeze_status.sh"

mkdir -p "${ROOT}/bin2" "${ROOT}/lib2" "${LOG_DIR}"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

LZ_Q=()
if [[ "${FAFAFA_BUILD_QUIET:-1}" != "0" ]]; then
  LZ_Q+=("--quiet")
fi

MODE="${FAFAFA_BUILD_MODE:-Debug}"

detect_lazarusdir() {
  # Prefer explicit override.
  if [[ -n "${FAFAFA_LAZARUSDIR:-}" ]]; then
    echo "${FAFAFA_LAZARUSDIR}"
    return 0
  fi

  # Common fpcupdeluxe layout (used by other module runners).
  if [[ -d "/opt/fpcupdeluxe/lazarus/lcl" ]]; then
    echo "/opt/fpcupdeluxe/lazarus"
    return 0
  fi

  # Best-effort: infer from lazbuild location if it sits in the Lazarus source root.
  local LLazbuildPath
  local LMaybeRoot
  LLazbuildPath="$(command -v "${LAZBUILD_BIN}" 2>/dev/null || true)"
  if [[ -n "${LLazbuildPath}" ]]; then
    LMaybeRoot="$(cd "$(dirname "${LLazbuildPath}")" && pwd)"
    if [[ -d "${LMaybeRoot}/lcl" ]]; then
      echo "${LMaybeRoot}"
      return 0
    fi
  fi

  echo ""
  return 0
}

build_project() {
  local LLazarusDir
  LLazarusDir="$(detect_lazarusdir)"

  echo "[BUILD] Project: ${PROJ} (mode=${MODE})"
  : >"${BUILD_LOG}"
  if [[ -n "${LLazarusDir}" ]]; then
    if "${LAZBUILD_BIN}" "${LZ_Q[@]}" --lazarusdir="${LLazarusDir}" --build-all "${PROJ}" >"${BUILD_LOG}" 2>&1; then
      echo "[BUILD] OK"
    else
      local rc=$?
      echo "[BUILD] FAILED rc=${rc} (see ${BUILD_LOG})"
      return "${rc}"
    fi
    return 0
  fi

  if "${LAZBUILD_BIN}" "${LZ_Q[@]}" --build-all "${PROJ}" >"${BUILD_LOG}" 2>&1; then
    echo "[BUILD] OK"
  else
    local rc=$?
    echo "[BUILD] FAILED rc=${rc} (see ${BUILD_LOG})"
    return "${rc}"
  fi
}

check_build_log() {
  # Module acceptance criteria: no warnings/hints emitted from the SIMD module units under src/.
  if grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${BUILD_LOG}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from SIMD units in build log:"
    grep -nE '(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)' "${BUILD_LOG}" || true
    return 1
  fi
  echo "[CHECK] OK (no SIMD-unit warnings/hints)"
}

run_tests() {
  if [[ ! -x "${BIN}" ]]; then
    echo "[TEST] Missing binary: ${BIN} (did build succeed?)"
    return 2
  fi

  echo "[TEST] Running: ${BIN} $*"
  : >"${TEST_LOG}"

  if "${BIN}" "$@" >"${TEST_LOG}" 2>&1; then
    echo "[TEST] OK"
  else
    local rc=$?
    echo "[TEST] FAILED rc=${rc} (see ${TEST_LOG})"
    tail -n 80 "${TEST_LOG}" || true
    return "${rc}"
  fi

  if grep -nE '^Invalid option' "${TEST_LOG}" >/dev/null; then
    echo "[TEST] FAILED: unsupported test argument (see ${TEST_LOG})"
    grep -nE '^Invalid option' "${TEST_LOG}" || true
    return 2
  fi
}

run_suite_repeat() {
  local aSuite
  local aRounds
  local LRound
  local LSafeSuite
  local LPerRunLog

  aSuite="${1:-TTestCase_SimdConcurrent}"
  aRounds="${2:-10}"

  if ! [[ "${aRounds}" =~ ^[1-9][0-9]*$ ]]; then
    echo "[REPEAT] Invalid rounds: ${aRounds} (expect positive integer)"
    return 2
  fi

  LSafeSuite="$(echo "${aSuite}" | tr -c 'A-Za-z0-9._-' '_')"

  build_project || return $?
  for ((LRound = 1; LRound <= aRounds; LRound++)); do
    echo "[REPEAT] ${LRound}/${aRounds} suite=${aSuite}"
    run_tests --suite="${aSuite}" || return $?
    check_heap_leaks || return $?

    LPerRunLog="${LOG_DIR}/repeat.${LSafeSuite}.${LRound}.txt"
    cp "${TEST_LOG}" "${LPerRunLog}" || true
  done
  echo "[REPEAT] OK suite=${aSuite} rounds=${aRounds}"
}

check_heap_leaks() {
  # heaptrc prints e.g. "0 unfreed memory blocks : 0" or "2 unfreed memory blocks : 38".
  if grep -nE '^[1-9][0-9]* unfreed memory blocks' "${TEST_LOG}" >/dev/null; then
    echo "[LEAK] FAILED: heaptrc reports unfreed blocks:"
    grep -nE '^[0-9]+ unfreed memory blocks' "${TEST_LOG}" || true
    return 1
  fi
  echo "[LEAK] OK"
}

check_windows_runner_parity() {
  local LBat
  local LMissing
  local LPattern
  local -a LRequired

  LBat="${ROOT}/buildOrTest.bat"
  LMissing=0

  if [[ ! -f "${LBat}" ]]; then
    echo "[CHECK] Missing Windows runner: ${LBat}"
    return 1
  fi

  LRequired=(
    'if /I "%ACTION%"=="check" goto :check'
    'if /I "%ACTION%"=="test" goto :test'
    'if /I "%ACTION%"=="test-concurrent-repeat" goto :test_concurrent_repeat'
    'if /I "%ACTION%"=="gate" goto :gate'
    'if /I "%ACTION%"=="gate-strict" goto :gate_strict'
    'if /I "%ACTION%"=="interface-completeness" goto :interface_completeness'
    'if /I "%ACTION%"=="adapter-sync-pascal" goto :adapter_sync_pascal'
    'if /I "%ACTION%"=="adapter-sync" goto :adapter_sync'
    'if /I "%ACTION%"=="parity-suites" goto :parity_suites'
    'if /I "%ACTION%"=="perf-smoke" goto :perf_smoke'
    'if /I "%ACTION%"=="nonx86-ieee754" goto :nonx86_ieee754'
    'if /I "%ACTION%"=="backend-bench" goto :backend_bench'
    'if /I "%ACTION%"=="qemu-nonx86-evidence" goto :qemu_nonx86_evidence'
    'if /I "%ACTION%"=="qemu-arch-matrix-evidence" goto :qemu_arch_matrix_evidence'
    'if /I "%ACTION%"=="qemu-nonx86-experimental-asm" goto :qemu_nonx86_experimental_asm'
    'if /I "%ACTION%"=="qemu-experimental-report" goto :qemu_experimental_report'
    'if /I "%ACTION%"=="qemu-experimental-baseline-check" goto :qemu_experimental_baseline_check'
    'if /I "%ACTION%"=="evidence-win" goto :evidence_win'
    'if /I "%ACTION%"=="verify-win-evidence" goto :verify_win_evidence'
    'if /I "%ACTION%"=="evidence-win-verify" goto :evidence_win_verify'
    'if /I "%ACTION%"=="wiring-sync" goto :wiring_sync'
    'if /I "%ACTION%"=="gate-summary" goto :gate_summary'
    'if /I "%ACTION%"=="gate-summary-sample" goto :gate_summary_sample'
    'if /I "%ACTION%"=="gate-summary-rehearsal" goto :gate_summary_rehearsal'
    'if /I "%ACTION%"=="gate-summary-inject" goto :gate_summary_inject'
    'if /I "%ACTION%"=="gate-summary-rollback" goto :gate_summary_rollback'
    'if /I "%ACTION%"=="gate-summary-backups" goto :gate_summary_backups'
    'echo Usage: %~nx0 [clean^|build^|check^|test^|test-concurrent-repeat^|debug^|release^|gate^|gate-strict^|interface-completeness^|adapter-sync-pascal^|adapter-sync^|parity-suites^|gate-summary^|gate-summary-sample^|gate-summary-rehearsal^|gate-summary-inject^|gate-summary-rollback^|gate-summary-backups^|perf-smoke^|nonx86-ieee754^|backend-bench^|qemu-nonx86-evidence^|qemu-arch-matrix-evidence^|qemu-nonx86-experimental-asm^|qemu-experimental-report^|qemu-experimental-baseline-check^|coverage^|wiring-sync^|experimental-intrinsics^|experimental-intrinsics-tests^|evidence-win^|verify-win-evidence^|evidence-win-verify] [test-args...]'
    'findstr /r /c:"src\\fafafa\.core\.simd\..*Warning:" /c:"src\\fafafa\.core\.simd\..*Hint:" "%BUILD_LOG%" >nul 2>nul'
    'findstr /b /c:"Invalid option" "%TEST_LOG%" >nul 2>nul'
    'findstr /r /c:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul 2>nul'
    'call "%SELF%" check'
    'if /I "%SIMD_CHECK_WIRING_SYNC%"=="1" ('
    'call "%~f0" wiring-sync'
    'call "%SELF%" test --list-suites'
    'call "%SELF%" test --suite=TTestCase_AVX2IntrinsicsFallback'
    'if /I "%SIMD_GATE_NONX86_IEEE754%"=="0" ('
    'echo [GATE] SKIP optional non-x86 IEEE754 suite ^(set SIMD_GATE_NONX86_IEEE754=1 to enable^)'
    'call "%SELF%" nonx86-ieee754'
    'call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo\buildOrTest.bat" test --list-suites'
    'call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo\buildOrTest.bat" test --suite=TTestCase_PlatformSpecific'
    'call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat" test --list-suites'
    'call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat" test --suite=TTestCase_Global'
    'call "%TESTS_ROOT%\run_all_tests.bat" =fafafa.core.simd =fafafa.core.simd.cpuinfo =fafafa.core.simd.cpuinfo.x86 =fafafa.core.simd.intrinsics.sse =fafafa.core.simd.intrinsics.mmx'
    'if /I "%SIMD_GATE_CONCURRENT_REPEAT%"=="0" ('
    'echo [GATE] SKIP optional concurrent repeat ^(set SIMD_GATE_CONCURRENT_REPEAT=10 to enable^)'
    'call "%SELF%" test-concurrent-repeat %SIMD_GATE_CONCURRENT_REPEAT%'
    'if /I "%SIMD_GATE_PERF_SMOKE%"=="1" ('
    'echo [GATE] SKIP optional perf smoke ^(set SIMD_GATE_PERF_SMOKE=1 to enable^)'
    'call "%SELF%" perf-smoke'
    'if /I "%SIMD_GATE_QEMU_NONX86_EVIDENCE%"=="1" ('
    'echo [GATE] SKIP optional qemu non-x86 evidence ^(set SIMD_GATE_QEMU_NONX86_EVIDENCE=1 to enable^)'
    'call "%SELF%" qemu-nonx86-evidence'
    'if /I "%SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE%"=="1" ('
    'echo [GATE] SKIP optional qemu arch matrix evidence ^(set SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=1 to enable^)'
    'call "%SELF%" qemu-arch-matrix-evidence'
    'if /I "%SIMD_GATE_WIRING_SYNC%"=="1" ('
    'echo [GATE] SKIP optional wiring-sync ^(set SIMD_GATE_WIRING_SYNC=1 to enable^)'
    'set "WIN_EVIDENCE_LOG=%ROOT%logs\windows_b07_gate.log"'
    'if exist "%WIN_EVIDENCE_LOG%" ('
    'if /I "%SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE%"=="1" ('
    'echo [GATE] FAIL required windows evidence log missing: %WIN_EVIDENCE_LOG%'
    'echo [GATE] SKIP evidence verify ^(windows log not present: %WIN_EVIDENCE_LOG%^)'
    'set "SIMD_GATE_PERF_SMOKE=1"'
    'set "SIMD_GATE_NONX86_IEEE754=1"'
    'set "SIMD_GATE_QEMU_NONX86_EVIDENCE=0"'
    'set "SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=1"'
    'set "SIMD_GATE_INTERFACE_COMPLETENESS=1"'
    'set "SIMD_GATE_ADAPTER_SYNC_PASCAL=1"'
    'set "SIMD_GATE_ADAPTER_SYNC=1"'
    'set "SIMD_GATE_PARITY_SUITES=1"'
    'call "%~f0" gate'
    'echo [GATE] Optional interface completeness check'
    'call "%SELF%" interface-completeness'
    'echo [GATE] Optional backend adapter sync Pascal smoke'
    'call "%SELF%" adapter-sync-pascal'
    'echo [GATE] Optional backend adapter sync'
    'set "SIMD_ADAPTER_SYNC_PASCAL_SMOKE=0"'
    'call "%SELF%" adapter-sync'
    'echo [GATE] Optional cross-backend parity suites'
    'call "%SELF%" test --suite=TTestCase_DispatchAllSlots'
    'call "%SELF%" test --suite=TTestCase_DispatchAPI'
    'set "BENCH_SCRIPT=%ROOT%run_backend_benchmarks.sh"'
    'echo [BENCH] SKIP ^(bash not found^)'
    'set "QEMU_SCRIPT=%ROOT%docker\run_multiarch_qemu.sh"'
    'echo [QEMU] SKIP ^(bash not found^)'
    'bash "%QEMU_SCRIPT%" nonx86-evidence %NORMALIZED_TEST_ARGS%'
    'bash "%QEMU_SCRIPT%" arch-matrix-evidence %NORMALIZED_TEST_ARGS%'
    'bash "%QEMU_SCRIPT%" nonx86-experimental-asm %NORMALIZED_TEST_ARGS%'
    'set "QEMU_EXP_REPORT_SCRIPT=%ROOT%report_qemu_experimental_blockers.py"'
    'py -3 "%QEMU_EXP_REPORT_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%'
    'python "%QEMU_EXP_REPORT_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%'
    'set "QEMU_EXP_BASELINE_SCRIPT=%ROOT%check_experimental_failure_baseline.py"'
    'py -3 "%QEMU_EXP_BASELINE_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%'
    'python "%QEMU_EXP_BASELINE_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%'
    'set "EVIDENCE_SCRIPT=%ROOT%collect_windows_b07_evidence.bat"'
    'set "VERIFY_SCRIPT=%ROOT%verify_windows_b07_evidence.bat"'
    'call "%~f0" evidence-win'
    'call "%~f0" verify-win-evidence %NORMALIZED_TEST_ARGS%'
    'echo [GATE-SUMMARY] %SUMMARY_FILE%'
    'echo [GATE-SUMMARY] thresholds: warn_ms=%SIMD_GATE_STEP_WARN_MS%, fail_ms=%SIMD_GATE_STEP_FAIL_MS%'
    'set "SUMMARY_FILTER=%SIMD_GATE_SUMMARY_FILTER%"'
    'echo [GATE-SUMMARY] filter=%SUMMARY_FILTER%, max_detail=%SIMD_GATE_SUMMARY_MAX_DETAIL%'
    'findstr /r /c:"^| Time |" /c:"^|---|" /c:"| FAIL |" "%SUMMARY_FILE%"'
    'findstr /r /c:"^| Time |" /c:"^|---|" /c:"| SLOW_WARN |" /c:"| SLOW_FAIL |" "%SUMMARY_FILE%"'
    'set "EXPORT_SCRIPT=%ROOT%export_gate_summary_json.py"'
    'echo [GATE-SUMMARY] json=%SUMMARY_JSON_FILE%'
    'set "SAMPLE_SCRIPT=%ROOT%generate_gate_summary_sample.py"'
    'set "REHEARSAL_SCRIPT=%ROOT%rehearse_gate_summary_thresholds.sh"'
    'echo [GATE-SUMMARY-SAMPLE] output=%SAMPLE_OUTPUT%'
    'echo [GATE-SUMMARY-REHEARSAL] SKIP ^(bash not found^)'
    'if /I "%SIMD_GATE_SUMMARY_APPLY%"=="1" ('
    'echo [GATE-SUMMARY-INJECT] sample=%SAMPLE_OUTPUT%'
    'echo [GATE-SUMMARY-INJECT] backup=!BACKUP_FILE!'
    'echo [GATE-SUMMARY-ROLLBACK] restored=%SUMMARY_FILE% from=%RESTORE_FILE%'
    'echo [GATE-SUMMARY-BACKUPS] none'
  )

  for LPattern in "${LRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows runner missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (windows runner parity signatures present)"
}

check_cpuinfo_runner_parity() {
  local LScript
  local LMissing
  local LPattern
  local -a LRequired
  local -a LTargets

  LTargets=(
    "${ROOT}/../fafafa.core.simd.cpuinfo/BuildOrTest.sh"
    "${ROOT}/../fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh"
  )

  LRequired=(
    'if [[ "${LArg}" == "--list-suites" ]]; then'
    'LArgs+=("--list")'
    "if grep -nE '^Invalid option' \"\${TEST_LOG}\" >/dev/null; then"
    "if grep -nE '^[1-9][0-9]* unfreed memory blocks' \"\${TEST_LOG}\" >/dev/null; then"
  )

  for LScript in "${LTargets[@]}"; do
    if [[ ! -f "${LScript}" ]]; then
      echo "[CHECK] Missing cpuinfo runner: ${LScript}"
      return 1
    fi

    LMissing=0
    for LPattern in "${LRequired[@]}"; do
      if ! grep -F -- "${LPattern}" "${LScript}" >/dev/null; then
        echo "[CHECK] cpuinfo runner missing pattern (${LScript}): ${LPattern}"
        LMissing=1
      fi
    done

    if [[ "${LMissing}" != "0" ]]; then
      return 1
    fi
  done

  echo "[CHECK] OK (cpuinfo runner parity signatures present)"
}

check_perf_log() {
  local LZeroSpeedup
  local LMemRegressions

  if ! grep -F '=== SIMD Benchmark (' "${TEST_LOG}" >/dev/null; then
    echo "[PERF] FAILED: benchmark header not found in ${TEST_LOG}"
    return 1
  fi

  if grep -F '/Scalar)' "${TEST_LOG}" >/dev/null; then
    echo "[PERF] SKIP (active backend is Scalar)"
    return 0
  fi

  LZeroSpeedup="$(awk '/^(MemEqual|MemFindByte|SumBytes|CountByte|BitsetPopCount|VecF32x4Add|VecF32x4Mul|VecF32x4Div|VecI32x4Add|VecF32x4Dot|VecF32x8DotApi|VecF32x8DotBatch|ArrSumF32|ArrSumF64|ArrMinMaxF32|ArrMinMaxF64|ArrVarF32|ArrVarF64|ArrKahanF32|ArrKahanF64)/ { if (($NF + 0) == 0) print }' "${TEST_LOG}")"
  if [[ -n "${LZeroSpeedup}" ]]; then
    echo "[PERF] FAILED: zero speedup rows detected"
    echo "${LZeroSpeedup}"
    return 1
  fi

  LMemRegressions="$(awk '/^(MemEqual|MemFindByte|SumBytes|CountByte|BitsetPopCount)/ { if (($NF + 0) < 1.00) print }' "${TEST_LOG}")"
  if [[ -n "${LMemRegressions}" ]]; then
    echo "[PERF] FAILED: memory-facade speedup < 1.00x"
    echo "${LMemRegressions}"
    return 1
  fi

  echo "[PERF] OK (non-scalar backend benchmark looks healthy)"
}

run_interface_completeness() {
  if [[ ! -f "${INTERFACE_COMPLETENESS_SCRIPT}" ]]; then
    echo "[INTERFACE-CHECK] Missing checker: ${INTERFACE_COMPLETENESS_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[INTERFACE-CHECK] SKIP (python3 not found)"
    return 0
  fi

  local LStrictLevel
  local LJsonPath
  local LMdPath
  local -a LArgs

  LStrictLevel="${SIMD_INTERFACE_COMPLETENESS_STRICT_LEVEL:-p2}"
  LJsonPath="${SIMD_INTERFACE_COMPLETENESS_JSON_FILE:-${INTERFACE_COMPLETENESS_JSON_LOG}}"
  LMdPath="${SIMD_INTERFACE_COMPLETENESS_MD_FILE:-${INTERFACE_COMPLETENESS_MD_LOG}}"

  LArgs=(
    "--strict"
    "--strict-level" "${LStrictLevel}"
    "--json-file" "${LJsonPath}"
    "--md-file" "${LMdPath}"
  )

  echo "[INTERFACE-CHECK] Running: python3 ${INTERFACE_COMPLETENESS_SCRIPT} ${LArgs[*]}"
  python3 "${INTERFACE_COMPLETENESS_SCRIPT}" "${LArgs[@]}"
}

run_backend_adapter_sync() {
  if [[ "${SIMD_ADAPTER_SYNC_PASCAL_SMOKE:-1}" != "0" ]]; then
    run_backend_adapter_sync_pascal || return $?
  else
    echo "[ADAPTER-SYNC] SKIP Pascal smoke (SIMD_ADAPTER_SYNC_PASCAL_SMOKE=0)"
  fi

  if [[ ! -f "${ADAPTER_SYNC_SCRIPT}" ]]; then
    echo "[ADAPTER-SYNC] Missing checker: ${ADAPTER_SYNC_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[ADAPTER-SYNC] SKIP (python3 not found)"
    return 0
  fi

  local LSyncLog
  local LSyncJsonLog
  local LSummaryLine
  local LMainRC
  local -a LArgs

  LSyncLog="${SIMD_ADAPTER_SYNC_LOG_FILE:-${ADAPTER_SYNC_LOG}}"
  LSyncJsonLog="${SIMD_ADAPTER_SYNC_JSON_FILE:-${ADAPTER_SYNC_JSON_LOG}}"

  LArgs=("--summary-line")
  if [[ "${SIMD_ADAPTER_SYNC_STRICT:-1}" == "0" ]]; then
    LArgs+=("--no-strict")
  fi

  echo "[ADAPTER-SYNC] Running: python3 ${ADAPTER_SYNC_SCRIPT} ${LArgs[*]}"
  : > "${LSyncLog}"
  python3 "${ADAPTER_SYNC_SCRIPT}" "${LArgs[@]}" 2>&1 | tee "${LSyncLog}"
  LMainRC="${PIPESTATUS[0]}"

  if [[ "${SIMD_ADAPTER_SYNC_JSON:-1}" != "0" ]]; then
    local -a LJsonArgs
    LJsonArgs=("--json")
    if [[ "${SIMD_ADAPTER_SYNC_STRICT:-1}" == "0" ]]; then
      LJsonArgs+=("--no-strict")
    fi
    if python3 "${ADAPTER_SYNC_SCRIPT}" "${LJsonArgs[@]}" > "${LSyncJsonLog}"; then
      echo "[ADAPTER-SYNC] JSON snapshot: ${LSyncJsonLog}"
    else
      echo "[ADAPTER-SYNC] WARN: failed to snapshot JSON: ${LSyncJsonLog}"
    fi
  fi

  LSummaryLine="$(grep -E '^ADAPTER_SYNC_SUMMARY ' "${LSyncLog}" | tail -n 1 || true)"
  if [[ -n "${LSummaryLine}" ]]; then
    echo "[ADAPTER-SYNC] Summary: ${LSummaryLine#ADAPTER_SYNC_SUMMARY }"
  fi

  return "${LMainRC}"
}

run_backend_adapter_sync_pascal() {
  echo "[ADAPTER-SYNC-PASCAL] suite=TTestCase_DispatchAllSlots"
  run_tests --suite=TTestCase_DispatchAllSlots || return $?
  check_heap_leaks || return $?
}

run_coverage() {
  if [[ ! -f "${COVERAGE_SCRIPT}" ]]; then
    echo "[COVERAGE] Missing checker: ${COVERAGE_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[COVERAGE] SKIP (python3 not found)"
    return 0
  fi

  local -a LCoverageArgs
  LCoverageArgs=()
  if [[ "${SIMD_COVERAGE_STRICT_EXTRA:-0}" != "0" ]]; then
    LCoverageArgs+=("--strict-extra")
  fi
  if [[ "${SIMD_COVERAGE_REQUIRE_AVX2:-0}" != "0" ]]; then
    LCoverageArgs+=("--require-avx2")
  fi
  if [[ "${SIMD_COVERAGE_REQUIRE_EXPERIMENTAL:-0}" != "0" ]]; then
    LCoverageArgs+=("--require-experimental")
  fi

  echo "[COVERAGE] Running: python3 ${COVERAGE_SCRIPT} ${LCoverageArgs[*]}"
  python3 "${COVERAGE_SCRIPT}" "${LCoverageArgs[@]}"
}

run_intrinsics_experimental_status() {
  if [[ ! -f "${EXPERIMENTAL_INTRINSICS_SCRIPT}" ]]; then
    echo "[EXPERIMENTAL] Missing checker: ${EXPERIMENTAL_INTRINSICS_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[EXPERIMENTAL] SKIP (python3 not found)"
    return 0
  fi

  echo "[EXPERIMENTAL] Running: python3 ${EXPERIMENTAL_INTRINSICS_SCRIPT}"
  python3 "${EXPERIMENTAL_INTRINSICS_SCRIPT}"
}

run_experimental_intrinsics_tests() {
  local LTestsRoot
  local LRunner

  LTestsRoot="$(cd "${ROOT}/.." && pwd)"
  LRunner="${LTestsRoot}/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh"

  if [[ ! -x "${LRunner}" ]]; then
    echo "[EXPERIMENTAL-TESTS] Missing runner: ${LRunner}"
    return 2
  fi

  echo "[EXPERIMENTAL-TESTS] Running: bash ${LRunner} test-all"
  bash "${LRunner}" test-all
}

append_gate_summary() {
  local LStep
  local LStatus
  local LDetail
  local LDurationMs
  local LEvent
  local LArtifacts
  local LSummaryFile
  local LMaxDetail
  local LTrimmedChars

  LStep="${1:-unknown-step}"
  LStatus="${2:-INFO}"
  LDetail="${3:-}"
  LDurationMs="${4:--}"
  LEvent="${5:-INFO}"
  LArtifacts="${6:--}"
  LSummaryFile="${SIMD_GATE_SUMMARY_FILE:-${GATE_SUMMARY_LOG}}"

  LDetail="${LDetail//$'\n'/ }"
  LDetail="${LDetail//|//}"
  LArtifacts="${LArtifacts//$'\n'/ }"
  LArtifacts="${LArtifacts//|//}"

  LMaxDetail="${SIMD_GATE_SUMMARY_MAX_DETAIL:-260}"
  if [[ "${LMaxDetail}" =~ ^[0-9]+$ ]] && (( LMaxDetail > 0 )) && (( ${#LDetail} > LMaxDetail )); then
    LTrimmedChars="$(( ${#LDetail} - LMaxDetail ))"
    LDetail="${LDetail:0:LMaxDetail}...(truncated ${LTrimmedChars} chars)"
  fi

  mkdir -p "$(dirname "${LSummaryFile}")"
  if [[ ! -f "${LSummaryFile}" ]]; then
    echo "| Time | Step | Status | DurationMs | Event | Detail | Artifacts |" > "${LSummaryFile}"
    echo "|---|---|---|---|---|---|---|" >> "${LSummaryFile}"
  fi

  printf '| %s | %s | %s | %s | %s | %s | %s |\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${LStep}" "${LStatus}" "${LDurationMs}" "${LEvent}" "${LDetail}" "${LArtifacts}" >> "${LSummaryFile}"
}

reset_gate_summary() {
  local LSummaryFile

  LSummaryFile="${SIMD_GATE_SUMMARY_FILE:-${GATE_SUMMARY_LOG}}"
  mkdir -p "$(dirname "${LSummaryFile}")"
  echo "| Time | Step | Status | DurationMs | Event | Detail | Artifacts |" > "${LSummaryFile}"
  echo "|---|---|---|---|---|---|---|" >> "${LSummaryFile}"
}

now_ms() {
  if date +%s%3N >/dev/null 2>&1; then
    date +%s%3N
  else
    echo "$(( $(date +%s) * 1000 ))"
  fi
}

gate_step_event() {
  local LDurationMs
  local LWarnMs
  local LFailMs

  LDurationMs="${1:--}"
  LWarnMs="${SIMD_GATE_STEP_WARN_MS:-20000}"
  LFailMs="${SIMD_GATE_STEP_FAIL_MS:-120000}"

  if [[ "${LDurationMs}" == "-" ]]; then
    echo "NA"
    return 0
  fi

  if (( LDurationMs >= LFailMs )); then
    echo "SLOW_FAIL"
  elif (( LDurationMs >= LWarnMs )); then
    echo "SLOW_WARN"
  else
    echo "NORMAL"
  fi
}

run_gate_step() {
  local LStep
  local LPassDetail
  local LFailDetail
  local LArtifacts
  local LStartMs
  local LEndMs
  local LDurationMs
  local LEvent
  local LCommand
  local LRC

  LStep="${1:-unknown-step}"
  LPassDetail="${2:-ok}"
  LFailDetail="${3:-failed}"
  LArtifacts="${4:--}"
  shift 4

  LCommand="$*"

  LStartMs="$(now_ms)"
  if "$@"; then
    LEndMs="$(now_ms)"
    LDurationMs="$(( LEndMs - LStartMs ))"
    LEvent="$(gate_step_event "${LDurationMs}")"
    append_gate_summary "${LStep}" "PASS" "${LPassDetail}" "${LDurationMs}" "${LEvent}" "${LArtifacts}"
    return 0
  else
    LRC=$?
    LEndMs="$(now_ms)"
    LDurationMs="$(( LEndMs - LStartMs ))"
    LEvent="FAILED"
    append_gate_summary "${LStep}" "FAIL" "rc=${LRC}; ${LFailDetail}; cmd=${LCommand}" "${LDurationMs}" "${LEvent}" "${LArtifacts}"
    return "${LRC}"
  fi
}

gate_step_build_check() {
  build_project || return $?
  check_build_log || return $?
  check_windows_runner_parity || return $?
  check_cpuinfo_runner_parity || return $?
}

gate_step_interface_completeness() {
  run_interface_completeness || return $?
}

gate_step_adapter_sync_pascal() {
  run_backend_adapter_sync_pascal || return $?
}

gate_step_adapter_sync() {
  run_backend_adapter_sync || return $?
}

gate_step_adapter_sync_python_only() {
  SIMD_ADAPTER_SYNC_PASCAL_SMOKE=0 run_backend_adapter_sync || return $?
}

gate_step_simd_list_suites() {
  run_tests --list-suites || return $?
  check_heap_leaks || return $?
}

gate_step_simd_avx2_fallback() {
  run_tests --suite=TTestCase_AVX2IntrinsicsFallback || return $?
  check_heap_leaks || return $?
}

gate_step_cross_backend_parity() {
  run_tests --suite=TTestCase_DispatchAllSlots || return $?
  check_heap_leaks || return $?
  run_tests --suite=TTestCase_DispatchAPI || return $?
  check_heap_leaks || return $?
}

gate_step_nonx86_ieee754() {
  run_tests --suite=TTestCase_NonX86IEEE754 || return $?
  check_heap_leaks || return $?
}

gate_step_cpuinfo_portable() {
  local LTestsRoot

  LTestsRoot="${1}"
  bash "${LTestsRoot}/fafafa.core.simd.cpuinfo/BuildOrTest.sh" test --list-suites || return $?
  bash "${LTestsRoot}/fafafa.core.simd.cpuinfo/BuildOrTest.sh" test --suite=TTestCase_PlatformSpecific || return $?
}

gate_step_cpuinfo_x86() {
  local LTestsRoot

  LTestsRoot="${1}"
  bash "${LTestsRoot}/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh" test --list-suites || return $?
  bash "${LTestsRoot}/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh" test --suite=TTestCase_Global || return $?
}

gate_step_filtered_run_all() {
  local LTestsRoot

  LTestsRoot="${1}"
  STOP_ON_FAIL=1 bash "${LTestsRoot}/run_all_tests.sh" \
    =fafafa.core.simd \
    =fafafa.core.simd.cpuinfo \
    =fafafa.core.simd.cpuinfo.x86 \
    =fafafa.core.simd.intrinsics.sse \
    =fafafa.core.simd.intrinsics.mmx
}

gate_step_concurrent_repeat() {
  local LRounds

  LRounds="${SIMD_GATE_CONCURRENT_REPEAT:-10}"
  run_suite_repeat "TTestCase_SimdConcurrent" "${LRounds}" || return $?
}

gate_step_qemu_nonx86_evidence() {
  run_qemu_multiarch "nonx86-evidence" || return $?
}

gate_step_qemu_arch_matrix_evidence() {
  run_qemu_multiarch "arch-matrix-evidence" || return $?
}

gate_step_evidence_verify() {
  verify_windows_evidence_if_present || return $?
}

run_wiring_sync() {
  if [[ ! -f "${WIRING_SYNC_SCRIPT}" ]]; then
    echo "[WIRING-SYNC] Missing checker: ${WIRING_SYNC_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[WIRING-SYNC] SKIP (python3 not found)"
    return 0
  fi

  local LWiringLog
  local LWiringJsonLog
  local LSummaryLine
  local LMainRC
  local -a LWiringArgs

  LWiringLog="${SIMD_WIRING_SYNC_LOG_FILE:-${WIRING_SYNC_LOG}}"
  LWiringJsonLog="${SIMD_WIRING_SYNC_JSON_FILE:-${WIRING_SYNC_JSON_LOG}}"

  LWiringArgs=()
  if [[ "${SIMD_WIRING_SYNC_STRICT_EXTRA:-0}" != "0" ]]; then
    LWiringArgs+=("--strict-extra")
  fi
  LWiringArgs+=("--summary-line")

  echo "[WIRING-SYNC] Running: python3 ${WIRING_SYNC_SCRIPT} ${LWiringArgs[*]}"
  : > "${LWiringLog}"
  python3 "${WIRING_SYNC_SCRIPT}" "${LWiringArgs[@]}" 2>&1 | tee "${LWiringLog}"
  LMainRC="${PIPESTATUS[0]}"

  if [[ "${SIMD_WIRING_SYNC_JSON:-1}" != "0" ]]; then
    local -a LWiringJsonArgs
    LWiringJsonArgs=("--json")
    if [[ "${SIMD_WIRING_SYNC_STRICT_EXTRA:-0}" != "0" ]]; then
      LWiringJsonArgs+=("--strict-extra")
    fi
    if python3 "${WIRING_SYNC_SCRIPT}" "${LWiringJsonArgs[@]}" > "${LWiringJsonLog}"; then
      echo "[WIRING-SYNC] JSON snapshot: ${LWiringJsonLog}"
    else
      echo "[WIRING-SYNC] WARN: failed to snapshot JSON: ${LWiringJsonLog}"
    fi
  fi

  LSummaryLine="$(grep -E '^WIRING_SYNC_SUMMARY ' "${LWiringLog}" | tail -n 1 || true)"
  if [[ -n "${LSummaryLine}" ]]; then
    echo "[WIRING-SYNC] Summary: ${LSummaryLine#WIRING_SYNC_SUMMARY }"
  fi

  return "${LMainRC}"
}

run_perf_smoke() {
  build_project || return $?
  run_tests --bench-only || return $?
  check_heap_leaks || return $?
  check_perf_log || return $?
}

run_nonx86_ieee754() {
  build_project || return $?
  run_tests --suite=TTestCase_NonX86IEEE754 || return $?
  check_heap_leaks || return $?
}

run_backend_bench() {
  local LBenchScript
  LBenchScript="${ROOT}/run_backend_benchmarks.sh"

  if [[ ! -x "${LBenchScript}" ]]; then
    echo "[BENCH] Missing script: ${LBenchScript}"
    return 2
  fi

  "${LBenchScript}" "$@"
}

run_qemu_multiarch() {
  local LQemuScript
  local LScenario

  LScenario="${1:-nonx86-evidence}"
  shift || true
  LQemuScript="${ROOT}/docker/run_multiarch_qemu.sh"

  if [[ ! -x "${LQemuScript}" ]]; then
    echo "[QEMU] Missing script: ${LQemuScript}"
    return 2
  fi

  echo "[QEMU] Build policy: ${SIMD_QEMU_BUILD_POLICY:-if-missing} (always|if-missing|skip)"

  if [[ "${LScenario}" == "nonx86-experimental-asm" ]]; then
    echo "[QEMU] Experimental asm env:"
    echo "[QEMU]   SIMD_QEMU_ENABLE_BACKEND_ASM=${SIMD_QEMU_ENABLE_BACKEND_ASM:-0}"
    echo "[QEMU]   SIMD_QEMU_BACKEND_ASM_PROBE_MODE=${SIMD_QEMU_BACKEND_ASM_PROBE_MODE:-1}"
    echo "[QEMU]   SIMD_QEMU_EXPERIMENTAL_ARM64_COMPILER_DEFINE=${SIMD_QEMU_EXPERIMENTAL_ARM64_COMPILER_DEFINE:-<empty>}"
    echo "[QEMU]   SIMD_QEMU_EXPERIMENTAL_RISCV64_COMPILER_DEFINE=${SIMD_QEMU_EXPERIMENTAL_RISCV64_COMPILER_DEFINE:-<empty>}"
    echo "[QEMU]   SIMD_QEMU_EXPERIMENTAL_RISCV64_OPCODE_DEFINE=${SIMD_QEMU_EXPERIMENTAL_RISCV64_OPCODE_DEFINE:-<empty>}"
  fi

  bash "${LQemuScript}" "${LScenario}" "$@"
}

run_riscvv_opcode_lane() {
  local LScript
  LScript="${ROOT}/docker/run_riscvv_opcode_lane.sh"

  if [[ ! -x "${LScript}" ]]; then
    echo "[RVV-LANE] Missing script: ${LScript}"
    return 2
  fi

  bash "${LScript}" "$@"
}

run_qemu_experimental_report() {
  local -a LArgs

  if [[ ! -f "${QEMU_EXPERIMENTAL_REPORT_SCRIPT}" ]]; then
    echo "[QEMU-EXPERIMENTAL-REPORT] Missing script: ${QEMU_EXPERIMENTAL_REPORT_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[QEMU-EXPERIMENTAL-REPORT] SKIP (python3 not found)"
    return 0
  fi

  if [[ "$#" -eq 0 ]]; then
    LArgs=("--latest")
  else
    LArgs=("$@")
  fi

  echo "[QEMU-EXPERIMENTAL-REPORT] Running: python3 ${QEMU_EXPERIMENTAL_REPORT_SCRIPT} ${LArgs[*]}"
  python3 "${QEMU_EXPERIMENTAL_REPORT_SCRIPT}" "${LArgs[@]}"
}

run_qemu_experimental_baseline_check() {
  local -a LArgs

  if [[ ! -f "${QEMU_EXPERIMENTAL_BASELINE_SCRIPT}" ]]; then
    echo "[QEMU-EXPERIMENTAL-BASELINE] Missing script: ${QEMU_EXPERIMENTAL_BASELINE_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[QEMU-EXPERIMENTAL-BASELINE] SKIP (python3 not found)"
    return 0
  fi

  if [[ "$#" -eq 0 ]]; then
    LArgs=("--latest")
  else
    LArgs=("$@")
  fi

  echo "[QEMU-EXPERIMENTAL-BASELINE] Running: python3 ${QEMU_EXPERIMENTAL_BASELINE_SCRIPT} ${LArgs[*]}"
  python3 "${QEMU_EXPERIMENTAL_BASELINE_SCRIPT}" "${LArgs[@]}"
}

verify_windows_evidence_if_present() {
  local LEvidenceLog

  LEvidenceLog="${ROOT}/logs/windows_b07_gate.log"
  if [[ ! -f "${LEvidenceLog}" ]]; then
    if [[ "${SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE:-0}" != "0" ]]; then
      echo "[CHECK] FAILED (required windows evidence log missing: ${LEvidenceLog})"
      return 1
    fi
    echo "[CHECK] SKIP (windows evidence log not present: ${LEvidenceLog})"
    return 0
  fi

  verify_windows_evidence "${LEvidenceLog}"
}

run_gate() {
  local LTestsRoot
  local LGateStartMs
  local LGateEndMs
  local LGateDurationMs
  local LGateEvent
  local LWiringSummary
  local LWiringRC
  local LWiringStartMs
  local LWiringEndMs
  local LWiringDurationMs
  local LWiringEvent
  local LRunAllLogDir
  local LRunAllSummary

  LTestsRoot="$(cd "${ROOT}/.." && pwd)"
  LRunAllLogDir="${LTestsRoot}/_run_all_logs_sh"
  LRunAllSummary="${LTestsRoot}/run_all_tests_summary_sh.txt"
  LGateStartMs="$(now_ms)"

  if [[ "${SIMD_GATE_SUMMARY_APPEND:-0}" == "0" ]]; then
    reset_gate_summary
  fi

  append_gate_summary "gate" "START" "mode=${MODE}; interface-completeness=${SIMD_GATE_INTERFACE_COMPLETENESS:-0}; adapter-sync-pascal=${SIMD_GATE_ADAPTER_SYNC_PASCAL:-0}; adapter-sync=${SIMD_GATE_ADAPTER_SYNC:-0}; parity-suites=${SIMD_GATE_PARITY_SUITES:-0}; wiring=${SIMD_GATE_WIRING_SYNC:-0}; coverage=${SIMD_GATE_COVERAGE:-0}; perf=${SIMD_GATE_PERF_SMOKE:-0}; experimental=${SIMD_GATE_EXPERIMENTAL:-1}; experimental-tests=${SIMD_GATE_EXPERIMENTAL_TESTS:-0}; nonx86-ieee754=${SIMD_GATE_NONX86_IEEE754:-0}; qemu-nonx86-evidence=${SIMD_GATE_QEMU_NONX86_EVIDENCE:-0}; qemu-arch-matrix=${SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE:-0}; require-win-evidence=${SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE:-0}; concurrent-repeat=${SIMD_GATE_CONCURRENT_REPEAT:-0}" "-" "START" "${BUILD_LOG}; ${TEST_LOG}; ${SIMD_WIRING_SYNC_LOG_FILE:-${WIRING_SYNC_LOG}}"

  echo "[GATE] 1/6 Build + check SIMD module"
  if ! run_gate_step "build-check" "build/check/parity passed" "see ${BUILD_LOG}" "${BUILD_LOG}" gate_step_build_check; then
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=build-check" "${LGateDurationMs}" "FAILED"
    return 1
  fi

  if [[ "${SIMD_GATE_INTERFACE_COMPLETENESS:-0}" != "0" ]]; then
    echo "[GATE] Optional interface completeness check"
    if ! run_gate_step "interface-completeness" "interface completeness passed" "interface completeness check failed" "${SIMD_INTERFACE_COMPLETENESS_JSON_FILE:-${INTERFACE_COMPLETENESS_JSON_LOG}}; ${SIMD_INTERFACE_COMPLETENESS_MD_FILE:-${INTERFACE_COMPLETENESS_MD_LOG}}" gate_step_interface_completeness; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=interface-completeness" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "interface-completeness" "SKIP" "SIMD_GATE_INTERFACE_COMPLETENESS=0" "-" "SKIP" "${SIMD_INTERFACE_COMPLETENESS_JSON_FILE:-${INTERFACE_COMPLETENESS_JSON_LOG}}; ${SIMD_INTERFACE_COMPLETENESS_MD_FILE:-${INTERFACE_COMPLETENESS_MD_LOG}}"
  fi

  if [[ "${SIMD_GATE_ADAPTER_SYNC_PASCAL:-0}" != "0" ]]; then
    echo "[GATE] Optional backend adapter sync Pascal smoke"
    if ! run_gate_step "adapter-sync-pascal" "backend adapter pascal smoke passed" "backend adapter pascal smoke failed" "${TEST_LOG}" gate_step_adapter_sync_pascal; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=adapter-sync-pascal" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "adapter-sync-pascal" "SKIP" "SIMD_GATE_ADAPTER_SYNC_PASCAL=0" "-" "SKIP" "${TEST_LOG}"
  fi

  if [[ "${SIMD_GATE_ADAPTER_SYNC:-0}" != "0" ]]; then
    echo "[GATE] Optional backend adapter sync"
    if [[ "${SIMD_GATE_ADAPTER_SYNC_PASCAL:-0}" != "0" ]]; then
      if ! run_gate_step "adapter-sync" "backend adapter sync passed (python-only; pascal smoke in adapter-sync-pascal step)" "backend adapter sync failed" "${SIMD_ADAPTER_SYNC_LOG_FILE:-${ADAPTER_SYNC_LOG}}; ${SIMD_ADAPTER_SYNC_JSON_FILE:-${ADAPTER_SYNC_JSON_LOG}}" gate_step_adapter_sync_python_only; then
        LGateEndMs="$(now_ms)"
        LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
        append_gate_summary "gate" "FAIL" "failed-step=adapter-sync" "${LGateDurationMs}" "FAILED"
        return 1
      fi
    else
      if ! run_gate_step "adapter-sync" "backend adapter sync passed" "backend adapter sync failed" "${SIMD_ADAPTER_SYNC_LOG_FILE:-${ADAPTER_SYNC_LOG}}; ${SIMD_ADAPTER_SYNC_JSON_FILE:-${ADAPTER_SYNC_JSON_LOG}}" gate_step_adapter_sync; then
        LGateEndMs="$(now_ms)"
        LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
        append_gate_summary "gate" "FAIL" "failed-step=adapter-sync" "${LGateDurationMs}" "FAILED"
        return 1
      fi
    fi
  else
    append_gate_summary "adapter-sync" "SKIP" "SIMD_GATE_ADAPTER_SYNC=0" "-" "SKIP" "${SIMD_ADAPTER_SYNC_LOG_FILE:-${ADAPTER_SYNC_LOG}}; ${SIMD_ADAPTER_SYNC_JSON_FILE:-${ADAPTER_SYNC_JSON_LOG}}"
  fi

  if [[ "${SIMD_GATE_WIRING_SYNC:-0}" != "0" ]]; then
    echo "[GATE] Optional wiring-sync enabled"
    LWiringStartMs="$(now_ms)"
    if run_wiring_sync; then
      LWiringEndMs="$(now_ms)"
      LWiringDurationMs="$(( LWiringEndMs - LWiringStartMs ))"
      LWiringEvent="$(gate_step_event "${LWiringDurationMs}")"
      LWiringSummary="$(grep -E '^WIRING_SYNC_SUMMARY ' "${SIMD_WIRING_SYNC_LOG_FILE:-${WIRING_SYNC_LOG}}" | tail -n 1 | sed -e 's/^WIRING_SYNC_SUMMARY //' || true)"
      append_gate_summary "wiring-sync" "PASS" "${LWiringSummary:-summary-missing}" "${LWiringDurationMs}" "${LWiringEvent}" "${SIMD_WIRING_SYNC_LOG_FILE:-${WIRING_SYNC_LOG}}; ${SIMD_WIRING_SYNC_JSON_FILE:-${WIRING_SYNC_JSON_LOG}}"
    else
      LWiringRC=$?
      LWiringEndMs="$(now_ms)"
      LWiringDurationMs="$(( LWiringEndMs - LWiringStartMs ))"
      LWiringSummary="$(grep -E '^WIRING_SYNC_SUMMARY ' "${SIMD_WIRING_SYNC_LOG_FILE:-${WIRING_SYNC_LOG}}" | tail -n 1 | sed -e 's/^WIRING_SYNC_SUMMARY //' || true)"
      append_gate_summary "wiring-sync" "FAIL" "rc=${LWiringRC}; ${LWiringSummary:-run-failed}; log=${SIMD_WIRING_SYNC_LOG_FILE:-${WIRING_SYNC_LOG}}" "${LWiringDurationMs}" "FAILED" "${SIMD_WIRING_SYNC_LOG_FILE:-${WIRING_SYNC_LOG}}; ${SIMD_WIRING_SYNC_JSON_FILE:-${WIRING_SYNC_JSON_LOG}}"
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=wiring-sync" "${LGateDurationMs}" "FAILED"
      return "${LWiringRC}"
    fi
  else
    echo "[GATE] SKIP optional wiring-sync (set SIMD_GATE_WIRING_SYNC=1 to enable)"
    append_gate_summary "wiring-sync" "SKIP" "SIMD_GATE_WIRING_SYNC=0" "-" "SKIP" "-"
  fi

  echo "[GATE] 2/6 SIMD list suites"
  if ! run_gate_step "simd-list-suites" "suite-list + leak-check passed" "see ${TEST_LOG}" "${TEST_LOG}" gate_step_simd_list_suites; then
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=simd-list-suites" "${LGateDurationMs}" "FAILED"
    return 1
  fi

  echo "[GATE] 3/6 SIMD AVX2 fallback suite"
  if ! run_gate_step "simd-avx2-fallback" "suite + leak-check passed" "see ${TEST_LOG}" "${TEST_LOG}" gate_step_simd_avx2_fallback; then
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=simd-avx2-fallback" "${LGateDurationMs}" "FAILED"
    return 1
  fi

  if [[ "${SIMD_GATE_PARITY_SUITES:-0}" != "0" ]]; then
    echo "[GATE] Optional cross-backend parity suites"
    if ! run_gate_step "cross-backend-parity" "dispatch slot/api parity suites passed" "cross-backend parity suites failed" "${TEST_LOG}" gate_step_cross_backend_parity; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=cross-backend-parity" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "cross-backend-parity" "SKIP" "SIMD_GATE_PARITY_SUITES=0" "-" "SKIP" "${TEST_LOG}"
  fi

  if [[ "${SIMD_GATE_NONX86_IEEE754:-0}" != "0" ]]; then
    echo "[GATE] Optional non-x86 IEEE754 suite"
    if ! run_gate_step "nonx86-ieee754" "non-x86 ieee754 suite + leak-check passed" "non-x86 ieee754 suite failed" "${TEST_LOG}" gate_step_nonx86_ieee754; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=nonx86-ieee754" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "nonx86-ieee754" "SKIP" "SIMD_GATE_NONX86_IEEE754=0" "-" "SKIP" "${TEST_LOG}"
  fi

  echo "[GATE] 4/6 CPUInfo portable suites"
  if ! run_gate_step "cpuinfo-portable" "list + platform-specific passed" "cpuinfo portable suite failed" "${LTestsRoot}/fafafa.core.simd.cpuinfo/logs/test.txt" gate_step_cpuinfo_portable "${LTestsRoot}"; then
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=cpuinfo-portable" "${LGateDurationMs}" "FAILED"
    return 1
  fi

  echo "[GATE] 5/6 CPUInfo x86 suites"
  if ! run_gate_step "cpuinfo-x86" "list + global passed" "cpuinfo x86 suite failed" "${LTestsRoot}/fafafa.core.simd.cpuinfo.x86/logs/test.txt" gate_step_cpuinfo_x86 "${LTestsRoot}"; then
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=cpuinfo-x86" "${LGateDurationMs}" "FAILED"
    return 1
  fi

  echo "[GATE] 6/6 Filtered run_all chain"
  if ! run_gate_step "run-all-chain" "filtered run_all passed; logs=${LRunAllLogDir}; summary=${LRunAllSummary}" "run_all chain failed; logs=${LRunAllLogDir}; summary=${LRunAllSummary}" "${LRunAllLogDir}; ${LRunAllSummary}" gate_step_filtered_run_all "${LTestsRoot}"; then
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=run-all-chain" "${LGateDurationMs}" "FAILED"
    return 1
  fi

  if [[ "${SIMD_GATE_CONCURRENT_REPEAT:-0}" != "0" ]]; then
    echo "[GATE] Optional concurrent repeat (${SIMD_GATE_CONCURRENT_REPEAT} rounds)"
    if ! run_gate_step "concurrent-repeat" "simd concurrent repeat passed; rounds=${SIMD_GATE_CONCURRENT_REPEAT}" "simd concurrent repeat failed; rounds=${SIMD_GATE_CONCURRENT_REPEAT}" "${LOG_DIR}/repeat.TTestCase_SimdConcurrent.*.txt" gate_step_concurrent_repeat; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=concurrent-repeat" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "concurrent-repeat" "SKIP" "SIMD_GATE_CONCURRENT_REPEAT=0" "-" "SKIP" "${LOG_DIR}/repeat.TTestCase_SimdConcurrent.*.txt"
  fi

  if [[ "${SIMD_GATE_EXPERIMENTAL:-1}" != "0" ]]; then
    echo "[GATE] Optional experimental intrinsics isolation"
    if ! run_gate_step "experimental-intrinsics" "experimental entry isolation passed" "experimental entry leak detected" "${EXPERIMENTAL_INTRINSICS_SCRIPT}" run_intrinsics_experimental_status; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=experimental-intrinsics" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "experimental-intrinsics" "SKIP" "SIMD_GATE_EXPERIMENTAL=0" "-" "SKIP" "${EXPERIMENTAL_INTRINSICS_SCRIPT}"
  fi

  if [[ "${SIMD_GATE_EXPERIMENTAL_TESTS:-0}" != "0" ]]; then
    echo "[GATE] Optional experimental intrinsics tests"
    if ! run_gate_step "experimental-tests" "experimental test-all passed" "experimental test-all failed" "${ROOT}/../fafafa.core.simd.intrinsics.experimental" run_experimental_intrinsics_tests; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=experimental-tests" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "experimental-tests" "SKIP" "SIMD_GATE_EXPERIMENTAL_TESTS=0" "-" "SKIP" "${ROOT}/../fafafa.core.simd.intrinsics.experimental"
  fi

  if [[ "${SIMD_GATE_COVERAGE:-0}" != "0" ]]; then
    echo "[GATE] Optional intrinsics coverage"
    if ! run_gate_step "coverage" "coverage passed" "coverage check failed" "${ROOT}/check_intrinsics_coverage.py" run_coverage; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=coverage" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "coverage" "SKIP" "SIMD_GATE_COVERAGE=0" "-" "SKIP" "${ROOT}/check_intrinsics_coverage.py"
  fi

  if [[ "${SIMD_GATE_PERF_SMOKE:-0}" != "0" ]]; then
    echo "[GATE] Optional perf smoke"
    if ! run_gate_step "perf-smoke" "perf-smoke passed" "perf-smoke failed" "${TEST_LOG}" run_perf_smoke; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=perf-smoke" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "perf-smoke" "SKIP" "SIMD_GATE_PERF_SMOKE=0" "-" "SKIP" "${TEST_LOG}"
  fi

  if [[ "${SIMD_GATE_QEMU_NONX86_EVIDENCE:-0}" != "0" ]]; then
    echo "[GATE] Optional qemu non-x86 evidence"
    if ! run_gate_step "qemu-nonx86-evidence" "qemu non-x86 evidence passed" "qemu non-x86 evidence failed" "${ROOT}/logs/qemu-multiarch-*" gate_step_qemu_nonx86_evidence; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=qemu-nonx86-evidence" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "qemu-nonx86-evidence" "SKIP" "SIMD_GATE_QEMU_NONX86_EVIDENCE=0" "-" "SKIP" "${ROOT}/logs/qemu-multiarch-*"
  fi

  if [[ "${SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE:-0}" != "0" ]]; then
    echo "[GATE] Optional qemu arch matrix evidence"
    if ! run_gate_step "qemu-arch-matrix-evidence" "qemu arch matrix evidence passed" "qemu arch matrix evidence failed" "${ROOT}/logs/qemu-multiarch-*" gate_step_qemu_arch_matrix_evidence; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=qemu-arch-matrix-evidence" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "qemu-arch-matrix-evidence" "SKIP" "SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0" "-" "SKIP" "${ROOT}/logs/qemu-multiarch-*"
  fi

  echo "[GATE] Evidence verify (windows log optional unless SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1)"
  if ! run_gate_step "evidence-verify" "verify/skip completed" "verify-win-evidence failed" "${ROOT}/logs/windows_b07_gate.log" gate_step_evidence_verify; then
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=evidence-verify" "${LGateDurationMs}" "FAILED"
    return 1
  fi

  LGateEndMs="$(now_ms)"
  LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
  LGateEvent="$(gate_step_event "${LGateDurationMs}")"
  append_gate_summary "gate" "PASS" "all steps passed" "${LGateDurationMs}" "${LGateEvent}"
  echo "[GATE] OK"
}

write_gate_summary_json() {
  local LSummaryFile
  local LJsonFile
  local LSummaryFilter

  LSummaryFile="${1}"
  LJsonFile="${2}"
  LSummaryFilter="${3}"

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[GATE-SUMMARY] SKIP JSON export (python3 not found)"
    return 0
  fi

  if [[ ! -f "${GATE_SUMMARY_EXPORT_SCRIPT}" ]]; then
    echo "[GATE-SUMMARY] Missing exporter: ${GATE_SUMMARY_EXPORT_SCRIPT}"
    return 2
  fi

  python3 "${GATE_SUMMARY_EXPORT_SCRIPT}" \
    --input "${LSummaryFile}" \
    --output "${LJsonFile}" \
    --filter "${LSummaryFilter}" \
    --warn-ms "${SIMD_GATE_STEP_WARN_MS:-20000}" \
    --fail-ms "${SIMD_GATE_STEP_FAIL_MS:-120000}"
}

run_gate_summary() {
  local LSummaryFile
  local LTailLines
  local LSummaryFilter
  local LRowsFile
  local LJsonEnabled
  local LJsonFile

  LSummaryFile="${SIMD_GATE_SUMMARY_FILE:-${GATE_SUMMARY_LOG}}"
  LTailLines="${SIMD_GATE_SUMMARY_TAIL:-80}"
  LSummaryFilter="$(echo "${SIMD_GATE_SUMMARY_FILTER:-ALL}" | tr '[:lower:]' '[:upper:]')"
  LJsonEnabled="${SIMD_GATE_SUMMARY_JSON:-0}"
  LJsonFile="${SIMD_GATE_SUMMARY_JSON_FILE:-${GATE_SUMMARY_JSON_LOG}}"

  if [[ ! -f "${LSummaryFile}" ]]; then
    echo "[GATE-SUMMARY] Missing summary file: ${LSummaryFile}"
    return 2
  fi

  if [[ ! "${LTailLines}" =~ ^[0-9]+$ ]]; then
    LTailLines="80"
  fi

  case "${LSummaryFilter}" in
    ALL|FAIL|SLOW)
      ;;
    *)
      echo "[GATE-SUMMARY] WARN: unsupported filter=${LSummaryFilter}, fallback=ALL"
      LSummaryFilter="ALL"
      ;;
  esac

  echo "[GATE-SUMMARY] ${LSummaryFile} (tail=${LTailLines})"
  echo "[GATE-SUMMARY] thresholds: warn_ms=${SIMD_GATE_STEP_WARN_MS:-20000}, fail_ms=${SIMD_GATE_STEP_FAIL_MS:-120000}"
  echo "[GATE-SUMMARY] filter=${LSummaryFilter}, max_detail=${SIMD_GATE_SUMMARY_MAX_DETAIL:-260}"

  head -n 2 "${LSummaryFile}"

  LRowsFile="$(mktemp)"
  awk -F'|' -v LFilter="${LSummaryFilter}" '
    function trim(v) {
      gsub(/^[ 	]+|[ 	]+$/, "", v)
      return v
    }
    NR <= 2 { next }
    NF >= 8 {
      LStatus = trim($4)
      LEvent = trim($6)
      if (LFilter == "ALL") { print $0; next }
      if (LFilter == "FAIL" && LStatus == "FAIL") { print $0; next }
      if (LFilter == "SLOW" && (LEvent == "SLOW_WARN" || LEvent == "SLOW_FAIL")) { print $0; next }
    }
  ' "${LSummaryFile}" > "${LRowsFile}"

  local LMatchedRows
  LMatchedRows="$(wc -l < "${LRowsFile}" | tr -d '[:space:]')"

  if [[ -s "${LRowsFile}" ]]; then
    echo "[GATE-SUMMARY] matched_rows=${LMatchedRows}"
    tail -n "${LTailLines}" "${LRowsFile}"
  else
    echo "[GATE-SUMMARY] matched_rows=0"
    echo "[GATE-SUMMARY] no rows matched filter=${LSummaryFilter}"
  fi

  rm -f "${LRowsFile}"

  if [[ "${LJsonEnabled}" != "0" ]]; then
    write_gate_summary_json "${LSummaryFile}" "${LJsonFile}" "${LSummaryFilter}"
    echo "[GATE-SUMMARY] json=${LJsonFile}"
  fi
}

run_gate_summary_sample() {
  local LScenario
  local LOutput
  local LSampleScript

  LScenario="${1:-mixed}"
  LOutput="${2:-${LOG_DIR}/gate_summary.sample.${LScenario}.md}"
  LSampleScript="${GATE_SUMMARY_SAMPLE_SCRIPT:-${ROOT}/generate_gate_summary_sample.py}"

  if [[ ! -f "${LSampleScript}" ]]; then
    echo "[GATE-SUMMARY-SAMPLE] Missing generator: ${LSampleScript}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[GATE-SUMMARY-SAMPLE] Missing python3"
    return 2
  fi

  python3 "${LSampleScript}" \
    --scenario "${LScenario}" \
    --warn-ms "${SIMD_GATE_STEP_WARN_MS:-20000}" \
    --fail-ms "${SIMD_GATE_STEP_FAIL_MS:-120000}" \
    --output "${LOutput}"

  echo "[GATE-SUMMARY-SAMPLE] output=${LOutput}"
}

run_gate_summary_rehearsal() {
  local LRehearsalScript

  LRehearsalScript="${GATE_SUMMARY_REHEARSAL_SCRIPT:-${ROOT}/rehearse_gate_summary_thresholds.sh}"
  if [[ ! -x "${LRehearsalScript}" ]]; then
    echo "[GATE-SUMMARY-REHEARSAL] Missing script: ${LRehearsalScript}"
    return 2
  fi

  "${LRehearsalScript}" "$@"
}

run_gate_summary_inject() {
  local LInjectScript

  LInjectScript="${GATE_SUMMARY_INJECT_SCRIPT:-${ROOT}/inject_gate_summary_sample.sh}"
  if [[ ! -x "${LInjectScript}" ]]; then
    echo "[GATE-SUMMARY-INJECT] Missing script: ${LInjectScript}"
    return 2
  fi

  "${LInjectScript}" "$@"
}

run_gate_summary_rollback() {
  local LRollbackScript

  LRollbackScript="${GATE_SUMMARY_ROLLBACK_SCRIPT:-${ROOT}/rollback_gate_summary_sample.sh}"
  if [[ ! -x "${LRollbackScript}" ]]; then
    echo "[GATE-SUMMARY-ROLLBACK] Missing script: ${LRollbackScript}"
    return 2
  fi

  "${LRollbackScript}" "$@"
}

run_gate_summary_backups() {
  local LBackupsScript

  LBackupsScript="${GATE_SUMMARY_BACKUPS_SCRIPT:-${ROOT}/list_gate_summary_backups.sh}"
  if [[ ! -x "${LBackupsScript}" ]]; then
    echo "[GATE-SUMMARY-BACKUPS] Missing script: ${LBackupsScript}"
    return 2
  fi

  "${LBackupsScript}" "$@"
}

run_gate_summary_selfcheck() {
  local LSummaryFile
  local LTmpJson

  LSummaryFile="${SIMD_GATE_SUMMARY_FILE:-${GATE_SUMMARY_LOG}}"
  if [[ ! -f "${LSummaryFile}" ]]; then
    echo "[GATE-SUMMARY-SELFCHECK] Missing summary file: ${LSummaryFile}"
    return 2
  fi

  if ! SIMD_GATE_SUMMARY_FILTER=ALL run_gate_summary >/dev/null; then
    echo "[GATE-SUMMARY-SELFCHECK] FAILED: ALL filter"
    return 1
  fi

  if ! SIMD_GATE_SUMMARY_FILTER=FAIL run_gate_summary >/dev/null; then
    echo "[GATE-SUMMARY-SELFCHECK] FAILED: FAIL filter"
    return 1
  fi

  if ! SIMD_GATE_SUMMARY_FILTER=SLOW run_gate_summary >/dev/null; then
    echo "[GATE-SUMMARY-SELFCHECK] FAILED: SLOW filter"
    return 1
  fi

  LTmpJson="$(mktemp)"
  if ! SIMD_GATE_SUMMARY_FILTER=SLOW SIMD_GATE_SUMMARY_JSON=1 SIMD_GATE_SUMMARY_JSON_FILE="${LTmpJson}" run_gate_summary >/dev/null; then
    echo "[GATE-SUMMARY-SELFCHECK] FAILED: JSON export"
    rm -f "${LTmpJson}"
    return 1
  fi

  if [[ ! -s "${LTmpJson}" ]]; then
    echo "[GATE-SUMMARY-SELFCHECK] FAILED: JSON file empty"
    rm -f "${LTmpJson}"
    return 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    if ! python3 - "${LTmpJson}" <<'PY_JSON_CHECK'
import json
import sys
from pathlib import Path

json_path = Path(sys.argv[1])
payload = json.loads(json_path.read_text(encoding='utf-8'))
if payload.get('filter') != 'SLOW':
    raise SystemExit(1)
PY_JSON_CHECK
    then
      echo "[GATE-SUMMARY-SELFCHECK] FAILED: JSON filter mismatch"
      rm -f "${LTmpJson}"
      return 1
    fi
  fi

  rm -f "${LTmpJson}"
  echo "[GATE-SUMMARY-SELFCHECK] OK"
}

run_evidence_linux() {
  local LEvidenceScript

  LEvidenceScript="${ROOT}/collect_linux_simd_evidence.sh"

  if [[ ! -x "${LEvidenceScript}" ]]; then
    echo "[EVIDENCE] Missing collector: ${LEvidenceScript}"
    return 2
  fi

  "${LEvidenceScript}" "$@"
}

verify_windows_evidence() {
  local LEvidenceVerifier

  LEvidenceVerifier="${ROOT}/verify_windows_b07_evidence.sh"

  if [[ ! -x "${LEvidenceVerifier}" ]]; then
    echo "[CHECK] Missing evidence verifier: ${LEvidenceVerifier}"
    return 2
  fi

  "${LEvidenceVerifier}" "$@"
}

finalize_windows_evidence() {
  local LCloseoutScript

  LCloseoutScript="${ROOT}/finalize_windows_b07_closeout.sh"

  if [[ ! -x "${LCloseoutScript}" ]]; then
    echo "[CLOSEOUT] Missing closeout script: ${LCloseoutScript}"
    return 2
  fi

  "${LCloseoutScript}" "$@"
}

run_windows_closeout_dryrun() {
  local LSimScript
  local LSimLog
  local LSummaryLog

  LSimScript="${ROOT}/simulate_windows_b07_evidence.sh"
  if [[ ! -x "${LSimScript}" ]]; then
    echo "[CLOSEOUT] Missing simulator: ${LSimScript}"
    return 2
  fi

  LSimLog="${ROOT}/logs/windows_b07_gate.simulated.log"
  LSummaryLog="${ROOT}/logs/windows_b07_closeout_summary.simulated.md"

  "${LSimScript}" "${LSimLog}"
  verify_windows_evidence "${LSimLog}"
  finalize_windows_evidence "${LSimLog}" "${LSummaryLog}"

  echo "[CLOSEOUT] DRYRUN OK: ${LSummaryLog}"
}

windows_closeout_snippets() {
  local LApplyScript

  LApplyScript="${ROOT}/apply_windows_b07_closeout_updates.sh"
  if [[ ! -x "${LApplyScript}" ]]; then
    echo "[CLOSEOUT] Missing updater: ${LApplyScript}"
    return 2
  fi

  "${LApplyScript}" "$@"
}

print_windows_closeout_3cmd() {
  local LThreeCmdScript

  LThreeCmdScript="${WIN_CLOSEOUT_3CMD_SCRIPT:-${ROOT}/print_windows_b07_closeout_3cmd.sh}"
  if [[ ! -x "${LThreeCmdScript}" ]]; then
    echo "[CLOSEOUT] Missing 3cmd helper: ${LThreeCmdScript}"
    return 2
  fi

  "${LThreeCmdScript}" "$@"
}

run_freeze_status() {
  local LFreezeScript
  local LJsonPath

  LFreezeScript="${FREEZE_STATUS_SCRIPT:-${ROOT}/evaluate_simd_freeze_status.py}"
  if [[ ! -f "${LFreezeScript}" ]]; then
    echo "[FREEZE] Missing status script: ${LFreezeScript}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[FREEZE] Missing python3"
    return 2
  fi

  LJsonPath="${SIMD_FREEZE_STATUS_JSON_FILE:-${ROOT}/logs/freeze_status.json}"
  python3 "${LFreezeScript}" --root "${ROOT}" --json-file "${LJsonPath}" "$@"
}

run_windows_closeout_finalize() {
  local LFinalizeScript

  LFinalizeScript="${WIN_CLOSEOUT_FINALIZE_SCRIPT:-${ROOT}/run_windows_b07_closeout_finalize.sh}"
  if [[ ! -x "${LFinalizeScript}" ]]; then
    echo "[CLOSEOUT] Missing finalize helper: ${LFinalizeScript}"
    return 2
  fi

  "${LFinalizeScript}" "$@"
}

run_freeze_status_rehearsal() {
  local LRehearsalScript

  LRehearsalScript="${FREEZE_REHEARSAL_SCRIPT:-${ROOT}/rehearse_freeze_status.sh}"
  if [[ ! -x "${LRehearsalScript}" ]]; then
    echo "[FREEZE-REHEARSAL] Missing script: ${LRehearsalScript}"
    return 2
  fi

  "${LRehearsalScript}" "$@"
}

case "${ACTION}" in
  clean)
    echo "[CLEAN] Removing bin2/, lib2/, logs/"
    rm -rf "${ROOT}/bin2" "${ROOT}/lib2" "${ROOT}/logs"
    ;;
  build)
    build_project
    ;;
  check)
    build_project
    check_build_log
    check_windows_runner_parity
    check_cpuinfo_runner_parity
    if [[ "${SIMD_CHECK_WIRING_SYNC:-0}" != "0" ]]; then
      echo "[CHECK] Optional wiring-sync enabled"
      run_wiring_sync
    else
      echo "[CHECK] SKIP optional wiring-sync (set SIMD_CHECK_WIRING_SYNC=1 to enable)"
    fi
    if [[ "${SIMD_CHECK_EXPERIMENTAL:-1}" != "0" ]]; then
      echo "[CHECK] Experimental intrinsics isolation"
      run_intrinsics_experimental_status
    else
      echo "[CHECK] SKIP optional experimental isolation (set SIMD_CHECK_EXPERIMENTAL=1 to enable)"
    fi
    ;;
  debug)
    MODE="Debug"
    build_project
    run_tests "$@"
    check_heap_leaks
    ;;
  release)
    MODE="Release"
    build_project
    run_tests "$@"
    check_heap_leaks
    ;;
  test)
    build_project
    run_tests "$@"
    check_heap_leaks
    ;;
  test-concurrent-repeat)
    run_suite_repeat "TTestCase_SimdConcurrent" "${1:-${SIMD_CONCURRENT_REPEAT_ROUNDS:-10}}"
    ;;
  gate)
    run_gate
    ;;
  gate-strict)
    SIMD_GATE_INTERFACE_COMPLETENESS=1
    SIMD_GATE_ADAPTER_SYNC_PASCAL=1
    SIMD_GATE_ADAPTER_SYNC=1
    SIMD_GATE_PARITY_SUITES=1
    SIMD_GATE_WIRING_SYNC=1
    SIMD_WIRING_SYNC_STRICT_EXTRA=1
    SIMD_GATE_COVERAGE=1
    SIMD_COVERAGE_STRICT_EXTRA=1
    SIMD_COVERAGE_REQUIRE_AVX2=1
    SIMD_COVERAGE_REQUIRE_EXPERIMENTAL=1
    SIMD_GATE_PERF_SMOKE=1
    SIMD_GATE_EXPERIMENTAL=1
    SIMD_GATE_EXPERIMENTAL_TESTS=1
    SIMD_GATE_NONX86_IEEE754=1
    SIMD_GATE_QEMU_NONX86_EVIDENCE=0
    SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=1
    SIMD_GATE_CONCURRENT_REPEAT="${SIMD_GATE_CONCURRENT_REPEAT:-10}"
    run_gate
    ;;
  interface-completeness)
    run_interface_completeness
    ;;
  adapter-sync-pascal)
    build_project
    run_backend_adapter_sync_pascal
    ;;
  adapter-sync)
    run_backend_adapter_sync
    ;;
  parity-suites)
    build_project
    gate_step_cross_backend_parity
    ;;
  gate-summary)
    run_gate_summary
    ;;
  gate-summary-sample)
    run_gate_summary_sample "$@"
    ;;
  gate-summary-rehearsal)
    run_gate_summary_rehearsal "$@"
    ;;
  gate-summary-inject)
    run_gate_summary_inject "$@"
    ;;
  gate-summary-rollback)
    run_gate_summary_rollback "$@"
    ;;
  gate-summary-backups)
    run_gate_summary_backups "$@"
    ;;
  gate-summary-selfcheck)
    run_gate_summary_selfcheck
    ;;
  perf-smoke)
    run_perf_smoke
    ;;
  nonx86-ieee754)
    run_nonx86_ieee754
    ;;
  backend-bench)
    run_backend_bench "$@"
    ;;
  qemu-nonx86-evidence)
    run_qemu_multiarch nonx86-evidence "$@"
    ;;
  qemu-arch-matrix-evidence)
    run_qemu_multiarch arch-matrix-evidence "$@"
    ;;
  qemu-nonx86-experimental-asm)
    run_qemu_multiarch nonx86-experimental-asm "$@"
    ;;
  riscvv-opcode-lane)
    run_riscvv_opcode_lane "$@"
    ;;
  qemu-experimental-report)
    run_qemu_experimental_report "$@"
    ;;
  qemu-experimental-baseline-check)
    run_qemu_experimental_baseline_check "$@"
    ;;
  coverage)
    run_coverage
    ;;
  experimental-intrinsics)
    run_intrinsics_experimental_status
    ;;
  experimental-intrinsics-tests)
    run_experimental_intrinsics_tests
    ;;
  wiring-sync)
    run_wiring_sync
    ;;
  evidence-linux)
    run_evidence_linux "$@"
    ;;
  verify-win-evidence)
    verify_windows_evidence "$@"
    ;;
  finalize-win-evidence)
    finalize_windows_evidence "$@"
    ;;
  win-closeout-dryrun)
    run_windows_closeout_dryrun
    ;;
  win-closeout-snippets)
    windows_closeout_snippets "$@"
    ;;
  win-closeout-3cmd)
    print_windows_closeout_3cmd "$@"
    ;;
  freeze-status)
    run_freeze_status "$@"
    ;;
  freeze-status-linux)
    run_freeze_status --linux-only "$@"
    ;;
  win-closeout-finalize)
    run_windows_closeout_finalize "$@"
    ;;
  freeze-status-rehearsal)
    run_freeze_status_rehearsal "$@"
    ;;
  *)
    echo "Usage: $0 [clean|build|check|test|test-concurrent-repeat|debug|release|gate|gate-strict|interface-completeness|adapter-sync-pascal|adapter-sync|parity-suites|gate-summary|gate-summary-sample|gate-summary-rehearsal|gate-summary-inject|gate-summary-rollback|gate-summary-backups|gate-summary-selfcheck|perf-smoke|nonx86-ieee754|backend-bench|qemu-nonx86-evidence|qemu-arch-matrix-evidence|qemu-nonx86-experimental-asm|riscvv-opcode-lane|qemu-experimental-report|qemu-experimental-baseline-check|coverage|wiring-sync|experimental-intrinsics|experimental-intrinsics-tests|evidence-linux|verify-win-evidence|finalize-win-evidence|win-closeout-dryrun|win-closeout-snippets|win-closeout-3cmd|freeze-status|freeze-status-linux|win-closeout-finalize|freeze-status-rehearsal] [test-args...]"
    echo "QEMU env: SIMD_QEMU_BUILD_POLICY=always|if-missing|skip (default: if-missing)"
    exit 2
    ;;
esac
