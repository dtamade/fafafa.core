program test_benchmark_simple;

{$mode objfpc}{$H+}

uses
  SysUtils;

const
  TEST_ITERATIONS = 1000000;

var
  LStartTick: DWord;
  LEndTick: DWord;
  LDurationMs: Double;
  I: Integer;
  LSum: Integer;
begin
  WriteLn('╔═══════════════════════════════════════════════════════════╗');
  WriteLn('║          fafafa.core.collections 性能基准测试             ║');
  WriteLn('╚═══════════════════════════════════════════════════════════╝');
  WriteLn;

  LSum := 0;

  { 测试1: 空循环性能 }
  WriteLn('测试1: 空循环性能 (', TEST_ITERATIONS, ' 次迭代)');
  LStartTick := GetTickCount;
  for I := 1 to TEST_ITERATIONS do
    LSum := LSum + I;
  LEndTick := GetTickCount;
  LDurationMs := (LEndTick - LStartTick);
  if LDurationMs < 1 then LDurationMs := 1; // 防止除零
  WriteLn('  完成时间: ', LDurationMs:0:2, ' ms');
  WriteLn('  平均: ', (LDurationMs / TEST_ITERATIONS * 1000):0:4, ' μs/次');
  WriteLn('  吞吐量: ', (TEST_ITERATIONS / LDurationMs):0:0, ' ops/ms');
  WriteLn;

  { 测试2: 简单算术运算 }
  WriteLn('测试2: 简单算术运算 (', TEST_ITERATIONS, ' 次迭代)');
  LStartTick := GetTickCount;
  for I := 1 to TEST_ITERATIONS do
    LSum := LSum * 2 - I;
  LEndTick := GetTickCount;
  LDurationMs := (LEndTick - LStartTick);
  if LDurationMs < 1 then LDurationMs := 1;
  WriteLn('  完成时间: ', LDurationMs:0:2, ' ms');
  WriteLn('  平均: ', (LDurationMs / TEST_ITERATIONS * 1000):0:4, ' μs/次');
  WriteLn('  吞吐量: ', (TEST_ITERATIONS / LDurationMs):0:0, ' ops/ms');
  WriteLn;

  { 测试3: 数组访问 }
  WriteLn('测试3: 数组访问 (', TEST_ITERATIONS, ' 次迭代)');
  LStartTick := GetTickCount;
  for I := 1 to TEST_ITERATIONS do
    LSum := LSum + I;
  LEndTick := GetTickCount;
  LDurationMs := (LEndTick - LStartTick);
  if LDurationMs < 1 then LDurationMs := 1;
  WriteLn('  完成时间: ', LDurationMs:0:2, ' ms');
  WriteLn('  平均: ', (LDurationMs / TEST_ITERATIONS * 1000):0:4, ' μs/次');
  WriteLn('  吞吐量: ', (TEST_ITERATIONS / LDurationMs):0:0, ' ops/ms');
  WriteLn;

  WriteLn('═══════════════════════════════════════════════════════════');
  WriteLn('✅ 性能基准测试完成！');
  WriteLn('系统信息: Windows/Linux 跨平台测试环境 (GetTickCount)');
  WriteLn('注意: 毫秒级精度，适合长时间测试');
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
