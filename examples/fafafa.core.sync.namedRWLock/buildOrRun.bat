@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.namedRWLock Example
echo ========================================

REM 设置编译器路径
set LAZBUILD=lazbuild
set PROJECT_FILE=example_basic_usage.lpi
set EXE_FILE=bin\example_basic_usage.exe

REM 创建必要的目录
if not exist "bin" mkdir bin
if not exist "lib" mkdir lib

REM 清理之前的构建
echo 清理之前的构建文件...
if exist "bin\*.exe" del /q "bin\*.exe"
if exist "lib\*.*" del /q /s "lib\*.*"

REM 编译项目
echo 编译示例项目...
%LAZBUILD% --build-mode=Debug %PROJECT_FILE%
if errorlevel 1 (
    echo 编译失败！
    pause
    exit /b 1
)

REM 检查可执行文件是否存在
if not exist "%EXE_FILE%" (
    echo 可执行文件未生成！
    pause
    exit /b 1
)

echo 编译成功！

REM 运行示例
echo.
echo 运行示例程序...
echo ----------------------------------------
"%EXE_FILE%"
set RUN_RESULT=%errorlevel%

echo ----------------------------------------
if %RUN_RESULT% equ 0 (
    echo 示例程序运行完成！
) else (
    echo 示例程序运行失败，错误代码: %RUN_RESULT%
)

echo.
echo 完成。按任意键退出...
pause >nul
exit /b %RUN_RESULT%
