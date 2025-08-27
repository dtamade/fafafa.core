unit Test_fafafa_core_json_facade_typed_tryget;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json;

procedure RegisterTests;

implementation

type
  TTestCase_FacadeTypedTryGet = class(TTestCase)
  published
    procedure Test_Typed_TryGet_Success;
    procedure Test_Typed_TryGet_Fail;
    procedure Test_OrDefault;
  end;

procedure TTestCase_FacadeTypedTryGet.Test_Typed_TryGet_Success;
var
  D: TJsonDocument; Doc: IJsonDocument; Obj, V: IJsonValue;
  b: Boolean; i: Int64; u: UInt64; f: Double; s: String; ok: Boolean;
begin
  D := JsonRead(PChar('{"b":true,"i":-5,"u":6,"f":1.5,"s":"x"}'), Length('{"b":true,"i":-5,"u":6,"f":1.5,"s":"x"}'), []);
  Doc := JsonWrapDocument(D);
  Obj := Doc.Root;
  AssertTrue(JsonTryGetObjectValue(Obj, 'b', V)); ok := JsonTryGetBool(V, b); AssertTrue(ok); AssertTrue(b);
  AssertTrue(JsonTryGetObjectValue(Obj, 'i', V)); ok := JsonTryGetInt(V, i); AssertTrue(ok); AssertEquals(-5, i);
  AssertTrue(JsonTryGetObjectValue(Obj, 'u', V)); ok := JsonTryGetUInt(V, u); AssertTrue(ok); AssertEquals(QWord(6), u);
  AssertTrue(JsonTryGetObjectValue(Obj, 'f', V)); ok := JsonTryGetFloat(V, f); AssertTrue(ok); AssertEquals(1.5, f);
  AssertTrue(JsonTryGetObjectValue(Obj, 's', V)); ok := JsonTryGetStr(V, s); AssertTrue(ok); AssertEquals('x', s);
end;

procedure TTestCase_FacadeTypedTryGet.Test_Typed_TryGet_Fail;
var
  D: TJsonDocument; Doc: IJsonDocument; Obj, V: IJsonValue;
  b: Boolean; i: Int64; u: UInt64; f: Double; s: String; ok: Boolean;
begin
  D := JsonRead(PChar('{"n":null,"a":[],"o":{}}'), Length('{"n":null,"a":[],"o":{}}'), []);
  Doc := JsonWrapDocument(D);
  Obj := Doc.Root;
  AssertTrue(JsonTryGetObjectValue(Obj, 'n', V)); ok := JsonTryGetBool(V, b); AssertFalse(ok);
  ok := JsonTryGetInt(V, i); AssertFalse(ok);
  ok := JsonTryGetUInt(V, u); AssertFalse(ok);
  ok := JsonTryGetFloat(V, f); AssertFalse(ok);
  ok := JsonTryGetStr(V, s); AssertFalse(ok);
  AssertTrue(JsonTryGetObjectValue(Obj, 'a', V)); ok := JsonTryGetStr(V, s); AssertFalse(ok);
  AssertTrue(JsonTryGetObjectValue(Obj, 'o', V)); ok := JsonTryGetStr(V, s); AssertFalse(ok);
end;

procedure TTestCase_FacadeTypedTryGet.Test_OrDefault;
var
  D: TJsonDocument; Doc: IJsonDocument; Obj, V: IJsonValue;
  b: Boolean; i: Int64; u: UInt64; f: Double; s: String;
begin
  D := JsonRead(PChar('{"b":true,"x":123,"s":"hi"}'), Length('{"b":true,"x":123,"s":"hi"}'), []);
  Doc := JsonWrapDocument(D);
  Obj := Doc.Root;
  AssertTrue(JsonTryGetObjectValue(Obj, 'b', V)); b := JsonGetBoolOrDefault(V, False); AssertTrue(b);
  AssertTrue(JsonTryGetObjectValue(Obj, 'x', V)); i := JsonGetIntOrDefault(V, -1); AssertEquals(123, i);
  AssertTrue(JsonTryGetObjectValue(Obj, 'x', V)); u := JsonGetUIntOrDefault(V, 7); AssertEquals(QWord(123), u);
  AssertTrue(JsonTryGetObjectValue(Obj, 'x', V)); f := JsonGetFloatOrDefault(V, 0.5); AssertEquals(123.0, f);
  AssertTrue(JsonTryGetObjectValue(Obj, 's', V)); s := JsonGetStrOrDefault(V, ''); AssertEquals('hi', s);

  // not exists
  AssertFalse(JsonTryGetObjectValue(Obj, 'nope', V)); b := JsonGetBoolOrDefault(V, False); AssertFalse(b);
  i := JsonGetIntOrDefault(nil, -2); AssertEquals(-2, i);
  u := JsonGetUIntOrDefault(nil, 8); AssertEquals(QWord(8), u);
  f := JsonGetFloatOrDefault(nil, 0.25); AssertEquals(0.25, f);
  s := JsonGetStrOrDefault(nil, 'd'); AssertEquals('d', s);
end;

procedure RegisterTests;
begin
  RegisterTest('json-facade', TTestCase_FacadeTypedTryGet.Suite);
end;

initialization
  RegisterTests;

end.

