program fafafa.core.simd.intrinsics.mmx.test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.mmx.testcase;

var
  TestSuite: TTestSuite;
  TestResult: TTestResult;
  i: Integer;

begin
  WriteLn('MMX Intrinsics Unit Test');
  WriteLn('========================');
  WriteLn('');

  // 获取测试套件
  TestSuite := GetTestRegistry;
  TestResult := TTestResult.Create;

  try
    // 运行所有测试
    TestSuite.Run(TestResult);

    // 输出测试结果
    WriteLn('Test completed!');
    WriteLn('Tests run: ', TestResult.RunTests);
    WriteLn('Failures: ', TestResult.NumberOfFailures);
    WriteLn('Errors: ', TestResult.NumberOfErrors);
    WriteLn('Skipped: ', TestResult.NumberOfSkippedTests);

    if (TestResult.NumberOfFailures = 0) and (TestResult.NumberOfErrors = 0) then
    begin
      WriteLn('');
      WriteLn('All tests passed!');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('');
      WriteLn('Some tests failed!');

      // 输出失败详情
      if TestResult.NumberOfFailures > 0 then
      begin
        WriteLn('');
        WriteLn('Failures detected - check individual test results');
      end;

      if TestResult.NumberOfErrors > 0 then
      begin
        WriteLn('');
        WriteLn('Errors detected - check individual test results');
      end;

      ExitCode := 1;
    end;

  finally
    TestResult.Free;
  end;
end.
