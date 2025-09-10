@echo off
echo Building fafafa.core.sync.sem tests...

:: Set paths
set LAZBUILD=D:\devtools\lazarus\trunk\lazbuild.exe
set PROJECT_FILE=fafafa.core.sync.sem.test.lpi

:: Create directories
if not exist bin mkdir bin
if not exist lib mkdir lib

:: Build
echo Building %PROJECT_FILE%...
"%LAZBUILD%" --verbose --build-mode=Debug %PROJECT_FILE%

if %errorlevel% equ 0 (
    echo Build completed successfully
    if exist bin\fafafa.core.sync.sem.test.exe (
        echo Executable created: bin\fafafa.core.sync.sem.test.exe
        dir bin\fafafa.core.sync.sem.test.exe
    ) else (
        echo Warning: Executable not found in expected location
    )
) else (
    echo Build failed with error code: %errorlevel%
)

echo.
echo Done.
