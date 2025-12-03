unit Test_LinkedHashMap_Order;

{**
 * @desc TDD 测试：LinkedHashMap 插入顺序保持测试
 * @purpose 验证 LinkedHashMap 保持插入顺序
 *
 * 测试内容:
 *   - 插入顺序保持
 *   - 迭代顺序验证
 *   - 更新不改变顺序
 *   - 删除后顺序正确
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.linkedhashmap,
  fafafa.core.collections.base,
  fafafa.core.mem.allocator;

type
  { TTestCase_LinkedHashMap_Order }
  TTestCase_LinkedHashMap_Order = class(TTestCase)
  private
    type
      TIntIntLinkedMap = specialize TLinkedHashMap<Integer, Integer>;
      TStrIntLinkedMap = specialize TLinkedHashMap<string, Integer>;
  published
    // 插入顺序测试
    procedure Test_LinkedHashMap_InsertionOrder_Preserved;
    procedure Test_LinkedHashMap_IterationOrder_MatchesInsertion;
    procedure Test_LinkedHashMap_Update_DoesNotChangeOrder;
    procedure Test_LinkedHashMap_Remove_PreservesRemainingOrder;
    
    // 基本操作测试
    procedure Test_LinkedHashMap_Put_Get_Works;
    procedure Test_LinkedHashMap_ContainsKey;
    procedure Test_LinkedHashMap_Remove_Works;
    procedure Test_LinkedHashMap_Clear_Works;
    
    // 托管类型测试
    procedure Test_LinkedHashMap_String_Keys_NoLeak;
  end;

implementation

{ TTestCase_LinkedHashMap_Order }

procedure TTestCase_LinkedHashMap_Order.Test_LinkedHashMap_InsertionOrder_Preserved;
var
  Map: TIntIntLinkedMap;
  LIter: TPtrIter;
  LEntry: ^specialize TPair<Integer, Integer>;
  LOrder: array[0..4] of Integer;
  LIdx: Integer;
begin
  Map := TIntIntLinkedMap.Create;
  try
    // 插入顺序: 5, 3, 7, 1, 9
    Map.Put(5, 50);
    Map.Put(3, 30);
    Map.Put(7, 70);
    Map.Put(1, 10);
    Map.Put(9, 90);
    
    AssertEquals('Count 应为 5', 5, Map.GetCount);
    
    // 遍历验证顺序
    LIter := Map.PtrIter;
    LIdx := 0;
    while LIter.MoveNext do
    begin
      LEntry := LIter.Current;
      LOrder[LIdx] := LEntry^.Key;
      Inc(LIdx);
    end;
    
    // 验证插入顺序
    AssertEquals('第1个键应为 5', 5, LOrder[0]);
    AssertEquals('第2个键应为 3', 3, LOrder[1]);
    AssertEquals('第3个键应为 7', 7, LOrder[2]);
    AssertEquals('第4个键应为 1', 1, LOrder[3]);
    AssertEquals('第5个键应为 9', 9, LOrder[4]);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_LinkedHashMap_Order.Test_LinkedHashMap_IterationOrder_MatchesInsertion;
var
  Map: TIntIntLinkedMap;
  Keys: array of Integer;
begin
  Map := TIntIntLinkedMap.Create;
  try
    Map.Put(100, 1);
    Map.Put(200, 2);
    Map.Put(300, 3);
    
    Keys := Map.GetAllKeys;
    
    AssertEquals('键数组长度应为 3', 3, Length(Keys));
    AssertEquals('第1个键应为 100', 100, Keys[0]);
    AssertEquals('第2个键应为 200', 200, Keys[1]);
    AssertEquals('第3个键应为 300', 300, Keys[2]);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_LinkedHashMap_Order.Test_LinkedHashMap_Update_DoesNotChangeOrder;
var
  Map: TIntIntLinkedMap;
  Keys: array of Integer;
  V: Integer;
begin
  Map := TIntIntLinkedMap.Create;
  try
    Map.Put(1, 10);
    Map.Put(2, 20);
    Map.Put(3, 30);
    
    // 更新中间的键
    Map.Put(2, 200);
    
    // 顺序不应改变
    Keys := Map.GetAllKeys;
    AssertEquals('第1个键应仍为 1', 1, Keys[0]);
    AssertEquals('第2个键应仍为 2', 2, Keys[1]);
    AssertEquals('第3个键应仍为 3', 3, Keys[2]);
    
    // 值应更新
    AssertTrue(Map.Get(2, V));
    AssertEquals('值应更新为 200', 200, V);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_LinkedHashMap_Order.Test_LinkedHashMap_Remove_PreservesRemainingOrder;
var
  Map: TIntIntLinkedMap;
  Keys: array of Integer;
begin
  Map := TIntIntLinkedMap.Create;
  try
    Map.Put(1, 10);
    Map.Put(2, 20);
    Map.Put(3, 30);
    Map.Put(4, 40);
    
    // 删除中间的键
    Map.Remove(2);
    
    Keys := Map.GetAllKeys;
    AssertEquals('键数组长度应为 3', 3, Length(Keys));
    AssertEquals('第1个键应为 1', 1, Keys[0]);
    AssertEquals('第2个键应为 3', 3, Keys[1]);
    AssertEquals('第3个键应为 4', 4, Keys[2]);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_LinkedHashMap_Order.Test_LinkedHashMap_Put_Get_Works;
var
  Map: TIntIntLinkedMap;
  V: Integer;
begin
  Map := TIntIntLinkedMap.Create;
  try
    Map.Put(42, 100);
    
    AssertTrue('Get 应成功', Map.Get(42, V));
    AssertEquals('值应为 100', 100, V);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_LinkedHashMap_Order.Test_LinkedHashMap_ContainsKey;
var
  Map: TIntIntLinkedMap;
begin
  Map := TIntIntLinkedMap.Create;
  try
    Map.Put(1, 10);
    Map.Put(2, 20);
    
    AssertTrue('应包含键 1', Map.ContainsKey(1));
    AssertTrue('应包含键 2', Map.ContainsKey(2));
    AssertFalse('不应包含键 3', Map.ContainsKey(3));
  finally
    Map.Free;
  end;
end;

procedure TTestCase_LinkedHashMap_Order.Test_LinkedHashMap_Remove_Works;
var
  Map: TIntIntLinkedMap;
begin
  Map := TIntIntLinkedMap.Create;
  try
    Map.Put(1, 10);
    Map.Put(2, 20);
    
    AssertTrue('Remove 应成功', Map.Remove(1));
    AssertFalse('Remove 已删除键应返回 False', Map.Remove(1));
    AssertFalse('不应再包含键 1', Map.ContainsKey(1));
    AssertEquals('Count 应为 1', 1, Map.GetCount);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_LinkedHashMap_Order.Test_LinkedHashMap_Clear_Works;
var
  Map: TIntIntLinkedMap;
begin
  Map := TIntIntLinkedMap.Create;
  try
    Map.Put(1, 10);
    Map.Put(2, 20);
    Map.Put(3, 30);
    
    Map.Clear;
    
    AssertTrue('Clear 后应为空', Map.IsEmpty);
    AssertEquals('Clear 后 Count 为 0', 0, Map.GetCount);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_LinkedHashMap_Order.Test_LinkedHashMap_String_Keys_NoLeak;
var
  Map: TStrIntLinkedMap;
  V: Integer;
begin
  Map := TStrIntLinkedMap.Create;
  try
    Map.Put('apple', 1);
    Map.Put('banana', 2);
    Map.Put('cherry', 3);
    
    AssertEquals('Count 应为 3', 3, Map.GetCount);
    
    AssertTrue(Map.Get('banana', V));
    AssertEquals('banana 值应为 2', 2, V);
    
    Map.Remove('banana');
    AssertFalse('banana 应已删除', Map.ContainsKey('banana'));
    
    Map.Clear;
    AssertTrue('Clear 后应为空', Map.IsEmpty);
  finally
    Map.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_LinkedHashMap_Order);

end.
