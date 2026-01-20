@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=run"

set "LAZBUILD=lazbuild"

echo === Building fafafa.core.sync.condvar Examples ===
echo.

rem List of all example subdirectories
set "EXAMPLES=barrier\example_multi_thread_coordination cond_vs_event\example_cond_vs_event mpmc_queue\example_mpmc_queue producer_consumer\example_producer_consumer robust_wait\example_robust_wait timeout\example_timeout wait_notify\example_wait_notify"

rem Build all examples
for %%e in (%EXAMPLES%) do (
  echo [BUILD] %LAZBUILD% --build-mode=Release %%e.lpi
  %LAZBUILD% --build-mode=Release "%%e.lpi"
  if errorlevel 1 exit /b 1
)

echo.
echo === All examples built successfully! ===
echo.

if /I "%ACTION%"=="run" (
  echo === Running Examples ===
  echo.

  for %%e in (%EXAMPLES%) do (
    for %%f in ("%%e") do set "example_name=%%~nxf"
    if exist "bin\!example_name!.exe" (
      echo [RUN] bin\!example_name!.exe
      "bin\!example_name!.exe"
      echo.
    ) else (
      echo [WARN] Executable not found: bin\!example_name!.exe
    )
  )
) else (
  echo [INFO] Build-only mode ^(%ACTION%^)
  echo You can run the examples manually:
  for %%e in (%EXAMPLES%) do (
    for %%f in ("%%e") do set "example_name=%%~nxf"
    echo   bin\!example_name!.exe
  )
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
