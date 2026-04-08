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

echo === Building fafafa.core.sync Examples ===
echo.

rem List of all examples
set "EXAMPLES=example_sync example_autolock example_condvar example_condvar_broadcast example_rwlock example_sem example_smoketest"

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
    if exist "bin\%%e.exe" (
      echo [RUN] bin\%%e.exe
      "bin\%%e.exe"
      echo.
    ) else echo [WARN] Executable not found: bin\%%e.exe
  )
)

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0

