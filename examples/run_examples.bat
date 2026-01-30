@echo off
setlocal

set ROOT=%~dp0
set EXAMPLE=%ROOT%fafafa.core.json\example_forin_and_ptr_best_practices.lpr
set EXE=%ROOT%fafafa.core.json\example_forin_and_ptr_best_practices.exe

set LAZBUILD=
for /f "delims=" %%i in ('where lazbuild 2^>NUL') do (
  set LAZBUILD=%%i
  goto :found
)
:found
if not defined LAZBUILD if exist "C:\Program Files\Lazarus\lazbuild.exe" set LAZBUILD=C:\Program Files\Lazarus\lazbuild.exe
if not defined LAZBUILD if exist "C:\Lazarus\lazbuild.exe" set LAZBUILD=C:\Lazarus\lazbuild.exe

if not defined LAZBUILD (
  echo [ERROR] lazbuild not found. Please install Lazarus or add lazbuild to PATH.
  exit /b 1
)

echo [INFO] Building example with %LAZBUILD%
"%LAZBUILD%" "%EXAMPLE%"
if errorlevel 1 (
  echo [ERROR] Build failed
  exit /b 1
)

if exist "%EXE%" (
  echo [INFO] Running example ...
  "%EXE%"
) else (
  echo [WARN] Example exe not found at %EXE%
)

