#!/usr/bin/env bash
set -eu

cd "$(dirname "${BASH_SOURCE[0]}")"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[ERROR] lazbuild not found in PATH" >&2
  exit 1
fi

# Deterministic outputs
rm -rf ./bin ./lib/*-*/
mkdir -p ./bin ./lib ./results

echo "=== Building fafafa.core.sync.mutex Benchmark ==="
echo

echo "[BUILD] ${LAZBUILD_BIN} --build-mode=Default fafafa.core.sync.mutex.benchmark.parkinglot.lpi"
"${LAZBUILD_BIN}" --build-mode=Default fafafa.core.sync.mutex.benchmark.parkinglot.lpi

echo
echo "=== Benchmark built successfully! ==="
echo

echo "=== Running Benchmark ==="
echo

if [[ -x "bin/fafafa.core.sync.mutex.benchmark.parkinglot" ]]; then
  echo "[RUN] bin/fafafa.core.sync.mutex.benchmark.parkinglot"
  ./bin/fafafa.core.sync.mutex.benchmark.parkinglot | tee results/benchmark_$(date +%Y%m%d_%H%M%S).txt
elif [[ -x "bin/fafafa.core.sync.mutex.benchmark.parkinglot.exe" ]]; then
  echo "[RUN] bin/fafafa.core.sync.mutex.benchmark.parkinglot.exe"
  ./bin/fafafa.core.sync.mutex.benchmark.parkinglot.exe | tee results/benchmark_$(date +%Y%m%d_%H%M%S).txt
else
  echo "[ERROR] Benchmark executable not found" >&2
  exit 1
fi

echo
echo "=== Benchmark completed! ==="
echo "Results saved to: results/"
