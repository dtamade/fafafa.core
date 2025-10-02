unit fafafa.core.sync.namedEvent.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedEvent.base;

const
  ESysETIMEDOUT = 110;  // 超时错误�?
  ESysEINTR = 4;        // 信号中断
  CLOCK_REALTIME = 0;   // 实时时钟

// POSIX 共享内存函数声明
function shm_open(name: PAnsiChar; oflag: cint; mode: mode_t): cint; cdecl; external 'rt';
function shm_unlink(name: PAnsiChar): cint; cdecl; external 'rt';
function ftruncate(fd: cint; length: off_t): cint; cdecl; external 'c';

{$IFDEF HAS_CLOCK_GETTIME}
// POSIX 时钟函数声明
function clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt';
{$ENDIF}

type
  // 共享内存中的事件状态结�?
  PEventState = ^TEventState;
  TEventState = record
    Mutex: pthread_mutex_t;
    Cond: pthread_cond_t;
    InitCond: pthread_cond_t;  // 用于初始化同步的条件变量
    Signaled: Boolean;
    ManualReset: Boolean;
    WaitingCount: Integer;
    RefCount: Integer;        // 引用计数
    Initialized: Boolean;
    InitError: Boolean;       // 初始化是否出�?
  end;

  // RAII 守卫实现
  TNamedEventGuard = class(TInterfacedObject, INamedEventGuard)
  private
    FName: string;
    FSignaled: Boolean;
  public
    constructor Create(const AName: string; ASignaled: Boolean);
    function GetName: string;
    function IsSignaled: Boolean;
  end;

  TNamedEvent = class(TSynchronizable, INamedEvent)
  private
    FEventState: PEventState;   // 指向共享内存中的事件状�?
    FShmFile: cint;             // 共享内存文件描述�?
    FShmPath: AnsiString;       // 共享内存路径
    FOriginalName: string;      // 保存用户提供的原始名�?
    FIsCreator: Boolean;        // 是否为创建�?
    FShmSize: csize_t;          // 共享内存大小
    FLastError: TWaitError;
    
    function ValidateName(const AName: string): string;
    function CreateShmPath(const AName: string): string;
    function InitializeEventState(const AConfig: TNamedEventConfig): Boolean;
    function TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TNamedEventConfig); overload;
    destructor Destroy; override;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;

    // INamedEvent 接口 - 现代化方�?
    function Wait: INamedEventGuard;
    function TryWait: INamedEventGuard;
    function TryWaitFor(ATimeoutMs: Cardinal): INamedEventGuard;

    procedure Signal;
    procedure Reset;
    procedure Pulse;

    function GetName: string;
    function IsManualReset: Boolean;
    function IsSignaled: Boolean;
  end;

implementation

{ 辅助函数 }

function GetCurrentTimespec: TTimeSpec;
{$IFDEF HAS_CLOCK_GETTIME}
begin
  if clock_gettime(CLOCK_REALTIME, @Result) <> 0 then
  begin
    Result.tv_sec := 0;
    Result.tv_nsec := 0;
  end;
end;
{$ELSE}
var
  tv: timeval;
begin
  if fpgettimeofday(@tv, nil) = 0 then
  begin
    Result.tv_sec := tv.tv_sec;
    Result.tv_nsec := tv.tv_usec * 1000;
  end
  else
  begin
    Result.tv_sec := 0;
    Result.tv_nsec := 0;
  end;
end;
{$ENDIF}

function AddMillisecondsToTimespec(const base: TTimeSpec; ms: Cardinal): TTimeSpec;
begin
  Result.tv_sec := base.tv_sec + (ms div 1000);
  Result.tv_nsec := base.tv_nsec + (ms mod 1000) * 1000000;

  // 处理纳秒溢出
  if Result.tv_nsec >= 1000000000 then
  begin
    Inc(Result.tv_sec, Result.tv_nsec div 1000000000);
    Result.tv_nsec := Result.tv_nsec mod 1000000000;
  end;
end;

{ TNamedEventGuard }

constructor TNamedEventGuard.Create(const AName: string; ASignaled: Boolean);
begin
  inherited Create;
  FName := AName;
  FSignaled := ASignaled;
end;

function TNamedEventGuard.GetName: string;
begin
  Result := FName;
end;

function TNamedEventGuard.IsSignaled: Boolean;
begin
  Result := FSignaled;
end;

{ TNamedEvent }

constructor TNamedEvent.Create(const AName: string);
var
  LConfig: TNamedEventConfig;
begin
  LConfig := DefaultNamedEventConfig;
  Create(AName, LConfig);
end;

