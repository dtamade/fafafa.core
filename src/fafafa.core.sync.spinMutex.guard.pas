unit fafafa.core.sync.spinMutex.guard;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.spinMutex.base;

{$IFDEF WINDOWS}
function GetTickCount64: QWord; external 'kernel32' name 'GetTickCount64';
{$ELSE}
function GetTickCount64: QWord;
{$ENDIF}

type
  // 前向声明
  TSpinMutexImpl = class;

  // ===== RAII 自旋互斥锁守卫实现 =====
  TSpinMutexGuard = class(TInterfacedObject, ISpinMutexGuard)
  private
    FMutex: TSpinMutexImpl;
    FName: string;
    FStartTime: QWord;
    FLocked: Boolean;
    FValid: Boolean;
  protected
    procedure InternalRelease;
  public
    constructor Create(AMutex: TSpinMutexImpl; const AName: string);
    destructor Destroy; override;

    // ISpinMutexGuard 接口实现
    function GetName: string;
    function GetHoldTimeUs: UInt64;
    function IsValid: Boolean;
    procedure Release;
  end;

  // ===== 抽象自旋互斥锁实现基类 =====
  TSpinMutexImpl = class(TInterfacedObject, ISpinMutex)
  private
    FName: string;
    FConfig: TSpinMutexConfig;
    FStats: TSpinMutexStats;
    FOwnerThreadId: TThreadID;
    FLocked: Boolean;
    FLastError: TWaitError;
  protected
    // 子类需要实现的抽象方法
    function DoAcquire: Boolean; virtual; abstract;
    function DoTryAcquire: Boolean; virtual; abstract;
    function DoTryAcquire(ATimeoutMs: Cardinal): Boolean; virtual; abstract;
    procedure DoRelease; virtual; abstract;
    function DoSpinLock: Boolean; virtual; abstract;
    function DoTrySpinLock(AMaxSpins: Cardinal): Boolean; virtual; abstract;

    // 统计更新方法
    procedure UpdateAcquireStats(ASpinCount: Cardinal; ABlocked: Boolean);
    procedure UpdateReleaseStats(AHoldTimeUs: UInt64);
    procedure UpdateTimeoutStats;

    // 内部辅助方法
    function GetCurrentTimeUs: UInt64;
    procedure ValidateConfig(const AConfig: TSpinMutexConfig);
  public
    constructor Create(const AName: string; const AConfig: TSpinMutexConfig);
    destructor Destroy; override;

    // ILock 接口实现
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function GetLastError: TWaitError;

    // ISpinMutex 接口实现 - 配置管理
    function GetConfig: TSpinMutexConfig;
    procedure UpdateConfig(const AConfig: TSpinMutexConfig);

    // ISpinMutex 接口实现 - RAII 接口
    function Lock: ISpinMutexGuard; overload;
    function Lock(const AName: string): ISpinMutexGuard; overload;
    function TryLock: ISpinMutexGuard; overload;
    function TryLock(const AName: string): ISpinMutexGuard; overload;
    function TryLockFor(ATimeoutMs: Cardinal): ISpinMutexGuard; overload;
    function TryLockFor(ATimeoutMs: Cardinal; const AName: string): ISpinMutexGuard; overload;

    // ISpinMutex 接口实现 - 自旋专用接口
    function SpinLock: ISpinMutexGuard; overload;
    function SpinLock(const AName: string): ISpinMutexGuard; overload;
    function TrySpinLock(AMaxSpins: Cardinal): ISpinMutexGuard; overload;
    function TrySpinLock(AMaxSpins: Cardinal; const AName: string): ISpinMutexGuard; overload;

    // ISpinMutex 接口实现 - 统计和监控
    function GetStats: TSpinMutexStats;
    procedure ResetStats;
    function GetSpinEfficiency: Double;

    // ISpinMutex 接口实现 - 标识和调试
    function GetName: string;
    function GetOwnerThreadId: TThreadID;
    function IsLocked: Boolean;

    // 内部方法供守卫使用
    procedure InternalRelease;
  end;

implementation

{$IFNDEF WINDOWS}
// Unix 平台的 GetTickCount64 实现
var
  StartupTime: QWord = 0;

function GetTickCount64: QWord;
begin
  // 简化实现：使用递增计数器模拟时间
  if StartupTime = 0 then
    StartupTime := 1000; // 初始时间戳
  Inc(StartupTime);
  Result := StartupTime;
end;
{$ENDIF}

{ TSpinMutexGuard }

constructor TSpinMutexGuard.Create(AMutex: TSpinMutexImpl; const AName: string);
begin
  inherited Create;
  FMutex := AMutex;
  FName := AName;
  FStartTime := GetTickCount64 * 1000; // 转换为微秒
  FLocked := True;
  FValid := True;
end;

destructor TSpinMutexGuard.Destroy;
begin
  if FLocked and FValid then
    InternalRelease;
  inherited Destroy;
end;

procedure TSpinMutexGuard.InternalRelease;
var
  HoldTime: UInt64;
