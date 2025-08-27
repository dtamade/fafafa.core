@echo off

REM ===================================================================
REM fafafa.core.process Example Project Build Script (Windows)
REM ===================================================================

echo.
echo ===================================================================
echo fafafa.core.process Example Project Build Script
echo ===================================================================

REM Set script directory and project paths
SET SCRIPT_DIR=%~dp0
SET PROJECT_FILE=%SCRIPT_DIR%example_process.lpi
SET OUTPUT_DIR=%SCRIPT_DIR%bin

REM Detect build mode
SET BUILD_MODE=Debug
if /i "%1"=="release" SET BUILD_MODE=Release

echo Build Mode: %BUILD_MODE%
echo Project File: %PROJECT_FILE%
echo.

REM Set Lazarus build tool path
SET LAZBUILD=D:\devtools\lazarus\trunk\lazarus\lazbuild.exe
if not exist "%LAZBUILD%" (
    SET LAZBUILD=C:\lazarus\lazbuild.exe
)
if not exist "%LAZBUILD%" (
    SET LAZBUILD=C:\Program Files\Lazarus\lazbuild.exe
)
if not exist "%LAZBUILD%" (
    echo [ERROR] Cannot find lazbuild.exe
    echo Please ensure Lazarus is properly installed.
    goto ERROR_END
)

echo [OK] Found Lazarus build tool

REM Create output directory
if not exist "%OUTPUT_DIR%" (
    echo [OK] Creating output directory
    mkdir "%OUTPUT_DIR%"
)

echo.
echo ===================================================================
echo Starting build...
echo ===================================================================

REM Execute build
echo Executing: lazbuild --build-mode=%BUILD_MODE% example_process.lpi
"%LAZBUILD%" --build-mode=%BUILD_MODE% "%PROJECT_FILE%"

REM Check build result
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Build failed! Error code: %ERRORLEVEL%
    goto ERROR_END
)

echo.
echo ===================================================================
echo Build successful!
echo ===================================================================

REM Check output file
SET EXECUTABLE_PATH=%OUTPUT_DIR%\example_process.exe

if exist "%EXECUTABLE_PATH%" (
    echo [OK] Executable file generated successfully
    echo.
    echo Run example:
    echo   run.bat
    echo.
    echo Or directly:
    echo   cd ..\..\bin
    echo   example_process.exe
) else (

REM === Build optional examples ===
echo.
echo [INFO] Building optional examples (AutoDrain)...
call "%SCRIPT_DIR%build_autodrain.bat"
if %ERRORLEVEL% NEQ 0 (
  echo [WARN] build_autodrain.bat failed (optional), continuing.
)

    echo [WARNING] Cannot find generated executable file

REM === Build optional example: Combined vs CaptureAll ===
echo.
echo [INFO] Building optional example (Combined vs CaptureAll)...
call "%SCRIPT_DIR%build_combined_vs_capture_all.bat"
if %ERRORLEVEL% NEQ 0 (
  echo [WARN] build_combined_vs_capture_all.bat failed (optional), continuing.
)


REM === Build optional example: Silent vs Interactive ===
echo.
echo [INFO] Building optional example (Silent vs Interactive)...
call "%SCRIPT_DIR%build_silent_interactive.bat"
if %ERRORLEVEL% NEQ 0 (
  echo [WARN] build_silent_interactive.bat failed (optional), continuing.
)

)

echo.
echo ===================================================================
echo Build completed
echo ===================================================================
goto END

:ERROR_END
echo.
echo ===================================================================
echo Build failed
echo ===================================================================
exit /b 1

:END
pause
