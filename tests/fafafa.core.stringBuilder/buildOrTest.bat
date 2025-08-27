@echo off
setlocal

rem Build or run tests for fafafa.core.stringBuilder
rem Usage: buildOrTest.bat [test]

pushd %~dp0
set LAZBUILD=lazbuild
set PROJ=fafafa.core.stringBuilder.test.lpi

if not exist bin mkdir bin
if not exist lib mkdir lib

%LAZBUILD% --build-mode=Debug %PROJ%
if errorlevel 1 (
  echo Build failed.
  popd
  exit /b 1
)

if /I "%1"=="test" (
  echo Running tests...
  bin\fafafa.core.stringBuilder.test.exe --all --progress
  set ERR=%ERRORLEVEL%
  popd
  exit /b %ERR%
)

echo Done. To run tests: buildOrTest.bat test
popd
exit /b 0

