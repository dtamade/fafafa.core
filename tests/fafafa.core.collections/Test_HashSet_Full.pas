unit Test_HashSet_Full;

{**
 * @desc TDD 测试：THashSet<K> 基础操作测试套件
 * @purpose 验证哈希集合的核心 API
 *
 * 测试覆盖:
 *   - Add: 添加元素
 *   - Contains: 成员测试
 *   - Remove: 删除元素
 *   - Clear/Reserve: 容量管理
 *   - 边界条件: 空集、单元素、大数据集
 *
 * @note 集合运算（Union/Intersection/Difference）尚未实现，
 *       相关测试在 Test_HashSet_SetOperations.pas
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
  { TTestCase_HashSet_Full }
  TTestCase_HashSet_Full = class(TTestCase)
  private
    type
      TIntSet = specialize THashSet<Integer>;
      TStrSet = specialize THashSet<String>;
  published
    // === 基本添加操作测试 ===
    procedure Test_HashSet_Add_SingleElement;
    procedure Test_HashSet_Add_MultipleElements;
    procedure Test_HashSet_Add_Duplicate_ReturnsFalse;
    
    // === 成员测试 ===
    procedure Test_HashSet_Contains_ExistingElement;
    procedure Test_HashSet_Contains_NonExistingElement;
    procedure Test_HashSet_Contains_EmptySet;
    
    // === 删除操作测试 ===
    procedure Test_HashSet_Remove_ExistingElement;
    procedure Test_HashSet_Remove_NonExistingElement;
    procedure Test_HashSet_Remove_ThenAdd;
    
    // === 容量管理测试 ===
    procedure Test_HashSet_Reserve_IncreasesCapacity;
    procedure Test_HashSet_Clear_RemovesAll;
    
    // === 边界条件测试 ===
    procedure Test_HashSet_IsEmpty_InitiallyTrue;
    procedure Test_HashSet_Count_AfterOperations;
    
    // === 字符串元素测试 ===
    procedure Test_HashSet_StringElement_BasicOperations;
    
    // === 大数据集测试 ===
    procedure Test_HashSet_LargeDataSet;
    procedure Test_HashSet_LargeRemove;
  end;

implementation

{ TTestCase_HashSet_Full }

// === 基本添加操作测试 ===

procedure TTestCase_HashSet_Full.Test_HashSet_Add_SingleElement;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    AssertTrue('Add should return True', S.Add(42));
    AssertEquals('Count should be 1', 1, S.Count);
    AssertTrue('Should contain element', S.Contains(42));
  finally
    S.Free;
  end;
end;

procedure TTestCase_HashSet_Full.Test_HashSet_Add_MultipleElements;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    S.Add(1);
    S.Add(2);
    S.Add(3);
    
    AssertEquals('Count should be 3', 3, S.Count);
    AssertTrue('Contains 1', S.Contains(1));
    AssertTrue('Contains 2', S.Contains(2));
    AssertTrue('Contains 3', S.Contains(3));
  finally
    S.Free;
  end;
end;

procedure TTestCase_HashSet_Full.Test_HashSet_Add_Duplicate_ReturnsFalse;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    AssertTrue('First add should return True', S.Add(42));
    AssertFalse('Duplicate add should return False', S.Add(42));
    AssertEquals('Count should still be 1', 1, S.Count);
  finally
    S.Free;
  end;
end;

// === 成员测试 ===

procedure TTestCase_HashSet_Full.Test_HashSet_Contains_ExistingElement;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    S.Add(42);
    
    AssertTrue('Contains should return True', S.Contains(42));
  finally
    S.Free;
  end;
end;

procedure TTestCase_HashSet_Full.Test_HashSet_Contains_NonExistingElement;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    S.Add(1);
    S.Add(2);
    
    AssertFalse('Contains should return False', S.Contains(999));
  finally
    S.Free;
  end;
end;

procedure TTestCase_HashSet_Full.Test_HashSet_Contains_EmptySet;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    AssertFalse('Empty set contains nothing', S.Contains(42));
  finally
    S.Free;
  end;
end;

// === 删除操作测试 ===

procedure TTestCase_HashSet_Full.Test_HashSet_Remove_ExistingElement;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    S.Add(1);
    S.Add(2);
    S.Add(3);
    
    AssertTrue('Remove should return True', S.Remove(2));
    AssertEquals('Count should be 2', 2, S.Count);
    AssertFalse('Element should no longer exist', S.Contains(2));
    AssertTrue('Other elements still exist', S.Contains(1));
    AssertTrue('Other elements still exist', S.Contains(3));
  finally
    S.Free;
  end;
end;

procedure TTestCase_HashSet_Full.Test_HashSet_Remove_NonExistingElement;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    S.Add(1);
    
    AssertFalse('Remove non-existing should return False', S.Remove(999));
    AssertEquals('Count should still be 1', 1, S.Count);
  finally
    S.Free;
  end;
end;

procedure TTestCase_HashSet_Full.Test_HashSet_Remove_ThenAdd;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    S.Add(42);
    S.Remove(42);
    AssertTrue('Re-add should return True', S.Add(42));
    
    AssertEquals('Count should be 1', 1, S.Count);
    AssertTrue('Element exists', S.Contains(42));
  finally
    S.Free;
  end;
end;

// === 容量管理测试 ===

procedure TTestCase_HashSet_Full.Test_HashSet_Reserve_IncreasesCapacity;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    S.Reserve(1000);
    
    AssertTrue('Capacity should be >= 1000', S.GetCapacity >= 1000);
    AssertEquals('Count should still be 0', 0, S.Count);
  finally
    S.Free;
  end;
end;

procedure TTestCase_HashSet_Full.Test_HashSet_Clear_RemovesAll;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    S.Add(1);
    S.Add(2);
    S.Add(3);
    
    S.Clear;
    
    AssertEquals('Count should be 0', 0, S.Count);
    AssertTrue('Set should be empty', S.IsEmpty);
    AssertFalse('Element should not exist', S.Contains(1));
  finally
    S.Free;
  end;
end;

// === 边界条件测试 ===

procedure TTestCase_HashSet_Full.Test_HashSet_IsEmpty_InitiallyTrue;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    AssertTrue('New set should be empty', S.IsEmpty);
    AssertEquals('Count should be 0', 0, S.Count);
  finally
    S.Free;
  end;
end;

procedure TTestCase_HashSet_Full.Test_HashSet_Count_AfterOperations;
var
  S: TIntSet;
begin
  S := TIntSet.Create;
  try
    AssertEquals('Initial count', 0, S.Count);
    
    S.Add(1);
    AssertEquals('After add', 1, S.Count);
    
    S.Add(2);
    AssertEquals('After second add', 2, S.Count);
    
    S.Add(1);  // 重复，不增加 count
    AssertEquals('After duplicate add', 2, S.Count);
    
    S.Remove(1);
    AssertEquals('After remove', 1, S.Count);
    
    S.Clear;
    AssertEquals('After clear', 0, S.Count);
  finally
    S.Free;
  end;
end;

// === 字符串元素测试 ===

procedure TTestCase_HashSet_Full.Test_HashSet_StringElement_BasicOperations;
var
  S: TStrSet;
begin
  S := TStrSet.Create;
  try
    S.Add('apple');
    S.Add('banana');
    S.Add('cherry');
    
    AssertEquals('Count', 3, S.Count);
    
    AssertTrue('Contains apple', S.Contains('apple'));
    AssertTrue('Contains banana', S.Contains('banana'));
    AssertTrue('Contains cherry', S.Contains('cherry'));
    AssertFalse('Does not contain date', S.Contains('date'));
    
    S.Remove('banana');
    AssertEquals('Count after remove', 2, S.Count);
    AssertFalse('banana removed', S.Contains('banana'));
  finally
    S.Free;
  end;
end;

// === 大数据集测试 ===

procedure TTestCase_HashSet_Full.Test_HashSet_LargeDataSet;
var
  S: TIntSet;
  i: Integer;
begin
  S := TIntSet.Create;
  try
    // 插入 10000 个元素
    for i := 0 to 9999 do
      S.Add(i);
    
    AssertEquals('Count should be 10000', 10000, S.Count);
    
    // 验证几个随机元素
    AssertTrue('Contains 0', S.Contains(0));
    AssertTrue('Contains 5000', S.Contains(5000));
    AssertTrue('Contains 9999', S.Contains(9999));
    AssertFalse('Does not contain 10000', S.Contains(10000));
  finally
    S.Free;
  end;
end;

procedure TTestCase_HashSet_Full.Test_HashSet_LargeRemove;
var
  S: TIntSet;
  i: Integer;
begin
  S := TIntSet.Create;
  try
    // 插入 10000 个元素
    for i := 0 to 9999 do
      S.Add(i);
    
    // 删除一半
    for i := 0 to 4999 do
      S.Remove(i);
    
    AssertEquals('Count after removes', 5000, S.Count);
    AssertFalse('0 removed', S.Contains(0));
    AssertFalse('4999 removed', S.Contains(4999));
    AssertTrue('5000 still exists', S.Contains(5000));
    AssertTrue('9999 still exists', S.Contains(9999));
  finally
    S.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_HashSet_Full);

end.
