unit fafafa.core.collections.vec.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  // 复用现有 FPCUnit 测试单元（自动注册）
  Test_vec,
  Test_vec_hysteresis,
  Test_vec_span,
  Test_vec_trimtosize_alias,
  Test_vec_reserve_overflow_freebuffer,
  Test_vec_capacity_convergence,
  Test_vec_growstrategy_interface_regression;

implementation

end.

