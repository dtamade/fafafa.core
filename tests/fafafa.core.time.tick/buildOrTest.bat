@echo off
setlocal enabledelayedexpansion

rem Ensure running from the script directory so relative paths work
pushd "%~dp0"

echo ========================================
echo fafafa.core.time.tick Unit Test Build Script
echo ========================================
echo.

set PROJECT_NAME=fafafa.core.time.tick.test
set PROJECT_FILE=%PROJECT_NAME%.lpi
set BIN_DIR=bin
set LIB_DIR=lib

:: Prefer lazbuild if available; otherwise fallback to FPC
where lazbuild >nul 2>&1
set "HAVE_LAZBUILD=%ERRORLEVEL%"

:: Create output directories
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

echo Building test project...
echo Project file: %PROJECT_FILE%
echo.

if %HAVE_LAZBUILD% EQU 0 (
  echo [build] lazbuild --build-mode=Debug --verbose %PROJECT_FILE%
  lazbuild --build-mode=Debug --verbose %PROJECT_FILE%
  set BUILD_RESULT=%ERRORLEVEL%
) else (
  echo [WARN] lazbuild not found. Falling back to FPC direct compile...
  if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
  if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
  mkdir "%BIN_DIR%" 2>nul
  mkdir "%LIB_DIR%" 2>nul
  echo [build] fpc -Mobjfpc -Sh -O2 -g -gl -Ci -Co -Cr -Ct -Fu../../src -Fu. -FU"%LIB_DIR%" -FE"%BIN_DIR%" %PROJECT_NAME%.lpr
  fpc -Mobjfpc -Sh -O2 -g -gl -Ci -Co -Cr -Ct -Fu../../src -Fu. -FU"%LIB_DIR%" -FE"%BIN_DIR%" %PROJECT_NAME%.lpr
  set BUILD_RESULT=%ERRORLEVEL%
)

echo.
if %BUILD_RESULT% EQU 0 (
    echo Build successful!
    echo.

    :: Use canonical runner exe and force plain output
    set EXE_PATH=%BIN_DIR%\%PROJECT_NAME%.exe

    if exist "%EXE_PATH%" (
        echo Running tests (plain): %EXE_PATH%
        echo ========================================
        echo.
        "%EXE_PATH%" --format=plain --all
        set TEST_RESULT=!ERRORLEVEL!
        if NOT !TEST_RESULT! EQU 0 (
            echo [info] Falling back to run without extra args...
            "%EXE_PATH%"
            set TEST_RESULT=!ERRORLEVEL!
        )
    ) else (
        echo ERROR: Expected test runner not found: %EXE_PATH%
        echo Available executables under %BIN_DIR%:
        dir /b "%BIN_DIR%\*.exe"
        set TEST_RESULT=1
    )

        echo.
        echo ========================================
        if !TEST_RESULT! EQU 0 (
            echo All tests passed!
        ) else (
            echo Tests failed with exit code: !TEST_RESULT!
        )
) else (
    echo Build failed with exit code: %BUILD_RESULT%
    set TEST_RESULT=%BUILD_RESULT%
)

echo.
echo Press any key to exit...
pause >nul
exit /b %TEST_RESULT%
