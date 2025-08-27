unit test_json_pointer_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

procedure RegisterJsonPointerTests; // keep exporting for run_tests.lpr compatibility

implementation

procedure Test_JsonPtrGet_Hit;
var
  Alc: TAllocator;
  Err: TJsonError;
  Doc: TJsonDocument;
  Root, V: PJsonValue;
begin
  FillChar(Alc, SizeOf(Alc), 0);
  FillChar(Err, SizeOf(Err), 0);
  Doc := JsonRead('{"a":[{"b":1}]}', Length('{"a":[{"b":1}]}'), [jrfDefault]);
  AssertTrue(Doc <> nil);
  Root := JsonDocGetRoot(Doc);
  V := JsonPtrGet(Root, '/a/0/b');
  AssertTrue(V <> nil);
  AssertTrue(JsonIsNum(V));
  JsonDocFree(Doc);
end;

procedure Test_JsonPtrGet_Miss;
var
  Alc: TAllocator;
  Err: TJsonError;
  Doc: TJsonDocument;
  Root, V: PJsonValue;
begin
  FillChar(Alc, SizeOf(Alc), 0);
  FillChar(Err, SizeOf(Err), 0);
  Doc := JsonRead('{"a":[{"b":1}]}', Length('{"a":[{"b":1}]}'), [jrfDefault]);
  AssertTrue(Doc <> nil);
  Root := JsonDocGetRoot(Doc);
  V := JsonPtrGet(Root, '/a/1/b');
  AssertTrue(V = nil);
  JsonDocFree(Doc);
end;

procedure RegisterJsonPointerTests;
begin
  RegisterTest('json-pointer-basic', @Test_JsonPtrGet_Hit);
  RegisterTest('json-pointer-basic', @Test_JsonPtrGet_Miss);
end;

end.

