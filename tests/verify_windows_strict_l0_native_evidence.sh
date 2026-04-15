#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_DOWNLOAD_ROOT="${REPO_ROOT}/tests/_windows_l0_native_evidence_gh"
SNAPSHOT_INPUT="${1:-}"
EXPECTED_COMMIT="${2:-${L0_NATIVE_EVIDENCE_EXPECT_COMMIT:-}}"
EXPECTED_REF="${3:-${L0_NATIVE_EVIDENCE_EXPECT_REF:-}}"

print_usage() {
  cat <<EOF
Usage: $0 [snapshot-root] [expected-commit] [expected-ref]

Default snapshot-root: latest directory under tests/_windows_l0_native_evidence_gh

Examples:
  bash tests/verify_windows_strict_l0_native_evidence.sh
  bash tests/verify_windows_strict_l0_native_evidence.sh tests/_windows_l0_native_evidence_gh/L0-20260409-gha
  bash tests/verify_windows_strict_l0_native_evidence.sh tests/_windows_l0_native_evidence_gh/L0-20260409-gha <commit> <ref>

Exit codes:
  0   success
  1   artifact contract mismatch
  2   invalid usage / missing snapshot
EOF
}

if [[ "${SNAPSHOT_INPUT}" == "-h" || "${SNAPSHOT_INPUT}" == "--help" ]]; then
  print_usage
  exit 0
fi

trim_value() {
  printf '%s' "${1:-}" | tr -d '\r' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'
}

