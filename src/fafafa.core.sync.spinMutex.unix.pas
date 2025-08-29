unit fafafa.core.sync.spinMutex.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.spinMutex.base,
  fafafa.core.sync.spinMutex.guard;

type
  // Unix 平台真正的自旋互斥锁实现
  TSpinMutex = class(TSpinMutexImpl)
  private
    FLockState: LongBool;  // 原子锁状态：False=未锁定，True=已锁定

    // 退避策略实现
    procedure DoBackoff(AIteration: Cardinal);
    procedure DoPause; inline;

    // 原子操作封装
    function AtomicTryLock: Boolean; inline;
    procedure AtomicUnlock; inline;
  protected
    // 实现抽象方法
    function DoAcquire: Boolean; override;
    function DoTryAcquire: Boolean; override;
    function DoTryAcquire(ATimeoutMs: Cardinal): Boolean; override;
    procedure DoRelease; override;
    function DoSpinLock: Boolean; override;
    function DoTrySpinLock(AMaxSpins: Cardinal): Boolean; override;
  public
    constructor Create(const AName: string; const AConfig: TSpinMutexConfig);
  end;

implementation

{ TSpinMutex }

constructor TSpinMutex.Create(const AName: string; const AConfig: TSpinMutexConfig);
begin
  inherited Create(AName, AConfig);
  FLockState := False; // 初始未锁定
end;

// ===== 原子操作封装 =====

function TSpinMutex.AtomicTryLock: Boolean;
begin
  // 使用原子比较交换：如果当前值是 False，则设置为 True
  Result := InterlockedCompareExchange(LongInt(FLockState), 1, 0) = 0;
end;

procedure TSpinMutex.AtomicUnlock;
begin
  // 原子设置为 False（未锁定）
  InterlockedExchange(LongInt(FLockState), 0);
end;

// ===== 退避策略实现 =====

procedure TSpinMutex.DoPause;
begin
  // 在 x86/x64 上使用 PAUSE 指令减少功耗
  // FreePascal 没有内置 pause，使用短暂循环代替
  asm
    {$IFDEF CPUX86_64}
    pause
    {$ELSE}
    nop
    {$ENDIF}
  end;
end;

procedure TSpinMutex.DoBackoff(AIteration: Cardinal);
var
  BackoffTime, i: Cardinal;
begin
  case GetConfig.BackoffStrategy of
    sbsNone:
      DoPause; // 仅 CPU pause

    sbsLinear:
      begin
        BackoffTime := AIteration;
        if BackoffTime > GetConfig.MaxBackoffMs then
          BackoffTime := GetConfig.MaxBackoffMs;
        for i := 1 to BackoffTime * 10 do
          DoPause;
      end;

    sbsExponential:
      begin
        BackoffTime := 1 shl (AIteration and 7); // 限制最大指数
        if BackoffTime > GetConfig.MaxBackoffMs then
          BackoffTime := GetConfig.MaxBackoffMs;
        for i := 1 to BackoffTime * 10 do
          DoPause;
      end;

    sbsAdaptive:
      begin
        // 自适应：前几次快速自旋，然后逐渐增加退避
        if AIteration < 10 then
          DoPause
        else if AIteration < 50 then
        begin
          for i := 1 to AIteration do
            DoPause;
        end
        else
        begin
          // 高争用时使用线程让出
          if (AIteration and $FF) = 0 then
            ThreadSwitch
          else
          begin
            for i := 1 to 100 do
              DoPause;
          end;
        end;
      end;
  end;
end;

// ===== 抽象方法实现 =====

function TSpinMutex.DoAcquire: Boolean;
var
  SpinCount: Cardinal;
begin
  SpinCount := 0;

  // 自旋尝试获取锁
  while SpinCount < GetConfig.MaxSpinCount do
  begin
    if AtomicTryLock then
    begin
      UpdateAcquireStats(SpinCount, False);
      Exit(True);
    end;

    Inc(SpinCount);
    DoBackoff(SpinCount);
  end;

  // 自旋失败，进入阻塞等待（简化实现：继续自旋但降低频率）
  while True do
  begin
    if AtomicTryLock then
    begin
      UpdateAcquireStats(SpinCount, True);
      Exit(True);
    end;

    Inc(SpinCount);
    ThreadSwitch; // 让出 CPU 时间片

    // 避免无限等待，定期检查
    if (SpinCount and $FFFF) = 0 then
    begin
      // 每 65536 次检查一次是否应该超时
      if SpinCount > GetConfig.MaxSpinCount * 100 then
      begin
        UpdateTimeoutStats;
        Exit(False);
      end;
    end;
  end;
end;

function TSpinMutex.DoTryAcquire: Boolean;
begin
  Result := AtomicTryLock;
  if Result then
    UpdateAcquireStats(0, False);
end;

function TSpinMutex.DoTryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: QWord;
  SpinCount: Cardinal;
begin
  if ATimeoutMs = 0 then
    Exit(DoTryAcquire);

  StartTime := GetTickCount64;
  SpinCount := 0;

  while (GetTickCount64 - StartTime) < ATimeoutMs do
  begin
    if AtomicTryLock then
    begin
      UpdateAcquireStats(SpinCount, True);
      Exit(True);
    end;

    Inc(SpinCount);

    // 在超时等待中使用适度的退避
    if SpinCount < GetConfig.MaxSpinCount then
      DoBackoff(SpinCount)
    else
      ThreadSwitch; // 超过自旋次数后让出时间片
  end;

  UpdateTimeoutStats;
  Result := False;
end;

procedure TSpinMutex.DoRelease;
begin
  AtomicUnlock;
end;

function TSpinMutex.DoSpinLock: Boolean;
var
  SpinCount: Cardinal;
begin
  SpinCount := 0;

  // 纯自旋，不回退到阻塞
  while SpinCount < GetConfig.MaxSpinCount do
  begin
    if AtomicTryLock then
    begin
      UpdateAcquireStats(SpinCount, False);
      Exit(True);
    end;

    Inc(SpinCount);
    DoBackoff(SpinCount);
  end;

  // 自旋次数用完，失败
  Result := False;
end;

function TSpinMutex.DoTrySpinLock(AMaxSpins: Cardinal): Boolean;
var
  SpinCount: Cardinal;
begin
  SpinCount := 0;

  while SpinCount < AMaxSpins do
  begin
    if AtomicTryLock then
    begin
      UpdateAcquireStats(SpinCount, False);
      Exit(True);
    end;

    Inc(SpinCount);
    DoBackoff(SpinCount);
  end;

  Result := False;
end;

end.