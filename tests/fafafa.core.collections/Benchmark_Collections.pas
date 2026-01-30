unit Benchmark_Collections;

{$mode objfpc}{$H+}

{**
 * Benchmark_Collections - 集合性能基准测试
 *
 * 用于测量各容器操作的性能
 * 输出格式: 操作名称, 次数, 总耗时(ms), 每次耗时(ns)
 *}

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry,
  fafafa.core.collections.base,
  fafafa.core.collections.vec,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.treemap,
  fafafa.core.collections.bitset,
  fafafa.core.collections.skiplist;

type
  TIntVec = specialize TVec<Integer>;
  TIntHashMap = specialize THashMap<Integer, Integer>;
  TIntTreeMap = specialize TTreeMap<Integer, Integer>;
  TIntSkipList = specialize TSkipList<Integer, Integer>;

  { TBenchmarkCollections }
  TBenchmarkCollections = class(TTestCase)
  private
    FStartTime: QWord;
    procedure StartTimer;
    function StopTimer: Double; // Returns milliseconds
    procedure Report(const aName: string; aIterations: Integer; aTimeMs: Double);
  published
    // Vec benchmarks
    procedure Bench_Vec_PushBack_100K;
    procedure Bench_Vec_RandomAccess_100K;
    procedure Bench_Vec_Iterate_100K;
    
    // HashMap benchmarks
    procedure Bench_HashMap_Insert_100K;
    procedure Bench_HashMap_Lookup_100K;
    procedure Bench_HashMap_Delete_50K;
    
    // TreeMap benchmarks
    procedure Bench_TreeMap_Insert_100K;
    procedure Bench_TreeMap_Lookup_100K;
    procedure Bench_TreeMap_InOrder_100K;
    
    // BitSet benchmarks
    procedure Bench_BitSet_SetBit_1M;
    procedure Bench_BitSet_Cardinality_1M;
    procedure Bench_BitSet_And_1M;
    
    // SkipList benchmarks
    procedure Bench_SkipList_Insert_100K;
    procedure Bench_SkipList_Lookup_100K;
  end;

implementation

{ High-resolution timer using TDateTime }

function GetTickNow: TDateTime;
begin
  Result := Now;
end;

function DateTimeToMs(aStart, aEnd: TDateTime): Double;
begin
  Result := MilliSecondSpan(aEnd, aStart);
end;

{ Compare function for TreeMap }
function CompareInt(const A, B: Integer): SizeInt;
begin
  if A < B then Result := -1
  else if A > B then Result := 1
  else Result := 0;
end;

{ TBenchmarkCollections }

var
  GStartTime: TDateTime;

procedure TBenchmarkCollections.StartTimer;
begin
  GStartTime := GetTickNow;
end;

function TBenchmarkCollections.StopTimer: Double;
begin
  Result := DateTimeToMs(GStartTime, GetTickNow);
end;

procedure TBenchmarkCollections.Report(const aName: string; aIterations: Integer; aTimeMs: Double);
var
  NsPerOp: Double;
begin
  if aTimeMs > 0 then
    NsPerOp := (aTimeMs * 1000000) / aIterations
  else
    NsPerOp := 0;
  WriteLn(Format('  %-30s %8d ops  %8.2f ms  %8.1f ns/op', 
    [aName, aIterations, aTimeMs, NsPerOp]));
end;

{ Vec Benchmarks }

procedure TBenchmarkCollections.Bench_Vec_PushBack_100K;
const
  N = 100000;
var
  V: TIntVec;
  i: Integer;
  t: Double;
begin
  V := TIntVec.Create;
  try
    StartTimer;
    for i := 0 to N - 1 do
      V.Push(i);
    t := StopTimer;
    Report('Vec.Push', N, t);
    AssertEquals(Int64(N), Int64(V.Count));
  finally
    V.Free;
  end;
end;

procedure TBenchmarkCollections.Bench_Vec_RandomAccess_100K;
const
  N = 100000;
