@echo off
setlocal
set LAZBUILD=..\..\..\tools\lazbuild.bat
set PROJ=example_console_and_rolling.lpr
call %LAZBUILD% %PROJ%
endlocal

