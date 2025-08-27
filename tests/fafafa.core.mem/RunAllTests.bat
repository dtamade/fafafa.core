@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.mem 完整测试套件
echo ========================================
echo.

set "BIN_DIR=bin"
set "LOG_DIR=test_logs"
set "TOTAL_TESTS=0"
set "PASSED_TESTS=0"
set "FAILED_TESTS=0"

:: 创建日志目录
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: 获取时间戳
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "timestamp=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%-%dt:~12,2%"

echo 测试时间: %timestamp%
echo 日志目录: %LOG_DIR%
echo.

:: 定义测试程序（mem-only，使用本目录 bin 下的 Debug 可执行）
set "test_programs[0]=tests_mem_debug.exe"
set "test_names[0]=主单元测试 (Debug)"

:: 运行测试函数
:run_test
set "test_exe=%~1"
set "test_name=%~2"
set "test_index=%~3"
set "log_file=%LOG_DIR%\%test_exe%_%timestamp%.log"

echo [%test_index%/1] 运行 %test_name% (%test_exe%)...

if exist "%BIN_DIR%\%test_exe%" (
    echo 开始时间: %time% > "%log_file%"
    echo 测试程序: %test_exe% >> "%log_file%"
    echo 测试名称: %test_name% >> "%log_file%"
    echo ---------------------------------------- >> "%log_file%"
    
    "%BIN_DIR%\%test_exe%" >> "%log_file%" 2>&1
    set "exit_code=!ERRORLEVEL!"
    
    echo ---------------------------------------- >> "%log_file%"
    echo 结束时间: %time% >> "%log_file%"
    echo 退出代码: !exit_code! >> "%log_file%"
    
    if !exit_code! EQU 0 (
        echo   ✓ 通过
        set /a PASSED_TESTS+=1
    ) else (
        echo   ✗ 失败 ^(退出代码: !exit_code!^)
        set /a FAILED_TESTS+=1
    )
    
    set /a TOTAL_TESTS+=1
    echo   日志: %log_file%
) else (
    echo   - 跳过 ^(程序不存在^)
    echo 测试程序不存在: %test_exe% > "%log_file%"
)
echo.
goto :eof

:: 运行所有测试
echo 开始运行完整测试套件...
echo.

for /l %%i in (0,1,0) do (
    call :run_test "!test_programs[%%i]!" "!test_names[%%i]!" %%i
)

:: 生成测试报告
set "report_file=%LOG_DIR%\complete_test_report_%timestamp%.txt"
echo ======================================== > "%report_file%"
echo fafafa.core.mem 完整测试报告 >> "%report_file%"
echo ======================================== >> "%report_file%"
echo 测试时间: %timestamp% >> "%report_file%"
echo 总测试数: %TOTAL_TESTS% >> "%report_file%"
echo 通过数量: %PASSED_TESTS% >> "%report_file%"
echo 失败数量: %FAILED_TESTS% >> "%report_file%"

if %TOTAL_TESTS% GTR 0 (
    set /a success_rate=PASSED_TESTS*100/TOTAL_TESTS
    echo 成功率: !success_rate!%% >> "%report_file%"
) else (
    echo 成功率: 0%% >> "%report_file%"
)

echo. >> "%report_file%"
echo 详细结果: >> "%report_file%"

for /l %%i in (0,1,0) do (
    echo [%%i] !test_names[%%i]! - !test_programs[%%i]! >> "%report_file%"
)

echo ========================================
echo 完整测试套件完成！
echo ========================================
echo.
echo 测试统计:
echo   总测试数: %TOTAL_TESTS%
echo   通过数量: %PASSED_TESTS%
echo   失败数量: %FAILED_TESTS%

if %TOTAL_TESTS% GTR 0 (
    set /a success_rate=PASSED_TESTS*100/TOTAL_TESTS
    echo   成功率: !success_rate!%%
) else (
    echo   成功率: 0%%
)

echo.
echo 测试报告: %report_file%
echo 详细日志: %LOG_DIR%\*.log
echo.

:: 根据结果设置退出代码
if %FAILED_TESTS% GTR 0 (
    echo ⚠️  警告: 有 %FAILED_TESTS% 个测试失败
    echo    请查看日志文件了解详细信息
    set "exit_code=1"
) else if %TOTAL_TESTS% EQU 0 (
    echo ⚠️  警告: 没有找到可执行的测试程序
    echo    请先运行构建脚本生成测试程序
    set "exit_code=2"
) else (
    echo 🎉 所有测试通过！
    echo    fafafa.core.mem 模块工作正常（mem-only）
    set "exit_code=0"
)

echo.
echo 按任意键退出...
pause > nul

exit /b %exit_code%
