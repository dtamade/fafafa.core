unit fafafa.core.result;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils
  {$IFDEF FAFAFA_CORE_RESULT_METHODS}
  , fafafa.core.option
  {$ENDIF}
  ;

type
  EResultUnwrapError = class(Exception);

  generic TResultFunc<TArg, TRes> = reference to function (const Arg: TArg): TRes;
  generic TResultFuncPtr<TArg, TRes> = function (const Arg: TArg): TRes;
  generic TResultProc<TArg> = reference to procedure (const Arg: TArg);
  generic TResultProcPtr<TArg> = procedure (const Arg: TArg);
  // 0参函数类型用于异常桥接
  generic TResultThunk<TRes> = reference to function: TRes;
  generic TResultThunkPtr<TRes> = function: TRes;
  // 二元谓词用于等值比较
  generic TResultBiPred<T1,T2> = reference to function (const A: T1; const B: T2): Boolean;
  generic TResultBiPredPtr<T1,T2> = function (const A: T1; const B: T2): Boolean;


  generic TResult<T,E> = record
  private
    FIsOk: Boolean;
    {$IFDEF FAFAFA_RESULT_VARIANT_LAYOUT}
    {$IFDEF FAFAFA_RESULT_ASSUME_NO_MANAGED}
    case Byte of
      0: (FOk: T);
      1: (FErr: E);
    {$ELSE}
    // Fallback to dual-field when managed types可能存在，避免 RC 错误
      FOk: T;
      FErr: E;
    {$ENDIF}
    {$ELSE}
    FOk: T;
    FErr: E;
    {$ENDIF}
  public
    // 构造
    class function Ok(const AValue: T): TResult; static; inline;
    class function Err(const AError: E): TResult; static; inline;
    // 查询
    function IsOk: Boolean; inline;
    function IsErr: Boolean; inline;
    // 取值

    function Unwrap: T; inline;
    function UnwrapOr(const ADefault: T): T; inline;
    function Expect(const AMsg: string): T; inline;
    function UnwrapErr: E; inline;
    // 辅助
    function ToString: string;
    generic function ToDebugString(const OkPrinter: specialize TResultFunc<T,string>; const ErrPrinter: specialize TResultFunc<E,string>): string; inline; overload;
    generic function ToDebugString(const OkPrinter: specialize TResultFuncPtr<T,string>; const ErrPrinter: specialize TResultFuncPtr<E,string>): string; inline; overload;

    {$IFDEF FAFAFA_CORE_RESULT_METHODS}
    // 方法式（Phase 3 部分）：MapOr/MapOrElse/Inspect/InspectErr/OkOpt/ErrOpt
    generic function MapOr<U>(const ADefault: U; const F: specialize TResultFunc<T,U>): U; inline; overload;
    generic function MapOr<U>(const ADefault: U; const F: specialize TResultFuncPtr<T,U>): U; inline; overload;

    generic function MapOrElse<U>(const Ferr: specialize TResultFunc<E,U>; const Fok: specialize TResultFunc<T,U>): U; inline; overload;
    generic function MapOrElse<U>(const Ferr: specialize TResultFuncPtr<E,U>; const Fok: specialize TResultFuncPtr<T,U>): U; inline; overload;

    function Inspect(const F: specialize TResultProc<T>): TResult; inline; overload;
    function Inspect(const F: specialize TResultProcPtr<T>): TResult; inline; overload;
    function InspectErr(const F: specialize TResultProc<E>): TResult; inline; overload;
    function InspectErr(const F: specialize TResultProcPtr<E>): TResult; inline; overload;

    function OkOpt: specialize TOption<T>; inline;
    function ErrOpt: specialize TOption<E>; inline;
    {$ENDIF}
    // 便捷方法：无异常分支与惰性默认值
    // 补充：Err 路径下抛出包含自定义消息的异常
    function ExpectErr(const AMsg: string): E; inline;

    function TryUnwrap(out AValue: T): Boolean; inline;
    function TryUnwrapErr(out AError: E): Boolean; inline;
    function UnwrapOrElse(const ErrFunc: specialize TResultFunc<E,T>): T; inline; overload;
    function UnwrapOrElse(const ErrFunc: specialize TResultFuncPtr<E,T>): T; inline; overload;

    {$IFDEF FAFAFA_CORE_RESULT_METHODS}
    // 方法式链式 API（Map/MapErr/AndThen/OrElse），内部委托顶层组合子
    generic function Map<U>(const F: specialize TResultFunc<T,U>): specialize TResult<U,E>; inline; overload;
    generic function Map<U>(const F: specialize TResultFuncPtr<T,U>): specialize TResult<U,E>; inline; overload;

    generic function MapErr<E2>(const F: specialize TResultFunc<E,E2>): specialize TResult<T,E2>; inline; overload;
    generic function MapErr<E2>(const F: specialize TResultFuncPtr<E,E2>): specialize TResult<T,E2>; inline; overload;

    generic function AndThen<U>(const F: specialize TResultFunc<T, specialize TResult<U,E>>): specialize TResult<U,E>; inline; overload;
    generic function AndThen<U>(const F: specialize TResultFuncPtr<T, specialize TResult<U,E>>): specialize TResult<U,E>; inline; overload;

    generic function OrElse<E2>(const F: specialize TResultFunc<E, specialize TResult<T,E2>>): specialize TResult<T,E2>; inline; overload;
    generic function OrElse<E2>(const F: specialize TResultFuncPtr<E, specialize TResult<T,E2>>): specialize TResult<T,E2>; inline; overload;
    {$ENDIF}


    {$IFDEF FAFAFA_CORE_RESULT_METHODS}
      // 方法式镜像：And/Or/Contains*/FilterOrElse/ToTry
      function And(const B: TResult): TResult; inline;
      function Or(const B: TResult): TResult; inline;

      generic function Contains(const V: T; const Eq: specialize TResultBiPred<T,T>): Boolean; inline; overload;
      generic function Contains(const V: T; const Eq: specialize TResultBiPredPtr<T,T>): Boolean; inline; overload;
      generic function ContainsErr(const EVal: E; const Eq: specialize TResultBiPred<E,E>): Boolean; inline; overload;
      generic function ContainsErr(const EVal: E; const Eq: specialize TResultBiPredPtr<E,E>): Boolean; inline; overload;

      generic function FilterOrElse(const Pred: specialize TResultFunc<T,Boolean>;
        const Ferr: specialize TResultFunc<T,E>): TResult; inline; overload;
      generic function FilterOrElse(const Pred: specialize TResultFuncPtr<T,Boolean>;
        const Ferr: specialize TResultFuncPtr<T,E>): TResult; inline; overload;

      function ToTry(const MapE: specialize TResultFunc<E,Exception>): T; inline; overload;
      function ToTry(const MapE: specialize TResultFuncPtr<E,Exception>): T; inline; overload;
    {$ENDIF}
  end;


