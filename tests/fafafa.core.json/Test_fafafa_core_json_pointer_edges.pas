{$CODEPAGE UTF8}
unit Test_fafafa_core_json_pointer_edges;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr;

type
  TTestCase_JsonPointer_Edges = class(TTestCase)
  published
    procedure Test_Empty_Pointer_Returns_Root;
    procedure Test_Slash_Only_Pointer_Invalid;
    procedure Test_Unescape_Tokens;
    procedure Test_Index_Out_Of_Range;
    procedure Test_Type_Mismatch_Object_vs_Array;
    procedure Test_Mutable_Edges_Basic;
  end;

implementation

procedure TTestCase_JsonPointer_Edges.Test_Empty_Pointer_Returns_Root;
var Doc: TJsonDocument; Err: TJsonError; Al: TAllocator; S: String; Root, R: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"a":[1],"b":2}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  R := JsonPtrGet(Root, '');
  AssertTrue(R = Root);
  Doc.Free;
end;

procedure TTestCase_JsonPointer_Edges.Test_Slash_Only_Pointer_Invalid;
var Doc: TJsonDocument; Err: TJsonError; Al: TAllocator; S: String; Root, R: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"x":1}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  R := JsonPtrGet(Root, '/');
  AssertTrue(R = nil);
  Doc.Free;
end;

procedure TTestCase_JsonPointer_Edges.Test_Unescape_Tokens;
var Doc: TJsonDocument; Err: TJsonError; Al: TAllocator; S: String; Root, R: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"a/b": {"~key": 42}}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  R := JsonPtrGet(Root, '/a~1b/~0key');
  AssertTrue(Assigned(R));
  AssertTrue(JsonIsNum(R));
  AssertTrue(JsonGetInt(R) = 42);
  Doc.Free;
end;

procedure TTestCase_JsonPointer_Edges.Test_Index_Out_Of_Range;
var Doc: TJsonDocument; Err: TJsonError; Al: TAllocator; S: String; Root, R: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"arr":[10,20]}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  R := JsonPtrGet(Root, '/arr/2'); // out of range
  AssertTrue(R = nil);
  Doc.Free;
end;

procedure TTestCase_JsonPointer_Edges.Test_Type_Mismatch_Object_vs_Array;
var Doc: TJsonDocument; Err: TJsonError; Al: TAllocator; S: String; Root, R: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // Object with numeric key and an array to test mismatch
  S := '{"obj": {"0": "zero"}, "arr": [1,2]}';
  Doc := JsonReadOpts(PChar(S), Length(S), [], Al, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  // On object, token "0" matches key "0"
  R := JsonPtrGet(Root, '/obj/0');
  AssertTrue(Assigned(R));
  AssertTrue(JsonIsStr(R));
  AssertTrue(JsonEqualsStrN(R, 'zero', 4));
  // On array, non-numeric token mismatches and returns nil
  R := JsonPtrGet(Root, '/arr/x');
  AssertTrue(R = nil);
  Doc.Free;
end;

procedure TTestCase_JsonPointer_Edges.Test_Mutable_Edges_Basic;
var M: TJsonMutDocument; Al: TAllocator; Root, Arr, Obj, V: PJsonMutValue;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Arr := JsonMutObjAddArr(M, Root, 'arr');
  JsonMutArrAddInt(M, Arr, 7);
  Obj := JsonMutObjAddObj(M, Root, 'obj');
  JsonMutObjAddStr(M, Obj, 'a/b', 'slash');
  JsonMutObjAddStr(M, Obj, '~x', 'tilde');
  // Empty pointer returns root
  AssertTrue(JsonMutPtrGet(Root, '') = Root);
  // Slash only invalid
  AssertTrue(JsonMutPtrGet(Root, '/') = nil);
  // Unescape tokens
  V := JsonMutPtrGet(Root, '/obj/a~1b');
  AssertTrue(Assigned(V));
  AssertTrue(JsonEqualsStrN(PJsonValue(V), 'slash', 5));
  V := JsonMutPtrGet(Root, '/obj/~0x');
  AssertTrue(Assigned(V));
  AssertTrue(JsonEqualsStrN(PJsonValue(V), 'tilde', 5));
  // Out of range
  AssertTrue(JsonMutPtrGet(Root, '/arr/9') = nil);
  M.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPointer_Edges);
end.

