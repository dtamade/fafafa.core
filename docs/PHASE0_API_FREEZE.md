# Phase 0 API 冻结文档

## 文档信息

- **创建日期**: 2026-01-18
- **版本**: 1.0.0
- **状态**: 🔒 FROZEN
- **适用范围**: 第 0 层模块（base, option, result, math, mem）

## 概述

本文档记录了 fafafa.core 第 0 层模块的公共 API 冻结状态。这些 API 已经过充分测试和验证，将在 1.0 版本发布后保持稳定，遵循语义化版本控制原则。

### API 稳定性保证

- **向后兼容**: 所有冻结的 API 在 1.x 版本系列中保持向后兼容
- **废弃策略**: 如需废弃 API，将提前至少一个大版本发出警告
- **破坏性变更**: 仅在主版本号升级时引入破坏性变更（如 2.0.0）

### 测试覆盖率

| 模块 | 测试数 | 覆盖率 | 状态 |
|------|--------|--------|------|
| base | 64 | 95% | ✅ 优秀 |
| option | 63 | 95%+ | ✅ 优秀 |
| result | 168 | 88% | ✅ 良好 |
| math | 328 | 52% | ✅ 合格 |
| mem | 187 | 39% | ✅ 合格 |
| **总计** | **810** | **平均 73.8%** | **✅ 通过** |

---

## 1. fafafa.core.base 模块

### 1.1 版本信息

```pascal
const
  FAFAFA_CORE_BASE_VERSION = '1.0.0';
```

**状态**: 🔒 FROZEN

### 1.2 基础过程类型

```pascal
type
  TProc    = procedure;
  TObjProc = procedure of object;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TRefProc = reference to procedure;
  {$ENDIF}
```

**状态**: 🔒 FROZEN
**用途**: 无参数过程类型，用于回调和事件处理

### 1.3 泛型函数类型

```pascal
generic TFunc<TArg, TResult> = function(const A: TArg): TResult;
generic TAction<TArg> = procedure(const A: TArg);
generic TThunk<TResult> = function: TResult;
generic TPredicate<T> = function(const A: T): Boolean;
generic TComparer<T> = function(const A, B: T): Integer;
generic TEquality<T> = function(const A, B: T): Boolean;
generic TBiFunc<T1, T2, TResult> = function(const A: T1; const B: T2): TResult;
```

**状态**: 🔒 FROZEN
**用途**: 函数式编程基础类型，用于高阶函数和组合子

**匿名引用版本** (条件编译):
```pascal
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
generic TRefFunc<TArg, TResult> = reference to function(const A: TArg): TResult;
generic TRefAction<TArg> = reference to procedure(const A: TArg);
generic TRefThunk<TResult> = reference to function: TResult;
generic TRefPredicate<T> = reference to function(const A: T): Boolean;
generic TRefComparer<T> = reference to function(const A, B: T): Integer;
generic TRefEquality<T> = reference to function(const A, B: T): Boolean;
generic TRefBiFunc<T1, T2, TResult> = reference to function(const A: T1; const B: T2): TResult;
{$ENDIF}
```

### 1.4 异常层次结构

```pascal
type
  ECore = class(Exception) end;
  EWow = class(ECore) end;
  EArgumentNil = class(ECore) end;
  EEmptyCollection = class(ECore) end;
  EInvalidArgument = class(ECore) end;
  EInvalidResult = class(ECore) end;
  ETimeoutError = class(ECore) end;
  EInvalidState = class(ECore) end;
  EOutOfRange = class(ECore) end;
  ENotSupported = class(ECore) end;
  ENotCompatible = class(ECore) end;
  EInvalidOperation = class(ECore) end;
  EOutOfMemory = class(ECore) end;
  EOverflow = class(ECore) end;
```

**状态**: 🔒 FROZEN
**设计原则**: 所有 fafafa.core 异常均继承自 ECore，形成统一的异常层次

### 1.5 数值常量

```pascal
const
  // SizeInt/SizeUInt 边界
  MAX_SIZE_INT: SizeInt = High(SizeInt);
  MIN_SIZE_INT: SizeInt = Low(SizeInt);
  MAX_SIZE_UINT: SizeUInt = High(SizeUInt);

  // 整数类型边界
  MAX_UINT8: UInt8 = High(UInt8);
  MAX_INT8: Int8 = High(Int8);
  MIN_INT8: Int8 = Low(Int8);

  MAX_UINT16: UInt16 = High(UInt16);
  MAX_INT16: Int16 = High(Int16);
  MIN_INT16: Int16 = Low(Int16);

  MAX_UINT32: UInt32 = High(UInt32);
  MAX_INT32: Int32 = High(Int32);
  MIN_INT32: Int32 = Low(Int32);

  MAX_UINT64: UInt64 = High(UInt64);
  MAX_INT64: Int64 = High(Int64);
  MIN_INT64: Int64 = Low(Int64);

  // 类型大小常量
  SIZE_PTR = SizeOf(Pointer);
  SIZE_8 = SizeOf(UInt8);
  SIZE_16 = SizeOf(UInt16);
  SIZE_32 = SizeOf(UInt32);
  SIZE_64 = SizeOf(UInt64);
```

**状态**: 🔒 FROZEN
**用途**: 跨平台数值边界和类型大小常量

### 1.6 类型别名

```pascal
type
  TStringArray = array of string;
  TBytes = array of Byte;
```

**状态**: 🔒 FROZEN
**用途**: 常用数组类型的简化别名

