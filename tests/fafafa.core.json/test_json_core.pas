unit test_json_core;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}


interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.json, fafafa.core.json.errors;

type
  TJsonCoreTests = class(TTestCase)
  private
    FReader: IJsonReader;
    FWriter: IJsonWriter;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_IsInteger_IsUInteger_And_TryGet_Semantics;
    procedure Test_GetInteger_Range_Check_For_UInt_Bigger_Than_Int64;
    procedure Test_ByPointer_OrDefault;
    procedure Test_ForIn_Enumerators_Array_And_Object;
    procedure Test_ReadFromStream_And_WriteToStream;
    procedure Test_ReadFromFile;
    procedure Test_Utf8Key_Helpers;
    procedure Test_TryGetUtf8_StringValue;
  end;

implementation

procedure TJsonCoreTests.SetUp;
begin
  FReader := NewJsonReader();
  FWriter := NewJsonWriter();
end;

procedure TJsonCoreTests.TearDown;
begin
  FReader := nil;
  FWriter := nil;
end;

procedure TJsonCoreTests.Test_IsInteger_IsUInteger_And_TryGet_Semantics;
var Doc: IJsonDocument; R: IJsonValue; V: IJsonValue; I64: Int64; U64: QWord; B: Boolean; F: Double; S: String;
const J = '{"a":1,"b":-2,"c":3.14,"s":"你好","n":null}';
begin
  Doc := FReader.ReadFromString(J, []);
  R := Doc.Root;
  // a: integer
  V := R.GetObjectValue('a');
  AssertTrue(V.IsNumber);
  AssertTrue(V.IsInteger);
  AssertTrue(V.IsUInteger);
  AssertTrue(JsonTryGetInt(V, I64)); AssertEquals(Int64(1), I64);
  AssertTrue(JsonTryGetUInt(V, U64)); AssertEquals(QWord(1), U64);
  // c: real
  V := R.GetObjectValue('c');
  AssertTrue(V.IsNumber);
  AssertFalse(V.IsInteger);
  AssertFalse(V.IsUInteger);
  I64 := 123; U64 := 456;
  AssertFalse(JsonTryGetInt(V, I64));
  AssertFalse(JsonTryGetUInt(V, U64));
  AssertTrue(JsonTryGetFloat(V, F)); AssertTrue(Abs(F - 3.14) < 1e-9);
  // s: string
  V := R.GetObjectValue('s');
  AssertTrue(V.IsString);
  AssertTrue(JsonTryGetStr(V, S));
  // n: null
  V := R.GetObjectValue('n');
  AssertTrue(V.IsNull);
  B := False; AssertFalse(JsonTryGetBool(V, B));
end;

procedure TJsonCoreTests.Test_GetInteger_Range_Check_For_UInt_Bigger_Than_Int64;
var Doc: IJsonDocument; R, V: IJsonValue;
const J = '{"x":9223372036854775808}'; // MaxInt64 + 1
begin
  Doc := FReader.ReadFromString(J, []);
  R := Doc.Root; V := R.GetObjectValue('x');
  // V 是无符号整数，GetInteger 应抛越界异常
  try
    V.GetInteger;
    Fail('Expected EJsonValueError not raised');
  except
    on E: EJsonValueError do begin
      AssertTrue(Pos(JSON_ERR_NUMBER_OUT_OF_RANGE, E.Message) > 0);
    end;
  end;
end;

procedure TJsonCoreTests.Test_ByPointer_OrDefault;
var Doc: IJsonDocument; R: IJsonValue; I64: Int64; S: String;
const J = '{"arr":[10,20],"obj":{"k":"v"}}';
begin
  Doc := FReader.ReadFromString(J, []);
  R := Doc.Root;
  I64 := JsonGetIntOrDefaultByPtr(R, '/arr/1', -1);
  AssertEquals(Int64(20), I64);
  I64 := JsonGetIntOrDefaultByPtr(R, '/arr/99', -1);
  AssertEquals(Int64(-1), I64);
  S := JsonGetStrOrDefaultByPtr(R, '/obj/k', '');
  AssertEquals('v', S);
  S := JsonGetStrOrDefaultByPtr(R, '/obj/nope', 'd');
  AssertEquals('d', S);
