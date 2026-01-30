#!/bin/bash

echo "========================================"
echo "fafafa.core.socket 示例构建脚本"
echo "========================================"
echo

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXAMPLES_DIR="$SCRIPT_DIR"
BIN_DIR="$EXAMPLES_DIR/bin"
LIB_DIR="$EXAMPLES_DIR/lib"

echo "项目根目录: $PROJECT_ROOT"
echo "示例目录: $EXAMPLES_DIR"
echo "输出目录: $BIN_DIR"
echo "库目录: $LIB_DIR"
echo

# 检查 lazbuild 是否可用
if ! command -v lazbuild &> /dev/null; then
    echo "错误: 找不到 lazbuild 命令"
    echo "请确保 Lazarus 已正确安装并添加到 PATH 环境变量中"
    exit 1
fi

# 创建输出目录
if [ ! -d "$BIN_DIR" ]; then
    echo "创建输出目录: $BIN_DIR"
    mkdir -p "$BIN_DIR"
fi

if [ ! -d "$LIB_DIR" ]; then
    echo "创建库目录: $LIB_DIR"
    mkdir -p "$LIB_DIR"
fi

echo "========================================"
echo "构建 Debug 版本"
echo "========================================"

lazbuild --build-mode=Debug "$EXAMPLES_DIR/example_socket.lpi" || exit 1
lazbuild --build-mode=Debug "$EXAMPLES_DIR/echo_server.lpi" || exit 1
lazbuild --build-mode=Debug "$EXAMPLES_DIR/echo_client.lpi" || exit 1
lazbuild --build-mode=Debug "$EXAMPLES_DIR/udp_server.lpi" || exit 1
lazbuild --build-mode=Debug "$EXAMPLES_DIR/udp_client.lpi" || exit 1
# build minimal nonblocking poller echo example (Debug)
lazbuild --build-mode=Debug "$EXAMPLES_DIR/example_echo_min_poll_nb.lpi" || exit 1

echo "Debug 版本构建成功！"

echo "========================================"
echo "构建 Release 版本"
echo "========================================"

lazbuild --build-mode=Release "$EXAMPLES_DIR/example_socket.lpi" || exit 1
lazbuild --build-mode=Release "$EXAMPLES_DIR/echo_server.lpi" || exit 1
lazbuild --build-mode=Release "$EXAMPLES_DIR/echo_client.lpi" || exit 1
lazbuild --build-mode=Release "$EXAMPLES_DIR/udp_server.lpi" || exit 1
lazbuild --build-mode=Release "$EXAMPLES_DIR/udp_client.lpi" || exit 1
# build minimal nonblocking poller echo example (Release)
lazbuild --build-mode=Release "$EXAMPLES_DIR/example_echo_min_poll_nb.lpi" || exit 1

echo "Release 版本构建成功！"

echo "========================================"
echo "构建完成"
echo "========================================"
echo
echo "可执行文件位置:"
echo "  $BIN_DIR/example_socket"
echo "  $BIN_DIR/echo_server"
echo "  $BIN_DIR/echo_client"
echo
echo "运行示例:"
echo "  $BIN_DIR/example_socket address-demo"
echo "  $BIN_DIR/example_socket tcp-server 8080"
echo "  $BIN_DIR/example_socket tcp-client localhost 8080"
echo "  $BIN_DIR/echo_server --port=8080"
echo "  $BIN_DIR/echo_client --host=127.0.0.1 --port=8080 --message=hello"
echo

# 设置可执行权限
chmod +x "$BIN_DIR/example_socket" "$BIN_DIR/echo_server" "$BIN_DIR/echo_client" 2>/dev/null || true
