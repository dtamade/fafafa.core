@echo off
setlocal ENABLEDELAYEDEXPANSION

REM === Paths ===
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\..\"
set "LAZBUILD=%ROOT_DIR%tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%tests_core_no_fpcunit.lpi"
set "BIN_DIR=%SCRIPT_DIR%bin"
set "LIB_DIR=%SCRIPT_DIR%lib"
set "TEST_EXE=%BIN_DIR%\tests.exe"

set "RC=0"

if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
mkdir "%BIN_DIR%" 1>nul 2>nul
mkdir "%LIB_DIR%" 1>nul 2>nul

echo [1/4] Building project: %PROJECT% ...
call "%LAZBUILD%" "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
  echo [ERROR] Build failed with code %ERRORLEVEL%.
  exit /b %ERRORLEVEL%
)

echo [2/4] Build successful.

if /i "%1"=="test" (
  set "SMOKE_LOG=%BIN_DIR%\smoke-run.txt"
  set "FULL_LOG=%BIN_DIR%\last-run.txt"
  set "JUNIT_XML=%BIN_DIR%\report.xml"

  echo [3/4] Running smoke tests...
  powershell -NoProfile -Command "& { & '%TEST_EXE%' --filter=core.smoke; $code=$LastExitCode; exit $code }" | powershell -NoProfile -Command "$input | Out-File -FilePath '%SMOKE_LOG%' -Encoding utf8"
  set "RC=%ERRORLEVEL%"
  type "%SMOKE_LOG%"
  if not "%RC%"=="0" (
    echo [ERROR] Smoke tests failed. Skip full run.
    exit /b %RC%
  )

  echo.
  echo [4/4] Running full tests (console + JUnit)...
  powershell -NoProfile -Command "& { & '%TEST_EXE%' --filter=core; $code=$LastExitCode; exit $code }" | powershell -NoProfile -Command "$input | Out-File -FilePath '%FULL_LOG%' -Encoding utf8"
  set "RC=%ERRORLEVEL%"
  powershell -NoProfile -Command "& { & '%TEST_EXE%' --junit='%JUNIT_XML%'; $code=$LastExitCode; exit $code }" >nul 2>&1
  type "%FULL_LOG%"
  if exist "%JUNIT_XML%" echo JUnit: %JUNIT_XML%
  exit /b %RC%
) else (
  echo Tip: to run tests, call with 'test' argument.
)

exit /b 0

