@echo off

set "SCRIPT_DIR=%~dp0"

set "PROJECT=example_node.lpr"

echo Building project with FPC: %PROJECT%...
fpc -Mobjfpc -Fi..\..\src -Fu..\..\src -o..\..\bin\example_node.exe "%PROJECT%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed with error code %ERRORLEVEL%.
    goto END
)

echo.
echo Build successful.
echo.

if /i "%1"=="run" (
    echo Running example...
    "..\..\bin\example_node.exe"
) else (
    echo To run the example, call this script with the 'run' parameter.
)

:END
