unit Test_HashMap_Full;

{**
 * @desc TDD 测试：THashMap<K,V> 完整测试套件
 * @purpose 验证哈希映射的所有公共 API
 *
 * 测试覆盖:
 *   - Put/Add/AddOrAssign: 插入操作
 *   - TryGetValue/ContainsKey: 查询操作
 *   - Remove: 删除操作
 *   - Clear/Reserve: 容量管理
 *   - 边界条件: 空表、单元素、大数据集
 *   - 冲突处理: 哈希冲突场景
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.base,
  fafafa.core.mem.allocator;

type
  { TTestCase_HashMap_Full }
  TTestCase_HashMap_Full = class(TTestCase)
  private
    type
      TIntIntMap = specialize THashMap<Integer, Integer>;
      TStrIntMap = specialize THashMap<String, Integer>;
  published
    // === 基本插入操作测试 ===
    procedure Test_HashMap_Put_SingleElement;
    procedure Test_HashMap_Put_MultipleElements;
    procedure Test_HashMap_Put_OverwriteExisting;
    procedure Test_HashMap_Add_NewKey_ReturnsTrue;
    procedure Test_HashMap_Add_ExistingKey_ReturnsFalse;
    procedure Test_HashMap_AddOrAssign_NewKey;
    procedure Test_HashMap_AddOrAssign_ExistingKey;
    
    // === 查询操作测试 ===
    procedure Test_HashMap_TryGetValue_ExistingKey;
    procedure Test_HashMap_TryGetValue_NonExistingKey;
    procedure Test_HashMap_ContainsKey_True;
    procedure Test_HashMap_ContainsKey_False;
    
    // === 删除操作测试 ===
    procedure Test_HashMap_Remove_ExistingKey;
    procedure Test_HashMap_Remove_NonExistingKey;
    procedure Test_HashMap_Remove_ThenAdd;
    
    // === 容量管理测试 ===
    procedure Test_HashMap_Reserve_IncreasesCapacity;
    procedure Test_HashMap_Clear_RemovesAll;
    procedure Test_HashMap_LoadFactor_Increases;
    
    // === 边界条件测试 ===
    procedure Test_HashMap_IsEmpty_InitiallyTrue;
    procedure Test_HashMap_Count_AfterOperations;
    
    // === 字符串键测试 ===
    procedure Test_HashMap_StringKey_BasicOperations;
    
    // === 大数据集测试 ===
    procedure Test_HashMap_LargeDataSet;
  end;

implementation

{ TTestCase_HashMap_Full }

// === 基本插入操作测试 ===

procedure TTestCase_HashMap_Full.Test_HashMap_Put_SingleElement;
var
  Map: TIntIntMap;
  V: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 100);
    
    AssertEquals('Count should be 1', 1, Map.Count);
    AssertTrue('Should contain key', Map.TryGetValue(1, V));
    AssertEquals('Value should be 100', 100, V);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_Put_MultipleElements;
var
  Map: TIntIntMap;
  V: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 100);
    Map.Put(2, 200);
    Map.Put(3, 300);
    
    AssertEquals('Count should be 3', 3, Map.Count);
    
    AssertTrue('Key 1 exists', Map.TryGetValue(1, V));
    AssertEquals('Value 1', 100, V);
    
    AssertTrue('Key 2 exists', Map.TryGetValue(2, V));
    AssertEquals('Value 2', 200, V);
    
    AssertTrue('Key 3 exists', Map.TryGetValue(3, V));
    AssertEquals('Value 3', 300, V);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_Put_OverwriteExisting;
var
  Map: TIntIntMap;
  V: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 100);
    Map.Put(1, 999);  // 覆盖
    
    AssertEquals('Count should still be 1', 1, Map.Count);
    AssertTrue('Key exists', Map.TryGetValue(1, V));
    AssertEquals('Value should be updated', 999, V);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_Add_NewKey_ReturnsTrue;
var
  Map: TIntIntMap;
begin
  Map := TIntIntMap.Create;
  try
    AssertTrue('Add new key should return True', Map.Add(1, 100));
    AssertEquals('Count should be 1', 1, Map.Count);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_Add_ExistingKey_ReturnsFalse;
