unit fafafa.core.sync.namedBarrier.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedBarrier.base;

type
  // RAII 守卫实现
  TNamedBarrierGuard = class(TInterfacedObject, INamedBarrierGuard)
  private
    FName: string;
    FParticipantCount: Cardinal;
    FWaitingCount: Cardinal;
    FIsLastParticipant: Boolean;
    FReleased: Boolean;
  public
    constructor Create(const AName: string; AParticipantCount, AWaitingCount: Cardinal; AIsLastParticipant: Boolean);
    destructor Destroy; override;
    
    // INamedBarrierGuard 接口
    function GetName: string;
    function GetParticipantCount: Cardinal;
    function GetWaitingCount: Cardinal;
    function IsLastParticipant: Boolean;
  end;

  TNamedBarrier = class(TInterfacedObject, INamedBarrier)
  private
    FEvent: THandle;                // Windows Event 句柄
    FMutex: THandle;                // 保护共享状态的互斥锁
    FSharedMemory: THandle;         // 共享内存句柄
    FSharedData: Pointer;           // 共享数据指针
    FName: string;
    FParticipantCount: Cardinal;
    FAutoReset: Boolean;
    FIsCreator: Boolean;
    FLastError: TWaitError;
    
    function ValidateName(const AName: string): string;
    function CreateSharedMemory(const AName: string): Boolean;
    function GetSharedCounter: PCardinal;
    procedure IncrementCounter;
    function DecrementCounter: Cardinal;
    procedure ResetCounter;
  public
    constructor Create(const AName: string; const AConfig: TNamedBarrierConfig);
    destructor Destroy; override;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;

    // INamedBarrier 接口
    function Wait: INamedBarrierGuard;
    function TryWait: INamedBarrierGuard;
    function TryWaitFor(ATimeoutMs: Cardinal): INamedBarrierGuard;
    
    function GetName: string;
    function GetParticipantCount: Cardinal;
    function GetWaitingCount: Cardinal;
    function IsSignaled: Boolean;
    
    procedure Reset;
    procedure Signal;
    
    // ===== 增量接口：基于 TResult 的现代化错误处理 =====
    function WaitResult: TNamedBarrierGuardResult;
    function TryWaitResult: TNamedBarrierGuardResult;
    function TryWaitForResult(ATimeoutMs: Cardinal): TNamedBarrierGuardResult;
    function GetWaitingCountResult: TNamedBarrierCardinalResult;
    function IsSignaledResult: TNamedBarrierBoolResult;
    function ResetResult: TNamedBarrierVoidResult;
    function SignalResult: TNamedBarrierVoidResult;

    // 兼容性方法（已弃用）
    procedure Arrive; deprecated;
    function TryArrive: Boolean; deprecated;
    function TryArrive(ATimeoutMs: Cardinal): Boolean; overload; deprecated;
    procedure Arrive(ATimeoutMs: Cardinal); overload; deprecated;
    function GetHandle: Pointer; deprecated;
    function IsCreator: Boolean; deprecated;
  end;

implementation

type
  // 共享内存中的屏障状态
  PBarrierState = ^TBarrierState;
  TBarrierState = record
    WaitingCount: Cardinal;         // 当前等待者数量
    ParticipantCount: Cardinal;     // 参与者总数
    Generation: Cardinal;           // 屏障代数（用于重置）
    AutoReset: Boolean;             // 是否自动重置
  end;

{ TNamedBarrierGuard }

constructor TNamedBarrierGuard.Create(const AName: string; AParticipantCount, AWaitingCount: Cardinal; AIsLastParticipant: Boolean);
begin
  inherited Create;
  FName := AName;
  FParticipantCount := AParticipantCount;
  FWaitingCount := AWaitingCount;
  FIsLastParticipant := AIsLastParticipant;
  FReleased := False;
end;

destructor TNamedBarrierGuard.Destroy;
begin
  if not FReleased then
  begin
    // 守卫析构时的清理工作（如果需要）
    FReleased := True;
  end;
  inherited Destroy;
end;

function TNamedBarrierGuard.GetName: string;
begin
  Result := FName;
end;

function TNamedBarrierGuard.GetParticipantCount: Cardinal;
begin
  Result := FParticipantCount;
end;

function TNamedBarrierGuard.GetWaitingCount: Cardinal;
begin
  Result := FWaitingCount;
end;

