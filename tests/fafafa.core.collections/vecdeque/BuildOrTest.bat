@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Set paths relative to the script's location
SET SCRIPT_DIR=%~dp0
REM Prefer project-local lazbuild wrapper without polluting LAZBUILD_EXE
set "LAZWRAP_EXE=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
if exist "%LAZWRAP_EXE%" (
  set "USE_LAZBUILD=%LAZWRAP_EXE%"
) else (
  set "USE_LAZBUILD=lazbuild"
)
if not defined FPC_EXE set FPC_EXE=fpc
if not defined FPC_OPTS set FPC_OPTS=-Mobjfpc -Sh -O1 -g -gl -l -vewnhibq
SET PROJECT="%SCRIPT_DIR%tests_vecdeque.lpi"
SET SIMPLE_TEST="%SCRIPT_DIR%test_countof_simple.pas"
SET SIMPLE_TEST_2="%SCRIPT_DIR%test_slices_simple.pas"
SET SIMPLE_TEST_3="%SCRIPT_DIR%test_reverse_simple.pas"
SET SIMPLE_TEST_4="%SCRIPT_DIR%test_capacity_pushfront_simple.pas"
SET SIMPLE_TEST_5="%SCRIPT_DIR%test_wrap_batch_simple.pas"
SET SIMPLE_TEST_6="%SCRIPT_DIR%test_findlastif_wraparound_simple.pas"
SET SIMPLE_TEST_7="%SCRIPT_DIR%test_strategy_pow2_rounding.pas"
SET SIMPLE_TEST_8="%SCRIPT_DIR%test_strategy_lower_bound.pas"
SET SIMPLE_TEST_9="%SCRIPT_DIR%test_create_capacity_pow2.pas"
SET SIMPLE_TEST_10="%SCRIPT_DIR%test_set_strategy_runtime.pas"
SET SIMPLE_TEST_11="%SCRIPT_DIR%test_set_strategy_interface.pas"
SET SIMPLE_TEST_12="%SCRIPT_DIR%test_make_contiguous_simple.pas"
SET TEST_EXECUTABLE="%SCRIPT_DIR%bin\test_countof_simple.exe"
SET TEST_EXECUTABLE_2="%SCRIPT_DIR%bin\test_slices_simple.exe"
SET TEST_EXECUTABLE_3="%SCRIPT_DIR%bin\test_reverse_simple.exe"
SET TEST_EXECUTABLE_4="%SCRIPT_DIR%bin\test_capacity_pushfront_simple.exe"
SET TEST_EXECUTABLE_5="%SCRIPT_DIR%bin\test_wrap_batch_simple.exe"
SET TEST_EXECUTABLE_6="%SCRIPT_DIR%bin\test_findlastif_wraparound_simple.exe"
SET TEST_EXECUTABLE_7="%SCRIPT_DIR%bin\test_strategy_pow2_rounding.exe"
SET TEST_EXECUTABLE_8="%SCRIPT_DIR%bin\test_strategy_lower_bound.exe"
SET TEST_EXECUTABLE_9="%SCRIPT_DIR%bin\test_create_capacity_pow2.exe"
SET TEST_EXECUTABLE_10="%SCRIPT_DIR%bin\test_set_strategy_runtime.exe"
SET TEST_EXECUTABLE_11="%SCRIPT_DIR%bin\test_set_strategy_interface.exe"
SET FULL_TEST_EXECUTABLE="%SCRIPT_DIR%..\..\bin\tests_vecdeque.exe"
SET FULL_PLAIN="%SCRIPT_DIR%bin\results_plain.txt"

REM Create output directories
if not exist "%SCRIPT_DIR%bin" mkdir "%SCRIPT_DIR%bin"
if not exist "%SCRIPT_DIR%lib" mkdir "%SCRIPT_DIR%lib"