var
  Map: TIntIntMap;
  V: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.Add(1, 100);
    AssertFalse('Add existing key should return False', Map.Add(1, 200));
    AssertEquals('Count should still be 1', 1, Map.Count);
    
    // 值不应被更新
    AssertTrue('Key exists', Map.TryGetValue(1, V));
    AssertEquals('Value should be original', 100, V);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_AddOrAssign_NewKey;
var
  Map: TIntIntMap;
begin
  Map := TIntIntMap.Create;
  try
    AssertTrue('AddOrAssign new key should return True', Map.AddOrAssign(1, 100));
    AssertEquals('Count should be 1', 1, Map.Count);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_AddOrAssign_ExistingKey;
var
  Map: TIntIntMap;
  V: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.AddOrAssign(1, 100);
    AssertFalse('AddOrAssign existing key should return False', Map.AddOrAssign(1, 999));
    AssertEquals('Count should still be 1', 1, Map.Count);
    
    // 值应被更新
    AssertTrue('Key exists', Map.TryGetValue(1, V));
    AssertEquals('Value should be updated', 999, V);
  finally
    Map.Free;
  end;
end;

// === 查询操作测试 ===

procedure TTestCase_HashMap_Full.Test_HashMap_TryGetValue_ExistingKey;
var
  Map: TIntIntMap;
  V: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(42, 123);
    V := 0;
    
    AssertTrue('TryGetValue should return True', Map.TryGetValue(42, V));
    AssertEquals('Value should be 123', 123, V);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_TryGetValue_NonExistingKey;
var
  Map: TIntIntMap;
  V: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 100);
    V := 999;
    
    AssertFalse('TryGetValue should return False', Map.TryGetValue(999, V));
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_ContainsKey_True;
var
  Map: TIntIntMap;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(42, 100);
    
    AssertTrue('ContainsKey should return True', Map.ContainsKey(42));
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_ContainsKey_False;
var
  Map: TIntIntMap;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 100);
    
    AssertFalse('ContainsKey should return False', Map.ContainsKey(999));
  finally
    Map.Free;
  end;
end;

// === 删除操作测试 ===

procedure TTestCase_HashMap_Full.Test_HashMap_Remove_ExistingKey;
var
  Map: TIntIntMap;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 100);
    Map.Put(2, 200);
    
    AssertTrue('Remove should return True', Map.Remove(1));
    AssertEquals('Count should be 1', 1, Map.Count);
    AssertFalse('Key should no longer exist', Map.ContainsKey(1));
    AssertTrue('Other key should still exist', Map.ContainsKey(2));
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_Remove_NonExistingKey;
var
  Map: TIntIntMap;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 100);
    
    AssertFalse('Remove non-existing should return False', Map.Remove(999));
    AssertEquals('Count should still be 1', 1, Map.Count);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_Remove_ThenAdd;
var
  Map: TIntIntMap;
  V: Integer;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 100);
    Map.Remove(1);
    Map.Put(1, 200);  // 重新添加相同的键
    
    AssertEquals('Count should be 1', 1, Map.Count);
    AssertTrue('Key exists', Map.TryGetValue(1, V));
    AssertEquals('Value should be new value', 200, V);
  finally
    Map.Free;
  end;
end;

// === 容量管理测试 ===

procedure TTestCase_HashMap_Full.Test_HashMap_Reserve_IncreasesCapacity;
var
  Map: TIntIntMap;
  OldCapacity: SizeUInt;
begin
  Map := TIntIntMap.Create;
  try
    OldCapacity := Map.GetCapacity;
    
    Map.Reserve(1000);
    
    AssertTrue('Capacity should increase', Map.GetCapacity >= 1000);
    AssertEquals('Count should still be 0', 0, Map.Count);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_Clear_RemovesAll;
var
  Map: TIntIntMap;
