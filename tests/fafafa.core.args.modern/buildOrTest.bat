@echo off
setlocal

cd /d "%~dp0"

echo Building fafafa.core.args.modern tests...

REM 创建输出目录
if not exist bin mkdir bin
if not exist lib mkdir lib

REM 编译测试
lazbuild --build-mode=Debug fafafa.core.args.modern.test.lpi

if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo Build successful!

REM 运行测试
echo Running tests...
bin\fafafa.core.args.modern.test.exe

pause
