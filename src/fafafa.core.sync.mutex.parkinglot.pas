unit fafafa.core.sync.mutex.parkinglot;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base
  {$IFNDEF WINDOWS}
  , BaseUnix
  {$ENDIF};

type
  // 直接移植 Rust parking_lot 的 RawMutex 实现
  TParkingLotMutex = class(TInterfacedObject, ITryLock)
  private
    // 原子状态，使用 32 位 (FreePascal 限制)
    FState: LongWord;

    // 数据指针 (ISynchronizable 接口需要)
    FData: Pointer;

    // 常量定义 (直接移植 Rust 的位掩码)
    const
      LOCKED_BIT = $01;  // 0b01 - 锁定位
      PARKED_BIT = $02;  // 0b10 - 有线程等待位
    
    // 直接移植 Rust parking_lot 的方法
    function TryLockFast: Boolean; inline;
    procedure LockSlow(ATimeoutMs: Cardinal = INFINITE);
    procedure UnlockSlow(AForceFair: Boolean);

    // 自旋等待辅助
    function ShouldSpin(var ASpinCount: Integer): Boolean; inline;

    // parking_lot_core 的简化实现
    procedure ParkThread(ATimeoutMs: Cardinal = INFINITE);
    function UnparkOneThread: Boolean;
    
  public
    constructor Create;
    
    // ISynchronizable 接口实现
    function GetData: Pointer;
    procedure SetData(aData: Pointer);
    
    // ILock 接口实现
    procedure Acquire;
    procedure Release;
    function LockGuard: ILockGuard;
    
    // ITryLock 接口实现
    function TryAcquire: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean;
  end;

function MakeParkingLotMutex: ITryLock;

implementation

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ELSE}
  BaseUnix, Unix, Linux,
  {$ENDIF}
  SysUtils;

{$IFDEF WINDOWS}
// Windows API 声明
type
  TWaitOnAddress = function(Address: Pointer; CompareAddress: Pointer; 
    AddressSize: SIZE_T; dwMilliseconds: DWORD): BOOL; stdcall;
  TWakeByAddressSingle = procedure(Address: Pointer); stdcall;

var
  WaitOnAddressFunc: TWaitOnAddress = nil;
  WakeByAddressSingleFunc: TWakeByAddressSingle = nil;
  HasWaitOnAddress: Boolean = False;

procedure InitWaitOnAddress;
var
  Kernel32: HMODULE;
begin
  Kernel32 := GetModuleHandle('kernel32.dll');
  if Kernel32 <> 0 then
  begin
    WaitOnAddressFunc := TWaitOnAddress(GetProcAddress(Kernel32, 'WaitOnAddress'));
    WakeByAddressSingleFunc := TWakeByAddressSingle(GetProcAddress(Kernel32, 'WakeByAddressSingle'));
    HasWaitOnAddress := Assigned(WaitOnAddressFunc) and Assigned(WakeByAddressSingleFunc);
  end;
end;

{$ELSE}
// Linux futex 系统调用
const
  FUTEX_WAIT = 0;
  FUTEX_WAKE = 1;

type
  TTimeSpec = record
    tv_sec: Int64;
    tv_nsec: Int64;
  end;
  PTimeSpec = ^TTimeSpec;

function futex(uaddr: PLongWord; op: Integer; val: LongWord;
  timeout: PTimeSpec; uaddr2: Pointer; val3: LongWord): Integer; cdecl; external 'c' name 'syscall';

const
  SYS_futex = 202; // x86_64 futex 系统调用号

{$ENDIF}

function MakeParkingLotMutex: ITryLock;
begin
  Result := TParkingLotMutex.Create;
end;

{ TParkingLotMutex }

constructor TParkingLotMutex.Create;
begin
  inherited Create;
  FState := 0; // 初始状态：未锁定，无等待者
  FData := nil;
end;

function TParkingLotMutex.GetData: Pointer;
begin
  Result := FData;
