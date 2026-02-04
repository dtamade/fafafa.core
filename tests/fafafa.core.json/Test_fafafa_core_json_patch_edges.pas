{$CODEPAGE UTF8}
unit Test_fafafa_core_json_patch_edges;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.patch;

type
  TTestCase_JsonPatch_Edges = class(TTestCase)
  published
    procedure Test_Invalid_Op;
    procedure Test_Add_Index_OutOfRange;
    procedure Test_Replace_Path_Not_Exist;
    procedure Test_Remove_Path_Not_Exist;
    procedure Test_Copy_From_Not_Exist;
    procedure Test_Move_From_Not_Exist;
    procedure Test_Test_DeepEqual_Fail;
  end;

implementation

procedure TTestCase_JsonPatch_Edges.Test_Invalid_Op;
var Al: IAllocator; M: TJsonMutDocument; Root: PJsonMutValue; PatchText: String; PatchDoc: TJsonDocument; ok: Boolean; err: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  PatchText := '[{"op":"bogus","path":"/x","value":1}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), err);
  AssertTrue(not ok);
  AssertTrue(Length(err) > 0);
  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_Edges.Test_Add_Index_OutOfRange;
var Al: IAllocator; M: TJsonMutDocument; Root, Arr: PJsonMutValue; PatchText: String; PatchDoc: TJsonDocument; ok: Boolean; err: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Arr := JsonMutObjAddArr(M, Root, 'a'); AssertTrue(Assigned(Arr));
  // Cannot add to a non-contiguous index (len=0, index=2)
  PatchText := '[{"op":"add","path":"/a/2","value":1}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), err);
  AssertTrue(not ok);
  AssertTrue(Length(err) > 0);
  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_Edges.Test_Replace_Path_Not_Exist;
var Al: IAllocator; M: TJsonMutDocument; Root: PJsonMutValue; PatchText: String; PatchDoc: TJsonDocument; ok: Boolean; err: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  PatchText := '[{"op":"replace","path":"/no","value":1}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), err);
  AssertTrue(not ok);
  AssertTrue(Length(err) > 0);
  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_Edges.Test_Remove_Path_Not_Exist;
var Al: IAllocator; M: TJsonMutDocument; Root: PJsonMutValue; PatchText: String; PatchDoc: TJsonDocument; ok: Boolean; err: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  PatchText := '[{"op":"remove","path":"/no"}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), err);
  AssertTrue(not ok);
  AssertTrue(Length(err) > 0);
  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_Edges.Test_Copy_From_Not_Exist;
var Al: IAllocator; M: TJsonMutDocument; Root: PJsonMutValue; PatchText: String; PatchDoc: TJsonDocument; ok: Boolean; err: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  PatchText := '[{"op":"copy","from":"/no","path":"/x"}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), err);
  AssertTrue(not ok);
  AssertTrue(Length(err) > 0);
  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_Edges.Test_Move_From_Not_Exist;
var Al: IAllocator; M: TJsonMutDocument; Root: PJsonMutValue; PatchText: String; PatchDoc: TJsonDocument; ok: Boolean; err: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  PatchText := '[{"op":"move","from":"/no","path":"/x"}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), err);
  AssertTrue(not ok);
  AssertTrue(Length(err) > 0);
  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_Edges.Test_Test_DeepEqual_Fail;
var Al: IAllocator; M: TJsonMutDocument; Root, Obj: PJsonMutValue; PatchText: String; PatchDoc: TJsonDocument; ok: Boolean; err: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Obj := JsonMutObj(M);
  AssertTrue(JsonMutObjAddStr(M, Obj, 'k', 'v'));
  AssertTrue(JsonMutObjAddVal(M, Root, 'o', Obj));
  PatchText := '[{"op":"test","path":"/o","value":{"k":"vv"}}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), err);
  AssertTrue(not ok);
  AssertTrue(Length(err) > 0);
  PatchDoc.Free; M.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPatch_Edges);
end.

