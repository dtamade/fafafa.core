@echo off
setlocal
set LAZBUILD=..\..\..\tools\lazbuild.bat
set PROJ=example_daily_rolling.lpr
call %LAZBUILD% %PROJ%
endlocal

