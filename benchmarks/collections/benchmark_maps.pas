program benchmark_maps;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.treemap,
  fafafa.core.collections.linkedhashmap;

const
  TEST_SIZES: array[0..2] of Integer = (1000, 10000, 100000);
  LOOKUP_COUNT = 10000;

type
  TBenchmarkResult = record
    ContainerType: string;
    Operation: string;
    ElementCount: Integer;
    TimeMs: Double;
    OpsPerSec: Double;
  end;

var
  GResults: array of TBenchmarkResult;

function CompareInt(const a, b: Integer; aData: Pointer): SizeInt;
begin
  if a < b then Result := -1
  else if a > b then Result := 1
  else Result := 0;
end;

procedure AddResult(const aType, aOp: string; aCount: Integer; aTimeMs: Double);
var
  LResult: TBenchmarkResult;
begin
  LResult.ContainerType := aType;
  LResult.Operation := aOp;
  LResult.ElementCount := aCount;
  LResult.TimeMs := aTimeMs;
  if aTimeMs > 0 then
    LResult.OpsPerSec := (aCount / aTimeMs) * 1000
  else
    LResult.OpsPerSec := 0;
  
  SetLength(GResults, Length(GResults) + 1);
  GResults[High(GResults)] := LResult;
end;

function BenchmarkInsert_HashMap(aCount: Integer): Double;
var
  LMap: specialize THashMap<Integer, Integer>;
  LStart, LEnd: QWord;
  i: Integer;
begin
  LMap := specialize THashMap<Integer, Integer>.Create(aCount);
  try
    LStart := GetTickCount64;
    for i := 0 to aCount - 1 do
      LMap.Add(i, i * 2);
    LEnd := GetTickCount64;
    Result := LEnd - LStart;
  finally
    LMap.Free;
  end;
end;

function BenchmarkInsert_TreeMap(aCount: Integer): Double;
var
  LMap: specialize TTreeMap<Integer, Integer>;
  LStart, LEnd: QWord;
  i: Integer;
begin
  LMap := specialize TTreeMap<Integer, Integer>.Create(nil, @CompareInt);
  try
    LStart := GetTickCount64;
    for i := 0 to aCount - 1 do
      LMap.Put(i, i * 2);
    LEnd := GetTickCount64;
    Result := LEnd - LStart;
  finally
    LMap.Free;
  end;
end;

function BenchmarkInsert_LinkedHashMap(aCount: Integer): Double;
var
  LMap: specialize TLinkedHashMap<Integer, Integer>;
  LStart, LEnd: QWord;
  i: Integer;
begin
  LMap := specialize TLinkedHashMap<Integer, Integer>.Create(aCount);
  try
    LStart := GetTickCount64;
    for i := 0 to aCount - 1 do
      LMap.Add(i, i * 2);
    LEnd := GetTickCount64;
    Result := LEnd - LStart;
  finally
    LMap.Free;
  end;
end;

function BenchmarkLookup_HashMap(aCount: Integer): Double;
var
  LMap: specialize THashMap<Integer, Integer>;
  LStart, LEnd: QWord;
  i, LValue: Integer;
begin
  LMap := specialize THashMap<Integer, Integer>.Create(aCount);
  try
    for i := 0 to aCount - 1 do
      LMap.Add(i, i * 2);
    
    LStart := GetTickCount64;
    for i := 0 to LOOKUP_COUNT - 1 do
      LMap.TryGetValue(i mod aCount, LValue);
    LEnd := GetTickCount64;
    Result := LEnd - LStart;
  finally
    LMap.Free;
  end;
end;

function BenchmarkLookup_TreeMap(aCount: Integer): Double;
var
  LMap: specialize TTreeMap<Integer, Integer>;
  LStart, LEnd: QWord;
  i, LValue: Integer;
begin
  LMap := specialize TTreeMap<Integer, Integer>.Create(nil, @CompareInt);
  try
    for i := 0 to aCount - 1 do
      LMap.Put(i, i * 2);
    
    LStart := GetTickCount64;
    for i := 0 to LOOKUP_COUNT - 1 do
      LMap.Get(i mod aCount, LValue);
    LEnd := GetTickCount64;
    Result := LEnd - LStart;
  finally
    LMap.Free;
  end;
end;

