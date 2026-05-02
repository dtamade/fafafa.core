#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUN_ALL_BAT="${REPO_ROOT}/tests/run_all_tests.bat"

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

if [[ ! -f "${RUN_ALL_BAT}" ]]; then
  fail "missing Windows run_all batch runner: ${RUN_ALL_BAT}"
fi

require_pattern() {
  local aPattern
  aPattern="${1}"
  if ! grep -F -- "${aPattern}" "${RUN_ALL_BAT}" >/dev/null; then
    fail "run_all batch missing required anti-pollution pattern: ${aPattern}"
  fi
}

forbid_pattern() {
  local aPattern
  aPattern="${1}"
  if grep -F -- "${aPattern}" "${RUN_ALL_BAT}" >/dev/null; then
    fail "run_all batch still contains forbidden fragile pattern: ${aPattern}"
  fi
}

require_pattern 'set "DISCOVERY_FILE=%LOG_DIR%\run_all_discovery.txt"'
require_pattern ':is_generated_dir'
require_pattern 'findstr /I /C:"\_run_all_logs\" /C:"\run_all\" /C:"\bin\" /C:"\lib\" /C:"\logs\" /C:"\nonx86.optin\" /C:"\dispatch.preinit.smoke\"'
require_pattern ':collect_module_dir'
require_pattern 'set "__FILTER_REST=%FILTER%"'
require_pattern ':should_run_next'
require_pattern 'for /f "tokens=1,* delims= " %%A in ("!__FILTER_REST!") do ('
require_pattern 'set "__F_RAW=%%A"'
require_pattern 'set "__FILTER_REST=%%B"'
require_pattern 'call :collect_module_dir "%TESTS_ROOT%"'
require_pattern 'dir /b /s /ad "%TESTS_ROOT%" 2^>nul'
require_pattern 'for /f "usebackq delims=" %%F in ("%DISCOVERY_FILE%") do call :run_one "%%F"'
require_pattern 'echo [PASS] !MOD_FULL! ^(rc=%RC%^)'
require_pattern 'echo [FAIL] !MOD_FULL! ^(rc=%RC%^)'

forbid_pattern 'for /R "%TESTS_ROOT%" %%F in (BuildOrTest.bat) do call :run_one "%%~fF"'
forbid_pattern 'for /R "%TESTS_ROOT%" %%F in (buildOrTest.bat) do call :run_one "%%~fF"'
forbid_pattern 'for /R "%TESTS_ROOT%" %%F in (BuildAndTest.bat) do call :run_one "%%~fF"'
forbid_pattern 'for %%F in (%FILTER%) do ('
forbid_pattern 'echo [PASS] !MOD_FULL! (rc=%RC%)'
forbid_pattern 'echo [FAIL] !MOD_FULL! (rc=%RC%)'

echo "[PASS] windows run_all batch anti-pollution structure verified"
