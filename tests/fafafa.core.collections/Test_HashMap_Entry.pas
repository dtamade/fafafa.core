unit Test_HashMap_Entry;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

{**
 * TDD 测试用例: HashMap Entry API
 * 
 * 测试目标:
 * 1. GetOrInsert(key, default) - 键不存在时插入默认值
 * 2. GetOrInsertWith(key, func) - 键不存在时使用函数生成值
 * 3. ModifyOrInsert(key, modifier, default) - 键存在时修改，不存在时插入
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.base,
  fafafa.core.collections.hashmap,
  fafafa.core.collections;

type
  { TTestHashMapEntry }
  TTestHashMapEntry = class(TTestCase)
  published
    // GetOrInsert 测试
    procedure Test_GetOrInsert_KeyNotExists;
    procedure Test_GetOrInsert_KeyExists;
    
    // GetOrInsertWith 测试
    procedure Test_GetOrInsertWith_KeyNotExists;
    procedure Test_GetOrInsertWith_KeyExists;
    
    // ModifyOrInsert 测试
    procedure Test_ModifyOrInsert_KeyExists;
    procedure Test_ModifyOrInsert_KeyNotExists;
    procedure Test_ModifyOrInsert_Counter_Pattern;
    
    // 实际用例测试
    procedure Test_WordCount_Pattern;
    
    // 内存泄漏测试
    procedure Test_Entry_NoLeak;
  end;

implementation

{ Callback functions (top-level for FPC compatibility) }

var
  GCallCount: Integer = 0;
  GModifyCalled: Boolean = False;

function ComputeDefault999: Integer;
begin
  Inc(GCallCount);
  Result := 999;
end;

procedure DoubleValue(var Value: Integer);
begin
  Value := Value * 2;
end;

procedure MarkModifyCalled(var Value: Integer);
begin
  GModifyCalled := True;
end;

procedure IncrementValue(var Value: Integer);
begin
  Inc(Value);
end;

procedure Add10Value(var Value: Integer);
begin
  Value := Value + 10;
end;

{ Entry Tests }

procedure TTestHashMapEntry.Test_GetOrInsert_KeyNotExists;
var
  Map: specialize IHashMap<String, Integer>;
  Value: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  
  // Key doesn't exist, should insert default value
  Value := Map.GetOrInsert('key1', 100);
  
  AssertEquals('Should return inserted value', 100, Value);
  AssertTrue('Key should exist now', Map.ContainsKey('key1'));
  AssertEquals('Count should be 1', 1, Map.Count);
end;

procedure TTestHashMapEntry.Test_GetOrInsert_KeyExists;
var
  Map: specialize IHashMap<String, Integer>;
  Value: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  Map.Put('key1', 42);
  
  // Key exists, should return existing value
  Value := Map.GetOrInsert('key1', 100);
  
  AssertEquals('Should return existing value', 42, Value);
  AssertEquals('Count should still be 1', 1, Map.Count);
end;

procedure TTestHashMapEntry.Test_GetOrInsertWith_KeyNotExists;
var
  Map: specialize IHashMap<String, Integer>;
  Value: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  GCallCount := 0;
  
  // Key doesn't exist, should call function to get value
  Value := Map.GetOrInsertWith('key1', @ComputeDefault999);
  
  AssertEquals('Should return computed value', 999, Value);
  AssertTrue('Key should exist', Map.ContainsKey('key1'));
  AssertEquals('Function should be called once', 1, GCallCount);
end;

procedure TTestHashMapEntry.Test_GetOrInsertWith_KeyExists;
var
  Map: specialize IHashMap<String, Integer>;
  Value: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  Map.Put('key1', 42);
  GCallCount := 0;
  
  // Key exists, function should NOT be called
  Value := Map.GetOrInsertWith('key1', @ComputeDefault999);
  
  AssertEquals('Should return existing value', 42, Value);
  AssertEquals('Function should not be called', 0, GCallCount);
end;

procedure TTestHashMapEntry.Test_ModifyOrInsert_KeyExists;
var
  Map: specialize IHashMap<String, Integer>;
  V: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  Map.Put('key1', 50);
  
  // Key exists - modifier should be called
  Map.ModifyOrInsert('key1', @DoubleValue, 0);
  
  Map.TryGetValue('key1', V);
  AssertEquals('Value should be doubled', 100, V);
end;

procedure TTestHashMapEntry.Test_ModifyOrInsert_KeyNotExists;
var
  Map: specialize IHashMap<String, Integer>;
  V: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  GModifyCalled := False;
  
  // Key doesn't exist - modifier should NOT be called, default inserted
  Map.ModifyOrInsert('key1', @MarkModifyCalled, 42);
  
  AssertFalse('Modify function should not be called', GModifyCalled);
  AssertTrue('Key should exist', Map.ContainsKey('key1'));
  Map.TryGetValue('key1', V);
  AssertEquals('Value should be default', 42, V);
end;

procedure TTestHashMapEntry.Test_ModifyOrInsert_Counter_Pattern;
var
  Map: specialize IHashMap<String, Integer>;
  V: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  
  // First call: key doesn't exist, insert 0
  Map.ModifyOrInsert('counter', @IncrementValue, 0);
  Map.TryGetValue('counter', V);
  AssertEquals('First access should be 0', 0, V);
  
  // Second call: key exists, increment
  Map.ModifyOrInsert('counter', @IncrementValue, 0);
  Map.TryGetValue('counter', V);
  AssertEquals('Second access should be 1', 1, V);
  
  // Third call: key exists, increment again
  Map.ModifyOrInsert('counter', @IncrementValue, 0);
  Map.TryGetValue('counter', V);
  AssertEquals('Third access should be 2', 2, V);
end;

procedure TTestHashMapEntry.Test_WordCount_Pattern;
var
  Map: specialize IHashMap<String, Integer>;
  Words: array[0..9] of String = ('apple', 'banana', 'apple', 'cherry', 
    'banana', 'apple', 'date', 'cherry', 'apple', 'banana');
  i: Integer;
  V: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  
  // Classic word count pattern
  for i := 0 to High(Words) do
    Map.ModifyOrInsert(Words[i], @IncrementValue, 1);
  
  Map.TryGetValue('apple', V);
  AssertEquals('apple count', 4, V);
  
  Map.TryGetValue('banana', V);
  AssertEquals('banana count', 3, V);
  
  Map.TryGetValue('cherry', V);
  AssertEquals('cherry count', 2, V);
  
  Map.TryGetValue('date', V);
  AssertEquals('date count', 1, V);
end;

procedure TTestHashMapEntry.Test_Entry_NoLeak;
var
  Map: specialize IHashMap<String, Integer>;
  i: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  
  // Create many entries
  for i := 1 to 1000 do
    Map.ModifyOrInsert('key' + IntToStr(i mod 100), @Add10Value, 1);
  
  // Map will be released, HeapTrc will report leaks
end;

initialization
  RegisterTest(TTestHashMapEntry);

end.
