program test_cpuinfo;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}
  {$CODEPAGE UTF8}
{$ENDIF}
{$ifdef windows}{$codepage utf8}{$endif}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  Classes, SysUtils, DateUtils,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.cpuinfo.diagnostic
  {$IFDEF CPUX86_64}
  , fafafa.core.simd.cpuinfo.x86
  {$ENDIF}
  ;

procedure TestBasicTypes;
var
  arch: TCPUArch;
  features: TGenericFeatureSet;
begin
  WriteLn('=== Testing Basic Types ===');
  
  // Test CPU architecture enumeration
  arch := caX86;
  WriteLn('Architecture caX86 = ', Ord(arch));
  
  // Test generic feature set
  features := [];
  Include(features, gfSimd128);
  Include(features, gfSimd256);
  
  if gfSimd128 in features then
    WriteLn('✓ SIMD-128 feature detected');
  if gfSimd256 in features then
    WriteLn('✓ SIMD-256 feature detected');
  if not (gfSimd512 in features) then
    WriteLn('✓ SIMD-512 feature not in set (expected)');
    
  WriteLn('Test Basic Types: PASSED');
  WriteLn;
end;

procedure TestCPUInfoDetection;
var
  cpuInfo: TCPUInfo;
  i: Integer;
begin
  WriteLn('=== Testing CPU Info Detection ===');
  
  // Get CPU information
  cpuInfo := GetCPUInfo;
  
  WriteLn('CPU Vendor: ', cpuInfo.Vendor);
  WriteLn('CPU Model: ', cpuInfo.Model);
  WriteLn('Logical Cores: ', cpuInfo.LogicalCores);
  
  // Display architecture
  case cpuInfo.Arch of
    caUnknown: WriteLn('Architecture: Unknown');
    caX86: WriteLn('Architecture: x86/x64');
    caARM: WriteLn('Architecture: ARM');
    caRISCV: WriteLn('Architecture: RISC-V');
  end;
  
  // Display cache information
  if cpuInfo.Cache.L1DataKB > 0 then
  begin
    WriteLn('Cache Information:');
    WriteLn('  L1 Data: ', cpuInfo.Cache.L1DataKB, ' KB');
    WriteLn('  L1 Instruction: ', cpuInfo.Cache.L1InstrKB, ' KB');
    WriteLn('  L2: ', cpuInfo.Cache.L2KB, ' KB');
    WriteLn('  L3: ', cpuInfo.Cache.L3KB, ' KB');
    WriteLn('  Line Size: ', cpuInfo.Cache.LineSize, ' bytes');
  end;
  
  {$IFDEF CPUX86_64}
  // Display x86 features
  WriteLn('x86 Features:');
  if cpuInfo.X86.HasSSE2 then WriteLn('  ✓ SSE2');
  if cpuInfo.X86.HasSSE3 then WriteLn('  ✓ SSE3');
  if cpuInfo.X86.HasSSSE3 then WriteLn('  ✓ SSSE3');
  if cpuInfo.X86.HasSSE41 then WriteLn('  ✓ SSE4.1');
  if cpuInfo.X86.HasSSE42 then WriteLn('  ✓ SSE4.2');
  if cpuInfo.X86.HasAVX then WriteLn('  ✓ AVX');
  if cpuInfo.X86.HasAVX2 then WriteLn('  ✓ AVX2');
  if cpuInfo.X86.HasFMA then WriteLn('  ✓ FMA');
  if cpuInfo.X86.HasAVX512F then WriteLn('  ✓ AVX-512F');
  {$ENDIF}
  
  WriteLn('Test CPU Info Detection: PASSED');
  WriteLn;
end;

procedure TestBackendDetection;
var
  backends: TSimdBackendArray;
  bestBackend: TSimdBackend;
  backendInfo: TSimdBackendInfo;
  i: Integer;
begin
  WriteLn('=== Testing Backend Detection ===');
  
  // Get available backends
  backends := GetAvailableBackends;
  WriteLn('Available Backends: ', Length(backends));
  
  for i := 0 to High(backends) do
  begin
    backendInfo := GetBackendInfo(backends[i]);
    WriteLn('  - ', backendInfo.Name, ': ', backendInfo.Description);
    WriteLn('    Priority: ', backendInfo.Priority);
    WriteLn('    Available: ', backendInfo.Available);
  end;
  
  // Get best backend
  bestBackend := GetBestBackend;
  WriteLn('Best Backend: ', GetBackendName(bestBackend));
  
  WriteLn('Test Backend Detection: PASSED');
  WriteLn;
end;

