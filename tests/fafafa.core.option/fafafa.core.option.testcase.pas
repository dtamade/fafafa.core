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

    { UnwrapOrElse 测试 }
    procedure Test_UnwrapOrElse_Some_ReturnsValue;
    procedure Test_UnwrapOrElse_None_CallsFunction;
    procedure Test_UnwrapOrElse_None_NilFunction_Raises;

    { UnwrapOrDefault 测试 }
    procedure Test_UnwrapOrDefault_Some_ReturnsValue;
    procedure Test_UnwrapOrDefault_None_ReturnsDefault;

    { Expect 测试 }
    procedure Test_Expect_Some_ReturnsValue;
    procedure Test_Expect_None_RaisesWithMessage;

    { TryUnwrap 测试 }
    procedure Test_TryUnwrap_Some_ReturnsTrue;
    procedure Test_TryUnwrap_None_ReturnsFalse;

    { IsSomeAnd 测试 }
    procedure Test_IsSomeAnd_Some_PredicateTrue;
    procedure Test_IsSomeAnd_Some_PredicateFalse;
    procedure Test_IsSomeAnd_None_ReturnsFalse;

    { Contains 测试 }
    procedure Test_Contains_Some_Equal;
    procedure Test_Contains_Some_NotEqual;
    procedure Test_Contains_None_ReturnsFalse;

    { Or_ 逻辑或测试 }
    procedure Test_Or_Some_Some;
    procedure Test_Or_Some_None;
    procedure Test_Or_None_Some;

    { And_ 逻辑与测试 }
    procedure Test_And_Some_Some;
    procedure Test_And_Some_None;
    procedure Test_And_None_Some;

    { Xor_ 逻辑异或测试 }
    procedure Test_Xor_Some_None;
    procedure Test_Xor_None_Some;
    procedure Test_Xor_Some_Some;

    { Flatten 测试 }
    procedure Test_Flatten_SomeSome;
    procedure Test_Flatten_SomeNone;

    { Zip 测试 }
    procedure Test_Zip_SomeSome;
    procedure Test_Zip_SomeNone;
    procedure Test_Zip_NoneSome;
    procedure Test_Zip_NoneNone;

    { ZipWith 测试 }
    procedure Test_ZipWith_SomeSome;
    procedure Test_ZipWith_SomeNone;
    procedure Test_ZipWith_NoneSome;
    procedure Test_ZipWith_NoneNone;

    { OptionToResultElse 测试 }
    procedure Test_ToResultElse_Some;
    procedure Test_ToResultElse_None_CallsFunction;

    { ResultErrOption 测试 }
    procedure Test_ResultErrOption_Ok;
    procedure Test_ResultErrOption_Err;

    { Transpose 测试 }
    procedure Test_ResultTransposeOption_OkSome;
    procedure Test_ResultTransposeOption_OkNone;
    procedure Test_OptionTransposeResult_SomeOk;
    procedure Test_OptionTransposeResult_SomeErr;

    { FromInterface 测试 }
    procedure Test_FromInterface_NonNil;
    procedure Test_FromInterface_Nil;

    { P3 高级场景测试 }
    procedure Test_Flatten_Nested;
    procedure Test_Zip_Chain;
    procedure Test_Transpose_Complex;
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
    procedure Test_IsSomeAnd_Some_NilPredicate_Raises;
    procedure Test_Contains_Some_NilEq_Raises;
  end;

implementation

uses
  fafafa.core.base;

type
  { Test interface for FromInterface tests }
  ITestInterface = interface
    ['{12345678-1234-1234-1234-123456789012}']
    function GetValue: Integer;
  end;

  { Test object implementing ITestInterface }
  TTestObject = class(TInterfacedObject, ITestInterface)
    function GetValue: Integer;
  end;

{ TTestObject }

function TTestObject.GetValue: Integer;
begin
  Result := 42;
end;

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

{ UnwrapOrElse 测试 }

procedure TTestCase_Option.Test_UnwrapOrElse_Some_ReturnsValue;
var
  O: specialize TOption<Integer>;
  V: Integer;
