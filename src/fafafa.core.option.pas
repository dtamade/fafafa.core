unit fafafa.core.option;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.result;

type
  generic TOptionFunc<TArg, TRes> = reference to function (const Arg: TArg): TRes;
  generic TOptionProc<TArg> = reference to procedure (const Arg: TArg);
  generic TOptionThunk<TResult> = reference to function: TResult;

  generic TOption<T> = record
  private
    FHas: Boolean;
    FValue: T;
  public
    // 构造
    class function Some(const AValue: T): TOption; static; inline;
    class function None: TOption; static; inline;

    // 查询
    function IsSome: Boolean; inline;
    function IsNone: Boolean; inline;

    // 取值
    function Unwrap: T; inline;              // None -> EOptionUnwrapError
    function UnwrapOr(const ADefault: T): T; inline;

    // 组合子（方法仅保留 Inspect/ToDebugString；Map/AndThen 以顶层组合子提供）
    function Inspect(const F: specialize TOptionProc<T>): TOption; inline;
    function ToDebugString(const Printer: specialize TOptionFunc<T,string>): string; inline;
  end;

  EOptionUnwrapError = class(Exception);

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

{ TOption<T> }

class function TOption.Some(const AValue: T): TOption;
begin
  Result.FHas := True;
  Result.FValue := AValue;
end;

class function TOption.None: TOption;
begin
  Result.FHas := False;
end;

function TOption.IsSome: Boolean;
begin
  Result := FHas;
end;

function TOption.IsNone: Boolean;
begin
  Result := not FHas;
end;

function TOption.Unwrap: T;
begin
  if not FHas then raise EOptionUnwrapError.Create('Unwrap on None');
  Exit(FValue);
end;

function TOption.UnwrapOr(const ADefault: T): T;
begin
  if FHas then Exit(FValue) else Exit(ADefault);
end;

// 顶层组合子实现

generic function OptionMap<T,U>(const O: specialize TOption<T>; const F: specialize TOptionFunc<T,U>): specialize TOption<U>;
begin
  if O.IsSome then
    Exit(specialize TOption<U>.Some(F(O.Unwrap)))
  else
    Exit(specialize TOption<U>.None);
end;

generic function OptionAndThen<T,U>(const O: specialize TOption<T>; const F: specialize TOptionFunc<T, specialize TOption<U>>): specialize TOption<U>;
begin
  if O.IsSome then
    Exit(F(O.Unwrap))
  else
    Exit(specialize TOption<U>.None);
end;

generic function OptionMapOr<T,U>(const O: specialize TOption<T>; const ADefault: U; const F: specialize TOptionFunc<T,U>): U;
begin
  if O.IsSome then Exit(F(O.Unwrap)) else Exit(ADefault);
end;

generic function OptionMapOrElse<T,U>(const O: specialize TOption<T>; const Fnone: specialize TOptionThunk<U>; const Fok: specialize TOptionFunc<T,U>): U;
begin
  if O.IsSome then Exit(Fok(O.Unwrap)) else Exit(Fnone());
end;

generic function OptionFilter<T>(const O: specialize TOption<T>; const Pred: specialize TOptionFunc<T,Boolean>): specialize TOption<T>;
begin
  if O.IsSome and Pred(O.Unwrap) then Exit(O) else Exit(specialize TOption<T>.None);
end;

function TOption.Inspect(const F: specialize TOptionProc<T>): TOption;
begin
  if FHas and Assigned(@F) then F(FValue);
  Exit(Self);
end;

function TOption.ToDebugString(const Printer: specialize TOptionFunc<T,string>): string;
begin
  if FHas then
  begin
    if Assigned(Printer) then
      Result := 'Some(' + Printer(FValue) + ')'
    else
      Result := 'Some';
  end
  else
    Result := 'None';
end;

generic function OptionToResult<T,E>(const O: specialize TOption<T>; const Err: E): specialize TResult<T,E>;
begin
  if O.IsSome then Exit(specialize TResult<T,E>.Ok(O.Unwrap))
  else Exit(specialize TResult<T,E>.Err(Err));
end;

generic function OptionToResultElse<T,E>(const O: specialize TOption<T>; const FerrThunk: specialize TOptionThunk<E>): specialize TResult<T,E>;
begin
  if O.IsSome then Exit(specialize TResult<T,E>.Ok(O.Unwrap))
  else Exit(specialize TResult<T,E>.Err(FerrThunk()));
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

