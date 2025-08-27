@echo off

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=..\..\tools\lazbuild.bat"
set "PROJECT=example_term_ui.lpi"
set "EXECUTABLE=.\bin\example.exe"

echo Building project: %PROJECT%...
call "%LAZBUILD%" "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed with error code %ERRORLEVEL%.
    goto END
)

echo.
echo Build successful.

echo Running example...
"%EXECUTABLE%"

:END

