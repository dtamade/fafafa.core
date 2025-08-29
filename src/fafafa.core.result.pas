unit fafafa.core.result;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Variants, TypInfo
  // 注意：移除对 fafafa.core.option 的直接依赖以解决循环依赖
  // Option 相关功能将通过前向声明和延迟绑定实现
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

  // 类型约束接口
  IResultComparable = interface
    ['{B8F3A4C2-1D5E-4F6A-9B8C-3E7F2A1D4C5B}']
    function CompareTo(const Other: IResultComparable): Integer;
    function Equals(const Other: IResultComparable): Boolean;
  end;

  IResultSerializable = interface
    ['{C9E4B5D3-2E6F-5A7B-AC9D-4F8A3B2E5D6C}']
    function Serialize: string;
    procedure Deserialize(const Data: string);
  end;

  IResultCloneable = interface
    ['{DA05C6E4-3F70-6B8C-BD0E-5A9B4C3F6E7D}']
    function Clone: IResultCloneable;
  end;

  // Iterator 风格操作需要的类型
  generic TArray<T> = array of T;
  generic TResultArray<T> = array of T;

  // 为解决 FreePascal 泛型返回类型限制，定义具体的类型别名
  TIntegerArray = array of Integer;
  TStringArray = array of String;
  TBooleanArray = array of Boolean;

  // 为解决 FreePascal 函数参数类型限制，定义具体的类型别名将在 TResult 定义后添加

  // 批量操作结果类型
  generic TPartitionResult<T,E> = record
    Oks: array of T;
    Errs: array of E;
  end;

  // 前向声明：Option 类型（避免循环依赖）
  generic TOption<T> = record
  private
    FHas: Boolean;
    FValue: T;
  public
    class function Some(const AValue: T): TOption; static; inline;
    class function None: TOption; static; inline;
    function IsSome: Boolean; inline;
    function IsNone: Boolean; inline;
    function Unwrap: T; inline;
  end;


  { TResult<T,E> - 零成本错误处理类型

    内存布局选择：
    - 默认：双字段布局 (FIsOk + FOk + FErr) - 安全，支持所有类型
    - 可选：变体布局 (FIsOk + variant record) - 节省内存，仅限非受管类型

    启用变体布局的条件：
    1. 定义 FAFAFA_RESULT_VARIANT_LAYOUT 宏
    2. 确保 T 和 E 都是非受管类型（Integer, Boolean, record 等）
    3. 可选：定义 FAFAFA_RESULT_ASSUME_NO_MANAGED 跳过运行时检查

    内存占用对比（64位）：
    - 双字段：SizeOf(Boolean) + SizeOf(T) + SizeOf(E) + 对齐填充
    - 变体：SizeOf(Boolean) + Max(SizeOf(T), SizeOf(E)) + 对齐填充
  }
  generic TResult<T,E> = record
  private
    FIsOk: Boolean;
    {$IFDEF FAFAFA_RESULT_VARIANT_LAYOUT}
    {$IFDEF FAFAFA_RESULT_ASSUME_NO_MANAGED}
    case Byte of
      0: (FOk: T);
      1: (FErr: E);
    {$ELSE}
    // 运行时检查：如果启用变体布局但类型可能受管，回退到双字段
    {$IF (TypeInfo(T) <> nil) and (PTypeInfo(TypeInfo(T))^.Kind in [tkAString, tkUString, tkWString, tkInterface, tkDynArray, tkArray])}
      {$MESSAGE WARN 'TResult<T,E>: T 类型可能是受管类型，建议使用双字段布局或确认类型安全'}
    {$ENDIF}
    {$IF (TypeInfo(E) <> nil) and (PTypeInfo(TypeInfo(E))^.Kind in [tkAString, tkUString, tkWString, tkInterface, tkDynArray, tkArray])}
      {$MESSAGE WARN 'TResult<T,E>: E 类型可能是受管类型，建议使用双字段布局或确认类型安全'}
    {$ENDIF}
      FOk: T;
      FErr: E;
    {$ENDIF}
    {$ELSE}
    // 默认双字段布局：安全支持所有类型
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
    function ToString: string; overload;
    function ToString(const OkFormat, ErrFormat: string): string; overload;
    function ToStringDetailed: string; // 尝试显示值的详细信息
    // TODO: Fix FreePascal generic function syntax issues
    {
    // 暂时注释掉泛型 ToDebugString 方法，等解决语法问题后再启用
    // generic function ToDebugString(const OkPrinter: specialize TResultFunc<T,string>; const ErrPrinter: specialize TResultFunc<E,string>): string; inline; overload;
    // generic function ToDebugString(const OkPrinter: specialize TResultFuncPtr<T,string>; const ErrPrinter: specialize TResultFuncPtr<E,string>): string; inline; overload;
    }

    // 内存布局信息
    class function MemoryLayoutInfo: string; static;
    class function SizeInfo: string; static;

    // 类型约束支持
    class function SupportsComparable: Boolean; static;
    class function SupportsSerializable: Boolean; static;
    class function SupportsCloneable: Boolean; static;
    function TryCompareTo(const Other: TResult): Integer; // 返回 -2 表示不支持比较
    function TryClone: TResult; // 如果不支持克隆则返回 self

    // Rust 核心 API 补全
    function Flatten: TResult; // 当 T = TResult<U,E> 时展平嵌套
    function AsRef: TResult; // 借用转换（在 Pascal 中等价于 self）
    function Copied: TResult; // 值复制（对于值类型等价于 self）
    function Cloned: TResult; // 深度克隆
    function UnwrapUnchecked: T; inline; // 无检查解包（性能关键）
    // MapOrDefault: 暂时简化实现，避免泛型语法问题
    // 将在 implementation 部分提供全局函数版本

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
    // TODO: Fix FreePascal generic function syntax issues
    // function UnwrapOrElse(const ErrFunc: specialize TResultFunc<E,T>): T; inline; overload;
    // function UnwrapOrElse(const ErrFunc: specialize TResultFuncPtr<E,T>): T; inline; overload;

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

  // 为解决 FreePascal 函数参数类型限制，定义具体的类型别名
  TResultIntegerString = specialize TResult<Integer,String>;
  TResultStringString = specialize TResult<String,String>;
  TResultIntegerStringArray = array of TResultIntegerString;
  TResultStringStringArray = array of TResultStringString;

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

  // 异常安全增强版本
  generic function ResultToTryWithChain<T,E>(const R: specialize TResult<T,E>; const MapE: specialize TResultFunc<E,Exception>; const ChainMessage: string = ''): T;
  generic function ResultToTryWithValidation<T,E>(const R: specialize TResult<T,E>; const MapE: specialize TResultFunc<E,Exception>; const Validator: specialize TResultFunc<Exception,Boolean> = nil): T;

  // 序列化支持
  generic function ResultToJSON<T,E>(const R: specialize TResult<T,E>; const OkSerializer: specialize TResultFunc<T,string>; const ErrSerializer: specialize TResultFunc<E,string>): string;
  generic function ResultFromJSON<T,E>(const JSON: string; const OkDeserializer: specialize TResultFunc<string,T>; const ErrDeserializer: specialize TResultFunc<string,E>): specialize TResult<T,E>;
  generic function ResultToTOML<T,E>(const R: specialize TResult<T,E>; const OkSerializer: specialize TResultFunc<T,string>; const ErrSerializer: specialize TResultFunc<E,string>): string;
  generic function ResultFromTOML<T,E>(const TOML: string; const OkDeserializer: specialize TResultFunc<string,T>; const ErrDeserializer: specialize TResultFunc<string,E>): specialize TResult<T,E>;

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

