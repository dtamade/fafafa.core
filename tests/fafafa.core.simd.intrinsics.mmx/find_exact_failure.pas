program find_exact_failure;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.intrinsics.mmx.testcase;

type
  TFailureCapture = class(TTestResult)
  private
    FFailedTest: string;
    FFailureMessage: string;
  public
    procedure AddFailure(ATest: TTest; AFailure: EAssertionFailedError; AAddr: TFPList; AMsg: Pointer); override;
    property FailedTest: string read FFailedTest;
    property FailureMessage: string read FFailureMessage;
  end;

procedure TFailureCapture.AddFailure(ATest: TTest; AFailure: EAssertionFailedError; AAddr: TFPList; AMsg: Pointer);
begin
  inherited AddFailure(ATest, AFailure, AAddr, AMsg);
  FFailedTest := ATest.TestName;
  FFailureMessage := AFailure.Message;
  WriteLn('FOUND FAILURE: ', FFailedTest);
  WriteLn('MESSAGE: ', FFailureMessage);
end;

var
  TestSuite: TTestSuite;
  TestResult: TFailureCapture;

begin
  TestSuite := GetTestRegistry;
  TestResult := TFailureCapture.Create;
  try
    TestSuite.Run(TestResult);
    WriteLn('Tests: ', TestResult.RunTests);
    WriteLn('Failures: ', TestResult.NumberOfFailures);
  finally
    TestResult.Free;
  end;
end.
