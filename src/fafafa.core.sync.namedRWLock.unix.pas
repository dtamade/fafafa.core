unit fafafa.core.sync.namedRWLock.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, cthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.namedRWLock.base,
  fafafa.core.atomic;

{$LINKLIB pthread}
{$LINKLIB rt}

type
  // pthread 相关类型定义
  pthread_rwlock_t = record
    data: array[0..55] of Byte; // 足够大的空间
  end;
  ppthread_rwlock_t = ^pthread_rwlock_t;

  pthread_rwlockattr_t = record
    data: array[0..7] of Byte;
  end;
  ppthread_rwlockattr_t = ^pthread_rwlockattr_t;

  TTimeSpec = record
    tv_sec: clong;
    tv_nsec: clong;
  end;
  PTimeSpec = ^TTimeSpec;

// pthread 函数声明
function pthread_rwlock_init(rwlock: ppthread_rwlock_t; attr: ppthread_rwlockattr_t): cint; cdecl; external;
function pthread_rwlock_destroy(rwlock: ppthread_rwlock_t): cint; cdecl; external;
function pthread_rwlock_rdlock(rwlock: ppthread_rwlock_t): cint; cdecl; external;
function pthread_rwlock_wrlock(rwlock: ppthread_rwlock_t): cint; cdecl; external;
function pthread_rwlock_unlock(rwlock: ppthread_rwlock_t): cint; cdecl; external;
function pthread_rwlock_tryrdlock(rwlock: ppthread_rwlock_t): cint; cdecl; external;
function pthread_rwlock_trywrlock(rwlock: ppthread_rwlock_t): cint; cdecl; external;
function pthread_rwlock_timedrdlock(rwlock: ppthread_rwlock_t; abstime: PTimeSpec): cint; cdecl; external;
function pthread_rwlock_timedwrlock(rwlock: ppthread_rwlock_t; abstime: PTimeSpec): cint; cdecl; external;

function pthread_rwlockattr_init(attr: ppthread_rwlockattr_t): cint; cdecl; external;
function pthread_rwlockattr_destroy(attr: ppthread_rwlockattr_t): cint; cdecl; external;
function pthread_rwlockattr_setpshared(attr: ppthread_rwlockattr_t; pshared: cint): cint; cdecl; external;

// POSIX 共享内存函数
function shm_open(name: PAnsiChar; oflag: cint; mode: mode_t): cint; cdecl; external;
function shm_unlink(name: PAnsiChar): cint; cdecl; external;
function ftruncate(fd: cint; length: off_t): cint; cdecl; external;
function mmap(addr: Pointer; length: size_t; prot: cint; flags: cint; fd: cint; offset: off_t): Pointer; cdecl; external;
function munmap(addr: Pointer; length: size_t): cint; cdecl; external;
function fpClose(fd: cint): cint; cdecl; external name 'close';
function fpGetErrno: cint; cdecl; external name '__errno_location';

const
  PTHREAD_PROCESS_SHARED = 1;
  ESysETIMEDOUT = 110;
  ESysEBUSY = 16;
  ESysEEXIST = 17;

  // 共享内存标志
  O_CREAT = $40;
  O_EXCL = $80;
  O_RDWR = 2;

  // mmap 标志
  PROT_READ = 1;
  PROT_WRITE = 2;
  MAP_SHARED = 1;
  MAP_FAILED = Pointer(-1);

  // 文件权限
  S_IRUSR = $100;
  S_IWUSR = $80;
  S_IRGRP = $20;
  S_IWGRP = $10;

