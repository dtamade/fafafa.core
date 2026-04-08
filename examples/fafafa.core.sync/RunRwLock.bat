@echo off
setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"
if "%LAZBUILD%"=="" set "LAZBUILD=lazbuild"

set "LPI=%SCRIPT_DIR%example_rwlock.lpi"
set "OUT_DIR=%SCRIPT_DIR%build\x86_64-win64"

where "%LAZBUILD%" >nul 2>&1
if errorlevel 1 (
  echo lazbuild not found: %LAZBUILD%
  exit /b 1
)

echo [BUILD] %LAZBUILD% %LPI% (project default mode)
"%LAZBUILD%" "%LPI%"
if %ERRORLEVEL% NEQ 0 (
  echo Build failed with error %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

rem Common Lazarus output path (adjust if your config differs)
set "EXE=%OUT_DIR%\example_rwlock.exe"
if not exist "%EXE%" (
  rem Try bin fallback
  set "EXE=%SCRIPT_DIR%..\..\..\bin\example_rwlock.exe"
)

if exist "%EXE%" (
  echo Running: "%EXE%"
  "%EXE%" %*
) else (
  echo Executable not found. Tried:
  echo   %OUT_DIR%\example_rwlock.exe
  echo   %SCRIPT_DIR%..\..\..\bin\example_rwlock.exe
  exit /b 1
)
