unit fafafa.core.base;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;  // ✅ OPT: 移除未使用的 classes 单元，减少依赖

const
  {** 模块版本 | Module version *}
  FAFAFA_CORE_BASE_VERSION = '1.0.0';

type

  { 基础过程类型 | Basic procedure types }
  TProc    = procedure;
  TObjProc = procedure of object;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TRefProc = reference to procedure;
  {$ENDIF}

  { 通用函数类型 | Generic function types
    这些类型供上层模块（option、result 等）使用，避免各模块重复定义。
    These types are for use by higher-level modules (option, result, etc.) to avoid duplicate definitions.
  }

  {**
   * TFunc<TArg, TResult>
   *
   * @desc
   *   A generic function type that takes one argument and returns a result.
   *   接受一个参数并返回结果的泛型函数类型。
   *
   * @usage
   *   Used in Option.Map, Result.Map, and other functional transformations.
   *   用于 Option.Map、Result.Map 和其他函数式转换。
   *
   * @example
   *   type TIntToStr = specialize TFunc<Integer, string>;
   *   function IntToHex(const N: Integer): string;
   *   begin
   *     Result := Format('0x%x', [N]);
   *   end;
   *   var Mapper: TIntToStr := @IntToHex;
   *}
  generic TFunc<TArg, TResult> = function(const A: TArg): TResult;

  {**
   * TAction<TArg>
   *
   * @desc
   *   A generic procedure type that takes one argument and returns nothing.
   *   接受一个参数且无返回值的泛型过程类型。
   *
   * @usage
   *   Used for side-effect operations like logging, printing, or updating state.
   *   用于副作用操作，如日志记录、打印或状态更新。
   *
   * @example
   *   type TLogAction = specialize TAction<string>;
   *   procedure LogMessage(const Msg: string);
   *   begin
   *     WriteLn('[LOG] ', Msg);
   *   end;
   *   var Logger: TLogAction := @LogMessage;
   *}
  generic TAction<TArg> = procedure(const A: TArg);

  {**
   * TThunk<TResult>
   *
   * @desc
   *   A generic function type that takes no arguments and returns a result.
   *   无参数并返回结果的泛型函数类型。
   *
   * @usage
   *   Used for lazy evaluation, deferred computation, or factory functions.
   *   用于延迟求值、延迟计算或工厂函数。
   *
   * @example
   *   type TIntThunk = specialize TThunk<Integer>;
   *   function GetRandomNumber: Integer;
   *   begin
   *     Result := Random(100);
   *   end;
   *   var Factory: TIntThunk := @GetRandomNumber;
   *   WriteLn(Factory());  // 每次调用生成新的随机数
   *}
  generic TThunk<TResult> = function: TResult;

  {**
   * TPredicate<T>
   *
   * @desc
   *   A generic function type that takes one argument and returns a Boolean.
   *   接受一个参数并返回布尔值的泛型函数类型。
   *
   * @usage
   *   Used for filtering, validation, and conditional operations.
   *   用于过滤、验证和条件操作。
   *
   * @example
   *   type TIntPredicate = specialize TPredicate<Integer>;
   *   function IsEven(const N: Integer): Boolean;
   *   begin
   *     Result := (N mod 2) = 0;
   *   end;
   *   var Filter: TIntPredicate := @IsEven;
   *   // 用于 Vec.Filter、Option.Filter 等
   *}
  generic TPredicate<T> = function(const A: T): Boolean;

  {**
   * TComparer<T>
   *
   * @desc
   *   A generic function type for comparing two values.
   *   Returns negative if A < B, zero if A = B, positive if A > B.
   *   用于比较两个值的泛型函数类型。
   *   A < B 返回负数，A = B 返回零，A > B 返回正数。
   *
   * @usage
   *   Used for sorting, ordering, and comparison operations.
   *   用于排序、排序和比较操作。
   *
   * @example
   *   type TIntComparer = specialize TComparer<Integer>;
   *   function CompareIntegers(const A, B: Integer): Integer;
   *   begin
   *     Result := A - B;  // 升序排序
   *   end;
   *   var Comparer: TIntComparer := @CompareIntegers;
   *   // 用于 Vec.Sort、TreeMap 等
   *}
  generic TComparer<T> = function(const A, B: T): Integer;

  {**
   * TEquality<T>
   *
   * @desc
   *   A generic function type for testing equality of two values.
   *   用于测试两个值是否相等的泛型函数类型。
   *
   * @usage
   *   Used for custom equality comparisons in hash maps, sets, and deduplication.
   *   用于哈希映射、集合和去重中的自定义相等性比较。
   *
   * @example
   *   type TStringEquality = specialize TEquality<string>;
   *   function CaseInsensitiveEqual(const A, B: string): Boolean;
   *   begin
   *     Result := LowerCase(A) = LowerCase(B);
   *   end;
   *   var Equality: TStringEquality := @CaseInsensitiveEqual;
   *   // 用于 HashMap 的自定义键比较
   *}
  generic TEquality<T> = function(const A, B: T): Boolean;

  {**
   * TBiFunc<T1, T2, TResult>
   *
   * @desc
   *   A generic function type that takes two arguments and returns a result.
   *   接受两个参数并返回结果的泛型函数类型。
   *
   * @usage
   *   Used for binary operations, combining values, or transformations with two inputs.
   *   用于二元操作、组合值或双输入转换。
   *
   * @example
   *   type TIntCombiner = specialize TBiFunc<Integer, Integer, Integer>;
   *   function Add(const A, B: Integer): Integer;
   *   begin
   *     Result := A + B;
   *   end;
   *   var Combiner: TIntCombiner := @Add;
   *   // 用于 Fold、Reduce 等聚合操作
   *}
  generic TBiFunc<T1, T2, TResult> = function(const A: T1; const B: T2): TResult;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  { 匿名引用版本 | Anonymous reference versions }

  {**
   * TRefFunc<TArg, TResult>
   *
   * @desc
   *   Anonymous reference version of TFunc.
   *   TFunc 的匿名引用版本。
   *}
  generic TRefFunc<TArg, TResult> = reference to function(const A: TArg): TResult;

  {**
   * TRefAction<TArg>
   *
   * @desc
   *   Anonymous reference version of TAction.
   *   TAction 的匿名引用版本。
   *}
  generic TRefAction<TArg> = reference to procedure(const A: TArg);

  {**
   * TRefThunk<TResult>
   *
   * @desc
   *   Anonymous reference version of TThunk.
   *   TThunk 的匿名引用版本。
   *}
  generic TRefThunk<TResult> = reference to function: TResult;

  {**
   * TRefPredicate<T>
   *
   * @desc
   *   Anonymous reference version of TPredicate.
   *   TPredicate 的匿名引用版本。
   *}
  generic TRefPredicate<T> = reference to function(const A: T): Boolean;

  {**
   * TRefComparer<T>
   *
   * @desc
   *   Anonymous reference version of TComparer.
   *   TComparer 的匿名引用版本。
   *}
  generic TRefComparer<T> = reference to function(const A, B: T): Integer;

  {**
   * TRefEquality<T>
   *
   * @desc
   *   Anonymous reference version of TEquality.
   *   TEquality 的匿名引用版本。
   *}
  generic TRefEquality<T> = reference to function(const A, B: T): Boolean;

  {**
   * TRefBiFunc<T1, T2, TResult>
   *
   * @desc
   *   Anonymous reference version of TBiFunc.
   *   TBiFunc 的匿名引用版本。
   *}
  generic TRefBiFunc<T1, T2, TResult> = reference to function(const A: T1; const B: T2): TResult;
  {$ENDIF}

