@echo off
setlocal

set ROOT=%~dp0
set PROJ=%ROOT%examples.lpi
set EXE=%ROOT%bin\examples.exe

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

echo [INFO] Building examples project with %LAZBUILD%
"%LAZBUILD%" "%PROJ%"
if errorlevel 1 (
  echo [ERROR] Build failed
  exit /b 1
)

if exist "%EXE%" (
  echo [INFO] Running examples ...
  "%EXE%"
) else (
  echo [WARN] Examples exe not found at %EXE%
)

rem ---- Thread module quick entries ----
if exist "%ROOT%fafafa.core.thread\BuildOrRun_CancelBestPractices.bat" (
  echo [INFO] Running thread cancel best practices ...
  call "%ROOT%fafafa.core.thread\BuildOrRun_CancelBestPractices.bat"
)

if exist "%ROOT%fafafa.core.thread\BuildOrRun_BenchMatrix.bat" (
  echo [INFO] Running thread bench matrix ...
  call "%ROOT%fafafa.core.thread\BuildOrRun_BenchMatrix.bat"
)


