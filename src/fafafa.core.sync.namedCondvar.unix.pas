unit fafafa.core.sync.namedCondvar.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base,
  fafafa.core.sync.namedCondvar.base,
  fafafa.core.sync.namedMutex.base, fafafa.core.sync.mutex.base;

{$LINKLIB pthread}
{$LINKLIB rt}

const
  PTHREAD_PROCESS_SHARED = 1;

type
  // 共享状态结构（存储在共享内存中�?
  PSharedCondVarState = ^TSharedCondVarState;
  TSharedCondVarState = record
    Cond: pthread_cond_t;             // POSIX 条件变量
    Mutex: pthread_mutex_t;           // 保护共享状态的互斥�?
    WaitingCount: LongInt;            // 当前等待者数�?
    BroadcastGeneration: LongInt;     // 广播代数
    Stats: TNamedCondVarStats; // 统计信息
  end;

  TNamedCondVar = class(TSynchronizable, INamedCondVar)
  private
    FName: string;
    FOriginalName: string;
    FIsCreator: Boolean;
    FLastError: TWaitError;
    FConfig: TNamedCondVarConfig;
    
    // Unix 共享内存对象
    FShmFd: cint;                     // 共享内存文件描述�?
    FSharedState: PSharedCondVarState; // 共享状态指�?
    FShmName: AnsiString;             // 共享内存名称
    
    // 错误处理辅助方法
    function MapSystemErrorToWaitError(ASystemError: cint): TWaitError;
    function GetDetailedErrorMessage(AError: TWaitError; ASystemError: cint): string;

    function ValidateName(const AName: string): string;
    function CreateShmPath(const AName: string): string;
    function CreateSharedObjects(const AName: string): Boolean;
    function OpenSharedObjects(const AName: string): Boolean;
    procedure CleanupSharedObjects;
    function GetTickCount64: QWord;
    procedure UpdateStats(AOperation: string; AWaitTimeUs: QWord = 0);
    function TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TNamedCondVarConfig); overload;
    destructor Destroy; override;
    
    // ILock 接口（条件变量本身的锁定�?
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;
    
    // ICondVar 接口
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Signal;
    procedure Broadcast;
    
    // INamedCondVar 特有方法
    function GetName: string;
    function GetConfig: TNamedCondVarConfig;
    procedure UpdateConfig(const AConfig: TNamedCondVarConfig);
    function GetStats: TNamedCondVarStats;
    procedure ResetStats;
    function GetHandle: Pointer;
    function IsCreator: Boolean;
  end;

// POSIX 函数声明
function shm_open(name: PAnsiChar; oflag: cint; mode: mode_t): cint; cdecl; external 'rt';
function shm_unlink(name: PAnsiChar): cint; cdecl; external 'rt';
function ftruncate(fd: cint; length: off_t): cint; cdecl; external 'c';
function mmap(addr: Pointer; len: size_t; prot: cint; flags: cint; fd: cint; offset: off_t): Pointer; cdecl; external 'c';
function munmap(addr: Pointer; len: size_t): cint; cdecl; external 'c';
function clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt';
function pthread_condattr_setclock(attr: Ppthread_condattr_t; clock_id: cint): cint; cdecl; external 'pthread';

const
  O_CREAT = $40;
  O_EXCL = $80;
  O_RDWR = $2;
  S_IRUSR = $100;
  S_IWUSR = $80;
  S_IRGRP = $20;
  S_IWGRP = $10;
  PROT_READ = $1;
  PROT_WRITE = $2;
  MAP_SHARED = $1;
  MAP_FAILED = Pointer(-1);
  CLOCK_REALTIME = 0;
  CLOCK_MONOTONIC = 1;

implementation

{ TNamedCondVar }

constructor TNamedCondVar.Create(const AName: string);
begin
  Create(AName, DefaulTNamedCondVarConfig);
end;

constructor TNamedCondVar.Create(const AName: string; const AConfig: TNamedCondVarConfig);
var
  LValidatedName: string;
