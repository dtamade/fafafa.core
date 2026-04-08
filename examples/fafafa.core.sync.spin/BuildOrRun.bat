@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=run"
set "LAZBUILD_BIN=%LAZBUILD%"
if "%LAZBUILD_BIN%"=="" set "LAZBUILD_BIN=lazbuild"
set "EXAMPLES=example_basic_usage example_use_cases"

where "%LAZBUILD_BIN%" >nul 2>nul
if errorlevel 1 (
  echo [ERROR] lazbuild not found in PATH
  exit /b 1
)

if exist "bin" rmdir /s /q "bin"
if exist "lib" rmdir /s /q "lib"
mkdir "bin"
mkdir "lib"

echo === Building fafafa.core.sync.spin Examples ===
echo.

for %%e in (%EXAMPLES%) do (
  echo [BUILD] %LAZBUILD_BIN% %%e.lpi
  call "%LAZBUILD_BIN%" "%%e.lpi"
  if errorlevel 1 exit /b 1
)

echo.
echo === Build completed successfully! ===
echo.

if /I "%ACTION%"=="build" (
  echo Build-only mode. Skipping execution.
  if "%FAFAFA_INTERACTIVE%"=="1" pause
  exit /b 0
)

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

echo === All examples completed! ===

if "%FAFAFA_INTERACTIVE%"=="1" pause
exit /b 0
