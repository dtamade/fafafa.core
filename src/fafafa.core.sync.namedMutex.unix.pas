unit fafafa.core.sync.namedMutex.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$LINKLIB pthread}

interface

uses
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedMutex.base;

type
  // pthread_mutex_t 指针类型
  PPThreadMutex = ^TPThreadMutex;
  TPThreadMutex = record
    // 平台相关�?pthread_mutex_t 结构
    // 使用 opaque 数组来避免平台差�?
    data: array[0..39] of Byte; // 足够大的空间
  end;

  // pthread_mutexattr_t 指针类型
  PPThreadMutexAttr = ^TPThreadMutexAttr;
  TPThreadMutexAttr = record
    data: array[0..3] of Byte;
  end;

  // RAII 守卫实现
  TNamedMutexGuard = class(TInterfacedObject, INamedMutexGuard)
  private
    FMutex: PPThreadMutex;
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(AMutex: PPThreadMutex; const AName: string);
    destructor Destroy; override;
    function GetName: string;
  end;

  TNamedMutex = class(TSynchronizable, INamedMutex)
  private
    FMutex: PPThreadMutex;      // pthread_mutex_t 指针
    FShmFile: cint;             // 共享内存文件描述�?
    FShmPath: AnsiString;       // 共享内存路径（使�?AnsiString 减少转换开销�?
    FOriginalName: string;      // 保存用户提供的原始名�?
    FIsCreator: Boolean;        // 是否为创建�?
    FShmSize: csize_t;          // 缓存共享内存大小
    
    function ValidateName(const AName: string): string;
    function CreateShmPath(const AName: string): string;
    function InitializeMutex: Boolean;
    function TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
  private
    FLastError: TWaitError;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; AInitialOwner: Boolean); overload;
    destructor Destroy; override;

    // ISynchronizable 接口
    function GetLastError: TWaitError;

    // 现代化接�?    function Lock: INamedMutexGuard;
    function TryLock: INamedMutexGuard;
    function TryLockFor(ATimeoutMs: Cardinal): INamedMutexGuard;
    function GetName: string;
    // ILock 接口补充：RAII 锁守�?    function LockGuard: ILockGuard;

    // 兼容性接口（已弃用）
    procedure Acquire; deprecated;
    procedure Release; deprecated;
    function TryAcquire: Boolean; deprecated;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload; deprecated;
    procedure Acquire(ATimeoutMs: Cardinal); overload; deprecated;
    function GetHandle: Pointer; deprecated;
    function IsCreator: Boolean; deprecated;
    function IsAbandoned: Boolean; deprecated;
  end;

// pthread 函数声明 - 现代 Linux 系统�?pthread 函数�?libc �?
function pthread_mutex_init(mutex: PPThreadMutex; attr: PPThreadMutexAttr): cint; cdecl; external 'c';
function pthread_mutex_destroy(mutex: PPThreadMutex): cint; cdecl; external 'c';
function pthread_mutex_lock(mutex: PPThreadMutex): cint; cdecl; external 'c';
function pthread_mutex_unlock(mutex: PPThreadMutex): cint; cdecl; external 'c';
function pthread_mutex_trylock(mutex: PPThreadMutex): cint; cdecl; external 'c';
function pthread_mutex_timedlock(mutex: PPThreadMutex; abs_timeout: PTimeSpec): cint; cdecl; external 'c';
function pthread_mutexattr_init(attr: PPThreadMutexAttr): cint; cdecl; external 'c';
function pthread_mutexattr_destroy(attr: PPThreadMutexAttr): cint; cdecl; external 'c';
function pthread_mutexattr_setpshared(attr: PPThreadMutexAttr; pshared: cint): cint; cdecl; external 'c';

const
  PTHREAD_PROCESS_SHARED = 1;
  PTHREAD_PROCESS_PRIVATE = 0;

implementation

{ TNamedMutexGuard }

constructor TNamedMutexGuard.Create(AMutex: PPThreadMutex; const AName: string);
begin
  inherited Create;
  FMutex := AMutex;
  FName := AName;
  FReleased := False;
end;

destructor TNamedMutexGuard.Destroy;
begin
  if not FReleased and Assigned(FMutex) then
  begin
    pthread_mutex_unlock(FMutex);
    FReleased := True;
  end;
  inherited Destroy;
end;

function TNamedMutexGuard.GetName: string;
begin
  Result := FName;
end;

{ TNamedMutex }