begin
  O := specialize TOption<Integer>.Some(42);
  V := O.UnwrapOrElse(function: Integer begin Result := 99; end);
  CheckEquals(42, V, 'Some should return value without calling function');
end;

procedure TTestCase_Option.Test_UnwrapOrElse_None_CallsFunction;
var
  O: specialize TOption<Integer>;
  V: Integer;
  Called: Boolean;
begin
  Called := False;
  O := specialize TOption<Integer>.None;
  V := O.UnwrapOrElse(function: Integer begin Called := True; Result := 99; end);
  CheckEquals(99, V, 'None should call function and return its result');
  CheckTrue(Called, 'Function should have been called');
end;

procedure TTestCase_Option.Test_UnwrapOrElse_None_NilFunction_Raises;
var
  O: specialize TOption<Integer>;
  F: specialize TOptionThunk<Integer>;
  V: Integer;
begin
  O := specialize TOption<Integer>.None;
  F := nil;
  try
    V := O.UnwrapOrElse(F);
    if V = V then; // suppress hint
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
end;

{ UnwrapOrDefault 测试 }

procedure TTestCase_Option.Test_UnwrapOrDefault_Some_ReturnsValue;
var
  O: specialize TOption<Integer>;
  V: Integer;
begin
  O := specialize TOption<Integer>.Some(42);
  V := O.UnwrapOrDefault;
  CheckEquals(42, V, 'Some should return value');
end;

procedure TTestCase_Option.Test_UnwrapOrDefault_None_ReturnsDefault;
var
  O: specialize TOption<Integer>;
  V: Integer;
begin
  O := specialize TOption<Integer>.None;
  V := O.UnwrapOrDefault;
  CheckEquals(0, V, 'None should return Default(Integer) = 0');
end;

{ Expect 测试 }

procedure TTestCase_Option.Test_Expect_Some_ReturnsValue;
var
  O: specialize TOption<Integer>;
  V: Integer;
begin
  O := specialize TOption<Integer>.Some(42);
  V := O.Expect('Should not raise');
  CheckEquals(42, V, 'Some should return value');
end;

procedure TTestCase_Option.Test_Expect_None_RaisesWithMessage;
var
  O: specialize TOption<Integer>;
  V: Integer;
begin
  O := specialize TOption<Integer>.None;
  try
    V := O.Expect('Custom error message');
    if V = V then; // suppress hint
    Fail('Expected exception: Custom error message');
  except
    on E: EOptionUnwrapError do
      CheckEquals('Custom error message', E.Message);
  end;
end;

{ TryUnwrap 测试 }

procedure TTestCase_Option.Test_TryUnwrap_Some_ReturnsTrue;
var
  O: specialize TOption<Integer>;
  V: Integer;
  Success: Boolean;
begin
  O := specialize TOption<Integer>.Some(42);
  Success := O.TryUnwrap(V);
  CheckTrue(Success, 'TryUnwrap should return True for Some');
  CheckEquals(42, V, 'Value should be 42');
end;

procedure TTestCase_Option.Test_TryUnwrap_None_ReturnsFalse;
var
  O: specialize TOption<Integer>;
  V: Integer;
  Success: Boolean;
begin
  V := 999; // Set to non-default value
  O := specialize TOption<Integer>.None;
  Success := O.TryUnwrap(V);
  CheckFalse(Success, 'TryUnwrap should return False for None');
  CheckEquals(0, V, 'Value should be Default(Integer) = 0');
end;

{ IsSomeAnd 测试 }

procedure TTestCase_Option.Test_IsSomeAnd_Some_PredicateTrue;
var
  O: specialize TOption<Integer>;
  Result: Boolean;
begin
  O := specialize TOption<Integer>.Some(42);
  Result := O.IsSomeAnd(function(const X: Integer): Boolean begin Result := X > 40; end);
  CheckTrue(Result, 'IsSomeAnd should return True when Some and predicate is true');
end;

procedure TTestCase_Option.Test_IsSomeAnd_Some_PredicateFalse;
var
  O: specialize TOption<Integer>;
  Result: Boolean;
