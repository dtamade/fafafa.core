@echo off
setlocal enabledelayedexpansion

echo fafafa.core.socket.async 异步Socket测试构建脚本
echo ===============================================

set PROJECT_NAME=fafafa.core.socket.async.test
set SRC_DIR=..\..\src
set TEST_DIR=.
set BIN_DIR=bin
set LIB_DIR=lib

:: 创建输出目录
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

:: 检查参数
if "%1"=="clean" goto :clean
if "%1"=="test" goto :test
if "%1"=="build" goto :build
if "%1"=="" goto :build

echo 用法: %0 [build^|test^|clean]
echo   build - 构建测试程序
echo   test  - 构建并运行测试
echo   clean - 清理生成文件
goto :end

:build
echo 正在构建异步Socket测试...
echo.

:: 使用 lazbuild 构建项目
lazbuild --build-mode=debug ^
         --target-os=win64 ^
         --target-cpu=x86_64 ^
         -B ^
         --bm=debug ^
         -Fu"%SRC_DIR%" ^
         -FU"%LIB_DIR%" ^
         -FE"%BIN_DIR%" ^
         -o"%BIN_DIR%\%PROJECT_NAME%.exe" ^
         "%PROJECT_NAME%.lpr"

if errorlevel 1 (
    echo 构建失败！
    exit /b 1
) else (
    echo 构建成功！
    echo 可执行文件: %BIN_DIR%\%PROJECT_NAME%.exe
)
goto :end

:test
echo 正在构建并运行异步Socket测试...
echo.

call :build
if errorlevel 1 goto :end

echo.
echo 运行测试...
echo ============

cd "%BIN_DIR%"
"%PROJECT_NAME%.exe" --all --progress --format=plain
set TEST_RESULT=!errorlevel!
cd ..

echo.
if !TEST_RESULT! equ 0 (
    echo 所有测试通过！
) else (
    echo 测试失败，错误代码: !TEST_RESULT!
)

exit /b !TEST_RESULT!

:clean
echo 清理生成文件...
if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
echo 清理完成！
goto :end

:end
endlocal
