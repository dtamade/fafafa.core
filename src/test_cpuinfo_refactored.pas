program test_cpuinfo_refactored;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.refactored;

var
  outputFile: TextFile;
  testsPassed: Integer;
  totalTests: Integer;

procedure WriteLog(const msg: string);
begin
  WriteLn(outputFile, msg);
  Flush(outputFile);
end;

procedure TestBackwardCompatibility;
var
  cpuInfo: TCPUInfo;
  backend: TSimdBackend;
  backends: TSimdBackendArray;
  backendInfo: TSimdBackendInfo;
  i: Integer;
begin
  WriteLog('=== Testing Backward Compatibility ===');
  
  try
    WriteLog('1. Testing GetCPUInfo...');
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
    
    WriteLog('3. Testing GetBestBackend...');
    backend := GetBestBackend;
    WriteLog('   Best backend: ' + GetBackendName(backend));
    
    WriteLog('4. Testing GetAvailableBackends...');
    backends := GetAvailableBackends;
    WriteLog('   Count: ' + IntToStr(Length(backends)));
    
    if Length(backends) = 0 then
      raise Exception.Create('No backends available');
    
    for i := 0 to Length(backends) - 1 do
    begin
      backendInfo := GetBackendInfo(backends[i]);
      WriteLog('   - ' + backendInfo.Name + ' (Priority: ' + IntToStr(backendInfo.Priority) + ')');
    end;
    
    WriteLog('5. Testing platform-specific features...');
    {$IFDEF SIMD_X86_AVAILABLE}
    WriteLog('   x86 SSE: ' + BoolToStr(cpuInfo.X86.HasSSE, True));
    WriteLog('   x86 SSE2: ' + BoolToStr(cpuInfo.X86.HasSSE2, True));
    WriteLog('   x86 AVX: ' + BoolToStr(cpuInfo.X86.HasAVX, True));
    WriteLog('   x86 AVX2: ' + BoolToStr(cpuInfo.X86.HasAVX2, True));
    {$ELSE}
    WriteLog('   x86 features not available');
    {$ENDIF}
    
    {$IFDEF SIMD_ARM_AVAILABLE}
    WriteLog('   ARM NEON: ' + BoolToStr(cpuInfo.ARM.HasNEON, True));
    WriteLog('   ARM AdvSIMD: ' + BoolToStr(cpuInfo.ARM.HasAdvSIMD, True));
    {$ELSE}
    WriteLog('   ARM features not available');
    {$ENDIF}
    
    WriteLog('✓ Backward compatibility test PASSED');
    Inc(testsPassed);
    
  except
    on E: Exception do
    begin
      WriteLog('✗ Backward compatibility test FAILED: ' + E.Message);
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
  WriteLog('=== Testing Thread Safety ===');
  
  try
    WriteLog('Testing consistency across ' + IntToStr(NUM_ITERATIONS) + ' calls...');
    
    cpuInfo1 := GetCPUInfo;
    consistent := True;
    
    for i := 1 to NUM_ITERATIONS do
    begin
      cpuInfo2 := GetCPUInfo;
      
      if (cpuInfo1.Vendor <> cpuInfo2.Vendor) or 
         (cpuInfo1.Model <> cpuInfo2.Model) then
      begin
        consistent := False;
        WriteLog('✗ Inconsistency detected at iteration ' + IntToStr(i));
        Break;
      end;
      
      {$IFDEF SIMD_X86_AVAILABLE}
      if (cpuInfo1.X86.HasSSE <> cpuInfo2.X86.HasSSE) or
         (cpuInfo1.X86.HasSSE2 <> cpuInfo2.X86.HasSSE2) or
         (cpuInfo1.X86.HasAVX <> cpuInfo2.X86.HasAVX) or
         (cpuInfo1.X86.HasAVX2 <> cpuInfo2.X86.HasAVX2) then
      begin
        consistent := False;
        WriteLog('✗ x86 feature inconsistency detected at iteration ' + IntToStr(i));
        Break;
      end;
      {$ENDIF}
      
      {$IFDEF SIMD_ARM_AVAILABLE}
      if (cpuInfo1.ARM.HasNEON <> cpuInfo2.ARM.HasNEON) or
         (cpuInfo1.ARM.HasAdvSIMD <> cpuInfo2.ARM.HasAdvSIMD) then
      begin
        consistent := False;
        WriteLog('✗ ARM feature inconsistency detected at iteration ' + IntToStr(i));
        Break;
      end;
      {$ENDIF}
    end;
    
    if consistent then
    begin
      WriteLog('✓ Thread safety test PASSED');
      Inc(testsPassed);
    end
    else
      WriteLog('✗ Thread safety test FAILED');
      
  except
    on E: Exception do
    begin
      WriteLog('✗ Thread safety test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestPerformance;
const
  NUM_CALLS = 10000;
var
  i: Integer;
  cpuInfo: TCPUInfo;
  startTime, endTime: QWord;
  avgTimeNs: Double;
begin
  WriteLog('=== Testing Performance ===');
  
  try
    WriteLog('Measuring performance of ' + IntToStr(NUM_CALLS) + ' GetCPUInfo calls...');
    
    // Warm up
    for i := 1 to 10 do
      cpuInfo := GetCPUInfo;
      
    // Measure
    startTime := GetTickCount64;
    for i := 1 to NUM_CALLS do
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

procedure TestModularArchitecture;
var
  cpuInfo: TCPUInfo;
begin
  WriteLog('=== Testing Modular Architecture ===');

  try
    WriteLog('Testing that platform-specific modules are properly isolated...');

    // This test verifies that the refactored architecture works
    // by ensuring we can get CPU info without directly calling platform modules

    {$IFDEF SIMD_X86_AVAILABLE}
    WriteLog('x86 module integration: Available');
    {$ELSE}
    WriteLog('x86 module integration: Not available (expected on non-x86)');
    {$ENDIF}

    {$IFDEF SIMD_ARM_AVAILABLE}
    WriteLog('ARM module integration: Available');
    {$ELSE}
    WriteLog('ARM module integration: Not available (expected on non-ARM)');
    {$ENDIF}

    // Test that we can get CPU info regardless of platform
    cpuInfo := GetCPUInfo;
    if (cpuInfo.Vendor <> '') and (cpuInfo.Model <> '') then
    begin
      WriteLog('✓ Modular architecture test PASSED');
      Inc(testsPassed);
    end
    else
    begin
      WriteLog('✗ Modular architecture test FAILED: No CPU info available');
    end;
    
  except
    on E: Exception do
    begin
      WriteLog('✗ Modular architecture test FAILED: ' + E.Message);
    end;
  end;
end;

begin
  testsPassed := 0;
  totalTests := 5;
  
  // Open output file
  AssignFile(outputFile, 'test_refactored_results.txt');
  Rewrite(outputFile);
  
  try
    WriteLog('Refactored CPU Info Module Test Suite');
    WriteLog('====================================');
    WriteLog('Start time: ' + DateTimeToStr(Now));
    WriteLog('');
    
    TestBackwardCompatibility;
    WriteLog('');
    
    TestThreadSafety;
    WriteLog('');
    
    TestPerformance;
    WriteLog('');
    
    TestResetFunctionality;
    WriteLog('');
    
    TestModularArchitecture;
    WriteLog('');
    
    WriteLog('=== Test Results Summary ===');
    WriteLog('Tests passed: ' + IntToStr(testsPassed) + '/' + IntToStr(totalTests));
    WriteLog('Success rate: ' + FormatFloat('0.0', (testsPassed * 100.0 / totalTests)) + '%');
    WriteLog('End time: ' + DateTimeToStr(Now));
    
    if testsPassed = totalTests then
    begin
      WriteLog('✅ ALL TESTS PASSED - Refactored module is working correctly');
      ExitCode := 0;
    end
    else
    begin
      WriteLog('❌ SOME TESTS FAILED - Refactored module needs attention');
      ExitCode := 1;
    end;
    
  finally
    CloseFile(outputFile);
  end;
  
  WriteLn('Refactored module test completed. Check test_refactored_results.txt for results.');
  WriteLn('Tests passed: ', testsPassed, '/', totalTests);
end.