begin
  O := specialize TOption<Integer>.Some(42);
  Result := O.IsSomeAnd(function(const X: Integer): Boolean begin Result := X > 50; end);
  CheckFalse(Result, 'IsSomeAnd should return False when Some but predicate is false');
end;

procedure TTestCase_Option.Test_IsSomeAnd_None_ReturnsFalse;
var
  O: specialize TOption<Integer>;
  Result: Boolean;
begin
  O := specialize TOption<Integer>.None;
  Result := O.IsSomeAnd(function(const X: Integer): Boolean begin Result := True; end);
  CheckFalse(Result, 'IsSomeAnd should return False for None');
end;

{ Contains 测试 }

procedure TTestCase_Option.Test_Contains_Some_Equal;
var
  O: specialize TOption<Integer>;
  Result: Boolean;
begin
  O := specialize TOption<Integer>.Some(42);
  Result := O.Contains(42, function(const A, B: Integer): Boolean begin Result := A = B; end);
  CheckTrue(Result, 'Contains should return True when Some and values are equal');
end;

procedure TTestCase_Option.Test_Contains_Some_NotEqual;
var
  O: specialize TOption<Integer>;
  Result: Boolean;
begin
  O := specialize TOption<Integer>.Some(42);
  Result := O.Contains(99, function(const A, B: Integer): Boolean begin Result := A = B; end);
  CheckFalse(Result, 'Contains should return False when Some but values are not equal');
end;

procedure TTestCase_Option.Test_Contains_None_ReturnsFalse;
var
  O: specialize TOption<Integer>;
  Result: Boolean;
begin
  O := specialize TOption<Integer>.None;
  Result := O.Contains(42, function(const A, B: Integer): Boolean begin Result := A = B; end);
  CheckFalse(Result, 'Contains should return False for None');
end;

{ Or_ 逻辑或测试 }

procedure TTestCase_Option.Test_Or_Some_Some;
var
  O1, O2, Result: specialize TOption<Integer>;
begin
  O1 := specialize TOption<Integer>.Some(42);
  O2 := specialize TOption<Integer>.Some(99);
  Result := O1.Or_(O2);
  CheckTrue(Result.IsSome, 'Or_ should return Some when first is Some');
  CheckEquals(42, Result.Unwrap, 'Or_ should return first Some value');
end;

procedure TTestCase_Option.Test_Or_Some_None;
var
  O1, O2, Result: specialize TOption<Integer>;
begin
  O1 := specialize TOption<Integer>.Some(42);
  O2 := specialize TOption<Integer>.None;
  Result := O1.Or_(O2);
  CheckTrue(Result.IsSome, 'Or_ should return Some when first is Some');
  CheckEquals(42, Result.Unwrap, 'Or_ should return first Some value');
end;

procedure TTestCase_Option.Test_Or_None_Some;
var
  O1, O2, Result: specialize TOption<Integer>;
begin
  O1 := specialize TOption<Integer>.None;
  O2 := specialize TOption<Integer>.Some(99);
  Result := O1.Or_(O2);
  CheckTrue(Result.IsSome, 'Or_ should return Some when second is Some');
  CheckEquals(99, Result.Unwrap, 'Or_ should return second Some value');
end;

{ And_ 逻辑与测试 }

procedure TTestCase_Option.Test_And_Some_Some;
var
  O1, O2, Result: specialize TOption<Integer>;
begin
  O1 := specialize TOption<Integer>.Some(42);
  O2 := specialize TOption<Integer>.Some(99);
  Result := O1.And_(O2);
  CheckTrue(Result.IsSome, 'And_ should return Some when both are Some');
  CheckEquals(99, Result.Unwrap, 'And_ should return second Some value');
end;

procedure TTestCase_Option.Test_And_Some_None;
var
  O1, O2, Result: specialize TOption<Integer>;
begin
  O1 := specialize TOption<Integer>.Some(42);
  O2 := specialize TOption<Integer>.None;
  Result := O1.And_(O2);
  CheckTrue(Result.IsNone, 'And_ should return None when second is None');
