program example_basic_usage;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

var
  SpinLock: ISpinLock;
  Policy: TSpinLockPolicy;
  Counter: Integer;

begin
  WriteLn('=== 自旋锁基本使用示例 ===');
  WriteLn('');
  
  // 1. 使用默认策略创建自旋锁
  WriteLn('1. 创建默认自旋锁...');
  SpinLock := MakeSpinLock;
  WriteLn('   默认自旋次数: ', SpinLock.GetSpinCount);
  WriteLn('   默认策略: ', Ord(SpinLock.GetPolicy.BackoffStrategy));
  WriteLn('');
  
  // 2. 基本的获取和释放
  WriteLn('2. 基本获取和释放操作...');
  Counter := 0;
  
  WriteLn('   获取锁前 IsHeld: ', SpinLock.IsHeld);
  SpinLock.Acquire;
  WriteLn('   获取锁后 IsHeld: ', SpinLock.IsHeld);
  
  // 在锁保护下修改共享数据
  Inc(Counter);
  WriteLn('   在锁保护下修改计数器: ', Counter);
  
  SpinLock.Release;
  WriteLn('   释放锁后 IsHeld: ', SpinLock.IsHeld);
  WriteLn('');
  
  // 3. 尝试获取锁（非阻塞）
  WriteLn('3. 尝试获取锁（非阻塞）...');
  if SpinLock.TryAcquire then
  begin
    WriteLn('   ✓ 成功获取锁');
    Inc(Counter);
    WriteLn('   计数器值: ', Counter);
    SpinLock.Release;
  end
  else
    WriteLn('   ✗ 获取锁失败');
  WriteLn('');
  
  // 4. 带超时的尝试获取
  WriteLn('4. 带超时的尝试获取（100ms）...');
  if SpinLock.TryAcquire(100) then
  begin
    WriteLn('   ✓ 在超时内成功获取锁');
    Inc(Counter);
    WriteLn('   计数器值: ', Counter);
    SpinLock.Release;
  end
  else
    WriteLn('   ✗ 超时未能获取锁');
  WriteLn('');
  
  // 5. 自定义策略
  WriteLn('5. 使用自定义策略...');
  Policy := DefaultSpinLockPolicy;
  Policy.MaxSpins := 128;
  Policy.BackoffStrategy := sbsExponential;
  Policy.MaxBackoffMs := 20;

  SpinLock := MakeSpinLock(Policy);
  WriteLn('   自定义自旋次数: ', SpinLock.GetMaxSpins);
  WriteLn('   最大退避时间: ', Policy.MaxBackoffMs, ' ms');
  WriteLn('');

  // 6. 动态更新自旋次数
  WriteLn('6. 动态更新自旋次数...');
  WriteLn('   更新前自旋次数: ', SpinLock.GetMaxSpins);
  SpinLock.SetMaxSpins(256);
  WriteLn('   更新后自旋次数: ', SpinLock.GetMaxSpins);
  WriteLn('');

  // 7. 检查锁状态
  WriteLn('7. 检查锁状态...');
  WriteLn('   当前是否持有锁: ', SpinLock.IsHeld);
  SpinLock.Acquire;
  WriteLn('   获取锁后状态: ', SpinLock.IsHeld);
  SpinLock.Release;
  WriteLn('   释放锁后状态: ', SpinLock.IsHeld);
  WriteLn('');
  
  // 8. 错误处理示例
  WriteLn('8. 错误处理示例...');
  try
    // 零超时应该立即返回
    if SpinLock.TryAcquire(0) then
    begin
      WriteLn('   ✓ 零超时获取成功');
      SpinLock.Release;
    end
    else
      WriteLn('   零超时获取失败（正常情况）');
  except
    on E: Exception do
      WriteLn('   异常: ', E.Message);
  end;
  WriteLn('');
  
  WriteLn('=== 基本使用示例完成 ===');
  WriteLn('最终计数器值: ', Counter);
end.
