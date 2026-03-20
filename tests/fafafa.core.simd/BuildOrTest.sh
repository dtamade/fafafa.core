#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${ROOT}}"
PROJ="${ROOT}/fafafa.core.simd.test.lpi"
FPC_BIN="${FPC_BIN:-fpc}"
TARGET_CPU="$(${FPC_BIN} -iTP 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
TARGET_OS="$(${FPC_BIN} -iTO 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
if [[ -z "${TARGET_CPU}" ]]; then
  TARGET_CPU="nativecpu"
fi
if [[ -z "${TARGET_OS}" ]]; then
  TARGET_OS="nativeos"
fi
UNIT_DIR="${OUTPUT_ROOT}/lib2/${TARGET_CPU}-${TARGET_OS}"
BIN_DIR="${OUTPUT_ROOT}/bin2"
BIN="${BIN_DIR}/fafafa.core.simd.test"
LOG_DIR="${OUTPUT_ROOT}/logs"
BUILD_LOG="${LOG_DIR}/build.txt"
TEST_LOG="${LOG_DIR}/test.txt"
COVERAGE_SCRIPT="${ROOT}/check_intrinsics_coverage.py"
INTERFACE_COMPLETENESS_SCRIPT="${ROOT}/check_interface_implementation_completeness.py"
DISPATCH_CONTRACT_SIGNATURE_SCRIPT="${ROOT}/check_dispatch_contract_signature.py"
PUBLIC_ABI_SIGNATURE_SCRIPT="${ROOT}/check_public_abi_signature.py"
PERF_SMOKE_CHECK_SCRIPT="${ROOT}/check_perf_smoke_log.py"
ADAPTER_SYNC_SCRIPT="${ROOT}/check_backend_adapter_sync.py"
REGISTER_INCLUDE_CHECK_SCRIPT="${ROOT}/check_backend_register_include_consistency.py"
SUITE_MANIFEST_CHECK_SCRIPT="${ROOT}/check_suite_manifest_sync.py"
EXPERIMENTAL_INTRINSICS_SCRIPT="${ROOT}/check_intrinsics_experimental_status.py"
WIRING_SYNC_SCRIPT="${ROOT}/check_nonx86_wiring_sync.py"
QEMU_EXPERIMENTAL_REPORT_SCRIPT="${ROOT}/report_qemu_experimental_blockers.py"
QEMU_EXPERIMENTAL_BASELINE_SCRIPT="${ROOT}/check_experimental_failure_baseline.py"
INTERFACE_COMPLETENESS_JSON_LOG="${LOG_DIR}/interface_completeness.json"
INTERFACE_COMPLETENESS_MD_LOG="${LOG_DIR}/interface_completeness.md"
DISPATCH_CONTRACT_SIGNATURE_LOG="${LOG_DIR}/dispatch_contract_signature.txt"
DISPATCH_CONTRACT_SIGNATURE_JSON_LOG="${LOG_DIR}/dispatch_contract_signature.json"
PUBLIC_ABI_SIGNATURE_LOG="${LOG_DIR}/public_abi_signature.txt"
PUBLIC_ABI_SIGNATURE_JSON_LOG="${LOG_DIR}/public_abi_signature.json"
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
WIN_EVIDENCE_PREFLIGHT_SCRIPT="${ROOT}/preflight_windows_b07_evidence_gh.sh"
PUBLICABI_RUNNER_SCRIPT="${ROOT}/../fafafa.core.simd.publicabi/BuildOrTest.sh"

mkdir -p "${BIN_DIR}" "${UNIT_DIR}" "${LOG_DIR}"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

LZ_Q=()
if [[ "${FAFAFA_BUILD_QUIET:-1}" != "0" ]]; then
  LZ_Q+=("--quiet")
fi

MODE="${FAFAFA_BUILD_MODE:-Release}"

is_msys_shell() {
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

to_windows_path() {
  local aPath
  local LDrive
  local LRest

  aPath="${1:-}"
  if [[ -z "${aPath}" ]]; then
    echo ""
    return 0
  fi

  if [[ "${aPath}" =~ ^/([a-zA-Z])/(.*)$ ]]; then
    LDrive="${BASH_REMATCH[1]}"
    LRest="${BASH_REMATCH[2]//\//\\}"
    LDrive="$(printf '%s' "${LDrive}" | tr '[:lower:]' '[:upper:]')"
    echo "${LDrive}:\\${LRest}"
    return 0
  fi

  if [[ "${aPath}" =~ ^[a-zA-Z]:[\\/].* ]]; then
    echo "${aPath//\//\\}"
    return 0
  fi

  echo "${aPath}"
}

detect_lazarusdir() {
  local LLazbuildPath
  local LMaybeRoot
  local LCandidate

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
  LLazbuildPath="$(command -v "${LAZBUILD_BIN}" 2>/dev/null || true)"
  if [[ -n "${LLazbuildPath}" ]]; then
    LLazbuildPath="$(readlink -f "${LLazbuildPath}" 2>/dev/null || echo "${LLazbuildPath}")"
    LMaybeRoot="$(cd "$(dirname "${LLazbuildPath}")" && pwd)"
    if [[ -d "${LMaybeRoot}/lcl" ]]; then
      echo "${LMaybeRoot}"
      return 0
    fi
  fi

  for LCandidate in /usr/lib/lazarus/* /usr/local/lib/lazarus/*; do
    if [[ -d "${LCandidate}/lcl" ]]; then
      echo "${LCandidate}"
      return 0
    fi
  done

  echo ""
  return 0
}

build_project() {
  local LLazarusDir
  local -a LLazbuildArgs
  LLazarusDir="$(detect_lazarusdir)"

  echo "[BUILD] Project: ${PROJ} (mode=${MODE}, output_root=${OUTPUT_ROOT})"
  : >"${BUILD_LOG}"
  mkdir -p "${BIN_DIR}" "${UNIT_DIR}" "${LOG_DIR}"
  LLazbuildArgs=("${LZ_Q[@]}")
  if [[ -n "${LLazarusDir}" ]]; then
    LLazbuildArgs=("--lazarusdir=${LLazarusDir}" "${LLazbuildArgs[@]}")
  fi
  LLazbuildArgs+=("--build-mode=${MODE}" "--build-all")

  if "${LAZBUILD_BIN}" --help 2>&1 | grep -q -- '--opt'; then
    if is_msys_shell; then
      LLazbuildArgs+=(
        "--opt=-FE$(to_windows_path "${BIN_DIR}")"
        "--opt=-FU$(to_windows_path "${UNIT_DIR}")"
      )
    else
      LLazbuildArgs+=("--opt=-FE${BIN_DIR}" "--opt=-FU${UNIT_DIR}")
    fi
    if [[ "${SIMD_ENABLE_NEON_BACKEND:-0}" == "1" ]]; then
      LLazbuildArgs+=("--opt=-dSIMD_BACKEND_NEON")
      LLazbuildArgs+=("--opt=-dFAFAFA_SIMD_TEST_REGISTER_NEON_BACKEND")
    fi
    if [[ "${SIMD_ENABLE_RISCVV_BACKEND:-0}" == "1" ]]; then
      LLazbuildArgs+=(
        "--opt=-dSIMD_RISCV_AVAILABLE"
        "--opt=-dSIMD_EXPERIMENTAL_RISCVV"
        "--opt=-dSIMD_BACKEND_RISCVV"
        "--opt=-dFAFAFA_SIMD_TEST_REGISTER_RISCVV_BACKEND"
      )
    fi
    if [[ "${SIMD_ENABLE_AVX512_BACKEND:-0}" == "1" ]]; then
      LLazbuildArgs+=("--opt=-dSIMD_BACKEND_AVX512")
    fi
  elif [[ "${OUTPUT_ROOT}" != "${ROOT}" ]]; then
    echo "[BUILD] WARN: lazbuild without --opt support; fallback to project-local bin2/lib2 layout" | tee -a "${BUILD_LOG}"
  fi

  if [[ -n "${LLazarusDir}" ]]; then
    if "${LAZBUILD_BIN}" "${LLazbuildArgs[@]}" "${PROJ}" >"${BUILD_LOG}" 2>&1; then
      normalize_built_binary
      echo "[BUILD] OK"
    else
      local rc=$?
      echo "[BUILD] FAILED rc=${rc} (see ${BUILD_LOG})"
      return "${rc}"
    fi
    return 0
  fi

  if "${LAZBUILD_BIN}" "${LLazbuildArgs[@]}" "${PROJ}" >"${BUILD_LOG}" 2>&1; then
    normalize_built_binary
    echo "[BUILD] OK"
  else
    local rc=$?
    echo "[BUILD] FAILED rc=${rc} (see ${BUILD_LOG})"
    return "${rc}"
  fi
}

resolve_binary_from_build_log() {
  local LLine
  local LCandidate
  local LBase

  if [[ ! -f "${BUILD_LOG}" ]]; then
    return 1
  fi

  LLine="$(grep -E '\(9015\)[[:space:]]+Linking[[:space:]]+' "${BUILD_LOG}" | tail -n 1 || true)"
  if [[ -z "${LLine}" ]]; then
    return 1
  fi

  LCandidate="$(printf '%s\n' "${LLine}" | sed -E 's/.*\(9015\)[[:space:]]+Linking[[:space:]]+//')"
  LCandidate="$(printf '%s' "${LCandidate}" | tr -d '\r')"
  if [[ -z "${LCandidate}" ]]; then
    return 1
  fi

  if [[ "${LCandidate}" == /* && -f "${LCandidate}" ]]; then
    echo "${LCandidate}"
    return 0
  fi

  for LBase in "${ROOT}" "${OUTPUT_ROOT}" "${REPO_ROOT}" "$(pwd)"; do
    if [[ -f "${LBase}/${LCandidate}" ]]; then
      echo "${LBase}/${LCandidate}"
      return 0
    fi
  done

  return 1
}

normalize_built_binary() {
  local LResolved

  if [[ -f "${BIN}" || -f "${BIN}.exe" ]]; then
    return 0
  fi

  LResolved="$(resolve_binary_from_build_log)" || return 0
  if [[ -z "${LResolved}" || ! -f "${LResolved}" ]]; then
    return 0
  fi

  if [[ "${LResolved}" == "${BIN}" || "${LResolved}" == "${BIN}.exe" ]]; then
    return 0
  fi

  mkdir -p "${BIN_DIR}"
  cp "${LResolved}" "${BIN}"
  chmod +x "${BIN}" 2>/dev/null || true
  echo "[BUILD] Binary normalized: ${LResolved} -> ${BIN}"
}

check_build_log() {
  local LPattern
  local LIgnorePattern

  # Module acceptance criteria: no warnings/hints emitted from the stable SIMD module units under src/.
  LPattern='(^|.*/)src/fafafa\.core\.simd\..*(Warning:|Hint:)'
  LIgnorePattern='(^|.*/)src/fafafa\.core\.simd\.intrinsics\.avx2\.pas\('

  if grep -nE "${LPattern}" "${BUILD_LOG}" | grep -vE "${LIgnorePattern}" >/dev/null; then
    echo "[CHECK] Found warnings/hints from stable SIMD units in build log:"
    grep -nE "${LPattern}" "${BUILD_LOG}" | grep -vE "${LIgnorePattern}" || true
    return 1
  fi

  if grep -nE "${LPattern}" "${BUILD_LOG}" | grep -E "${LIgnorePattern}" >/dev/null; then
    echo "[CHECK] Ignoring experimental intrinsics hints from src/fafafa.core.simd.intrinsics.avx2.pas"
  fi

  echo "[CHECK] OK (no SIMD-unit warnings/hints on stable path)"
}

