program test_hashmap_memory_safety;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.hashmap;

type
  TStringStringMap = specialize THashMap<string, string>;
  TStringIntMap = specialize THashMap<string, Integer>;

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

// 测试 DoZero 对管理类型的处理
procedure TestDoZeroWithManagedTypes;
var
  Map: TStringStringMap;
  Value: string;
begin
  WriteLn;
  WriteLn('=== Test Suite 1: DoZero with Managed Types ===');
  
  Map := TStringStringMap.Create(16, @HashOfAnsiString, nil);
  try
    // 填充一些字符串对（字符串有引用计数）
    Map.AddOrAssign('key1', 'value1');
    Map.AddOrAssign('key2', 'value2');
    Map.AddOrAssign('key3', 'value3');
    
    if Map.Count = 3 then
      Pass('Initial insertion')
    else
      Fail('Initial insertion', Format('Expected 3, got %d', [Map.Count]));
    
    // 调用 Zero (应该清空所有值但保留键)
    // THashMap的Zero语义：将所有值重置为默认值（空字符串），键保持不变
    Map.Zero;
    
    // Zero 之后 count 应该仍然是 3（键仍然存在）
    if Map.Count = 3 then
      Pass('Zero preserves keys')
    else
      Fail('Zero preserves keys', Format('Expected 3, got %d', [Map.Count]));
    
    // 验证键仍然存在但值已被清零
    if Map.TryGetValue('key1', Value) and (Value = '') then
      Pass('Keys still accessible with zero values after Zero')
    else
      Fail('Keys still accessible with zero values after Zero', Format('Key1 should exist with empty value, got: %s', [Value]));
    
    // 重新插入，验证没有内存泄漏或损坏
    Map.AddOrAssign('key1', 'new_value1');
    
    if Map.TryGetValue('key1', Value) and (Value = 'new_value1') then
      Pass('Re-insertion after Zero')
    else
      Fail('Re-insertion after Zero', 'Failed to insert or retrieve');
      
  finally
    Map.Free;
  end;
end;

// 测试 Remove 后的内存状态
procedure TestRemoveWithManagedTypes;
var
  Map: TStringStringMap;
  Value: string;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== Test Suite 2: Remove with Managed Types ===');
  
  Map := TStringStringMap.Create(16, @HashOfAnsiString, nil);
  try
    // 插入多个字符串键值对
    for I := 1 to 10 do
      Map.AddOrAssign(Format('key%d', [I]), Format('value%d', [I]));
    
    if Map.Count = 10 then
      Pass('Initial 10 insertions')
    else
      Fail('Initial 10 insertions', Format('Expected 10, got %d', [Map.Count]));
    
    // 删除一半
    for I := 1 to 5 do
    begin
      if not Map.Remove(Format('key%d', [I])) then
      begin
        Fail('Remove half keys', Format('Failed to remove key%d', [I]));
        Exit;
      end;
    end;
    
    if Map.Count = 5 then
      Pass('Remove half keys')
    else
      Fail('Remove half keys', Format('Expected 5, got %d', [Map.Count]));
    
    // 验证已删除的键不存在
    for I := 1 to 5 do
    begin
      if Map.TryGetValue(Format('key%d', [I]), Value) then
      begin
        Fail('Verify removed keys', Format('Key%d should not exist', [I]));
        Exit;
      end;
    end;
    Pass('Verify removed keys not accessible');
    
    // 验证保留的键仍然存在
    for I := 6 to 10 do
    begin
      if not (Map.TryGetValue(Format('key%d', [I]), Value) and (Value = Format('value%d', [I]))) then
      begin
        Fail('Verify remaining keys', Format('Key%d failed', [I]));
        Exit;
      end;
    end;
    Pass('Verify remaining keys intact');
    
    // 重新插入已删除的键
    for I := 1 to 5 do
      Map.AddOrAssign(Format('key%d', [I]), Format('new_value%d', [I]));
    
    if Map.Count = 10 then
      Pass('Re-insert removed keys')
    else
      Fail('Re-insert removed keys', Format('Expected 10, got %d', [Map.Count]));
    
    // 验证新值
    if Map.TryGetValue('key1', Value) and (Value = 'new_value1') then
      Pass('Verify re-inserted values')
    else
      Fail('Verify re-inserted values', 'Failed');
      
  finally
    Map.Free;
  end;
