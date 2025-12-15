unit fafafa.core.option;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.option - Option 类型组合子扩展

  此模块基于 fafafa.core.option.base 提供的 TOption<T> 核心定义，
  扩展更多全局组合子函数和与 Result 的互转功能。

  用法：
    uses fafafa.core.option.base, fafafa.core.option;

  TOption<T> 核心类型定义位于 fafafa.core.option.base 模块。
}

interface

uses
  SysUtils,
  fafafa.core.option.base,  // TOption<T> 核心定义
  fafafa.core.result;

// 顶层组合子（Option）
// Map: Some(T)->Some(U)  None->None
generic function OptionMap<T,U>(const O: specialize TOption<T>; const F: specialize TOptionFunc<T,U>): specialize TOption<U>;
// AndThen: Some(T)->F(T)  None->None
generic function OptionAndThen<T,U>(const O: specialize TOption<T>; const F: specialize TOptionFunc<T, specialize TOption<U>>): specialize TOption<U>;
// MapOr: Some(T)->F(T):U  None->Default:U
generic function OptionMapOr<T,U>(const O: specialize TOption<T>; const ADefault: U; const F: specialize TOptionFunc<T,U>): U;
// MapOrElse: Some(T)->Fok(T):U  None->Fnone():U
generic function OptionMapOrElse<T,U>(const O: specialize TOption<T>; const Fnone: specialize TOptionThunk<U>; const Fok: specialize TOptionFunc<T,U>): U;
// Filter: Some(T)&Pred(T)->Some(T) else None
generic function OptionFilter<T>(const O: specialize TOption<T>; const Pred: specialize TOptionFunc<T,Boolean>): specialize TOption<T>;

// Flatten: Option<Option<T>> -> Option<T>
generic function OptionFlatten<T>(const O: specialize TOption<specialize TOption<T>>): specialize TOption<T>;

// Zip: (Some(T), Some(U)) -> Some((T,U))  else None
// 返回 TPair 记录，包含 First 和 Second 字段
type
  generic TPair<TFirst, TSecond> = record
    First: TFirst;
    Second: TSecond;
  end;

generic function OptionZip<T, U>(const A: specialize TOption<T>; const B: specialize TOption<U>): specialize TOption<specialize TPair<T, U>>;

// ZipWith: (Some(T), Some(U)) -> Some(F(T,U))  else None
generic function OptionZipWith<T, U, R>(const A: specialize TOption<T>; const B: specialize TOption<U>;
  const F: specialize TOptionFunc<specialize TPair<T, U>, R>): specialize TOption<R>;

// 与 Result 互转
// Some(T) -> Ok(T)；None -> Err(E)
generic function OptionToResult<T,E>(const O: specialize TOption<T>; const Err: E): specialize TResult<T,E>;
// Some(T) -> Ok(T)；None -> FerrThunk():Err(E)
generic function OptionToResultElse<T,E>(const O: specialize TOption<T>; const FerrThunk: specialize TOptionThunk<E>): specialize TResult<T,E>;
// Ok(T) -> Some(T)；Err(E) -> None
generic function ResultToOption<T,E>(const R: specialize TResult<T,E>): specialize TOption<T>;
// Err(E) -> Some(E)；Ok(T) -> None
generic function ResultErrOption<T,E>(const R: specialize TResult<T,E>): specialize TOption<E>;

  // Transpose：Result<Option<T>,E> <-> Option<Result<T,E>>
  generic function ResultTransposeOption<T,E>(const R: specialize TResult<specialize TOption<T>,E>): specialize TOption< specialize TResult<T,E> >;
  generic function OptionTransposeResult<T,E>(const O: specialize TOption< specialize TResult<T,E> >): specialize TResult< specialize TOption<T>, E>;


// FromNullable 家族
// 1) 从布尔条件
generic function OptionFromBool<T>(B: Boolean; const WhenTrue: T): specialize TOption<T>;
// 2) 从字符串（TreatEmptyAsNone=True 表示空串视为 None）
function OptionFromString(const S: string; const TreatEmptyAsNone: Boolean = True): specialize TOption<string>;
// 3) 通用聚合（已知 HasValue）
generic function OptionFromValue<T>(HasValue: Boolean; const Value: T): specialize TOption<T>;
// 4) 从 IInterface（nil -> None）
function OptionFromInterface(const V: IInterface): specialize TOption<IInterface>;

implementation

uses
  fafafa.core.base;

{ 全局组合子实现 }

generic function OptionMap<T,U>(const O: specialize TOption<T>; const F: specialize TOptionFunc<T,U>): specialize TOption<U>;
begin
  if O.IsSome then
  begin
    if F = nil then
      raise EArgumentNil.Create('F is nil');
    Exit(specialize TOption<U>.Some(F(O.GetValueUnchecked)));
  end;

  Result := specialize TOption<U>.None;
end;

generic function OptionAndThen<T,U>(const O: specialize TOption<T>; const F: specialize TOptionFunc<T, specialize TOption<U>>): specialize TOption<U>;
begin
  if O.IsSome then
  begin
    if F = nil then
      raise EArgumentNil.Create('F is nil');
    Exit(F(O.GetValueUnchecked));
  end;

  Result := specialize TOption<U>.None;
end;

generic function OptionMapOr<T,U>(const O: specialize TOption<T>; const ADefault: U; const F: specialize TOptionFunc<T,U>): U;
begin
  if O.IsSome then
  begin
    if F = nil then
      raise EArgumentNil.Create('F is nil');
    Exit(F(O.GetValueUnchecked));
  end;

  Result := ADefault;
end;