run_tests() {
  local LBinPath

  resolve_test_binary() {
    local LCandidate

    for LCandidate in \
      "${BIN}" \
      "${BIN}.exe" \
      "${ROOT}/bin2/fafafa.core.simd.test" \
      "${ROOT}/bin2/fafafa.core.simd.test.exe" \
      "${REPO_ROOT}/bin2/fafafa.core.simd.test" \
      "${REPO_ROOT}/bin2/fafafa.core.simd.test.exe" \
      "${OUTPUT_ROOT}/bin2/bin2/fafafa.core.simd.test" \
      "${OUTPUT_ROOT}/bin2/bin2/fafafa.core.simd.test.exe"; do
      if [[ -f "${LCandidate}" ]]; then
        chmod +x "${LCandidate}" 2>/dev/null || true
        echo "${LCandidate}"
        return 0
      fi
    done

    while IFS= read -r LCandidate; do
      if [[ -n "${LCandidate}" && -f "${LCandidate}" ]]; then
        chmod +x "${LCandidate}" 2>/dev/null || true
        echo "${LCandidate}"
        return 0
      fi
    done < <(
      find "${OUTPUT_ROOT}" "${ROOT}" "${REPO_ROOT}" -maxdepth 4 -type f \
        \( -name 'fafafa.core.simd.test' -o -name 'fafafa.core.simd.test.exe' -o -name 'fafafa.core.simd.test.*' \) \
        ! -name '*.lpi' \
        ! -name '*.lpr' \
        ! -name '*.pas' \
        ! -name '*.ppu' \
        ! -name '*.o' \
        ! -name '*.compiled' \
        ! -name '*.res' \
        ! -name '*.rsj' \
        2>/dev/null | sort -u
    )

    return 1
  }

  LBinPath="$(resolve_test_binary)" || {
    echo "[TEST] Missing binary: ${BIN} (did build succeed?)"
    echo "[TEST] Build log tail:"
    tail -n 40 "${BUILD_LOG}" || true
    echo "[TEST] Bin dirs:"
    ls -la "${BIN_DIR}" 2>/dev/null || true
    ls -la "${REPO_ROOT}/bin2" 2>/dev/null || true
    echo "[TEST] Candidate files:"
    find "${OUTPUT_ROOT}" "${ROOT}" "${REPO_ROOT}" -maxdepth 4 -type f \
      \( -name 'fafafa.core.simd.test' -o -name 'fafafa.core.simd.test.exe' -o -name 'fafafa.core.simd.test.*' \) \
      ! -name '*.lpi' \
      ! -name '*.lpr' \
      ! -name '*.pas' \
      ! -name '*.ppu' \
      ! -name '*.o' \
      ! -name '*.compiled' \
      ! -name '*.res' \
      ! -name '*.rsj' \
      2>/dev/null | sort -u || true
    return 2
  }

  if [[ "${LBinPath}" != "${BIN}" ]]; then
    echo "[TEST] Resolved binary fallback: ${LBinPath}"
  fi

  echo "[TEST] Running: ${LBinPath} $*"
  : >"${TEST_LOG}"

  if "${LBinPath}" "$@" >"${TEST_LOG}" 2>&1; then
    :
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

  if grep -nE '^[[:space:]]*Number of failures:[[:space:]]*[1-9][0-9]*|^[[:space:]]*Number of errors:[[:space:]]*[1-9][0-9]*|Time:[^[:cntrl:]]*[[:space:]]E:[1-9][0-9]*|Time:[^[:cntrl:]]*[[:space:]]F:[1-9][0-9]*' "${TEST_LOG}" >/dev/null; then
    echo "[TEST] FAILED: test runner reports failures/errors (see ${TEST_LOG})"
    grep -nE '^[[:space:]]*Number of failures:[[:space:]]*[0-9]+|^[[:space:]]*Number of errors:[[:space:]]*[0-9]+|Time:[^[:cntrl:]]*[[:space:]]E:[0-9]+|Time:[^[:cntrl:]]*[[:space:]]F:[0-9]+' "${TEST_LOG}" || true
    return 1
  fi

  echo "[TEST] OK"
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

cpuinfo_output_root() {
  local aTestsRoot
  aTestsRoot="${1}"
  if [[ "${OUTPUT_ROOT}" == "${ROOT}" ]]; then
    echo "${aTestsRoot}/fafafa.core.simd.cpuinfo"
  else
    echo "${OUTPUT_ROOT}/cpuinfo"
  fi
}

cpuinfo_x86_output_root() {
  local aTestsRoot
  aTestsRoot="${1}"
  if [[ "${OUTPUT_ROOT}" == "${ROOT}" ]]; then
    echo "${aTestsRoot}/fafafa.core.simd.cpuinfo.x86"
  else
    echo "${OUTPUT_ROOT}/cpuinfo.x86"
  fi
}

publicabi_output_root() {
  local aTestsRoot
  aTestsRoot="${1}"
  if [[ "${OUTPUT_ROOT}" == "${ROOT}" ]]; then
    echo "${aTestsRoot}/fafafa.core.simd.publicabi"
  else
    echo "${OUTPUT_ROOT}/publicabi"
  fi
}

experimental_intrinsics_output_root() {
  local aTestsRoot
  aTestsRoot="${1}"
  if [[ "${OUTPUT_ROOT}" == "${ROOT}" ]]; then
    echo "${aTestsRoot}/fafafa.core.simd.intrinsics.experimental"
  else
    echo "${OUTPUT_ROOT}/intrinsics.experimental"
  fi
}

nonx86_optin_output_root() {
  local aBackend
  aBackend="${1}"
  if [[ "${OUTPUT_ROOT}" == "${ROOT}" ]]; then
    echo "${ROOT}/nonx86.optin/${aBackend}"
  else
    echo "${OUTPUT_ROOT}/nonx86.optin/${aBackend}"
  fi
}

run_clean() {
  local -a LPaths

  LPaths=("${BIN_DIR}" "${OUTPUT_ROOT}/lib2" "${LOG_DIR}" "${OUTPUT_ROOT}/nonx86.optin")
  if [[ "${OUTPUT_ROOT}" != "${ROOT}" ]]; then
    LPaths+=(
      "${OUTPUT_ROOT}/bin"
      "${OUTPUT_ROOT}/lib"
      "${OUTPUT_ROOT}/cpuinfo"
      "${OUTPUT_ROOT}/cpuinfo.x86"
      "${OUTPUT_ROOT}/intrinsics.experimental"
      "${OUTPUT_ROOT}/publicabi"
      "${OUTPUT_ROOT}/run_all"
    )
  fi

  echo "[CLEAN] Removing ${LPaths[*]}"
  rm -rf "${LPaths[@]}"
}

run_cpuinfo_lazy_repeat() {
  local aTestsRoot
  local aRounds
  local LRound
  local LCpuinfoRunner
  local LCpuinfoLogDir
  local LCpuinfoSuiteLog
  local LCpuinfoTargetCPU
  local LCpuinfoTargetOS
  local LCpuinfoTargetLog
  local LPerRunLog

  aTestsRoot="${1:-}"
  aRounds="${2:-5}"

  if [[ -z "${aTestsRoot}" ]]; then
    echo "[CPUINFO-LAZY] Missing tests root"
    return 2
  fi

  if ! [[ "${aRounds}" =~ ^[1-9][0-9]*$ ]]; then
    echo "[CPUINFO-LAZY] Invalid rounds: ${aRounds} (expect positive integer)"
    return 2
  fi

  local LCpuinfoOutputRoot
  LCpuinfoOutputRoot="$(cpuinfo_output_root "${aTestsRoot}")"
  LCpuinfoRunner="${aTestsRoot}/fafafa.core.simd.cpuinfo/BuildOrTest.sh"
  LCpuinfoLogDir="${LCpuinfoOutputRoot}/logs"
  LCpuinfoSuiteLog="${LCpuinfoLogDir}/test.txt"

  if [[ ! -x "${LCpuinfoRunner}" ]]; then
    echo "[CPUINFO-LAZY] Missing runner: ${LCpuinfoRunner}"
    return 2
  fi

  LCpuinfoTargetCPU="$(fpc -iTP 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  LCpuinfoTargetOS="$(fpc -iTO 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  if [[ -z "${LCpuinfoTargetCPU}" ]]; then
    LCpuinfoTargetCPU="unknowncpu"
  fi
  if [[ -z "${LCpuinfoTargetOS}" ]]; then
    LCpuinfoTargetOS="unknownos"
  fi
  LCpuinfoTargetLog="${LCpuinfoLogDir}/${LCpuinfoTargetCPU}-${LCpuinfoTargetOS}/test.txt"

  SIMD_OUTPUT_ROOT="${LCpuinfoOutputRoot}" bash "${LCpuinfoRunner}" test --list-suites || return $?
  if [[ -f "${LCpuinfoTargetLog}" ]]; then
    LCpuinfoSuiteLog="${LCpuinfoTargetLog}"
  fi
  if [[ ! -f "${LCpuinfoSuiteLog}" ]] || ! grep -q "TTestCase_LazyCPUInfo" "${LCpuinfoSuiteLog}"; then
    echo "[CPUINFO-LAZY] Missing suite TTestCase_LazyCPUInfo (see ${LCpuinfoSuiteLog})"
    return 2
  fi

  for ((LRound = 1; LRound <= aRounds; LRound++)); do
    echo "[CPUINFO-LAZY] ${LRound}/${aRounds} suite=TTestCase_LazyCPUInfo"
    SIMD_OUTPUT_ROOT="${LCpuinfoOutputRoot}" bash "${LCpuinfoRunner}" test --suite=TTestCase_LazyCPUInfo || return $?
    if [[ -f "${LCpuinfoTargetLog}" ]]; then
      LCpuinfoSuiteLog="${LCpuinfoTargetLog}"
    fi

    LPerRunLog="${LCpuinfoLogDir}/repeat.TTestCase_LazyCPUInfo.${LRound}.txt"
    cp "${LCpuinfoSuiteLog}" "${LPerRunLog}" || true
  done

  echo "[CPUINFO-LAZY] OK suite=TTestCase_LazyCPUInfo rounds=${aRounds}"
}

run_cpuinfo_lazy_repeat_action() {
  local LTestsRoot
  local LRounds

  LTestsRoot="$(cd "${ROOT}/.." && pwd)"
  LRounds="${1:-${SIMD_CPUINFO_LAZY_REPEAT_ROUNDS:-5}}"
  run_cpuinfo_lazy_repeat "${LTestsRoot}" "${LRounds}" || return $?
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

array_contains() {
  local aNeedle
  local LItem

  aNeedle="${1:-}"
  shift || true
  for LItem in "$@"; do
    if [[ "${LItem}" == "${aNeedle}" ]]; then
      return 0
    fi
  done

  return 1
}

collect_shell_runner_actions() {
  local aRunner

  aRunner="${1:-}"
  sed -n 's/^  \([a-z0-9-][a-z0-9-]*\))$/\1/p' "${aRunner}" | sort -u
}

collect_windows_runner_actions() {
  local aRunner

  aRunner="${1:-}"
  sed -n 's/^if \/I "%ACTION%"=="\([^"]\+\)".*/\1/p' "${aRunner}" | sort -u
}

check_windows_runner_parity() {
  local LBat
  local LShellRunner
  local LMissing
  local LPattern
  local LAction
  local -a LRequired
  local -a LShellActions
  local -a LBatActions
  local -a LAllowedShellOnly
  local -a LAllowedWindowsOnly

  LBat="${ROOT}/buildOrTest.bat"
  LShellRunner="${ROOT}/BuildOrTest.sh"
  LMissing=0

  if [[ ! -f "${LBat}" ]]; then
    echo "[CHECK] Missing Windows runner: ${LBat}"
    return 1
  fi
  if [[ ! -f "${LShellRunner}" ]]; then
    echo "[CHECK] Missing shell runner: ${LShellRunner}"
    return 1
  fi

  # These actions are intentionally shell-only because they orchestrate bash/Python/GitHub workflows
  # rather than native batch execution.
  LAllowedShellOnly=(
    evidence-linux
    freeze-status
    freeze-status-linux
    freeze-status-rehearsal
    gate-summary-selfcheck
    win-closeout-dryrun
    win-closeout-snippets
    win-evidence-via-gh
  )

  # These aliases are intentionally Windows-only entry points for native evidence capture.
  LAllowedWindowsOnly=(
    evidence-win
    evidence-win-verify
  )

  LRequired=(
    'if /I "%ACTION%"=="check" goto :check'
    'if /I "%ACTION%"=="test" goto :test'
    'if /I "%ACTION%"=="test-concurrent-repeat" goto :test_concurrent_repeat'
    'if /I "%ACTION%"=="cpuinfo-lazy-repeat" goto :cpuinfo_lazy_repeat'
    'if /I "%ACTION%"=="gate" goto :gate'
    'if /I "%ACTION%"=="gate-strict" goto :gate_strict'
    'if /I "%ACTION%"=="interface-completeness" goto :interface_completeness'
    'if /I "%ACTION%"=="contract-signature" goto :contract_signature'
    'if /I "%ACTION%"=="publicabi-signature" goto :publicabi_signature'
    'if /I "%ACTION%"=="publicabi-smoke" goto :publicabi_smoke'
    'if /I "%ACTION%"=="adapter-sync-pascal" goto :adapter_sync_pascal'
    'if /I "%ACTION%"=="adapter-sync" goto :adapter_sync'
    'if /I "%ACTION%"=="parity-suites" goto :parity_suites'
    'if /I "%ACTION%"=="perf-smoke" goto :perf_smoke'
    'if /I "%ACTION%"=="nonx86-optin-list-suites" goto :nonx86_optin_list_suites'
    'if /I "%ACTION%"=="nonx86-ieee754" goto :nonx86_ieee754'
    'if /I "%ACTION%"=="backend-bench" goto :backend_bench'
    'if /I "%ACTION%"=="qemu-nonx86-evidence" goto :qemu_nonx86_evidence'
    'if /I "%ACTION%"=="qemu-cpuinfo-nonx86-evidence" goto :qemu_cpuinfo_nonx86_evidence'
    'if /I "%ACTION%"=="qemu-cpuinfo-nonx86-full-evidence" goto :qemu_cpuinfo_nonx86_full_evidence'
    'if /I "%ACTION%"=="qemu-cpuinfo-nonx86-full-repeat" goto :qemu_cpuinfo_nonx86_full_repeat'
    'if /I "%ACTION%"=="qemu-cpuinfo-nonx86-suite-repeat" goto :qemu_cpuinfo_nonx86_suite_repeat'
    'if /I "%ACTION%"=="qemu-arch-matrix-evidence" goto :qemu_arch_matrix_evidence'
    'if /I "%ACTION%"=="qemu-nonx86-experimental-asm" goto :qemu_nonx86_experimental_asm'
    'if /I "%ACTION%"=="qemu-experimental-report" goto :qemu_experimental_report'
    'if /I "%ACTION%"=="qemu-experimental-baseline-check" goto :qemu_experimental_baseline_check'
    'if /I "%ACTION%"=="evidence-win" goto :evidence_win'
    'if /I "%ACTION%"=="win-evidence-preflight" goto :win_evidence_preflight'
    'if /I "%ACTION%"=="verify-win-evidence" ('
    'if /I "%ACTION%"=="evidence-win-verify" ('
    'if /I "%ACTION%"=="finalize-win-evidence" goto :finalize_win_evidence'
    'if /I "%ACTION%"=="win-closeout-3cmd" goto :win_closeout_3cmd'
    'if /I "%ACTION%"=="win-closeout-finalize" goto :win_closeout_finalize'
    'set "NORMALIZED_TEST_ARGS=!NORMALIZED_TEST_ARGS! %1"'
    'if /I "%ACTION%"=="wiring-sync" goto :wiring_sync'
    'if /I "%ACTION%"=="gate-summary" goto :gate_summary'
    'if /I "%ACTION%"=="gate-summary-sample" goto :gate_summary_sample'
    'if /I "%ACTION%"=="gate-summary-rehearsal" goto :gate_summary_rehearsal'
    'if /I "%ACTION%"=="gate-summary-inject" goto :gate_summary_inject'
    'if /I "%ACTION%"=="gate-summary-rollback" goto :gate_summary_rollback'
    'if /I "%ACTION%"=="gate-summary-backups" goto :gate_summary_backups'
    'echo Usage: %~nx0 [clean^|build^|check^|test^|test-concurrent-repeat^|cpuinfo-lazy-repeat^|debug^|release^|gate^|gate-strict^|interface-completeness^|contract-signature^|publicabi-signature^|publicabi-smoke^|adapter-sync-pascal^|adapter-sync^|parity-suites^|gate-summary^|gate-summary-sample^|gate-summary-rehearsal^|gate-summary-inject^|gate-summary-rollback^|gate-summary-backups^|perf-smoke^|nonx86-optin-list-suites^|nonx86-ieee754^|backend-bench^|qemu-nonx86-evidence^|qemu-cpuinfo-nonx86-evidence^|qemu-cpuinfo-nonx86-full-evidence^|qemu-cpuinfo-nonx86-full-repeat^|qemu-cpuinfo-nonx86-suite-repeat^|qemu-arch-matrix-evidence^|qemu-nonx86-experimental-asm^|qemu-experimental-report^|qemu-experimental-baseline-check^|coverage^|wiring-sync^|experimental-intrinsics^|experimental-intrinsics-tests^|evidence-win^|win-evidence-preflight^|verify-win-evidence^|evidence-win-verify^|finalize-win-evidence^|win-closeout-3cmd^|win-closeout-finalize] [test-args...]'
    'findstr /r /c:"src\fafafa\.core\.simd\..*Warning:" /c:"src\fafafa\.core\.simd\..*Hint:" "%BUILD_LOG%" | findstr /v /c:"src\fafafa.core.simd.intrinsics.avx2.pas" >nul 2>nul'
    'call :register_include_check'
    ':register_include_check'
    'set "REGISTER_INCLUDE_SCRIPT=%ROOT%check_backend_register_include_consistency.py"'
    'echo [REGISTER-INCLUDE] FAILED (python runtime not found; tried py and python)'
    'findstr /b /c:"Invalid option" "%TEST_LOG%" >nul 2>nul'
    'findstr /r /c:"Number of failures:[ ]*[1-9][0-9]*" /c:"Number of errors:[ ]*[1-9][0-9]*" /c:"Time:.* E:[1-9][0-9]*" /c:"Time:.* F:[1-9][0-9]*" "%TEST_LOG%" >nul 2>nul'
    'findstr /r /c:"^[1-9][0-9]* unfreed memory blocks" "%TEST_LOG%" >nul 2>nul'
    'call "%SELF%" check'
    'call "%ROOT%buildOrTest.bat" nonx86-optin-list-suites'
    'if /I "%SIMD_CHECK_WIRING_SYNC%"=="1" ('
    'call "%SELF%" wiring-sync'
    'call "%SELF%" test --list-suites'
    'call "%SELF%" test --suite=TTestCase_VecI32x8'
    'if errorlevel 1 exit /b 1'
    'call "%SELF%" test --suite=TTestCase_VecU32x8'
    'if errorlevel 1 exit /b 1'
    'call "%SELF%" test --suite=TTestCase_VecF64x4'
    'if /I "%SIMD_GATE_NONX86_IEEE754%"=="0" ('
    'echo [GATE] SKIP optional non-x86 IEEE754 suite ^(set SIMD_GATE_NONX86_IEEE754=1 to enable^)'
    'call "%SELF%" nonx86-ieee754'
    'call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo\buildOrTest.bat" test --list-suites'
    'call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo\buildOrTest.bat" test --suite=TTestCase_PlatformSpecific'
    'if /I "%SIMD_GATE_CPUINFO_LAZY_REPEAT%"=="0" ('
    'echo [GATE] SKIP optional cpuinfo lazy repeat ^(set SIMD_GATE_CPUINFO_LAZY_REPEAT=5 to enable^)'
    'call "%SELF%" cpuinfo-lazy-repeat %SIMD_GATE_CPUINFO_LAZY_REPEAT%'
    'call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat" test --list-suites'
    'call "%TESTS_ROOT%\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat" test --suite=TTestCase_Global'
    'set "RUN_ACTION=check"'
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
    'if /I "%SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE%"=="1" ('
    'echo [GATE] SKIP optional qemu cpuinfo non-x86 evidence ^(set SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 to enable^)'
    'call "%SELF%" qemu-cpuinfo-nonx86-evidence'
    'if /I "%SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE%"=="1" ('
    'echo [GATE] SKIP optional qemu cpuinfo non-x86 full evidence ^(set SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=1 to enable^)'
    'call "%SELF%" qemu-cpuinfo-nonx86-full-evidence'
    'if /I "%SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT%"=="1" ('
    'echo [GATE] SKIP optional qemu cpuinfo non-x86 full repeat ^(set SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=1 to enable^)'
    'call "%SELF%" qemu-cpuinfo-nonx86-full-repeat'
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
    'if "%SIMD_GATE_PERF_SMOKE%"=="" set "SIMD_GATE_PERF_SMOKE=0"'
    'set "SIMD_GATE_NONX86_IEEE754=1"'
    'if "%SIMD_GATE_CPUINFO_LAZY_REPEAT%"=="" set "SIMD_GATE_CPUINFO_LAZY_REPEAT=3"'
    'set "SIMD_GATE_QEMU_NONX86_EVIDENCE=0"'
    'if "%SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE%"=="" set "SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1"'
    'if "%SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE%"=="" set "SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0"'
    'if "%SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT%"=="" set "SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0"'
    'if "%SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE%"=="" set "SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0"'
    'if "%SIMD_QEMU_CPUINFO_REPEAT_ROUNDS%"=="" set "SIMD_QEMU_CPUINFO_REPEAT_ROUNDS=1"'
    'set "SIMD_GATE_INTERFACE_COMPLETENESS=1"'
    'set "SIMD_GATE_CONTRACT_SIGNATURE=1"'
    'set "SIMD_GATE_PUBLICABI_SIGNATURE=1"'
    'set "SIMD_GATE_PUBLICABI_SMOKE=1"'
    'set "SIMD_GATE_ADAPTER_SYNC_PASCAL=1"'
    'set "SIMD_GATE_ADAPTER_SYNC=1"'
    'set "SIMD_GATE_PARITY_SUITES=1"'
    'call "%ROOT%buildOrTest.bat" gate'
    'echo [GATE] Optional interface completeness check'
    'call "%SELF%" interface-completeness'
    'echo [GATE] Optional dispatch contract signature'
    'call "%SELF%" contract-signature'
    'echo [GATE] Optional public ABI signature'
    'call "%SELF%" publicabi-signature'
    'echo [GATE] Optional public ABI smoke'
    'call "%SELF%" publicabi-smoke'
    'if "%SIMD_GATE_PUBLICABI_SIGNATURE%"=="" set "SIMD_GATE_PUBLICABI_SIGNATURE=1"'
    'if "%SIMD_GATE_PUBLICABI_SMOKE%"=="" set "SIMD_GATE_PUBLICABI_SMOKE=1"'
    'echo [GATE] Optional backend adapter sync Pascal smoke'
    'call "%SELF%" adapter-sync-pascal'
    'echo [GATE] Optional backend adapter sync'
    'set "SIMD_ADAPTER_SYNC_PASCAL_SMOKE=0"'
    'call "%SELF%" adapter-sync'
    'echo [GATE] Optional cross-backend parity suites'
    'call "%SELF%" test --suite=TTestCase_DispatchAPI'
    'call "%SELF%" test --suite=TTestCase_DirectDispatch'
    'set "BENCH_SCRIPT=%ROOT%run_backend_benchmarks.sh"'
    ':require_backend_bench_bash_runtime'
    'echo [BENCH] FAILED ^(bash runtime not found; backend-bench requires bash to preserve shell parity^)'
    'call :require_backend_bench_bash_runtime'
    ':require_qemu_bash_runtime'
    'set "QEMU_SCRIPT=%ROOT%docker\run_multiarch_qemu.sh"'
    'echo [QEMU] FAILED ^(bash runtime not found; qemu multiarch actions require bash to preserve shell parity^)'
    'call :require_qemu_bash_runtime'
    'bash "%QEMU_SCRIPT%" nonx86-evidence %NORMALIZED_TEST_ARGS%'
    'bash "%QEMU_SCRIPT%" cpuinfo-nonx86-evidence %NORMALIZED_TEST_ARGS%'
    'bash "%QEMU_SCRIPT%" cpuinfo-nonx86-full-evidence %NORMALIZED_TEST_ARGS%'
    'bash "%QEMU_SCRIPT%" cpuinfo-nonx86-full-repeat %NORMALIZED_TEST_ARGS%'
    'bash "%QEMU_SCRIPT%" arch-matrix-evidence %NORMALIZED_TEST_ARGS%'
    'bash "%QEMU_SCRIPT%" nonx86-experimental-asm %NORMALIZED_TEST_ARGS%'
    'set "QEMU_EXP_REPORT_SCRIPT=%ROOT%report_qemu_experimental_blockers.py"'
    'py -3 "%QEMU_EXP_REPORT_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%'
    'python "%QEMU_EXP_REPORT_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%'
    'set "QEMU_EXP_BASELINE_SCRIPT=%ROOT%check_experimental_failure_baseline.py"'
    'py -3 "%QEMU_EXP_BASELINE_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%'
    'python "%QEMU_EXP_BASELINE_SCRIPT%" --latest %NORMALIZED_TEST_ARGS%'
    'set "RVV_LANE_SCRIPT=%ROOT%docker\run_riscvv_opcode_lane.sh"'
    ':require_rvv_lane_bash_runtime'
    'echo [RVV-LANE] FAILED ^(bash runtime not found; riscvv-opcode-lane requires bash to preserve shell parity^)'
    'call :require_rvv_lane_bash_runtime'
    'bash "%RVV_LANE_SCRIPT%" %NORMALIZED_TEST_ARGS%'
    'set "EVIDENCE_SCRIPT=%ROOT%collect_windows_b07_evidence.bat"'
    'set "VERIFY_SCRIPT=%ROOT%verify_windows_b07_evidence.bat"'
    'call "%EVIDENCE_SCRIPT%"'
    'if "%VERIFY_ARGS%"=="" ('
    'call "%VERIFY_SCRIPT%" "%ROOT%logs\windows_b07_gate.log"'
    'call "%VERIFY_SCRIPT%" %VERIFY_ARGS%'
    'echo [GATE-SUMMARY] %SUMMARY_FILE%'
    'echo [GATE-SUMMARY] thresholds: warn_ms=%SIMD_GATE_STEP_WARN_MS%, fail_ms=%SIMD_GATE_STEP_FAIL_MS%'
    'set "SUMMARY_FILTER=%SIMD_GATE_SUMMARY_FILTER%"'
    'echo [GATE-SUMMARY] filter=%SUMMARY_FILTER%, max_detail=%SIMD_GATE_SUMMARY_MAX_DETAIL%'
    'findstr /r /c:"^| Time |" /c:"^|---|" /c:"| FAIL |" "%SUMMARY_FILE%"'
    'findstr /r /c:"^| Time |" /c:"^|---|" /c:"| SLOW_WARN |" /c:"| SLOW_CRIT |" /c:"| SLOW_FAIL |" "%SUMMARY_FILE%"'
    'set "EXPORT_SCRIPT=%ROOT%export_gate_summary_json.py"'
    'echo [GATE-SUMMARY] json=%SUMMARY_JSON_FILE%'
    'set "SAMPLE_SCRIPT=%ROOT%generate_gate_summary_sample.py"'
    'set "REHEARSAL_SCRIPT=%ROOT%rehearse_gate_summary_thresholds.sh"'
    'echo [GATE-SUMMARY-SAMPLE] output=%SAMPLE_OUTPUT%'
    'echo [GATE-SUMMARY-SAMPLE] FAILED ^(python runtime not found; gate-summary-sample requires python^)'
    'echo [GATE-SUMMARY-REHEARSAL] FAILED ^(bash runtime not found; gate-summary-rehearsal requires bash^)'
    'if /I "%SIMD_GATE_SUMMARY_APPLY%"=="1" ('
    'echo [GATE-SUMMARY-INJECT] sample=%SAMPLE_OUTPUT%'
    'echo [GATE-SUMMARY-INJECT] FAILED ^(python runtime not found; gate-summary-inject requires python^)'
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

  mapfile -t LShellActions < <(collect_shell_runner_actions "${LShellRunner}")
  mapfile -t LBatActions < <(collect_windows_runner_actions "${LBat}")

  for LAction in "${LShellActions[@]}"; do
    if ! array_contains "${LAction}" "${LBatActions[@]}" && \
       ! array_contains "${LAction}" "${LAllowedShellOnly[@]}"; then
      echo "[CHECK] Windows runner missing action without allowlist: ${LAction}"
      LMissing=1
    fi
  done

  for LAction in "${LBatActions[@]}"; do
    if ! array_contains "${LAction}" "${LShellActions[@]}" && \
       ! array_contains "${LAction}" "${LAllowedWindowsOnly[@]}"; then
      echo "[CHECK] Windows runner has unexpected Windows-only action: ${LAction}"
      LMissing=1
    fi
  done

  for LAction in "${LAllowedShellOnly[@]}"; do
    if ! array_contains "${LAction}" "${LShellActions[@]}"; then
      echo "[CHECK] Stale shell-only allowlist entry: ${LAction}"
      LMissing=1
    fi
  done

  for LAction in "${LAllowedWindowsOnly[@]}"; do
    if ! array_contains "${LAction}" "${LBatActions[@]}"; then
      echo "[CHECK] Stale Windows-only allowlist entry: ${LAction}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (windows runner parity signatures present)"
}

check_avx512_optin_runner_guard() {
  local LShellRunner
  local LBatRunner
  local LMissing
  local LPattern
  local -a LShellRequired
  local -a LBatRequired

  LShellRunner="${ROOT}/BuildOrTest.sh"
  LBatRunner="${ROOT}/buildOrTest.bat"
  LMissing=0

  if [[ ! -f "${LShellRunner}" ]]; then
    echo "[CHECK] Missing shell runner: ${LShellRunner}"
    return 1
  fi
  if [[ ! -f "${LBatRunner}" ]]; then
    echo "[CHECK] Missing Windows runner: ${LBatRunner}"
    return 1
  fi

  LShellRequired=(
    'if [[ "${SIMD_ENABLE_AVX512_BACKEND:-0}" == "1" ]]; then'
    'LLazbuildArgs+=("--opt=-dSIMD_BACKEND_AVX512")'
    'echo "Build env: SIMD_ENABLE_AVX512_BACKEND=1 (compile AVX-512 backend into the test binary for opt-in verification)"'
  )
  LBatRequired=(
    'if /I "%SIMD_ENABLE_AVX512_BACKEND%"=="1" set "LAZBUILD_EXTRA_OPTS=%LAZBUILD_EXTRA_OPTS% --opt=-dSIMD_BACKEND_AVX512"'
    'echo Build env: SIMD_ENABLE_AVX512_BACKEND=1 ^(compile AVX-512 backend into the test binary for opt-in verification^)'
  )

  for LPattern in "${LShellRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LShellRunner}" >/dev/null; then
      echo "[CHECK] Shell runner missing AVX512 opt-in pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBatRunner}" >/dev/null; then
      echo "[CHECK] Windows runner missing AVX512 opt-in pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (AVX512 opt-in runner guard present)"
}

check_nonx86_optin_runner_guard() {
  local LShellRunner
  local LBatRunner
  local LMissing
  local LPattern
  local -a LShellRequired
  local -a LBatRequired

  LShellRunner="${ROOT}/BuildOrTest.sh"
  LBatRunner="${ROOT}/buildOrTest.bat"
  LMissing=0

  if [[ ! -f "${LShellRunner}" ]]; then
    echo "[CHECK] Missing shell runner: ${LShellRunner}"
    return 1
  fi
  if [[ ! -f "${LBatRunner}" ]]; then
    echo "[CHECK] Missing Windows runner: ${LBatRunner}"
    return 1
  fi

  LShellRequired=(
    'if [[ "${SIMD_ENABLE_NEON_BACKEND:-0}" == "1" ]]; then'
    'LLazbuildArgs+=("--opt=-dSIMD_BACKEND_NEON")'
    'LLazbuildArgs+=("--opt=-dFAFAFA_SIMD_TEST_REGISTER_NEON_BACKEND")'
    'if [[ "${SIMD_ENABLE_RISCVV_BACKEND:-0}" == "1" ]]; then'
    '"--opt=-dSIMD_RISCV_AVAILABLE"'
    '"--opt=-dSIMD_EXPERIMENTAL_RISCVV"'
    '"--opt=-dSIMD_BACKEND_RISCVV"'
    '"--opt=-dFAFAFA_SIMD_TEST_REGISTER_RISCVV_BACKEND"'
    'echo "Build env: SIMD_ENABLE_NEON_BACKEND=1 (compile NEON backend into the test binary for opt-in verification/fallback coverage)"'
    'echo "Build env: SIMD_ENABLE_RISCVV_BACKEND=1 (compile RISCV-V backend into the test binary for opt-in verification/fallback coverage)"'
    'env "${aEnvVar}=1" SIMD_OUTPUT_ROOT="${LOutputRoot}" bash "${ROOT}/BuildOrTest.sh" test --list-suites || return $?'
    'run_nonx86_optin_list_suites || return $?'
  )
  LBatRequired=(
    'if /I "%SIMD_ENABLE_NEON_BACKEND%"=="1" set "LAZBUILD_EXTRA_OPTS=%LAZBUILD_EXTRA_OPTS% --opt=-dSIMD_BACKEND_NEON --opt=-dFAFAFA_SIMD_TEST_REGISTER_NEON_BACKEND"'
    'if /I "%SIMD_ENABLE_RISCVV_BACKEND%"=="1" set "LAZBUILD_EXTRA_OPTS=%LAZBUILD_EXTRA_OPTS% --opt=-dSIMD_RISCV_AVAILABLE --opt=-dSIMD_EXPERIMENTAL_RISCVV --opt=-dSIMD_BACKEND_RISCVV --opt=-dFAFAFA_SIMD_TEST_REGISTER_RISCVV_BACKEND"'
    'echo Build env: SIMD_ENABLE_NEON_BACKEND=1 ^(compile NEON backend into the test binary for opt-in verification/fallback coverage^)'
    'echo Build env: SIMD_ENABLE_RISCVV_BACKEND=1 ^(compile RISCV-V backend into the test binary for opt-in verification/fallback coverage^)'
    'if /I "%ACTION%"=="nonx86-optin-list-suites" goto :nonx86_optin_list_suites'
    'call "%ROOT%buildOrTest.bat" nonx86-optin-list-suites'
  )

  for LPattern in "${LShellRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LShellRunner}" >/dev/null; then
      echo "[CHECK] Shell runner missing non-x86 opt-in pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBatRunner}" >/dev/null; then
      echo "[CHECK] Windows runner missing non-x86 opt-in pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (non-x86 opt-in runner guard present)"
}

check_windows_publicabi_runner_guard() {
  local LBat
  local LMissing
  local LPattern
  local -a LRequired

  LBat="${ROOT}/../fafafa.core.simd.publicabi/BuildOrTest.bat"
  if [[ ! -f "${LBat}" ]]; then
    echo "[CHECK] Missing Windows public ABI runner: ${LBat}"
    return 1
  fi

  LMissing=0
  LRequired=(
    'set "POWERSHELL_EXE="'
    ':resolve_powershell'
    'where pwsh >nul 2>nul'
    'set "POWERSHELL_EXE=pwsh"'
    'where powershell >nul 2>nul'
    'set "POWERSHELL_EXE=powershell"'
    'echo [PUBLICABI] FAILED ^(PowerShell runtime not found; tried pwsh and powershell^)'
    '"!POWERSHELL_EXE!" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -LibraryPath "!LIB_PATH!" -ValidateOnly'
    '"!POWERSHELL_EXE!" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -LibraryPath "!LIB_PATH!" > "%TEST_LOG%" 2>&1'
  )

  for LPattern in "${LRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows public ABI runner missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if grep -F -- 'echo [PUBLICABI] SKIP ^(powershell not found^)' "${LBat}" >/dev/null; then
    echo "[CHECK] Windows public ABI runner still allows silent skip when PowerShell is missing"
    LMissing=1
  fi

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Windows public ABI runner guard present)"
}

check_windows_evidence_collector_guard() {
  local LCollector
  local LVerifyBat
  local LVerifySh
  local LMissing
  local LPattern
  local -a LCollectorRequired
  local -a LVerifyBatRequired
  local -a LVerifyShRequired
  local -a LForbidden

  LCollector="${ROOT}/collect_windows_b07_evidence.bat"
  LVerifyBat="${ROOT}/verify_windows_b07_evidence.bat"
  LVerifySh="${ROOT}/verify_windows_b07_evidence.sh"
  LMissing=0

  for LPattern in "${LCollector}" "${LVerifyBat}" "${LVerifySh}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing Windows evidence collector target: ${LPattern}"
      return 1
    fi
  done

  LCollectorRequired=(
    'echo [GATE] 1/7 Build + check SIMD module >> "%TMP_LOG%"'
    'echo [GATE] 5/7 CPUInfo x86 suites >> "%TMP_LOG%"'
    'echo [GATE] 6/7 Windows public ABI smoke >> "%TMP_LOG%"'
    'pushd "%TESTS_ROOT%\fafafa.core.simd.publicabi"'
    'call ".\BuildOrTest.bat" test >> "%TMP_LOG%" 2>&1'
    'echo [GATE] 7/7 Filtered run_all chain >> "%TMP_LOG%"'
  )

  LVerifyBatRequired=(
    'call :check_fixed "[GATE] 1/7 Build + check SIMD module"'
    'call :check_fixed "[GATE] 6/7 Windows public ABI smoke"'
    'call :check_fixed "[GATE] 7/7 Filtered run_all chain"'
  )

  LVerifyShRequired=(
    'check_fixed "[GATE] 1/7 Build + check SIMD module" || LFail=1'
    'check_fixed "[GATE] 6/7 Windows public ABI smoke" || LFail=1'
    'check_fixed "[GATE] 7/7 Filtered run_all chain" || LFail=1'
  )

  LForbidden=(
    '[GATE] 6/6 Filtered run_all chain'
    '[GATE] 5/6 CPUInfo x86 suites'
  )

  for LPattern in "${LCollectorRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LCollector}" >/dev/null; then
      echo "[CHECK] Windows evidence collector missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LVerifyBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LVerifyBat}" >/dev/null; then
      echo "[CHECK] Windows evidence batch verifier missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LVerifyShRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LVerifySh}" >/dev/null; then
      echo "[CHECK] Windows evidence shell verifier missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbidden[@]}"; do
    if grep -F -- "${LPattern}" "${LCollector}" >/dev/null || \
       grep -F -- "${LPattern}" "${LVerifyBat}" >/dev/null || \
       grep -F -- "${LPattern}" "${LVerifySh}" >/dev/null; then
      echo "[CHECK] Windows evidence collector still contains deprecated marker: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Windows evidence collector public ABI guard present)"
}

check_windows_simulated_evidence_guard() {
  local LSimulator
  local LRehearsal
  local LMissing
  local LPattern
  local -a LSimulatorRequired
  local -a LRehearsalRequired
  local -a LForbidden

  LSimulator="${ROOT}/simulate_windows_b07_evidence.sh"
  LRehearsal="${ROOT}/rehearse_freeze_status.sh"
  LMissing=0

  for LPattern in "${LSimulator}" "${LRehearsal}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing Windows simulated evidence target: ${LPattern}"
      return 1
    fi
  done

  LSimulatorRequired=(
    'SUMMARY_JSON_SENTINEL="${LOG_PATH%.log}.summary-json.missing"'
    '[B07] GateSummaryJson: ${SUMMARY_JSON_SENTINEL}'
    '[GATE] 1/7 Build + check SIMD module'
    '[GATE] 6/7 Windows public ABI smoke'
    '[GATE] 7/7 Filtered run_all chain'
  )

  LRehearsalRequired=(
    '[B07] GateSummaryJson: /tmp/rehearse.windows_b07_gate.simulated.summary-json.missing'
    '[B07] GateSummaryJson: /tmp/rehearse.windows_b07_gate.summary-json.missing'
    '[B07] GateSummaryJson: /tmp/rehearse.windows_b07_gate.source-fresh.summary-json.missing'
    '[GATE] 1/7 Build + check SIMD module'
    '[GATE] 6/7 Windows public ABI smoke'
    '[GATE] 7/7 Filtered run_all chain'
  )

  LForbidden=(
    '[GATE] 1/6 Build + check SIMD module'
    '[GATE] 6/6 Filtered run_all chain'
  )

  for LPattern in "${LSimulatorRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LSimulator}" >/dev/null; then
      echo "[CHECK] Windows simulated evidence helper missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LRehearsalRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LRehearsal}" >/dev/null; then
      echo "[CHECK] Windows freeze rehearsal missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbidden[@]}"; do
    if grep -F -- "${LPattern}" "${LSimulator}" >/dev/null; then
      echo "[CHECK] Windows simulated evidence helper still contains stale pattern: ${LPattern}"
      LMissing=1
    fi
    if grep -F -- "${LPattern}" "${LRehearsal}" >/dev/null; then
      echo "[CHECK] Windows freeze rehearsal still contains stale pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Windows simulated evidence guard present)"
}

check_windows_gate_summary_helper_guard() {
  local LBat
  local LMissing
  local LPattern
  local -a LRequired
  local -a LForbidden

  LBat="${ROOT}/buildOrTest.bat"
  if [[ ! -f "${LBat}" ]]; then
    echo "[CHECK] Missing Windows gate-summary helper runner: ${LBat}"
    return 1
  fi

  LMissing=0
  LRequired=(
    ':gate_summary_sample'
    'echo [GATE-SUMMARY-SAMPLE] FAILED ^(python runtime not found; gate-summary-sample requires python^)'
    ':gate_summary_rehearsal'
    'echo [GATE-SUMMARY-REHEARSAL] FAILED ^(bash runtime not found; gate-summary-rehearsal requires bash^)'
    ':gate_summary_inject'
    'echo [GATE-SUMMARY-INJECT] FAILED ^(python runtime not found; gate-summary-inject requires python^)'
    'goto :gate_summary_inject_apply'
  )

  LForbidden=(
    'echo [GATE-SUMMARY-SAMPLE] SKIP ^(python runtime not found^)'
    'echo [GATE-SUMMARY-REHEARSAL] SKIP ^(bash not found^)'
    'echo [GATE-SUMMARY-INJECT] SKIP ^(python runtime not found^)'
  )

  for LPattern in "${LRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows gate-summary helper missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbidden[@]}"; do
    if grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows gate-summary helper still allows silent skip: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Windows gate-summary helper guard present)"
}

check_windows_manual_closeout_guard() {
  local L3Cmd
  local LRunbook
  local LCloseoutDoc
  local LCloseoutChecklist
  local LCloseoutRoadmap
  local LCloseoutTemplate
  local LHandoffDoc
  local LReleaseChecklist
  local LCompletenessMatrix
  local LFullPlatformPlan
  local LTopChecklist
  local LMissing
  local LPattern
  local -a L3CmdRequired
  local -a LRunbookRequired
  local -a LCloseoutDocRequired
  local -a LCloseoutChecklistRequired
  local -a LCloseoutRoadmapRequired
  local -a LCloseoutTemplateRequired
  local -a LHandoffRequired
  local -a LReleaseChecklistRequired
  local -a LCompletenessMatrixRequired
  local -a LFullPlatformPlanRequired
  local -a LTopChecklistRequired

  L3Cmd="${ROOT}/print_windows_b07_closeout_3cmd.sh"
  LRunbook="${ROOT}/docs/windows_b07_closeout_runbook.md"
  LCloseoutDoc="${REPO_ROOT}/docs/fafafa.core.simd.closeout.md"
  LCloseoutChecklist="${REPO_ROOT}/docs/plans/2026-02-09-simd-windows-closeout-checklist.md"
  LCloseoutRoadmap="${REPO_ROOT}/docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md"
  LCloseoutTemplate="${REPO_ROOT}/docs/plans/2026-02-09-simd-windows-postrun-fill-template.md"
  LHandoffDoc="${REPO_ROOT}/docs/fafafa.core.simd.handoff.md"
  LReleaseChecklist="${ROOT}/docs/simd_release_candidate_checklist.md"
  LCompletenessMatrix="${ROOT}/docs/simd_completeness_matrix.md"
  LFullPlatformPlan="${REPO_ROOT}/docs/plans/2026-03-09-simd-full-platform-completeness.md"
  LTopChecklist="${REPO_ROOT}/docs/fafafa.core.simd.checklist.md"

  for LPattern in "${L3Cmd}" "${LRunbook}" "${LCloseoutDoc}" "${LCloseoutChecklist}" "${LCloseoutRoadmap}" "${LCloseoutTemplate}" "${LHandoffDoc}" "${LReleaseChecklist}" "${LCompletenessMatrix}" "${LFullPlatformPlan}" "${LTopChecklist}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing Windows manual closeout guard target: ${LPattern}"
      return 1
    fi
  done

  LMissing=0
  L3CmdRequired=(
    '2.2 Git Bash / WSL 回灌 cross gate（必需，native batch evidence 不会生成 fresh gate_summary）'
    'FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate'
    '- 手工 Windows 实机路径必须先显式补一轮 `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1` 的 Linux cross gate；`win-closeout-finalize` 自己不会回灌 gate。'
  )
  LRunbookRequired=(
    '3. 回灌 cross gate（Git Bash / WSL，必需）'
    '`FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`'
    '- 因此手工 Windows 实机路径在 finalize 前必须显式补跑 fail-close cross gate；否则 `freeze-status` 只会继续消费旧的 `gate_summary.md`。'
  )
  LCloseoutDocRequired=(
    'Then run the required fail-close cross gate:'
    'FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate'
    'native batch evidence 不会生成 fresh `gate_summary.md/json`'
  )
  LCloseoutChecklistRequired=(
    '0.1) 或直接使用 GH 单命令闭环（推荐）'
    'FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-20260320-152'
    '2) Git Bash / WSL 回灌 fail-close cross gate（必需）'
    'FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate'
    '不能从 `evidence-win-verify` 直接跳到 `win-closeout-finalize`'
  )
  LCloseoutRoadmapRequired=(
    'FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight'
    'FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate'
    'FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-YYYYMMDD-152'
  )
  LCloseoutTemplateRequired=(
    '先回灌 fail-close cross gate'
    'FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate'
    '不能从 `evidence-win-verify` 直接跳到 `finalize-win-evidence` 或 `win-closeout-finalize`'
  )
  LHandoffRequired=(
    'FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-YYYYMMDD-152'
    'FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status'
    'evidence-win-verify -> SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 gate -> win-closeout-finalize -> freeze-status'
  )
  LReleaseChecklistRequired=(
    'FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight'
    'FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate'
    'FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status'
  )
  LCompletenessMatrixRequired=(
    '采集 + 校验证据包；手工路径仍需后续 fail-close cross gate + finalize'
    'FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-YYYYMMDD-152'
  )
  LFullPlatformPlanRequired=(
    'FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate'
    'FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-YYYYMMDD-152'
  )
  LTopChecklistRequired=(
    '真正的 Windows 收口主线应优先使用 `win-evidence-via-gh`。'
    '若走手工 Windows 实机路径，则必须先跑 `FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`，再执行 `win-closeout-finalize`。'
  )

  for LPattern in "${L3CmdRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${L3Cmd}" >/dev/null; then
      echo "[CHECK] Windows closeout helper missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LRunbookRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LRunbook}" >/dev/null; then
      echo "[CHECK] Windows closeout runbook missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LCloseoutDocRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LCloseoutDoc}" >/dev/null; then
      echo "[CHECK] Windows closeout doc missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LCloseoutChecklistRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LCloseoutChecklist}" >/dev/null; then
      echo "[CHECK] Windows closeout checklist missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LCloseoutRoadmapRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LCloseoutRoadmap}" >/dev/null; then
      echo "[CHECK] Windows closeout roadmap missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LCloseoutTemplateRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LCloseoutTemplate}" >/dev/null; then
      echo "[CHECK] Windows closeout template missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LHandoffRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LHandoffDoc}" >/dev/null; then
      echo "[CHECK] Windows closeout handoff doc missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LReleaseChecklistRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LReleaseChecklist}" >/dev/null; then
      echo "[CHECK] Windows release checklist missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LCompletenessMatrixRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LCompletenessMatrix}" >/dev/null; then
      echo "[CHECK] Windows completeness matrix missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LFullPlatformPlanRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LFullPlatformPlan}" >/dev/null; then
      echo "[CHECK] Windows full-platform plan missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LTopChecklistRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LTopChecklist}" >/dev/null; then
      echo "[CHECK] Windows top checklist missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Windows manual closeout guard present)"
}

check_windows_closeout_helper_runtime_guard() {
  local LOutput
  local LPattern
  local LRC
  local LSampleBatchId
  local -a LRequired

  if [[ ! -f "${WIN_CLOSEOUT_3CMD_SCRIPT}" ]]; then
    echo "[CHECK] Missing Windows closeout helper runtime target: ${WIN_CLOSEOUT_3CMD_SCRIPT}"
    return 1
  fi

  LSampleBatchId="SIMD-CHECK-3CMD"
  set +e
  LOutput="$(bash "${WIN_CLOSEOUT_3CMD_SCRIPT}" "${LSampleBatchId}" 2>&1)"
  LRC=$?
  set -e
  if [[ "${LRC}" != "0" ]]; then
    echo "[CHECK] Windows closeout helper runtime failed rc=${LRC}"
    printf '%s\n' "${LOutput}"
    return 1
  fi

  LRequired=(
    'FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-CHECK-3CMD'
    'FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate'
    '- `win-evidence-via-gh` 现在会把中间态快照落到 `tests/fafafa.core.simd/logs/windows-closeout/SIMD-CHECK-3CMD/`，同时回写 canonical `logs/` 指针。'
    '- 手工 Windows 实机路径必须先显式补一轮 `SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1` 的 Linux cross gate；`win-closeout-finalize` 自己不会回灌 gate。'
  )

  for LPattern in "${LRequired[@]}"; do
    if ! grep -F -- "${LPattern}" <<<"${LOutput}" >/dev/null; then
      echo "[CHECK] Windows closeout helper runtime missing output pattern: ${LPattern}"
      return 1
    fi
  done

  echo "[CHECK] OK (Windows closeout helper runtime guard present)"
}

check_gate_summary_json_runtime_guard() {
  local LShell
  local LBat
  local LMissing
  local LPattern
  local LWriteJsonFunction
  local LRunGateSummaryFunction
  local LBatJsonBlock
  local -a LShellWriteRequired
  local -a LShellRunRequired
  local -a LBatRequired
  local -a LForbiddenShell
  local -a LForbiddenBat

  LShell="${ROOT}/BuildOrTest.sh"
  LBat="${ROOT}/buildOrTest.bat"

  for LPattern in "${LShell}" "${LBat}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing gate-summary JSON guard target: ${LPattern}"
      return 1
    fi
  done

  LMissing=0
  LWriteJsonFunction="$(sed -n '/^write_gate_summary_json()/,/^}/p' "${LShell}")"
  LRunGateSummaryFunction="$(sed -n '/^run_gate_summary()/,/^}/p' "${LShell}")"
  LBatJsonBlock="$(sed -n '/^if \/I \"%SIMD_GATE_SUMMARY_JSON%\"==\"1\" (/,/^exit \/b 0/p' "${LBat}")"

  LShellWriteRequired=(
    'echo "[GATE-SUMMARY] FAILED (python3 runtime not found; SIMD_GATE_SUMMARY_JSON=1 requires python3)"'
    'return 2'
  )

  LShellRunRequired=(
    'write_gate_summary_json "${LSummaryFile}" "${LJsonFile}" "${LSummaryFilter}" || return $?'
  )

  LBatRequired=(
    'where py >nul 2>nul'
    'where python >nul 2>nul'
    'echo [GATE-SUMMARY] FAILED ^(python runtime not found; SIMD_GATE_SUMMARY_JSON=1 requires python^)'
    'exit /b 2'
  )

  LForbiddenShell=(
    'echo "[GATE-SUMMARY] SKIP JSON export (python3 not found)"'
  )

  LForbiddenBat=(
    'echo [GATE-SUMMARY] SKIP JSON export ^(python runtime not found^)'
  )

  for LPattern in "${LShellWriteRequired[@]}"; do
    if [[ "${LWriteJsonFunction}" != *"${LPattern}"* ]]; then
      echo "[CHECK] Shell gate-summary JSON guard missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LShellRunRequired[@]}"; do
    if [[ "${LRunGateSummaryFunction}" != *"${LPattern}"* ]]; then
      echo "[CHECK] Shell gate-summary runner missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LBatRequired[@]}"; do
    if [[ "${LBatJsonBlock}" != *"${LPattern}"* ]]; then
      echo "[CHECK] Windows gate-summary JSON guard missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbiddenShell[@]}"; do
    if [[ "${LWriteJsonFunction}" == *"${LPattern}"* ]]; then
      echo "[CHECK] Shell gate-summary JSON guard still allows silent skip: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbiddenBat[@]}"; do
    if [[ "${LBatJsonBlock}" == *"${LPattern}"* ]]; then
      echo "[CHECK] Windows gate-summary JSON guard still allows silent skip: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (gate-summary JSON runtime guard present)"
}

check_perf_smoke_scalar_guard() {
  local LShell
  local LBat
  local LPython
  local LMissing
  local LPattern
  local LCheckPerfFunction
  local LBatPerfBlock
  local LPythonText
  local -a LShellRequired
  local -a LBatRequired
  local -a LPythonRequired
  local -a LForbiddenShell
  local -a LForbiddenBat
  local -a LForbiddenPython

  LShell="${ROOT}/BuildOrTest.sh"
  LBat="${ROOT}/buildOrTest.bat"
  LPython="${ROOT}/check_perf_smoke_log.py"

  for LPattern in "${LShell}" "${LBat}" "${LPython}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing perf-smoke scalar guard target: ${LPattern}"
      return 1
    fi
  done

  LMissing=0
  LCheckPerfFunction="$(sed -n '/^check_perf_log()/,/^}/p' "${LShell}")"
  LBatPerfBlock="$(sed -n '/^:perf_smoke/,/^:require_release_gate_prereqs/p' "${LBat}")"
  LPythonText="$(cat "${LPython}")"

  LShellRequired=(
    'echo "[PERF] FAILED (active backend is Scalar; perf-smoke requires non-scalar backend evidence)"'
    'return 1'
  )

  LBatRequired=(
    'echo [PERF] FAILED ^(active backend is Scalar; perf-smoke requires non-scalar backend evidence^)'
    'exit /b 1'
  )

  LPythonRequired=(
    'print("[PERF] FAILED (active backend is Scalar; perf-smoke requires non-scalar backend evidence)")'
    'return 1'
  )

  LForbiddenShell=(
    'echo "[PERF] SKIP (active backend is Scalar)"'
  )

  LForbiddenBat=(
    'echo [PERF] SKIP ^(active backend is Scalar^)'
  )

  LForbiddenPython=(
    'print("[PERF] SKIP (active backend is Scalar)")'
  )

  for LPattern in "${LShellRequired[@]}"; do
    if [[ "${LCheckPerfFunction}" != *"${LPattern}"* ]]; then
      echo "[CHECK] Shell perf-smoke scalar guard missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LBatRequired[@]}"; do
    if [[ "${LBatPerfBlock}" != *"${LPattern}"* ]]; then
      echo "[CHECK] Windows perf-smoke scalar guard missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LPythonRequired[@]}"; do
    if [[ "${LPythonText}" != *"${LPattern}"* ]]; then
      echo "[CHECK] Python perf-smoke scalar guard missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbiddenShell[@]}"; do
    if [[ "${LCheckPerfFunction}" == *"${LPattern}"* ]]; then
      echo "[CHECK] Shell perf-smoke scalar guard still allows silent skip: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbiddenBat[@]}"; do
    if [[ "${LBatPerfBlock}" == *"${LPattern}"* ]]; then
      echo "[CHECK] Windows perf-smoke scalar guard still allows silent skip: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbiddenPython[@]}"; do
    if [[ "${LPythonText}" == *"${LPattern}"* ]]; then
      echo "[CHECK] Python perf-smoke scalar guard still allows silent skip: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (perf-smoke scalar guard present)"
}

check_perf_smoke_public_abi_shape_guard() {
  local LBench
  local LMissing
  local LPattern
  local LBlock
  local -a LGlobalRequired
  local -a LGlobalForbidden

  LBench="${ROOT}/fafafa.core.simd.bench.pas"
  if [[ ! -f "${LBench}" ]]; then
    echo "[CHECK] Missing perf-smoke public ABI benchmark target: ${LBench}"
    return 1
  fi

  LMissing=0
  LGlobalRequired=(
    'PUBLIC_ABI_HOT_INNER = 256;'
  )
  LGlobalForbidden=(
    'g_PublicAbiApi: PFafafaSimdPublicApi;'
    'g_PublicAbiApi := GetSimdPublicApi;'
    'g_PublicAbiApi^.MemEqual('
    'g_PublicAbiApi^.SumBytes('
  )

  for LPattern in "${LGlobalRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBench}" >/dev/null; then
      echo "[CHECK] perf-smoke public ABI benchmark missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LGlobalForbidden[@]}"; do
    if grep -F -- "${LPattern}" "${LBench}" >/dev/null; then
      echo "[CHECK] perf-smoke public ABI benchmark still contains stale pattern: ${LPattern}"
      LMissing=1
    fi
  done

  LBlock="$(sed -n '/^function BenchHotMemEqual_Facade:/,/^end;$/p' "${LBench}")"
  for LPattern in \
    'for LIndex := 1 to PUBLIC_ABI_HOT_INNER do' \
    'g_PublicAbiDummyEq := MemEqual(' \
    'Result := PUBLIC_ABI_HOT_INNER;'
  do
    if [[ "${LBlock}" != *"${LPattern}"* ]]; then
      echo "[CHECK] BenchHotMemEqual_Facade missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  LBlock="$(sed -n '/^function BenchHotMemEqual_PublicCached:/,/^end;$/p' "${LBench}")"
  for LPattern in \
    'LApi: PFafafaSimdPublicApi;' \
    'LApi := GetSimdPublicApi;' \
    'for LIndex := 1 to PUBLIC_ABI_HOT_INNER do' \
    'g_PublicAbiDummyEq := LApi^.MemEqual(' \
    'Result := PUBLIC_ABI_HOT_INNER;'
  do
    if [[ "${LBlock}" != *"${LPattern}"* ]]; then
      echo "[CHECK] BenchHotMemEqual_PublicCached missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  LBlock="$(sed -n '/^function BenchHotMemEqual_PublicGetter:/,/^end;$/p' "${LBench}")"
  for LPattern in \
    'for LIndex := 1 to PUBLIC_ABI_HOT_INNER do' \
    'g_PublicAbiDummyEq := GetSimdPublicApi^.MemEqual(' \
    'Result := PUBLIC_ABI_HOT_INNER;'
  do
    if [[ "${LBlock}" != *"${LPattern}"* ]]; then
      echo "[CHECK] BenchHotMemEqual_PublicGetter missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  LBlock="$(sed -n '/^function BenchHotMemEqual_DispatchGetter:/,/^end;$/p' "${LBench}")"
  for LPattern in \
    'for LIndex := 1 to PUBLIC_ABI_HOT_INNER do' \
    'g_PublicAbiDummyEq := GetDispatchTable^.MemEqual(' \
    'Result := PUBLIC_ABI_HOT_INNER;'
  do
    if [[ "${LBlock}" != *"${LPattern}"* ]]; then
      echo "[CHECK] BenchHotMemEqual_DispatchGetter missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  LBlock="$(sed -n '/^function BenchHotSumBytes_Facade:/,/^end;$/p' "${LBench}")"
  for LPattern in \
    'for LIndex := 1 to PUBLIC_ABI_HOT_INNER do' \
    'g_PublicAbiDummySum := SumBytes(' \
    'Result := PUBLIC_ABI_HOT_INNER;'
  do
    if [[ "${LBlock}" != *"${LPattern}"* ]]; then
      echo "[CHECK] BenchHotSumBytes_Facade missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  LBlock="$(sed -n '/^function BenchHotSumBytes_PublicCached:/,/^end;$/p' "${LBench}")"
  for LPattern in \
    'LApi: PFafafaSimdPublicApi;' \
    'LApi := GetSimdPublicApi;' \
    'for LIndex := 1 to PUBLIC_ABI_HOT_INNER do' \
    'g_PublicAbiDummySum := LApi^.SumBytes(' \
    'Result := PUBLIC_ABI_HOT_INNER;'
  do
    if [[ "${LBlock}" != *"${LPattern}"* ]]; then
      echo "[CHECK] BenchHotSumBytes_PublicCached missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  LBlock="$(sed -n '/^function BenchHotSumBytes_PublicGetter:/,/^end;$/p' "${LBench}")"
  for LPattern in \
    'for LIndex := 1 to PUBLIC_ABI_HOT_INNER do' \
    'g_PublicAbiDummySum := GetSimdPublicApi^.SumBytes(' \
    'Result := PUBLIC_ABI_HOT_INNER;'
  do
    if [[ "${LBlock}" != *"${LPattern}"* ]]; then
      echo "[CHECK] BenchHotSumBytes_PublicGetter missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  LBlock="$(sed -n '/^function BenchHotSumBytes_DispatchGetter:/,/^end;$/p' "${LBench}")"
  for LPattern in \
    'for LIndex := 1 to PUBLIC_ABI_HOT_INNER do' \
    'g_PublicAbiDummySum := GetDispatchTable^.SumBytes(' \
    'Result := PUBLIC_ABI_HOT_INNER;'
  do
    if [[ "${LBlock}" != *"${LPattern}"* ]]; then
      echo "[CHECK] BenchHotSumBytes_DispatchGetter missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (perf-smoke public ABI benchmark shape present)"
}

check_windows_qemu_runner_guard() {
  local LBat
  local LMissing
  local LPattern
  local LHelperCallCount
  local -a LRequired
  local -a LForbidden

  LBat="${ROOT}/buildOrTest.bat"
  if [[ ! -f "${LBat}" ]]; then
    echo "[CHECK] Missing Windows qemu runner: ${LBat}"
    return 1
  fi

  LMissing=0
  LRequired=(
    ':require_qemu_bash_runtime'
    'echo [QEMU] FAILED ^(bash runtime not found; qemu multiarch actions require bash to preserve shell parity^)'
    ':qemu_nonx86_evidence'
    ':qemu_cpuinfo_nonx86_evidence'
    ':qemu_cpuinfo_nonx86_full_evidence'
    ':qemu_cpuinfo_nonx86_full_repeat'
    ':qemu_cpuinfo_nonx86_suite_repeat'
    ':qemu_arch_matrix_evidence'
    ':qemu_nonx86_experimental_asm'
    'call :require_qemu_bash_runtime'
  )

  LForbidden=(
    'echo [QEMU] SKIP ^(bash not found^)'
  )

  for LPattern in "${LRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows qemu runner missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbidden[@]}"; do
    if grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows qemu runner still allows silent skip when bash is missing"
      LMissing=1
    fi
  done

  LHelperCallCount="$(grep -cF 'call :require_qemu_bash_runtime' "${LBat}" || true)"
  if [[ "${LHelperCallCount}" != "7" ]]; then
    echo "[CHECK] Windows qemu runner expected 7 helper calls, got ${LHelperCallCount}"
    LMissing=1
  fi

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Windows qemu runner guard present)"
}

check_windows_bash_helper_runner_guard() {
  local LBat
  local LMissing
  local LPattern
  local -a LRequired
  local -a LForbidden

  LBat="${ROOT}/buildOrTest.bat"
  if [[ ! -f "${LBat}" ]]; then
    echo "[CHECK] Missing Windows bash helper runner: ${LBat}"
    return 1
  fi

  LMissing=0
  LRequired=(
    ':backend_bench'
    ':require_backend_bench_bash_runtime'
    'echo [BENCH] FAILED ^(bash runtime not found; backend-bench requires bash to preserve shell parity^)'
    'call :require_backend_bench_bash_runtime'
    ':riscvv_opcode_lane'
    ':require_rvv_lane_bash_runtime'
    'echo [RVV-LANE] FAILED ^(bash runtime not found; riscvv-opcode-lane requires bash to preserve shell parity^)'
    'call :require_rvv_lane_bash_runtime'
  )

  LForbidden=(
    'echo [BENCH] SKIP ^(bash not found^)'
    'echo [RVV-LANE] SKIP ^(bash not found^)'
  )

  for LPattern in "${LRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows bash helper runner missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbidden[@]}"; do
    if grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows bash helper runner still allows silent skip: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Windows bash helper runner guard present)"
}