// Iterator 风格操作（使用内置 Option 实现）
// Filter: Ok 且谓词满足 -> Some(Ok(T))，否则 -> None
generic function ResultFilter<T,E>(const R: specialize TResult<T,E>; const Predicate: specialize TResultFunc<T,Boolean>): specialize TOption<specialize TResult<T,E>>;
generic function ResultFilter<T,E>(const R: specialize TResult<T,E>; const Predicate: specialize TResultFuncPtr<T,Boolean>): specialize TOption<specialize TResult<T,E>>;

// FilterMap: Ok(T) -> F(T) -> Some(U) -> Some(Ok(U))，Ok(T) -> F(T) -> None -> None，Err -> None
generic function ResultFilterMap<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFunc<T,specialize TOption<U>>): specialize TOption<specialize TResult<U,E>>;
generic function ResultFilterMap<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFuncPtr<T,specialize TOption<U>>): specialize TOption<specialize TResult<U,E>>;

// Collect: 将 Result 数组转换为 Result<数组>
// 使用具体类型实现，避免泛型返回类型问题
type
  TResultInteger = specialize TResult<Integer,String>;
  TResultIntegerArray = specialize TResult<TIntegerArray,String>;
  TResultString = specialize TResult<String,String>;
  TResultStringArray = specialize TResult<TStringArray,String>;

