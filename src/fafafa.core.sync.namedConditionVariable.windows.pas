unit fafafa.core.sync.namedConditionVariable.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base,
  fafafa.core.sync.namedConditionVariable.base, fafafa.core.sync.mutex.base;

type
  // 共享状态结构（存储在共享内存中）
  PSharedCondVarState = ^TSharedCondVarState;
  TSharedCondVarState = record
    WaitingCount: LongInt;            // 当前等待者数量
    SignalCount: LongInt;             // 待处理的信号数量
    BroadcastGeneration: LongInt;     // 广播代数，防止虚假唤醒
    Stats: TNamedConditionVariableStats; // 统计信息
  end;

  TNamedConditionVariable = class(TInterfacedObject, INamedConditionVariable)
  private
    FName: string;
    FOriginalName: string;
    FIsCreator: Boolean;
    FLastError: TWaitError;
    FConfig: TNamedConditionVariableConfig;
    
    // Windows 同步对象
    FFileMapping: THandle;            // 共享内存映射
    FSharedState: PSharedCondVarState; // 共享状态指针
    FWaitSemaphore: THandle;          // 等待信号量
    FSignalEvent: THandle;            // 信号事件
    FStateMutex: THandle;             // 状态保护互斥锁
    
    function ValidateName(const AName: string): string;
    function CreateSharedObjects(const AName: string): Boolean;
    function OpenSharedObjects(const AName: string): Boolean;
    procedure CleanupSharedObjects;
    function GetTickCount64: QWord;
    procedure UpdateStats(AOperation: string; AWaitTimeUs: QWord = 0);
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TNamedConditionVariableConfig); overload;
    destructor Destroy; override;
    
    // ILock 接口（条件变量本身的锁定）
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;
    
    // INamedConditionVariable 接口
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Signal;
    procedure Broadcast;
    
    // 查询操作
    function GetName: string;
    function GetConfig: TNamedConditionVariableConfig;
    procedure UpdateConfig(const AConfig: TNamedConditionVariableConfig);
    
    // 统计信息
    function GetStats: TNamedConditionVariableStats;
    procedure ResetStats;
    
    // 兼容性方法
    function GetHandle: Pointer;
    function IsCreator: Boolean;
  end;

implementation

{ TNamedConditionVariable }

constructor TNamedConditionVariable.Create(const AName: string);
begin
  Create(AName, DefaultNamedConditionVariableConfig);
end;

constructor TNamedConditionVariable.Create(const AName: string; const AConfig: TNamedConditionVariableConfig);
var
  LActualName: string;
