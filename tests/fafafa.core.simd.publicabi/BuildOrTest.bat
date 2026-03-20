@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"
if not "%~1"=="" shift

set "ROOT=%~dp0"
if not "%ROOT:~-1%"=="\" set "ROOT=%ROOT%\"
for %%I in ("%ROOT%..\..") do set "REPO_ROOT=%%~fI"
set "FPC_BIN=%FPC_BIN%"
if "%FPC_BIN%"=="" set "FPC_BIN=fpc"

set "TARGET_CPU="
for /f "delims=" %%I in ('%FPC_BIN% -iTP 2^>nul') do if not defined TARGET_CPU set "TARGET_CPU=%%I"
if not defined TARGET_CPU set "TARGET_CPU=nativecpu"
set "TARGET_OS="
for /f "delims=" %%I in ('%FPC_BIN% -iTO 2^>nul') do if not defined TARGET_OS set "TARGET_OS=%%I"
if not defined TARGET_OS set "TARGET_OS=nativeos"

set "OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"
if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=%ROOT%"
set "BIN_DIR=%OUTPUT_ROOT%bin"
set "LIB_DIR=%OUTPUT_ROOT%lib\%TARGET_CPU%-%TARGET_OS%"
set "LOG_DIR=%OUTPUT_ROOT%logs"
set "PROJ=%ROOT%fafafa.core.simd.publicabi.lpr"
set "BUILD_LOG=%LOG_DIR%\build.txt"
set "TEST_LOG=%LOG_DIR%\test.txt"
set "PS_SCRIPT=%ROOT%publicabi_smoke.ps1"
set "LIB_PATH="
set "POWERSHELL_EXE="

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

if /I "%ACTION%"=="clean" goto :clean
if /I "%ACTION%"=="build" goto :build
if /I "%ACTION%"=="validate-exports" goto :validate_exports
if /I "%ACTION%"=="test" goto :test
if /I "%ACTION%"=="run" goto :test

echo Usage: %~nx0 [clean^|build^|validate-exports^|test^|run]
exit /b 2

:resolve_library
set "LIB_PATH="
for %%F in ("%BIN_DIR%\*.dll") do (
  if not defined LIB_PATH set "LIB_PATH=%%~fF"
)
if not defined LIB_PATH (
  for %%F in ("%BIN_DIR%\*.DLL") do (
    if not defined LIB_PATH set "LIB_PATH=%%~fF"
  )
)
if not defined LIB_PATH exit /b 1
exit /b 0

:resolve_powershell
set "POWERSHELL_EXE="
where pwsh >nul 2>nul
if not errorlevel 1 (
  set "POWERSHELL_EXE=pwsh"
  exit /b 0
)
where powershell >nul 2>nul
if not errorlevel 1 (
  set "POWERSHELL_EXE=powershell"
  exit /b 0
)
echo [PUBLICABI] FAILED ^(PowerShell runtime not found; tried pwsh and powershell^)
exit /b 2

:build
echo [BUILD] Project: %PROJ%
echo. > "%BUILD_LOG%"
%FPC_BIN% -B -Mobjfpc -Scghi -O3 -Fi"%REPO_ROOT%\src" -Fu"%REPO_ROOT%\src" -FE"%BIN_DIR%" -FU"%LIB_DIR%" "%PROJ%" > "%BUILD_LOG%" 2>&1
if errorlevel 1 (
  echo [BUILD] FAILED ^(see %BUILD_LOG%^)
  type "%BUILD_LOG%"
  exit /b 1
)
call :resolve_library
if errorlevel 1 (
  echo [BUILD] FAILED ^(library missing in %BIN_DIR%^)
  type "%BUILD_LOG%"
  exit /b 1
)
echo [BUILD] OK ^(!LIB_PATH!^)
exit /b 0

:validate_exports
call :build
if errorlevel 1 exit /b 1
if not exist "%PS_SCRIPT%" (
  echo [PUBLICABI] Missing PowerShell smoke script: %PS_SCRIPT%
  exit /b 2
)
call :resolve_powershell
if errorlevel 1 exit /b %ERRORLEVEL%
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -LibraryPath "%LIB_PATH%" -ValidateOnly
exit /b %ERRORLEVEL%

:test
call :build
if errorlevel 1 exit /b 1
if not exist "%PS_SCRIPT%" (
  echo [PUBLICABI] Missing PowerShell smoke script: %PS_SCRIPT%
  exit /b 2
)
call :resolve_powershell
if errorlevel 1 exit /b %ERRORLEVEL%
echo. > "%TEST_LOG%"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -LibraryPath "%LIB_PATH%" > "%TEST_LOG%" 2>&1
if errorlevel 1 (
  echo [TEST] FAILED ^(see %TEST_LOG%^)
  type "%TEST_LOG%"
  exit /b 1
)
echo [TEST] OK
exit /b 0

:clean
if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
exit /b 0