{ exception system 异常系统 }

type

  {**
   * ECore
   *
   * @desc
   *   The base exception class for all errors raised by the fafafa.core framework.
   *   fafafa.core 框架抛出的所有错误的基类异常.
   *
   * @example
   *   // 捕获所有 fafafa.core 框架异常
   *   try
   *     Vec.Get(Index);
   *   except
   *     on E: ECore do
   *       WriteLn('Framework error: ', E.Message);
   *   end;
   *}
  ECore = class(Exception) end;

  {**
   * EWow
   *
   * @desc
   *   A special exception that should not normally be triggered, indicating a surprising or unexpected internal state.
   *   一个通常不应被触发的特殊异常, 表明一个令人惊讶或意料之外的内部状态.
   *}
  EWow = class(ECore) end;

  {**
   * EArgumentNil
   *
   * @desc
   *   Raised when a required pointer, interface, or object argument is `nil`.
   *   当一个必需的指针、接口或对象参数为 `nil` 时抛出.
   *
   * @example
   *   procedure ProcessData(AAllocator: IAllocator);
   *   begin
   *     if AAllocator = nil then
   *       raise EArgumentNil.Create('Allocator cannot be nil');
   *     // 使用 allocator...
   *   end;
   *}
  EArgumentNil = class(ECore) end;

  {**
   * EEmptyCollection
   *
   * @desc
   *   Raised when an operation is performed on an empty collection that requires it to be non-empty.
   *   当在一个空集合上执行需要其非空的操作时抛出.
   *
   * @example
   *   function GetFirst<T>(const Vec: TVec<T>): T;
   *   begin
   *     if Vec.IsEmpty then
   *       raise EEmptyCollection.Create('Cannot get first element from empty vector');
   *     Result := Vec[0];
   *   end;
   *}
  EEmptyCollection = class(ECore) end;

  {**
   * EInvalidArgument
   *
   * @desc
   *   Raised when the value of an argument is unacceptable, but not covered by a more specific exception type.
   *   当一个参数的值不可接受, 但又没有更具体的异常类型可以描述时抛出.
   *
   * @example
   *   procedure SetCapacity(ACapacity: SizeUInt);
   *   begin
   *     if ACapacity = 0 then
   *       raise EInvalidArgument.Create('Capacity must be greater than zero');
   *     // 设置容量...
   *   end;
   *}
  EInvalidArgument = class(ECore) end;

  {**
   * EInvalidResult
   *
   * @desc
   *   Raised when the result of an operation is unacceptable, but not covered by a more specific exception type.
   *   当一个操作的结果不可接受, 但又没有更具体的异常类型可以描述时抛出.
   *
   * @example
   *   function ParseInteger(const S: string): Integer;
   *   var
   *     Code: Integer;
   *   begin
   *     Val(S, Result, Code);
   *     if Code <> 0 then
   *       raise EInvalidResult.CreateFmt('Failed to parse "%s" as integer', [S]);
   *   end;
   *}
  EInvalidResult = class(ECore) end;

  {**
   * ETimeoutError
   *
   * @desc
   *   Raised when an operation times out.
   *   当操作超时时抛出.
   *
   * @example
   *   function WaitForResponse(TimeoutMs: Integer): TResponse;
   *   begin
   *     if not WaitForData(TimeoutMs) then
   *       raise ETimeoutError.CreateFmt('Operation timed out after %d ms', [TimeoutMs]);
   *     Result := ReadResponse;
   *   end;
   *}
  ETimeoutError = class(ECore) end;

  {**
   * EInvalidState
   *
   * @desc
   *   Raised when an object is in an invalid state for the requested operation.
   *   当对象处于无效状态无法执行请求的操作时抛出.
   *
   * @example
   *   procedure TConnection.Send(const Data: TBytes);
   *   begin
   *     if not FConnected then
   *       raise EInvalidState.Create('Cannot send data: connection is not established');
   *     // 发送数据...
   *   end;
   *}
  EInvalidState = class(ECore) end;





  {**
   * EOutOfRange
   *
   * @desc
   *   Raised when an argument (e.g., an index or count) is outside its valid range of values.
   *   当一个参数 (例如: 索引或数量) 超出其有效范围时抛出.
   *
   * @example
   *   function GetElement(Index: SizeInt): T;
   *   begin
   *     if (Index < 0) or (Index >= FCount) then
   *       raise EOutOfRange.CreateFmt('Index %d out of range [0..%d)', [Index, FCount - 1]);
   *     Result := FItems[Index];
   *   end;
   *}

  EOutOfRange = class(ECore) end;

  {**
   * ENotSupported
   *
   * @desc
   *   Raised when a called method or operation is not supported by the object.
   *   当调用的方法或操作不被此对象支持时抛出.
   *
   * @example
   *   procedure TReadOnlyCollection.Add(const Item: T);
   *   begin
   *     raise ENotSupported.Create('Add operation is not supported on read-only collection');
   *   end;
   *}
  ENotSupported = class(ECore) end;

  {**
   * ENotCompatible
   *
   * @desc
   *   Raised when two objects are not compatible.
   *   当两个对象不兼容时抛出.
   *
   * @example
   *   procedure Merge(const A, B: TCollection);
   *   begin
   *     if A.ElementType <> B.ElementType then
   *       raise ENotCompatible.Create('Cannot merge collections with different element types');
   *     // 合并集合...
   *   end;
   *}
  ENotCompatible = class(ECore) end;

  {**
   * EInvalidOperation
   *
   * @desc
   *   Raised when an operation is not valid for the current state of the object.
   *   当操作对于对象的当前状态无效时抛出.
   *
   * @example
   *   procedure TIterator.Remove;
   *   begin
   *     if not FCanRemove then
   *       raise EInvalidOperation.Create('Cannot remove: no element has been retrieved yet');
   *     // 执行删除...
   *   end;
   *}
  EInvalidOperation = class(ECore) end;

  {**
   * EOutOfMemory
   *
   * @desc
   *   Raised when a memory allocation fails.
   *   当内存分配失败时抛出.
   *
   * @example
   *   function AllocateBuffer(Size: SizeUInt): Pointer;
   *   begin
   *     Result := GetMem(Size);
   *     if Result = nil then
   *       raise EOutOfMemory.CreateFmt('Failed to allocate %d bytes', [Size]);
   *   end;
   *}
  EOutOfMemory = class(ECore) end;

  {**
   * EOverflow
   *
   * @desc
   *   Raised when an operation overflows.
   *   当操作溢出时抛出.
   *
   * @example
   *   function SafeAdd(A, B: Int64): Int64;
   *   begin
   *     if (B > 0) and (A > High(Int64) - B) then
   *       raise EOverflow.Create('Integer overflow in addition');
   *     if (B < 0) and (A < Low(Int64) - B) then
   *       raise EOverflow.Create('Integer underflow in addition');
   *     Result := A + B;
   *   end;
   *}
  EOverflow = class(ECore) end;

