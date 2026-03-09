#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../../.." && pwd)"
DOCKER_DIR="${ROOT_DIR}/tests/fafafa.core.simd/docker"
LOG_ROOT="${ROOT_DIR}/tests/fafafa.core.simd/logs"

IMAGE_BASE="${SIMD_QEMU_IMAGE_BASE:-fafafa-core-simd-test}"
SCENARIO="${1:-${SIMD_QEMU_SCENARIO:-basic}}"
PLATFORMS_STRING="${SIMD_QEMU_PLATFORMS:-}"
DOCKER_BUILD_NETWORK="${DOCKER_BUILD_NETWORK:-default}"
RETRIES="${SIMD_QEMU_RETRIES:-3}"
BUILD_POLICY="${SIMD_QEMU_BUILD_POLICY:-if-missing}"
CPUINFO_REPEAT_ROUNDS="${SIMD_QEMU_CPUINFO_REPEAT_ROUNDS:-3}"
CPUINFO_SUITE_REPEAT_ROUNDS="${SIMD_QEMU_CPUINFO_SUITE_REPEAT_ROUNDS:-5}"
EXPERIMENTAL_DEFINE="${SIMD_QEMU_EXPERIMENTAL_DEFINE:--dFAFAFA_SIMD_EXPERIMENTAL_BACKEND_ASM}"
EXPERIMENTAL_ARM64_DEFINE="${SIMD_QEMU_EXPERIMENTAL_ARM64_DEFINE:--dFAFAFA_SIMD_ENABLE_NEON_ASM}"
EXPERIMENTAL_RISCV64_DEFINE="${SIMD_QEMU_EXPERIMENTAL_RISCV64_DEFINE:--dFAFAFA_SIMD_ENABLE_RISCVV_ASM}"
EXPERIMENTAL_ARM64_COMPILER_DEFINE="${SIMD_QEMU_EXPERIMENTAL_ARM64_COMPILER_DEFINE:-}"
EXPERIMENTAL_RISCV64_COMPILER_DEFINE="${SIMD_QEMU_EXPERIMENTAL_RISCV64_COMPILER_DEFINE:-}"
EXPERIMENTAL_RISCV64_OPCODE_DEFINE="${SIMD_QEMU_EXPERIMENTAL_RISCV64_OPCODE_DEFINE:-}"
EXPERIMENTAL_ENABLE_BACKEND_ASM="${SIMD_QEMU_ENABLE_BACKEND_ASM:-0}"
EXPERIMENTAL_BACKEND_ASM_PROBE_MODE="${SIMD_QEMU_BACKEND_ASM_PROBE_MODE:-1}"
NETWORK_BUILD_FALLBACK="${SIMD_QEMU_NETWORK_BUILD_FALLBACK:-1}"
ARCH_MATRIX_REQUIRED_PLATFORMS="linux/386 linux/amd64 linux/arm/v7 linux/arm64 linux/riscv64"

TS="$(date +%Y%m%d-%H%M%S)"
REPORT_DIR="${LOG_ROOT}/qemu-multiarch-${TS}"
SUMMARY_FILE="${REPORT_DIR}/summary.md"

mkdir -p "${REPORT_DIR}"

run_with_retry() {
  local aMax
  local aDesc
  local LAttempt
  local LRC

  aMax="${1}"
  shift
  aDesc="${1}"
  shift
  LAttempt=1

  while true; do
    set +e
    "$@"
    LRC=$?
    set -e

    if (( LRC == 0 )); then
      return 0
    fi
    emit_cpuinfo_retry_diagnostics "${aDesc}" "${LRC}" "${LAttempt}" "${aMax}"
    if (( LAttempt >= aMax )); then
      echo "[ERROR] ${aDesc} failed after ${LAttempt} attempt(s), rc=${LRC}"
      return "${LRC}"
    fi
    echo "[WARN] ${aDesc} failed rc=${LRC}, retry ${LAttempt}/${aMax} ..."
    sleep $((LAttempt * 3))
    LAttempt=$((LAttempt + 1))
  done
}

