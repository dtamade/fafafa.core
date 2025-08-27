@echo on
setlocal
pushd %~dp0

REM Build minimal tar example
fpc -MObjFPC -Scghi -gl -gh -vewnhibq -Fu..\..\..\src -FUlib example_minimal_tar.lpr
if errorlevel 1 goto :eof

example_minimal_tar.exe

popd
endlocal

