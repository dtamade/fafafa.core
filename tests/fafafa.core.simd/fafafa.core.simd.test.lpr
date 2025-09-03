program fafafa.core.simd.test;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fpcunit, testregistry,
  fafafa.core.simd.testcase;

var
  testResult: TTestResult;
  testSuite: TTestSuite;

begin
  WriteLn('=== fafafa.core.simd Test Suite ===');
  WriteLn('Starting SIMD facade function tests...');
  WriteLn;

  // Create test suite
  testSuite := TTestSuite.Create('SIMD Tests');
  try
    // Add test cases
    testSuite.AddTest(TTestCase_Global.Suite);

    // Create test result
    testResult := TTestResult.Create;
    try
      // Run tests
      testSuite.Run(testResult);

      // Display results
      WriteLn;
      WriteLn('=== Test Results ===');
      WriteLn('Tests run: ', testResult.RunTests);
      WriteLn('Failures: ', testResult.NumberOfFailures);
      WriteLn('Errors: ', testResult.NumberOfErrors);

      if (testResult.NumberOfFailures = 0) and (testResult.NumberOfErrors = 0) then
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
      testResult.Free;
    end;
  finally
    testSuite.Free;
  end;

  // Wait for user input in debug mode
  {$IFDEF DEBUG}
  WriteLn('Press Enter to exit...');
  ReadLn;
  {$ENDIF}
end.
