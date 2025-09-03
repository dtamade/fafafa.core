unit fafafa.core.sync.spin.atomic;

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│          ______   ______     ______   ______     ______   ______             │
│         /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \            │
│         \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \           │
│          \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\          │
│           \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/          │
│                                                                              │
│                                Studio                                        │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目：fafafa.core.sync.spin.atomic - 原子操作自旋锁实现

📖 概述：
  基于原子操作的高性能自旋锁实现，提供跨平台的通用解决方案。

🔧 特性：
  • 跨平台支持：Windows、Linux、macOS、FreeBSD 等
  • 原子操作优化：使用 InterlockedXxx/GCC Builtin 原子指令
  • 自适应退避：智能退避策略减少 CPU 占用
  • 超时支持：可配置的获取超时机制
  • RAII 支持：自动锁管理和异常安全
  • 无锁设计：基于 CAS (Compare-And-Swap) 操作

⚠️  重要说明：
  自旋锁适用于短时间持锁场景，长时间持锁会导致 CPU 资源浪费。
  请根据具体场景选择合适的锁类型和退避策略。

🧵 线程安全性：
  所有自旋锁操作都是线程安全的，支持多线程并发访问。

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

{$I fafafa.core.settings.inc}


interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.spin.base;

type

  TSpin = class(TTryLock, ISpin)
  private
    FState: LongInt; // 原子锁状态：0=未锁定，1=已锁定

  protected
    {**
     * 重写默认参数以适应超时尝试取锁的自旋锁特性
     * 自旋锁应该有更激进的自旋策略
     *}
    function GetDefaultTightSpin: UInt32; override;
    function GetDefaultBackOffSpin: UInt32; override;
    function GetDefaultBlockSleepIntervalMs: UInt32; override;

  public
    constructor Create;

    {**
     * Acquire - 获取锁（阻塞式）
     *
     * @desc
     *   阻塞式获取锁，使用简化的自旋策略。
     *
     * @blocking 会阻塞直到成功获取锁
     *
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
     *
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
     *
     * @thread_safety 线程安全
     *}
    function TryAcquire: Boolean; override;

    {**
     * TryAcquire - 带超时的尝试获取锁
     *
     * @params
     *   ATimeoutMs 超时时间（毫秒）
     *
     * @return True 如果在超时时间内成功获取锁，False 如果超时
     *
     * @desc
     *   使用继承的三段式等待策略进行带超时的锁获取。
     *   这个实现利用了 TTryLock 的优化策略。
     *
     * @timeout 在指定时间内尝试获取锁
     *
     * @thread_safety 线程安全
     *}
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;
  end;

function MakeSpin: ISpin;

implementation

uses
  fafafa.core.atomic,
  fafafa.core.time.cpu;

{ TSpin }

constructor TSpin.Create;
begin
  inherited Create;
  FState := 0;
end;

function TSpin.GetDefaultTightSpin: UInt32;
begin
  Result := 1000; // 适中的自旋次数，平衡性能和多线程扩展性
end;

function TSpin.GetDefaultBackOffSpin: UInt32;
begin
  Result := 200; // 增加退避次数，改善多线程性能
end;

function TSpin.GetDefaultBlockSleepIntervalMs: UInt32;
begin
  Result := 1; // 保持默认值，1ms 已经很合适
end;

procedure TSpin.Acquire;
var
  Expected: LongInt;
  SpinCount: UInt32;
  BackoffDelay: UInt32;
  i: UInt32;
begin
  // 快速路径：立即尝试获取
  Expected := 0;
  if atomic_compare_exchange_weak(FState, Expected, 1) then
    Exit;

  SpinCount := 0;
  BackoffDelay := 1;
  repeat
    if atomic_load(FState) = 0 then
    begin
      Expected := 0;
      if atomic_compare_exchange_weak(FState, Expected, 1) then
        Exit;
    end;

    Inc(SpinCount);

    // 改进的自旋策略：指数退避 + 智能让出
    if SpinCount <= TightSpin then
    begin
      // 阶段1：紧密自旋
      CpuRelax;
    end
    else if SpinCount <= TightSpin + BackOffSpin then
    begin
      // 阶段2：指数退避
      for i := 1 to BackoffDelay do
        CpuRelax;

      // 指数退避，但限制最大值
      if BackoffDelay < 64 then
        BackoffDelay := BackoffDelay * 2;

      // 定期让出CPU
      if (SpinCount and 7) = 0 then
        SchedYield;
    end
    else
    begin
      // 阶段3：重置计数，强制让出
      SpinCount := 0;
      BackoffDelay := 1;
      SchedYield;  // 强制让出，给其他线程机会
    end;
  until False; // 永不放弃
end;

procedure TSpin.Release;
begin
  atomic_store(FState, 0);
end;

function TSpin.TryAcquire: Boolean;
var
  Expected: LongInt;
begin
  Expected := 0;
  Result := atomic_compare_exchange_weak(FState, Expected, 1);
end;

function TSpin.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := inherited TryAcquire(ATimeoutMs);
end;

function MakeSpin: ISpin;
begin
  Result := TSpin.Create;
end;

end.
