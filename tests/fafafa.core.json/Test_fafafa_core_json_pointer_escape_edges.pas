{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_escape_edges;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_EscapeEdges = class(TTestCase)
  published
    procedure Test_TildeEscapes;
  end;

implementation

procedure TTestCase_JsonPointer_EscapeEdges.Test_TildeEscapes;
var
  Doc: TJsonDocument; Err: TJsonError; Root, V: PJsonValue; Al: TAllocator;
  S: String;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // 键包含 ~ 和 / ，验证 ~0 → ~, ~1 → /
  S := '{"a~b": 1, "c/d": 2, "~": 3, "/": 4}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);

  V := JsonPtrGet(Root, '/a~0b'); AssertTrue(Assigned(V)); AssertEquals(1, JsonGetInt(V));
  V := JsonPtrGet(Root, '/c~1d'); AssertTrue(Assigned(V)); AssertEquals(2, JsonGetInt(V));
  V := JsonPtrGet(Root, '/~0');   AssertTrue(Assigned(V)); AssertEquals(3, JsonGetInt(V));
  V := JsonPtrGet(Root, '/~1');   AssertTrue(Assigned(V)); AssertEquals(4, JsonGetInt(V));
  Doc.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer_EscapeEdges);
end.