end;

procedure TJsonCoreTests.Test_ForIn_Enumerators_Array_And_Object;
var Doc: IJsonDocument; R: IJsonValue; Sum: Int64; P: TJsonObjectPair; Utf: TJsonObjectPairUtf8; V: IJsonValue;
const J = '{"arr":[10,20],"obj":{"k":"v"},"u":{"你好":1}}';
begin
  Doc := FReader.ReadFromString(J, []);
  R := Doc.Root;
  Sum := 0;
  for V in JsonArrayItems(R.GetObjectValue('arr')) do
    Sum += V.GetInteger;
  AssertEquals(Int64(30), Sum);
  for P in JsonObjectPairs(R.GetObjectValue('obj')) do
  begin
    if P.Key = 'k' then AssertEquals('v', P.Value.GetString);
  end;
  for Utf in JsonObjectPairsUtf8(R.GetObjectValue('u')) do
  begin
    if Utf.Key = UTF8String('你好') then AssertEquals(Int64(1), Utf.Value.GetInteger);
  end;
end;

procedure TJsonCoreTests.Test_ReadFromStream_And_WriteToStream;
var Doc: IJsonDocument; R: IJsonValue; ms: TMemoryStream; S, S2: String;
const J = '{"a":1,"b":2}';
begin
  Doc := FReader.ReadFromString(J, []);
  R := Doc.Root; AssertTrue(R.IsObject);
  // Write to stream
  ms := TMemoryStream.Create;
  try
    AssertTrue(FWriter.WriteToStream(Doc, ms, []));
    ms.Position := 0;
    SetLength(S, ms.Size);
    if ms.Size > 0 then ms.ReadBuffer(Pointer(S)^, ms.Size);
  finally
    ms.Free;
  end;
  // Write to string as baseline
  S2 := FWriter.WriteToString(Doc, []);
  AssertTrue(Length(S2) > 0);
  AssertTrue(Length(S) > 0);
end;

procedure TJsonCoreTests.Test_ReadFromFile;
var Doc: IJsonDocument; Tmp: String;
const J = '{"x":123}';
begin
  Tmp := IncludeTrailingPathDelimiter(GetCurrentDir) + 'tests_tmp.json';
  with TStringStream.Create(J) do
  try
    SaveToFile(Tmp);
  finally
    Free;
  end;
  try
    Doc := FReader.ReadFromFile(Tmp, []);
    AssertEquals(Int64(123), Doc.Root.GetObjectValue('x').GetInteger);
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

procedure TJsonCoreTests.Test_Utf8Key_Helpers;
var Doc: IJsonDocument; R, UObj, V: IJsonValue; Key: UTF8String; I64: Int64;
const J = '{"u":{"你好":1}}';
begin
  Doc := FReader.ReadFromString(J, []);
  R := Doc.Root;
  UObj := R.GetObjectValue('u');
  Key := UTF8String('你好');
  AssertTrue(JsonHasKeyUtf8(UObj, Key));
  V := JsonGetValueUtf8(UObj, Key);
  AssertNotNull(V);
  AssertTrue(V.IsInteger);
  I64 := 0;
  AssertTrue(JsonTryGetInt(V, I64));
  AssertEquals(Int64(1), I64);
end;

procedure TJsonCoreTests.Test_TryGetUtf8_StringValue;
var Doc: IJsonDocument; R, V: IJsonValue; S8: UTF8String;
const J = '{"s":"你好"}';
begin
  Doc := FReader.ReadFromString(J, []);
  R := Doc.Root;
  V := R.GetObjectValue('s');
  AssertTrue(V.IsString);
  S8 := '';
  AssertTrue(JsonTryGetUtf8(V, S8));
  AssertTrue(Length(S8) > 0);
end;

initialization
  RegisterTest(TJsonCoreTests);

end.