cpuinfo_target_from_platform() {
  local aPlatform

  aPlatform="${1:-}"
  case "${aPlatform}" in
    linux/arm|linux/arm/v7)
      echo "arm-linux"
      ;;
    linux/arm64)
      echo "aarch64-linux"
      ;;
    linux/riscv64)
      echo "riscv64-linux"
      ;;
    linux/amd64)
      echo "x86_64-linux"
      ;;
    linux/386)
      echo "i386-linux"
      ;;
    *)
      return 1
      ;;
  esac
}

emit_cpuinfo_retry_diagnostics() {
  local aDesc
  local aRC
  local aAttempt
  local aMax
  local LPlatform
  local LScenario
  local LTargetTriple
  local LCpuinfoLogRoot
  local LTargetBuildLog
  local LTargetTestLog
  local LLegacyBuildLog
  local LLegacyTestLog
  local LTailLines

  aDesc="${1:-}"
  aRC="${2:-1}"
  aAttempt="${3:-1}"
  aMax="${4:-1}"
  LPlatform="${RETRY_CONTEXT_PLATFORM:-}"
  LScenario="${RETRY_CONTEXT_SCENARIO:-${SCENARIO}}"
  LTailLines="${SIMD_QEMU_CPUINFO_RETRY_LOG_TAIL_LINES:-60}"

  case "${LScenario}" in
    cpuinfo-nonx86-evidence|cpuinfo-nonx86-full-evidence|cpuinfo-nonx86-full-repeat|cpuinfo-nonx86-suite-repeat)
      ;;
    *)
      return 0
      ;;
  esac

  if [[ "${aDesc}" != *run* ]]; then
    return 0
  fi

  LCpuinfoLogRoot="${ROOT_DIR}/tests/fafafa.core.simd.cpuinfo/logs"
  LTargetTriple="$(cpuinfo_target_from_platform "${LPlatform}" || true)"
  LTargetBuildLog=""
  LTargetTestLog=""
  if [[ -n "${LTargetTriple}" ]]; then
    LTargetBuildLog="${LCpuinfoLogRoot}/${LTargetTriple}/build.txt"
    LTargetTestLog="${LCpuinfoLogRoot}/${LTargetTriple}/test.txt"
  fi
  LLegacyBuildLog="${LCpuinfoLogRoot}/build.txt"
  LLegacyTestLog="${LCpuinfoLogRoot}/test.txt"

  echo "[DIAG] cpuinfo retry context: scenario=${LScenario}, platform=${LPlatform:-unknown}, target=${LTargetTriple:-unknown}, attempt=${aAttempt}/${aMax}, rc=${aRC}, desc=${aDesc}"

  if [[ -n "${LTargetBuildLog}" ]] && [[ -f "${LTargetBuildLog}" ]]; then
    echo "[DIAG] target build log: ${LTargetBuildLog}"
    tail -n "${LTailLines}" "${LTargetBuildLog}" || true
  elif [[ -f "${LLegacyBuildLog}" ]]; then
    echo "[DIAG] legacy build log: ${LLegacyBuildLog}"
    tail -n "${LTailLines}" "${LLegacyBuildLog}" || true
  else
    echo "[DIAG] missing build log under ${LCpuinfoLogRoot}"
  fi

  if [[ -n "${LTargetTestLog}" ]] && [[ -f "${LTargetTestLog}" ]]; then
    echo "[DIAG] target test log: ${LTargetTestLog}"
    tail -n "${LTailLines}" "${LTargetTestLog}" || true
  elif [[ -f "${LLegacyTestLog}" ]]; then
    echo "[DIAG] legacy test log: ${LLegacyTestLog}"
    tail -n "${LTailLines}" "${LLegacyTestLog}" || true
  fi
}

