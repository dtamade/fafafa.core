@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"
set "PROJECT=fafafa.core.os.test.lpi"
set "TEST_EXECUTABLE=bin\tests_os.exe"

if not exist "%LAZBUILD%" (
  where lazbuild >nul 2>nul
  if %ERRORLEVEL% EQU 0 (
    echo [INFO] Using lazbuild from PATH.
    set "LAZBUILD=lazbuild"
  ) else (
    echo [ERROR] lazbuild not found.
    popd & endlocal & exit /b 1
  )
)

set "LZ_Q="
if not "%FAFAFA_BUILD_QUIET%"=="0" set "LZ_Q=--quiet"
if not exist logs mkdir logs >nul 2>nul
set "BUILD_LOG=logs\build.txt"
set "TEST_LOG=logs\test.txt"
if exist "%BUILD_LOG%" del /q "%BUILD_LOG%" >nul 2>nul
if exist "%TEST_LOG%" del /q "%TEST_LOG%" >nul 2>nul

echo [BUILD] Project: %PROJECT%
call "%LAZBUILD%" %LZ_Q% --build-all "%PROJECT%" >"%BUILD_LOG%" 2>&1
if errorlevel 1 (
  echo [BUILD] FAILED
  popd & endlocal & exit /b 1
)

echo [RUN] %TEST_EXECUTABLE%
if exist "%TEST_EXECUTABLE%" (
  echo [TEST] Running...
  "%TEST_EXECUTABLE%" -a -p --format=plain >"%TEST_LOG%" 2>&1
  set "EC=%ERRORLEVEL%"
  if !EC! EQU 0 (
    echo [TEST] OK
  ) else (
    echo [TEST] FAILED code=!EC! & echo See "%TEST_LOG%" for details.
  )
  popd & endlocal & exit /b !EC!
) else (
  echo [ERROR] Executable not found: %TEST_EXECUTABLE%
  popd & endlocal & exit /b 1
)
