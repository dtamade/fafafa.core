@echo on
setlocal
pushd %~dp0

REM Build minimal tar.gz example
fpc -MObjFPC -Scghi -gl -gh -vewnhibq -Fu..\..\..\src -FUlib example_minimal_targz.lpr
if errorlevel 1 goto :eof

example_minimal_targz.exe

popd
endlocal