// 顶层组合子（在 interface 区声明导出）
// Map: Ok(T)->Ok(U)  Err(E)->Err(E)
generic function ResultMap<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFunc<T,U>): specialize TResult<U,E>; inline;
// 指针重载
generic function ResultMap<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFuncPtr<T,U>): specialize TResult<U,E>; inline;
// MapErr: Ok(T)->Ok(T)  Err(E)->Err(E2)
generic function ResultMapErr<T,E,E2>(const R: specialize TResult<T,E>; const F: specialize TResultFunc<E,E2>): specialize TResult<T,E2>; inline;
// 指针重载
generic function ResultMapErr<T,E,E2>(const R: specialize TResult<T,E>; const F: specialize TResultFuncPtr<E,E2>): specialize TResult<T,E2>; inline;
// AndThen: Ok(T)->F(T)  Err(E)->Err(E)
generic function ResultAndThen<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFunc<T, specialize TResult<U,E>>): specialize TResult<U,E>; inline;
// 指针重载
generic function ResultAndThen<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFuncPtr<T, specialize TResult<U,E>>): specialize TResult<U,E>; inline;
// OrElse: Ok(T)->Ok(T)  Err(E)->F(E)
generic function ResultOrElse<T,E,E2>(const R: specialize TResult<T,E>; const F: specialize TResultFunc<E, specialize TResult<T,E2>>): specialize TResult<T,E2>; inline;
// 指针重载
generic function ResultOrElse<T,E,E2>(const R: specialize TResult<T,E>; const F: specialize TResultFuncPtr<E, specialize TResult<T,E2>>): specialize TResult<T,E2>; inline;
// MapOr: Ok(T)->F(T):U  Err(E)->Default:U
generic function ResultMapOr<T,E,U>(const R: specialize TResult<T,E>; const ADefault: U; const F: specialize TResultFunc<T,U>): U; inline;
// 指针重载
generic function ResultMapOr<T,E,U>(const R: specialize TResult<T,E>; const ADefault: U; const F: specialize TResultFuncPtr<T,U>): U; inline;
// MapOrElse: Ok(T)->Fok(T):U  Err(E)->Ferr(E):U
generic function ResultMapOrElse<T,E,U>(const R: specialize TResult<T,E>; const Ferr: specialize TResultFunc<E,U>; const Fok: specialize TResultFunc<T,U>): U; inline;
// 指针重载
generic function ResultMapOrElse<T,E,U>(const R: specialize TResult<T,E>; const Ferr: specialize TResultFuncPtr<E,U>; const Fok: specialize TResultFuncPtr<T,U>): U; inline;
// Inspect: Ok 时执行副作用过程，返回原 R
generic function ResultInspect<T,E>(const R: specialize TResult<T,E>; const F: specialize TResultProc<T>): specialize TResult<T,E>; inline;
// 指针重载
generic function ResultInspect<T,E>(const R: specialize TResult<T,E>; const F: specialize TResultProcPtr<T>): specialize TResult<T,E>; inline;
// InspectErr: Err 时执行副作用过程，返回原 R
generic function ResultInspectErr<T,E>(const R: specialize TResult<T,E>; const F: specialize TResultProc<E>): specialize TResult<T,E>; inline;
// 指针重载
generic function ResultInspectErr<T,E>(const R: specialize TResult<T,E>; const F: specialize TResultProcPtr<E>): specialize TResult<T,E>; inline;
// Match/Fold：Ok -> Fok(T):U；Err -> Ferr(E):U
generic function ResultMatch<T,E,U>(const R: specialize TResult<T,E>; const Fok: specialize TResultFunc<T,U>; const Ferr: specialize TResultFunc<E,U>): U; inline;
// 指针重载
generic function ResultMatch<T,E,U>(const R: specialize TResult<T,E>; const Fok: specialize TResultFuncPtr<T,U>; const Ferr: specialize TResultFuncPtr<E,U>): U; inline;
// Fold 为 Match 的别名
generic function ResultFold<T,E,U>(const R: specialize TResult<T,E>; const Fok: specialize TResultFunc<T,U>; const Ferr: specialize TResultFunc<E,U>): U; inline;
// 指针重载
generic function ResultFold<T,E,U>(const R: specialize TResult<T,E>; const Fok: specialize TResultFuncPtr<T,U>; const Ferr: specialize TResultFuncPtr<E,U>): U; inline;
// 扩展组合子：Swap/Flatten/MapBoth
// Swap: Ok(T)->Err(T) Err(E)->Ok(E)
generic function ResultSwap<T,E>(const R: specialize TResult<T,E>): specialize TResult<E,T>; inline;
// Flatten: Result<Result<T,E>,E> -> Result<T,E>
generic function ResultFlatten<T,E>(const R: specialize TResult<specialize TResult<T,E>,E>): specialize TResult<T,E>; inline;
// MapBoth: Ok(T)->Ok(U), Err(E)->Err(F)
generic function ResultMapBoth<T,E,U,F>(const R: specialize TResult<T,E>;
  const Fok: specialize TResultFunc<T,U>;
  const Ferr: specialize TResultFunc<E,F>): specialize TResult<U,F>; inline;
