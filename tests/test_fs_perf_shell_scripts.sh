#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FS_DIR="${REPO_ROOT}/tests/fafafa.core.fs"
BIN_DIR="${FS_DIR}/bin"
PERF_DIR="${FS_DIR}/performance-data"

TARGETS=(
  "tests/fafafa.core.fs/ArchivePerfResult.sh"
  "tests/fafafa.core.fs/BuildOrRunPerf.sh"
  "tests/fafafa.core.fs/BuildOrRunPerfAll.sh"
  "tests/fafafa.core.fs/BuildOrRunResolvePerf.sh"
)

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

require_file() {
  local aPath="$1"
  [[ -f "${REPO_ROOT}/${aPath}" ]] || fail "missing file: ${aPath}"
}

require_literal_in_file() {
  local aPath="$1"
  local aLiteral="$2"
  rg -F --quiet -- "${aLiteral}" "${REPO_ROOT}/${aPath}" \
    || fail "${aPath} missing literal: ${aLiteral}"
}

assert_no_crlf() {
  local aPath="$1"
  if grep -n $'\r$' "${REPO_ROOT}/${aPath}" >/dev/null; then
    fail "${aPath} still contains CRLF line endings"
  fi
}

assert_bash_syntax_ok() {
  local aPath="$1"
  bash -n "${REPO_ROOT}/${aPath}" || fail "bash -n failed: ${aPath}"
}

assert_not_interactive() {
  local aPath="$1"
  if rg -n '(^|[^[:alpha:]_])(read|select)[[:space:]]' "${REPO_ROOT}/${aPath}" >/dev/null; then
    fail "${aPath} still contains interactive shell input"
  fi
}

backup_file() {
  local aPath="$1"
  local aToken

  aToken="$(basename "${aPath}")"
  if [[ -e "${aPath}" ]]; then
    cp -a "${aPath}" "${LTmpDir}/backup/${aToken}"
    BACKUPS+=("${aPath}:${LTmpDir}/backup/${aToken}")
  else
    BACKUPS+=("${aPath}:")
  fi
}

restore_backups() {
  local LEntry
  local LPath
  local LBackup

  for (( i=${#BACKUPS[@]} - 1; i>=0; i-- )); do
    LEntry="${BACKUPS[i]}"
    LPath="${LEntry%%:*}"
    LBackup="${LEntry#*:}"
    rm -f "${LPath}"
    if [[ -n "${LBackup}" ]]; then
      cp -a "${LBackup}" "${LPath}"
    fi
  done
}

for LPath in "${TARGETS[@]}"; do
  require_file "${LPath}"
  assert_no_crlf "${LPath}"
  assert_bash_syntax_ok "${LPath}"
  assert_not_interactive "${LPath}"
done

require_literal_in_file "tests/fafafa.core.fs/ArchivePerfResult.sh" "BuildOrRunPerf.sh"
require_literal_in_file "tests/fafafa.core.fs/ArchivePerfResult.sh" "performance-data"
require_literal_in_file "tests/fafafa.core.fs/ArchivePerfResult.sh" "latest.txt"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunPerf.sh" "perf_fs_bench.lpr"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunPerf.sh" "perf_resolve_bench.lpr"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunPerf.sh" "perf_walk_bench.lpr"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunPerf.sh" "buildonly"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunPerf.sh" "resolve"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunPerf.sh" "walk"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunPerf.sh" "all"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunPerfAll.sh" "BuildOrRunPerf.sh"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunResolvePerf.sh" "BuildOrRunPerf.sh"
require_literal_in_file "tests/fafafa.core.fs/BuildOrRunResolvePerf.sh" "perf_resolve_"

LTmpDir="$(mktemp -d)"
BACKUPS=()
trap 'restore_backups; rm -rf "${LTmpDir}"' EXIT
mkdir -p "${LTmpDir}/bin" "${LTmpDir}/backup"

backup_file "${BIN_DIR}/perf_fs_bench"
backup_file "${BIN_DIR}/perf_resolve_bench"
backup_file "${BIN_DIR}/perf_walk_bench"
backup_file "${PERF_DIR}/latest.txt"
backup_file "${PERF_DIR}/perf_all_latest.txt"
backup_file "${PERF_DIR}/perf_resolve_latest.txt"
backup_file "${PERF_DIR}/perf_walk_latest.txt"

cat >"${LTmpDir}/bin/fpc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

OUT_DIR=""
LPR_FILE=""

for arg in "$@"; do
  case "${arg}" in
    -FE*)
      OUT_DIR="${arg#-FE}"
      ;;
    *.lpr)
      LPR_FILE="${arg}"
      ;;
  esac
done

[[ -n "${OUT_DIR}" ]] || {
  echo "[stub-fpc] missing -FE output dir" >&2
  exit 90
}
[[ -n "${LPR_FILE}" ]] || {
  echo "[stub-fpc] missing .lpr input" >&2
  exit 91
}

mkdir -p "${OUT_DIR}"
BASE_NAME="$(basename "${LPR_FILE}" .lpr)"
OUT_FILE="${OUT_DIR}/${BASE_NAME}"

case "${BASE_NAME}" in
  perf_fs_bench)
    cat >"${OUT_FILE}" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
