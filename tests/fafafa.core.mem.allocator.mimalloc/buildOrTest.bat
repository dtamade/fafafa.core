@echo off
setlocal
REM Build or run tests for fafafa.core.mem.allocator.mimalloc
set PROJ=%~dp0
pushd "%PROJ%"

REM Build Debug with heap tracing enabled (per LPI config)
lazbuild fafafa.core.mem.allocator.mimalloc.test.lpi --bm=Debug || goto :eof

REM Run tests (plain format). Copy mimalloc.dll if exists in repo tmp_build for convenience
if exist "..\..\tmp_build\mimalloc.dll" copy /Y "..\..\tmp_build\mimalloc.dll" bin\mimalloc.dll >nul 2>&1
if exist "..\..\tmp_build\mimalloc-redirect.dll" copy /Y "..\..\tmp_build\mimalloc-redirect.dll" bin\mimalloc-redirect.dll >nul 2>&1

bin\fafafa.core.mem.allocator.mimalloc.test_debug.exe --all --format=plain || exit /b 1

popd
endlocal