end;

procedure TTestCase_Option.Test_And_None_Some;
var
  O1, O2, Result: specialize TOption<Integer>;
begin
  O1 := specialize TOption<Integer>.None;
  O2 := specialize TOption<Integer>.Some(99);
  Result := O1.And_(O2);
  CheckTrue(Result.IsNone, 'And_ should return None when first is None');
end;

{ Xor_ 逻辑异或测试 }

procedure TTestCase_Option.Test_Xor_Some_None;
var
  O1, O2, Result: specialize TOption<Integer>;
begin
  O1 := specialize TOption<Integer>.Some(42);
  O2 := specialize TOption<Integer>.None;
  Result := O1.Xor_(O2);
  CheckTrue(Result.IsSome, 'Xor_ should return Some when only first is Some');
  CheckEquals(42, Result.Unwrap, 'Xor_ should return first Some value');
end;

procedure TTestCase_Option.Test_Xor_None_Some;
var
  O1, O2, Result: specialize TOption<Integer>;
begin
  O1 := specialize TOption<Integer>.None;
  O2 := specialize TOption<Integer>.Some(99);
  Result := O1.Xor_(O2);
  CheckTrue(Result.IsSome, 'Xor_ should return Some when only second is Some');
  CheckEquals(99, Result.Unwrap, 'Xor_ should return second Some value');
end;

procedure TTestCase_Option.Test_Xor_Some_Some;
var
  O1, O2, Result: specialize TOption<Integer>;
begin
  O1 := specialize TOption<Integer>.Some(42);
  O2 := specialize TOption<Integer>.Some(99);
  Result := O1.Xor_(O2);
  CheckTrue(Result.IsNone, 'Xor_ should return None when both are Some');
end;

{ Flatten 测试 }

procedure TTestCase_Option.Test_Flatten_SomeSome;
var
  Inner: specialize TOption<Integer>;
  Outer: specialize TOption<specialize TOption<Integer>>;
  Flattened: specialize TOption<Integer>;
begin
  Inner := specialize TOption<Integer>.Some(42);
  Outer := specialize TOption<specialize TOption<Integer>>.Some(Inner);
  Flattened := specialize OptionFlatten<Integer>(Outer);
  CheckTrue(Flattened.IsSome, 'Flatten should return Some when nested Some(Some(T))');
  CheckEquals(42, Flattened.Unwrap, 'Flatten should unwrap to inner value');
end;

procedure TTestCase_Option.Test_Flatten_SomeNone;
var
  Inner: specialize TOption<Integer>;
  Outer: specialize TOption<specialize TOption<Integer>>;
  Flattened: specialize TOption<Integer>;
begin
  Inner := specialize TOption<Integer>.None;
  Outer := specialize TOption<specialize TOption<Integer>>.Some(Inner);
  Flattened := specialize OptionFlatten<Integer>(Outer);
  CheckTrue(Flattened.IsNone, 'Flatten should return None when Some(None)');
end;

{ Zip 测试 }

procedure TTestCase_Option.Test_Zip_SomeSome;
var
  A, B: specialize TOption<Integer>;
  Zipped: specialize TOption<specialize TTuple2<Integer, Integer>>;
  Tuple: specialize TTuple2<Integer, Integer>;
begin
  A := specialize TOption<Integer>.Some(42);
  B := specialize TOption<Integer>.Some(99);
  Zipped := specialize OptionZip<Integer, Integer>(A, B);
  CheckTrue(Zipped.IsSome, 'Zip should return Some when both are Some');
  Tuple := Zipped.Unwrap;
  CheckEquals(42, Tuple.First, 'Zip should contain first value');
  CheckEquals(99, Tuple.Second, 'Zip should contain second value');
end;

procedure TTestCase_Option.Test_Zip_SomeNone;
var
  A, B: specialize TOption<Integer>;
  Zipped: specialize TOption<specialize TTuple2<Integer, Integer>>;
begin
  A := specialize TOption<Integer>.Some(42);
  B := specialize TOption<Integer>.None;
  Zipped := specialize OptionZip<Integer, Integer>(A, B);
  CheckTrue(Zipped.IsNone, 'Zip should return None when second is None');
