{$MODE OBJFPC}{$H+}
program simple_collections_benchmark;

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.collections,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.vec,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.list,
  fafafa.core.collections.priorityqueue;

type
  {**
   * 简单的集合类型性能基准测试
   * 使用高精度计时器测量操作性能
   *}

function GetTickCountMicro: Int64;
{$IFDEF WINDOWS}
var
  F: Int64;
begin
  QueryPerformanceCounter(F);
  Result := F;
end;
{$ELSE}
var
  T: TimeVal;
begin
  fpGetTimeOfDay(@T, nil);
  Result := Int64(T.TV_USec) + Int64(T.TV_Sec) * 1000000;
end;
{$ENDIF}

procedure BenchmarkHashMapInsert;
var
  LMap: specialize IHashMap<Integer, Integer>;
  I, StartTick, EndTick: Int64;
  Duration: Double;
  Iterations: Integer;
begin
  WriteLn('[Benchmark] HashMap Insert 10000 elements');
  LMap := specialize MakeHashMap<Integer, Integer>(10000);
  Iterations := 10000;

  StartTick := GetTickCountMicro;
  for I := 0 to Iterations - 1 do
    LMap.Add(I, I * 2);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0; // ms
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn;

  LMap.Free;
end;

procedure BenchmarkHashMapLookup;
var
  LMap: specialize IHashMap<Integer, Integer>;
  I, V, StartTick, EndTick: Int64;
  Duration: Double;
  Iterations: Integer;
begin
  WriteLn('[Benchmark] HashMap Lookup 10000 elements');
  LMap := specialize MakeHashMap<Integer, Integer>(1000);
  for I := 0 to 999 do
    LMap.Add(I, I * 2);

  Iterations := 10000;
  StartTick := GetTickCountMicro;
  for I := 0 to Iterations - 1 do
    LMap.TryGetValue(I mod 1000, V);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0; // ms
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn;

  LMap.Free;
end;

procedure BenchmarkVecInsert;
var
  LVec: specialize IVec<Integer>;
  I, StartTick, EndTick: Int64;
  Duration: Double;
  Iterations: Integer;
begin
  WriteLn('[Benchmark] Vec Insert 10000 elements');
  LVec := specialize MakeVec<Integer>(0);
  Iterations := 10000;

  StartTick := GetTickCountMicro;
  for I := 0 to Iterations - 1 do
    LVec.Add(I);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0; // ms
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn;

  LVec.Free;
end;

procedure BenchmarkVecDequePushBack;
var
  LDeque: specialize IDeque<Integer>;
  I, StartTick, EndTick: Int64;
  Duration: Double;
  Iterations: Integer;
begin
  WriteLn('[Benchmark] VecDeque PushBack 10000 elements');
  LDeque := specialize MakeVecDeque<Integer>(0);
  Iterations := 10000;

  StartTick := GetTickCountMicro;
  for I := 0 to Iterations - 1 do
    LDeque.PushBack(I);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0; // ms
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn;

  LDeque.Free;
end;

procedure BenchmarkListPushBack;
var
  LList: specialize IList<Integer>;
  I, StartTick, EndTick: Int64;
  Duration: Double;
  Iterations: Integer;
begin
  WriteLn('[Benchmark] List PushBack 10000 elements');
  LList := specialize MakeList<Integer>;
  Iterations := 10000;

  StartTick := GetTickCountMicro;
  for I := 0 to Iterations - 1 do
    LList.Add(I);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0; // ms
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn;

  LList.Free;
end;

var
  LStart, LEnd: Int64;
  LDuration: Double;
begin
  WriteLn('===========================================');
  WriteLn('fafafa.core.collections 简单性能基准测试');
  WriteLn('===========================================');
  WriteLn;

  LStart := GetTickCountMicro;

  BenchmarkHashMapInsert;
  BenchmarkHashMapLookup;
  BenchmarkVecInsert;
  BenchmarkVecDequePushBack;
  BenchmarkListPushBack;

  LEnd := GetTickCountMicro;
  LDuration := (LEnd - LStart) / 1000.0;

  WriteLn('===========================================');
  WriteLn(Format('总执行时间: %.2f ms', [LDuration]));
  WriteLn('===========================================');
end.