function ResultCollectInteger(const Results: TResultIntegerStringArray): TResultIntegerArray;
function ResultCollectString(const Results: TResultStringStringArray): TResultStringArray;

// Chain: 连接两个 Result，第一个 Ok 则返回第二个，第一个 Err 则返回第一个
generic function ResultChain<T,E>(const First, Second: specialize TResult<T,E>): specialize TResult<T,E>;

// 批量操作和性能关键 API
// 使用具体类型实现，避免泛型语法问题
type
  TPartitionResultInteger = specialize TPartitionResult<Integer,String>;

function ResultPartitionInteger(const Results: TResultIntegerStringArray): TPartitionResultInteger;
function ResultAllInteger(const Results: TResultIntegerStringArray): Boolean;
function ResultAnyInteger(const Results: TResultIntegerStringArray): Boolean;
function ResultFirstOkInteger(const Results: TResultIntegerStringArray): specialize TOption<Integer>;
function ResultFirstErrInteger(const Results: TResultIntegerStringArray): specialize TOption<String>;

// MapOrDefault 全局函数版本 - 避免泛型方法语法问题
function MapOrDefaultInteger(const R: specialize TResult<Integer,String>; const F: specialize TResultFunc<Integer,Integer>; const Default: Integer): Integer;
function MapOrDefaultString(const R: specialize TResult<String,String>; const F: specialize TResultFunc<String,String>; const Default: String): String;

// UnwrapOrElse 全局函数版本 - 避免泛型方法语法问题
function UnwrapOrElseInteger(const R: specialize TResult<Integer,String>; const F: specialize TResultFunc<String,Integer>): Integer;
function UnwrapOrElseString(const R: specialize TResult<String,String>; const F: specialize TResultFunc<String,String>): String;

// ToDebugString 全局函数版本 - 避免泛型方法语法问题
function ToDebugStringInteger(const R: specialize TResult<Integer,String>; const OkPrinter: specialize TResultFunc<Integer,String>; const ErrPrinter: specialize TResultFunc<String,String>): String;
function ToDebugStringString(const R: specialize TResult<String,String>; const OkPrinter: specialize TResultFunc<String,String>; const ErrPrinter: specialize TResultFunc<String,String>): String;



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

function TResult.ToString(const OkFormat, ErrFormat: string): string;
begin
  if FIsOk then
    Result := OkFormat
  else
    Result := ErrFormat;
end;

function TResult.ToStringDetailed: string;
var
  OkStr, ErrStr: string;
begin
  if FIsOk then
  begin
    // 对常见类型进行特殊处理
    case PTypeInfo(TypeInfo(T))^.Kind of
      tkInteger, tkInt64: OkStr := IntToStr(PInteger(@FOk)^);
      tkFloat: OkStr := FloatToStr(PDouble(@FOk)^);
      tkAString, tkUString: OkStr := PString(@FOk)^;
      tkBool: if PBoolean(@FOk)^ then OkStr := 'True' else OkStr := 'False';
    else
      OkStr := '<value>';
    end;
    Result := 'Ok(' + OkStr + ')';
  end
  else
  begin
    // 对常见错误类型进行特殊处理
    case PTypeInfo(TypeInfo(E))^.Kind of
      tkInteger, tkInt64: ErrStr := IntToStr(PInteger(@FErr)^);
      tkFloat: ErrStr := FloatToStr(PDouble(@FErr)^);
      tkAString, tkUString: ErrStr := PString(@FErr)^;
      tkBool: if PBoolean(@FErr)^ then ErrStr := 'True' else ErrStr := 'False';
    else
      ErrStr := '<error>';
    end;
    Result := 'Err(' + ErrStr + ')';
  end;
end;

