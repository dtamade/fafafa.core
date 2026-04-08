#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

SOCKET_DIR="tests/fafafa.core.socket.async"
FS_DIR="tests/fafafa.core.fs.async"

[[ -f "${SOCKET_DIR}/BuildOrTest.bat" ]] || { echo "[FAIL] missing ${SOCKET_DIR}/BuildOrTest.bat"; exit 1; }
[[ -f "${SOCKET_DIR}/BuildOrTest.sh" ]] || { echo "[FAIL] missing ${SOCKET_DIR}/BuildOrTest.sh"; exit 1; }
[[ ! -e "${SOCKET_DIR}/buildOrTest.bat" ]] || { echo "[FAIL] stale lowercase runner remains in ${SOCKET_DIR}"; exit 1; }

[[ -f "${FS_DIR}/BuildOrTest.bat" ]] || { echo "[FAIL] missing ${FS_DIR}/BuildOrTest.bat"; exit 1; }
[[ ! -e "${FS_DIR}/buildOrTest.bat" ]] || { echo "[FAIL] stale lowercase runner remains in ${FS_DIR}"; exit 1; }
[[ ! -e "${FS_DIR}/BuildOrTest.sh" ]] || { echo "[FAIL] ${FS_DIR}/BuildOrTest.sh should stay absent until the source blocker is fixed"; exit 1; }
[[ ! -e "${FS_DIR}/test_simple.pas" ]] || { echo "[FAIL] stale ${FS_DIR}/test_simple.pas still exists"; exit 1; }
[[ -f "${FS_DIR}/README.md" ]] || { echo "[FAIL] missing ${FS_DIR}/README.md"; exit 1; }

echo "[PASS] async runner hygiene matches the current L0 policy"
