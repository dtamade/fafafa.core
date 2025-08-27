#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${SCRIPT_DIR}/bin"

if [[ ! -d "${BIN_DIR}" ]]; then
  echo "bin/ not found. Build first: ./BuildExamples.sh"
  exit 1
fi

run_bin() {
  local exe="$1"
  if [[ -x "${exe}" ]]; then
    echo
    echo "==== Running $(basename "${exe}") ===="
    "${exe}"
  elif [[ -x "${exe}.exe" ]]; then
    echo
    echo "==== Running $(basename "${exe}.exe") ===="
    wine "${exe}.exe" || true
  else
    echo "Skipped $(basename "${exe}") (not built)"
  fi
}

run_bin "${BIN_DIR}/example_xml_reader"
run_bin "${BIN_DIR}/example_xml_writer"

