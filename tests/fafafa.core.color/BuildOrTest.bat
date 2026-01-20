@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Use standard template with overrides
set "MODULE_NAME=color"
set "PROJECT=%~dp0tests_color.lpi"
set "TEST_EXE=%~dp0..\..\bin\tests_color.exe"
call "%~dp0..\..\tools\test_template.bat" %*
exit /b %ERRORLEVEL%

