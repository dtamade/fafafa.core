unit Test_fafafa_core_json_patch_helpers;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json,
  fafafa.core.json.patch.helpers;

procedure RegisterTests;

implementation

type
  TTestCase_JsonPatchHelpers = class(TTestCase)
  published
    procedure Test_MergePatch_Add_And_Delete;
    procedure Test_JsonPatch_Add_Replace_Remove;
  end;

procedure TTestCase_JsonPatchHelpers.Test_MergePatch_Add_And_Delete;
var
  R: IJsonReader;
  D, U: IJsonDocument;
  Ok: Boolean;
  Err: String;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"o":{"x":1,"y":2}}');
  Ok := TryApplyJsonMergePatch(D, '{"o":{"y":null,"z":3}}', U, Err);
  AssertTrue(Ok);
  AssertTrue(Assigned(U));
  AssertEquals(3, (JsonPointerGet(U, '/o/z')).GetInteger);
  AssertTrue(JsonPointerGet(U, '/o/y') = nil);
end;

procedure TTestCase_JsonPatchHelpers.Test_JsonPatch_Add_Replace_Remove;
var
  R: IJsonReader;
  D, U: IJsonDocument;
  Ok: Boolean;
  Err: String;
  Patch: String;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"a":[1]}');
  Patch := '[{"op":"add","path":"/a/-","value":2},{"op":"replace","path":"/a/0","value":9},{"op":"remove","path":"/a/1"}]';
  Ok := TryApplyJsonPatch(D, Patch, U, Err);
  AssertTrue(Ok);
  AssertTrue(Assigned(U));
  AssertEquals(1, JsonPointerGet(U, '/a').GetArraySize);
  AssertEquals(9, JsonPointerGet(U, '/a/0').GetInteger);
end;

procedure RegisterTests;
begin
  RegisterTest('json-patch-helpers', TTestCase_JsonPatchHelpers.Suite);
end;

initialization
  RegisterTests;

end.

