{**
 * fafafa.core.result - Rust 风格错误处理类型
 *
 * @desc
 *   提供 TResult<T, E> 类型和丰富的组合子函数，用于显式、类型安全的错误处理。
 *   Provides TResult<T, E> type and rich combinators for explicit, type-safe error handling.
 *
 * @design_philosophy
 *   Result 类型将成功值和错误值统一为一个类型，强制调用者显式处理错误，避免异常的隐式控制流。
 *   Result type unifies success and error values into one type, forcing callers to explicitly handle errors, avoiding implicit control flow of exceptions.
 *
 * @core_concepts
 *   1. **Ok(T)**: 包含成功值的 Result
 *   2. **Err(E)**: 包含错误值的 Result
 *   3. **组合子**: 函数式操作，如 Map、AndThen、MapErr
 *   4. **类型转换**: 与 Option 类型的互转
 *   5. **错误上下文**: TErrorCtx 提供错误链和上下文信息
 *
 * @usage_patterns
 *   // 1. 基础构造
 *   type TIntResult = specialize TResult<Integer, string>;
 *   var R: TIntResult;
 *   R := TIntResult.Ok(42);
 *   R := TIntResult.Err('Not found');
 *
 *   // 2. Map 转换成功值（Ok(T) -> Ok(U)）
 *   function DoubleIt(const N: Integer): Integer;
 *   begin
 *     Result := N * 2;
 *   end;
 *   var Doubled: specialize TResult<Integer, string>;
 *   Doubled := ResultMap(R, @DoubleIt);  // Ok(42) -> Ok(84)
 *
 *   // 3. MapErr 转换错误值（Err(E) -> Err(E2)）
 *   function AddContext(const Err: string): string;
 *   begin
 *     Result := 'Error: ' + Err;
 *   end;
 *   var WithContext: specialize TResult<Integer, string>;
 *   WithContext := ResultMapErr(R, @AddContext);
 *
 *   // 4. AndThen 链式操作（Ok(T) -> Result<U, E>）
 *   function SafeDivide(const N: Integer): specialize TResult<Integer, string>;
 *   begin
 *     if N = 0 then
 *       Exit(specialize TResult<Integer, string>.Err('Division by zero'));
 *     Result := specialize TResult<Integer, string>.Ok(100 div N);
 *   end;
 *   var Divided: specialize TResult<Integer, string>;
 *   Divided := ResultAndThen(R, @SafeDivide);
 *
 *   // 5. Match 模式匹配
 *   function HandleResult(const N: Integer): string;
 *   begin
 *     Result := 'Success: ' + IntToStr(N);
 *   end;
 *   function HandleError(const Err: string): string;
 *   begin
 *     Result := 'Failed: ' + Err;
 *   end;
 *   var Message: string;
 *   Message := ResultMatch(R, @HandleResult, @HandleError);
 *
 * @combinators
 *   - **Map**: 转换 Ok 中的值，Err 保持不变
 *   - **MapErr**: 转换 Err 中的错误，Ok 保持不变
 *   - **AndThen**: 链式操作，可能返回 Err
 *   - **OrElse**: 错误恢复，提供备选 Result
 *   - **MapOr**: 提供默认值的 Map
 *   - **MapOrElse**: 提供默认值生成函数的 Map
 *   - **Match/Fold**: 模式匹配，处理 Ok 和 Err 两种情况
 *   - **Flatten**: 展平嵌套的 Result<Result<T, E>, E>
 *   - **Swap**: 交换 Ok 和 Err 的位置
 *   - **Zip**: 组合两个 Result 为元组
 *   - **ZipWith**: 组合两个 Result 并应用函数
 *
 * @error_handling_strategies
 *   1. **显式处理**: 使用 Match/Fold 处理所有情况
 *   2. **传播错误**: 使用 AndThen 链式传播
 *   3. **提供默认值**: 使用 UnwrapOr/MapOr
 *   4. **错误转换**: 使用 MapErr 添加上下文
 *   5. **错误恢复**: 使用 OrElse 提供备选方案
 *
 * @best_practices
 *   1. 优先使用 Result 而非异常处理可预期的错误
 *   2. 使用 AndThen 构建错误传播链
 *   3. 使用 MapErr 为错误添加上下文信息
 *   4. 使用 Match 显式处理所有情况
 *   5. 避免使用 Unwrap，优先使用 UnwrapOr 或 Match
 *
 * @see fafafa.core.option, fafafa.core.option.base, TOption, TErrorCtx
 *}
unit fafafa.core.result;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.option.base;

const
  {** 模块版本 | Module version *}
  FAFAFA_CORE_RESULT_VERSION = '1.0.0';

