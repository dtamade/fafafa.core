program tests_atomic;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  consoletestrunner,
  Test_fafafa.core.atomic;

begin
  // 注册该模块的测试
  Test_fafafa.core.atomic.RegisterAtomicTests;
  // 友好控制台输出
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

