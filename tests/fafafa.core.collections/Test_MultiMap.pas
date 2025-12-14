unit Test_MultiMap;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

type
  TMultiMapTest = class(TTestCase)
  published
    // 基础操作
    procedure Test_Add_SingleKeyMultipleValues;
    procedure Test_Add_MultipleKeysSingleValue;
    procedure Test_GetValues_ExistingKey;
    procedure Test_GetValues_NonExistingKey;
    procedure Test_Contains_True;
    procedure Test_Contains_False;
    
    // 删除操作
    procedure Test_Remove_SingleValue;
    procedure Test_Remove_AllValuesForKey;
    procedure Test_RemoveAll_ExistingKey;
    procedure Test_Clear_EmptiesAll;
    
    // 计数操作
    procedure Test_TotalCount_TotalPairs;
    procedure Test_KeyCount_UniqueKeys;
    procedure Test_GetValueCount_ForKey;
    
    // 迭代
    procedure Test_GetKeys_UniqueKeys;
    procedure Test_ContainsValue_True;
    procedure Test_ContainsValue_False;
end;

implementation

uses
  fafafa.core.collections.multimap;

type
  TIntStrMultiMap = specialize TMultiMap<Integer, string>;

{ TMultiMapTest }

procedure TMultiMapTest.Test_Add_SingleKeyMultipleValues;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(1, 'b');
    M.Add(1, 'c');
    
    AssertEquals('Key count', 1, M.KeyCount);
    AssertEquals('Total count', 3, M.TotalCount);
    AssertEquals('Values for key 1', 3, M.GetValueCount(1));
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_Add_MultipleKeysSingleValue;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(2, 'b');
    M.Add(3, 'c');
    
    AssertEquals('Key count', 3, M.KeyCount);
    AssertEquals('Total count', 3, M.TotalCount);
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_GetValues_ExistingKey;
var
  M: TIntStrMultiMap;
  Values: array of string;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(1, 'b');
    M.Add(1, 'c');
    
    Values := M.GetValues(1);
    AssertEquals('Value count', 3, Length(Values));
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_GetValues_NonExistingKey;
var
  M: TIntStrMultiMap;
  Values: array of string;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    
    Values := M.GetValues(999);
    AssertEquals('Empty array for non-existing key', 0, Length(Values));
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_Contains_True;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(42, 'answer');
    
    AssertTrue('Contains key 42', M.Contains(42));
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_Contains_False;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    
    AssertFalse('Does not contain key 999', M.Contains(999));
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_Remove_SingleValue;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(1, 'b');
    M.Add(1, 'c');
    
    AssertTrue('Remove b', M.Remove(1, 'b'));
    AssertEquals('Value count after remove', 2, M.GetValueCount(1));
    AssertEquals('Total count', 2, M.TotalCount);
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_Remove_AllValuesForKey;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'only');
    
    AssertTrue('Remove only value', M.Remove(1, 'only'));
    AssertFalse('Key no longer exists', M.Contains(1));
    AssertEquals('Key count', 0, M.KeyCount);
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_RemoveAll_ExistingKey;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(1, 'b');
    M.Add(1, 'c');
    M.Add(2, 'x');
    
    AssertEquals('Removed count', 3, M.RemoveAll(1));
    AssertFalse('Key 1 no longer exists', M.Contains(1));
    AssertTrue('Key 2 still exists', M.Contains(2));
    AssertEquals('Total count', 1, M.TotalCount);
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_Clear_EmptiesAll;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(2, 'b');
    M.Add(3, 'c');
    
    M.Clear;
    
    AssertEquals('Count after clear', 0, M.TotalCount);
    AssertEquals('Key count after clear', 0, M.KeyCount);
    AssertTrue('IsEmpty', M.IsEmpty);
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_TotalCount_TotalPairs;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(1, 'b');
    M.Add(2, 'c');
    
    AssertEquals('Total pairs', 3, M.TotalCount);
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_KeyCount_UniqueKeys;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(1, 'b');
    M.Add(2, 'c');
    M.Add(2, 'd');
    M.Add(3, 'e');
    
    AssertEquals('Unique keys', 3, M.KeyCount);
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_GetValueCount_ForKey;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(1, 'b');
    M.Add(1, 'c');
    M.Add(2, 'x');
    
    AssertEquals('Values for key 1', 3, M.GetValueCount(1));
    AssertEquals('Values for key 2', 1, M.GetValueCount(2));
    AssertEquals('Values for non-existing key', 0, M.GetValueCount(999));
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_GetKeys_UniqueKeys;
var
  M: TIntStrMultiMap;
  Keys: array of Integer;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(1, 'b');
    M.Add(2, 'c');
    M.Add(3, 'd');
    
    Keys := M.GetKeys;
    AssertEquals('Unique key count', 3, Length(Keys));
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_ContainsValue_True;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(1, 'b');
    
    AssertTrue('Contains value a', M.ContainsValue(1, 'a'));
    AssertTrue('Contains value b', M.ContainsValue(1, 'b'));
  finally
    M.Free;
  end;
end;

procedure TMultiMapTest.Test_ContainsValue_False;
var
  M: TIntStrMultiMap;
begin
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    
    AssertFalse('Does not contain value z', M.ContainsValue(1, 'z'));
    AssertFalse('Non-existing key', M.ContainsValue(999, 'a'));
  finally
    M.Free;
  end;
end;

initialization
  RegisterTest(TMultiMapTest);

end.