### 1.7 元组类型

```pascal
generic TTuple2<TFirst, TSecond> = record
  First: TFirst;
  Second: TSecond;
  class function Create(const AFirst: TFirst; const ASecond: TSecond): TTuple2; static; inline;
end;

generic TTuple3<T1, T2, T3> = record
  First: T1;
  Second: T2;
  Third: T3;
  class function Create(const A1: T1; const A2: T2; const A3: T3): TTuple3; static; inline;
end;

generic TTuple4<T1, T2, T3, T4> = record
  First: T1;
  Second: T2;
  Third: T3;
  Fourth: T4;
  class function Create(const A1: T1; const A2: T2; const A3: T3; const A4: T4): TTuple4; static; inline;
end;
```

**状态**: 🔒 FROZEN
**用途**: 多值返回和数据组合

### 1.8 随机生成器回调

```pascal
type
  TRandomGeneratorFunc = function(aRange: Int64; aData: Pointer): Int64;
  TRandomGeneratorMethod = function(aRange: Int64; aData: Pointer): Int64 of object;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TRandomGeneratorRefFunc = reference to function(aRange: Int64): Int64;
  {$ENDIF}
```

**状态**: 🔒 FROZEN
**用途**: 自定义随机数生成器接口

---

## 2. fafafa.core.option 模块

### 2.1 版本信息

```pascal
const
  FAFAFA_CORE_OPTION_BASE_VERSION = '1.0.0';
  FAFAFA_CORE_OPTION_VERSION = '1.0.0';
```

**状态**: 🔒 FROZEN

### 2.2 核心类型 (fafafa.core.option.base)

#### 2.2.1 异常类型

```pascal
type
  EOptionUnwrapError = class(ECore);
```

**状态**: 🔒 FROZEN

#### 2.2.2 函数类型

```pascal
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
generic TOptionFunc<TArg, TRes> = reference to function (const Arg: TArg): TRes;
generic TOptionProc<TArg> = reference to procedure (const Arg: TArg);
generic TOptionThunk<TResult> = reference to function: TResult;
generic TOptionBiPred<T1, T2> = reference to function(const A: T1; const B: T2): Boolean;
{$ELSE}
generic TOptionFunc<TArg, TRes> = function (const Arg: TArg): TRes;
generic TOptionProc<TArg> = procedure (const Arg: TArg);
generic TOptionThunk<TResult> = function: TResult;
generic TOptionBiPred<T1, T2> = function(const A: T1; const B: T2): Boolean;
{$ENDIF}
```

**状态**: 🔒 FROZEN


#### 2.2.3 TOption<T> 核心类型

```pascal
generic TOption<T> = record
private
  FHas: Boolean;
  FValue: T;
  class operator Initialize(var aRec: TOption);
public
  { 内部使用 }
  function GetValueUnchecked: T; inline;
  
  { 构造 }
  class function Some(const aValue: T): TOption; static; inline;
  class function None: TOption; static; inline;
  
  { 查询 }
  function IsSome: Boolean; inline;
  function IsNone: Boolean; inline;
  
  { 取值 }
  function Unwrap: T; inline;
  function UnwrapOr(const aDefault: T): T; inline;
  function UnwrapOrElse(const aF: specialize TOptionThunk<T>): T; inline;
  function UnwrapOrDefault: T; inline;
  function Expect(const aMsg: string): T; inline;
  function TryUnwrap(out aValue: T): Boolean; inline;
  
  { 组合子方法 }
  function Inspect(const aF: specialize TOptionProc<T>): TOption; inline;
  function ToDebugString(const aPrinter: specialize TOptionFunc<T, string>): string;
  
  { 谓词检查 }
  function IsSomeAnd(const aPred: specialize TOptionFunc<T, Boolean>): Boolean; inline;
  function Contains(const aValue: T; const aEq: specialize TOptionBiPred<T, T>): Boolean; inline;
  
  { 逻辑组合 }
  function Or_(const aOther: TOption): TOption; inline;
  function And_(const aOther: TOption): TOption; inline;
  function Xor_(const aOther: TOption): TOption; inline;
end;
```

**状态**: 🔒 FROZEN
**设计原则**: 
- 默认初始化为 None 状态
- 所有方法均为 inline 以实现零成本抽象
- Unwrap 系列方法在 None 时抛出 EOptionUnwrapError

### 2.3 组合子函数 (fafafa.core.option)

