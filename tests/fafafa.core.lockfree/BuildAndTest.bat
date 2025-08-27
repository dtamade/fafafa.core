@echo off
setlocal enabledelayedexpansion

:: fafafa.core.lockfree 完整构建和测试脚本
:: 用法: BuildAndTest.bat [clean|test|benchmark|all]

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\.."
set "SRC_DIR=%ROOT_DIR%\src"
set "BIN_DIR=%ROOT_DIR%\bin"
set "TOOLS_DIR=%ROOT_DIR%\tools"
set "LAZBUILD=%TOOLS_DIR%\lazbuild.bat"

:: 检查是否存在 lazbuild 工具
if not exist "%LAZBUILD%" (
    echo 错误: 未找到 lazbuild 工具 (%LAZBUILD%)
    echo 请确保 tools\lazbuild.bat 已正确配置
    exit /b 1
)

:: 创建输出目录
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

:: 解析命令行参数
set "ACTION=%1"
if "%ACTION%"=="" set "ACTION=all"

echo fafafa.core.lockfree 构建和测试系统
echo ====================================
echo.

if "%ACTION%"=="clean" goto :CLEAN
if "%ACTION%"=="test" goto :TEST
if "%ACTION%"=="benchmark" goto :BENCHMARK
if "%ACTION%"=="benchmark-compare" goto :BENCHMARK_COMPARE
if "%ACTION%"=="all" goto :ALL
if "%ACTION%"=="minimal" goto :MINIMAL
if "%ACTION%"=="minimal-runner" goto :MINIMAL_RUNNER
goto :USAGE

:CLEAN
echo 清理构建产物...
if exist "%BIN_DIR%\tests_lockfree.exe" del "%BIN_DIR%\tests_lockfree.exe"
if exist "%BIN_DIR%\lockfree_tests.exe" del "%BIN_DIR%\lockfree_tests.exe"
if exist "%BIN_DIR%\benchmark_lockfree.exe" del "%BIN_DIR%\benchmark_lockfree.exe"
if exist "%BIN_DIR%\example_lockfree.exe" del "%BIN_DIR%\example_lockfree.exe"
if exist "%BIN_DIR%\aba_test.exe" del "%BIN_DIR%\aba_test.exe"
if exist "%SCRIPT_DIR%lib" rmdir /s /q "%SCRIPT_DIR%lib"
echo 清理完成
goto :END

:TEST
echo 开始测试流程...
echo.

:: 1. 编译基础测试
echo [1/4] 编译基础功能测试...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%tests_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 基础测试编译失败
    exit /b 1
)

:: 2. 运行基础测试
echo [2/4] 运行基础功能测试...
"%BIN_DIR%\tests_lockfree.exe"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 基础测试运行失败
    exit /b 1
)

:: 3. 编译ABA问题验证测试
echo [3/4] 编译ABA问题验证测试...
call "%LAZBUILD%" --build-mode=Release "%ROOT_DIR%\play\fafafa.core.lockfree\aba_test.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: ABA测试编译失败
    exit /b 1
)

:: 4. 运行ABA测试（避免管道输入引发本地化问题）
echo [4/4] 运行ABA问题验证测试...
"%BIN_DIR%\aba_test.exe"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: ABA测试运行失败
    exit /b 1
)

echo.
echo ✅ 所有测试通过！
goto :END

:BENCHMARK
echo 开始性能基准测试...
echo.

:: 编译基准测试
echo [1/2] 编译性能基准测试...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%benchmark_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 基准测试编译失败
    exit /b 1
)

:: 运行基准测试
echo [2/2] 运行性能基准测试...
echo y | "%BIN_DIR%\benchmark_lockfree.exe"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 基准测试运行失败
    exit /b 1
)

echo.
echo ✅ 性能基准测试完成！
:MINIMAL
echo 运行最小回归测试（独立可执行）...
echo.

