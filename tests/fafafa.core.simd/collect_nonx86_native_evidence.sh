#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${SCRIPT_DIR}}"
REQUESTED_BACKEND="${1:-auto}"
TS="$(date +%Y%m%d-%H%M%S)"

normalize_arch() {
  local aRawArch

  aRawArch="$(uname -m 2>/dev/null || echo unknown)"
  case "${aRawArch}" in
    aarch64|arm64)
      echo "arm64"
      ;;
    riscv64)
      echo "riscv64"
      ;;
    *)
      echo "${aRawArch}"
      ;;
  esac
}

resolve_backend() {
  local aRequested
  local aArch

  aRequested="${1:-auto}"
  aArch="${2:-unknown}"

  case "${aRequested}" in
    auto)
      case "${aArch}" in
        arm64)
          echo "neon"
          ;;
        riscv64)
          echo "riscvv"
          ;;
        *)
          echo ""
          ;;
      esac
      ;;
    neon|riscvv)
      echo "${aRequested}"
      ;;
    *)
      echo ""
      ;;
  esac
}

ARCH="$(normalize_arch)"
BACKEND="$(resolve_backend "${REQUESTED_BACKEND}" "${ARCH}")"
if [[ -z "${BACKEND}" ]]; then
  echo "[NATIVE-EVIDENCE] Unsupported host/backend combination: host=${ARCH}, requested=${REQUESTED_BACKEND}"
  echo "[NATIVE-EVIDENCE] Supported: arm64->neon, riscv64->riscvv, or explicit neon/riscvv on a matching native host"
  exit 2
fi

case "${BACKEND}" in
  neon)
    if [[ "${ARCH}" != "arm64" ]]; then
      echo "[NATIVE-EVIDENCE] neon evidence requires arm64 native host; got ${ARCH}"
      exit 2
    fi
    BACKEND_ENV_NAME="SIMD_ENABLE_NEON_BACKEND"
    BACKEND_ENV_VALUE="1"
    BACKEND_LABEL="NEON"
    ;;
  riscvv)
    if [[ "${ARCH}" != "riscv64" ]]; then
      echo "[NATIVE-EVIDENCE] riscvv evidence requires riscv64 native host; got ${ARCH}"
      exit 2
    fi
    BACKEND_ENV_NAME="SIMD_ENABLE_RISCVV_BACKEND"
    BACKEND_ENV_VALUE="1"
    BACKEND_LABEL="RISCVV"
    ;;
  *)
    echo "[NATIVE-EVIDENCE] Internal error: unsupported backend ${BACKEND}"
    exit 2
    ;;
esac

OUT_DIR="${OUTPUT_ROOT}/logs/native-evidence-${BACKEND}-${TS}"
RUN_OUTPUT_ROOT="${OUT_DIR}/run"
RUN_TMPDIR="${OUT_DIR}/tmp"
SUMMARY_FILE="${OUT_DIR}/summary.md"
ENV_FILE="${OUT_DIR}/environment.txt"
mkdir -p "${OUT_DIR}" "${RUN_OUTPUT_ROOT}" "${RUN_TMPDIR}"

run_step() {
  local aName
  local aLogFile

  aName="${1:-}"
  shift || true
  aLogFile="${OUT_DIR}/${aName}.log"

  echo "[NATIVE-EVIDENCE] >>> ${aName}" | tee -a "${OUT_DIR}/_runner.log"
  (
    cd "${ROOT_DIR}"
    env \
      TMPDIR="${RUN_TMPDIR}" \
      FAFAFA_BUILD_MODE="${FAFAFA_BUILD_MODE:-Release}" \
      SIMD_OUTPUT_ROOT="${RUN_OUTPUT_ROOT}" \
      "${BACKEND_ENV_NAME}=${BACKEND_ENV_VALUE}" \
      "$@"
  ) 2>&1 | tee "${aLogFile}"
}

{
  echo "host_arch=${ARCH}"
  echo "backend=${BACKEND}"
  echo "backend_label=${BACKEND_LABEL}"
  echo "output_root=${RUN_OUTPUT_ROOT}"
  echo "tmpdir=${RUN_TMPDIR}"
  echo "fa_build_mode=${FAFAFA_BUILD_MODE:-Release}"
  echo "kernel=$(uname -srmo 2>/dev/null || true)"
  echo "fpc=$(command -v fpc || true)"
  echo "fpc_target_cpu=$(fpc -iTP 2>/dev/null || true)"
  echo "fpc_target_os=$(fpc -iTO 2>/dev/null || true)"
  echo "lazbuild=$(command -v lazbuild || true)"
} > "${ENV_FILE}"

run_step list_suites bash tests/fafafa.core.simd/BuildOrTest.sh test --list-suites
run_step dispatch_publicabi bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_PublicAbi
run_step check bash tests/fafafa.core.simd/BuildOrTest.sh check

if [[ "${SIMD_NATIVE_EVIDENCE_INCLUDE_BENCH:-0}" == "1" ]]; then
  run_step backend_bench bash tests/fafafa.core.simd/run_backend_benchmarks.sh
fi

{
  echo "# SIMD Non-X86 Native Evidence (${TS})"
  echo
  echo "- Root: ${ROOT_DIR}"
  echo "- Host Arch: ${ARCH}"
  echo "- Backend: ${BACKEND_LABEL}"
  echo "- Output Root: ${RUN_OUTPUT_ROOT}"
  echo "- Environment: ${ENV_FILE}"
  echo
  echo "## list-suites"
  grep -E "\[BUILD\]|\[TEST\]|\[LEAK\]|TTestCase_" "${OUT_DIR}/list_suites.log" || true
  echo
  echo "## DispatchAPI + PublicAbi"
  grep -E "\[BUILD\]|\[TEST\]|\[LEAK\]" "${OUT_DIR}/dispatch_publicabi.log" || true
  echo
  echo "## Check"
  grep -E "\[BUILD\]|\[CHECK\]|\[TEST\]|\[LEAK\]|\[REGISTER-INCLUDE\]|\[SUITE-MANIFEST\]|\[DISPATCH-PREINIT\]" "${OUT_DIR}/check.log" || true
  if [[ -f "${OUT_DIR}/backend_bench.log" ]]; then
    echo
    echo "## Backend Benchmarks"
    grep -E "\[BENCH\]|^===|Average Speedup:|^\[SKIP\]" "${OUT_DIR}/backend_bench.log" || true
  fi
} > "${SUMMARY_FILE}"

echo "[NATIVE-EVIDENCE] DONE: ${OUT_DIR}"
echo "[NATIVE-EVIDENCE] SUMMARY: ${SUMMARY_FILE}"