```pascal
{ Map 系列 }
generic function OptionMap<T,U>(const aO: specialize TOption<T>; 
  const aF: specialize TOptionFunc<T,U>): specialize TOption<U>;

generic function OptionAndThen<T,U>(const aO: specialize TOption<T>; 
  const aF: specialize TOptionFunc<T, specialize TOption<U>>): specialize TOption<U>;

generic function OptionMapOr<T,U>(const aO: specialize TOption<T>; 
  const aDefault: U; const aF: specialize TOptionFunc<T,U>): U;

generic function OptionMapOrElse<T,U>(const aO: specialize TOption<T>; 
  const aFnone: specialize TOptionThunk<U>; 
  const aFok: specialize TOptionFunc<T,U>): U;

{ Filter }
generic function OptionFilter<T>(const aO: specialize TOption<T>; 
  const aPred: specialize TOptionFunc<T,Boolean>): specialize TOption<T>;

{ Flatten }
generic function OptionFlatten<T>(const aO: specialize TOption<specialize TOption<T>>): 
  specialize TOption<T>;

{ Zip 系列 }
generic function OptionZip<T, U>(const aA: specialize TOption<T>; 
  const aB: specialize TOption<U>): specialize TOption<specialize TTuple2<T, U>>;

generic function OptionZipWith<T, U, R>(const aA: specialize TOption<T>; 
  const aB: specialize TOption<U>;
  const aF: specialize TOptionFunc<specialize TTuple2<T, U>, R>): specialize TOption<R>;

{ Result 互转 }
generic function OptionToResult<T,E>(const aO: specialize TOption<T>; 
  const aErr: E): specialize TResult<T,E>;

generic function OptionToResultElse<T,E>(const aO: specialize TOption<T>; 
  const aFerrThunk: specialize TOptionThunk<E>): specialize TResult<T,E>;

generic function ResultToOption<T,E>(const aR: specialize TResult<T,E>): 
  specialize TOption<T>;

generic function ResultErrOption<T,E>(const aR: specialize TResult<T,E>): 
  specialize TOption<E>;

{ Transpose }
generic function ResultTransposeOption<T,E>(const aR: specialize TResult<specialize TOption<T>,E>): 
  specialize TOption< specialize TResult<T,E> >;

generic function OptionTransposeResult<T,E>(const aO: specialize TOption< specialize TResult<T,E> >): 
  specialize TResult< specialize TOption<T>, E>;

{ FromNullable 家族 }
generic function OptionFromBool<T>(aB: Boolean; const aWhenTrue: T): specialize TOption<T>;
function OptionFromString(const aStr: string; const aTreatEmptyAsNone: Boolean = True): 
  specialize TOption<string>;
generic function OptionFromValue<T>(aHasValue: Boolean; const aValue: T): specialize TOption<T>;
function OptionFromInterface(const aV: IInterface): specialize TOption<IInterface>;
```

**状态**: 🔒 FROZEN
**设计原则**:
- 所有回调参数在 Some 时检查 nil，抛出 EArgumentNil
- 使用 GetValueUnchecked 避免双重检查，提升性能
- 命名遵循 Rust Option API 约定

---

## 3. fafafa.core.result 模块

### 3.1 版本信息

```pascal
const
  FAFAFA_CORE_RESULT_VERSION = '1.0.0';
```

**状态**: 🔒 FROZEN

### 3.2 核心类型

#### 3.2.1 异常类型

```pascal
type
  EResultUnwrapError = class(ECore);
```

**状态**: 🔒 FROZEN

#### 3.2.2 函数类型

```pascal
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
generic TResultFunc<TArg, TRes> = reference to function(const Arg: TArg): TRes;
generic TResultProc<TArg> = reference to procedure(const Arg: TArg);
generic TResultThunk<TRes> = reference to function: TRes;
generic TResultBiPred<T1, T2> = reference to function(const A: T1; const B: T2): Boolean;
{$ELSE}
generic TResultFunc<TArg, TRes> = function(const Arg: TArg): TRes;
generic TResultProc<TArg> = procedure(const Arg: TArg);
generic TResultThunk<TRes> = function: TRes;
generic TResultBiPred<T1, T2> = function(const A: T1; const B: T2): Boolean;
{$ENDIF}
```

**状态**: 🔒 FROZEN

#### 3.2.3 辅助类型

```pascal
type
  { TUnit - 单元类型 }
  TUnit = record end;
  
  { TValueArray<T> - 动态数组别名 }
  generic TValueArray<T> = array of T;
  
  { TErrorCtx<E> - 错误上下文链 }
  generic TErrorCtx<E> = record
    Msg: string;
    Inner: E;
    class function Create(const AMsg: string; const AInner: E): TErrorCtx; static; inline;
    function ToDebugString(const InnerPrinter: specialize TResultFunc<E, string>): string;
  end;
```

**状态**: 🔒 FROZEN
**用途**: TUnit 用于仅关注错误路径的 API（如 ResultEnsure）


#### 3.2.4 TResult<T,E> 核心类型

```pascal
generic TResult<T, E> = record
private
  FIsOk: Boolean;
  FOk: T;
  FErr: E;
  class operator Initialize(var aRec: TResult);
public
  { 内部使用 }
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
  function OkOption: specialize TOption<T>; inline;
  function ErrOption: specialize TOption<E>; inline;
  
  { 字符串表示 }
  function ToString: string; overload;
  function ToString(const OkFormat, ErrFormat: string): string; overload;
  function ToDebugString(const OkPrinter: specialize TResultFunc<T, string>;
    const ErrPrinter: specialize TResultFunc<E, string>): string;
  
  { 方法式 API }
  function And_(const B: TResult): TResult; inline;
  function Or_(const B: TResult): TResult; inline;
  function OrElseThunk(const F: specialize TResultThunk<TResult>): TResult; inline;
  function AndResult(const B: TResult): TResult; inline; deprecated 'Use And_ instead';
  function OrResult(const B: TResult): TResult; inline; deprecated 'Use Or_ instead';
  
  { 组合子方法 }
  function Inspect(const F: specialize TResultProc<T>): TResult; inline;
  function InspectErr(const F: specialize TResultProc<E>): TResult; inline;
  function IsOkAnd(const Pred: specialize TResultFunc<T, Boolean>): Boolean; inline;
  function IsErrAnd(const Pred: specialize TResultFunc<E, Boolean>): Boolean; inline;
  function Contains(const V: T; const Eq: specialize TResultBiPred<T, T>): Boolean; inline;
  function ContainsErr(const EVal: E; const Eq: specialize TResultBiPred<E, E>): Boolean; inline;
  function Equals(const Other: TResult; const EqT: specialize TResultBiPred<T, T>; 
    const EqE: specialize TResultBiPred<E, E>): Boolean;
end;
```

