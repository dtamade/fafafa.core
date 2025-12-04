unit fafafa.core.sync.lazylock;

{**
 * LazyLock - Rust 风格的线程安全懒加载容器
 *
 * TLazyLock<T> 与 OnceLock<T> 类似，但它在创建时接受一个初始化器，
 * 在第一次访问时自动初始化。类似于 Rust 的 std::sync::LazyLock。
 *
 * 特性：
 *   - 延迟初始化：创建时不执行初始化器，第一次访问时才执行
 *   - 线程安全：多线程环境下初始化器只执行一次
 *   - 无锁快路径：初始化后访问无额外开销
 *
 * 示例：
 *   function GlobalInit: Integer;
 *   begin
 *     Result := ComputeExpensiveValue;
 *   end;
 *
 *   var Lazy: specialize TLazyLock<Integer>;
 *   Lazy := specialize TLazyLock<Integer>.Create(@GlobalInit);
 *   Value := Lazy.GetValue;  // 第一次访问时调用 GlobalInit
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils;

type
  { 初始化器函数类型 }
  generic TInitializer<T> = function: T;

  { 懒加载状态 }
  TLazyState = (
    lsUninit,       // 未初始化
    lsInitializing, // 正在初始化（某线程正在执行）
    lsInitialized   // 已初始化
  );

  { TLazyLock - 线程安全懒加载容器 }
  generic TLazyLock<T> = class
  public type
    PT = ^T;
    TInit = specialize TInitializer<T>;
  private
    FState: TLazyState;
    FValue: T;
    FInitializer: TInit;

    {**
     * EnsureInitialized - 确保初始化完成（内部统一逻辑）
     *
     * @return True 如果当前线程执行了初始化，False 如果其他线程已初始化
     *}
    function EnsureInitialized: Boolean;

    { 等待其他线程完成初始化 }
    procedure WaitForInitialized;
  public
    {**
     * 创建 LazyLock
     * @param AInitializer 初始化函数，第一次访问时调用
     *}
    constructor Create(AInitializer: TInit);
    destructor Destroy; override;

    {**
     * 获取值，如果未初始化则执行初始化
     * 这是最常用的方法
     *}
    function GetValue: T;

    {**
     * 强制初始化（如果尚未初始化）
     * 用于预热或确保初始化在特定时机完成
     *}
    procedure Force; inline;

    {**
     * 尝试获取值的指针，不触发初始化
     * @return 如果已初始化返回指针，否则返回 nil
     *}
    function TryGet: PT;

    {**
     * 检查是否已初始化
     *}
    function IsInitialized: Boolean; inline;

    {**
     * ForceInit - 强制初始化，返回是否首次初始化
     *
     * @return True 如果是首次初始化，False 如果已经初始化
     *}
    function ForceInit: Boolean;

    {**
     * TryGetValue - 尝试获取值（不触发初始化）
     *
     * @param AValue 输出参数，如果已初始化则返回值
     * @return True 如果已初始化，False 如果未初始化
     *}
    function TryGetValue(out AValue: T): Boolean;

    {**
     * GetOrElse - 获取值或返回默认值（不触发初始化）
     *
     * @param ADefault 未初始化时返回的默认值
     * @return 如果已初始化返回实际值，否则返回默认值
     *}
    function GetOrElse(const ADefault: T): T;
  end;

implementation

{ TLazyLock }

constructor TLazyLock.Create(AInitializer: TInit);
begin
  inherited Create;
  FState := lsUninit;
  FInitializer := AInitializer;
  FValue := Default(T);
end;

destructor TLazyLock.Destroy;
begin
  FValue := Default(T);
  inherited;
end;

procedure TLazyLock.WaitForInitialized;
begin
  // 等待另一个线程完成初始化
  while FState = lsInitializing do
  begin
    ReadBarrier;
    ThreadSwitch;
  end;
end;

function TLazyLock.EnsureInitialized: Boolean;
var
  OldState: LongInt;
begin
  // 快速路径：已初始化
  if FState = lsInitialized then
    Exit(False);

  // 慢路径：尝试获取初始化权
  OldState := InterlockedCompareExchange(
    LongInt(FState),
    LongInt(lsInitializing),
    LongInt(lsUninit)
  );

  case TLazyState(OldState) of
    lsUninit:
    begin
      // 我们赢得了初始化权
      try
        FValue := FInitializer();
        WriteBarrier;  // Release 语义：确保 FValue 可见
        FState := lsInitialized;
        Result := True;
      except
        FState := lsUninit;  // 初始化失败，恢复状态
        raise;
      end;
    end;
    
    lsInitializing:
    begin
      // 另一个线程正在初始化，等待完成
      WaitForInitialized;
      Result := False;
    end;
    
    else  // lsInitialized
      Result := False;
  end;
end;

function TLazyLock.GetValue: T;
begin
  EnsureInitialized;
  ReadBarrier;  // Acquire 语义
  Result := FValue;
end;

procedure TLazyLock.Force;
begin
  EnsureInitialized;
end;

function TLazyLock.TryGet: PT;
begin
  if FState = lsInitialized then
  begin
    ReadBarrier;
    Result := @FValue;
  end
  else
    Result := nil;
end;

function TLazyLock.IsInitialized: Boolean;
begin
  Result := FState = lsInitialized;
end;

function TLazyLock.ForceInit: Boolean;
begin
  // 统一使用 EnsureInitialized，返回是否由当前线程执行了初始化
  Result := EnsureInitialized;
end;

function TLazyLock.TryGetValue(out AValue: T): Boolean;
begin
  if FState = lsInitialized then
  begin
    ReadBarrier;
    AValue := FValue;
    Result := True;
  end
  else
  begin
    AValue := Default(T);
    Result := False;
  end;
end;

function TLazyLock.GetOrElse(const ADefault: T): T;
begin
  if FState = lsInitialized then
  begin
    ReadBarrier;
    Result := FValue;
  end
  else
    Result := ADefault;
end;

end.
