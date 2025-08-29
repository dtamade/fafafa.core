@echo off
echo === 编译和运行 SpinMutex 简单测试 ===

cd /d "%~dp0"

echo 正在编译...
lazbuild -B --build-mode=debug simple_spinmutex_test.lpr
if errorlevel 1 (
    echo 编译失败!
    pause
    exit /b 1
)

echo 编译成功，正在运行测试...
echo.

simple_spinmutex_test.exe
if errorlevel 1 (
    echo 测试失败!
    pause
    exit /b 1
)

echo.
echo === 测试完成 ===
pause
