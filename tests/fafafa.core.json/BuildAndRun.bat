@echo off
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

rem Paths
set FPC_EXE=D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe
set SRC=tests\fafafa.core.json\tests_json.lpr
set OUTDIR=tests\fafafa.core.json\bin
set OUTEXE=%OUTDIR%\tests_json.exe

if not exist "%FPC_EXE%" (
  echo FPC not found at %FPC_EXE%
  echo Please adjust FPC_EXE path in this script.
  exit /b 2
)

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

rem Compile
"%FPC_EXE%" -MObjFPC -Scghi -O1 -g -gl -vewnhibq ^
  -Fi"tests\fafafa.core.json\lib\x86_64-win64" ^
  -Fi"src" ^
  -Fu"tests\fafafa.core.json" ^
  -Fu"src" ^
  -FE"%OUTDIR%" -o"%OUTEXE%" "%SRC%"
if errorlevel 1 (
  echo Build failed. ExitCode=%ERRORLEVEL%
  exit /b %ERRORLEVEL%
)

echo Running tests...
"%OUTEXE%" --all --progress
set RUN_EXIT=%ERRORLEVEL%

set LOGFILE=%OUTDIR%\tests_json.out.txt
if exist "%LOGFILE%" (
  echo ===== Log: %LOGFILE% =====
  type "%LOGFILE%"
  echo ===== End of Log =====
) else (
  echo Log file not found: %LOGFILE%
)

exit /b %RUN_EXIT%

