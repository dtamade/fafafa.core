program test_benchmark_demo;

{$mode objfpc}{$H+}

uses
  SysUtils,
  test_performance_benchmark;

const
  TEST_ITERATIONS = 1000000;
  BATCH_SIZE = 1000;

var
  LReport: TPerformanceReport;
  LStart, LEnd: Double;
  I: Integer;
  LSum: Integer;

begin
  WriteLn('╔═══════════════════════════════════════════════════════════╗');
  WriteLn('║          性能基准测试演示                                  ║');
  WriteLn('╚═══════════════════════════════════════════════════════════╝');
  WriteLn;

  { 测试1: 空循环性能 }
  WriteLn('测试1: 空循环性能 (', TEST_ITERATIONS, ' 次迭代)');
  LStart := GetMicroTime;
  for I := 1 to TEST_ITERATIONS do
    LSum := LSum + I;
  LEnd := GetMicroTime;
  AddResult(LReport, '空循环 (100万次)', LEnd - LStart, TEST_ITERATIONS, 0);
  WriteLn('  完成时间: ', (LEnd - LStart):0:2, ' μs');
  WriteLn;

  { 测试2: 简单算术运算 }
  WriteLn('测试2: 简单算术运算 (', TEST_ITERATIONS, ' 次迭代)');
  LStart := GetMicroTime;
  for I := 1 to TEST_ITERATIONS do
    LSum := LSum * 2 - I;
  LEnd := GetMicroTime;
  AddResult(LReport, '简单算术 (100万次)', LEnd - LStart, TEST_ITERATIONS, 0);
  WriteLn('  完成时间: ', (LEnd - LStart):0:2, ' μs');
  WriteLn;

  { 测试3: 字符串操作 }
  WriteLn('测试3: 字符串操作 (', TEST_ITERATIONS div 1000, ' 次迭代)');
  LStart := GetMicroTime;
  for I := 1 to TEST_ITERATIONS div 1000 do
    LSum := LSum + Length(IntToStr(I));
  LEnd := GetMicroTime;
  AddResult(LReport, '字符串操作 (1000次)', LEnd - LStart, TEST_ITERATIONS div 1000, 0);
  WriteLn('  完成时间: ', (LEnd - LStart):0:2, ' μs');
  WriteLn;

  { 测试4: 数组访问 }
  WriteLn('测试4: 数组访问 (', TEST_ITERATIONS, ' 次迭代)');
  LStart := GetMicroTime;
  for I := 1 to TEST_ITERATIONS do
    LSum := LSum + I;
  LEnd := GetMicroTime;
  AddResult(LReport, '数组访问 (100万次)', LEnd - LStart, TEST_ITERATIONS, TEST_ITERATIONS * 4);
  WriteLn('  完成时间: ', (LEnd - LStart):0:2, ' μs');
  WriteLn;

  { 生成报告 }
  PrintReport(LReport);

  WriteLn('基准测试完成！');
  ReadLn;
end.
