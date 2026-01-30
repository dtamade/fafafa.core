unit Test_HashSet_SetOperations;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

{**
 * TDD 测试用例: HashSet 集合运算
 * 
 * 测试目标:
 * 1. Union - 并集
 * 2. Intersection - 交集
 * 3. Difference - 差集
 * 4. SymmetricDifference - 对称差集
 * 5. IsSubsetOf - 是否为子集
 * 6. IsSupersetOf - 是否为超集
 * 7. IsDisjoint - 是否不相交
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.hashmap;

type
  TIntHashSet = specialize THashSet<Integer>;
  TStrHashSet = specialize THashSet<String>;

  { TTestHashSetSetOperations }
  TTestHashSetSetOperations = class(TTestCase)
  published
    // === Union (并集) 测试 ===
    procedure Test_Union_TwoNonEmpty;
    procedure Test_Union_FirstEmpty;
    procedure Test_Union_SecondEmpty;
    procedure Test_Union_BothEmpty;
    procedure Test_Union_NoOverlap;
    procedure Test_Union_FullOverlap;
    
    // === Intersection (交集) 测试 ===
    procedure Test_Intersection_PartialOverlap;
    procedure Test_Intersection_FirstEmpty;
    procedure Test_Intersection_SecondEmpty;
    procedure Test_Intersection_NoOverlap;
    procedure Test_Intersection_FullOverlap;
    
    // === Difference (差集) 测试 ===
    procedure Test_Difference_PartialOverlap;
    procedure Test_Difference_FirstEmpty;
    procedure Test_Difference_SecondEmpty;
    procedure Test_Difference_NoOverlap;
    procedure Test_Difference_FullOverlap;
    
    // === SymmetricDifference (对称差集) 测试 ===
    procedure Test_SymmetricDifference_PartialOverlap;
    procedure Test_SymmetricDifference_NoOverlap;
    procedure Test_SymmetricDifference_FullOverlap;
    procedure Test_SymmetricDifference_Empty;
    
    // === IsSubsetOf (子集) 测试 ===
    procedure Test_IsSubsetOf_True;
    procedure Test_IsSubsetOf_False;
    procedure Test_IsSubsetOf_EmptyIsSubsetOfAny;
    procedure Test_IsSubsetOf_EqualSets;
    
    // === IsSupersetOf (超集) 测试 ===
    procedure Test_IsSupersetOf_True;
    procedure Test_IsSupersetOf_False;
    procedure Test_IsSupersetOf_AnyIsSupersetOfEmpty;
    procedure Test_IsSupersetOf_EqualSets;
    
    // === IsDisjoint (不相交) 测试 ===
    procedure Test_IsDisjoint_True;
    procedure Test_IsDisjoint_False;
    procedure Test_IsDisjoint_EmptySets;
    
    // === 综合/边界测试 ===
    procedure Test_LargeScale_SetOperations;
  end;

implementation

{ TTestHashSetSetOperations }

// === Union (并集) 测试 ===

procedure TTestHashSetSetOperations.Test_Union_TwoNonEmpty;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(3); B.Add(4); B.Add(5);
    
    Result := A.Union(B);
    try
      AssertEquals('Union count', 5, Result.Count);
      AssertTrue('Contains 1', Result.Contains(1));
      AssertTrue('Contains 2', Result.Contains(2));
      AssertTrue('Contains 3', Result.Contains(3));
      AssertTrue('Contains 4', Result.Contains(4));
      AssertTrue('Contains 5', Result.Contains(5));
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Union_FirstEmpty;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    // A is empty
    B.Add(1); B.Add(2);
    
    Result := A.Union(B);
    try
      AssertEquals('Union count', 2, Result.Count);
      AssertTrue('Contains 1', Result.Contains(1));
      AssertTrue('Contains 2', Result.Contains(2));
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Union_SecondEmpty;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    // B is empty
    
    Result := A.Union(B);
    try
      AssertEquals('Union count', 2, Result.Count);
      AssertTrue('Contains 1', Result.Contains(1));
      AssertTrue('Contains 2', Result.Contains(2));
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Union_BothEmpty;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    Result := A.Union(B);
    try
      AssertEquals('Union of empty sets', 0, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Union_NoOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    B.Add(3); B.Add(4);
    
    Result := A.Union(B);
    try
      AssertEquals('Union count', 4, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Union_FullOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(1); B.Add(2); B.Add(3);
    
    Result := A.Union(B);
    try
      AssertEquals('Union of identical sets', 3, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

// === Intersection (交集) 测试 ===

procedure TTestHashSetSetOperations.Test_Intersection_PartialOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(2); B.Add(3); B.Add(4);
    
    Result := A.Intersection(B);
    try
      AssertEquals('Intersection count', 2, Result.Count);
      AssertTrue('Contains 2', Result.Contains(2));
      AssertTrue('Contains 3', Result.Contains(3));
      AssertFalse('Not contains 1', Result.Contains(1));
      AssertFalse('Not contains 4', Result.Contains(4));
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Intersection_FirstEmpty;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    B.Add(1); B.Add(2);
    
    Result := A.Intersection(B);
    try
      AssertEquals('Intersection with empty', 0, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Intersection_SecondEmpty;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    
    Result := A.Intersection(B);
    try
      AssertEquals('Intersection with empty', 0, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Intersection_NoOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    B.Add(3); B.Add(4);
    
    Result := A.Intersection(B);
    try
      AssertEquals('No overlap intersection', 0, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Intersection_FullOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(1); B.Add(2); B.Add(3);
    
    Result := A.Intersection(B);
    try
      AssertEquals('Full overlap intersection', 3, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

// === Difference (差集) 测试 ===

procedure TTestHashSetSetOperations.Test_Difference_PartialOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(2); B.Add(3); B.Add(4);
    
    Result := A.Difference(B);
    try
      AssertEquals('Difference count', 1, Result.Count);
      AssertTrue('Contains 1', Result.Contains(1));
      AssertFalse('Not contains 2', Result.Contains(2));
      AssertFalse('Not contains 3', Result.Contains(3));
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Difference_FirstEmpty;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    B.Add(1); B.Add(2);
    
    Result := A.Difference(B);
    try
      AssertEquals('Empty - X = Empty', 0, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Difference_SecondEmpty;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    
    Result := A.Difference(B);
    try
      AssertEquals('X - Empty = X', 2, Result.Count);
      AssertTrue('Contains 1', Result.Contains(1));
      AssertTrue('Contains 2', Result.Contains(2));
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Difference_NoOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    B.Add(3); B.Add(4);
    
    Result := A.Difference(B);
    try
      AssertEquals('No overlap difference', 2, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_Difference_FullOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(1); B.Add(2); B.Add(3);
    
    Result := A.Difference(B);
    try
      AssertEquals('Full overlap difference', 0, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

// === SymmetricDifference (对称差集) 测试 ===

procedure TTestHashSetSetOperations.Test_SymmetricDifference_PartialOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(2); B.Add(3); B.Add(4);
    
    Result := A.SymmetricDifference(B);
    try
      AssertEquals('SymDiff count', 2, Result.Count);
      AssertTrue('Contains 1', Result.Contains(1));
      AssertTrue('Contains 4', Result.Contains(4));
      AssertFalse('Not contains 2', Result.Contains(2));
      AssertFalse('Not contains 3', Result.Contains(3));
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_SymmetricDifference_NoOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    B.Add(3); B.Add(4);
    
    Result := A.SymmetricDifference(B);
    try
      AssertEquals('No overlap sym diff', 4, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_SymmetricDifference_FullOverlap;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(1); B.Add(2); B.Add(3);
    
    Result := A.SymmetricDifference(B);
    try
      AssertEquals('Full overlap sym diff', 0, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_SymmetricDifference_Empty;
var
  A, B, Result: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    // B empty
    
    Result := A.SymmetricDifference(B);
    try
      AssertEquals('SymDiff with empty', 2, Result.Count);
    finally
      Result.Free;
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

// === IsSubsetOf (子集) 测试 ===

procedure TTestHashSetSetOperations.Test_IsSubsetOf_True;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(2); A.Add(3);
    B.Add(1); B.Add(2); B.Add(3); B.Add(4);
    
    AssertTrue('A is subset of B', A.IsSubsetOf(B));
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_IsSubsetOf_False;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(5);
    B.Add(1); B.Add(2); B.Add(3); B.Add(4);
    
    AssertFalse('A is not subset of B', A.IsSubsetOf(B));
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_IsSubsetOf_EmptyIsSubsetOfAny;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    // A is empty
    B.Add(1); B.Add(2);
    
    AssertTrue('Empty is subset of any', A.IsSubsetOf(B));
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_IsSubsetOf_EqualSets;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(1); B.Add(2); B.Add(3);
    
    AssertTrue('Equal sets are subsets', A.IsSubsetOf(B));
  finally
    A.Free;
    B.Free;
  end;
end;

// === IsSupersetOf (超集) 测试 ===

procedure TTestHashSetSetOperations.Test_IsSupersetOf_True;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3); A.Add(4);
    B.Add(2); B.Add(3);
    
    AssertTrue('A is superset of B', A.IsSupersetOf(B));
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_IsSupersetOf_False;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    B.Add(2); B.Add(3);
    
    AssertFalse('A is not superset of B', A.IsSupersetOf(B));
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_IsSupersetOf_AnyIsSupersetOfEmpty;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    // B is empty
    
    AssertTrue('Any is superset of empty', A.IsSupersetOf(B));
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_IsSupersetOf_EqualSets;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(1); B.Add(2); B.Add(3);
    
    AssertTrue('Equal sets are supersets', A.IsSupersetOf(B));
  finally
    A.Free;
    B.Free;
  end;
end;

// === IsDisjoint (不相交) 测试 ===

procedure TTestHashSetSetOperations.Test_IsDisjoint_True;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2);
    B.Add(3); B.Add(4);
    
    AssertTrue('Disjoint sets', A.IsDisjoint(B));
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_IsDisjoint_False;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    A.Add(1); A.Add(2); A.Add(3);
    B.Add(3); B.Add(4);
    
    AssertFalse('Not disjoint sets', A.IsDisjoint(B));
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TTestHashSetSetOperations.Test_IsDisjoint_EmptySets;
var
  A, B: TIntHashSet;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    // Both empty
    AssertTrue('Empty sets are disjoint', A.IsDisjoint(B));
  finally
    A.Free;
    B.Free;
  end;
end;

// === 综合/边界测试 ===

procedure TTestHashSetSetOperations.Test_LargeScale_SetOperations;
var
  A, B, Result: TIntHashSet;
  i: Integer;
begin
  A := TIntHashSet.Create;
  B := TIntHashSet.Create;
  try
    // A: 0-999 (偶数)
    for i := 0 to 499 do
      A.Add(i * 2);
      
    // B: 0-999 (奇数 + 一些偶数)
    for i := 0 to 499 do
      B.Add(i * 2 + 1);
    for i := 0 to 99 do
      B.Add(i * 2);  // 前100个偶数
    
    // 测试并集
    Result := A.Union(B);
    try
      AssertEquals('Union large', 1000, Result.Count);
    finally
      Result.Free;
    end;
    
    // 测试交集
    Result := A.Intersection(B);
    try
      AssertEquals('Intersection large', 100, Result.Count);
    finally
      Result.Free;
    end;
    
    // 测试差集
    Result := A.Difference(B);
    try
      AssertEquals('Difference large', 400, Result.Count);
    finally
      Result.Free;
    end;
    
  finally
    A.Free;
    B.Free;
  end;
end;

initialization
  RegisterTest(TTestHashSetSetOperations);

end.