type
  EResultUnwrapError = class(ECore);

  { 函数类型定义 }
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  generic TResultFunc<TArg, TRes> = reference to function(const Arg: TArg): TRes;
  generic TResultProc<TArg> = reference to procedure(const Arg: TArg);
  generic TResultThunk<TRes> = reference to function: TRes;
  generic TResultBiPred<T1, T2> = reference to function(const A: T1; const B: T2): Boolean;
  {$ELSE}
  // FPC 3.2.x 兼容：使用传统函数指针类型
  generic TResultFunc<TArg, TRes> = function(const Arg: TArg): TRes;
  generic TResultProc<TArg> = procedure(const Arg: TArg);
  generic TResultThunk<TRes> = function: TRes;
  generic TResultBiPred<T1, T2> = function(const A: T1; const B: T2): Boolean;
  {$ENDIF}

  { TValueArray<T> - 动态数组别名（用于 collect/sequence 输出） }
  generic TValueArray<T> = array of T;

  { TUnit - 单元类型（无有效返回值）
    用于 ensure 等仅关注错误路径的 API。
  }
  TUnit = record
  end;

  { TTuple2 - 从 fafafa.core.base 重新导出
    用于 zip 等组合子返回值，字段命名为 First/Second。
    注意：类型定义在 fafafa.core.base 中，此处仅为文档说明。
  }

  { TErrorCtx<E> - 轻量错误上下文链类型
    封装原始错误并添加上下文消息，类似 Rust anyhow 的 Context 但保留原始错误类型。
    用法：
      var Err: specialize TErrorCtx<Integer>;
      Err := specialize TErrorCtx<Integer>.Create('file not found', 404);
      WriteLn(Err.Msg);   // 'file not found'
      WriteLn(Err.Inner); // 404
  }
  generic TErrorCtx<E> = record
    Msg: string;   // 上下文消息
    Inner: E;      // 原始错误（cause）
    class function Create(const AMsg: string; const AInner: E): TErrorCtx; static; inline;
    function ToDebugString(const InnerPrinter: specialize TResultFunc<E, string>): string;
  end;

  { TResult<T,E> - Rust 风格错误处理类型 }
  generic TResult<T, E> = record
  private
    type
      TOkOption = specialize TOption<T>;
      TErrOption = specialize TOption<E>;
  private
    FIsOk: Boolean;
    FOk: T;
    FErr: E;
    class operator Initialize(var aRec: TResult);
  public
    { 内部使用：无检查访问器，供组合子使用 }
    function GetOkUnchecked: T; inline;
    function GetErrUnchecked: E; inline;
    { 构造 }
    class function Ok(const AValue: T): TResult; static; inline;
    class function Err(const AError: E): TResult; static; inline;

    { 查询 }
    function IsOk: Boolean; inline;
    function IsErr: Boolean; inline;

    { 取值 }
    function Unwrap: T; inline;
    function UnwrapOr(const ADefault: T): T; inline;
    function UnwrapOrElse(const F: specialize TResultThunk<T>): T; inline;
    function UnwrapOrDefault: T; inline;
    function Expect(const AMsg: string): T; inline;
    function UnwrapErr: E; inline;
    function ExpectErr(const AMsg: string): E; inline;
    function TryUnwrap(out AValue: T): Boolean; inline;
    function TryUnwrapErr(out AError: E): Boolean; inline;
    function UnwrapUnchecked: T; inline;
    function UnwrapErrUnchecked: E; inline;

    { Option 转换 }
    function OkOption: TOkOption; inline;
    function ErrOption: TErrOption; inline;

    { 字符串表示 }
    function ToString: string; overload;
    function ToString(const OkFormat, ErrFormat: string): string; overload;
    function ToDebugString(const OkPrinter: specialize TResultFunc<T, string>;
      const ErrPrinter: specialize TResultFunc<E, string>): string;

    { 方法式 API - 仅限不改变泛型类型的操作 }
    { And_: Ok 时返回 B，Err 时返回自身（与 Rust and 对齐）}
    function And_(const B: TResult): TResult; inline;
    { Or_: Ok 时返回自身，Err 时返回 B（与 Rust or 对齐）}
    function Or_(const B: TResult): TResult; inline;
    function OrElseThunk(const F: specialize TResultThunk<TResult>): TResult; inline;
    { 旧名称，建议迁移至 And_/Or_ }
    function AndResult(const B: TResult): TResult; inline; deprecated 'Use And_ instead';
    function OrResult(const B: TResult): TResult; inline; deprecated 'Use Or_ instead';

    { 组合子方法 - 仅限不引入新泛型参数的操作 }
    function Inspect(const F: specialize TResultProc<T>): TResult; inline;
    function InspectErr(const F: specialize TResultProc<E>): TResult; inline;

    function IsOkAnd(const Pred: specialize TResultFunc<T, Boolean>): Boolean; inline;
    function IsErrAnd(const Pred: specialize TResultFunc<E, Boolean>): Boolean; inline;

    function Contains(const V: T; const Eq: specialize TResultBiPred<T, T>): Boolean; inline;
    function ContainsErr(const EVal: E; const Eq: specialize TResultBiPred<E, E>): Boolean; inline;

    function Equals(const Other: TResult; const EqT: specialize TResultBiPred<T, T>; const EqE: specialize TResultBiPred<E, E>): Boolean;
  end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
{ 全局组合子 - 需要改变泛型类型的操作 }
{ 由于 FPC 不支持在泛型记录中定义泛型方法，这些必须作为全局函数存在 }
{ 注意：这些函数需要 FPC 3.3.1+ 的 generic function 语法支持 }

generic function ResultMap<T, E, U>(const R: specialize TResult<T, E>;
  const F: specialize TResultFunc<T, U>): specialize TResult<U, E>; inline;

generic function ResultMapErr<T, E, E2>(const R: specialize TResult<T, E>;
  const F: specialize TResultFunc<E, E2>): specialize TResult<T, E2>; inline;

