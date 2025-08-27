@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Jump to repo root (this script is under src\tests)
pushd "%~dp0..\.." >NUL

if not exist bin mkdir bin
if not exist report\benchmarks mkdir report\benchmarks

REM Build and run env tests (subset) FIRST to ensure env pipeline is green
fpc tests\run_env_tests.lpr -B -FEbin -Fusrc -Futests -Futests\fafafa.core.env -Fusrc\plat -Fisrc -Fisrc\plat -O2 -S2 -MObjFPC > build_run_env_tests.log 2>&1
if errorlevel 1 (
  echo Build env tests failed, see build_run_env_tests.log
  popd >NUL
  exit /b 1
)

bin\run_env_tests.exe --all --format=plain > src\tests\tests_env_output.txt 2>&1
if errorlevel 1 (
  echo Env tests finished with non-zero exit code. See src\tests\tests_env_output.txt
) else (
  echo Env tests OK. See src\tests\tests_env_output.txt
)

REM Build and run general tests (output to bin) AFTER env tests
fpc src\tests\run_tests.lpr -B -FEbin -Fusrc -Fusrc\tests -Fusrc\tests\lib -Fusrc\tests\lib\x86_64-win64 -Fusrc\plat -Fusrc\tests\tools -Fisrc -Fisrc\plat -O2 -S2 -MObjFPC -dFAFAFA_CORE_INLINE -dFAFAFA_COLLECTIONS_INLINE -dFAFAFA_ENABLE_TOML_TESTS > build_run_tests.log 2>&1
if errorlevel 1 (
  echo Build tests failed, see build_run_tests.log
  popd >NUL
  exit /b 1
)

bin\run_tests.exe --all --format=plain > src\tests\tests_all_output.txt 2>&1
if errorlevel 1 (
  echo Tests run finished with non-zero exit code. See src\tests\tests_all_output.txt
) else (
  echo Tests OK. See src\tests\tests_all_output.txt
)

REM Build and run vec bench (extended)
call src\tests\tools\run_vec_bench_ext.bat 1000000
set RC=!ERRORLEVEL!
if %RC% NEQ 0 (
  echo vec_bench_ext run failed ^(exit code %RC%^) >> build_vec_bench_ext.log
  popd >NUL
  exit /b %RC%
)

echo All done. Outputs:
echo   - tests: src\tests\tests_all_output.txt
echo   - env:   src\tests\tests_env_output.txt
echo   - bench: report\benchmarks\vec_bench_ext_1000000.csv

popd >NUL
exit /b 0

