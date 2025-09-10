@echo off
echo ========================================
echo fafafa.core.sync.once Build and Test
echo ========================================
echo.

echo 1. Cleaning previous build...
if exist "bin" (
  rmdir /s /q "bin"
)
if exist "lib" (
  rmdir /s /q "lib"
)
mkdir bin
mkdir lib

echo 2. Building test executable...
lazbuild fafafa.core.sync.once.test.lpi
set BUILD_RESULT=%ERRORLEVEL%

if %BUILD_RESULT% equ 0 (
    echo   SUCCESS: Build completed
) else (
    echo   FAILED: Build failed ^(exit code: %BUILD_RESULT%^)
    exit /b 1
)

echo.
echo 3. Running unit tests...
echo   Testing TTestCase_Global...
bin\fafafa.core.sync.once.test.exe --suite=TTestCase_Global --format=plain > global_test_output.txt 2>&1
set GLOBAL_EXIT=%ERRORLEVEL%

echo   Testing TTestCase_IOnce...
bin\fafafa.core.sync.once.test.exe --suite=TTestCase_IOnce --format=plain > ionce_test_output.txt 2>&1
set IONCE_EXIT=%ERRORLEVEL%

echo   Running all tests...
bin\fafafa.core.sync.once.test.exe --all --format=plain > all_test_output.txt 2>&1
set ALL_EXIT=%ERRORLEVEL%

echo.
echo ========================================
echo Test Results Summary:
echo ========================================
echo TTestCase_Global:  %GLOBAL_EXIT%
echo TTestCase_IOnce:   %IONCE_EXIT%
echo All Tests:         %ALL_EXIT%

if %ALL_EXIT% equ 0 (
    echo.
    echo SUCCESS: All tests passed!
) else (
    echo.
    echo FAILURE: Some tests failed.
    echo Check output files for details:
    echo - global_test_output.txt
    echo - ionce_test_output.txt
    echo - all_test_output.txt
    exit /b 1
)

echo.
echo Build and test completed successfully.
echo.
