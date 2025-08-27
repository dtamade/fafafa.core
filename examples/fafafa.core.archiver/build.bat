@echo off
setlocal ENABLEDELAYEDEXPANSION

rem Optional: specify a custom FPC path via FPC_EXE env var
set FPC_EXE="%FPC_EXE%"
if "%FPC_EXE%"=="" set FPC_EXE=fpc

set SRC_DIR=..\..\src
set OUT_DIR=bin
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo Building examples with %FPC_EXE%

%FPC_EXE% -B -MObjFPC -Scghi -gl -gh -vewnhibq -Fu"%SRC_DIR%" -FE"%OUT_DIR%" CreateTarGz.pas || goto :eof
%FPC_EXE% -B -MObjFPC -Scghi -gl -gh -vewnhibq -Fu"%SRC_DIR%" -FE"%OUT_DIR%" ExtractTarGz.pas || goto :eof

echo.
echo Done. Binaries are in %OUT_DIR%\
endlocal

