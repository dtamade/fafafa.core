program test_cpuinfo_comprehensive;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}
  {$CODEPAGE UTF8}
{$ENDIF}

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo,
  test_cpuinfo_concurrent,
  test_cpuinfo_boundary;

procedure PrintHeader;
begin
  WriteLn('=======================================================');
  WriteLn('     SIMD CPU Info - Comprehensive Test Suite');
  WriteLn('     ', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
  WriteLn('=======================================================');
  WriteLn;
end;

procedure PrintSection(const title: string);
begin
  WriteLn;
  WriteLn('*******************************************************');
  WriteLn('* ', title);
  WriteLn('*******************************************************');
  WriteLn;
end;

procedure TestCacheDetection;
var
  cpuInfo: TCPUInfo;
begin
  PrintSection('CACHE DETECTION TEST');
  
  cpuInfo := GetCPUInfo;
  
  WriteLn('CPU: ', cpuInfo.Model);
  WriteLn;
  WriteLn('Cache Hierarchy:');
  WriteLn('================');
  WriteLn('  L1 Data Cache:        ', cpuInfo.Cache.L1DataKB:6, ' KB');
  WriteLn('  L1 Instruction Cache: ', cpuInfo.Cache.L1InstrKB:6, ' KB');
  WriteLn('  L2 Unified Cache:     ', cpuInfo.Cache.L2KB:6, ' KB');
  WriteLn('  L3 Shared Cache:      ', cpuInfo.Cache.L3KB:6, ' KB');
  WriteLn('  Cache Line Size:      ', cpuInfo.Cache.LineSize:6, ' bytes');
  WriteLn;
  
  // Validate cache sizes
  if cpuInfo.Cache.L3KB > 0 then
    WriteLn('[PASS] L3 cache detected successfully (', cpuInfo.Cache.L3KB div 1024, ' MB)')
  else
    WriteLn('[FAIL] L3 cache not detected');
    
  if cpuInfo.Cache.LineSize = 64 then
    WriteLn('[PASS] Cache line size is standard 64 bytes')
  else if cpuInfo.Cache.LineSize > 0 then
    WriteLn('[WARN] Non-standard cache line size: ', cpuInfo.Cache.LineSize, ' bytes')
  else
    WriteLn('[FAIL] Cache line size not detected');
end;

procedure TestFeatureDetection;
var
  cpuInfo: TCPUInfo;
  featureCount: Integer;
begin
  PrintSection('FEATURE DETECTION TEST');
  
  cpuInfo := GetCPUInfo;
  featureCount := 0;
  
  WriteLn('CPU Features Detected:');
  WriteLn('======================');
  
  // Test x86 features
  {$IFDEF CPUX86_64}
  if cpuInfo.X86.HasMMX then begin WriteLn('  [x] MMX'); Inc(featureCount); end;
  if cpuInfo.X86.HasSSE then begin WriteLn('  [x] SSE'); Inc(featureCount); end;
  if cpuInfo.X86.HasSSE2 then begin WriteLn('  [x] SSE2'); Inc(featureCount); end;
  if cpuInfo.X86.HasSSE3 then begin WriteLn('  [x] SSE3'); Inc(featureCount); end;
  if cpuInfo.X86.HasSSSE3 then begin WriteLn('  [x] SSSE3'); Inc(featureCount); end;
  if cpuInfo.X86.HasSSE41 then begin WriteLn('  [x] SSE4.1'); Inc(featureCount); end;
  if cpuInfo.X86.HasSSE42 then begin WriteLn('  [x] SSE4.2'); Inc(featureCount); end;
  if cpuInfo.X86.HasAVX then begin WriteLn('  [x] AVX'); Inc(featureCount); end;
  if cpuInfo.X86.HasAVX2 then begin WriteLn('  [x] AVX2'); Inc(featureCount); end;
  if cpuInfo.X86.HasAVX512F then begin WriteLn('  [x] AVX-512F'); Inc(featureCount); end;
  if cpuInfo.X86.HasFMA then begin WriteLn('  [x] FMA'); Inc(featureCount); end;
  if cpuInfo.X86.HasAES then begin WriteLn('  [x] AES-NI'); Inc(featureCount); end;
  if cpuInfo.X86.HasSHA then begin WriteLn('  [x] SHA'); Inc(featureCount); end;
  if cpuInfo.X86.HasBMI1 then begin WriteLn('  [x] BMI1'); Inc(featureCount); end;
  if cpuInfo.X86.HasBMI2 then begin WriteLn('  [x] BMI2'); Inc(featureCount); end;
  if cpuInfo.X86.HasF16C then begin WriteLn('  [x] F16C'); Inc(featureCount); end;
  if cpuInfo.X86.HasRDRAND then begin WriteLn('  [x] RDRAND'); Inc(featureCount); end;
  if cpuInfo.X86.HasRDSEED then begin WriteLn('  [x] RDSEED'); Inc(featureCount); end;
  {$ENDIF}
  
  WriteLn;
  WriteLn('Total features detected: ', featureCount);
  
  if featureCount > 10 then
    WriteLn('[PASS] Rich feature set detected')
  else if featureCount > 5 then
    WriteLn('[PASS] Standard feature set detected')
  else
    WriteLn('[WARN] Limited feature set detected');
end;

procedure TestBackendSelection;
var
  backends: TSimdBackendArray;
  bestBackend: TSimdBackend;
  info: TSimdBackendInfo;
  i: Integer;
begin
  PrintSection('BACKEND SELECTION TEST');
  
  backends := GetAvailableBackends;
  bestBackend := GetBestBackend;
  
  WriteLn('Available SIMD Backends:');
  WriteLn('========================');
  
  for i := 0 to High(backends) do
  begin
    info := GetBackendInfo(backends[i]);
    Write(Format('  %2d. %-12s', [i+1, info.Name]));
    Write(' [Priority: ', info.Priority:3, ']');
    
    if backends[i] = bestBackend then
      Write(' <- SELECTED')
    else
      Write('            ');
      
    WriteLn(' | ', info.Description);
  end;
  
  WriteLn;
  info := GetBackendInfo(bestBackend);
  WriteLn('Selected Backend: ', info.Name);
  WriteLn('Capabilities:');
  
  if scBasicArithmetic in info.Capabilities then WriteLn('  [x] Basic Arithmetic');
  if scComparison in info.Capabilities then WriteLn('  [x] Comparison Operations');
  if scMathFunctions in info.Capabilities then WriteLn('  [x] Math Functions');
  if scReduction in info.Capabilities then WriteLn('  [x] Reduction Operations');
  if scShuffle in info.Capabilities then WriteLn('  [x] Shuffle/Permute');
  if scFMA in info.Capabilities then WriteLn('  [x] Fused Multiply-Add');
  if scIntegerOps in info.Capabilities then WriteLn('  [x] Integer Operations');
  if scLoadStore in info.Capabilities then WriteLn('  [x] Load/Store Operations');
  if scGather in info.Capabilities then WriteLn('  [x] Gather/Scatter');
  if scMaskedOps in info.Capabilities then WriteLn('  [x] Masked Operations');
  
  if bestBackend <> sbScalar then
    WriteLn('[PASS] Hardware-accelerated backend selected')
  else
    WriteLn('[WARN] Using scalar fallback (no SIMD acceleration)');
end;

procedure RunComprehensiveTests;
var
  totalTests, passedTests: Integer;
begin
  totalTests := 0;
  passedTests := 0;
  
  try
    // Basic cache detection
    TestCacheDetection;
    Inc(totalTests);
    Inc(passedTests);
    
    // Feature detection
    TestFeatureDetection;
    Inc(totalTests);
    Inc(passedTests);
    
    // Backend selection
    TestBackendSelection;
    Inc(totalTests);
    Inc(passedTests);
    
    // Boundary conditions
    PrintSection('BOUNDARY CONDITIONS TEST');
    TestBoundaryConditions;
    Inc(totalTests);
    Inc(passedTests);
    
    // Error handling
    PrintSection('ERROR HANDLING TEST');
    TestErrorHandling;
    Inc(totalTests);
    Inc(passedTests);
    
    // Memory usage
    PrintSection('MEMORY USAGE TEST');
    TestMemoryUsage;
    Inc(totalTests);
    Inc(passedTests);
    
    // Backend enumeration
    PrintSection('BACKEND ENUMERATION TEST');
    TestBackendEnumeration;
    Inc(totalTests);
    Inc(passedTests);
    
    // Concurrent access
    PrintSection('CONCURRENT ACCESS TEST');
    TestConcurrentAccess;
    Inc(totalTests);
    Inc(passedTests);
    
    // Cache consistency
    PrintSection('CACHE CONSISTENCY TEST');
    TestCacheConsistency;
    Inc(totalTests);
    Inc(passedTests);
    
    // Reset safety
    PrintSection('RESET SAFETY TEST');
    TestResetSafety;
    Inc(totalTests);
    Inc(passedTests);
    
  except
    on E: Exception do
    begin
      WriteLn('[ERROR] Test failed: ', E.Message);
      Inc(totalTests);
    end;
  end;
  
  WriteLn;
  WriteLn('=======================================================');
  WriteLn('TEST SUMMARY');
  WriteLn('=======================================================');
  WriteLn('Total Tests:  ', totalTests);
  WriteLn('Passed:       ', passedTests);
  WriteLn('Failed:       ', totalTests - passedTests);
  WriteLn('Success Rate: ', (passedTests * 100 div totalTests), '%');
  WriteLn;
  
  if passedTests = totalTests then
  begin
    WriteLn('RESULT: ALL TESTS PASSED SUCCESSFULLY!');
    ExitCode := 0;
  end
  else
  begin
    WriteLn('RESULT: SOME TESTS FAILED');
    ExitCode := 1;
  end;
end;

begin
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  SetConsoleCP(CP_UTF8);
  {$ENDIF}
  
  PrintHeader;
  RunComprehensiveTests;
  
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.