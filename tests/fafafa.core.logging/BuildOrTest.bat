@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%tests_logging.lpi"
set "BIN=%SCRIPT_DIR%bin"
set "LIB=%SCRIPT_DIR%lib"
set "TEST_EXE=%BIN%\tests_logging.exe"

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"

REM Guard against stale binary
if exist "%TEST_EXE%" del /f /q "%TEST_EXE%"

set "LZ_Q="
if not "%FAFAFA_BUILD_QUIET%"=="0" set "LZ_Q=--quiet"
if not exist "%SCRIPT_DIR%logs" mkdir "%SCRIPT_DIR%logs" >nul 2>nul
set "BUILD_LOG=%SCRIPT_DIR%logs\build.txt"
if exist "%BUILD_LOG%" del /q "%BUILD_LOG%" >nul 2>nul

echo [BUILD] Project: %PROJECT%
call "%LAZBUILD%" %LZ_Q% "%PROJECT%" >"%BUILD_LOG%" 2>&1
set "BUILD_ERR=%ERRORLEVEL%"
if !BUILD_ERR! NEQ 0 (
  echo [BUILD] FAILED code=!BUILD_ERR!
  goto END
) else (
  echo [BUILD] OK
)

echo.
if /i "%1"=="test" (
  set "TEST_LOG=%SCRIPT_DIR%logs\test.txt"
  if exist "%TEST_LOG%" del /q "%TEST_LOG%" >nul 2>nul
  echo [TEST] Running...
  "%TEST_EXE%" --all --format=plain >"%TEST_LOG%" 2>&1
  set "TE=!ERRORLEVEL!"
  if !TE! EQU 0 (
    echo [TEST] OK
  ) else (
    echo [TEST] FAILED code=!TE! & echo See "%TEST_LOG%" for details.
  )
) else (
  echo To run tests, call this script with the 'test' parameter.
)

:END
endlocal

