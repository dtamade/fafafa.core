@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "BIN=%SCRIPT_DIR%bin\paste_storage_demo.exe"

if not exist "%BIN%" (
  echo [INFO] paste_storage_demo.exe not found. Trying to build examples...
  call "%SCRIPT_DIR%build_examples.bat" || goto :END
)

if exist "%BIN%" (
  echo Running paste_storage_demo.exe ...
  "%BIN%"
) else (
  echo [ERROR] Unable to find or build paste_storage_demo.exe
)

:END
endlocal

