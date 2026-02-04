{$CODEPAGE UTF8}
unit Test_fafafa_core_json_mutable;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

type
  TTestCase_Mutable = class(TTestCase)
  published
    procedure Test_Create_Primitives_And_DocRoot;
    procedure Test_Array_Append_Insert_Remove_Clear_Iter;
    procedure Test_Object_Add_Put_Remove_Get_Iter;
    procedure Test_Object_Delete_Edges_And_Order;
    procedure Test_Array_IterRemove;
    procedure Test_Object_IterRemove;
    procedure Test_Object_Put_Dedup_Order;
    procedure Test_Object_Insert_Index_Order;
    procedure Test_Array_Remove_Multi_OutOfRange;
    procedure Test_Clear_ReAdd;
    procedure Test_Nested_RoundTrip;
  end;

implementation

procedure TTestCase_Mutable.Test_Create_Primitives_And_DocRoot;
var Al: IAllocator; MD: TJsonMutDocument; R: PJsonMutValue;
begin
  Al := GetRtlAllocator();
  MD := JsonMutDocNew(Al); AssertTrue(Assigned(MD));
  R := JsonMutNull(MD); AssertTrue(Assigned(R)); JsonMutDocSetRoot(MD, R); AssertTrue(JsonMutDocGetRoot(MD) = R);
  R := JsonMutTrue(MD); AssertTrue(Assigned(R));
  R := JsonMutFalse(MD); AssertTrue(Assigned(R));
  R := JsonMutUint(MD, 123); AssertTrue(Assigned(R));
  R := JsonMutSint(MD, -5); AssertTrue(Assigned(R));
  R := JsonMutReal(MD, 3.14); AssertTrue(Assigned(R));
  R := JsonMutStr(MD, 'hi'); AssertTrue(Assigned(R));
  MD.Free;
end;

procedure TTestCase_Mutable.Test_Array_Append_Insert_Remove_Clear_Iter;
var Al: IAllocator; MD: TJsonMutDocument; Arr, V1, V2, V3, Tmp: PJsonMutValue; It: TJsonMutArrayIterator; S: SizeUInt;
begin
  Al := GetRtlAllocator(); MD := JsonMutDocNew(Al);
  Arr := JsonMutArr(MD); AssertTrue(Assigned(Arr));
  AssertEquals(0, JsonMutArrSize(Arr));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 1)));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 2)));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 3)));
  AssertEquals(3, JsonMutArrSize(Arr));

  // Insert at 1 -> [1,99,2,3]
  V2 := JsonMutUint(MD, 99); AssertTrue(JsonMutArrInsert(Arr, V2, 1)); AssertEquals(4, JsonMutArrSize(Arr));
  // Replace index 2 -> [1,99,77,3]
  V3 := JsonMutUint(MD, 77); Tmp := JsonMutArrReplace(Arr, 2, V3); AssertTrue(Assigned(Tmp)); AssertEquals(4, JsonMutArrSize(Arr));
  // Remove first -> [99,77,3]
  Tmp := JsonMutArrRemoveFirst(Arr); AssertTrue(Assigned(Tmp)); AssertEquals(3, JsonMutArrSize(Arr));
  // Remove last -> [99,77]
  Tmp := JsonMutArrRemoveLast(Arr); AssertTrue(Assigned(Tmp)); AssertEquals(2, JsonMutArrSize(Arr));

  // Iterate
  AssertTrue(JsonMutArrIterInit(Arr, @It)); S := 0;
  while JsonMutArrIterHasNext(@It) do begin V1 := JsonMutArrIterNext(@It); if V1 <> nil then; Inc(S); end;
  AssertEquals(2, S);

  // Clear
  AssertTrue(JsonMutArrClear(Arr)); AssertEquals(0, JsonMutArrSize(Arr));
  MD.Free;
end;