// 指针重载
generic function ResultMapBoth<T,E,U,F>(const R: specialize TResult<T,E>;
  const Fok: specialize TResultFuncPtr<T,U>;
  const Ferr: specialize TResultFuncPtr<E,F>): specialize TResult<U,F>; inline;

  // 新增：非闭包直连组合子 And/Or
  generic function ResultAnd<T,E>(const A, B: specialize TResult<T,E>): specialize TResult<T,E>; inline;
  generic function ResultOr<T,E>(const A, B: specialize TResult<T,E>): specialize TResult<T,E>; inline;
  // 新增：Contains/ContainsErr 判定（带比较器）
  generic function ResultContains<T,E>(const R: specialize TResult<T,E>; const V: T;
    const Eq: specialize TResultBiPred<T,T>): Boolean; inline;
  generic function ResultContains<T,E>(const R: specialize TResult<T,E>; const V: T;
    const Eq: specialize TResultBiPredPtr<T,T>): Boolean; inline;
  generic function ResultContainsErr<T,E>(const R: specialize TResult<T,E>; const EVal: E;
    const Eq: specialize TResultBiPred<E,E>): Boolean; inline;
  generic function ResultContainsErr<T,E>(const R: specialize TResult<T,E>; const EVal: E;
    const Eq: specialize TResultBiPredPtr<E,E>): Boolean; inline;
  // 新增：FilterOrElse（Ok 且谓词假 -> 生成 Err）
  generic function ResultFilterOrElse<T,E>(const R: specialize TResult<T,E>;
    const Pred: specialize TResultFunc<T,Boolean>;
    const Ferr: specialize TResultFunc<T,E>): specialize TResult<T,E>; inline;
  generic function ResultFilterOrElse<T,E>(const R: specialize TResult<T,E>;
    const Pred: specialize TResultFuncPtr<T,Boolean>;
    const Ferr: specialize TResultFuncPtr<T,E>): specialize TResult<T,E>; inline;



  // 等值比较默认重载：依赖 T/E 的 = 运算（当类型支持时可用）
  generic function ResultEquals<T,E>(const A, B: specialize TResult<T,E>): Boolean; inline;

  // ResultToTry：Err -> raise MapE(E)；Ok -> 返回 T
  generic function ResultToTry<T,E>(const R: specialize TResult<T,E>; const MapE: specialize TResultFunc<E,Exception>): T; inline;
  generic function ResultToTry<T,E>(const R: specialize TResult<T,E>; const MapE: specialize TResultFuncPtr<E,Exception>): T; inline;

// 谓词辅助：与 Rust is_ok_and / is_err_and 等价
generic function ResultIsOkAnd<T,E>(const R: specialize TResult<T,E>; const Pred: specialize TResultFunc<T,Boolean>): Boolean;
// 指针重载
generic function ResultIsOkAnd<T,E>(const R: specialize TResult<T,E>; const Pred: specialize TResultFuncPtr<T,Boolean>): Boolean;
// is_err_and（同时提供引用与指针重载）
generic function ResultIsErrAnd<T,E>(const R: specialize TResult<T,E>; const Pred: specialize TResultFunc<E,Boolean>): Boolean;
// 指针重载
generic function ResultIsErrAnd<T,E>(const R: specialize TResult<T,E>; const Pred: specialize TResultFuncPtr<E,Boolean>): Boolean;

// 异常桥接：从可能抛异常的工作流生成 Result
// Work: ()->T；MapEx: Exception->E
generic function ResultFromTry<T,E>(const Work: specialize TResultThunk<T>; const MapEx: specialize TResultFunc<Exception,E>): specialize TResult<T,E>;
// 指针重载
generic function ResultFromTry<T,E>(const Work: specialize TResultThunkPtr<T>; const MapEx: specialize TResultFuncPtr<Exception,E>): specialize TResult<T,E>;

