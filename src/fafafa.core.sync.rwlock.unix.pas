unit fafafa.core.sync.rwlock.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.rwlock.base;

const
  ETIMEDOUT = 110;  // Connection timed out
  EBUSY = 16;       // Device or resource busy

type
  // 前向声明
  TRWLock = class;

  // ===== 读锁守卫实现 =====
  TRWLockReadGuard = class(TInterfacedObject, IRWLockReadGuard)
  private
    FLock: TRWLock;
    FReleased: Boolean;
  public
    constructor Create(ALock: TRWLock); // ALock = nil 表示不自动获取锁
    destructor Destroy; override;
    procedure Release;
  end;

  // ===== 写锁守卫实现 =====
  TRWLockWriteGuard = class(TInterfacedObject, IRWLockWriteGuard)
  private
    FLock: TRWLock;
    FReleased: Boolean;
  public
    constructor Create(ALock: TRWLock); // ALock = nil 表示不自动获取锁
    destructor Destroy; override;
    procedure Release;
  end;

  // ===== RWLock 主实现 =====
  TRWLock = class(TInterfacedObject, IRWLock)
  private
    FRWLock: pthread_rwlock_t;
    FReaderCount: Integer;  // 使用原子操作
    FWriterThread: TThreadID;
  public
    constructor Create;
    destructor Destroy; override;

    // ===== 现代化 API =====
    function Read: IRWLockReadGuard;
    function Write: IRWLockWriteGuard;
    function TryRead(ATimeoutMs: Cardinal = 0): IRWLockReadGuard;
    function TryWrite(ATimeoutMs: Cardinal = 0): IRWLockWriteGuard;

    // ===== 传统 API =====
    procedure AcquireRead;
    procedure ReleaseRead;
    procedure AcquireWrite;
    procedure ReleaseWrite;
    function TryAcquireRead: Boolean; overload;
    function TryAcquireRead(ATimeoutMs: Cardinal): TLockResult; overload;
    function TryAcquireWrite: Boolean; overload;
    function TryAcquireWrite(ATimeoutMs: Cardinal): TLockResult; overload;

    // ===== 状态查询 =====
    function GetReaderCount: Integer;
    function IsWriteLocked: Boolean;
    function IsReadLocked: Boolean;
    function GetWriterThread: TThreadID;
    function GetMaxReaders: Integer;
  end;

implementation

{ TRWLockReadGuard }

