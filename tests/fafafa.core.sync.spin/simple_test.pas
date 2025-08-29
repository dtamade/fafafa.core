program simple_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin.unix;

var
  SpinLock: TSpinLock;
  Policy: TSpinLockPolicy;

procedure TestGetMaxSpinsSetMaxSpins;
begin
  WriteLn('测试 GetMaxSpins/SetMaxSpins...');
  
  // 测试默认值
  if SpinLock.GetMaxSpins <> 64 then
  begin
    WriteLn('错误: 默认 MaxSpins 应该是 64，实际是 ', SpinLock.GetMaxSpins);
    Halt(1);
  end;
  
  // 测试设置新值
  SpinLock.SetMaxSpins(128);
  if SpinLock.GetMaxSpins <> 128 then
  begin
    WriteLn('错误: 设置后 MaxSpins 应该是 128，实际是 ', SpinLock.GetMaxSpins);
    Halt(1);
  end;
  
  WriteLn('✓ GetMaxSpins/SetMaxSpins 测试通过');
end;

procedure TestIsHeld;
begin
  WriteLn('测试 IsHeld...');
  
  // 初始状态应该是未持有
  if SpinLock.IsHeld then
  begin
    WriteLn('错误: 初始状态应该是未持有');
    Halt(1);
  end;
  
  // 获取锁后应该是持有状态
  SpinLock.Acquire;
  if not SpinLock.IsHeld then
  begin
    WriteLn('错误: 获取锁后应该是持有状态');
    Halt(1);
  end;
  
  // 释放锁后应该是未持有状态
  SpinLock.Release;
  if SpinLock.IsHeld then
  begin
    WriteLn('错误: 释放锁后应该是未持有状态');
    Halt(1);
  end;
  
  WriteLn('✓ IsHeld 测试通过');
end;

procedure TestBasicLocking;
begin
  WriteLn('测试基本锁操作...');
  
  // 测试 TryAcquire
  if not SpinLock.TryAcquire then
  begin
    WriteLn('错误: TryAcquire 应该成功');
    Halt(1);
  end;
  
  SpinLock.Release;
  
  // 测试 Acquire/Release
  SpinLock.Acquire;
  SpinLock.Release;
  
  WriteLn('✓ 基本锁操作测试通过');
end;

begin
  WriteLn('=== fafafa.core.sync.spin 简单测试 ===');
  
  // 创建自旋锁
  Policy := DefaultSpinLockPolicy;
  SpinLock := TSpinLock.Create(Policy);
  
  try
    TestGetMaxSpinsSetMaxSpins;
    TestIsHeld;
    TestBasicLocking;
    
    WriteLn('');
    WriteLn('🎉 所有测试通过！');
    WriteLn('');
    WriteLn('核心方法验证完成：');
    WriteLn('  ✓ GetMaxSpins/SetMaxSpins - 可以完美实现');
    WriteLn('  ✓ IsHeld - 可以完美实现');
    WriteLn('  ✓ 基本锁操作 - 工作正常');
    
  finally
    SpinLock.Free;
  end;
end.
