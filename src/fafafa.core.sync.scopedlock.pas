unit fafafa.core.sync.scopedlock;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{**
 * fafafa.core.sync.scopedlock - 作用域锁（多锁获取）实现
 *
 * @description
 *   ScopedLock 提供安全的多锁获取机制，通过固定的获取顺序
 *   避免死锁。支持同时获取多个锁，按地址排序获取顺序。
 *
 * @deadlock_prevention
 *   - 所有锁按内存地址排序后依次获取
 *   - 确保全局一致的获取顺序
 *   - 异常时自动释放已获取的锁
 *
 * @rust_equivalent
 *   类似 std::lock 的功能，但采用 Pascal 接口风格
 *
 * @usage
 *   var
 *     Lock1, Lock2: IMutex;
 *     Guard: IMultiLockGuard;
 *   begin
 *     Lock1 := MakeMutex;
 *     Lock2 := MakeMutex;
 *
 *     // 安全获取多个锁
 *     Guard := ScopedLock([Lock1, Lock2]);
 *     try
 *       // 临界区：两个锁都被持有
 *     finally
 *       Guard.Release;
 *     end;
 *   end;
 *}

interface

uses
  SysUtils,
  fafafa.core.sync.base;

type
  {**
   * IMultiLockGuard - 多锁守卫接口
   *
   * @description
   *   管理多个锁的 RAII 守卫。所有锁在创建时获取，
   *   在释放时按相反顺序释放。
   *}
  IMultiLockGuard = interface(IGuard)
    ['{D1E2F3A4-B5C6-7D8E-9F0A-1B2C3D4E5F6A}']

    {**
     * GetLockCount - 获取持有的锁数量
     *}
    function GetLockCount: Integer;

    {**
     * GetLock - 获取指定索引的锁
     *}
    function GetLock(AIndex: Integer): ILock;

    property LockCount: Integer read GetLockCount;
    property Locks[AIndex: Integer]: ILock read GetLock; default;
  end;

{**
 * ScopedLock - 安全获取多个锁
 *
 * @param ALocks 要获取的锁数组
 * @returns 多锁守卫，超出作用域自动释放所有锁
 *
 * @description
 *   按固定顺序（地址排序）获取所有锁，防止死锁。
 *   如果获取过程中发生异常，已获取的锁会被释放。
 *
 * @throws
 *   ELockError 如果锁数量为 0
 *}
function ScopedLock(const ALocks: array of ILock): IMultiLockGuard;

{**
 * ScopedLock2 - 安全获取两个锁
 *}
function ScopedLock2(ALock1, ALock2: ILock): IMultiLockGuard;

{**
 * ScopedLock3 - 安全获取三个锁
 *}
function ScopedLock3(ALock1, ALock2, ALock3: ILock): IMultiLockGuard;

{**
 * ScopedLock4 - 安全获取四个锁
 *}
function ScopedLock4(ALock1, ALock2, ALock3, ALock4: ILock): IMultiLockGuard;

{**
 * TryScopedLock - 尝试安全获取多个锁（非阻塞）
 *
 * @param ALocks 要获取的锁数组
 * @param AGuard 输出参数，成功时返回守卫
 * @returns True 如果所有锁都成功获取，False 否则
 *
 * @description
 *   尝试按固定顺序获取所有锁，任何一个失败则释放已获取的锁。
 *}
function TryScopedLock(const ALocks: array of ILock; out AGuard: IMultiLockGuard): Boolean;

{**
 * TryScopedLockFor - 带超时尝试获取多个锁
 *
 * @param ALocks 要获取的锁数组
 * @param ATimeoutMs 总超时时间（毫秒）
 * @param AGuard 输出参数，成功时返回守卫
 * @returns True 如果所有锁都成功获取，False 超时
 *}
function TryScopedLockFor(const ALocks: array of ILock; ATimeoutMs: Cardinal; out AGuard: IMultiLockGuard): Boolean;

implementation