type
  // RAII 读锁守卫实现
  TNamedRWLockReadGuard = class(TInterfacedObject, INamedRWLockReadGuard)
  private
    FRWLock: Pointer;  // 指向 TNamedRWLock
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(ARWLock: Pointer; const AName: string);
    destructor Destroy; override;
    function GetName: string;
  end;

  // RAII 写锁守卫实现
  TNamedRWLockWriteGuard = class(TInterfacedObject, INamedRWLockWriteGuard)
  private
    FRWLock: Pointer;  // 指向 TNamedRWLock
    FName: string;
    FReleased: Boolean;
  public
    constructor Create(ARWLock: Pointer; const AName: string);
    destructor Destroy; override;
    function GetName: string;
  end;

  TNamedRWLock = class(TSynchronizable, INamedRWLock)
  private
    FShmFile: cint;             // 共享内存文件描述符
    FShmPath: AnsiString;       // 共享内存路径
    FSharedData: Pointer;       // 共享数据指针
    FOriginalName: string;      // 保存用户提供的原始名称
    FIsCreator: Boolean;        // 是否为创建者
    FShmSize: csize_t;          // 缓存共享内存大小
    FLastError: TWaitError;
    
    // 共享数据结构
    type
      PSharedRWLockData = ^TSharedRWLockData;
      TSharedRWLockData = record
        RWLock: pthread_rwlock_t; // pthread 读写锁
        ReaderCount: Integer;     // 读者计数（原子操作保护）
        WriterThread: Int64;      // 写者线程ID（原子操作保护）
        MaxReaders: Integer;      // 最大读者数量
        Initialized: Boolean;     // 初始化标志（原子操作保护）
        ProcessCount: Integer;    // 进程引用计数（用于清理）
        CreatorPID: Integer;      // 创建者进程ID
        LastAccessTime: Int64;    // 最后访问时间（用于清理检测）
      end;
    
    function ValidateName(const AName: string): string;
    function CreateShmPath(const AName: string): string;
    function CreateSharedMemory(const AName: string; AInitialOwner: Boolean): Boolean;
    function GetSharedData: PSharedRWLockData;
    procedure InitializeSharedData;
    function TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; AInitialOwner: Boolean); overload;
    destructor Destroy; override;
    
    // ISynchronizable 接口
    function GetLastError: TWaitError;

    // 现代化 API
    function ReadLock: INamedRWLockReadGuard;
    function WriteLock: INamedRWLockWriteGuard;
    function TryReadLock: INamedRWLockReadGuard;
    function TryWriteLock: INamedRWLockWriteGuard;
    function TryReadLockFor(ATimeoutMs: Cardinal): INamedRWLockReadGuard;
    function TryWriteLockFor(ATimeoutMs: Cardinal): INamedRWLockWriteGuard;

    // 查询操作
    function GetName: string;

    // 状态查询方法
    function GetHandle: Pointer;
    function GetReaderCount: Integer;
    function IsWriteLocked: Boolean;
    
    // 内部方法
    procedure InternalAcquireRead;
    procedure InternalReleaseRead;
    procedure InternalAcquireWrite;
    procedure InternalReleaseWrite;
    function InternalTryAcquireRead(ATimeoutMs: Cardinal): Boolean;
    function InternalTryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
  end;

implementation

{ TNamedRWLockReadGuard }

constructor TNamedRWLockReadGuard.Create(ARWLock: Pointer; const AName: string);
begin
  inherited Create;
  FRWLock := ARWLock;
  FName := AName;
  FReleased := False;
end;

destructor TNamedRWLockReadGuard.Destroy;
begin
  if not FReleased and Assigned(FRWLock) then
  begin
    TNamedRWLock(FRWLock).InternalReleaseRead;
    FReleased := True;
  end;
  inherited Destroy;
end;

function TNamedRWLockReadGuard.GetName: string;
begin
  Result := FName;
end;

{ TNamedRWLockWriteGuard }

constructor TNamedRWLockWriteGuard.Create(ARWLock: Pointer; const AName: string);
begin
  inherited Create;
  FRWLock := ARWLock;
  FName := AName;
  FReleased := False;
end;

destructor TNamedRWLockWriteGuard.Destroy;
begin
  if not FReleased and Assigned(FRWLock) then
  begin
    TNamedRWLock(FRWLock).InternalReleaseWrite;
    FReleased := True;
  end;
  inherited Destroy;
end;

function TNamedRWLockWriteGuard.GetName: string;
begin
  Result := FName;
end;

{ TNamedRWLock }

function TNamedRWLock.ValidateName(const AName: string): string;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named RWLock name cannot be empty');
  
  // Unix 命名规则：
  // - 长度限制为 255 字符 (NAME_MAX)
  // - 不能包含 '/' 字符（除了前缀）
  Result := AName;
  if Length(Result) > 255 then
    raise EInvalidArgument.Create('Named RWLock name too long (max 255 characters)');
  
  // 检查非法字符
  if Pos('/', Result) > 0 then
    raise EInvalidArgument.Create('Invalid characters in RWLock name');
end;

function TNamedRWLock.CreateShmPath(const AName: string): string;
begin
  // 创建符合 POSIX 规范的共享内存路径
  Result := '/rwlock_' + AName;
end;

constructor TNamedRWLock.Create(const AName: string);
begin
  Create(AName, False);
end;

constructor TNamedRWLock.Create(const AName: string; AInitialOwner: Boolean);
var
  LName: string;
