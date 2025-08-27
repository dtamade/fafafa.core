@echo off
setlocal
set LAZBUILD=lazbuild
set OUTDIR=%~dp0bin
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

rem Delegate to build_all.bat to build green-only set
call "%~dp0build_all.bat"

echo Build finished. See %~dp0bin for artifacts.
endlocal

