@echo off
REM ====================================================================
REM fafafa.core.sync.mutex.parkinglot 测试构建脚本
REM ====================================================================

setlocal enabledelayedexpansion

echo ====================================================================
echo fafafa.core.sync.mutex.parkinglot 单元测试构建脚本
echo ====================================================================

REM 创建输出目录
if not exist "bin" mkdir bin
if not exist "lib" mkdir lib

REM 设置编译选项
set PROJECT_FILE=fafafa.core.sync.mutex.parkinglot.test.lpi
set BUILD_MODE=Debug
set COMPILER_OPTIONS=-dDEBUG -gh -gl

echo.
echo [1/3] 清理旧文件...
if exist "bin\*.exe" del /q "bin\*.exe"
if exist "lib\*.*" del /q /s "lib\*.*"

echo [2/3] 编译测试项目...
lazbuild --build-mode=%BUILD_MODE% %PROJECT_FILE%

if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ 编译失败！
    echo 错误代码: %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo [3/3] 编译成功！

REM 检查是否要运行测试
if "%1"=="test" (
    echo.
    echo ====================================================================
    echo 运行单元测试...
    echo ====================================================================
    echo.
    
    if exist "bin\fafafa.core.sync.mutex.parkinglot.test.exe" (
        "bin\fafafa.core.sync.mutex.parkinglot.test.exe"
        echo.
        echo 测试完成，返回代码: !ERRORLEVEL!
    ) else (
        echo ❌ 找不到测试可执行文件！
        pause
        exit /b 1
    )
) else (
    echo.
    echo ✅ 构建完成！
    echo 可执行文件: bin\fafafa.core.sync.mutex.parkinglot.test.exe
    echo.
    echo 使用方法:
    echo   buildOrTest.bat          - 仅编译
    echo   buildOrTest.bat test     - 编译并运行测试
    echo   bin\fafafa.core.sync.mutex.parkinglot.test.exe - 直接运行测试
)

echo.
pause
