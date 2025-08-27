@echo off
setlocal
call "%~dp0run_suite.bat" TTestCase_ShellExecute_Min
exit /B %ERRORLEVEL%