generic function ResultAndThen<T, E, U>(const R: specialize TResult<T, E>;
  const F: specialize TResultFunc<T, specialize TResult<U, E>>): specialize TResult<U, E>; inline;

generic function ResultOrElse<T, E, E2>(const R: specialize TResult<T, E>;
  const F: specialize TResultFunc<E, specialize TResult<T, E2>>): specialize TResult<T, E2>; inline;

generic function ResultMapOr<T, E, U>(const R: specialize TResult<T, E>;
  const ADefault: U; const F: specialize TResultFunc<T, U>): U; inline;

generic function ResultMapOrElse<T, E, U>(const R: specialize TResult<T, E>;
  const Ferr: specialize TResultFunc<E, U>; const Fok: specialize TResultFunc<T, U>): U; inline;

generic function ResultMatch<T, E, U>(const R: specialize TResult<T, E>;
  const Fok: specialize TResultFunc<T, U>; const Ferr: specialize TResultFunc<E, U>): U; inline;

{ ResultFold - ResultMatch 的同义函数，便于从 fold 风格迁移 }
generic function ResultFold<T, E, U>(const R: specialize TResult<T, E>;
  const Fok: specialize TResultFunc<T, U>; const Ferr: specialize TResultFunc<E, U>): U; inline;

generic function ResultSwap<T, E>(const R: specialize TResult<T, E>): specialize TResult<E, T>; inline;

generic function ResultFlatten<T, E>(const R: specialize TResult<specialize TResult<T, E>, E>): specialize TResult<T, E>; inline;

generic function ResultMapBoth<T, E, U, F>(const R: specialize TResult<T, E>;
  const Fok: specialize TResultFunc<T, U>; const Ferr: specialize TResultFunc<E, F>): specialize TResult<U, F>; inline;

generic function ResultFilterOrElse<T, E>(const R: specialize TResult<T, E>;
  const Pred: specialize TResultFunc<T, Boolean>;
  const Ferr: specialize TResultFunc<T, E>): specialize TResult<T, E>; inline;

{ ResultChain - 函数式管道组合
  功能等同于 First.AndResult(Second)，但作为全局函数形式存在，
  适用于函数式管道场景，例如：
    R := specialize ResultChain<T,E>(
           specialize ResultChain<T,E>(Step1, Step2),
           Step3);
  如果 First 是 Ok，返回 Second；否则返回 First。
}
generic function ResultChain<T, E>(const First, Second: specialize TResult<T, E>): specialize TResult<T, E>;

{ ResultEnsure - 断言条件为真，否则返回 Err
  成功时返回 Ok(Unit)。
}
generic function ResultEnsure<E>(const Cond: Boolean;
  const ErrVal: E): specialize TResult<TUnit, E>; inline;

{ ResultEnsureWith - 惰性版本
  仅在 Cond=False 时调用 ErrThunk。
}
generic function ResultEnsureWith<E>(const Cond: Boolean;
  const ErrThunk: specialize TResultThunk<E>): specialize TResult<TUnit, E>; inline;

{ ResultFromBool - 从布尔条件构造 Result }
generic function ResultFromBool<T, E>(const Cond: Boolean;
  const OkVal: T; const ErrVal: E): specialize TResult<T, E>; inline;

{ ResultFromOption - Option<T> -> Result<T,E>
  Some(T) -> Ok(T)
  None -> Err(ErrVal)
}
generic function ResultFromOption<T, E>(const O: specialize TOption<T>;
  const ErrVal: E): specialize TResult<T, E>; inline;

{ ResultFromOptionElse - 惰性版本
  None -> Err(ErrThunk())
}
generic function ResultFromOptionElse<T, E>(const O: specialize TOption<T>;
  const ErrThunk: specialize TResultThunk<E>): specialize TResult<T, E>; inline;

{ ResultZip - (Ok(T1), Ok(T2)) -> Ok((T1,T2))，否则返回首个 Err }
generic function ResultZip<T1, T2, E>(const A: specialize TResult<T1, E>;
  const B: specialize TResult<T2, E>): specialize TResult<specialize TTuple2<T1, T2>, E>; inline;

{ ResultZipWith - (Ok(T1), Ok(T2)) -> Ok(F((T1,T2)))，否则返回首个 Err
  仅在两个都 Ok 时调用 F。
}
generic function ResultZipWith<T1, T2, E, U>(const A: specialize TResult<T1, E>;
  const B: specialize TResult<T2, E>;
  const F: specialize TResultFunc<specialize TTuple2<T1, T2>, U>): specialize TResult<U, E>; inline;

{ TryCollectPtrIntoArray
  输入：(ptr,count) 形式的 Result<T,E> 序列
  输出：
    - 全部 Ok：返回 True，并将 Ok 值按顺序写入 OutValues（动态数组）
    - 遇到首个 Err：返回 False，清空 OutValues，并将 FirstErr 设为首个错误
  注意：为规避 FPC 3.3.1 的泛型链接器/initialize 问题，此 API 返回 Boolean + out 参数，而非 TResult。
}
generic function TryCollectPtrIntoArray<T, E>(const ItemsPtr: Pointer; const Count: SizeUInt;
  var OutValues: specialize TValueArray<T>; out FirstErr: E): Boolean;

