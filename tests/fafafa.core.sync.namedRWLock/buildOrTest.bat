@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.namedRWLock 单元测试
echo ========================================

REM 设置编译器路径
set LAZBUILD=lazbuild
set PROJECT_FILE=fafafa.core.sync.namedRWLock.test.lpi
set EXE_FILE=bin\fafafa.core.sync.namedRWLock.test.exe

REM 创建必要的目录
if not exist "bin" mkdir bin
if not exist "lib" mkdir lib

REM 清理之前的构建
echo 清理之前的构建文件...
if exist "bin\*.exe" del /q "bin\*.exe"
if exist "lib\*.*" del /q /s "lib\*.*"

REM 编译项目
echo 编译测试项目...
%LAZBUILD% --build-mode=Debug %PROJECT_FILE%
if errorlevel 1 (
    echo 编译失败！
if "%FAFAFA_INTERACTIVE%"=="1" if "%FAFAFA_INTERACTIVE%"=="1" pause
    exit /b 1
)

REM 检查可执行文件是否存在
if not exist "%EXE_FILE%" (
    echo 可执行文件未生成！
if "%FAFAFA_INTERACTIVE%"=="1" if "%FAFAFA_INTERACTIVE%"=="1" pause
    exit /b 1
)

echo 编译成功！

REM 运行测试
echo.
echo 运行单元测试...
echo ----------------------------------------
"%EXE_FILE%" --all --progress --format=plain
set TEST_RESULT=%errorlevel%

echo ----------------------------------------
if %TEST_RESULT% equ 0 (
    echo 所有测试通过！
) else (
    echo 测试失败，错误代码: %TEST_RESULT%
)

echo.
echo 测试完成。按任意键退出...
if "%FAFAFA_INTERACTIVE%"=="1" pause >nul
exit /b %TEST_RESULT%