begin
  inherited Create;
  
  FOriginalName := AName;
  FConfig := AConfig;
  FLastError := weNone;
  FIsCreator := False;
  
  // 初始化句�?
  FShmFd := -1;
  FSharedState := nil;
  
  // 验证并处理名�?
  LValidatedName := ValidateName(AName);
  FShmName := AnsiString(CreateShmPath(LValidatedName));
  FName := LValidatedName;
  
  // 尝试创建共享对象
  if not CreateSharedObjects(LValidatedName) then
  begin
    // 创建失败，尝试打开现有�?
    if not OpenSharedObjects(LValidatedName) then
      raise ELockError.CreateFmt('Failed to create or open Named condition variable "%s": %s',
        [AName, GetDetailedErrorMessage(FLastError, fpGetErrno)]);
  end;
end;

destructor TNamedCondVar.Destroy;
begin
  CleanupSharedObjects;
  inherited Destroy;
end;

// 错误处理辅助函数
function TNamedCondVar.MapSystemErrorToWaitError(ASystemError: cint): TWaitError;
begin
  case ASystemError of
    0: Result := weNone;
    ESysEACCES: Result := weAccessDenied;
    ESysEEXIST: Result := weInvalidState;  // 对象已存�?
    ESysENOENT: Result := weInvalidHandle; // 对象不存�?
    ESysEINVAL: Result := weInvalidParameter;
    ESysENOMEM: Result := weResourceExhausted;
    ESysENOSPC: Result := weResourceExhausted; // 磁盘空间不足
    ESysEMFILE: Result := weResourceExhausted; // 文件描述符耗尽
    ESysENFILE: Result := weResourceExhausted; // 系统文件表满
    ESysEPERM: Result := weAccessDenied;
    ESysETIMEDOUT: Result := weTimeout;
    ESysEDEADLK: Result := weDeadlock;
    ESysEINTR: Result := weInterrupted;
    ESysEAGAIN: Result := weResourceExhausted;
    {$IF ESysEWOULDBLOCK <> ESysEAGAIN}
    ESysEWOULDBLOCK: Result := weResourceExhausted;
    {$ENDIF}
    ESysEBUSY: Result := weInvalidState; // 资源�?
    {$IFDEF ESysENOTSUP}
    ESysENOTSUP: Result := weNotSupported;
    {$ENDIF}
    {$IFDEF ESysEOPNOTSUPP}
    ESysEOPNOTSUPP: Result := weNotSupported;
    {$ENDIF}
  else
    Result := weSystemError;
  end;
end;

function TNamedCondVar.GetDetailedErrorMessage(AError: TWaitError; ASystemError: cint): string;
begin
  Result := WaitErrorToString(AError);
  if (AError = weSystemError) and (ASystemError <> 0) then
    Result := Result + Format(' (errno=%d: %s)', [ASystemError, SysErrorMessage(ASystemError)]);
end;

function TNamedCondVar.ValidateName(const AName: string): string;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named condition variable name cannot be empty');

  if Length(AName) > 255 then
    raise EInvalidArgument.Create('Named condition variable name too long (max 255 characters)');

  // Unix 不允许名称中包含额外�?'/' 字符
  if Pos('/', AName) > 0 then
    raise EInvalidArgument.Create('Invalid character in Named condition variable name');

  Result := AName;
end;

function TNamedCondVar.CreateShmPath(const AName: string): string;
begin
  // POSIX 要求共享内存名称�?'/' 开�?
  if AName[1] <> '/' then
    Result := '/' + AName
  else
    Result := AName;
end;

function TNamedCondVar.GetTickCount64: QWord;
var
  LTimeSpec: TTimeSpec;
begin
  if clock_gettime(CLOCK_MONOTONIC, @LTimeSpec) = 0 then
    Result := QWord(LTimeSpec.tv_sec) * 1000 + QWord(LTimeSpec.tv_nsec) div 1000000
  else
    Result := 0;
end;

function TNamedCondVar.TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
var
  LCurrentTime: TTimeSpec;
  LTotalNs: QWord;
begin
  // 重要：使�?CLOCK_MONOTONIC 保持�?GetTickCount64 一致，避免系统时间调整影响
  // 注意：pthread_cond_timedwait 默认使用 CLOCK_REALTIME，但我们可以通过 pthread_condattr_setclock 设置
  if clock_gettime(CLOCK_MONOTONIC, @LCurrentTime) <> 0 then
    raise ELockError.Create('Failed to get monotonic time');

  LTotalNs := QWord(LCurrentTime.tv_sec) * 1000000000 + QWord(LCurrentTime.tv_nsec) + QWord(ATimeoutMs) * 1000000;

  Result.tv_sec := LTotalNs div 1000000000;
  Result.tv_nsec := LTotalNs mod 1000000000;
