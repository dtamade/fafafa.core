#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_ROOT="${ROOT}/logs"
LINUX_ARTIFACT_DIR="${1:-}"
WINDOWS_ARTIFACT_DIR="${2:-}"
NEON_NATIVE_ARTIFACT_DIR="${3:-}"
RISCVV_NATIVE_ARTIFACT_DIR="${4:-}"

print_usage() {
  cat <<'EOF'
Usage: restore_nightly_evidence_artifacts.sh <linux-artifact-dir> <windows-artifact-dir> [arm64-neon-artifact-dir] [riscvv-native-artifact-dir]

Restore nightly CI artifacts into the canonical paths expected by:
- tests/fafafa.core.simd/BuildOrTest.sh freeze-status
- tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize

Optional native artifact dirs let you restore extra non-x86 native evidence snapshots:
- ARM64 NEON: native-evidence-neon-*
- RISCVV: native-evidence-riscvv-*
EOF
}

require_arg_dir() {
  local aLabel
  local aDir

  aLabel="$1"
  aDir="$2"

  if [[ -z "${aDir}" ]]; then
    echo "[RESTORE] Missing ${aLabel} directory"
    print_usage
    exit 2
  fi
  if [[ ! -d "${aDir}" ]]; then
    echo "[RESTORE] Missing ${aLabel} directory: ${aDir}"
    exit 2
  fi
}

find_unique_file() {
  local aDir
  local aName
  local aLabel
  local -a LCandidates

  aDir="$1"
  aName="$2"
  aLabel="${3:-${aName}}"

  mapfile -t LCandidates < <(find "${aDir}" -type f -name "${aName}" | sort)
  if [[ "${#LCandidates[@]}" == "0" ]]; then
    return 10
  fi
  if [[ "${#LCandidates[@]}" != "1" ]]; then
    echo "[RESTORE] Refuse artifact: multiple ${aLabel} files found in ${aDir}" >&2
    printf '  - %s\n' "${LCandidates[@]}" >&2
    return 11
  fi

  printf '%s\n' "${LCandidates[0]}"
}

has_matching_dirs() {
  local aSourceDir
  local aPattern

  aSourceDir="$1"
  aPattern="$2"
  find "${aSourceDir}" -type d -name "${aPattern}" -print -quit | grep -q .
}

copy_file_preserve_mtime() {
  local aSource
  local aTarget

  aSource="$1"
  aTarget="$2"

  mkdir -p "$(dirname "${aTarget}")"
  cp -p "${aSource}" "${aTarget}"
}

copy_required_file() {
  local aSource
  local aTarget

  aSource="$1"
  aTarget="$2"

  if [[ -z "${aSource}" || ! -f "${aSource}" ]]; then
    echo "[RESTORE] Missing required file for ${aTarget}"
    exit 1
  fi

  copy_file_preserve_mtime "${aSource}" "${aTarget}"
  echo "[RESTORE] file: ${aSource} -> ${aTarget}"
}

copy_optional_dirs() {
  local aSourceDir
  local aPattern
  local LFoundAny
  local LDir

  aSourceDir="$1"
  aPattern="$2"
  LFoundAny=1

  while IFS= read -r -d '' LDir; do
    cp -a "${LDir}" "${LOG_ROOT}/"
    echo "[RESTORE] dir: ${LDir} -> ${LOG_ROOT}/$(basename "${LDir}")"
    LFoundAny=0
  done < <(find "${aSourceDir}" -type d -name "${aPattern}" -print0 | sort -z)

  return "${LFoundAny}"
}

clear_matching_target_dirs() {
  local aPattern
  local LDir

  aPattern="$1"
  while IFS= read -r -d '' LDir; do
    rm -rf "${LDir}"
    echo "[RESTORE] clear: ${LDir}"
  done < <(find "${LOG_ROOT}" -maxdepth 1 -type d -name "${aPattern}" -print0 | sort -z)
}

require_arg_dir "linux artifact" "${LINUX_ARTIFACT_DIR}"
require_arg_dir "windows artifact" "${WINDOWS_ARTIFACT_DIR}"
if [[ -n "${NEON_NATIVE_ARTIFACT_DIR}" ]]; then
  require_arg_dir "arm64 neon native artifact" "${NEON_NATIVE_ARTIFACT_DIR}"
fi
if [[ -n "${RISCVV_NATIVE_ARTIFACT_DIR}" ]]; then
  require_arg_dir "riscvv native artifact" "${RISCVV_NATIVE_ARTIFACT_DIR}"
