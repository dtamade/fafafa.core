#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${SCRIPT_DIR}"

ACTION="${1:-run}"
TOOLS_LAZBUILD="${REPO_ROOT}/tools/lazbuild.sh"
PROJECTS=(example_base.lpi)

resolve_lazbuild() {
  if [[ -n "${LAZBUILD:-}" ]]; then
    echo "${LAZBUILD}"
    return 0
  fi

  if [[ -x "${TOOLS_LAZBUILD}" ]]; then
    echo "${TOOLS_LAZBUILD}"
    return 0
  fi

  if command -v lazbuild >/dev/null 2>&1; then
    command -v lazbuild
    return 0
  fi

  echo "[ERROR] lazbuild not found (expected ${TOOLS_LAZBUILD} or lazbuild in PATH)" >&2
  exit 127
}

build_examples() {
  local LLazbuild
  local project

  LLazbuild="$(resolve_lazbuild)"
  echo "Building examples..."
  for project in "${PROJECTS[@]}"; do
    "${LLazbuild}" --build-all "${project}"
  done
}

run_examples() {
  local exe

  echo "Running examples..."
  for exe in ./bin/*; do
    if [[ -x "${exe}" && -f "${exe}" ]]; then
      echo "=== Running $(basename "${exe}") ==="
      "${exe}"
      echo
    fi
  done
}

case "${ACTION}" in
  build)
    build_examples
    ;;
  run)
    build_examples
    run_examples
    ;;
  *)
    echo "Usage: $0 [build|run]" >&2
    exit 2
    ;;
esac
