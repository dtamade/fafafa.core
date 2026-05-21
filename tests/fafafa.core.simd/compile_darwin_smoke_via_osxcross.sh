#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${ROOT}/../.." && pwd)"
OUTPUT_ROOT="${SIMD_OUTPUT_ROOT:-${ROOT}}"
SUMMARY_LOG="${SIMD_DARWIN_COMPILE_SMOKE_LOG_FILE:-${OUTPUT_ROOT}/logs/darwin_compile_smoke.log}"
DETAIL_ROOT="${SIMD_DARWIN_COMPILE_SMOKE_DETAIL_ROOT:-${OUTPUT_ROOT}/logs/darwin-compile-smoke}"
TMP_ROOT="${SIMD_DARWIN_COMPILE_SMOKE_TMP_ROOT:-/tmp/fafafa-core-darwin-smoke}"
RTL_SOURCE_ROOT="${SIMD_DARWIN_RTL_SOURCE_ROOT:-/opt/fpcupdeluxe/fpcsrc/rtl}"
FPC_X86_64="${SIMD_DARWIN_FPC_X86_64:-/opt/fpcupdeluxe/fpc/bin/x86_64-linux/ppcx64}"
FPC_AARCH64="${SIMD_DARWIN_FPC_AARCH64:-}"
FPCSRC_ROOT="${SIMD_DARWIN_FPCSRC_ROOT:-}"
OSXCROSS_ROOT="${SIMD_DARWIN_OSXCROSS_ROOT:-/home/dtamade/osxcross/target}"
SDK_ROOT="${SIMD_DARWIN_SDK_ROOT:-}"
REQUIRE_AARCH64="${SIMD_DARWIN_REQUIRE_AARCH64:-0}"

UNITS=(
  "src/fafafa.core.simd.cpuinfo.darwin.pas"
  "src/fafafa.core.simd.cpuinfo.pas"
  "src/fafafa.core.simd.cpuinfo.diagnostic.pas"
  "src/fafafa.core.simd.pas"
  "src/fafafa.core.simd.api.pas"
  "src/fafafa.core.time.tick.pas"
  "src/fafafa.core.time.stopwatch.pas"
  "tests/fafafa.core.simd/fafafa.core.simd.darwin_link_smoke.pas"
  "tests/fafafa.core.simd.cpuinfo/fafafa.core.simd.cpuinfo.darwin_link_smoke.pas"
)

OVERALL_STATUS="PASS"

append_summary() {
  printf '%s\n' "$*" >> "${SUMMARY_LOG}"
}

sanitize_value() {
  printf '%s' "${1:-}" | tr ' \t\r\n' '_'
}

