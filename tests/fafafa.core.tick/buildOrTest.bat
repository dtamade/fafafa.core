@echo off

REM Set paths relative to the script's location
SET SCRIPT_DIR=%~dp0
SET LAZBUILD="D:\devtools\lazarus\trunk\lazarus\lazbuild.exe"
SET PROJECT="%SCRIPT_DIR%tests_tick.lpi"
SET TEST_EXECUTABLE="%SCRIPT_DIR%bin\tests_tick.exe"
SET LPR_FILE="%SCRIPT_DIR%tests_tick.lpr"

REM Modify .lpr file to ensure recompilation
REM echo. >> %LPR_FILE%

REM Build the project
echo Building fafafa.core.tick test project: %PROJECT%...
%LAZBUILD% %PROJECT%

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed with error code %ERRORLEVEL%.
    goto END
)

echo.
echo Build successful.
echo.

REM Run tests if the 'test' parameter is provided
if /i "%1"=="test" (
    echo Running fafafa.core.tick tests...
    echo.
    %TEST_EXECUTABLE%
) else (
    echo To run tests, call this script with the 'test' parameter.
    echo e.g., BuildOrTest.bat test
)

:END
