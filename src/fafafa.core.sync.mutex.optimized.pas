unit fafafa.core.sync.mutex.optimized;

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.event;

type
  // 借鉴 parking_lot 的极简状态管理
  TOptimizedMutex = class(TInterfacedObject, ITryLock)
  private
    // 使用 32 位存储状态 (FreePascal 没有 8 位原子操作)
    FState: LongWord;  // 0b01 = LOCKED, 0b10 = PARKED

    // 公平性计时
    FLastFairUnlock: UInt64;

    // 自旋计数器
    FSpinCount: Integer;

    // 数据指针 (ISynchronizable 接口需要)
    FData: Pointer;
    
    // 常量定义
    const
      LOCKED_BIT = LongWord($01);  // 0b01
      PARKED_BIT = LongWord($02);  // 0b10
      
      // 自旋参数 (借鉴 parking_lot)
      MAX_SPIN_COUNT = 40;
      FAIR_UNLOCK_INTERVAL_NS = 500000; // 0.5ms
      LONG_CRITICAL_SECTION_NS = 1000000; // 1ms
    
    // 快速路径：尝试无竞争获取锁
    function TryLockFast: Boolean; inline;
    
    // 慢速路径：处理竞争情况
    procedure LockSlow;
    
    // 快速解锁
    function TryUnlockFast: Boolean; inline;
    
    // 慢速解锁
    procedure UnlockSlow(AForceFair: Boolean);
    
    // 自适应自旋
    function ShouldSpin: Boolean; inline;
    
    // 检查是否需要公平解锁
    function ShouldBeFair: Boolean; inline;
    
    // 获取高精度时间戳 (纳秒)
    function GetTimeStampNs: UInt64; inline;
    
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

    // 公平解锁 (借鉴 parking_lot)
    procedure ReleaseFair;
  end;

function MakeOptimizedMutex: ITryLock;

implementation

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ELSE}
  BaseUnix, Unix,
  {$ENDIF}
  SysUtils;

{$IFDEF WINDOWS}
var
  GFrequency: Int64;
{$ENDIF}

function MakeOptimizedMutex: ITryLock;
begin
  Result := TOptimizedMutex.Create;
end;

{ TOptimizedMutex }

constructor TOptimizedMutex.Create;
begin
  inherited Create;
  FState := 0;
  FLastFairUnlock := 0;
  FSpinCount := 0;
  FData := nil;
end;

function TOptimizedMutex.GetData: Pointer;
begin
  Result := FData;
end;

procedure TOptimizedMutex.SetData(aData: Pointer);
begin
  FData := aData;
end;

function TOptimizedMutex.LockGuard: ILockGuard;
begin
  // 简化实现，返回 nil
  // 实际应该返回一个 RAII guard 对象
  Result := nil;
end;

function TOptimizedMutex.GetTimeStampNs: UInt64;
{$IFDEF WINDOWS}
var
  Counter: Int64;
{$ELSE}
var
  ts: TTimeSpec;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  QueryPerformanceCounter(Counter);
  Result := (Counter * 1000000000) div GFrequency;
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @ts);
  Result := UInt64(ts.tv_sec) * 1000000000 + UInt64(ts.tv_nsec);
  {$ENDIF}
end;

function TOptimizedMutex.TryLockFast: Boolean;
var
  Expected: LongWord;
begin
  // 快速路径：尝试从 0 -> LOCKED_BIT 的原子转换
  Expected := 0;
  Result := InterlockedCompareExchange(FState, LOCKED_BIT, Expected) = 0;
end;

function TOptimizedMutex.ShouldSpin: Boolean;
begin
  // 自适应自旋：如果没有等待线程且自旋次数未超限
  Result := (FState and PARKED_BIT = 0) and (FSpinCount < MAX_SPIN_COUNT);
end;

procedure TOptimizedMutex.LockSlow;
var
  CurrentState: LongWord;
  SpinCounter: Integer;