// 等值比较：通过外部比较器提供语义
// 返回 True 当且仅当：
//  - 两者均 Ok 且 EqT(Ok1,Ok2)=True；或
//  - 两者均 Err 且 EqE(Err1,Err2)=True
// 否则 False。
generic function ResultEquals<T,E>(const A, B: specialize TResult<T,E>;
  const EqT: specialize TResultBiPred<T,T>; const EqE: specialize TResultBiPred<E,E>): Boolean;
// 指针重载
generic function ResultEquals<T,E>(const A, B: specialize TResult<T,E>;
  const EqT: specialize TResultBiPredPtr<T,T>; const EqE: specialize TResultBiPredPtr<E,E>): Boolean;



implementation

{ TResult<T,E> }



// 内部无检查访问器实现（仅本单元使用）


class function TResult.Ok(const AValue: T): TResult;
begin
  Initialize(Result);
  Result.FIsOk := True;
  Result.FOk := AValue;
end;

class function TResult.Err(const AError: E): TResult;
begin
  Initialize(Result);
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
  Exit(FOk);
end;

function TResult.UnwrapOr(const ADefault: T): T;
begin


  if FIsOk then Exit(FOk) else Exit(ADefault);
end;

function TResult.Expect(const AMsg: string): T;
begin
  if not FIsOk then
    raise EResultUnwrapError.Create(AMsg);
  Exit(FOk);
end;



function TResult.UnwrapErr: E;
begin
  if FIsOk then
    raise EResultUnwrapError.Create('UnwrapErr on Ok');
  Exit(FErr);
end;

function TResult.ToString: string;
begin
  if FIsOk then
    Result := 'Ok'
  else
    Result := 'Err';

end;


function TResult.ToDebugString(const OkPrinter: specialize TResultFunc<T,string>; const ErrPrinter: specialize TResultFunc<E,string>): string;
begin
  if FIsOk then
  begin
    if Assigned(OkPrinter) then
      Result := 'Ok(' + OkPrinter(FOk) + ')'
    else
      Result := 'Ok';
  end
  else
  begin
    if Assigned(ErrPrinter) then
      Result := 'Err(' + ErrPrinter(FErr) + ')'
    else
      Result := 'Err';
  end;
end;



{$IFDEF FAFAFA_CORE_RESULT_METHODS}
// 方法式镜像实现：And/Or/Contains*/FilterOrElse/ToTry

generic function TResult<T,E>.And(const B: TResult): TResult;
begin
  Exit(specialize ResultAnd<T,E>(Self, B));
end;

generic function TResult<T,E>.Or(const B: TResult): TResult;
begin
  Exit(specialize ResultOr<T,E>(Self, B));
end;

generic function TResult<T,E>.Contains(const V: T; const Eq: specialize TResultBiPred<T,T>): Boolean;
begin
  Exit(specialize ResultContains<T,E>(Self, V, Eq));
end;

generic function TResult<T,E>.Contains(const V: T; const Eq: specialize TResultBiPredPtr<T,T>): Boolean;
begin
  Exit(specialize ResultContains<T,E>(Self, V, Eq));
end;

generic function TResult<T,E>.ContainsErr(const EVal: E; const Eq: specialize TResultBiPred<E,E>): Boolean;
begin
  Exit(specialize ResultContainsErr<T,E>(Self, EVal, Eq));
end;

generic function TResult<T,E>.ContainsErr(const EVal: E; const Eq: specialize TResultBiPredPtr<E,E>): Boolean;
begin
  Exit(specialize ResultContainsErr<T,E>(Self, EVal, Eq));
end;

generic function TResult<T,E>.FilterOrElse(const Pred: specialize TResultFunc<T,Boolean>;
  const Ferr: specialize TResultFunc<T,E>): TResult;
begin
  Exit(specialize ResultFilterOrElse<T,E>(Self, Pred, Ferr));
end;

generic function TResult<T,E>.FilterOrElse(const Pred: specialize TResultFuncPtr<T,Boolean>;
  const Ferr: specialize TResultFuncPtr<T,E>): TResult;
begin
  Exit(specialize ResultFilterOrElse<T,E>(Self, Pred, Ferr));
end;

function TResult<T,E>.ToTry(const MapE: specialize TResultFunc<E,Exception>): T;
begin
  Exit(specialize ResultToTry<T,E>(Self, MapE));
end;

function TResult<T,E>.ToTry(const MapE: specialize TResultFuncPtr<E,Exception>): T;
begin
  Exit(specialize ResultToTry<T,E>(Self, MapE));
end;
{$ENDIF}



function TResult.ToDebugString(const OkPrinter: specialize TResultFuncPtr<T,string>; const ErrPrinter: specialize TResultFuncPtr<E,string>): string;
begin
  if FIsOk then
  begin
    if Assigned(OkPrinter) then
      Result := 'Ok(' + OkPrinter(FOk) + ')'
    else
      Result := 'Ok';
  end
  else
  begin
    if Assigned(ErrPrinter) then
      Result := 'Err(' + ErrPrinter(FErr) + ')'
    else
      Result := 'Err';
  end;
{$IFDEF FAFAFA_CORE_RESULT_METHODS}
// 方法式链式 API 实现（Map/MapErr/AndThen/OrElse/MapOr/MapOrElse/Inspect/InspectErr/OkOpt/ErrOpt）