fi

mkdir -p "${LOG_ROOT}"

set +e
LINUX_GATE_SUMMARY_MD="$(find_unique_file "${LINUX_ARTIFACT_DIR}" 'gate_summary.md' 'linux gate summary md')"
LLinuxGateSummaryMdRc=$?
LINUX_GATE_SUMMARY_JSON="$(find_unique_file "${LINUX_ARTIFACT_DIR}" 'gate_summary.json' 'linux gate summary json')"
LLinuxGateSummaryJsonRc=$?
WINDOWS_EVIDENCE_LOG="$(find_unique_file "${WINDOWS_ARTIFACT_DIR}" 'windows_b07_gate.log' 'windows evidence log')"
LWindowsEvidenceLogRc=$?
set -e

case "${LLinuxGateSummaryMdRc}" in
  0)
    ;;
  10)
    echo "[RESTORE] Missing required file for ${LOG_ROOT}/gate_summary.md"
    exit 1
    ;;
  *)
    exit 1
    ;;
esac
case "${LLinuxGateSummaryJsonRc}" in
  0)
    ;;
  10)
    echo "[RESTORE] Missing required file for ${LOG_ROOT}/gate_summary.json"
    exit 1
    ;;
  *)
    exit 1
    ;;
esac
case "${LWindowsEvidenceLogRc}" in
  0)
    ;;
  10)
    echo "[RESTORE] Missing required file for ${LOG_ROOT}/windows_b07_gate.log"
    exit 1
    ;;
  *)
    exit 1
    ;;
esac
if ! has_matching_dirs "${LINUX_ARTIFACT_DIR}" 'qemu-multiarch-*'; then
  echo "[RESTORE] Missing qemu-multiarch-* directories in ${LINUX_ARTIFACT_DIR}"
  exit 1
fi
if [[ -n "${NEON_NATIVE_ARTIFACT_DIR}" ]] && ! has_matching_dirs "${NEON_NATIVE_ARTIFACT_DIR}" 'native-evidence-neon-*'; then
  echo "[RESTORE] Missing native-evidence-neon-* directories in ${NEON_NATIVE_ARTIFACT_DIR}"
  exit 1
fi
if [[ -n "${RISCVV_NATIVE_ARTIFACT_DIR}" ]] && ! has_matching_dirs "${RISCVV_NATIVE_ARTIFACT_DIR}" 'native-evidence-riscvv-*'; then
  echo "[RESTORE] Missing native-evidence-riscvv-* directories in ${RISCVV_NATIVE_ARTIFACT_DIR}"
  exit 1
fi

clear_matching_target_dirs 'qemu-multiarch-*'
clear_matching_target_dirs 'evidence-*'
clear_matching_target_dirs 'native-evidence-neon-*'
clear_matching_target_dirs 'native-evidence-riscvv-*'

copy_required_file "${LINUX_GATE_SUMMARY_MD}" "${LOG_ROOT}/gate_summary.md"
copy_required_file "${LINUX_GATE_SUMMARY_JSON}" "${LOG_ROOT}/gate_summary.json"
copy_required_file "${WINDOWS_EVIDENCE_LOG}" "${LOG_ROOT}/windows_b07_gate.log"

if ! copy_optional_dirs "${LINUX_ARTIFACT_DIR}" 'qemu-multiarch-*'; then
  echo "[RESTORE] Missing qemu-multiarch-* directories in ${LINUX_ARTIFACT_DIR}"
  exit 1
fi

copy_optional_dirs "${LINUX_ARTIFACT_DIR}" 'evidence-*' || true
if [[ -n "${NEON_NATIVE_ARTIFACT_DIR}" ]]; then
  if ! copy_optional_dirs "${NEON_NATIVE_ARTIFACT_DIR}" 'native-evidence-neon-*'; then
    echo "[RESTORE] Missing native-evidence-neon-* directories in ${NEON_NATIVE_ARTIFACT_DIR}"
    exit 1
  fi
fi
if [[ -n "${RISCVV_NATIVE_ARTIFACT_DIR}" ]]; then
  if ! copy_optional_dirs "${RISCVV_NATIVE_ARTIFACT_DIR}" 'native-evidence-riscvv-*'; then
    echo "[RESTORE] Missing native-evidence-riscvv-* directories in ${RISCVV_NATIVE_ARTIFACT_DIR}"
    exit 1
  fi
fi

echo "[RESTORE] OK"
