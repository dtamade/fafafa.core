unit fafafa.core.args.fx;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.args,
  fafafa.core.option;

type
  // 非侵入式的 Args 函数式包装器：不改 IArgs 接口与 TArgs，对外提供 Option/Result 风格 API
  TArgsFx = record
  private
    FArgs: IArgs;
  public
    // 构造/来源
    class function FromProcess: TArgsFx; static;
    class function FromArray(const A: array of string; const Opts: TArgsOptions): TArgsFx; static;
    class function FromIArgs(const A: IArgs): TArgsFx; static; inline;

    // 查询（Option/Result 风格）
    function ValueOpt(const Key: string): specialize TOption<string>;
    function Int64Opt(const Key: string): specialize TOption<Int64>;
    function DoubleOpt(const Key: string): specialize TOption<Double>;
    function BoolOpt(const Key: string): specialize TOption<boolean>;

    // 透传原语
    function Underlying: IArgs; inline;
  end;

implementation

{ TArgsFx }
class function TArgsFx.FromProcess: TArgsFx;
begin
  Result.FArgs := TArgs.FromProcess as IArgs;
end;

class function TArgsFx.FromArray(const A: array of string; const Opts: TArgsOptions): TArgsFx;
begin
  Result.FArgs := TArgs.FromArray(A, Opts) as IArgs;
end;

class function TArgsFx.FromIArgs(const A: IArgs): TArgsFx; inline;
begin
  Result.FArgs := A;
end;

function TArgsFx.Underlying: IArgs; inline;
begin
  Result := FArgs;
end;

function TArgsFx.ValueOpt(const Key: string): specialize TOption<string>;
var s: string;
begin
  if (FArgs<>nil) and FArgs.TryGetValue(Key, s) then
    Exit(specialize TOption<string>.Some(s))
  else
    Exit(specialize TOption<string>.None);
end;

function TArgsFx.Int64Opt(const Key: string): specialize TOption<Int64>;
var s: string; v: Int64;
begin
  if (FArgs<>nil) and FArgs.TryGetValue(Key, s) and TryStrToInt64(s, v) then
    Exit(specialize TOption<Int64>.Some(v))
  else
    Exit(specialize TOption<Int64>.None);
end;

function TArgsFx.DoubleOpt(const Key: string): specialize TOption<Double>;
var s: string; v: Double;
begin
  if (FArgs<>nil) and FArgs.TryGetValue(Key, s) and TryStrToFloat(s, v) then
    Exit(specialize TOption<Double>.Some(v))
  else
    Exit(specialize TOption<Double>.None);
end;

function TArgsFx.BoolOpt(const Key: string): specialize TOption<boolean>;
var s: string;
begin
  if (FArgs=nil) or (not FArgs.TryGetValue(Key, s)) then
    Exit(specialize TOption<boolean>.None);
  if SameText(s, 'true') or (s='1') or SameText(s,'yes') then Exit(specialize TOption<boolean>.Some(True));
  if SameText(s, 'false') or (s='0') or SameText(s,'no') then Exit(specialize TOption<boolean>.Some(False));
  Exit(specialize TOption<boolean>.None);
end;

end.