REM Try to build simple test first using FPC directly
echo Building simple VecDeque test...
%FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST%"
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_2%"
)
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_3%"
)
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_4%"
)
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_5%"
)
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_6%"
)
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_7%"
)
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_8%"
)
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_9%"
)
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_10%"
)
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_11%"
)
if %ERRORLEVEL% EQU 0 (
    %FPC_EXE% %FPC_OPTS% -I"%SCRIPT_DIR%..\..\src" -Fu"%SCRIPT_DIR%..\..\src" -FU"%SCRIPT_DIR%lib" -FE"%SCRIPT_DIR%bin" "%SIMPLE_TEST_12%"
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Simple test build successful.
    echo.

    REM Run simple tests if the 'test' parameter is provided
    if /i "%1"=="test" (
        echo Running simple VecDeque tests...
        echo.
        %TEST_EXECUTABLE%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 1 passed.
        ) else (
            echo.
            echo [FAIL] Simple test 1 failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_2%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 2 slices passed.
        ) else (
            echo.
            echo [FAIL] Simple test 2 slices failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_3%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 3 reverse passed.
        ) else (
            echo.
            echo [FAIL] Simple test 3 reverse failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_4%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 4 capacity+pushfront passed.
        ) else (
            echo.
            echo [FAIL] Simple test 4 capacity+pushfront failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_5%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 5 wrap+batch passed.
        ) else (
            echo.
            echo [FAIL] Simple test 5 wrap+batch failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_6%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 6 findlastif wraparound passed.
        ) else (
            echo.
            echo [FAIL] Simple test 6 findlastif wraparound failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_7%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 7 growth strategy pow2 rounding passed.
        ) else (
            echo.
            echo [FAIL] Simple test 7 growth strategy pow2 rounding failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_8%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 8 growth strategy lower bound passed.
        ) else (
            echo.
            echo [FAIL] Simple test 8 growth strategy lower bound failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_9%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 9 create capacity pow2 normalization passed.
        ) else (
            echo.
            echo [FAIL] Simple test 9 create capacity pow2 normalization failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_10%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 10 set strategy at runtime passed.
        ) else (
            echo.
            echo [FAIL] Simple test 10 set strategy at runtime failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_11%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 11 set strategy via interface passed.
        ) else (
            echo.
            echo [FAIL] Simple test 11 set strategy via interface failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        %TEST_EXECUTABLE_12%
        set TEST_RESULT=%ERRORLEVEL%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] Simple test 12 make_contiguous passed.
        ) else (
            echo.
            echo [FAIL] Simple test 12 make_contiguous failed. Exit code: !TEST_RESULT!
            exit /b !TEST_RESULT!
        )
        echo.
        echo Building full test project after simple tests passed: %PROJECT%...
        call "%USE_LAZBUILD%" %PROJECT%
        if %ERRORLEVEL% NEQ 0 (
            echo.
            echo Full test build failed with error code %ERRORLEVEL%.
            exit /b %ERRORLEVEL%
        )
        echo.
        if not exist %FULL_TEST_EXECUTABLE% (
            echo [ERROR] Full test executable not found: %FULL_TEST_EXECUTABLE%
            exit /b 1
        )
        echo Running full VecDeque test suite...
        if exist %FULL_PLAIN% del /f /q %FULL_PLAIN%
        %FULL_TEST_EXECUTABLE% --all --format=plain 1> %FULL_PLAIN% 2>&1
        set TEST_RESULT=%ERRORLEVEL%
        echo --- Full test plain output ---
        type %FULL_PLAIN%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] All full tests passed.
        ) else (
            echo.
            echo [FAIL] Some full tests failed. Exit code: !TEST_RESULT!
        )
        exit /b !TEST_RESULT!
    ) else (
        echo Simple test executables created:
        echo   %TEST_EXECUTABLE%
        echo   %TEST_EXECUTABLE_2%
        echo   %TEST_EXECUTABLE_3%
        echo   %TEST_EXECUTABLE_4%
        echo   %TEST_EXECUTABLE_5%
        echo   %TEST_EXECUTABLE_6%
        echo   %TEST_EXECUTABLE_7%
        echo   %TEST_EXECUTABLE_8%
        echo   %TEST_EXECUTABLE_9%
        echo   %TEST_EXECUTABLE_10%
        echo   %TEST_EXECUTABLE_11%
        echo   %TEST_EXECUTABLE_12%
        echo To run tests, call this script with the 'test' parameter.
        echo e.g., BuildOrTest.bat test
    )
) else (
    echo.
    echo Simple test build failed. Trying full test suite with lazbuild...
    echo.

    REM Build the full project with lazbuild
    echo Building full test project: %PROJECT%...
    set "LAZLOG=%SCRIPT_DIR%lazbuild.log"
    echo Locating lazbuild: %USE_LAZBUILD%
    if not exist "%USE_LAZBUILD%" (
        where %LAZBUILD_EXE% >NUL 2>&1
        if %ERRORLEVEL% NEQ 0 (
            echo [ERROR] lazbuild not found. Ensure lazbuild is in PATH or set LAZBUILD_EXE to full path.
            exit /b 1
        )
    )
    call "%USE_LAZBUILD%" %PROJECT% > "%LAZLOG%" 2>&1

    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Full test build failed with error code %ERRORLEVEL%.
        exit /b %ERRORLEVEL%
    )

    echo.
    echo Full test build successful.
    echo.

    REM Run full tests if the 'test' parameter is provided
    if /i "%1"=="test" (
        if not exist %FULL_TEST_EXECUTABLE% (
            echo [ERROR] Full test executable not found: %FULL_TEST_EXECUTABLE%
            exit /b 1
        )
        echo Running full VecDeque test suite...
        echo.
        if exist %FULL_PLAIN% del /f /q %FULL_PLAIN%
        %FULL_TEST_EXECUTABLE% --all --format=plain 1> %FULL_PLAIN% 2>&1
        set TEST_RESULT=%ERRORLEVEL%
        echo --- Full test plain output ---
        type %FULL_PLAIN%
        if !TEST_RESULT! EQU 0 (
            echo.
            echo [PASS] All tests passed.
        ) else (
            echo.
            echo [FAIL] Some tests failed. Exit code: !TEST_RESULT!
        )
        exit /b !TEST_RESULT!
    ) else (
        echo Full test executable created: %FULL_TEST_EXECUTABLE%
        echo To run tests, call this script with the 'test' parameter.
        echo e.g., BuildOrTest.bat test
    )
)
