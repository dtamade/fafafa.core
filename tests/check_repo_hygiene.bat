@echo off
setlocal EnableDelayedExpansion

if "%~1"=="" (
  set "REPO_ROOT=%~dp0.."
) else (
  set "REPO_ROOT=%~1"
)

if not exist "%REPO_ROOT%\src" (
  echo [CHECK] Missing src directory: %REPO_ROOT%\src
  exit /b 2
)

set "FOUND="
for /R "%REPO_ROOT%\src" %%F in (*.o *.ppu *.bak) do (
  if not defined FOUND (
    echo [CHECK] FAIL: source tree contains generated artifacts under src/
    set "FOUND=1"
  )
  echo %%~fF
)

if defined FOUND exit /b 1

echo [CHECK] OK (src tree hygiene: no .o/.ppu/.bak artifacts)
exit /b 0