class function TResult.MemoryLayoutInfo: string;
begin
  {$IFDEF FAFAFA_RESULT_VARIANT_LAYOUT}
  {$IFDEF FAFAFA_RESULT_ASSUME_NO_MANAGED}
  Result := 'Variant layout (optimized, no managed type checks)';
  {$ELSE}
  Result := 'Variant layout (with managed type safety checks)';
  {$ENDIF}
  {$ELSE}
  Result := 'Dual-field layout (safe for all types)';
  {$ENDIF}
end;

class function TResult.SizeInfo: string;
var
  TotalSize, BoolSize, TSize, ESize: Integer;
begin
  TotalSize := SizeOf(TResult);
  BoolSize := SizeOf(Boolean);
  TSize := SizeOf(T);
  ESize := SizeOf(E);

  {$IFDEF FAFAFA_RESULT_VARIANT_LAYOUT}
  Result := Format('Total: %d bytes (Boolean: %d + max(T: %d, E: %d) + padding)',
                   [TotalSize, BoolSize, TSize, ESize]);
  {$ELSE}
  Result := Format('Total: %d bytes (Boolean: %d + T: %d + E: %d + padding)',
                   [TotalSize, BoolSize, TSize, ESize]);
  {$ENDIF}
end;

class function TResult.SupportsComparable: Boolean;
begin
  // 检查 T 和 E 是否支持 IResultComparable 接口
  Result := (PTypeInfo(TypeInfo(T))^.Kind = tkInterface) and
            (PTypeInfo(TypeInfo(E))^.Kind = tkInterface);
  // 简化实现：实际应该检查具体接口支持
end;

class function TResult.SupportsSerializable: Boolean;
begin
  // 检查 T 和 E 是否支持 IResultSerializable 接口
  Result := (PTypeInfo(TypeInfo(T))^.Kind = tkInterface) and
            (PTypeInfo(TypeInfo(E))^.Kind = tkInterface);
  // 简化实现：实际应该检查具体接口支持
end;

class function TResult.SupportsCloneable: Boolean;
begin
  // 检查 T 和 E 是否支持 IResultCloneable 接口
  Result := (PTypeInfo(TypeInfo(T))^.Kind = tkInterface) and
            (PTypeInfo(TypeInfo(E))^.Kind = tkInterface);
  // 简化实现：实际应该检查具体接口支持
end;

function TResult.TryCompareTo(const Other: TResult): Integer;
begin
  // 简化实现：基于状态和基本类型比较
  if FIsOk <> Other.FIsOk then
  begin
    if FIsOk then Result := 1 else Result := -1;
    Exit;
  end;

  // 同状态时，尝试基本类型比较
  if FIsOk then
  begin
    case PTypeInfo(TypeInfo(T))^.Kind of
      tkInteger: Result := PInteger(@FOk)^ - PInteger(@Other.FOk)^;
      tkBool: Result := Ord(PBoolean(@FOk)^) - Ord(PBoolean(@Other.FOk)^);
    else
      Result := -2; // 不支持比较
    end;
  end
  else
  begin
    case PTypeInfo(TypeInfo(E))^.Kind of
      tkInteger: Result := PInteger(@FErr)^ - PInteger(@Other.FErr)^;
      tkBool: Result := Ord(PBoolean(@FErr)^) - Ord(PBoolean(@Other.FErr)^);
    else
      Result := -2; // 不支持比较
    end;
  end;
end;

function TResult.TryClone: TResult;
begin
  // 简化实现：对于基本类型直接复制
  Result := Self;
  // 对于复杂类型，应该调用相应的克隆方法
end;

// Rust 核心 API 实现

function TResult.Flatten: TResult;
begin
  // 注意：这个实现假设 T 本身就是 TResult 类型
  // 在实际使用中需要特化处理
  if FIsOk then
  begin
    // 如果 T 是 TResult<U,E> 类型，则返回内部的 Result
    // 简化实现：直接返回 self（需要类型特化）
    Result := Self;
  end
  else
    Result := Self;
end;

function TResult.AsRef: TResult;
begin
  // 在 Pascal 中，记录类型的借用转换等价于值复制
  Result := Self;
end;

function TResult.Copied: TResult;
begin
  // 对于值类型，复制等价于赋值
  Result := Self;
end;

function TResult.Cloned: TResult;
begin
  // 深度克隆：对于基本类型等价于复制
  // 对于复杂类型需要递归克隆
  Result := Self;
  // TODO: 为复杂类型实现真正的深度克隆
end;