begin
  inherited Create;
  
  FOriginalName := AName;
  FConfig := AConfig;
  FLastError := weNone;
  FIsCreator := False;
  
  // 初始化句柄
  FFileMapping := 0;
  FSharedState := nil;
  FWaitSemaphore := 0;
  FSignalEvent := 0;
  FStateMutex := 0;
  
  // 验证并处理名称
  LActualName := ValidateName(AName);
  
  // 处理全局命名空间
  if AConfig.UseGlobalNamespace and (Pos('Global\', LActualName) <> 1) then
    LActualName := 'Global\' + LActualName;
    
  FName := LActualName;
  
  // 尝试创建共享对象
  if not CreateSharedObjects(LActualName) then
  begin
    // 创建失败，尝试打开现有的
    if not OpenSharedObjects(LActualName) then
      raise ELockError.CreateFmt('Failed to create or open named condition variable "%s": %s', 
        [AName, SysErrorMessage(GetLastError)]);
  end;
end;

destructor TNamedConditionVariable.Destroy;
begin
  CleanupSharedObjects;
  inherited Destroy;
end;

function TNamedConditionVariable.ValidateName(const AName: string): string;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named condition variable name cannot be empty');
    
  if Length(AName) > 260 then
    raise EInvalidArgument.Create('Named condition variable name too long (max 260 characters)');
    
  // Windows 不允许名称中包含反斜杠（除了命名空间前缀）
  if (Pos('\', AName) > 0) and (Pos('Global\', AName) <> 1) and (Pos('Local\', AName) <> 1) then
    raise EInvalidArgument.Create('Invalid character in named condition variable name');
    
  Result := AName;
end;

function TNamedConditionVariable.CreateSharedObjects(const AName: string): Boolean;
var
  LSecurityAttributes: PSecurityAttributes;
  LMappingName, LSemaphoreName, LEventName, LMutexName: string;
begin
  Result := False;
  LSecurityAttributes := nil;
  
  // 构造各个对象的名称
  LMappingName := AName + '_mapping';
  LSemaphoreName := AName + '_semaphore';
  LEventName := AName + '_event';
  LMutexName := AName + '_mutex';
  
  try
    // 创建共享内存映射
    FFileMapping := CreateFileMappingA(INVALID_HANDLE_VALUE, LSecurityAttributes, 
                                      PAGE_READWRITE, 0, SizeOf(TSharedCondVarState), 
                                      PAnsiChar(AnsiString(LMappingName)));
    if FFileMapping = 0 then Exit;
    
    FIsCreator := (GetLastError <> ERROR_ALREADY_EXISTS);
    
    // 映射共享内存
    FSharedState := MapViewOfFile(FFileMapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
    if FSharedState = nil then Exit;
    
    // 如果是创建者，初始化共享状态
    if FIsCreator then
    begin
      FillChar(FSharedState^, SizeOf(TSharedCondVarState), 0);
      FSharedState^.BroadcastGeneration := 1;
    end;
    
    // 创建信号量（用于等待）
    FWaitSemaphore := CreateSemaphoreA(LSecurityAttributes, 0, FConfig.MaxWaiters, 
                                      PAnsiChar(AnsiString(LSemaphoreName)));
    if FWaitSemaphore = 0 then Exit;
    
    // 创建事件（用于信号通知）
    FSignalEvent := CreateEventA(LSecurityAttributes, False, False, 
                                PAnsiChar(AnsiString(LEventName)));
    if FSignalEvent = 0 then Exit;
    
    // 创建互斥锁（保护共享状态）
    FStateMutex := CreateMutexA(LSecurityAttributes, False, 
                               PAnsiChar(AnsiString(LMutexName)));
    if FStateMutex = 0 then Exit;
    
    Result := True;
    FLastError := weNone;
    
  except
    on E: Exception do
    begin
      CleanupSharedObjects;
      FLastError := weSystemError;
    end;
  end;
end;

function TNamedConditionVariable.OpenSharedObjects(const AName: string): Boolean;
var
  LMappingName, LSemaphoreName, LEventName, LMutexName: string;
begin
  Result := False;

  // 构造各个对象的名称
  LMappingName := AName + '_mapping';
  LSemaphoreName := AName + '_semaphore';
  LEventName := AName + '_event';
  LMutexName := AName + '_mutex';

  try
    // 打开现有的共享内存映射
    FFileMapping := OpenFileMappingA(FILE_MAP_ALL_ACCESS, False,
                                    PAnsiChar(AnsiString(LMappingName)));
    if FFileMapping = 0 then Exit;

    // 映射共享内存
    FSharedState := MapViewOfFile(FFileMapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
    if FSharedState = nil then Exit;

    // 打开现有的同步对象
    FWaitSemaphore := OpenSemaphoreA(SEMAPHORE_ALL_ACCESS, False,
                                    PAnsiChar(AnsiString(LSemaphoreName)));
    if FWaitSemaphore = 0 then Exit;

    FSignalEvent := OpenEventA(EVENT_ALL_ACCESS, False,
                              PAnsiChar(AnsiString(LEventName)));
    if FSignalEvent = 0 then Exit;

    FStateMutex := OpenMutexA(MUTEX_ALL_ACCESS, False,
                             PAnsiChar(AnsiString(LMutexName)));
    if FStateMutex = 0 then Exit;

    Result := True;
    FLastError := weNone;

  except
    on E: Exception do
    begin
      CleanupSharedObjects;
      FLastError := weSystemError;
    end;
  end;
end;

procedure TNamedConditionVariable.CleanupSharedObjects;
begin
  if FSharedState <> nil then
  begin
    UnmapViewOfFile(FSharedState);
    FSharedState := nil;
  end;

  if FFileMapping <> 0 then
  begin
    CloseHandle(FFileMapping);
    FFileMapping := 0;
  end;

  if FWaitSemaphore <> 0 then
  begin
    CloseHandle(FWaitSemaphore);
    FWaitSemaphore := 0;
  end;

  if FSignalEvent <> 0 then
  begin
    CloseHandle(FSignalEvent);
    FSignalEvent := 0;
  end;

  if FStateMutex <> 0 then
  begin
    CloseHandle(FStateMutex);
    FStateMutex := 0;
  end;
end;

function TNamedConditionVariable.GetTickCount64: QWord;
begin
  Result := Windows.GetTickCount64;
end;

procedure TNamedConditionVariable.UpdateStats(AOperation: string; AWaitTimeUs: QWord);
begin
  if not FConfig.EnableStats then Exit;

  // 更新统计信息（在共享内存中）
  if AOperation = 'wait' then
  begin
    InterlockedIncrement64(FSharedState^.Stats.WaitCount);
    InterlockedAdd64(FSharedState^.Stats.TotalWaitTimeUs, AWaitTimeUs);
    if AWaitTimeUs > FSharedState^.Stats.MaxWaitTimeUs then
      FSharedState^.Stats.MaxWaitTimeUs := AWaitTimeUs;
  end
  else if AOperation = 'signal' then
    InterlockedIncrement64(FSharedState^.Stats.SignalCount)
  else if AOperation = 'broadcast' then
    InterlockedIncrement64(FSharedState^.Stats.BroadcastCount)
  else if AOperation = 'timeout' then
    InterlockedIncrement64(FSharedState^.Stats.TimeoutCount);
end;

// ILock 接口实现（条件变量本身的锁定）
procedure TNamedConditionVariable.Acquire;
begin
  if WaitForSingleObject(FStateMutex, INFINITE) <> WAIT_OBJECT_0 then
    raise ELockError.Create('Failed to acquire condition variable lock');
end;

procedure TNamedConditionVariable.Release;
begin
  if not ReleaseMutex(FStateMutex) then
    raise ELockError.Create('Failed to release condition variable lock');
end;

function TNamedConditionVariable.TryAcquire: Boolean;
begin
  Result := WaitForSingleObject(FStateMutex, 0) = WAIT_OBJECT_0;
end;

function TNamedConditionVariable.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := WaitForSingleObject(FStateMutex, ATimeoutMs) = WAIT_OBJECT_0;
end;

function TNamedConditionVariable.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

// 核心条件变量操作
procedure TNamedConditionVariable.Wait(const AMutex: ILock);
begin
  if not Wait(AMutex, INFINITE) then
    raise ELockError.Create('Infinite wait should not fail');
end;

function TNamedConditionVariable.Wait(const AMutex: ILock; ATimeoutMs: Cardinal): Boolean;
var
  LStartTime: QWord;
  LCurrentGeneration: LongInt;
  LWaitResult: DWORD;
begin
  Result := False;

  if AMutex = nil then
    raise EInvalidArgument.Create('Mutex cannot be nil');

  LStartTime := GetTickCount64;

  // 获取状态锁
  if WaitForSingleObject(FStateMutex, ATimeoutMs) <> WAIT_OBJECT_0 then
  begin
    UpdateStats('timeout');
    Exit;
  end;

  try
    // 增加等待者计数
    InterlockedIncrement(FSharedState^.WaitingCount);
    LCurrentGeneration := FSharedState^.BroadcastGeneration;

    // 更新统计
    if FSharedState^.WaitingCount > FSharedState^.Stats.MaxWaiters then
      FSharedState^.Stats.MaxWaiters := FSharedState^.WaitingCount;
    FSharedState^.Stats.CurrentWaiters := FSharedState^.WaitingCount;

  finally
    ReleaseMutex(FStateMutex);
  end;

  // 释放用户互斥锁
  AMutex.Release;

  try
    // 等待信号量或超时
    LWaitResult := WaitForSingleObject(FWaitSemaphore, ATimeoutMs);

    case LWaitResult of
      WAIT_OBJECT_0: begin
        Result := True;
        UpdateStats('wait', (GetTickCount64 - LStartTime) * 1000);
      end;
      WAIT_TIMEOUT: begin
        UpdateStats('timeout');
      end;
      else begin
        FLastError := weSystemError;
      end;
    end;

  finally
    // 重新获取用户互斥锁
    AMutex.Acquire;

    // 减少等待者计数
    if WaitForSingleObject(FStateMutex, 1000) = WAIT_OBJECT_0 then
    begin
      InterlockedDecrement(FSharedState^.WaitingCount);
      FSharedState^.Stats.CurrentWaiters := FSharedState^.WaitingCount;
      ReleaseMutex(FStateMutex);
    end;
  end;
end;

procedure TNamedConditionVariable.Signal;
begin
  // 获取状态锁
  if WaitForSingleObject(FStateMutex, 1000) <> WAIT_OBJECT_0 then
  begin
    FLastError := weSystemError;
    Exit;
  end;

  try
    // 如果有等待者，释放一个信号量
    if FSharedState^.WaitingCount > 0 then
    begin
      ReleaseSemaphore(FWaitSemaphore, 1, nil);
      UpdateStats('signal');
    end;
  finally
    ReleaseMutex(FStateMutex);
  end;
end;

procedure TNamedConditionVariable.Broadcast;
var
  LWaitingCount: LongInt;
begin
  // 获取状态锁
  if WaitForSingleObject(FStateMutex, 1000) <> WAIT_OBJECT_0 then
  begin
    FLastError := weSystemError;
    Exit;
  end;

  try
    LWaitingCount := FSharedState^.WaitingCount;
    if LWaitingCount > 0 then
    begin
      // 释放所有等待者
      ReleaseSemaphore(FWaitSemaphore, LWaitingCount, nil);
      // 增加广播代数，防止虚假唤醒
      InterlockedIncrement(FSharedState^.BroadcastGeneration);
      UpdateStats('broadcast');
    end;
  finally
    ReleaseMutex(FStateMutex);
  end;
end;

// 查询操作
function TNamedConditionVariable.GetName: string;
begin
  Result := FOriginalName;
end;

function TNamedConditionVariable.GetConfig: TNamedConditionVariableConfig;
begin
  Result := FConfig;
end;

procedure TNamedConditionVariable.UpdateConfig(const AConfig: TNamedConditionVariableConfig);
begin
  FConfig := AConfig;
  // 注意：不能更改 UseGlobalNamespace，因为对象已经创建
end;

// 统计信息
function TNamedConditionVariable.GetStats: TNamedConditionVariableStats;
begin
  if FSharedState <> nil then
    Result := FSharedState^.Stats
  else
    Result := EmptyNamedConditionVariableStats;
end;

procedure TNamedConditionVariable.ResetStats;
begin
  if FSharedState <> nil then
    FillChar(FSharedState^.Stats, SizeOf(TNamedConditionVariableStats), 0);
end;

// 兼容性方法
function TNamedConditionVariable.GetHandle: Pointer;
begin
  Result := Pointer(FFileMapping);
end;

function TNamedConditionVariable.IsCreator: Boolean;
begin
  Result := FIsCreator;
end;



end.
