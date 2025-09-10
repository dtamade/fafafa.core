@echo off
setlocal

set PROJECT_NAME=fafafa.core.simd.intrinsics.sse.test
set PROJECT_FILE=%PROJECT_NAME%.lpi
set EXECUTABLE=bin\%PROJECT_NAME%.exe

echo Building %PROJECT_NAME%...
echo ================================

lazbuild %PROJECT_FILE%
if %ERRORLEVEL% neq 0 (
    echo Build failed!
    exit /b 1
)

echo Build successful!
echo.

if "%1"=="test" (
    echo Running tests...
    echo ================
    %EXECUTABLE%
    if %ERRORLEVEL% equ 0 (
        echo.
        echo All tests passed!
    ) else (
        echo.
        echo Some tests failed!
        exit /b 1
    )
) else (
    echo To run tests, use: buildOrTest.bat test
)

echo.
echo Done.
