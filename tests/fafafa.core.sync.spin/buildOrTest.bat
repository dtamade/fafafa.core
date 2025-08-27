@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.spin 单元测试构建脚本
echo ========================================

set PROJECT_NAME=fafafa.core.sync.spin.test
set PROJECT_FILE=%PROJECT_NAME%.lpi
set EXECUTABLE=bin\%PROJECT_NAME%.exe

:: 检查 lazbuild 是否可用
where lazbuild >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 找不到 lazbuild 命令，请确保 Lazarus 已正确安装并添加到 PATH
    exit /b 1
)

:: 创建输出目录
if not exist bin mkdir bin
if not exist lib mkdir lib

:: 构建项目
echo 正在构建项目...
lazbuild --build-mode=Debug %PROJECT_FILE%
if %errorlevel% neq 0 (
    echo 构建失败！
    exit /b 1
)

echo 构建成功！

:: 检查是否需要运行测试
if "%1"=="test" (
    echo.
    echo 正在运行测试...
    if exist %EXECUTABLE% (
        %EXECUTABLE%
        echo.
        echo 测试完成，退出代码: !errorlevel!
    ) else (
        echo 错误: 找不到可执行文件 %EXECUTABLE%
        exit /b 1
    )
) else (
    echo.
    echo 要运行测试，请使用: buildOrTest.bat test
)

echo.
echo 完成！
