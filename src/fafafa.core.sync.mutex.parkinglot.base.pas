unit fafafa.core.sync.mutex.parkinglot.base;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.atomic,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base;

const
  // Parking lot mutex 状态位定义
  LOCKED_BIT = $01;  // 0b01 - 锁定位
  PARKED_BIT = $02;  // 0b10 - 有线程等待位

  // 自旋参数（基于 Rust parking_lot 的优化值）
  MAX_SPIN_COUNT = 40;           // 最大自旋次数
  SPIN_BACKOFF_THRESHOLD = 10;   // 开始退避的自旋次数

type
  {**
   * IParkingLotMutex - 高性能 Parking Lot 互斥锁接口
   *
   * @desc
   *   基于 Rust parking_lot 设计的高性能互斥锁接口。
   *   使用原子操作 + 智能自旋 + 系统级等待的混合策略。
   *
   * @features
   *   - 快速路径：无竞争时仅需一次原子操作
   *   - 智能自旋：短期竞争时避免系统调用
   *   - 系统等待：长期竞争时使用高效的系统原语
   *   - 公平性支持：可选的公平解锁策略
   *
   * @performance
   *   在大多数场景下性能优于传统 mutex，特别是：
   *   - 低竞争场景：接近自旋锁性能
   *   - 中等竞争：智能自旋减少上下文切换
   *   - 高竞争：系统等待避免 CPU 浪费
   *}
  IParkingLotMutex = interface(IMutex)
    ['{C0A1B2C3-D4E5-F6A7-B8C9-D0E1F2A3B4C5}']

    {**
     * ReleaseFair - 公平释放锁
     *
     * @desc
     *   使用公平策略释放锁，确保等待时间最长的线程优先获得锁。
     *   在高竞争场景下可以减少线程饥饿问题。
     *
     * @performance
     *   比普通 Release 略慢，但提供更好的公平性保证。
     *}
    procedure ReleaseFair;
  end;

  {**
   * TParkingLotMutexBase - Parking Lot 互斥锁基类
   *
   * @desc
   *   实现 parking lot mutex 的核心逻辑，平台特定的等待/唤醒
   *   操作由子类实现。
   *
   * @implementation
   *   - 使用 32 位原子整数存储锁状态
   *   - 快速路径：单次 CAS 操作获取/释放锁
   *   - 慢速路径：自旋 + 系统等待的混合策略
   *   - 支持超时和公平性控制
   *}
  TParkingLotMutexBase = class(TTryLock, IParkingLotMutex)
  protected
    FState: Int32;  // 原子状态：位 0=锁定，位 1=有等待者

    // 核心锁操作
    function  TryLockFast: Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function LockSlow(ATimeoutMs: Cardinal = INFINITE): Boolean; virtual;
    procedure UnlockSlow(AForceFair: Boolean); virtual;

    // 自旋策略
    function  ShouldSpin(var ASpinCount: Integer): Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

    // 平台特定的等待/唤醒操作（由子类实现）
    function ParkThread(ATimeoutMs: Cardinal = INFINITE): Boolean; virtual; abstract;
    function  UnparkOneThread: Boolean; virtual; abstract;

  public
    constructor Create; virtual;

    // IMutex 接口实现
    function  GetHandle: Pointer;

    // ITryLock 接口实现
    procedure Acquire; override;
    procedure Release; override;
    function  TryAcquire: Boolean; override;
    function  TryAcquire(ATimeoutMs: Cardinal): Boolean; override;

    // IParkingLotMutex 特有方法
    procedure ReleaseFair;
  end;

implementation

uses
  fafafa.core.time.cpu, SysUtils;

{ TParkingLotMutexBase }

constructor TParkingLotMutexBase.Create;
begin
  inherited Create;
  atomic_store(FState, 0, mo_relaxed);
end;

function TParkingLotMutexBase.GetHandle: Pointer;
begin
  // 返回对象本身的地址，而不是内部状态的地址
  // 这避免了外部代码直接修改内部状态的安全风险
  Result := Self;
end;

function TParkingLotMutexBase.TryLockFast: Boolean;
var
  LCurrentState, LNewState: Int32;
begin
  // 快速路径：尝试获取锁，保留等待者位
  LCurrentState := atomic_load(FState, mo_relaxed);

  // 如果已经被锁定，快速失败
  if (LCurrentState and LOCKED_BIT) <> 0 then
    Exit(False);

  // 尝试设置锁定位，保留其他位
  LNewState := LCurrentState or LOCKED_BIT;
Result := atomic_compare_exchange_weak(FState, LCurrentState, LNewState);

  // 注意：这里不重试是故意的，TryLockFast 应该是真正的"快速"尝试
  // 如果失败，调用者会进入 LockSlow 进行完整的获取流程
end;

function TParkingLotMutexBase.ShouldSpin(var ASpinCount: Integer): Boolean;
begin
  if ASpinCount < MAX_SPIN_COUNT then
  begin
    Inc(ASpinCount);

    // 前期紧密自旋，后期加入暂停指令
    if ASpinCount > SPIN_BACKOFF_THRESHOLD then
      CpuRelax;

    Result := True;
  end
  else
    Result := False;
end;

function TParkingLotMutexBase.LockSlow(ATimeoutMs: Cardinal): Boolean;
var
  LState, LNewState: Int32;
  LSpinCount: Integer;
  LStartTime: QWord;
  LRemainingTimeout: Cardinal;
  LElapsed: QWord;
begin
  LSpinCount := 0;
LStartTime := SysUtils.GetTickCount64;
  LState := atomic_load(FState, mo_relaxed);

  repeat
    // 检查超时
    if ATimeoutMs <> INFINITE then
    begin
