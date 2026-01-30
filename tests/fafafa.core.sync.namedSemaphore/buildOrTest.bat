@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.namedSemaphore 测试构建
echo ========================================

set PROJECT_NAME=fafafa.core.sync.namedSemaphore.test
set PROJECT_FILE=%PROJECT_NAME%.lpi
set EXECUTABLE=bin\%PROJECT_NAME%.exe

:: 检查 lazbuild 是否可用
where lazbuild >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 找不到 lazbuild 命令
    echo 请确保 Lazarus 已安装并且 lazbuild 在 PATH 中
if "%FAFAFA_INTERACTIVE%"=="1" if "%FAFAFA_INTERACTIVE%"=="1" pause
    exit /b 1
)

:: 创建输出目录
if not exist bin mkdir bin
if not exist lib mkdir lib

echo.
echo 正在构建项目...
echo 项目文件: %PROJECT_FILE%
echo 输出文件: %EXECUTABLE%
echo.

:: 构建项目（Debug 模式，启用内存泄漏检查）
lazbuild --build-mode=Debug %PROJECT_FILE%

if %errorlevel% neq 0 (
    echo.
    echo 构建失败！
if "%FAFAFA_INTERACTIVE%"=="1" if "%FAFAFA_INTERACTIVE%"=="1" pause
    exit /b 1
)

echo.
echo 构建成功！
echo.

:: 检查是否要运行测试
set /p RUN_TEST="是否运行测试？(Y/N): "
if /i "%RUN_TEST%"=="Y" (
    echo.
    echo 正在运行测试...
    echo ========================================
    %EXECUTABLE%
    echo ========================================
    echo.
    echo 测试完成。
) else (
    echo.
    echo 跳过测试运行。
    echo 要手动运行测试，请执行: %EXECUTABLE%
)

echo.
if "%FAFAFA_INTERACTIVE%"=="1" if "%FAFAFA_INTERACTIVE%"=="1" pause
