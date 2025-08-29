unit fafafa.core.sync.namedConditionVariable.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base,
  fafafa.core.sync.namedConditionVariable.base,
  fafafa.core.sync.namedMutex.base, fafafa.core.sync.mutex.base;

{$LINKLIB pthread}
{$LINKLIB rt}

const
  PTHREAD_PROCESS_SHARED = 1;

type
  // 共享状态结构（存储在共享内存中）
  PSharedCondVarState = ^TSharedCondVarState;
  TSharedCondVarState = record
    Cond: pthread_cond_t;             // POSIX 条件变量
    Mutex: pthread_mutex_t;           // 保护共享状态的互斥锁
    WaitingCount: LongInt;            // 当前等待者数量
    BroadcastGeneration: LongInt;     // 广播代数
    Stats: TNamedConditionVariableStats; // 统计信息
  end;

  TNamedConditionVariable = class(TInterfacedObject, INamedConditionVariable)
  private
    FName: string;
    FOriginalName: string;
    FIsCreator: Boolean;
    FLastError: TWaitError;
    FConfig: TNamedConditionVariableConfig;
    
    // Unix 共享内存对象
    FShmFd: cint;                     // 共享内存文件描述符
    FSharedState: PSharedCondVarState; // 共享状态指针
    FShmName: AnsiString;             // 共享内存名称
    
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
    constructor Create(const AName: string; const AConfig: TNamedConditionVariableConfig); overload;
    destructor Destroy; override;
    
    // ILock 接口（条件变量本身的锁定）
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;
    
    // IConditionVariable 接口
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Wait(const AMutex: IMutex); overload;
    function Wait(const AMutex: IMutex; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Signal;
    procedure Broadcast;
    
    // INamedConditionVariable 特有方法
    function GetName: string;
    function GetConfig: TNamedConditionVariableConfig;
    procedure UpdateConfig(const AConfig: TNamedConditionVariableConfig);
    function GetStats: TNamedConditionVariableStats;
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

{ TNamedConditionVariable }

constructor TNamedConditionVariable.Create(const AName: string);
begin
  Create(AName, DefaultNamedConditionVariableConfig);
end;

constructor TNamedConditionVariable.Create(const AName: string; const AConfig: TNamedConditionVariableConfig);
var
  LValidatedName: string;
begin
  inherited Create;
  
  FOriginalName := AName;
  FConfig := AConfig;
  FLastError := weNone;
  FIsCreator := False;
  
  // 初始化句柄
  FShmFd := -1;
  FSharedState := nil;
  
  // 验证并处理名称
  LValidatedName := ValidateName(AName);
  FShmName := AnsiString(CreateShmPath(LValidatedName));
  FName := LValidatedName;
  
  // 尝试创建共享对象
  if not CreateSharedObjects(LValidatedName) then
  begin
    // 创建失败，尝试打开现有的
    if not OpenSharedObjects(LValidatedName) then
      raise ELockError.CreateFmt('Failed to create or open named condition variable "%s": %s', 
        [AName, SysErrorMessage(fpGetErrno)]);
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
    
  if Length(AName) > 255 then
    raise EInvalidArgument.Create('Named condition variable name too long (max 255 characters)');
    
  // Unix 不允许名称中包含额外的 '/' 字符
  if Pos('/', AName) > 0 then
    raise EInvalidArgument.Create('Invalid character in named condition variable name');
    
  Result := AName;
end;

function TNamedConditionVariable.CreateShmPath(const AName: string): string;
begin
  // POSIX 要求共享内存名称以 '/' 开头
  if AName[1] <> '/' then
    Result := '/' + AName
  else
    Result := AName;
end;

function TNamedConditionVariable.GetTickCount64: QWord;
var
  LTimeSpec: TTimeSpec;
begin
  if clock_gettime(CLOCK_MONOTONIC, @LTimeSpec) = 0 then
    Result := QWord(LTimeSpec.tv_sec) * 1000 + QWord(LTimeSpec.tv_nsec) div 1000000
  else
    Result := 0;
end;

function TNamedConditionVariable.TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
var
  LCurrentTime: TTimeSpec;
  LTotalNs: QWord;
begin
  if clock_gettime(CLOCK_REALTIME, @LCurrentTime) <> 0 then
    raise ELockError.Create('Failed to get current time');
    
  LTotalNs := QWord(LCurrentTime.tv_sec) * 1000000000 + QWord(LCurrentTime.tv_nsec) + QWord(ATimeoutMs) * 1000000;
  
  Result.tv_sec := LTotalNs div 1000000000;
  Result.tv_nsec := LTotalNs mod 1000000000;
end;

function TNamedConditionVariable.CreateSharedObjects(const AName: string): Boolean;
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
        FLastError := weSystemError;
        Exit;
      end;
    end;

    FIsCreator := True;

    // 设置共享内存大小
    if ftruncate(FShmFd, SizeOf(TSharedCondVarState)) <> 0 then
    begin
      FLastError := weSystemError;
      Exit;
    end;

    // 映射共享内存
    FSharedState := mmap(nil, SizeOf(TSharedCondVarState),
                        PROT_READ or PROT_WRITE, MAP_SHARED, FShmFd, 0);
    if FSharedState = MAP_FAILED then
    begin
      FSharedState := nil;
      FLastError := weSystemError;
      Exit;
    end;

    // 初始化共享状态
    FillChar(FSharedState^, SizeOf(TSharedCondVarState), 0);
    FSharedState^.BroadcastGeneration := 1;

    // 初始化条件变量属性（进程间共享）
    LRC := pthread_condattr_init(@LCondAttr);
    if LRC <> 0 then
    begin
      FLastError := weSystemError;
      Exit;
    end;

    LRC := pthread_condattr_setpshared(@LCondAttr, PTHREAD_PROCESS_SHARED);
    if LRC <> 0 then
    begin
      pthread_condattr_destroy(@LCondAttr);
      FLastError := weSystemError;
      Exit;
    end;

    // 初始化条件变量
    LRC := pthread_cond_init(@FSharedState^.Cond, @LCondAttr);
    pthread_condattr_destroy(@LCondAttr);
    if LRC <> 0 then
    begin
      FLastError := weSystemError;
      Exit;
    end;

    // 初始化互斥锁属性（进程间共享）
    LRC := pthread_mutexattr_init(@LMutexAttr);
    if LRC <> 0 then
    begin
      FLastError := weSystemError;
      Exit;
    end;

    LRC := pthread_mutexattr_setpshared(@LMutexAttr, PTHREAD_PROCESS_SHARED);
    if LRC <> 0 then
    begin
      pthread_mutexattr_destroy(@LMutexAttr);
      FLastError := weSystemError;
      Exit;
    end;

    // 初始化互斥锁
    LRC := pthread_mutex_init(@FSharedState^.Mutex, @LMutexAttr);
    pthread_mutexattr_destroy(@LMutexAttr);
    if LRC <> 0 then
    begin
      FLastError := weSystemError;
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

function TNamedConditionVariable.OpenSharedObjects(const AName: string): Boolean;
begin
  Result := False;

  try
    // 打开现有的共享内存对象
    FShmFd := shm_open(PAnsiChar(FShmName), O_RDWR, 0);
    if FShmFd = -1 then
    begin
      FLastError := weSystemError;
      Exit;
    end;

    // 映射共享内存
    FSharedState := mmap(nil, SizeOf(TSharedCondVarState),
                        PROT_READ or PROT_WRITE, MAP_SHARED, FShmFd, 0);
    if FSharedState = MAP_FAILED then
    begin
      FSharedState := nil;
      FLastError := weSystemError;
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

procedure TNamedConditionVariable.CleanupSharedObjects;
begin
  if FSharedState <> nil then
  begin
    // 如果是创建者，销毁 pthread 对象
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

procedure TNamedConditionVariable.UpdateStats(AOperation: string; AWaitTimeUs: QWord);
begin
  if not FConfig.EnableStats then Exit;

  // 更新统计信息（在共享内存中）
  if AOperation = 'wait' then
  begin
    InterlockedIncrement64(FSharedState^.Stats.WaitCount);
    // 使用简单的加法，接受轻微的竞态条件
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

// ILock 接口实现（条件变量本身的锁定）
procedure TNamedConditionVariable.Acquire;
begin
  if pthread_mutex_lock(@FSharedState^.Mutex) <> 0 then
    raise ELockError.Create('Failed to acquire condition variable lock');
end;

procedure TNamedConditionVariable.Release;
begin
  if pthread_mutex_unlock(@FSharedState^.Mutex) <> 0 then
    raise ELockError.Create('Failed to release condition variable lock');
end;

function TNamedConditionVariable.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FSharedState^.Mutex) = 0;
end;

