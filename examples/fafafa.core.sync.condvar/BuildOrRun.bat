@echo off
setlocal enabledelayedexpansion
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

if exist "bin" rmdir /s /q "bin"
if exist "lib" rmdir /s /q "lib"
mkdir "bin"
mkdir "lib"

echo === Building fafafa.core.sync.condvar Examples ===
echo.

rem List of all example subdirectories
set "EXAMPLES=barrier\example_multi_thread_coordination cond_vs_event\example_cond_vs_event mpmc_queue\example_mpmc_queue producer_consumer\example_producer_consumer robust_wait\example_robust_wait timeout\example_timeout wait_notify\example_wait_notify"

rem Build all examples
for %%e in (%EXAMPLES%) do (
  echo [BUILD] %LAZBUILD% %%e.lpi ^(project default mode^)
  call "%LAZBUILD%" "%%e.lpi"
  if errorlevel 1 exit /b 1
)

echo.
echo === All examples built successfully! ===
echo.

if /I "%ACTION%"=="build" (
  echo [INFO] Build-only mode.
  if "%FAFAFA_INTERACTIVE%"=="1" pause
  exit /b 0
) else (
  echo === Running Examples ===
  echo.

  for %%e in (%EXAMPLES%) do (
    for %%f in ("%%e") do set "example_name=%%~nxf"
    if exist "bin\!example_name!.exe" (
      echo [RUN] bin\!example_name!.exe
      "bin\!example_name!.exe"
      echo.
    ) else echo [WARN] Executable not found: bin\!example_name!.exe
  )
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
