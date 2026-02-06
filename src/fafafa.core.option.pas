unit fafafa.core.option;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{**
 * fafafa.core.option - Option 类型组合子扩展
 *
 * @desc
 *   基于 fafafa.core.option.base 的 TOption<T> 核心定义，提供丰富的函数式组合子和类型转换功能。
 *   Extends TOption<T> from fafafa.core.option.base with rich functional combinators and type conversion utilities.
 *
 * @design_philosophy
 *   Option 类型用于显式表达"值可能不存在"的语义，避免 nil 指针和空值检查的陷阱。
 *   Option type explicitly expresses "value may not exist" semantics, avoiding nil pointer and null check pitfalls.
 *
 * @core_concepts
 *   1. **Some(T)**: 包含值的 Option
 *   2. **None**: 不包含值的 Option
 *   3. **组合子**: 函数式操作，如 Map、Filter、AndThen
 *   4. **类型转换**: 与 Result 类型的互转
 *
 * @usage_patterns
 *   // 1. 基础构造
 *   var Opt: specialize TOption<Integer>;
 *   Opt := specialize TOption<Integer>.Some(42);
 *   Opt := specialize TOption<Integer>.None;
 *
 *   // 2. Map 转换（Some(T) -> Some(U)）
 *   function DoubleIt(const N: Integer): Integer;
 *   begin
 *     Result := N * 2;
 *   end;
 *   var Doubled: specialize TOption<Integer>;
 *   Doubled := OptionMap(Opt, @DoubleIt);  // Some(42) -> Some(84)
 *
 *   // 3. Filter 过滤（Some(T) -> Some(T) or None）
 *   function IsEven(const N: Integer): Boolean;
 *   begin
 *     Result := (N mod 2) = 0;
 *   end;
 *   var Filtered: specialize TOption<Integer>;
 *   Filtered := OptionFilter(Opt, @IsEven);  // Some(42) -> Some(42)
 *
 *   // 4. AndThen 链式操作（Some(T) -> Option<U>）
 *   function SafeDivide(const N: Integer): specialize TOption<Integer>;
 *   begin
 *     if N = 0 then
 *       Exit(specialize TOption<Integer>.None);
 *     Result := specialize TOption<Integer>.Some(100 div N);
 *   end;
 *   var Divided: specialize TOption<Integer>;
 *   Divided := OptionAndThen(Opt, @SafeDivide);
 *
 *   // 5. 与 Result 互转
 *   var Res: specialize TResult<Integer, string>;
 *   Res := OptionToResult(Opt, 'Value not found');  // Some(42) -> Ok(42)
 *
 * @combinators
 *   - **Map**: 转换 Some 中的值，None 保持不变
 *   - **AndThen**: 链式操作，可能返回 None
 *   - **Filter**: 根据谓词过滤，不满足返回 None
 *   - **MapOr**: 提供默认值的 Map
 *   - **MapOrElse**: 提供默认值生成函数的 Map
 *   - **Flatten**: 展平嵌套的 Option<Option<T>>
 *   - **Zip**: 组合两个 Option 为元组
 *   - **ZipWith**: 组合两个 Option 并应用函数
 *
 * @conversions
 *   - **OptionToResult**: Option<T> -> Result<T, E>
 *   - **ResultToOption**: Result<T, E> -> Option<T>
 *   - **ResultErrOption**: Result<T, E> -> Option<E>
 *   - **Transpose**: Result<Option<T>, E> <-> Option<Result<T, E>>
 *
 * @best_practices
 *   1. 优先使用 Option 而非 nil 指针
 *   2. 使用组合子链式操作，避免嵌套 if
 *   3. 使用 UnwrapOr 提供默认值，避免异常
 *   4. 使用 AndThen 处理可能失败的操作链
 *
 * @see fafafa.core.option.base, fafafa.core.result, TOption, TResult
 *}

interface

uses
  SysUtils,
  fafafa.core.base,              // TTuple2 类型定义
  fafafa.core.option.base,       // TOption<T> 核心定义
  fafafa.core.result;

const
  {** 模块版本 | Module version *}
  FAFAFA_CORE_OPTION_VERSION = '1.0.0';

