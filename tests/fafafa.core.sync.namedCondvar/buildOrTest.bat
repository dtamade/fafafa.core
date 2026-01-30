@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.namedConditionVariable 测试构建
echo ========================================

set PROJECT_NAME=fafafa.core.sync.namedConditionVariable.test
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
lazbuild --build-mode=Debug %PROJECT_FILE%

if %errorlevel% neq 0 (
    echo.
    echo 构建失败！
if "%FAFAFA_INTERACTIVE%"=="1" if "%FAFAFA_INTERACTIVE%"=="1" pause
    exit /b 1
)

echo.
echo 构建成功！

:: 检查是否要运行测试
if "%1"=="test" goto run_test
if "%1"=="run" goto run_test

echo.
echo 要运行测试吗？ (Y/N)
set /p choice=
if /i "%choice%"=="Y" goto run_test
if /i "%choice%"=="yes" goto run_test
goto end

:run_test
echo.
echo ========================================
echo 运行测试...
echo ========================================

if not exist %EXECUTABLE% (
    echo 错误: 找不到可执行文件 %EXECUTABLE%
if "%FAFAFA_INTERACTIVE%"=="1" if "%FAFAFA_INTERACTIVE%"=="1" pause
    exit /b 1
)

%EXECUTABLE%
set test_result=%errorlevel%

echo.
if %test_result% equ 0 (
    echo 测试通过！
) else (
    echo 测试失败！错误代码: %test_result%
)

:end
echo.
echo 完成。
if "%1"=="" pause
exit /b %test_result%