**状态**: 🔒 FROZEN
**设计原则**:
- 默认初始化为 Err 状态（防止未初始化的 Ok）
- 所有方法均为 inline 以实现零成本抽象
- Unwrap 系列方法在 Err 时抛出 EResultUnwrapError
- 提供 deprecated 标记的旧 API（AndResult/OrResult）以支持平滑迁移

### 3.3 组合子函数 (条件编译)

```pascal
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}

{ Map 系列 }
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

{ Match/Fold }
generic function ResultMatch<T, E, U>(const R: specialize TResult<T, E>;
  const Fok: specialize TResultFunc<T, U>; const Ferr: specialize TResultFunc<E, U>): U; inline;

generic function ResultFold<T, E, U>(const R: specialize TResult<T, E>;
  const Fok: specialize TResultFunc<T, U>; const Ferr: specialize TResultFunc<E, U>): U; inline;

{ 结构转换 }
generic function ResultSwap<T, E>(const R: specialize TResult<T, E>): specialize TResult<E, T>; inline;

generic function ResultFlatten<T, E>(const R: specialize TResult<specialize TResult<T, E>, E>): 
  specialize TResult<T, E>; inline;

generic function ResultMapBoth<T, E, U, F>(const R: specialize TResult<T, E>;
  const Fok: specialize TResultFunc<T, U>; const Ferr: specialize TResultFunc<E, F>): 
  specialize TResult<U, F>; inline;

{ Filter }
generic function ResultFilterOrElse<T, E>(const R: specialize TResult<T, E>;
  const Pred: specialize TResultFunc<T, Boolean>;
  const Ferr: specialize TResultFunc<T, E>): specialize TResult<T, E>; inline;

{ 链式操作 }
generic function ResultChain<T, E>(const First, Second: specialize TResult<T, E>): 
  specialize TResult<T, E>;

{ 断言 }
generic function ResultEnsure<E>(const Cond: Boolean;
  const ErrVal: E): specialize TResult<TUnit, E>; inline;

generic function ResultEnsureWith<E>(const Cond: Boolean;
  const ErrThunk: specialize TResultThunk<E>): specialize TResult<TUnit, E>; inline;

{ 构造 }
generic function ResultFromBool<T, E>(const Cond: Boolean;
  const OkVal: T; const ErrVal: E): specialize TResult<T, E>; inline;

generic function ResultFromOption<T, E>(const O: specialize TOption<T>;
  const ErrVal: E): specialize TResult<T, E>; inline;

generic function ResultFromOptionElse<T, E>(const O: specialize TOption<T>;
  const ErrThunk: specialize TResultThunk<E>): specialize TResult<T, E>; inline;

{ Zip 系列 }
generic function ResultZip<T1, T2, E>(const A: specialize TResult<T1, E>;
  const B: specialize TResult<T2, E>): specialize TResult<specialize TTuple2<T1, T2>, E>; inline;

generic function ResultZipWith<T1, T2, E, U>(const A: specialize TResult<T1, E>;
  const B: specialize TResult<T2, E>;
  const F: specialize TResultFunc<specialize TTuple2<T1, T2>, U>): specialize TResult<U, E>; inline;

{ 集合操作 }
generic function TryCollectPtrIntoArray<T, E>(const ItemsPtr: Pointer; const Count: SizeUInt;
  var OutValues: specialize TValueArray<T>; out FirstErr: E): Boolean;

{ 异常互转 }
generic function ResultToTry<T, E>(const R: specialize TResult<T, E>;
  const MapE: specialize TResultFunc<E, Exception>): T; inline;

generic function ResultFromTry<T, E>(const Work: specialize TResultThunk<T>;
  const MapEx: specialize TResultFunc<Exception, E>): specialize TResult<T, E>;

{ 错误上下文 }
generic function ResultContext<T, E>(const R: specialize TResult<T, E>;
  const Ctx: string): specialize TResult<T, string>; inline;

generic function ResultWithContext<T, E>(const R: specialize TResult<T, E>;
  const CtxFunc: specialize TResultFunc<E, string>): specialize TResult<T, string>; inline;

generic function ResultContextE<T, E>(const R: specialize TResult<T, E>;
  const Ctx: string): specialize TResult<T, specialize TErrorCtx<E>>; inline;

generic function ResultWithContextE<T, E>(const R: specialize TResult<T, E>;
  const CtxFunc: specialize TResultFunc<E, string>): specialize TResult<T, specialize TErrorCtx<E>>; inline;

{ Transpose }
generic function ResultTranspose<T, E>(const R: specialize TResult<specialize TOption<T>, E>):
  specialize TOption<specialize TResult<T, E>>;

{$ENDIF FAFAFA_CORE_ANONYMOUS_REFERENCES}
```

**状态**: 🔒 FROZEN
**设计原则**:
- 所有组合子函数需要 `FAFAFA_CORE_ANONYMOUS_REFERENCES` 宏支持
- 所有回调参数在调用前检查 nil，抛出 EArgumentNil
- 使用 GetOkUnchecked/GetErrUnchecked 避免双重检查
- 命名遵循 Rust Result API 约定

---

## 4. fafafa.core.math 模块

