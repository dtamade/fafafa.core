@echo off
setlocal
set PROJ=%~dp0
pushd "%PROJ%"

REM Build Debug
lazbuild fafafa.core.mem.manager.mimalloc.play.lpi --bm=Debug || goto :eof

REM Copy mimalloc DLL if available from repo tmp_build
if exist "..\..\tmp_build\mimalloc.dll" copy /Y "..\..\tmp_build\mimalloc.dll" bin\mimalloc.dll >nul 2>&1

REM Run
bin\fafafa.core.mem.manager.mimalloc.play.exe

popd
endlocal

