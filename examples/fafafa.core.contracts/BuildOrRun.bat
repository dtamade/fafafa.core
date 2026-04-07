@echo off
setlocal
cd /d "%~dp0"

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=run"

set "PROJECT=example_contracts_basics.lpi"
set "EXE=bin\example_contracts_basics.exe"
set "EXE_ALT=bin\example_contracts_basics"
set "LAZBUILD=..\..\tools\lazbuild.bat"
set "LZ_Q="
if /i not "%FAFAFA_BUILD_QUIET%"=="0" set "LZ_Q=--quiet"

if exist "%LAZBUILD%" (
  echo [BUILD] Project: %PROJECT%
  call "%LAZBUILD%" %LZ_Q% --build-all "%PROJECT%"
) else (
  echo [BUILD] Project: %PROJECT%
  lazbuild %LZ_Q% --build-all "%PROJECT%"
)
if errorlevel 1 exit /b 1

if /i "%ACTION%"=="build" exit /b 0
if /i not "%ACTION%"=="run" (
  echo Usage: %~nx0 [build^|run]
  exit /b 2
)

if exist "%EXE%" (
  "%EXE%"
  exit /b %ERRORLEVEL%
)

if exist "%EXE_ALT%" (
  "%EXE_ALT%"
  exit /b %ERRORLEVEL%
)

echo [ERROR] Example executable not found: %EXE%
exit /b 1
