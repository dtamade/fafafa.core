#!/bin/bash

# fafafa.core.sync.barrier Linux Test Runner
# Cross-compiled from Windows, ready for Linux deployment

echo "========================================"
echo "fafafa.core.sync.barrier Linux Tests"
echo "========================================"
echo

# Check if executable exists
if [ ! -f "fafafa.core.sync.barrier.test" ]; then
    echo "ERROR: Linux executable not found!"
    echo "Please run cross-compilation first:"
    echo "  lazbuild --cpu=x86_64 --os=linux fafafa.core.sync.barrier.test.lpi"
    exit 1
fi

# Make executable
chmod +x fafafa.core.sync.barrier.test

echo "1. Running TTestCase_Global tests..."
./fafafa.core.sync.barrier.test --suite=TTestCase_Global --format=plain > global_test_linux.log 2>&1
GLOBAL_EXIT=$?
if [ $GLOBAL_EXIT -eq 0 ]; then
    echo "   PASSED: TTestCase_Global tests"
else
    echo "   FAILED: TTestCase_Global tests (exit code: $GLOBAL_EXIT)"
    echo "   Check global_test_linux.log for details"
fi

echo
echo "2. Running TTestCase_IBarrier tests..."
./fafafa.core.sync.barrier.test --suite=TTestCase_IBarrier --format=plain > ibarrier_test_linux.log 2>&1
IBARRIER_EXIT=$?
if [ $IBARRIER_EXIT -eq 0 ]; then
    echo "   PASSED: TTestCase_IBarrier tests"
else
    echo "   FAILED: TTestCase_IBarrier tests (exit code: $IBARRIER_EXIT)"
    echo "   Check ibarrier_test_linux.log for details"
fi

echo
echo "3. Running all tests together..."
./fafafa.core.sync.barrier.test --all --format=plain > all_test_linux.log 2>&1
ALL_EXIT=$?
if [ $ALL_EXIT -eq 0 ]; then
    echo "   PASSED: All tests"
else
    echo "   FAILED: Some tests (exit code: $ALL_EXIT)"
    echo "   Check all_test_linux.log for details"
fi

echo
echo "========================================"
echo "Linux Test Summary:"
echo "========================================"
echo "TTestCase_Global:  $GLOBAL_EXIT"
echo "TTestCase_IBarrier: $IBARRIER_EXIT"
echo "All Tests:         $ALL_EXIT"

if [ $ALL_EXIT -eq 0 ]; then
    echo
    echo "SUCCESS: All Linux tests passed!"
    echo "Platform: $(uname -s) $(uname -m)"
    echo "Kernel: $(uname -r)"
    echo "Implementation: Unix pthread_barrier_t + fallback"
else
    echo
    echo "FAILURE: Some Linux tests failed."
    echo "Check log files for details:"
    echo "- global_test_linux.log"
    echo "- ibarrier_test_linux.log"
    echo "- all_test_linux.log"
fi

echo
echo "Cross-compilation verification:"
echo "- Source: Windows x64"
echo "- Target: Linux x86_64"
echo "- Compiler: Free Pascal 3.3.1+"
echo "- Status: $([ $ALL_EXIT -eq 0 ] && echo 'SUCCESS' || echo 'FAILED')"
echo
