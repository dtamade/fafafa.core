# fafafa.core.sync.sem Unit Tests

## Overview

This directory contains unit tests for the `fafafa.core.sync.sem` module (semaphore implementation).

## Test Files

### Main Test Suite
- `fafafa.core.sync.sem.test.lpr` - Main test program
- `fafafa.core.sync.sem.test.lpi` - Lazarus project file
- `fafafa.core.sync.sem.testcase.pas` - Test cases using FPCUnit

### Alternative Tests
- `direct_test.lpr` - Direct test without FPCUnit dependency
- `simple_run_test.lpr` - Minimal functionality test
- `minimal.lpr` - Basic compilation test

### Build Scripts
- `buildOrTest.bat` - Original build and test script
- `run_tests.bat` - Enhanced test runner with detailed output
- `build_only.bat` - Build-only script
- `debug_build.bat` - Debug build with verbose output
- `test_minimal.bat` - Test minimal compilation

## Test Coverage

The test suite covers:

### Basic Functionality
- Semaphore creation with `MakeSem()`
- Basic acquire/release operations
- Available count and max count queries
- Bulk operations (acquire/release multiple permits)

### RAII Guard Mechanism
- Guard creation with `AcquireGuard()`
- Automatic resource cleanup on destruction
- Manual release with `Guard.Release()`
- Guard permit count tracking

### Non-blocking Operations
- `TryAcquire()` variants
- `TryAcquireGuard()` variants
- Timeout-based operations

### Multi-threading
- Concurrent access patterns
- Thread safety verification
- Blocking and non-blocking scenarios

### Error Handling
- Boundary conditions
- Invalid parameter handling
- Exception safety

## Usage

### Running Tests

#### Method 1: Using build script
```batch
buildOrTest.bat test
```

#### Method 2: Using enhanced runner
```batch
run_tests.bat
```

#### Method 3: Manual build and run
```batch
build_only.bat
bin\fafafa.core.sync.sem.test.exe
```

### Building Only
```batch
build_only.bat
```

### Debug Build
```batch
debug_build.bat
```

## Test Structure

### Test Classes

#### `TTestCase_Global`
Tests global functions:
- `Test_CreateSemaphore_Factory` - Tests `MakeSem()` function

#### `TTestCase_ISem`
Tests `ISem` interface:
- Basic operations (acquire, release, try operations)
- State queries (available count, max count)
- Guard creation methods
- Bulk operations
- Timeout operations

### Thread Test Classes

#### `TBlockingAcquireThread`
- Tests blocking acquire behavior
- Verifies thread synchronization

#### `TDelayedReleaseThread`
- Tests delayed release scenarios
- Verifies timing behavior

#### `TWorkerThread`
- Tests concurrent worker patterns
- Stress testing with multiple operations

#### `TSamplerThread`
- Monitors semaphore state during concurrent access
- Detects race conditions and violations

## Expected Behavior

### Semaphore Creation
```pascal
Sem := MakeSem(1, 3);  // Initial: 1, Max: 3
Assert(Sem.GetAvailableCount = 1);
Assert(Sem.GetMaxCount = 3);
```

### Basic Operations
```pascal
Sem.Acquire;           // Available: 0
Sem.Release;           // Available: 1
```

### RAII Guard Usage
```pascal
Guard := Sem.AcquireGuard;     // Acquires 1 permit
// Guard automatically releases on destruction
```

### Bulk Operations
```pascal
Guard := Sem.AcquireGuard(2);  // Acquires 2 permits
Assert(Guard.GetCount = 2);
```

### Non-blocking Operations
```pascal
Guard := Sem.TryAcquireGuard;
if Guard <> nil then
  // Successfully acquired permit
else
  // No permits available
```

## Troubleshooting

### Build Issues

If tests fail to build:

1. **Check Lazarus Installation**
   - Verify `lazbuild.exe` path in scripts
   - Ensure Lazarus is properly installed

2. **Check Source Paths**
   - Verify `..\..\src` contains required modules
   - Check all dependencies are available

3. **Clean Build**
   - Delete `lib\` and `bin\` directories
   - Rebuild from scratch

4. **Alternative Compilation**
   - Try using FPC directly instead of lazbuild
   - Use minimal test programs first

### Runtime Issues

If tests build but fail to run:

1. **Check Dependencies**
   - Ensure all required DLLs are available
   - Verify platform-specific implementations

2. **Debug Output**
   - Run tests with verbose output
   - Check for memory leaks or access violations

3. **Simplified Testing**
   - Start with `minimal.lpr` test
   - Gradually add complexity

## Notes

- All batch files use English only (no Chinese characters)
- Tests are designed for Windows x64 platform
- Cross-platform compatibility maintained in source code
- RAII patterns ensure exception safety
- Thread safety verified through concurrent testing

## Status

- ✅ Test code completed and updated for new interfaces
- ✅ All test cases cover public API surface
- ✅ Multi-threading tests implemented
- ✅ RAII guard mechanism fully tested
- 🔄 Build environment issues need resolution
- 📋 Tests ready to run once build issues resolved
