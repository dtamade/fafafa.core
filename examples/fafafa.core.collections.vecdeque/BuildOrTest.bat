@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.collections.vecdeque 示例构建脚本
echo ========================================

set PROJECT_ROOT=%~dp0..\..
set PROJECT_FILE=%~dp0example_vecdeque.lpi
set OUTPUT_DIR=%PROJECT_ROOT%\bin
set LIB_DIR=%~dp0lib

:: 设置 lazbuild 路径
set LAZBUILD=%PROJECT_ROOT%\tools\lazbuild.bat
if not exist "%LAZBUILD%" (
    echo 错误: 找不到 lazbuild 工具: %LAZBUILD%
    echo 请确保项目工具已正确配置
    pause
    exit /b 1
)

:: 创建输出目录
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

echo.
echo 正在编译示例项目...
echo 项目文件: %PROJECT_FILE%
echo 输出目录: %OUTPUT_DIR%
echo.

:: 编译 Debug 版本
echo [1/2] 编译 Debug 版本...
call "%LAZBUILD%" --build-mode=Debug "%PROJECT_FILE%"
if %errorlevel% neq 0 (
    echo.
    echo ❌ Debug 版本编译失败！
    pause
    exit /b 1
)

echo ✅ Debug 版本编译成功

:: 编译 Release 版本
echo.
echo [2/2] 编译 Release 版本...
call "%LAZBUILD%" --build-mode=Release "%PROJECT_FILE%"
if %errorlevel% neq 0 (
    echo.
    echo ❌ Release 版本编译失败！
    pause
    exit /b 1
)

echo ✅ Release 版本编译成功

:: 运行示例
echo.
echo ========================================
echo 运行示例程序
echo ========================================
echo.

set EXAMPLE_EXE=%OUTPUT_DIR%\example_vecdeque.exe
if not exist "%EXAMPLE_EXE%" (
    echo 错误: 找不到示例可执行文件 %EXAMPLE_EXE%
    pause
    exit /b 1
)

echo 执行示例: %EXAMPLE_EXE%
echo.

"%EXAMPLE_EXE%"
set EXAMPLE_RESULT=%errorlevel%

echo.
echo ========================================
if %EXAMPLE_RESULT% equ 0 (
    echo ✅ 示例运行完成！
) else (
    echo ❌ 示例运行出现错误！
    echo 退出代码: %EXAMPLE_RESULT%
)
echo ========================================

pause
exit /b %EXAMPLE_RESULT%
