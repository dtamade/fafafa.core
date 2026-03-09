@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "RUNNER=%SCRIPT_DIR%BuildOrTest.sh"
if not exist "%RUNNER%" (
  echo [EXPERIMENTAL-TESTS] Missing runner: %RUNNER%
  exit /b 2
)
where bash >nul 2>nul
if errorlevel 1 (
  echo [EXPERIMENTAL-TESTS] SKIP (bash not found)
  exit /b 0
)
bash "%RUNNER%" %*
exit /b %ERRORLEVEL%
