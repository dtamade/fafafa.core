program find_failures;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.mmx.testcase;

type
  TMyTestResult = class(TTestResult)
  public
    procedure AddFailure(ATest: TTest; AFailure: EAssertionFailedError; AAddr: TFPList; AMsg: Pointer); override;
    procedure AddError(ATest: TTest; AError: Exception; AAddr: Pointer); override;
  end;

procedure TMyTestResult.AddFailure(ATest: TTest; AFailure: EAssertionFailedError; AAddr: TFPList; AMsg: Pointer);
begin
  inherited AddFailure(ATest, AFailure, AAddr, AMsg);
  WriteLn('FAILURE: ', ATest.TestName);
  WriteLn('Message: ', AFailure.Message);
  WriteLn('Class: ', AFailure.ClassName);
  WriteLn('');
end;

procedure TMyTestResult.AddError(ATest: TTest; AError: Exception; AAddr: Pointer);
begin
  inherited AddError(ATest, AError, AAddr);
  WriteLn('ERROR: ', ATest.TestName);
  WriteLn('Message: ', AError.Message);
  WriteLn('Class: ', AError.ClassName);
  WriteLn('');
end;

var
  TestSuite: TTestSuite;
  TestResult: TMyTestResult;

begin
  WriteLn('MMX Intrinsics Failure Finder');
  WriteLn('==============================');
  WriteLn('');

  // 获取测试套件
  TestSuite := GetTestRegistry;
  TestResult := TMyTestResult.Create;

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
      ExitCode := 1;
    end;

  finally
    TestResult.Free;
  end;
end.
