@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

call build_pipeline_best_practices.bat
if errorlevel 1 (
  echo [ERROR] Build failed, aborting run.
  exit /b 1
)

set EXE=bin\example_pipeline_best_practices.exe
if not exist "%EXE%" (
  echo [ERROR] Executable not found: %EXE%
  exit /b 1
)

"%EXE%"
set EC=%ERRORLEVEL%
echo [INFO] ExitCode=%EC%
exit /b %EC%