type
  {**
   * TMultiLockGuard - 多锁守卫实现类（获取锁）
   *}
  TMultiLockGuard = class(TInterfacedObject, IMultiLockGuard, IGuard)
  private
    FLocks: array of ILock;
    FReleased: Boolean;

    class procedure SortLocksByAddress(var ALocks: array of ILock); static;
  public
    constructor Create(const ALocks: array of ILock);
    destructor Destroy; override;

    // IMultiLockGuard
    function GetLockCount: Integer;
    function GetLock(AIndex: Integer): ILock;

    // IGuard
    function IsLocked: Boolean;
    procedure Release;
    procedure Unlock;
  end;

  {**
   * TMultiLockGuardNoAcquire - 不获取锁的守卫（用于 TryScopedLock）
   *}
  TMultiLockGuardNoAcquire = class(TInterfacedObject, IMultiLockGuard, IGuard)
  private
    FLocks: array of ILock;
    FReleased: Boolean;
  public
    constructor Create(const ALocks: array of ILock);
    destructor Destroy; override;

    function GetLockCount: Integer;
    function GetLock(AIndex: Integer): ILock;
    function IsLocked: Boolean;
    procedure Release;
    procedure Unlock;
  end;

{ TMultiLockGuard }

class procedure TMultiLockGuard.SortLocksByAddress(var ALocks: array of ILock);
var
  i, j: Integer;
  Temp: ILock;
begin
  // 简单冒泡排序（锁数量很少，性能不是问题）
  for i := 0 to High(ALocks) - 1 do
    for j := i + 1 to High(ALocks) do
      {$PUSH}{$WARN 4055 OFF}  // 指针转换是安全的，用于地址比较
      if PtrUInt(Pointer(ALocks[i])) > PtrUInt(Pointer(ALocks[j])) then
      {$POP}
      begin
        Temp := ALocks[i];
        ALocks[i] := ALocks[j];
        ALocks[j] := Temp;
      end;
end;

constructor TMultiLockGuard.Create(const ALocks: array of ILock);
var
  i, j: Integer;
begin
  inherited Create;
  FReleased := False;

  if Length(ALocks) = 0 then
    raise ELockError.Create('ScopedLock requires at least one lock');

  // 复制并排序锁
  SetLength(FLocks, Length(ALocks));
  for i := 0 to High(ALocks) do
    FLocks[i] := ALocks[i];

  SortLocksByAddress(FLocks);

  // 按排序后的顺序获取锁
  for i := 0 to High(FLocks) do
  begin
    try
      FLocks[i].Acquire;
    except
      // 获取失败，释放已获取的锁（从 i-1 到 0）
      for j := i - 1 downto 0 do
        FLocks[j].Release;
      SetLength(FLocks, 0);
      raise;
    end;
  end;
end;

destructor TMultiLockGuard.Destroy;
begin
  if not FReleased then
    Release;
  inherited Destroy;
end;

function TMultiLockGuard.GetLockCount: Integer;
begin
  Result := Length(FLocks);
end;

function TMultiLockGuard.GetLock(AIndex: Integer): ILock;
begin
  if (AIndex < 0) or (AIndex >= Length(FLocks)) then
    raise ELockError.CreateFmt('Lock index %d out of range [0..%d]', [AIndex, Length(FLocks) - 1]);
  Result := FLocks[AIndex];
end;

function TMultiLockGuard.IsLocked: Boolean;
begin
  Result := not FReleased and (Length(FLocks) > 0);
end;

procedure TMultiLockGuard.Release;
var
  i: Integer;
begin
  if not FReleased then
  begin
    // 按相反顺序释放锁
    for i := High(FLocks) downto 0 do
      FLocks[i].Release;
    FReleased := True;
  end;
end;

procedure TMultiLockGuard.Unlock;
begin
  Release;
end;

{ TMultiLockGuardNoAcquire }

constructor TMultiLockGuardNoAcquire.Create(const ALocks: array of ILock);
var
  i: Integer;
begin
  inherited Create;
  FReleased := False;
  SetLength(FLocks, Length(ALocks));
  for i := 0 to High(ALocks) do
    FLocks[i] := ALocks[i];
end;

destructor TMultiLockGuardNoAcquire.Destroy;
begin
  if not FReleased then
    Release;
  inherited Destroy;
end;

function TMultiLockGuardNoAcquire.GetLockCount: Integer;
begin
  Result := Length(FLocks);
end;

