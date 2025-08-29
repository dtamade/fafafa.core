@echo off
setlocal

cd /d "%~dp0"

echo Building fafafa.core.args.v2 tests...

REM 创建输出目录
if not exist bin mkdir bin
if not exist lib mkdir lib

REM 编译测试
lazbuild --build-mode=Debug fafafa.core.args.v2.test.lpi

if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo Build successful!

REM 如果参数是 test，则运行测试
if "%1"=="test" (
    echo Running tests...
    bin\fafafa.core.args.v2.test.exe
    if %errorlevel% neq 0 (
        echo Tests failed!
        pause
        exit /b 1
    )
    echo All tests passed!
)

pause