const

  MAX_SIZE_INT  = High(SizeInt);
  MAX_SIZE_UINT = High(SizeUInt);
  MAX_UINT8     = High(UInt8);
  MAX_INT8      = High(Int8);
  MAX_UINT16    = High(UInt16);
  MAX_INT16     = High(Int16);
  MAX_UINT32    = High(UInt32);
  MAX_INT32     = High(Int32);
  MAX_UINT64    = High(UInt64);
  MAX_INT64     = High(Int64);

  MIN_SIZE_INT  = Low(SizeInt);
  MIN_INT8      = Low(Int8);
  MIN_INT16     = Low(Int16);
  MIN_INT32     = Low(Int32);
  MIN_INT64     = Low(Int64);

  SIZE_PTR = SizeOf(Pointer);
  SIZE_8   = SizeOf(UInt8);
  SIZE_16  = SizeOf(UInt16);
  SIZE_32  = SizeOf(UInt32);
  SIZE_64  = SizeOf(UInt64);

type

  TStringArray = array of string;
  // Canonical bytes alias across the framework
  TBytes = array of Byte;

  {**
   * TTuple2<TFirst, TSecond>
   *
   * @desc
   *   A generic two-element tuple type for combining two values of different types.
   *   用于组合两个不同类型值的泛型二元组类型。
   *
   * @usage
   *   Used for returning multiple values from functions, representing key-value pairs,
   *   or combining related data without creating a full class.
   *   用于从函数返回多个值、表示键值对或组合相关数据而无需创建完整的类。
   *
   * @example
   *   // 返回多个值
   *   type TDivResult = specialize TTuple2<Integer, Integer>;
   *   function DivMod(A, B: Integer): TDivResult;
   *   begin
   *     Result := TDivResult.Create(A div B, A mod B);
   *   end;
   *
   *   // 使用示例
   *   var Result: TDivResult;
   *   Result := DivMod(17, 5);
   *   WriteLn('Quotient: ', Result.First, ', Remainder: ', Result.Second);
   *   // 输出: Quotient: 3, Remainder: 2
   *}
  generic TTuple2<TFirst, TSecond> = record
    First: TFirst;
    Second: TSecond;
    class function Create(const AFirst: TFirst; const ASecond: TSecond): TTuple2; static; inline;
  end;

  {**
   * TTuple3<T1, T2, T3>
   *
   * @desc
   *   A generic three-element tuple type for combining three values of different types.
   *   用于组合三个不同类型值的泛型三元组类型。
   *
   * @usage
   *   Used for returning multiple related values, representing complex data structures,
   *   or combining three pieces of information without creating a dedicated record type.
   *   用于返回多个相关值、表示复杂数据结构或组合三个信息片段而无需创建专用记录类型。
   *
   * @example
   *   // 解析结果：值、是否成功、错误信息
   *   type TParseResult = specialize TTuple3<Integer, Boolean, string>;
   *   function ParseInt(const S: string): TParseResult;
   *   var
   *     Value, Code: Integer;
   *   begin
   *     Val(S, Value, Code);
   *     if Code = 0 then
   *       Result := TParseResult.Create(Value, True, '')
   *     else
   *       Result := TParseResult.Create(0, False, 'Invalid integer format');
   *   end;
   *
   *   // 使用示例
   *   var ParseResult: TParseResult;
   *   ParseResult := ParseInt('123');
   *   if ParseResult.Second then
   *     WriteLn('Parsed value: ', ParseResult.First)
   *   else
   *     WriteLn('Error: ', ParseResult.Third);
   *}
  generic TTuple3<T1, T2, T3> = record
    First: T1;
    Second: T2;
    Third: T3;
    class function Create(const A1: T1; const A2: T2; const A3: T3): TTuple3; static; inline;
  end;

  {**
   * TTuple4<T1, T2, T3, T4>
   *
   * @desc
   *   A generic four-element tuple type for combining four values of different types.
   *   用于组合四个不同类型值的泛型四元组类型。
   *
   * @usage
   *   Used for complex return values, representing structured data with multiple fields,
   *   or combining four related pieces of information without creating a dedicated record type.
   *   用于复杂返回值、表示具有多个字段的结构化数据或组合四个相关信息片段而无需创建专用记录类型。
   *
   * @example
   *   // 数据库查询结果：ID、名称、状态、时间戳
   *   type TQueryResult = specialize TTuple4<Integer, string, Boolean, Int64>;
   *   function QueryUser(UserID: Integer): TQueryResult;
   *   begin
   *     // 模拟数据库查询
   *     Result := TQueryResult.Create(
   *       UserID,           // ID
   *       'John Doe',       // 名称
   *       True,             // 活跃状态
   *       1234567890        // 最后登录时间戳
   *     );
   *   end;
   *
   *   // 使用示例
   *   var UserData: TQueryResult;
   *   UserData := QueryUser(123);
   *   WriteLn('User: ', UserData.Second);
   *   WriteLn('Active: ', UserData.Third);
   *   WriteLn('Last Login: ', UserData.Fourth);
   *}
  generic TTuple4<T1, T2, T3, T4> = record
    First: T1;
    Second: T2;
    Third: T3;
    Fourth: T4;
    class function Create(const A1: T1; const A2: T2; const A3: T3; const A4: T4): TTuple4; static; inline;
  end;