end;

function TNamedCondVar.CreateSharedObjects(const AName: string): Boolean;
var
  LCondAttr: pthread_condattr_t;
  LMutexAttr: pthread_mutexattr_t;
  LRC: cint;
begin
  Result := False;

  try
    // 创建共享内存对象
    FShmFd := shm_open(PAnsiChar(FShmName), O_CREAT or O_EXCL or O_RDWR,
                       S_IRUSR or S_IWUSR or S_IRGRP or S_IWGRP);

    if FShmFd = -1 then
    begin
      if fpGetErrno = ESysEEXIST then
        Exit // 对象已存在，稍后尝试打开
      else
      begin
        FLastError := MapSystemErrorToWaitError(fpGetErrno);
        Exit;
      end;
    end;

    FIsCreator := True;

    // 设置共享内存大小
    if ftruncate(FShmFd, SizeOf(TSharedCondVarState)) <> 0 then
    begin
      FLastError := MapSystemErrorToWaitError(fpGetErrno);
      Exit;
    end;

    // 映射共享内存
    FSharedState := mmap(nil, SizeOf(TSharedCondVarState),
                        PROT_READ or PROT_WRITE, MAP_SHARED, FShmFd, 0);
    if FSharedState = MAP_FAILED then
    begin
      FSharedState := nil;
      FLastError := MapSystemErrorToWaitError(fpGetErrno);
      Exit;
    end;

    // 初始化共享状�?
    FillChar(FSharedState^, SizeOf(TSharedCondVarState), 0);
    FSharedState^.BroadcastGeneration := 1;

    // 初始化条件变量属性（进程间共享）
    LRC := pthread_condattr_init(@LCondAttr);
    if LRC <> 0 then
    begin
      FLastError := MapSystemErrorToWaitError(LRC);
      Exit;
    end;

    LRC := pthread_condattr_setpshared(@LCondAttr, PTHREAD_PROCESS_SHARED);
    if LRC <> 0 then
    begin
      pthread_condattr_destroy(@LCondAttr);
      FLastError := MapSystemErrorToWaitError(LRC);
      Exit;
    end;

    // 设置条件变量使用 CLOCK_MONOTONIC，与 TimeoutToTimespec 保持一�?
    LRC := pthread_condattr_setclock(@LCondAttr, CLOCK_MONOTONIC);
    if LRC <> 0 then
    begin
      pthread_condattr_destroy(@LCondAttr);
      FLastError := MapSystemErrorToWaitError(LRC);
      Exit;
    end;

    // 初始化条件变�?
    LRC := pthread_cond_init(@FSharedState^.Cond, @LCondAttr);
    pthread_condattr_destroy(@LCondAttr);
    if LRC <> 0 then
    begin
      FLastError := MapSystemErrorToWaitError(LRC);
      Exit;
    end;

    // 初始化互斥锁属性（进程间共享）
    LRC := pthread_mutexattr_init(@LMutexAttr);
    if LRC <> 0 then
    begin
      FLastError := MapSystemErrorToWaitError(LRC);
      Exit;
    end;

    LRC := pthread_mutexattr_setpshared(@LMutexAttr, PTHREAD_PROCESS_SHARED);
    if LRC <> 0 then
    begin
      pthread_mutexattr_destroy(@LMutexAttr);
      FLastError := MapSystemErrorToWaitError(LRC);
      Exit;
    end;

    // 初始化互斥锁
    LRC := pthread_mutex_init(@FSharedState^.Mutex, @LMutexAttr);
    pthread_mutexattr_destroy(@LMutexAttr);
    if LRC <> 0 then
    begin
      FLastError := MapSystemErrorToWaitError(LRC);
      Exit;
    end;

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

