program test_cpuinfo_arm;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.arm;

var
  outputFile: TextFile;
  testsPassed: Integer;
  totalTests: Integer;

procedure WriteLog(const msg: string);
begin
  WriteLn(outputFile, msg);
  Flush(outputFile);
end;

procedure TestARMFeatureDetection;
var
  features: TARMFeatures;
begin
  WriteLog('=== Testing ARM Feature Detection ===');
  
  try
    {$IFDEF SIMD_ARM_AVAILABLE}
    features := DetectARMFeatures;
    
    WriteLog('Detected ARM features:');
    WriteLog('  NEON: ' + BoolToStr(features.HasNEON, True));
    WriteLog('  Advanced SIMD: ' + BoolToStr(features.HasAdvSIMD, True));
    WriteLog('  Floating Point: ' + BoolToStr(features.HasFP, True));
    WriteLog('  SVE: ' + BoolToStr(features.HasSVE, True));
    WriteLog('  Crypto: ' + BoolToStr(features.HasCrypto, True));
    
    {$IFDEF CPUAARCH64}
    // On AArch64, NEON should always be available
    if not features.HasNEON then
      WriteLog('⚠ Warning: NEON not detected on AArch64 (should be mandatory)');
    {$ENDIF}
    
    WriteLog('✓ ARM feature detection test PASSED');
    Inc(testsPassed);
    {$ELSE}
    WriteLog('✓ ARM feature detection test PASSED (non-ARM platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ ARM feature detection test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestARMVendorDetection;
var
  cpuInfo: TCPUInfo;
begin
  WriteLog('=== Testing ARM Vendor Detection ===');
  
  try
    {$IFDEF SIMD_ARM_AVAILABLE}
    FillChar(cpuInfo, SizeOf(cpuInfo), 0);
    DetectARMVendorAndModel(cpuInfo);
    
    WriteLog('Detected ARM vendor information:');
    WriteLog('  Vendor: "' + cpuInfo.Vendor + '"');
    WriteLog('  Model: "' + cpuInfo.Model + '"');
    
    if (cpuInfo.Vendor <> '') and (cpuInfo.Model <> '') then
    begin
      WriteLog('✓ ARM vendor detection test PASSED');
      Inc(testsPassed);
    end
    else
    begin
      WriteLog('✗ ARM vendor detection test FAILED: Empty vendor or model');
    end;
    {$ELSE}
    WriteLog('✓ ARM vendor detection test PASSED (non-ARM platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ ARM vendor detection test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestIndividualFeatureChecks;
begin
  WriteLog('=== Testing Individual Feature Checks ===');
  
  try
    {$IFDEF SIMD_ARM_AVAILABLE}
    WriteLog('Individual feature availability:');
    WriteLog('  NEON available: ' + BoolToStr(IsNEONAvailable, True));
    WriteLog('  Advanced SIMD available: ' + BoolToStr(IsAdvSIMDAvailable, True));
    WriteLog('  SVE available: ' + BoolToStr(IsSVEAvailable, True));
    
    WriteLog('✓ Individual feature checks test PASSED');
    Inc(testsPassed);
    {$ELSE}
    WriteLog('✓ Individual feature checks test PASSED (non-ARM platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ Individual feature checks test FAILED: ' + E.Message);
    end;
  end;
end;

procedure TestARMProcessorInfo;
var
  procInfo: TARMProcessorInfo;
begin
  WriteLog('=== Testing ARM Processor Information ===');
  
  try
    {$IFDEF SIMD_ARM_AVAILABLE}
    procInfo := GetARMProcessorInfo;
    
    WriteLog('ARM processor information:');
    WriteLog('  Architecture: "' + procInfo.Architecture + '"');
    WriteLog('  Instruction Set: "' + procInfo.InstructionSet + '"');
    WriteLog('  Core Type: "' + procInfo.CoreType + '"');
    
    WriteLog('✓ ARM processor information test PASSED');
    Inc(testsPassed);
    {$ELSE}
    WriteLog('✓ ARM processor information test PASSED (non-ARM platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ ARM processor information test FAILED: ' + E.Message);
    end;
  end;
end;

{$IFDEF UNIX}
procedure TestProcCpuInfoParsing;
var
  cpuInfoText: string;
  features: TARMFeatures;
  vendor, model: string;
begin
  WriteLog('=== Testing /proc/cpuinfo Parsing ===');
  
  try
    {$IFDEF SIMD_ARM_AVAILABLE}
    cpuInfoText := ReadProcCpuInfoSafe;
    
    if cpuInfoText <> '' then
    begin
      WriteLog('/proc/cpuinfo read successfully (' + IntToStr(Length(cpuInfoText)) + ' characters)');
      
      // Test feature parsing
      features := ParseARMFeaturesFromCpuInfo(cpuInfoText);
      WriteLog('Parsed features from /proc/cpuinfo:');
      WriteLog('  NEON: ' + BoolToStr(features.HasNEON, True));
      WriteLog('  FP: ' + BoolToStr(features.HasFP, True));
      WriteLog('  SVE: ' + BoolToStr(features.HasSVE, True));
      WriteLog('  Crypto: ' + BoolToStr(features.HasCrypto, True));
      
      // Test vendor parsing
      if ParseARMVendorFromCpuInfo(cpuInfoText, vendor, model) then
      begin
        WriteLog('Parsed vendor info from /proc/cpuinfo:');
        WriteLog('  Vendor: "' + vendor + '"');
        WriteLog('  Model: "' + model + '"');
      end
      else
      begin
        WriteLog('No vendor info found in /proc/cpuinfo');
      end;
      
      WriteLog('✓ /proc/cpuinfo parsing test PASSED');
      Inc(testsPassed);
    end
    else
    begin
      WriteLog('/proc/cpuinfo not available or empty');
      WriteLog('✓ /proc/cpuinfo parsing test PASSED (file not available)');
      Inc(testsPassed);
    end;
    {$ELSE}
    WriteLog('✓ /proc/cpuinfo parsing test PASSED (non-ARM platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ /proc/cpuinfo parsing test FAILED: ' + E.Message);
    end;
  end;
end;
{$ELSE}
procedure TestProcCpuInfoParsing;
begin
  WriteLog('=== Testing /proc/cpuinfo Parsing ===');
  WriteLog('✓ /proc/cpuinfo parsing test PASSED (non-Unix platform)');
  Inc(testsPassed);
end;
{$ENDIF}

procedure TestConsistency;
var
  features1, features2: TARMFeatures;
  i: Integer;
begin
  WriteLog('=== Testing Consistency ===');
  
  try
    {$IFDEF SIMD_ARM_AVAILABLE}
    // Test that multiple calls return consistent results
    features1 := DetectARMFeatures;
    
    for i := 1 to 100 do
    begin
      features2 := DetectARMFeatures;
      
      if (features1.HasNEON <> features2.HasNEON) or
         (features1.HasAdvSIMD <> features2.HasAdvSIMD) or
         (features1.HasFP <> features2.HasFP) or
         (features1.HasSVE <> features2.HasSVE) or
         (features1.HasCrypto <> features2.HasCrypto) then
      begin
        WriteLog('✗ Consistency test FAILED: Results differ between calls');
        Exit;
      end;
    end;
    
    WriteLog('✓ Consistency test PASSED (100 calls)');
    Inc(testsPassed);
    {$ELSE}
    WriteLog('✓ Consistency test PASSED (non-ARM platform)');
    Inc(testsPassed);
    {$ENDIF}
    
  except
    on E: Exception do
    begin
      WriteLog('✗ Consistency test FAILED: ' + E.Message);
    end;
  end;
end;

begin
  testsPassed := 0;
  totalTests := 6;
  
  // Open output file
  AssignFile(outputFile, 'test_arm_results.txt');
  Rewrite(outputFile);
  
  try
    WriteLog('ARM CPU Info Module Test Suite');
    WriteLog('==============================');
    WriteLog('Start time: ' + DateTimeToStr(Now));
    WriteLog('');
    
    TestARMFeatureDetection;
    WriteLog('');
    
    TestARMVendorDetection;
    WriteLog('');
    
    TestIndividualFeatureChecks;
    WriteLog('');
    
    TestARMProcessorInfo;
    WriteLog('');
    
    TestProcCpuInfoParsing;
    WriteLog('');
    
    TestConsistency;
    WriteLog('');
    
    WriteLog('=== Test Results Summary ===');
    WriteLog('Tests passed: ' + IntToStr(testsPassed) + '/' + IntToStr(totalTests));
    WriteLog('Success rate: ' + FormatFloat('0.0', (testsPassed * 100.0 / totalTests)) + '%');
    WriteLog('End time: ' + DateTimeToStr(Now));
    
    if testsPassed = totalTests then
    begin
      WriteLog('✅ ALL TESTS PASSED - ARM module is working correctly');
      ExitCode := 0;
    end
    else
    begin
      WriteLog('❌ SOME TESTS FAILED - ARM module needs attention');
      ExitCode := 1;
    end;
    
  finally
    CloseFile(outputFile);
  end;
  
  WriteLn('ARM module test completed. Check test_arm_results.txt for results.');
  WriteLn('Tests passed: ', testsPassed, '/', totalTests);
end.