### 4.1 版本信息

```pascal
const
  PI: Double = 3.1415926535897932384626433832795;
```

**状态**: 🔒 FROZEN
**说明**: 提供 PI 常量以避免直接使用 RTL Math 单元

### 4.2 核心 API 分类

#### 4.2.1 溢出检查函数

```pascal
function IsAddOverflow(aA, aB: SizeUInt): Boolean; overload; inline;
{$IFDEF CPU64}
function IsAddOverflow(aA, aB: UInt32): Boolean; overload; inline;
{$ENDIF}

function IsSubUnderflow(aA, aB: SizeUInt): Boolean; overload; inline;
{$IFDEF CPU64}
function IsSubUnderflow(aA, aB: UInt32): Boolean; overload; inline;
{$ENDIF}

function IsMulOverflow(aA, aB: SizeUInt): Boolean; overload; inline;
{$IFDEF CPU64}
function IsMulOverflow(aA, aB: UInt32): Boolean; overload; inline;
{$ENDIF}
```

**状态**: 🔒 FROZEN
**用途**: 检查算术运算是否会溢出/下溢


#### 4.2.2 饱和运算函数

```pascal
function SaturatingAdd(aA, aB: SizeUInt): SizeUInt; overload; inline;
{$IFDEF CPU64}
function SaturatingAdd(aA, aB: UInt32): UInt32; overload; inline;
{$ENDIF}

function SaturatingSub(aA, aB: SizeUInt): SizeUInt; overload; inline;
{$IFDEF CPU64}
function SaturatingSub(aA, aB: UInt32): UInt32; overload; inline;
{$ENDIF}

function SaturatingMul(aA, aB: SizeUInt): SizeUInt; overload; inline;
{$IFDEF CPU64}
function SaturatingMul(aA, aB: UInt32): UInt32; overload; inline;
{$ENDIF}
```

**状态**: 🔒 FROZEN
**用途**: 饱和算术运算，溢出时返回类型最大值/最小值

#### 4.2.3 Checked 操作（Rust 风格）

```pascal
{ 返回 TOptional<T>，溢出时返回 None }
function CheckedAddU32(aA, aB: UInt32): TOptionalU32; inline;
function CheckedSubU32(aA, aB: UInt32): TOptionalU32; inline;
function CheckedMulU32(aA, aB: UInt32): TOptionalU32; inline;
function CheckedDivU32(aA, aB: UInt32): TOptionalU32; inline;

function CheckedAddU64(aA, aB: UInt64): TOptionalU64; inline;
function CheckedSubU64(aA, aB: UInt64): TOptionalU64; inline;
function CheckedMulU64(aA, aB: UInt64): TOptionalU64; inline;
function CheckedDivU64(aA, aB: UInt64): TOptionalU64; inline;

function CheckedAddI32(aA, aB: Int32): TOptionalI32; inline;
function CheckedSubI32(aA, aB: Int32): TOptionalI32; inline;
function CheckedMulI32(aA, aB: Int32): TOptionalI32; inline;
function CheckedDivI32(aA, aB: Int32): TOptionalI32; inline;
function CheckedNegI32(aA: Int32): TOptionalI32; inline;

function CheckedAddI64(aA, aB: Int64): TOptionalI64; inline;
function CheckedSubI64(aA, aB: Int64): TOptionalI64; inline;
function CheckedMulI64(aA, aB: Int64): TOptionalI64; inline;
function CheckedDivI64(aA, aB: Int64): TOptionalI64; inline;
function CheckedNegI64(aA: Int64): TOptionalI64; inline;
```

**状态**: 🔒 FROZEN
**用途**: 检查算术运算，溢出时返回 None，永不抛异常

#### 4.2.4 Overflowing 操作（Rust 风格）

```pascal
{ 返回 TOverflow<T>，包含环绕值和溢出标志 }
function OverflowingAddU32(aA, aB: UInt32): TOverflowU32; inline;
function OverflowingSubU32(aA, aB: UInt32): TOverflowU32; inline;
function OverflowingMulU32(aA, aB: UInt32): TOverflowU32; inline;

function OverflowingAddU64(aA, aB: UInt64): TOverflowU64; inline;
function OverflowingSubU64(aA, aB: UInt64): TOverflowU64; inline;
function OverflowingMulU64(aA, aB: UInt64): TOverflowU64; inline;

function OverflowingAddI32(aA, aB: Int32): TOverflowI32; inline;
function OverflowingSubI32(aA, aB: Int32): TOverflowI32; inline;
function OverflowingMulI32(aA, aB: Int32): TOverflowI32; inline;
function OverflowingNegI32(aA: Int32): TOverflowI32; inline;

function OverflowingAddI64(aA, aB: Int64): TOverflowI64; inline;
function OverflowingSubI64(aA, aB: Int64): TOverflowI64; inline;
function OverflowingMulI64(aA, aB: Int64): TOverflowI64; inline;
function OverflowingNegI64(aA: Int64): TOverflowI64; inline;
```

**状态**: 🔒 FROZEN
**用途**: 溢出算术运算，返回环绕值和溢出标志

#### 4.2.5 Wrapping 操作（Rust 风格）

