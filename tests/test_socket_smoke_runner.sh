#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOCKET_DIR="${ROOT}/tests/fafafa.core.socket"
BIN_DIR="${SOCKET_DIR}/bin"

TMPDIR_ROOT="$(mktemp -d)"
FAKE_BIN="${TMPDIR_ROOT}/fake-bin"
mkdir -p "${FAKE_BIN}" "${BIN_DIR}"

ARGS_LOG="${TMPDIR_ROOT}/socket-smoke-args.log"
ORIG_EXE="${BIN_DIR}/tests_socket"
BACKUP_EXE=""
if [[ -e "${ORIG_EXE}" ]]; then
  BACKUP_EXE="${TMPDIR_ROOT}/tests_socket.backup"
  mv "${ORIG_EXE}" "${BACKUP_EXE}"
fi

cleanup() {
  rm -f "${ORIG_EXE}"
  if [[ -n "${BACKUP_EXE}" && -e "${BACKUP_EXE}" ]]; then
    mv "${BACKUP_EXE}" "${ORIG_EXE}"
  fi
  rm -rf "${TMPDIR_ROOT}"
}
trap cleanup EXIT

cat > "${FAKE_BIN}/lazbuild" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
for LArg in "$@"; do
  if [[ "${LArg}" == --build-mode=* ]]; then
    echo "[FAIL] unexpected build mode flag: ${LArg}" >&2
    exit 99
  fi
done
exit 0
EOF
chmod +x "${FAKE_BIN}/lazbuild"

cat > "${ORIG_EXE}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$@" > "${ARGS_LOG}"
exit 0
EOF
chmod +x "${ORIG_EXE}"

if ! PATH="${FAKE_BIN}:${PATH}" SMOKE_SUITES="TTestCase_Socket" bash "${SOCKET_DIR}/smoke.sh" >/dev/null 2>&1; then
  echo "[FAIL] socket smoke runner should work with default build mode project" >&2
  exit 1
fi

if ! grep -q -- '--suite=TTestCase_Socket' "${ARGS_LOG}"; then
  echo "[FAIL] smoke runner did not pass suite argument through" >&2
  exit 1
fi

if ! grep -q -- '--format=plain' "${ARGS_LOG}"; then
  echo "[FAIL] smoke runner did not pass plain format through" >&2
  exit 1
fi

echo "[PASS] socket smoke runner works without forcing a missing build mode"
