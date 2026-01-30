@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"
set "LAZBUILD_PATH=lazbuild"
set "PROJECT=fafafa.core.args.config.test.lpi"
set "TEST_EXECUTABLE=bin\fafafa.core.args.config.test.exe"
set "CLEAN_DIRS=lib bin"

set "EXIT_ERR=1"

if /i "%1"=="clean" goto :CLEAN
if /i "%1"=="rebuild" ( set "DO_CLEAN=1" )

if not exist "%LAZBUILD%" (
  where lazbuild >nul 2>nul
  if %ERRORLEVEL% EQU 0 (
    set "LAZBUILD_PATH=lazbuild"
  ) else (
    echo [WARN] lazbuild not found.
  )
)

if defined DO_CLEAN (
  for %%D in (%CLEAN_DIRS%) do if exist "%%D" rmdir /s /q "%%D" 2>nul
)

if exist "%LAZBUILD%" (
  call "%LAZBUILD%" --build-all "%PROJECT%"
  set "EXIT_ERR=%ERRORLEVEL%"
) else (
  where lazbuild >nul 2>nul
  if %ERRORLEVEL% EQU 0 (
    lazbuild --build-all "%PROJECT%"
    set "EXIT_ERR=%ERRORLEVEL%"
  ) else (
    echo [WARN] tools\lazbuild.bat not found and lazbuild not in PATH.
  )
)

if /i "%1"=="test" (
  if exist "%TEST_EXECUTABLE%" (
    "%TEST_EXECUTABLE%" -a -p --format=plain
    set "EXIT_ERR=!ERRORLEVEL!"
  ) else (
    echo [ERROR] Test executable not found: %TEST_EXECUTABLE%
    if !EXIT_ERR! EQU 0 set "EXIT_ERR=1"
  )
)

popd
endlocal
exit /b !EXIT_ERR!

:CLEAN
for %%D in (%CLEAN_DIRS%) do if exist "%%D" rmdir /s /q "%%D" 2>nul
exit /b 0

