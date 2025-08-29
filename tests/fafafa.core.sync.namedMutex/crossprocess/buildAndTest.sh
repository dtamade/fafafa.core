#!/bin/bash

# 跨进程测试构建和执行脚本

set -e

echo "=== 构建跨进程测试程序 ==="
lazbuild --build-mode=Debug fafafa.core.sync.namedMutex.crossprocess.lpi

if [ ! -f "bin/fafafa.core.sync.namedMutex.crossprocess" ]; then
    echo "错误：构建失败"
    exit 1
fi

echo "=== 清理之前的测试文件 ==="
rm -f /tmp/fafafa_crossprocess_counter.txt

echo "=== 启动跨进程测试 ==="
echo "启动 3 个并发进程，每个进程执行 1000 次操作..."

# 启动多个进程并发执行
./bin/fafafa.core.sync.namedMutex.crossprocess &
PID1=$!

./bin/fafafa.core.sync.namedMutex.crossprocess &
PID2=$!

./bin/fafafa.core.sync.namedMutex.crossprocess &
PID3=$!

echo "进程 PID: $PID1, $PID2, $PID3"

# 等待所有进程完成
wait $PID1
RESULT1=$?

wait $PID2
RESULT2=$?

wait $PID3
RESULT3=$?

echo "=== 测试结果 ==="
echo "进程 1 退出码: $RESULT1"
echo "进程 2 退出码: $RESULT2"
echo "进程 3 退出码: $RESULT3"

if [ -f "/tmp/fafafa_crossprocess_counter.txt" ]; then
    FINAL_COUNT=$(cat /tmp/fafafa_crossprocess_counter.txt)
    echo "最终计数: $FINAL_COUNT"
    
    # 期望的计数是 3000 (3个进程 × 1000次操作)
    if [ "$FINAL_COUNT" -eq 3000 ]; then
        echo "✅ 跨进程测试成功！计数正确。"
        rm -f /tmp/fafafa_crossprocess_counter.txt
        exit 0
    else
        echo "❌ 跨进程测试失败！期望计数 3000，实际计数 $FINAL_COUNT"
        exit 1
    fi
else
    echo "❌ 跨进程测试失败！未找到计数文件"
    exit 1
fi
