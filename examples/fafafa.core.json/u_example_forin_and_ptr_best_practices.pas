unit u_example_forin_and_ptr_best_practices;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

procedure RunAll;

implementation

uses
  SysUtils, Classes,
  fafafa.core.json;

procedure DemoForIn(const Json: String);
var
  R: IJsonValue;
  Doc: IJsonDocument;
  Obj: IJsonValue;
  V: IJsonValue;
  P: TJsonObjectPair;
  // no-op local callbacks kept for clarity; not used after switching to for-in
  function ArrEach(Index: SizeUInt; Item: IJsonValue): Boolean; begin Result := True; end;
  function ObjEach(const Key: String; Value: IJsonValue): Boolean; begin Result := True; end;
begin
  Writeln('--- for-in over array items ---');
  Doc := NewJsonReader().ReadFromString(Json, []);
  R := Doc.Root;
  for V in JsonArrayItems(R.GetObjectValue('arr')) do
    Writeln('item = ', V.GetInteger);

  Writeln('--- for-in over object pairs ---');
  for P in JsonObjectPairs(R.GetObjectValue('obj')) do
    Writeln('key = ', P.Key, ' value = ', P.Value.GetString);
end;

procedure DemoPointerDefaults(const Json: String);
var Doc: IJsonDocument; R: IJsonValue; I64: Int64; S: String; V: IJsonValue;
begin
  Writeln('--- json pointer with defaults ---');
  Doc := NewJsonReader().ReadFromString(Json, []);
  R := Doc.Root;
  V := JsonPointerGet(R, '/arr/9');
  if (V <> nil) and V.IsInteger then I64 := V.GetInteger else I64 := -1;
  V := JsonPointerGet(R, '/obj/k');
  if (V <> nil) and V.IsString then S := V.GetString else S := 'default';
  Writeln('ptr /arr/9 = ', I64, ' /obj/k = ', S);
end;

procedure DemoUtf8Keys(const Json: String);
var Doc: IJsonDocument; R, UObj, V: IJsonValue; Key: UTF8String; S8: UTF8String;
begin
  Writeln('--- utf-8 key helpers ---');
  Doc := NewJsonReader().ReadFromString(Json, []);
  R := Doc.Root;
  UObj := R.GetObjectValue('u');
  Key := UTF8String('你好');
  V := JsonGetValueUtf8(UObj, Key);
  if (V <> nil) and V.IsString then
  begin
    S8 := V.GetUtf8String;
    Writeln('utf8 key "你好" = ', S8);
  end
  else if (V <> nil) then
    Writeln('utf8 key "你好" (non-string) = ', V.GetInteger)
  else
    Writeln('utf8 key not found');
end;

procedure RunAll;
begin
  DemoForIn('{"arr":[1,2,3],"obj":{"a":"A","b":"B"}}');
  DemoPointerDefaults('{"arr":[1,2,3],"obj":{"k":"v"}}');
  DemoUtf8Keys('{"u":{"你好":"世界"}}');
end;

end.