procedure TTestCase_Mutable.Test_Object_Add_Put_Remove_Get_Iter;
var Al: IAllocator; MD: TJsonMutDocument; Obj, V: PJsonMutValue; It: TJsonMutObjectIterator; Key: PJsonMutValue; Cnt: SizeUInt;
begin
  Al := GetRtlAllocator(); MD := JsonMutDocNew(Al);
  Obj := JsonMutObj(MD); AssertTrue(Assigned(Obj));
  AssertEquals(0, JsonMutObjSize(Obj));
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'a'), JsonMutUint(MD, 1)));
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'b'), JsonMutUint(MD, 2)));
  AssertEquals(2, JsonMutObjSize(Obj));

  // Put same key -> replace value
  AssertTrue(JsonMutObjPut(Obj, JsonMutStr(MD, 'b'), JsonMutUint(MD, 22)));
  V := JsonMutObjGet(Obj, 'b'); AssertTrue(Assigned(V)); AssertTrue(UnsafeIsNum(PJsonValue(V)));

  // Iter: iterator yields keys, ensure two keys
  AssertTrue(JsonMutObjIterInit(Obj, @It)); Cnt := 0;
  while JsonMutObjIterHasNext(@It) do begin Key := JsonMutObjIterNext(@It); AssertTrue(UnsafeIsStr(PJsonValue(Key))); V := JsonMutObjIterGetVal(Key); AssertTrue(Assigned(V)); Inc(Cnt); end;
  AssertEquals(2, Cnt);

  // Remove by key
  V := JsonMutObjRemoveKey(Obj, 'b'); AssertTrue(Assigned(V)); AssertEquals(1, JsonMutObjSize(Obj));
  AssertTrue(JsonMutObjClear(Obj)); AssertEquals(0, JsonMutObjSize(Obj));
  MD.Free;
end;


procedure TTestCase_Mutable.Test_Object_Delete_Edges_And_Order;
var Al: IAllocator; MD: TJsonMutDocument; Obj, V, Rm: PJsonMutValue; It: TJsonMutObjectIterator; Keys: array of String;
begin
  Keys := nil;
  Al := GetRtlAllocator(); MD := JsonMutDocNew(Al); Obj := JsonMutObj(MD);
  // 插入 a,b,c
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'a'), JsonMutUint(MD, 1)));
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'b'), JsonMutUint(MD, 2)));
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'c'), JsonMutUint(MD, 3)));
  AssertEquals(3, JsonMutObjSize(Obj));

  // 删除尾键 c
  Rm := JsonMutObjRemoveKey(Obj, 'c'); AssertTrue(Assigned(Rm)); AssertEquals(2, JsonMutObjSize(Obj));
  // 删除首键 a
  Rm := JsonMutObjRemoveKey(Obj, 'a'); AssertTrue(Assigned(Rm)); AssertEquals(1, JsonMutObjSize(Obj));
  // 现在只剩 b
  V := JsonMutObjGet(Obj, 'b'); AssertTrue(Assigned(V));

  // 顺序稳定性：重新插入 d,e 后顺序应为 b,d,e（尾部追加）
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'd'), JsonMutUint(MD, 4)));
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'e'), JsonMutUint(MD, 5)));
  AssertEquals(3, JsonMutObjSize(Obj));
  AssertTrue(JsonMutObjIterInit(Obj, @It)); SetLength(Keys, 0);
  while JsonMutObjIterHasNext(@It) do begin
    V := JsonMutObjIterNext(@It);
    SetLength(Keys, Length(Keys)+1);
    Keys[High(Keys)] := String(JsonGetStr(PJsonValue(V)));
  end;
  AssertEquals('b', Keys[0]); AssertEquals('d', Keys[1]); AssertEquals('e', Keys[2]);
  MD.Free;
end;

procedure TTestCase_Mutable.Test_Array_IterRemove;
var Al: IAllocator; MD: TJsonMutDocument; Arr, V: PJsonMutValue; It: TJsonMutArrayIterator; Count: SizeUInt;
begin
  Al := GetRtlAllocator(); MD := JsonMutDocNew(Al); Arr := JsonMutArr(MD);
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 1)));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 2)));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 3)));
  AssertEquals(3, JsonMutArrSize(Arr));

  AssertTrue(JsonMutArrIterInit(Arr, @It));
  V := JsonMutArrIterNext(@It); // -> 1
  AssertTrue(Assigned(JsonMutArrIterRemove(@It))); // 删除 1
  V := JsonMutArrIterNext(@It); if V <> nil then; // -> 2 (原 2)
  V := JsonMutArrIterNext(@It); if V <> nil then; // -> 3 (原 3)
  AssertFalse(JsonMutArrIterHasNext(@It));

  Count := JsonMutArrSize(Arr); AssertEquals(2, Count);
  MD.Free;
