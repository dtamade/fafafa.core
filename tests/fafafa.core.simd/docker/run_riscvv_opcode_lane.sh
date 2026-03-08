#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
SIMD_ROOT="${ROOT_DIR}/tests/fafafa.core.simd"
DOCKER_DIR="${SIMD_ROOT}/docker"
LOG_ROOT="${SIMD_ROOT}/logs"
TS="$(date +%Y%m%d-%H%M%S)"
REPORT_DIR="${LOG_ROOT}/rvv-opcode-lane-${TS}"
SUMMARY_FILE="${REPORT_DIR}/summary.md"
COMPILE_LOG="${REPORT_DIR}/compile_only.log"
SUITE_LOG="${REPORT_DIR}/suite.log"
BENCH_LOG="${REPORT_DIR}/bench.log"
ENV_SCRIPT_HOST="${REPORT_DIR}/prebuilt_fpc_env.sh"
ENV_SCRIPT_WORK="tests/fafafa.core.simd/logs/rvv-opcode-lane-${TS}/prebuilt_fpc_env.sh"
IMAGE_TAG="${SIMD_RVV_LANE_IMAGE:-fafafa-core-simd-test-rvv:riscv64}"
BUILD_POLICY="${SIMD_RVV_LANE_BUILD_POLICY:-if-missing}"
BUILD_NETWORK="${DOCKER_BUILD_NETWORK:-default}"
HOST_PPCROSSRV64="${SIMD_RVV_PREBUILT_COMPILER:-/opt/fpcupdeluxe/fpcsrc/compiler/ppcrossrv64_v}"
HOST_QEMU_X86="${SIMD_RVV_PREBUILT_HOST_QEMU:-/usr/bin/qemu-x86_64-static}"
HOST_UNITS_DIR="${SIMD_RVV_PREBUILT_UNITS:-/opt/fpcupdeluxe/fpc-rvv-units}"
COMPILER_PREFIX="${SIMD_RVV_PREBUILT_COMPILER_PREFIX:-riscv64-linux-gnu-}"
CPU_NAME="${SIMD_RVV_PREBUILT_CPU:-RV64GCV}"
COMPILE_DEFINES="${SIMD_RVV_OPCODE_COMPILE_DEFINES:--dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY -dFAFAFA_SIMD_RISCVV_ASM_OPCODE_READY}"
RUNTIME_DEFINES="${SIMD_RVV_OPCODE_RUNTIME_DEFINES:--dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM -dFAFAFA_SIMD_ENABLE_RISCVV_ASM -dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY}"

mkdir -p "${REPORT_DIR}"

write_log() {
  local aLogFile
  aLogFile="$1"
  shift
  printf '%s\n' "$@" >"${aLogFile}"
}

build_image_if_needed() {
  case "${BUILD_POLICY}" in
    always)
      ;;
    if-missing)
      if docker image inspect "${IMAGE_TAG}" >/dev/null 2>&1; then
        return 0
      fi
      ;;
    skip)
      if docker image inspect "${IMAGE_TAG}" >/dev/null 2>&1; then
        return 0
      fi
      echo "[RVV-LANE] Missing local image under skip policy: ${IMAGE_TAG}"
      return 2
      ;;
    *)
      echo "[RVV-LANE] Unsupported build policy: ${BUILD_POLICY}"
      return 2
      ;;
  esac

  docker buildx build \
    --platform linux/riscv64 \
    --network "${BUILD_NETWORK}" \
    --tag "${IMAGE_TAG}" \
    --file "${DOCKER_DIR}/Dockerfile" \
    --load \
    "${DOCKER_DIR}" >/dev/null
}

