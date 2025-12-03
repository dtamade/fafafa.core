unit fafafa.core.sync.latch.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  ILatch - Java 风格的一次性倒计数同步原语接口（base unit）

  设计目标：
  - 参照 Java java.util.concurrent.CountDownLatch 的语义
  - 一次性同步原语，计数只能减少不能增加
  - 与 fafafa.core.sync 其他原语保持一致的模块结构

  核心 API：
  - CountDown(): 减少计数 1
  - Await(): 阻塞直到计数为 0
  - AwaitTimeout(ms): 带超时等待
  - GetCount(): 获取当前计数

  使用模式（门控启动）：
    var StartGate := MakeLatch(1);
    for i := 1 to N do
      SpawnWorker(procedure begin
        StartGate.Await;  // 等待启动信号
        // 工作...
      end);
    // 准备就绪
    StartGate.CountDown;  // 所有工作线程同时开始

  使用模式（等待完成）：
    var DoneLatch := MakeLatch(N);
    for i := 1 to N do
      SpawnWorker(procedure begin
        // 工作...
        DoneLatch.CountDown;  // 工作完成
      end);
    DoneLatch.Await;  // 等待所有工作完成

  与 WaitGroup 的区别：
  - Latch 是一次性的，计数只能减少
  - WaitGroup 可以通过 Add 增加计数
  - Latch 更适合一次性门控场景
}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.time.duration;

type

  ILatch = interface(ISynchronizable)
    ['{B4E8C3D1-7A2F-4B9E-8C1D-5E6F7A8B9C0D}']

    {**
     * CountDown - 减少计数 1
     *
     * @desc
     *   将计数减 1。如果计数已经为 0，则什么都不做。
     *   当计数降为 0 时，唤醒所有等待的线程。
     *
     * @thread_safety
     *   线程安全，可从任意线程调用。
     *}
    procedure CountDown;

    {**
     * Await - 阻塞直到计数为 0
     *
     * @desc
     *   阻塞当前线程直到计数降为 0。如果计数已经为 0，
     *   立即返回。
     *
     * @thread_safety
     *   线程安全，可从任意线程调用。
     *}
    procedure Await;

    {**
     * AwaitTimeout - 带超时的等待
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return True 如果计数变为 0；False 如果超时
     *
     * @desc
     *   阻塞当前线程直到计数降为 0 或超时。
     *
     * @thread_safety
     *   线程安全。
     *}
    function AwaitTimeout(ATimeoutMs: Cardinal): Boolean;

    {**
     * AwaitDuration - 使用 TDuration 的超时等待
     *
     * @param ADuration 超时时间
     * @return TWaitResult: wrSignaled 如果计数变为 0；wrTimeout 如果超时
     *
     * @desc
     *   阻塞当前线程直到计数降为 0 或超时。
     *   使用 TDuration 类型提供更灵活的时间单位支持。
     *
     * @thread_safety
     *   线程安全。
     *}
    function AwaitDuration(const ADuration: TDuration): TWaitResult;

    {**
     * GetCount - 获取当前计数
     *
     * @return 当前计数值
     *
     * @desc
     *   返回计数的当前值。注意这是一个瞬时值，
     *   主要用于调试和监控。
     *
     * @thread_safety
     *   线程安全（但返回值可能立即过时）。
     *}
    function GetCount: Integer;
  end;

implementation

end.
