@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "FPC_EXE=fpc"
set "FPC_FLAGS=-MObjFPC -Scghi -O1 -g -gl -gh -vewnhibq"
set "SRC_ROOT=..\..\src"
set "BIN_DIR=bin"
set "LIB_DIR=lib"
set "PROG=event_echo.lpr"
rem to switch example, set PROG to another .lpr (e.g., play_term_raw_poll.lpr)
for %%F in ("%PROG%") do set "OUT_EXE=%BIN_DIR%\%%~nF.exe"
rem to try the minimal UI frame loop demo, set:
rem   set "PROG=play_ui_frame_loop.lpr"


if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

rem Prefer lazbuild if .lpi exists (not provided for plays), otherwise compile with fpc directly
where lazbuild >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  echo [plays] lazbuild found, compiling with FPC directly for simplicity.
)

echo Building %PROG% ...
"%FPC_EXE%" %FPC_FLAGS% ^
  -Fi"%SRC_ROOT%" -Fu"%SRC_ROOT%" -Fu"%SRC_ROOT%\ui" ^
  -FE"%BIN_DIR%" -FU"%LIB_DIR%" "%PROG%"
set "BUILD_ERR=%ERRORLEVEL%"

if not !BUILD_ERR! EQU 0 (
  echo Build failed with code !BUILD_ERR!
  popd
  endlocal
  exit /b !BUILD_ERR!
)

echo.
echo Build successful: %OUT_EXE%
echo.

echo Running... (press 'q' or 'Q' to quit)
"%OUT_EXE%"
set "RUN_ERR=%ERRORLEVEL%"
echo Program exit code: !RUN_ERR!

popd
endlocal
exit /b !RUN_ERR!