check_qemu_experimental_python_helper_guard() {
  local LShell
  local LBat
  local LMissing
  local LPattern
  local LReportFunction
  local LBaselineFunction
  local -a LShellRequired
  local -a LBatRequired
  local -a LForbiddenShell
  local -a LForbiddenBat

  LShell="${ROOT}/BuildOrTest.sh"
  LBat="${ROOT}/buildOrTest.bat"

  for LPattern in "${LShell}" "${LBat}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing qemu experimental helper target: ${LPattern}"
      return 1
    fi
  done

  LMissing=0
  LReportFunction="$(sed -n '/^run_qemu_experimental_report()/,/^}/p' "${LShell}")"
  LBaselineFunction="$(sed -n '/^run_qemu_experimental_baseline_check()/,/^}/p' "${LShell}")"

  LShellRequired=(
    'echo "[QEMU-EXPERIMENTAL-REPORT] FAILED (python3 runtime not found; qemu-experimental-report requires python3)"'
    'echo "[QEMU-EXPERIMENTAL-BASELINE] FAILED (python3 runtime not found; qemu-experimental-baseline-check requires python3)"'
  )

  LBatRequired=(
    'echo [QEMU-EXPERIMENTAL-REPORT] FAILED ^(python runtime not found; tried py and python^)'
    'echo [QEMU-EXPERIMENTAL-BASELINE] FAILED ^(python runtime not found; tried py and python^)'
  )

  LForbiddenShell=(
    'echo "[QEMU-EXPERIMENTAL-REPORT] SKIP (python3 not found)"'
    'echo "[QEMU-EXPERIMENTAL-BASELINE] SKIP (python3 not found)"'
  )

  LForbiddenBat=(
    'echo [QEMU-EXPERIMENTAL-REPORT] SKIP ^(python runtime not found^)'
    'echo [QEMU-EXPERIMENTAL-BASELINE] SKIP ^(python runtime not found^)'
  )

  for LPattern in "${LShellRequired[@]}"; do
    case "${LPattern}" in
      *REPORT*)
        if ! grep -F -- "${LPattern}" <<<"${LReportFunction}" >/dev/null; then
          echo "[CHECK] Shell qemu experimental report helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
      *BASELINE*)
        if ! grep -F -- "${LPattern}" <<<"${LBaselineFunction}" >/dev/null; then
          echo "[CHECK] Shell qemu experimental baseline helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
    esac
  done

  for LPattern in "${LBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows qemu experimental helper missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbiddenShell[@]}"; do
    case "${LPattern}" in
      *REPORT*)
        if grep -F -- "${LPattern}" <<<"${LReportFunction}" >/dev/null; then
          echo "[CHECK] QEMU experimental report helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
      *BASELINE*)
        if grep -F -- "${LPattern}" <<<"${LBaselineFunction}" >/dev/null; then
          echo "[CHECK] QEMU experimental baseline helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
    esac
  done

  for LPattern in "${LForbiddenBat[@]}"; do
    if grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] QEMU experimental helper still allows silent skip: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (QEMU experimental python helper guard present)"
}