// 顶层组合子（Option）
// Map: Some(T)->Some(U)  None->None
generic function OptionMap<T,U>(const aO: specialize TOption<T>; const aF: specialize TOptionFunc<T,U>): specialize TOption<U>; inline;
// AndThen: Some(T)->F(T)  None->None
generic function OptionAndThen<T,U>(const aO: specialize TOption<T>; const aF: specialize TOptionFunc<T, specialize TOption<U>>): specialize TOption<U>; inline;
// MapOr: Some(T)->F(T):U  None->Default:U
generic function OptionMapOr<T,U>(const aO: specialize TOption<T>; const aDefault: U; const aF: specialize TOptionFunc<T,U>): U; inline;
// MapOrElse: Some(T)->Fok(T):U  None->Fnone():U
generic function OptionMapOrElse<T,U>(const aO: specialize TOption<T>; const aFnone: specialize TOptionThunk<U>; const aFok: specialize TOptionFunc<T,U>): U; inline;
// Filter: Some(T)&Pred(T)->Some(T) else None
generic function OptionFilter<T>(const aO: specialize TOption<T>; const aPred: specialize TOptionFunc<T,Boolean>): specialize TOption<T>; inline;

// Flatten: Option<Option<T>> -> Option<T>
generic function OptionFlatten<T>(const aO: specialize TOption<specialize TOption<T>>): specialize TOption<T>; inline;

// Zip: (Some(T), Some(U)) -> Some((T,U))  else None
// 使用 fafafa.core.base 中的 TTuple2 类型

generic function OptionZip<T, U>(const aA: specialize TOption<T>; const aB: specialize TOption<U>): specialize TOption<specialize TTuple2<T, U>>; inline;

// ZipWith: (Some(T), Some(U)) -> Some(F(T,U))  else None
generic function OptionZipWith<T, U, R>(const aA: specialize TOption<T>; const aB: specialize TOption<U>;
  const aF: specialize TOptionFunc<specialize TTuple2<T, U>, R>): specialize TOption<R>; inline;

// 与 Result 互转
// Some(T) -> Ok(T)；None -> Err(E)
generic function OptionToResult<T,E>(const aO: specialize TOption<T>; const aErr: E): specialize TResult<T,E>;
// Some(T) -> Ok(T)；None -> FerrThunk():Err(E)
generic function OptionToResultElse<T,E>(const aO: specialize TOption<T>; const aFerrThunk: specialize TOptionThunk<E>): specialize TResult<T,E>;
// Ok(T) -> Some(T)；Err(E) -> None
generic function ResultToOption<T,E>(const aR: specialize TResult<T,E>): specialize TOption<T>;
// Err(E) -> Some(E)；Ok(T) -> None
generic function ResultErrOption<T,E>(const aR: specialize TResult<T,E>): specialize TOption<E>;

  // Transpose：Result<Option<T>,E> <-> Option<Result<T,E>>
  generic function ResultTransposeOption<T,E>(const aR: specialize TResult<specialize TOption<T>,E>): specialize TOption< specialize TResult<T,E> >;
  generic function OptionTransposeResult<T,E>(const aO: specialize TOption< specialize TResult<T,E> >): specialize TResult< specialize TOption<T>, E>;


// FromNullable 家族
// 1) 从布尔条件
generic function OptionFromBool<T>(aB: Boolean; const aWhenTrue: T): specialize TOption<T>;
// 2) 从字符串（TreatEmptyAsNone=True 表示空串视为 None）
function OptionFromString(const aStr: string; const aTreatEmptyAsNone: Boolean = True): specialize TOption<string>;
// 3) 通用聚合（已知 HasValue）
generic function OptionFromValue<T>(aHasValue: Boolean; const aValue: T): specialize TOption<T>;
// 4) 从 IInterface（nil -> None）
function OptionFromInterface(const aV: IInterface): specialize TOption<IInterface>;

implementation

{ 全局组合子实现 }

generic function OptionMap<T,U>(const aO: specialize TOption<T>; const aF: specialize TOptionFunc<T,U>): specialize TOption<U>; inline;
begin
  if aO.IsSome then
  begin
    {$IFDEF FAFAFA_CORE_CONTRACTS}
    // 契约：启用合约检查时，禁止 nil 回调
    if aF = nil then
      raise EArgumentNil.Create('aF is nil');
    {$ENDIF}
    Exit(specialize TOption<U>.Some(aF(aO.GetValueUnchecked)));
  end;

  Result := specialize TOption<U>.None;