begin
  inherited Create;

  LName := ValidateName(AName);
  FOriginalName := LName;
  FShmPath := CreateShmPath(LName);
  FLastError := weNone;
  FShmFile := -1;
  FSharedData := nil;

  if not CreateSharedMemory(LName, AInitialOwner) then
    raise ELockError.CreateFmt('Failed to create named RWLock "%s": %s',
      [LName, SysErrorMessage(fpGetErrno)]);
end;

destructor TNamedRWLock.Destroy;
var
  LData: PSharedRWLockData;
  LProcessCount: Integer;
  LShouldCleanup: Boolean;
begin
  if Assigned(FSharedData) then
  begin
    LData := GetSharedData;
    LShouldCleanup := False;

    if Assigned(LData) then
    begin
      // 原子递减进程引用计数
      LProcessCount := atomic_decrement(LData^.ProcessCount);

      // 如果是最后一个进程，需要清理共享资源
      if LProcessCount = 0 then
      begin
        LShouldCleanup := True;
        // 销毁 pthread_rwlock
        pthread_rwlock_destroy(@LData^.RWLock);
      end;
    end;

    // 解除内存映射
    munmap(FSharedData, FShmSize);
    FSharedData := nil;

    // 如果是最后一个进程，删除共享内存对象
    if LShouldCleanup then
      shm_unlink(PAnsiChar(FShmPath));
  end;

  // 关闭文件描述符
  if FShmFile >= 0 then
  begin
    fpClose(FShmFile);
    FShmFile := -1;
  end;

  inherited Destroy;
end;

function TNamedRWLock.CreateSharedMemory(const AName: string; AInitialOwner: Boolean): Boolean;
var
  LFlags: cint;
  LMode: mode_t;
  LCreated: Boolean;
  LData: PSharedRWLockData;
begin
  Result := False;
  FShmSize := SizeOf(TSharedRWLockData);
  FShmPath := CreateShmPath(AName);

  // 设置文件权限：用户和组可读写
  LMode := S_IRUSR or S_IWUSR or S_IRGRP or S_IWGRP;

  // 首先尝试创建新的共享内存对象
  LFlags := O_CREAT or O_EXCL or O_RDWR;
  FShmFile := shm_open(PAnsiChar(FShmPath), LFlags, LMode);

  if FShmFile >= 0 then
  begin
    // 成功创建，我们是创建者
    FIsCreator := True;
    LCreated := True;
  end
  else
  begin
    // 创建失败，尝试打开现有的
    LFlags := O_RDWR;
    FShmFile := shm_open(PAnsiChar(FShmPath), LFlags, 0);
    if FShmFile < 0 then
      Exit; // 打开失败

    FIsCreator := False;
    LCreated := False;
  end;

  try
    // 如果是创建者，设置共享内存大小
    if FIsCreator then
    begin
      if ftruncate(FShmFile, FShmSize) < 0 then
        Exit;
    end;

    // 映射共享内存到进程地址空间
    FSharedData := mmap(nil, FShmSize, PROT_READ or PROT_WRITE, MAP_SHARED, FShmFile, 0);
    if FSharedData = MAP_FAILED then
    begin
      FSharedData := nil;
      Exit;
    end;

    // 如果是创建者，初始化共享数据
    if FIsCreator then
      InitializeSharedData
    else
    begin
      // 非创建者需要增加进程引用计数
      LData := GetSharedData;
      if Assigned(LData) then
      begin
        atomic_increment(LData^.ProcessCount);
        atomic_store_64(LData^.LastAccessTime, Int64(GetTickCount64()));
      end;
    end;

    Result := True;
  except
    // 出错时清理资源
    if FSharedData <> nil then
    begin
      munmap(FSharedData, FShmSize);
      FSharedData := nil;
    end;
    if FShmFile >= 0 then
    begin
      fpClose(FShmFile);
      FShmFile := -1;
    end;
    if LCreated then
      shm_unlink(PAnsiChar(FShmPath));
    raise;
  end;
end;

function TNamedRWLock.GetSharedData: PSharedRWLockData;
begin
  Result := PSharedRWLockData(FSharedData);
end;

