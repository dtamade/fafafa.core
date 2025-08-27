unit Test_fafafa_core_json_facade_tryget;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json;

procedure RegisterTests;

implementation

type
  TTestCase_FacadeTryGet = class(TTestCase)
  published
    procedure Test_TryGet_ObjectValue_Found_NotFound;
    procedure Test_TryGet_ArrayItem_Found_NotFound;
  end;

procedure TTestCase_FacadeTryGet.Test_TryGet_ObjectValue_Found_NotFound;
var D: TJsonDocument; Doc: IJsonDocument; Root, OutV: IJsonValue;
begin
  D := JsonRead(PChar('{"a":1}'), Length('{"a":1}'), [jrfDefault]);
  Doc := JsonWrapDocument(D);
  Root := Doc.Root;
  AssertTrue('expect found', JsonTryGetObjectValue(Root, 'a', OutV));
  AssertTrue('out not nil', OutV <> nil);
  AssertFalse('expect not found', JsonTryGetObjectValue(Root, 'b', OutV));
  AssertTrue('out reset to nil', OutV = nil);
end;

procedure TTestCase_FacadeTryGet.Test_TryGet_ArrayItem_Found_NotFound;
var D: TJsonDocument; Doc: IJsonDocument; Root, Arr, OutV: IJsonValue;
begin
  D := JsonRead(PChar('[1,2,3]'), Length('[1,2,3]'), [jrfDefault]);
  Doc := JsonWrapDocument(D);
  Root := Doc.Root;
  // 用指针取根数组
  Arr := JsonPointerGet(Doc, '');
  AssertTrue('expect found', JsonTryGetArrayItem(Arr, 1, OutV));
  AssertTrue('out not nil', OutV <> nil);
  AssertFalse('expect not found', JsonTryGetArrayItem(Arr, 100, OutV));
  AssertTrue('out reset to nil', OutV = nil);
end;

procedure RegisterTests;
begin
  RegisterTest('json-facade', TTestCase_FacadeTryGet.Suite);
end;

initialization
  RegisterTests;

end.

