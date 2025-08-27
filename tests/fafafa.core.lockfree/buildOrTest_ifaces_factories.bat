@echo off
setlocal enabledelayedexpansion

REM Build and run the interface/factories tests
set SCRIPT_DIR=%~dp0
set LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat
set PROJECT=fafafa.core.lockfree.ifaces_factories.test.lpi
set TEST_EXE=%SCRIPT_DIR%bin\lockfree_ifaces_factories_tests.exe

pushd %SCRIPT_DIR%
call "%LAZBUILD%" "%PROJECT%"
if errorlevel 1 goto :build_failed

"%TEST_EXE%" --all --format=plain --progress
set ERR=%ERRORLEVEL%
popd
if not "%ERR%"=="0" goto :run_failed

echo Done.
exit /b 0

:build_failed
echo Build failed.
exit /b 1

:run_failed
echo Run failed with code %ERR%.
exit /b %ERR%