end;

procedure TTestCase_Option.Test_Zip_NoneSome;
var
  A, B: specialize TOption<Integer>;
  Zipped: specialize TOption<specialize TTuple2<Integer, Integer>>;
begin
  A := specialize TOption<Integer>.None;
  B := specialize TOption<Integer>.Some(99);
  Zipped := specialize OptionZip<Integer, Integer>(A, B);
  CheckTrue(Zipped.IsNone, 'Zip should return None when first is None');
end;

procedure TTestCase_Option.Test_Zip_NoneNone;
var
  A, B: specialize TOption<Integer>;
  Zipped: specialize TOption<specialize TTuple2<Integer, Integer>>;
begin
  A := specialize TOption<Integer>.None;
  B := specialize TOption<Integer>.None;
  Zipped := specialize OptionZip<Integer, Integer>(A, B);
  CheckTrue(Zipped.IsNone, 'Zip should return None when both are None');
end;

{ ZipWith 测试 }

procedure TTestCase_Option.Test_ZipWith_SomeSome;
var
  A, B: specialize TOption<Integer>;
  Result: specialize TOption<Integer>;
begin
  A := specialize TOption<Integer>.Some(42);
  B := specialize TOption<Integer>.Some(99);
  Result := specialize OptionZipWith<Integer, Integer, Integer>(
    A, B,
    function(const Tuple: specialize TTuple2<Integer, Integer>): Integer
    begin
      Result := Tuple.First + Tuple.Second;
    end
  );
  CheckTrue(Result.IsSome, 'ZipWith should return Some when both are Some');
  CheckEquals(141, Result.Unwrap, 'ZipWith should apply function to tuple');
end;

procedure TTestCase_Option.Test_ZipWith_SomeNone;
var
  A, B: specialize TOption<Integer>;
  Result: specialize TOption<Integer>;
begin
  A := specialize TOption<Integer>.Some(42);
  B := specialize TOption<Integer>.None;
  Result := specialize OptionZipWith<Integer, Integer, Integer>(
    A, B,
    function(const Tuple: specialize TTuple2<Integer, Integer>): Integer
    begin
      Result := Tuple.First + Tuple.Second;
    end
  );
  CheckTrue(Result.IsNone, 'ZipWith should return None when second is None');
end;

procedure TTestCase_Option.Test_ZipWith_NoneSome;
var
  A, B: specialize TOption<Integer>;
  Result: specialize TOption<Integer>;
begin
  A := specialize TOption<Integer>.None;
  B := specialize TOption<Integer>.Some(99);
  Result := specialize OptionZipWith<Integer, Integer, Integer>(
    A, B,
    function(const Tuple: specialize TTuple2<Integer, Integer>): Integer
    begin
      Result := Tuple.First + Tuple.Second;
    end
  );
  CheckTrue(Result.IsNone, 'ZipWith should return None when first is None');
end;

procedure TTestCase_Option.Test_ZipWith_NoneNone;
var
  A, B: specialize TOption<Integer>;
  Result: specialize TOption<Integer>;
begin
  A := specialize TOption<Integer>.None;
  B := specialize TOption<Integer>.None;
  Result := specialize OptionZipWith<Integer, Integer, Integer>(
    A, B,
    function(const Tuple: specialize TTuple2<Integer, Integer>): Integer
    begin
      Result := Tuple.First + Tuple.Second;
    end
  );
  CheckTrue(Result.IsNone, 'ZipWith should return None when both are None');
end;

{ OptionToResultElse 测试 }

procedure TTestCase_Option.Test_ToResultElse_Some;
var
  O: specialize TOption<Integer>;
  R: specialize TResult<Integer, string>;
begin
  O := specialize TOption<Integer>.Some(42);
  R := specialize OptionToResultElse<Integer, string>(
    O,
    function: string begin Result := 'error'; end
  );
  CheckTrue(R.IsOk, 'ToResultElse should return Ok when Some');
  CheckEquals(42, R.Unwrap, 'ToResultElse should contain value');
