@echo off
setlocal ENABLEDELAYEDEXPANSION
pushd "%~dp0"

set "FINAL_RC=0"
set "LAZBUILD=..\..\tools\lazbuild.bat"
set "PROJECT=%CD%\fafafa.core.mem.pool.fixed.test.lpi"
set "BIN=%CD%\bin"
set "LIB=%CD%\lib"

if exist "%BIN%" rmdir /s /q "%BIN%"
if exist "%LIB%" rmdir /s /q "%LIB%"
mkdir "%BIN%" 2>nul
mkdir "%LIB%" 2>nul

if not exist "%LAZBUILD%" (
  echo [WARN] tools\lazbuild.bat not found, trying PATH lazbuild
  set "LAZBUILD=lazbuild"
)

echo Building project: %PROJECT% ...
call "%LAZBUILD%" "%PROJECT%" --build-mode=Debug
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo [ERROR] Build failed with error code %RC%.
  set "FINAL_RC=%RC%"
  goto END
)

echo.
echo Build successful.
echo.

rem --- test mode routing ---
if /i "%~1"=="test" goto DO_TEST
echo To run tests, call this script with the 'test' parameter.
goto END

:DO_TEST
set "EXE=%BIN%\fafafa.core.mem.pool.fixed.test.exe"
if exist "%EXE%" goto RUN_TEST
echo [WARN] Preferred test EXE not found: %EXE%
for /f "delims=" %%E in ('dir /b /a:-d "%BIN%\*.exe" 2^>nul') do (
  set "EXE=%BIN%\%%E"
  goto RUN_TEST
)
echo [ERROR] No test EXE found in "%BIN%"
set "FINAL_RC=2"
goto END

:RUN_TEST
echo Running test: "%EXE%"
"%EXE%" --all --format=plainnotiming
set "FINAL_RC=%ERRORLEVEL%"

:END
popd
endlocal & exit /b %FINAL_RC%
