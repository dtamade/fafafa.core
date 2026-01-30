@echo off
setlocal

set PROJECT_NAME=fafafa.core.simd.cpuinfo.test
set SRC_DIR=..\..\src
set BIN_DIR=bin
set LIB_DIR=lib

echo ========================================
echo Building %PROJECT_NAME%
echo ========================================

REM 创建输出目录
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

REM 编译测试项目
lazbuild -B --bm=Debug --cpu=x86_64 --os=win64 ^
  --build-mode=Debug ^
  -Fu"%SRC_DIR%" ^
  -FE"%BIN_DIR%" ^
  -FU"%LIB_DIR%" ^
  %PROJECT_NAME%.lpi

if %ERRORLEVEL% neq 0 (
    echo 编译失败！
    pause
    exit /b 1
)

echo 编译成功！

REM 询问是否运行测试
set /p RUN_TEST="是否运行测试？(Y/N): "
if /i "%RUN_TEST%"=="Y" (
    echo 运行测试...
    "%BIN_DIR%\%PROJECT_NAME%.exe"
    
    if %ERRORLEVEL% neq 0 (
        echo 测试失败！
    ) else (
        echo 测试完成！
    )
)

pause
