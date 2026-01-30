@echo off
setlocal EnableDelayedExpansion

pushd %~dp0

echo ========================================
echo fafafa.core.simd.cpuinfo.x86 单元测试
echo CWD: %CD%
echo ========================================

echo.
echo [1/2] 编译测试...
"%ProgramFiles%\Lazarus\lazbuild.exe" --build-mode=Debug fafafa.core.simd.cpuinfo.x86.test.lpi
if %ERRORLEVEL% neq 0 (
    echo 编译失败！
    popd
    exit /b 1
)

set EXE=bin\fafafa.core.simd.cpuinfo.x86.test.exe
if not exist "%EXE%" set EXE=bin\fafafa.core.simd.cpuinfo.x86.test

if not exist "%EXE%" (
    echo 未找到可执行文件：%EXE%
    dir /b bin
    popd
    exit /b 1
)

set LOG=run.log

echo.
echo [2/2] 运行测试：%EXE%
"%CD%\%EXE%" >"%LOG%" 2>&1
set ERR=%ERRORLEVEL%

echo 退出码：!ERR!
if !ERR! neq 0 (
    echo 运行失败，以下为日志：
    type "%LOG%"
    popd
    exit /b !ERR!
)

echo 运行成功，关键输出（尾部20行）：
for /f "skip=0 delims=" %%L in ('powershell -NoProfile -Command "Get-Content -Tail 20 '%LOG%'"') do @echo %%L

popd
exit /b 0
