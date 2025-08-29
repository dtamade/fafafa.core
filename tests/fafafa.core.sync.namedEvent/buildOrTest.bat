@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.namedEvent Test Suite
echo ========================================

set PROJECT_NAME=fafafa.core.sync.namedEvent.test
set PROJECT_FILE=%PROJECT_NAME%.lpi
set EXECUTABLE=bin\%PROJECT_NAME%.exe

echo.
echo [INFO] Building %PROJECT_NAME%...

REM 清理之前的构建
if exist bin\*.exe del /q bin\*.exe
if exist lib rmdir /s /q lib

REM 创建输出目录
if not exist bin mkdir bin
if not exist lib mkdir lib

REM 使用 lazbuild 构建项目
lazbuild --build-mode=Debug %PROJECT_FILE%
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Build failed with error code !ERRORLEVEL!
    exit /b !ERRORLEVEL!
)

echo [SUCCESS] Build completed successfully.

REM 检查可执行文件是否存在
if not exist %EXECUTABLE% (
    echo [ERROR] Executable not found: %EXECUTABLE%
    exit /b 1
)

echo.
echo [INFO] Running tests...
echo ----------------------------------------

REM 运行测试
%EXECUTABLE% --all --progress --format=plain
set TEST_RESULT=!ERRORLEVEL!

echo ----------------------------------------
if !TEST_RESULT! equ 0 (
    echo [SUCCESS] All tests passed!
) else (
    echo [FAILURE] Some tests failed. Exit code: !TEST_RESULT!
)

echo.
echo [INFO] Test run completed.
exit /b !TEST_RESULT!