type

  {**
   * TRandomGeneratorFunc
   *
   * @desc
   *   A function that generates a random number.
   *   一个生成随机数的函数回调.
   *
   * @param
   *   aRange - The range of the random number.
   *   随机数的范围.
   *}
  TRandomGeneratorFunc = function(aRange: Int64; aData: Pointer): Int64;

  {**
   * TRandomGeneratorMethod
   *
   * @desc
   *   A method that generates a random number.
   *   一个生成随机数的类方法回调.
   *}
  TRandomGeneratorMethod = function(aRange: Int64; aData: Pointer): Int64 of object;

  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  {**
   * TRandomGeneratorRefFunc
   *
   * @desc
   *   A function that generates a random number.
   *   一个生成随机数的函数回调.
   *}
  TRandomGeneratorRefFunc = reference to function(aRange: Int64): Int64;
  {$ENDIF}

implementation

{ TTuple2<TFirst, TSecond> }

class function TTuple2.Create(const AFirst: TFirst; const ASecond: TSecond): TTuple2;
begin
  Result.First := AFirst;
  Result.Second := ASecond;
end;

{ TTuple3<T1, T2, T3> }

class function TTuple3.Create(const A1: T1; const A2: T2; const A3: T3): TTuple3;
begin
  Result.First := A1;
  Result.Second := A2;
  Result.Third := A3;
end;

{ TTuple4<T1, T2, T3, T4> }

class function TTuple4.Create(const A1: T1; const A2: T2; const A3: T3; const A4: T4): TTuple4;
begin
  Result.First := A1;
  Result.Second := A2;
  Result.Third := A3;
  Result.Fourth := A4;
end;

end.
