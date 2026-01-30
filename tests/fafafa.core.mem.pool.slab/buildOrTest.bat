@echo off

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=fafafa.core.mem.pool.slab.test.lpi"
set "TEST_EXECUTABLE=%SCRIPT_DIR%bin\fafafa.core.mem.pool.slab.test_debug.exe"

echo Building project: %PROJECT% ...
call "%LAZBUILD%" --build-mode=Debug "%SCRIPT_DIR%\%PROJECT%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed with error code %ERRORLEVEL%.
    goto END
)

echo.
Echo Build successful.
echo.

if /i "%1"=="test" (
    echo Running tests...
    "%TEST_EXECUTABLE%" --all --format=plain
) else (
    echo To run tests, call this script with the 'test' parameter.
)

:END

