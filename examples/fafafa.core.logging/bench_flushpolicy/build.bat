@echo off
setlocal
set LAZBUILD=..\..\..\tools\lazbuild.bat
set PROJ=bench_flushpolicy.lpr
call %LAZBUILD% %PROJ%
endlocal

