@echo off
setlocal
set EXAMPLE=example_json_read_traverse
set EXAMPLE2=example_json_pointer_min
set EXAMPLE3=example_json_patch_min
set EXAMPLE4=example_fluent_min
set EXE_DIR=%~dp0bin
set LIB_DIR=%~dp0lib
if not exist "%EXE_DIR%" mkdir "%EXE_DIR%"
if not exist "%LIB_DIR%" mkdir "%LIB_DIR%"

pushd %~dp0
rem Resolve lazbuild
set "LAZBUILD=..\..\tools\lazbuild.bat"
if not exist "%LAZBUILD%" (
  echo [WARN] tools\lazbuild.bat not found, falling back to lazbuild in PATH
  set "LAZBUILD=lazbuild"
)
rem Build example 1 using lazbuild
call "%LAZBUILD%" "%EXAMPLE%.lpi" --bm=Debug
if errorlevel 1 (
  echo Build failed (example 1).
  popd
  exit /b 1
)

call "%EXE_DIR%\%EXAMPLE%.exe"
if errorlevel 1 (
  echo Example 1 run failed with exit code %ERRORLEVEL%.
  popd
  exit /b %ERRORLEVEL%
)

rem Build example 2 (JSON Pointer minimal)
call "%LAZBUILD%" "%EXAMPLE2%.lpi" --bm=Debug
if errorlevel 1 (
  echo Build failed (example 2).
  popd
  exit /b 1
)

if not exist "..\..\todo\fafafa.core.json\logs" mkdir "..\..\todo\fafafa.core.json\logs"
call "%EXE_DIR%\%EXAMPLE2%.exe" > "..\..\todo\fafafa.core.json\logs\pointer_min_run.txt" 2>&1
if errorlevel 1 (
  echo Example 2 run failed with error %ERRORLEVEL%.
  popd
  exit /b %ERRORLEVEL%
)

rem Build example 3 (JSON Patch minimal)
call "%LAZBUILD%" "%EXAMPLE3%.lpi" --bm=Debug
if errorlevel 1 (
  echo Build failed (example 3).
  popd
  exit /b 1
)

call "%EXE_DIR%\%EXAMPLE3%.exe" > "..\..\todo\fafafa.core.json\logs\patch_min_run.txt" 2>&1
if errorlevel 1 (
  echo Example 3 run failed with error %ERRORLEVEL%.
  popd
  exit /b %ERRORLEVEL%
)

rem Build example 4 (Fluent minimal)
call "%LAZBUILD%" "%EXAMPLE4%.lpi" --bm=Debug
if errorlevel 1 (
  echo Build failed (example 4).
  popd
  exit /b 1
)

call "%EXE_DIR%\%EXAMPLE4%.exe" > "..\..\todo\fafafa.core.json\logs\fluent_min_run.txt" 2>&1
if errorlevel 1 (
  echo Example 4 run failed with error %ERRORLEVEL%.
  popd
  exit /b %ERRORLEVEL%
)

rem Build example 5 (Hot Path minimal)
call "%LAZBUILD%" "example_hot_path_min.lpi" --bm=Debug
if errorlevel 1 (
  echo Build failed (example 5 - hot path).
  popd
  exit /b 1
)

call "%EXE_DIR%\example_hot_path_min.exe" > "..\..\todo\fafafa.core.json\logs\hot_path_min_run.txt" 2>&1
if errorlevel 1 (
  echo Example 5 run failed with error %ERRORLEVEL%.
  popd
  exit /b %ERRORLEVEL%
)


rem Build minimal flag examples
for %%F in (example_reader_flags.lpi example_stop_when_done.lpi) do (
  call "%LAZBUILD%" "%%F" --bm=Debug
  if errorlevel 1 (
    echo Build failed (%%F).
    popd
    exit /b 1
  )
)

"%EXE_DIR%\example_reader_flags.exe" || (popd & exit /b 1)
"%EXE_DIR%\example_stop_when_done.exe" || (popd & exit /b 1)

popd
exit /b 0