is_truthy() {
  case "$(printf '%s' "${1:-0}" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|on)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

detect_sdk_root() {
  local LCandidate

  if [[ -n "${SDK_ROOT}" ]]; then
    if [[ -d "${SDK_ROOT}" ]]; then
      printf '%s\n' "${SDK_ROOT}"
      return 0
    fi
    return 1
  fi

  for LCandidate in "${OSXCROSS_ROOT}"/SDK/MacOSX*.sdk; do
    if [[ -d "${LCandidate}" ]]; then
      printf '%s\n' "${LCandidate}"
      return 0
    fi
  done

  return 1
}

detect_osxcross_prefix() {
  local aArch
  local LCandidate

  aArch="${1:-}"
  for LCandidate in "${OSXCROSS_ROOT}/bin/${aArch}-apple-darwin"*-clang; do
    if [[ -x "${LCandidate}" ]]; then
      printf '%s\n' "${LCandidate%-clang}"
      return 0
    fi
  done

  return 1
}

detect_aarch64_compiler() {
  local LCandidate

  if [[ -n "${FPC_AARCH64}" ]]; then
    if [[ -x "${FPC_AARCH64}" ]]; then
      printf '%s\n' "${FPC_AARCH64}"
      return 0
    fi
    return 1
  fi

  for LCandidate in ppcrossa64 ppca64 ppcaarch64; do
    if command -v "${LCandidate}" >/dev/null 2>&1; then
      command -v "${LCandidate}"
      return 0
    fi
  done

  return 1
}

detect_fpcsrc_root() {
  if [[ -n "${FPCSRC_ROOT}" ]]; then
    if [[ -d "${FPCSRC_ROOT}" ]]; then
      printf '%s\n' "${FPCSRC_ROOT}"
      return 0
    fi
    return 1
  fi

  if [[ -d "${RTL_SOURCE_ROOT}" ]]; then
    if [[ "$(basename "${RTL_SOURCE_ROOT}")" = "rtl" ]]; then
      printf '%s\n' "$(dirname "${RTL_SOURCE_ROOT}")"
      return 0
    fi
  fi

  return 1
}

create_aliases() {
  local aArch
  local aPrefix
  local aAliasDir
  local LTool
  local LTarget
  local LAlias

  aArch="${1:-}"
  aPrefix="${2:-}"
  aAliasDir="${3:-}"

  mkdir -p "${aAliasDir}"
  for LTool in as ld ar ranlib strip clang clang++ nm; do
    LTarget="${aPrefix}-${LTool}"
    if [[ ! -x "${LTarget}" ]]; then
      echo "[DARWIN-COMPILE-SMOKE] Missing osxcross tool: ${LTarget}"
      return 1
    fi

    LAlias="${aAliasDir}/${aArch}-darwin-${LTool}"
    cat > "${LAlias}" <<EOF
#!/usr/bin/env bash
exec "${LTarget}" "\$@"
EOF
    chmod +x "${LAlias}"
  done
}

bootstrap_aarch64_compiler() {
  local LSourceRoot
  local LPrefix
  local LBootstrapRoot
  local LAliasDir
  local LBootstrapLog

  if ! LSourceRoot="$(detect_fpcsrc_root)"; then
    echo "[DARWIN-COMPILE-SMOKE] Missing FPC source root for aarch64 bootstrap" >&2
    return 1
  fi

  if ! LPrefix="$(detect_osxcross_prefix "aarch64")"; then
    echo "[DARWIN-COMPILE-SMOKE] Missing osxcross prefix for aarch64 bootstrap" >&2
    return 1
  fi

  LBootstrapRoot="${TMP_ROOT}/bootstrap-fpcsrc-aarch64-darwin"
  LAliasDir="${LBootstrapRoot}/bin"
  LBootstrapLog="${DETAIL_ROOT}/aarch64-darwin/bootstrap-ppcrossa64.log"
  mkdir -p "$(dirname "${LBootstrapLog}")"

  if [[ -x "${LBootstrapRoot}/compiler/ppcrossa64" ]]; then
    printf '%s\n' "${LBootstrapRoot}/compiler/ppcrossa64"
    return 0
  fi

  rm -rf "${LBootstrapRoot}"
  cp -a "${LSourceRoot}" "${LBootstrapRoot}"

  if ! create_aliases "aarch64" "${LPrefix}" "${LAliasDir}"; then
    echo "[DARWIN-COMPILE-SMOKE] Failed to create aarch64 osxcross aliases" >&2
    return 1
  fi

  echo "[DARWIN-COMPILE-SMOKE] Bootstrapping ppcrossa64 via compiler_cycle" >&2
  if ! PATH="${LAliasDir}:$PATH" make -C "${LBootstrapRoot}" \
      compiler_cycle RELEASE=1 OS_TARGET=darwin CPU_TARGET=aarch64 \
      PP="${FPC_X86_64}" FPC="${FPC_X86_64}" NOGDB=1 > "${LBootstrapLog}" 2>&1; then
    if [[ ! -x "${LBootstrapRoot}/compiler/ppcrossa64" ]]; then
      echo "[DARWIN-COMPILE-SMOKE] aarch64 bootstrap failed: ${LBootstrapLog}" >&2
      return 1
    fi
  fi

  printf '%s\n' "${LBootstrapRoot}/compiler/ppcrossa64"
}

compile_target() {
  local aArch
  local aCpuTarget
  local aCompiler
  local aRequire
  local LTargetName
  local LTargetLogDir
  local LTargetTmpRoot
  local LAliasDir
  local LRtlRoot
  local LRtlUnits
  local LUnitOutput
  local LRtlLog
  local LPrefix
  local LCompilerFlags
  local LUnit
  local LUnitBase
  local LUnitLog
  local LCompiledCount

  aArch="${1:-}"
  aCpuTarget="${2:-}"
  aCompiler="${3:-}"
  aRequire="${4:-0}"
  LTargetName="${aArch}-darwin"
  LTargetLogDir="${DETAIL_ROOT}/${LTargetName}"
  LTargetTmpRoot="${TMP_ROOT}/${LTargetName}"
  LAliasDir="${LTargetTmpRoot}/bin"
  LRtlRoot="${LTargetTmpRoot}/rtl"
  LRtlUnits="${LRtlRoot}/units/${LTargetName}"
  LUnitOutput="${LTargetTmpRoot}/simd-units"
  LRtlLog="${LTargetLogDir}/build-rtl.log"

  mkdir -p "${LTargetLogDir}"

  if [[ -z "${aCompiler}" || ! -x "${aCompiler}" ]]; then
    if is_truthy "${aRequire}"; then
      append_summary "TARGET ${LTargetName} status=FAIL detail=compiler-unavailable"
      OVERALL_STATUS="FAIL"
    else
      append_summary "TARGET ${LTargetName} status=SKIP detail=compiler-unavailable"
    fi
    return 0
  fi

  if ! LPrefix="$(detect_osxcross_prefix "${aArch}")"; then
    append_summary "TARGET ${LTargetName} status=FAIL detail=osxcross-prefix-missing"
    OVERALL_STATUS="FAIL"
    return 0
  fi

  rm -rf "${LTargetTmpRoot}"
  mkdir -p "${LTargetTmpRoot}" "${LTargetLogDir}"
  cp -a "${RTL_SOURCE_ROOT}" "${LRtlRoot}"

  if ! create_aliases "${aArch}" "${LPrefix}" "${LAliasDir}"; then
    append_summary "TARGET ${LTargetName} status=FAIL detail=osxcross-wrapper-missing"
    OVERALL_STATUS="FAIL"
    return 0
  fi

  echo "[DARWIN-COMPILE-SMOKE] ${LTargetName} building RTL"
  if ! PATH="${LAliasDir}:$PATH" make -C "${LRtlRoot}/darwin" \
      units OS_TARGET=darwin CPU_TARGET="${aCpuTarget}" \
      PP="${aCompiler}" FPC="${aCompiler}" \
      CROSSOPT="-XR${SDK_ROOT} -Xd" > "${LRtlLog}" 2>&1; then
    append_summary "TARGET ${LTargetName} status=FAIL detail=rtl-build-failed rtl_log=${LRtlLog}"
    OVERALL_STATUS="FAIL"
    return 0
  fi

  rm -rf "${LUnitOutput}"
  mkdir -p "${LUnitOutput}"
  LCompiledCount=0
  case "${aArch}" in
    x86_64)
      LCompilerFlags="-Tdarwin -Px86_64 -XPx86_64-darwin-"
      ;;
    aarch64)
      LCompilerFlags="-Tdarwin -Paarch64 -XPaarch64-darwin-"
      ;;
    *)
      append_summary "TARGET ${LTargetName} status=FAIL detail=unsupported-arch"
      OVERALL_STATUS="FAIL"
      return 0
      ;;
  esac

  for LUnit in "${UNITS[@]}"; do
    LUnitBase="$(basename "${LUnit}")"
    LUnitLog="${LTargetLogDir}/${LUnitBase}.log"
    echo "[DARWIN-COMPILE-SMOKE] ${LTargetName} compiling ${LUnit}"
    if ! PATH="${LAliasDir}:$PATH" "${aCompiler}" \
        ${LCompilerFlags} \
        -XR"${SDK_ROOT}" -Xd \
        -Fi"${REPO_ROOT}/src" \
        -Fu"${LRtlUnits}" \
        -Fu"${REPO_ROOT}/src" \
        -FE"${LUnitOutput}" \
        -FU"${LUnitOutput}" \
        "${REPO_ROOT}/${LUnit}" > "${LUnitLog}" 2>&1; then
      append_summary "TARGET ${LTargetName} status=FAIL detail=unit-compile-failed unit=${LUnit} unit_log=${LUnitLog}"
      append_summary "UNIT ${LTargetName} ${LUnit} status=FAIL log=${LUnitLog}"
      OVERALL_STATUS="FAIL"
      return 0
    fi
    append_summary "UNIT ${LTargetName} ${LUnit} status=PASS log=${LUnitLog}"
    LCompiledCount=$((LCompiledCount + 1))
  done

  append_summary "TARGET ${LTargetName} status=PASS compiler=${aCompiler} compiled=${LCompiledCount} rtl_log=${LRtlLog}"
}

