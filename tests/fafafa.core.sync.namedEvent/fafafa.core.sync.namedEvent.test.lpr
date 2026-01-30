{$CODEPAGE UTF8}
program fafafa.core.sync.namedEvent.test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit, testregistry, consoletestrunner,
  fafafa.core.sync.namedEvent.testcase;

type
  TMyTestRunner = class(TTestRunner)
  protected
    // 可以在这里自定义测试运行器行为
  end;

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.sync.namedEvent Test Suite';
    Application.Run;
  finally
    Application.Free;
  end;
end.
