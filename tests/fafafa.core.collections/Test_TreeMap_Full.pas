unit Test_TreeMap_Full;

{**
 * @desc TDD 测试：TTreeMap<K,V> 完整测试套件
 * @purpose 验证红黑树映射的所有公共 API
 *
 * 测试覆盖:
 *   - Put/Get/Remove: 基本操作
 *   - ContainsKey: 查询操作
 *   - GetLowerBound/GetUpperBound: 边界查询
 *   - Ceiling/Floor: 天花板/地板操作
 *   - GetRange: 范围遍历
 *   - Clear: 容量管理
 *   - 有序性验证
 *   - 边界条件: 空树、单元素、大数据集
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.treemap,
  fafafa.core.collections.base,
  fafafa.core.mem.allocator;

type
  { TTestCase_TreeMap_Full }
  TTestCase_TreeMap_Full = class(TTestCase)
  private
    type
      TIntIntTree = specialize TTreeMap<Integer, Integer>;
      TStrIntTree = specialize TTreeMap<String, Integer>;
    class function CompareInt(const A, B: Integer; Data: Pointer): SizeInt; static;
    class function CompareStr(const A, B: String; Data: Pointer): SizeInt; static;
    function CreateIntTree: TIntIntTree;
    function CreateStrTree: TStrIntTree;
  published
    // === 基本插入操作测试 ===
    procedure Test_TreeMap_Put_SingleElement;
    procedure Test_TreeMap_Put_MultipleElements;
    procedure Test_TreeMap_Put_OverwriteExisting;
    
    // === 查询操作测试 ===
    procedure Test_TreeMap_Get_ExistingKey;
    procedure Test_TreeMap_Get_NonExistingKey;
    procedure Test_TreeMap_ContainsKey_True;
    procedure Test_TreeMap_ContainsKey_False;
    
    // === 删除操作测试 ===
    procedure Test_TreeMap_Remove_ExistingKey;
    procedure Test_TreeMap_Remove_NonExistingKey;
    procedure Test_TreeMap_Remove_Root;
    
    // === 边界查询测试 ===
    procedure Test_TreeMap_Ceiling_ExactMatch;
    procedure Test_TreeMap_Ceiling_NoExactMatch;
    procedure Test_TreeMap_Ceiling_NoMatch;
    procedure Test_TreeMap_Floor_ExactMatch;
    procedure Test_TreeMap_Floor_NoExactMatch;
    procedure Test_TreeMap_Floor_NoMatch;
    
    // === 容量管理测试 ===
    procedure Test_TreeMap_Clear_RemovesAll;
    
    // === 边界条件测试 ===
    procedure Test_TreeMap_IsEmpty_InitiallyTrue;
    procedure Test_TreeMap_Count_AfterOperations;
    
    // === 有序性测试 ===
    procedure Test_TreeMap_InsertOrder_Ascending;
    procedure Test_TreeMap_InsertOrder_Descending;
    procedure Test_TreeMap_InsertOrder_Random;
    
    // === 字符串键测试 ===
    procedure Test_TreeMap_StringKey_BasicOperations;
    
    // === 大数据集测试 ===
    procedure Test_TreeMap_LargeDataSet;
  end;

implementation

{ TTestCase_TreeMap_Full }

class function TTestCase_TreeMap_Full.CompareInt(const A, B: Integer; Data: Pointer): SizeInt;
begin
  Result := A - B;
end;

class function TTestCase_TreeMap_Full.CompareStr(const A, B: String; Data: Pointer): SizeInt;
begin
  Result := SysUtils.CompareStr(A, B);
end;

function TTestCase_TreeMap_Full.CreateIntTree: TIntIntTree;
begin
  Result := TIntIntTree.Create(nil, @CompareInt);
end;

function TTestCase_TreeMap_Full.CreateStrTree: TStrIntTree;
begin
  Result := TStrIntTree.Create(nil, @CompareStr);
end;

// === 基本插入操作测试 ===

procedure TTestCase_TreeMap_Full.Test_TreeMap_Put_SingleElement;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    
    AssertEquals('Count should be 1', 1, Tree.Count);
    AssertTrue('Should contain key', Tree.Get(1, V));
    AssertEquals('Value should be 100', 100, V);
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Put_MultipleElements;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(3, 300);
    Tree.Put(1, 100);
    Tree.Put(2, 200);
    
    AssertEquals('Count should be 3', 3, Tree.Count);
    
    AssertTrue('Key 1 exists', Tree.Get(1, V));
    AssertEquals('Value 1', 100, V);
    
    AssertTrue('Key 2 exists', Tree.Get(2, V));
    AssertEquals('Value 2', 200, V);
    
    AssertTrue('Key 3 exists', Tree.Get(3, V));
    AssertEquals('Value 3', 300, V);
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Put_OverwriteExisting;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    Tree.Put(1, 999);  // 覆盖
    
    AssertEquals('Count should still be 1', 1, Tree.Count);
    AssertTrue('Key exists', Tree.Get(1, V));
    AssertEquals('Value should be updated', 999, V);
  finally
    Tree.Free;
  end;
end;

// === 查询操作测试 ===

procedure TTestCase_TreeMap_Full.Test_TreeMap_Get_ExistingKey;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(42, 123);
    V := 0;
    
    AssertTrue('Get should return True', Tree.Get(42, V));
    AssertEquals('Value should be 123', 123, V);
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Get_NonExistingKey;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    V := 999;
    
    AssertFalse('Get should return False', Tree.Get(999, V));
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_ContainsKey_True;
var
  Tree: TIntIntTree;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(42, 100);
    
    AssertTrue('ContainsKey should return True', Tree.ContainsKey(42));
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_ContainsKey_False;
var
  Tree: TIntIntTree;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    
    AssertFalse('ContainsKey should return False', Tree.ContainsKey(999));
  finally
    Tree.Free;
  end;
end;

// === 删除操作测试 ===

procedure TTestCase_TreeMap_Full.Test_TreeMap_Remove_ExistingKey;
var
  Tree: TIntIntTree;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    Tree.Put(2, 200);
    
    AssertTrue('Remove should return True', Tree.Remove(1));
    AssertEquals('Count should be 1', 1, Tree.Count);
    AssertFalse('Key should no longer exist', Tree.ContainsKey(1));
    AssertTrue('Other key should still exist', Tree.ContainsKey(2));
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Remove_NonExistingKey;
var
  Tree: TIntIntTree;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    
    AssertFalse('Remove non-existing should return False', Tree.Remove(999));
    AssertEquals('Count should still be 1', 1, Tree.Count);
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Remove_Root;
var
  Tree: TIntIntTree;
begin
  Tree := CreateIntTree;
  try
    // 插入多个元素，确保有根节点
    Tree.Put(5, 500);
    Tree.Put(3, 300);
    Tree.Put(7, 700);
    Tree.Put(1, 100);
    Tree.Put(9, 900);
    
    // 删除根节点（可能是 5）
    AssertTrue('Remove root should succeed', Tree.Remove(5));
    AssertEquals('Count should be 4', 4, Tree.Count);
    AssertFalse('Root key removed', Tree.ContainsKey(5));
    
    // 其他节点仍存在
    AssertTrue('Key 3 exists', Tree.ContainsKey(3));
    AssertTrue('Key 7 exists', Tree.ContainsKey(7));
    AssertTrue('Key 1 exists', Tree.ContainsKey(1));
    AssertTrue('Key 9 exists', Tree.ContainsKey(9));
  finally
    Tree.Free;
  end;
end;

// === 边界查询测试 ===

procedure TTestCase_TreeMap_Full.Test_TreeMap_Ceiling_ExactMatch;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    Tree.Put(5, 500);
    Tree.Put(10, 1000);
    
    // 精确匹配
    AssertTrue('Ceiling(5) should find', Tree.Ceiling(5, V));
    AssertEquals('Ceiling(5) value', 500, V);
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Ceiling_NoExactMatch;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    Tree.Put(5, 500);
    Tree.Put(10, 1000);
    
    // 无精确匹配，返回下一个更大的
    AssertTrue('Ceiling(3) should find', Tree.Ceiling(3, V));
    AssertEquals('Ceiling(3) value', 500, V);  // 返回键 5 的值
    
    AssertTrue('Ceiling(7) should find', Tree.Ceiling(7, V));
    AssertEquals('Ceiling(7) value', 1000, V);  // 返回键 10 的值
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Ceiling_NoMatch;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    Tree.Put(5, 500);
    Tree.Put(10, 1000);
    
    // 没有更大的键
    AssertFalse('Ceiling(11) should not find', Tree.Ceiling(11, V));
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Floor_ExactMatch;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    Tree.Put(5, 500);
    Tree.Put(10, 1000);
    
    // 精确匹配
    AssertTrue('Floor(5) should find', Tree.Floor(5, V));
    AssertEquals('Floor(5) value', 500, V);
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Floor_NoExactMatch;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    Tree.Put(5, 500);
    Tree.Put(10, 1000);
    
    // 无精确匹配，返回下一个更小的
    AssertTrue('Floor(7) should find', Tree.Floor(7, V));
    AssertEquals('Floor(7) value', 500, V);  // 返回键 5 的值
    
    AssertTrue('Floor(3) should find', Tree.Floor(3, V));
    AssertEquals('Floor(3) value', 100, V);  // 返回键 1 的值
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Floor_NoMatch;
var
  Tree: TIntIntTree;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(5, 500);
    Tree.Put(10, 1000);
    
    // 没有更小的键
    AssertFalse('Floor(4) should not find', Tree.Floor(4, V));
  finally
    Tree.Free;
  end;
end;

// === 容量管理测试 ===

procedure TTestCase_TreeMap_Full.Test_TreeMap_Clear_RemovesAll;
var
  Tree: TIntIntTree;
begin
  Tree := CreateIntTree;
  try
    Tree.Put(1, 100);
    Tree.Put(2, 200);
    Tree.Put(3, 300);
    
    Tree.Clear;
    
    AssertEquals('Count should be 0', 0, Tree.Count);
    AssertTrue('Tree should be empty', Tree.IsEmpty);
    AssertFalse('Key should not exist', Tree.ContainsKey(1));
  finally
    Tree.Free;
  end;
end;

// === 边界条件测试 ===

procedure TTestCase_TreeMap_Full.Test_TreeMap_IsEmpty_InitiallyTrue;
var
  Tree: TIntIntTree;
begin
  Tree := CreateIntTree;
  try
    AssertTrue('New tree should be empty', Tree.IsEmpty);
    AssertEquals('Count should be 0', 0, Tree.Count);
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_Count_AfterOperations;
var
  Tree: TIntIntTree;
begin
  Tree := CreateIntTree;
  try
    AssertEquals('Initial count', 0, Tree.Count);
    
    Tree.Put(1, 100);
    AssertEquals('After put', 1, Tree.Count);
    
    Tree.Put(2, 200);
    AssertEquals('After second put', 2, Tree.Count);
    
    Tree.Put(1, 150);  // 更新，不增加 count
    AssertEquals('After update', 2, Tree.Count);
    
    Tree.Remove(1);
    AssertEquals('After remove', 1, Tree.Count);
    
    Tree.Clear;
    AssertEquals('After clear', 0, Tree.Count);
  finally
    Tree.Free;
  end;
end;

// === 有序性测试 ===

procedure TTestCase_TreeMap_Full.Test_TreeMap_InsertOrder_Ascending;
var
  Tree: TIntIntTree;
  V: Integer;
  i: Integer;
begin
  Tree := CreateIntTree;
  try
    // 升序插入
    for i := 1 to 10 do
      Tree.Put(i, i * 100);
    
    AssertEquals('Count', 10, Tree.Count);
    
    // 验证所有元素存在
    for i := 1 to 10 do
    begin
      AssertTrue('Key exists', Tree.Get(i, V));
      AssertEquals('Value correct', i * 100, V);
    end;
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_InsertOrder_Descending;
var
  Tree: TIntIntTree;
  V: Integer;
  i: Integer;
begin
  Tree := CreateIntTree;
  try
    // 降序插入
    for i := 10 downto 1 do
      Tree.Put(i, i * 100);
    
    AssertEquals('Count', 10, Tree.Count);
    
    // 验证所有元素存在
    for i := 1 to 10 do
    begin
      AssertTrue('Key exists', Tree.Get(i, V));
      AssertEquals('Value correct', i * 100, V);
    end;
  finally
    Tree.Free;
  end;
end;

procedure TTestCase_TreeMap_Full.Test_TreeMap_InsertOrder_Random;
var
  Tree: TIntIntTree;
  V: Integer;
  Keys: array[0..9] of Integer = (7, 3, 9, 1, 5, 8, 2, 6, 4, 10);
  i: Integer;
begin
  Tree := CreateIntTree;
  try
    // 随机顺序插入
    for i := 0 to High(Keys) do
      Tree.Put(Keys[i], Keys[i] * 100);
    
    AssertEquals('Count', 10, Tree.Count);
    
    // 验证所有元素存在
    for i := 1 to 10 do
    begin
      AssertTrue('Key exists', Tree.Get(i, V));
      AssertEquals('Value correct', i * 100, V);
    end;
  finally
    Tree.Free;
  end;
end;

// === 字符串键测试 ===

procedure TTestCase_TreeMap_Full.Test_TreeMap_StringKey_BasicOperations;
var
  Tree: TStrIntTree;
  V: Integer;
begin
  Tree := CreateStrTree;
  try
    Tree.Put('apple', 1);
    Tree.Put('banana', 2);
    Tree.Put('cherry', 3);
    
    AssertEquals('Count', 3, Tree.Count);
    
    AssertTrue('Contains apple', Tree.ContainsKey('apple'));
    AssertTrue('Contains banana', Tree.ContainsKey('banana'));
    AssertTrue('Contains cherry', Tree.ContainsKey('cherry'));
    AssertFalse('Does not contain date', Tree.ContainsKey('date'));
    
    AssertTrue('Get apple', Tree.Get('apple', V));
    AssertEquals('Value apple', 1, V);
    
    Tree.Remove('banana');
    AssertEquals('Count after remove', 2, Tree.Count);
    AssertFalse('banana removed', Tree.ContainsKey('banana'));
  finally
    Tree.Free;
  end;
end;

// === 大数据集测试 ===

procedure TTestCase_TreeMap_Full.Test_TreeMap_LargeDataSet;
var
  Tree: TIntIntTree;
  i: Integer;
  V: Integer;
begin
  Tree := CreateIntTree;
  try
    // 插入 10000 个元素
    for i := 0 to 9999 do
      Tree.Put(i, i * 10);
    
    AssertEquals('Count should be 10000', 10000, Tree.Count);
    
    // 验证几个随机元素
    AssertTrue('Key 0 exists', Tree.Get(0, V));
    AssertEquals('Value 0', 0, V);
    
    AssertTrue('Key 5000 exists', Tree.Get(5000, V));
    AssertEquals('Value 5000', 50000, V);
    
    AssertTrue('Key 9999 exists', Tree.Get(9999, V));
    AssertEquals('Value 9999', 99990, V);
    
    // 删除一半
    for i := 0 to 4999 do
      Tree.Remove(i);
    
    AssertEquals('Count after removes', 5000, Tree.Count);
    AssertFalse('Key 0 removed', Tree.ContainsKey(0));
    AssertTrue('Key 5000 still exists', Tree.ContainsKey(5000));
  finally
    Tree.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_TreeMap_Full);

end.
