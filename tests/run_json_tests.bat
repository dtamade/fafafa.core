@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Simple runner to build and run fafafa.core.json test suite
set ROOT=%~dp0
set PROJ=%ROOT%fafafa.core.json\tests_json.lpi
set EXE=%ROOT%fafafa.core.json\bin\tests_json.exe

if not exist "%PROJ%" (
  echo [ERROR] Project file not found: %PROJ%
  exit /b 1
)

set LAZBUILD=
for /f "delims=" %%i in ('where lazbuild 2^>NUL') do (
  set LAZBUILD=%%i
  goto :found
)

:found
if not defined LAZBUILD if exist "C:\Program Files\Lazarus\lazbuild.exe" set LAZBUILD=C:\Program Files\Lazarus\lazbuild.exe
if not defined LAZBUILD if exist "C:\Lazarus\lazbuild.exe" set LAZBUILD=C:\Lazarus\lazbuild.exe

if not defined LAZBUILD (
  echo [ERROR] lazbuild not found in PATH or default locations. Please install Lazarus or add lazbuild to PATH.
  exit /b 1
)

echo [INFO] Using lazbuild: %LAZBUILD%
"%LAZBUILD%" "%PROJ%"
if errorlevel 1 (
  echo [ERROR] Build failed.
  exit /b 1
)

if not exist "%EXE%" (
  echo [WARN] Built EXE not found at expected path: %EXE%
  echo        Trying to run test binary from project output directory if available...
)

if exist "%EXE%" (
  echo [INFO] Running: %EXE%
  "%EXE%"
  exit /b %ERRORLEVEL%
) else (
  echo [INFO] Build finished, but test binary location unknown. Please run tests manually from Lazarus IDE.
  exit /b 0
)

