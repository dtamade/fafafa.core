{$CODEPAGE UTF8}
unit fafafa.core.option.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.option, fafafa.core.result;

type
  TTestCase_Option = class(TTestCase)
  published
    procedure Test_Some_None_Query_Unwrap;
    procedure Test_Map_AndThen_Inspect_Debug;
    procedure Test_MapOr_MapOrElse_Filter;
    procedure Test_FromNullable_And_Strings;
    procedure Test_Interop_With_Result;
  end;

implementation

procedure TTestCase_Option.Test_Some_None_Query_Unwrap;
var
  O1, O2: specialize TOption<Integer>;
begin
  O1 := specialize TOption<Integer>.Some(7);
  CheckTrue(O1.IsSome);
  CheckEquals(7, O1.Unwrap);
  CheckEquals(7, O1.UnwrapOr(9));

  O2 := specialize TOption<Integer>.None;
  CheckTrue(O2.IsNone);
  CheckEquals(9, O2.UnwrapOr(9));
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException(EOptionUnwrapError, procedure begin O2.Unwrap; end);
  {$ELSE}
  try
    O2.Unwrap; Fail('unwrap on None should raise');
  except on E: EOptionUnwrapError do ; end;
  {$ENDIF}
end;

procedure TTestCase_Option.Test_Map_AndThen_Inspect_Debug;
var
  O: specialize TOption<Integer>;
  O2: specialize TOption<Integer>;
  Seen: Integer;
  S: string;
begin
  O := specialize TOption<Integer>.Some(3);
  O2 := specialize OptionMap<Integer,Integer>(O,
    function (const X: Integer): Integer begin Result := X+1; end);
  CheckTrue(O2.IsSome); CheckEquals(4, O2.Unwrap);

  O2 := specialize OptionAndThen<Integer,Integer>(O,
    function (const X: Integer): specialize TOption<Integer>
    begin
      if X>0 then Result := specialize TOption<Integer>.Some(X*2)
      else Result := specialize TOption<Integer>.None;
    end);
  CheckTrue(O2.IsSome); CheckEquals(6, O2.Unwrap);

  Seen := 0;
  O := O.Inspect(procedure (const X: Integer) begin Inc(Seen, X); end);
  CheckEquals(3, Seen);

  S := O.ToDebugString(function (const X: Integer): string begin Result := IntToStr(X); end);
  CheckEquals('Some(3)', S);
end;

procedure TTestCase_Option.Test_MapOr_MapOrElse_Filter;
var
  O: specialize TOption<Integer>;
  S: Integer;
  O2: specialize TOption<Integer>;
begin
  O := specialize TOption<Integer>.Some(10);
  S := specialize OptionMapOr<Integer,Integer>(O, -1, function (const X: Integer): Integer begin Result := X div 2; end);
  CheckEquals(5, S);

  O := specialize TOption<Integer>.None;
  S := specialize OptionMapOr<Integer,Integer>(O, -1, function (const X: Integer): Integer begin Result := X div 2; end);
  CheckEquals(-1, S);

  O := specialize TOption<Integer>.Some(3);
  S := specialize OptionMapOrElse<Integer,Integer>(O,
    function: Integer begin Result := -2; end,
    function (const X: Integer): Integer begin Result := X+7; end);
  CheckEquals(10, S);

  O := specialize TOption<Integer>.None;
  S := specialize OptionMapOrElse<Integer,Integer>(O,
    function: Integer begin Result := -2; end,
    function (const X: Integer): Integer begin Result := X+7; end);
  CheckEquals(-2, S);

  O := specialize TOption<Integer>.Some(4);
  O2 := specialize OptionFilter<Integer>(O, function (const X: Integer): Boolean begin Result := (X mod 2)=0; end);
  CheckTrue(O2.IsSome); CheckEquals(4, O2.Unwrap);
  O2 := specialize OptionFilter<Integer>(O, function (const X: Integer): Boolean begin Result := (X mod 2)=1; end);
  CheckTrue(O2.IsNone);
end;

procedure TTestCase_Option.Test_FromNullable_And_Strings;
var
  Oi: specialize TOption<IInterface>;
  Os: specialize TOption<string>;
  Ot: specialize TOption<Integer>;
begin
  // FromBool
  Ot := specialize OptionFromBool<Integer>(True, 99);
  CheckTrue(Ot.IsSome); CheckEquals(99, Ot.Unwrap);
  Ot := specialize OptionFromBool<Integer>(False, 99);
  CheckTrue(Ot.IsNone);

  // FromString
  Os := OptionFromString('', True);
  CheckTrue(Os.IsNone);
  Os := OptionFromString('', False);
  CheckTrue(Os.IsSome); CheckEquals('', Os.Unwrap);
  Os := OptionFromString('abc');
  CheckTrue(Os.IsSome); CheckEquals('abc', Os.Unwrap);

  // FromValue
  Ot := specialize OptionFromValue<Integer>(True, 7);
  CheckTrue(Ot.IsSome); CheckEquals(7, Ot.Unwrap);
  Ot := specialize OptionFromValue<Integer>(False, 7);
  CheckTrue(Ot.IsNone);

  // FromInterface
  Oi := OptionFromInterface(nil);
  CheckTrue(Oi.IsNone);
end;

procedure TTestCase_Option.Test_Interop_With_Result;
var
  O: specialize TOption<Integer>;
  R: specialize TResult<Integer,String>;
  OE: specialize TOption<String>;
begin
  O := specialize TOption<Integer>.Some(1);
  R := specialize OptionToResult<Integer,String>(O, 'e');
  CheckTrue(R.IsOk); CheckEquals(1, R.Unwrap);

  O := specialize TOption<Integer>.None;
  R := specialize OptionToResult<Integer,String>(O, 'e');
  CheckTrue(R.IsErr); CheckEquals('e', R.UnwrapErr);

  O := specialize ResultToOption<Integer,String>(specialize TResult<Integer,String>.Ok(8));
  CheckTrue(O.IsSome); CheckEquals(8, O.Unwrap);
  O := specialize ResultToOption<Integer,String>(specialize TResult<Integer,String>.Err('e'));
  CheckTrue(O.IsNone);

  OE := specialize ResultErrOption<Integer,String>(specialize TResult<Integer,String>.Err('boom'));
  CheckTrue(OE.IsSome); CheckEquals('boom', OE.Unwrap);
  OE := specialize ResultErrOption<Integer,String>(specialize TResult<Integer,String>.Ok(42));
  CheckTrue(OE.IsNone);
end;

initialization
  RegisterTest(TTestCase_Option);
end.

