{$CODEPAGE UTF8}
program test_reverse_simple;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  consoletestrunner,
  Test_VecDeque_Reverse_Fix;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'VecDeque Reverse 专项测试';
  Application.Run;
  Application.Free;
end.
