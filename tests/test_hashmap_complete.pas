program test_hashmap_complete;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

uses
  SysUtils,
  fafafa.core.collections.hashmap;

type
  TStringIntMap = specialize THashMap<string, Integer>;
  TIntStrMap = specialize THashMap<Integer, string>;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Pass(const TestName: string);
begin
  Inc(TestsPassed);
  WriteLn('[PASS] ', TestName);
end;

procedure Fail(const TestName, ErrorMsg: string);
begin
  Inc(TestsFailed);
  WriteLn('[FAIL] ', TestName);
  if ErrorMsg <> '' then
    WriteLn('       ', ErrorMsg);
end;

procedure TestBasicOperations;
var
  Map: TStringIntMap;
  Value: Integer;
begin
  WriteLn;
  WriteLn('=== Test Suite 1: Basic Operations ===');
  
  Map := TStringIntMap.Create(16, @HashOfAnsiString, nil);
  try
    // Test Add
    if Map.Add('hello', 42) then
      Pass('Add new key')
    else
      Fail('Add new key', 'Should return true');
      
    // Test TryGetValue
    if Map.TryGetValue('hello', Value) and (Value = 42) then
      Pass('TryGetValue')
    else
      Fail('TryGetValue', 'Expected 42');
      
    // Test ContainsKey
    if Map.ContainsKey('hello') then
      Pass('ContainsKey')
    else
      Fail('ContainsKey', 'Key should exist');
      
    // Test duplicate Add (should fail)
    if not Map.Add('hello', 100) then
      Pass('Add duplicate key returns false')
    else
      Fail('Add duplicate key returns false', 'Should return false');
      
    // Test AddOrAssign (update)
    if not Map.AddOrAssign('hello', 100) then
      Pass('AddOrAssign update')
    else
      Fail('AddOrAssign update', 'Should return false for update');
      
    if Map.TryGetValue('hello', Value) and (Value = 100) then
      Pass('Value updated by AddOrAssign')
    else
      Fail('Value updated by AddOrAssign', 'Expected 100');
      
    // Test Remove
    if Map.Remove('hello') then
      Pass('Remove existing key')
    else
      Fail('Remove existing key', 'Should return true');
      
    if not Map.ContainsKey('hello') then
      Pass('Key removed successfully')
    else
      Fail('Key removed successfully', 'Key should not exist');
      
    // Test Count
    Map.Clear;
    Map.Add('a', 1);
    Map.Add('b', 2);
    Map.Add('c', 3);
    
    if Map.Count = 3 then
      Pass('Count after multiple adds')
    else
      Fail('Count after multiple adds', Format('Expected 3, got %d', [Map.Count]));
      
    // Test Clear
    Map.Clear;
    if Map.Count = 0 then
      Pass('Clear')
    else
      Fail('Clear', Format('Expected 0, got %d', [Map.Count]));
      
  finally
    Map.Free;
  end;
end;

procedure TestIntegerKeys;
var
  Map: TIntStrMap;
  Value: string;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== Test Suite 2: Integer Keys (Auto Hash) ===');
  
  Map := TIntStrMap.Create(16);  // No hash function needed for integers
  try
    Map.AddOrAssign(1, 'one');
    Map.AddOrAssign(2, 'two');
    Map.AddOrAssign(3, 'three');
    
    if Map.Count = 3 then
      Pass('Multiple integer keys')
    else
      Fail('Multiple integer keys', Format('Expected 3, got %d', [Map.Count]));
      
    if Map.TryGetValue(2, Value) and (Value = 'two') then
      Pass('Retrieve integer key value')
    else
      Fail('Retrieve integer key value', 'Expected "two"');
      
    // Test many keys
    Map.Clear;
    for I := 1 to 100 do
      Map.AddOrAssign(I, Format('value%d', [I]));
      
    if Map.Count = 100 then
      Pass('100 keys insertion')
    else
      Fail('100 keys insertion', Format('Expected 100, got %d', [Map.Count]));
      
    // Verify all retrievable
    for I := 1 to 100 do
    begin
      if not (Map.TryGetValue(I, Value) and (Value = Format('value%d', [I]))) then
      begin
        Fail('Verify all 100 keys', Format('Failed at key %d', [I]));
        Exit;
      end;
    end;
    Pass('Verify all 100 keys');
    
  finally
    Map.Free;
  end;
end;

procedure TestResize;
var
  Map: TStringIntMap;
  I: Integer;
  Key: string;
  Value: Integer;
  InitialCap, FinalCap: SizeUInt;
