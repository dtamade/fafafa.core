{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$ifdef windows}{$codepage utf8}{$endif}

program run_cpuinfo_tests;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  test_cpuinfo_suite,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.cpuinfo.diagnostic;

procedure PrintUsage;
begin
  WriteLn('CPU Info Test Suite Runner');
  WriteLn('==========================');
  WriteLn;
  WriteLn('Usage: ', ExtractFileName(ParamStr(0)), ' [options]');
  WriteLn;
  WriteLn('Options:');
  WriteLn('  --help, -h        Show this help message');
  WriteLn('  --verbose, -v     Enable verbose output');
  WriteLn('  --category <cat>  Run only tests in specified category');
  WriteLn('                    (basic, boundary, concurrency, performance, integration)');
  WriteLn('  --report <file>   Generate test report to specified file');
  WriteLn('  --diagnostic      Run diagnostic tests');
  WriteLn('  --benchmark       Run only performance benchmarks');
  WriteLn('  --quick           Run quick smoke tests only');
  WriteLn;
end;

procedure RunDiagnosticTests;
var
  Report: TCPUInfoDiagnosticReport;
  FileName: string;
begin
  WriteLn('Running Diagnostic Tests...');
  WriteLn('===========================');
  
  Report := GenerateDiagnosticReport;
  PrintCPUInfo(Report.CPUInfo);
  
  // Also export to a file next to the runner
  FileName := ChangeFileExt(ParamStr(0), '.cpuinfo.diagnostic.txt');
  ExportDiagnosticReport(Report, FileName);
  WriteLn('Diagnostic report saved to: ', FileName);
end;

procedure RunQuickTests;
var
  Suite: TCPUInfoTestSuite;
begin
  WriteLn('Running Quick Smoke Tests...');
  WriteLn('============================');
  
  Suite := TCPUInfoTestSuite.Create(True);
  try
    // Run only basic tests for quick validation
    Suite.TestBasicDetection;
    Suite.TestFeatureQueries;
    Suite.TestVendorDetection;
    
    WriteLn;
    WriteLn(Format('Quick test pass rate: %.1f%%', [Suite.GetPassRate]));
  finally
    Suite.Free;
  end;
end;

procedure RunFullTestSuite(AVerbose: Boolean; const AReportFile: string);
var
  Suite: TCPUInfoTestSuite;
begin
  Suite := TCPUInfoTestSuite.Create(AVerbose);
  try
    Suite.RunAllTests;
    
    if AReportFile <> '' then
    begin
      Suite.GenerateReport(AReportFile);
      WriteLn('Report saved to: ', AReportFile);
    end;
  finally
    Suite.Free;
  end;
end;

procedure RunCategoryTests(const ACategory: string; AVerbose: Boolean);
var
  Suite: TCPUInfoTestSuite;
  Cat: TTestCategory;
begin
  // Parse category string
  if LowerCase(ACategory) = 'basic' then
    Cat := tcBasic
  else if LowerCase(ACategory) = 'boundary' then
    Cat := tcBoundary
  else if LowerCase(ACategory) = 'concurrency' then
    Cat := tcConcurrency
  else if LowerCase(ACategory) = 'performance' then
    Cat := tcPerformance
  else if LowerCase(ACategory) = 'integration' then
    Cat := tcIntegration
  else
  begin
    WriteLn('Error: Unknown category: ', ACategory);
    Exit;
  end;
  
  Suite := TCPUInfoTestSuite.Create(AVerbose);
  try
    Suite.RunCategory(Cat);
    WriteLn;
    WriteLn(Format('Category test pass rate: %.1f%%', [Suite.GetPassRate]));
  finally
    Suite.Free;
  end;
end;

var
  i: Integer;
  Verbose: Boolean;
  ReportFile: string;
  Category: string;
  RunDiagnostic: Boolean;
  RunBenchmark: Boolean;
  RunQuick: Boolean;
begin
  // Parse command line arguments
  Verbose := False;
  ReportFile := '';
  Category := '';
  RunDiagnostic := False;
  RunBenchmark := False;
  RunQuick := False;
  
  i := 1;
  while i <= ParamCount do
  begin
    if (ParamStr(i) = '--help') or (ParamStr(i) = '-h') then
    begin
      PrintUsage;
      Exit;
    end
    else if (ParamStr(i) = '--verbose') or (ParamStr(i) = '-v') then
      Verbose := True
    else if ParamStr(i) = '--category' then
    begin
      Inc(i);
      if i <= ParamCount then
        Category := ParamStr(i);
    end
    else if ParamStr(i) = '--report' then
    begin
      Inc(i);
      if i <= ParamCount then
        ReportFile := ParamStr(i);
    end
    else if ParamStr(i) = '--diagnostic' then
      RunDiagnostic := True
    else if ParamStr(i) = '--benchmark' then
      RunBenchmark := True
    else if ParamStr(i) = '--quick' then
      RunQuick := True;
      
    Inc(i);
  end;
  
  try
    // Run requested tests
    if RunDiagnostic then
      RunDiagnosticTests
    else if RunQuick then
      RunQuickTests
    else if RunBenchmark then
      RunCategoryTests('performance', Verbose)
    else if Category <> '' then
      RunCategoryTests(Category, Verbose)
    else
      RunFullTestSuite(Verbose, ReportFile);
      
    WriteLn;
    WriteLn('Test execution completed successfully.');
  except
    on E: Exception do
    begin
      WriteLn('Error during test execution: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.