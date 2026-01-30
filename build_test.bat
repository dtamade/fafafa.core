@echo off
echo Building and testing fafafa.core.atomic...

REM Set Lazarus path
set LAZARUS_PATH=D:\devtools\lazarus\trunk

REM Build the test project
echo Building tests...
"%LAZARUS_PATH%\lazbuild.exe" -B -vewnhibq tests\fafafa.core.atomic\tests_atomic.lpi

if %ERRORLEVEL% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo Build successful!

REM Run the tests
echo Running tests...
tests\fafafa.core.atomic\bin\tests_atomic.exe

if %ERRORLEVEL% neq 0 (
    echo Tests failed!
    pause
    exit /b 1
)

echo All tests passed!
pause