function TResult.UnwrapUnchecked: T;
begin
  // 无检查解包：直接返回值，不进行错误检查
  // 警告：仅在确定是 Ok 状态时使用，否则会返回未定义值
  Result := FOk;
end;

// 暂时注释掉 MapOrDefault 实现，等解决泛型语法问题后再启用
{
generic function TResult.MapOrDefault(const F: specialize TResultFunc<T,T>; const Default: T): T;
begin
  if FIsOk then
    Result := F(FOk)
  else
    Result := Default;
end;
}

// 暂时注释掉 ToDebugString 实现，等解决泛型语法问题后再启用
{
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
}



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



// 暂时注释掉第二个 ToDebugString 实现
{
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
}
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


function TResult.ExpectErr(const AMsg: string): E;
begin
  if FIsOk then raise EResultUnwrapError.Create('ExpectErr on Ok: ' + AMsg)
  else Exit(FErr);
end;

function TResult.TryUnwrap(out AValue: T): Boolean;
begin
  if FIsOk then begin AValue := FOk; Exit(True); end



  else begin Initialize(AValue); Exit(False); end;
end;

function TResult.TryUnwrapErr(out AError: E): Boolean;
begin
  if not FIsOk then begin AError := FErr; Exit(True); end
  else begin Initialize(AError); Exit(False); end;
end;

// 暂时注释掉 UnwrapOrElse 实现，等解决泛型语法问题后再启用
{
function TResult.UnwrapOrElse(const ErrFunc: specialize TResultFunc<E,T>): T;
begin
  if FIsOk then Exit(FOk) else Exit(ErrFunc(FErr));
end;

function TResult.UnwrapOrElse(const ErrFunc: specialize TResultFuncPtr<E,T>): T;
begin
  if FIsOk then Exit(FOk) else Exit(ErrFunc(FErr));
end;
}


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

// 异常安全增强实现

generic function ResultToTryWithChain<T,E>(const R: specialize TResult<T,E>; const MapE: specialize TResultFunc<E,Exception>; const ChainMessage: string): T;
var
  Ex: Exception;
  ChainEx: Exception;
begin
  if R.IsOk then Exit(R.Unwrap);

  try
    Ex := MapE(R.UnwrapErr);
    if ChainMessage <> '' then
    begin
      // 创建异常链
      ChainEx := Exception.Create(ChainMessage + ' -> ' + Ex.Message);
      Ex.Free; // 释放原异常
      raise ChainEx;
    end
    else
      raise Ex;
  except
    on E: Exception do
    begin
      // 如果映射函数本身抛出异常，包装它
      if E <> Ex then
      begin
        ChainEx := Exception.Create('Exception mapping failed: ' + E.Message);
        raise ChainEx;
      end
      else
        raise;
    end;
  end;
end;

generic function ResultToTryWithValidation<T,E>(const R: specialize TResult<T,E>; const MapE: specialize TResultFunc<E,Exception>; const Validator: specialize TResultFunc<Exception,Boolean>): T;
var
  Ex: Exception;
begin
  if R.IsOk then Exit(R.Unwrap);

  try
    Ex := MapE(R.UnwrapErr);

    // 验证生成的异常
    if Assigned(Validator) and not Validator(Ex) then
    begin
      Ex.Free;
      raise Exception.Create('Generated exception failed validation');
    end;

    raise Ex;
  except
    on E: Exception do
    begin
      // 如果映射或验证失败，提供更好的错误信息
      if E.Message = 'Generated exception failed validation' then
        raise
      else
        raise Exception.Create('Exception mapping or validation failed: ' + E.Message);
    end;
  end;
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

// Iterator 风格操作实现

generic function ResultFilter<T,E>(const R: specialize TResult<T,E>; const Predicate: specialize TResultFunc<T,Boolean>): specialize TOption<specialize TResult<T,E>>;
begin
  if R.IsOk and Predicate(R.Unwrap) then
    Result := specialize TOption<specialize TResult<T,E>>.Some(R)
  else
    Result := specialize TOption<specialize TResult<T,E>>.None;
end;

generic function ResultFilter<T,E>(const R: specialize TResult<T,E>; const Predicate: specialize TResultFuncPtr<T,Boolean>): specialize TOption<specialize TResult<T,E>>;
begin
  if R.IsOk and Predicate(R.Unwrap) then
    Result := specialize TOption<specialize TResult<T,E>>.Some(R)
  else
    Result := specialize TOption<specialize TResult<T,E>>.None;
