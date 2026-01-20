@echo off
echo Debug Build Script for fafafa.core.sync.sem
echo =============================================

:: Set paths
set LAZBUILD=D:\devtools\lazarus\trunk\lazbuild.exe
set PROJECT_FILE=fafafa.core.sync.sem.test.lpi

echo Checking environment...
echo LAZBUILD: %LAZBUILD%
echo PROJECT_FILE: %PROJECT_FILE%
echo Current directory: %CD%

:: Check if lazbuild exists
if exist "%LAZBUILD%" (
    echo [OK] lazbuild found
) else (
    echo [ERROR] lazbuild not found
    goto :end
)

:: Check if project file exists
if exist "%PROJECT_FILE%" (
    echo [OK] Project file found
) else (
    echo [ERROR] Project file not found
    goto :end
)

:: Create directories
echo Creating directories...
if not exist bin mkdir bin
if not exist lib mkdir lib

:: Show directory structure before build
echo.
echo Directory structure before build:
echo bin\:
dir bin 2>nul || echo (empty)
echo lib\:
dir lib 2>nul || echo (empty)

:: Run lazbuild with maximum verbosity
echo.
echo Running lazbuild with verbose output...
echo Command: "%LAZBUILD%" --verbose --build-mode=Debug %PROJECT_FILE%
echo =============================================
"%LAZBUILD%" --verbose --build-mode=Debug %PROJECT_FILE% 2>&1
set BUILD_RESULT=%errorlevel%
echo =============================================
echo Build result: %BUILD_RESULT%

:: Show directory structure after build
echo.
echo Directory structure after build:
echo bin\:
dir bin 2>nul || echo (empty)
echo lib\:
dir lib 2>nul || echo (empty)
if exist lib\x86_64-win64 (
    echo lib\x86_64-win64\:
    dir lib\x86_64-win64
)

:: Check for specific files
echo.
echo Checking for expected files...
if exist bin\fafafa.core.sync.sem.test.exe (
    echo [OK] Executable found: bin\fafafa.core.sync.sem.test.exe
    dir bin\fafafa.core.sync.sem.test.exe
) else (
    echo [MISSING] Executable not found: bin\fafafa.core.sync.sem.test.exe
)

if exist lib\x86_64-win64\fafafa.core.sync.sem.test.compiled (
    echo [OK] Compiled marker found
) else (
    echo [MISSING] Compiled marker not found
)

:end
echo.
echo Debug build script completed.
if "%FAFAFA_INTERACTIVE%"=="1" pause
