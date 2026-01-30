@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Pre-push helper: build Release and run all crypto tests
REM Optional: pass "debug" as first arg to additionally build Debug mode

set ROOT=%~dp0..
set LPI=%ROOT%\tests_crypto.lpi
set EXE=%ROOT%\bin\tests_crypto.exe

REM Build Release
"D:\devtools\lazarus\trunk\lazarus\lazbuild.exe" --build-mode=Release "%LPI%" || goto :fail

REM Run tests (Release)
"%EXE%" --all --format=plain || goto :fail

echo [prepush] Release build+tests OK

if /i "%1"=="debug" (
  echo [prepush] Building Debug as well...
  "D:\devtools\lazarus\trunk\lazarus\lazbuild.exe" --build-mode=Release -dDEBUG "%LPI%" || goto :fail
  "%EXE%" --all --format=plain || goto :fail
)

echo [prepush] All good
exit /b 0

:fail
echo [prepush] FAILED with error %ERRORLEVEL%
exit /b 1

