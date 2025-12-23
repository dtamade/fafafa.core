unit fafafa.core.sync.namedMutex.unix;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$LINKLIB pthread}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType,
  fafafa.core.sync.base, fafafa.core.sync.namedMutex.base,
  fafafa.core.sync.timespec;

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
    // ILockGuard 实现
    function IsLocked: Boolean;
    procedure Release;
  end;
  TNamedMutex = class(TSynchronizable, ILock, INamedMutex)
  private
    FMutex: PPThreadMutex;      // pthread_mutex_t 指针
    FShmFile: cint;             // 共享内存文件描述符
    FShmPath: AnsiString;       // 共享内存路径（使用 AnsiString 减少转换开销）
    FOriginalName: string;      // 保存用户提供的原始名称
    FIsCreator: Boolean;        // 是否为创建者
    FShmSize: csize_t;          // 缓存共享内存大小
    FLastError: TWaitError;
    
    function ValidateName(const AName: string): string;
    function CreateShmPath(const AName: string): string;
    function InitializeMutex: Boolean;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; AInitialOwner: Boolean); overload;
    destructor Destroy; override;

    // ISynchronizable 接口
    function GetLastError: TWaitError;

    // ILock 接口 - 现代 API
    procedure Acquire;
    procedure Release;
    function Lock: ILockGuard;
    function TryLock: ILockGuard;
    function LockGuard: ILockGuard;
    
    function TryAcquireLock: Boolean; overload;
    function TryAcquireLock(ATimeoutMs: Cardinal): Boolean; overload;

    // 现代化接口 - 带名称信息
    function LockNamed: INamedMutexGuard;
    function TryLockNamed: INamedMutexGuard;
    function TryLockForNamed(ATimeoutMs: Cardinal): INamedMutexGuard;
    function GetName: string;
    function GetHandle: Pointer;
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

function TNamedMutexGuard.IsLocked: Boolean;
begin
  Result := Assigned(FMutex) and (not FReleased);
end;

procedure TNamedMutexGuard.Release;
begin
  if Assigned(FMutex) and (not FReleased) then
  begin
    pthread_mutex_unlock(FMutex);
    FReleased := True;
  end;
end;

{ TNamedMutex }

function TNamedMutex.ValidateName(const AName: string): string;
var
  i: Integer;
  LName: string;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named mutex name cannot be empty');

  // 处理 Windows 风格的 Global\ 前缀
  // 在 Unix 上，将 Global\ 转换为 global_ 前缀
  LName := AName;
  if (Length(LName) > 7) and (Copy(LName, 1, 7) = 'Global\') then
    LName := 'global_' + Copy(LName, 8, Length(LName) - 7);

  // 共享内存名称规则：
  // - 不能包含路径分隔符和特殊字符
  // - 长度限制为 255 字符
  Result := LName;

  if Length(Result) > 255 then
    raise EInvalidArgument.Create('Named mutex name too long (max 255 characters)');

  // 检查是否包含非法字符
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
      [AName, SysErrorMessage(GetCErrno)]);

  try
    // 检查文件是否是新创建的（优化：使用 fstat 而不�?lseek�?
    FIsCreator := (fpLSeek(FShmFile, 0, SEEK_END) = 0);

    // 设置文件大小
    if FIsCreator then
    begin
      if fpFTruncate(FShmFile, FShmSize) <> 0 then
        raise ELockError.CreateFmt('Failed to set shared memory size for named mutex "%s": %s',
          [AName, SysErrorMessage(GetCErrno)]);
    end;

    // 映射共享内存
    FMutex := PPThreadMutex(fpMMap(nil, FShmSize, PROT_READ or PROT_WRITE, MAP_SHARED, FShmFile, 0));
    if FMutex = PPThreadMutex(-1) then
      raise ELockError.CreateFmt('Failed to map shared memory for named mutex "%s": %s',
        [AName, SysErrorMessage(GetCErrno)]);

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

function TNamedMutex.Lock: ILockGuard;
begin
  Result := Self.LockNamed;
end;

function TNamedMutex.TryLock: ILockGuard;
begin
  Result := Self.TryLockNamed;
end;

function TNamedMutex.LockGuard: ILockGuard;
begin
  Result := Self.Lock;
end;

function TNamedMutex.LockNamed: INamedMutexGuard;
begin
  // Directly use pthread mutex lock to avoid overhead
  if pthread_mutex_lock(FMutex) <> 0 then
    raise ELockError.CreateFmt('Failed to acquire named mutex "%s": %s',
      [FOriginalName, SysErrorMessage(GetCErrno)]);

  Result := TNamedMutexGuard.Create(FMutex, FOriginalName);
end;

function TNamedMutex.TryLockNamed: INamedMutexGuard;
begin
  if pthread_mutex_trylock(FMutex) = 0 then
    Result := TNamedMutexGuard.Create(FMutex, FOriginalName)
  else
    Result := nil;
end;

function TNamedMutex.TryLockForNamed(ATimeoutMs: Cardinal): INamedMutexGuard;
var
  LTimespec: TTimeSpec;
  LResult: cint;
begin
  if ATimeoutMs = 0 then
    Exit(TryLockNamed);

  if ATimeoutMs = Cardinal(-1) then
    Exit(LockNamed);

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

procedure TNamedMutex.Acquire;
begin
  if FMutex = nil then
    raise ELockError.CreateFmt('Named mutex "%s" not initialized', [FOriginalName]);

  if pthread_mutex_lock(@FMutex^) <> 0 then
    raise ELockError.CreateFmt('Failed to acquire named mutex "%s": %s',
      [FOriginalName, SysErrorMessage(GetCErrno)]);
end;

procedure TNamedMutex.Release;
begin
  if FMutex = nil then
    raise ELockError.CreateFmt('Named mutex "%s" not initialized', [FOriginalName]);

  if pthread_mutex_unlock(@FMutex^) <> 0 then
    raise ELockError.CreateFmt('Failed to release named mutex "%s": %s',
      [FOriginalName, SysErrorMessage(GetCErrno)]);
end;

function TNamedMutex.TryAcquireLock: Boolean;
begin
  if FMutex = nil then
    raise ELockError.CreateFmt('Named mutex "%s" not initialized', [FOriginalName]);

  Result := pthread_mutex_trylock(@FMutex^) = 0;
end;

function TNamedMutex.TryAcquireLock(ATimeoutMs: Cardinal): Boolean;
var
  LTimespec: TTimeSpec;
  LResult: cint;
begin
  Result := False;  // 初始化返回值
  if ATimeoutMs = 0 then
    Exit(TryAcquireLock);

  if ATimeoutMs = Cardinal(-1) then
  begin
    Acquire;
    Exit(True);
  end;

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

function TNamedMutex.GetHandle: Pointer;
begin
  Result := FMutex;
end;

end.
