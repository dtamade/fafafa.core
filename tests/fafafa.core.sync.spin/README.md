# fafafa.core.sync.spin Tests

## Overview

Unit tests for `fafafa.core.sync.spin` module.

## Building Tests

### Windows
```batch
buildOrTest.bat          # Build only
buildOrTest.bat test     # Build and run tests
```

### Linux Cross-compilation
```batch
buildLinux.bat           # Cross-compile to Linux x86_64
```

### Linux Native
```bash
chmod +x build.sh
./build.sh               # Build on Linux system
```

## Running Tests

### Windows
```batch
bin\fafafa.core.sync.spin.test.exe
```

### Linux
```bash
chmod +x bin/fafafa.core.sync.spin.test
./bin/fafafa.core.sync.spin.test
```

## Test Coverage

- ✅ Basic spin lock operations (Acquire, Release, TryAcquire)
- ✅ Timeout handling and edge cases
- ✅ RAII lock guard functionality
- ✅ Concurrent access and thread safety
- ✅ Platform compatibility (Windows/Linux)
- ✅ Performance characteristics

## File Structure

- `fafafa.core.sync.spin.test.lpr` - Test program main file
- `fafafa.core.sync.spin.test.lpi` - Lazarus project file
- `fafafa.core.sync.spin.testcase.pas` - Test cases
- `buildOrTest.bat` - Windows build script
- `buildLinux.bat` - Linux cross-compilation script
- `build.sh` - Linux native build script
