{**
 * fafafa.core.sync.spin - 高性能自旋锁模块
 *
 * @desc
 *   提供跨平台的高性能自旋锁实现，适用于锁持有时间极短的高频场景。
 *   自动选择最优的平台特定实现：
 *   - Windows: 基于原子操作的自定义实现
 *   - Unix: 基于 pthread_spinlock_t 的系统实现
 *
 * @performance_characteristics
 *   - 无系统调用开销的快速路径
 *   - 智能自旋策略，避免过度 CPU 占用
 *   - 适合锁持有时间 < 100ns 的场景
 *   - 低竞争环境下性能优于 Mutex
 *
 * @usage_guidelines
 *   - 优先用于保护简单的数据结构更新
 *   - 避免在锁内进行 I/O 或系统调用
 *   - 高竞争场景建议使用 parking_lot Mutex
 *   - 非重入设计，同一线程重复获取将死锁
 *
 * @cross_platform
 *   支持 Windows 和 Unix 系统，自动选择最优实现。
 *
 * @example
 *   var
 *     SpinLock: ISpin;
 *   begin
 *     SpinLock := MakeSpin;
 *
 *     // 方式1: 手动管理
 *     SpinLock.Acquire;
 *     try
 *       // 极短的临界区代码
 *     finally
 *       SpinLock.Release;
 *     end;
 *
 *     // 方式2: RAII 管理（推荐）
 *     with SpinLock.LockGuard do
 *     begin
 *       // 极短的临界区代码
 *     end;
 *   end;
 *}
unit fafafa.core.sync.spin;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.spin.base;

type
  {**
   * ISpin - 高性能自旋锁接口
   *
   * @desc 从基础模块导出的自旋锁接口类型
   *}
  ISpin = fafafa.core.sync.spin.base.ISpin;

  {**
   * ISpinLock - 自旋锁兼容性别名
   *
   * @desc 为了向后兼容而提供的别名，新代码建议使用 ISpin
   * @deprecated 建议使用 ISpin 替代
   *}
  ISpinLock = ISpin;

{**
 * MakeSpin - 创建自旋锁实例
 *
 * @return 自旋锁接口实例
 *
 * @desc
 *   创建一个高性能自旋锁实例，自动选择当前平台的最优实现：
 *   - Windows: 基于原子操作的轻量级实现
 *   - Unix: 基于 pthread_spinlock_t 的系统实现
 *
 * @thread_safety
 *   返回的实例是线程安全的，但非重入。
 *
 * @performance
 *   这是推荐的自旋锁创建方式，提供最佳的平台性能。
 *
 * @usage
 *   var SpinLock := MakeSpin;
 *   // 使用 SpinLock...
 *}
function MakeSpin: ISpin;

{**
 * MakeSpinLock - 创建自旋锁实例（兼容性函数）
 *
 * @return 自旋锁接口实例
 *
 * @desc
 *   向后兼容的自旋锁创建函数，内部调用 MakeSpin。
 *   为了保持 API 兼容性而保留，新代码建议使用 MakeSpin。
 *
 * @deprecated
 *   建议使用 MakeSpin 替代此函数。
 *
 * @inline
 *   使用内联优化，确保最佳性能。
 *}
function MakeSpinLock: ISpinLock; inline;

implementation

uses
  {$IFDEF WINDOWS}
  fafafa.core.sync.spin.windows
  {$ELSE}
  fafafa.core.sync.spin.unix
  {$ENDIF};

function MakeSpin: ISpin;
begin
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.spin.windows.MakeSpin;
  {$ELSE}
  Result := fafafa.core.sync.spin.unix.MakeSpin;
  {$ENDIF}
end;

function MakeSpinLock: ISpinLock;
begin
  Result := MakeSpin;
end;
end.
