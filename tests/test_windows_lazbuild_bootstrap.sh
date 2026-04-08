#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP_BAT="${REPO_ROOT}/tools/lazbuild.bat"

if [[ ! -f "${BOOTSTRAP_BAT}" ]]; then
  echo "[FAIL] missing Windows lazbuild bootstrap: ${BOOTSTRAP_BAT}" >&2
  exit 1
fi

if ! rg -n "lazbuild" "${BOOTSTRAP_BAT}" >/dev/null; then
  echo "[FAIL] Windows lazbuild bootstrap does not mention lazbuild lookup logic" >&2
  exit 1
fi

if command -v wine >/dev/null 2>&1; then
  WIN_REPO_ROOT="Z:\\$(printf '%s' "${REPO_ROOT}" | sed 's#^/##; s#/#\\\\#g')"
  set +e
  OUTPUT="$(wine cmd /c "cd /d ${WIN_REPO_ROOT} && call tools\\lazbuild.bat --help" 2>&1)"
  RC=$?
  set -e

  if ! printf '%s' "${OUTPUT}" | rg -n "\[ERROR\] lazbuild|lazbuild" >/dev/null; then
    echo "[FAIL] Windows lazbuild bootstrap did not execute expected bootstrap path" >&2
    printf '%s\n' "${OUTPUT}" >&2
    exit 1
  fi

  if printf '%s' "${OUTPUT}" | rg -n "Can't recognize|not recognized as an internal or external command" >/dev/null; then
    echo "[FAIL] Windows lazbuild bootstrap was not callable under wine cmd" >&2
    printf '%s\n' "${OUTPUT}" >&2
    exit 1
  fi

  echo "[INFO] wine invocation exit code: ${RC}"

  set +e
  OUTPUT_UNIX_EXE="$(wine cmd /c "set LAZBUILD_EXE=Z:\\opt\\fpcupdeluxe\\lazarus\\lazbuild && cd /d ${WIN_REPO_ROOT} && call tools\\lazbuild.bat --help" 2>&1)"
  RC_UNIX_EXE=$?
  set -e

  if ! printf '%s' "${OUTPUT_UNIX_EXE}" | rg -n "non-Windows executable|Windows lazbuild executable|lazbuild.exe" >/dev/null; then
    echo "[FAIL] Windows lazbuild bootstrap did not explain Unix-path LAZBUILD_EXE clearly" >&2
    printf '%s\n' "${OUTPUT_UNIX_EXE}" >&2
    exit 1
  fi

  if printf '%s' "${OUTPUT_UNIX_EXE}" | rg -n "Can't recognize|not recognized as an internal or external command" >/dev/null; then
    echo "[FAIL] Windows lazbuild bootstrap leaked raw cmd execution error for Unix-path LAZBUILD_EXE" >&2
    printf '%s\n' "${OUTPUT_UNIX_EXE}" >&2
    exit 1
  fi

  echo "[INFO] wine unix-path invocation exit code: ${RC_UNIX_EXE}"
fi

echo "[PASS] windows lazbuild bootstrap contract verified"
