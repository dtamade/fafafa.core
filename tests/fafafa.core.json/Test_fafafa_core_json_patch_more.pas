{$CODEPAGE UTF8}
unit Test_fafafa_core_json_patch_more;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.ptr,
  fafafa.core.json.patch;

type
  TTestCase_JsonPatch_More = class(TTestCase)
  published
    procedure Test_Copy_ObjectKey;
    procedure Test_Move_ArrayToAppend;
    procedure Test_Test_DeepEqual;
    // New complex/edge combination tests
    procedure Test_Add_Object_ExistingKey_Replaces;
    procedure Test_Replace_Array_Dash_Invalid;
    procedure Test_Move_Into_Descendant_Not_Allowed;
    procedure Test_Copy_Array_Insert_Middle;
    procedure Test_Add_Parent_Not_Found;
  end;

implementation

procedure TTestCase_JsonPatch_More.Test_Copy_ObjectKey;
var Al: TAllocator; M: TJsonMutDocument; Root, Obj: PJsonMutValue; PatchText: String;
    PatchDoc: TJsonDocument; ok: Boolean; errMsg: String; V: PJsonMutValue;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Obj := JsonMutObj(M);
  AssertTrue(JsonMutObjAddStr(M, Obj, 'k', 'v'));
  AssertTrue(JsonMutObjAddVal(M, Root, 'o', Obj));

  PatchText := '[{"op":"copy","from":"/o/k","path":"/o/k2"}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), errMsg);
  AssertTrue(ok);

  V := JsonMutPtrGet(Root, '/o/k2');
  AssertTrue(Assigned(V));
  AssertTrue(JsonEqualsStrN(PJsonValue(V), 'v', 1));

  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_More.Test_Move_ArrayToAppend;
var Al: TAllocator; M: TJsonMutDocument; Root, Arr: PJsonMutValue; PatchText: String;
    PatchDoc: TJsonDocument; ok: Boolean; errMsg: String; V: PJsonMutValue;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Arr := JsonMutObjAddArr(M, Root, 'a');
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(M, 1)));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(M, 2)));

  PatchText := '[{"op":"move","from":"/a/0","path":"/a/-"}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), errMsg);
  AssertTrue(ok);

  // expect [2,1]; verify from head (last^.Next)
  V := PJsonMutValue(Arr^.Data.Ptr)^.Next;
  AssertEquals(2, JsonGetInt(PJsonValue(V)));
  V := V^.Next;
  AssertEquals(1, JsonGetInt(PJsonValue(V)));

  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_More.Test_Test_DeepEqual;
var Al: TAllocator; M: TJsonMutDocument; Root, Obj: PJsonMutValue; PatchText: String;
    PatchDoc: TJsonDocument; ok: Boolean; errMsg: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Obj := JsonMutObj(M);
  AssertTrue(JsonMutObjAddStr(M, Obj, 'k', 'v'));
  AssertTrue(JsonMutObjAddVal(M, Root, 'o', Obj));

  PatchText := '[{"op":"test","path":"/o","value":{"k":"v"}}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), errMsg);
  AssertTrue(ok);
  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_More.Test_Add_Object_ExistingKey_Replaces;
var Al: TAllocator; M: TJsonMutDocument; Root, Obj: PJsonMutValue; PatchText: String;
    PatchDoc: TJsonDocument; ok: Boolean; errMsg: String; V: PJsonMutValue;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Obj := JsonMutObjAddObj(M, Root, 'o');
  AssertTrue(JsonMutObjAddStr(M, Obj, 'k', 'old'));

  PatchText := '[{"op":"add","path":"/o/k","value":"new"}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), errMsg);
  AssertTrue(ok);

  V := JsonMutPtrGet(Root, '/o/k');
  AssertTrue(Assigned(V));
  AssertTrue(JsonEqualsStrN(PJsonValue(V), 'new', 3));

  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_More.Test_Replace_Array_Dash_Invalid;
var Al: TAllocator; M: TJsonMutDocument; Root, Arr: PJsonMutValue; PatchText: String;
    PatchDoc: TJsonDocument; ok: Boolean; errMsg: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Arr := JsonMutObjAddArr(M, Root, 'a');
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(M, 1)));

  PatchText := '[{"op":"replace","path":"/a/-","value":2}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), errMsg);
  AssertTrue(not ok);
  AssertTrue(Length(errMsg) > 0);
  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_More.Test_Move_Into_Descendant_Not_Allowed;
var Al: TAllocator; M: TJsonMutDocument; Root, Obj, Inner: PJsonMutValue; PatchText: String;
    PatchDoc: TJsonDocument; ok: Boolean; errMsg: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Obj := JsonMutObjAddObj(M, Root, 'o');
  Inner := JsonMutObjAddObj(M, Obj, 'i');
  AssertTrue(Assigned(Inner));

  // Move o into its descendant o/i => should be blocked
  PatchText := '[{"op":"move","from":"/o","path":"/o/i/x"}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), errMsg);
  AssertTrue(not ok);
  AssertTrue(Length(errMsg) > 0);
  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_More.Test_Copy_Array_Insert_Middle;
var Al: TAllocator; M: TJsonMutDocument; Root, Arr: PJsonMutValue; PatchText: String;
    PatchDoc: TJsonDocument; ok: Boolean; errMsg: String; V: PJsonMutValue;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Arr := JsonMutObjAddArr(M, Root, 'a');
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(M, 1)));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(M, 3)));

  PatchText := '[{"op":"copy","from":"/a/0","path":"/a/1"}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), errMsg);
  AssertTrue(ok);

  // expect [1,1,3]
  V := PJsonMutValue(Arr^.Data.Ptr)^.Next;              // first
  AssertEquals(1, JsonGetInt(PJsonValue(V)));
  V := V^.Next;                                         // second
  AssertEquals(1, JsonGetInt(PJsonValue(V)));
  V := V^.Next;                                         // third
  AssertEquals(3, JsonGetInt(PJsonValue(V)));

  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch_More.Test_Add_Parent_Not_Found;
var Al: TAllocator; M: TJsonMutDocument; Root: PJsonMutValue; PatchText: String;
    PatchDoc: TJsonDocument; ok: Boolean; errMsg: String;
begin
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);

  PatchText := '[{"op":"add","path":"/no/x","value":1}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), errMsg);
  AssertTrue(not ok);
  AssertTrue(Length(errMsg) > 0);
  PatchDoc.Free; M.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPatch_More);
end.

