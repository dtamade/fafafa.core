@echo off

set "SCRIPT_DIR=%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"

set "PROJECT=example_node.lpi"

set "EXAMPLE_EXECUTABLE=bin\example_node.exe"

echo Building project: %PROJECT%...
call "%LAZBUILD%" "%PROJECT%"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed with error code %ERRORLEVEL%.
    goto END
)

echo.
echo Build successful.

REM Copy executable with .exe extension for Windows compatibility
copy "bin\example_node" "bin\example_node.exe" >nul 2>&1

echo.

if /i "%1"=="run" (
    echo Running example...
    "bin\example_node.exe"
) else (
    echo To run the example, call this script with the 'run' parameter.
)

:END
