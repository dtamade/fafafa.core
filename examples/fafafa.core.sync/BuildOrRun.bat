@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=run"

set "LAZBUILD=lazbuild"

echo === Building fafafa.core.sync Examples ===
echo.

rem List of all examples
set "EXAMPLES=example_sync example_autolock example_condvar example_condvar_broadcast example_rwlock example_sem example_smoketest"

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
    if exist "bin\%%e.exe" (
      echo [RUN] bin\%%e.exe
      "bin\%%e.exe"
      echo.
    ) else (
      echo [WARN] Executable not found: bin\%%e.exe
    )
  )
) else (
  echo [INFO] Build-only mode ^(%ACTION%^)
  echo You can run the examples manually:
  for %%e in (%EXAMPLES%) do (
    echo   bin\%%e.exe
  )
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0

