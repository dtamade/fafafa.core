@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "PROJECT=%SCRIPT_DIR%example_forwardList.lpi"
set "DEBUG_EXE=%SCRIPT_DIR%..\..\bin\example_forwardList_debug.exe"
set "RELEASE_EXE=%SCRIPT_DIR%..\..\bin\example_forwardList.exe"

echo Building project: %PROJECT% (Debug)...
call "%LAZBUILD%" "%PROJECT%" --build-mode=Debug

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo Build failed with error code %ERRORLEVEL%.
  goto END
)

echo.
echo Build successful.

if /i "%1"=="run" (
  echo Running example (prefer Debug executable)...
  if exist "%DEBUG_EXE%" (
    "%DEBUG_EXE%"
  ) else if exist "%RELEASE_EXE%" (
    "%RELEASE_EXE%"
  ) else (
    echo Executable not found in ..\..\bin\
    echo You can build Release with: BuildOrRun.bat release
  )
) else if /i "%1"=="release" (
  echo Building project: %PROJECT% (Release)...
  call "%LAZBUILD%" "%PROJECT%" --build-mode=Release
  if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build (Release) failed with error code %ERRORLEVEL%.
    goto END
  )
  echo.
  echo Build (Release) successful.
  echo Output: %RELEASE_EXE%
) else (
  echo.
  echo Usage:
  echo   BuildOrRun.bat run       ^(Build Debug and run executable^)
  echo   BuildOrRun.bat release   ^(Build Release executable^)
)

:END
endlocal

