{$CODEPAGE UTF8}
program fafafa_core_time_tz_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.time.tz.testcase;

type
  TTestApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

procedure TTestApp.DoRun;
var Runner: TTestRunner;
begin
  WriteLn('fafafa.core.time.tz 单元测试');
  WriteLn('===================================');
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
  App.Title := 'fafafa.core.time.tz Tests';
  App.Run;
  App.Free;
end.
