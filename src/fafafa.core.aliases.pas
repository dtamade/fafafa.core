unit fafafa.core.aliases;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.option, fafafa.core.result;

type
  // 常用别名（按需扩展）
  TOptionStr = specialize TOption<string>;
  TOptionInt = specialize TOption<Integer>;
  TResultIntStr = specialize TResult<Integer,string>;

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

