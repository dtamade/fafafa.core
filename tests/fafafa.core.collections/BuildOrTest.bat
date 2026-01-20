@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Use standard template with overrides
set "MODULE_NAME=collections"
set "PROJECT=%~dp0tests_collections.lpi"
set "TEST_EXE=%~dp0bin\tests_collections.exe"
call "%~dp0..\..\tools\test_template.bat" %*
exit /b %ERRORLEVEL%
