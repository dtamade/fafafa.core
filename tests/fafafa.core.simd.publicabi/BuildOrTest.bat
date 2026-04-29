@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=test"
if not "%~1"=="" shift
if /I "%ACTION%"=="run" set "ACTION=test"

for %%I in ("%~dp0.") do set "ROOT=%%~fI"
if not "%ROOT:~-1%"=="\" set "ROOT=%ROOT%\"
for %%I in ("%ROOT%..\..") do set "REPO_ROOT=%%~fI"
set "FPC_BIN=%FPC_BIN%"
if "%FPC_BIN%"=="" set "FPC_BIN=%FPC%"
set "FPC_RESOLVE_ERROR="
call :resolve_fpc_bin >nul 2>nul

set "TARGET_CPU="
if not "%FPC_BIN%"=="" for /f "delims=" %%I in ('"%FPC_BIN%" -iTP 2^>nul') do if not defined TARGET_CPU set "TARGET_CPU=%%I"
if not defined TARGET_CPU set "TARGET_CPU=nativecpu"
set "TARGET_OS="
if not "%FPC_BIN%"=="" for /f "delims=" %%I in ('"%FPC_BIN%" -iTO 2^>nul') do if not defined TARGET_OS set "TARGET_OS=%%I"
if not defined TARGET_OS set "TARGET_OS=nativeos"

set "OUTPUT_ROOT=%SIMD_OUTPUT_ROOT%"
if "%OUTPUT_ROOT%"=="" set "OUTPUT_ROOT=%ROOT%"
set "BIN_DIR=%OUTPUT_ROOT%\bin"
set "LIB_DIR=%OUTPUT_ROOT%\lib\%TARGET_CPU%-%TARGET_OS%"
set "LOG_DIR=%OUTPUT_ROOT%\logs"
set "PROJ=%ROOT%fafafa.core.simd.publicabi.lpr"
set "BUILD_LOG=%LOG_DIR%\build.txt"
set "TEST_LOG=%LOG_DIR%\test.txt"
set "PS_SCRIPT=%ROOT%publicabi_smoke.ps1"
set "LIB_PATH="
set "POWERSHELL_EXE="

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

if /I "%ACTION%"=="clean" (
  if exist "%BIN_DIR%" rmdir /s /q "%BIN_DIR%"
  if exist "%LIB_DIR%" rmdir /s /q "%LIB_DIR%"
  if exist "%LOG_DIR%" rmdir /s /q "%LOG_DIR%"
  exit /b 0
)

if /I "%ACTION%"=="build" (
  call :build
  set "ACTION_RC=!ERRORLEVEL!"
  exit /b !ACTION_RC!
)

if /I "%ACTION%"=="validate-exports" (
  call :build
  if errorlevel 1 exit /b 1
  if not exist "%PS_SCRIPT%" (
    echo [PUBLICABI] Missing PowerShell smoke script: %PS_SCRIPT%
    exit /b 2
  )
  call :resolve_powershell
  set "ACTION_RC=!ERRORLEVEL!"
  if not "!ACTION_RC!"=="0" exit /b !ACTION_RC!
  "!POWERSHELL_EXE!" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -LibraryPath "!LIB_PATH!" -ValidateOnly
  set "ACTION_RC=!ERRORLEVEL!"
  exit /b !ACTION_RC!
)

if /I "%ACTION%"=="test" (
  call :build
  if errorlevel 1 exit /b 1
  if not exist "%PS_SCRIPT%" (
    echo [PUBLICABI] Missing PowerShell smoke script: %PS_SCRIPT%
    exit /b 2
  )
  call :resolve_powershell
  set "ACTION_RC=!ERRORLEVEL!"
  if not "!ACTION_RC!"=="0" exit /b !ACTION_RC!
  echo. > "%TEST_LOG%"
  "!POWERSHELL_EXE!" -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -LibraryPath "!LIB_PATH!" > "%TEST_LOG%" 2>&1
  if errorlevel 1 (
    echo [TEST] FAILED ^(see %TEST_LOG%^)
    type "%TEST_LOG%"
    exit /b 1
  )
  echo [TEST] OK
  exit /b 0
)

echo Usage: %~nx0 [clean^|build^|validate-exports^|test^|run]
exit /b 2

:resolve_fpc_bin_from_root
set "FPC_SEARCH_ROOT=%~1"
if "%FPC_SEARCH_ROOT%"=="" exit /b 1
if not exist "%FPC_SEARCH_ROOT%\fpc" exit /b 1
for /d %%V in ("%FPC_SEARCH_ROOT%\fpc\*") do (
  if exist "%%~fV\bin\%TARGET_CPU%-%TARGET_OS%\fpc.exe" (
    set "FPC_BIN=%%~fV\bin\%TARGET_CPU%-%TARGET_OS%\fpc.exe"
    exit /b 0
  )
  if exist "%%~fV\bin\x86_64-win64\fpc.exe" (
    set "FPC_BIN=%%~fV\bin\x86_64-win64\fpc.exe"
    exit /b 0
  )
  if exist "%%~fV\bin\i386-win32\fpc.exe" (
    set "FPC_BIN=%%~fV\bin\i386-win32\fpc.exe"
    exit /b 0
  )
)
exit /b 1

:resolve_fpc_bin
if not "%FPC_BIN%"=="" (
  if exist "%FPC_BIN%" exit /b 0
  set "FPC_RESOLVE_ERROR=requested FPC compiler not found: %FPC_BIN%"
  exit /b 1
)
for /f "delims=" %%P in ('where fpc.exe 2^>nul') do (
  set "FPC_BIN=%%~fP"
  exit /b 0
)
for /f "delims=" %%P in ('where fpc 2^>nul') do (
  set "FPC_BIN=%%~fP"
  exit /b 0
)
if defined ProgramFiles (
  call :resolve_fpc_bin_from_root "%ProgramFiles%\Lazarus"
  if not errorlevel 1 exit /b 0
)
if defined ProgramW6432 (
  call :resolve_fpc_bin_from_root "%ProgramW6432%\Lazarus"
  if not errorlevel 1 exit /b 0
)
call :resolve_fpc_bin_from_root "C:\Program Files\Lazarus"
if not errorlevel 1 exit /b 0
call :resolve_fpc_bin_from_root "C:\Program Files (x86)\Lazarus"
if not errorlevel 1 exit /b 0
call :resolve_fpc_bin_from_root "C:\lazarus"
if not errorlevel 1 exit /b 0
call :resolve_fpc_bin_from_root "C:\Lazarus"
if not errorlevel 1 exit /b 0
set "FPC_BIN="
exit /b 1

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
call :resolve_fpc_bin
if errorlevel 1 (
  if defined FPC_RESOLVE_ERROR (
    echo [BUILD] FAILED ^(%FPC_RESOLVE_ERROR%^) > "%BUILD_LOG%"
  ) else (
    echo [BUILD] FAILED ^(fpc compiler not found; set FPC_BIN/FPC or install Lazarus/FPC^) > "%BUILD_LOG%"
  )
  echo [BUILD] FAILED ^(see %BUILD_LOG%^)
  type "%BUILD_LOG%"
  exit /b 2
)
"%FPC_BIN%" -B -Mobjfpc -Scghi -O3 -Fi"%REPO_ROOT%\src" -Fu"%REPO_ROOT%\src" -FE"%BIN_DIR%" -FU"%LIB_DIR%" "%PROJ%" > "%BUILD_LOG%" 2>&1
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
