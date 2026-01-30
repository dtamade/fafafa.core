@echo off
REM Build script for fafafa.core SIMD library

echo Building fafafa.core SIMD library...

REM Set compiler flags
set FPC_FLAGS=-O3 -Xs -XX -Fi./src -Fu./src

REM Create output directory
if not exist "lib" mkdir lib

REM Compile units
echo Compiling base units...
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.cpuinfo.base.pas
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.types.pas
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.sync.pas

echo Compiling platform-specific units...
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.cpuinfo.x86.base.pas
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.cpuinfo.x86.x86_64.pas
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.cpuinfo.x86.i386.pas
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.cpuinfo.x86.pas
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.cpuinfo.arm.pas
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.cpuinfo.riscv.pas

echo Compiling main units...
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.cpuinfo.pas
fpc %FPC_FLAGS% -FElib src\fafafa.core.simd.cpuinfo.diagnostic.pas

echo.
echo Build completed!
echo Compiled units are in the 'lib' directory.
echo.

REM Compile test program
echo Compiling test program...
fpc %FPC_FLAGS% -Fulib -FEtest test\test_cpuinfo_refactored.pas

if exist test\test_cpuinfo_refactored.exe (
    echo Test program compiled successfully!
    echo.
    echo Running tests...
    test\test_cpuinfo_refactored.exe
) else (
    echo Failed to compile test program.
)
