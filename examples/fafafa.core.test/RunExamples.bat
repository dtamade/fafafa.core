@echo off
setlocal ENABLEDELAYEDEXPANSION
cd /d "%~dp0"
set "BIN=%CD%\bin"
set "EXE1=%BIN%\example_core_test_minimal.exe"
if exist "%EXE1%" (
  echo.
  echo ==== Running example_core_test_minimal ====
  "%EXE1%" --filter=example --junit="%BIN%\example_core_test_minimal.junit.xml" --json="%BIN%\example_core_test_minimal.json"
  echo Exit code: %ERRORLEVEL%
) else (
  echo Skipped: example_core_test_minimal.exe (not built)
)

set "EXE2=%BIN%\example_snapshots.exe"
if exist "%EXE2%" (
  echo.
  echo ==== Running example_snapshots ====
  "%EXE2%"
  echo Exit code: %ERRORLEVEL%
) else (
  echo Skipped: example_snapshots.exe (not built)
)

exit /b 0

