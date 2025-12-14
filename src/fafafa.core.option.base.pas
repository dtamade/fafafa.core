unit fafafa.core.option.base;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.option.base - Option 类型基础定义

  此模块提供 TOption<T> 的核心定义，被 fafafa.core.result 和
  fafafa.core.option 共同引用，避免循环依赖和代码重复。

  设计决策：
  - TOption 只包含最基础的构造和查询方法
  - 组合子和高级功能在 fafafa.core.option 中实现
  - fafafa.core.result 仅依赖此基础模块
}

interface

uses
  SysUtils;

type
  { EOptionUnwrapError - Option 解包错误 }
  EOptionUnwrapError = class(Exception);

  { 函数类型定义 }
  generic TOptionFunc<TArg, TRes> = reference to function (const Arg: TArg): TRes;
  generic TOptionProc<TArg> = reference to procedure (const Arg: TArg);
  generic TOptionThunk<TResult> = reference to function: TResult;
  generic TOptionBiPred<T1, T2> = reference to function(const A: T1; const B: T2): Boolean;

  { TOption<T> - 可选值类型

    表示一个值可能存在(Some)或不存在(None)的情况。
    类似 Rust 的 Option<T> 和 Haskell 的 Maybe。

    用法：
      var Opt: specialize TOption<Integer>;
      Opt := specialize TOption<Integer>.Some(42);
      if Opt.IsSome then WriteLn(Opt.Unwrap);

      Opt := specialize TOption<Integer>.None;
      WriteLn(Opt.UnwrapOr(0)); // 输出 0
  }
  generic TOption<T> = record
  private
    FHas: Boolean;
    FValue: T;
  public
    { 内部使用：无检查访问器 }
    function GetValueUnchecked: T; inline;

    { 构造 }
    class function Some(const AValue: T): TOption; static; inline;
    class function None: TOption; static; inline;

    { 查询 }
    function IsSome: Boolean; inline;
    function IsNone: Boolean; inline;

    { 取值 }
    function Unwrap: T; inline;              // None -> EOptionUnwrapError
    function UnwrapOr(const ADefault: T): T; inline;
    function UnwrapOrElse(const F: specialize TOptionThunk<T>): T; inline;
    function UnwrapOrDefault: T; inline;
    function Expect(const AMsg: string): T; inline; // None -> EOptionUnwrapError(AMsg)

    { 安全取值 }
    function TryUnwrap(out AValue: T): Boolean; inline;

    { 组合子方法 }
    function Inspect(const F: specialize TOptionProc<T>): TOption; inline;
    function ToDebugString(const Printer: specialize TOptionFunc<T, string>): string;

    { 谓词检查 }
    function IsSomeAnd(const Pred: specialize TOptionFunc<T, Boolean>): Boolean; inline;
    function Contains(const V: T; const Eq: specialize TOptionBiPred<T, T>): Boolean; inline;

    { 逻辑组合 }
    function Or_(const Other: TOption): TOption; inline;
    function And_(const Other: TOption): TOption; inline;
    function Xor_(const Other: TOption): TOption; inline;
  end;

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
  Result.FValue := Default(T);
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
    raise EOptionUnwrapError.Create('Unwrap on None');
  Result := FValue;
end;

function TOption.UnwrapOr(const ADefault: T): T;
begin
  if FHas then
    Result := FValue
  else
    Result := ADefault;
end;

function TOption.UnwrapOrElse(const F: specialize TOptionThunk<T>): T;
begin
  if FHas then
    Result := FValue
  else
    Result := F();
end;

function TOption.UnwrapOrDefault: T;
begin
  if FHas then
    Result := FValue
  else
    Result := Default(T);
end;

function TOption.Expect(const AMsg: string): T;
begin
  if not FHas then
    raise EOptionUnwrapError.Create(AMsg);
  Result := FValue;
end;

function TOption.TryUnwrap(out AValue: T): Boolean;
begin
  if FHas then
  begin
    AValue := FValue;
    Result := True;
  end
  else
  begin
    AValue := Default(T);
    Result := False;
  end;
end;

function TOption.GetValueUnchecked: T;
begin
  Result := FValue;
end;

function TOption.Inspect(const F: specialize TOptionProc<T>): TOption;
begin
  if FHas then F(FValue);
  Result := Self;
end;

function TOption.ToDebugString(const Printer: specialize TOptionFunc<T, string>): string;
begin
  if FHas then
  begin
    if Assigned(Printer) then
      Result := 'Some(' + Printer(FValue) + ')'
    else
      Result := 'Some(?)';
  end
  else
    Result := 'None';
end;

function TOption.IsSomeAnd(const Pred: specialize TOptionFunc<T, Boolean>): Boolean;
begin
  if FHas then
    Result := Pred(FValue)
  else
    Result := False;
end;

function TOption.Contains(const V: T; const Eq: specialize TOptionBiPred<T, T>): Boolean;
begin
  if FHas then
    Result := Eq(FValue, V)
  else
    Result := False;
end;

function TOption.Or_(const Other: TOption): TOption;
begin
  if FHas then
    Result := Self
  else
    Result := Other;
end;

function TOption.And_(const Other: TOption): TOption;
begin
  if FHas then
    Result := Other
  else
    Result := Self;
end;

function TOption.Xor_(const Other: TOption): TOption;
begin
  if FHas and (not Other.FHas) then
    Result := Self
  else if (not FHas) and Other.FHas then
    Result := Other
  else
    Result := specialize TOption<T>.None;
end;

end.
