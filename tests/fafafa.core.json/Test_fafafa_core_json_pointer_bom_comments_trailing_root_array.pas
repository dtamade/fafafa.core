{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_bom_comments_trailing_root_array;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_BOMCommentsTrailing_RootArray = class(TTestCase)
  published
    procedure Test_BOM_Comments_Trailing_RootArray;
  end;

implementation

procedure TTestCase_JsonPointer_BOMCommentsTrailing_RootArray.Test_BOM_Comments_Trailing_RootArray;
var
  Doc: TJsonDocument; Err: TJsonError; Root, V: PJsonValue; Al: TAllocator; S: RawByteString;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // UTF-8 BOM + 注释 + 尾随逗号，根为数组
  S := #$EF#$BB#$BF + '[' + LineEnding +
       '  // head' + LineEnding +
       '  1, 2, 3, /* trailing comma */' + LineEnding +
       ']';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowBOM, jrfAllowComments, jrfAllowTrailingCommas], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  AssertEquals(3, JsonArrSize(Root));
  V := JsonPtrGet(Root, '/0'); AssertTrue(Assigned(V)); AssertEquals(1, JsonGetInt(V));
  V := JsonPtrGet(Root, '/2'); AssertTrue(Assigned(V)); AssertEquals(3, JsonGetInt(V));
  Doc.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer_BOMCommentsTrailing_RootArray);
end.

