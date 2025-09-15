# FAFAFA.Core SIMD CPU Information Module

A high-performance, thread-safe CPU feature detection and SIMD capabilities library for Free Pascal/Lazarus.

## Features

- **Cross-platform Support**: Works on x86, x86-64, ARM, and RISC-V architectures
- **Thread-safe**: Lock-free atomic operations for concurrent access
- **Lazy Loading**: On-demand feature detection for optimal performance
- **Comprehensive Detection**: Detects SSE, AVX, NEON, and other SIMD instruction sets
- **Diagnostic Tools**: Built-in performance profiling and diagnostic reporting
- **Optimized Caching**: Minimal overhead for repeated feature queries

## Architecture

The module follows a modular, layered architecture:

```
fafafa.core.simd.cpuinfo (Main facade)
    ├── fafafa.core.simd.cpuinfo.base (Common types and interfaces)
    ├── fafafa.core.simd.cpuinfo.x86 (x86/x86-64 detection)
    │   ├── fafafa.core.simd.cpuinfo.x86.base
    │   ├── fafafa.core.simd.cpuinfo.x86.i386
    │   └── fafafa.core.simd.cpuinfo.x86.x86_64
    ├── fafafa.core.simd.cpuinfo.arm (ARM detection)
    ├── fafafa.core.simd.cpuinfo.riscv (RISC-V detection)
    ├── fafafa.core.simd.cpuinfo.lazy (Lazy loading wrapper)
    ├── fafafa.core.simd.cpuinfo.diagnostic (Diagnostic tools)
    └── fafafa.core.simd.sync (Synchronization primitives)
```

## Quick Start

### Basic Usage

```pascal
uses
  fafafa.core.simd.cpuinfo;

var
  Info: TCPUInfo;
begin
  // Get complete CPU information
  Info := GetCPUInfo;
  
  WriteLn('CPU Vendor: ', Info.Vendor);
  WriteLn('CPU Brand: ', Info.Brand);
  WriteLn('CPU Family: ', Info.Family);
  
  // Quick feature checks
  if HasSSE2 then
    WriteLn('SSE2 is supported');
    
  if HasAVX then
    WriteLn('AVX is supported');
end;
```

### Lazy Loading

```pascal
uses
  fafafa.core.simd.cpuinfo.lazy;

var
  Lazy: TLazyCPUInfo;
begin
  Lazy := TLazyCPUInfo.Create;
  try
    // Features are detected only when first accessed
    if Lazy.HasSSE then
      ProcessWithSSE;
      
    if Lazy.HasAVX2 then
      ProcessWithAVX2;
  finally
    Lazy.Free;
  end;
end;
```

### Capability model (Raw vs Usable)

- Raw: hardware-advertised features (e.g., CPUID on x86)
- Usable: Raw features that are also enabled by the OS and current process context
  - x86 examples:
    - SIMD-256 (AVX-family) requires OSXSAVE=1 and XCR0 enabling XMM(bit1)+YMM(bit2)
    - SIMD-512 (AVX-512) additionally requires XCR0 bits 5,6,7
- Backend semantics:
  - 128-bit backend corresponds to SSE2 (x86) or NEON (ARM)
  - 256-bit backend corresponds to AVX2+ on x86 (no separate AVX-only backend exposed)
  - 512-bit backend corresponds to AVX-512F on x86

### Diagnostics

```pascal
uses
  fafafa.core.simd.cpuinfo.diagnostic;

var
  Diag: TCPUDiagnostic;
begin
  Diag := TCPUDiagnostic.Create;
  try
    Diag.RunCompleteDiagnostic;
    WriteLn(Diag.GetReport);
    
    // Benchmark feature detection
    Diag.BenchmarkDetection(1000);
    WriteLn('Average detection time: ', Diag.GetAverageTime, ' ms');
  finally
    Diag.Free;
  end;
end;
```

## API Reference

### Main Functions

#### `GetCPUInfo: TCPUInfo`
Returns complete CPU information including vendor, brand, features, and cache sizes.

#### Feature Detection Functions

- `HasMMX: Boolean` - Checks for MMX support
- `HasSSE: Boolean` - Checks for SSE support
- `HasSSE2: Boolean` - Checks for SSE2 support
- `HasSSE3: Boolean` - Checks for SSE3 support
- `HasSSSE3: Boolean` - Checks for SSSE3 support
- `HasSSE41: Boolean` - Checks for SSE4.1 support
- `HasSSE42: Boolean` - Checks for SSE4.2 support
- `HasAVX: Boolean` - Checks for AVX support
- `HasAVX2: Boolean` - Checks for AVX2 support
- `HasAVX512F: Boolean` - Checks for AVX-512 Foundation support
- `HasFMA3: Boolean` - Checks for FMA3 support
- `HasAES: Boolean` - Checks for AES-NI support
- `HasNEON: Boolean` - Checks for ARM NEON support (ARM only)

### Types

#### `TCPUInfo` Record

