program test_multimap;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.base, fafafa.core.collections.multimap;

type
  TIntStrMultiMap = specialize TMultiMap<Integer, string>;
  TStrIntMultiMap = specialize TMultiMap<string, Integer>;

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;

procedure Assert(Condition: Boolean; const Msg: string);
begin
  Inc(TestCount);
  if not Condition then
  begin
    WriteLn('[FAIL] ', Msg);
    Halt(1);
  end
  else
  begin
    Inc(PassCount);
    WriteLn('[PASS] ', Msg);
  end;
end;

procedure TestBasicOperations;
var
  M: TIntStrMultiMap;
  Values: array of string;
begin
  WriteLn('=== TestBasicOperations ===');
  M := TIntStrMultiMap.Create;
  try
    // Test empty state
    Assert(M.IsEmpty, 'New map should be empty');
    Assert(M.KeyCount = 0, 'New map should have 0 keys');
    Assert(M.TotalCount = 0, 'New map should have 0 total values');

    // Test Add
    M.Add(1, 'one');
    Assert(not M.IsEmpty, 'Map should not be empty after Add');
    Assert(M.KeyCount = 1, 'Should have 1 key');
    Assert(M.TotalCount = 1, 'Should have 1 total value');
    Assert(M.Contains(1), 'Should contain key 1');

    // Add multiple values for same key
    M.Add(1, 'uno');
    M.Add(1, 'eins');
    Assert(M.KeyCount = 1, 'Should still have 1 key');
    Assert(M.TotalCount = 3, 'Should have 3 total values');
    Assert(M.GetValueCount(1) = 3, 'Key 1 should have 3 values');

    // Get values
    Values := M.GetValues(1);
    Assert(Length(Values) = 3, 'GetValues should return 3 values');
    Assert((Values[0] = 'one') and (Values[1] = 'uno') and (Values[2] = 'eins'),
           'Values should match insertion order');

    // Add different key
    M.Add(2, 'two');
    Assert(M.KeyCount = 2, 'Should have 2 keys');
    Assert(M.TotalCount = 4, 'Should have 4 total values');

    // Test ContainsValue
    Assert(M.ContainsValue(1, 'uno'), 'Should find value uno for key 1');
    Assert(not M.ContainsValue(1, 'two'), 'Should not find value two for key 1');
    Assert(not M.ContainsValue(3, 'any'), 'Should not find non-existent key');
  finally
    M.Free;
  end;
end;

procedure TestRemove;
var
  M: TIntStrMultiMap;
  Values: array of string;
  RemovedCount: SizeUInt;
begin
  WriteLn('=== TestRemove ===');
  M := TIntStrMultiMap.Create;
  try
    // Setup
    M.Add(1, 'a');
    M.Add(1, 'b');
    M.Add(1, 'c');
    M.Add(2, 'x');
    Assert(M.TotalCount = 4, 'Should have 4 total values');

    // Remove specific value
    Assert(M.Remove(1, 'b'), 'Should successfully remove value b');
    Assert(M.TotalCount = 3, 'Should have 3 total values after remove');
    Assert(not M.ContainsValue(1, 'b'), 'Should not find removed value');
    Values := M.GetValues(1);
    Assert(Length(Values) = 2, 'Key 1 should have 2 values');

    // Remove non-existent value
    Assert(not M.Remove(1, 'z'), 'Should return False for non-existent value');
    Assert(M.TotalCount = 3, 'Total count should not change');

    // Remove last value of a key
    M.Remove(1, 'a');
    M.Remove(1, 'c');
    Assert(not M.Contains(1), 'Key 1 should be removed when no values left');
    Assert(M.KeyCount = 1, 'Should have 1 key left');

    // RemoveAll
    M.Add(3, 'p');
    M.Add(3, 'q');
    M.Add(3, 'r');
    RemovedCount := M.RemoveAll(3);
    Assert(RemovedCount = 3, 'RemoveAll should return 3');
    Assert(not M.Contains(3), 'Key 3 should be removed');
  finally
    M.Free;
  end;
end;

procedure TestTryGetValues;
var
  M: TIntStrMultiMap;
  Values: array of string;
begin
  WriteLn('=== TestTryGetValues ===');
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'first');
    M.Add(1, 'second');

    Assert(M.TryGetValues(1, Values), 'TryGetValues should return True for existing key');
    Assert(Length(Values) = 2, 'Should get 2 values');

    Assert(not M.TryGetValues(999, Values), 'TryGetValues should return False for non-existent key');
    Assert(Length(Values) = 0, 'Should get empty array for non-existent key');
  finally
    M.Free;
  end;
end;

procedure TestGetKeys;
var
  M: TIntStrMultiMap;
  Keys: array of Integer;