write_env_script() {
  cat >"${ENV_SCRIPT_HOST}" <<EOF2
#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f /host/ppcrossrv64 ]]; then
  echo "[RVV-LANE] ERROR: missing mounted compiler at /host/ppcrossrv64"
  exit 2
fi
if [[ ! -f /host/qemu-x86_64-static ]]; then
  echo "[RVV-LANE] ERROR: missing mounted qemu at /host/qemu-x86_64-static"
  exit 2
fi
if [[ ! -d /host/fpc-units ]]; then
  echo "[RVV-LANE] ERROR: missing mounted units dir at /host/fpc-units"
  exit 2
fi

install -m 755 /host/ppcrossrv64 /tmp/ppcrossrv64
install -m 755 /host/qemu-x86_64-static /tmp/qemu-x86_64-static

cat > /tmp/fpc <<'__RVV_FPC_WRAPPER__'
#!/usr/bin/env bash
set -euo pipefail
: "\${SIMD_RVV_PREBUILT_COMPILER_PREFIX:=${COMPILER_PREFIX}}"
: "\${SIMD_RVV_PREBUILT_DISABLE_FPC_CFG:=1}"
: "\${SIMD_RVV_PREBUILT_CPU:=${CPU_NAME}}"
if [[ "\$#" -gt 0 && "\$1" == -i* ]]; then
  exec /tmp/qemu-x86_64-static /tmp/ppcrossrv64 "\$@"
fi
LUnitsRoot="/host/fpc-units"
if [[ -d "/host/fpc-units/riscv64-linux" ]]; then
  LUnitsRoot="/host/fpc-units/riscv64-linux"
fi
LNoCfg=()
if [[ "\${SIMD_RVV_PREBUILT_DISABLE_FPC_CFG}" != "0" ]]; then
  LNoCfg+=("-n")
fi
exec /tmp/qemu-x86_64-static /tmp/ppcrossrv64 "\${LNoCfg[@]}" "-Cp\${SIMD_RVV_PREBUILT_CPU}" "-XP\${SIMD_RVV_PREBUILT_COMPILER_PREFIX}" -Fu"\${LUnitsRoot}" -Fu"\${LUnitsRoot}"/* "\$@"
__RVV_FPC_WRAPPER__
chmod +x /tmp/fpc
export PATH="/tmp:\${PATH}"
echo "[RVV-LANE] prebuilt wrapper active"
echo "[RVV-LANE] using host compiler /host/ppcrossrv64 with units /host/fpc-units"
EOF2
}

run_container_step() {
  local aLogFile
  local aCommand
  aLogFile="$1"
  aCommand="$2"
  set +e
  docker run --rm \
    --platform linux/riscv64 \
    --user "$(id -u):$(id -g)" \
    --volume "${ROOT_DIR}:/work" \
    --volume "${HOST_PPCROSSRV64}:/host/ppcrossrv64:ro" \
    --volume "${HOST_QEMU_X86}:/host/qemu-x86_64-static:ro" \
    --volume "${HOST_UNITS_DIR}:/host/fpc-units:ro" \
    --workdir /work \
    "${IMAGE_TAG}" \
    bash -lc "set -euo pipefail; source '${ENV_SCRIPT_WORK}'; ${aCommand}" >"${aLogFile}" 2>&1
  local LRC=$?
  set -e
  return "${LRC}"
}

finalize_summary() {
  local aCompileStatus
  local aSuiteStatus
  local aBenchStatus
  aCompileStatus="$1"
  aSuiteStatus="$2"
  aBenchStatus="$3"

  cat >"${SUMMARY_FILE}" <<EOF2
# RVV Opcode Lane

- generated_at: $(date -Is)
- image: \`${IMAGE_TAG}\`
- compile_target: \`project\`
- compile_defines: \`${COMPILE_DEFINES}\`
- runtime_defines: \`${RUNTIME_DEFINES}\`

## Layered Acceptance

| Step | Status | Log |
|---|---|---|
| compile-only | ${aCompileStatus} | \`${COMPILE_LOG}\` |
| suite (TTestCase_NonX86IEEE754) | ${aSuiteStatus} | \`${SUITE_LOG}\` |
| bench | ${aBenchStatus} | \`${BENCH_LOG}\` |
EOF2
}

if ! command -v docker >/dev/null 2>&1; then
  write_log "${COMPILE_LOG}" "[RVV-LANE] SKIP (docker not found)"
  write_log "${SUITE_LOG}" "[RVV-LANE] SKIP (docker not found)"
  write_log "${BENCH_LOG}" "[RVV-LANE] SKIP (docker not found)"
  finalize_summary "SKIP" "SKIP" "SKIP"
  echo "[RVV-LANE] DONE: ${REPORT_DIR}"
  exit 0
fi

if [[ ! -f "${HOST_PPCROSSRV64}" || ! -f "${HOST_QEMU_X86}" || ! -d "${HOST_UNITS_DIR}" ]]; then
  write_log "${COMPILE_LOG}" "[RVV-LANE] SKIP (missing prebuilt host assets: compiler=${HOST_PPCROSSRV64}, qemu=${HOST_QEMU_X86}, units=${HOST_UNITS_DIR})"
  write_log "${SUITE_LOG}" "[RVV-LANE] SKIP (missing prebuilt host assets)"
  write_log "${BENCH_LOG}" "[RVV-LANE] SKIP (missing prebuilt host assets)"
  finalize_summary "SKIP" "SKIP" "SKIP"
  echo "[RVV-LANE] DONE: ${REPORT_DIR}"
  exit 0
fi

write_env_script
if ! build_image_if_needed; then
  write_log "${COMPILE_LOG}" "[RVV-LANE] SKIP (failed to prepare image ${IMAGE_TAG})"
  write_log "${SUITE_LOG}" "[RVV-LANE] SKIP (failed to prepare image ${IMAGE_TAG})"
  write_log "${BENCH_LOG}" "[RVV-LANE] SKIP (failed to prepare image ${IMAGE_TAG})"
  finalize_summary "SKIP" "SKIP" "SKIP"
  echo "[RVV-LANE] DONE: ${REPORT_DIR}"
  exit 0
fi

COMPILE_STATUS="FAIL"
SUITE_STATUS="SKIP"
BENCH_STATUS="SKIP"
COMPILE_CMD="export SIMD_FPC_EXTRA_DEFINES=$(printf '%q' "${COMPILE_DEFINES}"); export SIMD_RUN_ONLY_BUILD=1; bash tests/fafafa.core.simd/docker/run_fpc_tests.sh"
RUNTIME_CMD="export SIMD_FPC_EXTRA_DEFINES=$(printf '%q' "${RUNTIME_DEFINES}"); bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_NonX86IEEE754"
BENCH_CMD="export SIMD_BENCH_EXTRA_DEFINES=$(printf '%q' "${RUNTIME_DEFINES}"); bash tests/fafafa.core.simd/run_backend_benchmarks.sh"

if run_container_step "${COMPILE_LOG}" "${COMPILE_CMD}"; then
  COMPILE_STATUS="PASS"
  if run_container_step "${SUITE_LOG}" "${RUNTIME_CMD}"; then
    SUITE_STATUS="PASS"
    if run_container_step "${BENCH_LOG}" "${BENCH_CMD}"; then
      BENCH_STATUS="PASS"
    else
      BENCH_STATUS="FAIL"
    fi
  else
    SUITE_STATUS="FAIL"
    write_log "${BENCH_LOG}" "[RVV-LANE] SKIP (suite step failed)"
  fi
else
  write_log "${SUITE_LOG}" "[RVV-LANE] SKIP (compile-only step failed)"
  write_log "${BENCH_LOG}" "[RVV-LANE] SKIP (compile-only step failed)"
fi

finalize_summary "${COMPILE_STATUS}" "${SUITE_STATUS}" "${BENCH_STATUS}"
echo "[RVV-LANE] DONE: ${REPORT_DIR}"
echo "[RVV-LANE] SUMMARY: ${SUMMARY_FILE}"
exit 0
