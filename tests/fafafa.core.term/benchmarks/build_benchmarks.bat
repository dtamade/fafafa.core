@echo off

set "SCRIPT_DIR=%~dp0"
set "BIN_DIR=..\..\..\bin"
set "SRC_DIR=..\..\..\src"


if not exist %BIN_DIR% mkdir %BIN_DIR%

rem Ensure working directory is the script directory
pushd "%SCRIPT_DIR%"

echo Building fafafa.core.term benchmarks...
echo =====================================

echo.
rem Skipped: benchmark_term.lpr (not present)
rem fpc -Fu%SRC_DIR% -FE%BIN_DIR% -FU..\..\..\lib benchmark_term.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for benchmark_term.lpr
    goto END
)

echo.
echo.
echo Building benchmark_paste_backends.lpr...
fpc -Fu%SRC_DIR% -FE%BIN_DIR% -FU..\..\..\lib benchmark_paste_backends.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for performance_analyzer.lpr
    goto END
)

echo.
echo All benchmarks built successfully!
echo.
echo Available executables in %BIN_DIR%:
echo   - benchmark_paste_backends.exe  (Paste backends micro benchmarks)
echo.
echo Usage:
echo   %BIN_DIR%\benchmark_paste_backends.exe [N]
echo.

:END
popd
