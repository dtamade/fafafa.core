#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LAZBUILD="lazbuild"

# Build Debug for all examples
"$LAZBUILD" --build-mode=Debug "$SCRIPT_DIR/example_mem.lpi"
"$LAZBUILD" --build-mode=Debug "$SCRIPT_DIR/example_mem_pool_basic.lpi"
"$LAZBUILD" --build-mode=Debug "$SCRIPT_DIR/example_mem_pool_config.lpi"

"$LAZBUILD" --build-mode=Debug "$SCRIPT_DIR/example_stack_scope.lpi"
"$LAZBUILD" --build-mode=Debug "$SCRIPT_DIR/example_mem_pool_exceptions.lpi"
"$LAZBUILD" --build-mode=Debug "$SCRIPT_DIR/example_mem_integration_runner.lpi"
"$LAZBUILD" --build-mode=Debug "$SCRIPT_DIR/example_mem_interface.lpi"

# 单文件示例（无 lpi）：对齐异常语义演示
"$LAZBUILD" --build-mode=Debug "$SCRIPT_DIR/example_align_exceptions.lpr"

echo "All examples built (Debug)."