inject_cpuinfo_fail_once_cmd() {
  local aCmd
  local aScenario
  local aPlatform
  local aArchTag
  local LEnabled
  local LScenarioFilter
  local LPlatformFilter
  local LStampDir
  local LStampFile
  local LExitCode

  aCmd="${1:-}"
  aScenario="${2:-}"
  aPlatform="${3:-}"
  aArchTag="${4:-}"

  LEnabled="${SIMD_QEMU_CPUINFO_FAIL_ONCE:-0}"
  LScenarioFilter="${SIMD_QEMU_CPUINFO_FAIL_ONCE_SCENARIO:-}"
  LPlatformFilter="${SIMD_QEMU_CPUINFO_FAIL_ONCE_PLATFORM:-}"
  LExitCode="${SIMD_QEMU_CPUINFO_FAIL_ONCE_EXIT_CODE:-85}"

  case "${aScenario}" in
    cpuinfo-nonx86-evidence|cpuinfo-nonx86-full-evidence|cpuinfo-nonx86-full-repeat|cpuinfo-nonx86-suite-repeat)
      ;;
    *)
      printf '%s\n' "${aCmd}"
      return 0
      ;;
  esac

  if [[ "${LEnabled}" == "0" ]]; then
    printf '%s\n' "${aCmd}"
    return 0
  fi

  if [[ -n "${LScenarioFilter}" ]] && [[ "${LScenarioFilter}" != "${aScenario}" ]]; then
    printf '%s\n' "${aCmd}"
    return 0
  fi

  if [[ -n "${LPlatformFilter}" ]] && [[ "${LPlatformFilter}" != "${aPlatform}" ]]; then
    printf '%s\n' "${aCmd}"
    return 0
  fi

  if ! [[ "${LExitCode}" =~ ^[1-9][0-9]*$ ]] || (( LExitCode > 255 )); then
    LExitCode=85
  fi

  LStampDir="tests/fafafa.core.simd/logs/.qemu-retry-inject/${TS}"
  LStampFile="${LStampDir}/${aScenario}.${aArchTag}.once"
  printf '%s\n' "mkdir -p ${LStampDir} && if [[ ! -f ${LStampFile} ]]; then echo \"[INJECT] cpuinfo fail-once scenario=${aScenario} platform=${aPlatform} exit=${LExitCode}\"; touch ${LStampFile}; exit ${LExitCode}; fi && ${aCmd}"
}

