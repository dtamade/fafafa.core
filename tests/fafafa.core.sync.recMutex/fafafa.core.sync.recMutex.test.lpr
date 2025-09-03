program fafafa.core.sync.recMutex.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  consoletestrunner,
  fafafa.core.sync.recMutex.testcase.enhanced;

var
  Application: TTestRunner;
begin
  DefaultRunAllTests := true;
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.sync.recMutex 单元测试';
  Application.Run;
  Application.Free;
end.
