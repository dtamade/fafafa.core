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

echo "=== Building fafafa.core.sync.condvar Examples ==="
echo

# List of all example subdirectories
EXAMPLES=(
  "barrier/example_multi_thread_coordination"
  "cond_vs_event/example_cond_vs_event"
  "mpmc_queue/example_mpmc_queue"
  "producer_consumer/example_producer_consumer"
  "robust_wait/example_robust_wait"
  "timeout/example_timeout"
  "wait_notify/example_wait_notify"
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
    example_name=$(basename "${example}")
    if [[ -x "bin/${example_name}" ]]; then
      echo "[RUN] bin/${example_name}"
      "bin/${example_name}"
      echo
    elif [[ -x "bin/${example_name}.exe" ]]; then
      echo "[RUN] bin/${example_name}.exe"
      "bin/${example_name}.exe"
      echo
    else
      echo "[WARN] Executable not found: bin/${example_name}[.exe]" >&2
    fi
  done
else
  echo "[INFO] Build-only mode (${ACTION})"
  echo "You can run the examples manually:"
  for example in "${EXAMPLES[@]}"; do
    example_name=$(basename "${example}")
    echo "  ./bin/${example_name}"
  done
fi