function TNamedConditionVariable.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  LAbsTimeout: TTimeSpec;
begin
  LAbsTimeout := TimeoutToTimespec(ATimeoutMs);
  Result := pthread_mutex_timedlock(@FSharedState^.Mutex, @LAbsTimeout) = 0;
end;

function TNamedConditionVariable.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

// 核心条件变量操作
procedure TNamedConditionVariable.Wait(const ALock: ILock);
begin
  if not Wait(ALock, Cardinal(-1)) then
    raise ELockError.Create('Infinite wait should not fail');
end;

function TNamedConditionVariable.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
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

  // 尝试将 ILock 转换为 INamedMutex
  if not Supports(ALock, INamedMutex, LNamedMutex) then
    raise EInvalidArgument.Create('Unix namedConditionVariable requires INamedMutex');

  // 获取用户互斥锁的句柄
  LUserMutex := LNamedMutex.GetHandle;
  if LUserMutex = nil then
    raise EInvalidArgument.Create('Lock handle is invalid');

  // 获取条件变量的内部锁
  if pthread_mutex_lock(@FSharedState^.Mutex) <> 0 then
  begin
    FLastError := weSystemError;
    Exit;
  end;

  try
    // 增加等待者计数
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
      // 带超时等待
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
    // 减少等待者计数
    if pthread_mutex_lock(@FSharedState^.Mutex) = 0 then
    begin
      InterlockedDecrement(FSharedState^.WaitingCount);
      FSharedState^.Stats.CurrentWaiters := FSharedState^.WaitingCount;
      pthread_mutex_unlock(@FSharedState^.Mutex);
    end;
  end;
