unit test_cpuinfo_suite;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, TypInfo,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.cpuinfo.diagnostic,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.types;

type
  TTestCategory = (tcBasic, tcBoundary, tcConcurrency, tcPerformance, tcIntegration);

  { TCPUInfoTestSuite }
  TCPUInfoTestSuite = class
  private
    FVerbose: Boolean;
    FPassedTests: Integer;
    FTotalTests: Integer;
    procedure LogTest(const TestName: string; Category: TTestCategory);
    procedure Assert(Condition: Boolean; const Message: string);
  public
    constructor Create(AVerbose: Boolean = False);
    procedure TestBasicDetection;
    procedure TestFeatureQueries;
    procedure TestVendorDetection;
    procedure TestCacheInfo;
    procedure TestOSEnablementInvariants;
    procedure TestPerformance;
    procedure RunAllTests;
    procedure RunCategory(Category: TTestCategory);
    function GetPassRate: Double;
    procedure GenerateReport(const FileName: string);
  end;

implementation

{ TCPUInfoTestSuite }

constructor TCPUInfoTestSuite.Create(AVerbose: Boolean);
begin
  FVerbose := AVerbose;
  FPassedTests := 0;
  FTotalTests := 0;
end;

procedure TCPUInfoTestSuite.LogTest(const TestName: string; Category: TTestCategory);
begin
  if FVerbose then
  begin
    Write(Format('[%s] %s ... ', [GetEnumName(TypeInfo(TTestCategory), Ord(Category)), TestName]));
  end;
  Inc(FTotalTests);
end;

procedure TCPUInfoTestSuite.Assert(Condition: Boolean; const Message: string);
begin
  if Condition then
  begin
    Inc(FPassedTests);
    if FVerbose then
      WriteLn('PASS');
  end
  else
  begin
    if FVerbose then
      WriteLn('FAIL: ', Message)
    else
      WriteLn('FAIL: ', Message);
  end;
end;

procedure TCPUInfoTestSuite.TestBasicDetection;
var
  Info: TCPUInfo;
begin
  Info := GetCPUInfo;
  
  LogTest('VendorDetection', tcBasic);
  Assert(Info.Vendor <> '', 'Vendor should not be empty');
  
  LogTest('ModelDetection', tcBasic);
  Assert(Info.Model <> '', 'Model should not be empty');
  
  LogTest('ArchitectureDetection', tcBasic);
  Assert(Info.Arch <> caUnknown, 'Architecture should be detected');
  
  LogTest('CoreCountDetection', tcBasic);
  Assert((Info.LogicalCores > 0) and (Info.PhysicalCores > 0), 'Both logical and physical cores should be > 0');
end;

procedure TCPUInfoTestSuite.TestFeatureQueries;
var
  Info: TCPUInfo;
  HasSimd128: Boolean;
  Backends: TSimdBackendArray;
begin
  Info := GetCPUInfo;
  
  LogTest('SIMD128FeatureQuery', tcBasic);
  HasSimd128 := HasFeature(gfSimd128);
  {$IFDEF SIMD_X86_AVAILABLE}
  if Info.Arch = caX86 then
    Assert(HasSimd128 = Info.X86.HasSSE2, 'SIMD128 feature should match SSE2')
  else
  {$ENDIF}
    Assert(True, 'SIMD128 feature query executed');
  
  LogTest('SupportedBackends', tcBasic);
  Backends := GetSupportedBackends;
  Assert((Length(Backends) > 0) and (Backends[0] = sbScalar), 'Should have at least scalar backend as first');
end;

procedure TCPUInfoTestSuite.TestVendorDetection;
var
  Info: TCPUInfo;
begin
  LogTest('VendorStringValidation', tcBasic);
  Info := GetCPUInfo;
  
  {$IFDEF SIMD_X86_AVAILABLE}
  if Info.Arch = caX86 then
  begin
    Assert((Info.Vendor = 'GenuineIntel') or 
           (Info.Vendor = 'AuthenticAMD') or 
           (Pos('Intel', Info.Vendor) > 0) or
           (Pos('AMD', Info.Vendor) > 0),
           'Should detect known x86 vendor');
  end
  else
  {$ENDIF}
    Assert(Length(Info.Vendor) > 0, 'Vendor string should not be empty');
end;

procedure TCPUInfoTestSuite.TestCacheInfo;
var
  Info: TCPUInfo;
begin
  LogTest('CacheInfoValidation', tcBasic);
  Info := GetCPUInfo;
  
  Assert((Info.Cache.LineSize > 0) and (Info.Cache.L1DataKB >= 0), 'Cache information should be valid');
end;

procedure TCPUInfoTestSuite.TestPerformance;
var
  Report: TCPUInfoDiagnosticReport;
  i: Integer;
  StartTime: QWord;
  TotalTime: QWord;
  Info: TCPUInfo;
begin
  LogTest('CachingPerformance', tcPerformance);
  StartTime := GetTickCount64;
  for i := 1 to 1000 do
  begin
    Info := GetCPUInfo;
    if Info.Vendor = '' then Break;
  end;
  TotalTime := GetTickCount64 - StartTime;
  Assert(TotalTime < 100, Format('1000 calls should be fast (<%dms, got %dms)', [100, TotalTime]));
  
  LogTest('DiagnosticReportGeneration', tcPerformance);
  Report := GenerateDiagnosticReport;
  Assert((Report.DetectionTime >= 0) and Report.ValidationPassed, 'Diagnostic report should be valid');
