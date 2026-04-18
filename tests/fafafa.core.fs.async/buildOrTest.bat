@echo off
setlocal enabledelayedexpansion

echo === fafafa.core.fs.async 测试构建脚本 ===
echo.

set "SRC_PATH=..\..\src"
set "TEST_PATH=."
set "LIB_PATH=lib"
set "BIN_PATH=bin"

:: 创建输出目录
if not exist "%LIB_PATH%" mkdir "%LIB_PATH%"
if not exist "%BIN_PATH%" mkdir "%BIN_PATH%"

:: 编译器参数
set "FPC_OPTS=-MObjFPC -Scghi -O1 -g -gl -l -vewnhibq"
set "FPC_PATHS=-Fu%SRC_PATH% -FU%LIB_PATH% -FE%BIN_PATH%"

echo 正在编译异步文件系统测试...

:: 编译测试
fpc %FPC_OPTS% %FPC_PATHS% run_async_tests.lpr

if %ERRORLEVEL% neq 0 (
    echo 编译失败！
    pause
    exit /b 1
)

echo 编译成功！
echo.

:: 如果传入参数为 "test"，则运行测试
if "%1"=="test" (
    echo 正在运行测试...
    echo.
    %BIN_PATH%\run_async_tests.exe
    
    if %ERRORLEVEL% neq 0 (
        echo 测试失败！
        pause
        exit /b 1
    )
    
    echo.
    echo 所有测试通过！
)

echo 完成。
pause
