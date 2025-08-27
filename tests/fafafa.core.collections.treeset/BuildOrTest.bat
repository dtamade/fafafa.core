@echo off
setlocal

REM BuildOrTest for fafafa.core.collections.treeSet
set SCRIPT_DIR=%~dp0
set PROJECT=%SCRIPT_DIR%tests_treeSet.lpi
set EXECUTABLE=%SCRIPT_DIR%bin\tests_treeSet.exe

if not exist "%SCRIPT_DIR%bin" mkdir "%SCRIPT_DIR%bin"
if not exist "%SCRIPT_DIR%lib" mkdir "%SCRIPT_DIR%lib"

echo Building: %PROJECT%
lazbuild --build-mode=Debug "%PROJECT%"
if errorlevel 1 (
  echo Build failed.
  exit /b 1
)

if exist "%EXECUTABLE%" (
  echo Running tests...
  "%EXECUTABLE%"
  exit /b %errorlevel%
) else (
  echo Executable not found: %EXECUTABLE%
  exit /b 1
)

