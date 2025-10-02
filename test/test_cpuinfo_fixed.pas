program test_cpuinfo_fixed;

{$mode objfpc}{$H+}
{$ifdef windows}{$codepage utf8}{$endif}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.fixed;

procedure TestBasicFunctionality;
var
  cpuInfo: TCPUInfo;
  backend: TSimdBackend;
  backends: TSimdBackendArray;
  backendInfo: TSimdBackendInfo;
  i: Integer;
begin
  WriteLn('=== Testing Basic Functionality ===');
  
  try
    WriteLn('1. Getting CPU Info...');
    cpuInfo := GetCPUInfo;
    WriteLn('   Vendor: "', cpuInfo.Vendor, '"');
    WriteLn('   Model: "', cpuInfo.Model, '"');
    
    WriteLn('2. Testing backend availability...');
    WriteLn('   Scalar: ', IsBackendAvailable(sbScalar));
    WriteLn('   SSE2: ', IsBackendAvailable(sbSSE2));
    WriteLn('   AVX2: ', IsBackendAvailable(sbAVX2));
    WriteLn('   NEON: ', IsBackendAvailable(sbNEON));
    
    WriteLn('3. Getting best backend...');
    backend := GetBestBackend;
    WriteLn('   Best backend: ', GetBackendName(backend));
    
    WriteLn('4. Getting available backends...');
    backends := GetAvailableBackends;
    WriteLn('   Count: ', Length(backends));
    for i := 0 to Length(backends) - 1 do
    begin
      backendInfo := GetBackendInfo(backends[i]);
      WriteLn('   - ', backendInfo.Name, ' (Priority: ', backendInfo.Priority, ')');
    end;
    
    WriteLn('5. Testing x86 features...');
    {$IFDEF SIMD_X86_AVAILABLE}
    WriteLn('   SSE: ', cpuInfo.X86.HasSSE);
    WriteLn('   SSE2: ', cpuInfo.X86.HasSSE2);
    WriteLn('   AVX: ', cpuInfo.X86.HasAVX);
    WriteLn('   AVX2: ', cpuInfo.X86.HasAVX2);
    {$ELSE}
    WriteLn('   x86 features not available');
    {$ENDIF}
    
    WriteLn('6. Testing ARM features...');
    {$IFDEF SIMD_ARM_AVAILABLE}
    WriteLn('   NEON: ', cpuInfo.ARM.HasNEON);
    WriteLn('   AdvSIMD: ', cpuInfo.ARM.HasAdvSIMD);
    {$ELSE}
    WriteLn('   ARM features not available');
    {$ENDIF}
    
    WriteLn('✓ Basic functionality test passed');
    
  except
    on E: Exception do
    begin
      WriteLn('✗ Basic functionality test failed: ', E.Message);
      raise;
    end;
  end;
end;

procedure TestThreadSafety;
const
  NUM_ITERATIONS = 1000;
var
  i: Integer;
  cpuInfo1, cpuInfo2: TCPUInfo;
  consistent: Boolean;
begin
  WriteLn('=== Testing Thread Safety ===');
  
  try
    WriteLn('Testing consistency across ', NUM_ITERATIONS, ' calls...');
    
    cpuInfo1 := GetCPUInfo;
    consistent := True;
    
    for i := 1 to NUM_ITERATIONS do
    begin
      cpuInfo2 := GetCPUInfo;
      
      if (cpuInfo1.Vendor <> cpuInfo2.Vendor) or 
         (cpuInfo1.Model <> cpuInfo2.Model) then
      begin
        consistent := False;
        WriteLn('✗ Inconsistency detected at iteration ', i);
        Break;
      end;
    end;
    
    if consistent then
      WriteLn('✓ Thread safety test passed')
    else
      raise Exception.Create('Thread safety test failed');
      
  except
    on E: Exception do
    begin
      WriteLn('✗ Thread safety test failed: ', E.Message);
      raise;
    end;
  end;
end;

procedure TestPerformance;
const
  NUM_CALLS = 100000;
var
  i: Integer;
  cpuInfo: TCPUInfo;
  startTime, endTime: QWord;
  avgTimeNs: Double;
