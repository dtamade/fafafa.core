@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
rem Normalize to script dir for relative paths
pushd "%SCRIPT_DIR%"

set "LAZBUILD=..\..\tools\lazbuild.bat"
if not exist "%LAZBUILD%" (
  echo [WARN] tools\lazbuild.bat not found, falling back to lazbuild in PATH
  set "LAZBUILD=lazbuild"
)
set "PROJECT=tests_toml.lpi"
set "TEST_EXECUTABLE=.\bin\tests_toml.exe"
set "TEST_EXECUTABLE_ALT=.\bin\tests_toml_debug.exe"

rem Clean old executables to avoid running stale binaries on failed builds
if exist "%TEST_EXECUTABLE%" del /f /q "%TEST_EXECUTABLE%" >nul 2>nul
if exist "%TEST_EXECUTABLE_ALT%" del /f /q "%TEST_EXECUTABLE_ALT%" >nul 2>nul


set "LZ_Q="
if not "%FAFAFA_BUILD_QUIET%"=="0" set "LZ_Q=--quiet"
if not exist logs mkdir logs >nul 2>nul
set "BUILD_LOG=logs\build.txt"
if exist "%BUILD_LOG%" del /q "%BUILD_LOG%" >nul 2>nul

echo [BUILD] Project: %PROJECT%...
call "%LAZBUILD%" %LZ_Q% "%PROJECT%" >"%BUILD_LOG%" 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo [BUILD] FAILED code=%ERRORLEVEL%
rem Guard: ensure a fresh test executable exists before running
if not exist "%TEST_EXECUTABLE%" if not exist "%TEST_EXECUTABLE_ALT%" (
  echo.
  echo Build did not produce test executable in .\bin\
  echo Aborting to avoid running stale binaries.
  goto END
)

  goto END
)

echo.
echo Build successful.
echo.

if /i "%1"=="test" (
  set "TEST_LOG=logs\test.txt"
  if exist "%TEST_LOG%" del /q "%TEST_LOG%" >nul 2>nul
  echo [TEST] Running...
  if exist "%TEST_EXECUTABLE%" (
    "%TEST_EXECUTABLE%" --all --format=plain >"%TEST_LOG%" 2>&1
  ) else if exist ".\bin\tests_toml_debug.exe" (
    .\bin\tests_toml_debug.exe --all --format=plain >"%TEST_LOG%" 2>&1
  ) else (
    echo [ERROR] Test executable not found in .\bin\
    goto END
  )
  set "TE=%ERRORLEVEL%"
  if %TE% EQU 0 (
    echo [TEST] OK
  ) else (
    echo [TEST] FAILED code=%TE% & echo See "%TEST_LOG%" for details.
  )
) else (
  echo To run tests, call this script with the 'test' parameter.
)

:END
endlocal

