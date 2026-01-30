@echo off
setlocal
cd /d "%~dp0"

set "LAZBUILD=..\..\tools\lazbuild.bat"
set "PROJECT=ui_showcase.lpi"
set "EXE=bin\ui_showcase.exe"

if not exist "%LAZBUILD%" (
  echo ERROR: lazbuild tool not found: %LAZBUILD%
  exit /b 1
)

if not exist "bin" mkdir "bin"
if not exist "lib" mkdir "lib"

echo Building %PROJECT% ...
call "%LAZBUILD%" "%PROJECT%"
if %ERRORLEVEL% NEQ 0 (
  echo Build failed with code %ERRORLEVEL%
  exit /b %ERRORLEVEL%
)

echo.
echo Build successful.

if /i "%1"=="run" (
  if exist "%EXE%" (
    echo Running %EXE% ...
    "%EXE%"
  ) else (
    echo Executable not found: %EXE%
    exit /b 1
  )
) else (
  echo To run: BuildOrRun_UI_Showcase.bat run
)

