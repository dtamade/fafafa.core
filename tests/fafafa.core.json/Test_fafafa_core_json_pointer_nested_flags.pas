{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_nested_flags;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_NestedFlags = class(TTestCase)
  published
    procedure Test_Obj_Arr_Interleaved_With_Comments_And_TrailingCommas;
  end;

implementation

procedure TTestCase_JsonPointer_NestedFlags.Test_Obj_Arr_Interleaved_With_Comments_And_TrailingCommas;
var
  Doc: TJsonDocument; Err: TJsonError; Al: TAllocator; S: String;
  Root, X, Y: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // 含注释与尾随逗号的交错嵌套
  S := '{'
     + '  // c1' + LineEnding
     + '  "a": [ { "x": [1,] }, 2, ], /* c2 */' + LineEnding
     + '  "b": [3, {"y": [4,5,]}, ], // c3' + LineEnding
     + '}';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowComments, jrfAllowTrailingCommas], Al, Err);
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
  RegisterTest(TTestCase_JsonPointer_NestedFlags);
end.

