@echo off
setlocal
set "LAZBUILD=%~dp0..\..\tools\lazbuild.bat"
set "PROJECT=%~dp0example_layout_ui.lpi"
set "EXE=%~dp0bin\example_layout_ui.exe"

call "%LAZBUILD%" "%PROJECT%"
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%

if exist "%EXE%" (
  echo Running: %EXE%
  "%EXE%"
) else (
  echo Executable not found: %EXE%
  exit /b 1
)
endlocal

