@echo off
echo ========================================
echo Running fafafa.core.sync.barrier Unit Tests
echo ========================================
echo.

echo 1. Running TTestCase_Global tests...
.\fafafa.core.sync.barrier.test.exe --suite=TTestCase_Global --format=plain > global_test_output.txt 2>&1
set GLOBAL_EXIT=%ERRORLEVEL%
if %GLOBAL_EXIT% equ 0 (
    echo   PASSED: TTestCase_Global tests
) else (
    echo   FAILED: TTestCase_Global tests ^(exit code: %GLOBAL_EXIT%^)
    echo   Check global_test_output.txt for details
)

echo.
echo 2. Running TTestCase_IBarrier tests...
.\fafafa.core.sync.barrier.test.exe --suite=TTestCase_IBarrier --format=plain > ibarrier_test_output.txt 2>&1
set IBARRIER_EXIT=%ERRORLEVEL%
if %IBARRIER_EXIT% equ 0 (
    echo   PASSED: TTestCase_IBarrier tests
) else (
    echo   FAILED: TTestCase_IBarrier tests ^(exit code: %IBARRIER_EXIT%^)
    echo   Check ibarrier_test_output.txt for details
)

echo.
echo 3. Running all tests together...
.\fafafa.core.sync.barrier.test.exe --all --format=plain > all_test_output.txt 2>&1
set ALL_EXIT=%ERRORLEVEL%
if %ALL_EXIT% equ 0 (
    echo   PASSED: All tests
) else (
    echo   FAILED: Some tests ^(exit code: %ALL_EXIT%^)
    echo   Check all_test_output.txt for details
)

echo.
echo ========================================
echo Test Summary:
echo ========================================
echo TTestCase_Global:  %GLOBAL_EXIT%
echo TTestCase_IBarrier: %IBARRIER_EXIT%
echo All Tests:         %ALL_EXIT%

if %ALL_EXIT% equ 0 (
    echo.
    echo SUCCESS: All unit tests passed!
) else (
    echo.
    echo FAILURE: Some tests failed. Check output files for details.
)

echo.
echo Output files generated:
echo - global_test_output.txt
echo - ibarrier_test_output.txt
echo - all_test_output.txt
echo.
