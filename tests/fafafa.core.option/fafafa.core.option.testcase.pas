{$CODEPAGE UTF8}
unit fafafa.core.option.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.option.base,
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

  { Option nil 回调契约测试（防止 AV，提供更 Rust-like 的错误提示） }
  TTestCase_Option_CallbackContracts = class(TTestCase)
  published
    procedure Test_NilCallbacks_UnusedBranches_DoNotRaise;

    procedure Test_OptionMap_Some_NilFunc_Raises;
    procedure Test_OptionAndThen_Some_NilFunc_Raises;
    procedure Test_OptionMapOr_Some_NilFunc_Raises;
    procedure Test_OptionMapOrElse_Some_NilFok_Raises;
    procedure Test_OptionMapOrElse_None_NilFnone_Raises;
    procedure Test_OptionFilter_Some_NilPred_Raises;
    procedure Test_OptionZipWith_SomeSome_NilFunc_Raises;
    procedure Test_OptionToResultElse_None_NilThunk_Raises;
  end;

implementation

uses
  fafafa.core.base;

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

{ TTestCase_Option_CallbackContracts }

procedure TTestCase_Option_CallbackContracts.Test_NilCallbacks_UnusedBranches_DoNotRaise;
var
  O: specialize TOption<Integer>;
  O2: specialize TOption<Integer>;
  O3: specialize TOption<Integer>;
  MapF: specialize TOptionFunc<Integer, Integer>;
  AndThenF: specialize TOptionFunc<Integer, specialize TOption<Integer>>;
  Fnone: specialize TOptionThunk<Integer>;
  Fok: specialize TOptionFunc<Integer, Integer>;
  Pred: specialize TOptionFunc<Integer, Boolean>;
  ZipF: specialize TOptionFunc<specialize TPair<Integer, Integer>, Integer>;
  FerrThunk: specialize TOptionThunk<string>;
  R: specialize TResult<Integer, string>;
  V: Integer;
begin
  // OptionMap: None + nil mapper
  O := specialize TOption<Integer>.None;
  MapF := nil;
  O2 := specialize OptionMap<Integer, Integer>(O, MapF);
  CheckTrue(O2.IsNone);

  // OptionAndThen: None + nil func
  AndThenF := nil;
  O2 := specialize OptionAndThen<Integer, Integer>(O, AndThenF);
  CheckTrue(O2.IsNone);

  // OptionMapOr: None + nil mapper -> default
  V := specialize OptionMapOr<Integer, Integer>(O, 123, MapF);
  CheckEquals(123, V);

  // OptionMapOrElse: Some uses Fok; Fnone may be nil
  O := specialize TOption<Integer>.Some(1);
  Fnone := nil;
  Fok := function(const X: Integer): Integer begin Result := X + 1; end;
  V := specialize OptionMapOrElse<Integer, Integer>(O, Fnone, Fok);
  CheckEquals(2, V);

  // OptionMapOrElse: None uses Fnone; Fok may be nil
  O := specialize TOption<Integer>.None;
  Fok := nil;
  Fnone := function: Integer begin Result := 9; end;
  V := specialize OptionMapOrElse<Integer, Integer>(O, Fnone, Fok);
  CheckEquals(9, V);

  // OptionFilter: None + nil pred
  Pred := nil;
  O2 := specialize OptionFilter<Integer>(O, Pred);
  CheckTrue(O2.IsNone);

  // OptionZipWith: if any None, mapper not called
  ZipF := nil;
  O2 := specialize TOption<Integer>.None;
  O3 := specialize TOption<Integer>.Some(1);
  O2 := specialize OptionZipWith<Integer, Integer, Integer>(O2, O3, ZipF);
  CheckTrue(O2.IsNone);

  // OptionToResultElse: Some does not call FerrThunk
  FerrThunk := nil;
  O := specialize TOption<Integer>.Some(7);
  R := specialize OptionToResultElse<Integer, string>(O, FerrThunk);
  CheckTrue(R.IsOk);
  CheckEquals(7, R.Unwrap);
end;

procedure TTestCase_Option_CallbackContracts.Test_OptionMap_Some_NilFunc_Raises;
var
  O: specialize TOption<Integer>;
  F: specialize TOptionFunc<Integer, Integer>;
  O2: specialize TOption<Integer>;
begin
  O := specialize TOption<Integer>.Some(1);
  F := nil;
  try
    O2 := specialize OptionMap<Integer, Integer>(O, F);
    if O2.IsSome then; // suppress hint
    Fail('Expected exception: F is nil');
  except
    on E: EArgumentNil do
      CheckEquals('F is nil', E.Message);
  end;
end;

