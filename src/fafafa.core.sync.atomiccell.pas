unit fafafa.core.sync.atomiccell;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  TAtomicCell<T> - 原子单元格（线程安全的值容器）

  参照 Rust crossbeam::atomic::AtomicCell 设计：
  - 对于 4/8 字节类型，使用无锁原子操作
  - 对于其他大小的类型，使用自旋锁保护
  - 提供 Load/Store/Swap/CompareExchange 操作

  与 Interlocked 函数的区别：
  - AtomicCell 是泛型容器，支持任意类型
  - 自动选择最优的同步策略
  - API 更符合现代并发编程风格

  使用示例：
    var
      Cell: TAtomicCell<Integer>;
    begin
      Cell.Init(42);
      WriteLn(Cell.Load);      // 42
      Cell.Store(100);
      WriteLn(Cell.Swap(200)); // 100
    end;

  限制：
  - 最高效支持 4 字节和 8 字节类型
  - 其他大小的类型使用自旋锁（性能较低）
}

interface

uses
  SysUtils, fafafa.core.atomic;

type

  { TAtomicCell<T> - 泛型原子单元格 }

  generic TAtomicCell<T> = record
  private
    FValue: T;
    FLock: Int32;  // 自旋锁（非原子类型使用）

    procedure SpinLock; inline;
    procedure SpinUnlock; inline;
    function IsLockFree: Boolean; inline;
  public
    {** 初始化单元格 *}
    procedure Init(const AValue: T);

    {** 原子加载值 *}
    function Load: T;

    {** 原子存储值 *}
    procedure Store(const AValue: T);

    {** 原子交换，返回旧值 *}
    function Swap(const ANewValue: T): T;

    {** 原子比较交换
        @param AExpected 期望的当前值（成功后不变，失败后更新为实际值）
        @param ADesired 要设置的新值
        @return 如果交换成功返回 True *}
    function CompareExchange(var AExpected: T; const ADesired: T): Boolean;

    {** 获取或设置值（非原子，仅用于单线程初始化） *}
    property Value: T read FValue write FValue;
  end;

  { 常用类型特化 }
  TAtomicCellInt32 = specialize TAtomicCell<Int32>;
  TAtomicCellInt64 = specialize TAtomicCell<Int64>;
  TAtomicCellUInt32 = specialize TAtomicCell<UInt32>;
  TAtomicCellUInt64 = specialize TAtomicCell<UInt64>;
  TAtomicCellPointer = specialize TAtomicCell<Pointer>;

implementation

{ TAtomicCell<T> }

procedure TAtomicCell.SpinLock;
var
  Expected: Int32;
begin
  repeat
    Expected := 0;
  until atomic_compare_exchange_weak(FLock, Expected, 1, mo_acquire, mo_relaxed);
end;

procedure TAtomicCell.SpinUnlock;
begin
  atomic_store(FLock, 0, mo_release);
end;

function TAtomicCell.IsLockFree: Boolean;
begin
  // 4 或 8 字节的类型可以使用原子操作
  Result := (SizeOf(T) = 4) or (SizeOf(T) = 8);
end;

procedure TAtomicCell.Init(const AValue: T);
begin
  FLock := 0;
  FValue := AValue;
end;

function TAtomicCell.Load: T;
var
  Temp32: Int32;
  Temp64: Int64;
begin
  if SizeOf(T) = 4 then
  begin
    Temp32 := atomic_load(PInt32(@FValue)^, mo_acquire);
    Move(Temp32, Result, 4);
  end
  else if SizeOf(T) = 8 then
  begin
    Temp64 := atomic_load(PInt64(@FValue)^, mo_acquire);
    Move(Temp64, Result, 8);
  end
  else
  begin
    // 其他大小使用自旋锁
    SpinLock;
    try
      Result := FValue;
    finally
      SpinUnlock;
    end;
  end;
end;

procedure TAtomicCell.Store(const AValue: T);
var
  Temp32: Int32;
  Temp64: Int64;
begin
  if SizeOf(T) = 4 then
  begin
    Move(AValue, Temp32, 4);
    atomic_store(PInt32(@FValue)^, Temp32, mo_release);
  end
  else if SizeOf(T) = 8 then
  begin
    Move(AValue, Temp64, 8);
    atomic_store(PInt64(@FValue)^, Temp64, mo_release);
  end
  else
  begin
    SpinLock;
    try
      FValue := AValue;
    finally
      SpinUnlock;
    end;
  end;
end;

function TAtomicCell.Swap(const ANewValue: T): T;
var
  TempOld32, TempNew32: Int32;
  TempOld64, TempNew64: Int64;
begin
  if SizeOf(T) = 4 then
  begin
    Move(ANewValue, TempNew32, 4);
    TempOld32 := atomic_exchange(PInt32(@FValue)^, TempNew32, mo_acq_rel);
    Move(TempOld32, Result, 4);
  end
  else if SizeOf(T) = 8 then
  begin
    Move(ANewValue, TempNew64, 8);
    TempOld64 := atomic_exchange(PInt64(@FValue)^, TempNew64, mo_acq_rel);
    Move(TempOld64, Result, 8);
  end
  else
  begin
    SpinLock;
    try
      Result := FValue;
      FValue := ANewValue;
    finally
      SpinUnlock;
    end;
  end;
end;

function TAtomicCell.CompareExchange(var AExpected: T; const ADesired: T): Boolean;
var
  TempExp32, TempDes32: Int32;
  TempExp64, TempDes64: Int64;
begin
  if SizeOf(T) = 4 then
  begin
    Move(AExpected, TempExp32, 4);
    Move(ADesired, TempDes32, 4);
    Result := atomic_compare_exchange_strong(
      PInt32(@FValue)^,
      TempExp32,
      TempDes32,
      mo_acq_rel, mo_acquire);
    if not Result then
      Move(TempExp32, AExpected, 4);
  end
  else if SizeOf(T) = 8 then
  begin
    Move(AExpected, TempExp64, 8);
    Move(ADesired, TempDes64, 8);
    Result := atomic_compare_exchange_strong(
      PInt64(@FValue)^,
      TempExp64,
      TempDes64,
      mo_acq_rel, mo_acquire);
    if not Result then
      Move(TempExp64, AExpected, 8);
  end
  else
  begin
    SpinLock;
    try
      if CompareMem(@FValue, @AExpected, SizeOf(T)) then
      begin
        FValue := ADesired;
        Result := True;
      end
      else
      begin
        AExpected := FValue;
        Result := False;
      end;
    finally
      SpinUnlock;
    end;
  end;
end;

end.