end;

procedure TTestCase_Mutable.Test_Object_IterRemove;
var Al: IAllocator; MD: TJsonMutDocument; Obj, K: PJsonMutValue; It: TJsonMutObjectIterator; Keys: array of String; Count: SizeUInt;
begin
  Keys := nil;
  Al := GetRtlAllocator(); MD := JsonMutDocNew(Al); Obj := JsonMutObj(MD);
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'a'), JsonMutUint(MD, 1)));
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'b'), JsonMutUint(MD, 2)));
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'c'), JsonMutUint(MD, 3)));

  AssertTrue(JsonMutObjIterInit(Obj, @It));
  K := JsonMutObjIterNext(@It); // a
  AssertTrue(Assigned(JsonMutObjIterRemove(@It))); // remove a
  K := JsonMutObjIterNext(@It); if K <> nil then; // b
  K := JsonMutObjIterNext(@It); if K <> nil then; // c
  AssertFalse(JsonMutObjIterHasNext(@It));

  Count := JsonMutObjSize(Obj); AssertEquals(2, Count);
  // 迭代顺序剩余 b,c
  AssertTrue(JsonMutObjIterInit(Obj, @It)); SetLength(Keys, 0);
  while JsonMutObjIterHasNext(@It) do begin
    K := JsonMutObjIterNext(@It); if JsonMutObjIterGetVal(K) <> nil then;
    SetLength(Keys, Length(Keys)+1);
    Keys[High(Keys)] := String(JsonGetStr(PJsonValue(K)));
  end;
  AssertEquals('b', Keys[0]); AssertEquals('c', Keys[1]);
  MD.Free;
end;

procedure TTestCase_Mutable.Test_Object_Put_Dedup_Order;
var MD: TJsonMutDocument; Obj, V: PJsonMutValue; It: TJsonMutObjectIterator; Keys: array of String;
begin
  Keys := nil;
  MD := JsonMutDocNew(GetRtlAllocator()); Obj := JsonMutObj(MD);
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'k'), JsonMutUint(MD, 1)));
  // Put 同键：替换第一次，去重其余
  AssertTrue(JsonMutObjPut(Obj, JsonMutStr(MD, 'k'), JsonMutUint(MD, 2)));
  AssertTrue(JsonMutObjPut(Obj, JsonMutStr(MD, 'k'), JsonMutUint(MD, 3)));
  AssertEquals(1, JsonMutObjSize(Obj));
  // 顺序稳定（只有 k）
  AssertTrue(JsonMutObjIterInit(Obj, @It)); SetLength(Keys, 0);
  while JsonMutObjIterHasNext(@It) do begin V := JsonMutObjIterNext(@It); SetLength(Keys, Length(Keys)+1); Keys[High(Keys)] := String(JsonGetStr(PJsonValue(V))); end;
  AssertEquals(1, Length(Keys)); AssertEquals('k', Keys[0]);
  MD.Free;
end;

procedure TTestCase_Mutable.Test_Object_Insert_Index_Order;
var MD: TJsonMutDocument; Obj, V: PJsonMutValue; It: TJsonMutObjectIterator; Keys: array of String;
begin
  Keys := nil;
  MD := JsonMutDocNew(GetRtlAllocator()); Obj := JsonMutObj(MD);
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'a'), JsonMutUint(MD, 1)));
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'c'), JsonMutUint(MD, 3)));
  // 在索引 1 插入 b -> a,b,c
  AssertTrue(JsonMutObjInsert(Obj, JsonMutStr(MD, 'b'), JsonMutUint(MD, 2), 1));
  AssertTrue(JsonMutObjIterInit(Obj, @It)); SetLength(Keys, 0);
  while JsonMutObjIterHasNext(@It) do begin V := JsonMutObjIterNext(@It); SetLength(Keys, Length(Keys)+1); Keys[High(Keys)] := String(JsonGetStr(PJsonValue(V))); end;
  AssertEquals('a', Keys[0]); AssertEquals('b', Keys[1]); AssertEquals('c', Keys[2]);
  MD.Free;
