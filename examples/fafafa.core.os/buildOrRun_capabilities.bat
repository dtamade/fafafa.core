@echo off
setlocal
cd /d %~dp0
..
..\..\tools\lazbuild.bat example_capabilities.lpi
if errorlevel 1 goto :eof
bin\example_capabilities.exe
endlocal

