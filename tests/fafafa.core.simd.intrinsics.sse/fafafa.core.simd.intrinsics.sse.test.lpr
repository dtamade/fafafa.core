program fafafa.core.simd.intrinsics.sse.test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.sse.testcase;

var
  TestSuite: TTestSuite;
  TestResult: TTestResult;
  i: Integer;

begin
  WriteLn('SSE Intrinsics Unit Test');
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

    // 输出失败详情
    if TestResult.NumberOfFailures > 0 then
    begin
      WriteLn('');
      WriteLn('=== Failures ===');
      for i := 0 to TestResult.Failures.Count - 1 do
        WriteLn('  ', TTestFailure(TestResult.Failures[i]).AsString);
    end;

    // 输出错误详情
    if TestResult.NumberOfErrors > 0 then
    begin
      WriteLn('');
      WriteLn('=== Errors ===');
      for i := 0 to TestResult.Errors.Count - 1 do
        WriteLn('  ', TTestFailure(TestResult.Errors[i]).AsString);
    end;

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
      ExitCode := 1;
    end;

  finally
    TestResult.Free;
  end;
end.
