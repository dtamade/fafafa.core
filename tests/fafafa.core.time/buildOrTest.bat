@echo off

REM Set paths relative to the script's location
SET SCRIPT_DIR=%~dp0
SET LAZBUILD="D:\devtools\lazarus\trunk\lazarus\lazbuild.exe"
SET PROJECT="%SCRIPT_DIR%fafafa.core.time.test.lpi"
SET TEST_EXECUTABLE="%SCRIPT_DIR%bin\fafafa.core.time.test.exe"
SET LPR_FILE="%SCRIPT_DIR%fafafa.core.time.test.lpr"

REM Build the project
echo Building fafafa.core.time test project: %PROJECT%...
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
    echo Running fafafa.core.time tests...
    echo.
    %TEST_EXECUTABLE%
) else (
    echo To run tests, call this script with the 'test' parameter.
    echo e.g., BuildOrTest.bat test
)

:END