var
  V: TIntVec;
  i: Integer;
  sum: Int64;
  t: Double;
begin
  V := TIntVec.Create;
  try
    for i := 0 to N - 1 do
      V.Push(i);
    
    sum := 0;
    StartTimer;
    for i := 0 to N - 1 do
      sum := sum + V[i];
    t := StopTimer;
    Report('Vec[i] access', N, t);
    AssertTrue(sum > 0);
  finally
    V.Free;
  end;
end;

procedure TBenchmarkCollections.Bench_Vec_Iterate_100K;
const
  N = 100000;
var
  V: TIntVec;
  i: Integer;
  sum: Int64;
  t: Double;
  Arr: specialize TGenericArray<Integer>;
begin
  V := TIntVec.Create;
  try
    for i := 0 to N - 1 do
      V.Push(i);
    
    sum := 0;
    Arr := V.ToArray;
    StartTimer;
    for i := 0 to High(Arr) do
      sum := sum + Arr[i];
    t := StopTimer;
    Report('Vec iterate', N, t);
    AssertTrue(sum > 0);
  finally
    V.Free;
  end;
end;

{ HashMap Benchmarks }

procedure TBenchmarkCollections.Bench_HashMap_Insert_100K;
const
  N = 100000;
var
  M: TIntHashMap;
  i: Integer;
  t: Double;
begin
  M := TIntHashMap.Create;
  try
    StartTimer;
    for i := 0 to N - 1 do
      M.Add(i, i * 2);
    t := StopTimer;
    Report('HashMap.Add', N, t);
    AssertEquals(Int64(N), Int64(M.Count));
  finally
    M.Free;
  end;
end;

procedure TBenchmarkCollections.Bench_HashMap_Lookup_100K;
const
  N = 100000;
var
  M: TIntHashMap;
  i: Integer;
  v: Integer;
  t: Double;
begin
  M := TIntHashMap.Create;
  try
    for i := 0 to N - 1 do
      M.Add(i, i * 2);
    
    StartTimer;
    for i := 0 to N - 1 do
      M.TryGetValue(i, v);
    t := StopTimer;
    Report('HashMap.TryGetValue', N, t);
  finally
    M.Free;
  end;
end;

procedure TBenchmarkCollections.Bench_HashMap_Delete_50K;
const
  N = 100000;
  D = 50000;
var
  M: TIntHashMap;
  i: Integer;
  t: Double;
begin
  M := TIntHashMap.Create;
  try
    for i := 0 to N - 1 do
      M.Add(i, i * 2);
    
    StartTimer;
    for i := 0 to D - 1 do
      M.Remove(i);
    t := StopTimer;
    Report('HashMap.Remove', D, t);
    AssertEquals(Int64(N - D), Int64(M.Count));
  finally
    M.Free;
  end;
end;

{ TreeMap Benchmarks }

procedure TBenchmarkCollections.Bench_TreeMap_Insert_100K;
const
  N = 100000;
var
  M: TIntTreeMap;
  i: Integer;
  t: Double;
begin
  M := TIntTreeMap.Create(nil, @CompareInt);
  try
    StartTimer;
    for i := 0 to N - 1 do
      M.Put(i, i * 2);
    t := StopTimer;
    Report('TreeMap.Put', N, t);
    AssertEquals(Int64(N), Int64(M.Count));
  finally
    M.Free;
  end;
end;

procedure TBenchmarkCollections.Bench_TreeMap_Lookup_100K;
const
  N = 100000;
var
  M: TIntTreeMap;
  i: Integer;
  v: Integer;
  t: Double;
begin
  M := TIntTreeMap.Create(nil, @CompareInt);
  try
    for i := 0 to N - 1 do
      M.Put(i, i * 2);
    
    StartTimer;
    for i := 0 to N - 1 do
      M.Get(i, v);
    t := StopTimer;
    Report('TreeMap.Get', N, t);
  finally
    M.Free;
  end;
