unit fafafa.core.aliases;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.option.base, fafafa.core.option, fafafa.core.result;

type
  { Option 便捷类型别名 }
  TOptionStr = specialize TOption<string>;
  TOptionInt = specialize TOption<Integer>;
  TOptionInt64 = specialize TOption<Int64>;
  TOptionBool = specialize TOption<Boolean>;
  TOptionDouble = specialize TOption<Double>;

  { Result 便捷类型别名 - 错误类型为 string }
  TStringResult = specialize TResult<string, string>;
  TIntResult = specialize TResult<Integer, string>;
  TInt64Result = specialize TResult<Int64, string>;
  TBoolResult = specialize TResult<Boolean, string>;
  TDoubleResult = specialize TResult<Double, string>;

  { 兼容旧名称 }
  TResultIntStr = specialize TResult<Integer, string>;

  { Result 便捷类型别名 - 错误类型为 Exception 派生类 }
  { 用于 IO 操作场景 }
  TIOResultInt = specialize TResult<Integer, EInOutError>;
  TIOResultStr = specialize TResult<string, EInOutError>;
  TIOResultBool = specialize TResult<Boolean, EInOutError>;
  { 用于解析/转换场景 }
  TParseResultInt = specialize TResult<Integer, EConvertError>;
  TParseResultStr = specialize TResult<string, EConvertError>;
  TParseResultInt64 = specialize TResult<Int64, EConvertError>;
  TParseResultDouble = specialize TResult<Double, EConvertError>;
  { 通用异常结果 }
  TExResultInt = specialize TResult<Integer, Exception>;
  TExResultStr = specialize TResult<string, Exception>;
  TExResultBool = specialize TResult<Boolean, Exception>;

// 轻量泛型辅助
// Some/None for Option
generic function Some<T>(const V: T): specialize TOption<T>;
generic function None<T>: specialize TOption<T>;
// Ok/Err for Result
generic function Ok<T,E>(const V: T): specialize TResult<T,E>;
generic function Err<T,E>(const EVal: E): specialize TResult<T,E>;

implementation

generic function Some<T>(const V: T): specialize TOption<T>;
begin
  Exit(specialize TOption<T>.Some(V));
end;

generic function None<T>: specialize TOption<T>;
begin
  Exit(specialize TOption<T>.None);
end;

generic function Ok<T,E>(const V: T): specialize TResult<T,E>;
begin
  Exit(specialize TResult<T,E>.Ok(V));
end;

generic function Err<T,E>(const EVal: E): specialize TResult<T,E>;
begin
  Exit(specialize TResult<T,E>.Err(EVal));
end;

end.

