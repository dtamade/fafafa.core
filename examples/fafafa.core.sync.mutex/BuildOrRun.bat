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

set "EXAMPLES=example_advanced_patterns example_basic_usage"

echo === Building fafafa.core.sync.mutex Examples ===
echo.

for %%e in (%EXAMPLES%) do (
  echo [BUILD] %LAZBUILD% %%e.lpi ^(project default mode^)
  call "%LAZBUILD%" "%%e.lpi"
  if errorlevel 1 exit /b 1
)

echo.
echo === Build completed successfully! ===
echo.

if /I "%ACTION%"=="build" (
  echo [INFO] Build-only mode.
  if "%FAFAFA_INTERACTIVE%"=="1" pause
  exit /b 0
)

echo === Running Examples ===
echo.

for %%e in (%EXAMPLES%) do (
  if exist "bin\%%e.exe" (
    echo [RUN] bin\%%e.exe
    "bin\%%e.exe"
    if errorlevel 1 exit /b 1
    echo.
  ) else echo [WARN] Executable not found: bin\%%e.exe
)

echo === All examples completed! ===

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