begin
  WriteLn;
  WriteLn('=== Test Suite 3: Automatic Resizing ===');
  
  Map := TStringIntMap.Create(8, @HashOfAnsiString, nil);
  try
    InitialCap := Map.Capacity;
    WriteLn('  Initial capacity: ', InitialCap);
    
    // Insert enough to trigger resize
    for I := 1 to 50 do
    begin
      Key := Format('key%d', [I]);
      Map.AddOrAssign(Key, I * 100);
    end;
    
    FinalCap := Map.Capacity;
    WriteLn('  Final capacity: ', FinalCap);
    WriteLn('  Count: ', Map.Count);
    
    if FinalCap > InitialCap then
      Pass('Capacity increased')
    else
      Fail('Capacity increased', Format('Expected > %d, got %d', [InitialCap, FinalCap]));
      
    if Map.Count = 50 then
      Pass('All 50 keys retained')
    else
      Fail('All 50 keys retained', Format('Expected 50, got %d', [Map.Count]));
      
    // Verify all keys accessible
    for I := 1 to 50 do
    begin
      Key := Format('key%d', [I]);
      if not (Map.TryGetValue(Key, Value) and (Value = I * 100)) then
      begin
        Fail('Verify all keys after resize', Format('Failed at %s', [Key]));
        Exit;
      end;
    end;
    Pass('Verify all keys after resize');
    
  finally
    Map.Free;
  end;
end;

procedure TestReserve;
var
  Map: TStringIntMap;
begin
  WriteLn;
  WriteLn('=== Test Suite 4: Reserve ===');
  
  Map := TStringIntMap.Create(4, @HashOfAnsiString, nil);
  try
    WriteLn('  Initial capacity: ', Map.Capacity);
    
    Map.Reserve(100);
    WriteLn('  After Reserve(100): ', Map.Capacity);
    
    if Map.Capacity >= 100 then
      Pass('Reserve increases capacity')
    else
      Fail('Reserve increases capacity', Format('Expected >= 100, got %d', [Map.Capacity]));
      
  finally
    Map.Free;
  end;
end;

procedure TestLoadFactor;
var
  Map: TStringIntMap;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== Test Suite 5: Load Factor ===');
  
  Map := TStringIntMap.Create(8, @HashOfAnsiString, nil);
  try
    WriteLn('  Initial load factor: ', Map.LoadFactor:0:3);
    
    for I := 1 to 4 do
      Map.AddOrAssign(Format('key%d', [I]), I);
      
    WriteLn('  After 4 inserts (cap=8): ', Map.LoadFactor:0:3);
    
    if (Map.LoadFactor >= 0.4) and (Map.LoadFactor <= 0.6) then
      Pass('Load factor in expected range')
    else
      Fail('Load factor in expected range', Format('Got %f', [Map.LoadFactor]));
      
  finally
    Map.Free;
  end;
end;

procedure TestEdgeCases;
var
  Map: TStringIntMap;
  Value: Integer;
begin
  WriteLn;
  WriteLn('=== Test Suite 6: Edge Cases ===');
  
  Map := TStringIntMap.Create(8, @HashOfAnsiString, nil);
  try
    // Empty string key
    if Map.AddOrAssign('', 0) then
      Pass('Empty string key')
    else
      Fail('Empty string key', 'Should accept empty string');
      
    if Map.TryGetValue('', Value) and (Value = 0) then
      Pass('Retrieve empty string key')
    else
      Fail('Retrieve empty string key', 'Failed');
      
    // Remove non-existent
    if not Map.Remove('nonexistent') then
      Pass('Remove non-existent returns false')
    else
      Fail('Remove non-existent returns false', 'Should return false');
      
    // Multiple removes
    Map.AddOrAssign('test', 123);
    if Map.Remove('test') then
      Pass('First remove')
    else
      Fail('First remove', 'Should succeed');
      
    if not Map.Remove('test') then
      Pass('Second remove returns false')
    else
      Fail('Second remove returns false', 'Should return false');
      
  finally
    Map.Free;
  end;
end;

begin
  WriteLn('================================================');
  WriteLn('  THashMap Complete Test Suite');
  WriteLn('================================================');
  
  try
    TestBasicOperations;
    TestIntegerKeys;
    TestResize;
    TestReserve;
    TestLoadFactor;
    TestEdgeCases;
    
    WriteLn;
    WriteLn('================================================');
    WriteLn('=== Final Summary ===');
    WriteLn('Passed: ', TestsPassed);
    WriteLn('Failed: ', TestsFailed);
    WriteLn('================================================');
    WriteLn;
    
    if TestsFailed = 0 then
    begin
      WriteLn('SUCCESS: ALL TESTS PASSED!');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('FAILURE: Some tests failed');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('=== UNHANDLED EXCEPTION ===');
      WriteLn('Type: ', E.ClassName);
      WriteLn('Message: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
