unit Test_fafafa_core_json_patch_helpers_more_edges;

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
  TTestCase_JsonPatchHelpersMoreEdges = class(TTestCase)
  published
    procedure Test_Add_ExistingKey_Replaces;
    procedure Test_Append_Dash_Twice;
    procedure Test_Replace_Path_Not_Exist_ReturnsErr;
    procedure Test_Remove_Path_Not_Exist_ReturnsErr;
  end;

procedure TTestCase_JsonPatchHelpersMoreEdges.Test_Add_ExistingKey_Replaces;
var
  R: IJsonReader; D,U: IJsonDocument; Ok: Boolean; Err: String;
  Patch: String;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"o":{"k":1}}');
  Patch := '[{"op":"add","path":"/o/k","value":2}]';
  Ok := TryApplyJsonPatch(D, Patch, U, Err);
  AssertTrue(Ok);
  AssertEquals(2, JsonPointerGet(U, '/o/k').GetInteger);
end;

procedure TTestCase_JsonPatchHelpersMoreEdges.Test_Append_Dash_Twice;
var
  R: IJsonReader; D,U: IJsonDocument; Ok: Boolean; Err: String;
  Patch: String;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"a":[]}');
  Patch := '[{"op":"add","path":"/a/-","value":1},' +
           '{"op":"add","path":"/a/-","value":2}]';
  Ok := TryApplyJsonPatch(D, Patch, U, Err);
  AssertTrue(Ok);
  AssertEquals(2, JsonPointerGet(U, '/a').GetArraySize);
  AssertEquals(1, JsonPointerGet(U, '/a/0').GetInteger);
  AssertEquals(2, JsonPointerGet(U, '/a/1').GetInteger);
end;

procedure TTestCase_JsonPatchHelpersMoreEdges.Test_Replace_Path_Not_Exist_ReturnsErr;
var
  R: IJsonReader; D,U: IJsonDocument; Ok: Boolean; Err: String;
  Patch: String;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"a":1}');
  Patch := '[{"op":"replace","path":"/b","value":2}]';
  Ok := TryApplyJsonPatch(D, Patch, U, Err);
  AssertFalse(Ok);
  AssertTrue(Err <> '');
  AssertTrue(U = nil);
end;

procedure TTestCase_JsonPatchHelpersMoreEdges.Test_Remove_Path_Not_Exist_ReturnsErr;
var
  R: IJsonReader; D,U: IJsonDocument; Ok: Boolean; Err: String;
  Patch: String;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"a":1}');
  Patch := '[{"op":"remove","path":"/b"}]';
  Ok := TryApplyJsonPatch(D, Patch, U, Err);
  AssertFalse(Ok);
  AssertTrue(Err <> '');
  AssertTrue(U = nil);
end;

procedure RegisterTests;
begin
  RegisterTest('json-patch-helpers', TTestCase_JsonPatchHelpersMoreEdges.Suite);
end;

initialization
  RegisterTests;

end.

