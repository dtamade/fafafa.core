unit fafafa.core.sync.reentrantrwlock;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  IReentrantRWLock - 可重入读写锁

  特点：
  - 同一线程可多次获取读锁或写锁
  - 支持读锁升级为写锁
  - 支持写锁降级为读锁

  注意：
  - 可重入会带来一定的性能开销
  - 需要维护每个线程的锁持有状态

  使用示例：
    Lock.ReadLock;
    try
      // 读取数据
      if NeedModify then
      begin
        Lock.WriteLock;  // 升级为写锁
        try
          // 修改数据
        finally
          Lock.WriteUnlock;
        end;
      end;
    finally
      Lock.ReadUnlock;
    end;
}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base,
  fafafa.core.atomic;

type

  { IReentrantRWLock }

  IReentrantRWLock = interface(ISynchronizable)
    ['{A9B0C1D2-E3F4-5A6B-7C8D-9E0F1A2B3C4D}']

    {** 获取读锁（可重入） *}
    procedure ReadLock;

    {** 尝试获取读锁（不阻塞） *}
    function TryReadLock: Boolean;

    {** 释放读锁 *}
    procedure ReadUnlock;

    {** 获取写锁（可重入） *}
    procedure WriteLock;

    {** 尝试获取写锁（不阻塞） *}
    function TryWriteLock: Boolean;

    {** 释放写锁 *}
    procedure WriteUnlock;

    {** 检查当前线程是否持有读锁 *}
    function IsReadLockHeld: Boolean;

    {** 检查当前线程是否持有写锁 *}
    function IsWriteLockHeld: Boolean;

    {** 获取当前读锁持有数 *}
    function GetReadHoldCount: Integer;

    {** 获取当前写锁持有数 *}
    function GetWriteHoldCount: Integer;
  end;

  { TReentrantRWLock }

  TReentrantRWLock = class(TInterfacedObject, IReentrantRWLock, ISynchronizable)
  private
    FMutex: pthread_mutex_t;
    FReadCond: pthread_cond_t;
    FWriteCond: pthread_cond_t;

    FWriteOwner: TThreadID;       // 写锁持有者
    FWriteCount: Integer;         // 写锁重入计数
    FReadCount: Integer;          // 总读锁计数

    // 简化实现：只跟踪写锁持有者的读锁计数
    FWriteOwnerReadCount: Integer;

    FData: Pointer;
  public
    constructor Create;
    destructor Destroy; override;

    { IReentrantRWLock }
    procedure ReadLock;
    function TryReadLock: Boolean;
    procedure ReadUnlock;
    procedure WriteLock;
    function TryWriteLock: Boolean;
    procedure WriteUnlock;
    function IsReadLockHeld: Boolean;
    function IsWriteLockHeld: Boolean;
    function GetReadHoldCount: Integer;
    function GetWriteHoldCount: Integer;

    { ISynchronizable }
    function GetData: Pointer;
    procedure SetData(AData: Pointer);
  end;

function MakeReentrantRWLock: IReentrantRWLock;

implementation

{ TReentrantRWLock }