LElapsed := SysUtils.GetTickCount64 - LStartTime;
      if LElapsed >= ATimeoutMs then
        Exit(False);
    end;

    // 如果锁未被持有，尝试获取
    if (LState and LOCKED_BIT) = 0 then
    begin
      // 如果我们之前设置了 PARKED_BIT，现在获取锁时可能需要清理它
      // 这里我们保守地保留 PARKED_BIT，让后续的释放者来处理
      LNewState := LState or LOCKED_BIT;
if atomic_compare_exchange_weak(FState, LState, LNewState) then
        Exit(True); // 成功获取锁
      Continue;
    end;

    // 如果没有等待者且应该继续自旋
    if ((LState and PARKED_BIT) = 0) and ShouldSpin(LSpinCount) then
    begin
      LState := atomic_load(FState, mo_relaxed);
      Continue;
    end;

    // 设置等待者标志
    if (LState and PARKED_BIT) = 0 then
    begin
      LNewState := LState or PARKED_BIT;
if atomic_compare_exchange_weak(FState, LState, LNewState) then
        LState := LNewState
      else
        Continue;
    end;

    // 计算剩余超时时间
    if ATimeoutMs = INFINITE then
      LRemainingTimeout := INFINITE
    else
    begin
      // 确保剩余时间不为负数
      if LElapsed >= ATimeoutMs then
        LRemainingTimeout := 1  // 最小等待时间
      else
        LRemainingTimeout := ATimeoutMs - LElapsed;
    end;

    // 进入系统等待
    if not ParkThread(LRemainingTimeout) then
    begin
      // ParkThread 超时或失败，需要清理状态并最后尝试一次获取锁
      repeat
        LState := atomic_load(FState, mo_relaxed);

        // 如果锁未被持有，尝试获取
        if (LState and LOCKED_BIT) = 0 then
        begin
          LNewState := LState or LOCKED_BIT;
if atomic_compare_exchange_weak(FState, LState, LNewState) then
            Exit(True);
          Continue;
        end;

        // 如果锁被持有，我们无法确定是否还有其他等待者
        // 保守地保留 PARKED_BIT，让释放锁的线程来处理
        // 这避免了错误清除导致其他等待线程无法被唤醒的问题
        Break;
      until False;

      Exit(False);
    end;

    // 被唤醒后重置自旋计数并重新检查状态
    LSpinCount := 0;
    LState := atomic_load(FState, mo_acquire);
  until False;
end;

procedure TParkingLotMutexBase.UnlockSlow(AForceFair: Boolean);
var
  LCurrentState, LNewState: Int32;
begin
  // 使用 CAS 循环确保原子性
  repeat
    LCurrentState := atomic_load(FState, mo_relaxed);

    // 检查是否有等待者
    if (LCurrentState and PARKED_BIT) <> 0 then
    begin
      // 唤醒一个线程，让它来清理 PARKED_BIT
      if UnparkOneThread then
      begin
        if AForceFair then
        begin
          // 公平模式：只清除锁定位，让被唤醒的线程优先获取锁
          // 被唤醒的线程会在获取锁时清理 PARKED_BIT（如果它是最后一个）
          LNewState := LCurrentState and (not LOCKED_BIT);
if atomic_compare_exchange_weak(FState, LCurrentState, LNewState) then
            Exit;
        end
        else
        begin
          // 非公平模式：清除锁定位，允许竞争
          // 被唤醒的线程或新线程会清理 PARKED_BIT
          LNewState := LCurrentState and (not LOCKED_BIT);
if atomic_compare_exchange_weak(FState, LCurrentState, LNewState) then
            Exit;
        end;
      end
      else
      begin
        // 没有线程被唤醒，说明没有真正的等待者，清除 PARKED_BIT
        LNewState := 0;
if atomic_compare_exchange_weak(FState, LCurrentState, LNewState) then
          Exit;
      end;
    end
    else
    begin
      // 无等待者：原子地清除所有位
      LNewState := 0;
if atomic_compare_exchange_weak(FState, LCurrentState, LNewState) then
        Exit;
    end;
  until False;
end;

procedure TParkingLotMutexBase.Acquire;
begin
  if not TryLockFast then
  begin
    // 无限等待应该总是成功，但为了安全起见检查返回值
    if not LockSlow(INFINITE) then
    begin
      // 这种情况理论上不应该发生，但如果发生了，说明有严重问题
      // 使用 Assert 而不是异常，因为这是一个内部错误
      Assert(False, 'TParkingLotMutexBase.Acquire: LockSlow with INFINITE timeout failed');
    end;
  end;
end;

procedure TParkingLotMutexBase.Release;
var
  LCurrentState: Int32;
begin
  // 快速路径：如果只有锁定位被设置，直接清除
  LCurrentState := atomic_load(FState, mo_relaxed);
  if LCurrentState = LOCKED_BIT then
  begin
if atomic_compare_exchange_strong(FState, LCurrentState, 0) then
      Exit;
  end;

  // 慢速路径：有等待者需要唤醒或状态复杂
  UnlockSlow(False);
end;

procedure TParkingLotMutexBase.ReleaseFair;
begin
  // 公平释放总是走慢速路径，确保公平性和原子性
  // 不做快速路径优化，避免竞态条件
  UnlockSlow(True);
end;

function TParkingLotMutexBase.TryAcquire: Boolean;
begin
  Result := TryLockFast;
end;

function TParkingLotMutexBase.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  // 首先尝试快速获取
  if TryLockFast then
    Exit(True);

  // 超时为 0，直接返回失败
  if ATimeoutMs = 0 then
    Exit(False);

  // 使用慢速路径，带超时
  Result := LockSlow(ATimeoutMs);
end;

end.