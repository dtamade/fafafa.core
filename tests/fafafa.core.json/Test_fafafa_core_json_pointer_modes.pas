{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_modes;

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_Modes = class(TTestCase)
  published
    procedure Test_Compat_SlashOnly_Invalid;
    procedure Test_Compat_EmptyToken_Invalid;
    procedure Test_Strict_SlashOnly_EmptyToken_RootOrKey;
  end;

implementation

procedure TTestCase_JsonPointer_Modes.Test_Compat_SlashOnly_Invalid;
var Doc: TJsonDocument; Err: TJsonError; Al: IAllocator; S: String; Root, R: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"a":{"":1}}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  // compat: '/' invalid -> nil
  R := JsonPtrGet(Root, '/');
  AssertTrue(R = nil);
  Doc.Free;
end;

procedure TTestCase_JsonPointer_Modes.Test_Compat_EmptyToken_Invalid;
var Doc: TJsonDocument; Err: TJsonError; Al: IAllocator; S: String; Root, R: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"a":{"":2,"x":3}}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  // compat: '/a//x' invalid -> nil
  R := JsonPtrGet(Root, '/a//x');
  AssertTrue(R = nil);
  Doc.Free;
end;

procedure TTestCase_JsonPointer_Modes.Test_Strict_SlashOnly_EmptyToken_RootOrKey;
var Doc: TJsonDocument; Err: TJsonError; Al: IAllocator; S: String; Root, R: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"": {"x": 42}, "a":{"":2,"x":3}}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  // strict: '/' means empty-token; to make it meaningful, empty key must exist when used under an object
  // here root is an object but '/' alone cannot address root's empty key; RFC 6901 defines tokens after '/'
  // We will test '/a/' to fetch key "" under object a
  R := JsonPtrGet(Root, '/a/', [jpfStrict]);
  AssertTrue(Assigned(R));
  AssertTrue(JsonIsNum(R));
  AssertEquals(Int64(2), JsonGetSint(R));
  // strict: empty pointer still returns root
  R := JsonPtrGet(Root, '', [jpfStrict]);
  AssertTrue(R = Root);
  Doc.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer_Modes);
end.

