@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Fast smoke: build tests and run a small set of high-signal suites
set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%tests_socket.lpi"
set "TEST_EXE=%SCRIPT_DIR%bin\tests_socket.exe"

REM Build via lazbuild
call "%LAZBUILD%" "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
  echo Build failed with code %ERRORLEVEL%.
  goto FAIL
)

REM Suites to run (space-separated). Allow override by env SMOKE_SUITES
if not defined SMOKE_SUITES set SMOKE_SUITES=TTestCase_Socket TTestCase_SocketListener

set "ARGS="
for %%S in (%SMOKE_SUITES%) do (
  set ARGS=!ARGS! --suite=%%S
)

set "SMOKE_LOG=%SCRIPT_DIR%bin\tests_socket_smoke.log"
"%TEST_EXE%" %ARGS% --progress --format=plain > "%SMOKE_LOG%" 2>&1
set "RC=%ERRORLEVEL%"
for /f "usebackq delims=" %%S in (`findstr /R /C:"OK:" /C:"Failures" /C:"Errors" "%SMOKE_LOG%"`) do set "SUMMARY=%%S"
if defined SUMMARY (echo [SMOKE] Summary: !SUMMARY!) else (echo [SMOKE] Summary: see log "%SMOKE_LOG%")
if not "%RC%"=="0" (
  echo [SMOKE] Failed with code %RC%. Last 50 lines:
  powershell -NoProfile -Command "Get-Content -Tail 50 -Path '%SMOKE_LOG%'"
)
endlocal & exit /b %RC%

:FAIL
endlocal & exit /b 1

