{$CODEPAGE UTF8}
program example_mutable_showcase;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

procedure DumpMutableObj(Obj: PJsonMutValue);
var It: TJsonMutObjectIterator; K, V: PJsonMutValue; Keys: array of String;
begin
  if not Assigned(Obj) then Exit;
  if not JsonMutObjIterInit(Obj, @It) then Exit;
  SetLength(Keys, 0);
  while JsonMutObjIterHasNext(@It) do begin
    K := JsonMutObjIterNext(@It); V := JsonMutObjIterGetVal(K);
    SetLength(Keys, Length(Keys)+1);
    Keys[High(Keys)] := String(JsonGetStr(PJsonValue(K)));
  end;
  Write('Object keys: ');
  if Length(Keys) = 0 then Writeln('<empty>') else Writeln(String.Join(',', Keys));
end;

var
  Al: TAllocator;
  MD: TJsonMutDocument;
  Root, Obj, Arr, V: PJsonMutValue;
begin
  Al := GetRtlAllocator();
  MD := JsonMutDocNew(Al);
  try
    // 构造 {"o":{"k":1}, "a":[2,3]}
    Root := JsonMutObj(MD); JsonMutDocSetRoot(MD, Root);
    Obj := JsonMutObj(MD); JsonMutObjAdd(Root, JsonMutStr(MD, 'o'), Obj);
    Arr := JsonMutArr(MD); JsonMutObjAdd(Root, JsonMutStr(MD, 'a'), Arr);
    JsonMutObjAdd(Obj, JsonMutStr(MD, 'k'), JsonMutUint(MD, 1));
    JsonMutArrAppend(Arr, JsonMutUint(MD, 2));
    JsonMutArrAppend(Arr, JsonMutUint(MD, 3));

    // 在对象中插入新键，并删除一个键
    JsonMutObjInsert(Root, JsonMutStr(MD, 'x'), JsonMutBool(MD, True), 1);
    DumpMutableObj(Root);
    V := JsonMutObjRemoveKey(Root, 'x');
    if Assigned(V) then Writeln('Removed key x');

    // 数组迭代删除首元素
    var ItArr: TJsonMutArrayIterator;
    if JsonMutArrIterInit(Arr, @ItArr) then begin
      JsonMutArrIterNext(@ItArr); // -> first
      JsonMutArrIterRemove(@ItArr);
    end;
    Writeln('Array size after remove-first via iter: ', JsonMutArrSize(Arr));

    // 最终结构断言
    DumpMutableObj(Root);
  finally
    MD.Free;
  end;
end.

