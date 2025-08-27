@echo off
setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"
set "LAZBUILD=%SCRIPT_DIR%..\..\tools\lazbuild.bat"
set "EXTRA_ARGS=%~1"

if /I "%EXTRA_ARGS%"=="release" (
  set "MODE=Release"
) else (
  set "MODE=Debug"
)

echo Building examples (!MODE!)...

call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_mem.lpi" || goto FAILED
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_mem_pool_basic.lpi" || goto FAILED
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_mem_pool_config.lpi" || goto FAILED
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_mem_pool_exceptions.lpi" || goto FAILED
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_stack_scope.lpi" || goto FAILED
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_mem_integration_runner.lpi" || goto FAILED
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_mem_interface.lpi" || goto FAILED

call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_enhanced_stack_pool.lpi" || goto FAILED
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_mapped_runner.lpi" || goto FAILED
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_mapped_ringbuffer_bidir.lpi" || goto FAILED
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_mem_microbench.lpi" || goto FAILED
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_mapped_ringbuffer_bench.lpi" || goto FAILED

REM ALIGN EXCEPTIONS DEMO
call "%LAZBUILD%" --build-mode=!MODE! "%SCRIPT_DIR%example_align_exceptions.lpi" || goto FAILED

echo All examples built successfully.
goto END

:FAILED
echo Build failed with error code %ERRORLEVEL%.
exit /b %ERRORLEVEL%

:END
endlocal
