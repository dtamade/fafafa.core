unit TestTreeSet;

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}
{$modeswitch typehelpers}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.treeSet;

type
  TTestTreeSet = class(TTestCase)
  published
    // 基础功能测试
    procedure Test_Create_EmptySet_Success;
    procedure Test_Add_SingleElement_ContainsElement;
    procedure Test_Add_DuplicateElement_RemainsOne;
    procedure Test_Remove_ExistingElement_Success;
    procedure Test_Remove_NonExistingElement_NoChange;
    
    // 排序与遍历测试
    procedure Test_Iterator_EmptySet_NoElements;
    procedure Test_Iterator_MultipleElements_InOrder;
    procedure Test_ToArray_MultipleElements_Sorted;
    
    // 集合操作测试
    procedure Test_Union_TwoSets_CorrectUnion;
    procedure Test_Intersect_TwoSets_CorrectIntersection;
    procedure Test_Difference_TwoSets_CorrectDifference;
    
    // 边界条件测试
    procedure Test_Add_ManyElements_MaintainsOrder;
    procedure Test_Clear_NonEmptySet_BecomesEmpty;
  end;

implementation

{ TTestTreeSet }

procedure TTestTreeSet.Test_Create_EmptySet_Success;
var
  TreeSet: specialize TTreeSet<Integer>;
begin
  TreeSet := specialize TTreeSet<Integer>.Create;
  try
    AssertEquals('New TreeSet should be empty', 0, TreeSet.GetCount);
    AssertTrue('New TreeSet should report IsEmpty', TreeSet.IsEmpty);
  finally
    TreeSet.Free;
  end;
end;

procedure TTestTreeSet.Test_Add_SingleElement_ContainsElement;
var
  TreeSet: specialize TTreeSet<Integer>;
begin
  TreeSet := specialize TTreeSet<Integer>.Create;
  try
    TreeSet.Add(42);
    AssertEquals('Count should be 1', 1, TreeSet.GetCount);
    AssertTrue('Should contain 42', TreeSet.Contains(42));
    AssertFalse('Should not contain 99', TreeSet.Contains(99));
  finally
    TreeSet.Free;
  end;
end;

procedure TTestTreeSet.Test_Add_DuplicateElement_RemainsOne;
var
  TreeSet: specialize TTreeSet<Integer>;
begin
  TreeSet := specialize TTreeSet<Integer>.Create;
  try
    TreeSet.Add(42);
    TreeSet.Add(42);
    TreeSet.Add(42);
    AssertEquals('Count should remain 1 after adding duplicates', 1, TreeSet.GetCount);
  finally
    TreeSet.Free;
  end;
end;

procedure TTestTreeSet.Test_Remove_ExistingElement_Success;
var
  TreeSet: specialize TTreeSet<Integer>;
begin
  TreeSet := specialize TTreeSet<Integer>.Create;
  try
    TreeSet.Add(10);
    TreeSet.Add(20);
    TreeSet.Add(30);
    
    AssertTrue('Should remove 20', TreeSet.Remove(20));
    AssertEquals('Count should be 2', 2, TreeSet.GetCount);
    AssertFalse('Should not contain 20', TreeSet.Contains(20));
    AssertTrue('Should still contain 10', TreeSet.Contains(10));
    AssertTrue('Should still contain 30', TreeSet.Contains(30));
  finally
    TreeSet.Free;
  end;
end;

procedure TTestTreeSet.Test_Remove_NonExistingElement_NoChange;
var
  TreeSet: specialize TTreeSet<Integer>;
begin
  TreeSet := specialize TTreeSet<Integer>.Create;
  try
    TreeSet.Add(10);
    TreeSet.Add(20);
    
    AssertFalse('Should return False for non-existing element', TreeSet.Remove(99));
    AssertEquals('Count should remain 2', 2, TreeSet.GetCount);
  finally
    TreeSet.Free;
  end;
end;

procedure TTestTreeSet.Test_Iterator_EmptySet_NoElements;
var
  TreeSet: specialize TTreeSet<Integer>;
  Count: Integer;
  Element: Integer;
begin
  TreeSet := specialize TTreeSet<Integer>.Create;
  try
    Count := 0;
    for Element in TreeSet do
      Inc(Count);
    AssertEquals('Empty set should have 0 elements in iteration', 0, Count);
  finally
    TreeSet.Free;
  end;
end;

procedure TTestTreeSet.Test_Iterator_MultipleElements_InOrder;
var
  TreeSet: specialize TTreeSet<Integer>;
  Element: Integer;
  Expected: array[0..4] of Integer = (10, 20, 30, 40, 50);
  Index: Integer;
begin
  TreeSet := specialize TTreeSet<Integer>.Create;
  try
    // 乱序添加
    TreeSet.Add(30);
    TreeSet.Add(10);
    TreeSet.Add(50);
    TreeSet.Add(20);
    TreeSet.Add(40);
    
    Index := 0;
    for Element in TreeSet do
    begin
      AssertEquals('Element should be in sorted order', Expected[Index], Element);
      Inc(Index);
    end;
    AssertEquals('Should iterate through all 5 elements', 5, Index);
  finally
    TreeSet.Free;
  end;
end;

procedure TTestTreeSet.Test_ToArray_MultipleElements_Sorted;
var
  TreeSet: specialize TTreeSet<Integer>;
  Arr: specialize TArray<Integer>;
