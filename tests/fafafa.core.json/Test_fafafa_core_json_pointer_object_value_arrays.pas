{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_object_value_arrays;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_ObjectValueArrays = class(TTestCase)
  published
    procedure Test_Obj_With_Two_Array_Values;
  end;

implementation

procedure TTestCase_JsonPointer_ObjectValueArrays.Test_Obj_With_Two_Array_Values;
var Doc: TJsonDocument; Err: TJsonError; Al: IAllocator; S: String; Root, A1, A2: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"a":[1,2],"tags":[1,2]}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  A1 := JsonPtrGet(Root, '/a');
  A2 := JsonPtrGet(Root, '/tags');
  AssertTrue(Assigned(A1));
  AssertTrue(Assigned(A2));
  AssertEquals(2, JsonArrSize(A1));
  AssertEquals(2, JsonArrSize(A2));
  Doc.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer_ObjectValueArrays);
end.

