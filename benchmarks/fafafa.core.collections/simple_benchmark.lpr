{$CODEPAGE UTF8}
program simple_collections_benchmark;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$UNITPATH ../../src}

uses
  SysUtils,
  fafafa.core.collections,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.list,
  fafafa.core.collections.queue,
  fafafa.core.collections.vec;

const
  DEFAULT_ITERATIONS = 10000;
  LOOKUP_KEY_SPACE = 1000;

function SafeElapsedMs(aStartMs: QWord): QWord;
begin
  Result := GetTickCount64 - aStartMs;
  if Result = 0 then
    Result := 1;
end;

function OpsPerSecond(aOps: QWord; aElapsedMs: QWord): Double;
begin
  if aElapsedMs = 0 then
    aElapsedMs := 1;
  Result := (Double(aOps) * 1000.0) / Double(aElapsedMs);
end;

procedure PrintBenchmarkStats(const aName: string; aIterations: Integer; aElapsedMs: QWord; aPayload: string = '');
begin
  WriteLn('[Benchmark] ', aName);
  WriteLn(Format('  Time: %d ms', [aElapsedMs]));
  WriteLn(Format('  Rate: %.0f ops/sec', [OpsPerSecond(QWord(aIterations), aElapsedMs)]));
  if aPayload <> '' then
    WriteLn('  ', aPayload);
  WriteLn;
end;

procedure BenchmarkHashMapInsert;
var
  LMap: specialize IHashMap<Integer, Integer>;
  LIndex: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
begin
  LMap := specialize MakeHashMap<Integer, Integer>(DEFAULT_ITERATIONS);

  LStartMs := GetTickCount64;
  for LIndex := 0 to DEFAULT_ITERATIONS - 1 do
    LMap.Add(LIndex, LIndex * 2);
  LElapsedMs := SafeElapsedMs(LStartMs);

  PrintBenchmarkStats(
    'HashMap Insert 10000 elements',
    DEFAULT_ITERATIONS,
    LElapsedMs,
    Format('Count=%d', [LMap.Count])
  );
end;

procedure BenchmarkHashMapLookup;
var
  LMap: specialize IHashMap<Integer, Integer>;
  LIndex: Integer;
  LValue: Integer;
  LChecksum: Int64;
  LStartMs: QWord;
  LElapsedMs: QWord;
begin
  LMap := specialize MakeHashMap<Integer, Integer>(LOOKUP_KEY_SPACE);
  for LIndex := 0 to LOOKUP_KEY_SPACE - 1 do
    LMap.Add(LIndex, LIndex * 2);

  LChecksum := 0;
  LStartMs := GetTickCount64;
  for LIndex := 0 to DEFAULT_ITERATIONS - 1 do
    if LMap.TryGetValue(LIndex mod LOOKUP_KEY_SPACE, LValue) then
      Inc(LChecksum, LValue);
  LElapsedMs := SafeElapsedMs(LStartMs);

  PrintBenchmarkStats(
    'HashMap Lookup 10000 elements',
    DEFAULT_ITERATIONS,
    LElapsedMs,
    Format('Checksum=%d', [LChecksum])
  );
end;

procedure BenchmarkVecPush;
var
  LVec: specialize IVec<Integer>;
  LIndex: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
begin
  LVec := specialize MakeVec<Integer>(DEFAULT_ITERATIONS);

  LStartMs := GetTickCount64;
  for LIndex := 0 to DEFAULT_ITERATIONS - 1 do
    LVec.Push(LIndex);
  LElapsedMs := SafeElapsedMs(LStartMs);

  PrintBenchmarkStats(
    'Vec Push 10000 elements',
    DEFAULT_ITERATIONS,
    LElapsedMs,
    Format('Count=%d', [LVec.Count])
  );
end;

procedure BenchmarkDequePushBack;
var
  LDeque: specialize IDeque<Integer>;
  LIndex: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
begin
  LDeque := specialize MakeVecDeque<Integer>(DEFAULT_ITERATIONS);

  LStartMs := GetTickCount64;
  for LIndex := 0 to DEFAULT_ITERATIONS - 1 do
    LDeque.PushBack(LIndex);
  LElapsedMs := SafeElapsedMs(LStartMs);

  PrintBenchmarkStats(
    'VecDeque PushBack 10000 elements',
    DEFAULT_ITERATIONS,
    LElapsedMs,
    Format('Count=%d', [LDeque.Count])
  );
end;

procedure BenchmarkListPushBack;
var
  LList: specialize IList<Integer>;
  LIndex: Integer;
  LStartMs: QWord;
  LElapsedMs: QWord;
begin
  LList := specialize MakeList<Integer>;

  LStartMs := GetTickCount64;
  for LIndex := 0 to DEFAULT_ITERATIONS - 1 do
    LList.PushBack(LIndex);
  LElapsedMs := SafeElapsedMs(LStartMs);

  PrintBenchmarkStats(
    'List PushBack 10000 elements',
    DEFAULT_ITERATIONS,
    LElapsedMs,
    Format('Count=%d', [LList.Count])
  );
end;

var
  LStartMs: QWord;
  LElapsedMs: QWord;
begin
  WriteLn('===========================================');
  WriteLn('fafafa.core.collections simple benchmark');
  WriteLn('===========================================');
  WriteLn;

  LStartMs := GetTickCount64;

  BenchmarkHashMapInsert;
  BenchmarkHashMapLookup;
  BenchmarkVecPush;
  BenchmarkDequePushBack;
  BenchmarkListPushBack;

  LElapsedMs := SafeElapsedMs(LStartMs);
  WriteLn('===========================================');
  WriteLn(Format('Total elapsed: %d ms', [LElapsedMs]));
  WriteLn('===========================================');
end.
