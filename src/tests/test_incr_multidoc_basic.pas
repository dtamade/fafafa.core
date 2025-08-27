unit test_incr_multidoc_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.incr;

procedure RegisterJsonIncrMultiDocTests;

implementation

procedure Test_Incr_MultiDoc_TwoFeeds;
const
  S1: AnsiString = '{"a":1}';
  S2: AnsiString = '{"b":2}';
var
  Buf: array[0..63] of AnsiChar;
  St: PJsonIncrState;
  Err: TJsonError;
  Alc: TAllocator;
  Doc1, Doc2: TJsonDocument;
  Root: PJsonValue;
  V: PJsonValue;
begin
  FillChar(Buf, SizeOf(Buf), 0);
  FillChar(Err, SizeOf(Err), 0);
  FillChar(Alc, SizeOf(Alc), 0);
  Move(Pointer(S1)^, Buf[0], Length(S1));
  Move(Pointer(S2)^, Buf[Length(S1)], Length(S2));
  St := JsonIncrNew(@Buf[0], SizeOf(Buf), [jrfDefault], Alc);

  // 第一次馈送仅前半段，解析出第一个文档
  Doc1 := JsonIncrRead(St, Length(S1), Err);
  AssertTrue(Doc1 <> nil);
  Root := JsonDocGetRoot(Doc1);
  AssertTrue(Root <> nil);
  V := JsonObjGet(Root, 'a');
  AssertTrue(V <> nil);
  AssertTrue(JsonIsInt(V));
  JsonDocFree(Doc1);

  // 第二次馈送剩余的后半段，解析第二个文档
  Doc2 := JsonIncrRead(St, Length(S2), Err);
  AssertTrue(Doc2 <> nil);
  Root := JsonDocGetRoot(Doc2);
  AssertTrue(Root <> nil);
  V := JsonObjGet(Root, 'b');
  AssertTrue(V <> nil);
  AssertTrue(JsonIsInt(V));
  JsonDocFree(Doc2);

  JsonIncrFree(St);
end;

procedure RegisterJsonIncrMultiDocTests;
begin
  RegisterTest('json-incr-multidoc-basic', @Test_Incr_MultiDoc_TwoFeeds);
end;

end.