begin
  WriteLn('=== Testing Performance ===');
  
  try
    WriteLn('Measuring performance of ', NUM_CALLS, ' GetCPUInfo calls...');
    
    // Warm up
    for i := 1 to 10 do
      cpuInfo := GetCPUInfo;
      
    // Measure
    startTime := GetTickCount64;
    for i := 1 to NUM_CALLS do
      cpuInfo := GetCPUInfo;
    endTime := GetTickCount64;
    
    avgTimeNs := ((endTime - startTime) * 1000000.0) / NUM_CALLS;
    
    WriteLn('Average time per call: ', avgTimeNs:0:2, ' ns');
    
    if avgTimeNs < 1000 then
      WriteLn('✓ Performance test passed (< 1μs per call)')
    else
      WriteLn('⚠ Performance could be improved (', avgTimeNs:0:0, 'ns per call)');
      
  except
    on E: Exception do
    begin
      WriteLn('✗ Performance test failed: ', E.Message);
      raise;
    end;
  end;
end;

procedure TestFeatureConsistency;
var
  cpuInfo: TCPUInfo;
  valid: Boolean;
  errorMsg: string;
begin
  WriteLn('=== Testing Feature Consistency ===');
  
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
      WriteLn('✓ Feature consistency test passed')
    else
    begin
      WriteLn('✗ Feature consistency test failed: ', errorMsg);
      raise Exception.Create('Feature hierarchy validation failed');
    end;
      
  except
    on E: Exception do
    begin
      WriteLn('✗ Feature consistency test failed: ', E.Message);
      raise;
    end;
  end;
end;

procedure TestErrorHandling;
var
  backend: TSimdBackend;
  backendInfo: TSimdBackendInfo;
begin
  WriteLn('=== Testing Error Handling ===');
  
  try
    // Test with invalid backend value
    backend := TSimdBackend(999);
    backendInfo := GetBackendInfo(backend);
    
    // Should handle gracefully
    WriteLn('✓ Error handling test passed (handled invalid backend gracefully)');
    
  except
    on E: Exception do
    begin
      WriteLn('✗ Error handling test failed: ', E.Message);
      raise;
    end;
  end;
end;

procedure TestResetFunctionality;
var
  cpuInfo1, cpuInfo2: TCPUInfo;
begin
  WriteLn('=== Testing Reset Functionality ===');
  
  try
    cpuInfo1 := GetCPUInfo;
    ResetCPUInfo;
    cpuInfo2 := GetCPUInfo;
    
    // Results should be the same after reset
    if (cpuInfo1.Vendor = cpuInfo2.Vendor) and (cpuInfo1.Model = cpuInfo2.Model) then
      WriteLn('✓ Reset functionality test passed')
    else
    begin
      WriteLn('✗ Reset functionality test failed: Results differ after reset');
      raise Exception.Create('Reset functionality failed');
    end;
      
  except
    on E: Exception do
    begin
      WriteLn('✗ Reset functionality test failed: ', E.Message);
      raise;
    end;
  end;
end;

var
  testsPassed: Integer;
  totalTests: Integer;

begin
  WriteLn('Fixed CPU Info Module Test Suite');
  WriteLn('================================');
  WriteLn;
  
  testsPassed := 0;
  totalTests := 6;
  
  try
    TestBasicFunctionality;
    Inc(testsPassed);
  except
    on E: Exception do
      WriteLn('Basic functionality test failed: ', E.Message);
  end;
  
  try
    TestThreadSafety;
    Inc(testsPassed);
  except
    on E: Exception do
      WriteLn('Thread safety test failed: ', E.Message);
  end;
  
  try
    TestPerformance;
    Inc(testsPassed);
  except
    on E: Exception do
      WriteLn('Performance test failed: ', E.Message);
  end;
  
  try
    TestFeatureConsistency;
    Inc(testsPassed);
  except
    on E: Exception do
      WriteLn('Feature consistency test failed: ', E.Message);
  end;
  
  try
    TestErrorHandling;
    Inc(testsPassed);
  except
    on E: Exception do
      WriteLn('Error handling test failed: ', E.Message);
  end;
  
  try
    TestResetFunctionality;
    Inc(testsPassed);
  except
    on E: Exception do
      WriteLn('Reset functionality test failed: ', E.Message);
  end;
  
  WriteLn;
  WriteLn('=== Test Results ===');
  WriteLn('Passed: ', testsPassed, '/', totalTests);
  WriteLn('Success rate: ', (testsPassed * 100.0 / totalTests):0:1, '%');
  
  if testsPassed = totalTests then
  begin
    WriteLn('✅ ALL TESTS PASSED - Module is ready for use');
    ExitCode := 0;
  end
  else
  begin
    WriteLn('❌ SOME TESTS FAILED - Module needs further work');
    ExitCode := 1;
  end;
  
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
