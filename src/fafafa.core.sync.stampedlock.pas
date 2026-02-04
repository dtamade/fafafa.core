unit fafafa.core.sync.stampedlock;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  IStampedLock - 乐观读写锁实现

  状态编码（64 位）：
  - 低 16 位：读锁计数
  - 高 48 位：版本号（每次写操作递增）
  - 最高位：写锁标志

  特点：
  - 乐观读不获取锁，仅获取版本号
  - 验证时检查版本号是否变化
  - 适用于读远多于写的场景
}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.stampedlock.base,
  fafafa.core.atomic;

type

  { TStampedLock }

  TStampedLock = class(TInterfacedObject, IStampedLock, ISynchronizable)
  private
    FState: Int64;
    FData: Pointer;
  const
    WRITE_LOCKED = Int64($8000000000000000);  // 最高位：写锁
    READ_MASK = Int64($FFFF);                  // 低 16 位：读计数
    VERSION_SHIFT = 16;
    VERSION_UNIT = Int64(1) shl VERSION_SHIFT; // 版本号单位
  public
    constructor Create;

    { IStampedLock }
    function WriteLock: Int64;
    function TryWriteLock: Int64;
    procedure UnlockWrite(AStamp: Int64);
    function ReadLock: Int64;
    function TryReadLock: Int64;
    procedure UnlockRead(AStamp: Int64);
    function TryOptimisticRead: Int64;
    function Validate(AStamp: Int64): Boolean;
    function IsWriteLocked: Boolean;
    function GetReadLockCount: Integer;

    { ISynchronizable }
    function GetData: Pointer;
    procedure SetData(AData: Pointer);
  end;

function MakeStampedLock: IStampedLock;

implementation

uses
  SysUtils;

{ TStampedLock }

constructor TStampedLock.Create;
begin
  inherited Create;
  FState := VERSION_UNIT;  // 初始版本号为 1
  FData := nil;
end;

function TStampedLock.WriteLock: Int64;
var
  Current, NewState: Int64;
begin
  repeat
    Current := atomic_load(FState, mo_relaxed);
    // 等待没有读锁和写锁
    if ((Current and WRITE_LOCKED) <> 0) or ((Current and READ_MASK) <> 0) then
    begin
      Sleep(0);
      Continue;
    end;
    // 设置写锁标志
    NewState := Current or WRITE_LOCKED;
  until atomic_compare_exchange_weak(FState, Current, NewState, mo_acquire, mo_relaxed);

  Result := NewState;
end;

function TStampedLock.TryWriteLock: Int64;
var
  Current, NewState: Int64;
begin
  Current := atomic_load(FState, mo_relaxed);
  // 如果有读锁或写锁，直接返回 0
  if ((Current and WRITE_LOCKED) <> 0) or ((Current and READ_MASK) <> 0) then
    Exit(0);

  NewState := Current or WRITE_LOCKED;
  if atomic_compare_exchange_strong(FState, Current, NewState, mo_acquire, mo_relaxed) then
    Result := NewState
  else
    Result := 0;
end;

procedure TStampedLock.UnlockWrite(AStamp: Int64);
var
  NewState: Int64;
begin
  // 清除写锁标志，递增版本号
  NewState := (AStamp and (not WRITE_LOCKED)) + VERSION_UNIT;
  atomic_store(FState, NewState, mo_release);
end;

function TStampedLock.ReadLock: Int64;
var
  Current, NewState: Int64;
begin
  repeat
    Current := atomic_load(FState, mo_relaxed);
    // 等待没有写锁
    if (Current and WRITE_LOCKED) <> 0 then
    begin
      Sleep(0);
      Continue;
    end;
    // 递增读计数
    NewState := Current + 1;
  until atomic_compare_exchange_weak(FState, Current, NewState, mo_acquire, mo_relaxed);

  Result := NewState;
end;

function TStampedLock.TryReadLock: Int64;
var
  Current, NewState: Int64;
begin
  Current := atomic_load(FState, mo_relaxed);
  // 如果有写锁，直接返回 0
  if (Current and WRITE_LOCKED) <> 0 then
    Exit(0);

  NewState := Current + 1;
  if atomic_compare_exchange_strong(FState, Current, NewState, mo_acquire, mo_relaxed) then
    Result := NewState
  else
    Result := 0;
end;

procedure TStampedLock.UnlockRead(AStamp: Int64);
begin
  // 递减读计数
  atomic_fetch_sub(FState, 1, mo_release);
end;

function TStampedLock.TryOptimisticRead: Int64;
var
  S: Int64;
begin
  S := atomic_load(FState, mo_acquire);
  // 如果有写锁，返回 0
  if (S and WRITE_LOCKED) <> 0 then
    Result := 0
  else
    Result := S and (not READ_MASK);  // 返回版本号部分
end;

function TStampedLock.Validate(AStamp: Int64): Boolean;
var
  Current: Int64;
begin
  // 内存屏障确保之前的读操作完成
  atomic_thread_fence(mo_acquire);

  Current := atomic_load(FState, mo_relaxed);
  // 比较版本号是否相同（忽略读计数）
  Result := (Current and (not READ_MASK)) = AStamp;
end;

function TStampedLock.IsWriteLocked: Boolean;
begin
  Result := (atomic_load(FState, mo_relaxed) and WRITE_LOCKED) <> 0;
end;

function TStampedLock.GetReadLockCount: Integer;
begin
  Result := Integer(atomic_load(FState, mo_relaxed) and READ_MASK);
end;

function TStampedLock.GetData: Pointer;
begin
  Result := FData;
end;

procedure TStampedLock.SetData(AData: Pointer);
begin
  FData := AData;
end;

function MakeStampedLock: IStampedLock;
begin
  Result := TStampedLock.Create;
end;

end.