begin
  if not FLocked or not FValid then
    Exit;

  HoldTime := (GetTickCount64 * 1000) - FStartTime;
  FMutex.InternalRelease;
  FMutex.UpdateReleaseStats(HoldTime);
  
  FLocked := False;
  FValid := False;
end;

function TSpinMutexGuard.GetName: string;
begin
  Result := FName;
end;

function TSpinMutexGuard.GetHoldTimeUs: UInt64;
begin
  if FLocked and FValid then
    Result := (GetTickCount64 * 1000) - FStartTime
  else
    Result := 0;
end;

function TSpinMutexGuard.IsValid: Boolean;
begin
  Result := FValid and FLocked;
end;

procedure TSpinMutexGuard.Release;
begin
  InternalRelease;
end;

{ TSpinMutexImpl }

constructor TSpinMutexImpl.Create(const AName: string; const AConfig: TSpinMutexConfig);
begin
  inherited Create;
  
  if AName = '' then
    raise EInvalidArgument.Create('SpinMutex name cannot be empty');
  if Length(AName) > 255 then
    raise EInvalidArgument.Create('SpinMutex name too long (max 255 characters)');
    
  FName := AName;
  ValidateConfig(AConfig);
  FConfig := AConfig;
  FStats := EmptySpinMutexStats;
  FOwnerThreadId := 0;
  FLocked := False;
  FLastError := weNone;
end;

destructor TSpinMutexImpl.Destroy;
begin
  if FLocked then
  begin
    try
      DoRelease;
    except
      // 忽略析构时的释放错误
    end;
  end;
  inherited Destroy;
end;

procedure TSpinMutexImpl.ValidateConfig(const AConfig: TSpinMutexConfig);
begin
  if AConfig.MaxSpinCount = 0 then
    raise EInvalidArgument.Create('MaxSpinCount must be greater than 0');
  if AConfig.DefaultTimeoutMs = 0 then
    raise EInvalidArgument.Create('DefaultTimeoutMs must be greater than 0');
  if AConfig.MaxBackoffMs > 1000 then
    raise EInvalidArgument.Create('MaxBackoffMs too large (max 1000ms)');
end;

function TSpinMutexImpl.GetCurrentTimeUs: UInt64;
begin
  Result := GetTickCount64 * 1000; // 转换为微秒
end;

procedure TSpinMutexImpl.UpdateAcquireStats(ASpinCount: Cardinal; ABlocked: Boolean);
begin
  if not FConfig.EnableStats then
    Exit;
    
  Inc(FStats.AcquireCount);
  Inc(FStats.TotalSpinCount, ASpinCount);
  
  if ASpinCount > 0 then
    Inc(FStats.SpinSuccessCount);
    
  if ABlocked then
    Inc(FStats.BlockingCount);
    
  // 更新平均值
  if FStats.AcquireCount > 0 then
  begin
    FStats.AvgSpinsPerAcquire := FStats.TotalSpinCount / FStats.AcquireCount;
    if FStats.TotalSpinCount > 0 then
      FStats.SpinEfficiency := FStats.SpinSuccessCount / FStats.TotalSpinCount;
  end;
end;

procedure TSpinMutexImpl.UpdateReleaseStats(AHoldTimeUs: UInt64);
begin
  if not FConfig.EnableStats then
    Exit;
    
  if AHoldTimeUs > FStats.MaxHoldTimeUs then
    FStats.MaxHoldTimeUs := AHoldTimeUs;
    
  // 更新平均持锁时间
  FStats.AvgHoldTimeUs := (FStats.AvgHoldTimeUs * (FStats.AcquireCount - 1) + AHoldTimeUs) / FStats.AcquireCount;
end;

procedure TSpinMutexImpl.UpdateTimeoutStats;
begin
  if FConfig.EnableStats then
    Inc(FStats.TimeoutCount);
end;

// ILock 接口实现
procedure TSpinMutexImpl.Acquire;
var
  SpinCount: Cardinal;
  Success: Boolean;
begin
  SpinCount := 0;
  Success := DoAcquire;
  
  if Success then
  begin
    FOwnerThreadId := GetCurrentThreadId;
    FLocked := True;
    FLastError := weNone;
    UpdateAcquireStats(SpinCount, False);
  end
  else
  begin
    FLastError := weTimeout;
  end;
end;

procedure TSpinMutexImpl.Release;
begin
  if not FLocked then
  begin
    FLastError := weNotOwner;
    Exit;
  end;
  
  if GetCurrentThreadId <> FOwnerThreadId then
  begin
    FLastError := weNotOwner;
    Exit;
  end;
  
  DoRelease;
  FOwnerThreadId := 0;
  FLocked := False;
  FLastError := weNone;
end;

function TSpinMutexImpl.TryAcquire: Boolean;
begin
  Result := DoTryAcquire;
  if Result then
  begin
    FOwnerThreadId := GetCurrentThreadId;
    FLocked := True;
    FLastError := weNone;
    UpdateAcquireStats(0, False);
  end
  else
  begin
    FLastError := weTimeout;
  end;
end;

