program test_hashmap_simple;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.hashmap;

type
  TIntMap = specialize THashMap<Integer, string>;
  
var
  map: TIntMap;
  value: string;
  
begin
  WriteLn('Testing HashMap...');
  
  // 创建 HashMap
  map := TIntMap.Create(16);
  try
    // 测试插入
    WriteLn('Testing Add...');
    if not map.Add(1, 'one') then
      WriteLn('ERROR: Failed to add key 1');
    if not map.Add(2, 'two') then
      WriteLn('ERROR: Failed to add key 2');
    if not map.Add(3, 'three') then
      WriteLn('ERROR: Failed to add key 3');
    
    WriteLn('Count after adds: ', map.GetCount);
    
    // 测试查找
    WriteLn('Testing TryGetValue...');
    if map.TryGetValue(1, value) then
      WriteLn('Key 1 = ', value)
    else
      WriteLn('ERROR: Key 1 not found');
      
    if map.TryGetValue(2, value) then
      WriteLn('Key 2 = ', value)
    else
      WriteLn('ERROR: Key 2 not found');
    
    // 测试包含
    WriteLn('Testing ContainsKey...');
    if not map.ContainsKey(1) then
      WriteLn('ERROR: Key 1 should exist');
    if map.ContainsKey(99) then
      WriteLn('ERROR: Key 99 should not exist');
    
    // 测试覆盖
    WriteLn('Testing AddOrAssign...');
    if map.AddOrAssign(1, 'ONE') then
      WriteLn('ERROR: Key 1 should already exist')
    else
      WriteLn('Successfully updated key 1');
    
    if map.TryGetValue(1, value) then
      WriteLn('Key 1 now = ', value)
    else
      WriteLn('ERROR: Key 1 not found after update');
    
    // 测试删除
    WriteLn('Testing Remove...');
    if not map.Remove(2) then
      WriteLn('ERROR: Failed to remove key 2');
    
    WriteLn('Count after remove: ', map.GetCount);
    
    if map.ContainsKey(2) then
      WriteLn('ERROR: Key 2 should have been removed');
    
    // 测试清空
    WriteLn('Testing Clear...');
    map.Clear;
    WriteLn('Count after clear: ', map.GetCount);
    
    if map.GetCount <> 0 then
      WriteLn('ERROR: Map should be empty');
    
    WriteLn('All tests completed!');
    
  finally
    map.Free;
  end;
  
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
