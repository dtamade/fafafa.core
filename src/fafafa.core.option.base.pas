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
  SysUtils,
  fafafa.core.base;  // ✅ OPT-001: 引入 ECore 基类

const
  {** 模块版本 | Module version *}
  FAFAFA_CORE_OPTION_BASE_VERSION = '1.0.0';

type
  { EOptionUnwrapError - Option 解包错误 }
  EOptionUnwrapError = class(ECore);  // ✅ OPT-001: 继承自 ECore

  { 函数类型定义 }
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  generic TOptionFunc<TArg, TRes> = reference to function (const Arg: TArg): TRes;
  generic TOptionProc<TArg> = reference to procedure (const Arg: TArg);
  generic TOptionThunk<TResult> = reference to function: TResult;
  generic TOptionBiPred<T1, T2> = reference to function(const A: T1; const B: T2): Boolean;
  {$ELSE}
  // FPC 3.2.x 兼容：使用传统函数指针类型
  generic TOptionFunc<TArg, TRes> = function (const Arg: TArg): TRes;
  generic TOptionProc<TArg> = procedure (const Arg: TArg);
  generic TOptionThunk<TResult> = function: TResult;
  generic TOptionBiPred<T1, T2> = function(const A: T1; const B: T2): Boolean;
  {$ENDIF}

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
    class operator Initialize(var aRec: TOption);  // ✅ FIX: 确保默认为 None
  public
    { 内部使用：无检查访问器 }
    function GetValueUnchecked: T; inline;

    { 构造 }
    class function Some(const aValue: T): TOption; static; inline;
    class function None: TOption; static; inline;

    { 查询 }
    function IsSome: Boolean; inline;
    function IsNone: Boolean; inline;

    { 取值 }
    function Unwrap: T; inline;              // None -> EOptionUnwrapError
    function UnwrapOr(const aDefault: T): T; inline;
    function UnwrapOrElse(const aF: specialize TOptionThunk<T>): T; inline;
    function UnwrapOrDefault: T; inline;
    function Expect(const aMsg: string): T; inline; // None -> EOptionUnwrapError(aMsg)

    { 安全取值 }
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

implementation

{ TOption<T> }

class operator TOption.Initialize(var aRec: TOption);
begin
  // ✅ FIX: 确保未初始化的变量默认为 None 状态
  // 与 TResult 保持一致的初始化语义
  aRec.FHas := False;
  aRec.FValue := Default(T);
end;

class function TOption.Some(const aValue: T): TOption;
begin
  Result.FHas := True;
  Result.FValue := aValue;
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

function TOption.UnwrapOr(const aDefault: T): T;
begin
  if FHas then
    Result := FValue
  else
    Result := aDefault;
end;

function TOption.UnwrapOrElse(const aF: specialize TOptionThunk<T>): T;
begin
  if FHas then
    Exit(FValue);

  if aF = nil then
    raise EArgumentNil.Create('aF is nil');

  Result := aF();
end;

function TOption.UnwrapOrDefault: T;
begin
  if FHas then
    Result := FValue
  else
    Result := Default(T);
end;

function TOption.Expect(const aMsg: string): T;
begin
  if not FHas then
    raise EOptionUnwrapError.Create(aMsg);
  Result := FValue;
end;

function TOption.TryUnwrap(out aValue: T): Boolean;
begin
  if FHas then
  begin
    aValue := FValue;
    Result := True;
  end
  else
  begin
    aValue := Default(T);
    Result := False;
  end;
end;

function TOption.GetValueUnchecked: T;
begin
  Result := FValue;
end;

function TOption.Inspect(const aF: specialize TOptionProc<T>): TOption;
begin
  if FHas then
  begin
    if aF = nil then
      raise EArgumentNil.Create('aF is nil');
    aF(FValue);
  end;
  Result := Self;
end;

function TOption.ToDebugString(const aPrinter: specialize TOptionFunc<T, string>): string;
begin
  if FHas then
  begin
    if Assigned(aPrinter) then
      Result := 'Some(' + aPrinter(FValue) + ')'
    else
      Result := 'Some(?)';
  end
  else
    Result := 'None';
end;

function TOption.IsSomeAnd(const aPred: specialize TOptionFunc<T, Boolean>): Boolean;
begin
  if FHas then
  begin
    if aPred = nil then
      raise EArgumentNil.Create('aPred is nil');
    Result := aPred(FValue);
  end
  else
    Result := False;
end;

function TOption.Contains(const aValue: T; const aEq: specialize TOptionBiPred<T, T>): Boolean;
begin
  if FHas then
  begin
    if aEq = nil then
      raise EArgumentNil.Create('aEq is nil');
    Result := aEq(FValue, aValue);
  end
  else
    Result := False;
end;

function TOption.Or_(const aOther: TOption): TOption;
begin
  if FHas then
    Result := Self
  else
    Result := aOther;
end;

function TOption.And_(const aOther: TOption): TOption;
begin
  if FHas then
    Result := aOther
  else
    Result := Self;
end;

function TOption.Xor_(const aOther: TOption): TOption;
begin
  if FHas and (not aOther.FHas) then
    Result := Self
  else if (not FHas) and aOther.FHas then
    Result := aOther
  else
    Result := specialize TOption<T>.None;
end;

end.