```pascal
{ 2 补码环绕运算，禁用溢出检查 }
function WrappingAddU32(aA, aB: UInt32): UInt32; inline;
function WrappingSubU32(aA, aB: UInt32): UInt32; inline;
function WrappingMulU32(aA, aB: UInt32): UInt32; inline;

function WrappingAddU64(aA, aB: UInt64): UInt64; inline;
function WrappingSubU64(aA, aB: UInt64): UInt64; inline;
function WrappingMulU64(aA, aB: UInt64): UInt64; inline;

function WrappingAddI32(aA, aB: Int32): Int32; inline;
function WrappingSubI32(aA, aB: Int32): Int32; inline;
function WrappingMulI32(aA, aB: Int32): Int32; inline;
function WrappingNegI32(aA: Int32): Int32; inline;

function WrappingAddI64(aA, aB: Int64): Int64; inline;
function WrappingSubI64(aA, aB: Int64): Int64; inline;
function WrappingMulI64(aA, aB: Int64): Int64; inline;
function WrappingNegI64(aA: Int64): Int64; inline;
```

**状态**: 🔒 FROZEN
**用途**: 环绕算术运算，总是使用 2 补码语义

#### 4.2.6 Carrying/Borrowing 操作

```pascal
{ 多字算术的进位/借位操作 }
function CarryingAddU32(aA, aB: UInt32; aCarryIn: Boolean): TCarryResultU32; inline;
function BorrowingSubU32(aA, aB: UInt32; aBorrowIn: Boolean): TCarryResultU32; inline;

function CarryingAddU64(aA, aB: UInt64; aCarryIn: Boolean): TCarryResultU64; inline;
function BorrowingSubU64(aA, aB: UInt64; aBorrowIn: Boolean): TCarryResultU64; inline;
```

**状态**: 🔒 FROZEN
**用途**: 多字算术的进位/借位传播

#### 4.2.7 Widening 乘法

```pascal
{ 扩展乘法，永不溢出 }
function WideningMulU32(aA, aB: UInt32): UInt64; inline;
function WideningMulU64(aA, aB: UInt64): TUInt128; inline;
```

**状态**: 🔒 FROZEN
**用途**: 扩展乘法，结果类型为输入类型的 2 倍宽度

#### 4.2.8 欧几里得除法

```pascal
{ 欧几里得除法，余数始终非负 }
function DivEuclidI32(aA, aB: Int32): Int32; inline;
function RemEuclidI32(aA, aB: Int32): Int32; inline;
function CheckedDivEuclidI32(aA, aB: Int32): TOptionalI32; inline;
function CheckedRemEuclidI32(aA, aB: Int32): TOptionalI32; inline;

function DivEuclidI64(aA, aB: Int64): Int64; inline;
function RemEuclidI64(aA, aB: Int64): Int64; inline;
function CheckedDivEuclidI64(aA, aB: Int64): TOptionalI64; inline;
function CheckedRemEuclidI64(aA, aB: Int64): TOptionalI64; inline;
```

**状态**: 🔒 FROZEN
**用途**: 欧几里得除法，余数始终满足 0 <= r < |divisor|

#### 4.2.9 浮点函数

```pascal
{ 基础浮点运算 }
function Abs(x: Double): Double; overload; inline;
function Min(aA, aB: Double): Double; overload; inline;
function Max(aA, aB: Double): Double; overload; inline;
function Clamp(x, aMin, aMax: Double): Double; inline;
function Floor(x: Double): Int64; overload; inline;
function Ceil(x: Double): Int64; overload; inline;
function Trunc(x: Double): Int64; overload; inline;
function Round(x: Double): Int64; overload; inline;
function Sqrt(x: Double): Double; overload; inline;
function Sqr(x: Double): Double; overload; inline;
function Int(x: Double): Double; overload; inline;
function Frac(x: Double): Double; overload; inline;
function Sign(x: Double): Integer; overload; inline;
function IntPower(aBase: Double; aExponent: Integer): Double; overload; inline;

{ 特殊值 }
function NaN: Double; inline;
function Infinity: Double; inline;
function IsNaN(x: Double): Boolean; overload; inline;
function IsInfinite(x: Double): Boolean; overload; inline;

{ FPU 控制 }
function GetExceptionMask: TFPUExceptionMask; inline;
procedure SetExceptionMask(const aMask: TFPUExceptionMask); inline;

{ 高级浮点运算 }
function Power(aBase, aExponent: Double): Double; overload; inline;
function EnsureRange(aValue, aMin, aMax: Double): Double; overload; inline;
function EnsureRange(aValue, aMin, aMax: Int64): Int64; overload; inline;
function EnsureRange(aValue, aMin, aMax: Integer): Integer; overload; inline;
function RadToDeg(aRadians: Double): Double; overload; inline;
function DegToRad(aDegrees: Double): Double; overload; inline;
function ArcTan2(aY, aX: Double): Double; overload; inline;

{ 三角函数 }
function Sin(x: Double): Double; overload; inline;
function Cos(x: Double): Double; overload; inline;
function Tan(x: Double): Double; overload; inline;
function ArcSin(x: Double): Double; overload; inline;
function ArcCos(x: Double): Double; overload; inline;
function ArcTan(x: Double): Double; overload; inline;

{ 指数和对数函数 }
function Exp(x: Double): Double; overload; inline;
function Ln(x: Double): Double; overload; inline;
function Log10(x: Double): Double; overload; inline;
function Log2(x: Double): Double; overload; inline;
```

**状态**: 🔒 FROZEN
**用途**: 浮点数学函数，语义对齐 RTL Math 单元

#### 4.2.10 整数工具函数

