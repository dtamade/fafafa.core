program example_json_pointer_min;

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

function StrOfJsonString(AVal: PJsonValue): String;
begin
  if Assigned(AVal) and JsonIsStr(AVal) then
    Result := String(JsonGetStrUtf8(AVal))
  else
    Result := '';
end;

procedure Test_Immutable;
var
  Al: TAllocator; Err: TJsonError; Doc: TJsonDocument; S: String; R: PJsonValue;
begin
  Writeln('== Immutable Pointer Test ==');
  Al := GetRtlAllocator();
  S := '{"a":[{"k":"v"}, {"k":"v2"}], "b": 123}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  if not Assigned(Doc) then begin Writeln('Read failed: ', Err.Message); Exit; end;
  R := JsonPtrGet(JsonDocGetRoot(Doc), '/a/1/k');
  if Assigned(R) then Writeln('ptr /a/1/k = ', StrOfJsonString(R)) else Writeln('ptr not found');
  JsonDocFree(Doc);
end;

procedure Test_Mutable;
var
  Al: TAllocator; M: TJsonMutDocument; Root, Arr, Obj, V: PJsonMutValue; S: String;
begin
  Writeln('== Mutable Pointer Test ==');
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Arr := JsonMutObjAddArr(M, Root, 'a');
  Obj := JsonMutArrAddObj(M, Arr);
  JsonMutObjAddStr(M, Obj, 'k', 'v2');
  V := JsonMutPtrGet(Root, '/a/0/k');
  if Assigned(V) then begin S := StrOfJsonString(PJsonValue(V)); Writeln('ptr /a/0/k = ', S); end else Writeln('ptr not found');
  M.Free;
end;

begin
  Test_Immutable;
  Test_Mutable;
end.

