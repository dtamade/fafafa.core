#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR_ROOT="$(mktemp -d)"
FAKE_BIN="${TMPDIR_ROOT}/fake-bin"
mkdir -p "${FAKE_BIN}"

SHELL_TARGETS=(
  "${ROOT}/examples/fafafa.core.sync.namedMutex/BuildAndRun.sh"
  "${ROOT}/examples/fafafa.core.sync.namedCondvar/BuildAndRun.sh"
  "${ROOT}/examples/fafafa.core.sync.namedSemaphore/BuildAndRun.sh"
  "${ROOT}/examples/fafafa.core.sync.rwlock/BuildAndRun.sh"
  "${ROOT}/examples/fafafa.core.sync.namedRWLock/BuildAndRun.sh"
)

BAT_TARGETS=(
  "${ROOT}/examples/fafafa.core.sync.namedMutex/BuildAndRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedCondvar/BuildAndRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedSemaphore/BuildAndRun.bat"
  "${ROOT}/examples/fafafa.core.sync.rwlock/BuildAndRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedRWLock/BuildAndRun.bat"
)

DOC_TARGETS=(
  "${ROOT}/docs/EXAMPLES.md"
  "${ROOT}/docs/fafafa.core.socket.md"
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
    rm -rf "${target}"
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
exit 0
EOF
chmod +x "${FAKE_BIN}/fpc"

for LTarget in "${SHELL_TARGETS[@]}"; do
  if ! bash -n "${LTarget}" >/dev/null; then
    echo "[FAIL] bash -n failed: ${LTarget}" >&2
    exit 1
  fi

  if LC_ALL=C grep -q $'\r' "${LTarget}"; then
    echo "[FAIL] shell runner must keep LF line endings: ${LTarget}" >&2
    exit 1
  fi
done

for LTarget in "${BAT_TARGETS[@]}"; do
  if grep -Fq -- '--build-mode=Debug' "${LTarget}"; then
    echo "[FAIL] batch runner still forces Debug mode: ${LTarget}" >&2
    exit 1
  fi
done

for LTarget in "${DOC_TARGETS[@]}"; do
  if grep -Fq 'Debug/Release 不存在将自动回退' "${LTarget}"; then
    echo "[FAIL] stale socket fallback wording remains: ${LTarget}" >&2
    exit 1
  fi

  if grep -Fq '使用 lazbuild 构建 .lpi 或参考 example_socket.lpr 源码' "${LTarget}"; then
    echo "[FAIL] stale socket linux run wording remains: ${LTarget}" >&2
    exit 1
  fi

  if grep -Fq '若 Debug/Release 模式不存在，脚本会自动回落到默认构建模式' "${LTarget}"; then
    echo "[FAIL] stale socket build mode wording remains: ${LTarget}" >&2
    exit 1
  fi
done

for LTarget in "${SHELL_TARGETS[@]}"; do
  prepare_output_path "$(dirname "${LTarget}")/bin"
  mkdir -p "$(dirname "${LTarget}")/bin"
  create_fake_exe "$(dirname "${LTarget}")/bin/fake_example"

  if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
    bash "${LTarget}" >/dev/null 2>&1; then
    echo "[FAIL] sync example runner should use project default mode: ${LTarget}" >&2
    exit 1
  fi
done

echo "[PASS] L0 sync example runners and socket docs are aligned with default-mode behavior"
