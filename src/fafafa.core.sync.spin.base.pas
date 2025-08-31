unit fafafa.core.sync.spin.base;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  {**
   * ISpin - 高性能自旋锁接口
   *
   * @desc
   *   基于原子操作的轻量级同步原语，通过智能自旋策略实现高性能锁定。
   *   参考 parking_lot 的自旋策略：渐进式退避 + CPU 让出。
   *
   * @features
   *   - 无系统调用开销的快速路径
   *   - 智能自旋策略：短期纯自旋 → 中期暂停 → 长期让出 CPU
   *   - 非重入设计，避免复杂性开销
   *   - 跨平台原子操作支持
   *
   * @performance
   *   适用于锁持有时间极短（< 100ns）的高频场景
   *   在低竞争环境下性能优于 Mutex
   *   高竞争环境下建议使用 parking_lot Mutex
   *
   * @thread_safety
   *   线程安全，非重入
   *   同一线程重复获取将导致死锁（这是正确的行为）
   *}
  ISpin = interface(ITryLock)
    ['{F1A2B3C4-D5E6-F7A8-B9C0-D1E2F3A4B5C6}']
  end;

  // 兼容性别名
  ISpinLock = ISpin;

implementation

end.