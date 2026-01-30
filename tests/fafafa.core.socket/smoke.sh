#!/usr/bin/env bash
set -euo pipefail

# Fast smoke: build tests and run a small set of high-signal suites
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$SCRIPT_DIR"
BIN_DIR="$TEST_DIR/bin"
LPI="$TEST_DIR/tests_socket.lpi"

# Check lazbuild
if ! command -v lazbuild >/dev/null 2>&1; then
  echo "错误: 找不到 lazbuild 命令 (请安装 Lazarus 并加入 PATH)"
  exit 1
fi

# Build (Debug by default)
echo "== 构建测试工程: $LPI =="
lazbuild --build-mode=Debug "$LPI"

# Resolve test executable
TEST_EXE="$BIN_DIR/tests_socket"
if [ ! -f "$TEST_EXE" ] && [ -f "$PROJECT_ROOT/bin/tests_socket" ]; then
  TEST_EXE="$PROJECT_ROOT/bin/tests_socket"
fi
if [ ! -f "$TEST_EXE" ]; then
  echo "错误: 未找到测试可执行文件: $TEST_EXE"
  exit 1
fi
chmod +x "$TEST_EXE" 2>/dev/null || true

# Suites to run (space-separated). Allow override by env SMOKE_SUITES
: "${SMOKE_SUITES:=TTestCase_Socket TTestCase_SocketListener}"
ARGS=()
for s in $SMOKE_SUITES; do
  ARGS+=("--suite=$s")
fi

LOG="$BIN_DIR/tests_socket_smoke.log"
echo "== 运行 Smoke 用例: $SMOKE_SUITES =="
"$TEST_EXE" "${ARGS[@]}" --progress --format=plain > "$LOG" 2>&1 || RC=$? || true
RC=${RC:-0}

SUMMARY=$(grep -E 'OK:|Failures|Errors' "$LOG" | tail -n 1 || true)
if [ -n "$SUMMARY" ]; then echo "[SMOKE] Summary: $SUMMARY"; else echo "[SMOKE] Summary: see log $LOG"; fi

if [ "$RC" != "0" ]; then
  echo "[SMOKE] Failed with code $RC. Last 50 lines:"
  tail -n 50 "$LOG" || true
fi
exit "$RC"

