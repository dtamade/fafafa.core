program tests_atomic;

{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  consoletestrunner,
  Test_fafafa.core.atomic,
  Test_fafafa.core.atomic.base,
  Test_fafafa.core.atomic.contract,
  Test_fafafa.core.atomic.compat.contract;

begin
  // 注册该模块的测试
  Test_fafafa.core.atomic.RegisterAtomicTests;
  Test_fafafa.core.atomic.base.RegisterAtomicBaseTests;
  Test_fafafa.core.atomic.contract.RegisterAtomicContractTests;
  Test_fafafa.core.atomic.compat.contract.RegisterAtomicCompatContractTests;
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