end;

procedure TTestCase_Option.Test_ToResultElse_None_CallsFunction;
var
  O: specialize TOption<Integer>;
  R: specialize TResult<Integer, string>;
  Called: Boolean;
begin
  Called := False;
  O := specialize TOption<Integer>.None;
  R := specialize OptionToResultElse<Integer, string>(
    O,
    function: string begin Called := True; Result := 'custom error'; end
  );
  CheckTrue(R.IsErr, 'ToResultElse should return Err when None');
  CheckEquals('custom error', R.UnwrapErr, 'ToResultElse should call function and return error');
  CheckTrue(Called, 'Function should have been called');
end;

{ ResultErrOption 测试 }

procedure TTestCase_Option.Test_ResultErrOption_Ok;
var
  R: specialize TResult<Integer, string>;
  O: specialize TOption<string>;
begin
  R := specialize TResult<Integer, string>.Ok(42);
  O := specialize ResultErrOption<Integer, string>(R);
  CheckTrue(O.IsNone, 'ResultErrOption should return None when Ok');
end;

procedure TTestCase_Option.Test_ResultErrOption_Err;
var
  R: specialize TResult<Integer, string>;
  O: specialize TOption<string>;
begin
  R := specialize TResult<Integer, string>.Err('error message');
  O := specialize ResultErrOption<Integer, string>(R);
  CheckTrue(O.IsSome, 'ResultErrOption should return Some when Err');
  CheckEquals('error message', O.Unwrap, 'ResultErrOption should contain error value');
end;

{ Transpose 测试 }

procedure TTestCase_Option.Test_ResultTransposeOption_OkSome;
var
  Inner: specialize TOption<Integer>;
  R: specialize TResult<specialize TOption<Integer>, string>;
  Transposed: specialize TOption<specialize TResult<Integer, string>>;
  InnerResult: specialize TResult<Integer, string>;
begin
  Inner := specialize TOption<Integer>.Some(42);
  R := specialize TResult<specialize TOption<Integer>, string>.Ok(Inner);
  Transposed := specialize ResultTransposeOption<Integer, string>(R);
  CheckTrue(Transposed.IsSome, 'ResultTransposeOption should return Some when Ok(Some)');
  InnerResult := Transposed.Unwrap;
  CheckTrue(InnerResult.IsOk, 'Inner Result should be Ok');
  CheckEquals(42, InnerResult.Unwrap, 'Inner Result should contain value');
end;

procedure TTestCase_Option.Test_ResultTransposeOption_OkNone;
var
  Inner: specialize TOption<Integer>;
  R: specialize TResult<specialize TOption<Integer>, string>;
  Transposed: specialize TOption<specialize TResult<Integer, string>>;
begin
  Inner := specialize TOption<Integer>.None;
  R := specialize TResult<specialize TOption<Integer>, string>.Ok(Inner);
  Transposed := specialize ResultTransposeOption<Integer, string>(R);
  CheckTrue(Transposed.IsNone, 'ResultTransposeOption should return None when Ok(None)');
end;

procedure TTestCase_Option.Test_OptionTransposeResult_SomeOk;
var
  Inner: specialize TResult<Integer, string>;
  O: specialize TOption<specialize TResult<Integer, string>>;
  Transposed: specialize TResult<specialize TOption<Integer>, string>;
  InnerOption: specialize TOption<Integer>;
begin
  Inner := specialize TResult<Integer, string>.Ok(42);
  O := specialize TOption<specialize TResult<Integer, string>>.Some(Inner);
  Transposed := specialize OptionTransposeResult<Integer, string>(O);
  CheckTrue(Transposed.IsOk, 'OptionTransposeResult should return Ok when Some(Ok)');
  InnerOption := Transposed.Unwrap;
  CheckTrue(InnerOption.IsSome, 'Inner Option should be Some');
  CheckEquals(42, InnerOption.Unwrap, 'Inner Option should contain value');
end;

