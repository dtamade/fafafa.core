@echo off
setlocal
call "%~dp0run_suite.bat" TTestCase_LookPath_Basic
if ERRORLEVEL 1 exit /B %ERRORLEVEL%
call "%~dp0run_suite.bat" TTestCase_LookPath_Edges
exit /B %ERRORLEVEL%

