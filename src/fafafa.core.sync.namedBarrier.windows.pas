unit fafafa.core.sync.namedBarrier.windows;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.atomic,
  fafafa.core.sync.namedBarrier.base;

type
  // 真正�?RAII 守卫实现 - 专注于生命周期管�?
  TNamedBarrierGuard = class(TInterfacedObject, INamedBarrierGuard)
  private
    FBarrier: Pointer;              // 指向父屏障的弱引�?
    FIsLastParticipant: Boolean;
    FGeneration: Cardinal;
    FWaitTime: Cardinal;            // 等待时间（毫秒）
    FReleased: Boolean;
    FStartTime: QWord;              // 开始等待的时间

    procedure InternalRelease;
  public
    constructor Create(ABarrier: Pointer; AIsLastParticipant: Boolean; AGeneration: Cardinal);
    destructor Destroy; override;

    // INamedBarrierGuard 接口 - 简化的接口
    function IsLastParticipant: Boolean;
    function GetGeneration: Cardinal;
    function GetWaitTime: Cardinal;
  end;

  TNamedBarrier = class(TSynchronizable, INamedBarrier)
  private
    FEvent: THandle;                // Windows Event 句柄
    FMutex: THandle;                // 保护共享状态的互斥�?
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

    // INamedBarrier 接口 - 简化的现代化接�?
    function Wait: INamedBarrierGuard;
    function TryWait: INamedBarrierGuard;
    function WaitFor(ATimeoutMs: Cardinal): INamedBarrierGuard;

    // 查询操作 - 返回完整快照
    function GetInfo: TNamedBarrierInfo;

    // 控制操作
    procedure Reset;
    procedure Signal;
  end;

implementation

type
  // 共享内存中的屏障状�?
  PBarrierState = ^TBarrierState;
  TBarrierState = record
    WaitingCount: Cardinal;         // 当前等待者数�?
    ParticipantCount: Cardinal;     // 参与者总数
    Generation: Cardinal;           // 屏障代数（用于重置）
    AutoReset: Boolean;             // 是否自动重置
  end;

{ TNamedBarrierGuard }

constructor TNamedBarrierGuard.Create(ABarrier: Pointer; AIsLastParticipant: Boolean; AGeneration: Cardinal);
begin
  inherited Create;
  FBarrier := ABarrier;
  FIsLastParticipant := AIsLastParticipant;
  FGeneration := AGeneration;
  FReleased := False;
  FStartTime := GetTickCount64;
  FWaitTime := 0;
end;

destructor TNamedBarrierGuard.Destroy;
begin
  if not FReleased then
    InternalRelease;
  inherited Destroy;
end;

procedure TNamedBarrierGuard.InternalRelease;
begin
  if FReleased then
    Exit;

  // 计算等待时间
  FWaitTime := GetTickCount64 - FStartTime;

  // RAII: 在守卫析构时进行必要的清�?
  // 这里可以添加屏障状态的清理逻辑
  FReleased := True;
end;

function TNamedBarrierGuard.IsLastParticipant: Boolean;
begin
  Result := FIsLastParticipant;
end;

function TNamedBarrierGuard.GetGeneration: Cardinal;
begin
  Result := FGeneration;
end;

