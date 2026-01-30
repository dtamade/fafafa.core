@echo off
setlocal
pushd %~dp0

set LAZBUILD=lazbuild
set PROJ=fafafa.core.bytes.buf.test.lpi

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
  bin\fafafa.core.bytes.buf.test.exe --all --progress
  set rc=%ERRORLEVEL%
  popd
  exit /b %rc%
)

echo Done. To run tests: buildOrTest.bat test
popd
exit /b 0

