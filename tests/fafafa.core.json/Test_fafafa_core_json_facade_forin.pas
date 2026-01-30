unit Test_fafafa_core_json_facade_forin;

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
  TTestCase_FacadeForIn = class(TTestCase)
  published
    procedure Test_ForIn_Array_Items;
    procedure Test_ForIn_Object_Pairs;
    procedure Test_Pointer_Defaults_And_Types;
  end;

procedure TTestCase_FacadeForIn.Test_ForIn_Array_Items;
var
  D: TJsonDocument; Doc: IJsonDocument; R, V: IJsonValue; S: String;
  I, Count, Sum: Integer;
begin
  D := JsonRead(PChar('{"arr":[1,2,3]}'), Length('{"arr":[1,2,3]}'), [jrfDefault]);
  Doc := JsonWrapDocument(D);
  R := Doc.Root;
  Count := 0; Sum := 0;
  for V in JsonArrayItems(R.GetObjectValue('arr')) do
  begin
    Inc(Count);
    Sum += V.GetInteger;
  end;
  AssertEquals('array count', 3, Count);
  AssertEquals('sum items', 1+2+3, Sum);
end;

procedure TTestCase_FacadeForIn.Test_ForIn_Object_Pairs;
var
  D: TJsonDocument; Doc: IJsonDocument; R: IJsonValue; P: TJsonObjectPair;
  Keys: array of String;
begin
  D := JsonRead(PChar('{"obj":{"a":"A","b":"B"}}'), Length('{"obj":{"a":"A","b":"B"}}'), [jrfDefault]);
  Doc := JsonWrapDocument(D);
  R := Doc.Root;
  SetLength(Keys, 0);
  for P in JsonObjectPairs(R.GetObjectValue('obj')) do
  begin
    SetLength(Keys, Length(Keys)+1);
    Keys[High(Keys)] := P.Key;
    AssertTrue('value is string', P.Value.IsString);
  end;
  AssertEquals('keys count', 2, Length(Keys));
end;

procedure TTestCase_FacadeForIn.Test_Pointer_Defaults_And_Types;
var
  D: TJsonDocument; Doc: IJsonDocument; R, V: IJsonValue; I64: Int64; S: String; U8: UTF8String;
begin
  Doc := NewJsonReader().ReadFromString('{"arr":[1,2],"obj":{"k":"v"},"u":{"你好":"世界"}}', [jrfDefault]);
  if Doc=nil then Writeln('Doc is nil') else Writeln('Doc ok');
  R := Doc.Root;
  if R=nil then Writeln('Root is nil') else Writeln('Root ok');
  Writeln('stage: start');
  I64 := JsonGetIntOrDefaultByPtr(R, '/arr/9', -1);
  Writeln('stage: after int default');
  AssertEquals('ptr default int', -1, I64);
  S := JsonGetStrOrDefaultByPtr(R, '/obj/k', 'default');
  Writeln('stage: after str default');
  AssertEquals('ptr str ok', 'v', S);
  V := JsonGetValueUtf8(R.GetObjectValue('u'), UTF8String('你好'));
  Writeln('stage: after get utf8 value');
  AssertTrue('utf8 key exists', V<>nil);
  AssertTrue('utf8 key is string', V.IsString);
  AssertTrue('try get utf8 ok', JsonTryGetUtf8(V, U8));
  // fpcunit assert prints with console codepage; compare via length and raw bytes
  AssertEquals('utf8 len', Length(UTF8String('世界')), Length(U8));
  // Compare raw bytes using CompareMem for robustness
  AssertTrue('utf8 bytes equal', CompareMem(Pointer(U8), Pointer(UTF8String('世界')), Length(U8)));
end;

procedure RegisterTests;
begin
  RegisterTest('json-facade-forin', TTestCase_FacadeForIn.Suite);
end;

initialization
  RegisterTests;

end.

