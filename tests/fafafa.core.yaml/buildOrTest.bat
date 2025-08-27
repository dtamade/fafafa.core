@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%"

set "LAZBUILD=..\..\tools\lazbuild.bat"
if not exist "%LAZBUILD%" (
  echo [WARN] tools\lazbuild.bat not found, falling back to lazbuild in PATH
  set "LAZBUILD=lazbuild"
)
set "FPC=fpc"
set "PROJECT=fafafa.core.yaml.test.lpi"
set "EXE=bin\fafafa.core.yaml.test.exe"

if exist bin rmdir /s /q bin
if exist lib rmdir /s /q lib
mkdir bin 2>nul
mkdir lib 2>nul

REM Prefer lazbuild if available
where lazbuild >nul 2>&1
if %errorlevel%==0 (
  echo Building with lazbuild...
  call "%LAZBUILD%" "%PROJECT%" --build-mode=Debug
  if %ERRORLEVEL% NEQ 0 (
    echo Build failed with error code %ERRORLEVEL%.
    set "FINAL_RC=%ERRORLEVEL%"
    goto END
  )
) else (
  echo [WARN] lazbuild not found, compiling with fpc directly...
  %FPC% -Mobjfpc -Sh -O3 -g -gl -gh -Ci -Co -Cr -Ct -I../../src -Fu../../src -Fu. -FUlib -FEbin fafafa.core.yaml.test.lpr
  if %ERRORLEVEL% NEQ 0 (
    echo Compilation failed with error code %ERRORLEVEL%.
    set "FINAL_RC=%ERRORLEVEL%"
    goto END
  )
)

echo.
echo Build successful.

echo Running tests...
"%EXE%" --all --format=plain
set "FINAL_RC=%ERRORLEVEL%"

echo.
if %FINAL_RC% EQU 0 (
  echo Tests passed!
) else (
  echo Tests failed! Error code: %FINAL_RC%
)

:END
popd
endlocal
exit /b %FINAL_RC%
