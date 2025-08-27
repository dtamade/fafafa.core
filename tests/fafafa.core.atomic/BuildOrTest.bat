@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM Use standard template with overrides
set "MODULE_NAME=atomic"
set "PROJECT=%~dp0tests_atomic.lpi"
set "TEST_EXE=%~dp0bin\tests_atomic.exe"
call "%~dp0..\..\tools\test_template.bat" %*
exit /b %ERRORLEVEL%

