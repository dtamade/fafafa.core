#!/bin/bash

echo "编译 fafafa.core.time.tick 测试程序"
echo "====================================="

FPC_PATH="fpc"
SRC_PATH="../src"
TEST_PATH="."

echo
echo "编译测试程序..."
$FPC_PATH -Fu$SRC_PATH -FE$TEST_PATH -o$TEST_PATH/test_tick $TEST_PATH/test_tick.pas

if [ $? -eq 0 ]; then
    echo
    echo "✓ 编译成功！"
    echo
    echo "运行测试程序..."
    echo "====================================="
    $TEST_PATH/test_tick
else
    echo
    echo "✗ 编译失败！"
    echo "错误代码: $?"
fi

echo
echo "按回车键退出..."
read
