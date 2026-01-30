@echo off
setlocal

set ROOT=%~dp0\..\..
set BIN=%ROOT%\bin

echo Building example_socket...
call "%ROOT%\tools\lazbuild.bat" "%~dp0\example_socket.lpi"
if errorlevel 1 goto :eof

"%BIN%\example_socket.exe" %*

endlocal

