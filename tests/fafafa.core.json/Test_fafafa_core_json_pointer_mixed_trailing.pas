{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_mixed_trailing;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_MixedTrailing = class(TTestCase)
  published
    procedure Test_Mixed_Containers_With_Comments_TrailingCommas;
  end;

implementation

procedure TTestCase_JsonPointer_MixedTrailing.Test_Mixed_Containers_With_Comments_TrailingCommas;
var
  Doc: TJsonDocument; Err: TJsonError; Al: TAllocator; S: String;
  Root, V: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // 混排容器 + 注释 + 尾随逗号
  S := '{' + LineEnding +
       '  // head' + LineEnding +
       '  "obj": { "k1": 1, "k2": { "inner": [10,20,] , }, }, // c1' + LineEnding +
       '  "arr": [ {"a":[1,2,3,]}, {"b":[null,true,false,]}, ], /* c2 */' + LineEnding +
       '  "tail": "ok", // c3' + LineEnding +
       '}';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowComments, jrfAllowTrailingCommas], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  // /obj/k2/inner => [10,20]
  V := JsonPtrGet(Root, '/obj/k2/inner');
  AssertTrue(Assigned(V));
  AssertEquals(2, JsonArrSize(V));
  // /arr/0/a => [1,2,3]
  V := JsonPtrGet(Root, '/arr/0/a');
  AssertTrue(Assigned(V));
  AssertEquals(3, JsonArrSize(V));
  // /arr/1/b => [null,true,false]
  V := JsonPtrGet(Root, '/arr/1/b');
  AssertTrue(Assigned(V));
  AssertEquals(3, JsonArrSize(V));
  Doc.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer_MixedTrailing);
end.

