program test_cpuinfo_real;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.real;

var
  outputFile: TextFile;
  cpuInfo: TCPUInfo;
  backend: TSimdBackend;
  backends: TSimdBackendArray;
  backendInfo: TSimdBackendInfo;
  i: Integer;
  testsPassed: Integer;

procedure WriteLog(const msg: string);
begin
  WriteLn(outputFile, msg);
  Flush(outputFile);
end;

procedure TestRealCPUID;
begin
  WriteLog('=== Testing Real CPUID Implementation ===');
  
  try
    WriteLog('1. Getting CPU Info with real CPUID...');
    cpuInfo := GetCPUInfo;
    WriteLog('   Vendor: "' + cpuInfo.Vendor + '"');
    WriteLog('   Model: "' + cpuInfo.Model + '"');
    
    if (cpuInfo.Vendor = '') or (cpuInfo.Model = '') then
      raise Exception.Create('CPU info is empty');
    
    // Check if we got real vendor strings (not simulated)
    if (cpuInfo.Vendor <> 'Intel/AMD') and (cpuInfo.Vendor <> 'Unknown') then
      WriteLog('   ✓ Real vendor detected: ' + cpuInfo.Vendor)
    else
      WriteLog('   ⚠ Vendor might be simulated');
    
    WriteLog('2. Testing x86 features with real detection...');
    {$IFDEF SIMD_X86_AVAILABLE}
    WriteLog('   SSE: ' + BoolToStr(cpuInfo.X86.HasSSE, True));
    WriteLog('   SSE2: ' + BoolToStr(cpuInfo.X86.HasSSE2, True));
    WriteLog('   SSE3: ' + BoolToStr(cpuInfo.X86.HasSSE3, True));
    WriteLog('   SSSE3: ' + BoolToStr(cpuInfo.X86.HasSSSE3, True));
    WriteLog('   SSE4.1: ' + BoolToStr(cpuInfo.X86.HasSSE41, True));
    WriteLog('   SSE4.2: ' + BoolToStr(cpuInfo.X86.HasSSE42, True));
    WriteLog('   AVX: ' + BoolToStr(cpuInfo.X86.HasAVX, True));
    WriteLog('   AVX2: ' + BoolToStr(cpuInfo.X86.HasAVX2, True));
    WriteLog('   FMA: ' + BoolToStr(cpuInfo.X86.HasFMA, True));
    WriteLog('   AVX512F: ' + BoolToStr(cpuInfo.X86.HasAVX512F, True));
    WriteLog('   AVX512DQ: ' + BoolToStr(cpuInfo.X86.HasAVX512DQ, True));
    WriteLog('   AVX512BW: ' + BoolToStr(cpuInfo.X86.HasAVX512BW, True));
    
    // Validate feature hierarchy
    if cpuInfo.X86.HasSSE2 and not cpuInfo.X86.HasSSE then
      WriteLog('   ⚠ Warning: SSE2 without SSE detected');
    if cpuInfo.X86.HasAVX2 and not cpuInfo.X86.HasAVX then
      WriteLog('   ⚠ Warning: AVX2 without AVX detected');
    if cpuInfo.X86.HasAVX512F and not cpuInfo.X86.HasAVX2 then
      WriteLog('   ⚠ Warning: AVX512F without AVX2 detected');
    {$ELSE}
    WriteLog('   x86 features not available in this build');
    {$ENDIF}
    
    WriteLog('3. Testing ARM features...');
    {$IFDEF SIMD_ARM_AVAILABLE}
    WriteLog('   NEON: ' + BoolToStr(cpuInfo.ARM.HasNEON, True));
    WriteLog('   AdvSIMD: ' + BoolToStr(cpuInfo.ARM.HasAdvSIMD, True));
    WriteLog('   FP: ' + BoolToStr(cpuInfo.ARM.HasFP, True));
    WriteLog('   SVE: ' + BoolToStr(cpuInfo.ARM.HasSVE, True));
    {$ELSE}
    WriteLog('   ARM features not available in this build');
    {$ENDIF}
    
    WriteLog('4. Testing backend availability...');
    WriteLog('   Scalar: ' + BoolToStr(IsBackendAvailable(sbScalar), True));
    WriteLog('   SSE2: ' + BoolToStr(IsBackendAvailable(sbSSE2), True));
    WriteLog('   AVX2: ' + BoolToStr(IsBackendAvailable(sbAVX2), True));
    WriteLog('   AVX512: ' + BoolToStr(IsBackendAvailable(sbAVX512), True));
    WriteLog('   NEON: ' + BoolToStr(IsBackendAvailable(sbNEON), True));
    
    WriteLog('5. Testing best backend selection...');
    backend := GetBestBackend;
    WriteLog('   Best backend: ' + GetBackendName(backend));
    
    WriteLog('6. Testing available backends...');
    backends := GetAvailableBackends;
    WriteLog('   Available backends count: ' + IntToStr(Length(backends)));
    for i := 0 to Length(backends) - 1 do
    begin
      backendInfo := GetBackendInfo(backends[i]);
      WriteLog('   - ' + backendInfo.Name + ' (Priority: ' + IntToStr(backendInfo.Priority) + ')');
    end;
    
    WriteLog('✓ Real CPUID test PASSED');
    Inc(testsPassed);
    
  except
    on E: Exception do
    begin
      WriteLog('✗ Real CPUID test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestConsistency;
const
  NUM_ITERATIONS = 1000;
var
  j: Integer;
  cpuInfo1, cpuInfo2: TCPUInfo;
  consistent: Boolean;
begin
  WriteLog('=== Testing Consistency ===');
  
  try
    WriteLog('Testing consistency across ' + IntToStr(NUM_ITERATIONS) + ' calls...');
    
    cpuInfo1 := GetCPUInfo;
    consistent := True;
    
    for j := 1 to NUM_ITERATIONS do
    begin
      cpuInfo2 := GetCPUInfo;
      
      if (cpuInfo1.Vendor <> cpuInfo2.Vendor) or 
         (cpuInfo1.Model <> cpuInfo2.Model) then
      begin
        consistent := False;
        WriteLog('✗ Inconsistency detected at iteration ' + IntToStr(j));
        Break;
      end;
      
      {$IFDEF SIMD_X86_AVAILABLE}
      if (cpuInfo1.X86.HasSSE <> cpuInfo2.X86.HasSSE) or
         (cpuInfo1.X86.HasSSE2 <> cpuInfo2.X86.HasSSE2) or
         (cpuInfo1.X86.HasAVX <> cpuInfo2.X86.HasAVX) or
         (cpuInfo1.X86.HasAVX2 <> cpuInfo2.X86.HasAVX2) then
      begin
        consistent := False;
        WriteLog('✗ x86 feature inconsistency detected at iteration ' + IntToStr(j));
        Break;
      end;
      {$ENDIF}
    end;
    
    if consistent then
    begin
      WriteLog('✓ Consistency test PASSED');
      Inc(testsPassed);
    end
    else
      WriteLog('✗ Consistency test FAILED');
      
  except
    on E: Exception do
    begin
      WriteLog('✗ Consistency test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestPerformance;
const
  NUM_CALLS = 10000;
var
  j: Integer;
  startTime, endTime: QWord;
  avgTimeNs: Double;
begin
  WriteLog('=== Testing Performance ===');
  
  try
    WriteLog('Measuring performance of ' + IntToStr(NUM_CALLS) + ' GetCPUInfo calls...');
    
    // Warm up
    for j := 1 to 10 do
      cpuInfo := GetCPUInfo;
      
    // Measure
    startTime := GetTickCount64;
    for j := 1 to NUM_CALLS do
      cpuInfo := GetCPUInfo;
    endTime := GetTickCount64;
    
    avgTimeNs := ((endTime - startTime) * 1000000.0) / NUM_CALLS;
    
    WriteLog('Average time per call: ' + FormatFloat('0.00', avgTimeNs) + ' ns');
    
    if avgTimeNs < 10000 then
    begin
      WriteLog('✓ Performance test PASSED (< 10μs per call)');
      Inc(testsPassed);
    end
    else
      WriteLog('⚠ Performance could be improved (' + FormatFloat('0.0', avgTimeNs) + 'ns per call)');
      
  except
    on E: Exception do
    begin
      WriteLog('✗ Performance test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestResetFunctionality;
var
  cpuInfo1, cpuInfo2: TCPUInfo;
begin
  WriteLog('=== Testing Reset Functionality ===');
  
  try
    cpuInfo1 := GetCPUInfo;
    ResetCPUInfo;
    cpuInfo2 := GetCPUInfo;
    
    // Results should be the same after reset
    if (cpuInfo1.Vendor = cpuInfo2.Vendor) and (cpuInfo1.Model = cpuInfo2.Model) then
    begin
      WriteLog('✓ Reset functionality test PASSED');
      Inc(testsPassed);
    end
    else
    begin
      WriteLog('✗ Reset functionality test FAILED: Results differ after reset');
      WriteLog('   Before: ' + cpuInfo1.Vendor + ' - ' + cpuInfo1.Model);
      WriteLog('   After: ' + cpuInfo2.Vendor + ' - ' + cpuInfo2.Model);
    end;
      
  except
    on E: Exception do
    begin
      WriteLog('✗ Reset functionality test FAILED: ' + E.Message);
    end;
  end;
end;

begin
  testsPassed := 0;
  
  // Open output file
  AssignFile(outputFile, 'test_real_results.txt');
  Rewrite(outputFile);
  
  try
    WriteLog('Real CPUID CPU Info Module Test Suite');
    WriteLog('====================================');
    WriteLog('Start time: ' + DateTimeToStr(Now));
    WriteLog('');
    
    TestRealCPUID;
    WriteLog('');
    
    TestConsistency;
    WriteLog('');
    
    TestPerformance;
    WriteLog('');
    
    TestResetFunctionality;
    WriteLog('');
    
    WriteLog('=== Test Results Summary ===');
    WriteLog('Tests passed: ' + IntToStr(testsPassed) + '/4');
    WriteLog('Success rate: ' + FormatFloat('0.0', (testsPassed * 100.0 / 4)) + '%');
    WriteLog('End time: ' + DateTimeToStr(Now));
    
    if testsPassed = 4 then
    begin
      WriteLog('✅ ALL TESTS PASSED - Real CPUID implementation is working');
      ExitCode := 0;
    end
    else
    begin
      WriteLog('❌ SOME TESTS FAILED - Real CPUID implementation needs attention');
      ExitCode := 1;
    end;
    
  finally
    CloseFile(outputFile);
  end;
  
  WriteLn('Real CPUID test completed. Check test_real_results.txt for detailed results.');
  WriteLn('Tests passed: ', testsPassed, '/4');
end.
