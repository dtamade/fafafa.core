@echo off
setlocal
set PROJ_DIR=%~dp0
set BIN=%PROJ_DIR%bin
set LIB=%PROJ_DIR%lib
if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"

REM Build with lazbuild if available, fallback to fpc
if exist "%PROJ_DIR%fafafa.core.term.play.lpi" (
  lazbuild --bm=Debug --lazarusdir="%LAZARUS_DIR%" --build-mode=Debug "%PROJ_DIR%fafafa.core.term.play.lpi"
) else (
  fpc -gl -O1 -Fugenerics.collections -Fu..\..\src -FE"%BIN%" -FU"%LIB%" "%PROJ_DIR%fafafa.core.term.play.lpr"
)
if errorlevel 1 goto :err

"%BIN%\fafafa.core.term.play.exe"
exit /b %errorlevel%

:err
echo Build failed
exit /b 1