case "${SCENARIO}" in
  basic)
    CONTAINER_CMD='bash tests/fafafa.core.simd/docker/run_fpc_tests.sh'
    ;;
  nonx86-evidence)
    CONTAINER_CMD='bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_NonX86IEEE754 && bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_NonX86BackendParity && bash tests/fafafa.core.simd/run_backend_benchmarks.sh'
    ;;
  cpuinfo-nonx86-evidence)
    CONTAINER_CMD='FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh check && FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --list-suites && LTARGET_CPU="$(fpc -iTP 2>/dev/null | tr "[:upper:]" "[:lower:]" || true)" && LTARGET_OS="$(fpc -iTO 2>/dev/null | tr "[:upper:]" "[:lower:]" || true)" && LTARGET_LOG="tests/fafafa.core.simd.cpuinfo/logs/${LTARGET_CPU:-unknowncpu}-${LTARGET_OS:-unknownos}/test.txt" && LSUITES="$(cat "$LTARGET_LOG" 2>/dev/null || cat tests/fafafa.core.simd.cpuinfo/logs/test.txt 2>/dev/null || true)" && if printf "%s\n" "$LSUITES" | grep -q "TTestCase_LazyCPUInfo"; then FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_LazyCPUInfo; else echo "[TEST] SKIP lazy cpuinfo suite (not available on this target)"; fi && FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_PlatformSpecific'
    ;;
  cpuinfo-nonx86-full-evidence)
    CONTAINER_CMD='FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh check && FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test'
    ;;
  cpuinfo-nonx86-full-repeat)
    if ! [[ "${CPUINFO_REPEAT_ROUNDS}" =~ ^[1-9][0-9]*$ ]]; then
      echo "[ERROR] SIMD_QEMU_CPUINFO_REPEAT_ROUNDS must be a positive integer (got: ${CPUINFO_REPEAT_ROUNDS})"
      exit 2
    fi
    CONTAINER_CMD="FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh check && LROUNDS=${CPUINFO_REPEAT_ROUNDS} && for LRound in \$(seq 1 \"\$LROUNDS\"); do echo \"[REPEAT] \${LRound}/\${LROUNDS} cpuinfo-full\"; FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test; done"
    ;;
  cpuinfo-nonx86-suite-repeat)
    if ! [[ "${CPUINFO_SUITE_REPEAT_ROUNDS}" =~ ^[1-9][0-9]*$ ]]; then
      echo "[ERROR] SIMD_QEMU_CPUINFO_SUITE_REPEAT_ROUNDS must be a positive integer (got: ${CPUINFO_SUITE_REPEAT_ROUNDS})"
      exit 2
    fi
    CONTAINER_CMD="FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh check && FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --list-suites && LTARGET_CPU=\"\$(fpc -iTP 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)\" && LTARGET_OS=\"\$(fpc -iTO 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)\" && LTARGET_LOG=\"tests/fafafa.core.simd.cpuinfo/logs/\${LTARGET_CPU:-unknowncpu}-\${LTARGET_OS:-unknownos}/test.txt\" && LSUITES=\"\$(cat \"\$LTARGET_LOG\" 2>/dev/null || cat tests/fafafa.core.simd.cpuinfo/logs/test.txt 2>/dev/null || true)\" && LHAS_LAZY=0 && if printf \"%s\n\" \"\$LSUITES\" | grep -q \"TTestCase_LazyCPUInfo\"; then LHAS_LAZY=1; fi && LROUNDS=${CPUINFO_SUITE_REPEAT_ROUNDS} && for LRound in \$(seq 1 \"\$LROUNDS\"); do echo \"[REPEAT] \${LRound}/\${LROUNDS} cpuinfo-platform-specific\"; FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_PlatformSpecific; if [[ \"\$LHAS_LAZY\" == \"1\" ]]; then echo \"[REPEAT] \${LRound}/\${LROUNDS} cpuinfo-lazy\"; FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_LazyCPUInfo; else echo \"[REPEAT] \${LRound}/\${LROUNDS} cpuinfo-lazy SKIP (suite unavailable)\"; fi; done"
    ;;
  nonx86-experimental-asm)
    CONTAINER_CMD="__NONX86_EXPERIMENTAL_ASM__"
    ;;
  linux-evidence)
    CONTAINER_CMD='bash tests/fafafa.core.simd/collect_linux_simd_evidence.sh'
    ;;
  arch-matrix-evidence)
    CONTAINER_CMD='__ARCH_MATRIX_EVIDENCE__'
    ;;
  *)
    echo "[ERROR] Unknown scenario: ${SCENARIO}"
    echo "[ERROR] Supported: basic | nonx86-evidence | cpuinfo-nonx86-evidence | cpuinfo-nonx86-full-evidence | cpuinfo-nonx86-full-repeat | cpuinfo-nonx86-suite-repeat | nonx86-experimental-asm | linux-evidence | arch-matrix-evidence"
    exit 2
    ;;
esac

if [[ -z "${PLATFORMS_STRING}" ]]; then
  case "${SCENARIO}" in
    arch-matrix-evidence)
      PLATFORMS_STRING="${ARCH_MATRIX_REQUIRED_PLATFORMS}"
      ;;
    nonx86-evidence|cpuinfo-nonx86-evidence|cpuinfo-nonx86-full-evidence|cpuinfo-nonx86-full-repeat|cpuinfo-nonx86-suite-repeat|linux-evidence|nonx86-experimental-asm)
      PLATFORMS_STRING="${SIMD_QEMU_PLATFORMS_NONX86:-linux/arm/v7 linux/arm64 linux/riscv64}"
      ;;
    *)
      PLATFORMS_STRING="linux/arm64 linux/riscv64"
      ;;
  esac
