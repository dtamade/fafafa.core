#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR_ROOT="$(mktemp -d)"
FAKE_BIN="${TMPDIR_ROOT}/fake-bin"
mkdir -p "${FAKE_BIN}"

SHELL_TARGETS=(
  "${ROOT}/examples/fafafa.core.sync/BuildOrRun.sh"
  "${ROOT}/examples/fafafa.core.sync.condvar/BuildOrRun.sh"
  "${ROOT}/examples/fafafa.core.sync.event/BuildOrRun.sh"
  "${ROOT}/examples/fafafa.core.sync.mutex/BuildOrRun.sh"
  "${ROOT}/examples/fafafa.core.sync.namedMutex/BuildAndRun.sh"
  "${ROOT}/examples/fafafa.core.sync.namedCondvar/BuildAndRun.sh"
  "${ROOT}/examples/fafafa.core.sync.namedEvent/BuildAndRun.sh"
  "${ROOT}/examples/fafafa.core.sync.namedSemaphore/BuildAndRun.sh"
  "${ROOT}/examples/fafafa.core.sync.rwlock/BuildAndRun.sh"
  "${ROOT}/examples/fafafa.core.sync.namedRWLock/BuildAndRun.sh"
  "${ROOT}/examples/fafafa.core.sync.namedBarrier/BuildOrRun.sh"
  "${ROOT}/examples/fafafa.core.sync.spin/BuildOrRun.sh"
)

BAT_TARGETS=(
  "${ROOT}/examples/fafafa.core.sync/BuildOrRun.bat"
  "${ROOT}/examples/fafafa.core.sync.condvar/BuildOrRun.bat"
  "${ROOT}/examples/fafafa.core.sync.event/BuildOrRun.bat"
  "${ROOT}/examples/fafafa.core.sync.mutex/BuildOrRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedMutex/BuildAndRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedCondvar/BuildAndRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedEvent/BuildAndRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedSemaphore/BuildAndRun.bat"
  "${ROOT}/examples/fafafa.core.sync.rwlock/BuildAndRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedRWLock/BuildAndRun.bat"
  "${ROOT}/examples/fafafa.core.sync/RunRwLock.bat"
  "${ROOT}/examples/fafafa.core.sync/BuildAllExamples.bat"
  "${ROOT}/examples/fafafa.core.sync.spin/BuildOrRun.bat"
  "${ROOT}/examples/fafafa.core.socket/build_examples.bat"
)

DELETED_ALIAS_TARGETS=(
  "${ROOT}/examples/fafafa.core.sync.mutex/buildOrRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedEvent/BuildOrRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedEvent/BuildOrRun.sh"
  "${ROOT}/examples/fafafa.core.sync.namedRWLock/BuildOrRun.bat"
  "${ROOT}/examples/fafafa.core.sync.namedRWLock/BuildOrRun.sh"
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

prepare_runner_bin() {
  local runner="$1"
  local runner_dir

  runner_dir="$(dirname "${runner}")"
  prepare_output_path "${runner_dir}/bin"
  mkdir -p "${runner_dir}/bin"
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

create_fake_output() {
  local target="$1"

  mkdir -p "$(dirname "${target}")"
  cat > "${target}" <<'EOR'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOR
  chmod +x "${target}"
}

LPrevWasOutput=0
for LArg in "$@"; do
  if [[ "${LPrevWasOutput}" == 1 ]]; then
    create_fake_output "${LArg}"
    LPrevWasOutput=0
    continue
  fi

  if [[ "${LArg}" == --build-mode=Debug || "${LArg}" == --bm=Debug ]]; then
    echo "[FAIL] unexpected debug build flag: ${LArg}" >&2
    exit 99
  fi

  case "${LArg}" in
    -o)
      LPrevWasOutput=1
      ;;
    -o*)
      create_fake_output "${LArg#-o}"
      ;;
    *.lpi)
      LBase="$(basename "${LArg}" .lpi)"
      create_fake_output "bin/${LBase}"
      ;;
  esac
done

exit 0
EOF
chmod +x "${FAKE_BIN}/lazbuild"

cat > "${FAKE_BIN}/fpc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

create_fake_output() {
  local target="$1"

  mkdir -p "$(dirname "${target}")"
  cat > "${target}" <<'EOR'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOR
  chmod +x "${target}"
}

LPrevWasOutput=0
for LArg in "$@"; do
  if [[ "${LPrevWasOutput}" == 1 ]]; then
    create_fake_output "${LArg}"
    exit 0
  fi

  case "${LArg}" in
    -o)
      LPrevWasOutput=1
      ;;
    -o*)
      create_fake_output "${LArg#-o}"
      exit 0
      ;;
  esac
done

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

  if grep -Fq -- '--build-mode=Release' "${LTarget}"; then
    echo "[FAIL] batch runner still forces Release mode: ${LTarget}" >&2
    exit 1
  fi

  if grep -Fq -- '--build-mode=Default' "${LTarget}"; then
    echo "[FAIL] batch runner still forces Default mode: ${LTarget}" >&2
    exit 1
  fi

  if grep -Fq -- 'set /p' "${LTarget}"; then
    echo "[FAIL] batch runner still uses interactive input: ${LTarget}" >&2
    exit 1
  fi
done

for LTarget in "${DELETED_ALIAS_TARGETS[@]}"; do
  if [[ -e "${LTarget}" ]]; then
    echo "[FAIL] stale example alias still exists: ${LTarget}" >&2
    exit 1
  fi
done

if grep -Fq -- '--build-mode=Release' "${ROOT}/examples/fafafa.core.socket/build_examples.bat"; then
  echo "[FAIL] socket batch runner still forces Release mode" >&2
  exit 1
fi

if grep -Fq 'falling back to default build' "${ROOT}/examples/fafafa.core.socket/build_examples.bat"; then
  echo "[FAIL] socket batch runner still contains stale fallback wording" >&2
  exit 1
fi

if grep -Fq 'Debug mode missing for' "${ROOT}/examples/fafafa.core.socket/build_examples.bat"; then
  echo "[FAIL] socket batch runner still contains stale Debug fallback wording" >&2
  exit 1
fi

if grep -Fq 'Release mode missing for' "${ROOT}/examples/fafafa.core.socket/build_examples.bat"; then
  echo "[FAIL] socket batch runner still contains stale Release fallback wording" >&2
  exit 1
fi

if grep -Fq 'example_semaphore.lpi' "${ROOT}/examples/fafafa.core.sync/BuildAllExamples.bat"; then
  echo "[FAIL] stale sync example name remains in BuildAllExamples.bat" >&2
  exit 1
fi

if grep -Fq 'example_semaphore.lpi' "${ROOT}/examples/fafafa.core.sync/README.md"; then
  echo "[FAIL] stale sync example name remains in examples/fafafa.core.sync/README.md" >&2
  exit 1
fi

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
  prepare_runner_bin "${LTarget}"

  if ! PATH="${FAKE_BIN}:$PATH" LAZBUILD="${FAKE_BIN}/lazbuild" FPC="${FAKE_BIN}/fpc" \
    bash "${LTarget}" >/dev/null 2>&1; then
    echo "[FAIL] sync example runner should use project default mode: ${LTarget}" >&2
    exit 1
  fi
done

echo "[PASS] L0 sync example runners are aligned with current default-mode and alias hygiene"