mkdir -p "$(dirname "${SUMMARY_LOG}")" "${DETAIL_ROOT}"
: > "${SUMMARY_LOG}"

if [[ ! -d "${RTL_SOURCE_ROOT}" ]]; then
  append_summary "DARWIN_COMPILE_SMOKE_SUMMARY status=FAIL detail=rtl-source-missing"
  cat "${SUMMARY_LOG}"
  exit 1
fi

if [[ ! -x "${FPC_X86_64}" ]]; then
  append_summary "DARWIN_COMPILE_SMOKE_SUMMARY status=FAIL detail=fpc-x86_64-missing"
  cat "${SUMMARY_LOG}"
  exit 1
fi

if ! SDK_ROOT="$(detect_sdk_root)"; then
  append_summary "DARWIN_COMPILE_SMOKE_SUMMARY status=FAIL detail=sdk-missing"
  cat "${SUMMARY_LOG}"
  exit 1
fi

FPC_AARCH64_AUTO="$(detect_aarch64_compiler || true)"
if [[ -z "${FPC_AARCH64}" ]]; then
  FPC_AARCH64="${FPC_AARCH64_AUTO}"
fi

if [[ -z "${FPC_AARCH64}" ]] && is_truthy "${REQUIRE_AARCH64}"; then
  FPC_AARCH64="$(bootstrap_aarch64_compiler || true)"
fi

append_summary "DARWIN_COMPILE_SMOKE_CONTEXT sdk=$(sanitize_value "${SDK_ROOT}") rtl=$(sanitize_value "${RTL_SOURCE_ROOT}")"
append_summary "DARWIN_COMPILE_SMOKE_CONTEXT require_aarch64=$(sanitize_value "${REQUIRE_AARCH64}") fpc_x86_64=$(sanitize_value "${FPC_X86_64}") fpc_aarch64=$(sanitize_value "${FPC_AARCH64:-missing}")"

compile_target "x86_64" "x86_64" "${FPC_X86_64}" "1"
compile_target "aarch64" "aarch64" "${FPC_AARCH64:-}" "${REQUIRE_AARCH64}"

append_summary "DARWIN_COMPILE_SMOKE_SUMMARY status=${OVERALL_STATUS} require_aarch64=$(sanitize_value "${REQUIRE_AARCH64}") summary_log=$(sanitize_value "${SUMMARY_LOG}") detail_root=$(sanitize_value "${DETAIL_ROOT}")"
cat "${SUMMARY_LOG}"

if [[ "${OVERALL_STATUS}" != "PASS" ]]; then
  exit 1
fi
