@echo off
setlocal
set SCRIPT_DIR=%~dp0
set BIN=%SCRIPT_DIR%\bin
if not exist "%BIN%" mkdir "%BIN%"

rem Build 07_frame_loop_demo.lpr
pushd "%SCRIPT_DIR%"
fpc -B -O2 -g -gl -S2 -FE"%BIN%" -FU"%SCRIPT_DIR%\lib" -Fu"%SCRIPT_DIR%\..\..\src" 07_frame_loop_demo.lpr
set BUILDERR=%ERRORLEVEL%
popd
if %BUILDERR% NEQ 0 (
  echo Build failed for 07_frame_loop_demo.lpr
  exit /b 1
)
if %ERRORLEVEL% NEQ 0 (
  echo Build failed for 07_frame_loop_demo.lpr
  exit /b 1
)

"%BIN%\07_frame_loop_demo.exe"
endlocal

