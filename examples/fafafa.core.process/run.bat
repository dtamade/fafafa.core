@echo off
setlocal
set DIR=%~dp0
pushd "%DIR%"

if not exist bin\example_process.exe (
  call build.bat
)

if exist bin\example_process.exe (
  echo [Run] example_process.exe
  bin\example_process.exe
) else (
  echo [ERROR] Executable not found. Build failed?
)

popd
endlocal

@echo off

REM ===================================================================
REM fafafa.core.process Example Program Run Script (Windows)
REM ===================================================================

echo.
echo ===================================================================
echo fafafa.core.process Example Program Run Script
echo ===================================================================

REM Set paths
SET SCRIPT_DIR=%~dp0
SET OUTPUT_DIR=%SCRIPT_DIR%bin
SET EXECUTABLE_PATH=%OUTPUT_DIR%\example_process.exe

echo Target executable: %EXECUTABLE_PATH%
echo.

REM Check if executable file exists
if not exist "%EXECUTABLE_PATH%" (
    echo [WARNING] Executable file not found, starting auto-build...
    echo.

    REM Call build script
    call "%SCRIPT_DIR%build.bat"

    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Build failed, cannot run example program
        goto ERROR_END
    )

    echo.
    echo [OK] Build completed, continuing to run...
    echo.
)

REM Check executable file again
if not exist "%EXECUTABLE_PATH%" (
    echo [ERROR] Cannot find executable file: %EXECUTABLE_PATH%
    goto ERROR_END
)

echo ===================================================================
echo Running fafafa.core.process example program
echo ===================================================================
echo.

REM Switch to output directory and run program
pushd "%OUTPUT_DIR%"
example_process.exe
SET RUN_RESULT=%ERRORLEVEL%
popd

echo.
echo ===================================================================

if %RUN_RESULT% EQU 0 (
    echo [OK] Example program ran successfully!
) else (
    echo [ERROR] Example program failed, exit code: %RUN_RESULT%
)

REM === Optional: run AutoDrain demo ===
echo.
echo [INFO] You can run AutoDrain demo via:
echo   run_autodrain.bat


REM === Optional: run Combined vs CaptureAll demo ===
echo.
echo [INFO] You can run Combined vs CaptureAll demo via:
echo   run_combined_vs_capture_all.bat


REM === Optional: run Silent vs Interactive demo ===
echo.
echo [INFO] You can run Silent vs Interactive demo via:
echo   run_silent_interactive.bat


REM === Optional: run Background vs Foreground demo ===
echo.
echo [INFO] You can run Background vs Foreground demo via:
echo   run_background_foreground.bat


REM === Optional: run Timeout + KillOnTimeout demo ===
echo.
echo [INFO] You can run Timeout + KillOnTimeout demo via:
echo   run_timeout_killon_timeout.bat


REM === Optional: run Process Group Policy demo (Windows) ===
echo.
echo [INFO] You can run Process Group Policy demo via:
echo   run_group_policy.bat


REM === Optional: run Pipeline Best Practices demo ===
echo.
echo [INFO] You can run Pipeline Best Practices demo by building example_pipeline_best_practices.lpr in Lazarus/IDE or CLI.

REM === Optional: run Pipeline Best Practices demo (script) ===
echo.
echo [INFO] Or simply run:
echo   run_pipeline_best_practices.bat


REM === Optional: sweep GroupPolicy GracefulWaitMs ===
echo.
echo [INFO] You can sweep GracefulWaitMs via:
echo   run_group_policy_sweep.bat [ms]


REM === Optional: build/run GUI child (WM_CLOSE) ===
echo.
echo [INFO] You can build GUI child that handles WM_CLOSE via:
echo   run_wmclose_child_gui.bat


REM === Optional: run Pipeline redirect stdout + split stderr ===
echo.
echo [INFO] You can run Pipeline redirect+split demo via:
echo   run_pipeline_redirect_and_split.bat



echo ===================================================================
goto END

:ERROR_END
echo.
echo ===================================================================
echo Run failed
echo ===================================================================
exit /b 1

:END
echo.
pause
