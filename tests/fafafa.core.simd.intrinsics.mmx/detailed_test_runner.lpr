program detailed_test_runner;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.mmx.testcase;

var
  TestSuite: TTestSuite;
  TestResult: TTestResult;
  i: Integer;

begin
  WriteLn('MMX Intrinsics Unit Test - Detailed');
  WriteLn('====================================');
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
    WriteLn('');

    // 输出失败详情
    if TestResult.NumberOfFailures > 0 then
    begin
      WriteLn('FAILURES:');
      WriteLn('---------');
      for i := 0 to TestResult.NumberOfFailures - 1 do
      begin
        WriteLn('Failure #', i + 1);
        WriteLn('');
      end;
    end;

    // 输出错误详情
    if TestResult.NumberOfErrors > 0 then
    begin
      WriteLn('ERRORS:');
      WriteLn('-------');
      for i := 0 to TestResult.NumberOfErrors - 1 do
      begin
        WriteLn('Error #', i + 1);
        WriteLn('');
      end;
    end;

    if (TestResult.NumberOfFailures = 0) and (TestResult.NumberOfErrors = 0) then
    begin
      WriteLn('All tests passed!');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('Some tests failed!');
      ExitCode := 1;
    end;

  finally
    TestResult.Free;
  end;
end.
