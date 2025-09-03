@echo off
REM Build and test script for fafafa.core.sync.mutex.parkinglot
REM Usage: buildOrTest.bat [build|test|clean|help]

setlocal enabledelayedexpansion

set "PROJECT_NAME=fafafa.core.sync.mutex.parkinglot.test"
set "PROJECT_FILE=%PROJECT_NAME%.lpi"
set "EXECUTABLE=bin\%PROJECT_NAME%.exe"

if "%1"=="" goto :test
if /i "%1"=="help" goto :help
if /i "%1"=="build" goto :build
if /i "%1"=="test" goto :test
if /i "%1"=="clean" goto :clean

echo Unknown command: %1
goto :help

:help
echo.
echo fafafa.core.sync.mutex.parkinglot 测试构建脚本
echo.
echo 用法: %0 [命令]
echo.
echo 命令:
echo   build  - 仅构建测试程序
echo   test   - 构建并运行测试 (默认)
echo   clean  - 清理构建产物
echo   help   - 显示此帮助信息
echo.
echo 示例:
echo   %0           # 构建并运行所有测试
echo   %0 build     # 仅构建
echo   %0 test      # 构建并运行测试
echo   %0 clean     # 清理
echo.
goto :end

:build
echo 构建 %PROJECT_NAME%...
echo.

if not exist "%PROJECT_FILE%" (
    echo 错误: 找不到项目文件 %PROJECT_FILE%
    exit /b 1
)

lazbuild --build-mode=Debug "%PROJECT_FILE%"
if errorlevel 1 (
    echo.
    echo 构建失败!
    exit /b 1
)

echo.
echo 构建成功!
goto :end

:test
echo 构建并测试 %PROJECT_NAME%...
echo.

call :build
if errorlevel 1 goto :end

if not exist "%EXECUTABLE%" (
    echo 错误: 找不到可执行文件 %EXECUTABLE%
    exit /b 1
)

echo.
echo 运行测试...
echo ================================================================================

"%EXECUTABLE%" --format=plain --progress

set "TEST_RESULT=%errorlevel%"

echo.
echo ================================================================================
if %TEST_RESULT% equ 0 (
    echo 所有测试通过! ✓
) else (
    echo 测试失败! ✗ (退出代码: %TEST_RESULT%)
)

exit /b %TEST_RESULT%

:clean
echo 清理构建产物...

if exist "bin" rmdir /s /q "bin"
if exist "lib" rmdir /s /q "lib"
if exist "*.compiled" del /q "*.compiled"
if exist "*.o" del /q "*.o"
if exist "*.ppu" del /q "*.ppu"

echo 清理完成!
goto :end

:end
endlocal