constructor TNamedEvent.Create(const AName: string; const AConfig: TNamedEventConfig);
var
  LValidatedName: string;
  LFlags: cint;
  LMode: mode_t;
begin
  inherited Create;
  FLastError := weNone;
  FShmSize := SizeOf(TEventState);
  
  LValidatedName := ValidateName(AName);
  FOriginalName := AName;
  FShmPath := CreateShmPath(LValidatedName);
  
  // 尝试创建共享内存
  LFlags := O_CREAT or O_RDWR;
  LMode := S_IRUSR or S_IWUSR or S_IRGRP or S_IWGRP;
  
  FShmFile := shm_open(PAnsiChar(FShmPath), LFlags, LMode);
  if FShmFile = -1 then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to create shared memory for named event "%s": %s',
      [AName, SysErrorMessage(fpGetErrno)]);
  end;
  
  // 检查是否为创建者（通过检查文件是否已存在�?
  FIsCreator := (fpGetErrno <> ESysEEXIST);
  
  // 设置共享内存大小
  if ftruncate(FShmFile, FShmSize) = -1 then
  begin
    FpClose(FShmFile);
    if FIsCreator then
      shm_unlink(PAnsiChar(FShmPath));
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to set shared memory size for named event "%s": %s',
      [AName, SysErrorMessage(fpGetErrno)]);
  end;
  
  // 映射共享内存
  FEventState := PEventState(fpmmap(nil, FShmSize, PROT_READ or PROT_WRITE, MAP_SHARED, FShmFile, 0));
  if FEventState = MAP_FAILED then
  begin
    FpClose(FShmFile);
    if FIsCreator then
      shm_unlink(PAnsiChar(FShmPath));
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to map shared memory for named event "%s": %s',
      [AName, SysErrorMessage(fpGetErrno)]);
  end;
  
  // 初始化事件状�?
  if not InitializeEventState(AConfig) then
  begin
    fpmunmap(FEventState, FShmSize);
    FpClose(FShmFile);
    if FIsCreator then
      shm_unlink(PAnsiChar(FShmPath));
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to initialize named event "%s"', [AName]);
  end;
end;

destructor TNamedEvent.Destroy;
var
  LShouldDestroy: Boolean;
begin
  LShouldDestroy := False;

  if FEventState <> nil then
  begin
    // 减少引用计数并检查是否需要销毁资�?
    if FEventState^.Initialized then
    begin
      if pthread_mutex_lock(@FEventState^.Mutex) = 0 then
      begin
        Dec(FEventState^.RefCount);
        LShouldDestroy := (FEventState^.RefCount <= 0);
        pthread_mutex_unlock(@FEventState^.Mutex);
      end;
    end;

    // 只有当引用计数为0时才销毁同步原�?
    if LShouldDestroy and FEventState^.Initialized then
    begin
      pthread_cond_destroy(@FEventState^.InitCond);
      pthread_cond_destroy(@FEventState^.Cond);
      pthread_mutex_destroy(@FEventState^.Mutex);
    end;

    fpmunmap(FEventState, FShmSize);
  end;

  if FShmFile <> -1 then
    FpClose(FShmFile);

  // 只有当引用计数为0时才删除共享内存
  if LShouldDestroy and (FShmPath <> '') then
    shm_unlink(PAnsiChar(FShmPath));

  inherited Destroy;
end;

function TNamedEvent.ValidateName(const AName: string): string;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named event name cannot be empty');
    
  if Length(AName) > 255 then
    raise EInvalidArgument.CreateFmt('Named event name too long: %d characters (max 255)', [Length(AName)]);
    
  // Unix 命名事件不能包含额外�?'/' 字符
  if Pos('/', AName) > 0 then
    raise EInvalidArgument.CreateFmt('Invalid character in named event name: "%s"', [AName]);
    
  Result := AName;
end;

function TNamedEvent.CreateShmPath(const AName: string): string;
begin
  // POSIX 共享内存名称必须�?'/' 开�?
  Result := '/fafafa_event_' + AName;
end;

function TNamedEvent.InitializeEventState(const AConfig: TNamedEventConfig): Boolean;
var
  LMutexAttr: pthread_mutexattr_t;
  LCondAttr: pthread_condattr_t;
  LLockResult: cint;
