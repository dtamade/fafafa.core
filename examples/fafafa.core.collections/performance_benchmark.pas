program PerformanceBenchmark;

{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils,
  fafafa.core.collections.arr;

type
  TIntArray = specialize TArray<Integer>;

const
  ARRAY_SIZE = 100000;
  ITERATIONS = 1000;

var
  TestArray: TIntArray;
  StartTime, EndTime: TDateTime;
  i, j, Index, Count: Integer;
  Found: Boolean;

procedure InitializeTestArray;
begin
  TestArray := TIntArray.Create;
  TestArray.Resize(ARRAY_SIZE);
  
  // 填充测试数据
  for i := 0 to ARRAY_SIZE - 1 do
    TestArray.PutUnChecked(i, i);
end;

procedure BenchmarkFind;
begin
  WriteLn('=== Find 性能测试 ===');
  
  // 测试普通方法
  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    for j := 0 to 99 do
      Index := TestArray.Find(j * 1000, 0, ARRAY_SIZE);
  end;
  EndTime := Now;
  WriteLn('普通方法 Find: ', MilliSecondsBetween(EndTime, StartTime), ' ms');
  
  // 测试 UnChecked 方法
  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    for j := 0 to 99 do
      Index := TestArray.FindUnChecked(j * 1000, 0, ARRAY_SIZE);
  end;
  EndTime := Now;
  WriteLn('UnChecked Find: ', MilliSecondsBetween(EndTime, StartTime), ' ms');
  WriteLn;
end;

procedure BenchmarkContains;
begin
  WriteLn('=== Contains 性能测试 ===');
  
  // 测试普通方法
  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    for j := 0 to 99 do
      Found := TestArray.Contains(j * 1000, 0, ARRAY_SIZE);
  end;
  EndTime := Now;
  WriteLn('普通方法 Contains: ', MilliSecondsBetween(EndTime, StartTime), ' ms');
  
  // 测试 UnChecked 方法
  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    for j := 0 to 99 do
      Found := TestArray.ContainsUnChecked(j * 1000, 0, ARRAY_SIZE);
  end;
  EndTime := Now;
  WriteLn('UnChecked Contains: ', MilliSecondsBetween(EndTime, StartTime), ' ms');
  WriteLn;
end;

procedure BenchmarkCountOf;
begin
  WriteLn('=== CountOf 性能测试 ===');
  
  // 测试普通方法
  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    for j := 0 to 99 do
      Count := TestArray.CountOf(j * 1000, 0, ARRAY_SIZE);
  end;
  EndTime := Now;
  WriteLn('普通方法 CountOf: ', MilliSecondsBetween(EndTime, StartTime), ' ms');
  
  // 测试 UnChecked 方法
  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    for j := 0 to 99 do
      Count := TestArray.CountOfUnChecked(j * 1000, 0, ARRAY_SIZE);
  end;
  EndTime := Now;
  WriteLn('UnChecked CountOf: ', MilliSecondsBetween(EndTime, StartTime), ' ms');
  WriteLn;
end;

function IsEven(const aValue: Integer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

procedure BenchmarkFindIF;
begin
  WriteLn('=== FindIF 性能测试 ===');
  
  // 测试普通方法
  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    Index := TestArray.FindIF(0, ARRAY_SIZE, @IsEven, nil);
  end;
  EndTime := Now;
  WriteLn('普通方法 FindIF: ', MilliSecondsBetween(EndTime, StartTime), ' ms');
  
  // 测试 UnChecked 方法
  StartTime := Now;
  for i := 1 to ITERATIONS do
  begin
    Index := TestArray.FindIFUnChecked(0, ARRAY_SIZE, @IsEven, nil);
  end;
  EndTime := Now;
  WriteLn('UnChecked FindIF: ', MilliSecondsBetween(EndTime, StartTime), ' ms');
  WriteLn;
end;

begin
  WriteLn('FreePascal 集合框架 UnChecked 方法性能基准测试');
  WriteLn('================================================');
  WriteLn('数组大小: ', ARRAY_SIZE);
  WriteLn('迭代次数: ', ITERATIONS);
  WriteLn;
  
  InitializeTestArray;
  
  BenchmarkFind;
  BenchmarkContains;
  BenchmarkCountOf;
  BenchmarkFindIF;
  
  WriteLn('测试完成！');
  WriteLn('UnChecked 方法通过跳过边界检查提供更高性能。');
  WriteLn('在性能关键的代码中，请使用 UnChecked 版本。');
  
  TestArray.Free;
end.
