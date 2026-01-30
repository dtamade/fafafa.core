@echo off

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=example_mem.lpi"
set "DEBUG_EXE=%SCRIPT_DIR%bin\example_mem_debug.exe"
set "RELEASE_EXE=%SCRIPT_DIR%bin\example_mem.exe"

if /i "%1"=="debug" (
  echo Building Debug...
  call "%LAZBUILD%" --build-mode=Debug "%SCRIPT_DIR%%PROJECT%"
  if %ERRORLEVEL% NEQ 0 goto BUILD_FAIL
  if /i "%2"=="run" (
    "%DEBUG_EXE%"
  )
  goto END
)

if /i "%1"=="release" (
  echo Building Release...
  call "%LAZBUILD%" --build-mode=Release "%SCRIPT_DIR%%PROJECT%"
  if %ERRORLEVEL% NEQ 0 goto BUILD_FAIL
  if /i "%2"=="run" (
    "%RELEASE_EXE%"
  )
  goto END
)

echo Usage: BuildAndRun.bat [debug|release] [run]
goto END

:BUILD_FAIL
echo.
echo Build failed with error code %ERRORLEVEL%.

:END