rem 直接调用 BuildOrTest.bat minimal 完成构建与运行
call "%SCRIPT_DIR%BuildOrTest.bat" minimal
set "RC=%ERRORLEVEL%"
echo 最小回归测试退出码: %RC%
goto :END
:MINIMAL_RUNNER
echo 运行最小回归测试（runner 工程）...
echo.

rem 直接调用 BuildOrTest.bat minimal-runner 完成构建与运行
call "%SCRIPT_DIR%BuildOrTest.bat" minimal-runner
set "RC=%ERRORLEVEL%"
echo 最小回归（runner）退出码: %RC%
goto :END



goto :END

:ALL
echo 开始完整构建和测试流程...
echo.

:: 1. 清理
call :CLEAN

:: 2. 编译所有项目（迁移至 lazbuild）
echo [1/8] 编译基础功能测试...
call "%LAZBUILD%" --build-mode=Debug "%SCRIPT_DIR%tests_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 基础测试编译失败
    exit /b 1
)

echo [2/8] 编译单元测试...
call "%LAZBUILD%" --build-mode=Debug "%SCRIPT_DIR%fafafa.core.lockfree.tests.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 单元测试编译失败
    exit /b 1
)

echo [3/8] 编译示例程序...
call "%LAZBUILD%" --build-mode=Debug "%ROOT_DIR%\examples\fafafa.core.lockfree\example_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 示例程序编译失败
    exit /b 1
)

echo [4/8] 编译ABA验证测试...
call "%LAZBUILD%" --build-mode=Debug "%ROOT_DIR%\play\fafafa.core.lockfree\aba_test.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: ABA测试编译失败
    exit /b 1
)

echo [5/8] 编译性能基准测试...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%benchmark_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 基准测试编译失败
    exit /b 1
)


:: 2b. 额外测试编译（使用 fpc 直接构建）
echo [附加] 编译 OA HashMap 额外测试...
call fpc -Fu"%SRC_DIR%" -FE"%BIN_DIR%" "%SCRIPT_DIR%test_oa_hashmap_extras.lpr"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: OA 额外测试编译失败
    exit /b 1
)

echo [附加] 编译 Padding 冒烟测试...
call fpc -Fu"%SRC_DIR%" -FE"%BIN_DIR%" "%SCRIPT_DIR%test_padding_smoke.lpr"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: Padding 冒烟测试编译失败
    exit /b 1
)

echo [附加] 编译 RingBuffer 冒烟测试...
call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%smoke_ringbuffer.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: RingBuffer 冒烟测试编译失败
    exit /b 1
)

:: 3. 运行所有测试
echo [6/6] 运行所有测试...
echo.

echo --- 基础功能测试 ---
"%BIN_DIR%\tests_lockfree.exe"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 基础测试失败
    exit /b 1
)
echo.
echo --- OA HashMap 额外测试 ---
"%BIN_DIR%\test_oa_hashmap_extras.exe"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: OA 额外测试失败
    exit /b 1
)

echo.
echo --- Padding 冒烟测试 ---
"%BIN_DIR%\test_padding_smoke.exe"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: Padding 冒烟测试失败
    exit /b 1
)


echo.
echo --- ABA问题验证测试 ---
"%BIN_DIR%\aba_test.exe"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: ABA测试失败
    exit /b 1
)

echo.
echo --- 示例程序测试 ---
"%BIN_DIR%\example_lockfree.exe"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: 示例程序失败
    exit /b 1
)

echo.
echo 🎉 所有构建和测试完成！
echo.
echo 生成的文件:
echo   - %BIN_DIR%\tests_lockfree.exe        (基础功能测试)
echo   - %BIN_DIR%\lockfree_tests.exe        (单元测试)
echo   - %BIN_DIR%\example_lockfree.exe      (示例程序)
echo   - %BIN_DIR%\aba_test.exe              (ABA验证测试)
echo   - %BIN_DIR%\benchmark_lockfree.exe    (性能基准测试)
echo.
echo 要运行性能基准测试，请执行:
echo   BuildAndTest.bat benchmark
goto :END

