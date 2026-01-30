program fafafa.core.sync.namedCondvar.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.sync.namedCondvar.testcase;

var
  LResult: TTestResult;
  I: Integer;
  LFailure: TTestFailure;
  
begin
  WriteLn('fafafa.core.sync.namedCondvar Unit Tests');
  WriteLn('================================================');
  
  // Create test result object
  LResult := TTestResult.Create;
  try
    // Run all registered tests
    GetTestRegistry.Run(LResult);
    
    WriteLn;
    WriteLn('Test Results:');
    WriteLn('  Run: ', LResult.RunTests);
    WriteLn('  Failures: ', LResult.NumberOfFailures);
    WriteLn('  Errors: ', LResult.NumberOfErrors);
    
    // Print failures
    if LResult.NumberOfFailures > 0 then
    begin
      WriteLn;
      WriteLn('Failures:');
      for I := 0 to LResult.Failures.Count - 1 do
      begin
        LFailure := TTestFailure(LResult.Failures[I]);
        WriteLn('  ', I+1, '. ', LFailure.AsString);
      end;
    end;
    
    // Print errors
    if LResult.NumberOfErrors > 0 then
    begin
      WriteLn;
      WriteLn('Errors:');
      for I := 0 to LResult.Errors.Count - 1 do
      begin
        LFailure := TTestFailure(LResult.Errors[I]);
        WriteLn('  ', I+1, '. ', LFailure.ExceptionClassName, ': ', LFailure.ExceptionMessage);
      end;
    end;
    
    if (LResult.NumberOfFailures = 0) and (LResult.NumberOfErrors = 0) then
      WriteLn('All tests passed!')
    else
    begin
      WriteLn;
      WriteLn('Tests failed!');
      ExitCode := 1;
    end;
  finally
    LResult.Free;
  end;
end.