check_python_checker_runtime_guard() {
  local LShell
  local LBat
  local LMissing
  local LPattern
  local LRegisterFunction
  local LSuiteManifestFunction
  local LInterfaceFunction
  local LContractFunction
  local LPublicAbiFunction
  local LAdapterFunction
  local LCoverageFunction
  local LExperimentalFunction
  local LWiringFunction
  local -a LShellRequired
  local -a LBatRequired
  local -a LForbiddenShell
  local -a LForbiddenBat

  LShell="${ROOT}/BuildOrTest.sh"
  LBat="${ROOT}/buildOrTest.bat"

  for LPattern in "${LShell}" "${LBat}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing python checker runtime target: ${LPattern}"
      return 1
    fi
  done

  LMissing=0
  LRegisterFunction="$(sed -n '/^run_register_include_check()/,/^}/p' "${LShell}")"
  LSuiteManifestFunction="$(sed -n '/^run_suite_manifest_check()/,/^}/p' "${LShell}")"
  LInterfaceFunction="$(sed -n '/^run_interface_completeness()/,/^}/p' "${LShell}")"
  LContractFunction="$(sed -n '/^run_dispatch_contract_signature()/,/^}/p' "${LShell}")"
  LPublicAbiFunction="$(sed -n '/^run_public_abi_signature()/,/^}/p' "${LShell}")"
  LAdapterFunction="$(sed -n '/^run_backend_adapter_sync()/,/^}/p' "${LShell}")"
  LCoverageFunction="$(sed -n '/^run_coverage()/,/^}/p' "${LShell}")"
  LExperimentalFunction="$(sed -n '/^run_intrinsics_experimental_status()/,/^}/p' "${LShell}")"
  LWiringFunction="$(sed -n '/^run_wiring_sync()/,/^}/p' "${LShell}")"

  LShellRequired=(
    'echo "[REGISTER-INCLUDE] FAILED (python3 runtime not found; register include check requires python3)"'
    'echo "[SUITE-MANIFEST] FAILED (python3 runtime not found; suite-manifest check requires python3)"'
    'echo "[INTERFACE-CHECK] FAILED (python3 runtime not found; interface-completeness requires python3)"'
    'echo "[DISPATCH-CONTRACT] FAILED (python3 runtime not found; contract-signature requires python3)"'
    'echo "[PUBLIC-ABI] FAILED (python3 runtime not found; publicabi-signature requires python3)"'
    'echo "[ADAPTER-SYNC] FAILED (python3 runtime not found; adapter-sync requires python3)"'
    'echo "[COVERAGE] FAILED (python3 runtime not found; coverage requires python3)"'
    'echo "[EXPERIMENTAL] FAILED (python3 runtime not found; experimental-intrinsics requires python3)"'
    'echo "[WIRING-SYNC] FAILED (python3 runtime not found; wiring-sync requires python3)"'
  )

  LBatRequired=(
    'echo [REGISTER-INCLUDE] FAILED (python runtime not found; tried py and python)'
    'echo [SUITE-MANIFEST] FAILED (python runtime not found; tried py and python)'
    'echo [INTERFACE-CHECK] FAILED (python runtime not found; tried py and python)'
    'echo [DISPATCH-CONTRACT] FAILED (python runtime not found; tried py and python)'
    'echo [PUBLIC-ABI] FAILED (python runtime not found; tried py and python)'
    'echo [ADAPTER-SYNC] FAILED (python runtime not found; tried py and python)'
    'echo [COVERAGE] FAILED (python runtime not found; tried py and python)'
    'echo [EXPERIMENTAL] FAILED (python runtime not found; tried py and python)'
    'echo [WIRING-SYNC] FAILED (python runtime not found; tried py and python)'
  )

  LForbiddenShell=(
    'echo "[REGISTER-INCLUDE] SKIP (python3 not found)"'
    'echo "[SUITE-MANIFEST] SKIP (python3 not found)"'
    'echo "[INTERFACE-CHECK] SKIP (python3 not found)"'
    'echo "[DISPATCH-CONTRACT] SKIP (python3 not found)"'
    'echo "[PUBLIC-ABI] SKIP (python3 not found)"'
    'echo "[ADAPTER-SYNC] SKIP (python3 not found)"'
    'echo "[COVERAGE] SKIP (python3 not found)"'
    'echo "[EXPERIMENTAL] SKIP (python3 not found)"'
    'echo "[WIRING-SYNC] SKIP (python3 not found)"'
  )

  LForbiddenBat=(
    'echo [REGISTER-INCLUDE] SKIP (python runtime not found)'
    'echo [SUITE-MANIFEST] SKIP (python runtime not found)'
    'echo [INTERFACE-CHECK] SKIP (python runtime not found)'
    'echo [DISPATCH-CONTRACT] SKIP (python runtime not found)'
    'echo [PUBLIC-ABI] SKIP (python runtime not found)'
    'echo [ADAPTER-SYNC] SKIP (python runtime not found)'
    'echo [COVERAGE] SKIP (python runtime not found)'
    'echo [EXPERIMENTAL] SKIP (python runtime not found)'
    'echo [WIRING-SYNC] SKIP (python runtime not found)'
  )

  for LPattern in "${LShellRequired[@]}"; do
    case "${LPattern}" in
      *REGISTER-INCLUDE*)
        if ! grep -F -- "${LPattern}" <<<"${LRegisterFunction}" >/dev/null; then
          echo "[CHECK] Shell register-include helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
      *SUITE-MANIFEST*)
        if ! grep -F -- "${LPattern}" <<<"${LSuiteManifestFunction}" >/dev/null; then
          echo "[CHECK] Shell suite-manifest helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
      *INTERFACE-CHECK*)
        if ! grep -F -- "${LPattern}" <<<"${LInterfaceFunction}" >/dev/null; then
          echo "[CHECK] Shell interface-completeness helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
      *DISPATCH-CONTRACT*)
        if ! grep -F -- "${LPattern}" <<<"${LContractFunction}" >/dev/null; then
          echo "[CHECK] Shell contract-signature helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
      *PUBLIC-ABI*)
        if ! grep -F -- "${LPattern}" <<<"${LPublicAbiFunction}" >/dev/null; then
          echo "[CHECK] Shell publicabi-signature helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
      *ADAPTER-SYNC*)
        if ! grep -F -- "${LPattern}" <<<"${LAdapterFunction}" >/dev/null; then
          echo "[CHECK] Shell adapter-sync helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
      *COVERAGE*)
        if ! grep -F -- "${LPattern}" <<<"${LCoverageFunction}" >/dev/null; then
          echo "[CHECK] Shell coverage helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
      *EXPERIMENTAL*)
        if ! grep -F -- "${LPattern}" <<<"${LExperimentalFunction}" >/dev/null; then
          echo "[CHECK] Shell experimental helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
      *WIRING-SYNC*)
        if ! grep -F -- "${LPattern}" <<<"${LWiringFunction}" >/dev/null; then
          echo "[CHECK] Shell wiring-sync helper missing pattern: ${LPattern}"
          LMissing=1
        fi
        ;;
    esac
  done

  for LPattern in "${LBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows python checker helper missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbiddenShell[@]}"; do
    case "${LPattern}" in
      *REGISTER-INCLUDE*)
        if grep -F -- "${LPattern}" <<<"${LRegisterFunction}" >/dev/null; then
          echo "[CHECK] Shell register-include helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
      *SUITE-MANIFEST*)
        if grep -F -- "${LPattern}" <<<"${LSuiteManifestFunction}" >/dev/null; then
          echo "[CHECK] Shell suite-manifest helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
      *INTERFACE-CHECK*)
        if grep -F -- "${LPattern}" <<<"${LInterfaceFunction}" >/dev/null; then
          echo "[CHECK] Shell interface-completeness helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
      *DISPATCH-CONTRACT*)
        if grep -F -- "${LPattern}" <<<"${LContractFunction}" >/dev/null; then
          echo "[CHECK] Shell contract-signature helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
      *PUBLIC-ABI*)
        if grep -F -- "${LPattern}" <<<"${LPublicAbiFunction}" >/dev/null; then
          echo "[CHECK] Shell publicabi-signature helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
      *ADAPTER-SYNC*)
        if grep -F -- "${LPattern}" <<<"${LAdapterFunction}" >/dev/null; then
          echo "[CHECK] Shell adapter-sync helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
      *COVERAGE*)
        if grep -F -- "${LPattern}" <<<"${LCoverageFunction}" >/dev/null; then
          echo "[CHECK] Shell coverage helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
      *EXPERIMENTAL*)
        if grep -F -- "${LPattern}" <<<"${LExperimentalFunction}" >/dev/null; then
          echo "[CHECK] Shell experimental helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
      *WIRING-SYNC*)
        if grep -F -- "${LPattern}" <<<"${LWiringFunction}" >/dev/null; then
          echo "[CHECK] Shell wiring-sync helper still allows silent skip: ${LPattern}"
          LMissing=1
        fi
        ;;
    esac
  done

  for LPattern in "${LForbiddenBat[@]}"; do
    if grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows python checker helper still allows silent skip: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Python checker runtime guard present)"
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
    'check_build_log'
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

