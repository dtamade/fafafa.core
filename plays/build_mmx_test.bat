@echo off
echo 编译 MMX 测试程序...

fpc -Fu../src -FE. -FU. mmx_test.pas

if %ERRORLEVEL% EQU 0 (
    echo 编译成功！运行测试...
    echo.
    mmx_test.exe
) else (
    echo 编译失败！
    pause
)
