unit fafafa.core.sync.namedCondvar.windows;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.atomic,
  fafafa.core.base, fafafa.core.sync.base,
  fafafa.core.sync.namedCondvar.base, fafafa.core.sync.mutex.base;

type
  {**
   * TNamedCondVar - Windows implementation of named condition variable
   *
   * @desc
   *   Since Windows doesn't have native named condition variables,
   *   we simulate them using named events and shared memory.
   *   This implementation uses:
   *   - Named auto-reset event for signaling
   *   - Named manual-reset event for broadcasting
   *   - Named mutex for internal synchronization
   *   - Shared memory for waiter count
   *}
  TNamedCondVar = class(TInterfacedObject, INamedCondVar)
  private
    FName: string;
    FSignalEvent: THandle;      // Auto-reset event for Signal
    FBroadcastEvent: THandle;   // Manual-reset event for Broadcast
    FWaiterCountMutex: THandle; // Mutex to protect waiter count
    FSharedMem: THandle;        // Shared memory for waiter count
    FWaiterCount: PInteger;     // Pointer to waiter count in shared memory
    FStats: TNamedCondVarStats;
    FConfig: TNamedCondVarConfig;
    FIsCreator: Boolean;
    FData: Pointer;
    FLastError: TWaitError;
    
    procedure IncrementWaiters;
    procedure DecrementWaiters;
    function GetWaiterCount: Integer;
  public
    constructor Create(const AName: string); overload;
    destructor Destroy; override;
    
    // ICondVar interface methods (inherited)
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Signal;
    procedure Broadcast;
    
    // ILock interface methods (inherited)
    procedure Lock;
    procedure Unlock;
    function TryLock: Boolean; overload;
    function TryLockFor(ATimeoutMs: Cardinal): Boolean; overload;
    
    // ISynchronizable interface methods
    function GetLastError: TWaitError;
    function GetData: Pointer;
    procedure SetData(AData: Pointer);
    
    // Backward compatibility methods
    function Wait(AMutex: IMutex): TWaitResult;
    function WaitFor(AMutex: IMutex; ATimeoutMs: Cardinal): TWaitResult;
    
    // INamedCondVar specific methods
    function GetName: string;
    function GetConfig: TNamedCondVarConfig;
    procedure UpdateConfig(const AConfig: TNamedCondVarConfig);
    function GetStats: TNamedCondVarStats;
    procedure ResetStats;
    function GetHandle: Pointer;
    function IsCreator: Boolean;
  end;

function MakeNamedCondVar(const AName: string): INamedCondVar;

implementation

const
  SHARED_MEM_SIZE = SizeOf(Integer);

constructor TNamedCondVar.Create(const AName: string);
var
  SignalEventName, BroadcastEventName, MutexName, SharedMemName: string;