run_register_include_check() {
  if [[ ! -f "${REGISTER_INCLUDE_CHECK_SCRIPT}" ]]; then
    echo "[REGISTER-INCLUDE] Missing checker: ${REGISTER_INCLUDE_CHECK_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[REGISTER-INCLUDE] FAILED (python3 runtime not found; register include check requires python3)"
    return 2
  fi

  echo "[REGISTER-INCLUDE] Running: python3 ${REGISTER_INCLUDE_CHECK_SCRIPT} --summary-line"
  python3 "${REGISTER_INCLUDE_CHECK_SCRIPT}" --summary-line
}

run_suite_manifest_check() {
  if [[ ! -f "${SUITE_MANIFEST_CHECK_SCRIPT}" ]]; then
    echo "[SUITE-MANIFEST] Missing checker: ${SUITE_MANIFEST_CHECK_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[SUITE-MANIFEST] FAILED (python3 runtime not found; suite-manifest check requires python3)"
    return 2
  fi

  echo "[SUITE-MANIFEST] Running: python3 ${SUITE_MANIFEST_CHECK_SCRIPT} --summary-line"
  python3 "${SUITE_MANIFEST_CHECK_SCRIPT}" --summary-line
}

check_perf_log() {
  local LZeroSpeedup
  local LMemRegressions

  if [[ -f "${PERF_SMOKE_CHECK_SCRIPT}" ]] && command -v python3 >/dev/null 2>&1; then
    python3 "${PERF_SMOKE_CHECK_SCRIPT}" "${TEST_LOG}"
    return $?
  fi

  if ! grep -F '=== SIMD Benchmark (' "${TEST_LOG}" >/dev/null; then
    echo "[PERF] FAILED: benchmark header not found in ${TEST_LOG}"
    return 1
  fi

  if grep -F '/Scalar)' "${TEST_LOG}" >/dev/null; then
    echo "[PERF] FAILED (active backend is Scalar; perf-smoke requires non-scalar backend evidence)"
    return 1
  fi

  LZeroSpeedup="$(awk '/^(MemEqual|MemFindByte|SumBytes|CountByte|BitsetPopCount|VecF32x4Add|VecF32x4Mul|VecF32x4Div|VecI32x4Add|VecF32x4Dot|VecF32x8DotApi|VecF32x8DotBatch|ArrSumF32|ArrSumF64|ArrMinMaxF32|ArrMinMaxF64|ArrVarF32|ArrVarF64|ArrKahanF32|ArrKahanF64)/ { if ($2 != "-" && (($NF + 0) == 0)) print }' "${TEST_LOG}")"
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
    echo "[INTERFACE-CHECK] FAILED (python3 runtime not found; interface-completeness requires python3)"
    return 2
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

run_dispatch_contract_signature() {
  if [[ ! -f "${DISPATCH_CONTRACT_SIGNATURE_SCRIPT}" ]]; then
    echo "[DISPATCH-CONTRACT] Missing checker: ${DISPATCH_CONTRACT_SIGNATURE_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[DISPATCH-CONTRACT] FAILED (python3 runtime not found; contract-signature requires python3)"
    return 2
  fi

  local LContractLog
  local LContractJsonLog
  local LMainRC
  local LSummaryLine

  LContractLog="${SIMD_DISPATCH_CONTRACT_LOG_FILE:-${DISPATCH_CONTRACT_SIGNATURE_LOG}}"
  LContractJsonLog="${SIMD_DISPATCH_CONTRACT_JSON_FILE:-${DISPATCH_CONTRACT_SIGNATURE_JSON_LOG}}"

  echo "[DISPATCH-CONTRACT] Running: python3 ${DISPATCH_CONTRACT_SIGNATURE_SCRIPT} --summary-line --json-file ${LContractJsonLog}"
  : > "${LContractLog}"
  python3 "${DISPATCH_CONTRACT_SIGNATURE_SCRIPT}" --summary-line --json-file "${LContractJsonLog}" 2>&1 | tee "${LContractLog}"
  LMainRC="${PIPESTATUS[0]}"

  LSummaryLine="$(grep -E '^DISPATCH_CONTRACT_SIGNATURE ' "${LContractLog}" | tail -n 1 || true)"
  if [[ -n "${LSummaryLine}" ]]; then
    echo "[DISPATCH-CONTRACT] Summary: ${LSummaryLine#DISPATCH_CONTRACT_SIGNATURE }"
  fi

  return "${LMainRC}"
}

run_public_abi_signature() {
  if [[ ! -f "${PUBLIC_ABI_SIGNATURE_SCRIPT}" ]]; then
    echo "[PUBLIC-ABI] Missing checker: ${PUBLIC_ABI_SIGNATURE_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[PUBLIC-ABI] FAILED (python3 runtime not found; publicabi-signature requires python3)"
    return 2
  fi

  local LContractLog
  local LContractJsonLog
  local LMainRC
  local LSummaryLine

  LContractLog="${SIMD_PUBLIC_ABI_LOG_FILE:-${PUBLIC_ABI_SIGNATURE_LOG}}"
  LContractJsonLog="${SIMD_PUBLIC_ABI_JSON_FILE:-${PUBLIC_ABI_SIGNATURE_JSON_LOG}}"

  echo "[PUBLIC-ABI] Running: python3 ${PUBLIC_ABI_SIGNATURE_SCRIPT} --summary-line --json-file ${LContractJsonLog}"
  : > "${LContractLog}"
  python3 "${PUBLIC_ABI_SIGNATURE_SCRIPT}" --summary-line --json-file "${LContractJsonLog}" 2>&1 | tee "${LContractLog}"
  LMainRC="${PIPESTATUS[0]}"

  LSummaryLine="$(grep -E '^PUBLIC_ABI_SIGNATURE ' "${LContractLog}" | tail -n 1 || true)"
  if [[ -n "${LSummaryLine}" ]]; then
    echo "[PUBLIC-ABI] Summary: ${LSummaryLine#PUBLIC_ABI_SIGNATURE }"
  fi

  return "${LMainRC}"
}

run_publicabi_smoke() {
  local LTestsRoot
  local LPublicAbiOutputRoot

  if [[ ! -f "${PUBLICABI_RUNNER_SCRIPT}" ]]; then
    echo "[PUBLICABI] Missing runner: ${PUBLICABI_RUNNER_SCRIPT}"
    return 2
  fi

  LTestsRoot="$(cd "${ROOT}/.." && pwd)"
  LPublicAbiOutputRoot="$(publicabi_output_root "${LTestsRoot}")"

  echo "[PUBLICABI] Running: bash ${PUBLICABI_RUNNER_SCRIPT} test"
  SIMD_OUTPUT_ROOT="${LPublicAbiOutputRoot}" bash "${PUBLICABI_RUNNER_SCRIPT}" test
}

check_publicabi_output_isolation() {
  local LMainShell
  local LMainBat
  local LPublicAbiShell
  local LPublicAbiBat
  local LPattern
  local LMissing
  local -a LMainShellRequired
  local -a LMainBatRequired
  local -a LPublicAbiShellRequired
  local -a LPublicAbiBatRequired

  LMainShell="${ROOT}/BuildOrTest.sh"
  LMainBat="${ROOT}/buildOrTest.bat"
  LPublicAbiShell="${ROOT}/../fafafa.core.simd.publicabi/BuildOrTest.sh"
  LPublicAbiBat="${ROOT}/../fafafa.core.simd.publicabi/BuildOrTest.bat"
  LMissing=0

  for LPattern in "${LMainShell}" "${LMainBat}" "${LPublicAbiShell}" "${LPublicAbiBat}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing public ABI isolation target: ${LPattern}"
      return 1
    fi
  done

  LMainShellRequired=(
    'publicabi_output_root() {'
    'LPublicAbiOutputRoot="$(publicabi_output_root "${LTestsRoot}")"'
    'SIMD_OUTPUT_ROOT="${LPublicAbiOutputRoot}" bash "${PUBLICABI_RUNNER_SCRIPT}" test'
    '"${LPublicAbiArtifactsRoot}/logs/test.txt"'
  )
  LMainBatRequired=(
    'set "PUBLICABI_OUTPUT_ROOT="'
    'if /I "%OUTPUT_ROOT%"=="%ROOT%" ('
    'set "PUBLICABI_OUTPUT_ROOT=%TESTS_ROOT%\fafafa.core.simd.publicabi"'
    'set "PUBLICABI_OUTPUT_ROOT=%OUTPUT_ROOT%\publicabi"'
    'set "PREV_SIMD_OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"'
    'set "SIMD_OUTPUT_ROOT=%PUBLICABI_OUTPUT_ROOT%"'
    'set "SIMD_OUTPUT_ROOT=%PREV_SIMD_OUTPUT_ROOT%"'
  )
  LPublicAbiShellRequired=(
    'OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${ROOT}}"'
    'BIN_DIR="${OUTPUT_ROOT}/bin"'
    'LIB_DIR="${OUTPUT_ROOT}/lib/${TARGET_CPU}-${TARGET_OS}"'
    'LOG_DIR="${OUTPUT_ROOT}/logs"'
  )
  LPublicAbiBatRequired=(
    'set "OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"'
    'if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=%ROOT%"'
    'set "BIN_DIR=%OUTPUT_ROOT%bin"'
    'set "LIB_DIR=%OUTPUT_ROOT%lib\%TARGET_CPU%-%TARGET_OS%"'
    'set "LOG_DIR=%OUTPUT_ROOT%logs"'
  )

  for LPattern in "${LMainShellRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LMainShell}" >/dev/null; then
      echo "[CHECK] Main shell runner missing public ABI isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LMainBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LMainBat}" >/dev/null; then
      echo "[CHECK] Main batch runner missing public ABI isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LPublicAbiShellRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LPublicAbiShell}" >/dev/null; then
      echo "[CHECK] Public ABI shell runner missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LPublicAbiBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LPublicAbiBat}" >/dev/null; then
      echo "[CHECK] Public ABI batch runner missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (public ABI output isolation present)"
}

check_publicabi_shell_export_guard() {
  local LPublicAbiShell
  local LMissing
  local LPattern
  local -a LRequired
  local -a LForbidden

  LPublicAbiShell="${ROOT}/../fafafa.core.simd.publicabi/BuildOrTest.sh"
  if [[ ! -f "${LPublicAbiShell}" ]]; then
    echo "[CHECK] Missing public ABI shell runner for export guard: ${LPublicAbiShell}"
    return 1
  fi

  LMissing=0
  LRequired=(
    'echo "[EXPORT] Running: readelf --wide --dyn-syms ${LIB_PATH}"'
    'echo "[EXPORT] Running: nm -D --defined-only ${LIB_PATH}"'
    'echo "[EXPORT] FAILED (readelf/nm not found; validate-exports requires a symbol inspection tool)"'
  )

  LForbidden=(
    'echo "[EXPORT] SKIP (readelf/nm not found)"'
  )

  for LPattern in "${LRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LPublicAbiShell}" >/dev/null; then
      echo "[CHECK] Public ABI shell export guard missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbidden[@]}"; do
    if grep -F -- "${LPattern}" "${LPublicAbiShell}" >/dev/null; then
      echo "[CHECK] Public ABI shell export guard still allows silent skip: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (public ABI shell export guard present)"
}

check_isolated_clean_coverage() {
  local LMainShell
  local LMainBat
  local LPattern
  local LMissing
  local -a LMainShellRequired
  local -a LMainBatRequired

  LMainShell="${ROOT}/BuildOrTest.sh"
  LMainBat="${ROOT}/buildOrTest.bat"
  LMissing=0

  for LPattern in "${LMainShell}" "${LMainBat}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing isolated clean target: ${LPattern}"
      return 1
    fi
  done

  LMainShellRequired=(
    'run_clean() {'
    'if [[ "${OUTPUT_ROOT}" != "${ROOT}" ]]; then'
    '"${OUTPUT_ROOT}/bin"'
    '"${OUTPUT_ROOT}/lib"'
    '"${OUTPUT_ROOT}/cpuinfo"'
    '"${OUTPUT_ROOT}/cpuinfo.x86"'
    '"${OUTPUT_ROOT}/intrinsics.experimental"'
    '"${OUTPUT_ROOT}/publicabi"'
    '"${OUTPUT_ROOT}/run_all"'
  )
  LMainBatRequired=(
    'if /I not "%OUTPUT_ROOT%"=="%ROOT%" ('
    'if exist "%OUTPUT_ROOT%\bin" rmdir /s /q "%OUTPUT_ROOT%\bin"'
    'if exist "%OUTPUT_ROOT%\lib" rmdir /s /q "%OUTPUT_ROOT%\lib"'
    'if exist "%OUTPUT_ROOT%\cpuinfo" rmdir /s /q "%OUTPUT_ROOT%\cpuinfo"'
    'if exist "%OUTPUT_ROOT%\cpuinfo.x86" rmdir /s /q "%OUTPUT_ROOT%\cpuinfo.x86"'
    'if exist "%OUTPUT_ROOT%\intrinsics.experimental" rmdir /s /q "%OUTPUT_ROOT%\intrinsics.experimental"'
    'if exist "%OUTPUT_ROOT%\publicabi" rmdir /s /q "%OUTPUT_ROOT%\publicabi"'
    'if exist "%OUTPUT_ROOT%\run_all" rmdir /s /q "%OUTPUT_ROOT%\run_all"'
  )

  for LPattern in "${LMainShellRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LMainShell}" >/dev/null; then
      echo "[CHECK] Main shell runner missing isolated clean pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LMainBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LMainBat}" >/dev/null; then
      echo "[CHECK] Main batch runner missing isolated clean pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (isolated clean coverage present)"
}

check_run_all_output_isolation() {
  local LRunAllShell
  local LRunAllBat
  local LPattern
  local LMissing
  local -a LRunAllShellRequired
  local -a LRunAllBatRequired

  LRunAllShell="${ROOT}/../run_all_tests.sh"
  LRunAllBat="${ROOT}/../run_all_tests.bat"
  LMissing=0

  for LPattern in "${LRunAllShell}" "${LRunAllBat}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing run_all isolation target: ${LPattern}"
      return 1
    fi
  done

  LRunAllShellRequired=(
    'simd_module_output_root() {'
    'echo "${SIMD_OUTPUT_ROOT}/run_all/${module}"'
    'SIMD_OUTPUT_ROOT="${module_output_root}" bash "./$(basename "$script")" "$action"'
  )
  LRunAllBatRequired=(
    'if defined SIMD_OUTPUT_ROOT if /I "!MOD_FULL:~0,16!"=="fafafa.core.simd" set "MODULE_SIMD_OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%\run_all\!MOD_FULL!"'
    'set "ACTION=%RUN_ACTION%"'
    'if not defined ACTION set "ACTION=test"'
    'echo Action: !ACTION!>>"%LOG_FILE%"'
    'set "PREV_SIMD_OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"'
    'if defined MODULE_SIMD_OUTPUT_ROOT set "SIMD_OUTPUT_ROOT=!MODULE_SIMD_OUTPUT_ROOT!"'
    'call "%SCRIPT%" "!ACTION!" >>"%LOG_FILE%" 2>&1'
    'set "SIMD_OUTPUT_ROOT=%PREV_SIMD_OUTPUT_ROOT%"'
  )

  for LPattern in "${LRunAllShellRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LRunAllShell}" >/dev/null; then
      echo "[CHECK] run_all shell missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LRunAllBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LRunAllBat}" >/dev/null; then
      echo "[CHECK] run_all batch missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if grep -F -- 'call "%SCRIPT%" >>"%LOG_FILE%" 2>&1' "${LRunAllBat}" >/dev/null; then
    echo "[CHECK] run_all batch still calls module scripts without RUN_ACTION forwarding"
    LMissing=1
  fi

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (run_all output isolation present)"
}

check_intrinsics_runner_output_isolation() {
  local LSseShell
  local LMmxShell
  local LSseBat
  local LMmxBat
  local LPattern
  local LMissing
  local -a LShellRequired
  local -a LBatRequired

  LSseShell="${ROOT}/../fafafa.core.simd.intrinsics.sse/BuildOrTest.sh"
  LMmxShell="${ROOT}/../fafafa.core.simd.intrinsics.mmx/BuildOrTest.sh"
  LSseBat="${ROOT}/../fafafa.core.simd.intrinsics.sse/buildOrTest.bat"
  LMmxBat="${ROOT}/../fafafa.core.simd.intrinsics.mmx/buildOrTest.bat"
  LMissing=0

  for LPattern in "${LSseShell}" "${LMmxShell}" "${LSseBat}" "${LMmxBat}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing intrinsics isolation target: ${LPattern}"
      return 1
    fi
  done

  LShellRequired=(
    'OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${ROOT}}"'
    'UNIT_DIR="${OUTPUT_ROOT}/lib/${TARGET_CPU}-${TARGET_OS}"'
    'BIN_DIR="${OUTPUT_ROOT}/bin"'
    'LOG_DIR="${OUTPUT_ROOT}/logs"'
    '--opt=-FE${BIN_DIR}'
    '--opt=-FU${UNIT_DIR}'
  )
  LBatRequired=(
    'set "OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"'
    'if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=%ROOT%"'
    'set "BIN_DIR=%OUTPUT_ROOT%\bin"'
    'set "LIB_DIR=%OUTPUT_ROOT%\lib\%TARGET_CPU%-%TARGET_OS%"'
    'set "LOG_DIR=%OUTPUT_ROOT%\logs"'
    '--opt=-FE%BIN_DIR%'
    '--opt=-FU%LIB_DIR%'
  )

  for LPattern in "${LShellRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LSseShell}" >/dev/null; then
      echo "[CHECK] SSE shell runner missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
    if ! grep -F -- "${LPattern}" "${LMmxShell}" >/dev/null; then
      echo "[CHECK] MMX shell runner missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LSseBat}" >/dev/null; then
      echo "[CHECK] SSE batch runner missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
    if ! grep -F -- "${LPattern}" "${LMmxBat}" >/dev/null; then
      echo "[CHECK] MMX batch runner missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (intrinsics runner output isolation present)"
}

check_experimental_intrinsics_output_isolation() {
  local LMainShell
  local LMainBat
  local LExperimentalShell
  local LExperimentalBat
  local LPattern
  local LMissing
  local -a LMainShellRequired
  local -a LMainBatRequired
  local -a LExperimentalShellRequired
  local -a LExperimentalBatRequired

  LMainShell="${ROOT}/BuildOrTest.sh"
  LMainBat="${ROOT}/buildOrTest.bat"
  LExperimentalShell="${ROOT}/../fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh"
  LExperimentalBat="${ROOT}/../fafafa.core.simd.intrinsics.experimental/buildOrTest.bat"
  LMissing=0

  for LPattern in "${LMainShell}" "${LMainBat}" "${LExperimentalShell}" "${LExperimentalBat}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing experimental intrinsics isolation target: ${LPattern}"
      return 1
    fi
  done

  LMainShellRequired=(
    'experimental_intrinsics_output_root() {'
    'LExperimentalOutputRoot="$(experimental_intrinsics_output_root "${LTestsRoot}")"'
    'SIMD_OUTPUT_ROOT="${LExperimentalOutputRoot}" bash "${LRunner}" test-all'
  )
  LMainBatRequired=(
    'set "EXPERIMENTAL_OUTPUT_ROOT="'
    'set "EXPERIMENTAL_OUTPUT_ROOT=%TESTS_ROOT%\fafafa.core.simd.intrinsics.experimental"'
    'set "EXPERIMENTAL_OUTPUT_ROOT=%OUTPUT_ROOT%\intrinsics.experimental"'
    'set "PREV_SIMD_OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"'
    'set "SIMD_OUTPUT_ROOT=%EXPERIMENTAL_OUTPUT_ROOT%"'
    'set "SIMD_OUTPUT_ROOT=%PREV_SIMD_OUTPUT_ROOT%"'
  )
  LExperimentalShellRequired=(
    'OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${ROOT}}"'
    'BIN_DIR="${OUTPUT_ROOT}/bin"'
    'LIB_DIR="${OUTPUT_ROOT}/lib/${TRIPLET}/${MODE_TAG}"'
    'LOG_DIR="${OUTPUT_ROOT}/logs"'
    'rm -rf "${BIN_DIR}" "${OUTPUT_ROOT}/lib" "${LOG_DIR}"'
  )
  LExperimentalBatRequired=(
    'set "OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"'
    'if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=%ROOT%"'
    'set "BIN_DIR=%OUTPUT_ROOT%bin"'
    'set "LIB_DIR=%OUTPUT_ROOT%lib"'
    'set "LOG_DIR=%OUTPUT_ROOT%logs"'
  )

  for LPattern in "${LMainShellRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LMainShell}" >/dev/null; then
      echo "[CHECK] Main shell runner missing experimental intrinsics isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LMainBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LMainBat}" >/dev/null; then
      echo "[CHECK] Main batch runner missing experimental intrinsics isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LExperimentalShellRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LExperimentalShell}" >/dev/null; then
      echo "[CHECK] Experimental intrinsics shell runner missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LExperimentalBatRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LExperimentalBat}" >/dev/null; then
      echo "[CHECK] Experimental intrinsics batch runner missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (experimental intrinsics output isolation present)"
}

check_linux_evidence_output_isolation() {
  local LEvidenceScript
  local LBenchScript
  local LPattern
  local LMissing
  local -a LEvidenceRequired
  local -a LBenchRequired
  local -a LEvidenceForbidden
  local -a LBenchForbidden

  LEvidenceScript="${ROOT}/collect_linux_simd_evidence.sh"
  LBenchScript="${ROOT}/run_backend_benchmarks.sh"
  LMissing=0

  for LPattern in "${LEvidenceScript}" "${LBenchScript}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing Linux evidence isolation target: ${LPattern}"
      return 1
    fi
  done

  LEvidenceRequired=(
    'OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${SCRIPT_DIR}}"'
    'OUT_DIR="${OUTPUT_ROOT}/logs/evidence-${TS}"'
  )
  LBenchRequired=(
    'OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${SCRIPT_DIR}}"'
    'OUT_DIR="${OUTPUT_ROOT}/logs/backend-bench-${TS}"'
    'LBinary="${OUTPUT_ROOT}/bin2/fafafa.core.simd.test"'
    'SIMD_OUTPUT_ROOT="${OUTPUT_ROOT}" bash tests/fafafa.core.simd/BuildOrTest.sh build'
  )
  LEvidenceForbidden=(
    'OUT_DIR="${SCRIPT_DIR}/logs/evidence-${TS}"'
  )
  LBenchForbidden=(
    'OUT_DIR="${SCRIPT_DIR}/logs/backend-bench-${TS}"'
    'LBinary="${SCRIPT_DIR}/bin2/fafafa.core.simd.test"'
  )

  for LPattern in "${LEvidenceRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LEvidenceScript}" >/dev/null; then
      echo "[CHECK] Linux evidence collector missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LBenchRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBenchScript}" >/dev/null; then
      echo "[CHECK] Backend bench runner missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LEvidenceForbidden[@]}"; do
    if grep -F -- "${LPattern}" "${LEvidenceScript}" >/dev/null; then
      echo "[CHECK] Linux evidence collector still writes default evidence root: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LBenchForbidden[@]}"; do
    if grep -F -- "${LPattern}" "${LBenchScript}" >/dev/null; then
      echo "[CHECK] Backend bench runner still writes default isolation-breaking path: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Linux evidence output isolation present)"
}

check_freeze_status_output_isolation() {
  local LRunner
  local LCollector
  local LFreezeFunction
  local LMissing
  local LPattern
  local -a LRunnerRequired
  local -a LRunnerForbidden
  local -a LCollectorRequired

  LRunner="${ROOT}/BuildOrTest.sh"
  LCollector="${ROOT}/collect_linux_simd_evidence.sh"
  for LPattern in "${LRunner}" "${LCollector}"; do
    if [[ ! -f "${LPattern}" ]]; then
      echo "[CHECK] Missing freeze-status isolation target: ${LPattern}"
      return 1
    fi
  done

  LMissing=0
  LFreezeFunction="$(sed -n '/^run_freeze_status()/,/^}/p' "${LRunner}")"
  LRunnerRequired=(
    'LJsonPath="${SIMD_FREEZE_STATUS_JSON_FILE:-${LOG_DIR}/freeze_status.json}"'
    'LGateSummaryFile="${SIMD_FREEZE_GATE_SUMMARY_FILE:-${SIMD_GATE_SUMMARY_FILE:-${GATE_SUMMARY_LOG}}}"'
    'SIMD_FREEZE_GATE_SUMMARY_FILE="${LGateSummaryFile}" \'
  )
  LRunnerForbidden=(
    'LJsonPath="${SIMD_FREEZE_STATUS_JSON_FILE:-${ROOT}/logs/freeze_status.json}"'
  )
  LCollectorRequired=(
    'SIMD_FREEZE_GATE_SUMMARY_FILE="${OUTPUT_ROOT}/logs/gate_summary.md"'
    'SIMD_FREEZE_STATUS_JSON_FILE="${OUTPUT_ROOT}/logs/freeze_status.json"'
  )

  for LPattern in "${LRunnerRequired[@]}"; do
    if [[ "${LFreezeFunction}" != *"${LPattern}"* ]]; then
      echo "[CHECK] Freeze-status runner missing isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LRunnerForbidden[@]}"; do
    if [[ "${LFreezeFunction}" == *"${LPattern}"* ]]; then
      echo "[CHECK] Freeze-status runner still contains stale root-log pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LCollectorRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LCollector}" >/dev/null; then
      echo "[CHECK] Linux evidence collector missing freeze-status isolation pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (freeze-status output isolation present)"
}

check_windows_experimental_tests_runner_guard() {
  local LBat
  local LMissing
  local LPattern
  local -a LRequired

  LBat="${ROOT}/buildOrTest.bat"
  if [[ ! -f "${LBat}" ]]; then
    echo "[CHECK] Missing Windows runner for experimental tests guard: ${LBat}"
    return 1
  fi

  LMissing=0
  LRequired=(
    ':experimental_intrinsics_tests'
    'set "EXPERIMENTAL_TESTS_RUNNER=%ROOT%..\fafafa.core.simd.intrinsics.experimental\BuildOrTest.sh"'
    'where bash >nul 2>nul'
    'echo [EXPERIMENTAL-TESTS] FAILED ^(bash runtime not found; native batch experimental runner parity is not guaranteed^)'
    'exit /b 2'
    'set "SIMD_OUTPUT_ROOT=%EXPERIMENTAL_OUTPUT_ROOT%"'
    'set "SIMD_OUTPUT_ROOT=%PREV_SIMD_OUTPUT_ROOT%"'
  )

  for LPattern in "${LRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows experimental tests runner missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  if grep -F -- 'echo [EXPERIMENTAL-TESTS] SKIP (bash not found)' "${LBat}" >/dev/null; then
    echo "[CHECK] Windows experimental tests runner still allows silent skip when bash is missing"
    LMissing=1
  fi

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Windows experimental tests runner guard present)"
}