function TNamedBarrierGuard.IsLastParticipant: Boolean;
begin
  Result := FIsLastParticipant;
end;

{ TNamedBarrier }

function TNamedBarrier.ValidateName(const AName: string): string;
var
  i: Integer;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named barrier name cannot be empty');

  Result := AName;
  
  if Length(Result) > 260 then
    raise EInvalidArgument.Create('Named barrier name too long (max 260 characters)');

  // 检查 Windows 对象名称的非法字符
  for i := 1 to Length(Result) do
  begin
    if Result[i] in ['\', '/', ':', '*', '?', '"', '<', '>', '|'] then
      raise EInvalidArgument.Create('Named barrier name contains invalid characters');
  end;
end;

function TNamedBarrier.CreateSharedMemory(const AName: string): Boolean;
var
  LMemoryName: string;
  LSize: Cardinal;
begin
  Result := False;
  LMemoryName := 'fafafa_barrier_' + AName;
  LSize := SizeOf(TBarrierState);
  
  // 创建或打开共享内存
  FSharedMemory := CreateFileMappingA(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, LSize, PAnsiChar(AnsiString(LMemoryName)));
  if FSharedMemory = 0 then
    Exit;
    
  FIsCreator := (GetLastError <> ERROR_ALREADY_EXISTS);
  
  // 映射共享内存
  FSharedData := MapViewOfFile(FSharedMemory, FILE_MAP_ALL_ACCESS, 0, 0, LSize);
  if FSharedData = nil then
  begin
    CloseHandle(FSharedMemory);
    FSharedMemory := 0;
    Exit;
  end;
  
  // 如果是创建者，初始化共享数据
  if FIsCreator then
  begin
    with PBarrierState(FSharedData)^ do
    begin
      WaitingCount := 0;
      ParticipantCount := FParticipantCount;
      Generation := 0;
      AutoReset := FAutoReset;
    end;
  end
  else
  begin
    // 如果不是创建者，读取配置
    FParticipantCount := PBarrierState(FSharedData)^.ParticipantCount;
    FAutoReset := PBarrierState(FSharedData)^.AutoReset;
  end;
  
  Result := True;
end;

function TNamedBarrier.GetSharedCounter: PCardinal;
begin
  Result := @PBarrierState(FSharedData)^.WaitingCount;
end;

procedure TNamedBarrier.IncrementCounter;
begin
  InterlockedIncrement(GetSharedCounter^);
end;

function TNamedBarrier.DecrementCounter: Cardinal;
begin
  Result := InterlockedDecrement(GetSharedCounter^);
end;

procedure TNamedBarrier.ResetCounter;
begin
  InterlockedExchange(GetSharedCounter^, 0);
  with PBarrierState(FSharedData)^ do
    InterlockedIncrement(Generation);
end;

constructor TNamedBarrier.Create(const AName: string; const AConfig: TNamedBarrierConfig);
var
  LName: string;
  LEventName, LMutexName: string;
begin
  inherited Create;
  
  LName := ValidateName(AName);
  FName := LName;
  FParticipantCount := AConfig.ParticipantCount;
  FAutoReset := AConfig.AutoReset;
  FLastError := weNone;
  FIsCreator := False;
  
  if FParticipantCount < 2 then
    raise EInvalidArgument.Create('Participant count must be at least 2');
  
  // 处理全局命名空间
  if AConfig.UseGlobalNamespace and (Pos('Global\', LName) <> 1) then
    LName := 'Global\' + LName;
    
  LEventName := 'fafafa_barrier_event_' + LName;
  LMutexName := 'fafafa_barrier_mutex_' + LName;
  
  // 创建共享内存
  if not CreateSharedMemory(LName) then
    raise ELockError.CreateFmt('Failed to create shared memory for named barrier "%s": %s', 
      [AName, SysErrorMessage(GetLastError)]);
  
  try
    // 创建事件对象（手动重置）
    FEvent := CreateEventA(nil, True, False, PAnsiChar(AnsiString(LEventName)));
    if FEvent = 0 then
      raise ELockError.CreateFmt('Failed to create event for named barrier "%s": %s', 
        [AName, SysErrorMessage(GetLastError)]);
    
    // 创建互斥锁保护共享状态
    FMutex := CreateMutexA(nil, False, PAnsiChar(AnsiString(LMutexName)));
    if FMutex = 0 then
      raise ELockError.CreateFmt('Failed to create mutex for named barrier "%s": %s', 
        [AName, SysErrorMessage(GetLastError)]);
        
  except
    if FSharedData <> nil then
      UnmapViewOfFile(FSharedData);
    if FSharedMemory <> 0 then
      CloseHandle(FSharedMemory);
    if FEvent <> 0 then
      CloseHandle(FEvent);
    if FMutex <> 0 then
      CloseHandle(FMutex);
    raise;
  end;
end;

destructor TNamedBarrier.Destroy;
begin
  if FSharedData <> nil then
    UnmapViewOfFile(FSharedData);
  if FSharedMemory <> 0 then
    CloseHandle(FSharedMemory);
  if FEvent <> 0 then
    CloseHandle(FEvent);
  if FMutex <> 0 then
    CloseHandle(FMutex);
  inherited Destroy;
end;

function TNamedBarrier.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TNamedBarrier.Wait: INamedBarrierGuard;
begin
  Result := TryWaitFor(INFINITE);
  if not Assigned(Result) then
    raise ELockError.CreateFmt('Failed to wait on named barrier "%s"', [FName]);
end;

function TNamedBarrier.TryWait: INamedBarrierGuard;
begin
  Result := TryWaitFor(0);
end;

function TNamedBarrier.TryWaitFor(ATimeoutMs: Cardinal): INamedBarrierGuard;
var
  LWaitResult: DWORD;
  LCurrentCount: Cardinal;
  LIsLastParticipant: Boolean;
  LCurrentGeneration: Cardinal;
begin
  Result := nil;
  FLastError := weNone;
  
  // 获取互斥锁保护共享状态
  LWaitResult := WaitForSingleObject(FMutex, ATimeoutMs);
  if LWaitResult <> WAIT_OBJECT_0 then
  begin
    if LWaitResult = WAIT_TIMEOUT then
      FLastError := weTimeout
    else
      FLastError := weError;
    Exit;
  end;
  
  try
    LCurrentGeneration := PBarrierState(FSharedData)^.Generation;
    IncrementCounter;
    LCurrentCount := GetSharedCounter^;
    LIsLastParticipant := (LCurrentCount >= FParticipantCount);
    
    if LIsLastParticipant then
    begin
      // 最后一个参与者：触发事件
      SetEvent(FEvent);
      if FAutoReset then
        ResetCounter;
    end;
    
  finally
    ReleaseMutex(FMutex);
  end;
  
  if not LIsLastParticipant then
  begin
    // 等待事件被触发
    LWaitResult := WaitForSingleObject(FEvent, ATimeoutMs);
    if LWaitResult <> WAIT_OBJECT_0 then
    begin
      // 超时或错误，需要减少计数器
      WaitForSingleObject(FMutex, INFINITE);
      try
        // 检查代数是否改变（避免ABA问题）
        if PBarrierState(FSharedData)^.Generation = LCurrentGeneration then
          DecrementCounter;
      finally
        ReleaseMutex(FMutex);
      end;
      
      if LWaitResult = WAIT_TIMEOUT then
        FLastError := weTimeout
      else
        FLastError := weError;
      Exit;
    end;
  end;
  
  Result := TNamedBarrierGuard.Create(FName, FParticipantCount, LCurrentCount, LIsLastParticipant);
end;

function TNamedBarrier.GetName: string;
begin
  Result := FName;
end;

function TNamedBarrier.GetParticipantCount: Cardinal;
begin
  Result := FParticipantCount;
end;

function TNamedBarrier.GetWaitingCount: Cardinal;
begin
  if FSharedData <> nil then
    Result := GetSharedCounter^
  else
    Result := 0;
end;

function TNamedBarrier.IsSignaled: Boolean;
begin
  Result := (WaitForSingleObject(FEvent, 0) = WAIT_OBJECT_0);
end;

procedure TNamedBarrier.Reset;
begin
  WaitForSingleObject(FMutex, INFINITE);
  try
    ResetCounter;
    ResetEvent(FEvent);
  finally
    ReleaseMutex(FMutex);
  end;
end;

procedure TNamedBarrier.Signal;
begin
  SetEvent(FEvent);
end;

// ===== 增量接口实现：基于 TResult 的现代化错误处理 =====

function TNamedBarrier.WaitResult: TNamedBarrierGuardResult;
begin
  try
    Result := TNamedBarrierGuardResult.Ok(Wait);
  except
    on E: ELockError do
      Result := TNamedBarrierGuardResult.Err(nbeSystemError);
    on E: ETimeoutError do
      Result := TNamedBarrierGuardResult.Err(nbeTimeout);
    on E: Exception do
      Result := TNamedBarrierGuardResult.Err(nbeUnknownError);
  end;
end;

function TNamedBarrier.TryWaitResult: TNamedBarrierGuardResult;
var
  LGuard: INamedBarrierGuard;
begin
  try
    LGuard := TryWait;
    if Assigned(LGuard) then
      Result := TNamedBarrierGuardResult.Ok(LGuard)
    else
      Result := TNamedBarrierGuardResult.Err(nbeInvalidState);
  except
    on E: ELockError do
      Result := TNamedBarrierGuardResult.Err(nbeSystemError);
    on E: Exception do
      Result := TNamedBarrierGuardResult.Err(nbeUnknownError);
  end;
end;

function TNamedBarrier.TryWaitForResult(ATimeoutMs: Cardinal): TNamedBarrierGuardResult;
var
  LGuard: INamedBarrierGuard;
begin
  try
    LGuard := TryWaitFor(ATimeoutMs);
    if Assigned(LGuard) then
      Result := TNamedBarrierGuardResult.Ok(LGuard)
    else
    begin
      case FLastError of
        weTimeout: Result := TNamedBarrierGuardResult.Err(nbeTimeout);
        weError: Result := TNamedBarrierGuardResult.Err(nbeSystemError);
        else Result := TNamedBarrierGuardResult.Err(nbeInvalidState);
      end;
    end;
  except
    on E: ELockError do
      Result := TNamedBarrierGuardResult.Err(nbeSystemError);
    on E: ETimeoutError do
      Result := TNamedBarrierGuardResult.Err(nbeTimeout);
    on E: Exception do
      Result := TNamedBarrierGuardResult.Err(nbeUnknownError);
  end;
end;

function TNamedBarrier.GetWaitingCountResult: TNamedBarrierCardinalResult;
begin
  try
    Result := TNamedBarrierCardinalResult.Ok(GetWaitingCount);
  except
    on E: Exception do
      Result := TNamedBarrierCardinalResult.Err(nbeSystemError);
  end;
end;

function TNamedBarrier.IsSignaledResult: TNamedBarrierBoolResult;
begin
  try
    Result := TNamedBarrierBoolResult.Ok(IsSignaled);
  except
    on E: Exception do
      Result := TNamedBarrierBoolResult.Err(nbeSystemError);
  end;
end;

function TNamedBarrier.ResetResult: TNamedBarrierVoidResult;
begin
  try
    Reset;
    Result := TNamedBarrierVoidResult.Ok(True); // 使用 True 表示成功
  except
    on E: Exception do
      Result := TNamedBarrierVoidResult.Err(nbeSystemError);
  end;
end;

function TNamedBarrier.SignalResult: TNamedBarrierVoidResult;
begin
  try
    Signal;
    Result := TNamedBarrierVoidResult.Ok(True); // 使用 True 表示成功
  except
    on E: Exception do
      Result := TNamedBarrierVoidResult.Err(nbeSystemError);
  end;
end;

// 兼容性方法（已弃用）
procedure TNamedBarrier.Arrive;
var
  LGuard: INamedBarrierGuard;
begin
  LGuard := Wait;
  // 注意：守卫会在方法结束时自动析构
end;

function TNamedBarrier.TryArrive: Boolean;
var
  LGuard: INamedBarrierGuard;
begin
  LGuard := TryWait;
  Result := Assigned(LGuard);
end;

function TNamedBarrier.TryArrive(ATimeoutMs: Cardinal): Boolean;
var
  LGuard: INamedBarrierGuard;
begin
  LGuard := TryWaitFor(ATimeoutMs);
  Result := Assigned(LGuard);
end;

procedure TNamedBarrier.Arrive(ATimeoutMs: Cardinal);
var
  LGuard: INamedBarrierGuard;
begin
  LGuard := TryWaitFor(ATimeoutMs);
  if not Assigned(LGuard) then
    raise ETimeoutError.CreateFmt('Timeout waiting for named barrier "%s"', [FName]);
end;

function TNamedBarrier.GetHandle: Pointer;
begin
  Result := Pointer(FEvent);
end;

function TNamedBarrier.IsCreator: Boolean;
begin
  Result := FIsCreator;
end;

end.
