@echo off
echo ========================================
echo fafafa.core.sync.mutex 示例构建脚本
echo ========================================

if not exist "bin" mkdir bin
if not exist "lib" mkdir lib

echo 正在编译基础示例...
lazbuild --build-mode=Default example_basic_usage.lpi

if %ERRORLEVEL% NEQ 0 (
    echo ✗ 基础示例编译失败！
    exit /b 1
)

echo 正在编译高级示例...
lazbuild --build-mode=Default example_advanced_patterns.lpi

if %ERRORLEVEL% NEQ 0 (
    echo ✗ 高级示例编译失败！
    exit /b 1
)

echo ✓ 所有示例编译成功！
echo.

echo 选择要运行的示例：
echo 1. 基础使用示例
echo 2. 高级使用模式示例
echo 3. 运行所有示例
set /p choice="请输入选择 (1-3): "

if "%choice%"=="1" (
    echo.
    echo 正在运行基础示例...
    echo ========================================
    bin\example_basic_usage.exe
    echo ========================================
) else if "%choice%"=="2" (
    echo.
    echo 正在运行高级示例...
    echo ========================================
    bin\example_advanced_patterns.exe
    echo ========================================
) else if "%choice%"=="3" (
    echo.
    echo 正在运行基础示例...
    echo ========================================
    bin\example_basic_usage.exe
    echo ========================================
    echo.
    echo 正在运行高级示例...
    echo ========================================
    bin\example_advanced_patterns.exe
    echo ========================================
) else (
    echo 无效选择，退出。
    exit /b 1
)

echo ✓ 示例运行完成！

pause