generic function ResultToTry<T, E>(const R: specialize TResult<T, E>;
  const MapE: specialize TResultFunc<E, Exception>): T; inline;

generic function ResultFromTry<T, E>(const Work: specialize TResultThunk<T>;
  const MapEx: specialize TResultFunc<Exception, E>): specialize TResult<T, E>;

{ ResultContext - 错误上下文包装
  类似 Rust anyhow 的 context，将原始错误替换为上下文字符串。
  Ok 保持不变，Err 被替换为 Ctx 字符串。
  用于为错误添加有意义的上下文信息。
}
generic function ResultContext<T, E>(const R: specialize TResult<T, E>;
  const Ctx: string): specialize TResult<T, string>; inline;

{ ResultWithContext - 懒惰错误上下文包装
  仅在 Err 时调用 CtxFunc 生成上下文字符串。
  Ok 保持不变，Err 被替换为 CtxFunc(E) 的结果。
  用于动态构建上下文信息，如包含原始错误代码。
}
generic function ResultWithContext<T, E>(const R: specialize TResult<T, E>;
  const CtxFunc: specialize TResultFunc<E, string>): specialize TResult<T, string>; inline;

{ ResultContextE - 保留原始错误类型的上下文包装
  与 ResultContext 不同，此版本保留原始错误 E 作为 Inner，不丢失类型信息。
  Ok 保持不变，Err(e) -> Err(TErrorCtx<E>[Msg=Ctx, Inner=e])
}
generic function ResultContextE<T, E>(const R: specialize TResult<T, E>;
  const Ctx: string): specialize TResult<T, specialize TErrorCtx<E>>; inline;

{ ResultWithContextE - 惰性版本，保留原始错误类型
  仅在 Err 时调用 CtxFunc 生成上下文消息。
  Ok 保持不变，Err(e) -> Err(TErrorCtx<E>[Msg=CtxFunc(e), Inner=e])
}
generic function ResultWithContextE<T, E>(const R: specialize TResult<T, E>;
  const CtxFunc: specialize TResultFunc<E, string>): specialize TResult<T, specialize TErrorCtx<E>>; inline;

{ ResultTranspose - Result<Option<T>,E> -> Option<Result<T,E>>
  Ok(Some(v)) -> Some(Ok(v))
  Ok(None)    -> None
  Err(e)      -> Some(Err(e))
}
generic function ResultTranspose<T, E>(const R: specialize TResult<specialize TOption<T>, E>):
  specialize TOption<specialize TResult<T, E>>;
{$ENDIF FAFAFA_CORE_ANONYMOUS_REFERENCES}

implementation

{ TErrorCtx<E> }

class function TErrorCtx.Create(const AMsg: string; const AInner: E): TErrorCtx;
begin
  Result.Msg := AMsg;
  Result.Inner := AInner;
end;

function TErrorCtx.ToDebugString(const InnerPrinter: specialize TResultFunc<E, string>): string;
begin
  if InnerPrinter = nil then
    Exit(Msg + ' (caused by: ?)');

  Result := Msg + ' (caused by: ' + InnerPrinter(Inner) + ')';
end;

{ TResult<T,E> }

class operator TResult.Initialize(var aRec: TResult);
begin
  // ✅ Phase 4.2 优化：仅初始化标志位，减少不必要的初始化开销
  // 值字段将在 Ok/Err 构造时按需初始化
  aRec.FIsOk := False; // 默认为 Err 状态，防止未初始化的 Ok
  // 注意：FOk 和 FErr 不在此处初始化，由 Ok/Err 构造函数负责
end;

function TResult.GetOkUnchecked: T;
begin
  Result := FOk;
end;

function TResult.GetErrUnchecked: E;
begin
  Result := FErr;
end;

class function TResult.Ok(const AValue: T): TResult;
begin
  // ✅ Phase 4.2 优化：避免 Default(TResult) 调用，直接初始化必要字段
  // 性能提升：减少不必要的 Initialize 操作符调用和 FErr 初始化
  Result.FIsOk := True;
  Result.FOk := AValue;
  Result.FErr := Default(E);  // 仅初始化 FErr 为默认值，避免未定义行为
end;

class function TResult.Err(const AError: E): TResult;
begin
  // ✅ Phase 4.2 优化：避免 Default(TResult) 调用，直接初始化必要字段
  // 性能提升：减少不必要的 Initialize 操作符调用和 FOk 初始化
  Result.FIsOk := False;
  Result.FErr := AError;
  Result.FOk := Default(T);  // 仅初始化 FOk 为默认值，避免未定义行为
end;

function TResult.IsOk: Boolean;
begin
  Result := FIsOk;
end;

function TResult.IsErr: Boolean;
begin
  Result := not FIsOk;
end;

function TResult.Unwrap: T;
begin
  if not FIsOk then
    raise EResultUnwrapError.Create('Unwrap on Err');
  Result := FOk;
end;

function TResult.UnwrapOr(const ADefault: T): T;
begin
  if FIsOk then Result := FOk else Result := ADefault;
end;

function TResult.UnwrapOrElse(const F: specialize TResultThunk<T>): T;
begin
  if FIsOk then
    Exit(FOk);

  if F = nil then
    raise EArgumentNil.Create('aF is nil');

  Result := F();