begin
  SpinCounter := 0;

  repeat
    CurrentState := FState;

    // 如果锁已释放，尝试获取
    if (CurrentState and LOCKED_BIT) = 0 then
    begin
      if InterlockedCompareExchange(FState, CurrentState or LOCKED_BIT, CurrentState) = CurrentState then
        Exit; // 成功获取锁
      Continue;
    end;
    
    // 自适应自旋
    if ShouldSpin then
    begin
      Inc(SpinCounter);
      if SpinCounter < MAX_SPIN_COUNT then
      begin
        // CPU 暂停指令，减少功耗
        {$IFDEF CPUX86_64}
        asm
          pause
        end;
        {$ENDIF}
        Continue;
      end;
    end;
    
    // 设置 PARKED_BIT 表示有线程等待
    if (CurrentState and PARKED_BIT) = 0 then
    begin
      // 使用 compare-exchange 循环实现原子 OR 操作
      repeat
        CurrentState := FState;
        if (CurrentState and PARKED_BIT) <> 0 then
          Break;
      until InterlockedCompareExchange(FState, CurrentState or PARKED_BIT, CurrentState) = CurrentState;
    end;

    // 进入系统等待 (简化实现，实际应使用 futex/event)
    Sleep(1); // 简化的等待实现
    
    SpinCounter := 0; // 重置自旋计数
  until False;
end;

procedure TOptimizedMutex.Acquire;
begin
  // 快速路径：尝试无竞争获取
  if not TryLockFast then
  begin
    // 慢速路径：处理竞争
    LockSlow;
  end;
  
  // 重置自旋计数
  FSpinCount := 0;
end;

function TOptimizedMutex.TryAcquire: Boolean;
var
  CurrentState: LongWord;
begin
  CurrentState := FState;

  // 如果已锁定，直接返回失败
  if (CurrentState and LOCKED_BIT) <> 0 then
    Exit(False);

  // 尝试原子获取锁
  Result := InterlockedCompareExchange(FState, CurrentState or LOCKED_BIT, CurrentState) = CurrentState;
end;

function TOptimizedMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: UInt64;
  CurrentTime: UInt64;
  TimeoutNs: UInt64;
begin
  // 先尝试快速获取
  if TryAcquire then
    Exit(True);

  // 如果超时为0，直接返回失败
  if ATimeoutMs = 0 then
    Exit(False);

  StartTime := GetTimeStampNs;
  TimeoutNs := UInt64(ATimeoutMs) * 1000000; // 转换为纳秒

  // 带超时的获取循环
  repeat
    if TryAcquire then
      Exit(True);

    CurrentTime := GetTimeStampNs;
    if (CurrentTime - StartTime) >= TimeoutNs then
      Exit(False);

    // 短暂等待
    Sleep(1);
  until False;
end;

function TOptimizedMutex.TryUnlockFast: Boolean;
begin
  // 快速路径：如果没有等待线程，直接清除 LOCKED_BIT
  Result := InterlockedCompareExchange(FState, 0, LOCKED_BIT) = LOCKED_BIT;
end;

function TOptimizedMutex.ShouldBeFair: Boolean;
var
  CurrentTime: UInt64;
begin
  CurrentTime := GetTimeStampNs;
  
  // 如果距离上次公平解锁超过 0.5ms，或者有等待线程，则使用公平解锁
  Result := (FState and PARKED_BIT <> 0) and 
            ((CurrentTime - FLastFairUnlock) > FAIR_UNLOCK_INTERVAL_NS);
end;

procedure TOptimizedMutex.UnlockSlow(AForceFair: Boolean);
var
  CurrentState: LongWord;
begin
  // 简化的慢速解锁实现
  // 实际实现应该使用 parking_lot 风格的线程唤醒机制
  
  if AForceFair or ShouldBeFair then
  begin
    FLastFairUnlock := GetTimeStampNs;
    // 公平解锁：清除 LOCKED_BIT，保持 PARKED_BIT 让其他线程有机会
    // 使用 compare-exchange 循环实现原子 AND 操作
    repeat
      CurrentState := FState;
    until InterlockedCompareExchange(FState, CurrentState and (not LOCKED_BIT), CurrentState) = CurrentState;
  end
  else
  begin
    // 普通解锁：清除所有位
    InterlockedExchange(FState, 0);
  end;
end;

procedure TOptimizedMutex.Release;
begin
  // 快速路径：如果没有等待线程，直接解锁
  if not TryUnlockFast then
  begin
    // 慢速路径：处理等待线程
    UnlockSlow(False);
  end;
end;

procedure TOptimizedMutex.ReleaseFair;
begin
  // 强制公平解锁
  UnlockSlow(True);
end;

{$IFDEF WINDOWS}
initialization
  if not QueryPerformanceFrequency(GFrequency) then
    GFrequency := 1000000; // 回退到微秒精度
{$ENDIF}

end.