:BENCHMARK_COMPARE
echo 开始 PadOn/PadOff 基准对比...

:: 编译 PadOff
call "%LAZBUILD%" --build-mode=PadOff "%SCRIPT_DIR%benchmark_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: PadOff 构建失败
    exit /b 1
)

:: 编译 PadOn
call "%LAZBUILD%" --build-mode=PadOn "%SCRIPT_DIR%benchmark_lockfree.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo 错误: PadOn 构建失败
    exit /b 1
)

:: 运行两组

:: 记录日志目录
set "LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "LOG_FILE=%LOG_DIR%\benchmark_pad_compare_%DATE:~0,10%_%TIME:~0,2%-%TIME:~3,2%-%TIME:~6,2%.log"
set "LOG_FILE=%LOG_FILE: =0%"
echo [info] 日志: %LOG_FILE%

:: tee-like 输出函数（简化版）
>"%LOG_FILE%" (
  echo ===== 运行 PadOff =====
)

echo ===== 运行 PadOff =====
echo. | "%EXE_OFF%" >> "%LOG_FILE%" 2>&1
set "EC1=%ERRORLEVEL%"

>>"%LOG_FILE%" echo.
>>"%LOG_FILE%" echo ===== 运行 PadOn =====

echo.
echo ===== 运行 PadOn =====
echo. | "%EXE_ON%" >> "%LOG_FILE%" 2>&1
set "EC2=%ERRORLEVEL%"

>>"%LOG_FILE%" echo.
>>"%LOG_FILE%" echo 退出码: PadOff=%EC1% PadOn=%EC2%

echo.
echo 退出码: PadOff=%EC1% PadOn=%EC2%

type "%LOG_FILE%"
copy /Y "%LOG_FILE%" "%LOG_DIR%\latest.log" >NUL

set "EXE_OFF=%BIN_DIR%\benchmark_lockfree_padoff.exe"
set "EXE_ON=%BIN_DIR%\benchmark_lockfree_padon.exe"

if not exist "%EXE_OFF%" (
    echo 错误: 未找到 %EXE_OFF%
    exit /b 1
)
if not exist "%EXE_ON%" (
    echo 错误: 未找到 %EXE_ON%
    exit /b 1
)

echo.
echo ===== 运行 PadOff =====
echo. | "%EXE_OFF%"
set "EC1=%ERRORLEVEL%"

echo.
echo ===== 运行 PadOn =====
echo. | "%EXE_ON%"
set "EC2=%ERRORLEVEL%"

echo.
echo 退出码: PadOff=%EC1% PadOn=%EC2%
if %EC1% NEQ 0 exit /b %EC1%
if %EC2% NEQ 0 exit /b %EC2%

echo.
echo ✅ 基准对比完成
goto :END

:USAGE
echo 用法: BuildAndTest.bat [选项]
echo.
echo 选项:
echo   clean      - 清理构建产物
echo   test            - 编译并运行测试
echo   minimal         - 编译并运行最小回归测试（独立可执行集合）
echo   minimal-runner  - 构建并运行最小回归测试（runner 工程）
echo   benchmark       - 编译并运行性能基准测试
echo   benchmark-compare  - 构建并运行 PadOff / PadOn 对比
echo   all             - 完整构建和测试流程 (默认)
echo.
echo 示例:
echo   BuildAndTest.bat             # 完整构建和测试
echo   BuildAndTest.bat test        # 只运行测试
echo   BuildAndTest.bat minimal     # 运行最小回归测试
echo   BuildAndTest.bat minimal-runner  # 运行最小回归测试（runner 工程）
echo   BuildAndTest.bat benchmark   # 只运行性能测试
echo   BuildAndTest.bat clean       # 清理构建产物
goto :END

:END
echo.
pause