end;

generic function OptionAndThen<T,U>(const aO: specialize TOption<T>; const aF: specialize TOptionFunc<T, specialize TOption<U>>): specialize TOption<U>; inline;
begin
  if aO.IsSome then
  begin
    {$IFDEF FAFAFA_CORE_CONTRACTS}
    // 契约：启用合约检查时，禁止 nil 回调
    if aF = nil then
      raise EArgumentNil.Create('aF is nil');
    {$ENDIF}
    Exit(aF(aO.GetValueUnchecked));
  end;

  Result := specialize TOption<U>.None;
end;

generic function OptionMapOr<T,U>(const aO: specialize TOption<T>; const aDefault: U; const aF: specialize TOptionFunc<T,U>): U; inline;
begin
  if aO.IsSome then
  begin
    {$IFDEF FAFAFA_CORE_CONTRACTS}
    // 契约：启用合约检查时，禁止 nil 回调
    if aF = nil then
      raise EArgumentNil.Create('aF is nil');
    {$ENDIF}
    Exit(aF(aO.GetValueUnchecked));
  end;

  Result := aDefault;
end;

generic function OptionMapOrElse<T,U>(const aO: specialize TOption<T>; const aFnone: specialize TOptionThunk<U>; const aFok: specialize TOptionFunc<T,U>): U; inline;
begin
  if aO.IsSome then
  begin
    {$IFDEF FAFAFA_CORE_CONTRACTS}
    // 契约：启用合约检查时，禁止 nil 回调
    if aFok = nil then
      raise EArgumentNil.Create('aFok is nil');
    {$ENDIF}
    Exit(aFok(aO.GetValueUnchecked));
  end;

  {$IFDEF FAFAFA_CORE_CONTRACTS}
  // 契约：启用合约检查时，禁止 nil 回调
  if aFnone = nil then
    raise EArgumentNil.Create('aFnone is nil');
  {$ENDIF}

  Result := aFnone();
end;

generic function OptionFilter<T>(const aO: specialize TOption<T>; const aPred: specialize TOptionFunc<T,Boolean>): specialize TOption<T>; inline;
begin
  if aO.IsSome then
  begin
    {$IFDEF FAFAFA_CORE_CONTRACTS}
    // 契约：启用合约检查时，禁止 nil 回调
    if aPred = nil then
      raise EArgumentNil.Create('aPred is nil');
    {$ENDIF}

    if aPred(aO.GetValueUnchecked) then
      Exit(aO);
  end;

  Result := specialize TOption<T>.None;
end;

generic function OptionFlatten<T>(const aO: specialize TOption<specialize TOption<T>>): specialize TOption<T>; inline;
begin
  if aO.IsSome then
    Result := aO.GetValueUnchecked  // ✅ OPT: 避免双重检查
  else
    Result := specialize TOption<T>.None;
end;

generic function OptionZip<T, U>(const aA: specialize TOption<T>; const aB: specialize TOption<U>): specialize TOption<specialize TTuple2<T, U>>; inline;
type
  TResultTuple = specialize TTuple2<T, U>;
  TResultOption = specialize TOption<TResultTuple>;
var
  P: TResultTuple;
begin
  if aA.IsSome and aB.IsSome then
  begin
    P.First := aA.GetValueUnchecked;   // ✅ OPT: 避免双重检查
    P.Second := aB.GetValueUnchecked;  // ✅ OPT: 避免双重检查
    Result := TResultOption.Some(P);
  end
  else
    Result := TResultOption.None;
end;

generic function OptionZipWith<T, U, R>(const aA: specialize TOption<T>; const aB: specialize TOption<U>;
  const aF: specialize TOptionFunc<specialize TTuple2<T, U>, R>): specialize TOption<R>; inline;
type
  TTupleTU = specialize TTuple2<T, U>;
var
  P: TTupleTU;
begin
  if aA.IsSome and aB.IsSome then
  begin
    {$IFDEF FAFAFA_CORE_CONTRACTS}
    // 契约：启用合约检查时，禁止 nil 回调
    if aF = nil then
      raise EArgumentNil.Create('aF is nil');
    {$ENDIF}

    P.First := aA.GetValueUnchecked;
    P.Second := aB.GetValueUnchecked;
    Result := specialize TOption<R>.Some(aF(P));
  end
  else
    Result := specialize TOption<R>.None;