fi

read -r -a PLATFORMS <<< "${PLATFORMS_STRING}"
if [[ "${#PLATFORMS[@]}" -eq 0 ]]; then
  echo "[ERROR] SIMD_QEMU_PLATFORMS is empty"
  exit 2
fi

if [[ "${SCENARIO}" == "arch-matrix-evidence" ]]; then
  for required in ${ARCH_MATRIX_REQUIRED_PLATFORMS}; do
    found=0
    for platform in "${PLATFORMS[@]}"; do
      if [[ "${platform}" == "${required}" ]]; then
        found=1
        break
      fi
    done
    if [[ "${found}" == "0" ]]; then
      echo "[ERROR] arch-matrix-evidence requires platform: ${required}"
      echo "[ERROR] current SIMD_QEMU_PLATFORMS='${PLATFORMS_STRING}'"
      exit 2
    fi
  done
fi

case "${BUILD_POLICY}" in
  always|if-missing|skip)
    ;;
  *)
    echo "[ERROR] Unsupported SIMD_QEMU_BUILD_POLICY=${BUILD_POLICY}"
    echo "[ERROR] Supported values: always | if-missing | skip"
    exit 2
    ;;
esac

cat > "${SUMMARY_FILE}" <<EOF_SUMMARY
# SIMD QEMU Multiarch Report

- time: $(date -Is)
- scenario: ${SCENARIO}
- platforms: ${PLATFORMS_STRING}

| Platform | Status | Log |
|---|---|---|
EOF_SUMMARY

echo "[INFO] Repo: ${ROOT_DIR}"
echo "[INFO] Scenario: ${SCENARIO}"
echo "[INFO] Platforms: ${PLATFORMS_STRING}"
echo "[INFO] Build policy: ${BUILD_POLICY}"
echo "[INFO] Report dir: ${REPORT_DIR}"

overall_failures=0