```pascal
{ 整数工具 }
function DivRoundUp(aValue, aDivisor: SizeUInt): SizeUInt; inline;
function IsPowerOfTwo(aValue: SizeUInt): Boolean; inline;
function NextPowerOfTwo(aValue: SizeUInt): SizeUInt; inline;
function AlignUp(aValue, aAlignment: SizeUInt): SizeUInt; inline;
function AlignDown(aValue, aAlignment: SizeUInt): SizeUInt; inline;
function IsAligned(aValue, aAlignment: SizeUInt): Boolean; inline;

{ Min/Max 重载 }
function Min(aA, aB: SizeUInt): SizeUInt; overload; inline;
function Max(aA, aB: SizeUInt): SizeUInt; overload; inline;
function Min(aA, aB: Int64): Int64; overload; inline;
function Max(aA, aB: Int64): Int64; overload; inline;
{$if SizeOf(SizeInt) <> SizeOf(Int64)}
function Min(aA, aB: SizeInt): SizeInt; overload; inline;
function Max(aA, aB: SizeInt): SizeInt; overload; inline;
{$endif}
```

**状态**: 🔒 FROZEN
**用途**: 整数工具函数，用于对齐、2 的幂次等操作

---

## 5. fafafa.core.mem 模块

### 5.1 版本信息

```pascal
const
  FAFAFA_CORE_MEM_VERSION = '2.0.0';

function MemVersion: string; inline;
```

**状态**: 🔒 FROZEN

### 5.2 核心类型（v2.0 Rust 风格接口）

```pascal
type
  { 内存布局和能力 }
  TMemLayout = record
    Size: SizeUInt;
    Align: SizeUInt;
  end;
  
  TAllocCaps = record
    { 能力标志 }
  end;
  
  { 错误处理 }
  TAllocError = (aeOutOfMemory, aeInvalidLayout, aeUnsupported);
  TAllocResult = record
    Ptr: Pointer;
    Error: TAllocError;
    Success: Boolean;
  end;
  
  { Rust 风格分配器接口 }
  IAlloc = interface
    function Alloc(const Layout: TMemLayout): TAllocResult;
    procedure Dealloc(Ptr: Pointer; const Layout: TMemLayout);
    function Realloc(Ptr: Pointer; const OldLayout, NewLayout: TMemLayout): TAllocResult;
    function Caps: TAllocCaps;
  end;
  
  TAllocBase = class(TInterfacedObject, IAlloc)
    { 基础分配器实现 }
  end;
  
  TSystemAlloc = class(TAllocBase)
    { 系统分配器（GetMem/FreeMem）}
  end;
  
  TAlignedAlloc = class(TAllocBase)
    { 对齐分配器 }
  end;
  
  { 块池和 Arena 接口 }
  IBlockPool = interface
    { 块池接口 }
  end;
  
  IArena = interface
    { Arena 接口 }
  end;
  
  TArenaMarker = record
    { Arena 标记，用于回滚 }
  end;
  
  TBlockPool = class
    { 块池实现 }
  end;
  
  TArena = class
    { Arena 实现 }
  end;
  
  TGrowingArenaConfig = record
    { 可增长 Arena 配置 }
  end;
  
  TGrowingArena = class
    { 可增长 Arena 实现 }
  end;
```

**状态**: 🔒 FROZEN
**设计原则**: v2.0 采用 Rust 风格接口，基于 Layout 的内存布局描述，Result 类型错误处理

### 5.3 分配器获取函数

```pascal
function GetSystemAlloc: IAlloc; inline;
function GetAlignedAlloc: IAlloc; inline;
function GetMimalloc: IAlloc; inline;
```

**状态**: 🔒 FROZEN
**用途**: 获取全局分配器实例

### 5.4 内存操作函数

#### 5.4.1 Overlap 检查

```pascal
function IsOverlap(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean; overload; inline;
function IsOverlap(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean; overload; inline;
function IsOverlapUnChecked(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean; overload; inline;
function IsOverlapUnChecked(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean; overload; inline;
```

**状态**: 🔒 FROZEN
**用途**: 检查内存区域是否重叠

#### 5.4.2 Copy 系列

```pascal
procedure Copy(aSrc, aDst: Pointer; aSize: SizeUInt); inline;
procedure CopyUnChecked(aSrc, aDst: Pointer; aSize: SizeUInt); inline;
procedure CopyNonOverlap(aSrc, aDst: Pointer; aSize: SizeUInt); inline;
procedure CopyNonOverlapUnChecked(aSrc, aDst: Pointer; aSize: SizeUInt); inline;
```

**状态**: 🔒 FROZEN
**用途**: 内存复制，提供检查和非检查版本

#### 5.4.3 Fill/Zero 系列

```pascal
procedure Fill(aDst: Pointer; aCount: SizeUInt; aValue: UInt8); overload; inline;
procedure Fill(aDst: Pointer; aCount: SizeInt; aValue: UInt8); overload; inline;
procedure Fill8(aDst: Pointer; aCount: SizeUInt; aValue: UInt8); overload; inline;
procedure Fill8(aDst: Pointer; aCount: SizeInt; aValue: UInt8); overload; inline;
procedure Fill16(aDst: Pointer; aCount: SizeUInt; aValue: UInt16); overload; inline;
procedure Fill16(aDst: Pointer; aCount: SizeInt; aValue: UInt16); overload; inline;
procedure Fill32(aDst: Pointer; aCount: SizeUInt; aValue: UInt32); overload; inline;
procedure Fill32(aDst: Pointer; aCount: SizeInt; aValue: UInt32); overload; inline;
procedure Fill64(aDst: Pointer; aCount: SizeUInt; const aValue: UInt64); overload; inline;
procedure Fill64(aDst: Pointer; aCount: SizeInt; const aValue: UInt64); overload; inline;
procedure Zero(aDst: Pointer; aSize: SizeUInt); overload; inline;
procedure Zero(aDst: Pointer; aSize: SizeInt); overload; inline;
```

