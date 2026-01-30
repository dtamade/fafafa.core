@echo off
setlocal
REM Build or run tests for fafafa.core.mem.manager.crt
set PROJ=%~dp0
pushd "%PROJ%"

lazbuild fafafa.core.mem.manager.crt.test.lpi --bm=Debug || goto :eof

bin\fafafa.core.mem.manager.crt.test_debug.exe --all --format=plain

popd
endlocal