procedure TTestCase_Option.Test_OptionTransposeResult_SomeErr;
var
  Inner: specialize TResult<Integer, string>;
  O: specialize TOption<specialize TResult<Integer, string>>;
  Transposed: specialize TResult<specialize TOption<Integer>, string>;
begin
  Inner := specialize TResult<Integer, string>.Err('error message');
  O := specialize TOption<specialize TResult<Integer, string>>.Some(Inner);
  Transposed := specialize OptionTransposeResult<Integer, string>(O);
  CheckTrue(Transposed.IsErr, 'OptionTransposeResult should return Err when Some(Err)');
  CheckEquals('error message', Transposed.UnwrapErr, 'Transposed should contain error');
end;

{ FromInterface 测试 }

procedure TTestCase_Option.Test_FromInterface_NonNil;
var
  Obj: ITestInterface;
  Opt: specialize TOption<IInterface>;
begin
  Obj := TTestObject.Create;
  Opt := OptionFromInterface(Obj);
  CheckTrue(Opt.IsSome, 'FromInterface should return Some when interface is non-nil');
  CheckTrue(Opt.Unwrap <> nil, 'Unwrapped interface should not be nil');
end;

procedure TTestCase_Option.Test_FromInterface_Nil;
var
  Opt: specialize TOption<IInterface>;
begin
  Opt := OptionFromInterface(nil);
  CheckTrue(Opt.IsNone, 'FromInterface should return None when interface is nil');
end;

{ P3 高级场景测试 }

procedure TTestCase_Option.Test_Flatten_Nested;
var
  Inner: specialize TOption<Integer>;
  Middle: specialize TOption<specialize TOption<Integer>>;
  Outer: specialize TOption<specialize TOption<specialize TOption<Integer>>>;
  Flattened1: specialize TOption<specialize TOption<Integer>>;
  Flattened2: specialize TOption<Integer>;
begin
  // 创建三层嵌套: Some(Some(Some(42)))
  Inner := specialize TOption<Integer>.Some(42);
  Middle := specialize TOption<specialize TOption<Integer>>.Some(Inner);
  Outer := specialize TOption<specialize TOption<specialize TOption<Integer>>>.Some(Middle);

  // 第一次展平: Some(Some(Some(42))) -> Some(Some(42))
  Flattened1 := specialize OptionFlatten<specialize TOption<Integer>>(Outer);
  CheckTrue(Flattened1.IsSome, 'First flatten should return Some');

  // 第二次展平: Some(Some(42)) -> Some(42)
  Flattened2 := specialize OptionFlatten<Integer>(Flattened1);
  CheckTrue(Flattened2.IsSome, 'Second flatten should return Some');
  CheckEquals(42, Flattened2.Unwrap, 'Final value should be 42');
end;

procedure TTestCase_Option.Test_Zip_Chain;
var
  A, B, C: specialize TOption<Integer>;
  AB: specialize TOption<specialize TTuple2<Integer, Integer>>;
  ABC: specialize TOption<specialize TTuple2<specialize TTuple2<Integer, Integer>, Integer>>;
  Sum: Integer;
begin
  // 创建三个 Option
  A := specialize TOption<Integer>.Some(10);
  B := specialize TOption<Integer>.Some(20);
  C := specialize TOption<Integer>.Some(30);

  // 链式 Zip: (A, B) -> AB
  AB := specialize OptionZip<Integer, Integer>(A, B);
  CheckTrue(AB.IsSome, 'First Zip should return Some');

  // 继续 Zip: (AB, C) -> ABC
  ABC := specialize OptionZip<specialize TTuple2<Integer, Integer>, Integer>(AB, C);
  CheckTrue(ABC.IsSome, 'Second Zip should return Some');

  // 验证值: ((10, 20), 30)
  Sum := ABC.Unwrap.First.First + ABC.Unwrap.First.Second + ABC.Unwrap.Second;
  CheckEquals(60, Sum, 'Sum of all values should be 60');
end;