function TNamedCondVar.OpenSharedObjects(const AName: string): Boolean;
begin
  Result := False;

  try
    // 打开现有的共享内存对�?
    FShmFd := shm_open(PAnsiChar(FShmName), O_RDWR, 0);
    if FShmFd = -1 then
    begin
      FLastError := MapSystemErrorToWaitError(fpGetErrno);
      Exit;
    end;

    // 映射共享内存
    FSharedState := mmap(nil, SizeOf(TSharedCondVarState),
                        PROT_READ or PROT_WRITE, MAP_SHARED, FShmFd, 0);
    if FSharedState = MAP_FAILED then
    begin
      FSharedState := nil;
      FLastError := MapSystemErrorToWaitError(fpGetErrno);
      Exit;
    end;

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

procedure TNamedCondVar.CleanupSharedObjects;
begin
  if FSharedState <> nil then
  begin
    // 如果是创建者，销�?pthread 对象
    if FIsCreator then
    begin
      pthread_cond_destroy(@FSharedState^.Cond);
      pthread_mutex_destroy(@FSharedState^.Mutex);
    end;

    munmap(FSharedState, SizeOf(TSharedCondVarState));
    FSharedState := nil;
  end;

  if FShmFd <> -1 then
  begin
    fpClose(FShmFd);

    // 如果是创建者，删除共享内存对象
    if FIsCreator then
      shm_unlink(PAnsiChar(FShmName));

    FShmFd := -1;
  end;
end;

procedure TNamedCondVar.UpdateStats(AOperation: string; AWaitTimeUs: QWord);
begin
  if not FConfig.EnableStats then Exit;

  // 更新统计信息（在共享内存中）
  if AOperation = 'wait' then
  begin
    InterlockedIncrement64(FSharedState^.Stats.WaitCount);
    // 使用简单的加法，接受轻微的竞态条�?
    FSharedState^.Stats.TotalWaitTimeUs := FSharedState^.Stats.TotalWaitTimeUs + AWaitTimeUs;
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

// ILock 接口实现（条件变量本身的锁定�?
procedure TNamedCondVar.Acquire;
begin
  if pthread_mutex_lock(@FSharedState^.Mutex) <> 0 then
    raise ELockError.Create('Failed to acquire condition variable lock');
end;

procedure TNamedCondVar.Release;
begin
  if pthread_mutex_unlock(@FSharedState^.Mutex) <> 0 then
    raise ELockError.Create('Failed to release condition variable lock');
end;

function TNamedCondVar.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FSharedState^.Mutex) = 0;
end;

function TNamedCondVar.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  LAbsTimeout: TTimeSpec;
begin
  LAbsTimeout := TimeoutToTimespec(ATimeoutMs);
  Result := pthread_mutex_timedlock(@FSharedState^.Mutex, @LAbsTimeout) = 0;
end;

function TNamedCondVar.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

// 核心条件变量操作
procedure TNamedCondVar.Wait(const ALock: ILock);
begin
  if not Wait(ALock, Cardinal(-1)) then
    raise ELockError.Create('Infinite wait should not fail');
end;

function TNamedCondVar.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
var
  LStartTime: QWord;
  LAbsTimeout: TTimeSpec;
  LRC: cint;
  LNamedMutex: INamedMutex;
  LUserMutex: Pointer;