end;

function TResult.UnwrapOrDefault: T;
begin
  if FIsOk then Result := FOk else Result := Default(T);
end;

function TResult.Expect(const AMsg: string): T;
begin
  if not FIsOk then
    raise EResultUnwrapError.Create(AMsg);
  Result := FOk;
end;

function TResult.UnwrapErr: E;
begin
  if FIsOk then
    raise EResultUnwrapError.Create('UnwrapErr on Ok');
  Result := FErr;
end;

function TResult.ExpectErr(const AMsg: string): E;
begin
  if FIsOk then
    raise EResultUnwrapError.Create(AMsg);
  Result := FErr;
end;

function TResult.TryUnwrap(out AValue: T): Boolean;
begin
  if FIsOk then
  begin
    AValue := FOk;
    Result := True;
  end
  else
  begin
    AValue := Default(T);
    Result := False;
  end;
end;

function TResult.TryUnwrapErr(out AError: E): Boolean;
begin
  if not FIsOk then
  begin
    AError := FErr;
    Result := True;
  end
  else
  begin
    AError := Default(E);
    Result := False;
  end;
end;

function TResult.UnwrapUnchecked: T;
begin
  {$IFDEF DEBUG}
  Assert(FIsOk, 'UnwrapUnchecked called on Err');
  {$ENDIF}
  Result := FOk;
end;

function TResult.UnwrapErrUnchecked: E;
begin
  {$IFDEF DEBUG}
  Assert(not FIsOk, 'UnwrapErrUnchecked called on Ok');
  {$ENDIF}
  Result := FErr;
end;

function TResult.ToString: string;
begin
  if FIsOk then Result := 'Ok' else Result := 'Err';
end;

function TResult.ToString(const OkFormat, ErrFormat: string): string;
begin
  if FIsOk then Result := OkFormat else Result := ErrFormat;
end;

function TResult.ToDebugString(const OkPrinter: specialize TResultFunc<T, string>;
  const ErrPrinter: specialize TResultFunc<E, string>): string;
begin
  if FIsOk then
  begin
    if OkPrinter = nil then
      Exit('Ok(?)');
    Result := 'Ok(' + OkPrinter(FOk) + ')';
  end
  else
  begin
    if ErrPrinter = nil then
      Exit('Err(?)');
    Result := 'Err(' + ErrPrinter(FErr) + ')';
  end;
end;

function TResult.OkOption: TOkOption;
begin
  if FIsOk then
    Result := TOkOption.Some(FOk)
  else
    Result := TOkOption.None;
end;

function TResult.ErrOption: TErrOption;
begin
  if FIsOk then
    Result := TErrOption.None
  else
    Result := TErrOption.Some(FErr);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
{ Collect 实现 }

generic function TryCollectPtrIntoArray<T, E>(const ItemsPtr: Pointer; const Count: SizeUInt;
  var OutValues: specialize TValueArray<T>; out FirstErr: E): Boolean;
var
  I, N: SizeInt;
  P: ^specialize TResult<T, E>;
begin
  // 总是先清空输出
  SetLength(OutValues, 0);
  FirstErr := Default(E);

  if Count > SizeUInt(High(SizeInt)) then
    raise EOutOfRange.Create('Count is out of range');

  N := SizeInt(Count);
  if N = 0 then
    Exit(True);

  if ItemsPtr = nil then
    raise EArgumentNil.Create('ItemsPtr is nil');

  SetLength(OutValues, N);

  P := ItemsPtr;
  for I := 0 to N - 1 do
  begin
    if not P^.IsOk then
    begin
      SetLength(OutValues, 0);
      FirstErr := P^.GetErrUnchecked;
      Exit(False);
    end;
    OutValues[I] := P^.GetOkUnchecked;
    Inc(P);
  end;

  Result := True;
end;

{ TResult 组合子实现 (Global) }

generic function ResultMap<T, E, U>(const R: specialize TResult<T, E>;
  const F: specialize TResultFunc<T, U>): specialize TResult<U, E>;
begin
  if R.IsOk then
  begin
    {$IFDEF DEBUG}
    if F = nil then
      raise EArgumentNil.Create('aF is nil');
    {$ENDIF}
    Result := specialize TResult<U, E>.Ok(F(R.GetOkUnchecked));
  end
  else
    Result := specialize TResult<U, E>.Err(R.GetErrUnchecked);
end;

generic function ResultMapErr<T, E, E2>(const R: specialize TResult<T, E>;
  const F: specialize TResultFunc<E, E2>): specialize TResult<T, E2>;
begin
  if R.IsOk then
    Result := specialize TResult<T, E2>.Ok(R.GetOkUnchecked)
  else
  begin
    {$IFDEF DEBUG}
    if F = nil then
      raise EArgumentNil.Create('aF is nil');
    {$ENDIF}
    Result := specialize TResult<T, E2>.Err(F(R.GetErrUnchecked));
  end;
end;

generic function ResultAndThen<T, E, U>(const R: specialize TResult<T, E>;
  const F: specialize TResultFunc<T, specialize TResult<U, E>>): specialize TResult<U, E>;
begin
  if R.IsOk then
  begin
    {$IFDEF DEBUG}
    if F = nil then
      raise EArgumentNil.Create('aF is nil');
    {$ENDIF}
    Result := F(R.GetOkUnchecked);
  end
  else
    Result := specialize TResult<U, E>.Err(R.GetErrUnchecked);