constructor TRWLockReadGuard.Create(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  if Assigned(FLock) then
    FLock.AcquireRead;
end;

destructor TRWLockReadGuard.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TRWLockReadGuard.Release;
begin
  if not FReleased and Assigned(FLock) then
  begin
    FLock.ReleaseRead;
    FReleased := True;
  end;
end;

{ TRWLockWriteGuard }

constructor TRWLockWriteGuard.Create(ALock: TRWLock);
begin
  inherited Create;
  FLock := ALock;
  FReleased := False;
  if Assigned(FLock) then
    FLock.AcquireWrite;
end;

destructor TRWLockWriteGuard.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TRWLockWriteGuard.Release;
begin
  if not FReleased and Assigned(FLock) then
  begin
    FLock.ReleaseWrite;
    FReleased := True;
  end;
end;

{ TRWLock }

constructor TRWLock.Create;
var
  Attr: pthread_rwlockattr_t;
begin
  inherited Create;

  // 初始化读写锁属性
  if pthread_rwlockattr_init(@Attr) <> 0 then
    raise ELockError.Create('Failed to initialize rwlock attributes');

  // 设置为进程内共享
  if pthread_rwlockattr_setpshared(@Attr, PTHREAD_PROCESS_PRIVATE) <> 0 then
  begin
    pthread_rwlockattr_destroy(@Attr);
    raise ELockError.Create('Failed to set rwlock pshared attribute');
  end;

  // 初始化读写锁
  if pthread_rwlock_init(@FRWLock, @Attr) <> 0 then
  begin
    pthread_rwlockattr_destroy(@Attr);
    raise ELockError.Create('Failed to initialize pthread rwlock');
  end;

  pthread_rwlockattr_destroy(@Attr);

  FReaderCount := 0;
  FWriterThread := 0;
end;

destructor TRWLock.Destroy;
begin
  pthread_rwlock_destroy(@FRWLock);
  inherited Destroy;
end;

// ===== 现代化 API =====

function TRWLock.Read: IRWLockReadGuard;
begin
  Result := TRWLockReadGuard.Create(Self);
end;

function TRWLock.Write: IRWLockWriteGuard;
begin
  Result := TRWLockWriteGuard.Create(Self);
end;

function TRWLock.TryRead(ATimeoutMs: Cardinal): IRWLockReadGuard;
var
  Guard: TRWLockReadGuard;
begin
  Result := nil;
  if TryAcquireRead(ATimeoutMs) = lrSuccess then
  begin
    // 手动创建守卫，但不让它再次获取锁
    Guard := TRWLockReadGuard.Create(nil);
    Guard.FLock := Self;
    Guard.FReleased := False;
    Result := Guard;
  end;
end;

function TRWLock.TryWrite(ATimeoutMs: Cardinal): IRWLockWriteGuard;
var
  Guard: TRWLockWriteGuard;
begin
  Result := nil;
  if TryAcquireWrite(ATimeoutMs) = lrSuccess then
  begin
    // 手动创建守卫，但不让它再次获取锁
    Guard := TRWLockWriteGuard.Create(nil);
    Guard.FLock := Self;
    Guard.FReleased := False;
    Result := Guard;
  end;
end;

// ===== 传统 API =====

procedure TRWLock.AcquireRead;
begin
  if pthread_rwlock_rdlock(@FRWLock) <> 0 then
    raise ELockError.Create('Failed to acquire read lock');
  InterlockedIncrement(FReaderCount);  // 原子操作，性能更好
end;

procedure TRWLock.ReleaseRead;
begin
  InterlockedDecrement(FReaderCount);  // 先更新计数
  if pthread_rwlock_unlock(@FRWLock) <> 0 then
    raise ELockError.Create('Failed to release read lock');
end;

procedure TRWLock.AcquireWrite;
begin
  if pthread_rwlock_wrlock(@FRWLock) <> 0 then
    raise ELockError.Create('Failed to acquire write lock');
  FWriterThread := GetCurrentThreadId;
end;

procedure TRWLock.ReleaseWrite;
begin
  FWriterThread := 0;
  if pthread_rwlock_unlock(@FRWLock) <> 0 then
    raise ELockError.Create('Failed to release write lock');
end;

function TRWLock.TryAcquireRead: Boolean;
begin
  Result := pthread_rwlock_tryrdlock(@FRWLock) = 0;
  if Result then
    InterlockedIncrement(FReaderCount);
end;

function TRWLock.TryAcquireRead(ATimeoutMs: Cardinal): TLockResult;
var
  AbsTime: timespec;
  CurrentTime: timeval;
  NanoSecs: Int64;
  LockResult: Integer;
begin
  if ATimeoutMs = 0 then
  begin
    if TryAcquireRead() then
      Result := lrSuccess
    else
      Result := lrWouldBlock;
    Exit;
  end;

  // 计算绝对超时时间
  fpgettimeofday(@CurrentTime, nil);
  NanoSecs := (CurrentTime.tv_sec * 1000000000) + (CurrentTime.tv_usec * 1000) + (ATimeoutMs * 1000000);
  AbsTime.tv_sec := NanoSecs div 1000000000;
  AbsTime.tv_nsec := NanoSecs mod 1000000000;

  LockResult := pthread_rwlock_timedrdlock(@FRWLock, @AbsTime);
  case LockResult of
    0: begin
      InterlockedIncrement(FReaderCount);
      Result := lrSuccess;
    end;
    ETIMEDOUT: Result := lrTimeout;
    EBUSY: Result := lrWouldBlock;
    else Result := lrError;
  end;
end;

function TRWLock.TryAcquireWrite: Boolean;
begin
  Result := pthread_rwlock_trywrlock(@FRWLock) = 0;
  if Result then
    FWriterThread := GetCurrentThreadId;
end;

function TRWLock.TryAcquireWrite(ATimeoutMs: Cardinal): TLockResult;
var
  AbsTime: timespec;
  CurrentTime: timeval;
  NanoSecs: Int64;
  LockResult: Integer;
begin
  if ATimeoutMs = 0 then
  begin
    if TryAcquireWrite() then
      Result := lrSuccess
    else
      Result := lrWouldBlock;
    Exit;
  end;

  // 计算绝对超时时间
  fpgettimeofday(@CurrentTime, nil);
  NanoSecs := (CurrentTime.tv_sec * 1000000000) + (CurrentTime.tv_usec * 1000) + (ATimeoutMs * 1000000);
  AbsTime.tv_sec := NanoSecs div 1000000000;
  AbsTime.tv_nsec := NanoSecs mod 1000000000;

  LockResult := pthread_rwlock_timedwrlock(@FRWLock, @AbsTime);
  case LockResult of
    0: begin
      FWriterThread := GetCurrentThreadId;
      Result := lrSuccess;
    end;
    ETIMEDOUT: Result := lrTimeout;
    EBUSY: Result := lrWouldBlock;
    else Result := lrError;
  end;
end;

// ===== 状态查询 =====

function TRWLock.GetReaderCount: Integer;
begin
  Result := FReaderCount;  // 原子读取，无需额外同步
end;

function TRWLock.IsWriteLocked: Boolean;
begin
  Result := FWriterThread <> 0;
end;

function TRWLock.IsReadLocked: Boolean;
begin
  Result := FReaderCount > 0;
end;

function TRWLock.GetWriterThread: TThreadID;
begin
  Result := FWriterThread;
end;

function TRWLock.GetMaxReaders: Integer;
begin
  // pthread_rwlock_t 理论上支持的最大读者数量
  Result := High(Integer);
end;

end.
