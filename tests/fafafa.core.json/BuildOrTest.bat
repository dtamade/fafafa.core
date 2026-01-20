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
set "PROJECT=tests_json.lpi"
set "TEST_EXECUTABLE=.\bin\tests_json.exe"

rem Clean previous build artifacts for a deterministic fresh build
if exist .\bin (
  echo Cleaning .\bin ...
  rmdir /s /q .\bin
)
if exist .\lib (
  echo Cleaning .\lib ...
  rmdir /s /q .\lib
)

set "LZ_Q="
if not "%FAFAFA_BUILD_QUIET%"=="0" set "LZ_Q=--quiet"
set "BUILD_LOG=logs\build.txt"
if not exist logs mkdir logs >nul 2>nul
if exist "%BUILD_LOG%" del /q "%BUILD_LOG%" >nul 2>nul

echo [BUILD] Project: %PROJECT%
call "%LAZBUILD%" %LZ_Q% "%PROJECT%" -B >"%BUILD_LOG%" 2>&1
set "BUILD_ERR=%ERRORLEVEL%"
if not exist "%TEST_EXECUTABLE%" (
  echo [ERROR] Test executable not found: %TEST_EXECUTABLE%
  if %BUILD_ERR% EQU 0 set "BUILD_ERR=1"
)

if %BUILD_ERR% EQU 0 (
  echo [BUILD] OK
) else (
  echo [BUILD] FAILED code=%BUILD_ERR%
  goto END
)

echo.
if /i "%1"=="test" (
  set "TEST_LOG=logs\test.txt"
  if exist "%TEST_LOG%" del /q "%TEST_LOG%" >nul 2>nul
  echo [TEST] Running...
  "%TEST_EXECUTABLE%" --all --format=plain >"%TEST_LOG%" 2>&1
  set "TE=%ERRORLEVEL%"
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