begin
  Result := False;

  if FIsCreator then
  begin
    // 创建者负责初始化
    FillChar(FEventState^, SizeOf(TEventState), 0);

    // 初始化互斥锁属性（进程间共享）
    if pthread_mutexattr_init(@LMutexAttr) <> 0 then Exit;
    try
      if pthread_mutexattr_setpshared(@LMutexAttr, PTHREAD_PROCESS_SHARED) <> 0 then Exit;
      if pthread_mutex_init(@FEventState^.Mutex, @LMutexAttr) <> 0 then Exit;
    finally
      pthread_mutexattr_destroy(@LMutexAttr);
    end;

    // 初始化条件变量属性（进程间共享）
    if pthread_condattr_init(@LCondAttr) <> 0 then
    begin
      pthread_mutex_destroy(@FEventState^.Mutex);
      Exit;
    end;
    try
      if pthread_condattr_setpshared(@LCondAttr, PTHREAD_PROCESS_SHARED) <> 0 then
      begin
        pthread_mutex_destroy(@FEventState^.Mutex);
        Exit;
      end;

      // 初始化主条件变量
      if pthread_cond_init(@FEventState^.Cond, @LCondAttr) <> 0 then
      begin
        pthread_mutex_destroy(@FEventState^.Mutex);
        Exit;
      end;

      // 初始化初始化同步条件变量
      if pthread_cond_init(@FEventState^.InitCond, @LCondAttr) <> 0 then
      begin
        pthread_cond_destroy(@FEventState^.Cond);
        pthread_mutex_destroy(@FEventState^.Mutex);
        Exit;
      end;
    finally
      pthread_condattr_destroy(@LCondAttr);
    end;

    // 设置初始状�?
    FEventState^.Signaled := AConfig.InitialState;
    FEventState^.ManualReset := AConfig.ManualReset;
    FEventState^.WaitingCount := 0;
    FEventState^.RefCount := 1;  // 创建者的引用计数
    FEventState^.InitError := False;

    // 标记初始化完成并通知等待�?
    FEventState^.Initialized := True;
    pthread_cond_broadcast(@FEventState^.InitCond);
  end
  else
  begin
    // 非创建者等待初始化完成
    LLockResult := pthread_mutex_lock(@FEventState^.Mutex);
    if LLockResult <> 0 then
    begin
      FLastError := weSystemError;
      Exit;
    end;

    try
      // 使用条件变量等待初始化完成，避免忙等�?
      while not FEventState^.Initialized and not FEventState^.InitError do
      begin
        if pthread_cond_wait(@FEventState^.InitCond, @FEventState^.Mutex) <> 0 then
        begin
          FLastError := weSystemError;
          Exit;
        end;
      end;

      // 检查初始化是否成功
      if FEventState^.InitError then
      begin
        FLastError := weSystemError;
        Exit;
      end;

      // 增加引用计数
      Inc(FEventState^.RefCount);
    finally
      pthread_mutex_unlock(@FEventState^.Mutex);
    end;
  end;

  Result := True;
end;

function TNamedEvent.TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
begin
  Result := GetCurrentTimespec;
  if Result.tv_sec = 0 then
    raise ELockError.Create('Failed to get current time for timeout calculation');
  Result := AddMillisecondsToTimespec(Result, ATimeoutMs);
end;

function TNamedEvent.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TNamedEvent.Wait: INamedEventGuard;
begin
  if pthread_mutex_lock(@FEventState^.Mutex) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to lock mutex for named event "%s": %s',
      [FOriginalName, SysErrorMessage(fpGetErrno)]);
  end;

  try
    Inc(FEventState^.WaitingCount);
    try
      while not FEventState^.Signaled do
        pthread_cond_wait(@FEventState^.Cond, @FEventState^.Mutex);

      // 自动重置事件在被等待后自动重�?
      if not FEventState^.ManualReset then
        FEventState^.Signaled := False;

      Result := TNamedEventGuard.Create(FOriginalName, True);
    finally
      Dec(FEventState^.WaitingCount);
    end;
  finally
    pthread_mutex_unlock(@FEventState^.Mutex);
  end;
end;

function TNamedEvent.TryWait: INamedEventGuard;
begin
  Result := TryWaitFor(0);
end;

function TNamedEvent.TryWaitFor(ATimeoutMs: Cardinal): INamedEventGuard;
var
  LAbsTime: TTimeSpec;
  LResult: cint;