check_windows_experimental_direct_runner_guard() {
  local LBat
  local LMissing
  local LPattern
  local -a LRequired
  local -a LForbidden

  LBat="${ROOT}/../fafafa.core.simd.intrinsics.experimental/buildOrTest.bat"
  if [[ ! -f "${LBat}" ]]; then
    echo "[CHECK] Missing Windows direct experimental runner: ${LBat}"
    return 1
  fi

  LMissing=0
  LRequired=(
    'set "CANONICAL_RUNNER=%ROOT%BuildOrTest.sh"'
    ':require_canonical_runner'
    ':require_bash_runtime'
    ':run_canonical'
    'echo [CANONICAL] FAILED ^(bash runtime not found; direct batch experimental runner requires bash to preserve shell parity^)'
    'set "SIMD_OUTPUT_ROOT=%OUTPUT_ROOT%"'
    'set "FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=%CANONICAL_EXPERIMENTAL_FLAG%"'
    'bash "%CANONICAL_RUNNER%" "%CANONICAL_ACTION%" %TEST_ARGS%'
    'call :run_canonical "build" "0"'
    'call :run_canonical "build" "1"'
    'call :run_canonical "check" "0"'
    'call :run_canonical "test" "0"'
    'call :run_canonical "test" "1"'
    'call :run_canonical "test-all" "0"'
  )

  LForbidden=(
    ':build_core'
    ':check_build_log'
    ':run_tests'
    '"%FPC_BIN%" -B -Mobjfpc -Sc -Si -O1 -g -gl -dDEBUG'
    'call "%~f0" test %TEST_ARGS%'
    'call "%~f0" test-experimental %TEST_ARGS%'
  )

  for LPattern in "${LRequired[@]}"; do
    if ! grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows direct experimental runner missing pattern: ${LPattern}"
      LMissing=1
    fi
  done

  for LPattern in "${LForbidden[@]}"; do
    if grep -F -- "${LPattern}" "${LBat}" >/dev/null; then
      echo "[CHECK] Windows direct experimental runner still contains deprecated native path: ${LPattern}"
      LMissing=1
    fi
  done

  if [[ "${LMissing}" != "0" ]]; then
    return 1
  fi

  echo "[CHECK] OK (Windows direct experimental runner guard present)"
}

run_backend_adapter_sync() {
  build_project || return $?

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
    echo "[ADAPTER-SYNC] FAILED (python3 runtime not found; adapter-sync requires python3)"
    return 2
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
  echo "[ADAPTER-SYNC-PASCAL] suite=TTestCase_DispatchAPI"
  run_tests --suite=TTestCase_DispatchAPI || return $?
  check_heap_leaks || return $?
}

run_coverage() {
  if [[ ! -f "${COVERAGE_SCRIPT}" ]]; then
    echo "[COVERAGE] Missing checker: ${COVERAGE_SCRIPT}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[COVERAGE] FAILED (python3 runtime not found; coverage requires python3)"
    return 2
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
    echo "[EXPERIMENTAL] FAILED (python3 runtime not found; experimental-intrinsics requires python3)"
    return 2
  fi

  echo "[EXPERIMENTAL] Running: python3 ${EXPERIMENTAL_INTRINSICS_SCRIPT}"
  python3 "${EXPERIMENTAL_INTRINSICS_SCRIPT}"
}

run_experimental_intrinsics_tests() {
  local LTestsRoot
  local LRunner
  local LExperimentalOutputRoot

  LTestsRoot="$(cd "${ROOT}/.." && pwd)"
  LRunner="${LTestsRoot}/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh"
  LExperimentalOutputRoot="$(experimental_intrinsics_output_root "${LTestsRoot}")"

  if [[ ! -x "${LRunner}" ]]; then
    echo "[EXPERIMENTAL-TESTS] Missing runner: ${LRunner}"
    return 2
  fi

  echo "[EXPERIMENTAL-TESTS] Running: bash ${LRunner} test-all"
  SIMD_OUTPUT_ROOT="${LExperimentalOutputRoot}" bash "${LRunner}" test-all
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
    echo "SLOW_CRIT"
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
  check_avx512_optin_runner_guard || return $?
  check_nonx86_optin_runner_guard || return $?
  check_windows_experimental_tests_runner_guard || return $?
  check_windows_experimental_direct_runner_guard || return $?
  check_windows_publicabi_runner_guard || return $?
  check_windows_evidence_collector_guard || return $?
  check_windows_simulated_evidence_guard || return $?
  check_windows_gate_summary_helper_guard || return $?
  check_windows_manual_closeout_guard || return $?
  check_windows_closeout_helper_runtime_guard || return $?
  check_gate_summary_json_runtime_guard || return $?
  check_perf_smoke_scalar_guard || return $?
  check_perf_smoke_public_abi_shape_guard || return $?
  check_windows_qemu_runner_guard || return $?
  check_windows_bash_helper_runner_guard || return $?
  check_qemu_experimental_python_helper_guard || return $?
  check_python_checker_runtime_guard || return $?
  check_publicabi_output_isolation || return $?
  check_publicabi_shell_export_guard || return $?
  check_isolated_clean_coverage || return $?
  check_run_all_output_isolation || return $?
  check_intrinsics_runner_output_isolation || return $?
  check_experimental_intrinsics_output_isolation || return $?
  check_linux_evidence_output_isolation || return $?
  check_freeze_status_output_isolation || return $?
  check_cpuinfo_runner_parity || return $?
  run_register_include_check || return $?
  run_suite_manifest_check || return $?
  run_nonx86_optin_list_suites || return $?
}

