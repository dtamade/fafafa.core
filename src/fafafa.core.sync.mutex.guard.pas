unit fafafa.core.sync.mutex.guard;

{**
 * fafafa.core.sync.mutex.guard - Rust 风格的带数据保护的互斥锁容器
 *
 * @desc
 *   实现 Rust 的 Mutex<T> 语义：
 *   - 数据与锁绑定，确保只能在持有锁时访问数据
 *   - 类型安全的数据保护
 *   - RAII 风格的资源管理
 *
 * @rust_equivalent
 *   std::sync::Mutex<T>
 *
 * @usage
 *   var Guard: specialize TMutexGuard<Integer>;
 *   begin
 *     Guard := specialize TMutexGuard<Integer>.Create(42);
 *     try
 *       // 获取锁并访问数据
 *       var ValuePtr := Guard.LockPtr;
 *       ValuePtr^ := ValuePtr^ + 1;
 *       Guard.Unlock;
 *     finally
 *       Guard.Free;
 *     end;
 *   end;
 *
 * @author fafafaStudio
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.sync.base, fafafa.core.sync.mutex;

type
  { 更新函数类型注册 - 需要在 TMutexGuard 外部声明 }
  generic TUpdateFunc<T> = function(const AValue: T): T;
  generic TUpdateProc<T> = reference to procedure(var AValue: T);

  {**
   * TMutexGuard<T> - 带数据保护的互斥锁容器
   *
   * @desc
   *   存储一个值，并通过互斥锁保护对它的访问。
   *   这是 Rust Mutex<T> 的 Pascal 等价实现。
   *
   * @type_param T
   *   存储的值类型。支持任何类型，包括托管类型（如 string）。
   *
   * @rust_equivalent
   *   std::sync::Mutex<T>
   *}
  generic TMutexGuard<T> = class
  public type
    PT = ^T;
    TUpdateFunc = function(const AValue: T): T;
    TUpdateProc = reference to procedure(var AValue: T);
  private
    FMutex: IMutex;
    FValue: T;
    FLocked: Boolean;
  public
    {**
     * Create - 创建带初始值的互斥锁容器
     *
     * @param AValue 初始值
     *}
    constructor Create(const AValue: T);
    destructor Destroy; override;

    {**
     * LockPtr - 获取锁并返回数据指针
     *
     * @return 数据指针，必须在使用完后调用 Unlock
     *
     * @thread_safety
     *   线程安全，会阻塞直到获取到锁
     *}
    function LockPtr: PT;

    {**
     * Lock - 获取锁并返回数据指针
     *
     * @return 数据指针，必须在使用完后调用 Unlock
     *
     * @rust_equivalent
     *   Mutex::lock() -> MutexGuard
     *}
    function Lock: PT;

    {**
     * TryLock - 非阻塞尝试获取锁
     *
     * @return 成功返回数据指针，失败返回 nil
     *
     * @rust_equivalent
     *   Mutex::try_lock() -> Option<MutexGuard>
     *}
    function TryLock: PT;

    {**
     * Unlock - 释放锁
     *
     * @desc
     *   释放之前通过 Lock 或 TryLock 获取的锁
     *}
    procedure Unlock;

    {**
     * GetValue - 获取值的副本
     *
     * @return 值的副本
     *
     * @desc
     *   内部会自动加锁/解锁
     *}
    function GetValue: T;

    {**
     * SetValue - 设置新值
     *
     * @param AValue 新值
     *
     * @desc
     *   内部会自动加锁/解锁
     *}
    procedure SetValue(const AValue: T);

    {**
     * IsLocked - 检查当前线程是否持有锁
     *
     * @return True 如果当前持有锁
     *}
    function IsLocked: Boolean; inline;

    {**
     * TryLockTimeout - 带超时的 TryLock
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return 成功返回数据指针，超时返回 nil
     *
     * @rust_equivalent
     *   Mutex::try_lock_for()
     *
     * @note
     *   此方法需要底层 IMutex 实现 ITryLock 接口。
     *   如果底层不支持 ITryLock，将抛出 EInvalidArgument 异常，
     *   以避免将“超时”和“实现不支持”混淆在一起。
     *}
    function TryLockTimeout(ATimeoutMs: Cardinal): PT;

    {**
     * Update - 函数式更新接口
     *
     * @param AUpdateFunc 更新函数，接收当前值，返回新值
     *
     * @desc
     *   在持有锁的情况下执行更新函数，将结果写回存储。
     *   类似 Rust 的 Mutex::lock().map()
     *}
    procedure Update(AUpdateFunc: TUpdateFunc); overload;

    {**
     * Update - 过程式就地更新接口
     *
     * @param AUpdateProc 更新过程，直接修改值
     *
     * @desc
     *   在持有锁的情况下执行更新过程，直接修改内部值。
     *   对于大型 record 或复杂类型，避免不必要的复制。
     *   类似 Rust 的 FnOnce(&mut T) 语义。
     *}
    procedure Update(AUpdateProc: TUpdateProc); overload;

    {**
     * IntoInner - 消费容器获取值
     *
     * @return 存储的值
     *
     * @desc
     *   获取并返回内部值，同时释放锁。
     *   调用后容器应被销毁。
     *
     * @rust_equivalent
     *   Mutex::into_inner()
     *}
    function IntoInner: T;

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
     *   Mutex::get_mut()
     *}
    function GetMut: PT;
  end;