function TNamedBarrierGuard.GetWaitTime: Cardinal;
begin
  if FReleased then
    Result := FWaitTime
  else
    Result := GetTickCount64 - FStartTime;
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

  // Allow Global\\ / Local\\ prefixes; validate remaining characters
  if Pos('Global\', Result) = 1 then
  begin
    for i := 8 to Length(Result) do
      if Result[i] in ['\', '/', ':', '*', '?', '"', '<', '>', '|'] then
        raise EInvalidArgument.Create('Named barrier name contains invalid characters');
    Exit;
  end
  else if Pos('Local\', Result) = 1 then
  begin
    for i := 7 to Length(Result) do
      if Result[i] in ['\', '/', ':', '*', '?', '"', '<', '>', '|'] then
        raise EInvalidArgument.Create('Named barrier name contains invalid characters');
    Exit;
  end;

  // 检�?Windows 对象名称的非法字�?
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
  FSharedMemory := CreateFileMappingW(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, LSize, PWideChar(UnicodeString(LMemoryName)));
  if FSharedMemory = 0 then
    Exit;
    
  FIsCreator := (Windows.GetLastError <> ERROR_ALREADY_EXISTS);
  
  // 映射共享内存
  FSharedData := MapViewOfFile(FSharedMemory, FILE_MAP_ALL_ACCESS, 0, 0, LSize);
  if FSharedData = nil then
  begin
    CloseHandle(FSharedMemory);
    FSharedMemory := 0;
    Exit;
  end;
  
  // 如果是创建者，初始化共享数�?
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
  atomic_increment(PUInt32(GetSharedCounter)^);
end;

function TNamedBarrier.DecrementCounter: Cardinal;
begin
  Result := atomic_decrement(PUInt32(GetSharedCounter)^);
end;

procedure TNamedBarrier.ResetCounter;
begin
  atomic_exchange(PUInt32(GetSharedCounter)^, 0);
  // increase generation atomically
  atomic_increment(PUInt32(@PBarrierState(FSharedData)^.Generation)^);
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
      [AName, SysErrorMessage(Windows.GetLastError)]);
  
  try
    // 创建事件对象（手动重置）
    FEvent := CreateEventW(nil, True, False, PWideChar(UnicodeString(LEventName)));
    if FEvent = 0 then
      raise ELockError.CreateFmt('Failed to create event for named barrier "%s": %s', 
        [AName, SysErrorMessage(Windows.GetLastError)]);
    
    // 创建互斥锁保护共享状�?
    FMutex := CreateMutexW(nil, False, PWideChar(UnicodeString(LMutexName)));
    if FMutex = 0 then
      raise ELockError.CreateFmt('Failed to create mutex for named barrier "%s": %s', 
        [AName, SysErrorMessage(Windows.GetLastError)]);
        
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
  Result := WaitFor(INFINITE);
  if not Assigned(Result) then
    raise ELockError.CreateFmt('Failed to wait on named barrier "%s"', [FName]);
end;

function TNamedBarrier.TryWait: INamedBarrierGuard;
begin
  Result := WaitFor(0);
end;

function TNamedBarrier.WaitFor(ATimeoutMs: Cardinal): INamedBarrierGuard;
var
  LWaitResult: DWORD;
  LCurrentCount: Cardinal;
  LIsLastParticipant: Boolean;
  LCurrentGeneration: Cardinal;
begin
  Result := nil;
  FLastError := weNone;
  
  // 获取互斥锁保护共享状�?
  LWaitResult := WaitForSingleObject(FMutex, ATimeoutMs);
  if LWaitResult <> WAIT_OBJECT_0 then
  begin
    if LWaitResult = WAIT_TIMEOUT then
      FLastError := weTimeout
    else
      FLastError := weSystemError;
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
    // 等待事件被触�?
    LWaitResult := WaitForSingleObject(FEvent, ATimeoutMs);
    if LWaitResult <> WAIT_OBJECT_0 then
    begin
      // 超时或错误，需要减少计数器
      WaitForSingleObject(FMutex, INFINITE);
      try
        // 检查代数是否改变（避免ABA问题�?
        if PBarrierState(FSharedData)^.Generation = LCurrentGeneration then
          DecrementCounter;
      finally
        ReleaseMutex(FMutex);
      end;
      
      if LWaitResult = WAIT_TIMEOUT then
        FLastError := weTimeout
      else
        FLastError := weSystemError;
      Exit;
    end;
  end;
  
  Result := TNamedBarrierGuard.Create(Self, LIsLastParticipant, LCurrentGeneration);
end;

function TNamedBarrier.GetInfo: TNamedBarrierInfo;
begin
  // 初始化结�?
  FillChar(Result, SizeOf(Result), 0);
  Result.Name := FName;
  Result.ParticipantCount := FParticipantCount;
  Result.AutoReset := FAutoReset;

  // 获取动态状�?
  if WaitForSingleObject(FMutex, INFINITE) = WAIT_OBJECT_0 then
  try
    if Assigned(FSharedData) then
    begin
      Result.CurrentWaitingCount := GetSharedCounter^;
      Result.Generation := PBarrierState(FSharedData)^.Generation;
    end;
    Result.IsSignaled := (WaitForSingleObject(FEvent, 0) = WAIT_OBJECT_0);
  finally
    ReleaseMutex(FMutex);
  end;
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


end.
