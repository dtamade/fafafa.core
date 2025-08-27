@echo off
echo === fafafa.core.socket 基础功能验证 ===
echo.

echo 编译基础测试程序...
fpc -Fu../src socket_basic_test.pas -o socket_basic_test.exe

if %ERRORLEVEL% EQU 0 (
    echo ✅ 编译成功
    echo.
    echo 运行测试...
    socket_basic_test.exe
) else (
    echo ❌ 编译失败
    pause
)
