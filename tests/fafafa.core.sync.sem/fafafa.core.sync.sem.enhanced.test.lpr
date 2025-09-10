{$CODEPAGE UTF8}
program enhanced_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fpcunit, testreport, testregistry,
  fafafa.core.sync.sem.testcase,
  fafafa.core.sync.sem.enhanced.testcase;

var
  FXMLResultsWriter: TXMLResultsWriter;
  TestResult: TTestResult;

begin
  WriteLn('Running Enhanced Semaphore Tests...');
  WriteLn('====================================');

  // 创建测试结果写入器
  FXMLResultsWriter := TXMLResultsWriter.Create;
  try
    TestResult := TTestResult.Create;
    try
      TestResult.AddListener(FXMLResultsWriter);

      // 运行所有测试
      GetTestRegistry.Run(TestResult);

      // 输出结果
      WriteLn;
      WriteLn('Test Results:');
      WriteLn('Tests run: ', TestResult.RunTests);
      WriteLn('Failures: ', TestResult.NumberOfFailures);
      WriteLn('Errors: ', TestResult.NumberOfErrors);
      WriteLn('Skipped: ', TestResult.NumberOfSkippedTests);

      if TestResult.NumberOfErrors + TestResult.NumberOfFailures = 0 then
        WriteLn('All tests passed!')
      else
        WriteLn('Some tests failed!');

    finally
      TestResult.Free;
    end;
  finally
    FXMLResultsWriter.Free;
  end;
end.