**状态**: 🔒 FROZEN
**用途**: 内存填充和清零，支持不同字长

#### 5.4.4 Compare/Equal 系列

```pascal
function Compare(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; inline;
function Compare(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; inline;
function Compare8(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; inline;
function Compare8(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; inline;
function Compare16(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; inline;
function Compare16(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; inline;
function Compare32(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; inline;
function Compare32(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; inline;
function Equal(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean; overload; inline;
function Equal(aPtr1, aPtr2: Pointer; aSize: SizeInt): Boolean; overload; inline;
```

**状态**: 🔒 FROZEN
**用途**: 内存比较，支持不同字长

#### 5.4.5 对齐操作

```pascal
function IsAligned(aPtr: Pointer; aAlignment: SizeUInt = SizeOf(Pointer)): Boolean; inline;
function AlignUp(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; inline;
function AlignUpUnChecked(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; inline;
function AlignDown(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; inline;
function AlignDownUnChecked(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; inline;
```

**状态**: 🔒 FROZEN
**用途**: 指针对齐操作

---

## 6. API 冻结总结

### 6.1 冻结范围

本次 API 冻结涵盖第 0 层的 5 个核心模块：

1. **fafafa.core.base** - 基础类型、异常、常量、元组
2. **fafafa.core.option** - Option 类型和组合子
3. **fafafa.core.result** - Result 类型和组合子
4. **fafafa.core.math** - 数学函数和安全算术
5. **fafafa.core.mem** - 内存管理和分配器

### 6.2 API 稳定性承诺

- **向后兼容**: 所有冻结的 API 在 1.x 版本系列中保持向后兼容
- **废弃策略**: 如需废弃 API，将提前至少一个大版本发出警告（使用 `deprecated` 指令）
- **破坏性变更**: 仅在主版本号升级时引入破坏性变更（如 2.0.0）

### 6.3 已标记废弃的 API

以下 API 已标记为 `deprecated`，建议迁移：

```pascal
{ fafafa.core.result }
function TResult.AndResult(const B: TResult): TResult; deprecated 'Use And_ instead';
function TResult.OrResult(const B: TResult): TResult; deprecated 'Use Or_ instead';
```

**迁移指南**:
- `AndResult` → `And_`
- `OrResult` → `Or_`

### 6.4 条件编译 API

以下 API 需要 `FAFAFA_CORE_ANONYMOUS_REFERENCES` 宏支持：

- **base 模块**: `TRefProc`, `TRefFunc<>`, `TRefAction<>` 等匿名引用类型
- **option 模块**: 所有组合子函数（OptionMap, OptionAndThen 等）
- **result 模块**: 所有组合子函数（ResultMap, ResultAndThen 等）

**说明**: 这些 API 需要 FPC 3.3.1+ 的 `reference to` 语法支持

### 6.5 平台特定 API

以下 API 仅在 64 位平台可用（`{$IFDEF CPU64}`）：

```pascal
{ fafafa.core.math }
function IsAddOverflow(aA, aB: UInt32): Boolean; overload;
function IsSubUnderflow(aA, aB: UInt32): Boolean; overload;
function IsMulOverflow(aA, aB: UInt32): Boolean; overload;
function SaturatingAdd(aA, aB: UInt32): UInt32; overload;
function SaturatingSub(aA, aB: UInt32): UInt32; overload;
function SaturatingMul(aA, aB: UInt32): UInt32; overload;
```

**说明**: 在 32 位平台上，SizeUInt 即为 UInt32，无需单独重载

### 6.6 测试覆盖率目标

| 模块 | 当前覆盖率 | 1.0 目标 | 状态 |
|------|-----------|---------|------|
| base | 95% | 95% | ✅ 已达标 |
| option | 95%+ | 95% | ✅ 已达标 |
| result | 88% | 90% | ⚠️ 接近目标 |
| math | 52% | 60% | ⚠️ 需提升 |
| mem | 39% | 50% | ⚠️ 需提升 |

**说明**: math 和 mem 模块的测试覆盖率将在后续版本中持续提升

### 6.7 文档要求

所有冻结的 API 必须满足以下文档要求：

- ✅ 公共 API 有完整的文档注释
- ✅ 参数和返回值有清晰说明
- ✅ 异常情况有明确文档
- ✅ 使用示例在模块文档中提供

### 6.8 下一步行动

1. **Phase 5.2**: 接口冻结声明（1-2 小时）
   - 更新 CHANGELOG.md
   - 通知开发者
   - 标记所有接口为 🔒 FROZEN

2. **1.0 版本发布准备**:
   - 完成剩余测试覆盖率提升
   - 性能基准验证
   - 文档完善

---

## 附录 A：版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0.0 | 2026-01-18 | 初始 API 冻结 |

---

## 附录 B：参考文档

- `docs/PHASE0_REFINEMENT_PLAN.md` - Phase 0 精品化改进计划
- `WORKING.md` - 项目工作状态
- `CLAUDE.md` - 项目开发指南

---

**文档结束**

