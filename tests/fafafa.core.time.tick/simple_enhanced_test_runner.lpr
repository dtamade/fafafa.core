program simple_enhanced_test_runner;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  Classes, SysUtils, consoletestrunner,
  simple_enhanced_test;

var
  Application: TTestRunner;

begin
  WriteLn('Starting Enhanced Test Suite...');
  
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'Enhanced Test Suite';
    WriteLn('Running tests...');
    Application.Run;
    WriteLn('Tests completed.');
  finally
    Application.Free;
  end;
  
  WriteLn('Program finished.');
end.
