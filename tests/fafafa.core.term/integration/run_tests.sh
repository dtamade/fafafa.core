#!/bin/bash

# 集成测试运行脚本
# 自动检测终端环境并运行相应的测试

BIN_DIR="../../../bin"
REPORT_DIR="./reports"

# 创建报告目录
mkdir -p "$REPORT_DIR"

# 获取当前时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 检测终端类型
detect_terminal() {
    if [ -n "$TERM_PROGRAM" ]; then
        echo "$TERM_PROGRAM"
    elif [ -n "$TERM" ]; then
        echo "$TERM"
    else
        echo "unknown"
    fi
}

# 获取终端信息
get_terminal_info() {
    echo "Terminal Environment Information"
    echo "==============================="
    echo "TERM: ${TERM:-not set}"
    echo "TERM_PROGRAM: ${TERM_PROGRAM:-not set}"
    echo "TERM_PROGRAM_VERSION: ${TERM_PROGRAM_VERSION:-not set}"
    echo "COLORTERM: ${COLORTERM:-not set}"
    echo "LANG: ${LANG:-not set}"
    echo "LC_ALL: ${LC_ALL:-not set}"
    echo "Terminal size: $(tput cols)x$(tput lines)"
    echo "Color support: $(tput colors) colors"
    echo
}

# 运行兼容性测试
run_compatibility_test() {
    local terminal_type=$(detect_terminal)
    local report_file="$REPORT_DIR/compatibility_${terminal_type}_${TIMESTAMP}.txt"
    
    echo "Running compatibility test for $terminal_type..."
    echo "Report will be saved to: $report_file"
    echo
    
    # 保存终端信息到报告
    {
        get_terminal_info
        echo "Compatibility Test Results"
        echo "========================="
        echo
    } > "$report_file"
    
    # 运行测试并追加到报告
    if [ -x "$BIN_DIR/terminal_compatibility_test" ]; then
        "$BIN_DIR/terminal_compatibility_test" >> "$report_file" 2>&1
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo "Compatibility test completed successfully"
        else
            echo "Compatibility test failed with exit code: $exit_code"
        fi
        
        return $exit_code
    else
        echo "Error: terminal_compatibility_test not found in $BIN_DIR"
        echo "Please run build_integration_tests.sh first"
        return 1
    fi
}

# 运行交互式测试
run_interactive_test() {
    echo "Starting interactive test..."
    echo "This test requires user interaction"
    echo
    
    if [ -x "$BIN_DIR/interactive_test" ]; then
        "$BIN_DIR/interactive_test"
        return $?
    else
        echo "Error: interactive_test not found in $BIN_DIR"
        echo "Please run build_integration_tests.sh first"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "fafafa.core.term Integration Test Runner"
    echo "========================================"
    echo
    echo "Usage: $0 [option]"
    echo
    echo "Options:"
    echo "  -c, --compatibility    Run automated compatibility test"
    echo "  -i, --interactive      Run interactive test"
    echo "  -a, --all             Run all tests"
    echo "  -h, --help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0 -c                 # Run compatibility test only"
    echo "  $0 -i                 # Run interactive test only"
    echo "  $0 -a                 # Run all tests"
    echo
    echo "Reports are saved in: $REPORT_DIR"
}

# 主函数
main() {
    case "${1:-}" in
        -c|--compatibility)
            get_terminal_info
            run_compatibility_test
            ;;
        -i|--interactive)
            get_terminal_info
            run_interactive_test
            ;;
        -a|--all)
            get_terminal_info
            echo "Running all integration tests..."
            echo
            
            echo "1. Running compatibility test..."
            run_compatibility_test
            local compat_result=$?
            
            echo
            echo "2. Running interactive test..."
            echo "Press Enter to continue or Ctrl+C to skip..."
            read
            
            run_interactive_test
            local interactive_result=$?
            
            echo
            echo "Test Summary:"
            echo "============="
            echo "Compatibility test: $([ $compat_result -eq 0 ] && echo "PASSED" || echo "FAILED")"
            echo "Interactive test: $([ $interactive_result -eq 0 ] && echo "COMPLETED" || echo "FAILED")"
            ;;
        -h|--help|"")
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
}

# 检查是否在正确的目录中
if [ ! -d "$BIN_DIR" ]; then
    echo "Error: Binary directory $BIN_DIR not found"
    echo "Please run this script from the integration test directory"
    exit 1
fi

# 运行主函数
main "$@"
