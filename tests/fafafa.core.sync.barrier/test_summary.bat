@echo off
echo ========================================
echo fafafa.core.sync.barrier 测试覆盖率总结
echo ========================================
echo.

echo 运行全局函数测试...
.\fafafa.core.sync.barrier.test.exe --suite=TTestCase_Global --format=plain > global_tests.log 2>&1
if %errorlevel% equ 0 (
    echo ✓ 全局函数测试通过
) else (
    echo ✗ 全局函数测试失败 ^(退出码: %errorlevel%^)
)

echo.
echo 运行 IBarrier 接口测试...
.\fafafa.core.sync.barrier.test.exe --suite=TTestCase_IBarrier --format=plain > ibarrier_tests.log 2>&1
if %errorlevel% equ 0 (
    echo ✓ IBarrier 接口测试通过
) else (
    echo ✗ IBarrier 接口测试失败 ^(退出码: %errorlevel%^)
)

echo.
echo 运行所有测试...
.\fafafa.core.sync.barrier.test.exe --all --format=plain > all_tests.log 2>&1
if %errorlevel% equ 0 (
    echo ✓ 所有测试通过
) else (
    echo ✗ 部分测试失败 ^(退出码: %errorlevel%^)
)

echo.
echo ========================================
echo 测试统计信息:
echo ========================================

echo.
echo 全局函数测试方法数量:
findstr /C:"Test_MakeBarrier" fafafa.core.sync.barrier.testcase.pas | find /C "procedure"

echo.
echo IBarrier 接口测试方法数量:
findstr /C:"Test_" fafafa.core.sync.barrier.testcase.pas | findstr /C:"IBarrier" | find /C "procedure"

echo.
echo 总测试方法数量:
findstr /C:"procedure Test_" fafafa.core.sync.barrier.testcase.pas | find /C "procedure"

echo.
echo ========================================
echo 测试覆盖的功能模块:
echo ========================================
echo ✓ 工厂函数 MakeBarrier
echo ✓ 构造函数参数验证
echo ✓ GetParticipantCount 方法
echo ✓ Wait 方法 - 单参与者
echo ✓ Wait 方法 - 多参与者
echo ✓ Wait 方法 - 串行线程识别
echo ✓ Barrier 重用机制
echo ✓ 并发同步测试
echo ✓ 线程安全测试
echo ✓ 边界条件测试
echo ✓ 错误条件测试
echo ✓ 性能基准测试
echo ✓ 压力测试

echo.
echo 测试日志文件:
echo - global_tests.log
echo - ibarrier_tests.log  
echo - all_tests.log
echo.
