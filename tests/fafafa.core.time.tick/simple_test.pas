program simple_test;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  Classes, SysUtils, fpcunit, testregistry, consoletestrunner;

type
  TSimpleTest = class(TTestCase)
  published
    procedure Test_Simple;
  end;

procedure TSimpleTest.Test_Simple;
begin
  AssertEquals('Simple test', 1, 1);
  WriteLn('Simple test executed');
end;

var
  Application: TTestRunner;

begin
  WriteLn('Starting simple test...');
  
  RegisterTest(TSimpleTest);
  
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'Simple Test';
    WriteLn('Running tests...');
    Application.Run;
    WriteLn('Tests completed.');
  finally
    Application.Free;
  end;
  
  WriteLn('Program finished.');
end.