gate_step_interface_completeness() {
  run_interface_completeness || return $?
}

gate_step_contract_signature() {
  run_dispatch_contract_signature || return $?
}

gate_step_public_abi_signature() {
  run_public_abi_signature || return $?
}

gate_step_publicabi_smoke() {
  run_publicabi_smoke || return $?
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
  run_tests --suite=TTestCase_VecI32x8 || return $?
  check_heap_leaks || return $?
  run_tests --suite=TTestCase_VecU32x8 || return $?
  check_heap_leaks || return $?
  run_tests --suite=TTestCase_VecF64x4 || return $?
  check_heap_leaks || return $?
}

gate_step_cross_backend_parity() {
  run_tests --suite=TTestCase_DispatchAPI || return $?
  check_heap_leaks || return $?
  run_tests --suite=TTestCase_DirectDispatch || return $?
  check_heap_leaks || return $?
}

gate_step_nonx86_ieee754() {
  run_nonx86_ieee754 || return $?
}

gate_step_cpuinfo_portable() {
  local LTestsRoot

  local LCpuinfoOutputRoot

  LTestsRoot="${1}"
  LCpuinfoOutputRoot="$(cpuinfo_output_root "${LTestsRoot}")"
  SIMD_OUTPUT_ROOT="${LCpuinfoOutputRoot}" bash "${LTestsRoot}/fafafa.core.simd.cpuinfo/BuildOrTest.sh" test --list-suites || return $?
  SIMD_OUTPUT_ROOT="${LCpuinfoOutputRoot}" bash "${LTestsRoot}/fafafa.core.simd.cpuinfo/BuildOrTest.sh" test --suite=TTestCase_PlatformSpecific || return $?
}

gate_step_cpuinfo_lazy_repeat() {
  local LTestsRoot
  local LRounds

  LTestsRoot="${1}"
  LRounds="${SIMD_GATE_CPUINFO_LAZY_REPEAT:-0}"
  if ! [[ "${LRounds}" =~ ^[1-9][0-9]*$ ]]; then
    echo "[GATE] Invalid SIMD_GATE_CPUINFO_LAZY_REPEAT: ${LRounds} (expect positive integer)"
    return 2
  fi

  run_cpuinfo_lazy_repeat "${LTestsRoot}" "${LRounds}" || return $?
}

gate_step_cpuinfo_x86() {
  local LTestsRoot

  local LCpuinfoX86OutputRoot

  LTestsRoot="${1}"
  LCpuinfoX86OutputRoot="$(cpuinfo_x86_output_root "${LTestsRoot}")"
  SIMD_OUTPUT_ROOT="${LCpuinfoX86OutputRoot}" bash "${LTestsRoot}/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh" test --list-suites || return $?
  SIMD_OUTPUT_ROOT="${LCpuinfoX86OutputRoot}" bash "${LTestsRoot}/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh" test --suite=TTestCase_Global || return $?
}

gate_step_filtered_run_all() {
  local LTestsRoot

  LTestsRoot="${1}"
  RUN_ACTION=check STOP_ON_FAIL=1 bash "${LTestsRoot}/run_all_tests.sh" \
    '=fafafa.core.simd' \
    '=fafafa.core.simd.cpuinfo' \
    '=fafafa.core.simd.cpuinfo.x86' \
    '=fafafa.core.simd.intrinsics.sse' \
    '=fafafa.core.simd.intrinsics.mmx'
}

gate_step_concurrent_repeat() {
  local LRounds

  LRounds="${SIMD_GATE_CONCURRENT_REPEAT:-10}"
  run_suite_repeat "TTestCase_SimdConcurrent" "${LRounds}" || return $?
}

gate_step_qemu_nonx86_evidence() {
  run_qemu_multiarch "nonx86-evidence" || return $?
}

gate_step_qemu_cpuinfo_nonx86_evidence() {
  run_qemu_multiarch "cpuinfo-nonx86-evidence" || return $?
}

gate_step_qemu_cpuinfo_nonx86_full_evidence() {
  run_qemu_multiarch "cpuinfo-nonx86-full-evidence" || return $?
}

gate_step_qemu_cpuinfo_nonx86_full_repeat() {
  run_qemu_multiarch "cpuinfo-nonx86-full-repeat" || return $?
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
    echo "[WIRING-SYNC] FAILED (python3 runtime not found; wiring-sync requires python3)"
    return 2
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
  local -a LPerfArgs

  build_project || return $?

  LPerfArgs=(--bench-only)
  if [[ "${SIMD_PERF_VECTOR_ASM:-auto}" != "0" ]]; then
    if [[ "${SIMD_PERF_VECTOR_ASM:-auto}" == "1" || "${TARGET_CPU}" == "x86_64" || "${TARGET_CPU}" == "amd64" ]]; then
      LPerfArgs+=(--vector-asm)
    fi
  fi

  echo "[PERF] Args: ${LPerfArgs[*]}"
  run_tests "${LPerfArgs[@]}" || return $?
  check_heap_leaks || return $?
  check_perf_log || return $?
}

run_nonx86_ieee754() {
  build_project || return $?
  run_tests --list-suites || return $?
  if ! grep -q "TTestCase_NonX86IEEE754" "${TEST_LOG}"; then
    echo "[NONX86-IEEE754] SKIP (suite TTestCase_NonX86IEEE754 not present in this build)"
    return 0
  fi
  run_tests --suite=TTestCase_NonX86IEEE754 || return $?
  check_heap_leaks || return $?
}

run_nonx86_optin_list_suites_one() {
  local aBackend
  local aEnvVar
  local LOutputRoot

  aBackend="${1:-}"
  aEnvVar="${2:-}"
  if [[ -z "${aBackend}" || -z "${aEnvVar}" ]]; then
    echo "[NONX86-OPTIN] Missing backend/env selector"
    return 2
  fi

  LOutputRoot="$(nonx86_optin_output_root "${aBackend}")"
  echo "[NONX86-OPTIN] ${aBackend}: test --list-suites"
  env "${aEnvVar}=1" SIMD_OUTPUT_ROOT="${LOutputRoot}" bash "${ROOT}/BuildOrTest.sh" test --list-suites || return $?
}

run_nonx86_optin_list_suites() {
  run_nonx86_optin_list_suites_one "neon" "SIMD_ENABLE_NEON_BACKEND" || return $?
  run_nonx86_optin_list_suites_one "riscvv" "SIMD_ENABLE_RISCVV_BACKEND" || return $?
}

run_backend_bench() {
  local LBenchScript
  LBenchScript="${ROOT}/run_backend_benchmarks.sh"

  if [[ ! -f "${LBenchScript}" ]]; then
    echo "[BENCH] Missing script: ${LBenchScript}"
    return 2
  fi

  bash "${LBenchScript}" "$@"
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

  if [[ ! -f "${LScript}" ]]; then
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
    echo "[QEMU-EXPERIMENTAL-REPORT] FAILED (python3 runtime not found; qemu-experimental-report requires python3)"
    return 2
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
    echo "[QEMU-EXPERIMENTAL-BASELINE] FAILED (python3 runtime not found; qemu-experimental-baseline-check requires python3)"
    return 2
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

require_release_gate_prereqs() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "[GATE] Missing python3 required by release-gate"
    return 2
  fi

  if [[ "${SIMD_GATE_EXPERIMENTAL_TESTS:-0}" != "0" ]] && ! command -v bash >/dev/null 2>&1; then
    echo "[GATE] Missing bash required by release-gate experimental test runner"
    return 2
  fi
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
  local LGateInterfaceCompleteness
  local LGateContractSignature
  local LGatePublicAbiSignature
  local LGatePublicAbiSmoke
  local LGateAdapterSyncPascal
  local LGateAdapterSync
  local LCpuinfoArtifactsRoot
  local LCpuinfoX86ArtifactsRoot
  local LGateParitySuites
  local LGateWiringSync
  local LGateCoverage
  local LGateProfile
  local LEvidenceLog
  local LPublicAbiArtifactsRoot
  local LExperimentalIntrinsicsArtifactsRoot
  local LEvidenceStartMs
  local LEvidenceEndMs
  local LEvidenceDurationMs
  local LEvidenceEvent
  local LEvidenceRC

  LTestsRoot="$(cd "${ROOT}/.." && pwd)"
  LCpuinfoArtifactsRoot="$(cpuinfo_output_root "${LTestsRoot}")"
  LCpuinfoX86ArtifactsRoot="$(cpuinfo_x86_output_root "${LTestsRoot}")"
  LPublicAbiArtifactsRoot="$(publicabi_output_root "${LTestsRoot}")"
  LExperimentalIntrinsicsArtifactsRoot="$(experimental_intrinsics_output_root "${LTestsRoot}")"
  LRunAllLogDir="${LTestsRoot}/_run_all_logs_sh"
  LRunAllSummary="${LTestsRoot}/run_all_tests_summary_sh.txt"
  LGateStartMs="$(now_ms)"
  LGateInterfaceCompleteness="${SIMD_GATE_INTERFACE_COMPLETENESS:-1}"
  LGateContractSignature="${SIMD_GATE_CONTRACT_SIGNATURE:-1}"
  LGatePublicAbiSignature="${SIMD_GATE_PUBLICABI_SIGNATURE:-1}"
  LGatePublicAbiSmoke="${SIMD_GATE_PUBLICABI_SMOKE:-1}"
  LGateAdapterSyncPascal="${SIMD_GATE_ADAPTER_SYNC_PASCAL:-1}"
  LGateAdapterSync="${SIMD_GATE_ADAPTER_SYNC:-1}"
  LGateParitySuites="${SIMD_GATE_PARITY_SUITES:-1}"
  LGateWiringSync="${SIMD_GATE_WIRING_SYNC:-1}"
  LGateCoverage="${SIMD_GATE_COVERAGE:-1}"
  LGateProfile="${SIMD_GATE_PROFILE:-fast-gate}"
  LEvidenceLog="${ROOT}/logs/windows_b07_gate.log"

  if [[ "${SIMD_GATE_SUMMARY_APPEND:-0}" == "0" ]]; then
    reset_gate_summary
  fi

  append_gate_summary "gate" "START" "profile=${LGateProfile}; mode=${MODE}; interface-completeness=${LGateInterfaceCompleteness}; contract-signature=${LGateContractSignature}; publicabi-signature=${LGatePublicAbiSignature}; publicabi-smoke=${LGatePublicAbiSmoke}; adapter-sync-pascal=${LGateAdapterSyncPascal}; adapter-sync=${LGateAdapterSync}; parity-suites=${LGateParitySuites}; wiring=${LGateWiringSync}; coverage=${LGateCoverage}; perf=${SIMD_GATE_PERF_SMOKE:-0}; experimental=${SIMD_GATE_EXPERIMENTAL:-1}; experimental-tests=${SIMD_GATE_EXPERIMENTAL_TESTS:-0}; nonx86-ieee754=${SIMD_GATE_NONX86_IEEE754:-0}; cpuinfo-lazy-repeat=${SIMD_GATE_CPUINFO_LAZY_REPEAT:-0}; qemu-nonx86-evidence=${SIMD_GATE_QEMU_NONX86_EVIDENCE:-0}; qemu-cpuinfo-nonx86-evidence=${SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE:-0}; qemu-cpuinfo-nonx86-full-evidence=${SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE:-0}; qemu-cpuinfo-nonx86-full-repeat=${SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT:-0}; qemu-arch-matrix=${SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE:-0}; require-win-evidence=${SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE:-0}; concurrent-repeat=${SIMD_GATE_CONCURRENT_REPEAT:-0}" "-" "START" "${BUILD_LOG}; ${TEST_LOG}; ${SIMD_WIRING_SYNC_LOG_FILE:-${WIRING_SYNC_LOG}}"

  if [[ "${LGateProfile}" == "release-gate" ]]; then
    echo "[GATE] Profile: release-gate (发布/closeout 完整门禁)"
  else
    echo "[GATE] Profile: fast-gate (日常改动快门禁/基础门禁)"
  fi
  echo "[GATE] Experimental boundary: default entry chain keeps experimental intrinsics isolated."
  echo "[GATE] Note: gate/gate-strict PASS does not imply every experimental path is release-grade."

  echo "[GATE] 1/6 Build + check SIMD module"
  if ! run_gate_step "build-check" "build/check/parity passed" "see ${BUILD_LOG}" "${BUILD_LOG}" gate_step_build_check; then
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=build-check" "${LGateDurationMs}" "FAILED"
    return 1
  fi

  if [[ "${LGateInterfaceCompleteness}" != "0" ]]; then
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

  if [[ "${LGateContractSignature}" != "0" ]]; then
    echo "[GATE] Optional dispatch contract signature"
    if ! run_gate_step "contract-signature" "dispatch contract signature passed" "dispatch contract signature failed" "${SIMD_DISPATCH_CONTRACT_LOG_FILE:-${DISPATCH_CONTRACT_SIGNATURE_LOG}}; ${SIMD_DISPATCH_CONTRACT_JSON_FILE:-${DISPATCH_CONTRACT_SIGNATURE_JSON_LOG}}" gate_step_contract_signature; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=contract-signature" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "contract-signature" "SKIP" "SIMD_GATE_CONTRACT_SIGNATURE=0" "-" "SKIP" "${SIMD_DISPATCH_CONTRACT_LOG_FILE:-${DISPATCH_CONTRACT_SIGNATURE_LOG}}; ${SIMD_DISPATCH_CONTRACT_JSON_FILE:-${DISPATCH_CONTRACT_SIGNATURE_JSON_LOG}}"
  fi

  if [[ "${LGatePublicAbiSignature}" != "0" ]]; then
    echo "[GATE] Optional public ABI signature"
    if ! run_gate_step "publicabi-signature" "public ABI signature passed" "public ABI signature failed" "${SIMD_PUBLIC_ABI_LOG_FILE:-${PUBLIC_ABI_SIGNATURE_LOG}}; ${SIMD_PUBLIC_ABI_JSON_FILE:-${PUBLIC_ABI_SIGNATURE_JSON_LOG}}" gate_step_public_abi_signature; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=publicabi-signature" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "publicabi-signature" "SKIP" "SIMD_GATE_PUBLICABI_SIGNATURE=0" "-" "SKIP" "${SIMD_PUBLIC_ABI_LOG_FILE:-${PUBLIC_ABI_SIGNATURE_LOG}}; ${SIMD_PUBLIC_ABI_JSON_FILE:-${PUBLIC_ABI_SIGNATURE_JSON_LOG}}"
  fi

  if [[ "${LGatePublicAbiSmoke}" != "0" ]]; then
    echo "[GATE] Optional public ABI smoke"
    if ! run_gate_step "publicabi-smoke" "public ABI smoke passed" "public ABI smoke failed" "${LPublicAbiArtifactsRoot}/logs/test.txt" gate_step_publicabi_smoke; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=publicabi-smoke" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "publicabi-smoke" "SKIP" "SIMD_GATE_PUBLICABI_SMOKE=0" "-" "SKIP" "${LPublicAbiArtifactsRoot}/logs/test.txt"
  fi

  if [[ "${LGateAdapterSyncPascal}" != "0" ]]; then
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

  if [[ "${LGateAdapterSync}" != "0" ]]; then
    echo "[GATE] Optional backend adapter sync"
    if [[ "${LGateAdapterSyncPascal}" != "0" ]]; then
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

  if [[ "${LGateWiringSync}" != "0" ]]; then
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

  if [[ "${LGateParitySuites}" != "0" ]]; then
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
  if ! run_gate_step "cpuinfo-portable" "list + platform-specific passed" "cpuinfo portable suite failed" "${LCpuinfoArtifactsRoot}/logs/test.txt" gate_step_cpuinfo_portable "${LTestsRoot}"; then
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=cpuinfo-portable" "${LGateDurationMs}" "FAILED"
    return 1
  fi

  if [[ "${SIMD_GATE_CPUINFO_LAZY_REPEAT:-0}" != "0" ]]; then
    echo "[GATE] Optional cpuinfo lazy repeat (${SIMD_GATE_CPUINFO_LAZY_REPEAT} rounds)"
    if ! run_gate_step "cpuinfo-lazy-repeat" "cpuinfo lazy suite repeat passed; rounds=${SIMD_GATE_CPUINFO_LAZY_REPEAT}" "cpuinfo lazy suite repeat failed; rounds=${SIMD_GATE_CPUINFO_LAZY_REPEAT}" "${LCpuinfoArtifactsRoot}/logs/repeat.TTestCase_LazyCPUInfo.*.txt" gate_step_cpuinfo_lazy_repeat "${LTestsRoot}"; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=cpuinfo-lazy-repeat" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "cpuinfo-lazy-repeat" "SKIP" "SIMD_GATE_CPUINFO_LAZY_REPEAT=0" "-" "SKIP" "${LCpuinfoArtifactsRoot}/logs/repeat.TTestCase_LazyCPUInfo.*.txt"
  fi

  echo "[GATE] 5/6 CPUInfo x86 suites"
  if ! run_gate_step "cpuinfo-x86" "list + global passed" "cpuinfo x86 suite failed" "${LCpuinfoX86ArtifactsRoot}/logs/test.txt" gate_step_cpuinfo_x86 "${LTestsRoot}"; then
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=cpuinfo-x86" "${LGateDurationMs}" "FAILED"
    return 1
  fi

  echo "[GATE] 6/6 Filtered run_all check chain"
  if ! run_gate_step "run-all-chain" "filtered run_all check passed; logs=${LRunAllLogDir}; summary=${LRunAllSummary}" "run_all check chain failed; logs=${LRunAllLogDir}; summary=${LRunAllSummary}" "${LRunAllLogDir}; ${LRunAllSummary}" gate_step_filtered_run_all "${LTestsRoot}"; then
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
    if ! run_gate_step "experimental-tests" "experimental test-all passed" "experimental test-all failed" "${LExperimentalIntrinsicsArtifactsRoot}" run_experimental_intrinsics_tests; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=experimental-tests" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "experimental-tests" "SKIP" "SIMD_GATE_EXPERIMENTAL_TESTS=0" "-" "SKIP" "${LExperimentalIntrinsicsArtifactsRoot}"
  fi

  if [[ "${LGateCoverage}" != "0" ]]; then
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

  if [[ "${SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE:-0}" != "0" ]]; then
    echo "[GATE] Optional qemu cpuinfo non-x86 evidence"
    if ! run_gate_step "qemu-cpuinfo-nonx86-evidence" "qemu cpuinfo non-x86 evidence passed" "qemu cpuinfo non-x86 evidence failed" "${ROOT}/logs/qemu-multiarch-*" gate_step_qemu_cpuinfo_nonx86_evidence; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=qemu-cpuinfo-nonx86-evidence" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "qemu-cpuinfo-nonx86-evidence" "SKIP" "SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=0" "-" "SKIP" "${ROOT}/logs/qemu-multiarch-*"
  fi

  if [[ "${SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE:-0}" != "0" ]]; then
    echo "[GATE] Optional qemu cpuinfo non-x86 full evidence"
    if ! run_gate_step "qemu-cpuinfo-nonx86-full-evidence" "qemu cpuinfo non-x86 full evidence passed" "qemu cpuinfo non-x86 full evidence failed" "${ROOT}/logs/qemu-multiarch-*" gate_step_qemu_cpuinfo_nonx86_full_evidence; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=qemu-cpuinfo-nonx86-full-evidence" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "qemu-cpuinfo-nonx86-full-evidence" "SKIP" "SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0" "-" "SKIP" "${ROOT}/logs/qemu-multiarch-*"
  fi

  if [[ "${SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT:-0}" != "0" ]]; then
    echo "[GATE] Optional qemu cpuinfo non-x86 full repeat"
    if ! run_gate_step "qemu-cpuinfo-nonx86-full-repeat" "qemu cpuinfo non-x86 full repeat passed" "qemu cpuinfo non-x86 full repeat failed" "${ROOT}/logs/qemu-multiarch-*" gate_step_qemu_cpuinfo_nonx86_full_repeat; then
      LGateEndMs="$(now_ms)"
      LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
      append_gate_summary "gate" "FAIL" "failed-step=qemu-cpuinfo-nonx86-full-repeat" "${LGateDurationMs}" "FAILED"
      return 1
    fi
  else
    append_gate_summary "qemu-cpuinfo-nonx86-full-repeat" "SKIP" "SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0" "-" "SKIP" "${ROOT}/logs/qemu-multiarch-*"
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
  if [[ -f "${LEvidenceLog}" ]]; then
    if [[ "${SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE:-0}" != "0" ]]; then
      if ! run_gate_step "evidence-verify" "verify passed" "verify-win-evidence failed" "${LEvidenceLog}" gate_step_evidence_verify; then
        LGateEndMs="$(now_ms)"
        LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
        append_gate_summary "gate" "FAIL" "failed-step=evidence-verify" "${LGateDurationMs}" "FAILED"
        return 1
      fi
    else
      LEvidenceStartMs="$(now_ms)"
      if gate_step_evidence_verify; then
        LEvidenceEndMs="$(now_ms)"
        LEvidenceDurationMs="$(( LEvidenceEndMs - LEvidenceStartMs ))"
        LEvidenceEvent="$(gate_step_event "${LEvidenceDurationMs}")"
        append_gate_summary "evidence-verify" "PASS" "verify passed" "${LEvidenceDurationMs}" "${LEvidenceEvent}" "${LEvidenceLog}"
      else
        LEvidenceRC=$?
        LEvidenceEndMs="$(now_ms)"
        LEvidenceDurationMs="$(( LEvidenceEndMs - LEvidenceStartMs ))"
        append_gate_summary "evidence-verify" "SKIP" "optional evidence verify failed rc=${LEvidenceRC}; set SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 to enforce fail-close" "${LEvidenceDurationMs}" "SKIP" "${LEvidenceLog}"
        echo "[GATE] SKIP optional evidence verify (rc=${LEvidenceRC}; set SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 to enforce)"
      fi
    fi
  elif [[ "${SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE:-0}" != "0" ]]; then
    append_gate_summary "evidence-verify" "FAIL" "required windows evidence log missing: ${LEvidenceLog}" "-" "FAILED" "${LEvidenceLog}"
    LGateEndMs="$(now_ms)"
    LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
    append_gate_summary "gate" "FAIL" "failed-step=evidence-verify" "${LGateDurationMs}" "FAILED"
    return 1
  else
    echo "[GATE] SKIP evidence verify (windows log not present: ${LEvidenceLog})"
    append_gate_summary "evidence-verify" "SKIP" "windows evidence log missing (optional in gate)" "-" "SKIP" "${LEvidenceLog}"
  fi

  LGateEndMs="$(now_ms)"
  LGateDurationMs="$(( LGateEndMs - LGateStartMs ))"
  LGateEvent="$(gate_step_event "${LGateDurationMs}")"
  append_gate_summary "gate" "PASS" "all steps passed" "${LGateDurationMs}" "${LGateEvent}"
  echo "[GATE] OK"
}

