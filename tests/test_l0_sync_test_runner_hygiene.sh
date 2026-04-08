#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

BAT_TARGETS=(
  "${ROOT}/tests/fafafa.core.sync/BuildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.event/BuildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.mutex/BuildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedBarrier/BuildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedCondvar/BuildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedEvent/BuildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedMutex/BuildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedRWLock/BuildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedSemaphore/BuildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.rwlock/BuildOrTest.bat"
)

DELETED_ALIAS_TARGETS=(
  "${ROOT}/tests/fafafa.core.sync.namedBarrier/buildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedCondvar/buildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedEvent/buildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedMutex/buildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedRWLock/buildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.namedSemaphore/buildOrTest.bat"
  "${ROOT}/tests/fafafa.core.sync.rwlock/buildOrTest.bat"
)

for LTarget in "${BAT_TARGETS[@]}"; do
  if [[ ! -f "${LTarget}" ]]; then
    echo "[FAIL] missing sync test runner: ${LTarget}" >&2
    exit 1
  fi

  if grep -Fq -- '--build-mode=Debug' "${LTarget}"; then
    echo "[FAIL] test runner still forces Debug mode: ${LTarget}" >&2
    exit 1
  fi

  if grep -Fq -- 'set /p' "${LTarget}"; then
    echo "[FAIL] test runner still uses interactive input: ${LTarget}" >&2
    exit 1
  fi

  if grep -Fq -- 'if "%FAFAFA_INTERACTIVE%"=="1" if "%FAFAFA_INTERACTIVE%"=="1" pause' "${LTarget}"; then
    echo "[FAIL] test runner still contains broken double interactive pause template: ${LTarget}" >&2
    exit 1
  fi
done

for LTarget in "${DELETED_ALIAS_TARGETS[@]}"; do
  if [[ -e "${LTarget}" ]]; then
    echo "[FAIL] stale test alias still exists: ${LTarget}" >&2
    exit 1
  fi
done

echo "[PASS] L0 sync test runners are aligned with current batch hygiene rules"
