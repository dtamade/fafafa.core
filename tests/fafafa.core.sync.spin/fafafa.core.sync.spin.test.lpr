program fafafa.core.sync.spin.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  consoletestrunner,
  fafafa.core.sync.spin.testcase;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.sync.spin 单元测试';
  Application.Run;
  Application.Free;
end.
