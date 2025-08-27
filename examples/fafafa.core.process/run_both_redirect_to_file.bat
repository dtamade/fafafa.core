@echo off
setlocal
cd /d "%~dp0"
set BIN=bin
if not exist "%BIN%" mkdir "%BIN%"
set FPC=fpc
"%FPC%" -MObjFPC -Scaghi -gl -Fu"..\..\src" -Fi"..\..\src" -dFAFAFA_PROCESS_GROUPS -FE"%BIN%" example_both_redirect_to_file.pas
set EC=%ERRORLEVEL%
if not %EC%==0 (
  echo Build failed
  exit /b %EC%
)
"%BIN%\example_both_redirect_to_file.exe"
exit /b 0

