@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "EXE=%SCRIPT_DIR%quick_example.exe"

rem Prefer a fixed FPC path if present; otherwise fallback to PATH's fpc
set "FPC_EXE=D:\devtools\lazarus\trunk\fpc\bin\x86_64-win64\fpc.exe"
if exist "%FPC_EXE%" (
  set "FPC_CMD=%FPC_EXE%"
) else (
  set "FPC_CMD=fpc"
)

if not exist "%EXE%" (
  pushd "%SCRIPT_DIR%"
  echo Building quick_example with: %FPC_CMD%
  "%FPC_CMD%" -MObjFPC -Scaghi -O1 -vewnhibq -Fu"..\..\..\src" quick_example.lpr
  if errorlevel 1 (
    echo Build failed with exit code %errorlevel%.
    popd
    exit /b %errorlevel%
  )
  popd
)

if exist "%EXE%" (
  echo Running quick_example...
  "%EXE%"
) else (
  echo Build failed: quick_example.exe not found.
  exit /b 1
)

