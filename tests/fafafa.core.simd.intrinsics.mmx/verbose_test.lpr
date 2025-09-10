program verbose_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fpcunit, testregistry, testutils,
  fafafa.core.simd.intrinsics.mmx.testcase;

type
  TMyTestListener = class(TNoRefCountObject, ITestListener)
  public
    procedure AddFailure(ATest: TTest; AFailure: TTestFailure);
    procedure AddError(ATest: TTest; AError: TTestFailure);
    procedure StartTest(ATest: TTest);
    procedure EndTest(ATest: TTest);
    procedure StartTestSuite(ATestSuite: TTestSuite);
    procedure EndTestSuite(ATestSuite: TTestSuite);
  end;

procedure TMyTestListener.AddFailure(ATest: TTest; AFailure: TTestFailure);
begin
  WriteLn('FAILURE in ', ATest.TestName, ': ', AFailure.ExceptionMessage);
end;

procedure TMyTestListener.AddError(ATest: TTest; AError: TTestFailure);
begin
  WriteLn('ERROR in ', ATest.TestName, ': ', AError.ExceptionMessage);
end;

procedure TMyTestListener.StartTest(ATest: TTest);
begin
  Write('Running ', ATest.TestName, '... ');
end;

procedure TMyTestListener.EndTest(ATest: TTest);
begin
  WriteLn('done');
end;

procedure TMyTestListener.StartTestSuite(ATestSuite: TTestSuite);
begin
  WriteLn('Starting suite: ', ATestSuite.TestName);
end;

procedure TMyTestListener.EndTestSuite(ATestSuite: TTestSuite);
begin
  WriteLn('Finished suite: ', ATestSuite.TestName);
end;

var
  TestSuite: TTestSuite;
  TestResult: TTestResult;
  Listener: TMyTestListener;

begin
  WriteLn('Verbose MMX Test');
  WriteLn('================');
  
  TestSuite := GetTestRegistry;
  TestResult := TTestResult.Create;
  Listener := TMyTestListener.Create;
  
  try
    TestResult.AddListener(Listener);
    TestSuite.Run(TestResult);
    
    WriteLn('');
    WriteLn('Summary:');
    WriteLn('Tests run: ', TestResult.RunTests);
    WriteLn('Failures: ', TestResult.NumberOfFailures);
    WriteLn('Errors: ', TestResult.NumberOfErrors);
    
  finally
    TestResult.Free;
    Listener.Free;
  end;
end.
