{$CODEPAGE UTF8}
program fafafa_core_option_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.option.testcase;

type
  TTestApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

procedure TTestApp.DoRun;
var Runner: TTestRunner;
begin
  WriteLn('fafafa.core.option 单元测试');
  WriteLn('============================');
  Runner := TTestRunner.Create(nil);
  try
    Runner.Initialize;
    Runner.Run;
  finally
    Runner.Free;
  end;
  Terminate;
end;

var App: TTestApp;
begin
  App := TTestApp.Create(nil);
  App.Title := 'fafafa.core.option Tests';
  App.Run;
  App.Free;
end.