procedure TTestCase_Option_CallbackContracts.Test_OptionAndThen_Some_NilFunc_Raises;
var
  O: specialize TOption<Integer>;
  F: specialize TOptionFunc<Integer, specialize TOption<Integer>>;
  O2: specialize TOption<Integer>;
begin
  O := specialize TOption<Integer>.Some(1);
  F := nil;
  try
    O2 := specialize OptionAndThen<Integer, Integer>(O, F);
    if O2.IsSome then; // suppress hint
    Fail('Expected exception: F is nil');
  except
    on E: EArgumentNil do
      CheckEquals('F is nil', E.Message);
  end;
end;

procedure TTestCase_Option_CallbackContracts.Test_OptionMapOr_Some_NilFunc_Raises;
var
  O: specialize TOption<Integer>;
  F: specialize TOptionFunc<Integer, Integer>;
  V: Integer;
begin
  O := specialize TOption<Integer>.Some(1);
  F := nil;
  try
    V := specialize OptionMapOr<Integer, Integer>(O, 0, F);
    if V = V then; // suppress hint
    Fail('Expected exception: F is nil');
  except
    on E: EArgumentNil do
      CheckEquals('F is nil', E.Message);
  end;
end;

procedure TTestCase_Option_CallbackContracts.Test_OptionMapOrElse_Some_NilFok_Raises;
var
  O: specialize TOption<Integer>;
  Fnone: specialize TOptionThunk<Integer>;
  Fok: specialize TOptionFunc<Integer, Integer>;
  V: Integer;
begin
  O := specialize TOption<Integer>.Some(1);
  Fnone := function: Integer begin Result := 0; end;
  Fok := nil;
  try
    V := specialize OptionMapOrElse<Integer, Integer>(O, Fnone, Fok);
    if V = V then; // suppress hint
    Fail('Expected exception: Fok is nil');
  except
    on E: EArgumentNil do
      CheckEquals('Fok is nil', E.Message);
  end;
end;

procedure TTestCase_Option_CallbackContracts.Test_OptionMapOrElse_None_NilFnone_Raises;
var
  O: specialize TOption<Integer>;
  Fnone: specialize TOptionThunk<Integer>;
  Fok: specialize TOptionFunc<Integer, Integer>;
  V: Integer;
begin
  O := specialize TOption<Integer>.None;
  Fnone := nil;
  Fok := function(const X: Integer): Integer begin Result := X; end;
  try
    V := specialize OptionMapOrElse<Integer, Integer>(O, Fnone, Fok);
    if V = V then; // suppress hint
    Fail('Expected exception: Fnone is nil');
  except
    on E: EArgumentNil do
      CheckEquals('Fnone is nil', E.Message);
  end;
end;

procedure TTestCase_Option_CallbackContracts.Test_OptionFilter_Some_NilPred_Raises;
var
  O: specialize TOption<Integer>;
  Pred: specialize TOptionFunc<Integer, Boolean>;
  O2: specialize TOption<Integer>;
begin
  O := specialize TOption<Integer>.Some(1);
  Pred := nil;
  try
    O2 := specialize OptionFilter<Integer>(O, Pred);
    if O2.IsSome then; // suppress hint
    Fail('Expected exception: Pred is nil');
  except
    on E: EArgumentNil do
      CheckEquals('Pred is nil', E.Message);
  end;
end;

procedure TTestCase_Option_CallbackContracts.Test_OptionZipWith_SomeSome_NilFunc_Raises;
var
  A, B: specialize TOption<Integer>;
  F: specialize TOptionFunc<specialize TPair<Integer, Integer>, Integer>;
  O: specialize TOption<Integer>;
begin
  A := specialize TOption<Integer>.Some(1);
  B := specialize TOption<Integer>.Some(2);
  F := nil;
  try
    O := specialize OptionZipWith<Integer, Integer, Integer>(A, B, F);
    if O.IsSome then; // suppress hint
    Fail('Expected exception: F is nil');
  except
    on E: EArgumentNil do
      CheckEquals('F is nil', E.Message);
  end;
end;

procedure TTestCase_Option_CallbackContracts.Test_OptionToResultElse_None_NilThunk_Raises;
var
  O: specialize TOption<Integer>;
  FerrThunk: specialize TOptionThunk<string>;
  R: specialize TResult<Integer, string>;
begin
  O := specialize TOption<Integer>.None;
  FerrThunk := nil;
  try
    R := specialize OptionToResultElse<Integer, string>(O, FerrThunk);
    if R.IsOk then; // suppress hint
    Fail('Expected exception: FerrThunk is nil');
  except
    on E: EArgumentNil do
      CheckEquals('FerrThunk is nil', E.Message);
  end;
end;

initialization
  RegisterTest(TTestCase_Option);
  RegisterTest(TTestCase_Option_CallbackContracts);
end.

