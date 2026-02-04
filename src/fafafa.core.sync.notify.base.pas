unit fafafa.core.sync.notify.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  INotify - 轻量级线程通知原语接口（base unit）

  设计目标：
  - 参照 Rust tokio::sync::Notify 的语义
  - 比 Event 更简单：无状态，只负责通知
  - 比 Parker 更灵活：支持多等待者

  核心 API：
  - Wait(): 等待通知
  - WaitTimeout(ms): 带超时等待
  - NotifyOne(): 唤醒一个等待者
  - NotifyAll(): 唤醒所有等待者

  与 Event/Parker 的区别：
  - Event: 有状态（signaled/unsignaled），可以 Set/Reset
  - Parker: 一对一，有 permit 机制
  - Notify: 无状态，纯通知，支持多等待者

  使用场景：
  - 简单的线程间通知
  - "数据已就绪"信号
  - 任务完成通知

  注意事项：
  - 如果没有等待者，通知会丢失（不像 Event 会保持状态）
  - NotifyOne 唤醒一个等待者（FIFO 顺序）
  - NotifyAll 唤醒所有等待者
}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.time.duration;

type

  INotify = interface(ISynchronizable)
    ['{D6E8F0A1-2B3C-4D5E-6F7A-8B9C0D1E2F3A}']

    {**
     * Wait - 等待通知
     *
     * @desc
     *   阻塞当前线程直到收到通知（NotifyOne 或 NotifyAll）。
     *   如果在调用 Wait 之前已有通知发出，Wait 不会立即返回
     *   （与 Event 不同，Notify 是无状态的）。
     *
     * @thread_safety
     *   线程安全，可多线程同时等待。
     *}
    procedure Wait;

    {**
     * WaitTimeout - 带超时的等待
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return True 如果收到通知；False 如果超时
     *
     * @desc
     *   阻塞当前线程直到收到通知或超时。
     *
     * @thread_safety
     *   线程安全。
     *}
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;

    {**
     * WaitDuration - 使用 TDuration 的超时等待
     *
     * @param ADuration 超时时间
     * @return TWaitResult: wrSignaled 如果收到通知；wrTimeout 如果超时
     *
     * @thread_safety
     *   线程安全。
     *}
    function WaitDuration(const ADuration: TDuration): TWaitResult;

    {**
     * NotifyOne - 唤醒一个等待者
     *
     * @desc
     *   唤醒一个正在 Wait 的线程。如果没有等待者，通知丢失。
     *   如果有多个等待者，按 FIFO 顺序唤醒第一个。
     *
     * @thread_safety
     *   线程安全，可从任意线程调用。
     *}
    procedure NotifyOne;

    {**
     * NotifyAll - 唤醒所有等待者
     *
     * @desc
     *   唤醒所有正在 Wait 的线程。如果没有等待者，通知丢失。
     *
     * @thread_safety
     *   线程安全，可从任意线程调用。
     *}
    procedure NotifyAll;

    {**
     * GetWaiterCount - 获取当前等待者数量
     *
     * @return 当前正在等待的线程数量
     *
     * @desc
     *   返回当前等待者数量。此值是瞬时值，主要用于调试和监控。
     *
     * @thread_safety
     *   线程安全（但返回值可能立即过时）。
     *}
    function GetWaiterCount: Integer;
  end;

implementation

end.
