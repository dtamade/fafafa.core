@echo off
setlocal
set LAZBUILD=..\..\..\tools\lazbuild.bat
set PROJ=example_policy_pipeline.lpr
call %LAZBUILD% %PROJ%
endlocal

