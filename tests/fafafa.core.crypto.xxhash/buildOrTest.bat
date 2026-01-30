@echo off
setlocal ENABLEDELAYEDEXPANSION

set SCRIPT_DIR=%~dp0
set LPI=%SCRIPT_DIR%fafafa.core.crypto.xxhash.test.lpi
set BIN=%SCRIPT_DIR%bin\tests_xxhash.exe
set LIB=%SCRIPT_DIR%lib

if not exist "%LIB%" mkdir "%LIB%"
if not exist "%SCRIPT_DIR%bin" mkdir "%SCRIPT_DIR%bin"

lazbuild "%LPI%" --build-mode=Debug
if errorlevel 1 (
  echo Build failed
  exit /b 1
)

if /I "%1"=="test" (
  "%BIN%" --format=plain --all
  exit /b !ERRORLEVEL!
)

echo Built. To run tests: buildOrTest.bat test
exit /b 0

