@echo off
echo ========================================
echo fafafa.core.sync.barrier Test Coverage Summary
echo ========================================
echo.

echo Running global function tests...
.\fafafa.core.sync.barrier.test.exe --suite=TTestCase_Global --format=plain > global_tests.log 2>&1
if %errorlevel% equ 0 (
    echo Global function tests passed
) else (
    echo Global function tests failed ^(exit code: %errorlevel%^)
)

echo.
echo Running IBarrier interface tests...
.\fafafa.core.sync.barrier.test.exe --suite=TTestCase_IBarrier --format=plain > ibarrier_tests.log 2>&1
if %errorlevel% equ 0 (
    echo IBarrier interface tests passed
) else (
    echo IBarrier interface tests failed ^(exit code: %errorlevel%^)
)

echo.
echo Running all tests...
.\fafafa.core.sync.barrier.test.exe --all --format=plain > all_tests.log 2>&1
if %errorlevel% equ 0 (
    echo All tests passed
) else (
    echo Some tests failed ^(exit code: %errorlevel%^)
)

echo.
echo ========================================
echo Test Statistics:
echo ========================================

echo.
echo Global function test methods count:
findstr /C:"Test_MakeBarrier" fafafa.core.sync.barrier.testcase.pas | find /C "procedure"

echo.
echo IBarrier interface test methods count:
findstr /C:"Test_" fafafa.core.sync.barrier.testcase.pas | findstr /C:"IBarrier" | find /C "procedure"

echo.
echo Total test methods count:
findstr /C:"procedure Test_" fafafa.core.sync.barrier.testcase.pas | find /C "procedure"

echo.
echo ========================================
echo Test Coverage Modules:
echo ========================================
echo Factory function MakeBarrier
echo Constructor parameter validation
echo GetParticipantCount method
echo Wait method - single participant
echo Wait method - multiple participants
echo Wait method - serial thread identification
echo Barrier reuse mechanism
echo Concurrent synchronization tests
echo Thread safety tests
echo Boundary condition tests
echo Error condition tests
echo Performance benchmark tests
echo Stress tests

echo.
echo Test log files:
echo - global_tests.log
echo - ibarrier_tests.log
echo - all_tests.log
echo.
