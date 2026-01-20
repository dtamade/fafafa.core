@echo off
setlocal ENABLEDELAYEDEXPANSION

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\..\"
set "LAZBUILD=%ROOT_DIR%tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%tests_fafafa.core.test.lpr"
set "BIN_DIR=%SCRIPT_DIR%bin"
set "LIB_DIR=%SCRIPT_DIR%lib"
set "TEST_EXE=%BIN_DIR%\tests.exe"
set "BUILD_ERRORLEVEL=0"

if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
mkdir "%BIN_DIR%"
mkdir "%LIB_DIR%"

echo Building project: %PROJECT% ...
call "%LAZBUILD%" "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
  echo.
  echo Build failed with error code %ERRORLEVEL%.
  set "BUILD_ERRORLEVEL=%ERRORLEVEL%"
  goto END
)

echo.
echo Build successful.
echo.

if /i "%1"=="test" (
  if exist "%TEST_EXE%" (
    echo Running tests...
    if /i "%2"=="update" (
      echo Snapshot update mode is ON
      set TEST_SNAPSHOT_UPDATE=1
    )
    "%TEST_EXE%" --all --progress -u > "%BIN_DIR%\last-run.txt" 2>&1
    set "BUILD_ERRORLEVEL=%ERRORLEVEL%"
    "%TEST_EXE%" --all --format=xml > "%BIN_DIR%\results.xml" 2>&1
    type "%BIN_DIR%\last-run.txt"
    echo ====== End of console log ======
  ) else (
    echo Test executable not found: "%TEST_EXE%"
  )
) else (
  echo To run tests, call this script with the 'test' parameter.
  echo Optionally use: BuildOrTest.bat test update   ^(to refresh snapshots^)
)

:END
exit /b %BUILD_ERRORLEVEL%

