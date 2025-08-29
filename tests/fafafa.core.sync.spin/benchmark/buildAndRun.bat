@echo off
echo 构建并运行 fafafa.core.sync.spin 基准测试...
echo.

echo 构建 Release 版本...
lazbuild --build-mode=Release fafafa.core.sync.spin.benchmark.lpi
if %errorlevel% neq 0 (
    echo 构建失败！
    pause
    exit /b 1
)

echo.
echo 运行基准测试...
echo.
bin\fafafa.core.sync.spin.benchmark.exe

echo.
echo 基准测试完成。
pause