end;

procedure TParkingLotMutex.SetData(aData: Pointer);
begin
  FData := aData;
end;

function TParkingLotMutex.LockGuard: ILockGuard;
begin
  Result := nil; // 简化实现
end;

function TParkingLotMutex.TryLockFast: Boolean;
begin
  // 直接移植 Rust: compare_exchange_weak(0, LOCKED_BIT, Acquire, Relaxed)
  Result := InterlockedCompareExchange(FState, LOCKED_BIT, 0) = 0;
end;

function TParkingLotMutex.ShouldSpin(var ASpinCount: Integer): Boolean;
begin
  // 移植 Rust SpinWait 的逻辑：最多自旋 40 次
  if ASpinCount < 40 then
  begin
    Inc(ASpinCount);
    {$IFDEF CPUX86_64}
    asm
      pause  // CPU 暂停指令，减少功耗
    end;
    {$ENDIF}
    Result := True;
  end
  else
    Result := False;
end;

procedure TParkingLotMutex.ParkThread(ATimeoutMs: Cardinal);
begin
  // 简化的 parking_lot_core::park 实现
  // 验证状态：确保我们应该等待
  if FState <> (LOCKED_BIT or PARKED_BIT) then
    Exit; // 状态已改变，不需要等待

  {$IFDEF WINDOWS}
  if HasWaitOnAddress then
  begin
    // 使用 Windows 8.1+ 的 WaitOnAddress
    WaitOnAddressFunc(@FState, @FState, SizeOf(LongWord), ATimeoutMs);
  end
  else
  begin
    // 回退到简单的等待
    Sleep(1);
  end;
  {$ELSE}
  // 使用 Linux futex 带超时
  var
    TimeSpec: TTimeSpec;
    TimeSpecPtr: PTimeSpec;
  begin
    if ATimeoutMs = INFINITE then
      TimeSpecPtr := nil
    else
    begin
      TimeSpec.tv_sec := ATimeoutMs div 1000;
      TimeSpec.tv_nsec := (ATimeoutMs mod 1000) * 1000000;
      TimeSpecPtr := @TimeSpec;
    end;

    futex(PLongWord(@FState), FUTEX_WAIT, LOCKED_BIT or PARKED_BIT, TimeSpecPtr, nil, 0);
  end;
  {$ENDIF}
end;

function TParkingLotMutex.UnparkOneThread: Boolean;
begin
  // 简化的 parking_lot_core::unpark_one 实现
  {$IFDEF WINDOWS}
  if HasWaitOnAddress then
  begin
    WakeByAddressSingleFunc(@FState);
    Result := True;
  end
  else
    Result := False;
  {$ELSE}
  // 唤醒一个等待的线程
  Result := futex(PLongWord(@FState), FUTEX_WAKE, 1, nil, nil, 0) > 0;
  {$ENDIF}
end;

procedure TParkingLotMutex.LockSlow(ATimeoutMs: Cardinal);
var
  State: LongWord;
  SpinCount: Integer;
begin
  // 直接移植 Rust 的 lock_slow 逻辑
  SpinCount := 0;
  State := FState;

  repeat
    // Grab the lock if it isn't locked, even if there is a queue on it
    if (State and LOCKED_BIT) = 0 then
    begin
      if InterlockedCompareExchange(FState, State or LOCKED_BIT, State) = State then
        Exit; // 成功获取锁
      State := FState;
      Continue;
    end;

    // If there is no queue, try spinning a few times
    if ((State and PARKED_BIT) = 0) and ShouldSpin(SpinCount) then
    begin
      State := FState;
      Continue;
    end;

    // Set the parked bit
    if (State and PARKED_BIT) = 0 then
    begin
      if InterlockedCompareExchange(FState, State or PARKED_BIT, State) = State then
        State := State or PARKED_BIT
      else
      begin
        State := FState;
        Continue;
      end;
    end;

    // Park our thread until we are woken up by an unlock
    // 这里简化实现，使用系统原语
    ParkThread(ATimeoutMs);

    // Loop back and try locking again
    SpinCount := 0;
    State := FState;
  until False;