procedure TTestCase_Option.Test_Transpose_Complex;
var
  // 测试 1: Option<Result<T,E>> -> Result<Option<T>,E> (Ok case)
  InnerResult1: specialize TResult<Integer, string>;
  MiddleOption1: specialize TOption<specialize TResult<Integer, string>>;
  Transposed1: specialize TResult<specialize TOption<Integer>, string>;
  FinalOption1: specialize TOption<Integer>;

  // 测试 2: Option<Result<T,E>> -> Result<Option<T>,E> (Err case)
  InnerResult2: specialize TResult<Integer, string>;
  MiddleOption2: specialize TOption<specialize TResult<Integer, string>>;
  Transposed2: specialize TResult<specialize TOption<Integer>, string>;
begin
  // 测试 1: Option<Result<Ok(42),E>> -> Result<Option<42>,E>
  InnerResult1 := specialize TResult<Integer, string>.Ok(42);
  MiddleOption1 := specialize TOption<specialize TResult<Integer, string>>.Some(InnerResult1);

  Transposed1 := specialize OptionTransposeResult<Integer, string>(MiddleOption1);
  CheckTrue(Transposed1.IsOk, 'Transposed Result should be Ok');

  FinalOption1 := Transposed1.Unwrap;
  CheckTrue(FinalOption1.IsSome, 'Inner Option should be Some');
  CheckEquals(42, FinalOption1.Unwrap, 'Final value should be 42');

  // 测试 2: Option<Result<Err,E>> -> Result<Option<T>,E> (Err propagates)
  InnerResult2 := specialize TResult<Integer, string>.Err('error message');
  MiddleOption2 := specialize TOption<specialize TResult<Integer, string>>.Some(InnerResult2);

  Transposed2 := specialize OptionTransposeResult<Integer, string>(MiddleOption2);
  CheckTrue(Transposed2.IsErr, 'Transposed Result should be Err when inner Result is Err');
  CheckEquals('error message', Transposed2.UnwrapErr, 'Error message should be preserved');
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
  ZipF: specialize TOptionFunc<specialize TTuple2<Integer, Integer>, Integer>;
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
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
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
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
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
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
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
    Fail('Expected exception: aFok is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aFok is nil', E.Message);
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
    Fail('Expected exception: aFnone is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aFnone is nil', E.Message);
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
    Fail('Expected exception: aPred is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aPred is nil', E.Message);
  end;
end;

procedure TTestCase_Option_CallbackContracts.Test_OptionZipWith_SomeSome_NilFunc_Raises;
var
  A, B: specialize TOption<Integer>;
  F: specialize TOptionFunc<specialize TTuple2<Integer, Integer>, Integer>;
  O: specialize TOption<Integer>;
begin
  A := specialize TOption<Integer>.Some(1);
  B := specialize TOption<Integer>.Some(2);
  F := nil;
  try
    O := specialize OptionZipWith<Integer, Integer, Integer>(A, B, F);
    if O.IsSome then; // suppress hint
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
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
    Fail('Expected exception: aFerrThunk is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aFerrThunk is nil', E.Message);
  end;
end;

procedure TTestCase_Option_CallbackContracts.Test_IsSomeAnd_Some_NilPredicate_Raises;
var
  O: specialize TOption<Integer>;
  Pred: specialize TOptionFunc<Integer, Boolean>;
  Result: Boolean;
begin
  O := specialize TOption<Integer>.Some(42);
  Pred := nil;
  try
    Result := O.IsSomeAnd(Pred);
    if Result then; // suppress hint
    Fail('Expected exception: aPred is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aPred is nil', E.Message);
  end;
end;

procedure TTestCase_Option_CallbackContracts.Test_Contains_Some_NilEq_Raises;
var
  O: specialize TOption<Integer>;
  Eq: specialize TOptionBiPred<Integer, Integer>;
  Result: Boolean;
begin
  O := specialize TOption<Integer>.Some(42);
  Eq := nil;
  try
    Result := O.Contains(42, Eq);
    if Result then; // suppress hint
    Fail('Expected exception: aEq is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aEq is nil', E.Message);
  end;
end;

initialization
  RegisterTest(TTestCase_Option);
  RegisterTest(TTestCase_Option_CallbackContracts);
end.