end;

generic function ResultOrElse<T, E, E2>(const R: specialize TResult<T, E>;
  const F: specialize TResultFunc<E, specialize TResult<T, E2>>): specialize TResult<T, E2>;
begin
  if R.IsOk then
    Result := specialize TResult<T, E2>.Ok(R.GetOkUnchecked)
  else
  begin
    {$IFDEF DEBUG}
    if F = nil then
      raise EArgumentNil.Create('aF is nil');
    {$ENDIF}
    Result := F(R.GetErrUnchecked);
  end;
end;

generic function ResultMapOr<T, E, U>(const R: specialize TResult<T, E>;
  const ADefault: U; const F: specialize TResultFunc<T, U>): U;
begin
  if R.IsOk then
  begin
    {$IFDEF DEBUG}
    if F = nil then
      raise EArgumentNil.Create('aF is nil');
    {$ENDIF}
    Result := F(R.GetOkUnchecked);
  end
  else
    Result := ADefault;
end;

generic function ResultMapOrElse<T, E, U>(const R: specialize TResult<T, E>;
  const Ferr: specialize TResultFunc<E, U>; const Fok: specialize TResultFunc<T, U>): U;
begin
  if R.IsOk then
  begin
    {$IFDEF DEBUG}
    if Fok = nil then
      raise EArgumentNil.Create('aFok is nil');
    {$ENDIF}
    Result := Fok(R.GetOkUnchecked);
  end
  else
  begin
    {$IFDEF DEBUG}
    if Ferr = nil then
      raise EArgumentNil.Create('aFerr is nil');
    {$ENDIF}
    Result := Ferr(R.GetErrUnchecked);
  end;
end;

generic function ResultMatch<T, E, U>(const R: specialize TResult<T, E>;
  const Fok: specialize TResultFunc<T, U>; const Ferr: specialize TResultFunc<E, U>): U;
begin
  if R.IsOk then
  begin
    {$IFDEF DEBUG}
    if Fok = nil then
      raise EArgumentNil.Create('aFok is nil');
    {$ENDIF}
    Result := Fok(R.GetOkUnchecked);
  end
  else
  begin
    {$IFDEF DEBUG}
    if Ferr = nil then
      raise EArgumentNil.Create('aFerr is nil');
    {$ENDIF}
    Result := Ferr(R.GetErrUnchecked);
  end;
end;

generic function ResultFold<T, E, U>(const R: specialize TResult<T, E>;
  const Fok: specialize TResultFunc<T, U>; const Ferr: specialize TResultFunc<E, U>): U;
begin
  Result := specialize ResultMatch<T, E, U>(R, Fok, Ferr);
end;

generic function ResultSwap<T, E>(const R: specialize TResult<T, E>): specialize TResult<E, T>;
begin
  if R.IsOk then
    Result := specialize TResult<E, T>.Err(R.GetOkUnchecked)
  else
    Result := specialize TResult<E, T>.Ok(R.GetErrUnchecked);
end;

generic function ResultFlatten<T, E>(const R: specialize TResult<specialize TResult<T, E>, E>): specialize TResult<T, E>;
begin
  if R.IsOk then
    Result := R.GetOkUnchecked
  else
    Result := specialize TResult<T, E>.Err(R.GetErrUnchecked);
end;

generic function ResultMapBoth<T, E, U, F>(const R: specialize TResult<T, E>;
  const Fok: specialize TResultFunc<T, U>; const Ferr: specialize TResultFunc<E, F>): specialize TResult<U, F>;
begin
  if R.IsOk then
  begin
    {$IFDEF DEBUG}
    if Fok = nil then
      raise EArgumentNil.Create('aFok is nil');
    {$ENDIF}
    Result := specialize TResult<U, F>.Ok(Fok(R.GetOkUnchecked));
  end
  else
  begin
    {$IFDEF DEBUG}
    if Ferr = nil then
      raise EArgumentNil.Create('aFerr is nil');
    {$ENDIF}
    Result := specialize TResult<U, F>.Err(Ferr(R.GetErrUnchecked));
  end;
end;

generic function ResultFilterOrElse<T, E>(const R: specialize TResult<T, E>;
  const Pred: specialize TResultFunc<T, Boolean>;
  const Ferr: specialize TResultFunc<T, E>): specialize TResult<T, E>;
var
  V: T;
begin
  if R.IsOk then
  begin
    {$IFDEF DEBUG}
    if Pred = nil then
      raise EArgumentNil.Create('aPred is nil');
    {$ENDIF}

    V := R.GetOkUnchecked;
    if Pred(V) then
      Result := R
    else
    begin
      {$IFDEF DEBUG}
      if Ferr = nil then
        raise EArgumentNil.Create('aFerr is nil');
      {$ENDIF}
      Result := specialize TResult<T, E>.Err(Ferr(V));
    end;
  end
  else
    Result := R;
end;
{$ENDIF FAFAFA_CORE_ANONYMOUS_REFERENCES}

function TResult.And_(const B: TResult): TResult;
begin
  if FIsOk then Result := B else Result := Self;
end;

function TResult.Or_(const B: TResult): TResult;
begin
  if FIsOk then Result := Self else Result := B;
