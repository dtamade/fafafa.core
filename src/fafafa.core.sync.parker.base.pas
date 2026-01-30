unit fafafa.core.sync.parker.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  IParker - Rust 风格的线程暂停/唤醒机制接口（base unit）

  设计目标：
  - 参照 Rust std::thread::park/unpark 的语义
  - 比条件变量更轻量的线程唤醒机制
  - 支持 permit 机制（unpark 可以在 park 之前调用）

  核心 API：
  - Park(): 暂停当前线程，等待 unpark
  - ParkTimeout(ms): 带超时的暂停
  - Unpark(): 发放许可或唤醒已暂停的线程

  Permit 机制：
  - 每个 Parker 有一个二进制许可（permit）
  - Unpark() 设置许可为 available
  - Park() 消费许可，如果没有许可则阻塞
  - 多次 Unpark() 只存储一个许可

  使用场景：
  - 线程间简单的通知/唤醒
  - 生产者-消费者模式
  - 自定义同步原语的基础组件

  注意事项：
  - Parker 实例不绑定特定线程
  - 可以从任意线程调用 Unpark
  - 通常配合线程本地存储使用
}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.time.duration;

type

  IParker = interface(ISynchronizable)
    ['{C5D7E8F9-1A2B-3C4D-5E6F-7A8B9C0D1E2F}']

    {**
     * Park - 暂停当前线程
     *
     * @desc
     *   如果有许可（permit）可用，消费许可并立即返回。
     *   否则阻塞当前线程直到另一个线程调用 Unpark。
     *
     * @thread_safety
     *   线程安全。通常由"拥有"此 Parker 的线程调用。
     *}
    procedure Park;

    {**
     * ParkTimeout - 带超时的暂停
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return True 如果被 Unpark 唤醒；False 如果超时
     *
     * @desc
     *   如果有许可可用，消费许可并立即返回 True。
     *   否则阻塞直到 Unpark 或超时。
     *
     * @thread_safety
     *   线程安全。
     *}
    function ParkTimeout(ATimeoutMs: Cardinal): Boolean;

    {**
     * ParkDuration - 使用 TDuration 的超时暂停
     *
     * @param ADuration 超时时间
     * @return TWaitResult: wrSignaled 如果被 Unpark 唤醒；wrTimeout 如果超时
     *
     * @desc
     *   如果有许可可用，消费许可并立即返回 wrSignaled。
     *   否则阻塞直到 Unpark 或超时。
     *   使用 TDuration 类型提供更灵活的时间单位支持。
     *
     * @thread_safety
     *   线程安全。
     *}
    function ParkDuration(const ADuration: TDuration): TWaitResult;

    {**
     * Unpark - 唤醒或发放许可
     *
     * @desc
     *   如果线程正在 Park 中等待，唤醒它。
     *   否则设置许可为 available，下次 Park 将立即返回。
     *   多次调用只存储一个许可。
     *
     * @thread_safety
     *   线程安全，可从任意线程调用。
     *}
    procedure Unpark;
  end;

implementation

end.
