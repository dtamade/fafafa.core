#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${SCRIPT_DIR}/logs/backend-bench-${TS}"
BIN_DIR="${OUT_DIR}/bin"
LIB_DIR="${OUT_DIR}/lib"
SUMMARY_FILE="${OUT_DIR}/summary.md"
RUNNER_LOG="${OUT_DIR}/runner.log"
HOST_ARCH="$(uname -m)"

mkdir -p "${BIN_DIR}" "${LIB_DIR}"

FPC_BIN="${FPC:-fpc}"
if ! command -v "${FPC_BIN}" >/dev/null 2>&1; then
  echo "[BENCH] SKIP (fpc not found)" | tee "${RUNNER_LOG}"
  exit 0
fi

BENCH_FPC_EXTRA_DEFINES_STRING="${SIMD_BENCH_FPC_EXTRA_DEFINES:-}"
BENCH_FPC_EXTRA_ARGS_STRING="${SIMD_BENCH_FPC_EXTRA_ARGS:-}"
BENCH_FPC_EXTRA_DEFINES=()
BENCH_FPC_EXTRA_ARGS=()

if [[ -n "${BENCH_FPC_EXTRA_DEFINES_STRING}" ]]; then
  read -r -a BENCH_FPC_EXTRA_DEFINES <<< "${BENCH_FPC_EXTRA_DEFINES_STRING}"
fi
if [[ -n "${BENCH_FPC_EXTRA_ARGS_STRING}" ]]; then
  read -r -a BENCH_FPC_EXTRA_ARGS <<< "${BENCH_FPC_EXTRA_ARGS_STRING}"
fi

should_skip_compile_failure() {
  local aName="$1"
  local aBuildLog="$2"

  if [[ ! -f "${aBuildLog}" ]]; then
    return 1
  fi

  case "${aName}" in
    AVX512_vs_AVX2)
      if grep -Eq 'Unrecognized opcode|Assembler syntax error|Unknown identifier "ZMM|Unknown identifier "K1"' "${aBuildLog}" && \
         grep -Eq 'fafafa\.core\.simd\.avx512|avx512\.facade\.inc' "${aBuildLog}"; then
        return 0
      fi
      ;;
  esac

  return 1
}

run_one() {
  local aSource="$1"
  local aName="$2"
  local LBase
  local LBuildLog
  local LRunLog
  local LBinary
  local LBuildRc
  local LRunRc

  LBase="${aSource%.lpr}"
  LBuildLog="${OUT_DIR}/${LBase}.build.log"
  LRunLog="${OUT_DIR}/${LBase}.run.log"
  LBinary="${BIN_DIR}/${LBase}"

  echo "[BENCH] >>> ${aName}" | tee -a "${RUNNER_LOG}"
  (
    cd "${SCRIPT_DIR}"
    "${FPC_BIN}" \
      -Mobjfpc -Sh -O3 \
      -Fi"${ROOT_DIR}/src" \
      -Fu"${ROOT_DIR}/src" \
      -Fu"${SCRIPT_DIR}" \
      -FE"${BIN_DIR}" \
      -FU"${LIB_DIR}" \
      "${BENCH_FPC_EXTRA_DEFINES[@]}" \
      "${BENCH_FPC_EXTRA_ARGS[@]}" \
      "${aSource}"
  ) >"${LBuildLog}" 2>&1 || LBuildRc=$?
  LBuildRc="${LBuildRc:-0}"

  if [[ "${LBuildRc}" -ne 0 ]]; then
    if should_skip_compile_failure "${aName}" "${LBuildLog}"; then
      echo "[BENCH] SKIP ${aName} (compiler does not support required backend opcodes)" | tee -a "${RUNNER_LOG}"
      tail -n 40 "${LBuildLog}" || true
      return 0
    fi
    echo "[BENCH] FAILED (compile rc=${LBuildRc}): ${aName}" | tee -a "${RUNNER_LOG}"
    tail -n 80 "${LBuildLog}" || true
    return "${LBuildRc}"
  fi

  if [[ ! -x "${LBinary}" && -x "${LBinary}.exe" ]]; then
    LBinary="${LBinary}.exe"
  fi
  if [[ ! -x "${LBinary}" ]]; then
    echo "[BENCH] FAILED (binary missing): ${aSource}" | tee -a "${RUNNER_LOG}"
    ls -la "${BIN_DIR}" || true
    return 1
  fi

  (
    cd "${OUT_DIR}"
    "${LBinary}"
  ) >"${LRunLog}" 2>&1 || LRunRc=$?
  LRunRc="${LRunRc:-0}"

  if grep -q '^\[SKIP\]' "${LRunLog}"; then
    echo "[BENCH] SKIP ${aName}" | tee -a "${RUNNER_LOG}"
  elif [[ "${LRunRc}" -ne 0 ]]; then
    echo "[BENCH] FAILED (run rc=${LRunRc}): ${aName}" | tee -a "${RUNNER_LOG}"
    tail -n 80 "${LRunLog}" || true
    return "${LRunRc}"
  else
    echo "[BENCH] PASS ${aName}" | tee -a "${RUNNER_LOG}"
  fi
}

