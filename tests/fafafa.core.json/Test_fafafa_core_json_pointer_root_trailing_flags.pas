{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_root_trailing_flags;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_RootTrailingFlags = class(TTestCase)
  published
    procedure Test_Root_Object_With_Comments_And_TrailingCommas;
  end;

implementation

procedure TTestCase_JsonPointer_RootTrailingFlags.Test_Root_Object_With_Comments_And_TrailingCommas;
var
  Doc: TJsonDocument; Err: TJsonError; Al: TAllocator; S: String;
  Root, V: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // 根对象 + 注释 + 尾随逗号（对象/数组/根级尾逗均覆盖）
  S := '{' + LineEnding +
       '  // head comment' + LineEnding +
       '  "a": 1, // inline' + LineEnding +
       '  "b": [1, 2,], /* array trailing */' + LineEnding +
       '  "c": { "x": [7,8,], }, // inner object trailing + root trailing comma after c' + LineEnding +
       '}';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowComments, jrfAllowTrailingCommas], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  // /b => [1,2]
  V := JsonPtrGet(Root, '/b');
  AssertTrue(Assigned(V));
  AssertEquals(2, JsonArrSize(V));
  // /c/x => [7,8]
  V := JsonPtrGet(Root, '/c/x');
  AssertTrue(Assigned(V));
  AssertEquals(2, JsonArrSize(V));
  // /a 存在
  V := JsonPtrGet(Root, '/a');
  AssertTrue(Assigned(V));
  Doc.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer_RootTrailingFlags);
end.

