@echo off
setlocal
REM Build or run tests for fafafa.core.mem.manager.rtl
set PROJ=%~dp0
pushd "%PROJ%"

lazbuild fafafa.core.mem.manager.rtl.test.lpi --bm=Debug || goto :eof

bin\fafafa.core.mem.manager.rtl.test_debug.exe --all --format=plain

popd
endlocal