begin
  inherited Create;
  FName := AName;
  FillChar(FStats, SizeOf(FStats), 0);
  FConfig := DefaulTNamedCondVarConfig;
  FLastError := weNone;
  FData := nil;
  
  // Create unique names for each synchronization object
  SignalEventName := 'Global\CondVar_Signal_' + AName;
  BroadcastEventName := 'Global\CondVar_Broadcast_' + AName;
  MutexName := 'Global\CondVar_Mutex_' + AName;
  SharedMemName := 'Global\CondVar_SharedMem_' + AName;
  
  // Create or open the signal event (auto-reset)
  FSignalEvent := CreateEventW(nil, False, False, PWideChar(WideString(SignalEventName)));
  if FSignalEvent = 0 then
  begin
    if Windows.GetLastError() = 5 then  // ERROR_ACCESS_DENIED
      FSignalEvent := OpenEventW(EVENT_ALL_ACCESS, False, PWideChar(WideString(SignalEventName)));
    if FSignalEvent = 0 then
      raise ESyncError.CreateFmt('Failed to create/open signal event: %d', [Integer(Windows.GetLastError())]);
  end;
  
  // Create or open the broadcast event (manual-reset)
  FBroadcastEvent := CreateEventW(nil, True, False, PWideChar(WideString(BroadcastEventName)));
  if FBroadcastEvent = 0 then
  begin
    if Windows.GetLastError() = 5 then  // ERROR_ACCESS_DENIED
      FBroadcastEvent := OpenEventW(EVENT_ALL_ACCESS, False, PWideChar(WideString(BroadcastEventName)));
    if FBroadcastEvent = 0 then
    begin
      CloseHandle(FSignalEvent);
      raise ESyncError.CreateFmt('Failed to create/open broadcast event: %d', [Integer(Windows.GetLastError())]);
    end;
  end;
  
  // Create or open the mutex for waiter count protection
  FWaiterCountMutex := CreateMutexW(nil, False, PWideChar(WideString(MutexName)));
  if FWaiterCountMutex = 0 then
  begin
    if Windows.GetLastError() = 5 then  // ERROR_ACCESS_DENIED
      FWaiterCountMutex := OpenMutexW(MUTEX_ALL_ACCESS, False, PWideChar(WideString(MutexName)));
    if FWaiterCountMutex = 0 then
    begin
      CloseHandle(FSignalEvent);
      CloseHandle(FBroadcastEvent);
      raise ESyncError.CreateFmt('Failed to create/open mutex: %d', [Integer(Windows.GetLastError())]);
    end;
  end;
  
  // Create or open shared memory for waiter count
  FSharedMem := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE,
                                    0, SHARED_MEM_SIZE, PWideChar(WideString(SharedMemName)));
  if FSharedMem = 0 then
  begin
    CloseHandle(FSignalEvent);
    CloseHandle(FBroadcastEvent);
    CloseHandle(FWaiterCountMutex);
      raise ESyncError.CreateFmt('Failed to create shared memory: %d', [Integer(Windows.GetLastError())]);
  end;
  
  // Map the shared memory
  FWaiterCount := PInteger(MapViewOfFile(FSharedMem, FILE_MAP_ALL_ACCESS, 0, 0, SHARED_MEM_SIZE));
  if FWaiterCount = nil then
  begin
    CloseHandle(FSignalEvent);
    CloseHandle(FBroadcastEvent);
    CloseHandle(FWaiterCountMutex);
    CloseHandle(FSharedMem);
    raise ESyncError.CreateFmt('Failed to map shared memory: %d', [Integer(Windows.GetLastError())]);
  end;
  
  // Initialize waiter count if we created the shared memory
  FIsCreator := (Windows.GetLastError() <> 183);  // ERROR_ALREADY_EXISTS
  if FIsCreator then
    FWaiterCount^ := 0;
end;

destructor TNamedCondVar.Destroy;
begin
  if FWaiterCount <> nil then
    UnmapViewOfFile(FWaiterCount);
  if FSharedMem <> 0 then
    CloseHandle(FSharedMem);
  if FWaiterCountMutex <> 0 then
    CloseHandle(FWaiterCountMutex);
  if FBroadcastEvent <> 0 then
    CloseHandle(FBroadcastEvent);
  if FSignalEvent <> 0 then
    CloseHandle(FSignalEvent);
  inherited Destroy;
end;

procedure TNamedCondVar.IncrementWaiters;
begin
  WaitForSingleObject(FWaiterCountMutex, INFINITE);
  try
    Inc(FWaiterCount^);
  finally
    ReleaseMutex(FWaiterCountMutex);
  end;
end;

procedure TNamedCondVar.DecrementWaiters;
begin
  WaitForSingleObject(FWaiterCountMutex, INFINITE);
  try
    if FWaiterCount^ > 0 then
      Dec(FWaiterCount^);
  finally
    ReleaseMutex(FWaiterCountMutex);
  end;
end;

function TNamedCondVar.GetWaiterCount: Integer;
begin
  WaitForSingleObject(FWaiterCountMutex, INFINITE);
  try
    Result := FWaiterCount^;
  finally
    ReleaseMutex(FWaiterCountMutex);
  end;
end;

procedure TNamedCondVar.Signal;
begin
  AtomicIncrement(FStats.SignalCount);
  
  // Only signal if there are waiters
  if GetWaiterCount > 0 then
  begin
    SetEvent(FSignalEvent);
    AtomicIncrement(FStats.WakeupCount);
  end;
end;

procedure TNamedCondVar.Broadcast;
var
  WaiterCount: Integer;
begin
  AtomicIncrement(FStats.BroadcastCount);
  
  WaiterCount := GetWaiterCount;
  if WaiterCount > 0 then
  begin
    // Wake all waiters
    SetEvent(FBroadcastEvent);
    Inc(FStats.WakeupCount, WaiterCount);
    
    // LIMITATION: This heuristic has a theoretical race condition.
    // A more robust solution would use a generation counter to ensure
    // all waiters that were waiting at the time of Broadcast() are woken,
    // while new waiters after Broadcast() wait for the next signal.
    // Current approach: short delay then reset the manual-reset event.
    // In high-contention scenarios, consider using Signal() in a loop instead.
    Sleep(1); // Give threads time to wake
    ResetEvent(FBroadcastEvent);
  end;
end;

function TNamedCondVar.Wait(AMutex: IMutex): TWaitResult;
var
  ALock: ILock;
