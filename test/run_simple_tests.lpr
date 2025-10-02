program run_simple_tests;

{$mode objfpc}{$H+}
{$ifdef windows}{$codepage utf8}{$endif}

uses
  SysUtils,
  test_cpuinfo_suite;

var
  TestSuite: TCPUInfoTestSuite;
  ReportFile: string;

begin
  WriteLn('FAFAFA Core SIMD CPU Info - Simplified Test Suite');
  WriteLn('================================================');
  WriteLn;
  
  // Create test suite with verbose output
  TestSuite := TCPUInfoTestSuite.Create(True);
  try
    // Run all tests
    TestSuite.RunAllTests;
    
    WriteLn;
    
    // Generate report
    ReportFile := 'cpuinfo_test_report.txt';
    TestSuite.GenerateReport(ReportFile);
    WriteLn('Test report saved to: ', ReportFile);
    
    WriteLn;
    if TestSuite.GetPassRate >= 80.0 then
    begin
      WriteLn('✓ Test suite PASSED (', Format('%.1f', [TestSuite.GetPassRate]), '% pass rate)');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('✗ Test suite FAILED (', Format('%.1f', [TestSuite.GetPassRate]), '% pass rate)');
      ExitCode := 1;
    end;
    
  finally
    TestSuite.Free;
  end;
  
  WriteLn;
  WriteLn('Press Enter to continue...');
  ReadLn;
end.