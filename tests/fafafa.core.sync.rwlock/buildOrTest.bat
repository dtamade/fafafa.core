@echo off
echo Building and testing fafafa.core.sync.rwlock...

REM Set paths
set SRC_PATH=..\..\src
set TEST_PATH=.

REM Compile test
echo Compiling test...
fpc -Fu%SRC_PATH% -FE%TEST_PATH%\bin -FU%TEST_PATH%\lib %TEST_PATH%\fafafa.core.sync.rwlock.test.lpr

if %ERRORLEVEL% neq 0 (
    echo Compilation failed!
    pause
    exit /b 1
)

echo Compilation successful!

REM Run test
echo Running tests...
%TEST_PATH%\bin\fafafa.core.sync.rwlock.test.exe

echo.
echo Test completed.
pause
