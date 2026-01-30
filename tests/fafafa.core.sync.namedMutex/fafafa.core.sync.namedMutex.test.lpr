program fafafa.core.sync.namedMutex.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit, consoletestrunner,
  fafafa.core.sync.namedMutex.testcase;

type
  TMyTestRunner = class(TTestRunner)
  protected
    procedure WriteCustomHelp; override;
  end;

procedure TMyTestRunner.WriteCustomHelp;
begin
  inherited WriteCustomHelp;
  writeln('fafafa.core.sync.namedMutex 单元测试');
  writeln('测试进程间命名互斥锁的功能');
  writeln('');
end;

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.sync.namedMutex 测试套件';
    Application.Run;
  finally
    Application.Free;
  end;
end.