procedure TNamedRWLock.InitializeSharedData;
var
  LData: PSharedRWLockData;
  LAttr: pthread_rwlockattr_t;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    Exit;

  // 初始化 pthread_rwlockattr_t
  if pthread_rwlockattr_init(@LAttr) <> 0 then
    raise ELockError.Create('Failed to initialize rwlock attributes');

  try
    // 设置为进程间共享
    if pthread_rwlockattr_setpshared(@LAttr, PTHREAD_PROCESS_SHARED) <> 0 then
      raise ELockError.Create('Failed to set rwlock process-shared attribute');

    // 初始化 pthread_rwlock_t
    if pthread_rwlock_init(@LData^.RWLock, @LAttr) <> 0 then
      raise ELockError.Create('Failed to initialize pthread rwlock');

    // 初始化其他字段（使用原子操作保护）
    atomic_store(LData^.ReaderCount, 0);
    atomic_store_64(LData^.WriterThread, 0);
    LData^.MaxReaders := 1024;
    atomic_store(LData^.ProcessCount, 1);  // 创建者是第一个进程
    LData^.CreatorPID := fpgetpid();
    atomic_store_64(LData^.LastAccessTime, Int64(GetTickCount64()));

    // 内存屏障确保所有初始化完成后再设置 Initialized 标志
    atomic_thread_fence(memory_order_seq_cst);
    atomic_store(PInteger(@LData^.Initialized)^, 1);
  finally
    pthread_rwlockattr_destroy(@LAttr);
  end;
end;

function TNamedRWLock.TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
var
  LNow: TTimeVal;
  LNanoSecs: Int64;
begin
  // 获取当前时间
  fpgettimeofday(@LNow, nil);

  // 计算绝对超时时间
  LNanoSecs := Int64(LNow.tv_usec) * 1000 + Int64(ATimeoutMs) * 1000000;

  Result.tv_sec := LNow.tv_sec + (LNanoSecs div 1000000000);
  Result.tv_nsec := LNanoSecs mod 1000000000;
end;

function TNamedRWLock.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TNamedRWLock.ReadLock: INamedRWLockReadGuard;
begin
  InternalAcquireRead;
  Result := TNamedRWLockReadGuard.Create(Self, FOriginalName);
end;

function TNamedRWLock.WriteLock: INamedRWLockWriteGuard;
begin
  InternalAcquireWrite;
  Result := TNamedRWLockWriteGuard.Create(Self, FOriginalName);
end;

function TNamedRWLock.TryReadLock: INamedRWLockReadGuard;
begin
  if InternalTryAcquireRead(0) then
    Result := TNamedRWLockReadGuard.Create(Self, FOriginalName)
  else
    Result := nil;
end;

function TNamedRWLock.TryWriteLock: INamedRWLockWriteGuard;
begin
  if InternalTryAcquireWrite(0) then
    Result := TNamedRWLockWriteGuard.Create(Self, FOriginalName)
  else
    Result := nil;
end;

function TNamedRWLock.TryReadLockFor(ATimeoutMs: Cardinal): INamedRWLockReadGuard;
begin
  if InternalTryAcquireRead(ATimeoutMs) then
    Result := TNamedRWLockReadGuard.Create(Self, FOriginalName)
  else
    Result := nil;
end;

function TNamedRWLock.TryWriteLockFor(ATimeoutMs: Cardinal): INamedRWLockWriteGuard;
begin
  if InternalTryAcquireWrite(ATimeoutMs) then
    Result := TNamedRWLockWriteGuard.Create(Self, FOriginalName)
  else
    Result := nil;
end;

function TNamedRWLock.GetName: string;
begin
  Result := FOriginalName;
end;

// 状态查询方法实现

function TNamedRWLock.GetHandle: Pointer;
begin
  Result := FSharedData;
end;



function TNamedRWLock.GetReaderCount: Integer;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if Assigned(LData) then
    Result := LData^.ReaderCount
  else
    Result := 0;
end;

function TNamedRWLock.IsWriteLocked: Boolean;
var
  LData: PSharedRWLockData;
begin
  LData := GetSharedData;
  if Assigned(LData) then
    Result := (LData^.WriterThread <> 0)
  else
    Result := False;
end;

// 内部实现方法
procedure TNamedRWLock.InternalAcquireRead;
var
  LData: PSharedRWLockData;
  LResult: cint;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  LResult := pthread_rwlock_rdlock(@LData^.RWLock);
  if LResult = 0 then
  begin
    // 使用原子操作增加读者计数
    atomic_increment(LData^.ReaderCount);

    // 更新最后访问时间
    atomic_store_64(LData^.LastAccessTime, Int64(GetTickCount64()));

    // 内存屏障确保所有更新完成
    atomic_thread_fence(memory_order_seq_cst);

    FLastError := weNone;
  end
  else
    raise ELockError.CreateFmt('Failed to acquire read lock: %s', [SysErrorMessage(LResult)]);
