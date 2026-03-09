#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

LAZBUILD_BIN="${LAZBUILD:-}"
if [[ -z "${LAZBUILD_BIN}" ]]; then
  if [[ -x "${SCRIPT_DIR}/../../tools/lazbuild.sh" ]]; then
    LAZBUILD_BIN="${SCRIPT_DIR}/../../tools/lazbuild.sh"
  else
    LAZBUILD_BIN="lazbuild"
  fi
fi

detect_lazarusdir() {
  if [[ -n "${FAFAFA_LAZARUSDIR:-}" && -d "${FAFAFA_LAZARUSDIR}/lcl" ]]; then
    echo "${FAFAFA_LAZARUSDIR}"
    return 0
  fi

  if [[ -n "${LAZARUS_DIR:-}" && -d "${LAZARUS_DIR}/lcl" ]]; then
    echo "${LAZARUS_DIR}"
    return 0
  fi

  local LCandidate
  for LCandidate in \
    "/opt/fpcupdeluxe/lazarus" \
    "/usr/lib/lazarus" \
    "/usr/local/share/lazarus" \
    "/usr/share/lazarus"; do
    if [[ -d "${LCandidate}/lcl" ]]; then
      echo "${LCandidate}"
      return 0
    fi
  done

  local LLazbuildPath
  local LMaybeRoot
  LLazbuildPath="$(command -v lazbuild 2>/dev/null || true)"
  if [[ -n "${LLazbuildPath}" ]]; then
    LMaybeRoot="$(cd "$(dirname "${LLazbuildPath}")" && pwd)"
    if [[ -d "${LMaybeRoot}/lcl" ]]; then
      echo "${LMaybeRoot}"
      return 0
    fi
    LMaybeRoot="$(cd "${LMaybeRoot}/.." 2>/dev/null && pwd || true)"
    if [[ -n "${LMaybeRoot}" && -d "${LMaybeRoot}/lcl" ]]; then
      echo "${LMaybeRoot}"
      return 0
    fi
  fi

  echo ""
  return 0
}

LAZARUS_DIR="$(detect_lazarusdir)"
if [[ -z "${LAZARUS_DIR}" ]]; then
  echo "[ERROR] Lazarus root not found (missing lcl directory)." >&2
  echo "[HINT] Set FAFAFA_LAZARUSDIR or LAZARUS_DIR, e.g. /opt/fpcupdeluxe/lazarus" >&2
  exit 2
fi

PCP_DIR="${SCRIPT_DIR}/.lazarus"
mkdir -p "${PCP_DIR}"

PROJECT="tests_toml.lpi"
TEST_EXECUTABLE="./bin/tests_toml"


echo "Building project: ${PROJECT}..."
"${LAZBUILD_BIN}" "--pcp=${PCP_DIR}" "--lazarusdir=${LAZARUS_DIR}" "${PROJECT}"

echo
echo "Build successful."
echo

ACTION="${1:-}"
if [[ "${ACTION}" == "test" || "${ACTION}" == "run" ]]; then
  if [[ -x "${TEST_EXECUTABLE}" ]]; then
    echo "Running tests..."
    "${TEST_EXECUTABLE}" --all --format=plain
  elif [[ -x "${TEST_EXECUTABLE}.exe" ]]; then
    echo "Running tests..."
    "${TEST_EXECUTABLE}.exe" --all --format=plain
  else
    echo "[ERROR] Test executable not found: ${TEST_EXECUTABLE}[.exe]" >&2
    exit 1
  fi
else
  echo "To run tests, call this script with the 'test' parameter."
fi
