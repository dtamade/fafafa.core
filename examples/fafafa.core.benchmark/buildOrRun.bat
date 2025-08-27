@echo off
setlocal
set THIS_DIR=%~dp0
pushd %THIS_DIR%

rem resolve lazbuild
set LAZBUILD_EXE="D:\devtools\lazarus\trunk\lazarus\lazbuild.exe"
if not exist %LAZBUILD_EXE% (
  echo Please set LAZBUILD_EXE to lazbuild.exe
  exit /b 1
)

rem build
%LAZBUILD_EXE% --build-mode=Debug example_basic_console.lpi
if errorlevel 1 goto :eof
%LAZBUILD_EXE% --build-mode=Debug example_benchmarks_console.lpi
if errorlevel 1 goto :eof

rem run
..\..\bin\example_basic_console.exe
..\..\bin\example_benchmarks_console.exe

popd
endlocal

