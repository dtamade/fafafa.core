{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer = class(TTestCase)
  published
    procedure Test_Ptr_Immutable_Basic;
    procedure Test_Ptr_Mutable_Basic;
  end;

implementation

procedure TTestCase_JsonPointer.Test_Ptr_Immutable_Basic;
var Doc: TJsonDocument; Err: TJsonError; Al: TAllocator; S: String; R: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"a":[{"k":"v"}, {"k":"v2"}], "b": 123}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  R := JsonPtrGet(JsonDocGetRoot(Doc), '/a/1/k');
  AssertTrue(Assigned(R));
  AssertTrue(JsonEqualsStrN(R, 'v2', 2));
  Doc.Free;
end;

procedure TTestCase_JsonPointer.Test_Ptr_Mutable_Basic;
var M: TJsonMutDocument; Root, Arr, Obj: PJsonMutValue; Al: TAllocator; V: PJsonMutValue;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Arr := JsonMutObjAddArr(M, Root, 'a');
  Obj := JsonMutArrAddObj(M, Arr);
  AssertTrue(Assigned(Obj));
  AssertTrue(JsonMutObjAddStr(M, Obj, 'k', 'v2'));
  V := JsonMutPtrGet(Root, '/a/0/k');
  AssertTrue(Assigned(V));
  AssertTrue(JsonEqualsStrN(PJsonValue(V), 'v2', 2));
  M.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer);
end.

