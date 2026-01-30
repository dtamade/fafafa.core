@echo off
rem JSON Pointer 注意：空指针 "" 返回根；单独 "/" 与双斜杠空 token（如 "/a//x"）非法返回 nil；~0→~，~1→/
setlocal
set "SCRIPT_DIR=%~dp0"
set "SRC_DIR=%SCRIPT_DIR%..\..\src"
set "BIN_DIR=%SCRIPT_DIR%bin"
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
set "LIB_DIR=%SCRIPT_DIR%lib"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"


rem Resolve lazbuild once
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
if not exist "%LAZBUILD%" (
  echo [WARN] tools\lazbuild.bat not found, falling back to lazbuild in PATH
  set "LAZBUILD=lazbuild"
)

echo Building minimal examples with lazbuild...
for %%F in (example_reader_flags.lpi example_stop_when_done.lpi) do (
  echo   %%F
  call "%LAZBUILD%" "%SCRIPT_DIR%%%F" --bm=Debug
  if errorlevel 1 (
    echo Build failed: %%F
    exit /b 1
  )
)

echo Running minimal examples...
"%BIN_DIR%\example_reader_flags.exe" || (echo [RUN] example_reader_flags FAILED code=%ERRORLEVEL% & exit /b %ERRORLEVEL%)
"%BIN_DIR%\example_stop_when_done.exe" || (echo [RUN] example_stop_when_done FAILED code=%ERRORLEVEL% & exit /b %ERRORLEVEL%)

echo Done.
endlocal

