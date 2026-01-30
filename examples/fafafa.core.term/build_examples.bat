@echo off

set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=..\..\tools\lazbuild.bat"
set "BIN_DIR=bin"

REM Ensure running inside the examples folder
pushd "%SCRIPT_DIR%" >nul

echo Building fafafa.core.term examples...
echo ====================================

echo.
echo Building example_term.lpi...
call "%LAZBUILD%" "example_term.lpi"
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for example_term.lpi
    goto FAIL
)

REM Build migrated advanced_test via lazbuild (LPI)
if exist "advanced_test.lpi" (
  echo.
  echo Building advanced_test.lpi...
  call "%LAZBUILD%" "advanced_test.lpi"
  if %ERRORLEVEL% NEQ 0 (
      echo Build failed for advanced_test.lpi
      goto FAIL
  )
)


echo.
echo Building basic_example.lpr...
fpc -Fu..\..\src -FE%BIN_DIR% -FU..\..\lib basic_example.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for basic_example.lpr
    goto FAIL
)

echo.
echo Building keyboard_example.lpr...
fpc -Fu..\..\src -FE%BIN_DIR% -FU..\..\lib keyboard_example.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for keyboard_example.lpr
    goto FAIL
)


REM Build budget compare demo
echo.
echo Building events_collect_budget_compare.lpr...
fpc -Fu..\..\src -FE%BIN_DIR% -FU..\..\lib events_collect_budget_compare.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for events_collect_budget_compare.lpr
    goto FAIL
)

echo.
echo Building events_collect_statusbar_dynamic.lpr...
fpc -Fu..\..\src -FE%BIN_DIR% -FU..\..\lib events_collect_statusbar_dynamic.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for events_collect_statusbar_dynamic.lpr
    goto FAIL
)


echo.
echo Building text_editor.lpr...
fpc -Fu..\..\src -FE%BIN_DIR% -FU..\..\lib text_editor.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for text_editor.lpr
    goto FAIL
)

echo.
echo Building progress_simple_demo.lpr...
fpc -Fu..\..\src -FE%BIN_DIR% -FU..\..\lib progress_simple_demo.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for progress_simple_demo.lpr
    goto FAIL
)

REM Skipped menu_system.lpr (missing UI dependencies)

echo.
echo Building theme_demo.lpr...
fpc -Fu..\..\src -FE%BIN_DIR% -FU..\..\lib theme_demo.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for theme_demo.lpr
    goto FAIL
)

REM Skipped layout_demo.lpr (requires layout UI module)

echo.
echo Building unicode_demo.lpr...
fpc -Fu..\..\src -FE%BIN_DIR% -FU..\..\lib unicode_demo.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for unicode_demo.lpr
    goto FAIL
)

echo.
echo Building recorder_demo.lpr...
fpc -Fu..\..\src -FE%BIN_DIR% -FU..\..\lib -Fu. recorder_demo.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for recorder_demo.lpr
    goto FAIL
)

echo.
echo Building widgets_demo.lpr...
fpc -Fu..\..\src -FE%BIN_DIR% -FU..\..\lib widgets_demo.lpr
if %ERRORLEVEL% NEQ 0 (
    echo Build failed for widgets_demo.lpr
    goto FAIL
)

echo.

:END
popd >nul

echo All examples built successfully!
echo.
goto PRINT_LIST

:FAIL
echo Some examples failed to build.
echo.
goto PRINT_LIST

:PRINT_LIST
echo Available executables in %BIN_DIR%:
echo   - example_term.exe      (Complete feature demonstration)
echo   - basic_example.exe     (Basic terminal control)
echo   - keyboard_example.exe  (Keyboard input handling)
echo   - text_editor.exe       (Simple text editor)
echo   - progress_simple_demo.exe     (Progress bars and spinners)
REM   - menu_system.exe       (Interactive menu system) [skipped]
echo   - theme_demo.exe        (Theme system demonstration)
REM   - layout_demo.exe       (Layout system demonstration) [skipped]
echo   - unicode_demo.exe      (Unicode support demonstration)
echo   - recorder_demo.exe     (Recording and playback demonstration)
echo   - widgets_demo.exe      (Terminal widgets demonstration)
echo.

:END
