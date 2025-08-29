unit fafafa.core.sync.namedBarrier.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$LINKLIB pthread}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedBarrier.base;

type
  // pthread 相关类型定义
  PPThreadMutex = ^TPThreadMutex;
  TPThreadMutex = record
    data: array[0..39] of Byte;
  end;

  PPThreadCond = ^TPThreadCond;
  TPThreadCond = record
    data: array[0..47] of Byte;
  end;

  PPThreadMutexAttr = ^TPThreadMutexAttr;
  TPThreadMutexAttr = record
    data: array[0..3] of Byte;
  end;

  PPThreadCondAttr = ^TPThreadCondAttr;
  TPThreadCondAttr = record
    data: array[0..3] of Byte;
  end;

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
    FSharedData: Pointer;           // 共享内存指针
    FShmFile: cint;                 // 共享内存文件描述符
    FShmPath: AnsiString;           // 共享内存路径
    FOriginalName: string;          // 保存用户提供的原始名称
    FIsCreator: Boolean;            // 是否为创建者
    FShmSize: csize_t;              // 共享内存大小
    FParticipantCount: Cardinal;    // 参与者数量
    FAutoReset: Boolean;            // 是否自动重置
    
    function ValidateName(const AName: string): string;
    function CreateShmPath(const AName: string): string;
    function InitializeBarrier: Boolean;
    function TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
    function GetBarrierState: Pointer;
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

// pthread 函数声明
function pthread_mutex_init(mutex: PPThreadMutex; attr: PPThreadMutexAttr): cint; cdecl; external 'c';
function pthread_mutex_destroy(mutex: PPThreadMutex): cint; cdecl; external 'c';
function pthread_mutex_lock(mutex: PPThreadMutex): cint; cdecl; external 'c';
function pthread_mutex_unlock(mutex: PPThreadMutex): cint; cdecl; external 'c';
function pthread_mutexattr_init(attr: PPThreadMutexAttr): cint; cdecl; external 'c';
function pthread_mutexattr_destroy(attr: PPThreadMutexAttr): cint; cdecl; external 'c';
function pthread_mutexattr_setpshared(attr: PPThreadMutexAttr; pshared: cint): cint; cdecl; external 'c';

function pthread_cond_init(cond: PPThreadCond; attr: PPThreadCondAttr): cint; cdecl; external 'c';
function pthread_cond_destroy(cond: PPThreadCond): cint; cdecl; external 'c';
function pthread_cond_wait(cond: PPThreadCond; mutex: PPThreadMutex): cint; cdecl; external 'c';
function pthread_cond_timedwait(cond: PPThreadCond; mutex: PPThreadMutex; abstime: PTimeSpec): cint; cdecl; external 'c';
function pthread_cond_broadcast(cond: PPThreadCond): cint; cdecl; external 'c';
function pthread_condattr_init(attr: PPThreadCondAttr): cint; cdecl; external 'c';
function pthread_condattr_destroy(attr: PPThreadCondAttr): cint; cdecl; external 'c';
function pthread_condattr_setpshared(attr: PPThreadCondAttr; pshared: cint): cint; cdecl; external 'c';

const
  PTHREAD_PROCESS_SHARED = 1;
  PTHREAD_PROCESS_PRIVATE = 0;

implementation

