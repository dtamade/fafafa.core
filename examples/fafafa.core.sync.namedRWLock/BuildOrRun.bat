@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=run"

if "%LAZBUILD%"=="" set "LAZBUILD=lazbuild"

where "%LAZBUILD%" >nul 2>&1
if errorlevel 1 (
  echo [ERROR] lazbuild not found in PATH >&2
  exit /b 1
)

REM Deterministic outputs
if exist bin rmdir /s /q bin
if exist lib rmdir /s /q lib
mkdir bin
mkdir lib

set "EXAMPLES=example_basic_usage"

echo === Building fafafa.core.sync.namedRWLock Examples ===
echo.

for %%e in (%EXAMPLES%) do (
  echo [BUILD] %LAZBUILD% --build-mode=Default %%e.lpi
  "%LAZBUILD%" --build-mode=Default "%%e.lpi"
  if errorlevel 1 exit /b 1
)

echo.
echo === Build completed successfully! ===
echo.

if /i "%ACTION%"=="build" (
  echo Build-only mode. Skipping execution.
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
  ) else (
    echo [ERROR] Executable not found: bin\%%e.exe >&2
    exit /b 1
  )
)

echo === All examples completed! ===
