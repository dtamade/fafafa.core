program AdvancedSyncDemo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.sync;

var
  // 全局同步对象
  GSemaphore: ISemaphore;
  GEvent: IEvent;
  GBarrier: IBarrier;
  GCondition: IConditionVariable;
  GMutex: ILock;

{**
 * 演示信号量的使用
 * 模拟资源池管理
 *}
procedure DemoSemaphore;
var
  LWorkerThread: TThread;
  I: Integer;
begin
  WriteLn('=== 信号量演示 ===');
  
  // 创建一个最多允许2个并发访问的资源池
  GSemaphore := TSemaphore.Create(2, 2);
  
  WriteLn('创建信号量，最大并发数: 2');
  WriteLn('当前可用资源: ', GSemaphore.GetAvailableCount);
  
  // 模拟资源使用
  WriteLn('获取1个资源...');
  GSemaphore.Acquire;
  WriteLn('当前可用资源: ', GSemaphore.GetAvailableCount);
  
  WriteLn('获取第2个资源...');
  GSemaphore.Acquire;
  WriteLn('当前可用资源: ', GSemaphore.GetAvailableCount);
  
  WriteLn('尝试获取第3个资源（应该失败）...');
  if GSemaphore.TryAcquire then
    WriteLn('意外成功！')
  else
    WriteLn('正确失败 - 资源已耗尽');
  
  WriteLn('释放1个资源...');
  GSemaphore.Release;
  WriteLn('当前可用资源: ', GSemaphore.GetAvailableCount);
  
  WriteLn('释放第2个资源...');
  GSemaphore.Release;
  WriteLn('当前可用资源: ', GSemaphore.GetAvailableCount);
  
  WriteLn('信号量演示完成');
  WriteLn;
end;

{**
 * 演示事件的使用
 * 模拟线程间通知
 *}
procedure DemoEvent;
begin
  WriteLn('=== 事件演示 ===');
  
  // 创建自动重置事件
  GEvent := TEvent.Create(False, False);
  
  WriteLn('创建自动重置事件');
  WriteLn('初始状态: ', BoolToStr(GEvent.IsSignaled, '已信号', '未信号'));
  
  WriteLn('设置事件...');
  GEvent.SetEvent;
  WriteLn('设置后状态: ', BoolToStr(GEvent.IsSignaled, '已信号', '未信号'));
  
  WriteLn('等待事件...');
  case GEvent.WaitFor(1000) of
    wrSignaled: WriteLn('等待成功 - 事件已信号');
    wrTimeout: WriteLn('等待超时');
    wrError: WriteLn('等待错误');
  end;
  
  WriteLn('等待后状态: ', BoolToStr(GEvent.IsSignaled, '已信号', '未信号'));
  
  WriteLn('重置事件...');
  GEvent.ResetEvent;
  WriteLn('重置后状态: ', BoolToStr(GEvent.IsSignaled, '已信号', '未信号'));
  
  WriteLn('事件演示完成');
  WriteLn;
end;

{**
 * 演示屏障的使用
 * 模拟多线程同步点
 *}
procedure DemoBarrier;
begin
  WriteLn('=== 屏障演示 ===');
  
  // 创建3个参与者的屏障
  GBarrier := TBarrier.Create(3);
  
  WriteLn('创建屏障，参与者数量: ', GBarrier.GetParticipantCount);
  WriteLn('当前等待数量: ', GBarrier.GetWaitingCount);
  
  WriteLn('模拟单线程等待（应该超时）...');
  if GBarrier.Wait(100) then
    WriteLn('意外成功！')
  else
    WriteLn('正确超时 - 需要3个参与者');
  
  WriteLn('屏障演示完成');
  WriteLn;
end;

{**
 * 演示条件变量的使用
 * 模拟生产者-消费者模式
 *}
procedure DemoConditionVariable;
begin
  WriteLn('=== 条件变量演示 ===');
  
  // 创建条件变量和互斥锁
  GCondition := TConditionVariable.Create;
  GMutex := TMutex.Create;
  
  WriteLn('创建条件变量和互斥锁');
  
  WriteLn('模拟条件等待（应该超时）...');
  GMutex.Acquire;
  try
    if GCondition.Wait(GMutex, 100) then
      WriteLn('等待成功')
    else
      WriteLn('正确超时 - 没有信号');
  finally
    GMutex.Release;
  end;
  
  WriteLn('发送信号...');
  GCondition.Signal;
  
  WriteLn('广播信号...');
  GCondition.Broadcast;
  
  WriteLn('条件变量演示完成');
  WriteLn;
end;

{**
 * 演示 RAII 自动锁的使用
 *}
procedure DemoAutoLock;
var
  LMutex: ILock;
  LAutoLock: TAutoLock;
begin
  WriteLn('=== RAII 自动锁演示 ===');
  
  LMutex := TMutex.Create;
  
  WriteLn('创建互斥锁');
  WriteLn('锁状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  
  WriteLn('使用 RAII 自动锁...');
  LAutoLock := TAutoLock.Create(LMutex);
  try
    WriteLn('自动锁获取后状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
    
    // 模拟一些工作
    Sleep(10);
    
    WriteLn('工作完成，准备自动释放...');
  finally
    LAutoLock.Free; // 自动释放锁
  end;
  
  WriteLn('自动释放后状态: ', BoolToStr(LMutex.IsLocked, '已锁定', '未锁定'));
  
  WriteLn('RAII 自动锁演示完成');
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('fafafa.core.sync 高级同步原语演示');
  WriteLn('=====================================');
  WriteLn;
  
  try
    // 演示各种同步原语
    DemoSemaphore;
    DemoEvent;
    DemoBarrier;
    DemoConditionVariable;
    DemoAutoLock;
    
    WriteLn('所有演示完成！');
    
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
