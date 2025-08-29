program test_cpuinfo_working;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo;

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

procedure TestBasicFunctionality;
begin
  WriteLog('=== Testing Basic Functionality ===');
  
  try
    WriteLog('1. Getting CPU Info...');
    cpuInfo := GetCPUInfo;
    WriteLog('   Vendor: "' + cpuInfo.Vendor + '"');
    WriteLog('   Model: "' + cpuInfo.Model + '"');
    
    if (cpuInfo.Vendor = '') or (cpuInfo.Model = '') then
      raise Exception.Create('CPU info is empty');
    
    WriteLog('2. Testing backend availability...');
    WriteLog('   Scalar: ' + BoolToStr(IsBackendAvailable(sbScalar), True));
    WriteLog('   SSE2: ' + BoolToStr(IsBackendAvailable(sbSSE2), True));
    WriteLog('   AVX2: ' + BoolToStr(IsBackendAvailable(sbAVX2), True));
    WriteLog('   NEON: ' + BoolToStr(IsBackendAvailable(sbNEON), True));
    
    if not IsBackendAvailable(sbScalar) then
      raise Exception.Create('Scalar backend must always be available');
    
    WriteLog('3. Getting best backend...');
    backend := GetBestBackend;
    WriteLog('   Best backend: ' + GetBackendName(backend));
    
    WriteLog('4. Getting available backends...');
    backends := GetAvailableBackends;
    WriteLog('   Count: ' + IntToStr(Length(backends)));
    
    if Length(backends) = 0 then
      raise Exception.Create('No backends available');
    
    for i := 0 to Length(backends) - 1 do
    begin
      backendInfo := GetBackendInfo(backends[i]);
      WriteLog('   - ' + backendInfo.Name + ' (Priority: ' + IntToStr(backendInfo.Priority) + ')');
    end;
    
    WriteLog('5. Testing x86 features...');
    {$IFDEF SIMD_X86_AVAILABLE}
    WriteLog('   SSE: ' + BoolToStr(cpuInfo.X86.HasSSE, True));
    WriteLog('   SSE2: ' + BoolToStr(cpuInfo.X86.HasSSE2, True));
    WriteLog('   AVX: ' + BoolToStr(cpuInfo.X86.HasAVX, True));
    WriteLog('   AVX2: ' + BoolToStr(cpuInfo.X86.HasAVX2, True));
    {$ELSE}
    WriteLog('   x86 features not available');
    {$ENDIF}
    
    WriteLog('6. Testing ARM features...');
    {$IFDEF SIMD_ARM_AVAILABLE}
    WriteLog('   NEON: ' + BoolToStr(cpuInfo.ARM.HasNEON, True));
    WriteLog('   AdvSIMD: ' + BoolToStr(cpuInfo.ARM.HasAdvSIMD, True));
    {$ELSE}
    WriteLog('   ARM features not available');
    {$ENDIF}
    
    WriteLog('✓ Basic functionality test PASSED');
    Inc(testsPassed);
    
  except
    on E: Exception do
    begin
      WriteLog('✗ Basic functionality test FAILED: ' + E.Message);
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

procedure TestFeatureHierarchy;
var
  valid: Boolean;
  errorMsg: string;
begin
  WriteLog('=== Testing Feature Hierarchy ===');
  
  try
    cpuInfo := GetCPUInfo;
    valid := True;
    errorMsg := '';
    
    {$IFDEF SIMD_X86_AVAILABLE}
    // Test x86 feature dependencies
    if cpuInfo.X86.HasSSE2 and not cpuInfo.X86.HasSSE then
    begin
      valid := False;
      errorMsg := errorMsg + 'SSE2 without SSE; ';
    end;
    
    if cpuInfo.X86.HasAVX2 and not cpuInfo.X86.HasAVX then
    begin
      valid := False;
      errorMsg := errorMsg + 'AVX2 without AVX; ';
    end;
    
    if cpuInfo.X86.HasAVX512F and not cpuInfo.X86.HasAVX2 then
    begin
      valid := False;
      errorMsg := errorMsg + 'AVX512F without AVX2; ';
    end;
    
    if cpuInfo.X86.HasSSE3 and not cpuInfo.X86.HasSSE2 then
    begin
      valid := False;
      errorMsg := errorMsg + 'SSE3 without SSE2; ';
    end;
    {$ENDIF}
    
    if valid then
    begin
      WriteLog('✓ Feature hierarchy test PASSED');
      Inc(testsPassed);
    end
    else
      WriteLog('✗ Feature hierarchy test FAILED: ' + errorMsg);
      
  except
    on E: Exception do
    begin
      WriteLog('✗ Feature hierarchy test FAILED: ' + E.Message);
    end;
  end;
end;

begin
  testsPassed := 0;
  
  // Open output file
  AssignFile(outputFile, 'test_results.txt');
  Rewrite(outputFile);
  
  try
    WriteLog('CPU Info Module Test Suite');
    WriteLog('==========================');
    WriteLog('Start time: ' + DateTimeToStr(Now));
    WriteLog('');
    
    TestBasicFunctionality;
    WriteLog('');
    
    TestConsistency;
    WriteLog('');
    
    TestPerformance;
    WriteLog('');
    
    TestFeatureHierarchy;
    WriteLog('');
    
    WriteLog('=== Test Results Summary ===');
    WriteLog('Tests passed: ' + IntToStr(testsPassed) + '/4');
    WriteLog('Success rate: ' + FormatFloat('0.0', (testsPassed * 100.0 / 4)) + '%');
    WriteLog('End time: ' + DateTimeToStr(Now));
    
    if testsPassed = 4 then
    begin
      WriteLog('✅ ALL TESTS PASSED - Module is working correctly');
      ExitCode := 0;
    end
    else
    begin
      WriteLog('❌ SOME TESTS FAILED - Module needs attention');
      ExitCode := 1;
    end;
    
  finally
    CloseFile(outputFile);
  end;
  
  // Also try console output (even if garbled)
  WriteLn('Test completed. Check test_results.txt for detailed results.');
  WriteLn('Tests passed: ', testsPassed, '/4');
end.