end;

generic function OptionToResult<T,E>(const aO: specialize TOption<T>; const aErr: E): specialize TResult<T,E>;
begin
  if aO.IsSome then Exit(specialize TResult<T,E>.Ok(aO.GetValueUnchecked))  // ✅ OPT
  else Exit(specialize TResult<T,E>.Err(aErr));
end;

generic function OptionToResultElse<T,E>(const aO: specialize TOption<T>; const aFerrThunk: specialize TOptionThunk<E>): specialize TResult<T,E>;
begin
  if aO.IsSome then
    Exit(specialize TResult<T,E>.Ok(aO.GetValueUnchecked));

  {$IFDEF FAFAFA_CORE_CONTRACTS}
  // 契约：启用合约检查时，禁止 nil 回调
  if aFerrThunk = nil then
    raise EArgumentNil.Create('aFerrThunk is nil');
  {$ENDIF}

  Result := specialize TResult<T,E>.Err(aFerrThunk());
end;

generic function ResultToOption<T,E>(const aR: specialize TResult<T,E>): specialize TOption<T>;
begin
  if aR.IsOk then Exit(specialize TOption<T>.Some(aR.GetOkUnchecked))  // ✅ OPT
  else Exit(specialize TOption<T>.None);
end;

// Transpose 实现

generic function ResultTransposeOption<T,E>(const aR: specialize TResult<specialize TOption<T>,E>): specialize TOption< specialize TResult<T,E> >;
begin
  if aR.IsOk then
  begin
    if aR.GetOkUnchecked.IsSome then  // ✅ OPT
      Exit(specialize TOption< specialize TResult<T,E> >.Some(specialize TResult<T,E>.Ok(aR.GetOkUnchecked.GetValueUnchecked)))
    else
      Exit(specialize TOption< specialize TResult<T,E> >.None);
  end
  else
    Exit(specialize TOption< specialize TResult<T,E> >.Some(specialize TResult<T,E>.Err(aR.GetErrUnchecked)));  // ✅ OPT
end;

generic function OptionTransposeResult<T,E>(const aO: specialize TOption< specialize TResult<T,E> >): specialize TResult< specialize TOption<T>, E>;
var
  Inner: specialize TResult<T,E>;
begin
  if aO.IsSome then
  begin
    Inner := aO.GetValueUnchecked;  // ✅ OPT
    if Inner.IsOk then
      Exit(specialize TResult< specialize TOption<T>, E>.Ok(specialize TOption<T>.Some(Inner.GetOkUnchecked)))
    else
      Exit(specialize TResult< specialize TOption<T>, E>.Err(Inner.GetErrUnchecked));
  end
  else
    Exit(specialize TResult< specialize TOption<T>, E>.Ok(specialize TOption<T>.None));
end;


generic function ResultErrOption<T,E>(const aR: specialize TResult<T,E>): specialize TOption<E>;
begin
  if aR.IsErr then Exit(specialize TOption<E>.Some(aR.GetErrUnchecked))  // ✅ OPT
  else Exit(specialize TOption<E>.None);
end;

// FromNullable 实现

generic function OptionFromBool<T>(aB: Boolean; const aWhenTrue: T): specialize TOption<T>;
begin
  if aB then Exit(specialize TOption<T>.Some(aWhenTrue)) else Exit(specialize TOption<T>.None);
end;

function OptionFromString(const aStr: string; const aTreatEmptyAsNone: Boolean): specialize TOption<string>;
begin
  if (not aTreatEmptyAsNone) or (aStr <> '') then
    Exit(specialize TOption<string>.Some(aStr))
  else
    Exit(specialize TOption<string>.None);
end;

generic function OptionFromValue<T>(aHasValue: Boolean; const aValue: T): specialize TOption<T>;
begin
  if aHasValue then Exit(specialize TOption<T>.Some(aValue)) else Exit(specialize TOption<T>.None);
end;

function OptionFromInterface(const aV: IInterface): specialize TOption<IInterface>;
begin
  if aV <> nil then Exit(specialize TOption<IInterface>.Some(aV)) else Exit(specialize TOption<IInterface>.None);
end;

end.