end;

// 测试混合操作下的内存安全
procedure TestMixedOperationsMemorySafety;
var
  Map: TStringStringMap;
  Value: string;
  I, J: Integer;
begin
  WriteLn;
  WriteLn('=== Test Suite 3: Mixed Operations Memory Safety ===');
  
  Map := TStringStringMap.Create(8, @HashOfAnsiString, nil);
  try
    // 多轮插入、更新、删除
    for J := 1 to 3 do
    begin
      // 插入
      for I := 1 to 20 do
        Map.AddOrAssign(Format('key%d', [I]), Format('round%d_value%d', [J, I]));
      
      // 更新一部分
      for I := 1 to 10 do
        Map.AddOrAssign(Format('key%d', [I]), Format('round%d_updated%d', [J, I]));
      
      // 删除一部分
      for I := 11 to 20 do
        Map.Remove(Format('key%d', [I]));
    end;
    
    // 最后验证状态
    if Map.Count = 10 then
      Pass('Mixed operations count')
    else
      Fail('Mixed operations count', Format('Expected 10, got %d', [Map.Count]));
    
    // 验证最终值
    if Map.TryGetValue('key1', Value) and (Value = 'round3_updated1') then
      Pass('Verify final values')
    else
      Fail('Verify final values', Format('Expected round3_updated1, got %s', [Value]));
    
    // 清空并重新开始
    Map.Clear;
    
    if Map.Count = 0 then
      Pass('Clear after mixed operations')
    else
      Fail('Clear after mixed operations', Format('Expected 0, got %d', [Map.Count]));
    
    // 重新使用
    Map.AddOrAssign('final_key', 'final_value');
    
    if Map.TryGetValue('final_key', Value) and (Value = 'final_value') then
      Pass('Reuse after Clear')
    else
      Fail('Reuse after Clear', 'Failed');
      
  finally
    Map.Free;
  end;
end;

// 测试大量字符串的生命周期管理
procedure TestLargeStringLifecycle;
var
  Map: TStringStringMap;
  I: Integer;
  LongStr: string;
  Value: string;
begin
  WriteLn;
  WriteLn('=== Test Suite 4: Large String Lifecycle ===');
  
  Map := TStringStringMap.Create(64, @HashOfAnsiString, nil);
  try
    // 创建长字符串（确保堆分配）
    LongStr := StringOfChar('A', 1000);
    
    // 插入100个长字符串键值对
    for I := 1 to 100 do
      Map.AddOrAssign(Format('key%d', [I]), LongStr + IntToStr(I));
    
    if Map.Count = 100 then
      Pass('Insert 100 large strings')
    else
      Fail('Insert 100 large strings', Format('Expected 100, got %d', [Map.Count]));
    
    // 验证检索
    if Map.TryGetValue('key50', Value) and (Length(Value) > 1000) then
      Pass('Retrieve large string')
    else
      Fail('Retrieve large string', 'Failed or wrong length');
    
    // 删除一半
    for I := 1 to 50 do
      Map.Remove(Format('key%d', [I]));
    
    if Map.Count = 50 then
      Pass('Remove 50 large strings')
    else
      Fail('Remove 50 large strings', Format('Expected 50, got %d', [Map.Count]));
    
    // 清空
    Map.Clear;
    
    if Map.Count = 0 then
      Pass('Clear large strings')
    else
      Fail('Clear large strings', Format('Expected 0, got %d', [Map.Count]));
      
  finally
    Map.Free;
  end;
end;

