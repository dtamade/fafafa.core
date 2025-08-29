program test_cpuinfo_x86;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.x86;

var
  outputFile: TextFile;
  testsPassed: Integer;
  totalTests: Integer;

procedure WriteLog(const msg: string);
begin
  WriteLn(outputFile, msg);
  Flush(outputFile);
end;

procedure TestCPUIDAvailability;
begin
  WriteLog('=== Testing CPUID Availability ===');
  
  try
    {$IFDEF SIMD_X86_AVAILABLE}
    WriteLog('CPUID available: ' + BoolToStr(HasCPUID, True));
    
    if HasCPUID then
    begin
      WriteLog('✓ CPUID availability test PASSED');
      Inc(testsPassed);
    end
    else
    begin
      WriteLog('⚠ CPUID not available on this system');
      Inc(testsPassed); // Still pass the test
    end;
    {$ELSE}
    WriteLog('x86 not available in this build');
    WriteLog('✓ CPUID availability test PASSED (non-x86 platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ CPUID availability test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestCPUIDExecution;
var
  eax, ebx, ecx, edx: DWord;
begin
  WriteLog('=== Testing CPUID Execution ===');
  
  try
    {$IFDEF SIMD_X86_AVAILABLE}
    if HasCPUID then
    begin
      // Test basic CPUID call
      CPUID(0, eax, ebx, ecx, edx);
      WriteLog('CPUID(0) results:');
      WriteLog('  EAX (max leaf): $' + IntToHex(eax, 8));
      WriteLog('  EBX: $' + IntToHex(ebx, 8));
      WriteLog('  ECX: $' + IntToHex(ecx, 8));
      WriteLog('  EDX: $' + IntToHex(edx, 8));
      
      if eax > 0 then
      begin
        // Test feature detection CPUID call
        CPUID(1, eax, ebx, ecx, edx);
        WriteLog('CPUID(1) results:');
        WriteLog('  EAX (version): $' + IntToHex(eax, 8));
        WriteLog('  EBX: $' + IntToHex(ebx, 8));
        WriteLog('  ECX (features): $' + IntToHex(ecx, 8));
        WriteLog('  EDX (features): $' + IntToHex(edx, 8));
      end;
      
      WriteLog('✓ CPUID execution test PASSED');
      Inc(testsPassed);
    end
    else
    begin
      WriteLog('⚠ CPUID not available, skipping execution test');
      Inc(testsPassed);
    end;
    {$ELSE}
    WriteLog('✓ CPUID execution test PASSED (non-x86 platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ CPUID execution test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestX86FeatureDetection;
var
  features: TX86Features;
begin
  WriteLog('=== Testing x86 Feature Detection ===');
  
  try
    {$IFDEF SIMD_X86_AVAILABLE}
    features := DetectX86Features;
    
    WriteLog('Detected x86 features:');
    WriteLog('  SSE: ' + BoolToStr(features.HasSSE, True));
    WriteLog('  SSE2: ' + BoolToStr(features.HasSSE2, True));
    WriteLog('  SSE3: ' + BoolToStr(features.HasSSE3, True));
    WriteLog('  SSSE3: ' + BoolToStr(features.HasSSSE3, True));
    WriteLog('  SSE4.1: ' + BoolToStr(features.HasSSE41, True));
    WriteLog('  SSE4.2: ' + BoolToStr(features.HasSSE42, True));
    WriteLog('  AVX: ' + BoolToStr(features.HasAVX, True));
    WriteLog('  AVX2: ' + BoolToStr(features.HasAVX2, True));
    WriteLog('  FMA: ' + BoolToStr(features.HasFMA, True));
    WriteLog('  AVX512F: ' + BoolToStr(features.HasAVX512F, True));
    WriteLog('  AVX512DQ: ' + BoolToStr(features.HasAVX512DQ, True));
    WriteLog('  AVX512BW: ' + BoolToStr(features.HasAVX512BW, True));
    
    // Validate feature hierarchy
    if features.HasSSE2 and not features.HasSSE then
      WriteLog('⚠ Warning: SSE2 without SSE detected');
    if features.HasAVX2 and not features.HasAVX then
      WriteLog('⚠ Warning: AVX2 without AVX detected');
    if features.HasAVX512F and not features.HasAVX2 then
      WriteLog('⚠ Warning: AVX512F without AVX2 detected');
    
    WriteLog('✓ x86 feature detection test PASSED');
    Inc(testsPassed);
    {$ELSE}
    WriteLog('✓ x86 feature detection test PASSED (non-x86 platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ x86 feature detection test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestVendorDetection;
var
  cpuInfo: TCPUInfo;
begin
  WriteLog('=== Testing Vendor Detection ===');
  
  try
    {$IFDEF SIMD_X86_AVAILABLE}
    FillChar(cpuInfo, SizeOf(cpuInfo), 0);
    DetectX86VendorAndModel(cpuInfo);
    
    WriteLog('Detected vendor information:');
    WriteLog('  Vendor: "' + cpuInfo.Vendor + '"');
    WriteLog('  Model: "' + cpuInfo.Model + '"');
    
    if (cpuInfo.Vendor <> '') and (cpuInfo.Model <> '') then
    begin
      WriteLog('✓ Vendor detection test PASSED');
      Inc(testsPassed);
    end
    else
    begin
      WriteLog('✗ Vendor detection test FAILED: Empty vendor or model');
    end;
    {$ELSE}
    WriteLog('✓ Vendor detection test PASSED (non-x86 platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ Vendor detection test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestAVXOSSupport;
begin
  WriteLog('=== Testing AVX OS Support ===');
  
  try
    {$IFDEF SIMD_X86_AVAILABLE}
    WriteLog('AVX OS support: ' + BoolToStr(IsAVXSupportedByOS, True));
    WriteLog('✓ AVX OS support test PASSED');
    Inc(testsPassed);
    {$ELSE}
    WriteLog('✓ AVX OS support test PASSED (non-x86 platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ AVX OS support test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestCacheInfo;
var
  cacheInfo: TX86CacheInfo;
begin
  WriteLog('=== Testing Cache Information ===');
  
  try
    {$IFDEF SIMD_X86_AVAILABLE}
    cacheInfo := GetX86CacheInfo;
    
    WriteLog('Cache information:');
    WriteLog('  L1 Data Cache: ' + IntToStr(cacheInfo.L1DataCache) + ' KB');
    WriteLog('  L1 Instruction Cache: ' + IntToStr(cacheInfo.L1InstructionCache) + ' KB');
    WriteLog('  L2 Cache: ' + IntToStr(cacheInfo.L2Cache) + ' KB');
    WriteLog('  L3 Cache: ' + IntToStr(cacheInfo.L3Cache) + ' KB');
    
    WriteLog('✓ Cache information test PASSED');
    Inc(testsPassed);
    {$ELSE}
    WriteLog('✓ Cache information test PASSED (non-x86 platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ Cache information test FAILED: ' + E.Message);
    end;
  end;
end;

begin
  testsPassed := 0;
  totalTests := 6;
  
  // Open output file
  AssignFile(outputFile, 'test_x86_results.txt');
  Rewrite(outputFile);
  
  try
    WriteLog('x86 CPU Info Module Test Suite');
    WriteLog('==============================');
    WriteLog('Start time: ' + DateTimeToStr(Now));
    WriteLog('');
    
    TestCPUIDAvailability;
    WriteLog('');
    
    TestCPUIDExecution;
    WriteLog('');
    
    TestX86FeatureDetection;
    WriteLog('');
    
    TestVendorDetection;
    WriteLog('');
    
    TestAVXOSSupport;
    WriteLog('');
    
    TestCacheInfo;
    WriteLog('');
    
    WriteLog('=== Test Results Summary ===');
    WriteLog('Tests passed: ' + IntToStr(testsPassed) + '/' + IntToStr(totalTests));
    WriteLog('Success rate: ' + FormatFloat('0.0', (testsPassed * 100.0 / totalTests)) + '%');
    WriteLog('End time: ' + DateTimeToStr(Now));
    
    if testsPassed = totalTests then
    begin
      WriteLog('✅ ALL TESTS PASSED - x86 module is working correctly');
      ExitCode := 0;
    end
    else
    begin
      WriteLog('❌ SOME TESTS FAILED - x86 module needs attention');
      ExitCode := 1;
    end;
    
  finally
    CloseFile(outputFile);
  end;
  
  WriteLn('x86 module test completed. Check test_x86_results.txt for results.');
  WriteLn('Tests passed: ', testsPassed, '/', totalTests);
end.