generic function OptionMapOrElse<T,U>(const O: specialize TOption<T>; const Fnone: specialize TOptionThunk<U>; const Fok: specialize TOptionFunc<T,U>): U;
begin
  if O.IsSome then
  begin
    if Fok = nil then
      raise EArgumentNil.Create('Fok is nil');
    Exit(Fok(O.GetValueUnchecked));
  end;

  if Fnone = nil then
    raise EArgumentNil.Create('Fnone is nil');

  Result := Fnone();
end;

generic function OptionFilter<T>(const O: specialize TOption<T>; const Pred: specialize TOptionFunc<T,Boolean>): specialize TOption<T>;
begin
  if O.IsSome then
  begin
    if Pred = nil then
      raise EArgumentNil.Create('Pred is nil');

    if Pred(O.GetValueUnchecked) then
      Exit(O);
  end;

  Result := specialize TOption<T>.None;
end;

generic function OptionFlatten<T>(const O: specialize TOption<specialize TOption<T>>): specialize TOption<T>;
begin
  if O.IsSome then
    Result := O.Unwrap
  else
    Result := specialize TOption<T>.None;
end;

generic function OptionZip<T, U>(const A: specialize TOption<T>; const B: specialize TOption<U>): specialize TOption<specialize TPair<T, U>>;
type
  TResultPair = specialize TPair<T, U>;
  TResultOption = specialize TOption<TResultPair>;
var
  P: TResultPair;
begin
  if A.IsSome and B.IsSome then
  begin
    P.First := A.Unwrap;
    P.Second := B.Unwrap;
    Result := TResultOption.Some(P);
  end
  else
    Result := TResultOption.None;
end;

generic function OptionZipWith<T, U, R>(const A: specialize TOption<T>; const B: specialize TOption<U>;
  const F: specialize TOptionFunc<specialize TPair<T, U>, R>): specialize TOption<R>;
type
  TPairTU = specialize TPair<T, U>;
var
  P: TPairTU;
begin
  if A.IsSome and B.IsSome then
  begin
    if F = nil then
      raise EArgumentNil.Create('F is nil');

    P.First := A.GetValueUnchecked;
    P.Second := B.GetValueUnchecked;
    Result := specialize TOption<R>.Some(F(P));
  end
  else
    Result := specialize TOption<R>.None;
end;

generic function OptionToResult<T,E>(const O: specialize TOption<T>; const Err: E): specialize TResult<T,E>;
begin
  if O.IsSome then Exit(specialize TResult<T,E>.Ok(O.Unwrap))
  else Exit(specialize TResult<T,E>.Err(Err));
end;

generic function OptionToResultElse<T,E>(const O: specialize TOption<T>; const FerrThunk: specialize TOptionThunk<E>): specialize TResult<T,E>;
begin
  if O.IsSome then
    Exit(specialize TResult<T,E>.Ok(O.GetValueUnchecked));

  if FerrThunk = nil then
    raise EArgumentNil.Create('FerrThunk is nil');

  Result := specialize TResult<T,E>.Err(FerrThunk());
end;

generic function ResultToOption<T,E>(const R: specialize TResult<T,E>): specialize TOption<T>;
begin
  if R.IsOk then Exit(specialize TOption<T>.Some(R.Unwrap)) else Exit(specialize TOption<T>.None);
end;

// Transpose 实现

generic function ResultTransposeOption<T,E>(const R: specialize TResult<specialize TOption<T>,E>): specialize TOption< specialize TResult<T,E> >;
begin
  if R.IsOk then
  begin
    if R.Unwrap.IsSome then Exit(specialize TOption< specialize TResult<T,E> >.Some(specialize TResult<T,E>.Ok(R.Unwrap.Unwrap)))
    else Exit(specialize TOption< specialize TResult<T,E> >.None);
  end
  else
    Exit(specialize TOption< specialize TResult<T,E> >.Some(specialize TResult<T,E>.Err(R.UnwrapErr)));
end;

generic function OptionTransposeResult<T,E>(const O: specialize TOption< specialize TResult<T,E> >): specialize TResult< specialize TOption<T>, E>;
begin
  if O.IsSome then
  begin
    if O.Unwrap.IsOk then Exit(specialize TResult< specialize TOption<T>, E>.Ok(specialize TOption<T>.Some(O.Unwrap.Unwrap)))
    else Exit(specialize TResult< specialize TOption<T>, E>.Err(O.Unwrap.UnwrapErr));
  end
  else
    Exit(specialize TResult< specialize TOption<T>, E>.Ok(specialize TOption<T>.None));
end;


generic function ResultErrOption<T,E>(const R: specialize TResult<T,E>): specialize TOption<E>;
begin
  if R.IsErr then Exit(specialize TOption<E>.Some(R.UnwrapErr)) else Exit(specialize TOption<E>.None);
end;

// FromNullable 实现

generic function OptionFromBool<T>(B: Boolean; const WhenTrue: T): specialize TOption<T>;
begin
  if B then Exit(specialize TOption<T>.Some(WhenTrue)) else Exit(specialize TOption<T>.None);
end;

function OptionFromString(const S: string; const TreatEmptyAsNone: Boolean): specialize TOption<string>;
begin
  if (not TreatEmptyAsNone) or (S <> '') then
    Exit(specialize TOption<string>.Some(S))
  else
    Exit(specialize TOption<string>.None);
end;

generic function OptionFromValue<T>(HasValue: Boolean; const Value: T): specialize TOption<T>;
begin
  if HasValue then Exit(specialize TOption<T>.Some(Value)) else Exit(specialize TOption<T>.None);
end;

function OptionFromInterface(const V: IInterface): specialize TOption<IInterface>;
begin
  if V <> nil then Exit(specialize TOption<IInterface>.Some(V)) else Exit(specialize TOption<IInterface>.None);
end;

end.