// 测试空字符串和 nil 情况
procedure TestEmptyAndEdgeCases;
var
  Map: TStringStringMap;
  Value: string;
begin
  WriteLn;
  WriteLn('=== Test Suite 5: Empty and Edge Cases ===');
  
  Map := TStringStringMap.Create(16, @HashOfAnsiString, nil);
  try
    // 空字符串作为键
    Map.AddOrAssign('', 'empty_key_value');
    
    if Map.TryGetValue('', Value) and (Value = 'empty_key_value') then
      Pass('Empty string as key')
    else
      Fail('Empty string as key', 'Failed');
    
    // 空字符串作为值
    Map.AddOrAssign('nonempty_key', '');
    
    if Map.TryGetValue('nonempty_key', Value) and (Value = '') then
      Pass('Empty string as value')
    else
      Fail('Empty string as value', 'Failed');
    
    // 删除空键
    if Map.Remove('') then
      Pass('Remove empty key')
    else
      Fail('Remove empty key', 'Failed');
    
    // 再次验证
    if not Map.TryGetValue('', Value) then
      Pass('Empty key removed')
    else
      Fail('Empty key removed', 'Should not exist');
      
  finally
    Map.Free;
  end;
end;

// 测试更新操作的内存安全
procedure TestUpdateOperationsMemorySafety;
var
  Map: TStringStringMap;
  Value: string;
  I: Integer;
begin
  WriteLn;
  WriteLn('=== Test Suite 6: Update Operations Memory Safety ===');
  
  Map := TStringStringMap.Create(16, @HashOfAnsiString, nil);
  try
    // 插入初始值
    Map.AddOrAssign('update_key', 'initial_value');
    
    if Map.TryGetValue('update_key', Value) and (Value = 'initial_value') then
      Pass('Initial value set')
    else
      Fail('Initial value set', 'Failed');
    
    // 多次更新同一个键（测试旧值是否正确释放）
    for I := 1 to 50 do
      Map.AddOrAssign('update_key', Format('updated_value_%d', [I]));
    
    if Map.TryGetValue('update_key', Value) and (Value = 'updated_value_50') then
      Pass('50 updates on same key')
    else
      Fail('50 updates on same key', 'Final value mismatch');
    
    // Count 应该仍然是 1
    if Map.Count = 1 then
      Pass('Count remains 1 after updates')
    else
      Fail('Count remains 1 after updates', Format('Expected 1, got %d', [Map.Count]));
      
  finally
    Map.Free;
  end;
end;

begin
  WriteLn('================================================');
  WriteLn('  THashMap Memory Safety Test Suite');
  WriteLn('  Testing fixes for DoZero and Remove');
  WriteLn('================================================');
  
  try
    TestDoZeroWithManagedTypes;
    TestRemoveWithManagedTypes;
    TestMixedOperationsMemorySafety;
    TestLargeStringLifecycle;
    TestEmptyAndEdgeCases;
    TestUpdateOperationsMemorySafety;
    
    WriteLn;
    WriteLn('================================================');
    WriteLn('=== Final Summary ===');
    WriteLn('Passed: ', TestsPassed);
    WriteLn('Failed: ', TestsFailed);
    WriteLn('================================================');
    WriteLn;
    
    if TestsFailed = 0 then
    begin
      WriteLn('SUCCESS: ALL MEMORY SAFETY TESTS PASSED!');
      WriteLn('The DoZero and Remove fixes are working correctly.');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('FAILURE: Some tests failed');
      WriteLn('Memory safety issues may still exist.');
      ExitCode := 1;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn;
      WriteLn('=== UNHANDLED EXCEPTION ===');
      WriteLn('Type: ', E.ClassName);
      WriteLn('Message: ', E.Message);
      WriteLn;
      WriteLn('This may indicate a memory corruption or access violation.');
      ExitCode := 1;
    end;
  end;
  
  {$IFDEF WINDOWS}
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
  {$ENDIF}
end.
