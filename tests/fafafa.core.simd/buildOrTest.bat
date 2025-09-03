@echo off
setlocal enabledelayedexpansion

echo ========================================
echo fafafa.core.simd Test Build Script
echo ========================================

:: Create necessary directories
if not exist "bin" mkdir bin
if not exist "lib" mkdir lib

:: Set compiler path
set LAZBUILD_PATH=lazbuild
if exist "..\..\tools\lazbuild.bat" (
    set LAZBUILD_PATH=..\..\tools\lazbuild.bat
)

:: Check command line arguments
if "%1"=="clean" goto :clean
if "%1"=="test" goto :test
if "%1"=="debug" goto :debug
if "%1"=="release" goto :release

:: Default: debug build and test
goto :debug

:clean
echo Cleaning build files...
if exist "bin" rmdir /s /q bin
if exist "lib" rmdir /s /q lib
echo Clean completed.
goto :end

:debug
echo Executing debug build...
%LAZBUILD_PATH% --build-mode=Debug fafafa.core.simd.test.lpi
if errorlevel 1 (
    echo Debug build failed!
    exit /b 1
)
echo Debug build successful.
goto :test

:release
echo Executing release build...
%LAZBUILD_PATH% --build-mode=Release fafafa.core.simd.test.lpi
if errorlevel 1 (
    echo Release build failed!
    exit /b 1
)
echo Release build successful.
goto :test

:test
echo Running tests...
if not exist "bin\fafafa.core.simd.test.exe" (
    echo Test executable does not exist, please build first.
    exit /b 1
)

echo.
echo ========================================
echo Starting SIMD facade function tests
echo ========================================
echo.

bin\fafafa.core.simd.test.exe --all --progress --format=plain

set TEST_RESULT=%errorlevel%

echo.
echo ========================================
if %TEST_RESULT%==0 (
    echo All tests passed!
) else (
    echo Tests failed, exit code: %TEST_RESULT%
)
echo ========================================

exit /b %TEST_RESULT%

:end
echo Operation completed.

:usage
echo.
echo Usage: buildOrTest.bat [option]
echo.
echo Options:
echo   clean    - Clean build files
echo   debug    - Debug build and run tests (default)
echo   release  - Release build and run tests
echo   test     - Run tests only (requires prior build)
echo.
echo Examples:
echo   buildOrTest.bat          - Debug build and test
echo   buildOrTest.bat release  - Release build and test
echo   buildOrTest.bat clean    - Clean build files
echo.
