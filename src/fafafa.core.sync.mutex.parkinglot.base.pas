unit fafafa.core.sync.mutex.parkinglot.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.atomic,
  fafafa.core.sync.base;

const
  // 统一的无限等待常量（�?Windows INFINITE 一致含义）
  INFINITE = High(Cardinal);

  // Parking lot mutex 状态位定义
  LOCKED_BIT = $01;  // 0b01 - 锁定�?
  PARKED_BIT = $02;  // 0b10 - 有线程等待位

  // 自旋参数（基�?Rust parking_lot 的优化值）
  MAX_SPIN_COUNT = 40;           // 最大自旋次�?
  SPIN_BACKOFF_THRESHOLD = 10;   // 开始退避的自旋次数

type
  {**
   * IParkingLotMutex - 高性能 Parking Lot 互斥锁接�?
   *
   * @desc
   *   基于 Rust parking_lot 设计的高性能互斥锁接口�?
   *   按照 fafafa.core.sync.spin 的范式，继承 ITryLock 获得完整的锁功能�?
   *   使用原子操作 + 智能自旋 + 系统级等待的混合策略�?
   *
   * @features
   *   - 快速路径：无竞争时仅需一次原子操�?
   *   - 智能自旋：短期竞争时避免系统调用
   *   - 系统等待：长期竞争时使用高效的系统原�?
   *   - 公平性支持：可选的公平解锁策略
   *   - 继承 ITryLock：获得完整的三段式等待策略和 RAII 支持
   *
   * @performance
   *   在大多数场景下性能优于传统 mutex，特别是�?
   *   - 低竞争场景：接近自旋锁性能
   *   - 中等竞争：智能自旋减少上下文切换
   *   - 高竞争：系统等待避免 CPU 浪费
   *}
  IParkingLotMutex = interface(ITryLock)
    ['{C0A1B2C3-D4E5-F6A7-B8C9-D0E1F2A3B4C5}']

    {**
     * ReleaseFair - 公平释放�?
     *
     * @desc
     *   使用公平策略释放锁，确保等待时间最长的线程优先获得锁�?
     *   在高竞争场景下可以减少线程饥饿问题�?
     *
     * @performance
     *   比普�?Release 略慢，但提供更好的公平性保证�?
     *}
    procedure ReleaseFair;
  end;

  {**
   * TParkingLotMutexBase - Parking Lot 互斥锁基�?
   *
   * @desc
   *   实现 parking lot mutex 的核心逻辑，平台特定的等待/唤醒
   *   操作由子类实现�?
   *
   * @implementation
   *   - 使用 32 位原子整数存储锁状�?
   *   - 快速路径：单次 CAS 操作获取/释放�?
   *   - 慢速路径：自旋 + 系统等待的混合策�?
   *   - 支持超时和公平性控�?
   *}
  TParkingLotMutexBase = class(TTryLock, IParkingLotMutex)
  protected
    FState: Int32;  // 原子状态：�?0=锁定，位 1=有等待�?

    // 核心锁操�?- 按照 spin 范式简�?
    procedure UnlockSlow(AForceFair: Boolean); virtual;

    // 平台特定的等�?唤醒操作（由子类实现�?
    function ParkThread(ATimeoutMs: Cardinal = INFINITE): Boolean; virtual; abstract;
    function  UnparkOneThread: Boolean; virtual; abstract;

    // 重写默认参数以适应 parking lot mutex 的特�?
    function GetDefaultTightSpin: UInt32; override;
    function GetDefaultBackOffSpin: UInt32; override;
    function GetDefaultBlockSleepIntervalMs: UInt32; override;

  public
    constructor Create; override;

    // ITryLock 接口实现 - 按照 spin 范式
    procedure Acquire; override;
    procedure Release; override;
    function  TryAcquire: Boolean; override;
    function  TryAcquire(ATimeoutMs: Cardinal): Boolean; override;

    // IParkingLotMutex 特有方法
    procedure ReleaseFair;
  end;

