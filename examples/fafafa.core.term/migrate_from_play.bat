@echo off
setlocal

REM Build all .lpr examples in this folder with FPC, and .lpi via lazbuild
set "ROOT=%~dp0"
set "LAZBUILD=%ROOT%..\..\tools\lazbuild.bat"
set "BIN=%ROOT%bin"
set "LIB=%ROOT%lib"

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"

REM Build .lpi projects first (if any)
for %%F in ("%ROOT%*.lpi") do (
  echo Building LPI: %%~nxF
  call "%LAZBUILD%" "%%F" || goto :FAIL
)

REM Build .lpr files with FPC
for %%F in ("%ROOT%*.lpr") do (
  echo Building LPR: %%~nxF
  fpc -Mobjfpc -Fu"%ROOT%..\..\src" -FE"%BIN%" -FU"%LIB%" "%%F" || goto :FAIL
)

echo.
echo All examples built successfully into %BIN%
exit /b 0

:FAIL
echo Build failed.
exit /b 1

