@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.spinMutex 测试构建脚本
echo ========================================

set PROJECT_NAME=fafafa.core.sync.spinMutex.test
set PROJECT_FILE=%PROJECT_NAME%.lpi
set EXECUTABLE=bin\%PROJECT_NAME%.exe

:: 检查 lazbuild 是否可用
where lazbuild >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 找不到 lazbuild 命令
    echo 请确保 Lazarus 已安装并且 lazbuild 在 PATH 中
    pause
    exit /b 1
)

:: 创建输出目录
if not exist bin mkdir bin
if not exist lib mkdir lib

echo.
echo 正在构建项目...
echo 项目文件: %PROJECT_FILE%

:: 构建项目
lazbuild --build-mode=Debug %PROJECT_FILE%
if %errorlevel% neq 0 (
    echo.
    echo 构建失败！
    pause
    exit /b 1
)

echo.
echo 构建成功！

:: 检查可执行文件是否存在
if not exist %EXECUTABLE% (
    echo 错误: 找不到可执行文件 %EXECUTABLE%
    pause
    exit /b 1
)

echo.
echo 正在运行测试...
echo ========================================

:: 运行测试
%EXECUTABLE% --all --progress --format=plain
set TEST_RESULT=%errorlevel%

echo.
echo ========================================
if %TEST_RESULT% equ 0 (
    echo 所有测试通过！
) else (
    echo 测试失败，退出码: %TEST_RESULT%
)

echo.
echo 按任意键退出...
pause >nul
exit /b %TEST_RESULT%
