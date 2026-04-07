#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR_ROOT="$(mktemp -d)"
FAKE_BIN="${TMPDIR_ROOT}/fake-bin"
mkdir -p "${FAKE_BIN}"

SYNTAX_TARGETS=(
  "${ROOT}/examples/fafafa.core.env/BuildOrRun.sh"
  "${ROOT}/examples/fafafa.core.json/BuildOrRun.sh"
  "${ROOT}/examples/fafafa.core.json/BuildOrRun_Min.sh"
  "${ROOT}/examples/fafafa.core.json/BuildOrRun_NoExcept.sh"
  "${ROOT}/examples/fafafa.core.json/BuildOrRun_NoExcept_Writer.sh"
  "${ROOT}/benchmarks/fafafa.core.thread/run_matrix.sh"
  "${ROOT}/examples/fafafa.core.time/BuildOrRun.sh"
  "${ROOT}/examples/fafafa.core.color/run_demo.sh"
  "${ROOT}/examples/fafafa.core.xml/BuildExamples.sh"
  "${ROOT}/examples/fafafa.core.collections.vecdeque/BuildOrTest.sh"
  "${ROOT}/examples/fafafa.core.collections.forwardList/BuildOrRun.sh"
  "${ROOT}/benchmarks/fafafa.core.collections/run_simple_benchmark.sh"
  "${ROOT}/examples/fafafa.core.socket/build_examples.sh"
)

BACKUPS=()
CREATED=()

backup_path() {
  local target="$1"
  local backup

  if [[ -e "${target}" ]]; then
    backup="${TMPDIR_ROOT}/backup-${#BACKUPS[@]}"
    mv "${target}" "${backup}"
    BACKUPS+=("${target}:${backup}")
  fi
}

prepare_output_path() {
  local target="$1"

  backup_path "${target}"
  mkdir -p "$(dirname "${target}")"
  CREATED+=("${target}")
}

create_fake_exe() {
  local target="$1"

  prepare_output_path "${target}"
  cat > "${target}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF
  chmod +x "${target}"
}

cleanup() {
  local entry
  local target
  local backup

  for target in "${CREATED[@]}"; do
    rm -f "${target}"
  done

  for entry in "${BACKUPS[@]}"; do
    target="${entry%%:*}"
    backup="${entry#*:}"
    mkdir -p "$(dirname "${target}")"
    mv "${backup}" "${target}"
  done

  rm -rf "${TMPDIR_ROOT}"
}
trap cleanup EXIT

cat > "${FAKE_BIN}/lazbuild" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

for LArg in "$@"; do
  if [[ "${LArg}" == --build-mode=Debug || "${LArg}" == --bm=Debug ]]; then
    echo "[FAIL] unexpected debug build flag: ${LArg}" >&2
    exit 99
  fi
done

exit 0
EOF
chmod +x "${FAKE_BIN}/lazbuild"

cat > "${FAKE_BIN}/fpc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "[FAIL] unexpected fpc fallback: $*" >&2
exit 98
EOF
chmod +x "${FAKE_BIN}/fpc"

for LTarget in "${SYNTAX_TARGETS[@]}"; do
  if ! bash -n "${LTarget}" >/dev/null; then
    echo "[FAIL] bash -n failed: ${LTarget}" >&2
    exit 1
  fi

  if LC_ALL=C grep -q $'\r' "${LTarget}"; then
    echo "[FAIL] shell runner must keep LF line endings: ${LTarget}" >&2
    exit 1
  fi
done

create_fake_exe "${ROOT}/examples/fafafa.core.json/bin/example_json"
create_fake_exe "${ROOT}/examples/fafafa.core.json/bin/example_json_noexcept"
create_fake_exe "${ROOT}/examples/fafafa.core.json/bin/example_json_noexcept_writer"
create_fake_exe "${ROOT}/examples/fafafa.core.json/bin/example_reader_flags"
create_fake_exe "${ROOT}/examples/fafafa.core.json/bin/example_stop_when_done"
create_fake_exe "${ROOT}/bin/palette_demo.exe"
prepare_output_path "${ROOT}/examples/fafafa.core.color/palette_demo.log"
create_fake_exe "${ROOT}/examples/fafafa.core.xml/bin/example_xml_reader"
create_fake_exe "${ROOT}/examples/fafafa.core.xml/bin/example_xml_writer"
create_fake_exe "${ROOT}/bin/example_vecdeque"
create_fake_exe "${ROOT}/benchmarks/fafafa.core.collections/bin/collections_performance_benchmark"

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.env/BuildOrRun.sh" build quickstart >/dev/null 2>&1; then
  echo "[FAIL] env example runner should build with the project default mode" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.json/BuildOrRun.sh" >/dev/null 2>&1; then
  echo "[FAIL] json example runner should work without forcing Debug mode" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.json/BuildOrRun_NoExcept.sh" >/dev/null 2>&1; then
  echo "[FAIL] json noexcept runner should work without forcing Debug mode" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.json/BuildOrRun_NoExcept_Writer.sh" >/dev/null 2>&1; then
  echo "[FAIL] json noexcept writer runner should work without forcing Debug mode" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.json/BuildOrRun_Min.sh" >/dev/null 2>&1; then
  echo "[FAIL] json minimal runner should work without forcing Debug mode" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.time/BuildOrRun.sh" build quickstart >/dev/null 2>&1; then
  echo "[FAIL] time example runner should build with the project default mode" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.color/run_demo.sh" >/dev/null 2>&1; then
  echo "[FAIL] color demo runner should build with the project default mode" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.xml/BuildExamples.sh" >/dev/null 2>&1; then
  echo "[FAIL] xml example runner should build with the project default mode" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.collections.vecdeque/BuildOrTest.sh" >/dev/null 2>&1; then
  echo "[FAIL] vecdeque example runner should avoid forced Debug/Release double builds" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.collections.forwardList/BuildOrRun.sh" >/dev/null 2>&1; then
  echo "[FAIL] forwardList example runner should build with the project default mode" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/benchmarks/fafafa.core.collections/run_simple_benchmark.sh" >/dev/null 2>&1; then
  echo "[FAIL] simple collections benchmark runner should use portable lazbuild resolution and default mode" >&2
  exit 1
fi

if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
  bash "${ROOT}/examples/fafafa.core.socket/build_examples.sh" >/dev/null 2>&1; then
  echo "[FAIL] socket example runner should avoid forced Debug/Release double builds" >&2
  exit 1
fi

echo "[PASS] example and benchmark shell runners keep LF syntax and default build modes"
