#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

ACTION="${1:-run}"
LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[ERROR] lazbuild not found in PATH" >&2
  exit 1
fi

# Deterministic outputs
rm -rf ./bin ./lib/*-*/
mkdir -p ./bin ./lib

echo "=== Building fafafa.core.atomic Examples ==="
echo

EXAMPLES=(
  "example_basic_operations"
  "example_producer_consumer"
  "example_tagged_ptr_aba"
  "example_thread_counter"
)

for example in "${EXAMPLES[@]}"; do
  echo "[BUILD] ${LAZBUILD_BIN} --build-mode=Release ${example}.lpi"
  "${LAZBUILD_BIN}" --build-mode=Release "${example}.lpi"
done

echo
echo "=== All examples built successfully! ==="
echo

if [[ "${ACTION}" == "run" ]]; then
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
else
  echo "[INFO] Build-only mode (${ACTION})"
  echo "You can run the examples manually:"
  for example in "${EXAMPLES[@]}"; do
    echo "  ./bin/${example}"
  done
fi
