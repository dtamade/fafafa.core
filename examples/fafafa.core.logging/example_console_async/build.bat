@echo off
setlocal
set LAZBUILD=..\..\..\tools\lazbuild.bat
set PROJ=example_console_async.lpr
call %LAZBUILD% %PROJ%
endlocal

