#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG_ROOT="${ROOT}/logs"
LINUX_ARTIFACT_DIR="${1:-}"
WINDOWS_ARTIFACT_DIR="${2:-}"

print_usage() {
  cat <<'EOF'
Usage: restore_nightly_evidence_artifacts.sh <linux-artifact-dir> <windows-artifact-dir>

Restore nightly CI artifacts into the canonical paths expected by:
- tests/fafafa.core.simd/BuildOrTest.sh freeze-status
- tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize
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

find_first_file() {
  local aDir
  local aName

  aDir="$1"
  aName="$2"
  find "${aDir}" -type f -name "${aName}" | sort | head -n 1 || true
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

  mkdir -p "$(dirname "${aTarget}")"
  cp "${aSource}" "${aTarget}"
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

require_arg_dir "linux artifact" "${LINUX_ARTIFACT_DIR}"
require_arg_dir "windows artifact" "${WINDOWS_ARTIFACT_DIR}"

mkdir -p "${LOG_ROOT}"

copy_required_file \
  "$(find_first_file "${LINUX_ARTIFACT_DIR}" 'gate_summary.md')" \
  "${LOG_ROOT}/gate_summary.md"
copy_required_file \
  "$(find_first_file "${LINUX_ARTIFACT_DIR}" 'gate_summary.json')" \
  "${LOG_ROOT}/gate_summary.json"
copy_required_file \
  "$(find_first_file "${WINDOWS_ARTIFACT_DIR}" 'windows_b07_gate.log')" \
  "${LOG_ROOT}/windows_b07_gate.log"

if ! copy_optional_dirs "${LINUX_ARTIFACT_DIR}" 'qemu-multiarch-*'; then
  echo "[RESTORE] Missing qemu-multiarch-* directories in ${LINUX_ARTIFACT_DIR}"
  exit 1
fi

copy_optional_dirs "${LINUX_ARTIFACT_DIR}" 'evidence-*' || true

echo "[RESTORE] OK"
