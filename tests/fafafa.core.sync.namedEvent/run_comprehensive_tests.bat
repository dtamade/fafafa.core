@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.namedEvent 综合测试套件
echo ========================================

set FAILED_TESTS=0
set TOTAL_TESTS=0

echo.
echo [INFO] 编译所有测试程序...

REM 编译基础单元测试
echo [INFO] 编译基础单元测试...
lazbuild --build-mode=Debug fafafa.core.sync.namedEvent.test.lpi
if !ERRORLEVEL! neq 0 (
    echo [ERROR] 基础单元测试编译失败
    exit /b 1
)

REM 编译跨进程测试
echo [INFO] 编译跨进程测试...
fpc -Mobjfpc -Sh -Fu../../src crossprocess_test_producer.lpr
if !ERRORLEVEL! neq 0 (
    echo [ERROR] 跨进程生产者编译失败
    exit /b 1
)

fpc -Mobjfpc -Sh -Fu../../src crossprocess_test_consumer.lpr
if !ERRORLEVEL! neq 0 (
    echo [ERROR] 跨进程消费者编译失败
    exit /b 1
)

REM 编译并发测试
echo [INFO] 编译并发测试...
fpc -Mobjfpc -Sh -Fu../../src concurrent_test.lpr
if !ERRORLEVEL! neq 0 (
    echo [ERROR] 并发测试编译失败
    exit /b 1
)

REM 编译压力测试
echo [INFO] 编译压力测试...
fpc -Mobjfpc -Sh -Fu../../src stress_test.lpr
if !ERRORLEVEL! neq 0 (
    echo [ERROR] 压力测试编译失败
    exit /b 1
)

echo [SUCCESS] 所有测试程序编译成功
echo.

REM 运行测试
echo ========================================
echo 开始运行测试...
echo ========================================

REM 1. 基础单元测试
echo.
echo [TEST 1/4] 基础单元测试
echo ----------------------------------------
set /a TOTAL_TESTS+=1
bin\fafafa.core.sync.namedEvent.test.exe --all --progress --format=plain
if !ERRORLEVEL! equ 0 (
    echo [SUCCESS] 基础单元测试通过
) else (
    echo [FAILURE] 基础单元测试失败
    set /a FAILED_TESTS+=1
)

REM 2. 跨进程测试
echo.
echo [TEST 2/4] 跨进程同步测试
echo ----------------------------------------
set /a TOTAL_TESTS+=1

REM 启动消费者（后台）
echo [INFO] 启动跨进程消费者...
start /B crossprocess_test_consumer.exe

REM 等待消费者启动
timeout /t 2 /nobreak >nul

REM 启动生产者
echo [INFO] 启动跨进程生产者...
crossprocess_test_producer.exe
set PRODUCER_RESULT=!ERRORLEVEL!

REM 等待消费者完成
echo [INFO] 等待消费者完成...
timeout /t 5 /nobreak >nul

if !PRODUCER_RESULT! equ 0 (
    echo [SUCCESS] 跨进程测试通过
) else (
    echo [FAILURE] 跨进程测试失败
    set /a FAILED_TESTS+=1
)

REM 3. 并发测试
echo.
echo [TEST 3/4] 多线程并发测试
echo ----------------------------------------
set /a TOTAL_TESTS+=1
concurrent_test.exe
if !ERRORLEVEL! equ 0 (
    echo [SUCCESS] 并发测试通过
) else (
    echo [FAILURE] 并发测试失败
    set /a FAILED_TESTS+=1
)

REM 4. 压力测试
echo.
echo [TEST 4/4] 压力测试
echo ----------------------------------------
set /a TOTAL_TESTS+=1
stress_test.exe
if !ERRORLEVEL! equ 0 (
    echo [SUCCESS] 压力测试通过
) else (
    echo [FAILURE] 压力测试失败
    set /a FAILED_TESTS+=1
)

REM 测试结果汇总
echo.
echo ========================================
echo 测试结果汇总
echo ========================================
echo 总测试数: !TOTAL_TESTS!
echo 通过测试: !TOTAL_TESTS! - !FAILED_TESTS! = %PASSED_TESTS%
echo 失败测试: !FAILED_TESTS!

if !FAILED_TESTS! equ 0 (
    echo.
    echo 🎉 所有测试通过！namedEvent 模块质量优秀！
    exit /b 0
) else (
    echo.
    echo ❌ 有 !FAILED_TESTS! 个测试失败，需要修复
    exit /b 1
)
