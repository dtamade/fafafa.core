@echo off
echo Building and running simple test...

:: Create directories
if not exist bin mkdir bin
if not exist lib mkdir lib

:: Build simple test
echo Building simple_run_test...
D:\devtools\lazarus\trunk\lazbuild.exe --build-mode=Debug simple_run_test.lpi

:: Check if executable was generated
if exist bin\simple_run_test.exe (
    echo Build successful, running test...
    bin\simple_run_test.exe
) else (
    echo Build failed, executable not generated
)

pause
