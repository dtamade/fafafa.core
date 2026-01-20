@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo fafafa.core.atomic test
echo ==========================================

set "PROJECT=%~dp0tests_atomic.lpi"
set "TEST_EXE=%~dp0bin\tests_atomic.exe"

if not exist "%PROJECT%" (
    echo error: project file is not exist: %PROJECT%
    if "%FAFAFA_INTERACTIVE%"=="1" pause
    exit /b 1
)

echo building...
lazbuild -B "%PROJECT%"

if %ERRORLEVEL% neq 0 (
    echo error: build failed, return code %ERRORLEVEL%
    if "%FAFAFA_INTERACTIVE%"=="1" pause
    exit /b 1
)

echo build success!

if not exist "%TEST_EXE%" (
    echo error: file is not exist: %TEST_EXE%
    if "%FAFAFA_INTERACTIVE%"=="1" pause
    exit /b 1
)

echo testing...
echo.
"%TEST_EXE%"

if %ERRORLEVEL% neq 0 (
    echo.
    echo error: test failed, return code %ERRORLEVEL%
    if "%FAFAFA_INTERACTIVE%"=="1" pause
    exit /b %ERRORLEVEL%
)

echo.
echo ==========================================
echo bye!
echo ==========================================
if "%FAFAFA_INTERACTIVE%"=="1" pause

