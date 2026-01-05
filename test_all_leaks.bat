@echo off
setlocal enabledelayedexpansion

set FPC=C:\fpcupdeluxe\fpc\bin\x86_64-win64\fpc.exe
set SRC=C:\Users\dtama\projects\fafafa.core\src
set TESTS_DIR=C:\Users\dtama\projects\fafafa.core\tests
set BIN_DIR=%TESTS_DIR%\leak_test_bin
set REPORT=%TESTS_DIR%\MEMORY_LEAK_REPORT.txt

echo ======================================== > %REPORT%
echo Collections Memory Leak Test Report >> %REPORT%
echo Date: %date% %time% >> %REPORT%
echo ======================================== >> %REPORT%
echo. >> %REPORT%

set TESTS=test_vec_leak test_vecdeque_leak test_list_leak test_hashmap_leak test_hashset_leak test_linkedhashmap_leak test_bitset_leak test_treeset_leak test_treemap_leak test_priorityqueue_leak

set PASSED=0
set FAILED=0

for %%T in (%TESTS%) do (
    echo.
    echo ========================================
    echo Testing: %%T
    echo ========================================
    
    echo [%%T] >> %REPORT%
    
    "%FPC%" -gh -gl -B -Fu%SRC% -Fi%SRC% -FE%BIN_DIR% %TESTS_DIR%\%%T.pas > nul 2>&1
    if errorlevel 1 (
        echo   COMPILATION FAILED
        echo   Status: COMPILATION FAILED >> %REPORT%
        set /a FAILED+=1
    ) else (
        echo   Compiled successfully
        %BIN_DIR%\%%T.exe > %BIN_DIR%\%%T_output.txt 2>&1
        findstr /C:"0 unfreed memory blocks" %BIN_DIR%\%%T_output.txt > nul
        if errorlevel 1 (
            echo   MEMORY LEAK DETECTED!
            echo   Status: FAILED - Memory leak detected >> %REPORT%
            set /a FAILED+=1
        ) else (
            echo   PASSED - No memory leaks!
            echo   Status: PASSED - No memory leaks >> %REPORT%
            set /a PASSED+=1
        )
    )
    echo. >> %REPORT%
)

echo.
echo ========================================
echo Summary
echo ========================================
echo   PASSED: %PASSED%
echo   FAILED: %FAILED%
echo.
echo Report saved to: %REPORT%

echo. >> %REPORT%
echo ======================================== >> %REPORT%
echo Summary >> %REPORT%
echo ======================================== >> %REPORT%
echo   PASSED: %PASSED% >> %REPORT%
echo   FAILED: %FAILED% >> %REPORT%

endlocal
