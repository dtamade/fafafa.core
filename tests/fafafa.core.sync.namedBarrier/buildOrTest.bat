@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.namedBarrier 单元测试
echo ========================================

REM 创建必要的目录
if not exist "bin" mkdir bin
if not exist "lib" mkdir lib

REM 设置编译选项
set COMPILER_OPTIONS=-Mobjfpc -Sh -CX -O1 -g -gl -gh -Xg
set INCLUDE_PATHS=-Fi../../src
set UNIT_PATHS=-Fu../../src
set OUTPUT_DIR=-FUlib -FEbin

REM 编译测试程序
echo 正在编译测试程序...
lazbuild --build-mode=Debug fafafa.core.sync.namedBarrier.test.lpi

if %ERRORLEVEL% neq 0 (
    echo 编译失败！
    pause
    exit /b 1
)

echo 编译成功！

REM 运行测试
echo.
echo 正在运行测试...
echo ----------------------------------------

cd bin
fafafa.core.sync.namedBarrier.test.exe --all --progress --format=plain

set TEST_RESULT=%ERRORLEVEL%

cd ..

echo ----------------------------------------
if %TEST_RESULT% equ 0 (
    echo 所有测试通过！
) else (
    echo 测试失败，错误代码: %TEST_RESULT%
)

echo.
echo 测试完成。
pause
