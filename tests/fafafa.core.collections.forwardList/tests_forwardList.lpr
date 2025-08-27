program tests_forwardList;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  // 与线程测试工程保持一致，使用 consoletestrunner
  consoletestrunner,
  Test_forwardList;

var
  Application: TTestRunner;
begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'FPCUnit Console test runner for fafafa.core.collections.forwardList';
  Application.Run;
  Application.Free;
end.
