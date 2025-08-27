unit fafafa.core.sync.rwlock.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.rwlock.base;

type
  // 前向声明
  TRWLock = class;

  // ===== 读锁守卫实现 =====
  TRWLockReadGuard = class(TInterfacedObject, IRWLockReadGuard)
  private
    FLock: TRWLock;
    FReleased: Boolean;
  public
    constructor Create(ALock: TRWLock);
    destructor Destroy; override;
    procedure Release;
  end;

  // ===== 写锁守卫实现 =====
  TRWLockWriteGuard = class(TInterfacedObject, IRWLockWriteGuard)
  private
    FLock: TRWLock;
    FReleased: Boolean;
  public
    constructor Create(ALock: TRWLock);
    destructor Destroy; override;
    procedure Release;
  end;

  // ===== RWLock 主实现 =====
  TRWLock = class(TInterfacedObject, IRWLock)
  private
    FSRWLock: SRWLOCK;
    FReaderCount: Integer;  // 使用原子操作，无需额外锁
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
begin
  inherited Create;
  InitializeSRWLock(@FSRWLock);
  FReaderCount := 0;
  FWriterThread := 0;
end;

destructor TRWLock.Destroy;
begin
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
  AcquireSRWLockShared(@FSRWLock);
  InterlockedIncrement(FReaderCount);  // 原子操作，性能更好
end;

procedure TRWLock.ReleaseRead;
begin
  InterlockedDecrement(FReaderCount);  // 先更新计数
  ReleaseSRWLockShared(@FSRWLock);     // 再释放锁，修复顺序问题
end;

procedure TRWLock.AcquireWrite;
begin
  AcquireSRWLockExclusive(@FSRWLock);
  FWriterThread := GetCurrentThreadId;
end;

procedure TRWLock.ReleaseWrite;
begin
  FWriterThread := 0;
  ReleaseSRWLockExclusive(@FSRWLock);
end;

function TRWLock.TryAcquireRead: Boolean;
begin
  Result := TryAcquireSRWLockShared(@FSRWLock);
  if Result then
    InterlockedIncrement(FReaderCount);
end;

function TRWLock.TryAcquireRead(ATimeoutMs: Cardinal): TLockResult;
var
  StartTime: DWORD;
  ElapsedMs: DWORD;
begin
  if ATimeoutMs = 0 then
  begin
    if TryAcquireRead then
      Result := lrSuccess
    else
      Result := lrWouldBlock;
    Exit;
  end;

  StartTime := GetTickCount;
  repeat
    if TryAcquireSRWLockShared(@FSRWLock) then
    begin
      InterlockedIncrement(FReaderCount);
      Result := lrSuccess;
      Exit;
    end;

    // 检查超时
    ElapsedMs := GetTickCount - StartTime;
    if ElapsedMs >= ATimeoutMs then
    begin
      Result := lrTimeout;
      Exit;
    end;

    // 短暂休眠避免忙等待
    Sleep(1);
  until False;
end;

function TRWLock.TryAcquireWrite: Boolean;
begin
  Result := TryAcquireSRWLockExclusive(@FSRWLock);
  if Result then
    FWriterThread := GetCurrentThreadId;
end;

function TRWLock.TryAcquireWrite(ATimeoutMs: Cardinal): TLockResult;
var
  StartTime: DWORD;
  ElapsedMs: DWORD;
begin
  if ATimeoutMs = 0 then
  begin
    if TryAcquireWrite then
      Result := lrSuccess
    else
      Result := lrWouldBlock;
    Exit;
  end;

  StartTime := GetTickCount;
  repeat
    if TryAcquireSRWLockExclusive(@FSRWLock) then
    begin
      FWriterThread := GetCurrentThreadId;
      Result := lrSuccess;
      Exit;
    end;

    // 检查超时
    ElapsedMs := GetTickCount - StartTime;
    if ElapsedMs >= ATimeoutMs then
    begin
      Result := lrTimeout;
      Exit;
    end;

    // 短暂休眠避免忙等待
    Sleep(1);
  until False;
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
  // Windows SRWLOCK 理论上支持的最大读者数量
  Result := High(Integer);
end;

end.
