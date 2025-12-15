unit fafafa.core.result;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.option.base;

type
  EResultUnwrapError = class(Exception);

  { 函数类型定义 - 统一使用 reference to }
  generic TResultFunc<TArg, TRes> = reference to function(const Arg: TArg): TRes;
  generic TResultProc<TArg> = reference to procedure(const Arg: TArg);
  generic TResultThunk<TRes> = reference to function: TRes;
  generic TResultBiPred<T1, T2> = reference to function(const A: T1; const B: T2): Boolean;

  { TValueArray<T> - 动态数组别名（用于 collect/sequence 输出） }
  generic TValueArray<T> = array of T;

  { TUnit - 单元类型（无有效返回值）
    用于 ensure 等仅关注错误路径的 API。
  }
  TUnit = record
  end;

  { TTuple2<TFirst, TSecond> - 二元元组
    用于 zip 等组合子返回值，字段命名为 First/Second。
  }
  generic TTuple2<TFirst, TSecond> = record
    First: TFirst;
    Second: TSecond;
    class function Create(const AFirst: TFirst; const ASecond: TSecond): TTuple2; static; inline;
  end;

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

{ 全局组合子 - 需要改变泛型类型的操作 }
{ 由于 FPC 不支持在泛型记录中定义泛型方法，这些必须作为全局函数存在 }

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

implementation

uses
  fafafa.core.base;

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

{ TTuple2<TFirst, TSecond> }

class function TTuple2.Create(const AFirst: TFirst; const ASecond: TSecond): TTuple2;
begin
  Result.First := AFirst;
  Result.Second := ASecond;
end;

{ TResult<T,E> }

class operator TResult.Initialize(var aRec: TResult);
begin
  aRec.FIsOk := False; // 默认为 Err 状态，防止未初始化的 Ok
  aRec.FOk := Default(T);
  aRec.FErr := Default(E);
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
  Result := Default(TResult);
  Result.FIsOk := True;
  Result.FOk := AValue;
end;

class function TResult.Err(const AError: E): TResult;
begin
  Result := Default(TResult);
  Result.FIsOk := False;
  Result.FErr := AError;
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
    raise EArgumentNil.Create('F is nil');

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
    if F = nil then
      raise EArgumentNil.Create('F is nil');
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
    if F = nil then
      raise EArgumentNil.Create('F is nil');
    Result := specialize TResult<T, E2>.Err(F(R.GetErrUnchecked));
  end;
end;

generic function ResultAndThen<T, E, U>(const R: specialize TResult<T, E>;
  const F: specialize TResultFunc<T, specialize TResult<U, E>>): specialize TResult<U, E>;
begin
  if R.IsOk then
  begin
    if F = nil then
      raise EArgumentNil.Create('F is nil');
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
    if F = nil then
      raise EArgumentNil.Create('F is nil');
    Result := F(R.GetErrUnchecked);
  end;
end;

generic function ResultMapOr<T, E, U>(const R: specialize TResult<T, E>;
  const ADefault: U; const F: specialize TResultFunc<T, U>): U;
begin
  if R.IsOk then
  begin
    if F = nil then
      raise EArgumentNil.Create('F is nil');
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
    if Fok = nil then
      raise EArgumentNil.Create('Fok is nil');
    Result := Fok(R.GetOkUnchecked);
  end
  else
  begin
    if Ferr = nil then
      raise EArgumentNil.Create('Ferr is nil');
    Result := Ferr(R.GetErrUnchecked);
  end;
end;

generic function ResultMatch<T, E, U>(const R: specialize TResult<T, E>;
  const Fok: specialize TResultFunc<T, U>; const Ferr: specialize TResultFunc<E, U>): U;
begin
  if R.IsOk then
  begin
    if Fok = nil then
      raise EArgumentNil.Create('Fok is nil');
    Result := Fok(R.GetOkUnchecked);
  end
  else
  begin
    if Ferr = nil then
      raise EArgumentNil.Create('Ferr is nil');
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
    if Fok = nil then
      raise EArgumentNil.Create('Fok is nil');
    Result := specialize TResult<U, F>.Ok(Fok(R.GetOkUnchecked));
  end
  else
  begin
    if Ferr = nil then
      raise EArgumentNil.Create('Ferr is nil');
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
    if Pred = nil then
      raise EArgumentNil.Create('Pred is nil');

    V := R.GetOkUnchecked;
    if Pred(V) then
      Result := R
    else
    begin
      if Ferr = nil then
        raise EArgumentNil.Create('Ferr is nil');
      Result := specialize TResult<T, E>.Err(Ferr(V));
    end;
  end
  else
    Result := R;
end;

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
    raise EArgumentNil.Create('F is nil');

  Result := F();
end;

function TResult.Inspect(const F: specialize TResultProc<T>): TResult;
begin
  if IsOk then
  begin
    if F = nil then
      raise EArgumentNil.Create('F is nil');
    F(GetOkUnchecked);
  end;
  Result := Self;
end;

function TResult.InspectErr(const F: specialize TResultProc<E>): TResult;
begin
  if IsErr then
  begin
    if F = nil then
      raise EArgumentNil.Create('F is nil');
    F(GetErrUnchecked);
  end;
  Result := Self;
end;

function TResult.IsOkAnd(const Pred: specialize TResultFunc<T, Boolean>): Boolean;
begin
  if IsOk then
  begin
    if Pred = nil then
      raise EArgumentNil.Create('Pred is nil');
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
      raise EArgumentNil.Create('Pred is nil');
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
      raise EArgumentNil.Create('Eq is nil');
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
      raise EArgumentNil.Create('Eq is nil');
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
      raise EArgumentNil.Create('EqT is nil');
    Result := EqT(GetOkUnchecked, Other.GetOkUnchecked);
  end
  else if IsErr and Other.IsErr then
  begin
    if EqE = nil then
      raise EArgumentNil.Create('EqE is nil');
    Result := EqE(GetErrUnchecked, Other.GetErrUnchecked);
  end
  else
    Result := False;
end;

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
    raise EArgumentNil.Create('F is nil');

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

end.
