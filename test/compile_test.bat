@echo off
echo 编译 fafafa.core.time.tick 测试程序
echo =====================================

set FPC_PATH=fpc
set SRC_PATH=..\src
set TEST_PATH=.

echo.
echo 编译测试程序...
%FPC_PATH% -Fu%SRC_PATH% -FE%TEST_PATH% -o%TEST_PATH%\test_tick.exe %TEST_PATH%\test_tick.pas

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ 编译成功！
    echo.
    echo 运行测试程序...
    echo =====================================
    %TEST_PATH%\test_tick.exe
) else (
    echo.
    echo ✗ 编译失败！
    echo 错误代码: %ERRORLEVEL%
)

pause
