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

create_fake_exe() {
  local target="$1"

  backup_path "${target}"
  mkdir -p "$(dirname "${target}")"
  cat > "${target}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF
  chmod +x "${target}"
  CREATED+=("${target}")
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

for LTarget in "${SYNTAX_TARGETS[@]}"; do
  if ! bash -n "${LTarget}" >/dev/null; then
    echo "[FAIL] bash -n failed: ${LTarget}" >&2
    exit 1
  fi
done

create_fake_exe "${ROOT}/examples/fafafa.core.json/bin/example_json"
create_fake_exe "${ROOT}/examples/fafafa.core.json/bin/example_json_noexcept"
create_fake_exe "${ROOT}/examples/fafafa.core.json/bin/example_json_noexcept_writer"
create_fake_exe "${ROOT}/examples/fafafa.core.json/bin/example_reader_flags"
create_fake_exe "${ROOT}/examples/fafafa.core.json/bin/example_stop_when_done"

if ! LAZBUILD="${FAKE_BIN}/lazbuild" bash "${ROOT}/examples/fafafa.core.env/BuildOrRun.sh" build quickstart >/dev/null 2>&1; then
  echo "[FAIL] env example runner should build with the project default mode" >&2
  exit 1
fi

if ! LAZBUILD="${FAKE_BIN}/lazbuild" bash "${ROOT}/examples/fafafa.core.json/BuildOrRun.sh" >/dev/null 2>&1; then
  echo "[FAIL] json example runner should work without forcing Debug mode" >&2
  exit 1
fi

if ! LAZBUILD="${FAKE_BIN}/lazbuild" bash "${ROOT}/examples/fafafa.core.json/BuildOrRun_NoExcept.sh" >/dev/null 2>&1; then
  echo "[FAIL] json noexcept runner should work without forcing Debug mode" >&2
  exit 1
fi

if ! LAZBUILD="${FAKE_BIN}/lazbuild" bash "${ROOT}/examples/fafafa.core.json/BuildOrRun_NoExcept_Writer.sh" >/dev/null 2>&1; then
  echo "[FAIL] json noexcept writer runner should work without forcing Debug mode" >&2
  exit 1
fi

if ! LAZBUILD="${FAKE_BIN}/lazbuild" bash "${ROOT}/examples/fafafa.core.json/BuildOrRun_Min.sh" >/dev/null 2>&1; then
  echo "[FAIL] json minimal runner should work without forcing Debug mode" >&2
  exit 1
fi

echo "[PASS] example and benchmark shell runners keep LF syntax and default build modes"