```pascal
TCPUInfo = record
  // Identification
  Vendor: string;          // CPU vendor (GenuineIntel, AuthenticAMD, etc.)
  Brand: string;           // Full CPU brand string
  Family: Byte;            // CPU family
  Model: Byte;             // CPU model
  Stepping: Byte;          // CPU stepping
  
  // Features
  Features: TCPUFeatures;  // Set of supported features
  
  // Cache information
  L1DataCache: Cardinal;   // L1 data cache size in KB
  L1InstCache: Cardinal;   // L1 instruction cache size in KB
  L2Cache: Cardinal;       // L2 cache size in KB
  L3Cache: Cardinal;       // L3 cache size in KB
  
  // Additional info
  LogicalCores: Cardinal;  // Number of logical cores
  PhysicalCores: Cardinal; // Number of physical cores
end;
```

#### `TCPUFeatures` Set

```pascal
TCPUFeature = (
  cfMMX, cfSSE, cfSSE2, cfSSE3, cfSSSE3, cfSSE41, cfSSE42,
  cfAVX, cfAVX2, cfAVX512F, cfFMA3, cfAES, cfSHA,
  cfNEON, cfSVE, cfSVE2,  // ARM features
  cfRVV                    // RISC-V Vector
);

TCPUFeatures = set of TCPUFeature;
```

## Performance Characteristics

### Detection Performance
- Initial detection: ~0.1-1.0 ms (platform dependent)
- Cached queries: <0.001 ms
- Thread-safe access: No locks, uses atomic operations

### Memory Usage
- Static cache: ~512 bytes
- Lazy loading: ~128 bytes per instance
- Diagnostic tools: ~2KB when active

## Thread Safety

All functions are thread-safe and can be called concurrently:

```pascal
// Safe to call from multiple threads
procedure TWorkerThread.Execute;
begin
  if HasAVX2 then
    ProcessDataWithAVX2
  else if HasSSE2 then
    ProcessDataWithSSE2
  else
    ProcessDataScalar;
end;
```

## Platform-Specific Notes

### Windows
- Uses CPUID instruction on x86/x86-64
- Checks OS support for AVX via XCR0
- Fallback to WMI for additional information

### Linux
- Parses /proc/cpuinfo for ARM platforms
- Uses CPUID on x86/x86-64
- Checks auxiliary vector for feature flags

### macOS
- Uses sysctl for CPU information
- CPUID on x86/x86-64
- Feature detection via system frameworks on ARM

## Building and Testing

### Compilation

```bash
# Build the library
fpc -O3 -CX -XX fafafa.core.simd.cpuinfo.pas

# Build with debugging
fpc -g -gl -gw fafafa.core.simd.cpuinfo.pas
```

### Running Tests

```bash
# Run all tests
./run_cpuinfo_tests

# Run with verbose output
./run_cpuinfo_tests --verbose

# Run specific category
./run_cpuinfo_tests --category performance

# Generate test report
./run_cpuinfo_tests --report test_results.txt

# Quick smoke tests
./run_cpuinfo_tests --quick
```

## Best Practices

1. **Use cached functions for repeated checks**
   ```pascal
   // Good: Uses cached result
   for i := 1 to 1000000 do
     if HasSSE2 then ProcessSSE2;
   
   // Avoid: Creates new detection each time
   for i := 1 to 1000000 do
     if GetCPUInfo.Features.HasSSE2 then ProcessSSE2;
   ```

2. **Check OS support for advanced features**
   ```pascal
   // AVX requires both CPU and OS support
   if HasAVX and HasOSXSAVE then
     UseAVXInstructions;
   ```

3. **Provide fallback paths**
   ```pascal
   if HasAVX2 then
     Result := ProcessAVX2(Data)
   else if HasSSE2 then
     Result := ProcessSSE2(Data)
   else
     Result := ProcessScalar(Data);
   ```

## Troubleshooting

### Common Issues

1. **AVX not detected on supported CPU**
   - Check OS support (Windows 7 SP1+, Linux 2.6.30+)
   - Verify OSXSAVE flag is set
   - Check BIOS settings

2. **Performance degradation**
   - Ensure you're using cached functions
   - Check for excessive diagnostics in production
   - Verify compiler optimization flags

3. **Thread safety concerns**
   - All public functions are thread-safe
   - No manual synchronization needed
   - Atomic operations ensure consistency

## Contributing

Contributions are welcome! Please ensure:
- Code follows existing style conventions
- All tests pass
- New features include tests
- Documentation is updated

## License

This module is part of the FAFAFA.Core library and follows the same license terms.

## Changelog

### Version 2.0.0 (Current)
- Complete refactoring for better performance
- Added atomic operations for thread safety
- Implemented lazy loading
- Added comprehensive diagnostic tools
- Improved caching mechanism
- Added RISC-V support

### Version 1.0.0
- Initial release
- Basic CPU detection for x86/x86-64
- Simple caching mechanism

## Support

For issues, questions, or contributions, please contact the FAFAFA.Core maintainers.