generic function TResult<T,E>.Map<U>(const F: specialize TResultFunc<T,U>): specialize TResult<U,E>;
begin
  Exit(specialize ResultMap<T,E,U>(Self, F));
end;

generic function TResult<T,E>.Map<U>(const F: specialize TResultFuncPtr<T,U>): specialize TResult<U,E>;
begin
  Exit(specialize ResultMap<T,E,U>(Self, F));
end;

generic function TResult<T,E>.MapErr<E2>(const F: specialize TResultFunc<E,E2>): specialize TResult<T,E2>;
begin
  Exit(specialize ResultMapErr<T,E,E2>(Self, F));
end;

generic function TResult<T,E>.MapErr<E2>(const F: specialize TResultFuncPtr<E,E2>): specialize TResult<T,E2>;
begin
  Exit(specialize ResultMapErr<T,E,E2>(Self, F));
end;

generic function TResult<T,E>.AndThen<U>(const F: specialize TResultFunc<T, specialize TResult<U,E>>): specialize TResult<U,E>;
begin
  Exit(specialize ResultAndThen<T,E,U>(Self, F));
end;
// 方法式（Phase 3）的实现：MapOr/MapOrElse/Inspect/InspectErr/OkOpt/ErrOpt

generic function TResult<T,E>.MapOr<U>(const ADefault: U; const F: specialize TResultFunc<T,U>): U;
begin
  Exit(specialize ResultMapOr<T,E,U>(Self, ADefault, F));
end;

generic function TResult<T,E>.MapOr<U>(const ADefault: U; const F: specialize TResultFuncPtr<T,U>): U;
begin
  Exit(specialize ResultMapOr<T,E,U>(Self, ADefault, F));
end;

generic function TResult<T,E>.MapOrElse<U>(const Ferr: specialize TResultFunc<E,U>; const Fok: specialize TResultFunc<T,U>): U;
begin
  Exit(specialize ResultMapOrElse<T,E,U>(Self, Ferr, Fok));
end;

generic function TResult<T,E>.MapOrElse<U>(const Ferr: specialize TResultFuncPtr<E,U>; const Fok: specialize TResultFuncPtr<T,U>): U;
begin
  Exit(specialize ResultMapOrElse<T,E,U>(Self, Ferr, Fok));
end;

function TResult<T,E>.Inspect(const F: specialize TResultProc<T>): TResult;
begin
  Exit(specialize ResultInspect<T,E>(Self, F));
end;

function TResult<T,E>.Inspect(const F: specialize TResultProcPtr<T>): TResult;
begin
  Exit(specialize ResultInspect<T,E>(Self, F));
end;

function TResult<T,E>.InspectErr(const F: specialize TResultProc<E>): TResult;
begin
  Exit(specialize ResultInspectErr<T,E>(Self, F));
end;

function TResult<T,E>.InspectErr(const F: specialize TResultProcPtr<E>): TResult;
begin
  Exit(specialize ResultInspectErr<T,E>(Self, F));
end;

function TResult<T,E>.OkOpt: specialize TOption<T>;
begin
  if FIsOk then Exit(specialize TOption<T>.Some(FOk)) else Exit(specialize TOption<T>.None);
end;

function TResult<T,E>.ErrOpt: specialize TOption<E>;
begin
  if FIsOk then Exit(specialize TOption<E>.None) else Exit(specialize TOption<E>.Some(FErr));
end;
{$ENDIF}


{$IFDEF FAFAFA_CORE_RESULT_METHODS}


generic function TResult<T,E>.AndThen<U>(const F: specialize TResultFuncPtr<T, specialize TResult<U,E>>): specialize TResult<U,E>;
begin
  Exit(specialize ResultAndThen<T,E,U>(Self, F));
end;

generic function TResult<T,E>.OrElse<E2>(const F: specialize TResultFunc<E, specialize TResult<T,E2>>): specialize TResult<T,E2>;
begin
  Exit(specialize ResultOrElse<T,E,E2>(Self, F));
end;

generic function TResult<T,E>.OrElse<E2>(const F: specialize TResultFuncPtr<E, specialize TResult<T,E2>>): specialize TResult<T,E2>;
begin
  Exit(specialize ResultOrElse<T,E,E2>(Self, F));
end;
{$ENDIF}

function TResult<T,E>.ExpectErr(const AMsg: string): E;
begin
  if FIsOk then raise EResultUnwrapError.Create('ExpectErr on Ok: ' + AMsg)
  else Exit(FErr);
end;

function TResult<T,E>.TryUnwrap(out AValue: T): Boolean;
begin
  if FIsOk then begin AValue := FOk; Exit(True); end



  else begin Initialize(AValue); Exit(False); end;
end;

function TResult<T,E>.TryUnwrapErr(out AError: E): Boolean;
begin
  if not FIsOk then begin AError := FErr; Exit(True); end
  else begin Initialize(AError); Exit(False); end;
end;

