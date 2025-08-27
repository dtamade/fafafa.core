@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Build & run the temporary validation for vec growth strategy (Windows)

pushd "%~dp0"
set "LPR=validate_vec_growth_strategy.lpr"
set "BIN_DIR=bin"
set "LIB_DIR=lib"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

REM Prefer lazbuild if .lpi exists; else compile .lpr directly
if exist "%LPR%" (
  lazbuild "%LPR%" --build-mode=Debug
  if errorlevel 1 goto :err
) else (
  echo ERROR: LPR not found: %LPR%
  goto :err
)

REM find exe in bin or lib
set "EXE="
for /r "%BIN_DIR%" %%F in (*.exe) do set "EXE=%%F"
if not defined EXE for /r "%LIB_DIR%" %%F in (*.exe) do set "EXE=%%F"
if not defined EXE (
  echo ERROR: executable not found under bin/ or lib/
  goto :err
)

"%EXE%" --all --format=plain
set RC=!ERRORLEVEL!
echo ExitCode: !RC!
popd
exit /b !RC!

:err
echo BuildOrRun failed
popd
exit /b 1

