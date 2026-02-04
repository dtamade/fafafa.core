unit fafafa.core.sync.notify;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  INotify - 轻量级线程通知原语

  参照 Rust tokio::sync::Notify 的语义实现：
  - 比 Event 更简单：无状态，只负责通知
  - 比 Parker 更灵活：支持多等待者

  使用示例：

    // 生产者-消费者通知
    var
      Notify: INotify;
      DataReady: Boolean;

    // 消费者线程
    procedure ConsumerThread;
    begin
      while True do
      begin
        Notify.Wait;  // 等待数据就绪通知
        ProcessData;
      end;
    end;

    // 生产者线程
    procedure ProducerThread;
    begin
      PrepareData;
      Notify.NotifyOne;  // 通知一个消费者
    end;

  与 Event/Parker 的区别：
  - Event: 有状态（signaled/unsignaled），可以 Set/Reset
  - Parker: 一对一，有 permit 机制
  - Notify: 无状态，纯通知，支持多等待者

  注意事项：
  - 如果没有等待者，通知会丢失（不像 Event 会保持状态）
  - NotifyOne 唤醒一个等待者（FIFO 顺序）
  - NotifyAll 唤醒所有等待者
}

interface

uses
  fafafa.core.sync.notify.base;

{ 创建 INotify 实例 }
function MakeNotify: INotify;

implementation

uses
  {$IFDEF UNIX}
  fafafa.core.sync.notify.unix;
  {$ENDIF}
  {$IFDEF WINDOWS}
  fafafa.core.sync.notify.windows;
  {$ENDIF}

function MakeNotify: INotify;
begin
  {$IFDEF UNIX}
  Result := MakeNotifyUnix;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := MakeNotifyWindows;
  {$ENDIF}
end;

end.