function TMultiLockGuardNoAcquire.GetLock(AIndex: Integer): ILock;
begin
  if (AIndex < 0) or (AIndex >= Length(FLocks)) then
    raise ELockError.CreateFmt('Lock index %d out of range [0..%d]', [AIndex, Length(FLocks) - 1]);
  Result := FLocks[AIndex];
end;

function TMultiLockGuardNoAcquire.IsLocked: Boolean;
begin
  Result := not FReleased and (Length(FLocks) > 0);
end;

procedure TMultiLockGuardNoAcquire.Release;
var
  i: Integer;
begin
  if not FReleased then
  begin
    for i := High(FLocks) downto 0 do
      FLocks[i].Release;
    FReleased := True;
  end;
end;

procedure TMultiLockGuardNoAcquire.Unlock;
begin
  Release;
end;

{ Factory Functions }

function ScopedLock(const ALocks: array of ILock): IMultiLockGuard;
begin
  Result := TMultiLockGuard.Create(ALocks);
end;

function ScopedLock2(ALock1, ALock2: ILock): IMultiLockGuard;
begin
  Result := TMultiLockGuard.Create([ALock1, ALock2]);
end;

function ScopedLock3(ALock1, ALock2, ALock3: ILock): IMultiLockGuard;
begin
  Result := TMultiLockGuard.Create([ALock1, ALock2, ALock3]);
end;

function ScopedLock4(ALock1, ALock2, ALock3, ALock4: ILock): IMultiLockGuard;
begin
  Result := TMultiLockGuard.Create([ALock1, ALock2, ALock3, ALock4]);
end;

function TryScopedLock(const ALocks: array of ILock; out AGuard: IMultiLockGuard): Boolean;
var
  SortedLocks: array of ILock = nil;
  i, j: Integer;
begin
  Result := False;
  AGuard := nil;

  if Length(ALocks) = 0 then
  begin
    Result := True;  // 空数组视为成功
    Exit;
  end;

  // 复制并排序锁
  SetLength(SortedLocks, Length(ALocks));
  for i := 0 to High(ALocks) do
    SortedLocks[i] := ALocks[i];

  TMultiLockGuard.SortLocksByAddress(SortedLocks);

  // 尝试按顺序获取所有锁（使用 TryAcquire 而不是 TryLock）
  for i := 0 to High(SortedLocks) do
  begin
    if not SortedLocks[i].TryAcquire then
    begin
      // 释放已获取的锁（从 i-1 到 0）
      for j := i - 1 downto 0 do
        SortedLocks[j].Release;
      Exit;
    end;
  end;

  // 所有锁都已获取，创建守卫（不再次获取）
  Result := True;
  AGuard := TMultiLockGuardNoAcquire.Create(SortedLocks);
end;

function TryScopedLockFor(const ALocks: array of ILock; ATimeoutMs: Cardinal; out AGuard: IMultiLockGuard): Boolean;
var
  SortedLocks: array of ILock = nil;
  i, j: Integer;
  StartTime: QWord;
  Elapsed: QWord;
  Remaining: Cardinal;
begin
  Result := False;
  AGuard := nil;

  if Length(ALocks) = 0 then
  begin
    Result := True;  // 空数组视为成功
    Exit;
  end;

  // 复制并排序锁
  SetLength(SortedLocks, Length(ALocks));
  for i := 0 to High(ALocks) do
    SortedLocks[i] := ALocks[i];

  TMultiLockGuard.SortLocksByAddress(SortedLocks);

  StartTime := GetTickCount64;

  // 尝试按顺序获取所有锁（使用 TryAcquireFor 而不是 TryLockFor）
  for i := 0 to High(SortedLocks) do
  begin
    // 计算剩余超时时间
    Elapsed := GetTickCount64 - StartTime;
    if Elapsed >= ATimeoutMs then
      Remaining := 0
    else
      Remaining := ATimeoutMs - Cardinal(Elapsed);

    if not SortedLocks[i].TryAcquire(Remaining) then
    begin
      // 释放已获取的锁（从 i-1 到 0）
      for j := i - 1 downto 0 do
        SortedLocks[j].Release;
      Exit;
    end;
  end;

  // 所有锁都已获取
  Result := True;
  AGuard := TMultiLockGuardNoAcquire.Create(SortedLocks);
end;

end.