for platform in "${PLATFORMS[@]}"; do
  arch="${platform#linux/}"
  arch_tag="${arch//\//-}"
  tag="${IMAGE_BASE}:${arch_tag}"
  arch_log="${REPORT_DIR}/${arch_tag}.log"
  arm64_snapshot="${SIMD_QEMU_ARM64_FPC_SNAPSHOT:-}"
  build_args=()
  allow_probe_failure=0
  RETRY_CONTEXT_PLATFORM="${platform}"
  RETRY_CONTEXT_SCENARIO="${SCENARIO}"

  if [[ -z "${arm64_snapshot}" ]]; then
    if [[ "${SCENARIO}" == "nonx86-evidence" || "${SCENARIO}" == "cpuinfo-nonx86-evidence" || "${SCENARIO}" == "cpuinfo-nonx86-full-evidence" || "${SCENARIO}" == "cpuinfo-nonx86-full-repeat" || "${SCENARIO}" == "cpuinfo-nonx86-suite-repeat" || "${SCENARIO}" == "linux-evidence" || "${SCENARIO}" == "nonx86-experimental-asm" ]]; then
      arm64_snapshot="1"
    else
      arm64_snapshot="0"
    fi
  fi

  if [[ "${arch}" == "arm64" && "${arm64_snapshot}" != "0" ]]; then
    build_args+=(--build-arg "USE_FPC_SNAPSHOT=1")
  fi

  container_cmd="${CONTAINER_CMD}"
  if [[ "${SCENARIO}" == "arch-matrix-evidence" ]]; then
    case "${arch}" in
      amd64|386)
        container_cmd='bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_Global && bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_DispatchAPI && bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_AVX2IntrinsicsFallback'
        ;;
      arm|arm/v7|arm64|riscv64)
        container_cmd='bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_Global && bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_DispatchAPI && bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_NonX86IEEE754 && bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_NonX86BackendParity'
        ;;
      *)
        echo "[ERROR] Unsupported arch in arch-matrix-evidence: ${arch}"
        exit 2
        ;;
    esac
  fi

  if [[ "${SCENARIO}" == "nonx86-experimental-asm" ]]; then
    experimental_defines="${EXPERIMENTAL_DEFINE}"
    if [[ "${EXPERIMENTAL_ENABLE_BACKEND_ASM}" == "1" ]]; then
      case "${arch}" in
        arm64)
          experimental_defines="${experimental_defines} ${EXPERIMENTAL_ARM64_DEFINE}"
          if [[ -n "${EXPERIMENTAL_ARM64_COMPILER_DEFINE}" ]]; then
            experimental_defines="${experimental_defines} ${EXPERIMENTAL_ARM64_COMPILER_DEFINE}"
          fi
          ;;
        riscv64)
          experimental_defines="${experimental_defines} ${EXPERIMENTAL_RISCV64_DEFINE}"
          if [[ -n "${EXPERIMENTAL_RISCV64_COMPILER_DEFINE}" ]]; then
            experimental_defines="${experimental_defines} ${EXPERIMENTAL_RISCV64_COMPILER_DEFINE}"
          fi
          if [[ -n "${EXPERIMENTAL_RISCV64_OPCODE_DEFINE}" ]]; then
            experimental_defines="${experimental_defines} ${EXPERIMENTAL_RISCV64_OPCODE_DEFINE}"
          fi
          ;;
      esac
      echo "[INFO] ${platform} backend-asm=on"
      if [[ "${EXPERIMENTAL_BACKEND_ASM_PROBE_MODE}" == "1" ]]; then
        allow_probe_failure=1
        echo "[INFO] ${platform} backend-asm probe-mode=on (probe failure will retry fallback and keep PASS if fallback succeeds)"
      fi
    else
      echo "[INFO] ${platform} backend-asm=off (set SIMD_QEMU_ENABLE_BACKEND_ASM=1 to enable per-backend asm defines)"
    fi
    container_cmd="SIMD_FPC_EXTRA_DEFINES='${experimental_defines}' bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_NonX86IEEE754"
  fi

  container_cmd="$(inject_cpuinfo_fail_once_cmd "${container_cmd}" "${SCENARIO}" "${platform}" "${arch_tag}")"

  set +e
  {
    do_build=1
    case "${BUILD_POLICY}" in
      always)
        do_build=1
        ;;
      if-missing)
        if docker image inspect "${tag}" >/dev/null 2>&1; then
          do_build=0
        else
          do_build=1
        fi
        ;;
      skip)
        do_build=0
        ;;
    esac

    if [[ "${do_build}" == "1" ]]; then
      echo "[BUILD] ${tag} (${platform})"
      run_with_retry "${RETRIES}" "build ${platform}" docker buildx build \
        --platform "${platform}" \
        --network "${DOCKER_BUILD_NETWORK}" \
        "${build_args[@]}" \
        --tag "${tag}" \
        --file "${DOCKER_DIR}/Dockerfile" \
        --load \
        "${DOCKER_DIR}"
    else
      echo "[BUILD] SKIP ${tag} (${platform}) policy=${BUILD_POLICY}"
      if ! docker image inspect "${tag}" >/dev/null 2>&1; then
        echo "[ERROR] Missing local image for skipped build: ${tag}"
        exit 2
      fi
    fi

    echo "[RUN] ${tag} (${platform})"
    run_with_retry "${RETRIES}" "run ${platform}" docker run --rm \
      --platform "${platform}" \
      --user "$(id -u):$(id -g)" \
      --volume "${ROOT_DIR}:/work" \
      --workdir "/work" \
      "${tag}" \
      bash -lc "set -euo pipefail; ${container_cmd}"
  } 2>&1 | tee "${arch_log}"
  platform_rc=$?
  set -e

  if (( platform_rc == 0 )); then
    echo "| ${platform} | PASS | \`${arch_log}\` |" >> "${SUMMARY_FILE}"
  else
    if (( allow_probe_failure == 1 )); then
      fallback_defines="${EXPERIMENTAL_DEFINE}"
      fallback_cmd="SIMD_FPC_EXTRA_DEFINES='${fallback_defines}' bash tests/fafafa.core.simd/docker/run_fpc_tests.sh --suite=TTestCase_NonX86IEEE754"
      echo "[WARN] Platform ${platform} failed in backend-asm probe mode (rc=${platform_rc}), retry fallback path without per-backend asm define."

      set +e
      {
        echo "[FALLBACK] ${tag} (${platform})"
        run_with_retry "${RETRIES}" "fallback run ${platform}" docker run --rm \
          --platform "${platform}" \
          --user "$(id -u):$(id -g)" \
          --volume "${ROOT_DIR}:/work" \
          --workdir "/work" \
          "${tag}" \
          bash -lc "set -euo pipefail; ${fallback_cmd}"
      } 2>&1 | tee -a "${arch_log}"
      fallback_rc=$?
      set -e

      if (( fallback_rc == 0 )); then
        echo "| ${platform} | PASS | \`${arch_log}\` |" >> "${SUMMARY_FILE}"
        echo "[WARN] Platform ${platform} backend-asm probe failed but fallback path passed."
      else
        overall_failures=$((overall_failures + 1))
        echo "| ${platform} | FAIL | \`${arch_log}\` |" >> "${SUMMARY_FILE}"
        echo "[WARN] Platform ${platform} backend-asm probe failed and fallback path also failed (rc=${fallback_rc})."
      fi
    else
      if [[ "${NETWORK_BUILD_FALLBACK}" == "1" ]] \
        && grep -qiE "failed to resolve source metadata|DeadlineExceeded|i/o timeout" "${arch_log}" \
        && docker image inspect "${tag}" >/dev/null 2>&1; then
        echo "[WARN] Platform ${platform} hit network metadata failure; retry run with cached local image ${tag}."
        set +e
        {
          echo "[FALLBACK-NET] ${tag} (${platform})"
          run_with_retry "${RETRIES}" "fallback-net run ${platform}" docker run --rm \
            --platform "${platform}" \
            --user "$(id -u):$(id -g)" \
            --volume "${ROOT_DIR}:/work" \
            --workdir "/work" \
            "${tag}" \
            bash -lc "set -euo pipefail; ${container_cmd}"
        } 2>&1 | tee -a "${arch_log}"
        fallback_net_rc=$?
        set -e

        if (( fallback_net_rc == 0 )); then
          echo "| ${platform} | PASS | \`${arch_log}\` |" >> "${SUMMARY_FILE}"
          echo "[WARN] Platform ${platform} recovered via cached-image network fallback."
        else
          overall_failures=$((overall_failures + 1))
          echo "| ${platform} | FAIL | \`${arch_log}\` |" >> "${SUMMARY_FILE}"
          echo "[WARN] Platform ${platform} network fallback failed (rc=${fallback_net_rc})."
        fi
      else
        overall_failures=$((overall_failures + 1))
        echo "| ${platform} | FAIL | \`${arch_log}\` |" >> "${SUMMARY_FILE}"
        echo "[WARN] Platform ${platform} failed (rc=${platform_rc}), continue to collect remaining evidence."
      fi
    fi
  fi
done

RETRY_CONTEXT_PLATFORM=""
RETRY_CONTEXT_SCENARIO=""

if (( overall_failures > 0 )); then
  echo "[DONE] Completed with failures: ${overall_failures}"
  echo "[DONE] Summary: ${SUMMARY_FILE}"
  exit 1
fi

echo "[DONE] All platforms passed"
echo "[DONE] Summary: ${SUMMARY_FILE}"
