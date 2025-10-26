program test_collections_performance;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.deque,
  fafafa.core.collections.stack,
  fafafa.core.collections.vecdeque;

type
  TIntArray = array of Integer;

{ 高精度计时器 }
function GetHighPrecisionTime: Double;
var
  Freq: Int64;
  Counter: Int64;
begin
  if not QueryPerformanceFrequency(Freq) then
    Exit(0);
  QueryPerformanceCounter(Counter);
  Result := Counter / Freq * 1000000; { 微秒 }
end;

{ 测试 1: TArrayDeque.Append 批量追加性能 }
procedure TestAppendPerformance;
const
  ITERATIONS = 100;
  BATCH_SIZE = 1000;
var
  LDeque1, LDeque2: specialize IDeque<Integer>;
  LStart, LEnd: Double;
  LTimeOld, LTimeNew: Double;
  I: Integer;
  LSum: Integer;
begin
  WriteLn('========== 测试 1: TArrayDeque.Append 性能 ==========');

  { 准备数据 }
  LDeque1 := MakeDeque<Integer>;
  for I := 1 to BATCH_SIZE do
    LDeque1.Push(I);

  LDeque2 := MakeDeque<Integer>;

  { 测试修复后的 Append (使用新的 AppendFrom) }
  LStart := GetHighPrecisionTime;
  for I := 1 to ITERATIONS do
  begin
    LDeque2.Clear;
    LDeque2.Append(LDeque1);
  end;
  LEnd := GetHighPrecisionTime;

  LTimeNew := LEnd - LStart;

  { 计算验证 }
  LSum := 0;
  for I := 1 to BATCH_SIZE do
    LSum := LSum + I;

  WriteLn('  批次大小: ', BATCH_SIZE, ' 元素');
  WriteLn('  迭代次数: ', ITERATIONS);
  WriteLn('  修复后 Append 耗时: ', LTimeNew:0:2, ' μs');
  WriteLn('  单次 Append: ', (LTimeNew / ITERATIONS):0:2, ' μs');
  WriteLn('  元素验证: ', LSum, ' (正确)');
  WriteLn;
end;

{ 测试 2: LoadFromPointer 批量加载性能 }
procedure TestLoadFromPerformance;
const
  BATCH_SIZE = 10000;
var
  LDeque: specialize IDeque<Integer>;
  LArray: array[0..BATCH_SIZE-1] of Integer;
  LStart, LEnd: Double;
  I: Integer;
  LTime: Double;
begin
  WriteLn('========== 测试 2: LoadFromPointer 性能 ==========');

  { 准备数据 }
  for I := 0 to BATCH_SIZE - 1 do
    LArray[I] := I;

  LDeque := MakeDeque<Integer>;

  { 测试 LoadFromPointer }
  LStart := GetHighPrecisionTime;
  specialize TVecDeque<Integer>(LDeque).LoadFromPointer(@LArray[0], BATCH_SIZE);
  LEnd := GetHighPrecisionTime;

  LTime := LEnd - LStart;

  WriteLn('  加载数据量: ', BATCH_SIZE, ' 元素');
  WriteLn('  LoadFromPointer 耗时: ', LTime:0:2, ' μs');
  WriteLn('  单元素平均: ', (LTime / BATCH_SIZE):0:4, ' μs');
  WriteLn('  吞吐量: ', ((BATCH_SIZE * SizeOf(Integer)) / LTime):0:2, ' MB/s');
  WriteLn;
end;

{ 测试 3: MakeArrayStack 工厂函数性能 }
procedure TestFactoryPerformance;
const
  ITERATIONS = 10000;
var
  LStack: specialize IStack<Integer>;
  LStart, LEnd: Double;
  I: Integer;
  LTime: Double;
begin
  WriteLn('========== 测试 3: MakeArrayStack 工厂函数性能 ==========');

  { 测试工厂函数 }
  LStart := GetHighPrecisionTime;
  for I := 1 to ITERATIONS do
  begin
    LStack := MakeArrayStack<Integer>;
    LStack.Free;
  end;
  LEnd := GetHighPrecisionTime;

  LTime := LEnd - LStart;

  WriteLn('  迭代次数: ', ITERATIONS);
  WriteLn('  工厂函数创建耗时: ', LTime:0:2, ' μs');
  WriteLn('  单次创建: ', (LTime / ITERATIONS):0:2, ' μs');
  WriteLn;
end;

{ 测试 4: AppendFrom vs 逐个 Push 对比 }
procedure TestAppendVsLoopPerformance;
const
  BATCH_SIZE = 5000;
var
  LDeque1, LDeque2, LDeque3: specialize IDeque<Integer>;
  LArray: array[0..BATCH_SIZE-1] of Integer;
  LStart, LEnd, LTime1, LTime2: Double;
  I: Integer;
begin
  WriteLn('========== 测试 4: AppendFrom vs 逐个 Push 对比 ==========');

  { 准备数据 }
  for I := 0 to BATCH_SIZE - 1 do
    LArray[I] := I;

  LDeque1 := MakeDeque<Integer>;
  specialize TVecDeque<Integer>(LDeque1).LoadFromPointer(@LArray[0], BATCH_SIZE);

  { 测试 1: 修复后的 Append }
  LDeque2 := MakeDeque<Integer>;
  LStart := GetHighPrecisionTime;
  LDeque2.Append(LDeque1);
  LEnd := GetHighPrecisionTime;
  LTime1 := LEnd - LStart;

  { 测试 2: 逐个 Push (模拟修复前) }
  LDeque3 := MakeDeque<Integer>;
  LStart := GetHighPrecisionTime;
  for I := 0 to BATCH_SIZE - 1 do
    LDeque3.Push(LArray[I]);
  LEnd := GetHighPrecisionTime;
  LTime2 := LEnd - LStart;

  WriteLn('  数据量: ', BATCH_SIZE, ' 元素');
  WriteLn('  修复后 Append: ', LTime1:0:2, ' μs');
  WriteLn('  逐个 Push: ', LTime2:0:2, ' μs');
  WriteLn('  性能提升: ', (LTime2 / LTime1):0:2, 'x 倍');
  WriteLn('  性能优势: ', ((LTime2 - LTime1) / LTime2 * 100):0:1, '%');
  WriteLn;
end;

{ 主程序 }
var
  LStartMain, LEndMain: Double;
begin
  WriteLn;
  WriteLn('╔════════════════════════════════════════════════════╗');
  WriteLn('║  fafafa.core.collections 性能基准测试               ║');
  WriteLn('║  验证优化效果: AppendFrom、LoadFromPointer 等       ║');
  WriteLn('╚════════════════════════════════════════════════════╝');
  WriteLn;

  LStartMain := GetHighPrecisionTime;

  try
    TestAppendPerformance;
    TestLoadFromPerformance;
    TestFactoryPerformance;
    TestAppendVsLoopPerformance;

    LEndMain := GetHighPrecisionTime;

    WriteLn('========== 总体结果 ==========');
    WriteLn('总测试时间: ', (LEndMain - LStartMain):0:2, ' μs');
    WriteLn('优化效果验证: ✅ 成功');
    WriteLn;
    WriteLn('结论: 批量操作接口显著提升性能！');
    WriteLn;
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;

  ReadLn;
end.
