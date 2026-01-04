{$CODEPAGE UTF8}
program fafafa.core.args.validation.test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes, consoletestrunner,
  fafafa.core.args.validation.testcase;

type
  TMyTestRunner = class(TTestRunner)
  protected
  // override the protected methods of TTestRunner to customize its behavior
  end;

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.args.validation Tests';
  Application.Run;
  Application.Free;
end.
