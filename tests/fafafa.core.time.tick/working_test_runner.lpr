program working_test_runner;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  working_enhanced_test;

var
  Application: TTestRunner;

begin
  WriteLn('=== Enhanced Tick Test Suite ===');
  WriteLn('Starting enhanced test execution...');
  
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'Enhanced Tick Test Suite';
    Application.Run;
  finally
    Application.Free;
  end;
  
  WriteLn('Enhanced test execution completed.');
end.