begin
  WriteLn('=== TestGetKeys ===');
  M := TIntStrMultiMap.Create;
  try
    Assert(Length(M.GetKeys) = 0, 'Empty map should return empty key array');

    M.Add(1, 'a');
    M.Add(2, 'b');
    M.Add(3, 'c');

    Keys := M.GetKeys;
    Assert(Length(Keys) = 3, 'Should get 3 keys');
    // Note: key order is not guaranteed in HashMap
  finally
    M.Free;
  end;
end;

procedure TestClear;
var
  M: TIntStrMultiMap;
begin
  WriteLn('=== TestClear ===');
  M := TIntStrMultiMap.Create;
  try
    M.Add(1, 'a');
    M.Add(1, 'b');
    M.Add(2, 'c');
    Assert(M.TotalCount = 3, 'Should have 3 total values');

    M.Clear;
    Assert(M.IsEmpty, 'Map should be empty after Clear');
    Assert(M.KeyCount = 0, 'Should have 0 keys after Clear');
    Assert(M.TotalCount = 0, 'Should have 0 total values after Clear');

    // Can still use after Clear
    M.Add(5, 'new');
    Assert(M.KeyCount = 1, 'Should be able to add after Clear');
  finally
    M.Free;
  end;
end;

procedure TestStringKeys;
var
  M: TStrIntMultiMap;
  Values: array of Integer;
begin
  WriteLn('=== TestStringKeys ===');
  M := TStrIntMultiMap.Create;
  try
    M.Add('tag', 1);
    M.Add('tag', 2);
    M.Add('tag', 3);
    M.Add('label', 10);

    Assert(M.KeyCount = 2, 'Should have 2 string keys');
    Assert(M.GetValueCount('tag') = 3, 'tag should have 3 values');

    Values := M.GetValues('tag');
    Assert((Values[0] = 1) and (Values[1] = 2) and (Values[2] = 3),
           'Integer values should match');

    Assert(M.Remove('tag', 2), 'Should remove value 2 from tag');
    Assert(M.GetValueCount('tag') = 2, 'tag should have 2 values after remove');
  finally
    M.Free;
  end;
end;

procedure TestDuplicateValues;
var
  M: TIntStrMultiMap;
  Values: array of string;
begin
  WriteLn('=== TestDuplicateValues ===');
  M := TIntStrMultiMap.Create;
  try
    // MultiMap allows duplicate values for same key
    M.Add(1, 'dup');
    M.Add(1, 'dup');
    M.Add(1, 'dup');

    Assert(M.GetValueCount(1) = 3, 'Should allow duplicate values');

    // Remove only removes first match
    M.Remove(1, 'dup');
    Assert(M.GetValueCount(1) = 2, 'Should remove only one duplicate');

    Values := M.GetValues(1);
    Assert((Values[0] = 'dup') and (Values[1] = 'dup'),
           'Remaining duplicates should still exist');
  finally
    M.Free;
  end;
end;

procedure TestLargeDataset;
var
  M: TIntStrMultiMap;
  i, j: Integer;
  Values: array of string;
begin
  WriteLn('=== TestLargeDataset ===');
  M := TIntStrMultiMap.Create;
  try
    // Add many keys with multiple values each
    for i := 1 to 100 do
    begin
      for j := 1 to 10 do
        M.Add(i, 'value_' + IntToStr(j));
    end;

    Assert(M.KeyCount = 100, 'Should have 100 keys');
    Assert(M.TotalCount = 1000, 'Should have 1000 total values');

    // Verify specific key
    Assert(M.GetValueCount(50) = 10, 'Key 50 should have 10 values');
    Values := M.GetValues(50);
    Assert(Values[0] = 'value_1', 'First value should be correct');

    // Remove all for one key
    Assert(M.RemoveAll(50) = 10, 'Should remove 10 values');
    Assert(M.KeyCount = 99, 'Should have 99 keys');
    Assert(M.TotalCount = 990, 'Should have 990 total values');
  finally
    M.Free;
  end;
end;

begin
  WriteLn('Running TMultiMap<K,V> Tests...');
  WriteLn;

  TestBasicOperations;
  TestRemove;
  TestTryGetValues;
  TestGetKeys;
  TestClear;
  TestStringKeys;
  TestDuplicateValues;
  TestLargeDataset;

  WriteLn;
  WriteLn('========================================');
  WriteLn('Test Summary: ', PassCount, '/', TestCount, ' passed');

  if PassCount = TestCount then
  begin
    WriteLn('All tests PASSED!');
    Halt(0);
  end
  else
  begin
    WriteLn('Some tests FAILED!');
    Halt(1);
  end;
end.
