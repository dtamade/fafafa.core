#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${1:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

if ! git -C "${REPO_ROOT}" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "[CHECK] Missing git repository: ${REPO_ROOT}" >&2
  exit 2
fi

mapfile -t GITLINKS < <(git -C "${REPO_ROOT}" ls-files -s | awk '$1 == "160000" {print $4}' | sort)

if [[ "${#GITLINKS[@]}" == "0" ]]; then
  echo "[CHECK] OK (repo submodule metadata: no gitlinks)"
  exit 0
fi

set +e
OUTPUT="$(git -C "${REPO_ROOT}" submodule foreach --recursive true 2>&1)"
RC=$?
set -e

if [[ "${RC}" != "0" ]]; then
  echo "[CHECK] FAIL: broken git submodule metadata" >&2
  printf '%s\n' "${GITLINKS[@]}" >&2
  printf '%s\n' "${OUTPUT}" >&2
  exit 1
fi

echo "[CHECK] OK (repo submodule metadata consistent)"
