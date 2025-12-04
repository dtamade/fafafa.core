unit fafafa.core.sync.rwlock.guard;

{**
 * fafafa.core.sync.rwlock.guard - Rust 风格的带数据保护的读写锁容器
 *
 * @desc
 *   使用 IRWLock 保护一个泛型值 T，提供读/写两种访问模式：
 *   - ReadLock/TryReadLock/ReadUnlock
 *   - WriteLock/TryWriteLock/WriteUnlock
 *   并提供 GetValue/SetValue 的便捷方法（内部自动加锁/解锁）。
 *
 * @rust_equivalent
 *   std::sync::RwLock<T>
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.sync.base, fafafa.core.sync.rwlock, fafafa.core.sync.rwlock.base;

type
  generic TRwLockGuard<T> = class
  public type
    PT = ^T;
    TUpdateFunc = function(const AValue: T): T;
    TUpdateProc = reference to procedure(var AValue: T);
    // Note: Nested generic removed as it's not allowed in FPC
  private
    FRWLock: IRWLock;
    FValue: T;
    FReadLocked: Boolean;
    FWriteLocked: Boolean;
  public
    constructor Create(const AValue: T);
    destructor Destroy; override;

    // 读锁 API
    function ReadLockPtr: PT;
    function ReadLock: PT;  // 别名
    function TryReadLock: PT;
    procedure ReadUnlock;

    // 写锁 API
    function WriteLockPtr: PT;
    function WriteLock: PT;  // 别名
    function TryWriteLock: PT;
    procedure WriteUnlock;

    // 便捷 API（内部自动加/解锁）
    function GetValue: T;
    procedure SetValue(const AValue: T);

    // 状态查询
    function IsReadLocked: Boolean; inline;
    function IsWriteLocked: Boolean; inline;

    {**
     * TryReadTimeout - 带超时的读锁获取
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return 成功返回数据指针，超时返回 nil
     *}
    function TryReadTimeout(ATimeoutMs: Cardinal): PT;

    {**
     * TryWriteTimeout - 带超时的写锁获取
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return 成功返回数据指针，超时返回 nil
     *}
    function TryWriteTimeout(ATimeoutMs: Cardinal): PT;

    {**
     * Update - 函数式更新（带写锁）
     *
     * @param AUpdateFunc 更新函数，接收当前值，返回新值
     *
     * @desc
     *   在持有写锁的情况下执行更新函数。
     *}
    procedure Update(AUpdateFunc: TUpdateFunc); overload;

    {**
     * Update - 过程式就地更新（带写锁）
     *
     * @param AUpdateProc 更新过程，直接修改值
     *
     * @desc
     *   在持有写锁的情况下执行更新过程，直接修改内部值。
     *   对于大型 record 或复杂类型，避免不必要的复制。
     *}
    procedure Update(AUpdateProc: TUpdateProc); overload;

    {**
     * GetMut - 无锁获取数据指针
     *
     * @return 数据指针
     *
     * @warning
     *   不获取锁，调用方需自行保证线程安全。
     *   适用于单线程或外部已保证互斥的场景。
     *
     * @rust_equivalent
     *   RwLock::get_mut()
     *}
    function GetMut: PT;

    {**
     * IntoInner - 消费容器获取值
     *
     * @return 存储的值
     *
     * @desc
     *   获取并返回内部值。调用后容器应被销毁。
     *
     * @rust_equivalent
     *   RwLock::into_inner()
     *}
    function IntoInner: T;
  end;

implementation

{ TRwLockGuard<T> }

constructor TRwLockGuard.Create(const AValue: T);
begin
  inherited Create;
  FRWLock := MakeRWLock;
  FValue := AValue;
  FReadLocked := False;
  FWriteLocked := False;
end;

destructor TRwLockGuard.Destroy;
begin
  // 若仍持有锁，释放之（先写后读）
  if FWriteLocked then
  begin
    FWriteLocked := False;
    FRWLock.ReleaseWrite;
  end;
  if FReadLocked then
  begin
    FReadLocked := False;
    FRWLock.ReleaseRead;
  end;
  FRWLock := nil;
  FValue := Default(T);
  inherited Destroy;
end;

function TRwLockGuard.ReadLockPtr: PT;
begin
  // 防御性检查：避免重复加锁导致死锁
  if FReadLocked then
    raise ELockError.Create('TRwLockGuard: Already read-locked. Call ReadUnlock before locking again.');
  if FWriteLocked then
    raise ELockError.Create('TRwLockGuard: Already write-locked. Call WriteUnlock before read-locking.');
  FRWLock.AcquireRead;
  FReadLocked := True;
  Result := @FValue;
end;

function TRwLockGuard.ReadLock: PT;
begin
  Result := ReadLockPtr;
end;

function TRwLockGuard.TryReadLock: PT;
begin
  if FRWLock.TryAcquireRead then
  begin
    FReadLocked := True;
    Result := @FValue;
  end
  else
    Result := nil;
end;

procedure TRwLockGuard.ReadUnlock;
begin
  if FReadLocked then
  begin
    FReadLocked := False;
    FRWLock.ReleaseRead;
  end;
end;

function TRwLockGuard.WriteLockPtr: PT;
begin
  // 防御性检查：避免重复加锁导致死锁
  if FWriteLocked then
    raise ELockError.Create('TRwLockGuard: Already write-locked. Call WriteUnlock before locking again.');
  if FReadLocked then
    raise ELockError.Create('TRwLockGuard: Already read-locked. Call ReadUnlock before write-locking.');
  FRWLock.AcquireWrite;
  FWriteLocked := True;
  Result := @FValue;
end;

function TRwLockGuard.WriteLock: PT;
begin
  Result := WriteLockPtr;
end;

function TRwLockGuard.TryWriteLock: PT;
begin
  if FRWLock.TryAcquireWrite then
  begin
    FWriteLocked := True;
    Result := @FValue;
  end
  else
    Result := nil;
end;

procedure TRwLockGuard.WriteUnlock;
begin
  if FWriteLocked then
  begin
    FWriteLocked := False;
    FRWLock.ReleaseWrite;
  end;
end;

function TRwLockGuard.GetValue: T;
begin
  FRWLock.AcquireRead;
  try
    Result := FValue;
  finally
    FRWLock.ReleaseRead;
  end;
end;

procedure TRwLockGuard.SetValue(const AValue: T);
begin
  FRWLock.AcquireWrite;
  try
    FValue := AValue;
  finally
    FRWLock.ReleaseWrite;
  end;
end;

function TRwLockGuard.IsReadLocked: Boolean;
begin
  Result := FReadLocked;
end;

function TRwLockGuard.IsWriteLocked: Boolean;
begin
  Result := FWriteLocked;
end;

function TRwLockGuard.TryReadTimeout(ATimeoutMs: Cardinal): PT;
begin
  if FReadLocked then
    Exit(@FValue);  // 已持有读锁
    
  if FRWLock.TryAcquireRead(ATimeoutMs) then
  begin
    FReadLocked := True;
    Result := @FValue;
  end
  else
    Result := nil;
end;

function TRwLockGuard.TryWriteTimeout(ATimeoutMs: Cardinal): PT;
begin
  if FWriteLocked then
    Exit(@FValue);  // 已持有写锁
    
  if FRWLock.TryAcquireWrite(ATimeoutMs) then
  begin
    FWriteLocked := True;
    Result := @FValue;
  end
  else
    Result := nil;
end;

procedure TRwLockGuard.Update(AUpdateFunc: TUpdateFunc);
begin
  FRWLock.AcquireWrite;
  try
    FValue := AUpdateFunc(FValue);
  finally
    FRWLock.ReleaseWrite;
  end;
end;

procedure TRwLockGuard.Update(AUpdateProc: TUpdateProc);
begin
  FRWLock.AcquireWrite;
  try
    AUpdateProc(FValue);
  finally
    FRWLock.ReleaseWrite;
  end;
end;

function TRwLockGuard.GetMut: PT;
begin
  // 不获取锁，直接返回指针
  Result := @FValue;
end;

function TRwLockGuard.IntoInner: T;
begin
  FRWLock.AcquireWrite;
  try
    Result := FValue;
    FValue := Default(T);
  finally
    FRWLock.ReleaseWrite;
  end;
end;

end.