begin
  Result := False;

  if ALock = nil then
    raise EInvalidArgument.Create('Lock cannot be nil');

  LStartTime := GetTickCount64;

  // 尝试�?ILock 转换�?INamedMutex
  if not Supports(ALock, INamedMutex, LNamedMutex) then
    raise EInvalidArgument.Create('Unix namedCondVar requires INamedMutex');

  // 获取用户互斥锁的句柄
  LUserMutex := LNamedMutex.GetHandle;
  if LUserMutex = nil then
    raise EInvalidArgument.Create('Lock handle is invalid');

  // 重要：调用者必须已经持有这个互斥锁�?
  // pthread_cond_wait 要求调用时互斥锁已被当前线程锁定

  // 获取条件变量的内部锁
  if pthread_mutex_lock(@FSharedState^.Mutex) <> 0 then
  begin
    FLastError := weSystemError;
    Exit;
  end;

  try
    // 增加等待者计�?
    InterlockedIncrement(FSharedState^.WaitingCount);

    // 更新统计
    if FSharedState^.WaitingCount > FSharedState^.Stats.MaxWaiters then
      FSharedState^.Stats.MaxWaiters := FSharedState^.WaitingCount;
    FSharedState^.Stats.CurrentWaiters := FSharedState^.WaitingCount;

  finally
    pthread_mutex_unlock(@FSharedState^.Mutex);
  end;

  // 释放用户互斥锁并等待条件变量
  try
    if ATimeoutMs = Cardinal(-1) then
    begin
      // 无限等待
      LRC := pthread_cond_wait(@FSharedState^.Cond, Ppthread_mutex_t(LUserMutex));
    end
    else
    begin
      // 带超时等�?
      LAbsTimeout := TimeoutToTimespec(ATimeoutMs);
      LRC := pthread_cond_timedwait(@FSharedState^.Cond, Ppthread_mutex_t(LUserMutex), @LAbsTimeout);
    end;

    case LRC of
      0: begin
        Result := True;
        UpdateStats('wait', (GetTickCount64 - LStartTime) * 1000);
      end;
      ESysETIMEDOUT: begin
        UpdateStats('timeout');
      end;
      else begin
        FLastError := weSystemError;
      end;
    end;

  finally
    // 减少等待者计�?
    if pthread_mutex_lock(@FSharedState^.Mutex) = 0 then
    begin
      InterlockedDecrement(FSharedState^.WaitingCount);
      FSharedState^.Stats.CurrentWaiters := FSharedState^.WaitingCount;
      pthread_mutex_unlock(@FSharedState^.Mutex);
    end;
  end;
end;

procedure TNamedCondVar.Signal;
begin
  // 注意：根�?POSIX 标准，pthread_cond_signal 应该在持有与 pthread_cond_wait
  // 相同的互斥锁时调用。但是这里我们无法访问用户的互斥锁�?
  //
  // 这是一个设计问题：命名条件变量应该要求调用者在持有正确的锁时调�?Signal�?
  // 为了向后兼容，我们先使用内部锁，但这可能导致跨进程同步问题�?

  // 直接发送信号，不使用内部锁
  if pthread_cond_signal(@FSharedState^.Cond) = 0 then
  begin
    // 更新统计信息需要内部锁保护
    if pthread_mutex_lock(@FSharedState^.Mutex) = 0 then
    begin
      UpdateStats('signal');
      pthread_mutex_unlock(@FSharedState^.Mutex);
    end;
    FLastError := weNone;
  end
  else
    FLastError := weSystemError;
end;

procedure TNamedCondVar.Broadcast;
begin
  // 注意：同样的问题，理想情况下应该在持有用户互斥锁时调�?

  // 直接广播信号
  if pthread_cond_broadcast(@FSharedState^.Cond) = 0 then
  begin
    // 更新统计信息和广播代数需要内部锁保护
    if pthread_mutex_lock(@FSharedState^.Mutex) = 0 then
    begin
      InterlockedIncrement(FSharedState^.BroadcastGeneration);
      UpdateStats('broadcast');
      pthread_mutex_unlock(@FSharedState^.Mutex);
    end;
    FLastError := weNone;
  end
  else
    FLastError := weSystemError;
end;

// INamedCondVar 特有方法
function TNamedCondVar.GetName: string;
begin
  Result := FOriginalName;
end;

function TNamedCondVar.GetConfig: TNamedCondVarConfig;
begin
  Result := FConfig;
end;

procedure TNamedCondVar.UpdateConfig(const AConfig: TNamedCondVarConfig);
begin
  FConfig := AConfig;
  // 注意：不能更�?UseGlobalNamespace，因为对象已经创�?
end;

function TNamedCondVar.GetStats: TNamedCondVarStats;
begin
  if FSharedState <> nil then
    Result := FSharedState^.Stats
  else
    Result := EmptyNamedCondVarStats;
end;

procedure TNamedCondVar.ResetStats;
begin
  if FSharedState <> nil then
    FillChar(FSharedState^.Stats, SizeOf(TNamedCondVarStats), 0);
end;

function TNamedCondVar.GetHandle: Pointer;
begin
  Result := FSharedState;
end;

function TNamedCondVar.IsCreator: Boolean;
begin
  Result := FIsCreator;
end;



end.
