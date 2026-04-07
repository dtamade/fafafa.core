#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECKER="${SCRIPT_DIR}/check_repo_hygiene.sh"

if [[ ! -x "${CHECKER}" ]]; then
  echo "[FAIL] missing checker: ${CHECKER}" >&2
  exit 1
fi

TMPDIR_ROOT="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_ROOT}"' EXIT

CLEAN_REPO="${TMPDIR_ROOT}/clean-repo"
DIRTY_REPO="${TMPDIR_ROOT}/dirty-repo"
mkdir -p "${CLEAN_REPO}/src" "${DIRTY_REPO}/src"

if ! "${CHECKER}" "${CLEAN_REPO}" >/dev/null; then
  echo "[FAIL] clean repo should pass hygiene check" >&2
  exit 1
fi

touch "${DIRTY_REPO}/src/fake.ppu"
if "${CHECKER}" "${DIRTY_REPO}" >/dev/null 2>&1; then
  echo "[FAIL] dirty repo should fail hygiene check" >&2
  exit 1
fi

if ! bash "${SCRIPT_DIR}/run_all_tests.sh" =__no_such_module__ >/dev/null 2>&1; then
  :
fi

if ! rg -n "check_repo_hygiene" "${SCRIPT_DIR}/run_all_tests.sh" "${SCRIPT_DIR}/run_all_tests.bat" >/dev/null; then
  echo "[FAIL] run_all_tests runners must invoke check_repo_hygiene" >&2
  exit 1
fi

echo "[PASS] repo hygiene guard contract verified"
