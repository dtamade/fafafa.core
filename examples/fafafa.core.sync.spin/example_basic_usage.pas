program example_basic_usage;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}
{$CODEPAGE UTF8}
{$ENDIF}

uses
  SysUtils,
  fafafa.core.sync.spin;

var
  SpinLock: ISpin;
  Counter: Integer;

begin
  WriteLn('=== 自旋锁基本使用示例 ===');
  WriteLn('');

  // 1. 创建自旋锁（使用现代接口）
  WriteLn('1. 创建自旋锁...');
  SpinLock := MakeSpin;
  WriteLn('   ✓ 自旋锁创建成功');
  WriteLn('');

  // 2. 基本的获取和释放
  WriteLn('2. 基本获取和释放操作...');
  Counter := 0;

  SpinLock.Acquire;
  try
    // 在锁保护下修改共享数据
    Inc(Counter);
    WriteLn('   在锁保护下修改计数器: ', Counter);
  finally
    SpinLock.Release;
  end;
  WriteLn('   ✓ 锁已安全释放');
  WriteLn('');

  // 3. 尝试获取锁（非阻塞）
  WriteLn('3. 尝试获取锁（非阻塞）...');
  if SpinLock.TryAcquire then
  begin
    try
      WriteLn('   ✓ 成功获取锁');
      Inc(Counter);
      WriteLn('   计数器值: ', Counter);
    finally
      SpinLock.Release;
    end;
  end
  else
    WriteLn('   ✗ 获取锁失败');
  WriteLn('');

  // 4. 带超时的尝试获取
  WriteLn('4. 带超时的尝试获取（100ms）...');
  if SpinLock.TryAcquire(100) then
  begin
    try
      WriteLn('   ✓ 在超时内成功获取锁');
      Inc(Counter);
      WriteLn('   计数器值: ', Counter);
    finally
      SpinLock.Release;
    end;
  end
  else
    WriteLn('   ✗ 超时未能获取锁');
  WriteLn('');

  // 5. RAII 模式使用（推荐）
  WriteLn('5. RAII 模式使用（推荐）...');
  with SpinLock.LockGuard do
  begin
    WriteLn('   ✓ 使用 RAII 自动管理锁');
    Inc(Counter);
    WriteLn('   计数器值: ', Counter);
    // 锁会在 with 块结束时自动释放
  end;
  WriteLn('   ✓ 锁已自动释放');
  WriteLn('');

  // 6. 错误处理示例
  WriteLn('6. 错误处理示例...');
  try
    // 零超时应该立即返回
    if SpinLock.TryAcquire(0) then
    begin
      try
        WriteLn('   ✓ 零超时获取成功');
      finally
        SpinLock.Release;
      end;
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
