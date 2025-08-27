@echo off
setlocal

echo ========================================
echo fafafa.core.sync.once 单元测试构建脚本
echo ========================================

:: 创建输出目录
if not exist "bin" mkdir bin
if not exist "lib" mkdir lib

:: 构建测试项目
echo 正在构建测试项目...
lazbuild fafafa.core.sync.once.test.lpi

if %ERRORLEVEL% neq 0 (
    echo 构建失败！
    pause
    exit /b 1
)

echo 构建成功！

:: 运行测试
echo 正在运行测试...
echo.
bin\fafafa.core.sync.once.test.exe

if %ERRORLEVEL% neq 0 (
    echo 测试失败！
    pause
    exit /b 1
)

echo.
echo 所有测试通过！
pause
