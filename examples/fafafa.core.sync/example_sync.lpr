program example_sync;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.base,
  fafafa.core.sync;

{**
 * 演示基本的互斥锁使用
 *}
procedure DemoBasicMutex;
var
  LMutex: ILock;
begin
  WriteLn('=== 基本互斥锁演示 ===');
  
  // 创建互斥锁
  LMutex := TMutex.Create;
  
  WriteLn('互斥锁创建成功');
  WriteLn('初始状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  
  // 获取锁
  LMutex.Acquire;
  WriteLn('获取锁后: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  
  // 释放锁
  LMutex.Release;
  WriteLn('释放锁后: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  
  WriteLn('');
end;

{**
 * 演示重入锁功能
 *}
procedure DemoReentrantMutex;
var
  LMutex: ILock;
begin
  WriteLn('=== 重入锁演示 ===');
  
  LMutex := TMutex.Create;
  
  WriteLn('第一次获取锁...');
  LMutex.Acquire;
  WriteLn('状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  
  WriteLn('第二次获取锁（重入）...');
  LMutex.Acquire;
  WriteLn('状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  
  WriteLn('第一次释放锁...');
  LMutex.Release;
  WriteLn('状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  
  WriteLn('第二次释放锁...');
  LMutex.Release;
  WriteLn('状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  
  WriteLn('');
end;

{**
 * 演示 TryAcquire 功能
 *}
procedure DemoTryAcquire;
var
  LMutex: ILock;
  LResult: Boolean;
begin
  WriteLn('=== TryAcquire 演示 ===');
  
  LMutex := TMutex.Create;
  
  // 尝试获取锁（应该成功）
  LResult := LMutex.TryAcquire;
  WriteLn('第一次尝试获取锁: ', BoolToStr(LResult, '成功', '失败'));
  
  if LResult then
  begin
    WriteLn('锁状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
    
    // 带超时的尝试获取（重入锁应该成功）
    LResult := LMutex.TryAcquire(1000);
    WriteLn('重入尝试获取锁: ', BoolToStr(LResult, '成功', '失败'));
    
    if LResult then
      LMutex.Release; // 释放重入锁
      
    LMutex.Release; // 释放原始锁
  end;
  
  WriteLn('最终状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  WriteLn('');
end;

{**
 * 演示自旋锁使用
 *}
procedure DemoSpinLock;
var
  LSpinLock: ILock;
begin
  WriteLn('=== 自旋锁演示 ===');
  
  // 创建自旋锁
  LSpinLock := TSpinLock.Create;
  
  WriteLn('自旋锁创建成功');
  WriteLn('初始状态: ', BoolToStr(LSpinLock.IsLocked, '已锁定', '未锁定'));
  
  // 获取锁
  LSpinLock.Acquire;
  WriteLn('获取锁后: ', BoolToStr(LSpinLock.IsLocked, '已锁定', '未锁定'));
  
  // 尝试获取锁（应该失败，因为自旋锁不支持重入）
  try
    LSpinLock.Acquire;
    WriteLn('错误：自旋锁不应该支持重入');
  except
    on E: ELockError do
      WriteLn('正确：自旋锁不支持重入 - ', E.Message);
  end;
  
  // 释放锁
  LSpinLock.Release;
  WriteLn('释放锁后: ', BoolToStr(LSpinLock.IsLocked, '已锁定', '未锁定'));
  
  WriteLn('');
end;

{**
 * 演示 RAII 自动锁管理
 *}
procedure DemoAutoLock;
var
  LMutex: ILock;
  LAutoLock: TAutoLock;
begin
  WriteLn('=== RAII 自动锁演示 ===');

  LMutex := TMutex.Create;
  WriteLn('互斥锁初始状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));

  // 使用自动锁
  LAutoLock := TAutoLock.Create(LMutex);
  try
    WriteLn('创建自动锁后: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));

    // 在这个作用域内，锁被自动管理
    WriteLn('在自动锁作用域内执行操作...');
  finally
    LAutoLock.Free; // 自动锁析构并释放锁
  end;

  WriteLn('离开自动锁作用域后: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  WriteLn('');
end;

{**
 * 演示读写锁使用
 *}
procedure DemoReadWriteLock;
var
  LRWLock: IReadWriteLock;
begin
  WriteLn('=== 读写锁演示 ===');
  
  LRWLock := TReadWriteLock.Create;
  
  WriteLn('读写锁创建成功');
  WriteLn('初始读者数量: ', LRWLock.GetReaderCount);
  WriteLn('初始写锁状态: ', BoolToStr(LRWLock.IsWriteLocked, '已锁定', '未锁定'));
  
  // 获取读锁
  WriteLn('获取读锁...');
  LRWLock.AcquireRead;
  WriteLn('读者数量: ', LRWLock.GetReaderCount);
  
  // 再获取一个读锁（应该成功）
  WriteLn('再获取一个读锁...');
  LRWLock.AcquireRead;
  WriteLn('读者数量: ', LRWLock.GetReaderCount);
  
  // 尝试获取写锁（应该失败）
  WriteLn('尝试获取写锁...');
  if LRWLock.TryAcquireWrite then
    WriteLn('获取写锁成功')
  else
    WriteLn('获取写锁失败（预期结果，因为有读者）');
  
  // 释放读锁
  WriteLn('释放第一个读锁...');
  LRWLock.ReleaseRead;
  WriteLn('读者数量: ', LRWLock.GetReaderCount);
  
  WriteLn('释放第二个读锁...');
  LRWLock.ReleaseRead;
  WriteLn('读者数量: ', LRWLock.GetReaderCount);
  
  // 现在尝试获取写锁（应该成功）
  WriteLn('现在尝试获取写锁...');
  if LRWLock.TryAcquireWrite then
  begin
    WriteLn('获取写锁成功');
    WriteLn('写锁状态: ', BoolToStr(LRWLock.IsWriteLocked, '已锁定', '未锁定'));
    
    LRWLock.ReleaseWrite;
    WriteLn('释放写锁后: ', BoolToStr(LRWLock.IsWriteLocked, '已锁定', '未锁定'));
  end
  else
    WriteLn('获取写锁失败');
  
  WriteLn('');
end;

{**
 * 演示异常处理
 *}
procedure DemoExceptionHandling;
var
  LMutex: ILock;
begin
  WriteLn('=== 异常处理演示 ===');
  
  LMutex := TMutex.Create;
  
  // 尝试释放未锁定的互斥锁
  try
    LMutex.Release;
    WriteLn('错误：应该抛出异常');
  except
    on E: ELockError do
      WriteLn('正确捕获异常: ', E.Message);
  end;
  
  // 尝试创建自动锁时传入 nil
  try
    TAutoLock.Create(nil).Free;
    WriteLn('错误：应该抛出异常');
  except
    on E: EArgumentNil do
      WriteLn('正确捕获异常: ', E.Message);
  end;
  
  WriteLn('');
end;

{**
 * 主程序
 *}
begin
  WriteLn('fafafa.core.sync 模块使用示例');
  WriteLn('================================');
  WriteLn('');
  
  try
    // 运行各种演示
    DemoBasicMutex;
    DemoReentrantMutex;
    DemoTryAcquire;
    DemoSpinLock;
    DemoAutoLock;
    DemoReadWriteLock;
    DemoExceptionHandling;
    
    WriteLn('所有演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生异常: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('');
  WriteLn('按回车键退出...');
  ReadLn;
end.
