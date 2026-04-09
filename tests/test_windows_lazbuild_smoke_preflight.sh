#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BOOTSTRAP_BAT="${REPO_ROOT}/tools/lazbuild.bat"
WIN_REPO_ROOT="Z:\\$(printf '%s' "${REPO_ROOT}" | sed 's#^/##; s#/#\\\\#g')"

fail() {
  echo "[FAIL] $1" >&2
  exit "${2:-1}"
}

info() {
  echo "[INFO] $1"
}

pass() {
  echo "[PASS] $1"
}

print_windows_recovery_guidance() {
  echo "[INFO] To unblock Windows module smoke, provide a real Windows lazbuild.exe."
  echo "[INFO] Example CMD setup:"
  echo "[INFO]   set LAZBUILD_EXE=C:\\Lazarus\\lazbuild.exe"
  echo "[INFO]   rem or: set LAZBUILD_EXE=%ProgramFiles%\\Lazarus\\lazbuild.exe"
  echo "[INFO] Then rerun:"
  echo "[INFO]   bash tests/test_windows_lazbuild_smoke_preflight.sh"
  echo "[INFO]   tests\\fafafa.core.platform\\BuildOrTest.bat test"
}

if [[ ! -f "${BOOTSTRAP_BAT}" ]]; then
  fail "missing Windows lazbuild bootstrap: ${BOOTSTRAP_BAT}" 1
fi

if ! command -v wine >/dev/null 2>&1; then
  fail "wine not found; cannot run Windows lazbuild smoke preflight" 20
fi

set +e
WHERE_OUTPUT="$(wine cmd /c "where lazbuild.exe" 2>&1)"
WHERE_RC=$?
set -e

if [[ ${WHERE_RC} -eq 0 ]]; then
  info "wine PATH exposes lazbuild.exe:"
  printf '%s\n' "${WHERE_OUTPUT}"
else
  info "wine PATH does not expose lazbuild.exe"
fi

set +e
BOOTSTRAP_OUTPUT="$(wine cmd /c "cd /d ${WIN_REPO_ROOT} && call tools\\lazbuild.bat --help" 2>&1)"
BOOTSTRAP_RC=$?
set -e

if printf '%s' "${BOOTSTRAP_OUTPUT}" | rg -n "Can't recognize|not recognized as an internal or external command" >/dev/null; then
  printf '%s\n' "${BOOTSTRAP_OUTPUT}" >&2
  fail "tools\\lazbuild.bat was not callable under wine cmd" 33
fi

if printf '%s' "${BOOTSTRAP_OUTPUT}" | rg -n "non-Windows executable" >/dev/null; then
  printf '%s\n' "${BOOTSTRAP_OUTPUT}" >&2
  print_windows_recovery_guidance
  fail "LAZBUILD_EXE points to a non-Windows executable; use lazbuild.exe from a Windows Lazarus install" 32
fi

if printf '%s' "${BOOTSTRAP_OUTPUT}" | rg -n "\[ERROR\] lazbuild not found\. Set LAZBUILD_EXE or install Lazarus\." >/dev/null; then
  printf '%s\n' "${BOOTSTRAP_OUTPUT}" >&2
  print_windows_recovery_guidance
  fail "Windows module smoke is blocked: no Windows lazbuild.exe is available to BuildOrTest.bat" 31
fi

info "wine bootstrap invocation exit code: ${BOOTSTRAP_RC}"
printf '%s\n' "${BOOTSTRAP_OUTPUT}"
pass "Windows lazbuild smoke preflight passed"