end;

generic function ResultFilterMap<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFunc<T,specialize TOption<U>>): specialize TOption<specialize TResult<U,E>>;
var
  OptU: specialize TOption<U>;
begin
  if R.IsOk then
  begin
    OptU := F(R.Unwrap);
    if OptU.IsSome then
      Result := specialize TOption<specialize TResult<U,E>>.Some(specialize TResult<U,E>.Ok(OptU.Unwrap))
    else
      Result := specialize TOption<specialize TResult<U,E>>.None;
  end
  else
    Result := specialize TOption<specialize TResult<U,E>>.None;
end;

generic function ResultFilterMap<T,E,U>(const R: specialize TResult<T,E>; const F: specialize TResultFuncPtr<T,specialize TOption<U>>): specialize TOption<specialize TResult<U,E>>;
var
  OptU: specialize TOption<U>;
begin
  if R.IsOk then
  begin
    OptU := F(R.Unwrap);
    if OptU.IsSome then
      Result := specialize TOption<specialize TResult<U,E>>.Some(specialize TResult<U,E>.Ok(OptU.Unwrap))
    else
      Result := specialize TOption<specialize TResult<U,E>>.None;
  end
  else
    Result := specialize TOption<specialize TResult<U,E>>.None;
end;

// ResultCollect 具体类型实现

function ResultCollectInteger(const Results: TResultIntegerStringArray): TResultIntegerArray;
var
  Values: TIntegerArray;
  I: Integer;
begin
  SetLength(Values, Length(Results));
  for I := 0 to High(Results) do
  begin
    if Results[I].IsErr then
      Exit(TResultIntegerArray.Err(Results[I].UnwrapErr));
    Values[I] := Results[I].Unwrap;
  end;
  Result := TResultIntegerArray.Ok(Values);
end;

function ResultCollectString(const Results: TResultStringStringArray): TResultStringArray;
var
  Values: TStringArray;
  I: Integer;
begin
  SetLength(Values, Length(Results));
  for I := 0 to High(Results) do
  begin
    if Results[I].IsErr then
      Exit(specialize TResult<TStringArray,String>.Err(Results[I].UnwrapErr));
    Values[I] := Results[I].Unwrap;
  end;
  Result := specialize TResult<TStringArray,String>.Ok(Values);
end;

generic function ResultChain<T,E>(const First, Second: specialize TResult<T,E>): specialize TResult<T,E>;
begin
  if First.IsOk then
    Result := Second
  else
    Result := First;
end;

// 暂时注释掉所有批量操作实现，等解决泛型语法问题后再启用
{
// 批量操作实现

generic function ResultPartition<T,E>(const Results: array of specialize TResult<T,E>): specialize TPartitionResult<T,E>;
var
  I, OkCount, ErrCount: Integer;
  OkIndex, ErrIndex: Integer;
begin
  // 第一遍：计算数量
  OkCount := 0;
  ErrCount := 0;
  for I := 0 to High(Results) do
  begin
    if Results[I].IsOk then
      Inc(OkCount)
    else
      Inc(ErrCount);
  end;

  // 分配数组
  SetLength(Result.Oks, OkCount);
  SetLength(Result.Errs, ErrCount);

  // 第二遍：填充数组
  OkIndex := 0;
  ErrIndex := 0;
  for I := 0 to High(Results) do
  begin
    if Results[I].IsOk then
    begin
      Result.Oks[OkIndex] := Results[I].Unwrap;
      Inc(OkIndex);
    end
    else
    begin
      Result.Errs[ErrIndex] := Results[I].UnwrapErr;
      Inc(ErrIndex);
    end;
  end;
end;
}

// 批量操作具体类型实现

function ResultPartitionInteger(const Results: TResultIntegerStringArray): TPartitionResultInteger;
var
  I, OkCount, ErrCount: Integer;
  OkIndex, ErrIndex: Integer;
