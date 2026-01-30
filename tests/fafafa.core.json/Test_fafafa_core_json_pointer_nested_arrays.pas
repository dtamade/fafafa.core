{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_nested_arrays;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_NestedArrays = class(TTestCase)
  published
    procedure Test_Obj_Arr_Interleaved_Nesting;
  end;

implementation

procedure TTestCase_JsonPointer_NestedArrays.Test_Obj_Arr_Interleaved_Nesting;
var Doc: TJsonDocument; Err: TJsonError; Al: TAllocator; S: String; Root, X, Y: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"a":[{"x":[1]},2],"b":[3,{"y":[4,5]}]}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  X := JsonPtrGet(Root, '/a/0/x');
  Y := JsonPtrGet(Root, '/b/1/y');
  AssertTrue(Assigned(X));
  AssertTrue(Assigned(Y));
  AssertEquals(1, JsonArrSize(X));
  AssertEquals(2, JsonArrSize(Y));
  Doc.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer_NestedArrays);
end.

