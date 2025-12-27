program fafafa_core_mem_pool_fixed_tests;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, fpcunit, consoletestrunner,
  fafafa.core.mem.pool.fixed.testcase,
  fafafa.core.mem.pool.fixed.concurrent.testcase;

begin
  // 注册本模块测试用例
  fafafa.core.mem.pool.fixed.testcase.RegisterTests;
  fafafa.core.mem.pool.fixed.concurrent.testcase.RegisterTests;

  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