function TSpinMutexImpl.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := DoTryAcquire(ATimeoutMs);
  if Result then
  begin
    FOwnerThreadId := GetCurrentThreadId;
    FLocked := True;
    FLastError := weNone;
    UpdateAcquireStats(0, True);
  end
  else
  begin
    FLastError := weTimeout;
    UpdateTimeoutStats;
  end;
end;

function TSpinMutexImpl.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

// ISpinMutex 接口实现 - 配置管理
function TSpinMutexImpl.GetConfig: TSpinMutexConfig;
begin
  Result := FConfig;
end;

procedure TSpinMutexImpl.UpdateConfig(const AConfig: TSpinMutexConfig);
begin
  ValidateConfig(AConfig);
  FConfig := AConfig;
end;

// ISpinMutex 接口实现 - RAII 接口
function TSpinMutexImpl.Lock: ISpinMutexGuard;
begin
  Result := Lock('default');
end;

function TSpinMutexImpl.Lock(const AName: string): ISpinMutexGuard;
begin
  if DoAcquire then
  begin
    FOwnerThreadId := GetCurrentThreadId;
    FLocked := True;
    FLastError := weNone;
    UpdateAcquireStats(0, True);
    Result := TSpinMutexGuard.Create(Self, AName);
  end
  else
  begin
    FLastError := weTimeout;
    Result := nil;
  end;
end;

function TSpinMutexImpl.TryLock: ISpinMutexGuard;
begin
  Result := TryLock('default');
end;

function TSpinMutexImpl.TryLock(const AName: string): ISpinMutexGuard;
begin
  if DoTryAcquire then
  begin
    FOwnerThreadId := GetCurrentThreadId;
    FLocked := True;
    FLastError := weNone;
    UpdateAcquireStats(0, False);
    Result := TSpinMutexGuard.Create(Self, AName);
  end
  else
  begin
    FLastError := weTimeout;
    Result := nil;
  end;
end;

function TSpinMutexImpl.TryLockFor(ATimeoutMs: Cardinal): ISpinMutexGuard;
begin
  Result := TryLockFor(ATimeoutMs, 'default');
end;

function TSpinMutexImpl.TryLockFor(ATimeoutMs: Cardinal; const AName: string): ISpinMutexGuard;
begin
  if DoTryAcquire(ATimeoutMs) then
  begin
    FOwnerThreadId := GetCurrentThreadId;
    FLocked := True;
    FLastError := weNone;
    UpdateAcquireStats(0, True);
    Result := TSpinMutexGuard.Create(Self, AName);
  end
  else
  begin
    FLastError := weTimeout;
    UpdateTimeoutStats;
    Result := nil;
  end;
end;

// ISpinMutex 接口实现 - 自旋专用接口
function TSpinMutexImpl.SpinLock: ISpinMutexGuard;
begin
  Result := SpinLock('default');
end;

function TSpinMutexImpl.SpinLock(const AName: string): ISpinMutexGuard;
begin
  if DoSpinLock then
  begin
    FOwnerThreadId := GetCurrentThreadId;
    FLocked := True;
    FLastError := weNone;
    UpdateAcquireStats(FConfig.MaxSpinCount, False);
    Result := TSpinMutexGuard.Create(Self, AName);
  end
  else
  begin
    FLastError := weTimeout;
    Result := nil;
  end;
end;

function TSpinMutexImpl.TrySpinLock(AMaxSpins: Cardinal): ISpinMutexGuard;
begin
  Result := TrySpinLock(AMaxSpins, 'default');
end;

function TSpinMutexImpl.TrySpinLock(AMaxSpins: Cardinal; const AName: string): ISpinMutexGuard;
begin
  if DoTrySpinLock(AMaxSpins) then
  begin
    FOwnerThreadId := GetCurrentThreadId;
    FLocked := True;
    FLastError := weNone;
    UpdateAcquireStats(AMaxSpins, False);
    Result := TSpinMutexGuard.Create(Self, AName);
  end
  else
  begin
    FLastError := weTimeout;
    Result := nil;
  end;
end;

// ISpinMutex 接口实现 - 统计和监控
function TSpinMutexImpl.GetStats: TSpinMutexStats;
begin
  Result := FStats;
end;

procedure TSpinMutexImpl.ResetStats;
begin
  FStats := EmptySpinMutexStats;
end;

function TSpinMutexImpl.GetSpinEfficiency: Double;
begin
  Result := FStats.SpinEfficiency;
end;

// ISpinMutex 接口实现 - 标识和调试
function TSpinMutexImpl.GetName: string;
begin
  Result := FName;
end;

function TSpinMutexImpl.GetOwnerThreadId: TThreadID;
begin
  Result := FOwnerThreadId;
end;

function TSpinMutexImpl.IsLocked: Boolean;
begin
  Result := FLocked;
end;

// 内部方法供守卫使用
procedure TSpinMutexImpl.InternalRelease;
begin
  DoRelease;
  FOwnerThreadId := 0;
  FLocked := False;
  FLastError := weNone;
end;

end.
