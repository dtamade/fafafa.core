{$CODEPAGE UTF8}
program fafafa.core.args.command.test;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, consoletestrunner,
  fafafa.core.args.command.testcase;

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
  Application.Title := 'fafafa.core.args.command Tests';
  Application.Run;
  Application.Free;
end.
