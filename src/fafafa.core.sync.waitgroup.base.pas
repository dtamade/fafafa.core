unit fafafa.core.sync.waitgroup.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  IWaitGroup - Go 风格的等待组同步原语接口（base unit）

  设计目标：
  - 参照 Go sync.WaitGroup 的语义和行为
  - 与 fafafa.core.sync 其他原语保持一致的模块结构
  - 线程安全，支持多生产者-单消费者模式

  核心 API：
  - Add(delta): 原子地增加/减少计数器
  - Done(): 等同于 Add(-1)，工作线程完成时调用
  - Wait(): 阻塞直到计数器为 0
  - WaitTimeout(ms): 带超时的等待

  使用模式（典型）：
    var WG := MakeWaitGroup;
    WG.Add(N);  // 添加 N 个工作任务
    for i := 1 to N do
      SpawnWorker(procedure begin
        // 工作...
        WG.Done;
      end);
    WG.Wait;  // 等待所有工作完成

  线程安全约定：
  - Add/Done 可从任意线程调用
  - Wait/WaitTimeout 可从任意线程调用
  - 计数器为负时抛出异常（防止误用）
  - 在 Wait 期间调用 Add 是允许的（但需谨慎）

  注意事项：
  - 与 Go 不同，本实现允许在 Wait 期间调用 Add（Go 会 panic）
  - GetCount 返回的值是瞬时值，不保证原子性（仅用于调试）
}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.time.duration;

type

  IWaitGroup = interface(ISynchronizable)
    ['{A3F7B2E1-9C4D-4A8F-B5E6-7D1C3E2F4A9B}']

    {**
     * Add - 增加或减少计数器
     *
     * @param ADelta 增量（可为正或负）
     *
     * @desc
     *   原子地将 ADelta 加到计数器。如果结果计数器变为负数，
     *   将抛出 EInvalidArgument 异常。
     *
     * @thread_safety
     *   线程安全，可从任意线程调用。
     *
     * @raises EInvalidArgument 如果计数器变为负数
     *}
    procedure Add(ADelta: Integer);

    {**
     * Done - 减少计数器 1
     *
     * @desc
     *   等同于 Add(-1)。工作线程完成任务后调用。
     *
     * @thread_safety
     *   线程安全。
     *
     * @raises EInvalidArgument 如果计数器变为负数
     *}
    procedure Done;

    {**
     * Wait - 阻塞直到计数器为 0
     *
     * @desc
     *   阻塞当前线程直到计数器降为 0。如果计数器已经为 0，
     *   立即返回。
     *
     * @thread_safety
     *   线程安全，可从任意线程调用。
     *}
    procedure Wait;

    {**
     * WaitTimeout - 带超时的等待
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return True 如果计数器变为 0；False 如果超时
     *
     * @desc
     *   阻塞当前线程直到计数器降为 0 或超时。
     *
     * @thread_safety
     *   线程安全。
     *}
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;

    {**
     * WaitDuration - 使用 TDuration 的超时等待
     *
     * @param ADuration 超时时间
     * @return TWaitResult: wrSignaled 如果计数器变为 0；wrTimeout 如果超时
     *
     * @desc
     *   阻塞当前线程直到计数器降为 0 或超时。
     *   使用 TDuration 类型提供更灵活的时间单位支持。
     *
     * @thread_safety
     *   线程安全。
     *}
    function WaitDuration(const ADuration: TDuration): TWaitResult;

    {**
     * GetCount - 获取当前计数器值
     *
     * @return 当前计数器值
     *
     * @desc
     *   返回计数器的当前值。注意这是一个瞬时值，
     *   主要用于调试和监控，不应用于同步逻辑。
     *
     * @thread_safety
     *   线程安全（但返回值可能立即过时）。
     *}
    function GetCount: Integer;
  end;

  // 异常类型（重用 fafafa.core.sync.base 中的定义）
  EWaitGroupError = class(ESyncError);

implementation

end.