begin
  if Supports(AMutex, ILock, ALock) then
  begin
    if Wait(ALock, INFINITE) then
      Result := wrSignaled
    else
      Result := wrTimeout;
  end
  else
    raise EInvalidArgument.Create('Mutex does not support ILock interface');
end;

function TNamedCondVar.WaitFor(AMutex: IMutex; ATimeoutMs: Cardinal): TWaitResult;
var
  ALock: ILock;
begin
  if Supports(AMutex, ILock, ALock) then
  begin
    if Wait(ALock, ATimeoutMs) then
      Result := wrSignaled
    else
      Result := wrTimeout;
  end
  else
    raise EInvalidArgument.Create('Mutex does not support ILock interface');
end;
function TNamedCondVar.GetName: string;
begin
  Result := FName;
end;

function TNamedCondVar.GetStats: TNamedCondVarStats;
begin
  Result := FStats;
end;

procedure TNamedCondVar.ResetStats;
begin
  FillChar(FStats, SizeOf(FStats), 0);
end;

// ICondVar interface methods implementation
procedure TNamedCondVar.Wait(const ALock: ILock);
begin
  if ALock = nil then
    raise EInvalidArgument.Create('Lock cannot be nil');
  
  AtomicIncrement(FStats.WaitCount);
  IncrementWaiters;
  try
    ALock.Release;
    try
      WaitForSingleObject(FSignalEvent, INFINITE);
      AtomicIncrement(FStats.SuccessfulWaits);
    finally
      ALock.Acquire;
    end;
  finally
    DecrementWaiters;
  end;
end;

function TNamedCondVar.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
var
  Events: array[0..1] of THandle;
  WaitResult: DWORD;
begin
  if ALock = nil then
    raise EInvalidArgument.Create('Lock cannot be nil');
  
  Result := False;
  AtomicIncrement(FStats.WaitCount);
  IncrementWaiters;
  try
    ALock.Release;
    try
      Events[0] := FSignalEvent;
      Events[1] := FBroadcastEvent;
      WaitResult := WaitForMultipleObjects(2, @Events[0], False, ATimeoutMs);
      
      case WaitResult of
        WAIT_OBJECT_0, WAIT_OBJECT_0 + 1:
          begin
            Result := True;
            AtomicIncrement(FStats.SuccessfulWaits);
            FLastError := weNone;
          end;
        WAIT_TIMEOUT:
          begin
            AtomicIncrement(FStats.TimeoutCount);
            FLastError := weNone; // Timeout is not an error
          end;
        else
          FLastError := weSystemError;
      end;
    finally
      ALock.Acquire;
    end;
  finally
    DecrementWaiters;
  end;
end;

// ILock interface methods (condition variables can act as locks)
procedure TNamedCondVar.Lock;
begin
  WaitForSingleObject(FWaiterCountMutex, INFINITE);
end;

procedure TNamedCondVar.Unlock;
begin
  ReleaseMutex(FWaiterCountMutex);
end;

function TNamedCondVar.TryLock: Boolean;
begin
  Result := (WaitForSingleObject(FWaiterCountMutex, 0) = WAIT_OBJECT_0);
  if not Result then
    FLastError := weResourceExhausted
  else
    FLastError := weNone;
end;

function TNamedCondVar.TryLockFor(ATimeoutMs: Cardinal): Boolean;
var
  WaitResult: DWORD;
begin
  WaitResult := WaitForSingleObject(FWaiterCountMutex, ATimeoutMs);
  Result := (WaitResult = WAIT_OBJECT_0);
  
  if Result then
    FLastError := weNone
  else if WaitResult = WAIT_TIMEOUT then
    FLastError := weNone  // Timeout is not an error
  else
    FLastError := weSystemError;
end;

// ISynchronizable interface methods
function TNamedCondVar.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TNamedCondVar.GetData: Pointer;
begin
  Result := FData;
end;

procedure TNamedCondVar.SetData(AData: Pointer);
begin
  FData := AData;
end;

// INamedCondVar specific methods
function TNamedCondVar.GetConfig: TNamedCondVarConfig;
begin
  Result := FConfig;
end;

procedure TNamedCondVar.UpdateConfig(const AConfig: TNamedCondVarConfig);
begin
  FConfig := AConfig;
end;

function TNamedCondVar.GetHandle: Pointer;
begin
  Result := Pointer(FSignalEvent);
end;

function TNamedCondVar.IsCreator: Boolean;
begin
  Result := FIsCreator;
end;

function MakeNamedCondVar(const AName: string): INamedCondVar;
begin
  Result := TNamedCondVar.Create(AName);
end;

end.