end;

function TResult.AndResult(const B: TResult): TResult;
begin
  Result := And_(B);
end;

function TResult.OrResult(const B: TResult): TResult;
begin
  Result := Or_(B);
end;

function TResult.OrElseThunk(const F: specialize TResultThunk<TResult>): TResult;
begin
  if FIsOk then
    Exit(Self);

  if F = nil then
    raise EArgumentNil.Create('aF is nil');

  Result := F();
end;

function TResult.Inspect(const F: specialize TResultProc<T>): TResult;
begin
  if IsOk then
  begin
    if F = nil then
      raise EArgumentNil.Create('aF is nil');
    F(GetOkUnchecked);
  end;
  Result := Self;
end;

function TResult.InspectErr(const F: specialize TResultProc<E>): TResult;
begin
  if IsErr then
  begin
    if F = nil then
      raise EArgumentNil.Create('aF is nil');
    F(GetErrUnchecked);
  end;
  Result := Self;
end;

function TResult.IsOkAnd(const Pred: specialize TResultFunc<T, Boolean>): Boolean;
begin
  if IsOk then
  begin
    if Pred = nil then
      raise EArgumentNil.Create('aPred is nil');
    Result := Pred(GetOkUnchecked);
  end
  else
    Result := False;
end;

function TResult.IsErrAnd(const Pred: specialize TResultFunc<E, Boolean>): Boolean;
begin
  if IsErr then
  begin
    if Pred = nil then
      raise EArgumentNil.Create('aPred is nil');
    Result := Pred(GetErrUnchecked);
  end
  else
    Result := False;
end;

function TResult.Contains(const V: T; const Eq: specialize TResultBiPred<T, T>): Boolean;
begin
  if IsOk then
  begin
    if Eq = nil then
      raise EArgumentNil.Create('aEq is nil');
    Result := Eq(GetOkUnchecked, V);
  end
  else
    Result := False;
end;

function TResult.ContainsErr(const EVal: E; const Eq: specialize TResultBiPred<E, E>): Boolean;
begin
  if IsErr then
  begin
    if Eq = nil then
      raise EArgumentNil.Create('aEq is nil');
    Result := Eq(GetErrUnchecked, EVal);
  end
  else
    Result := False;
end;

function TResult.Equals(const Other: TResult; const EqT: specialize TResultBiPred<T, T>;
  const EqE: specialize TResultBiPred<E, E>): Boolean;
begin
  if IsOk and Other.IsOk then
  begin
    if EqT = nil then
      raise EArgumentNil.Create('aEqT is nil');
    Result := EqT(GetOkUnchecked, Other.GetOkUnchecked);
  end
  else if IsErr and Other.IsErr then
  begin
    if EqE = nil then
      raise EArgumentNil.Create('aEqE is nil');
    Result := EqE(GetErrUnchecked, Other.GetErrUnchecked);
  end
  else
    Result := False;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
{ 全局帮助函数实现 }

generic function ResultToTry<T, E>(const R: specialize TResult<T, E>;
  const MapE: specialize TResultFunc<E, Exception>): T;
begin
  if R.IsOk then
    Result := R.GetOkUnchecked
  else
  begin
    if MapE = nil then
      raise EArgumentNil.Create('MapE is nil');
    raise MapE(R.GetErrUnchecked);
  end;
end;

generic function ResultFromTry<T, E>(const Work: specialize TResultThunk<T>;
  const MapEx: specialize TResultFunc<Exception, E>): specialize TResult<T, E>;
begin
  if Work = nil then
    raise EArgumentNil.Create('Work is nil');

  try
    Result := specialize TResult<T, E>.Ok(Work());
  except
    on Ex: Exception do
    begin
      if MapEx = nil then
        raise EArgumentNil.Create('MapEx is nil');
      Result := specialize TResult<T, E>.Err(MapEx(Ex));
    end;
  end;
end;

generic function ResultChain<T, E>(const First, Second: specialize TResult<T, E>): specialize TResult<T, E>;
begin
  if First.IsOk then Result := Second else Result := First;
end;

generic function ResultEnsure<E>(const Cond: Boolean;
  const ErrVal: E): specialize TResult<TUnit, E>;
begin
  if Cond then
    Result := specialize TResult<TUnit, E>.Ok(Default(TUnit))
  else
    Result := specialize TResult<TUnit, E>.Err(ErrVal);
end;

generic function ResultEnsureWith<E>(const Cond: Boolean;
  const ErrThunk: specialize TResultThunk<E>): specialize TResult<TUnit, E>;
begin
  if Cond then
    Result := specialize TResult<TUnit, E>.Ok(Default(TUnit))
  else
  begin
    if ErrThunk = nil then
      raise EArgumentNil.Create('ErrThunk is nil');
    Result := specialize TResult<TUnit, E>.Err(ErrThunk());
  end;
end;

generic function ResultFromBool<T, E>(const Cond: Boolean;
  const OkVal: T; const ErrVal: E): specialize TResult<T, E>;
begin
  if Cond then
    Result := specialize TResult<T, E>.Ok(OkVal)
  else
    Result := specialize TResult<T, E>.Err(ErrVal);
end;

generic function ResultFromOption<T, E>(const O: specialize TOption<T>;
  const ErrVal: E): specialize TResult<T, E>;