declare -a TARGETS
if [[ "${SIMD_BENCH_ALL_BACKENDS:-0}" != "0" ]]; then
  TARGETS=(
    "bench_avx512_vs_avx2.lpr:AVX512_vs_AVX2:^(x86_64|amd64)$"
    "bench_neon_vs_scalar.lpr:NEON_vs_Scalar:^(aarch64|arm64)$"
    "bench_riscvv_vs_scalar.lpr:RISCVV_vs_Scalar:^riscv64$"
  )
else
  case "${HOST_ARCH}" in
    x86_64|amd64)
      TARGETS=("bench_avx512_vs_avx2.lpr:AVX512_vs_AVX2:^(x86_64|amd64)$")
      ;;
    aarch64|arm64)
      TARGETS=("bench_neon_vs_scalar.lpr:NEON_vs_Scalar:^(aarch64|arm64)$")
      ;;
    riscv64)
      TARGETS=("bench_riscvv_vs_scalar.lpr:RISCVV_vs_Scalar:^riscv64$")
      ;;
    *)
      TARGETS=()
      ;;
  esac
fi

if [[ "${#TARGETS[@]}" -eq 0 ]]; then
  echo "[BENCH] SKIP (no benchmark target for host arch: $(uname -m))" | tee "${RUNNER_LOG}"
  exit 0
fi

for LTarget in "${TARGETS[@]}"; do
  IFS=':' read -r LSource LName LHostRegex <<< "${LTarget}"
  if [[ "${SIMD_BENCH_FORCE_COMPILE:-0}" == "0" ]] && ! [[ "${HOST_ARCH}" =~ ${LHostRegex} ]]; then
    echo "[BENCH] SKIP ${LName} (host arch ${HOST_ARCH} does not match ${LHostRegex})" | tee -a "${RUNNER_LOG}"
    continue
  fi
  run_one "${LSource}" "${LName}"
done

if [[ -n "${BENCH_FPC_EXTRA_DEFINES_STRING}" ]]; then
  echo "[BENCH] extra-defines=${BENCH_FPC_EXTRA_DEFINES_STRING}" | tee -a "${RUNNER_LOG}"
fi
if [[ -n "${BENCH_FPC_EXTRA_ARGS_STRING}" ]]; then
  echo "[BENCH] extra-args=${BENCH_FPC_EXTRA_ARGS_STRING}" | tee -a "${RUNNER_LOG}"
fi

{
  echo "# SIMD Backend Benchmark Evidence (${TS})"
  echo
  echo "- Output: ${OUT_DIR}"
  echo "- Host: ${HOST_ARCH}"
  echo
  for LTarget in "${TARGETS[@]}"; do
    IFS=':' read -r LSource LName LHostRegex <<< "${LTarget}"
    LBase="${LSource%.lpr}"
    echo "## ${LName}"
    if [[ -f "${OUT_DIR}/${LBase}.build.log" ]]; then
      echo "- Build log: ${OUT_DIR}/${LBase}.build.log"
      echo "- Run log: ${OUT_DIR}/${LBase}.run.log"
      grep -E '^\[SKIP\]|^\[BENCH\]|^===|^Average Speedup:' "${OUT_DIR}/${LBase}.run.log" || true
    else
      echo "- SKIP: host arch ${HOST_ARCH} not in ${LHostRegex}"
    fi
    echo
  done
} > "${SUMMARY_FILE}"

echo "[BENCH] DONE: ${OUT_DIR}"
echo "[BENCH] SUMMARY: ${SUMMARY_FILE}"