find_unique_downloaded_file() {
  local aSearchRoot="${1:-}"
  local aName="${2:-}"
  local aLabel="${3:-${aName}}"
  local -a LCandidates

  mapfile -t LCandidates < <(find "${aSearchRoot}" -type f -name "${aName}" | sort)
  if [[ "${#LCandidates[@]}" == "0" ]]; then
    return 10
  fi

  if [[ "${#LCandidates[@]}" != "1" ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Refuse artifact: multiple ${aLabel} files found in snapshot:" >&2
    printf '  - %s\n' "${LCandidates[@]}" >&2
    return 11
  fi

  printf '%s\n' "${LCandidates[0]}"
}

find_unique_downloaded_dir() {
  local aSearchRoot="${1:-}"
  local aName="${2:-}"
  local aLabel="${3:-${aName}}"
  local -a LCandidates

  mapfile -t LCandidates < <(find "${aSearchRoot}" -type d -name "${aName}" | sort)
  if [[ "${#LCandidates[@]}" == "0" ]]; then
    return 10
  fi

  if [[ "${#LCandidates[@]}" != "1" ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Refuse artifact: multiple ${aLabel} directories found in snapshot:" >&2
    printf '  - %s\n' "${LCandidates[@]}" >&2
    return 11
  fi

  printf '%s\n' "${LCandidates[0]}"
}

require_literal_in_file() {
  local aFile="${1:-}"
  local aPattern="${2:-}"
  local aLabel="${3:-pattern}"

  if ! grep -F -- "${aPattern}" "${aFile}" >/dev/null 2>&1; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Missing ${aLabel} in ${aFile}: ${aPattern}" >&2
    return 1
  fi

  return 0
}

extract_kv_value() {
  local aFile="${1:-}"
  local aKey="${2:-}"

  awk -F= -v key="${aKey}" '
    $1 == key {
      sub($1 "=","")
      gsub(/\r/, "")
      print
      exit
    }
  ' "${aFile}"
}

require_kv_value() {
  local aFile="${1:-}"
  local aKey="${2:-}"
  local aLabel="${3:-${aKey}}"
  local LValue

  LValue="$(trim_value "$(extract_kv_value "${aFile}" "${aKey}")")"
  if [[ -z "${LValue}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Missing ${aLabel} in ${aFile}: ${aKey}=" >&2
    return 1
  fi

  printf '%s\n' "${LValue}"
}

extract_prefixed_value() {
  local aFile="${1:-}"
  local aPrefix="${2:-}"

  awk -v prefix="${aPrefix}" '
    index($0, prefix) == 1 {
      line = substr($0, length(prefix) + 1)
      gsub(/\r/, "", line)
      print line
      exit
    }
  ' "${aFile}"
}

normalize_ref_hint() {
  local aValue

  aValue="$(trim_value "${1:-}")"
  aValue="${aValue#refs/heads/}"
  aValue="${aValue#origin/}"
  printf '%s\n' "${aValue}"
}

resolve_snapshot_root() {
  local aInput="${1:-}"
  local LLatest

  if [[ -n "${aInput}" ]]; then
    printf '%s\n' "${aInput}"
    return 0
  fi

  if [[ ! -d "${DEFAULT_DOWNLOAD_ROOT}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Missing default snapshot root: ${DEFAULT_DOWNLOAD_ROOT}" >&2
    return 2
  fi

  LLatest="$(find "${DEFAULT_DOWNLOAD_ROOT}" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
  if [[ -z "${LLatest}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] No snapshot directories found under: ${DEFAULT_DOWNLOAD_ROOT}" >&2
    return 2
  fi

  printf '%s\n' "${LLatest}"
}

verify_downloaded_evidence_snapshot() {
  local aSnapshotRoot="${1:-}"
  local aExpectedCommit="${2:-}"
  local aExpectedRef="${3:-}"
  local LEvidenceLog
  local LSummaryPath
  local LSourceRevisionPath
  local LEnvironmentPath
  local LMatrixLog
  local LWhereLazbuildPath
  local LModuleLogDir
  local LEvidenceDir
  local LWorkingDir
  local LGitCommit
  local LGitRefHint
  local LHostOs
  local LToolWrapper
  local LWhereLazbuildValue
  local LExpectedCommitLower
  local LGitCommitLower
  local LExpectedRefNormalized
  local LGitRefNormalized
  local LModuleName

  if [[ ! -d "${aSnapshotRoot}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Missing snapshot root: ${aSnapshotRoot}" >&2
    return 2
  fi

  set +e
  LEvidenceLog="$(find_unique_downloaded_file "${aSnapshotRoot}" 'evidence.log' 'evidence log')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-SHELL] Missing evidence.log in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LSummaryPath="$(find_unique_downloaded_file "${aSnapshotRoot}" 'summary.md' 'summary')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-SHELL] Missing summary.md in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LSourceRevisionPath="$(find_unique_downloaded_file "${aSnapshotRoot}" 'source_revision.txt' 'source revision')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-SHELL] Missing source_revision.txt in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LEnvironmentPath="$(find_unique_downloaded_file "${aSnapshotRoot}" 'environment.txt' 'environment')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-SHELL] Missing environment.txt in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LMatrixLog="$(find_unique_downloaded_file "${aSnapshotRoot}" 'native_matrix.log' 'native matrix log')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-SHELL] Missing native_matrix.log in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LWhereLazbuildPath="$(find_unique_downloaded_file "${aSnapshotRoot}" 'where_lazbuild_exe.txt' 'where lazbuild evidence')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-SHELL] Missing where_lazbuild_exe.txt in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac

  LModuleLogDir="$(find_unique_downloaded_dir "${aSnapshotRoot}" 'module-logs' 'module log')"
  case $? in
    0) ;;
    10)
      echo "[L0-NATIVE-EVIDENCE-SHELL] Missing module-logs directory in downloaded artifact snapshot: ${aSnapshotRoot}" >&2
      return 1
      ;;
    *)
      return 1
      ;;
  esac
  set -e

  LEvidenceDir="$(dirname "${LEvidenceLog}")"

  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] strict L0 Windows native evidence capture' 'collector source marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] Source: collect_windows_strict_l0_native_evidence.bat' 'collector batch source'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] HostOS: Windows_NT' 'Windows host marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] MatrixCommand: tests\test_windows_strict_l0_batch_native_matrix.bat' 'matrix command marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] Total: 12' 'module total marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] Passed: 12' 'module pass marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] Failed: 0' 'module fail marker'
  require_literal_in_file "${LEvidenceLog}" '[L0-NATIVE] MATRIX_EXIT_CODE=0' 'matrix rc marker'

  LWorkingDir="$(trim_value "$(extract_prefixed_value "${LEvidenceLog}" '[L0-NATIVE] Working dir: ')")"
  if [[ -z "${LWorkingDir}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Missing Windows working dir marker in ${LEvidenceLog}" >&2
    return 1
  fi
  if [[ ! "${LWorkingDir}" == [A-Za-z]:\\* ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Invalid Windows working dir in ${LEvidenceLog}: ${LWorkingDir}" >&2
    return 1
  fi

  require_literal_in_file "${LSummaryPath}" '- Result: PASS' 'summary PASS marker'
  require_literal_in_file "${LMatrixLog}" '[PASS] strict L0 Windows native batch matrix verified' 'matrix PASS marker'

  LGitCommit="$(require_kv_value "${LSourceRevisionPath}" 'git_commit' 'source revision commit')"
  LGitRefHint="$(require_kv_value "${LSourceRevisionPath}" 'git_ref_hint' 'source revision ref hint')"
  LHostOs="$(require_kv_value "${LEnvironmentPath}" 'host_os' 'environment host_os')"
  LToolWrapper="$(require_kv_value "${LEnvironmentPath}" 'tool_lazbuild_wrapper' 'environment lazbuild wrapper')"
  LWhereLazbuildValue="$(require_kv_value "${LEnvironmentPath}" 'where_lazbuild_exe' 'environment where lazbuild path')"

  if [[ "${LHostOs}" != "Windows_NT" ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Invalid host_os in ${LEnvironmentPath}: ${LHostOs}" >&2
    return 1
  fi
  if [[ ! "${LToolWrapper}" == [A-Za-z]:\\* ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Invalid tool_lazbuild_wrapper path in ${LEnvironmentPath}: ${LToolWrapper}" >&2
    return 1
  fi
  if [[ ! "${LWhereLazbuildValue}" == [A-Za-z]:\\* ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Invalid where_lazbuild_exe path in ${LEnvironmentPath}: ${LWhereLazbuildValue}" >&2
    return 1
  fi
  if [[ ! -s "${LWhereLazbuildPath}" ]]; then
    echo "[L0-NATIVE-EVIDENCE-SHELL] Empty where_lazbuild_exe.txt evidence: ${LWhereLazbuildPath}" >&2
    return 1
  fi

  if [[ -n "${aExpectedCommit}" ]]; then
    LExpectedCommitLower="$(printf '%s' "${aExpectedCommit}" | tr '[:upper:]' '[:lower:]')"
    LGitCommitLower="$(printf '%s' "${LGitCommit}" | tr '[:upper:]' '[:lower:]')"
    if [[ "${LGitCommitLower}" != "${LExpectedCommitLower}" ]]; then
      echo "[L0-NATIVE-EVIDENCE-SHELL] Downloaded artifact commit mismatch: expected=${aExpectedCommit} actual=${LGitCommit}" >&2
      return 1
    fi
  fi

  if [[ -n "${aExpectedRef}" ]]; then
    LExpectedRefNormalized="$(normalize_ref_hint "${aExpectedRef}")"
    LGitRefNormalized="$(normalize_ref_hint "${LGitRefHint}")"
    if [[ "${LGitRefNormalized}" != "${LExpectedRefNormalized}" ]]; then
      echo "[L0-NATIVE-EVIDENCE-SHELL] Downloaded artifact ref mismatch: expected=${aExpectedRef} actual=${LGitRefHint}" >&2
      return 1
    fi
  fi

  for LModuleName in \
    base.log \
    contracts.log \
    bits.log \
    layout.log \
    endian.log \
    span.log \
    option.log \
    result.log \
    platform.log \
    atomic.log \
    mem_allocator_foundation.log \
    mem_allocator_only.log; do
    if [[ ! -f "${LModuleLogDir}/${LModuleName}" ]]; then
      echo "[L0-NATIVE-EVIDENCE-SHELL] Missing module log in snapshot: ${LModuleLogDir}/${LModuleName}" >&2
      return 1
    fi
    require_literal_in_file "${LModuleLogDir}/${LModuleName}" '[BUILD] OK' "module build marker (${LModuleName})"
    require_literal_in_file "${LModuleLogDir}/${LModuleName}" '[TEST] OK' "module test marker (${LModuleName})"
    require_literal_in_file "${LModuleLogDir}/${LModuleName}" '[LEAK] OK' "module leak marker (${LModuleName})"
  done

  echo "[L0-NATIVE-EVIDENCE-SHELL] Downloaded artifact contract verified on Linux shell"
  echo "[L0-NATIVE-EVIDENCE-SHELL] Snapshot root: ${aSnapshotRoot}"
  echo "[L0-NATIVE-EVIDENCE-SHELL] Evidence dir: ${LEvidenceDir}"
  echo "[L0-NATIVE-EVIDENCE-SHELL] Summary: ${LSummaryPath}"
  echo "[L0-NATIVE-EVIDENCE-SHELL] Source revision: ${LSourceRevisionPath}"
  echo "[L0-NATIVE-EVIDENCE-SHELL] Environment: ${LEnvironmentPath}"
  echo "[L0-NATIVE-EVIDENCE-SHELL] where lazbuild evidence: ${LWhereLazbuildPath}"
  echo "[L0-NATIVE-EVIDENCE-SHELL] Canonical native PASS still comes from the Windows-host collector + verifier inside the workflow."
}

LSnapshotRoot="$(resolve_snapshot_root "${SNAPSHOT_INPUT}")"
LResolveRc=$?
if [[ "${LResolveRc}" != "0" ]]; then
  exit "${LResolveRc}"
fi

verify_downloaded_evidence_snapshot "${LSnapshotRoot}" "${EXPECTED_COMMIT}" "${EXPECTED_REF}"
