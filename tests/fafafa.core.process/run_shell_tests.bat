@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Run only fafafa.core.process tests (build + run)
REM Note: current test runner lacks selective filters; this script runs all tests for the module.

set "SCRIPT_DIR=%~dp0"
call "%SCRIPT_DIR%buildOrTest.bat" test
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo [run_shell_tests] Tests failed with code %RC%
  exit /b %RC%
) else (
  echo [run_shell_tests] Tests passed.
  exit /b 0
)

