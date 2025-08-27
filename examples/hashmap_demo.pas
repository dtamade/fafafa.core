program HashMapDemo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  // 原子统一：示例不再引用 fafafa.core.sync
  fafafa.core.lockfree;

{**
 * 演示无锁哈希表的基础功能
 *}
procedure DemoBasicHashMap;
type
  TIntHashMap = specialize TLockFreeHashMap<Integer, String>;
var
  LHashMap: TIntHashMap;
  LValue: String;
  I: Integer;
begin
  WriteLn('=== 无锁哈希表基础功能演示 ===');
  
  LHashMap := TIntHashMap.Create(64);
  try
    WriteLn('哈希表容量: ', LHashMap.GetCapacity);
    
    // 插入一些键值对
    WriteLn('插入键值对...');
    for I := 1 to 10 do
      LHashMap.Put(I, 'Value' + IntToStr(I));
    
    WriteLn('哈希表大小: ', LHashMap.GetSize);
    
    // 查询键值对
    WriteLn('查询键值对:');
    for I := 1 to 10 do
    begin
      if LHashMap.Get(I, LValue) then
        WriteLn('Key ', I, ' -> ', LValue)
      else
        WriteLn('Key ', I, ' not found');
    end;
    
    // 测试不存在的键
    if LHashMap.Get(999, LValue) then
      WriteLn('Key 999 -> ', LValue)
    else
      WriteLn('Key 999 not found (正确)');
    
    // 更新值
    WriteLn('更新 Key 5 的值...');
    LHashMap.Put(5, 'Updated Value 5');
    if LHashMap.Get(5, LValue) then
      WriteLn('Key 5 -> ', LValue);
    
    // 删除键
    WriteLn('删除 Key 3...');
    if LHashMap.Remove(3) then
      WriteLn('Key 3 删除成功')
    else
      WriteLn('Key 3 删除失败');
    
    WriteLn('删除后哈希表大小: ', LHashMap.GetSize);
    
    // 验证删除
    if LHashMap.Get(3, LValue) then
      WriteLn('Key 3 -> ', LValue)
    else
      WriteLn('Key 3 not found (正确)');
    
    WriteLn('✅ 无锁哈希表基础功能正常！');
    
  finally
    LHashMap.Free;
  end;
  WriteLn;
end;

{**
 * 演示无锁哈希表的性能
 *}
procedure DemoHashMapPerformance;
type
  TIntHashMap = specialize TLockFreeHashMap<Integer, Integer>;
var
  LHashMap: TIntHashMap;
  LStartTime, LEndTime: QWord;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 无锁哈希表性能演示 ===');
  
  LHashMap := TIntHashMap.Create(1024);
  try
    // 测试插入性能
    WriteLn('插入10万个键值对...');
    LStartTime := GetTickCount64;
    
    for I := 1 to 100000 do
      LHashMap.Put(I, I * 2);
    
    LEndTime := GetTickCount64;
    WriteLn('插入耗时: ', LEndTime - LStartTime, ' ms');
    WriteLn('哈希表大小: ', LHashMap.GetSize);
    
    // 测试查询性能
    WriteLn('查询10万次...');
    LStartTime := GetTickCount64;
    
    for I := 1 to 100000 do
      LHashMap.Get(I, LValue);
    
    LEndTime := GetTickCount64;
    WriteLn('查询耗时: ', LEndTime - LStartTime, ' ms');
    
    // 验证一些值
    WriteLn('验证部分值:');
    for I := 1 to 5 do
    begin
      if LHashMap.Get(I, LValue) then
        WriteLn('Key ', I, ' -> ', LValue);
    end;
    
    WriteLn('✅ 无锁哈希表性能测试完成！');
    
  finally
    LHashMap.Free;
  end;
  WriteLn;
end;

{**
 * 演示多线程并发访问（简化版）
 *}
procedure DemoHashMapConcurrency;
type
  TIntHashMap = specialize TLockFreeHashMap<Integer, Integer>;
var
  LHashMap: TIntHashMap;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 无锁哈希表并发演示 ===');

  LHashMap := TIntHashMap.Create(1024);

  try
    WriteLn('单线程插入2000个键值对...');

    // 插入键值对
    for I := 1 to 2000 do
      LHashMap.Put(I, I * 2);

    WriteLn('哈希表大小: ', LHashMap.GetSize);

    // 验证一些值
    WriteLn('验证部分值:');
    for I := 1 to 5 do
    begin
      if LHashMap.Get(I, LValue) then
        WriteLn('Key ', I, ' -> ', LValue);
    end;

    // 测试删除
    WriteLn('删除前100个键...');
    for I := 1 to 100 do
      LHashMap.Remove(I);

    WriteLn('删除后哈希表大小: ', LHashMap.GetSize);

    // 验证删除
    if LHashMap.Get(50, LValue) then
      WriteLn('Key 50 仍然存在: ', LValue)
    else
      WriteLn('Key 50 已删除 (正确)');

    if LHashMap.Get(150, LValue) then
      WriteLn('Key 150 仍然存在: ', LValue, ' (正确)')
    else
      WriteLn('Key 150 不存在');

    WriteLn('✅ 无锁哈希表功能测试成功！');

  finally
    LHashMap.Free;
  end;
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('fafafa.core.lockfree 无锁哈希表演示');
  WriteLn('===================================');
  WriteLn;
  
  try
    DemoBasicHashMap;
    DemoHashMapPerformance;
    DemoHashMapConcurrency;
    
    WriteLn('🎉 所有无锁哈希表演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('演示过程中发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