end;

procedure TTestCase_Mutable.Test_Array_Remove_Multi_OutOfRange;
var MD: TJsonMutDocument; Arr: PJsonMutValue; Rem: PJsonMutValue;
begin
  MD := JsonMutDocNew(GetRtlAllocator()); Arr := JsonMutArr(MD);
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 10)));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 20)));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 30)));
  AssertEquals(3, JsonMutArrSize(Arr));
  // 多次删除
  Rem := JsonMutArrRemove(Arr, 1); AssertTrue(Assigned(Rem)); AssertEquals(2, JsonMutArrSize(Arr));
  Rem := JsonMutArrRemove(Arr, 1); AssertTrue(Assigned(Rem)); AssertEquals(1, JsonMutArrSize(Arr));
  // 越界
  Rem := JsonMutArrRemove(Arr, 5); AssertTrue(not Assigned(Rem)); AssertEquals(1, JsonMutArrSize(Arr));
  MD.Free;
end;

procedure TTestCase_Mutable.Test_Clear_ReAdd;
var MD: TJsonMutDocument; Arr, Obj: PJsonMutValue;
begin
  MD := JsonMutDocNew(GetRtlAllocator()); Arr := JsonMutArr(MD); Obj := JsonMutObj(MD);
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 1))); AssertEquals(1, JsonMutArrSize(Arr));
  AssertTrue(JsonMutArrClear(Arr)); AssertEquals(0, JsonMutArrSize(Arr));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 2))); AssertEquals(1, JsonMutArrSize(Arr));

  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'x'), JsonMutUint(MD, 1))); AssertEquals(1, JsonMutObjSize(Obj));
  AssertTrue(JsonMutObjClear(Obj)); AssertEquals(0, JsonMutObjSize(Obj));
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'y'), JsonMutUint(MD, 2))); AssertEquals(1, JsonMutObjSize(Obj));
  MD.Free;
end;

procedure TTestCase_Mutable.Test_Nested_RoundTrip;
var MD: TJsonMutDocument; Root, Obj, Arr, V: PJsonMutValue; It: TJsonMutObjectIterator; Keys: array of String;
begin
  Keys := nil;
  MD := JsonMutDocNew(GetRtlAllocator());
  Root := JsonMutObj(MD); JsonMutDocSetRoot(MD, Root);
  Obj := JsonMutObj(MD); AssertTrue(JsonMutObjAdd(Root, JsonMutStr(MD, 'o'), Obj));
  Arr := JsonMutArr(MD); AssertTrue(JsonMutObjAdd(Root, JsonMutStr(MD, 'a'), Arr));
  AssertTrue(JsonMutObjAdd(Obj, JsonMutStr(MD, 'k'), JsonMutUint(MD, 1)));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 2)));
  AssertTrue(JsonMutArrAppend(Arr, JsonMutUint(MD, 3)));

  // 结构断言：Root 包含键 o 和 a，o 内有 k，a 长度为 2
  AssertTrue(JsonMutObjIterInit(Root, @It)); SetLength(Keys, 0);
  while JsonMutObjIterHasNext(@It) do begin V := JsonMutObjIterNext(@It); SetLength(Keys, Length(Keys)+1); Keys[High(Keys)] := String(JsonGetStr(PJsonValue(V))); end;
  AssertEquals(2, Length(Keys));
  if Keys[0] = 'o' then begin AssertEquals('a', Keys[1]); end else begin AssertEquals('a', Keys[0]); AssertEquals('o', Keys[1]); end;
  V := JsonMutObjGet(Obj, 'k'); AssertTrue(Assigned(V));
  AssertEquals(2, JsonMutArrSize(Arr));
  MD.Free;
end;


initialization
  RegisterTest(TTestCase_Mutable);
end.

