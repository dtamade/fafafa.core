#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${SCRIPT_DIR}"

ACTION="${1:-run}"
TOOLS_LAZBUILD="${REPO_ROOT}/tools/lazbuild.sh"
EXAMPLES=(
  "example_basic_operations"
  "example_producer_consumer"
  "example_tagged_ptr_aba"
  "example_thread_counter"
)

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
  local example

  LLazbuild="$(resolve_lazbuild)"
  rm -rf ./bin ./lib/*-*/
  mkdir -p ./bin ./lib

  echo "=== Building fafafa.core.atomic Examples ==="
  echo

  for example in "${EXAMPLES[@]}"; do
    echo "[BUILD] ${LLazbuild} --build-mode=Release ${example}.lpi"
    "${LLazbuild}" --build-mode=Release "${example}.lpi"
  done

  echo
  echo "=== All examples built successfully! ==="
  echo
}

run_examples() {
  echo "=== Running Examples ==="
  echo

  for example in "${EXAMPLES[@]}"; do
    if [[ -x "bin/${example}" ]]; then
      echo "[RUN] bin/${example}"
      "bin/${example}"
      echo
    elif [[ -x "bin/${example}.exe" ]]; then
      echo "[RUN] bin/${example}.exe"
      "bin/${example}.exe"
      echo
    else
      echo "[WARN] Executable not found: bin/${example}[.exe]" >&2
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