end;

procedure TNamedRWLock.InternalReleaseRead;
var
  LData: PSharedRWLockData;
  LResult: cint;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  // 使用原子操作递减读者计数
  atomic_decrement(LData^.ReaderCount);

  // 更新最后访问时间
  atomic_store_64(LData^.LastAccessTime, Int64(GetTickCount64()));

  // 内存屏障确保计数更新在锁释放之前完成
  atomic_thread_fence(memory_order_seq_cst);

  LResult := pthread_rwlock_unlock(@LData^.RWLock);
  if LResult <> 0 then
    raise ELockError.CreateFmt('Failed to release read lock: %s', [SysErrorMessage(LResult)]);
end;

procedure TNamedRWLock.InternalAcquireWrite;
var
  LData: PSharedRWLockData;
  LResult: cint;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  LResult := pthread_rwlock_wrlock(@LData^.RWLock);
  if LResult = 0 then
  begin
    // 使用原子操作设置写者线程ID
    atomic_store_64(LData^.WriterThread, Int64(GetCurrentThreadId));

    // 更新最后访问时间
    atomic_store_64(LData^.LastAccessTime, Int64(GetTickCount64()));

    // 内存屏障确保所有更新完成
    atomic_thread_fence(memory_order_seq_cst);

    FLastError := weNone;
  end
  else
    raise ELockError.CreateFmt('Failed to acquire write lock: %s', [SysErrorMessage(LResult)]);
end;

procedure TNamedRWLock.InternalReleaseWrite;
var
  LData: PSharedRWLockData;
  LResult: cint;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  // 使用原子操作清除写者线程ID
  atomic_store_64(LData^.WriterThread, 0);

  // 更新最后访问时间
  atomic_store_64(LData^.LastAccessTime, Int64(GetTickCount64()));

  // 内存屏障确保状态更新在锁释放之前完成
  atomic_thread_fence(memory_order_seq_cst);

  LResult := pthread_rwlock_unlock(@LData^.RWLock);
  if LResult <> 0 then
    raise ELockError.CreateFmt('Failed to release write lock: %s', [SysErrorMessage(LResult)]);
end;

function TNamedRWLock.InternalTryAcquireRead(ATimeoutMs: Cardinal): Boolean;
var
  LData: PSharedRWLockData;
  LResult: cint;
  LTimespec: TTimeSpec;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  if ATimeoutMs = 0 then
  begin
    // 非阻塞尝试
    LResult := pthread_rwlock_tryrdlock(@LData^.RWLock);
    Result := (LResult = 0);
    if Result then
      InterlockedIncrement(LData^.ReaderCount)
    else if LResult = ESysEBUSY then
      FLastError := weTimeout
    else
      FLastError := weSystemError;
  end
  else
  begin
    // 带超时的获取
    LTimespec := TimeoutToTimespec(ATimeoutMs);
    LResult := pthread_rwlock_timedrdlock(@LData^.RWLock, @LTimespec);
    Result := (LResult = 0);
    if Result then
    begin
      InterlockedIncrement(LData^.ReaderCount);
      FLastError := weNone;
    end
    else if LResult = ESysETIMEDOUT then
      FLastError := weTimeout
    else
      FLastError := weSystemError;
  end;
end;

function TNamedRWLock.InternalTryAcquireWrite(ATimeoutMs: Cardinal): Boolean;
var
  LData: PSharedRWLockData;
  LResult: cint;
  LTimespec: TTimeSpec;
begin
  LData := GetSharedData;
  if not Assigned(LData) then
    raise ELockError.Create('Shared data not available');

  if ATimeoutMs = 0 then
  begin
    // 非阻塞尝试
    LResult := pthread_rwlock_trywrlock(@LData^.RWLock);
    Result := (LResult = 0);
    if Result then
      LData^.WriterThread := GetCurrentThreadId
    else if LResult = ESysEBUSY then
      FLastError := weTimeout
    else
      FLastError := weSystemError;
  end
  else
  begin
    // 带超时的获取
    LTimespec := TimeoutToTimespec(ATimeoutMs);
    LResult := pthread_rwlock_timedwrlock(@LData^.RWLock, @LTimespec);
    Result := (LResult = 0);
    if Result then
    begin
      LData^.WriterThread := GetCurrentThreadId;
      FLastError := weNone;
    end
    else if LResult = ESysETIMEDOUT then
      FLastError := weTimeout
    else
      FLastError := weSystemError;
  end;
end;

end.
