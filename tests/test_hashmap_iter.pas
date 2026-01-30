program test_hashmap_iter;
{**
 * test_hashmap_iter.pas
 * 测试 HashMap/HashSet 的迭代器功能
 * 
 * 此测试验证通过 IGenericCollection 接口使用 ForEach/Contains/CountOf 等方法时
 * HashMap/HashSet 能正常工作（修复 PtrIter 返回空值导致的崩溃问题）
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.hashmap;

type
  TIntStrMap = specialize THashMap<Integer, string>;
  TIntStrEntry = specialize TMapEntry<Integer, string>;
  TIntSet = specialize THashSet<Integer>;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Check(aCondition: Boolean; const aTestName: string);
begin
  if aCondition then
  begin
    Inc(TestsPassed);
    WriteLn('[PASS] ', aTestName);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('[FAIL] ', aTestName);
  end;
end;

// ========== HashMap 迭代器测试 ==========

procedure Test_HashMap_PtrIter_NotNil;
var
  map: TIntStrMap;
  iter: TPtrIter;
begin
  map := TIntStrMap.Create(4);
  try
    map.Add(1, 'one');
    iter := map.PtrIter;
    // PtrIter 返回的迭代器应该有效，不应该是全零
    Check(iter.Owner <> nil, 'HashMap_PtrIter_NotNil: Owner should not be nil');
  finally
    map.Free;
  end;
end;

procedure Test_HashMap_Iter_MoveNext;
var
  map: TIntStrMap;
  iter: specialize TIter<TIntStrEntry>;
  count: Integer;
begin
  map := TIntStrMap.Create(4);
  try
    map.Add(1, 'one');
    map.Add(2, 'two');
    map.Add(3, 'three');
    
    iter := map.Iter;
    count := 0;
    while iter.MoveNext do
      Inc(count);
    
    Check(count = 3, 'HashMap_Iter_MoveNext: should iterate 3 elements');
  finally
    map.Free;
  end;
end;

function SumMapKeys(const aEntry: TIntStrEntry; aData: Pointer): Boolean;
begin
  PInteger(aData)^ := PInteger(aData)^ + aEntry.Key;
  Result := True; // 继续迭代
end;

procedure Test_HashMap_ForEach_Func;
var
  map: TIntStrMap;
  sum: Integer;
begin
  map := TIntStrMap.Create(4);
  try
    map.Add(1, 'one');
    map.Add(2, 'two');
    map.Add(3, 'three');
    
    sum := 0;
    map.ForEach(@SumMapKeys, @sum);
    
    Check(sum = 6, 'HashMap_ForEach_Func: sum of keys should be 6 (1+2+3)');
  finally
    map.Free;
  end;
end;

procedure Test_HashMap_CountOf;
type
  TIntIntMap = specialize THashMap<Integer, Integer>;
  TIntIntEntry = specialize TMapEntry<Integer, Integer>;
var
  map: TIntIntMap;
  entry: TIntIntEntry;
  cnt: SizeUInt;
begin
  // 使用简单类型避免字符串比较问题
  map := TIntIntMap.Create(4);
  try
    map.Add(1, 100);
    map.Add(2, 200);
    map.Add(3, 300);
    
    entry.Key := 2;
    entry.Value := 200;
    cnt := map.CountOf(entry);
    
    Check(cnt = 1, 'HashMap_CountOf: should find exactly 1 matching entry');
  finally
    map.Free;
  end;
end;

procedure Test_HashMap_ToArray;
var
  map: TIntStrMap;
  arr: specialize TGenericArray<TIntStrEntry>;
begin
  map := TIntStrMap.Create(4);
  try
    map.Add(1, 'one');
    map.Add(2, 'two');
    
    arr := map.ToArray;
    
    Check(Length(arr) = 2, 'HashMap_ToArray: should return array with 2 elements');
  finally
    map.Free;
  end;
end;

// ========== HashSet 迭代器测试 ==========

procedure Test_HashSet_PtrIter_NotNil;
var
  s: TIntSet;
  iter: TPtrIter;
begin
  s := TIntSet.Create(4);
  try
    s.Add(1);
    iter := s.PtrIter;
    Check(iter.Owner <> nil, 'HashSet_PtrIter_NotNil: Owner should not be nil');
  finally
    s.Free;
  end;
end;

procedure Test_HashSet_Iter_MoveNext;
var
  s: TIntSet;
  iter: specialize TIter<Integer>;
  count: Integer;
begin
  s := TIntSet.Create(4);
  try
    s.Add(1);
    s.Add(2);
    s.Add(3);
    
    iter := s.Iter;
    count := 0;
    while iter.MoveNext do
      Inc(count);
    
    Check(count = 3, 'HashSet_Iter_MoveNext: should iterate 3 elements');
  finally
    s.Free;
  end;
end;

function SumSetValues(const aValue: Integer; aData: Pointer): Boolean;
begin
  PInteger(aData)^ := PInteger(aData)^ + aValue;
  Result := True;
end;

procedure Test_HashSet_ForEach_Func;
var
  s: TIntSet;
  sum: Integer;
begin
  s := TIntSet.Create(4);
  try
    s.Add(1);
    s.Add(2);
    s.Add(3);
    
    sum := 0;
    s.ForEach(@SumSetValues, @sum);
    
    Check(sum = 6, 'HashSet_ForEach_Func: sum should be 6 (1+2+3)');
  finally
    s.Free;
  end;
end;

procedure Test_HashSet_ToArray;
var
  s: TIntSet;
  arr: specialize TGenericArray<Integer>;
begin
  s := TIntSet.Create(4);
  try
    s.Add(10);
    s.Add(20);
    s.Add(30);
    
    arr := s.ToArray;
    
    Check(Length(arr) = 3, 'HashSet_ToArray: should return array with 3 elements');
  finally
    s.Free;
  end;
end;

// ========== 空集合边界测试 ==========

procedure Test_HashMap_Empty_Iter;
var
  map: TIntStrMap;
  iter: specialize TIter<TIntStrEntry>;
  count: Integer;
begin
  map := TIntStrMap.Create(4);
  try
    iter := map.Iter;
    count := 0;
    while iter.MoveNext do
      Inc(count);
    
    Check(count = 0, 'HashMap_Empty_Iter: empty map should iterate 0 elements');
  finally
    map.Free;
  end;
end;

procedure Test_HashSet_Empty_Iter;
var
  s: TIntSet;
  iter: specialize TIter<Integer>;
  count: Integer;
begin
  s := TIntSet.Create(4);
  try
    iter := s.Iter;
    count := 0;
    while iter.MoveNext do
      Inc(count);
    
    Check(count = 0, 'HashSet_Empty_Iter: empty set should iterate 0 elements');
  finally
    s.Free;
  end;
end;

begin
  WriteLn('=== HashMap/HashSet Iterator Tests ===');
  WriteLn;
  
  // HashMap 测试
  WriteLn('-- HashMap Tests --');
  Test_HashMap_PtrIter_NotNil;
  Test_HashMap_Iter_MoveNext;
  Test_HashMap_ForEach_Func;
  Test_HashMap_CountOf;
  Test_HashMap_ToArray;
  Test_HashMap_Empty_Iter;
  
  WriteLn;
  
  // HashSet 测试
  WriteLn('-- HashSet Tests --');
  Test_HashSet_PtrIter_NotNil;
  Test_HashSet_Iter_MoveNext;
  Test_HashSet_ForEach_Func;
  Test_HashSet_ToArray;
  Test_HashSet_Empty_Iter;
  
  WriteLn;
  WriteLn('=== Results ===');
  WriteLn('Passed: ', TestsPassed);
  WriteLn('Failed: ', TestsFailed);
  
  if TestsFailed > 0 then
    ExitCode := 1
  else
    ExitCode := 0;
end.
