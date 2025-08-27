@echo off
setlocal
set PROJ=%~dp0
pushd "%PROJ%"

REM Build Debug
lazbuild fafafa.core.mem.manager.rtl.play.lpi --bm=Debug || goto :eof

REM Run
bin\fafafa.core.mem.manager.rtl.play.exe

popd
endlocal