end;

procedure TCPUInfoTestSuite.TestOSEnablementInvariants;
var
  Info: TCPUInfo;
  B: TSimdBackendArray;
  function ContainsBackend(const A: TSimdBackend): Boolean;
  var i: Integer;
  begin
    Result := False;
    for i := 0 to High(B) do
      if B[i] = A then Exit(True);
  end;
begin
  Info := GetCPUInfo;

  LogTest('GenericUsableSubsetOfRaw', tcBasic);
  Assert((Info.GenericUsable - Info.GenericRaw) = [], 'Usable features must be subset of Raw features');

  {$IFDEF SIMD_X86_AVAILABLE}
  if Info.Arch = caX86 then
  begin
    LogTest('AVX512Implies256', tcBasic);
    if gfSimd512 in Info.GenericUsable then
      Assert(gfSimd256 in Info.GenericUsable, 'SIMD-512 usable implies SIMD-256 usable');

    LogTest('Usable256ImpliesCPUAVXorAVX2', tcBasic);
    if gfSimd256 in Info.GenericUsable then
      Assert(Info.X86.HasAVX or Info.X86.HasAVX2, 'SIMD-256 usable requires AVX or AVX2 CPU');
  end;
  {$ENDIF}

  // Backends alignment (best-effort portable checks)
  B := GetSupportedBackends;

  LogTest('ScalarAlwaysPresent', tcBasic);
  Assert(ContainsBackend(sbScalar), 'Scalar backend must always be present');

  {$IFDEF SIMD_X86_AVAILABLE}
  if Info.Arch = caX86 then
  begin
    LogTest('SSE2BackendMatches128', tcBasic);
    Assert(ContainsBackend(sbSSE2) = (gfSimd128 in Info.GenericUsable), 'SSE2 backend should reflect usable 128-bit');

    if (gfSimd256 in Info.GenericUsable) and Info.X86.HasAVX2 then
    begin
      LogTest('AVX2BackendWhenUsable', tcBasic);
      Assert(ContainsBackend(sbAVX2), 'AVX2 backend should be present when 256-bit usable and AVX2 CPU');
    end;

    if (gfSimd512 in Info.GenericUsable) and Info.X86.HasAVX512F then
    begin
      LogTest('AVX512BackendWhenUsable', tcBasic);
      Assert(ContainsBackend(sbAVX512), 'AVX-512 backend should be present when 512-bit usable');
    end;
  end;
  {$ENDIF}
end;

procedure TCPUInfoTestSuite.RunAllTests;
begin
  WriteLn('Running CPU Info Test Suite...');
  WriteLn('==============================');
  
  TestBasicDetection;
  TestFeatureQueries;  
  TestVendorDetection;
  TestCacheInfo;
  TestOSEnablementInvariants;
  TestPerformance;
  
  WriteLn;
  WriteLn(Format('Results: %d/%d tests passed (%.1f%%)', 
    [FPassedTests, FTotalTests, GetPassRate]));
end;

procedure TCPUInfoTestSuite.RunCategory(Category: TTestCategory);
begin
  WriteLn('Running ', GetEnumName(TypeInfo(TTestCategory), Ord(Category)), ' tests...');
  
  case Category of
    tcBasic: 
      begin
        TestBasicDetection;
        TestFeatureQueries;
        TestVendorDetection;
        TestOSEnablementInvariants;
      end;
    tcPerformance:
      TestPerformance;
    tcIntegration:
      TestCacheInfo;
  end;
  
  WriteLn(Format('Category results: %d/%d tests passed (%.1f%%)', 
    [FPassedTests, FTotalTests, GetPassRate]));
end;

function TCPUInfoTestSuite.GetPassRate: Double;
begin
  if FTotalTests > 0 then
    Result := (FPassedTests * 100.0) / FTotalTests
  else
    Result := 0.0;
end;

procedure TCPUInfoTestSuite.GenerateReport(const FileName: string);
var
  F: TextFile;
  Report: TCPUInfoDiagnosticReport;
begin
  AssignFile(F, FileName);
  Rewrite(F);
  try
    WriteLn(F, 'CPU Info Test Report');
    WriteLn(F, '===================');
    WriteLn(F, 'Generated: ', DateTimeToStr(Now));
    WriteLn(F);
    WriteLn(F, 'Test Results:');
    WriteLn(F, '  Total Tests: ', FTotalTests);
    WriteLn(F, '  Passed: ', FPassedTests);
    WriteLn(F, '  Failed: ', FTotalTests - FPassedTests);
    WriteLn(F, '  Pass Rate: ', Format('%.1f%%', [GetPassRate]));
    WriteLn(F);
    
    // Include diagnostic info
    Report := GenerateDiagnosticReport;
    WriteLn(F, 'System Information:');
    WriteLn(F, '  CPU: ', Report.CPUInfo.Vendor, ' ', Report.CPUInfo.Model);
    WriteLn(F, '  Architecture: ', GetArchName(Report.CPUInfo.Arch));
    WriteLn(F, '  Cores: ', Report.CPUInfo.PhysicalCores, ' physical, ', Report.CPUInfo.LogicalCores, ' logical');
    WriteLn(F, '  Cache: L1=', Report.CPUInfo.Cache.L1DataKB, 'KB, L2=', Report.CPUInfo.Cache.L2KB, 'KB, L3=', Report.CPUInfo.Cache.L3KB, 'KB');
    
  finally
    CloseFile(F);
  end;
end;

end.