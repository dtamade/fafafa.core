#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SRC_DIR="${ROOT_DIR}/src"
LIB_DIR="${SCRIPT_DIR}/lib"
BIN_DIR="${SCRIPT_DIR}/bin"
PERF_DIR="${SCRIPT_DIR}/performance-data"
FPC_BIN="${FPC:-fpc}"
DEFAULT_WALK_ROOT="tests/fafafa.core.fs/walk_bench_root"

mkdir -p "${LIB_DIR}" "${BIN_DIR}" "${PERF_DIR}"

FPC_OPTS=(-MObjFPC -Scghi -O2 -XX -CX -Si -vewnhibq)
FPC_PATHS=("-Fu${SRC_DIR}" "-FU${LIB_DIR}" "-FE${BIN_DIR}")

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

print_help() {
  cat <<'EOF'
Usage:
  bash tests/fafafa.core.fs/BuildOrRunPerf.sh [path] [fileMB] [seqKB] [rndKB] [samples]
  bash tests/fafafa.core.fs/BuildOrRunPerf.sh buildonly
  bash tests/fafafa.core.fs/BuildOrRunPerf.sh resolve [root] [iters]
  bash tests/fafafa.core.fs/BuildOrRunPerf.sh walk [root] [depth] [fanout] [files]
  bash tests/fafafa.core.fs/BuildOrRunPerf.sh all [root] [iters] [depth] [fanout] [files]

说明:
  不带子命令时，构建并运行 perf_fs_bench。
  resolve / walk / all 为 Linux/macOS 的 perf shell 统一入口。
EOF
}

compile_lpr() {
  local aLpr="$1"

  echo "[1/2] Compiling: ${aLpr} ..."
  (
    cd "${SCRIPT_DIR}"
    "${FPC_BIN}" "${FPC_OPTS[@]}" "${FPC_PATHS[@]}" "${aLpr}"
  )
  echo
  echo "[OK] Build successful."
}

run_from_root() {
  (
    cd "${ROOT_DIR}"
    "$@"
  )
}

build_fs_bench() {
  compile_lpr "perf_fs_bench.lpr"
  [[ -x "${BIN_DIR}/perf_fs_bench" ]] || fail "Executable not found: ${BIN_DIR}/perf_fs_bench"
}

build_resolve_bench() {
  compile_lpr "perf_resolve_bench.lpr"
  [[ -x "${BIN_DIR}/perf_resolve_bench" ]] || fail "Executable not found: ${BIN_DIR}/perf_resolve_bench"
}

build_walk_bench() {
  compile_lpr "perf_walk_bench.lpr"
  [[ -x "${BIN_DIR}/perf_walk_bench" ]] || fail "Executable not found: ${BIN_DIR}/perf_walk_bench"
}

run_fs_bench() {
  local LRet

  build_fs_bench
  echo
  echo "[2/2] Running benchmark..."
  if run_from_root "${BIN_DIR}/perf_fs_bench" "$@"; then
    LRet=0
  else
    LRet=$?
  fi

  echo
  echo "Benchmark exited with code ${LRet}"
  return "${LRet}"
}

run_resolve_perf() {
  local LRoot="${1:-${DEFAULT_WALK_ROOT}}"
  local LIters="${2:-1000}"
  local LOut="${PERF_DIR}/perf_resolve_latest.txt"

  build_resolve_bench
  echo
  echo "[2/2] Running resolve benchmark..."
  run_from_root "${BIN_DIR}/perf_resolve_bench" "${LRoot}" "${LIters}"

  [[ -f "${LOut}" ]] || fail "missing resolve perf output: ${LOut}"
  echo "Output file: ${LOut}"
  grep -E "^CSV,ResolvePathEx" "${LOut}" || true
}

run_walk_perf() {
  local LRoot="${1:-${DEFAULT_WALK_ROOT}}"
  local LDepth="${2:-3}"
  local LFanout="${3:-4}"
  local LFiles="${4:-2}"
  local LOut="${PERF_DIR}/perf_walk_latest.txt"

  build_walk_bench
  echo
  echo "[2/2] Running walk benchmark..."
  run_from_root "${BIN_DIR}/perf_walk_bench" "${LRoot}" "genwalk" "${LDepth}" "${LFanout}" "${LFiles}"

  [[ -f "${LOut}" ]] || fail "missing walk perf output: ${LOut}"
  echo "Output file: ${LOut}"
  grep -E "^CSV,Walk" "${LOut}" || true
}

run_all_perf() {
  local LRoot="${1:-${DEFAULT_WALK_ROOT}}"
  local LIters="${2:-2000}"
  local LDepth="${3:-3}"
  local LFanout="${4:-4}"
  local LFiles="${5:-2}"
  local LResolveOut="${PERF_DIR}/perf_resolve_latest.txt"
  local LWalkOut="${PERF_DIR}/perf_walk_latest.txt"
  local LAllOut="${PERF_DIR}/perf_all_latest.txt"

  run_resolve_perf "${LRoot}" "${LIters}"
  echo
  run_walk_perf "${LRoot}" "${LDepth}" "${LFanout}" "${LFiles}"

  {
    echo "==== ResolvePathEx ===="
    if [[ -f "${LResolveOut}" ]]; then
      cat "${LResolveOut}"
    fi
    echo
    echo "==== Walk ===="
    if [[ -f "${LWalkOut}" ]]; then
      cat "${LWalkOut}"
    fi
  } >"${LAllOut}"

  echo
  echo "Output file: ${LAllOut}"
  grep -E "^CSV," "${LAllOut}" || true
}

case "${1:-}" in
  --help|-h)
    print_help
    exit 0
    ;;
  buildonly)
    build_fs_bench
    ;;
  resolve)
    shift
    run_resolve_perf "$@"
    ;;
  walk)
    shift
    run_walk_perf "$@"
    ;;
  all)
    shift
    run_all_perf "$@"
    ;;
  "")
    run_fs_bench
    ;;
  *)
    run_fs_bench "$@"
    ;;
esac
