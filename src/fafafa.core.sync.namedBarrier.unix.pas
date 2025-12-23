unit fafafa.core.sync.namedBarrier.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$LINKLIB pthread}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType,
  fafafa.core.sync.base, fafafa.core.sync.namedBarrier.base;

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
    FSharedData: Pointer;           // 共享内存指针
    FShmFile: cint;                 // 共享内存文件描述�?
    FShmPath: AnsiString;           // 共享内存路径
    FOriginalName: string;          // 保存用户提供的原始名�?
    FIsCreator: Boolean;            // 是否为创建�?
    FShmSize: csize_t;              // 共享内存大小
    FParticipantCount: Cardinal;    // 参与者数�?
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

// Direct errno access for Linux - fpGetErrno doesn't work with libc functions
function __errno_location: pcint; cdecl; external 'c';
function GetCErrno: cint; inline;

const
  PTHREAD_PROCESS_SHARED = 1;
  PTHREAD_PROCESS_PRIVATE = 0;

implementation

function GetCErrno: cint; inline;
begin
  Result := __errno_location^;
end;

type
  // 共享内存中的屏障状�?
  PBarrierState = ^TBarrierState;
  TBarrierState = record
    Mutex: TPThreadMutex;           // 保护状态的互斥�?
    Cond: TPThreadCond;             // 条件变量
    WaitingCount: Cardinal;         // 当前等待者数�?
    ParticipantCount: Cardinal;     // 参与者总数
    Generation: Cardinal;           // 屏障代数（用于重置）
    AutoReset: Boolean;             // 是否自动重置
    Signaled: Boolean;              // 是否已触�?
    Initialized: Boolean;           // 是否已初始化
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

  if Length(Result) > 255 then
    raise EInvalidArgument.Create('Named barrier name too long (max 255 characters)');

  // 检查是否包含非法字�?
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
  
  // 初始化互斥锁属�?
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

    // 初始化条件变量属�?
    LCondAttrPtr := @LCondAttr;
    if pthread_condattr_init(LCondAttrPtr) <> 0 then
      Exit;

    try
      // 设置为进程间共享
      if pthread_condattr_setpshared(LCondAttrPtr, PTHREAD_PROCESS_SHARED) <> 0 then
        Exit;

      // 初始化条件变�?
      if pthread_cond_init(@LBarrierState^.Cond, LCondAttrPtr) <> 0 then
        Exit;

      // 初始化屏障状�?
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

  // 转换�?AnsiString 减少后续转换开销
  LAnsiPath := FShmPath;

  // 尝试创建共享内存文件
  LFlags := O_CREAT or O_RDWR;
  FShmFile := fpOpen(PAnsiChar(LAnsiPath), LFlags, S_IRUSR or S_IWUSR or S_IRGRP or S_IWGRP);

  if FShmFile = -1 then
    raise ELockError.CreateFmt('Failed to create shared memory for named barrier "%s": %s',
      [AName, SysErrorMessage(GetCErrno)]);

  try
    // 检查文件是否是新创建的
    FIsCreator := (fpLSeek(FShmFile, 0, SEEK_END) = 0);

    // 设置文件大小
    if FIsCreator then
    begin
      if fpFTruncate(FShmFile, FShmSize) <> 0 then
        raise ELockError.CreateFmt('Failed to set shared memory size for named barrier "%s": %s',
          [AName, SysErrorMessage(GetCErrno)]);
    end;

    // 映射共享内存
    FSharedData := fpMMap(nil, FShmSize, PROT_READ or PROT_WRITE, MAP_SHARED, FShmFile, 0);
    if FSharedData = Pointer(-1) then
      raise ELockError.CreateFmt('Failed to map shared memory for named barrier "%s": %s',
        [AName, SysErrorMessage(GetCErrno)]);

    // 如果是创建者，初始化屏�?
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
  Result := weNone; // Unix 实现中暂时简化错误处�?
end;

function TNamedBarrier.Wait: INamedBarrierGuard;
begin
  Result := WaitFor(Cardinal(-1));
  if not Assigned(Result) then
    raise ELockError.CreateFmt('Failed to wait on named barrier "%s"', [FOriginalName]);
end;

function TNamedBarrier.TryWait: INamedBarrierGuard;
begin
  Result := WaitFor(0);
end;

function TNamedBarrier.WaitFor(ATimeoutMs: Cardinal): INamedBarrierGuard;
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
  
  // 获取互斥�?
  if pthread_mutex_lock(@LBarrierState^.Mutex) <> 0 then
    Exit;
  
  try
    LCurrentGeneration := LBarrierState^.Generation;
    Inc(LBarrierState^.WaitingCount);
    LCurrentCount := LBarrierState^.WaitingCount;
    LIsLastParticipant := (LCurrentCount >= FParticipantCount);
    
    if LIsLastParticipant then
    begin
      // 最后一个参与者：触发所有等待�?
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
      // 等待屏障被触�?
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
        // 带超时等�?
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
  
  Result := TNamedBarrierGuard.Create(Self, LIsLastParticipant, LCurrentGeneration);
end;



function TNamedBarrier.GetInfo: TNamedBarrierInfo;
var
  LBarrierState: PBarrierState;
begin
  // 初始化结果（使用 Default 安全处理托管类型）
  Result := Default(TNamedBarrierInfo);
  Result.Name := FOriginalName;
  Result.ParticipantCount := FParticipantCount;
  Result.AutoReset := FAutoReset;

  if FSharedData <> nil then
  begin
    LBarrierState := PBarrierState(FSharedData);
    pthread_mutex_lock(@LBarrierState^.Mutex);
    try
      Result.CurrentWaitingCount := LBarrierState^.WaitingCount;
      Result.Generation := LBarrierState^.Generation;
      Result.IsSignaled := LBarrierState^.Signaled;
    finally
      pthread_mutex_unlock(@LBarrierState^.Mutex);
    end;
  end;
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



end.
