@echo off
setlocal
cd /d %~dp0

REM Build example_basic via lazbuild helper
..
..\..\tools\lazbuild.bat example_basic.lpi
if errorlevel 1 goto :eof

REM Run
bin\example_basic.exe
endlocal