begin
  TreeSet := specialize TTreeSet<Integer>.Create;
  try
    TreeSet.Add(30);
    TreeSet.Add(10);
    TreeSet.Add(50);
    TreeSet.Add(20);
    TreeSet.Add(40);
    
    Arr := TreeSet.ToArray;
    AssertEquals('Array length should be 5', 5, Length(Arr));
    AssertEquals('Array[0] should be 10', 10, Arr[0]);
    AssertEquals('Array[1] should be 20', 20, Arr[1]);
    AssertEquals('Array[2] should be 30', 30, Arr[2]);
    AssertEquals('Array[3] should be 40', 40, Arr[3]);
    AssertEquals('Array[4] should be 50', 50, Arr[4]);
  finally
    TreeSet.Free;
  end;
end;

procedure TTestTreeSet.Test_Union_TwoSets_CorrectUnion;
var
  Set1, Set2: specialize TTreeSet<Integer>;
  UnionSet: specialize ITreeSet<Integer>;
begin
  Set1 := specialize TTreeSet<Integer>.Create;
  Set2 := specialize TTreeSet<Integer>.Create;
  try
    Set1.Add(10);
    Set1.Add(20);
    Set1.Add(30);
    
    Set2.Add(20);
    Set2.Add(30);
    Set2.Add(40);
    
    UnionSet := Set1.Union(Set2);
    AssertEquals('Union should have 4 elements', 4, UnionSet.GetCount);
    AssertTrue('Union should contain 10', UnionSet.Contains(10));
    AssertTrue('Union should contain 20', UnionSet.Contains(20));
    AssertTrue('Union should contain 30', UnionSet.Contains(30));
    AssertTrue('Union should contain 40', UnionSet.Contains(40));
  finally
    Set1.Free;
    Set2.Free;
  end;
end;

procedure TTestTreeSet.Test_Intersect_TwoSets_CorrectIntersection;
var
  Set1, Set2: specialize TTreeSet<Integer>;
  IntersectSet: specialize ITreeSet<Integer>;
begin
  Set1 := specialize TTreeSet<Integer>.Create;
  Set2 := specialize TTreeSet<Integer>.Create;
  try
    Set1.Add(10);
    Set1.Add(20);
    Set1.Add(30);
    
    Set2.Add(20);
    Set2.Add(30);
    Set2.Add(40);
    
    IntersectSet := Set1.Intersect(Set2);
    AssertEquals('Intersection should have 2 elements', 2, IntersectSet.GetCount);
    AssertTrue('Intersection should contain 20', IntersectSet.Contains(20));
    AssertTrue('Intersection should contain 30', IntersectSet.Contains(30));
    AssertFalse('Intersection should not contain 10', IntersectSet.Contains(10));
    AssertFalse('Intersection should not contain 40', IntersectSet.Contains(40));
  finally
    Set1.Free;
    Set2.Free;
  end;
end;

procedure TTestTreeSet.Test_Difference_TwoSets_CorrectDifference;
var
  Set1, Set2: specialize TTreeSet<Integer>;
  DiffSet: specialize ITreeSet<Integer>;
begin
  Set1 := specialize TTreeSet<Integer>.Create;
  Set2 := specialize TTreeSet<Integer>.Create;
  try
    Set1.Add(10);
    Set1.Add(20);
    Set1.Add(30);
    
    Set2.Add(20);
    Set2.Add(30);
    Set2.Add(40);
    
    DiffSet := Set1.Difference(Set2);
    AssertEquals('Difference should have 1 element', 1, DiffSet.GetCount);
    AssertTrue('Difference should contain 10', DiffSet.Contains(10));
    AssertFalse('Difference should not contain 20', DiffSet.Contains(20));
    AssertFalse('Difference should not contain 30', DiffSet.Contains(30));
    AssertFalse('Difference should not contain 40', DiffSet.Contains(40));
  finally
    Set1.Free;
    Set2.Free;
  end;
end;

procedure TTestTreeSet.Test_Add_ManyElements_MaintainsOrder;
var
  TreeSet: specialize TTreeSet<Integer>;
  i: Integer;
  Arr: specialize TArray<Integer>;
begin
  TreeSet := specialize TTreeSet<Integer>.Create;
  try
    // 乱序添加 100 个元素
    for i := 99 downto 0 do
      TreeSet.Add(i);
    
    AssertEquals('Count should be 100', 100, TreeSet.GetCount);
    
    Arr := TreeSet.ToArray;
    for i := 0 to 99 do
      AssertEquals('Element should be in order', i, Arr[i]);
  finally
    TreeSet.Free;
  end;
end;

procedure TTestTreeSet.Test_Clear_NonEmptySet_BecomesEmpty;
var
  TreeSet: specialize TTreeSet<Integer>;
begin
  TreeSet := specialize TTreeSet<Integer>.Create;
  try
    TreeSet.Add(10);
    TreeSet.Add(20);
    TreeSet.Add(30);
    
    AssertEquals('Count should be 3', 3, TreeSet.GetCount);
    
    TreeSet.Clear;
    
    AssertEquals('Count should be 0 after Clear', 0, TreeSet.GetCount);
    AssertTrue('Should be empty after Clear', TreeSet.IsEmpty);
  finally
    TreeSet.Free;
  end;
end;

initialization
  RegisterTest(TTestTreeSet);

end.