begin
  // 第一遍：计算数量
  OkCount := 0;
  ErrCount := 0;
  for I := 0 to High(Results) do
  begin
    if Results[I].IsOk then
      Inc(OkCount)
    else
      Inc(ErrCount);
  end;

  // 分配数组
  SetLength(Result.Oks, OkCount);
  SetLength(Result.Errs, ErrCount);

  // 第二遍：填充数组
  OkIndex := 0;
  ErrIndex := 0;
  for I := 0 to High(Results) do
  begin
    if Results[I].IsOk then
    begin
      Result.Oks[OkIndex] := Results[I].Unwrap;
      Inc(OkIndex);
    end
    else
    begin
      Result.Errs[ErrIndex] := Results[I].UnwrapErr;
      Inc(ErrIndex);
    end;
  end;
end;

function ResultAllInteger(const Results: TResultIntegerStringArray): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to High(Results) do
  begin
    if Results[I].IsErr then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

function ResultAnyInteger(const Results: TResultIntegerStringArray): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(Results) do
  begin
    if Results[I].IsOk then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function ResultFirstOkInteger(const Results: TResultIntegerStringArray): specialize TOption<Integer>;
var
  I: Integer;
begin
  for I := 0 to High(Results) do
  begin
    if Results[I].IsOk then
      Exit(specialize TOption<Integer>.Some(Results[I].Unwrap));
  end;
  Result := specialize TOption<Integer>.None;
end;

function ResultFirstErrInteger(const Results: TResultIntegerStringArray): specialize TOption<String>;
var
  I: Integer;
begin
  for I := 0 to High(Results) do
  begin
    if Results[I].IsErr then
      Exit(specialize TOption<String>.Some(Results[I].UnwrapErr));
  end;
  Result := specialize TOption<String>.None;
end;

// MapOrDefault 全局函数实现

function MapOrDefaultInteger(const R: specialize TResult<Integer,String>; const F: specialize TResultFunc<Integer,Integer>; const Default: Integer): Integer;
begin
  if R.IsOk then
    Result := F(R.Unwrap)
  else
    Result := Default;
end;

function MapOrDefaultString(const R: specialize TResult<String,String>; const F: specialize TResultFunc<String,String>; const Default: String): String;
begin
  if R.IsOk then
    Result := F(R.Unwrap)
  else
    Result := Default;
end;

// UnwrapOrElse 全局函数实现

function UnwrapOrElseInteger(const R: specialize TResult<Integer,String>; const F: specialize TResultFunc<String,Integer>): Integer;
begin
  if R.IsOk then
    Result := R.Unwrap
  else
    Result := F(R.UnwrapErr);
end;

function UnwrapOrElseString(const R: specialize TResult<String,String>; const F: specialize TResultFunc<String,String>): String;
begin
  if R.IsOk then
    Result := R.Unwrap
  else
    Result := F(R.UnwrapErr);
end;

// ToDebugString 全局函数实现

function ToDebugStringInteger(const R: specialize TResult<Integer,String>; const OkPrinter: specialize TResultFunc<Integer,String>; const ErrPrinter: specialize TResultFunc<String,String>): String;
begin
  if R.IsOk then
  begin
    if Assigned(OkPrinter) then
      Result := 'Ok(' + OkPrinter(R.Unwrap) + ')'
    else
      Result := 'Ok(' + IntToStr(R.Unwrap) + ')';
  end
  else
  begin
    if Assigned(ErrPrinter) then
      Result := 'Err(' + ErrPrinter(R.UnwrapErr) + ')'
    else
      Result := 'Err(' + R.UnwrapErr + ')';
  end;
end;

function ToDebugStringString(const R: specialize TResult<String,String>; const OkPrinter: specialize TResultFunc<String,String>; const ErrPrinter: specialize TResultFunc<String,String>): String;
begin
  if R.IsOk then
  begin
    if Assigned(OkPrinter) then
      Result := 'Ok(' + OkPrinter(R.Unwrap) + ')'
    else
      Result := 'Ok(' + R.Unwrap + ')';
  end
  else
  begin
    if Assigned(ErrPrinter) then
      Result := 'Err(' + ErrPrinter(R.UnwrapErr) + ')'
    else
      Result := 'Err(' + R.UnwrapErr + ')';
  end;
end;

// 序列化支持实现

generic function ResultToJSON<T,E>(const R: specialize TResult<T,E>; const OkSerializer: specialize TResultFunc<T,string>; const ErrSerializer: specialize TResultFunc<E,string>): string;
begin
  if R.IsOk then
    Result := '{"status":"ok","value":' + OkSerializer(R.Unwrap) + '}'
  else
    Result := '{"status":"err","error":' + ErrSerializer(R.UnwrapErr) + '}';
