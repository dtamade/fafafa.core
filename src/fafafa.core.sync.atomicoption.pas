unit fafafa.core.sync.atomicoption;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  TAtomicOption<T> - 原子可选值（线程安全的 Option 类型）

  参照 Rust crossbeam::atomic::AtomicCell<Option<T>> 设计：
  - 原子地存储 Some(T) 或 None
  - 支持 Take（取出并清空）操作
  - 支持 Swap（交换值）操作

  使用示例：
    var
      Opt: TAtomicOption<Integer>;
      Val: Integer;
    begin
      Opt.Init;
      Opt.Store(42);
      if Opt.Take(Val) then
        WriteLn(Val);  // 42
      // 现在是 None
      if not Opt.Take(Val) then
        WriteLn('Empty');
    end;

  适用场景：
  - 线程间传递可选数据
  - 一次性初始化
  - 懒惰初始化
}

interface

uses
  fafafa.core.atomic;

type

  { generic TAtomicOption<T> }

  generic TAtomicOption<T> = record
  private
    FValue: T;
    FHasValue: Int32;  // 0 = None, 1 = Some
    FLock: Int32;

    procedure SpinLock; inline;
    procedure SpinUnlock; inline;
  public
    {** 初始化为 None *}
    procedure Init;

    {** 检查是否有值 *}
    function IsSome: Boolean;

    {** 检查是否为空 *}
    function IsNone: Boolean;

    {** 存储值（设为 Some） *}
    procedure Store(const AValue: T);

    {** 清空（设为 None） *}
    procedure Clear;

    {** 加载值
        @param AValue 输出值
        @return 如果有值返回 True *}
    function Load(out AValue: T): Boolean;

    {** 取出值（原子地读取并清空）
        @param AValue 输出值
        @return 如果有值返回 True *}
    function Take(out AValue: T): Boolean;

    {** 交换值
        @param ANewValue 新值（如果想设为 None，使用 Take）
        @param AOldValue 输出旧值
        @return 如果有旧值返回 True *}
    function Swap(const ANewValue: T; out AOldValue: T): Boolean;

    {** 仅在 None 时存储（类似 get_or_insert）
        @param AValue 要存储的值
        @return 如果成功存储返回 True *}
    function StoreIfNone(const AValue: T): Boolean;
  end;

  { 常用类型特化 }
  TAtomicOptionInt32 = specialize TAtomicOption<Int32>;
  TAtomicOptionInt64 = specialize TAtomicOption<Int64>;
  TAtomicOptionPointer = specialize TAtomicOption<Pointer>;

implementation

{ TAtomicOption<T> }

procedure TAtomicOption.SpinLock;
var
  Expected: Int32;
begin
  repeat
    Expected := 0;
  until atomic_compare_exchange_weak(FLock, Expected, 1, mo_acquire, mo_relaxed);
end;

procedure TAtomicOption.SpinUnlock;
begin
  atomic_store(FLock, 0, mo_release);
end;

procedure TAtomicOption.Init;
begin
  FHasValue := 0;
  FLock := 0;
end;

function TAtomicOption.IsSome: Boolean;
begin
  Result := atomic_load(FHasValue, mo_acquire) <> 0;
end;

function TAtomicOption.IsNone: Boolean;
begin
  Result := atomic_load(FHasValue, mo_acquire) = 0;
end;

procedure TAtomicOption.Store(const AValue: T);
begin
  SpinLock;
  try
    FValue := AValue;
    atomic_store(FHasValue, 1, mo_release);
  finally
    SpinUnlock;
  end;
end;

procedure TAtomicOption.Clear;
begin
  atomic_store(FHasValue, 0, mo_release);
end;

function TAtomicOption.Load(out AValue: T): Boolean;
begin
  SpinLock;
  try
    if FHasValue <> 0 then
    begin
      AValue := FValue;
      Result := True;
    end
    else
      Result := False;
  finally
    SpinUnlock;
  end;
end;

function TAtomicOption.Take(out AValue: T): Boolean;
begin
  SpinLock;
  try
    if FHasValue <> 0 then
    begin
      AValue := FValue;
      FHasValue := 0;
      Result := True;
    end
    else
      Result := False;
  finally
    SpinUnlock;
  end;
end;

function TAtomicOption.Swap(const ANewValue: T; out AOldValue: T): Boolean;
begin
  SpinLock;
  try
    if FHasValue <> 0 then
    begin
      AOldValue := FValue;
      Result := True;
    end
    else
      Result := False;
    FValue := ANewValue;
    FHasValue := 1;
  finally
    SpinUnlock;
  end;
end;

function TAtomicOption.StoreIfNone(const AValue: T): Boolean;
begin
  SpinLock;
  try
    if FHasValue = 0 then
    begin
      FValue := AValue;
      FHasValue := 1;
      Result := True;
    end
    else
      Result := False;
  finally
    SpinUnlock;
  end;
end;

end.