end;

procedure TParkingLotMutex.Acquire;
begin
  // 直接移植 Rust 的 lock() 方法:
  // if self.state.compare_exchange_weak(0, LOCKED_BIT, Acquire, Relaxed).is_err()
  if not TryLockFast then
  begin
    // self.lock_slow(None);
    LockSlow(INFINITE);
  end;
end;

function TParkingLotMutex.TryAcquire: Boolean;
begin
  Result := TryLockFast;
end;

function TParkingLotMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: DWORD;
  State: LongWord;
  SpinCount: Integer;
  ElapsedMs: DWORD;
  RemainingMs: Cardinal;
begin
  // 先尝试快速获取
  if TryLockFast then
    Exit(True);

  if ATimeoutMs = 0 then
    Exit(False);

  // 使用高精度计时
  StartTime := GetTickCount;
  SpinCount := 0;
  State := FState;

  // 带超时的精确获取循环 - 复用 LockSlow 的逻辑但加入超时检查
  repeat
    // 检查超时
    ElapsedMs := GetTickCount - StartTime;
    if ElapsedMs >= ATimeoutMs then
      Exit(False);

    // Grab the lock if it isn't locked, even if there is a queue on it
    if (State and LOCKED_BIT) = 0 then
    begin
      if InterlockedCompareExchange(FState, State or LOCKED_BIT, State) = State then
        Exit(True); // 成功获取锁
      State := FState;
      Continue;
    end;

    // If there is no queue, try spinning a few times
    if ((State and PARKED_BIT) = 0) and ShouldSpin(SpinCount) then
    begin
      State := FState;
      Continue;
    end;

    // Set the parked bit
    if (State and PARKED_BIT) = 0 then
    begin
      if InterlockedCompareExchange(FState, State or PARKED_BIT, State) = State then
        State := State or PARKED_BIT
      else
      begin
        State := FState;
        Continue;
      end;
    end;

    // Park our thread with remaining timeout
    RemainingMs := ATimeoutMs - ElapsedMs;
    if RemainingMs = 0 then
      Exit(False);

    ParkThread(RemainingMs);

    // Loop back and try locking again
    SpinCount := 0;
    State := FState;
  until False;
end;

// 这些旧方法已被新的实现替代，删除

procedure TParkingLotMutex.Release;
begin
  // 直接移植 Rust 的 unlock() 方法:
  // if self.state.compare_exchange(LOCKED_BIT, 0, Release, Relaxed).is_ok()
  if InterlockedCompareExchange(FState, 0, LOCKED_BIT) = LOCKED_BIT then
    Exit; // 快速路径：没有等待者

  // self.unlock_slow(false);
  UnlockSlow(False);
end;

procedure TParkingLotMutex.UnlockSlow(AForceFair: Boolean);
var
  HasMoreThreads: Boolean;
begin
  // 直接移植 Rust 的 unlock_slow 逻辑
  // 尝试唤醒一个等待的线程
  HasMoreThreads := UnparkOneThread;

  if AForceFair then
  begin
    // 公平解锁：保持锁定状态，直接传递给被唤醒的线程
    if not HasMoreThreads then
      InterlockedExchange(FState, LOCKED_BIT)
    else
      InterlockedExchange(FState, LOCKED_BIT); // 保持锁定，传递给下一个线程
  end
  else
  begin
    // 普通解锁：清除锁定位
    if HasMoreThreads then
      InterlockedExchange(FState, PARKED_BIT) // 仍有等待者
    else
      InterlockedExchange(FState, 0); // 无等待者，完全解锁
  end;
end;

{$IFDEF WINDOWS}
initialization
  InitWaitOnAddress;
{$ENDIF}

end.
