#!/bin/bash

echo "========================================"
echo "fafafa.core.socket 示例运行脚本"
echo "========================================"
echo

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
EXAMPLE_EXE="$BIN_DIR/example_socket"

echo "项目根目录: $PROJECT_ROOT"
echo "可执行文件: $EXAMPLE_EXE"
echo

# 检查可执行文件是否存在
if [ ! -f "$EXAMPLE_EXE" ]; then
    echo "错误: 找不到示例可执行文件"
    echo "请先运行 build_examples.sh 构建示例"
    exit 1
fi

# 确保可执行权限
chmod +x "$EXAMPLE_EXE" 2>/dev/null || true

echo "========================================"
echo "可用的示例演示"
echo "========================================"
echo
echo "1. 地址解析演示"
echo "2. TCP 服务器 (端口 8080)"
echo "3. TCP 客户端 (连接到 localhost:8080)"
echo "4. UDP 服务器 (端口 9090)"
echo "5. UDP 客户端 (发送到 localhost:9090)"
echo "6. 显示帮助信息"
echo "0. 退出"
echo

while true; do
    read -p "请选择要运行的示例 (0-6): " choice
    
    case $choice in
        0)
            echo "退出示例运行脚本"
            break
            ;;
        1)
            echo
            echo "========================================"
            echo "运行地址解析演示"
            echo "========================================"
            "$EXAMPLE_EXE" address-demo
            echo
            read -p "按 Enter 键继续..."
            ;;
        2)
            echo
            echo "========================================"
            echo "启动 TCP 服务器 (端口 8080)"
            echo "========================================"
            echo "注意: 服务器将持续运行，按 Ctrl+C 停止"
            echo "在另一个终端运行客户端进行测试"
            echo
            "$EXAMPLE_EXE" tcp-server 8080
            echo
            read -p "按 Enter 键继续..."
            ;;
        3)
            echo
            echo "========================================"
            echo "连接 TCP 服务器 (localhost:8080)"
            echo "========================================"
            echo "注意: 请确保 TCP 服务器正在运行"
            echo
            "$EXAMPLE_EXE" tcp-client localhost 8080
            echo
            read -p "按 Enter 键继续..."
            ;;
        4)
            echo
            echo "========================================"
            echo "启动 UDP 服务器 (端口 9090)"
            echo "========================================"
            echo "注意: 服务器将持续运行，按 Ctrl+C 停止"
            echo "在另一个终端运行客户端进行测试"
            echo
            "$EXAMPLE_EXE" udp-server 9090
            echo
            read -p "按 Enter 键继续..."
            ;;
        5)
            echo
            echo "========================================"
            echo "发送 UDP 消息 (localhost:9090)"
            echo "========================================"
            echo "注意: 请确保 UDP 服务器正在运行"
            echo
            "$EXAMPLE_EXE" udp-client localhost 9090
            echo
            read -p "按 Enter 键继续..."
            ;;
        6)
            echo
            echo "========================================"
            echo "显示帮助信息"
            echo "========================================"
            "$EXAMPLE_EXE"
            echo
            read -p "按 Enter 键继续..."
            ;;
        *)
            echo "无效选择，请重新输入"
            ;;
    esac
done
