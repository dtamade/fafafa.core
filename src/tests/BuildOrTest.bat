@echo off
setlocal ENABLEDELAYEDEXPANSION

set LPI=toml_tests.lpi
set BIN=bin\toml_tests.exe

pushd %~dp0

REM Build
lazbuild %LPI% --build-mode=Debug
if errorlevel 1 (
  echo Build failed
  popd
  exit /b 1
)

REM Run
if exist %BIN% (
  %BIN% --all --format=plain
  set RC=!ERRORLEVEL!
  echo ExitCode: !RC!
  popd
  exit /b !RC!
) else (
  echo Binary not found: %BIN%
  popd
  exit /b 2
)

