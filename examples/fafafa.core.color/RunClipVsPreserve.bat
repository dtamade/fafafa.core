@echo off
setlocal ENABLEDELAYEDEXPANSION

set "PROJ=%~dp0example_clip_vs_preserve.lpr"
set "OUT=%~dp0..\..\bin\example_clip_vs_preserve.exe"

call "%~dp0..\..\tools\lazbuild.bat" "%PROJ%"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

"%OUT%"
exit /b %ERRORLEVEL%