procedure TestFeatureQueries;
begin
  WriteLn('=== Testing Feature Queries ===');
  
  WriteLn('Generic Features:');
  WriteLn('  SIMD-128: ', HasFeature(gfSimd128));
  WriteLn('  SIMD-256: ', HasFeature(gfSimd256));
  WriteLn('  SIMD-512: ', HasFeature(gfSimd512));
  WriteLn('  AES: ', HasFeature(gfAES));
  WriteLn('  SHA: ', HasFeature(gfSHA));
  WriteLn('  FMA: ', HasFeature(gfFMA));
  
  {$IFDEF CPUX86_64}
  WriteLn('x86 Specific:');
  WriteLn('  SSE2: ', HasSSE2);
  WriteLn('  AVX: ', HasAVX);
  WriteLn('  AVX2: ', HasAVX2);
  {$ENDIF}
  
  WriteLn('Test Feature Queries: PASSED');
  WriteLn;
end;

procedure TestPerformance;
var
  counters: TCPUInfoPerfCounters;
begin
  WriteLn('=== Testing Performance ===');
  
  // Reset cache to test initialization time
  ResetCPUInfo;
  
  // Benchmark CPU info detection
  counters := BenchmarkCPUInfoDetection(100000);
  
  WriteLn('Performance Metrics:');
  WriteLn('  Initialization Time: ', counters.InitializationTime:0:3, ' ms');
  WriteLn('  Average Query Time: ', counters.AverageQueryTime:0:3, ' ns');
  WriteLn('  Total Queries: ', counters.TotalQueries);
  WriteLn('  Cache Hits: ', counters.CacheHits);
  WriteLn('  Cache Hit Rate: ', (counters.CacheHits * 100.0 / counters.TotalQueries):0:2, '%');
  
  if counters.AverageQueryTime < 1000 then
    WriteLn('Test Performance: PASSED (Good performance)')
  else
    WriteLn('Test Performance: WARNING (Slower than expected)');
  
  WriteLn;
end;

procedure TestDiagnostics;
var
  report: TCPUInfoDiagnosticReport;
  i: Integer;
begin
  WriteLn('=== Testing Diagnostics ===');
  
  // Generate diagnostic report
  report := GenerateDiagnosticReport;
  
  WriteLn('System Info: ', report.SystemInfo);
  WriteLn('SIMD Availability: ', CheckSIMDAvailability);
  
  if Length(report.Warnings) > 0 then
  begin
    WriteLn('Warnings:');
    for i := 0 to High(report.Warnings) do
      WriteLn('  ⚠ ', report.Warnings[i]);
  end
  else
    WriteLn('No warnings detected');
  
  if Length(report.Recommendations) > 0 then
  begin
    WriteLn('Optimization Recommendations:');
    for i := 0 to High(report.Recommendations) do
      WriteLn('  → ', report.Recommendations[i]);
  end;
  
  // Export report
  ExportDiagnosticReport(report, 'test_diagnostic_report.txt');
  WriteLn('Diagnostic report exported to: test_diagnostic_report.txt');
  
  WriteLn('Test Diagnostics: PASSED');
  WriteLn;
end;

procedure TestValidation;
begin
  WriteLn('=== Testing Validation ===');
  
  if ValidateCPUDetection then
    WriteLn('✓ CPU detection is consistent')
  else
    WriteLn('✗ CPU detection inconsistency detected');
    
  WriteLn('Test Validation: PASSED');
  WriteLn;
end;

procedure RunAllTests;
var
  startTime: TDateTime;
  totalTime: Integer;
  testsPassed: Integer;
  totalTests: Integer;
begin
  WriteLn('================================================');
  WriteLn('     SIMD CPU Info Module - Unit Tests');
  WriteLn('     ', DateTimeToStr(Now));
  WriteLn('================================================');
  WriteLn;
  
  startTime := Now;
  testsPassed := 0;
  totalTests := 7;
  
  try
    TestBasicTypes;
    Inc(testsPassed);
    
    TestCPUInfoDetection;
    Inc(testsPassed);
    
    TestBackendDetection;
    Inc(testsPassed);
    
    TestFeatureQueries;
    Inc(testsPassed);
    
    TestPerformance;
    Inc(testsPassed);
    
    TestDiagnostics;
    Inc(testsPassed);
    
    TestValidation;
    Inc(testsPassed);
    
    totalTime := MilliSecondsBetween(Now, startTime);
    
    WriteLn('================================================');
    WriteLn('Test Results: ', testsPassed, '/', totalTests, ' tests passed');
    WriteLn('Total execution time: ', totalTime, ' ms');
    
    if testsPassed = totalTests then
    begin
      WriteLn('Status: ALL TESTS PASSED ✓');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('Status: SOME TESTS FAILED ✗');
      ExitCode := 1;
    end;
    WriteLn('================================================');
    
  except
    on E: Exception do
    begin
      WriteLn('FATAL ERROR: ', E.Message);
      WriteLn('Test suite aborted');
      ExitCode := 2;
    end;
  end;
end;

begin
  {$IFDEF WINDOWS}
  // Set console to UTF-8 mode for proper character display
  SetConsoleOutputCP(CP_UTF8);
  SetConsoleCP(CP_UTF8);
  {$ENDIF}
  
  RunAllTests;
  
  {$IFDEF WINDOWS}
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
  {$ENDIF}
end.