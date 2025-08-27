@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.mutex 单元测试构建脚本
echo ========================================

set PROJECT_FILE=fafafa.core.sync.mutex.test.lpi
set BIN_DIR=bin
set LIB_DIR=lib

:: 创建输出目录
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

:: 清理旧文件
echo 清理旧的构建文件...
if exist "%BIN_DIR%\*.exe" del /q "%BIN_DIR%\*.exe"
if exist "%LIB_DIR%\*.*" del /q "%LIB_DIR%\*.*"

:: 构建项目
echo 构建测试项目...
lazbuild --build-mode=Default "%PROJECT_FILE%"

if %ERRORLEVEL% neq 0 (
    echo 构建失败！
    pause
    exit /b 1
)

echo 构建成功！

:: 运行测试
set TEST_EXE=%BIN_DIR%\fafafa.core.sync.mutex.test.exe
if exist "%TEST_EXE%" (
    echo 运行单元测试...
    "%TEST_EXE%"
    
    if %ERRORLEVEL% neq 0 (
        echo 测试失败！
        pause
        exit /b 1
    )
    
    echo 测试通过！
) else (
    echo 找不到测试可执行文件: %TEST_EXE%
    pause
    exit /b 1
)

echo ========================================
echo 测试完成
echo ========================================
pause
