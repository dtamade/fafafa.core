program fafafa.core.sync.namedRWLock.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.sync.namedRWLock.testcase;

type
  TMyTestRunner = class(TTestRunner)
  protected
    // 可以在这里添加自定义的测试运行逻辑
  end;

var
  Application: TMyTestRunner;

begin
  DefaultFormat := fPlain;
  DefaultRunAllTests := True;
  
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.sync.namedRWLock 单元测试';
  Application.Run;
  Application.Free;
end.
