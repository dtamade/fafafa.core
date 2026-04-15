#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECKER="${SCRIPT_DIR}/check_repo_submodule_hygiene.sh"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ -x "${CHECKER}" ]] || fail "missing checker: ${CHECKER}"

LTmpDir="$(mktemp -d)"
trap 'rm -rf "${LTmpDir}"' EXIT

LCleanRepo="${LTmpDir}/clean-repo"
LBrokenRepo="${LTmpDir}/broken-repo"

git init "${LCleanRepo}" >/dev/null 2>&1
git init "${LBrokenRepo}" >/dev/null 2>&1

"${CHECKER}" "${LCleanRepo}" >/dev/null \
  || fail "clean repo should pass submodule hygiene check"

git -C "${LBrokenRepo}" update-index --add --cacheinfo 160000,aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,3rd/mimalloc

if "${CHECKER}" "${LBrokenRepo}" >/dev/null 2>&1; then
  fail "broken gitlink metadata should fail submodule hygiene check"
fi

echo "[PASS] repo submodule hygiene guard contract verified"
