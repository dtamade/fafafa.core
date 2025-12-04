unit fafafa.core.sync.oncelock;

{**
 * fafafa.core.sync.oncelock - Rust 风格线程安全懒初始化容器
 *
 * @desc
 *   实现 Rust 的 OnceLock<T> 语义：
 *   - 线程安全的单次初始化
 *   - 懒加载值存储
 *   - 初始化后不可变
 *
 * @rust_equivalent
 *   std::sync::OnceLock<T>
 *
 * @usage
 *   var Lock: specialize TOnceLock<Integer>;
 *   begin
 *     Lock := specialize TOnceLock<Integer>.Create;
 *     try
 *       Lock.SetValue(42);
 *       WriteLn(Lock.GetValue);  // 42
 *     finally
 *       Lock.Free;
 *     end;
 *   end;
 *
 * @author fafafaStudio
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.sync.base;

type
  { 异常类型 }
  EOnceLockError = class(ESyncError);
  EOnceLockEmpty = class(EOnceLockError);
  EOnceLockAlreadySet = class(EOnceLockError);

  { OnceLock 状态（三态，用于正确的内存模型） }
  TOnceLockState = (
    olsUnset,      // 0: 未设置
    olsSetting,    // 1: 正在设置（某线程正在写入值）
    olsSet         // 2: 已设置（值可见）
  );

  { 泛型初始化器函数类型 }
  generic TInitializer<T> = function: T;

  {**
   * TOnceLock<T> - 线程安全的单次初始化容器
   *
   * @desc
   *   存储一个值，保证只能被初始化一次。
   *   线程安全，多线程可以同时尝试设置，但只有一个会成功。
   *
   * @type_param T
   *   存储的值类型。支持任何类型，包括托管类型（如 string）。
   *
   * @rust_equivalent
   *   std::sync::OnceLock<T>
   *}
  generic TOnceLock<T> = class
  public type
    PT = ^T;
    TInitFunc = function: T;
  private
    FValue: T;
    FState: LongInt;  // TOnceLockState as LongInt for atomic ops

    { 等待其他线程完成设置 }
    procedure WaitForSet;
  public
    constructor Create;
    destructor Destroy; override;

    {**
     * IsSet - 检查是否已设置值
     *
     * @return True 如果已设置值
     *}
    function IsSet: Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

    {**
     * SetValue - 设置值（如果已设置则抛出异常）
     *
     * @param AValue 要设置的值
     * @raises EOnceLockAlreadySet 如果值已经被设置
     *}
    procedure SetValue(const AValue: T);

    {**
     * TrySet - 尝试设置值
     *
     * @param AValue 要设置的值
     * @return True 如果成功设置，False 如果已有值
     *}
    function TrySet(const AValue: T): Boolean;

    {**
     * GetValue - 获取值（如果未设置则抛出异常）
     *
     * @return 存储的值
     * @raises EOnceLockEmpty 如果值未设置
     *}
    function GetValue: T;

    {**
     * TryGet - 尝试获取值的指针
     *
     * @return 值的指针，如果未设置则返回 nil
     *}
    function TryGet: PT;

    {**
     * GetOrInit - 获取值或使用初始化器初始化
     *
     * @param AInitializer 初始化函数（仅在未设置时调用）
     * @return 存储的值
     *
     * @thread_safety
     *   线程安全，多线程竞争时只有一个初始化器会被执行
     *}
    function GetOrInit(AInitializer: TInitFunc): T;

    {**
     * GetOrTryInit - 获取值或尝试初始化（带错误处理）
     *
     * @param AInitializer 初始化函数
     * @param AError 输出参数，初始化失败时返回异常对象
     * @return 存储的值（失败时返回默认值）
     *
     * @rust_equivalent
     *   std::sync::OnceLock::get_or_try_init
     *}
    function GetOrTryInit(AInitializer: TInitFunc; out AError: Exception): T;

    {**
     * Take - 获取并清空值（转移所有权）
     *
     * @return 存储的值
     * @raises EOnceLockEmpty 如果值未设置
     *
     * @rust_equivalent
     *   std::sync::OnceLock::take
     *}
    function Take: T;

    {**
     * IntoInner - 获取内部值（不清空）
     *
     * @return 存储的值
     * @raises EOnceLockEmpty 如果值未设置
     *
     * @rust_equivalent
     *   std::sync::OnceLock::into_inner
     *}
    function IntoInner: T;

    {**
     * Wait - 等待初始化完成
     *
     * @desc
     *   阻塞当前线程直到值被设置
     *}
    procedure Wait;

    {**
     * WaitTimeout - 带超时的等待
     *
     * @param ATimeoutMs 超时时间（毫秒）
     * @return True 如果值已设置，False 如果超时
     *}
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
  end;

implementation

{ TOnceLock<T> }

constructor TOnceLock.Create;
begin
  inherited Create;
  FState := LongInt(olsUnset);
  FValue := Default(T);
end;

destructor TOnceLock.Destroy;
begin
  // 清理托管类型
  FValue := Default(T);
  inherited Destroy;
end;

procedure TOnceLock.WaitForSet;
begin
  // 等待另一个线程完成设置
  while TOnceLockState(InterlockedCompareExchange(FState, 0, 0)) = olsSetting do
  begin
    {$IFDEF UNIX}
    ThreadSwitch;
    {$ELSE}
    Sleep(0);
    {$ENDIF}
  end;
end;

function TOnceLock.IsSet: Boolean;
var
  State: TOnceLockState;
begin
  // 使用原子读取状态
  State := TOnceLockState(InterlockedCompareExchange(FState, 0, 0));
  if State = olsSetting then
  begin
    // 正在设置中，等待完成
    WaitForSet;
    State := TOnceLockState(InterlockedCompareExchange(FState, 0, 0));
  end;
  Result := State = olsSet;
  if Result then
    ReadBarrier;  // Acquire 语义：确保后续读取 FValue 可见
end;

procedure TOnceLock.SetValue(const AValue: T);
begin
  if not TrySet(AValue) then
    raise EOnceLockAlreadySet.Create('OnceLock: Value already set');
end;

function TOnceLock.TrySet(const AValue: T): Boolean;
var
  OldState: LongInt;
begin
  // 原子性地尝试从 Unset 变为 Setting
  OldState := InterlockedCompareExchange(FState, LongInt(olsSetting), LongInt(olsUnset));
  
  if TOnceLockState(OldState) = olsUnset then
  begin
    // 成功获取设置权限
    // 正确顺序：先写值，再发布状态
    FValue := AValue;
    WriteBarrier;  // Release 语义：确保 FValue 写入对其他线程可见
    InterlockedExchange(FState, LongInt(olsSet));  // 发布：现在其他线程可以看到值了
    Result := True;
  end
  else if TOnceLockState(OldState) = olsSetting then
  begin
    // 另一个线程正在设置，等待完成后返回失败
    WaitForSet;
    Result := False;
  end
  else
    Result := False;  // 已经设置
end;

function TOnceLock.GetValue: T;
begin
  if not IsSet then  // IsSet 已经包含了 ReadBarrier
    raise EOnceLockEmpty.Create('OnceLock: Value not set');
  Result := FValue;
end;

function TOnceLock.TryGet: PT;
begin
  if IsSet then  // IsSet 已经包含了 ReadBarrier
    Result := @FValue
  else
    Result := nil;
end;

function TOnceLock.GetOrInit(AInitializer: TInitFunc): T;
var
  OldState: LongInt;
begin
  // 快速路径：已经设置
  if IsSet then  // IsSet 已经包含了 ReadBarrier
    Exit(FValue);

  // 慢路径：尝试初始化
  OldState := InterlockedCompareExchange(FState, LongInt(olsSetting), LongInt(olsUnset));
  
  if TOnceLockState(OldState) = olsUnset then
  begin
    // 赢得初始化权限
    // 正确顺序：先写值，再发布状态
    FValue := AInitializer();
    WriteBarrier;  // Release 语义
    InterlockedExchange(FState, LongInt(olsSet));
  end
  else if TOnceLockState(OldState) = olsSetting then
  begin
    // 另一个线程正在初始化，等待完成
    WaitForSet;
  end;
  // 否则 olsSet：其他线程已经设置了值

  ReadBarrier;  // Acquire 语义
  Result := FValue;
end;

function TOnceLock.GetOrTryInit(AInitializer: TInitFunc; out AError: Exception): T;
var
  OldState: LongInt;
begin
  AError := nil;
  Result := Default(T);
  
  // 快速路径：已经设置
  if IsSet then  // IsSet 已经包含了 ReadBarrier
    Exit(FValue);

  // 慢路径：尝试初始化
  OldState := InterlockedCompareExchange(FState, LongInt(olsSetting), LongInt(olsUnset));
  
  if TOnceLockState(OldState) = olsUnset then
  begin
    try
      // 赢得初始化权限
      FValue := AInitializer();
      WriteBarrier;  // Release 语义
      InterlockedExchange(FState, LongInt(olsSet));
      Result := FValue;
    except
      on E: Exception do
      begin
        // 初始化失败，恢复状态
        InterlockedExchange(FState, LongInt(olsUnset));
        AError := Exception.Create(E.Message);
      end;
    end;
  end
  else if TOnceLockState(OldState) = olsSetting then
  begin
    // 另一个线程正在初始化，等待完成
    WaitForSet;
    ReadBarrier;
    Result := FValue;
  end
  else
  begin
    // 其他线程已经设置了值
    ReadBarrier;
    Result := FValue;
  end;
end;

function TOnceLock.Take: T;
begin
  if not IsSet then  // IsSet 已经包含了 ReadBarrier
    raise EOnceLockEmpty.Create('OnceLock: Value not set');
  
  Result := FValue;
  FValue := Default(T);
  WriteBarrier;
  InterlockedExchange(FState, LongInt(olsUnset));
end;

function TOnceLock.IntoInner: T;
begin
  if not IsSet then  // IsSet 已经包含了 ReadBarrier
    raise EOnceLockEmpty.Create('OnceLock: Value not set');
  Result := FValue;
end;

procedure TOnceLock.Wait;
begin
  // IsSet 内部会处理 olsSetting 状态的等待，并在成功时加 ReadBarrier
  while not IsSet do
  begin
    // 简单的自旋等待，CPU 友好
    {$IFDEF UNIX}
    ThreadSwitch;
    {$ELSE}
    Sleep(0);
    {$ENDIF}
  end;
end;

function TOnceLock.WaitTimeout(ATimeoutMs: Cardinal): Boolean;
var
  EndTime: QWord;
begin
  // 快速路径
  if IsSet then
    Exit(True);
  
  EndTime := GetTickCount64 + ATimeoutMs;
  
  while not IsSet do
  begin
    if GetTickCount64 >= EndTime then
      Exit(False);
    
    // CPU 友好的短暂等待
    {$IFDEF UNIX}
    ThreadSwitch;
    {$ELSE}
    Sleep(1);
    {$ENDIF}
  end;
  
  Result := True;
end;

end.
