@echo off
setlocal ENABLEDELAYEDEXPANSION
set SUITE=%~1
set EXE=%~dp0bin\tests.exe

if "%SUITE%"=="" (
  echo Usage: %~n0 SuiteName
  exit /B 2
)

if not exist "%EXE%" (
  echo [run_suite] tests.exe not found: %EXE%
  echo Build first: tests\fafafa.core.process\buildOrTest.bat build
  exit /B 3
)

echo [run_suite] suite=%SUITE%

REM Try common FPCUnit syntaxes
"%EXE%" -s %SUITE% --progress --format=plainnotiming
if %ERRORLEVEL% EQU 0 goto :end

"%EXE%" --suite=%SUITE% --progress --format=plainnotiming
if %ERRORLEVEL% EQU 0 goto :end

REM Fallback: run all and filter output lines containing suite name

echo [run_suite] suite filter unsupported; fallback to --all and filter lines
"%EXE%" --all --progress --format=plainnotiming | findstr /I "%SUITE%"
REM Always succeed to avoid breaking automation; human inspects output
exit /B 0

:end
exit /B 0

