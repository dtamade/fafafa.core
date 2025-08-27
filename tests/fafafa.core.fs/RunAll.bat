@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "PROJECT=%SCRIPT_DIR%tests_fs.lpi"
set "BIN=%SCRIPT_DIR%bin"
set "TEST_EXE=%BIN%\tests_fs.exe"
set "BUILD_LOG=%SCRIPT_DIR%build_fs.log"
set "TEST_LOG=%SCRIPT_DIR%tests_fs.log"

if exist "%BUILD_LOG%" del /f /q "%BUILD_LOG%"
if exist "%TEST_LOG%" del /f /q "%TEST_LOG%"
if not exist "%BIN%" mkdir "%BIN%"

if not defined LAZBUILD_EXE set "LAZBUILD_EXE=D:\devtools\lazarus\trunk\lazarus\lazbuild.exe"
if not exist "%LAZBUILD_EXE%" (
  echo [RUNALL] ERROR: lazbuild not found: "%LAZBUILD_EXE%"
  exit /b 1
)

echo [RUNALL] Building: %PROJECT%
"%LAZBUILD_EXE%" -B "%PROJECT%" > "%BUILD_LOG%" 2>&1
set "BUILD_ERR=%ERRORLEVEL%"
echo [RUNALL] Build exit code: %BUILD_ERR%
type "%BUILD_LOG%"
if not "%BUILD_ERR%"=="0" (
  echo [RUNALL] Build failed
  exit /b %BUILD_ERR%
)

if not exist "%TEST_EXE%" (
  echo [RUNALL] ERROR: Test executable not found: %TEST_EXE%
  exit /b 2
)

echo [RUNALL] Running tests...
"%TEST_EXE%" --format=plain --all > "%TEST_LOG%" 2>&1
set "TEST_ERR=%ERRORLEVEL%"
echo [RUNALL] Tests exit code: %TEST_ERR%
type "%TEST_LOG%"
exit /b %TEST_ERR%

