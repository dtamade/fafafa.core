{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_empty_token_and_double_slash;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_EmptyTokenAndDoubleSlash = class(TTestCase)
  published
    procedure Test_Empty_Key_Token;
    procedure Test_Double_Slash_Invalid;
  end;

implementation

procedure TTestCase_JsonPointer_EmptyTokenAndDoubleSlash.Test_Empty_Key_Token;
var
  Doc: TJsonDocument; Err: TJsonError; Root, V: PJsonValue; Al: IAllocator; S: String;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // 对象包含空键名 ""
  S := '{"": {"x": 1}, "a": 2}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  // 现实现语义：单独 '/' 为非法（不支持空 token 作为键名）
  V := JsonPtrGet(Root, '/');
  AssertTrue(V = nil);
  Doc.Free;
end;

procedure TTestCase_JsonPointer_EmptyTokenAndDoubleSlash.Test_Double_Slash_Invalid;
var
  Doc: TJsonDocument; Err: TJsonError; Root, V: PJsonValue; Al: IAllocator; S: String;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"a": {"": 3}, "b": 4}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  // 指向 a 下的 "" 键应为路径 "/a/"，双斜杠 "/a//x" 中间空 token 非法，返回 nil
  V := JsonPtrGet(Root, '/a//x');
  AssertTrue(V = nil);
  Doc.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer_EmptyTokenAndDoubleSlash);
end.

