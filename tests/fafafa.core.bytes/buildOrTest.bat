@echo off
setlocal ENABLEDELAYEDEXPANSION

rem Build or run tests for fafafa.core.bytes
rem Usage: BuildOrTest.bat [test]

pushd "%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"
if not exist "%LAZBUILD%" set "LAZBUILD=lazbuild"
set "PROJ=fafafa.core.bytes.test.lpi"
set "TEST_EXE=bin\fafafa.core.bytes.test.exe"

if not exist bin mkdir bin >nul 2>nul
if not exist lib mkdir lib >nul 2>nul
if not exist logs mkdir logs >nul 2>nul

set "LZ_Q="
if not "%FAFAFA_BUILD_QUIET%"=="0" set "LZ_Q=--quiet"
set "BUILD_LOG=logs\build.txt"
set "TEST_LOG=logs\test.txt"
if exist "%BUILD_LOG%" del /q "%BUILD_LOG%" >nul 2>nul
if exist "%TEST_LOG%" del /q "%TEST_LOG%" >nul 2>nul

if "%LAZBUILD%"=="lazbuild" (
  echo [BUILD] Project: %PROJ%
  lazbuild %LZ_Q% --build-all "%PROJ%" >"%BUILD_LOG%" 2>&1
) else (
  echo [BUILD] Project: %PROJ%
  call "%LAZBUILD%" %LZ_Q% --build-all "%PROJ%" >"%BUILD_LOG%" 2>&1
)
set "ERR=!ERRORLEVEL!"
if !ERR! NEQ 0 (
  echo [BUILD] FAILED code=!ERR!
  popd & endlocal & exit /b !ERR!
) else (
  echo [BUILD] OK
)

if /I "%1"=="test" (
  echo [TEST] Running...
  "%TEST_EXE%" --all --format=plain >"%TEST_LOG%" 2>&1
  set "ERR=!ERRORLEVEL!"
  if !ERR! EQU 0 (
    echo [TEST] OK
  ) else (
    echo [TEST] FAILED code=!ERR! & echo See "%TEST_LOG%" for details.
  )
  popd & endlocal & exit /b !ERR!
)

echo To run tests: BuildOrTest.bat test
popd
endlocal
exit /b 0

