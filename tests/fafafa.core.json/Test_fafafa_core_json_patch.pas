{$CODEPAGE UTF8}
unit Test_fafafa_core_json_patch;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.patch;

type
  TTestCase_JsonPatch = class(TTestCase)
  published
    procedure Test_MergePatch_ObjectMergeAndNullDelete;
    procedure Test_JsonPatch_Add_Replace_Remove;
  end;

implementation

procedure TTestCase_JsonPatch.Test_MergePatch_ObjectMergeAndNullDelete;
var Al: TAllocator; M: TJsonMutDocument; Root, Obj: PJsonMutValue; PatchDoc: TJsonDocument;
    PatchStr: String; Res: PJsonMutValue;
    O, Keep, NewK: PJsonMutValue;
begin
  PatchStr := '';
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Obj := JsonMutObj(M);
  AssertTrue(JsonMutObjAddStr(M, Obj, 'keep', 'x'));
  AssertTrue(JsonMutObjAddStr(M, Obj, 'will', 'y'));
  AssertTrue(JsonMutObjAddVal(M, Root, 'o', Obj));

  PatchStr := '{"o":{"will":null,"newK":"nv"}}';
  PatchDoc := JsonRead(PChar(PatchStr), Length(PatchStr), []);
  Res := JsonMergePatch(M, Root, JsonDocGetRoot(PatchDoc));
  AssertTrue(Assigned(Res));

  // Validate via mutable traversal instead of serializing mutable as immutable
  // o.keep == "x"
  O := JsonMutObjGet(Root, 'o');
  AssertTrue(Assigned(O));
  Keep := JsonMutObjGet(O, 'keep');
  AssertTrue(Assigned(Keep));
  AssertTrue(JsonEqualsStrN(PJsonValue(Keep), 'x', 1));
  // o.will removed
  AssertTrue(not Assigned(JsonMutObjGet(O, 'will')));
  // o.newK == "nv"
  NewK := JsonMutObjGet(O, 'newK');
  AssertTrue(Assigned(NewK));
  AssertTrue(JsonEqualsStrN(PJsonValue(NewK), 'nv', 2));

  PatchDoc.Free; M.Free;
end;

procedure TTestCase_JsonPatch.Test_JsonPatch_Add_Replace_Remove;
var Al: TAllocator; M: TJsonMutDocument; Root, Arr: PJsonMutValue; PatchText: String;
    PatchDoc: TJsonDocument; ok: Boolean; errMsg: String;
    A, V: PJsonMutValue; It: TJsonMutArrayIterator;
begin
  PatchText := '';
  errMsg := '';
  Al := GetRtlAllocator();
  M := JsonMutDocNew(Al);
  Root := JsonMutObj(M); JsonMutDocSetRoot(M, Root);
  Arr := JsonMutObjAddArr(M, Root, 'a'); if Arr <> nil then;

  PatchText := '[{"op":"add","path":"/a/0","value":1},'+
               '{"op":"add","path":"/a/-","value":2},'+
               '{"op":"replace","path":"/a/0","value":3},'+
               '{"op":"remove","path":"/a/1"}]';
  PatchDoc := JsonRead(PChar(PatchText), Length(PatchText), []);
  ok := JsonPatchApply(M, Root, JsonDocGetRoot(PatchDoc), errMsg);
  AssertTrue(ok);

  // Validate array a = [3] via mutable iter
  A := JsonMutObjGet(Root, 'a');
  AssertTrue(Assigned(A));
  // It declared above
  AssertTrue(JsonMutArrIterInit(A, @It));
  AssertTrue(JsonMutArrIterHasNext(@It));
  V := JsonMutArrIterNext(@It);
  AssertTrue(not JsonMutArrIterHasNext(@It));
  AssertEquals(3, JsonGetInt(PJsonValue(V)));

  PatchDoc.Free; M.Free;
end;

initialization
  RegisterTest(TTestCase_JsonPatch);
end.