implementation

{ TMutexGuard<T> }

constructor TMutexGuard.Create(const AValue: T);
begin
  inherited Create;
  FMutex := MakeMutex;
  FValue := AValue;
  FLocked := False;
end;

destructor TMutexGuard.Destroy;
begin
  // 如果还持有锁，释放它
  if FLocked then
    FMutex.Release;
  FMutex := nil;
  FValue := Default(T);
  inherited Destroy;
end;

function TMutexGuard.LockPtr: PT;
begin
  // 防御性检查：避免同一对象重复加锁导致死锁
  if FLocked then
    raise ELockError.Create('TMutexGuard: Already locked. Call Unlock before locking again.');
  FMutex.Acquire;
  FLocked := True;
  Result := @FValue;
end;

function TMutexGuard.Lock: PT;
begin
  Result := LockPtr;
end;

function TMutexGuard.TryLock: PT;
begin
  if FMutex.TryAcquire then
  begin
    FLocked := True;
    Result := @FValue;
  end
  else
    Result := nil;
end;

procedure TMutexGuard.Unlock;
begin
  if FLocked then
  begin
    FLocked := False;
    FMutex.Release;
  end;
end;

function TMutexGuard.GetValue: T;
begin
  FMutex.Acquire;
  try
    Result := FValue;
  finally
    FMutex.Release;
  end;
end;

procedure TMutexGuard.SetValue(const AValue: T);
begin
  FMutex.Acquire;
  try
    FValue := AValue;
  finally
    FMutex.Release;
  end;
end;

function TMutexGuard.IsLocked: Boolean;
begin
  Result := FLocked;
end;

function TMutexGuard.TryLockTimeout(ATimeoutMs: Cardinal): PT;
var
  Acquired: Boolean;
  TryLockIntf: ITryLock;
begin
  if FLocked then
    Exit(@FValue);  // 已持有锁，直接返回

  // 检查底层是否支持 ITryLock/超时语义
  if not Supports(FMutex, ITryLock, TryLockIntf) then
    raise EInvalidArgument.Create('TMutexGuard.TryLockTimeout: underlying mutex does not support ITryLock/timeout');

  // 尝试在超时时间内获取锁
  Acquired := TryLockIntf.TryAcquire(ATimeoutMs);

  if Acquired then
  begin
    FLocked := True;
    Result := @FValue;
  end
  else
    Result := nil;
end;

procedure TMutexGuard.Update(AUpdateFunc: TUpdateFunc);
begin
  FMutex.Acquire;
  try
    FValue := AUpdateFunc(FValue);
  finally
    FMutex.Release;
  end;
end;

procedure TMutexGuard.Update(AUpdateProc: TUpdateProc);
begin
  FMutex.Acquire;
  try
    AUpdateProc(FValue);
  finally
    FMutex.Release;
  end;
end;

function TMutexGuard.IntoInner: T;
begin
  FMutex.Acquire;
  try
    Result := FValue;
    FValue := Default(T);
  finally
    FMutex.Release;
  end;
end;

function TMutexGuard.GetMut: PT;
begin
  // 不获取锁，直接返回指针
  Result := @FValue;
end;

end.
