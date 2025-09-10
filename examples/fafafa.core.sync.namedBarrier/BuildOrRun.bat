@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Build or Run - namedBarrier Examples
echo ========================================

set SRC_DIR=..\..\src
set BIN_DIR=..\..\bin

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

if "%1"=="run" goto :RUN

echo Building examples...
fpc -Mobjfpc -Sh -O1 -g -gl -Fu"%SRC_DIR%" -FE"%BIN_DIR%" example_basic_usage.pas || goto :ERR
fpc -Mobjfpc -Sh -O1 -g -gl -Fu"%SRC_DIR%" -FE"%BIN_DIR%" example_cross_process.pas || goto :ERR

echo Build success.
echo You can run:
echo   %BIN_DIR%\example_basic_usage.exe
echo   %BIN_DIR%\example_cross_process.exe coordinator
echo   %BIN_DIR%\example_cross_process.exe 1 ^| 2 ^| 3
goto :END

:RUN
if "%2"=="basic" (
  "%BIN_DIR%\example_basic_usage.exe"
) else (
  echo Usage: BuildOrRun.bat [run basic]
  echo        BuildOrRun.bat  (build only)
)
goto :END

:ERR
echo Build failed.
exit /b 1

:END
endlocal

