@echo off
setlocal EnableExtensions DisableDelayedExpansion

echo ========================================
echo fafafa.core.benchmark Test Build Script
echo ========================================
echo.

set PROJECT_ROOT=%~dp0..\..
set TEST_DIR=%~dp0
set BIN_DIR=%TEST_DIR%bin
set PROJECT_FILE=%TEST_DIR%tests_benchmark.lpi
set EXECUTABLE=%BIN_DIR%\tests_benchmark.exe

if "%1"=="quick" goto quick_only
if "%1"=="test" goto run_test
if "%1"=="build" goto build_only
if "%1"=="clean" goto clean_only

echo Building test project...
call :build_project
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo.
echo Running tests...
call :run_test
exit /b %errorlevel%

:build_only
echo Building test project only...
call :build_project
exit /b %errorlevel%
:quick_only
REM Run minimal reporters quick tests via FPC (no lazbuild)
call "%TEST_DIR%quick-runner.bat"
exit /b %ERRORLEVEL%


:run_test
if not exist "%EXECUTABLE%" (
    echo Executable not found, please build first
    echo    File path: %EXECUTABLE%
    exit /b 1
)

echo Running tests: %EXECUTABLE%
cd /d "%PROJECT_ROOT%"

REM Optionally keep reporter files for validation
if "%VALIDATE_EXPORTS%"=="1" (
  set FAFAFA_KEEP_REPORT_FILES=1
)

"%EXECUTABLE%" --all --format=plain --progress --no-pause
set TEST_RC=%ERRORLEVEL%

if NOT "%TEST_RC%"=="0" (
    echo.
    echo Tests failed!
    exit /b %TEST_RC%
)

REM Optional export validation
if "%VALIDATE_EXPORTS%"=="1" (
  powershell -ExecutionPolicy Bypass -File "%TEST_DIR%validate-exports.ps1"
  set VALIDATE_RC=%ERRORLEVEL%
  if NOT %VALIDATE_RC%==0 (
    echo.
    echo Export validation failed!
    exit /b %VALIDATE_RC%
  ) else (
    echo.
    echo Export validation passed.
  )
)

echo.
echo All tests passed!
exit /b 0

:clean_only
echo Cleaning build files...
if exist "%TEST_DIR%lib" (
    rmdir /s /q "%TEST_DIR%lib"
    echo    Deleted: %TEST_DIR%lib
)
if exist "%EXECUTABLE%" (
    del "%EXECUTABLE%"
    echo    Deleted: %EXECUTABLE%
)
if exist "%TEST_DIR%bin\reporters_quick.exe" del "%TEST_DIR%bin\reporters_quick.exe"
echo Clean completed
exit /b 0

:build_project
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

set "LAZBUILD=%PROJECT_ROOT%\tools\lazbuild.bat"
if not exist "%LAZBUILD%" (
  echo ERROR: tools\lazbuild.bat not found. Please configure lazbuild.
  exit /b 1
)

echo    Project file: %PROJECT_FILE%
echo    Output directory: %BIN_DIR%

REM Ensure stale executable does not mask build failure
if exist "%EXECUTABLE%" del /q "%EXECUTABLE%"

echo Building with unified lazbuild: %LAZBUILD%
call "%LAZBUILD%" --build-mode=Debug "%PROJECT_FILE%"
set BUILD_RC=%ERRORLEVEL%
if NOT "%BUILD_RC%"=="0" (
    echo Build failed with errorlevel %BUILD_RC%!
    exit /b %BUILD_RC%
)

if exist "%EXECUTABLE%" (
    echo Build successful
    echo    Executable: %EXECUTABLE%
    exit /b 0
) else (
    echo ERROR: Build reported success but executable not found
    exit /b 1
)

:show_help
echo.
echo Usage: %~nx0 [command]
echo.
echo Commands:
echo   quick    Build and run minimal reporters quick tests
echo   build    Build project only
echo   test     Run tests only (requires build first)
echo   clean    Clean build files
echo   (no args) Build and run tests
echo.
echo Examples:
echo   %~nx0           # Build and run tests
echo   %~nx0 quick     # Run minimal quick reporters tests
echo   %~nx0 build     # Build only
echo   %~nx0 test      # Run tests only
echo   %~nx0 clean     # Clean files
echo.
exit /b 0
