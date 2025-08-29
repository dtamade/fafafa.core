@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.sync.namedEvent Examples
echo ========================================

set FAILED_BUILDS=0
set TOTAL_BUILDS=0

echo.
echo [INFO] 编译所有示例程序...

REM 编译基本使用示例
echo [INFO] 编译基本使用示例...
set /a TOTAL_BUILDS+=1
fpc -Mobjfpc -Sh -Fu../../src example_basic_usage.lpr
if !ERRORLEVEL! neq 0 (
    echo [ERROR] 基本使用示例编译失败
    set /a FAILED_BUILDS+=1
) else (
    echo [SUCCESS] 基本使用示例编译成功
)

REM 编译跨进程生产者
echo [INFO] 编译跨进程生产者...
set /a TOTAL_BUILDS+=1
fpc -Mobjfpc -Sh -Fu../../src example_crossprocess_producer.lpr
if !ERRORLEVEL! neq 0 (
    echo [ERROR] 跨进程生产者编译失败
    set /a FAILED_BUILDS+=1
) else (
    echo [SUCCESS] 跨进程生产者编译成功
)

REM 编译跨进程消费者
echo [INFO] 编译跨进程消费者...
set /a TOTAL_BUILDS+=1
fpc -Mobjfpc -Sh -Fu../../src example_crossprocess_consumer.lpr
if !ERRORLEVEL! neq 0 (
    echo [ERROR] 跨进程消费者编译失败
    set /a FAILED_BUILDS+=1
) else (
    echo [SUCCESS] 跨进程消费者编译成功
)

REM 编译多线程示例
echo [INFO] 编译多线程示例...
set /a TOTAL_BUILDS+=1
fpc -Mobjfpc -Sh -Fu../../src example_multithreading.lpr
if !ERRORLEVEL! neq 0 (
    echo [ERROR] 多线程示例编译失败
    set /a FAILED_BUILDS+=1
) else (
    echo [SUCCESS] 多线程示例编译成功
)

echo.
echo ========================================
echo 编译结果汇总
echo ========================================
echo 总示例数: !TOTAL_BUILDS!
echo 编译成功: !TOTAL_BUILDS! - !FAILED_BUILDS! = %SUCCESS_BUILDS%
echo 编译失败: !FAILED_BUILDS!

if !FAILED_BUILDS! equ 0 (
    echo.
    echo 🎉 所有示例编译成功！
    echo.
    echo 运行示例:
    echo   基本使用: example_basic_usage.exe
    echo   多线程:   example_multithreading.exe
    echo   跨进程:   先运行 example_crossprocess_consumer.exe
    echo            再运行 example_crossprocess_producer.exe
    echo.
    
    REM 询问是否运行基本示例
    set /p RUN_BASIC="是否运行基本使用示例? (y/n): "
    if /i "!RUN_BASIC!"=="y" (
        echo.
        echo [INFO] 运行基本使用示例...
        echo ========================================
        example_basic_usage.exe
        echo ========================================
    )
    
    exit /b 0
) else (
    echo.
    echo ❌ 有 !FAILED_BUILDS! 个示例编译失败，请检查错误信息
    exit /b 1
)
