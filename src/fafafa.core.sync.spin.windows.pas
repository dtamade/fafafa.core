{**
 * fafafa.core.sync.spin.windows - Windows 平台自旋锁实现
 *
 * @desc
 *   基于原子操作的高性能自旋锁实现，专为 Windows 平台优化。
 *   使用单个原子变量作为锁状态，提供最小的内存占用和最快的操作速度。
 *
 * @implementation_details
 *   - 状态表示：0 = 未锁定，1 = 已锁定
 *   - 原子操作：使用 fafafa.core.atomic 模块
 *   - 自旋策略：继承 TTryLock 的三段式等待策略
 *   - 内存模型：使用适当的内存屏障确保正确性
 *
 * @performance
 *   - 快速路径：单次原子 CAS 操作
 *   - 慢速路径：智能自旋 + 渐进退避
 *   - 内存占用：仅 4 字节状态变量
 *
 * @thread_safety
 *   线程安全，非重入。同一线程重复获取将导致死锁。
 *}
unit fafafa.core.sync.spin.windows;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.spin.base;

type
  {**
   * TSpin - Windows 平台自旋锁实现
   *
   * @desc
   *   基于原子操作的轻量级自旋锁，继承 TTryLock 以获得
   *   三段式等待策略的优化。使用单个原子变量管理锁状态。
   *
   * @state_representation
   *   FState = 0: 锁未被持有
   *   FState = 1: 锁被某个线程持有
   *
   * @atomic_operations
   *   - 获取锁：CAS(0 -> 1)
   *   - 释放锁：Store(0)
   *   - 尝试获取：CAS(0 -> 1)
   *
   * @inheritance
   *   继承自 TTryLock，自动获得三段式等待策略：
   *   1. 紧密自旋：纯 CPU 自旋，适合短期竞争
   *   2. 退避自旋：自旋 + CPU 让出，适合中期竞争
   *   3. 阻塞等待：睡眠为主，适合长期竞争
   *}
  TSpin = class(TTryLock, ISpin)
  private
    FState: LongInt;  // 原子锁状态：0=未锁定，1=已锁定

  protected
    {**
     * 重写默认参数以适应自旋锁的特性
     * 自旋锁应该有更激进的自旋策略
     *}
    function GetDefaultTightSpin: UInt32; override;
    function GetDefaultBackOffSpin: UInt32; override;
    function GetDefaultBlockSleepIntervalMs: UInt32; override;

  public
    {**
     * Create - 构造函数
     *
     * @desc 初始化自旋锁为未锁定状态
     *}
    constructor Create;

    {**
     * Acquire - 获取锁（阻塞式）
     *
     * @desc
     *   阻塞式获取锁，使用简化的自旋策略。
     *   相比继承的 TryAcquire(INFINITE)，这个实现更简洁高效。
     *
     * @blocking 会阻塞直到成功获取锁
     * @thread_safety 线程安全，非重入
     *}
    procedure Acquire; override;

    {**
     * Release - 释放锁
     *
     * @desc
     *   原子地释放锁，允许其他等待的线程获取锁。
     *   必须由持有锁的线程调用。
     *
     * @precondition 当前线程必须持有锁
     * @thread_safety 线程安全
     *}
    procedure Release; override;

    {**
     * TryAcquire - 非阻塞尝试获取锁
     *
     * @return True 如果成功获取锁，False 如果锁被其他线程持有
     *
     * @desc
     *   立即尝试获取锁，不会阻塞。这是最快的获取方式。
     *
     * @non_blocking 立即返回，不会阻塞线程
     * @thread_safety 线程安全
     *}
    function TryAcquire: Boolean; override;

    {**
     * TryAcquire - 带超时的尝试获取锁
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return True 如果在超时时间内成功获取锁，False 如果超时
     *
     * @desc
     *   使用继承的三段式等待策略进行带超时的锁获取。
     *   这个实现利用了 TTryLock 的优化策略。
     *
     * @timeout 在指定时间内尝试获取锁
     * @thread_safety 线程安全
     *}
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;
  end;

{**
 * MakeSpin - 创建 Windows 自旋锁实例
 *
 * @return Windows 平台的自旋锁实现
 *
 * @desc 工厂函数，创建针对 Windows 平台优化的自旋锁实例
 *}
function MakeSpin: ISpin;
implementation

uses
  fafafa.core.atomic,
  fafafa.core.time.cpu;

{ TSpin }

constructor TSpin.Create;
begin
  inherited Create;
  FState := 0;  // 初始化为未锁定状态
end;

{**
 * GetDefaultTightSpin - 自旋锁的紧密自旋次数
 *
 * @desc
 *   自旋锁应该有更激进的紧密自旋策略，因为它专为短期锁设计。
 *   使用比通用锁更大的自旋次数。
 *}
function TSpin.GetDefaultTightSpin: UInt32;
begin
  Result := 8000;  // 比默认值 2000 更激进
end;

{**
 * GetDefaultBackOffSpin - 自旋锁的退避自旋次数
 *
 * @desc
 *   自旋锁的退避阶段也应该更激进一些。
 *}
function TSpin.GetDefaultBackOffSpin: UInt32;
begin
  Result := 100;  // 比默认值 50 稍大
end;

{**
 * GetDefaultBlockSleepIntervalMs - 自旋锁的阻塞睡眠间隔
 *
 * @desc
 *   自旋锁到了阻塞阶段说明竞争很激烈，使用稍短的睡眠间隔。
 *}
function TSpin.GetDefaultBlockSleepIntervalMs: UInt32;
begin
  Result := 1;  // 保持默认值，1ms 已经很合适
end;

procedure TSpin.Acquire;
var
  Expected: LongInt;
begin
  // 快速路径：立即尝试获取
  Expected := 0;
  if atomic_compare_exchange_weak(FState, Expected, 1) then
    Exit;

  // 慢速路径：使用继承的三段式等待策略
  // 这比自定义循环更优化，且代码更简洁
  TryAcquire(High(Cardinal));  // 使用最大超时值实现阻塞等待
end;

procedure TSpin.Release;
begin
  // 极简原子释放 - 使用 fafafa.core.atomic
  atomic_store(FState, 0);
end;

function TSpin.TryAcquire: Boolean;
var
  Expected: LongInt;
begin
  // 极简非阻塞尝试 - 使用 fafafa.core.atomic
  Expected := 0;
  Result := atomic_compare_exchange_weak(FState, Expected, 1);
end;

function TSpin.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  // 使用继承的三段式等待策略，这比自定义实现更优化
  // TTryLock.TryAcquire 会调用我们的 TryAcquire() 方法
  Result := inherited TryAcquire(ATimeoutMs);
end;

// 工厂函数
function MakeSpin: ISpin;
begin
  Result := TSpin.Create;
end;

end.
