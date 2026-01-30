{$CODEPAGE UTF8}
program fafafa.core.json.perf_rw;

{$MODE OBJFPC}{$H+}
{$modeswitch functionreferences}
{$modeswitch anonymousfunctions}
{$I ../../src/fafafa.core.settings.inc}
{$UNITPATH ../../src}

uses
  SysUtils, DateUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json;

function NowMs: QWord; inline;
begin
  Result := MilliSecondOf(Now);
end;

function BuildLargeObjectJson(N: Integer): String;
var i: Integer;
begin
  Result := '{';
  for i := 0 to N-1 do
  begin
    if i > 0 then Result := Result + ',';
    Result := Result + '"k' + IntToStr(i) + '"' + ':1';
  end;
  Result := Result + '}';
end;

function BuildNumArray(N: Integer): String; forward;

function BuildLargeDocJson(ArrLen: Integer): String;
begin
  Result := '{"arr":[' + BuildNumArray(ArrLen) + '],"obj":{"k":"' + StringOfChar('x',10000) + '"}}';
end;

function BuildObjWithNKeys(N: Integer): String;
var i: Integer;
begin
  Result := '{';
  for i := 0 to N-1 do
  begin
    if i > 0 then Result := Result + ',';
    Result := Result + '"k' + IntToStr(i) + '"' + ':1';
  end;
  Result := Result + '}';
end;

function BuildNumArray(N: Integer): String;
var i: Integer;
begin
  Result := '';
  for i := 0 to N-1 do
  begin
    if i > 0 then Result := Result + ',';
    Result := Result + '1';
  end;
end;

procedure BenchRead(const Name, Json: String; Flags: TJsonReadFlags);
var t0, t1: QWord; Doc: IJsonDocument; R: IJsonReader;
begin
  R := CreateJsonReader(nil);
  t0 := NowMs;
  Doc := R.ReadFromString(Json, Flags);
  t1 := NowMs;
  Writeln(Format('%s Read: %d ms, bytes=%d, values=%d',[Name, t1-t0, Doc.BytesRead, Doc.ValuesRead]));
end;

procedure BenchWrite(const Name, Json: String; RFlags: TJsonReadFlags; WFlags: TJsonWriteFlags);
var t0, t1: QWord; Doc: IJsonDocument; R: IJsonReader; W: IJsonWriter; S: String;
begin
  R := CreateJsonReader(nil);
  W := CreateJsonWriter;
  Doc := R.ReadFromString(Json, RFlags);
  t0 := NowMs;
  S := W.WriteToString(Doc, WFlags);
  t1 := NowMs;
  Writeln(Format('%s Write: %d ms, len=%d',[Name, t1-t0, Length(S)]));
end;

const
  SMALL = '{"a":1,"b":[1,2,3],"c":{"x":true,"y":null}}';

type
  TArgs = record
    ArrLen: Integer;
    NumCount: Integer;
    ObjKeys: Integer;
  end;

var
  A: TArgs;
  LargeJson: String;
  Doc, ObjDoc: IJsonDocument;
  R: IJsonReader;
  V, Item, Obj: IJsonValue;
  Sum, KeySum: Int64;
  t0, t1: QWord;
  i: SizeUInt;
  n: Int64;
  j: Integer;

begin
  // defaults
  A.ArrLen := 10000; A.NumCount := 5000; A.ObjKeys := 2000;
  // simple argv scan
  for j := 1 to ParamCount do begin
    if Pos('--arr=', ParamStr(j))=1 then A.ArrLen := StrToIntDef(Copy(ParamStr(j), 7, 99), A.ArrLen)
    else if Pos('--nums=', ParamStr(j))=1 then A.NumCount := StrToIntDef(Copy(ParamStr(j), 8, 99), A.NumCount)
    else if Pos('--objKeys=', ParamStr(j))=1 then A.ObjKeys := StrToIntDef(Copy(ParamStr(j), 11, 99), A.ObjKeys);
  end;

  LargeJson := BuildLargeDocJson(A.ArrLen);
  BenchRead('small default', SMALL, []);
  BenchRead('small comments+trailing', SMALL, [jrfAllowComments, jrfAllowTrailingCommas]);
  BenchWrite('small pretty', SMALL, [], [jwfPretty]);

  BenchRead('large default', LargeJson, []);

  // ForEach vs Pointer + TryGet
  R := CreateJsonReader(nil);
  Doc := R.ReadFromString('{"nums":[' + BuildNumArray(A.NumCount) + '],"obj":{"k":"' + StringOfChar('x',2000) + '"}}', []);

  // ForEach
  Sum := 0; t0 := NowMs;
  if JsonTryGetObjectValue(Doc.Root, 'nums', V) then
    JsonArrayForEach(V, function(I: SizeUInt; Item: IJsonValue): Boolean
    var n: Int64; ok: Boolean;
    begin
      ok := JsonTryGetInt(Item, n); if ok then Inc(Sum, n);
      Result := True;
    end);
  t1 := NowMs; Writeln(Format('ForEach nums sum: %d ms, sum=%d', [t1-t0, Sum]));

  // Object ForEach: String key vs Raw key
  ObjDoc := R.ReadFromString('{"obj":' + BuildObjWithNKeys(A.ObjKeys) + '}', []);
  Obj := JsonPointerGet(ObjDoc, '/obj');

  // String key version
  KeySum := 0; t0 := NowMs;
  JsonObjectForEach(Obj, function(const Key: String; Val: IJsonValue): Boolean
  var nLocal: Int64;
  begin
    if JsonTryGetInt(Val, nLocal) then Inc(KeySum, nLocal);
    Result := True;
  end);
  t1 := NowMs; Writeln(Format('Object ForEach (String key): %d ms, sum=%d', [t1-t0, KeySum]));

  // Raw key version (avoids transient String for keys)
  KeySum := 0; t0 := NowMs;
  JsonObjectForEachRaw(Obj, function(KeyPtr: PChar; KeyLen: SizeUInt; Val: IJsonValue): Boolean
  var nLocal: Int64;
  begin
    if JsonTryGetInt(Val, nLocal) then Inc(KeySum, nLocal);
    Result := True;
  end);
  t1 := NowMs; Writeln(Format('Object ForEach (Raw key): %d ms, sum=%d', [t1-t0, KeySum]));

  // Pointer + TryGet
  Sum := 0; t0 := NowMs;
  if JsonTryGetObjectValue(Doc.Root, 'nums', V) then
  begin
    // sequential pointer access
    for i := 0 to V.GetArraySize-1 do
    begin
      Item := V.GetArrayItem(i);
      if JsonTryGetInt(Item, n) then Inc(Sum, n);
    end;
  end;
  t1 := NowMs; Writeln(Format('Pointer+TryGet nums sum: %d ms, sum=%d', [t1-t0, Sum]));

  BenchWrite('large pretty', LargeJson, [], [jwfPretty]);
end.