begin
  if ATimeoutMs = 0 then
  begin
    // 非阻塞检�?
    if pthread_mutex_lock(@FEventState^.Mutex) <> 0 then
    begin
      FLastError := weSystemError;
      Exit(nil);
    end;

    try
      if FEventState^.Signaled then
      begin
        if not FEventState^.ManualReset then
          FEventState^.Signaled := False;
        Result := TNamedEventGuard.Create(FOriginalName, True);
      end
      else
        Result := nil;
    finally
      pthread_mutex_unlock(@FEventState^.Mutex);
    end;
    Exit;
  end;

  if ATimeoutMs = Cardinal(-1) then
    Exit(Wait);

  // 使用 pthread_cond_timedwait 实现精确超时
  LAbsTime := TimeoutToTimespec(ATimeoutMs);

  if pthread_mutex_lock(@FEventState^.Mutex) <> 0 then
  begin
    FLastError := weSystemError;
    Exit(nil);
  end;

  try
    Inc(FEventState^.WaitingCount);
    try
      while not FEventState^.Signaled do
      begin
        LResult := pthread_cond_timedwait(@FEventState^.Cond, @FEventState^.Mutex, @LAbsTime);

        if LResult = ESysETIMEDOUT then
        begin
          FLastError := weTimeout;
          Exit(nil);
        end;

        if LResult = ESysEINTR then
          continue; // 信号中断，继续等�?

        if LResult <> 0 then
        begin
          FLastError := weSystemError;
          raise ELockError.CreateFmt('pthread_cond_timedwait failed for named event "%s": error=%d',
            [FOriginalName, LResult]);
        end;
      end;

      // 自动重置事件在被等待后自动重�?
      if not FEventState^.ManualReset then
        FEventState^.Signaled := False;

      Result := TNamedEventGuard.Create(FOriginalName, True);
    finally
      Dec(FEventState^.WaitingCount);
    end;
  finally
    pthread_mutex_unlock(@FEventState^.Mutex);
  end;
end;

procedure TNamedEvent.Signal;
var
  LLockResult: cint;
begin
  // 添加调试信息
  if FEventState = nil then
    raise ELockError.CreateFmt('Event state is nil for named event "%s"', [FOriginalName]);

  if not FEventState^.Initialized then
    raise ELockError.CreateFmt('Event state not initialized for named event "%s"', [FOriginalName]);

  LLockResult := pthread_mutex_lock(@FEventState^.Mutex);
  if LLockResult <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to lock mutex for named event "%s": error=%d, errno=%d, msg=%s',
      [FOriginalName, LLockResult, fpGetErrno, SysErrorMessage(LLockResult)]);
  end;

  try
    FEventState^.Signaled := True;
    if FEventState^.ManualReset then
      pthread_cond_broadcast(@FEventState^.Cond)  // 唤醒所有等待�?
    else
      pthread_cond_signal(@FEventState^.Cond);    // 唤醒一个等待�?
  finally
    pthread_mutex_unlock(@FEventState^.Mutex);
  end;
end;

procedure TNamedEvent.Reset;
begin
  if pthread_mutex_lock(@FEventState^.Mutex) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to lock mutex for named event "%s": %s',
      [FOriginalName, SysErrorMessage(fpGetErrno)]);
  end;

  try
    FEventState^.Signaled := False;
  finally
    pthread_mutex_unlock(@FEventState^.Mutex);
  end;
end;

procedure TNamedEvent.Pulse;
begin
  if pthread_mutex_lock(@FEventState^.Mutex) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.CreateFmt('Failed to lock mutex for named event "%s": %s',
      [FOriginalName, SysErrorMessage(fpGetErrno)]);
  end;

  try
    FEventState^.Signaled := True;
    pthread_cond_broadcast(@FEventState^.Cond);  // 唤醒所有等待�?
    if not FEventState^.ManualReset then
      FEventState^.Signaled := False;  // 立即重置
  finally
    pthread_mutex_unlock(@FEventState^.Mutex);
  end;
end;

function TNamedEvent.GetName: string;
begin
  Result := FOriginalName;
end;

function TNamedEvent.IsManualReset: Boolean;
begin
  if pthread_mutex_lock(@FEventState^.Mutex) <> 0 then
    Exit(False);
  try
    Result := FEventState^.ManualReset;
  finally
    pthread_mutex_unlock(@FEventState^.Mutex);
  end;
end;

function TNamedEvent.IsSignaled: Boolean;
var
  LLockResult: cint;
begin
  LLockResult := pthread_mutex_lock(@FEventState^.Mutex);
  if LLockResult <> 0 then
  begin
    FLastError := weSystemError;
    // 对于查询操作，我们返�?False 而不是抛出异�?
    // 但记录错误状态供调用者检�?
    Exit(False);
  end;

  try
    if FEventState^.ManualReset then
      Result := FEventState^.Signaled
    else
      Result := False; // �?Windows 语义对齐：自动重置不提供非破坏式 IsSignaled
  finally
    if pthread_mutex_unlock(@FEventState^.Mutex) <> 0 then
      FLastError := weSystemError;
  end;
end;



end.
