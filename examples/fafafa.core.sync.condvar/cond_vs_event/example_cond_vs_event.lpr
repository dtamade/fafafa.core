program example_cond_vs_event;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex, fafafa.core.sync.condvar,
  fafafa.core.sync.event, fafafa.core.sync.sem;

var
  M: IMutex;
  CV: ICondVar;
  E: IEvent;
  S: ISem;
  Ready: Boolean;

procedure WithCondVar;
begin
  // 条件变量典型用法：在持有互斥锁时等待，醒来后通常循环判定条件
  M.Acquire;
  try
    while not Ready do
      CV.Wait(M);
    Writeln('[CondVar] 条件成立');
  finally
    M.Release;
  end;
end;

procedure WithEvent;
begin
  // 事件典型用法：等待一次信号（自动复位）或广播（手动复位）
  // 此处使用自动复位事件，Wait 返回后事件自动切回无信号
  if E.WaitFor(1000) = wrSignaled then
    Writeln('[Event] 收到信号')
  else
    Writeln('[Event] 超时未收到信号');
end;

procedure WithSemaphore;
begin
  // 信号量：控制可用资源计数；Release 增加计数，Acquire/TryAcquire 消耗
  if S.TryAcquire(200) then
  begin
    Writeln('[Semaphore] 成功获取一个资源');
    S.Release;
  end
  else
    Writeln('[Semaphore] 超时未获取资源');
end;

begin
  M := MakeMutex;
  CV := MakeCondVar;
  E := MakeEvent(False{AutoReset}, False{Initial});
  S := MakeSemaphore(0, 3);
  Ready := False;

  // 启动等待线程
  TThread.CreateAnonymousThread(@WithCondVar).Start;
  TThread.CreateAnonymousThread(@WithEvent).Start;
  TThread.CreateAnonymousThread(@WithSemaphore).Start;

  // 主线程稍后发信号
  Sleep(200);
  M.Acquire;
  try
    Ready := True;
    CV.Signal;  // 唤醒 condvar 等待者
  finally
    M.Release;
  end;
  E.SetEvent;   // 触发一次事件
  S.Release;    // 释放一个信号量资源

  Sleep(300);
  Writeln('对比示例完成。');
end.

