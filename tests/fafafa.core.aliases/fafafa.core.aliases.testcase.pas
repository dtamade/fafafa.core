{$CODEPAGE UTF8}
unit fafafa.core.aliases.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.aliases, fafafa.core.option, fafafa.core.result;

type
  TTestCase_Aliases = class(TTestCase)
  published
    procedure Test_Some_None_Ok_Err;
    procedure Test_OptionToResultElse;
  end;

implementation

procedure TTestCase_Aliases.Test_Some_None_Ok_Err;
var
  O: TOptionInt;
  R: TResultIntStr;
begin
  O := specialize Some<Integer>(7);
  CheckTrue(O.IsSome); CheckEquals(7, O.Unwrap);
  O := specialize None<Integer>;
  CheckTrue(O.IsNone);

  R := specialize Ok<Integer,string>(1);
  CheckTrue(R.IsOk); CheckEquals(1, R.Unwrap);
  R := specialize Err<Integer,string>('e');
  CheckTrue(R.IsErr); CheckEquals('e', R.UnwrapErr);
end;

procedure TTestCase_Aliases.Test_OptionToResultElse;
var
  O: TOptionStr;
  R: TResultIntStr;
begin
  O := TOptionStr.Some('x');
  R := specialize OptionToResultElse<Integer,string>(
    specialize OptionAndThen<string,Integer>(O, function (const S: string): specialize TOption<Integer>
    begin
      if Length(S)>0 then Result := specialize TOption<Integer>.Some(42)
      else Result := specialize TOption<Integer>.None;
    end),
    function: string begin Result := 'boom'; end);
  CheckTrue(R.IsOk); CheckEquals(42, R.Unwrap);

  O := TOptionStr.None;
  R := specialize OptionToResultElse<Integer,string>(
    specialize OptionAndThen<string,Integer>(O, function (const S: string): specialize TOption<Integer>
    begin
      Result := specialize TOption<Integer>.Some(1);
    end),
    function: string begin Result := 'boom'; end);
  CheckTrue(R.IsErr); CheckEquals('boom', R.UnwrapErr);
end;

initialization
  RegisterTest(TTestCase_Aliases);
end.

