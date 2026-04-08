@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=run"

if /I not "%ACTION%"=="build" if /I not "%ACTION%"=="run" (
  echo [ERROR] Unsupported action: %ACTION%
  echo Usage: %~nx0 [build^|run]
  exit /b 2
)

if "%LAZBUILD%"=="" set "LAZBUILD=lazbuild"

where "%LAZBUILD%" >nul 2>nul
if errorlevel 1 (
  echo [ERROR] lazbuild not found in PATH
  exit /b 1
)

echo [BUILD] %LAZBUILD% example_wait_notify.lpi ^(project default mode^)
call "%LAZBUILD%" "example_wait_notify.lpi"
if errorlevel 1 exit /b 1

if /I "%ACTION%"=="build" (
  echo [INFO] Build-only mode.
  if "%FAFAFA_INTERACTIVE%"=="1" pause
  exit /b 0
)

if exist "..\bin\example_wait_notify.exe" (
  echo [RUN] ..\bin\example_wait_notify.exe
  "..\bin\example_wait_notify.exe"
) else if exist "..\bin\example_wait_notify" (
  echo [RUN] ..\bin\example_wait_notify
  "..\bin\example_wait_notify"
) else (
  echo [ERROR] Executable not found: ..\bin\example_wait_notify[.exe]
  exit /b 100
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