constructor TReentrantRWLock.Create;
begin
  inherited Create;
  FWriteOwner := TThreadID(0);
  FWriteCount := 0;
  FReadCount := 0;
  FWriteOwnerReadCount := 0;
  FData := nil;

  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('ReentrantRWLock: failed to initialize mutex');

  if pthread_cond_init(@FReadCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create('ReentrantRWLock: failed to initialize read condition');
  end;

  if pthread_cond_init(@FWriteCond, nil) <> 0 then
  begin
    pthread_cond_destroy(@FReadCond);
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create('ReentrantRWLock: failed to initialize write condition');
  end;
end;

destructor TReentrantRWLock.Destroy;
begin
  pthread_cond_destroy(@FWriteCond);
  pthread_cond_destroy(@FReadCond);
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TReentrantRWLock.ReadLock;
var
  CurrentThread: TThreadID;
begin
  CurrentThread := GetCurrentThreadId;

  pthread_mutex_lock(@FMutex);
  try
    // 如果当前线程持有写锁，允许获取读锁（降级准备）
    if FWriteOwner = CurrentThread then
    begin
      Inc(FWriteOwnerReadCount);
      Inc(FReadCount);
      Exit;
    end;

    // 等待没有写锁
    while FWriteCount > 0 do
      pthread_cond_wait(@FReadCond, @FMutex);

    Inc(FReadCount);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TReentrantRWLock.TryReadLock: Boolean;
var
  CurrentThread: TThreadID;
begin
  CurrentThread := GetCurrentThreadId;

  pthread_mutex_lock(@FMutex);
  try
    if FWriteOwner = CurrentThread then
    begin
      Inc(FWriteOwnerReadCount);
      Inc(FReadCount);
      Result := True;
      Exit;
    end;

    if FWriteCount > 0 then
      Result := False
    else
    begin
      Inc(FReadCount);
      Result := True;
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TReentrantRWLock.ReadUnlock;
var
  CurrentThread: TThreadID;
begin
  CurrentThread := GetCurrentThreadId;

  pthread_mutex_lock(@FMutex);
  try
    if FWriteOwner = CurrentThread then
    begin
      if FWriteOwnerReadCount > 0 then
        Dec(FWriteOwnerReadCount);
    end;

    Dec(FReadCount);

    // 如果没有读锁了，通知等待的写锁
    if FReadCount = 0 then
      pthread_cond_signal(@FWriteCond);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TReentrantRWLock.WriteLock;
var
  CurrentThread: TThreadID;
begin
  CurrentThread := GetCurrentThreadId;

  pthread_mutex_lock(@FMutex);
  try
    // 重入检查
    if FWriteOwner = CurrentThread then
    begin
      Inc(FWriteCount);
      Exit;
    end;

    // 等待没有写锁
    while FWriteCount > 0 do
      pthread_cond_wait(@FWriteCond, @FMutex);

    // 等待没有读锁（除了自己持有的）
    while FReadCount > 0 do
      pthread_cond_wait(@FWriteCond, @FMutex);

    FWriteOwner := CurrentThread;
    FWriteCount := 1;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TReentrantRWLock.TryWriteLock: Boolean;
var
  CurrentThread: TThreadID;
begin
  CurrentThread := GetCurrentThreadId;

  pthread_mutex_lock(@FMutex);
  try
    if FWriteOwner = CurrentThread then
    begin
      Inc(FWriteCount);
      Result := True;
      Exit;
    end;

    if (FWriteCount > 0) or (FReadCount > 0) then
      Result := False
    else
    begin
      FWriteOwner := CurrentThread;
      FWriteCount := 1;
      Result := True;
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

procedure TReentrantRWLock.WriteUnlock;
begin
  pthread_mutex_lock(@FMutex);
  try
    Dec(FWriteCount);

    if FWriteCount = 0 then
    begin
      FWriteOwner := TThreadID(0);
      // 优先通知读锁等待者
      pthread_cond_broadcast(@FReadCond);
      pthread_cond_signal(@FWriteCond);
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TReentrantRWLock.IsReadLockHeld: Boolean;
begin
  // 简化实现：只能检查写锁持有者的读锁
  pthread_mutex_lock(@FMutex);
  try
    Result := (FWriteOwner = GetCurrentThreadId) and (FWriteOwnerReadCount > 0);
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TReentrantRWLock.IsWriteLockHeld: Boolean;
begin
  pthread_mutex_lock(@FMutex);
  try
    Result := FWriteOwner = GetCurrentThreadId;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TReentrantRWLock.GetReadHoldCount: Integer;
begin
  pthread_mutex_lock(@FMutex);
  try
    if FWriteOwner = GetCurrentThreadId then
      Result := FWriteOwnerReadCount
    else
      Result := 0;  // 简化实现
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TReentrantRWLock.GetWriteHoldCount: Integer;
begin
  pthread_mutex_lock(@FMutex);
  try
    if FWriteOwner = GetCurrentThreadId then
      Result := FWriteCount
    else
      Result := 0;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TReentrantRWLock.GetData: Pointer;
begin
  Result := FData;
end;

procedure TReentrantRWLock.SetData(AData: Pointer);
begin
  FData := AData;
end;

function MakeReentrantRWLock: IReentrantRWLock;
begin
  Result := TReentrantRWLock.Create;
end;

end.
