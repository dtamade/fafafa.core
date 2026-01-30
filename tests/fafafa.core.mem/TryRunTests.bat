@echo off
echo ========================================
echo 尝试运行 fafafa.core.mem 测试
echo ========================================
echo.

set "BIN_DIR=..\..\bin"

echo 检查可执行文件...
if exist "%BIN_DIR%\tests_mem.exe" (
    echo ✓ tests_mem.exe 存在
) else (
    echo ✗ tests_mem.exe 不存在
)

if exist "%BIN_DIR%\integration_test.exe" (
    echo ✓ integration_test.exe 存在
) else (
    echo ✗ integration_test.exe 不存在
)

echo.
echo 尝试运行最简单的测试...

if exist "%BIN_DIR%\tests_mem.exe" (
    echo 运行 tests_mem.exe...
    echo 开始时间: %time%
    
    rem 尝试运行，但设置超时
    timeout /t 1 /nobreak >nul
    start /wait /b "" "%BIN_DIR%\tests_mem.exe"
    set "exit_code=%ERRORLEVEL%"
    
    echo 结束时间: %time%
    echo 退出代码: %exit_code%
    
    if %exit_code% EQU 0 (
        echo ✓ 测试通过
    ) else (
        echo ✗ 测试失败或超时
    )
) else (
    echo 跳过 - 可执行文件不存在
)

echo.
echo ========================================
echo 测试尝试完成
echo ========================================

pause
