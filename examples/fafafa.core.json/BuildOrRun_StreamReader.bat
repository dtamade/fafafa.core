@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
set "BIN_DIR=%SCRIPT_DIR%bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
set "LIB_DIR=%SCRIPT_DIR%lib"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

rem Prepare a tiny JSON input in BIN_DIR so the exe can find it via CWD
> "%BIN_DIR%\example_json_input.json" echo {"hello":"world","n":123}

set "FPC=fpc"
where %FPC% >nul 2>nul || (
  echo [ERROR] fpc not found in PATH. Please install FPC or configure lazbuild project.
  exit /b 1
)

set "SRC_DIR=%SCRIPT_DIR%..\..\src"
set "OUT_EXE=%BIN_DIR%\example_stream_reader_min.exe"

echo [BUILD] example_stream_reader_min.lpr via FPC
"%FPC%" -B -O2 -FE"%BIN_DIR%" -FU"%LIB_DIR%" -Fu"%SRC_DIR%" -o"%OUT_EXE%" "%SCRIPT_DIR%example_stream_reader_min.lpr"
if errorlevel 1 (
  echo Build failed
  exit /b 1
)

echo [RUN] example_stream_reader_min.exe (cwd=BIN_DIR)
pushd "%BIN_DIR%"
"%OUT_EXE%"
set "EC=%ERRORLEVEL%"
popd
if not "%EC%"=="0" echo [RUN] failed code=%EC% & exit /b %EC%

echo Done.
endlocal

