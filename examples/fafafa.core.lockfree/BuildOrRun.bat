@echo off

set "SCRIPT_DIR=%~dp0"

set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"

set "PROJECT=%SCRIPT_DIR%example_lockfree.lpi"
set "BENCH_PROJECT=%SCRIPT_DIR%bench_map_str_key.lpi"
set "STRICT_EXAMPLE=%SCRIPT_DIR%example_oa_strict_factories.lpr"

set "EXAMPLE_EXECUTABLE=%SCRIPT_DIR%..\..\bin\example_lockfree.exe"
set "BENCH_EXECUTABLE=%SCRIPT_DIR%..\..\bin\bench_map_str_key.exe"
set "STRICT_EXE=%SCRIPT_DIR%..\..\bin\example_oa_strict_factories.exe"

echo Building example project: %PROJECT%...
call "%LAZBUILD%" "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build example failed with error code %ERRORLEVEL%.
    goto END
)

echo.
echo Building bench project: %BENCH_PROJECT%...
call "%LAZBUILD%" "%BENCH_PROJECT%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build bench failed with error code %ERRORLEVEL%.
    goto END
)

rem Build strict factories example (no .lpi)
echo.
echo Building strict factories example: %STRICT_EXAMPLE% ...
fpc -Fu"%SCRIPT_DIR%..\..\src" -FE"%SCRIPT_DIR%..\..\bin" "%STRICT_EXAMPLE%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build strict example failed with error code %ERRORLEVEL%.
    goto END
)
echo.
echo Build successful.
echo.

if /i "%1"=="run" (
    echo Running example...
    "%EXAMPLE_EXECUTABLE%"
    echo.
    echo Running bench...
    "%BENCH_EXECUTABLE%"
) else (
    echo To run example and bench, call this script with the 'run' parameter.
    echo.
    echo Running strict factories example...
    "%STRICT_EXE%"

)

:END
