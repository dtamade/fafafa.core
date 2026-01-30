program tests_vec;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  consoletestrunner,
  Test_vec,
  Test_vec_growstrategy_interface_regression,
  Test_vec_hysteresis,
  Test_vec_reserve_overflow_freebuffer,
  Test_vec_trimtosize_alias,
  Test_vec_capacity_convergence;


var
  LApplication: TTestRunner;

begin
  WriteLn('========================================');
  WriteLn('fafafa.core.collections.vec 单元测试');
  WriteLn('========================================');
  WriteLn;

  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'Vec Tests';
    // default console runner; no extra listeners
    // Note: older FPCUnit TTestRunner has no DoRun; rely on testdefaults.ini for defaults
    LApplication.Run;
  finally
    LApplication.Free;
  end;
  // 注释掉手动释放测试注册表，避免双重释放问题
  // testregistry.GetTestRegistry.Free;
end.
