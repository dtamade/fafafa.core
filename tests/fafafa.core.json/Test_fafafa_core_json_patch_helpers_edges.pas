unit Test_fafafa_core_json_patch_helpers_edges;

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
  TTestCase_JsonPatchHelpersEdges = class(TTestCase)
  published
    procedure Test_MergePatch_PatchIsNotObject;
    procedure Test_JsonPatch_PatchIsNotArray;
  end;

procedure TTestCase_JsonPatchHelpersEdges.Test_MergePatch_PatchIsNotObject;
var
  R: IJsonReader;
  D, U: IJsonDocument;
  Ok: Boolean;
  Err: String;
  V: IJsonValue;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"a":1}');
  // RFC 7386: 非对象补丁表示整体替换，结果为补丁本身
  Ok := TryApplyJsonMergePatch(D, '[1,2,3]', U, Err);
  AssertTrue(Ok);
  AssertTrue(Err = '');
  AssertTrue(Assigned(U));
  V := U.Root;
  AssertTrue(V.IsArray);
  AssertEquals(3, V.GetArraySize);
end;

procedure TTestCase_JsonPatchHelpersEdges.Test_JsonPatch_PatchIsNotArray;
var
  R: IJsonReader;
  D, U: IJsonDocument;
  Ok: Boolean;
  Err: String;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"a":1}');
  Ok := TryApplyJsonPatch(D, '{"op":"add","path":"/a","value":2}', U, Err);
  AssertFalse(Ok);
  AssertTrue(Err <> '');
  AssertTrue(U = nil);
end;

procedure RegisterTests;
begin
  RegisterTest('json-patch-helpers', TTestCase_JsonPatchHelpersEdges.Suite);
end;

initialization
  RegisterTests;

end.