begin
  Map := TIntIntMap.Create;
  try
    Map.Put(1, 100);
    Map.Put(2, 200);
    Map.Put(3, 300);
    
    Map.Clear;
    
    AssertEquals('Count should be 0', 0, Map.Count);
    AssertTrue('Map should be empty', Map.IsEmpty);
    AssertFalse('Key should not exist', Map.ContainsKey(1));
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_LoadFactor_Increases;
var
  Map: TIntIntMap;
  LF1, LF2: Single;
  i: Integer;
begin
  Map := TIntIntMap.Create;
  try
    LF1 := Map.GetLoadFactor;
    
    for i := 1 to 10 do
      Map.Put(i, i * 100);
    
    LF2 := Map.GetLoadFactor;
    
    AssertTrue('Load factor should increase', LF2 > LF1);
  finally
    Map.Free;
  end;
end;

// === 边界条件测试 ===

procedure TTestCase_HashMap_Full.Test_HashMap_IsEmpty_InitiallyTrue;
var
  Map: TIntIntMap;
begin
  Map := TIntIntMap.Create;
  try
    AssertTrue('New map should be empty', Map.IsEmpty);
    AssertEquals('Count should be 0', 0, Map.Count);
  finally
    Map.Free;
  end;
end;

procedure TTestCase_HashMap_Full.Test_HashMap_Count_AfterOperations;
var
  Map: TIntIntMap;
begin
  Map := TIntIntMap.Create;
  try
    AssertEquals('Initial count', 0, Map.Count);
    
    Map.Put(1, 100);
    AssertEquals('After put', 1, Map.Count);
    
    Map.Put(2, 200);
    AssertEquals('After second put', 2, Map.Count);
    
    Map.Put(1, 150);  // 更新，不增加 count
    AssertEquals('After update', 2, Map.Count);
    
    Map.Remove(1);
    AssertEquals('After remove', 1, Map.Count);
    
    Map.Clear;
    AssertEquals('After clear', 0, Map.Count);
  finally
    Map.Free;
  end;
end;

// === 字符串键测试 ===

procedure TTestCase_HashMap_Full.Test_HashMap_StringKey_BasicOperations;
var
  Map: TStrIntMap;
  V: Integer;
begin
  Map := TStrIntMap.Create;
  try
    Map.Put('one', 1);
    Map.Put('two', 2);
    Map.Put('three', 3);
    
    AssertEquals('Count', 3, Map.Count);
    
    AssertTrue('Contains one', Map.ContainsKey('one'));
    AssertTrue('Contains two', Map.ContainsKey('two'));
    AssertTrue('Contains three', Map.ContainsKey('three'));
    AssertFalse('Does not contain four', Map.ContainsKey('four'));
    
    AssertTrue('Get one', Map.TryGetValue('one', V));
    AssertEquals('Value one', 1, V);
    
    Map.Remove('two');
    AssertEquals('Count after remove', 2, Map.Count);
    AssertFalse('two removed', Map.ContainsKey('two'));
  finally
    Map.Free;
  end;
end;

// === 大数据集测试 ===

procedure TTestCase_HashMap_Full.Test_HashMap_LargeDataSet;
var
  Map: TIntIntMap;
  i: Integer;
  V: Integer;
begin
  Map := TIntIntMap.Create;
  try
    // 插入 10000 个元素
    for i := 0 to 9999 do
      Map.Put(i, i * 10);
    
    AssertEquals('Count should be 10000', 10000, Map.Count);
    
    // 验证几个随机元素
    AssertTrue('Key 0 exists', Map.TryGetValue(0, V));
    AssertEquals('Value 0', 0, V);
    
    AssertTrue('Key 5000 exists', Map.TryGetValue(5000, V));
    AssertEquals('Value 5000', 50000, V);
    
    AssertTrue('Key 9999 exists', Map.TryGetValue(9999, V));
    AssertEquals('Value 9999', 99990, V);
    
    // 删除一半
    for i := 0 to 4999 do
      Map.Remove(i);
    
    AssertEquals('Count after removes', 5000, Map.Count);
    AssertFalse('Key 0 removed', Map.ContainsKey(0));
    AssertTrue('Key 5000 still exists', Map.ContainsKey(5000));
  finally
    Map.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_HashMap_Full);

end.
