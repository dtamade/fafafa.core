#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-test}"
shift || true

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_ROOT="$(cd "${ROOT}/.." && pwd)"

SUITES=(base command config errors help validation)

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

clean_one() {
  local suite="$1"
  local dir="${TESTS_ROOT}/fafafa.core.args.${suite}"
  rm -rf "${dir}/bin" "${dir}/lib"
  mkdir -p "${dir}/bin" "${dir}/lib"
}

build_one() {
  local suite="$1"
  local dir="${TESTS_ROOT}/fafafa.core.args.${suite}"
  local proj="${dir}/fafafa.core.args.${suite}.test.lpi"

  clean_one "${suite}"

  if command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
    echo "[BUILD] args.${suite}: ${proj}"
    "${LAZBUILD_BIN}" -B "${proj}" >/dev/null
  else
    echo "[ERROR] lazbuild not found (needed to build args tests)"
    exit 1
  fi
}

run_one() {
  local suite="$1"
  local dir="${TESTS_ROOT}/fafafa.core.args.${suite}"
  local exe_base="${dir}/bin/fafafa.core.args.${suite}.test"
  local exe=""

  if [[ -x "${exe_base}" ]]; then
    exe="${exe_base}"
  elif [[ -x "${exe_base}.exe" ]]; then
    exe="${exe_base}.exe"
  else
    echo "[ERROR] missing test executable for args.${suite} (looked for ${exe_base}[.exe])"
    exit 1
  fi

  echo "[TEST] args.${suite}: ${exe} --all --format=plain"
  "${exe}" --all --format=plain
}

case "${ACTION}" in
  clean)
    for s in "${SUITES[@]}"; do
      echo "[CLEAN] args.${s}"
      clean_one "${s}"
    done
    ;;
  build)
    for s in "${SUITES[@]}"; do
      build_one "${s}"
    done
    ;;
  test)
    for s in "${SUITES[@]}"; do
      build_one "${s}"
      run_one "${s}"
      echo
    done
    ;;
  *)
    echo "Usage: $0 [clean|build|test]"
    exit 2
    ;;
esac