type
  // 共享内存中的屏障状态
  PBarrierState = ^TBarrierState;
  TBarrierState = record
    Mutex: TPThreadMutex;           // 保护状态的互斥锁
    Cond: TPThreadCond;             // 条件变量
    WaitingCount: Cardinal;         // 当前等待者数量
    ParticipantCount: Cardinal;     // 参与者总数
    Generation: Cardinal;           // 屏障代数（用于重置）
    AutoReset: Boolean;             // 是否自动重置
    Signaled: Boolean;              // 是否已触发
    Initialized: Boolean;           // 是否已初始化
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

  if Length(Result) > 255 then
    raise EInvalidArgument.Create('Named barrier name too long (max 255 characters)');

  // 检查是否包含非法字符
  for i := 1 to Length(Result) do
  begin
    if Result[i] in ['/', '\', ':', '*', '?', '"', '<', '>', '|'] then
      raise EInvalidArgument.Create('Named barrier name contains invalid characters');
  end;
end;

function TNamedBarrier.CreateShmPath(const AName: string): string;
const
  SHM_PREFIX = '/dev/shm/fafafa_barrier_';
begin
  Result := SHM_PREFIX + AName;
end;

function TNamedBarrier.InitializeBarrier: Boolean;
var
  LMutexAttr: TPThreadMutexAttr;
  LCondAttr: TPThreadCondAttr;
  LMutexAttrPtr: PPThreadMutexAttr;
  LCondAttrPtr: PPThreadCondAttr;
  LBarrierState: PBarrierState;
begin
  Result := False;
  LBarrierState := PBarrierState(FSharedData);
  
  // 初始化互斥锁属性
  LMutexAttrPtr := @LMutexAttr;
  if pthread_mutexattr_init(LMutexAttrPtr) <> 0 then
    Exit;

  try
    // 设置为进程间共享
    if pthread_mutexattr_setpshared(LMutexAttrPtr, PTHREAD_PROCESS_SHARED) <> 0 then
      Exit;

    // 初始化互斥锁
    if pthread_mutex_init(@LBarrierState^.Mutex, LMutexAttrPtr) <> 0 then
      Exit;

    // 初始化条件变量属性
    LCondAttrPtr := @LCondAttr;
    if pthread_condattr_init(LCondAttrPtr) <> 0 then
      Exit;

    try
      // 设置为进程间共享
      if pthread_condattr_setpshared(LCondAttrPtr, PTHREAD_PROCESS_SHARED) <> 0 then
        Exit;

      // 初始化条件变量
      if pthread_cond_init(@LBarrierState^.Cond, LCondAttrPtr) <> 0 then
        Exit;

      // 初始化屏障状态
      LBarrierState^.WaitingCount := 0;
      LBarrierState^.ParticipantCount := FParticipantCount;
      LBarrierState^.Generation := 0;
      LBarrierState^.AutoReset := FAutoReset;
      LBarrierState^.Signaled := False;
      LBarrierState^.Initialized := True;

      Result := True;
    finally
      pthread_condattr_destroy(LCondAttrPtr);
    end;
  finally
    pthread_mutexattr_destroy(LMutexAttrPtr);
  end;
end;

function TNamedBarrier.TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
var
  tv: TTimeVal;
begin
  if fpgettimeofday(@tv, nil) <> 0 then
    raise ELockError.Create('Failed to get current time');

  Result.tv_sec := tv.tv_sec + (ATimeoutMs div 1000);
  Result.tv_nsec := (tv.tv_usec * 1000) + ((ATimeoutMs mod 1000) * 1000000);

  if Result.tv_nsec >= 1000000000 then
  begin
    Inc(Result.tv_sec, Result.tv_nsec div 1000000000);
    Result.tv_nsec := Result.tv_nsec mod 1000000000;
  end;
end;

function TNamedBarrier.GetBarrierState: Pointer;
begin
  Result := FSharedData;
end;

constructor TNamedBarrier.Create(const AName: string; const AConfig: TNamedBarrierConfig);
var
  LValidatedName: string;
  LFlags: cint;
  LAnsiPath: AnsiString;
begin
  inherited Create;

  FOriginalName := AName;
  FParticipantCount := AConfig.ParticipantCount;
  FAutoReset := AConfig.AutoReset;
  
  if FParticipantCount < 2 then
    raise EInvalidArgument.Create('Participant count must be at least 2');

  LValidatedName := ValidateName(AName);
  FShmPath := AnsiString(CreateShmPath(LValidatedName));
  FShmFile := -1;
  FSharedData := nil;

  // 缓存共享内存大小
  FShmSize := SizeOf(TBarrierState);

  // 转换为 AnsiString 减少后续转换开销
  LAnsiPath := FShmPath;

  // 尝试创建共享内存文件
  LFlags := O_CREAT or O_RDWR;
  FShmFile := fpOpen(PAnsiChar(LAnsiPath), LFlags, S_IRUSR or S_IWUSR or S_IRGRP or S_IWGRP);

  if FShmFile = -1 then
    raise ELockError.CreateFmt('Failed to create shared memory for named barrier "%s": %s',
      [AName, SysErrorMessage(fpGetErrno)]);

  try
    // 检查文件是否是新创建的
    FIsCreator := (fpLSeek(FShmFile, 0, SEEK_END) = 0);

    // 设置文件大小
    if FIsCreator then
    begin
      if fpFTruncate(FShmFile, FShmSize) <> 0 then
        raise ELockError.CreateFmt('Failed to set shared memory size for named barrier "%s": %s',
          [AName, SysErrorMessage(fpGetErrno)]);
    end;

    // 映射共享内存
    FSharedData := fpMMap(nil, FShmSize, PROT_READ or PROT_WRITE, MAP_SHARED, FShmFile, 0);
    if FSharedData = Pointer(-1) then
      raise ELockError.CreateFmt('Failed to map shared memory for named barrier "%s": %s',
        [AName, SysErrorMessage(fpGetErrno)]);

    // 如果是创建者，初始化屏障
    if FIsCreator then
    begin
      if not InitializeBarrier then
        raise ELockError.CreateFmt('Failed to initialize barrier for named barrier "%s"', [AName]);
    end
    else
    begin
      // 如果不是创建者，等待初始化完成并读取配置
      while not PBarrierState(FSharedData)^.Initialized do
      begin
        Sleep(1); // 等待1毫秒
      end;
        
      FParticipantCount := PBarrierState(FSharedData)^.ParticipantCount;
      FAutoReset := PBarrierState(FSharedData)^.AutoReset;
    end;

  except
    // 清理资源
    if FSharedData <> nil then
      fpMUnMap(FSharedData, FShmSize);
    if FShmFile <> -1 then
      fpClose(FShmFile);
    if FIsCreator then
      fpUnlink(PAnsiChar(LAnsiPath));
    raise;
  end;
end;

destructor TNamedBarrier.Destroy;
var
  LBarrierState: PBarrierState;
begin
  // 清理屏障
  if Assigned(FSharedData) then
  begin
    LBarrierState := PBarrierState(FSharedData);
    if FIsCreator and LBarrierState^.Initialized then
    begin
      pthread_cond_destroy(@LBarrierState^.Cond);
      pthread_mutex_destroy(@LBarrierState^.Mutex);
    end;

    fpMUnMap(FSharedData, FShmSize);
    FSharedData := nil;
  end;

  // 清理共享内存文件
  if FShmFile <> -1 then
  begin
    fpClose(FShmFile);
    FShmFile := -1;

    // 如果是创建者，删除共享内存文件
    if FIsCreator then
      fpUnlink(PAnsiChar(FShmPath));
  end;

  inherited Destroy;
end;

function TNamedBarrier.GetLastError: TWaitError;
begin
  Result := weNone; // Unix 实现中暂时简化错误处理
end;

function TNamedBarrier.Wait: INamedBarrierGuard;
begin
  Result := TryWaitFor(Cardinal(-1));
  if not Assigned(Result) then
    raise ELockError.CreateFmt('Failed to wait on named barrier "%s"', [FOriginalName]);
end;

function TNamedBarrier.TryWait: INamedBarrierGuard;
begin
  Result := TryWaitFor(0);
end;

function TNamedBarrier.TryWaitFor(ATimeoutMs: Cardinal): INamedBarrierGuard;
var
  LBarrierState: PBarrierState;
  LCurrentCount: Cardinal;
  LIsLastParticipant: Boolean;
  LCurrentGeneration: Cardinal;
  LTimespec: TTimeSpec;
  LResult: cint;
begin
  Result := nil;
  LBarrierState := PBarrierState(FSharedData);
  
  // 获取互斥锁
  if pthread_mutex_lock(@LBarrierState^.Mutex) <> 0 then
    Exit;
  
  try
    LCurrentGeneration := LBarrierState^.Generation;
    Inc(LBarrierState^.WaitingCount);
    LCurrentCount := LBarrierState^.WaitingCount;
    LIsLastParticipant := (LCurrentCount >= FParticipantCount);
    
    if LIsLastParticipant then
    begin
      // 最后一个参与者：触发所有等待者
      LBarrierState^.Signaled := True;
      pthread_cond_broadcast(@LBarrierState^.Cond);
      
      if FAutoReset then
      begin
        LBarrierState^.WaitingCount := 0;
        LBarrierState^.Signaled := False;
        Inc(LBarrierState^.Generation);
      end;
    end
    else
    begin
      // 等待屏障被触发
      if ATimeoutMs = 0 then
      begin
        // 非阻塞模式：立即返回
        Dec(LBarrierState^.WaitingCount);
        Exit;
      end
      else if ATimeoutMs = Cardinal(-1) then
      begin
        // 无限等待
        while (LBarrierState^.Generation = LCurrentGeneration) and not LBarrierState^.Signaled do
        begin
          LResult := pthread_cond_wait(@LBarrierState^.Cond, @LBarrierState^.Mutex);
          if LResult <> 0 then
          begin
            Dec(LBarrierState^.WaitingCount);
            Exit;
          end;
        end;
      end
      else
      begin
        // 带超时等待
        LTimespec := TimeoutToTimespec(ATimeoutMs);
        while (LBarrierState^.Generation = LCurrentGeneration) and not LBarrierState^.Signaled do
        begin
          LResult := pthread_cond_timedwait(@LBarrierState^.Cond, @LBarrierState^.Mutex, @LTimespec);
          if LResult = ESysETIMEDOUT then
          begin
            Dec(LBarrierState^.WaitingCount);
            Exit;
          end
          else if LResult <> 0 then
          begin
            Dec(LBarrierState^.WaitingCount);
            Exit;
          end;
        end;
      end;
    end;
    
  finally
    pthread_mutex_unlock(@LBarrierState^.Mutex);
  end;
  
  Result := TNamedBarrierGuard.Create(FOriginalName, FParticipantCount, LCurrentCount, LIsLastParticipant);
end;

function TNamedBarrier.GetName: string;
begin
  Result := FOriginalName;
end;

function TNamedBarrier.GetParticipantCount: Cardinal;
begin
  Result := FParticipantCount;
end;

function TNamedBarrier.GetWaitingCount: Cardinal;
var
  LBarrierState: PBarrierState;
begin
  if FSharedData <> nil then
  begin
    LBarrierState := PBarrierState(FSharedData);
    pthread_mutex_lock(@LBarrierState^.Mutex);
    try
      Result := LBarrierState^.WaitingCount;
    finally
      pthread_mutex_unlock(@LBarrierState^.Mutex);
    end;
  end
  else
    Result := 0;
end;

function TNamedBarrier.IsSignaled: Boolean;
var
  LBarrierState: PBarrierState;
begin
  if FSharedData <> nil then
  begin
    LBarrierState := PBarrierState(FSharedData);
    pthread_mutex_lock(@LBarrierState^.Mutex);
    try
      Result := LBarrierState^.Signaled;
    finally
      pthread_mutex_unlock(@LBarrierState^.Mutex);
    end;
  end
  else
    Result := False;
end;

procedure TNamedBarrier.Reset;
var
  LBarrierState: PBarrierState;
begin
  LBarrierState := PBarrierState(FSharedData);
  pthread_mutex_lock(@LBarrierState^.Mutex);
  try
    LBarrierState^.WaitingCount := 0;
    LBarrierState^.Signaled := False;
    Inc(LBarrierState^.Generation);
  finally
    pthread_mutex_unlock(@LBarrierState^.Mutex);
  end;
end;

procedure TNamedBarrier.Signal;
var
  LBarrierState: PBarrierState;
begin
  LBarrierState := PBarrierState(FSharedData);
  pthread_mutex_lock(@LBarrierState^.Mutex);
  try
    LBarrierState^.Signaled := True;
    pthread_cond_broadcast(@LBarrierState^.Cond);
  finally
    pthread_mutex_unlock(@LBarrierState^.Mutex);
  end;
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
      Result := TNamedBarrierGuardResult.Err(nbeTimeout);
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
    raise ETimeoutError.CreateFmt('Timeout waiting for named barrier "%s"', [FOriginalName]);
end;

function TNamedBarrier.GetHandle: Pointer;
begin
  Result := FSharedData;
end;

function TNamedBarrier.IsCreator: Boolean;
begin
  Result := FIsCreator;
end;

end.