function TResult<T,E>.UnwrapOrElse(const ErrFunc: specialize TResultFunc<E,T>): T;
begin
  if FIsOk then Exit(FOk) else Exit(ErrFunc(FErr));
end;

function TResult<T,E>.UnwrapOrElse(const ErrFunc: specialize TResultFuncPtr<E,T>): T;
begin
  if FIsOk then Exit(FOk) else Exit(ErrFunc(FErr));
end;


// 顶层组合子实现



generic function ResultMap<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFunc<T,U>): specialize TResult<U,E>;
begin
  if R.IsOk then
    Exit(specialize TResult<U,E>.Ok(F(R.Unwrap)))
  else
    Exit(specialize TResult<U,E>.Err(R.UnwrapErr));
end;

generic function ResultMap<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFuncPtr<T,U>): specialize TResult<U,E>;
begin
  if R.IsOk then
    Exit(specialize TResult<U,E>.Ok(F(R.Unwrap)))
  else
    Exit(specialize TResult<U,E>.Err(R.UnwrapErr));
end;

generic function ResultMapErr<T,E,E2>(const R: specialize TResult<T,E>; const F: specialize TResultFunc<E,E2>): specialize TResult<T,E2>;
begin
  if R.IsOk then
    Exit(specialize TResult<T,E2>.Ok(R.Unwrap))
  else
    Exit(specialize TResult<T,E2>.Err(F(R.UnwrapErr)));
end;

generic function ResultMapErr<T,E,E2>(const R: specialize TResult<T,E>; const F: specialize TResultFuncPtr<E,E2>): specialize TResult<T,E2>;
begin
  if R.IsOk then
    Exit(specialize TResult<T,E2>.Ok(R.Unwrap))
  else
    Exit(specialize TResult<T,E2>.Err(F(R.UnwrapErr)));
end;

generic function ResultAndThen<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFunc<T, specialize TResult<U,E>>): specialize TResult<U,E>;
begin
  if R.IsOk then
    Exit(F(R.Unwrap))
  else
    Exit(specialize TResult<U,E>.Err(R.UnwrapErr));
end;

generic function ResultAndThen<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFuncPtr<T, specialize TResult<U,E>>): specialize TResult<U,E>;
begin
  if R.IsOk then
    Exit(F(R.Unwrap))
  else
    Exit(specialize TResult<U,E>.Err(R.UnwrapErr));
end;

generic function ResultOrElse<T,E,E2>(const R: specialize TResult<T,E>; const F: specialize TResultFunc<E, specialize TResult<T,E2>>): specialize TResult<T,E2>;
begin
  if R.IsOk then
    Exit(specialize TResult<T,E2>.Ok(R.Unwrap))
  else
    Exit(F(R.UnwrapErr));
end;

generic function ResultOrElse<T,E,E2>(const R: specialize TResult<T,E>; const F: specialize TResultFuncPtr<E, specialize TResult<T,E2>>): specialize TResult<T,E2>;
begin
  if R.IsOk then
    Exit(specialize TResult<T,E2>.Ok(R.Unwrap))
  else
    Exit(F(R.UnwrapErr));
end;

// 新组合子：MapOr（Ok->f(T):U, Err->Default:U）
generic function ResultMapOr<T,E,U>(const R: specialize TResult<T,E>; const ADefault: U; const F: specialize TResultFunc<T,U>): U;
begin
  if R.IsOk then Exit(F(R.Unwrap)) else Exit(ADefault);
end;

// 指针重载实现
generic function ResultMapOr<T,E,U>(const R: specialize TResult<T,E>; const ADefault: U; const F: specialize TResultFuncPtr<T,U>): U;
begin
  if R.IsOk then Exit(F(R.Unwrap)) else Exit(ADefault);
end;


// 新组合子：MapOrElse（Ok->fok(T):U, Err->ferr(E):U）
generic function ResultMapOrElse<T,E,U>(const R: specialize TResult<T,E>; const Ferr: specialize TResultFunc<E,U>; const Fok: specialize TResultFunc<T,U>): U;
begin
  if R.IsOk then Exit(Fok(R.Unwrap)) else Exit(Ferr(R.UnwrapErr));
end;

// 指针重载实现
generic function ResultMapOrElse<T,E,U>(const R: specialize TResult<T,E>; const Ferr: specialize TResultFuncPtr<E,U>; const Fok: specialize TResultFuncPtr<T,U>): U;
begin
  if R.IsOk then Exit(Fok(R.Unwrap)) else Exit(Ferr(R.UnwrapErr));
end;


// ResultMatch/ResultFold 实现
generic function ResultMatch<T,E,U>(const R: specialize TResult<T,E>; const Fok: specialize TResultFunc<T,U>; const Ferr: specialize TResultFunc<E,U>): U;
begin
  if R.IsOk then Exit(Fok(R.Unwrap)) else Exit(Ferr(R.UnwrapErr));
end;

generic function ResultMatch<T,E,U>(const R: specialize TResult<T,E>; const Fok: specialize TResultFuncPtr<T,U>; const Ferr: specialize TResultFuncPtr<E,U>): U;
begin
  if R.IsOk then Exit(Fok(R.Unwrap)) else Exit(Ferr(R.UnwrapErr));
end;

