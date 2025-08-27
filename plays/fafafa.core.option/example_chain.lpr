{$CODEPAGE UTF8}
program example_chain;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.option,
  fafafa.core.result;

function GetEnvOpt(const Name: string): specialize TOption<string>;
begin
  Result := OptionFromString(GetEnvironmentVariable(Name), True);
end;

function ParseIntOpt(const S: string): specialize TOption<Integer>;
var
  LValue: Integer;
begin
  if TryStrToInt(S, LValue) then
    Exit(specialize TOption<Integer>.Some(LValue))
  else
    Exit(specialize TOption<Integer>.None);
end;

function NonZero(const X: Integer): Boolean; begin Result := X<>0; end;

var OStr: specialize TOption<string>;
    OInt: specialize TOption<Integer>;
    R: specialize TResult<Integer,string>;
begin
  OStr := GetEnvOpt('MY_PORT');
  OInt := specialize OptionAndThen<string,Integer>(OStr, @ParseIntOpt);
  OInt := specialize OptionFilter<Integer>(OInt, @NonZero);
  R := specialize OptionToResult<Integer,string>(OInt, 'invalid port');
  if R.IsOk then WriteLn('port=', R.Unwrap) else WriteLn('ERR: ', R.UnwrapErr);
end.

