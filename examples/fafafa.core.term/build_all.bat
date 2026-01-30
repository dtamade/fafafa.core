@echo off
setlocal EnableDelayedExpansion

set "ROOT=%~dp0"
pushd "%ROOT%" >nul

set "LAZBUILD=%ROOT%..\..\tools\lazbuild.bat"
set "BIN=%ROOT%bin"
set "LIB=%ROOT%lib"

if not exist "%BIN%" mkdir "%BIN%"
if not exist "%LIB%" mkdir "%LIB%"

set "SKIP= recorder_demo.lpr layout_demo.lpr menu_system.lpr "
set "SKIP=!SKIP! example_facade_beta.lpr example_facade_frame_loop.lpr "


set "FAILS="

REM 1) Build all .lpi via lazbuild
for %%F in ("%ROOT%*.lpi") do (
  echo [LPI] Building %%~nxF
  call "%LAZBUILD%" "%%F"
  if errorlevel 1 (
    echo [FAIL] %%~nxF
    set "FAILS=%FAILS% %%~nxF"
  )
)

REM 2) Build all .lpr that have no matching .lpi
for %%F in ("%ROOT%*.lpr") do (
  if not exist "%%~nF.lpi" (
    set "FN=%%~nxF"
    echo !SKIP! | findstr /I /C:" !FN! " >nul
    if errorlevel 1 (
      echo [LPR] Building !FN!
      fpc -Mobjfpc -Fi"%ROOT%..\..\src" -Fu"%ROOT%..\..\src" -FE"%BIN%" -FU"%LIB%" "%%F"
      if errorlevel 1 (
        echo [FAIL] !FN!
        set "FAILS=!FAILS! !FN!"
      )
    ) else (
      echo [SKIP] !FN!
    )
  )
)

echo.
if "%FAILS%"=="" (
  echo [OK] All examples built successfully into %BIN%
) else (
  echo [WARN] Some builds failed:
  echo   %FAILS%
)

popd >nul
exit /b 0

