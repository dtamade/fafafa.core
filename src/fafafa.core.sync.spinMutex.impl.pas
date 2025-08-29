unit fafafa.core.sync.spinMutex.impl;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.spin.base, fafafa.core.sync.spinMutex.base,
  fafafa.core.sync.spin;

type
  // ===== SpinMutex 实现，组合 SpinLock =====
  TSpinMutex = class(TInterfacedObject, ISpinMutex)
  private
    FSpinLock: ISpinLock;                 // 底层 SpinLock 实现
    FName: string;                        // 互斥锁名称
    FConfig: TSpinMutexConfig;            // 当前配置
  public
    constructor Create(const AName: string; const AConfig: TSpinMutexConfig);
    destructor Destroy; override;

    // ILock 接口实现
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function GetLastError: TWaitError;

    // ISpinLock 接口实现（委托给底层 SpinLock）
    function GetMaxSpins: Integer;
    procedure SetMaxSpins(ASpins: Integer);
    function IsCurrentThreadOwner: Boolean;
    function GetLockState: Integer;
    function GetErrorMessage(AError: TWaitError): string;
    procedure ClearLastError;
    function Lock: ISpinLockGuard; overload;
    function TryLock: ISpinLockGuard; overload;
    function TryLock(ATimeoutMs: Cardinal): ISpinLockGuard; overload;

    // ISpinMutex 特有接口实现
    function GetName: string;
    function GetConfig: TSpinMutexConfig;
    procedure UpdateConfig(const AConfig: TSpinMutexConfig);
  end;

implementation

{ TSpinMutex }

constructor TSpinMutex.Create(const AName: string; const AConfig: TSpinMutexConfig);
var
  Policy: TSpinMutexPolicy;
begin
  inherited Create;

  if AName = '' then
    raise Exception.Create('SpinMutex name cannot be empty');
  if Length(AName) > 255 then
    raise Exception.Create('SpinMutex name too long (max 255 characters)');

  FName := AName;
  FConfig := AConfig;

  // 转换配置为 SpinLock 策略
  Policy := SpinMutexConfigToSpinLockPolicy(AConfig);

  // 创建底层 SpinLock
  FSpinLock := fafafa.core.sync.spin.MakeSpinLock(Policy);

  if FSpinLock = nil then
    raise Exception.Create('Failed to create underlying SpinLock');
end;

destructor TSpinMutex.Destroy;
begin
  FSpinLock := nil; // 释放接口引用
  inherited Destroy;
end;

// ===== ILock 接口实现 =====

procedure TSpinMutex.Acquire;
begin
  FSpinLock.Acquire;
end;

procedure TSpinMutex.Release;
begin
  FSpinLock.Release;
end;

function TSpinMutex.TryAcquire: Boolean;
begin
  Result := FSpinLock.TryAcquire;
end;

function TSpinMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := FSpinLock.TryAcquire(ATimeoutMs);
end;

function TSpinMutex.GetLastError: TWaitError;
begin
  Result := FSpinLock.GetLastError;
end;

// ===== ISpinLock 接口实现 =====

function TSpinMutex.GetMaxSpins: Integer;
begin
  Result := FSpinLock.GetMaxSpins;
end;

procedure TSpinMutex.SetMaxSpins(ASpins: Integer);
begin
  FSpinLock.SetMaxSpins(ASpins);
end;

function TSpinMutex.IsCurrentThreadOwner: Boolean;
begin
  Result := FSpinLock.IsCurrentThreadOwner;
end;

function TSpinMutex.GetLockState: Integer;
begin
  Result := FSpinLock.GetLockState;
end;

function TSpinMutex.GetErrorMessage(AError: TWaitError): string;
begin
  Result := FSpinLock.GetErrorMessage(AError);
end;

procedure TSpinMutex.ClearLastError;
begin
  FSpinLock.ClearLastError;
end;

function TSpinMutex.Lock: ISpinLockGuard;
begin
  Result := FSpinLock.Lock;
end;

function TSpinMutex.TryLock: ISpinLockGuard;
begin
  Result := FSpinLock.TryLock;
end;

function TSpinMutex.TryLock(ATimeoutMs: Cardinal): ISpinLockGuard;
begin
  Result := FSpinLock.TryLock(ATimeoutMs);
end;

// ===== ISpinMutex 特有接口实现 =====

function TSpinMutex.GetName: string;
begin
  Result := FName;
end;

function TSpinMutex.GetConfig: TSpinMutexConfig;
begin
  Result := FConfig;
end;

procedure TSpinMutex.UpdateConfig(const AConfig: TSpinMutexConfig);
var
  Policy: TSpinMutexPolicy;
begin
  FConfig := AConfig;
  
  // 转换配置为 SpinLock 策略并更新
  Policy := SpinMutexConfigToSpinLockPolicy(AConfig);
  FSpinLock.UpdatePolicy(Policy);
end;

end.
