unit fafafa.core.sync.barrier.windows;

{
  Windows 平台屏障同步实现

  特性：
  - 优先使用 SynchronizationBarrier API (Windows Vista+)
  - 运行时检测 API 可用性
  - 自动 fallback 到 mutex + condition variable
  - 支持编译时和运行时配置

  配置宏：
  - FAFAFA_SYNC_USE_WIN_BARRIER: 启用原生 API 支持
  - FAFAFA_SYNC_WIN_RUNTIME_FALLBACK: 启用运行时回退
  - FAFAFA_SYNC_WIN_BARRIER_SPIN_COUNT: 自旋计数
}

{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base,
  fafafa.core.sync.base,
  fafafa.core.sync.barrier.base
  {$IFDEF FAFAFA_SYNC_WIN_RUNTIME_FALLBACK}
  , fafafa.core.sync.conditionVariable.base
  {$ENDIF}
  ;

{$push}
{$packrecords c}
type
  TSynchronizationBarrier = record
    Reserved1, Reserved2: LongWord;        // DWORD
    Reserved3: array[0..1] of PtrUInt;     // ULONG_PTR
    Reserved4, Reserved5: LongWord;        // DWORD
  end;
{$pop}

type
  TBarrier = class(TSynchronizable, IBarrier)
  private
    FParticipantCount: Integer;
    {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
      FBarrier: TSynchronizationBarrier;
      {$IFDEF FAFAFA_SYNC_WIN_RUNTIME_FALLBACK}
        FWaitingCount: Integer;
        FGeneration: Integer;
        FCoordLock: ILock;               // Internal coordination lock
        FCondition: IConditionVariable;  // Internal condition variable
        FUseNative: Boolean;             // runtime switch
      {$ENDIF}
    {$ELSE}
      // Fallback coordination state (condvar + generation):
      FWaitingCount: Integer;
      FGeneration: Integer;
      FCoordLock: ILock;
      FCondition: IConditionVariable;
    {$ENDIF}
  public
    constructor Create(AParticipantCount: Integer);
    destructor Destroy; override;
    // IBarrier
    function Wait: Boolean;
    function GetParticipantCount: Integer;
  end;

{**
 * MakeBarrier - 创建 Windows 平台屏障实例
 *
 * @param AParticipantCount 参与线程数量
 * @return 屏障接口实例
 *}
function MakeBarrier(AParticipantCount: Integer): IBarrier;

implementation

{$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
type
  TInitSyncBarrier = function(var Barrier; TotalThreads, SpinCount: Longint): BOOL; stdcall;
  TEnterSyncBarrier = function(var Barrier; dwFlags: DWORD): BOOL; stdcall;
  TDeleteSyncBarrier = procedure(var Barrier); stdcall;

var
  _InitializeSynchronizationBarrier: TInitSyncBarrier = nil;
  _EnterSynchronizationBarrier: TEnterSyncBarrier = nil;
  _DeleteSynchronizationBarrier: TDeleteSyncBarrier = nil;

function ResolveWinBarrierAPIs: Boolean;
var h: HMODULE;
begin
  h := GetModuleHandle('kernel32.dll');
  if h = 0 then Exit(False);
  _InitializeSynchronizationBarrier := TInitSyncBarrier(GetProcAddress(h, 'InitializeSynchronizationBarrier'));
  _EnterSynchronizationBarrier := TEnterSyncBarrier(GetProcAddress(h, 'EnterSynchronizationBarrier'));
  _DeleteSynchronizationBarrier := TDeleteSyncBarrier(GetProcAddress(h, 'DeleteSynchronizationBarrier'));
  Result := Assigned(_InitializeSynchronizationBarrier) and Assigned(_EnterSynchronizationBarrier) and Assigned(_DeleteSynchronizationBarrier);
end;
{$ENDIF}

// Implementation dependencies
{$IF (not Defined(FAFAFA_SYNC_USE_WIN_BARRIER)) or Defined(FAFAFA_SYNC_WIN_RUNTIME_FALLBACK)}
uses
  fafafa.core.sync.mutex,
  fafafa.core.sync.conditionVariable;
{$ENDIF}

constructor TBarrier.Create(AParticipantCount: Integer);
begin
  inherited Create;
  if AParticipantCount <= 0 then
    raise EInvalidArgument.Create('Barrier participants must be > 0');
  FParticipantCount := AParticipantCount;
  {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
    {$IFDEF FAFAFA_SYNC_WIN_RUNTIME_FALLBACK}
      FUseNative := False;
      if ResolveWinBarrierAPIs then
      begin
        if _InitializeSynchronizationBarrier(FBarrier, FParticipantCount, FAFAFA_SYNC_WIN_BARRIER_SPIN_COUNT) then
          FUseNative := True;
      end;
      if not FUseNative then
      begin
        FWaitingCount := 0;
        FGeneration := 0;
        // Internal primitives for coordination
        FCoordLock := TMutex.Create;
        FCondition := TConditionVariable.Create;
      end;
    {$ELSE}
      if not ResolveWinBarrierAPIs then
        raise ELockError.Create('Windows SynchronizationBarrier APIs are not available');
      if not _InitializeSynchronizationBarrier(FBarrier, FParticipantCount, FAFAFA_SYNC_WIN_BARRIER_SPIN_COUNT) then
        raise ELockError.Create('InitializeSynchronizationBarrier failed');
    {$ENDIF}
  {$ELSE}
    // Pure fallback build (no native barrier compiled in)
    FWaitingCount := 0;
    FGeneration := 0;
    FCoordLock := TMutex.Create;
    FCondition := TConditionVariable.Create;
  {$ENDIF}
end;

destructor TBarrier.Destroy;
begin
  {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
    {$IFDEF FAFAFA_SYNC_WIN_RUNTIME_FALLBACK}
      if FUseNative then
        _DeleteSynchronizationBarrier(FBarrier)
      else
      begin
        FCondition := nil;
        FCoordLock := nil;
      end;
    {$ELSE}
      _DeleteSynchronizationBarrier(FBarrier);
    {$ENDIF}
  {$ELSE}
    FCondition := nil;
    FCoordLock := nil;
  {$ENDIF}
  inherited Destroy;
end;

function TBarrier.Wait: Boolean;
var myGen: Integer;
begin
  {$IFDEF FAFAFA_SYNC_USE_WIN_BARRIER}
    {$IFDEF FAFAFA_SYNC_WIN_RUNTIME_FALLBACK}
      if FUseNative then
      begin
        Result := _EnterSynchronizationBarrier(FBarrier, 0);
        Exit;
      end;
    {$ELSE}
      Result := _EnterSynchronizationBarrier(FBarrier, 0);
      Exit;
    {$ENDIF}
  {$ENDIF}

  {$IF (not Defined(FAFAFA_SYNC_USE_WIN_BARRIER)) or Defined(FAFAFA_SYNC_WIN_RUNTIME_FALLBACK)}
  // Fallback implementation using mutex + condition variable
  // Compiled when: 1) Native barrier disabled, OR 2) Runtime fallback enabled and native API unavailable
  FCoordLock.Acquire;
  try
    myGen := FGeneration;
    Inc(FWaitingCount);
    if FWaitingCount = FParticipantCount then
    begin
      Inc(FGeneration);
      FWaitingCount := 0;
      FCondition.Broadcast;
      Result := True; // serial thread
      Exit;
    end
    else
    begin
      while (myGen = FGeneration) do
        FCondition.Wait(FCoordLock);
      Result := False; // non-serial
      Exit;
    end;
  finally
    FCoordLock.Release;
  end;
  {$ENDIF}
end;



function TBarrier.GetParticipantCount: Integer;
begin
  Result := FParticipantCount;
end;

function MakeBarrier(AParticipantCount: Integer): IBarrier;
begin
  Result := TBarrier.Create(AParticipantCount);
end;

end.