end;

generic function ResultFromJSON<T,E>(const JSON: string; const OkDeserializer: specialize TResultFunc<string,T>; const ErrDeserializer: specialize TResultFunc<string,E>): specialize TResult<T,E>;
var
  StatusPos, ValuePos, ErrorPos: Integer;
  ValueStr: string;
begin
  // 简化的 JSON 解析实现
  StatusPos := Pos('"status":"ok"', JSON);
  if StatusPos > 0 then
  begin
    // 解析 Ok 值
    ValuePos := Pos('"value":', JSON);
    if ValuePos > 0 then
    begin
      ValueStr := Copy(JSON, ValuePos + 8, Length(JSON) - ValuePos - 8);
      // 移除尾部的 }
      if ValueStr[Length(ValueStr)] = '}' then
        ValueStr := Copy(ValueStr, 1, Length(ValueStr) - 1);
      Result := specialize TResult<T,E>.Ok(OkDeserializer(ValueStr));
    end
    else
      Result := specialize TResult<T,E>.Err(ErrDeserializer('Invalid JSON: missing value'));
  end
  else
  begin
    // 解析 Err 值
    ErrorPos := Pos('"error":', JSON);
    if ErrorPos > 0 then
    begin
      ValueStr := Copy(JSON, ErrorPos + 8, Length(JSON) - ErrorPos - 8);
      // 移除尾部的 }
      if ValueStr[Length(ValueStr)] = '}' then
        ValueStr := Copy(ValueStr, 1, Length(ValueStr) - 1);
      // 移除字符串值的引号
      if (Length(ValueStr) >= 2) and (ValueStr[1] = '"') and (ValueStr[Length(ValueStr)] = '"') then
        ValueStr := Copy(ValueStr, 2, Length(ValueStr) - 2);
      Result := specialize TResult<T,E>.Err(ErrDeserializer(ValueStr));
    end
    else
      Result := specialize TResult<T,E>.Err(ErrDeserializer('Invalid JSON format'));
  end;
end;

generic function ResultToTOML<T,E>(const R: specialize TResult<T,E>; const OkSerializer: specialize TResultFunc<T,string>; const ErrSerializer: specialize TResultFunc<E,string>): string;
begin
  if R.IsOk then
    Result := 'status = "ok"' + LineEnding + 'value = ' + OkSerializer(R.Unwrap)
  else
    Result := 'status = "err"' + LineEnding + 'error = ' + ErrSerializer(R.UnwrapErr);
end;

generic function ResultFromTOML<T,E>(const TOML: string; const OkDeserializer: specialize TResultFunc<string,T>; const ErrDeserializer: specialize TResultFunc<string,E>): specialize TResult<T,E>;
var
  Lines: TStringArray;
  I: Integer;
  Line, Key, Value: string;
  EqPos: Integer;
  IsOk: Boolean;
  ValueStr: string;
begin
  // 简化的 TOML 解析实现
  Lines := TOML.Split([LineEnding]);
  IsOk := False;
  ValueStr := '';

  for I := 0 to High(Lines) do
  begin
    Line := Trim(Lines[I]);
    if Line = '' then Continue;

    EqPos := Pos(' = ', Line);
    if EqPos > 0 then
    begin
      Key := Trim(Copy(Line, 1, EqPos - 1));
      Value := Trim(Copy(Line, EqPos + 3, Length(Line)));

      if Key = 'status' then
      begin
        IsOk := Pos('"ok"', Value) > 0;
      end
      else if (Key = 'value') and IsOk then
      begin
        ValueStr := Value;
      end
      else if (Key = 'error') and not IsOk then
      begin
        ValueStr := Value;
      end;
    end;
  end;

  if IsOk then
    Result := specialize TResult<T,E>.Ok(OkDeserializer(ValueStr))
  else
    Result := specialize TResult<T,E>.Err(ErrDeserializer(ValueStr));
end;

// 前向声明的 Option 基础实现

class function TOption.Some(const AValue: T): TOption;
begin
  Result.FHas := True;
  Result.FValue := AValue;
end;

class function TOption.None: TOption;
begin
  Result.FHas := False;
  // FValue 保持未初始化状态
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
  if not FHas then
    raise Exception.Create('Called Unwrap on None value');
  Result := FValue;
end;

end.

