@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Resolve repo root based on this script location
pushd "%~dp0..\..\.." >NUL

if not exist bin mkdir bin
if not exist report\benchmarks mkdir report\benchmarks

REM Build vec_bench_ext into bin
fpc src\tests\tools\vec_bench_ext.lpr -B -FEbin -Fusrc -Fusrc\tests -Fusrc\tests\lib -Fusrc\tests\lib\x86_64-win64 -Fusrc\plat -Fusrc\tests\tools -O2 -S2 -MObjFPC > build_vec_bench_ext.log 2>&1
if errorlevel 1 (
  echo Build failed, see build_vec_bench_ext.log
  popd >NUL
  exit /b 1
)

set N=%1
if "%N%"=="" set N=1000000
set CSV=report\benchmarks\vec_bench_ext_%N%.csv

bin\vec_bench_ext.exe --n=%N% --aligned-elements=64 --cases=all --csv > "%CSV%"
set RC=!ERRORLEVEL!
if %RC% NEQ 0 (
  echo Run failed ^(exit code %RC%^) >> build_vec_bench_ext.log
) else (
  echo Report saved: %CSV%
)

popd >NUL
exit /b %RC%

