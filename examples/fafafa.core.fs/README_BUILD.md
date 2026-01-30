# fafafa.core.fs Examples - Build Guide

## 🚀 Quick Start

### Build Examples
```bash
# Navigate to the examples directory
cd examples/fafafa.core.fs

# Build all examples
build_examples_fixed.bat
```

### Run Examples
```bash
# Run interactive showcase
run_examples.bat

# Or run individual examples from bin directory
cd bin
example_fs_basic.exe
example_fs_advanced.exe
example_fs_performance.exe
example_fs_benchmark.exe
```

### Clean Build Artifacts
```bash
# Clean all build artifacts
clean_examples_fixed.bat
```

## 📁 Directory Structure

```
examples/fafafa.core.fs/
├── build_examples_fixed.bat     # Build script (run from here)
├── clean_examples_fixed.bat     # Clean script
├── run_examples.bat             # Demo script
├── example_fs_basic.lpr         # Source files
├── example_fs_advanced.lpr
├── example_fs_performance.lpr
├── example_fs_benchmark.lpr
├── lib/                         # Intermediate files (.o, .ppu, .a)
└── README_BUILD.md              # This file

bin/                       # Generated executables
├── example_fs_basic.exe
├── example_fs_advanced.exe
├── example_fs_performance.exe
└── example_fs_benchmark.exe
```

## 🔧 Build Configuration

- **Source Path**: `../../src` (framework source code)
- **Executable Output**: `bin` (module-local bin directory)
- **Intermediate Files**: `lib/` (local lib directory)
- **Compiler Flags**: `-Mobjfpc -Fu"../../src" -FE"bin" -FU"lib" -gl -O2`

## 📊 Expected Output

### Build Success
```
=== fafafa.core.fs Examples Build Script ===
[1/4] Building example_fs_basic.exe...
SUCCESS: example_fs_basic.exe
[2/4] Building example_fs_advanced.exe...
SUCCESS: example_fs_advanced.exe
[3/4] Building example_fs_performance.exe...
SUCCESS: example_fs_performance.exe
[4/4] Building example_fs_benchmark.exe...
SUCCESS: example_fs_benchmark.exe
=== Build Complete ===
All examples built successfully!
```

### Example Run
```
--- Starting fafafa.core.fs Test ---
[  OK  ] Creating temp directory: test_temp
[  OK  ] Writing to file (22 bytes)
[  OK  ] Reading from file (22 bytes)
--- All fafafa.core.fs Tests Passed Successfully! ---
```

## 🐛 Troubleshooting

### Build Fails
1. Ensure you're in the `examples/fafafa.core.fs/` directory
2. Check that FPC is installed and in PATH
3. Verify source files exist
4. Try running as administrator

### Examples Don't Run
1. Check that bin directory contains .exe files
2. Ensure Windows allows execution
3. Try running from command prompt

### Permission Errors
1. Run as administrator if needed
2. Check antivirus software
3. Ensure directories are writable

## 🎯 File Organization

### ✅ Correct Structure
- **Executables**: `bin/` (module-local bin directory)
- **Intermediate Files**: `lib/` (local to examples)
- **Source Files**: Current directory (examples/fafafa.core.fs/)

### ❌ Avoid
- Don't put executables in source directory
- Don't put intermediate files in bin directory
- Don't mix source and binary files

## 🏆 Success Criteria

A successful build should produce:
- ✅ 4 executable files in `bin/`
- ✅ Intermediate files in `lib/`
- ✅ Clean source directory
- ✅ All examples run without errors

---

*Build system organized by namespace*  
*Location: examples/fafafa.core.fs/*  
*Updated: 2025-01-06*