generic function ResultFold<T,E,U>(const R: specialize TResult<T,E>; const Fok: specialize TResultFunc<T,U>; const Ferr: specialize TResultFunc<E,U>): U;
begin
  Exit(specialize ResultMatch<T,E,U>(R, Fok, Ferr));
end;

generic function ResultFold<T,E,U>(const R: specialize TResult<T,E>; const Fok: specialize TResultFuncPtr<T,U>; const Ferr: specialize TResultFuncPtr<E,U>): U;
begin
  Exit(specialize ResultMatch<T,E,U>(R, Fok, Ferr));
end;

// is_ok_and / is_err_and

generic function ResultIsOkAnd<T,E>(const R: specialize TResult<T,E>; const Pred: specialize TResultFunc<T,Boolean>): Boolean;
begin
  if R.IsOk then Exit(Pred(R.Unwrap)) else Exit(False);
end;

generic function ResultIsOkAnd<T,E>(const R: specialize TResult<T,E>; const Pred: specialize TResultFuncPtr<T,Boolean>): Boolean;
begin
  if R.IsOk then Exit(Pred(R.Unwrap)) else Exit(False);
end;

generic function ResultIsErrAnd<T,E>(const R: specialize TResult<T,E>; const Pred: specialize TResultFunc<E,Boolean>): Boolean;
begin
  if R.IsErr then Exit(Pred(R.UnwrapErr)) else Exit(False);
end;

generic function ResultIsErrAnd<T,E>(const R: specialize TResult<T,E>; const Pred: specialize TResultFuncPtr<E,Boolean>): Boolean;
begin
  if R.IsErr then Exit(Pred(R.UnwrapErr)) else Exit(False);
end;
// ResultFromTry 实现

generic function ResultFromTry<T,E>(const Work: specialize TResultThunk<T>; const MapEx: specialize TResultFunc<Exception,E>): specialize TResult<T,E>;
begin
  try
    Exit(specialize TResult<T,E>.Ok(Work()));
  except
    on Ex: Exception do
      Exit(specialize TResult<T,E>.Err(MapEx(Ex)));
  end;
end;

generic function ResultFromTry<T,E>(const Work: specialize TResultThunkPtr<T>; const MapEx: specialize TResultFuncPtr<Exception,E>): specialize TResult<T,E>;
begin
  try
    Exit(specialize TResult<T,E>.Ok(Work()));
  except
    on Ex: Exception do
      Exit(specialize TResult<T,E>.Err(MapEx(Ex)));
  end;
end;

generic function ResultEquals<T,E>(const A, B: specialize TResult<T,E>;
  const EqT: specialize TResultBiPred<T,T>; const EqE: specialize TResultBiPred<E,E>): Boolean;
begin
  if A.IsOk and B.IsOk then Exit(EqT(A.Unwrap, B.Unwrap))
  else if A.IsErr and B.IsErr then Exit(EqE(A.UnwrapErr, B.UnwrapErr))
  else Exit(False);
end;

generic function ResultEquals<T,E>(const A, B: specialize TResult<T,E>;
  const EqT: specialize TResultBiPredPtr<T,T>; const EqE: specialize TResultBiPredPtr<E,E>): Boolean;
begin
  if A.IsOk and B.IsOk then Exit(EqT(A.Unwrap, B.Unwrap))
  else if A.IsErr and B.IsErr then Exit(EqE(A.UnwrapErr, B.UnwrapErr))
  else Exit(False);
end;



// 扩展组合子实现
// Swap: Ok(T)->Err(T) Err(E)->Ok(E)
generic function ResultSwap<T,E>(const R: specialize TResult<T,E>): specialize TResult<E,T>;
begin
  if R.IsOk then Exit(specialize TResult<E,T>.Err(R.Unwrap))
  else Exit(specialize TResult<E,T>.Ok(R.UnwrapErr));
end;

// Flatten: Result<Result<T,E>,E> -> Result<T,E>
generic function ResultFlatten<T,E>(const R: specialize TResult<specialize TResult<T,E>,E>): specialize TResult<T,E>;
var Inner: specialize TResult<T,E>;
begin
  if R.IsOk then
  begin
    Inner := R.Unwrap;
    Exit(Inner);
  end
  else
    Exit(specialize TResult<T,E>.Err(R.UnwrapErr));
end;

// 新增：And/Or 实现

generic function ResultAnd<T,E>(const A, B: specialize TResult<T,E>): specialize TResult<T,E>;
begin
  if A.IsOk then Exit(B) else Exit(specialize TResult<T,E>.Err(A.UnwrapErr));
end;

generic function ResultOr<T,E>(const A, B: specialize TResult<T,E>): specialize TResult<T,E>;
begin
  if A.IsOk then Exit(A) else Exit(B);
end;

// 新增：Contains/ContainsErr 实现

generic function ResultContains<T,E>(const R: specialize TResult<T,E>; const V: T;
  const Eq: specialize TResultBiPred<T,T>): Boolean;
begin
  if R.IsOk then Exit(Eq(R.Unwrap, V)) else Exit(False);
end;

generic function ResultContains<T,E>(const R: specialize TResult<T,E>; const V: T;
  const Eq: specialize TResultBiPredPtr<T,T>): Boolean;