end;

procedure TNamedConditionVariable.Signal;
begin
  // 获取内部锁
  if pthread_mutex_lock(@FSharedState^.Mutex) <> 0 then
  begin
    FLastError := weSystemError;
    Exit;
  end;

  try
    // 如果有等待者，发送信号
    if FSharedState^.WaitingCount > 0 then
    begin
      pthread_cond_signal(@FSharedState^.Cond);
      UpdateStats('signal');
    end;
  finally
    pthread_mutex_unlock(@FSharedState^.Mutex);
  end;
end;

procedure TNamedConditionVariable.Broadcast;
begin
  // 获取内部锁
  if pthread_mutex_lock(@FSharedState^.Mutex) <> 0 then
  begin
    FLastError := weSystemError;
    Exit;
  end;

  try
    // 如果有等待者，广播信号
    if FSharedState^.WaitingCount > 0 then
    begin
      pthread_cond_broadcast(@FSharedState^.Cond);
      // 增加广播代数，防止虚假唤醒
      InterlockedIncrement(FSharedState^.BroadcastGeneration);
      UpdateStats('broadcast');
    end;
  finally
    pthread_mutex_unlock(@FSharedState^.Mutex);
  end;
end;

// INamedConditionVariable 特有方法
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

function TNamedConditionVariable.GetHandle: Pointer;
begin
  Result := FSharedState;
end;

function TNamedConditionVariable.IsCreator: Boolean;
begin
  Result := FIsCreator;
end;

// IMutex 版本的 Wait 方法（从 IConditionVariable 继承）
procedure TNamedConditionVariable.Wait(const AMutex: IMutex);
begin
  if AMutex = nil then
    raise EArgumentNilException.Create('Mutex cannot be nil');
  // 转换为 ILock 并调用现有实现
  Wait(ILock(AMutex));
end;

function TNamedConditionVariable.Wait(const AMutex: IMutex; ATimeoutMs: Cardinal): Boolean;
begin
  if AMutex = nil then
    raise EArgumentNilException.Create('Mutex cannot be nil');
  // 转换为 ILock 并调用现有实现
  Result := Wait(ILock(AMutex), ATimeoutMs);
end;

end.
