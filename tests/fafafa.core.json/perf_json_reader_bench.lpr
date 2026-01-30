program perf_json_reader_bench;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

function NowMs: QWord; inline; begin Result := GetTickCount64(); end;

function ReadDoc(const S: RawByteString; Flags: TJsonReadFlags): Boolean;
var Alc: TAllocator; Err: TJsonError; D: TJsonDocument;
begin
  Alc := GetRtlAllocator();
  D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err);
  Result := Assigned(D);
  if Result then JsonDocFree(D);
end;

procedure Bench(const Name, S: RawByteString; Flags: TJsonReadFlags; Iter: QWord);
var t0,t1: QWord; i: QWord; ok: QWord;
var Alc: TAllocator; Err: TJsonError; D: TJsonDocument;
begin
  // one-shot diagnose
  Alc := GetRtlAllocator();
  D := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err);
  if not Assigned(D) then
    WriteLn('[DIAG] ', Name, ' first-read failed: code=', Ord(Err.Code), ' pos=', Err.Position, ' msg=', Err.Message)
  else begin
    WriteLn('[DIAG] ', Name, ' first-read ok, len=', Length(S));
    JsonDocFree(D);
  end;
  // loop bench
  t0 := NowMs(); ok := 0;
  for i := 1 to Iter do if ReadDoc(S, Flags) then Inc(ok);
  t1 := NowMs();
  WriteLn(Name, ' iter=', Iter, ' ok=', ok, ' time_ms=', (t1 - t0));
end;

procedure BenchCSV(const Name, S: RawByteString; Flags: TJsonReadFlags; Iter: QWord);
var t0,t1: QWord; i: QWord; ok: QWord;
begin
  t0 := NowMs(); ok := 0;
  for i := 1 to Iter do if ReadDoc(S, Flags) then Inc(ok);
  t1 := NowMs();
  WriteLn('CSV,', Name, ',', Iter, ',', ok, ',', (t1 - t0));
end;

function GenLargeArrayObj(Items, Fields: Integer): RawByteString;
var i,j: Integer; s: RawByteString;
begin
  s := '[';
  for i := 1 to Items do begin
    s := s + '{';
    for j := 1 to Fields do begin
      s := s + '"k'+IntToStr(j)+'":'+IntToStr(j);
      if j < Fields then s := s + ',';
    end;
    s := s + '}';
    if i < Items then s := s + ',';
  end;
  s := s + ']';
  Result := s;
end;

function GenNestedMixed(levels, width: Integer): RawByteString;
var lvl, i: Integer; s: RawByteString;
begin
  s := '{"a":[';
  for lvl := 1 to levels do begin
    s := s + '{"n":'+IntToStr(lvl)+',"arr":[';
    for i := 1 to width do begin
      s := s + IntToStr(i);
      if i < width then s := s + ',';
    end;
    s := s + '] }';
    if lvl < levels then s := s + ',';
  end;
  s := s + ']}';
  Result := s;
end;


var SmallObj, ArrNums, DeepObj, BigArrObj100k, BigArrObj1m, Mixed100k, Mixed1m: RawByteString; i: Integer;
begin
  SmallObj := '{"a":1,"b":"x","c":true,"d":null}';
  ArrNums := '[';
  for i := 1 to 1000 do begin ArrNums := ArrNums + '1'; if i < 1000 then ArrNums := ArrNums + ','; end;
  ArrNums := ArrNums + ',0]';
  DeepObj := '{"a":{"b":{"c":{"d":{"e":1}}}}}';

  // generate ~100KB and ~1MB payloads (rough approximations)
  BigArrObj100k := GenLargeArrayObj(300, 20);
  BigArrObj1m := GenLargeArrayObj(3500, 20);
  Mixed100k := GenNestedMixed(60, 20);
  Mixed1m := GenNestedMixed(600, 20);

  // human-readable bench
  Bench('SmallObj', SmallObj, [], 20000);
  Bench('ArrNums', ArrNums, [], 3000);
  Bench('DeepObj', DeepObj, [], 20000);
  Bench('BigArrObj100k', BigArrObj100k, [], 200);
  Bench('BigArrObj1m', BigArrObj1m, [], 20);
  Bench('Mixed100k', Mixed100k, [], 200);
  Bench('Mixed1m', Mixed1m, [], 20);

  // CSV bench (name,iter,ok,time_ms)
  BenchCSV('SmallObj', SmallObj, [], 20000);
  BenchCSV('ArrNums', ArrNums, [], 3000);
  BenchCSV('DeepObj', DeepObj, [], 20000);
  BenchCSV('BigArrObj100k', BigArrObj100k, [], 200);
  BenchCSV('BigArrObj1m', BigArrObj1m, [], 20);
  BenchCSV('Mixed100k', Mixed100k, [], 200);
  BenchCSV('Mixed1m', Mixed1m, [], 20);
end.

