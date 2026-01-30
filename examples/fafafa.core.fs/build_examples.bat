@echo off
cd /d "%~dp0"
echo === fafafa.core.fs Examples Build ===
echo Working directory: %CD%
echo.

REM Set paths
set PROJECT_ROOT=%~dp0..\..
set SRC_PATH=%PROJECT_ROOT%\src
set BIN_PATH=bin
set LIB_PATH=%~dp0lib

REM Build flags for different optimization levels
set REGULAR_FLAGS=-Mobjfpc -Fu"%SRC_PATH%" -FE"bin" -FU"%LIB_PATH%" -gl -O2
set PERFORMANCE_FLAGS=-Mobjfpc -Fu"%SRC_PATH%" -FE"bin" -FU"%LIB_PATH%" -gl -O3 -CX -XX

REM Ensure directories exist
if not exist "%BIN_PATH%" mkdir "%BIN_PATH%"
if not exist "%LIB_PATH%" mkdir "%LIB_PATH%"

echo Project Root: %PROJECT_ROOT%
echo Source: %SRC_PATH%
echo Executables: %BIN_PATH%
echo Intermediate: %LIB_PATH%
echo.

echo Building fafafa.core.fs example...
echo.

echo [1/1] Building example_fs.exe (O2 optimization)...
lazbuild --build-mode=Release example_fs.lpi
if %ERRORLEVEL% EQU 0 (
    echo SUCCESS: example_fs.exe built with lazbuild
) else (
    echo WARNING: lazbuild failed, trying fpc...
    fpc %REGULAR_FLAGS% -o"%BIN_PATH%\example_fs.exe" "example_fs.lpr"
    if %ERRORLEVEL% EQU 0 (
        echo SUCCESS: example_fs.exe built with fpc
    ) else (
        echo FAILED: example_fs.lpr
        set BUILD_FAILED=1
    )
)

echo.
echo === Build Complete ===
echo.

if exist "%BIN_PATH%\example_fs.exe" (
    echo Generated file: example_fs.exe
    echo.
    echo Usage:
    echo   cd %BIN_PATH%
    echo   example_fs.exe
    echo.
    echo Or run from project root:
    echo   bin\example_fs.exe
) else (
    echo ERROR: No executable generated
    set BUILD_FAILED=1
)

if defined BUILD_FAILED (
    echo.
    echo Build failed. Check the output above.
    exit /b 1
) else (
    echo.
    echo Build completed successfully!
    exit /b 0
)