function BenchmarkLookup_LinkedHashMap(aCount: Integer): Double;
var
  LMap: specialize TLinkedHashMap<Integer, Integer>;
  LStart, LEnd: QWord;
  i, LValue: Integer;
begin
  LMap := specialize TLinkedHashMap<Integer, Integer>.Create(aCount);
  try
    for i := 0 to aCount - 1 do
      LMap.Add(i, i * 2);
    
    LStart := GetTickCount64;
    for i := 0 to LOOKUP_COUNT - 1 do
      LMap.TryGetValue(i mod aCount, LValue);
    LEnd := GetTickCount64;
    Result := LEnd - LStart;
  finally
    LMap.Free;
  end;
end;

procedure PrintResults;
var
  i: Integer;
begin
  WriteLn;
  WriteLn('╔════════════════════════════════════════════════════════════════╗');
  WriteLn('║     Maps 性能基准测试结果（HashMap/TreeMap/LinkedHashMap）       ║');
  WriteLn('╚════════════════════════════════════════════════════════════════╝');
  WriteLn;
  
  WriteLn('## 插入性能');
  WriteLn;
  WriteLn('| 容器类型 | 元素数量 | 耗时(ms) | Ops/Sec |');
  WriteLn('|----------|----------|----------|---------|');
  for i := 0 to High(GResults) do
  begin
    if GResults[i].Operation = 'Insert' then
      WriteLn(Format('| %-13s | %8d | %8.2f | %9.0f |',
        [GResults[i].ContainerType,
         GResults[i].ElementCount,
         GResults[i].TimeMs,
         GResults[i].OpsPerSec]));
  end;
  WriteLn;
  
  WriteLn('## 查找性能 (', LOOKUP_COUNT, ' 次查找)');
  WriteLn;
  WriteLn('| 容器类型 | 数据集大小 | 耗时(ms) | Ops/Sec |');
  WriteLn('|----------|----------|----------|---------|');
  for i := 0 to High(GResults) do
  begin
    if GResults[i].Operation = 'Lookup' then
      WriteLn(Format('| %-13s | %10d | %8.2f | %9.0f |',
        [GResults[i].ContainerType,
         GResults[i].ElementCount,
         GResults[i].TimeMs,
         GResults[i].OpsPerSec]));
  end;
  WriteLn;
end;

var
  i, LSize: Integer;
  LTime: Double;
begin
  WriteLn('开始 Maps 性能基准测试...');
  WriteLn;
  
  // 插入测试
  for i := 0 to High(TEST_SIZES) do
  begin
    LSize := TEST_SIZES[i];
    WriteLn(Format('测试插入 %d 个元素...', [LSize]));
    
    LTime := BenchmarkInsert_HashMap(LSize);
    AddResult('HashMap', 'Insert', LSize, LTime);
    WriteLn(Format('  HashMap: %.2f ms', [LTime]));
    
    LTime := BenchmarkInsert_TreeMap(LSize);
    AddResult('TreeMap', 'Insert', LSize, LTime);
    WriteLn(Format('  TreeMap: %.2f ms', [LTime]));
    
    LTime := BenchmarkInsert_LinkedHashMap(LSize);
    AddResult('LinkedHashMap', 'Insert', LSize, LTime);
    WriteLn(Format('  LinkedHashMap: %.2f ms', [LTime]));
    WriteLn;
  end;
  
  // 查找测试
  WriteLn(Format('测试随机查找 %d 次...', [LOOKUP_COUNT]));
  for i := 0 to High(TEST_SIZES) do
  begin
    LSize := TEST_SIZES[i];
    WriteLn(Format('  数据集大小: %d', [LSize]));
    
    LTime := BenchmarkLookup_HashMap(LSize);
    AddResult('HashMap', 'Lookup', LSize, LTime);
    WriteLn(Format('    HashMap: %.2f ms', [LTime]));
    
    LTime := BenchmarkLookup_TreeMap(LSize);
    AddResult('TreeMap', 'Lookup', LSize, LTime);
    WriteLn(Format('    TreeMap: %.2f ms', [LTime]));
    
    LTime := BenchmarkLookup_LinkedHashMap(LSize);
    AddResult('LinkedHashMap', 'Lookup', LSize, LTime);
    WriteLn(Format('    LinkedHashMap: %.2f ms', [LTime]));
    WriteLn;
  end;
  
  // 输出格式化结果
  PrintResults;
  
  WriteLn('基准测试完成！');
end.
