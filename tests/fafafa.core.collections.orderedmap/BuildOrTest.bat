@echo off
setlocal

rem Resolve project root regardless of current working directory
rem %~dp0 -> folder of this script (tests\fafafa.core.collections.orderedmap\)
set ROOT=%~dp0\..\..

pushd "%ROOT%\tests\fafafa.core.collections.orderedmap" || goto :eof

rem Build tests
lazbuild --build-mode=Debug tests_orderedmap.lpi || goto :eof

rem Run tests
"%ROOT%\bin\tests_orderedmap.exe" --all --format=plain

popd
endlocal