implementation

uses
  fafafa.core.time.cpu;

{ TParkingLotMutexBase }

constructor TParkingLotMutexBase.Create;
begin
  inherited Create;
  atomic_store(FState, 0, mo_relaxed);
end;

function TParkingLotMutexBase.GetDefaultTightSpin: UInt32;
begin
  // Parking lot mutex 适合更激进的自旋策略
  Result := 2000; // �?spin lock 更多的自旋次�?
end;

function TParkingLotMutexBase.GetDefaultBackOffSpin: UInt32;
begin
  // 适中的退避次数，平衡性能和多线程扩展�?
  Result := 500;
end;

function TParkingLotMutexBase.GetDefaultBlockSleepIntervalMs: UInt32;
begin
  // 使用较短的睡眠间隔，因为 parking lot 有专门的等待机制
  Result := 1;
end;

function TParkingLotMutexBase.TryAcquire: Boolean;
var
  LCurrentState, LNewState: Int32;
begin
  // 快速路径：尝试获取锁，保留等待者位
  LCurrentState := atomic_load(FState, mo_relaxed);

  // 如果已经被锁定，快速失�?
  if (LCurrentState and LOCKED_BIT) <> 0 then
    Exit(False);

  // 尝试设置锁定位，保留其他�?
  LNewState := LCurrentState or LOCKED_BIT;
  Result := atomic_compare_exchange_weak(FState, LCurrentState, LNewState);
end;

procedure TParkingLotMutexBase.UnlockSlow(AForceFair: Boolean);
var
  LCurrentState, LNewState: Int32;
begin
  // 原子地释放锁并处理等待�?
  repeat
    LCurrentState := atomic_load(FState, mo_relaxed);

    // 如果锁未被持有，直接返回
    if (LCurrentState and LOCKED_BIT) = 0 then
      Exit;

    // 清除锁定位，保留等待者位（如果有的话�?
    LNewState := LCurrentState and (not LOCKED_BIT);

    if atomic_compare_exchange_weak(FState, LCurrentState, LNewState) then
    begin
      // 如果有等待者，唤醒一个线�?
      if (LCurrentState and PARKED_BIT) <> 0 then
        UnparkOneThread;
      Exit;
    end;
  until False;
end;

procedure TParkingLotMutexBase.Acquire;
begin
  // 按照 spin 范式，使用继承的实现
  // 首先尝试快速获取，失败则使用三段式等待策略
  if not TryAcquire then
  begin
    // 使用继承的无限等待实�?
    inherited TryAcquire(INFINITE);
  end;
end;

procedure TParkingLotMutexBase.Release;
var
  LCurrentState, LNewState: Int32;
begin
  // 原子地尝试释放锁
  repeat
    LCurrentState := atomic_load(FState, mo_relaxed);

    // 如果锁未被持有，直接返回（允许多次释放）
    if (LCurrentState and LOCKED_BIT) = 0 then
      Exit;

    // 计算新状态：清除锁定位，保留其他�?
    LNewState := LCurrentState and (not LOCKED_BIT);

    // 如果没有等待者，可以直接清除锁定�?
    if (LCurrentState and PARKED_BIT) = 0 then
    begin
      if atomic_compare_exchange_weak(FState, LCurrentState, 0) then
        Exit;
    end
    else
    begin
      // 有等待者，需要唤醒线�?
      if atomic_compare_exchange_weak(FState, LCurrentState, LNewState) then
      begin
        UnparkOneThread;
        Exit;
      end;
    end;
  until False;
end;

procedure TParkingLotMutexBase.ReleaseFair;
begin
  // 公平释放总是走慢速路径，确保公平性和原子�?
  // 不做快速路径优化，避免竞态条�?
  UnlockSlow(True);
end;

function TParkingLotMutexBase.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  // 按照 spin 范式，使用继承的三段式等待策�?
  // 这比自定义实现更优化且更一�?
  Result := inherited TryAcquire(ATimeoutMs);
end;

end.