begin
  if R.IsOk then Exit(Eq(R.Unwrap, V)) else Exit(False);
end;

generic function ResultContainsErr<T,E>(const R: specialize TResult<T,E>; const EVal: E;
  const Eq: specialize TResultBiPred<E,E>): Boolean;
begin
  if R.IsErr then Exit(Eq(R.UnwrapErr, EVal)) else Exit(False);
end;

generic function ResultContainsErr<T,E>(const R: specialize TResult<T,E>; const EVal: E;
  const Eq: specialize TResultBiPredPtr<E,E>): Boolean;
begin
  if R.IsErr then Exit(Eq(R.UnwrapErr, EVal)) else Exit(False);
end;

// 新增：FilterOrElse 实现

generic function ResultFilterOrElse<T,E>(const R: specialize TResult<T,E>;
  const Pred: specialize TResultFunc<T,Boolean>;
  const Ferr: specialize TResultFunc<T,E>): specialize TResult<T,E>;
begin
  if R.IsOk then
  begin
    if Pred(R.Unwrap) then Exit(R)
    else Exit(specialize TResult<T,E>.Err(Ferr(R.Unwrap)));
  end
  else Exit(R);
end;

// 等值比较默认实现（当 T/E 支持 = 运算时）

// 等值比较默认实现（当 T/E 支持 = 运算时）

generic function ResultEquals<T,E>(const A, B: specialize TResult<T,E>): Boolean;
begin
  if A.IsOk and B.IsOk then Exit(A.Unwrap = B.Unwrap)
  else if A.IsErr and B.IsErr then Exit(A.UnwrapErr = B.UnwrapErr)
  else Exit(False);
end;

// ResultToTry 实现

generic function ResultToTry<T,E>(const R: specialize TResult<T,E>; const MapE: specialize TResultFunc<E,Exception>): T;
begin
  if R.IsOk then Exit(R.Unwrap)
  else raise MapE(R.UnwrapErr);
end;

generic function ResultToTry<T,E>(const R: specialize TResult<T,E>; const MapE: specialize TResultFuncPtr<E,Exception>): T;
begin
  if R.IsOk then Exit(R.Unwrap)
  else raise MapE(R.UnwrapErr);
end;

generic function ResultFilterOrElse<T,E>(const R: specialize TResult<T,E>;
  const Pred: specialize TResultFuncPtr<T,Boolean>;
  const Ferr: specialize TResultFuncPtr<T,E>): specialize TResult<T,E>;
begin
  if R.IsOk then
  begin
    if Pred(R.Unwrap) then Exit(R)
    else Exit(specialize TResult<T,E>.Err(Ferr(R.Unwrap)));
  end
  else Exit(R);
end;

{ Note: removed an old duplicate of ResultFlatten for clarity }

// MapBoth: Ok(T)->Ok(U), Err(E)->Err(F)
generic function ResultMapBoth<T,E,U,F>(const R: specialize TResult<T,E>;
  const Fok: specialize TResultFunc<T,U>;
  const Ferr: specialize TResultFunc<E,F>): specialize TResult<U,F>;
begin
  if R.IsOk then Exit(specialize TResult<U,F>.Ok(Fok(R.Unwrap)))
  else Exit(specialize TResult<U,F>.Err(Ferr(R.UnwrapErr)));
end;

generic function ResultMapBoth<T,E,U,F>(const R: specialize TResult<T,E>;
  const Fok: specialize TResultFuncPtr<T,U>;
  const Ferr: specialize TResultFuncPtr<E,F>): specialize TResult<U,F>;
begin
  if R.IsOk then Exit(specialize TResult<U,F>.Ok(Fok(R.Unwrap)))
  else Exit(specialize TResult<U,F>.Err(Ferr(R.UnwrapErr)));
end;




// 新组合子：Inspect（Ok 时调用副作用过程，返回原 Result）
generic function ResultInspect<T,E>(const R: specialize TResult<T,E>; const F: specialize TResultProc<T>): specialize TResult<T,E>;
begin
  if R.IsOk then
  begin
    if Assigned(@F) then F(R.Unwrap);
    Exit(R);
  end
  else
    Exit(R);
end;

// 指针重载实现
generic function ResultInspect<T,E>(const R: specialize TResult<T,E>; const F: specialize TResultProcPtr<T>): specialize TResult<T,E>;
begin
  if R.IsOk then
  begin
    if Assigned(@F) then F(R.Unwrap);
    Exit(R);
  end
  else
    Exit(R);
end;

// 新组合子：InspectErr（Err 时调用副作用过程，返回原 Result）
generic function ResultInspectErr<T,E>(const R: specialize TResult<T,E>; const F: specialize TResultProc<E>): specialize TResult<T,E>;
begin
  if R.IsErr then
  begin
    if Assigned(@F) then F(R.UnwrapErr);
    Exit(R);
  end
  else
    Exit(R);
end;

// 指针重载实现
generic function ResultInspectErr<T,E>(const R: specialize TResult<T,E>; const F: specialize TResultProcPtr<E>): specialize TResult<T,E>;
begin
  if R.IsErr then
  begin
    if Assigned(@F) then F(R.UnwrapErr);
    Exit(R);
  end
  else
    Exit(R);
end;



end.

