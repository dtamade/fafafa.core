@echo off
setlocal ENABLEDELAYEDEXPANSION
cd /d "%~dp0"

echo === BuildExamples (fafafa.core.fs) ===

set "PROJECT_ROOT=%~dp0..\.."
set "SRC=%PROJECT_ROOT%\src"
set "BIN=%CD%\bin"
set "LIB=%CD%\lib"
set "LAZBUILD=%PROJECT_ROOT%\tools\lazbuild.bat"

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"

echo Source: %SRC%
echo Bin:     %BIN%
echo Lib:     %LIB%

echo.
echo [1/8] Build example_fs.lpi via lazbuild (Release/default)...
call "%LAZBUILD%" "example_fs.lpi"
if %ERRORLEVEL% NEQ 0 (
  echo WARNING: lazbuild failed or not available for example_fs.lpi, will continue.
)

echo.
echo Using FPC for standalone .lpr examples...
set "FPC_FLAGS=-Mobjfpc -Scghi -gl -O2 -Fu%SRC% -FE%BIN% -FU%LIB%"

set BUILD_FAILED=

call :build_one example_fs_basic.lpr
call :build_one example_fs_advanced.lpr
call :build_one example_fs_performance.lpr
call :build_one example_fs_benchmark.lpr
call :build_one example_fs_path.lpr
call :build_one example_fs_showcase.lpr
call :build_one benchmark_fs_scan_stat.lpr
rem Build copytree symlink follow example (standalone folder)
call example_copytree_follow\buildOrRun.bat || echo WARNING: example_copytree_follow build/run skipped
rem If built, copy the exe into main bin for RunExamples.bat
if exist "example_copytree_follow\bin\example_copytree_follow.exe" copy /Y "example_copytree_follow\bin\example_copytree_follow.exe" "%BIN%\example_copytree_follow.exe" >nul

echo === BuildExamples done ===
if defined BUILD_FAILED (
  echo Some examples failed to build. See logs above.
  exit /b 1
) else (
  echo All examples built successfully.
  exit /b 0
)

:endlocal
endlocal
exit /b 0

:build_one
echo Building %1 ...
fpc %FPC_FLAGS% "%~1"
if %ERRORLEVEL% NEQ 0 (
  echo FAILED: %~1
  set BUILD_FAILED=1
) else (
  for %%X in ("%~n1.exe") do echo SUCCESS: %%~nX
)
echo.
exit /b 0

