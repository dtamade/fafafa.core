@echo off
echo Building fafafa.core.atomic examples...

REM Create output directories
if not exist bin mkdir bin
if not exist lib mkdir lib

echo.
echo ===========================================
echo Building Example 1: Basic Operations
echo ===========================================
lazbuild -B --build-mode=Release example_basic_operations.lpi

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build example_basic_operations
    pause
    exit /b 1
)

echo.
echo ===========================================
echo Building Example 2: Producer-Consumer
echo ===========================================
lazbuild -B --build-mode=Release example_producer_consumer.lpi

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build example_producer_consumer
    pause
    exit /b 1
)

echo.
echo ===========================================
echo Building Example 3: Tagged Pointer ABA
echo ===========================================
lazbuild -B --build-mode=Release example_tagged_ptr_aba.lpi

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build example_tagged_ptr_aba
    pause
    exit /b 1
)

echo.
echo ===========================================
echo Building Example 4: Thread Counter
echo ===========================================
lazbuild -B --build-mode=Release example_thread_counter.lpi

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build example_thread_counter
    pause
    exit /b 1
)

echo.
echo ===========================================
echo All examples built successfully!
echo ===========================================
echo.
echo You can now run the examples:
echo   bin\example_basic_operations.exe
echo   bin\example_producer_consumer.exe
echo   bin\example_tagged_ptr_aba.exe
echo   bin\example_thread_counter.exe
echo.
pause
