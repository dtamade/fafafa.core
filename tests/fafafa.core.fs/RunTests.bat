@echo off
setlocal ENABLEDELAYEDEXPANSION

set "ROOT=%~dp0"
set "PROJECT=%ROOT%tests_fs.lpi"
set "BIN=%ROOT%bin"
set "LIB=%ROOT%lib"
set "TEST_EXE=%BIN%\tests_fs.exe"

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"

if exist "%TEST_EXE%" del /f /q "%TEST_EXE%"

REM Resolve lazbuild path
if not defined LAZBUILD_EXE set "LAZBUILD_EXE=D:\devtools\lazarus\trunk\lazarus\lazbuild.exe"
if not exist "%LAZBUILD_EXE%" (
  echo ERROR: lazbuild not found: "%LAZBUILD_EXE%"
  exit /b 1
)

echo [RUNTESTS] Building: %PROJECT%
"%LAZBUILD_EXE%" -B "%PROJECT%"
set "BUILD_ERR=%ERRORLEVEL%"
if not "%BUILD_ERR%"=="0" (
  echo [RUNTESTS] Build failed: %BUILD_ERR%
  exit /b %BUILD_ERR%
)

echo [RUNTESTS] Listing bin directory...
dir "%BIN%"

if not exist "%TEST_EXE%" (
  echo [RUNTESTS] ERROR: Test executable not found: %TEST_EXE%
  exit /b 2
)

echo [RUNTESTS] Running tests...
"%TEST_EXE%" --format=plain --all
set "TEST_ERR=%ERRORLEVEL%"
echo [RUNTESTS] tests exit code: %TEST_ERR%
exit /b %TEST_ERR%

