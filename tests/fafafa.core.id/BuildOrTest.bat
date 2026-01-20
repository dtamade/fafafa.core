@echo off
setlocal ENABLEDELAYEDEXPANSION
set ROOT=%~dp0..
cd /d %~dp0

if "%1"=="" goto build
if /I "%1"=="test" goto test

:build
call ..\..\tools\lazbuild.bat tests_id.lpi || exit /b 1
exit /b 0

:test
call ..\..\tools\lazbuild.bat tests_id.lpi || exit /b 1
.\bin\tests_id.exe --all --format=plain
exit /b %ERRORLEVEL%