echo "perf_fs_bench stub run: $*"
SCRIPT
    ;;
  perf_resolve_bench)
    cat >"${OUT_FILE}" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-tests/fafafa.core.fs/walk_bench_root}"
ITERS="${2:-1000}"
mkdir -p tests/fafafa.core.fs/performance-data
{
  echo "ResolvePathEx: TouchDisk=False, iters=${ITERS}, time=1 ms, last=${ROOT}"
  echo "ResolvePathEx: TouchDisk=True,  iters=${ITERS}, time=2 ms, last=${ROOT}"
  echo "CSV,ResolvePathEx,${ROOT},${ITERS},1,2"
} > tests/fafafa.core.fs/performance-data/perf_resolve_latest.txt
cat tests/fafafa.core.fs/performance-data/perf_resolve_latest.txt
SCRIPT
    ;;
  perf_walk_bench)
    cat >"${OUT_FILE}" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-tests/fafafa.core.fs/walk_bench_root}"
MODE="${2:-genwalk}"
DEPTH="${3:-3}"
FANOUT="${4:-4}"
FILES="${5:-2}"
mkdir -p tests/fafafa.core.fs/performance-data
if [[ "${MODE}" == "gen" || "${MODE}" == "genwalk" ]]; then
  mkdir -p "${ROOT}"
fi
if [[ "${MODE}" == "walk" || "${MODE}" == "genwalk" ]]; then
  {
    echo "Walk entries: 42, time: 3 ms"
    echo "CSV,Walk,${ROOT},${DEPTH},${FANOUT},${FILES},3,42"
  } > tests/fafafa.core.fs/performance-data/perf_walk_latest.txt
  cat tests/fafafa.core.fs/performance-data/perf_walk_latest.txt
else
  echo "Tree generated at ${ROOT}"
fi
SCRIPT
    ;;
  *)
    echo "[stub-fpc] unexpected program: ${BASE_NAME}" >&2
    exit 92
    ;;
esac

chmod +x "${OUT_FILE}"
EOF
chmod +x "${LTmpDir}/bin/fpc"

OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  FPC=fpc \
  bash "${FS_DIR}/BuildOrRunPerf.sh" buildonly 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "BuildOrRunPerf.sh buildonly failed under stub fpc"
}
printf '%s\n' "${OUTPUT}" | rg -F --quiet "[OK] Build successful." \
  || fail "buildonly output missing success marker"

OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  FPC=fpc \
  bash "${FS_DIR}/BuildOrRunPerf.sh" resolve tests/fafafa.core.fs/walk_bench_root 12 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "BuildOrRunPerf.sh resolve failed under stub fpc"
}
[[ -f "${PERF_DIR}/perf_resolve_latest.txt" ]] || fail "resolve run did not write perf_resolve_latest.txt"
printf '%s\n' "${OUTPUT}" | rg -F --quiet "Output file: ${PERF_DIR}/perf_resolve_latest.txt" \
  || fail "resolve output missing latest file marker"
rg -F --quiet "CSV,ResolvePathEx,tests/fafafa.core.fs/walk_bench_root,12,1,2" "${PERF_DIR}/perf_resolve_latest.txt" \
  || fail "resolve latest file missing CSV contract"

OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  FPC=fpc \
  bash "${FS_DIR}/BuildOrRunPerf.sh" walk tests/fafafa.core.fs/walk_bench_root 5 6 7 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "BuildOrRunPerf.sh walk failed under stub fpc"
}
[[ -f "${PERF_DIR}/perf_walk_latest.txt" ]] || fail "walk run did not write perf_walk_latest.txt"
printf '%s\n' "${OUTPUT}" | rg -F --quiet "Output file: ${PERF_DIR}/perf_walk_latest.txt" \
  || fail "walk output missing latest file marker"
rg -F --quiet "CSV,Walk,tests/fafafa.core.fs/walk_bench_root,5,6,7,3,42" "${PERF_DIR}/perf_walk_latest.txt" \
  || fail "walk latest file missing CSV contract"

OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  FPC=fpc \
  bash "${FS_DIR}/BuildOrRunPerf.sh" all tests/fafafa.core.fs/walk_bench_root 21 8 9 10 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "BuildOrRunPerf.sh all failed under stub fpc"
}
[[ -f "${PERF_DIR}/perf_all_latest.txt" ]] || fail "all run did not write perf_all_latest.txt"
printf '%s\n' "${OUTPUT}" | rg -F --quiet "Output file: ${PERF_DIR}/perf_all_latest.txt" \
  || fail "all output missing latest file marker"
rg -F --quiet "CSV,ResolvePathEx,tests/fafafa.core.fs/walk_bench_root,21,1,2" "${PERF_DIR}/perf_all_latest.txt" \
  || fail "all latest file missing resolve CSV contract"
rg -F --quiet "CSV,Walk,tests/fafafa.core.fs/walk_bench_root,8,9,10,3,42" "${PERF_DIR}/perf_all_latest.txt" \
  || fail "all latest file missing walk CSV contract"

OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  FPC=fpc \
  bash "${FS_DIR}/BuildOrRunResolvePerf.sh" tests/fafafa.core.fs/walk_bench_root 15 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "BuildOrRunResolvePerf.sh failed under stub fpc"
}
printf '%s\n' "${OUTPUT}" | rg -F --quiet "Saved: ${PERF_DIR}/perf_resolve_" \
  || fail "resolve wrapper output missing saved snapshot marker"

OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  FPC=fpc \
  bash "${FS_DIR}/BuildOrRunPerfAll.sh" tests/fafafa.core.fs/walk_bench_root 18 3 4 5 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "BuildOrRunPerfAll.sh failed under stub fpc"
}
printf '%s\n' "${OUTPUT}" | rg -F --quiet "Output file: ${PERF_DIR}/perf_all_latest.txt" \
  || fail "all wrapper output missing latest file marker"

BEFORE_ARCHIVE_COUNT="$(find "${PERF_DIR}" -maxdepth 1 -name 'perf_*.txt' | wc -l)"
OUTPUT="$(
  PATH="${LTmpDir}/bin:${PATH}" \
  FPC=fpc \
  bash "${FS_DIR}/ArchivePerfResult.sh" /tmp/fs_bench.tmp 64 128 4 5000 2>&1
)" || {
  printf '%s\n' "${OUTPUT}" >&2
  fail "ArchivePerfResult.sh failed under stub fpc"
}
AFTER_ARCHIVE_COUNT="$(find "${PERF_DIR}" -maxdepth 1 -name 'perf_*.txt' | wc -l)"
[[ -f "${PERF_DIR}/latest.txt" ]] || fail "archive run did not write latest.txt"
[[ "${AFTER_ARCHIVE_COUNT}" -gt "${BEFORE_ARCHIVE_COUNT}" ]] \
  || fail "archive run did not create a new perf_*.txt snapshot"
rg -F --quiet "Timestamp:" "${PERF_DIR}/latest.txt" \
  || fail "latest.txt missing timestamp header"
rg -F --quiet "Command: BuildOrRunPerf.sh /tmp/fs_bench.tmp 64 128 4 5000" "${PERF_DIR}/latest.txt" \
  || fail "latest.txt missing command header"

echo "[PASS] fs perf shell scripts contract verified"