run_gate_strict() {
  echo "[GATE] Running gate-strict as release-gate profile"
  echo "[GATE] Note: release-gate adds stronger evidence, but experimental paths still keep a separate maturity boundary"
  require_release_gate_prereqs || return $?
  SIMD_GATE_INTERFACE_COMPLETENESS=1 \
  SIMD_GATE_CONTRACT_SIGNATURE=1 \
  SIMD_GATE_PUBLICABI_SIGNATURE=1 \
  SIMD_GATE_PUBLICABI_SMOKE=1 \
  SIMD_GATE_ADAPTER_SYNC_PASCAL=1 \
  SIMD_GATE_ADAPTER_SYNC=1 \
  SIMD_GATE_PARITY_SUITES=1 \
  SIMD_GATE_WIRING_SYNC=1 \
  SIMD_WIRING_SYNC_STRICT_EXTRA=1 \
  SIMD_GATE_COVERAGE=1 \
  SIMD_COVERAGE_STRICT_EXTRA=1 \
  SIMD_COVERAGE_REQUIRE_AVX2=1 \
  SIMD_COVERAGE_REQUIRE_EXPERIMENTAL=1 \
  SIMD_GATE_PERF_SMOKE="${SIMD_GATE_PERF_SMOKE:-0}" \
  SIMD_GATE_EXPERIMENTAL=1 \
  SIMD_GATE_EXPERIMENTAL_TESTS="${SIMD_GATE_EXPERIMENTAL_TESTS:-1}" \
  SIMD_GATE_NONX86_IEEE754=1 \
  SIMD_GATE_CPUINFO_LAZY_REPEAT="${SIMD_GATE_CPUINFO_LAZY_REPEAT:-3}" \
  SIMD_GATE_QEMU_NONX86_EVIDENCE=0 \
  SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE="${SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE:-1}" \
  SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE="${SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE:-0}" \
  SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT="${SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT:-0}" \
  SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE="${SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE:-0}" \
  SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE="${SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE:-1}" \
  SIMD_QEMU_CPUINFO_REPEAT_ROUNDS="${SIMD_QEMU_CPUINFO_REPEAT_ROUNDS:-1}" \
  SIMD_GATE_CONCURRENT_REPEAT="${SIMD_GATE_CONCURRENT_REPEAT:-10}" \
  SIMD_GATE_PROFILE=release-gate \
  run_gate
}

write_gate_summary_json() {
  local LSummaryFile
  local LJsonFile
  local LSummaryFilter

  LSummaryFile="${1}"
  LJsonFile="${2}"
  LSummaryFilter="${3}"

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[GATE-SUMMARY] FAILED (python3 runtime not found; SIMD_GATE_SUMMARY_JSON=1 requires python3)"
    return 2
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
      if (LFilter == "SLOW" && (LEvent == "SLOW_WARN" || LEvent == "SLOW_CRIT" || LEvent == "SLOW_FAIL")) { print $0; next }
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
    write_gate_summary_json "${LSummaryFile}" "${LJsonFile}" "${LSummaryFilter}" || return $?
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
  if [[ ! -f "${LRehearsalScript}" ]]; then
    echo "[GATE-SUMMARY-REHEARSAL] Missing script: ${LRehearsalScript}"
    return 2
  fi

  bash "${LRehearsalScript}" "$@"
}

run_gate_summary_inject() {
  local LInjectScript

  LInjectScript="${GATE_SUMMARY_INJECT_SCRIPT:-${ROOT}/inject_gate_summary_sample.sh}"
  if [[ ! -f "${LInjectScript}" ]]; then
    echo "[GATE-SUMMARY-INJECT] Missing script: ${LInjectScript}"
    return 2
  fi

  bash "${LInjectScript}" "$@"
}

run_gate_summary_rollback() {
  local LRollbackScript

  LRollbackScript="${GATE_SUMMARY_ROLLBACK_SCRIPT:-${ROOT}/rollback_gate_summary_sample.sh}"
  if [[ ! -f "${LRollbackScript}" ]]; then
    echo "[GATE-SUMMARY-ROLLBACK] Missing script: ${LRollbackScript}"
    return 2
  fi

  bash "${LRollbackScript}" "$@"
}

run_gate_summary_backups() {
  local LBackupsScript

  LBackupsScript="${GATE_SUMMARY_BACKUPS_SCRIPT:-${ROOT}/list_gate_summary_backups.sh}"
  if [[ ! -f "${LBackupsScript}" ]]; then
    echo "[GATE-SUMMARY-BACKUPS] Missing script: ${LBackupsScript}"
    return 2
  fi

  bash "${LBackupsScript}" "$@"
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

  if ! run_freeze_status_rehearsal >/dev/null; then
    echo "[GATE-SUMMARY-SELFCHECK] FAILED: freeze-status-rehearsal"
    rm -f "${LTmpJson}"
    return 1
  fi

  rm -f "${LTmpJson}"
  echo "[GATE-SUMMARY-SELFCHECK] OK"
}

run_evidence_linux() {
  local LEvidenceScript

  LEvidenceScript="${ROOT}/collect_linux_simd_evidence.sh"

  if [[ ! -f "${LEvidenceScript}" ]]; then
    echo "[EVIDENCE] Missing collector: ${LEvidenceScript}"
    return 2
  fi

  bash "${LEvidenceScript}" "$@"
}

verify_windows_evidence() {
  local LEvidenceVerifier

  LEvidenceVerifier="${ROOT}/verify_windows_b07_evidence.sh"

  if [[ ! -f "${LEvidenceVerifier}" ]]; then
    echo "[CHECK] Missing evidence verifier: ${LEvidenceVerifier}"
    return 2
  fi

  bash "${LEvidenceVerifier}" "$@"
}

finalize_windows_evidence() {
  local LCloseoutScript

  LCloseoutScript="${ROOT}/finalize_windows_b07_closeout.sh"

  if [[ ! -f "${LCloseoutScript}" ]]; then
    echo "[CLOSEOUT] Missing closeout script: ${LCloseoutScript}"
    return 2
  fi

  bash "${LCloseoutScript}" "$@"
}

run_windows_closeout_dryrun() {
  local LSimScript
  local LSimLog
  local LApplyScript
  local LSimSummary

  LSimScript="${ROOT}/simulate_windows_b07_evidence.sh"
  if [[ ! -f "${LSimScript}" ]]; then
    echo "[CLOSEOUT] Missing simulator: ${LSimScript}"
    return 2
  fi

  LApplyScript="${ROOT}/apply_windows_b07_closeout_updates.sh"
  if [[ ! -f "${LApplyScript}" ]]; then
    echo "[CLOSEOUT] Missing updater: ${LApplyScript}"
    return 2
  fi

  LSimLog="${ROOT}/logs/windows_b07_gate.simulated.log"
  LSimSummary="${ROOT}/logs/windows_b07_closeout_summary.simulated.md"

  bash "${LSimScript}" "${LSimLog}"
  if verify_windows_evidence "${LSimLog}" >/dev/null 2>&1; then
    echo "[CLOSEOUT] DRYRUN FAILED: simulated log unexpectedly passed default verifier"
    return 1
  fi

  verify_windows_evidence --allow-simulated "${LSimLog}" || return $?
  finalize_windows_evidence "${LSimLog}" "${LSimSummary}" --allow-simulated >/dev/null || return $?

  if bash "${LApplyScript}" "${LSimSummary}" --apply; then
    echo "[CLOSEOUT] DRYRUN FAILED: simulated summary unexpectedly passed apply gate"
    return 1
  fi

  echo "[CLOSEOUT] DRYRUN OK: simulated summary stayed preview-only"
}

windows_closeout_snippets() {
  local LApplyScript

  LApplyScript="${ROOT}/apply_windows_b07_closeout_updates.sh"
  if [[ ! -f "${LApplyScript}" ]]; then
    echo "[CLOSEOUT] Missing updater: ${LApplyScript}"
    return 2
  fi

  bash "${LApplyScript}" "$@"
}

print_windows_closeout_3cmd() {
  local LThreeCmdScript

  LThreeCmdScript="${WIN_CLOSEOUT_3CMD_SCRIPT:-${ROOT}/print_windows_b07_closeout_3cmd.sh}"
  if [[ ! -f "${LThreeCmdScript}" ]]; then
    echo "[CLOSEOUT] Missing 3cmd helper: ${LThreeCmdScript}"
    return 2
  fi

  bash "${LThreeCmdScript}" "$@"
}

run_freeze_status() {
  local LFreezeScript
  local LJsonPath
  local LGateSummaryFile

  LFreezeScript="${FREEZE_STATUS_SCRIPT:-${ROOT}/evaluate_simd_freeze_status.py}"
  if [[ ! -f "${LFreezeScript}" ]]; then
    echo "[FREEZE] Missing status script: ${LFreezeScript}"
    return 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[FREEZE] Missing python3"
    return 2
  fi

  LJsonPath="${SIMD_FREEZE_STATUS_JSON_FILE:-${LOG_DIR}/freeze_status.json}"
  LGateSummaryFile="${SIMD_FREEZE_GATE_SUMMARY_FILE:-${SIMD_GATE_SUMMARY_FILE:-${GATE_SUMMARY_LOG}}}"
  SIMD_FREEZE_GATE_SUMMARY_FILE="${LGateSummaryFile}" \
    python3 "${LFreezeScript}" --root "${ROOT}" --json-file "${LJsonPath}" "$@"
}

run_windows_closeout_finalize() {
  local LFinalizeScript

  LFinalizeScript="${WIN_CLOSEOUT_FINALIZE_SCRIPT:-${ROOT}/run_windows_b07_closeout_finalize.sh}"
  if [[ ! -f "${LFinalizeScript}" ]]; then
    echo "[CLOSEOUT] Missing finalize helper: ${LFinalizeScript}"
    return 2
  fi

  bash "${LFinalizeScript}" "$@"
}

run_freeze_status_rehearsal() {
  local LRehearsalScript

  LRehearsalScript="${FREEZE_REHEARSAL_SCRIPT:-${ROOT}/rehearse_freeze_status.sh}"
  if [[ ! -f "${LRehearsalScript}" ]]; then
    echo "[FREEZE-REHEARSAL] Missing script: ${LRehearsalScript}"
    return 2
  fi

  bash "${LRehearsalScript}" "$@"
}

run_win_evidence_preflight() {
  local LPreflightScript

  LPreflightScript="${WIN_EVIDENCE_PREFLIGHT_SCRIPT:-${ROOT}/preflight_windows_b07_evidence_gh.sh}"
  if [[ ! -f "${LPreflightScript}" ]]; then
    echo "[PREFLIGHT] Missing script: ${LPreflightScript}"
    return 2
  fi

  bash "${LPreflightScript}" "$@"
}

run_win_evidence_via_gh() {
  local LViaGHScript

  LViaGHScript="${WIN_EVIDENCE_VIA_GH_SCRIPT:-${ROOT}/run_windows_b07_closeout_via_github_actions.sh}"
  if [[ ! -f "${LViaGHScript}" ]]; then
    echo "[WIN-EVIDENCE-GH] Missing script: ${LViaGHScript}"
    return 2
  fi

  bash "${LViaGHScript}" "$@"
}

case "${ACTION}" in
  clean)
    run_clean
    ;;
  build)
    build_project
    ;;
  check)
    build_project
  check_build_log
  check_windows_runner_parity
  check_avx512_optin_runner_guard
  check_nonx86_optin_runner_guard
  check_windows_experimental_tests_runner_guard
  check_windows_experimental_direct_runner_guard
  check_windows_publicabi_runner_guard
  check_windows_evidence_collector_guard
  check_windows_simulated_evidence_guard
  check_windows_gate_summary_helper_guard
  check_windows_manual_closeout_guard
  check_windows_closeout_helper_runtime_guard
  check_gate_summary_json_runtime_guard
  check_perf_smoke_scalar_guard
  check_perf_smoke_public_abi_shape_guard
  check_windows_qemu_runner_guard
  check_windows_bash_helper_runner_guard
  check_qemu_experimental_python_helper_guard
  check_python_checker_runtime_guard
    check_publicabi_output_isolation
    check_publicabi_shell_export_guard
    check_isolated_clean_coverage
    check_run_all_output_isolation
    check_intrinsics_runner_output_isolation
    check_experimental_intrinsics_output_isolation
    check_linux_evidence_output_isolation
    check_freeze_status_output_isolation
    check_cpuinfo_runner_parity
    run_register_include_check
    run_suite_manifest_check
    run_nonx86_optin_list_suites
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
    if [[ "${SIMD_RELEASE_STRICT_GATE:-1}" != "0" ]]; then
      echo "[RELEASE] Running strict gate (set SIMD_RELEASE_STRICT_GATE=0 to skip)"
      run_gate_strict
    else
      echo "[RELEASE] SKIP strict gate (SIMD_RELEASE_STRICT_GATE=0)"
    fi
    ;;
  test)
    build_project
    run_tests "$@"
    check_heap_leaks
    ;;
  test-concurrent-repeat)
    run_suite_repeat "TTestCase_SimdConcurrent" "${1:-${SIMD_CONCURRENT_REPEAT_ROUNDS:-10}}"
    ;;
  cpuinfo-lazy-repeat)
    run_cpuinfo_lazy_repeat_action "${1:-${SIMD_CPUINFO_LAZY_REPEAT_ROUNDS:-5}}"
    ;;
  gate)
    echo "[GATE] Running fast-gate profile (日常改动/基础门禁)"
    run_gate
    ;;
  gate-strict)
    echo "[GATE] Running release-gate profile (发布/closeout 完整门禁)"
    run_gate_strict
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
  nonx86-optin-list-suites)
    run_nonx86_optin_list_suites
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
  qemu-cpuinfo-nonx86-evidence)
    run_qemu_multiarch cpuinfo-nonx86-evidence "$@"
    ;;
  qemu-cpuinfo-nonx86-full-evidence)
    run_qemu_multiarch cpuinfo-nonx86-full-evidence "$@"
    ;;
  qemu-cpuinfo-nonx86-full-repeat)
    run_qemu_multiarch cpuinfo-nonx86-full-repeat "$@"
    ;;
  qemu-cpuinfo-nonx86-suite-repeat)
    run_qemu_multiarch cpuinfo-nonx86-suite-repeat "$@"
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
  contract-signature)
    run_dispatch_contract_signature
    ;;
  publicabi-signature)
    run_public_abi_signature
    ;;
  publicabi-smoke)
    run_publicabi_smoke
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
  win-evidence-preflight)
    run_win_evidence_preflight "$@"
    ;;
  win-evidence-via-gh)
    run_win_evidence_via_gh "$@"
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
    echo "Usage: $0 [clean|build|check|test|test-concurrent-repeat|cpuinfo-lazy-repeat|debug|release|gate|gate-strict|interface-completeness|contract-signature|publicabi-signature|publicabi-smoke|adapter-sync-pascal|adapter-sync|parity-suites|gate-summary|gate-summary-sample|gate-summary-rehearsal|gate-summary-inject|gate-summary-rollback|gate-summary-backups|gate-summary-selfcheck|perf-smoke|nonx86-optin-list-suites|nonx86-ieee754|backend-bench|qemu-nonx86-evidence|qemu-cpuinfo-nonx86-evidence|qemu-cpuinfo-nonx86-full-evidence|qemu-cpuinfo-nonx86-full-repeat|qemu-cpuinfo-nonx86-suite-repeat|qemu-arch-matrix-evidence|qemu-nonx86-experimental-asm|riscvv-opcode-lane|qemu-experimental-report|qemu-experimental-baseline-check|coverage|wiring-sync|experimental-intrinsics|experimental-intrinsics-tests|evidence-linux|win-evidence-preflight|win-evidence-via-gh|verify-win-evidence|finalize-win-evidence|win-closeout-dryrun|win-closeout-snippets|win-closeout-3cmd|freeze-status|freeze-status-linux|win-closeout-finalize|freeze-status-rehearsal] [test-args...]"
    echo "  Experimental note: default entry chain isolates experimental intrinsics behind dedicated checks."
    echo "  gate/gate-strict PASS is not blanket release-grade approval for every experimental path."
    echo "  gate         Fast/base gate for routine SIMD changes"
    echo "  gate-strict  Release/closeout gate with perf, repeats, and evidence checks"
    echo "Suggested flow: check -> targeted suites -> gate; use gate-strict before release/closeout."
    echo "QEMU env: SIMD_QEMU_BUILD_POLICY=always|if-missing|skip (default: if-missing)"
    echo "Isolation env: SIMD_OUTPUT_ROOT=/tmp/simd-run-123 (override bin2/lib2/logs root)"
    echo "Build env: SIMD_ENABLE_NEON_BACKEND=1 (compile NEON backend into the test binary for opt-in verification/fallback coverage)"
    echo "Build env: SIMD_ENABLE_RISCVV_BACKEND=1 (compile RISCV-V backend into the test binary for opt-in verification/fallback coverage)"
    echo "Build env: SIMD_ENABLE_AVX512_BACKEND=1 (compile AVX-512 backend into the test binary for opt-in verification)"
    exit 2
    ;;
esac
