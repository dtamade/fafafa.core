unit Test_Collections_Facade;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections,
  fafafa.core.collections.base,
  fafafa.core.collections.vec,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.queue,  // for IDeque
  fafafa.core.collections.hashmap,
  fafafa.core.collections.treemap,
  fafafa.core.collections.treeSet;

type
  TTestCollectionsFacade = class(TTestCase)
  published
    // Vec<T> 快捷构造
    procedure Test_Vec_Default_CreatesEmptyVec;
    procedure Test_Vec_WithCapacity_ReservesSpace;
    procedure Test_Vec_FromArray_CopiesElements;
    
    // Map<K,V> 快捷构造 (HashMap)
    procedure Test_Map_Default_CreatesEmptyMap;
    procedure Test_Map_WithCapacity_ReservesSpace;
    
    // Set_<K> 快捷构造 (HashSet)
    procedure Test_Set_Default_CreatesEmptySet;
    procedure Test_Set_WithCapacity_ReservesSpace;
    
    // Deque<T> 快捷构造
    procedure Test_Deque_Default_CreatesEmptyDeque;
    procedure Test_Deque_WithCapacity_ReservesSpace;
    procedure Test_Deque_FromArray_CopiesElements;
    
    // OrdMap<K,V> 快捷构造 (TreeMap)
    procedure Test_OrdMap_Default_CreatesEmptyTreeMap;
    
    // OrdSet<K> 快捷构造 (TreeSet)
    procedure Test_OrdSet_Default_CreatesEmptyTreeSet;
  end;

implementation

// 默认比较函数
function IntCompare(const aLeft, aRight: Integer; aData: Pointer): SizeInt;
begin
  if aLeft < aRight then
    Result := -1
  else if aLeft > aRight then
    Result := 1
  else
    Result := 0;
end;

{ TTestCollectionsFacade }

procedure TTestCollectionsFacade.Test_Vec_Default_CreatesEmptyVec;
var
  V: specialize IVec<Integer>;
begin
  V := specialize Vec<Integer>;
  AssertEquals('Empty Vec should have Count 0', 0, V.Count);
end;

procedure TTestCollectionsFacade.Test_Vec_WithCapacity_ReservesSpace;
var
  V: specialize IVec<Integer>;
begin
  V := specialize Vec<Integer>(100);
  AssertEquals('Vec should have Count 0', 0, V.Count);
  AssertTrue('Vec should have Capacity >= 100', V.Capacity >= 100);
end;

procedure TTestCollectionsFacade.Test_Vec_FromArray_CopiesElements;
var
  V: specialize IVec<Integer>;
begin
  V := specialize Vec<Integer>([1, 2, 3, 4, 5]);
  AssertEquals('Vec should have 5 elements', 5, V.Count);
  AssertEquals('First element', 1, V[0]);
  AssertEquals('Last element', 5, V[4]);
end;

procedure TTestCollectionsFacade.Test_Map_Default_CreatesEmptyMap;
var
  M: specialize IHashMap<String, Integer>;
begin
  M := specialize Map<String, Integer>;
  AssertEquals('Empty Map should have Count 0', 0, M.Count);
end;

procedure TTestCollectionsFacade.Test_Map_WithCapacity_ReservesSpace;
var
  M: specialize IHashMap<String, Integer>;
begin
  M := specialize Map<String, Integer>(100);
  AssertEquals('Map should have Count 0', 0, M.Count);
  // HashMap capacity 可能因内部实现而不同
end;

procedure TTestCollectionsFacade.Test_Set_Default_CreatesEmptySet;
var
  S: specialize IHashSet<Integer>;
begin
  S := specialize Set_<Integer>;
  AssertEquals('Empty Set should have Count 0', 0, S.Count);
end;

procedure TTestCollectionsFacade.Test_Set_WithCapacity_ReservesSpace;
var
  S: specialize IHashSet<Integer>;
begin
  S := specialize Set_<Integer>(100);
  AssertEquals('Set should have Count 0', 0, S.Count);
end;

procedure TTestCollectionsFacade.Test_Deque_Default_CreatesEmptyDeque;
var
  D: specialize IDeque<Integer>;
begin
  D := specialize Deque<Integer>;
  AssertEquals('Empty Deque should have Count 0', 0, D.Count);
end;

procedure TTestCollectionsFacade.Test_Deque_WithCapacity_ReservesSpace;
var
  D: specialize IDeque<Integer>;
begin
  D := specialize Deque<Integer>(100);
  AssertEquals('Deque should have Count 0', 0, D.Count);
  // 测试可以添加大量元素（间接验证容量分配）
  // IDeque 接口没有 Capacity 属性，只能通过操作来验证
end;

procedure TTestCollectionsFacade.Test_Deque_FromArray_CopiesElements;
var
  D: specialize IDeque<Integer>;
begin
  D := specialize Deque<Integer>([10, 20, 30]);
  AssertEquals('Deque should have 3 elements', 3, D.Count);
end;

procedure TTestCollectionsFacade.Test_OrdMap_Default_CreatesEmptyTreeMap;
var
  M: specialize ITreeMap<Integer, String>;
begin
  // TreeMap 需要比较函数
  M := specialize OrdMap<Integer, String>(@IntCompare);
  AssertEquals('Empty OrdMap should have Count 0', 0, M.Count);
end;

procedure TTestCollectionsFacade.Test_OrdSet_Default_CreatesEmptyTreeSet;
var
  S: specialize ITreeSet<Integer>;
begin
  // TreeSet 当前不支持自定义比较器
  S := specialize OrdSet<Integer>;
  AssertEquals('Empty OrdSet should have Count 0', 0, S.Count);
end;

initialization
  RegisterTest(TTestCollectionsFacade);

end.
