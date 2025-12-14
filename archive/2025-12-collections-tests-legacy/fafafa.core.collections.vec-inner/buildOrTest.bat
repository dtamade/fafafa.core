@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

if not exist bin mkdir bin
if not exist lib mkdir lib

lazbuild "fafafa.core.collections.vec.test.lpi" --build-mode=Debug
if errorlevel 1 goto :err

for %%F in (bin\*.exe) do set "EXE=%%F"
if not defined EXE (
  echo ERROR: no exe under bin
  goto :err
)

"%EXE%" --all --format=plain --progress -x
set RC=!ERRORLEVEL!
popd
exit /b !RC!

:err
popd
exit /b 1