end;

procedure TBenchmarkCollections.Bench_TreeMap_InOrder_100K;
const
  N = 100000;
var
  M: TIntTreeMap;
  i: Integer;
  t: Double;
  v: Integer;
  sum: Int64;
begin
  M := TIntTreeMap.Create(nil, @CompareInt);
  try
    for i := 0 to N - 1 do
      M.Put(i, i * 2);
    
    // Iterate by sequential lookup (simulates in-order access)
    sum := 0;
    StartTimer;
    for i := 0 to N - 1 do
    begin
      M.Get(i, v);
      sum := sum + v;
    end;
    t := StopTimer;
    Report('TreeMap sequential', N, t);
    AssertTrue(sum > 0);
  finally
    M.Free;
  end;
end;

{ BitSet Benchmarks }

procedure TBenchmarkCollections.Bench_BitSet_SetBit_1M;
const
  N = 1000000;
var
  B: TBitSet;
  i: Integer;
  t: Double;
begin
  B := TBitSet.Create(N);
  try
    StartTimer;
    for i := 0 to N - 1 do
      B.SetBit(i);
    t := StopTimer;
    Report('BitSet.SetBit', N, t);
    AssertEquals(Int64(N), Int64(B.Cardinality));
  finally
    B.Free;
  end;
end;

procedure TBenchmarkCollections.Bench_BitSet_Cardinality_1M;
const
  N = 1000000;
  ITERS = 100;
var
  B: TBitSet;
  i, j: Integer;
  t: Double;
  c: SizeUInt;
begin
  B := TBitSet.Create(N);
  try
    for i := 0 to N - 1 do
      if i mod 2 = 0 then
        B.SetBit(i);
    
    StartTimer;
    for j := 0 to ITERS - 1 do
      c := B.Cardinality;
    t := StopTimer;
    Report('BitSet.Cardinality (1M bits)', ITERS, t);
    AssertEquals(Int64(N div 2), Int64(c));
  finally
    B.Free;
  end;
end;

procedure TBenchmarkCollections.Bench_BitSet_And_1M;
const
  N = 1000000;
  ITERS = 100;
var
  B1, B2: TBitSet;
  R: IBitSet;
  i, j: Integer;
  t: Double;
begin
  B1 := TBitSet.Create(N);
  B2 := TBitSet.Create(N);
  try
    for i := 0 to N - 1 do
    begin
      if i mod 2 = 0 then B1.SetBit(i);
      if i mod 3 = 0 then B2.SetBit(i);
    end;
    
    StartTimer;
    for j := 0 to ITERS - 1 do
      R := B1.AndWith(B2);
    t := StopTimer;
    Report('BitSet.AndWith (1M bits)', ITERS, t);
  finally
    B1.Free;
    B2.Free;
  end;
end;

{ SkipList Benchmarks }

procedure TBenchmarkCollections.Bench_SkipList_Insert_100K;
const
  N = 100000;
var
  S: TIntSkipList;
  i: Integer;
  t: Double;
begin
  S := TIntSkipList.Create;
  try
    StartTimer;
    for i := 0 to N - 1 do
      S.Put(i, i * 2);
    t := StopTimer;
    Report('SkipList.Put', N, t);
    AssertEquals(Int64(N), Int64(S.Count));
  finally
    S.Free;
  end;
end;

procedure TBenchmarkCollections.Bench_SkipList_Lookup_100K;
const
  N = 100000;
var
  S: TIntSkipList;
  i: Integer;
  v: Integer;
  t: Double;
begin
  S := TIntSkipList.Create;
  try
    for i := 0 to N - 1 do
      S.Put(i, i * 2);
    
    StartTimer;
    for i := 0 to N - 1 do
      S.Get(i, v);
    t := StopTimer;
    Report('SkipList.Get', N, t);
  finally
    S.Free;
  end;
end;

initialization
  RegisterTest(TBenchmarkCollections);
end.
