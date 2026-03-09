@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "VERIFY_SH=%SCRIPT_DIR%verify_windows_b07_evidence.sh"
if not exist "%VERIFY_SH%" (
  echo [EVIDENCE] Missing verifier: %VERIFY_SH%
  exit /b 2
)
where bash >nul 2>nul
if errorlevel 1 (
  echo [EVIDENCE] Missing bash ^(require Git Bash / WSL^)
  exit /b 2
)
bash "%VERIFY_SH%" %*
exit /b %ERRORLEVEL%
