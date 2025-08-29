@echo off
echo ========================================
echo fafafa.core.sync.mutex 示例构建脚本
echo ========================================

if not exist "bin" mkdir bin
if not exist "lib" mkdir lib

echo 正在编译示例...
lazbuild --build-mode=Default example_basic_usage.lpi

if %ERRORLEVEL% EQU 0 (
    echo ✓ 编译成功！
    echo.
    echo 正在运行示例...
    echo ========================================
    bin\example_basic_usage.exe
    echo ========================================
    echo ✓ 示例运行完成！
) else (
    echo ✗ 编译失败！
    exit /b 1
)

pause
