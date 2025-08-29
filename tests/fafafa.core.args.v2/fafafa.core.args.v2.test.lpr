{$CODEPAGE UTF8}
program fafafa_core_args_v2_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.args.v2.testcase;

type
  TTestApp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  end;

procedure TTestApp.DoRun;
var 
  Runner: TTestRunner;
begin
  WriteLn('fafafa.core.args.v2 现代化重构测试');
  WriteLn('=====================================');
  WriteLn('测试高性能、类型安全、现代化的参数解析系统');
  WriteLn;
  
  Runner := TTestRunner.Create(nil);
  try
    Runner.Initialize;
    Runner.Run;
  finally
    Runner.Free;
  end;
  Terminate;
end;

var 
  App: TTestApp;
begin
  App := TTestApp.Create(nil);
  App.Title := 'fafafa.core.args.v2 Tests';
  App.Run;
  App.Free;
end.
