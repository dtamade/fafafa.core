{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_bom_comments_trailing;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_BOMCommentsTrailing = class(TTestCase)
  published
    procedure Test_BOM_Comments_Trailing_Combo;
  end;

implementation

procedure TTestCase_JsonPointer_BOMCommentsTrailing.Test_BOM_Comments_Trailing_Combo;
var
  Doc: TJsonDocument; Err: TJsonError; Root, V: PJsonValue; Al: TAllocator; S: RawByteString;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // UTF-8 BOM + 注释 + 尾随逗号，根为对象
  S := #$EF#$BB#$BF + '{' + LineEnding +
       '  // head' + LineEnding +
       '  "arr": [1,2,], /* t */' + LineEnding +
       '  "obj": {"k": [7,8,],},' + LineEnding +
       '}';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowBOM, jrfAllowComments, jrfAllowTrailingCommas], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  V := JsonPtrGet(Root, '/arr'); AssertTrue(Assigned(V)); AssertEquals(2, JsonArrSize(V));
  V := JsonPtrGet(Root, '/obj/k'); AssertTrue(Assigned(V)); AssertEquals(2, JsonArrSize(V));
  Doc.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer_BOMCommentsTrailing);
end.