function TNamedMutex.ValidateName(const AName: string): string;
var
  i: Integer;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named mutex name cannot be empty');

  // 共享内存名称规则�?
  // - 不能包含路径分隔符和特殊字符
  // - 长度限制�?255 字符
  Result := AName;

  if Length(Result) > 255 then
    raise EInvalidArgument.Create('Named mutex name too long (max 255 characters)');

  // 检查是否包含非法字�?
  for i := 1 to Length(Result) do
  begin
    if Result[i] in ['/', '\', ':', '*', '?', '"', '<', '>', '|'] then
      raise EInvalidArgument.Create('Named mutex name contains invalid characters');
  end;
end;

function TNamedMutex.CreateShmPath(const AName: string): string;
const
  SHM_PREFIX = '/dev/shm/fafafa_mutex_';
begin
  // �?/dev/shm 目录下创建共享内存文�?
  // 使用常量前缀减少字符串分�?
  Result := SHM_PREFIX + AName;
end;

function TNamedMutex.InitializeMutex: Boolean;
var
  LAttr: TPThreadMutexAttr;
  LAttrPtr: PPThreadMutexAttr;
begin
  Result := False;

  // 初始化互斥锁属�?
  LAttrPtr := @LAttr;
  if pthread_mutexattr_init(LAttrPtr) <> 0 then
    Exit;

  try
    // 设置为进程间共享
    if pthread_mutexattr_setpshared(LAttrPtr, PTHREAD_PROCESS_SHARED) <> 0 then
      Exit;

    // 初始化互斥锁
    if pthread_mutex_init(FMutex, LAttrPtr) <> 0 then
      Exit;

    Result := True;
  finally
    pthread_mutexattr_destroy(LAttrPtr);
  end;
end;

function TNamedMutex.TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
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



constructor TNamedMutex.Create(const AName: string);
begin
  Create(AName, False);
end;

function TNamedMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

constructor TNamedMutex.Create(const AName: string; AInitialOwner: Boolean);
var
  LValidatedName: string;
  LFlags: cint;
  LAnsiPath: AnsiString;
begin
  inherited Create;

  FOriginalName := AName;  // 保存原始名称
  LValidatedName := ValidateName(AName);
  FShmPath := AnsiString(CreateShmPath(LValidatedName));
  FShmFile := -1;
  FMutex := nil;
  FLastError := weNone;

  // 缓存共享内存大小（pthread_mutex_t 的大小）
  FShmSize := SizeOf(TPThreadMutex);

  // 转换�?AnsiString 减少后续转换开销
  LAnsiPath := FShmPath;

  // 尝试创建共享内存文件
  LFlags := O_CREAT or O_RDWR;
  FShmFile := fpOpen(PAnsiChar(LAnsiPath), LFlags, S_IRUSR or S_IWUSR or S_IRGRP or S_IWGRP);

  if FShmFile = -1 then
    raise ELockError.CreateFmt('Failed to create shared memory for named mutex "%s": %s',
      [AName, SysErrorMessage(fpGetErrno)]);

  try
    // 检查文件是否是新创建的（优化：使用 fstat 而不�?lseek�?
    FIsCreator := (fpLSeek(FShmFile, 0, SEEK_END) = 0);

    // 设置文件大小
    if FIsCreator then
    begin
      if fpFTruncate(FShmFile, FShmSize) <> 0 then
        raise ELockError.CreateFmt('Failed to set shared memory size for named mutex "%s": %s',
          [AName, SysErrorMessage(fpGetErrno)]);
    end;

    // 映射共享内存
    FMutex := PPThreadMutex(fpMMap(nil, FShmSize, PROT_READ or PROT_WRITE, MAP_SHARED, FShmFile, 0));
    if FMutex = PPThreadMutex(-1) then
      raise ELockError.CreateFmt('Failed to map shared memory for named mutex "%s": %s',
        [AName, SysErrorMessage(fpGetErrno)]);

    // 如果是创建者，初始化互斥锁
    if FIsCreator then
    begin
      if not InitializeMutex then
        raise ELockError.CreateFmt('Failed to initialize mutex for named mutex "%s"', [AName]);
    end;

    // 如果要求初始拥有，立即获取锁
    if AInitialOwner then
    begin
      if pthread_mutex_lock(FMutex) <> 0 then
        raise ELockError.CreateFmt('Failed to acquire initial ownership of named mutex "%s"', [AName]);
    end;

  except
    // 清理资源
    if FMutex <> nil then
      fpMUnMap(FMutex, FShmSize);
    if FShmFile <> -1 then
      fpClose(FShmFile);
    if FIsCreator then
      fpUnlink(PAnsiChar(LAnsiPath));
    raise;
  end;
end;

destructor TNamedMutex.Destroy;
begin
  // 清理互斥�?
  if Assigned(FMutex) then
  begin
    if FIsCreator then
      pthread_mutex_destroy(FMutex);

    fpMUnMap(FMutex, FShmSize);  // 使用缓存的大�?
    FMutex := nil;
  end;

  // 清理共享内存文件
  if FShmFile <> -1 then
  begin
    fpClose(FShmFile);
    FShmFile := -1;

    // 如果是创建者，删除共享内存文件
    if FIsCreator then
      fpUnlink(PAnsiChar(FShmPath));  // 直接使用 AnsiString
  end;

  inherited Destroy;
end;

function TNamedMutex.Lock: INamedMutexGuard;
begin
  if pthread_mutex_lock(FMutex) <> 0 then
    raise ELockError.CreateFmt('Failed to acquire named mutex "%s": %s',
      [FOriginalName, SysErrorMessage(fpGetErrno)]);

  Result := TNamedMutexGuard.Create(FMutex, FOriginalName);
end;

function TNamedMutex.TryLock: INamedMutexGuard;
begin
  if pthread_mutex_trylock(FMutex) = 0 then
    Result := TNamedMutexGuard.Create(FMutex, FOriginalName)
  else
    Result := nil;
end;

function TNamedMutex.TryLockFor(ATimeoutMs: Cardinal): INamedMutexGuard;
var
  LTimespec: TTimeSpec;
  LResult: cint;
begin
  if ATimeoutMs = 0 then
    Exit(TryLock);

  if ATimeoutMs = Cardinal(-1) then
    Exit(Lock);

  // 使用高效�?pthread_mutex_timedlock
  LTimespec := TimeoutToTimespec(ATimeoutMs);
  LResult := pthread_mutex_timedlock(FMutex, @LTimespec);

  if LResult = 0 then
    Result := TNamedMutexGuard.Create(FMutex, FOriginalName)
  else if LResult = ESysETIMEDOUT then
    Result := nil
  else
    raise ELockError.CreateFmt('Failed to acquire named mutex "%s" with timeout: %s',
      [FOriginalName, SysErrorMessage(LResult)]);
end;

function TNamedMutex.GetName: string;
begin
  Result := FOriginalName;
end;

function TNamedMutex.LockGuard: ILockGuard;
begin
  Result := MakeLockGuard(Self as ILock);
end;

// 兼容性方法（已弃用）
procedure TNamedMutex.Acquire;
begin
  // 直接调用 pthread_mutex_lock，不使用 RAII 守卫
  if FMutex = nil then
    raise ELockError.CreateFmt('Named mutex "%s" not initialized', [FOriginalName]);

  if pthread_mutex_lock(@FMutex^) <> 0 then
    raise ELockError.CreateFmt('Failed to acquire named mutex "%s": %s',
      [FOriginalName, SysErrorMessage(fpGetErrno)]);
end;

procedure TNamedMutex.Release;
begin
  // 兼容性实现：直接释放互斥�?
  // 注意：这不是线程安全的，仅为向后兼容
  if FMutex = nil then
    raise ELockError.CreateFmt('Named mutex "%s" not initialized', [FOriginalName]);

  if pthread_mutex_unlock(@FMutex^) <> 0 then
    raise ELockError.CreateFmt('Failed to release named mutex "%s": %s',
      [FOriginalName, SysErrorMessage(fpGetErrno)]);
end;

function TNamedMutex.TryAcquire: Boolean;
begin
  // 直接调用 pthread_mutex_trylock，不使用 RAII 守卫
  if FMutex = nil then
    raise ELockError.CreateFmt('Named mutex "%s" not initialized', [FOriginalName]);

  Result := pthread_mutex_trylock(@FMutex^) = 0;
end;

function TNamedMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  LTimespec: TTimeSpec;
  LResult: cint;
begin
  if ATimeoutMs = 0 then
    Exit(TryAcquire);

  if ATimeoutMs = Cardinal(-1) then
  begin
    Acquire;
    Exit(True);
  end;

  // 使用 pthread_mutex_timedlock，不使用 RAII 守卫
  if FMutex = nil then
    raise ELockError.CreateFmt('Named mutex "%s" not initialized', [FOriginalName]);

  LTimespec := TimeoutToTimespec(ATimeoutMs);
  LResult := pthread_mutex_timedlock(@FMutex^, @LTimespec);

  if LResult = 0 then
    Result := True
  else if LResult = ESysETIMEDOUT then
    Result := False
  else
    raise ELockError.CreateFmt('Failed to acquire named mutex "%s" with timeout: %s',
      [FOriginalName, SysErrorMessage(LResult)]);
end;

procedure TNamedMutex.Acquire(ATimeoutMs: Cardinal);
var
  LGuard: INamedMutexGuard;
begin
  LGuard := TryLockFor(ATimeoutMs);
  if not Assigned(LGuard) then
    raise ETimeoutError.CreateFmt('Timeout waiting for named mutex "%s"', [FOriginalName]);
  // 注意：锁会在方法结束时自动释�?
end;

function TNamedMutex.GetHandle: Pointer;
begin
  Result := FMutex;
end;

function TNamedMutex.IsCreator: Boolean;
begin
  Result := FIsCreator;
end;

function TNamedMutex.IsAbandoned: Boolean;
begin
  // Unix 平台不支持遗弃检�?
  Result := False;
end;



end.