begin
  if O.IsSome then
    Result := specialize TResult<T, E>.Ok(O.GetValueUnchecked)
  else
    Result := specialize TResult<T, E>.Err(ErrVal);
end;

generic function ResultFromOptionElse<T, E>(const O: specialize TOption<T>;
  const ErrThunk: specialize TResultThunk<E>): specialize TResult<T, E>;
begin
  if O.IsSome then
    Result := specialize TResult<T, E>.Ok(O.GetValueUnchecked)
  else
  begin
    if ErrThunk = nil then
      raise EArgumentNil.Create('ErrThunk is nil');
    Result := specialize TResult<T, E>.Err(ErrThunk());
  end;
end;

generic function ResultZip<T1, T2, E>(const A: specialize TResult<T1, E>;
  const B: specialize TResult<T2, E>): specialize TResult<specialize TTuple2<T1, T2>, E>;
type
  TTup = specialize TTuple2<T1, T2>;
  TResultTup = specialize TResult<TTup, E>;
var
  P: TTup;
begin
  if A.IsErr then
    Exit(TResultTup.Err(A.GetErrUnchecked));
  if B.IsErr then
    Exit(TResultTup.Err(B.GetErrUnchecked));

  P := TTup.Create(A.GetOkUnchecked, B.GetOkUnchecked);
  Result := TResultTup.Ok(P);
end;

generic function ResultZipWith<T1, T2, E, U>(const A: specialize TResult<T1, E>;
  const B: specialize TResult<T2, E>;
  const F: specialize TResultFunc<specialize TTuple2<T1, T2>, U>): specialize TResult<U, E>;
type
  TTup = specialize TTuple2<T1, T2>;
  TResultU = specialize TResult<U, E>;
var
  P: TTup;
begin
  if A.IsErr then
    Exit(TResultU.Err(A.GetErrUnchecked));
  if B.IsErr then
    Exit(TResultU.Err(B.GetErrUnchecked));

  if F = nil then
    raise EArgumentNil.Create('aF is nil');

  P := TTup.Create(A.GetOkUnchecked, B.GetOkUnchecked);
  Result := TResultU.Ok(F(P));
end;


generic function ResultContext<T, E>(const R: specialize TResult<T, E>;
  const Ctx: string): specialize TResult<T, string>;
begin
  if R.IsOk then
    Exit(specialize TResult<T, string>.Ok(R.GetOkUnchecked))
  else
    Exit(specialize TResult<T, string>.Err(Ctx));
end;

generic function ResultWithContext<T, E>(const R: specialize TResult<T, E>;
  const CtxFunc: specialize TResultFunc<E, string>): specialize TResult<T, string>;
begin
  if R.IsOk then
    Exit(specialize TResult<T, string>.Ok(R.GetOkUnchecked))
  else
  begin
    if CtxFunc = nil then
      raise EArgumentNil.Create('CtxFunc is nil');
    Exit(specialize TResult<T, string>.Err(CtxFunc(R.GetErrUnchecked)));
  end;
end;

generic function ResultContextE<T, E>(const R: specialize TResult<T, E>;
  const Ctx: string): specialize TResult<T, specialize TErrorCtx<E>>;
type
  TErrCtx = specialize TErrorCtx<E>;
  TResultCtx = specialize TResult<T, TErrCtx>;
begin
  if R.IsOk then
    Result := TResultCtx.Ok(R.GetOkUnchecked)
  else
    Result := TResultCtx.Err(TErrCtx.Create(Ctx, R.GetErrUnchecked));
end;

generic function ResultWithContextE<T, E>(const R: specialize TResult<T, E>;
  const CtxFunc: specialize TResultFunc<E, string>): specialize TResult<T, specialize TErrorCtx<E>>;
type
  TErrCtx = specialize TErrorCtx<E>;
  TResultCtx = specialize TResult<T, TErrCtx>;
var
  ErrVal: E;
begin
  if R.IsOk then
    Result := TResultCtx.Ok(R.GetOkUnchecked)
  else
  begin
    if CtxFunc = nil then
      raise EArgumentNil.Create('CtxFunc is nil');

    ErrVal := R.GetErrUnchecked;
    Result := TResultCtx.Err(TErrCtx.Create(CtxFunc(ErrVal), ErrVal));
  end;
end;

generic function ResultTranspose<T, E>(const R: specialize TResult<specialize TOption<T>, E>):
  specialize TOption<specialize TResult<T, E>>;
type
  TInnerOpt = specialize TOption<T>;
  TInnerRes = specialize TResult<T, E>;
  TOutOpt = specialize TOption<TInnerRes>;
var
  OptVal: TInnerOpt;
begin
  if R.IsErr then
    // Err(e) -> Some(Err(e))
    Exit(TOutOpt.Some(TInnerRes.Err(R.GetErrUnchecked)));

  OptVal := R.GetOkUnchecked;
  if OptVal.IsSome then
    // Ok(Some(v)) -> Some(Ok(v))
    Result := TOutOpt.Some(TInnerRes.Ok(OptVal.GetValueUnchecked))
  else
    // Ok(None) -> None
    Result := TOutOpt.None;
end;
{$ENDIF FAFAFA_CORE_ANONYMOUS_REFERENCES}

end.
