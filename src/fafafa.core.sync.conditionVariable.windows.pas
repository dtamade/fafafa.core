unit fafafa.core.sync.conditionVariable.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.mutex.base,
  fafafa.core.sync.semaphore.base, fafafa.core.sync.conditionVariable.base;

type
  TConditionVariable = class(TInterfacedObject, IConditionVariable)
  private
    {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
    FCond: CONDITION_VARIABLE;
    {$ELSE}
    FWaitSemaphore: ISemaphore;
    FWaitingCount: Integer;
    FLock: ILock;
    FSignalEvent: IEvent;
    {$ENDIF}
    FInternalCS: TRTLCriticalSection; // for ILock semantics on the condvar object itself
  public
    constructor Create;
    destructor Destroy; override;
    // ILock
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    // Condvar ops
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Signal;
    procedure Broadcast;
  end;

implementation

{ TConditionVariable }

constructor TConditionVariable.Create;
begin
  inherited Create;
  InitializeCriticalSection(FInternalCS);
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  InitializeConditionVariable(FCond);
  {$ELSE}
  // 兼容路径：使用信号量/事件与内部自旋锁组合
  FWaitSemaphore := nil; // TODO: 可在需要时延迟创建
  FWaitingCount := 0;
  FLock := nil;
  FSignalEvent := nil;
  {$ENDIF}
end;

destructor TConditionVariable.Destroy;
begin
  {$IFNDEF FAFAFA_SYNC_USE_CONDVAR}
  FWaitSemaphore := nil;
  FLock := nil;
  FSignalEvent := nil;
  {$ENDIF}
  DeleteCriticalSection(FInternalCS);
  inherited Destroy;
end;

procedure TConditionVariable.Wait(const ALock: ILock);
var
  M: IMutex;
  PCS: PRTLCriticalSection;
{$IFNDEF FAFAFA_SYNC_USE_CONDVAR}
  ok: Boolean;
{$ENDIF}
begin
  if ALock = nil then
    raise EArgumentNilException.Create('Lock cannot be nil');

  if not Supports(ALock, IMutex, M) then
    raise ENotSupportedException.Create('Windows ConditionVariable requires IMutex');

  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  // 用 CriticalSection 路径
  PCS := PRTLCriticalSection(M.GetHandle);
  if PCS = nil then raise ENotSupportedException.Create('CondVar requires CriticalSection');
  SleepConditionVariableCS(@FCond, PCS, INFINITE);
  {$ELSE}
  // 兼容路径：较简化的等待（不精准）
  // 先释放锁再等待，之后再重新获取
  ALock.Release;
  try
    if FWaitSemaphore = nil then Exit; // 没有等待对象则直接返回
    FWaitSemaphore.Acquire;
  finally
    ALock.Acquire;
  end;
  {$ENDIF}
end;

function TConditionVariable.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
var
  M: IMutex;
  PCS: PRTLCriticalSection;
  ok: BOOL;
begin
  if ALock = nil then
    raise EArgumentNilException.Create('Lock cannot be nil');

  if not Supports(ALock, IMutex, M) then
    Exit(False);

  if ATimeoutMs = 0 then Exit(False);

  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  PCS := PRTLCriticalSection(M.GetHandle);
  if PCS = nil then Exit(False);
  ok := SleepConditionVariableCS(@FCond, PCS, ATimeoutMs);
  Result := ok;
  {$ELSE}
  ALock.Release;
  try

// ILock methods for the condition variable object
procedure TConditionVariable.Acquire;
begin
  EnterCriticalSection(FInternalCS);
end;

procedure TConditionVariable.Release;
begin
  LeaveCriticalSection(FInternalCS);
end;

function TConditionVariable.TryAcquire: Boolean;
begin
  Result := TryEnterCriticalSection(FInternalCS);
  if Result then
    LeaveCriticalSection(FInternalCS);
end;

    if FWaitSemaphore <> nil then
      Result := FWaitSemaphore.TryAcquire(ATimeoutMs)
    else
      Result := False;
  finally
    ALock.Acquire;
  end;
  {$ENDIF}
end;

procedure TConditionVariable.Signal;
begin
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  WakeConditionVariable(@FCond);
  {$ELSE}
  if FWaitSemaphore <> nil then
    FWaitSemaphore.Release;
  {$ENDIF}
end;

procedure TConditionVariable.Broadcast;
begin
  {$IFDEF FAFAFA_SYNC_USE_CONDVAR}
  WakeAllConditionVariable(@FCond);
  {$ELSE}
  // 简化：无法获知等待者数量，若已维护计数，可循环 Release
  if FWaitSemaphore <> nil then
  begin
    // 粗略广播三次（示例），实际应计数释放
    FWaitSemaphore.Release(3);
  end;
  {$ENDIF}
end;

end.

