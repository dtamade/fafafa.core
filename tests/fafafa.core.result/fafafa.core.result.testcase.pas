{$CODEPAGE UTF8}
unit fafafa.core.result.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.option.base, fafafa.core.result, fafafa.core.option, fafafa.core.result.facade;

type
  { 基础构造与查询测试 }
  TTestCase_TResult_Basic = class(TTestCase)
  published
    procedure Test_Ok_Construct_And_Query;
    procedure Test_Err_Construct_And_Query;
    procedure Test_Unwrap_On_Ok;
    procedure Test_Unwrap_On_Err_Raises;
    procedure Test_UnwrapOr;
    procedure Test_Expect_On_Ok;
    procedure Test_Expect_On_Err_Raises;
    procedure Test_UnwrapErr_On_Err;
    procedure Test_UnwrapErr_On_Ok_Raises;
    procedure Test_ExpectErr_On_Err;
    procedure Test_ExpectErr_On_Ok_Raises;
    procedure Test_TryUnwrap;
    procedure Test_TryUnwrapErr;
    procedure Test_UnwrapUnchecked;
    procedure Test_Default_Initialization;
  end;

  { 字符串表示测试 }
  TTestCase_TResult_ToString = class(TTestCase)
  published
    procedure Test_ToString_Basic;
    procedure Test_ToString_Formatted;
  end;

  { 组合子测试 }
  TTestCase_TResult_Combinators = class(TTestCase)
  published
    procedure Test_Map_On_Ok;
    procedure Test_Map_On_Err;
    procedure Test_MapErr_On_Ok;
    procedure Test_MapErr_On_Err;
    procedure Test_AndThen_On_Ok;
    procedure Test_AndThen_On_Err;
    procedure Test_OrElse_On_Ok;
    procedure Test_OrElse_On_Err;
    procedure Test_MapOr;
    procedure Test_MapOrElse;
    procedure Test_Match;
    procedure Test_Swap;
    procedure Test_Flatten;
    procedure Test_And_;
    procedure Test_Or_;
    procedure Test_Contains;
    procedure Test_ContainsErr;
    procedure Test_FilterOrElse;
    procedure Test_IsOkAnd;
    procedure Test_IsErrAnd;
    procedure Test_Chain;
    procedure Test_Equals;
    procedure Test_MapBoth;
    procedure Test_Fold;
  end;

  { 异常桥接测试 }
  TTestCase_TResult_ExceptionBridge = class(TTestCase)
  published
    procedure Test_ResultToTry_On_Ok;
    procedure Test_ResultToTry_On_Err_Raises;
    procedure Test_ResultFromTry_Success;
    procedure Test_ResultFromTry_Exception;
  end;

  { Inspect 测试 }
  TTestCase_TResult_Inspect = class(TTestCase)
  published
    procedure Test_Inspect_On_Ok;
    procedure Test_Inspect_On_Err;
    procedure Test_InspectErr_On_Ok;
    procedure Test_InspectErr_On_Err;
  end;

  { 新增 API 测试 - Phase 2 }
  TTestCase_TResult_NewAPI = class(TTestCase)
  published
    procedure Test_UnwrapOrElse_On_Ok;
    procedure Test_UnwrapOrElse_On_Err;
    procedure Test_UnwrapOrDefault_On_Ok;
    procedure Test_UnwrapOrDefault_On_Err;
    procedure Test_OkOption_On_Ok;
    procedure Test_OkOption_On_Err;
    procedure Test_ErrOption_On_Ok;
    procedure Test_ErrOption_On_Err;
    procedure Test_ToDebugString;
    procedure Test_UnwrapErrUnchecked;
    procedure Test_OrElseThunk_On_Ok;
    procedure Test_OrElseThunk_On_Err;
  end;

  { TOption 新增 API 测试 - Phase 3 }
  TTestCase_TOption_NewAPI = class(TTestCase)
  published
    procedure Test_UnwrapOrElse_On_Some;
    procedure Test_UnwrapOrElse_On_None;
    procedure Test_UnwrapOrDefault_On_Some;
    procedure Test_UnwrapOrDefault_On_None;
    procedure Test_TryUnwrap_On_None_OverwritesOutParam;
    procedure Test_IsSomeAnd;
    procedure Test_Contains;
    procedure Test_Or;
    procedure Test_And;
    procedure Test_Xor;
    procedure Test_Flatten;
    procedure Test_Zip;
  end;

  { 错误上下文测试 - Phase 4 }
  TTestCase_TResult_Context = class(TTestCase)
  published
    procedure Test_ResultContext_On_Ok;
    procedure Test_ResultContext_On_Err;
    procedure Test_ResultWithContext_On_Ok;
    procedure Test_ResultWithContext_On_Err;
    { 错误链测试 - TErrorCtx 与 ResultContextE/ResultWithContextE }
    procedure Test_TErrorCtx_Create_And_Fields;
    procedure Test_TErrorCtx_ToDebugString;
    procedure Test_ResultContextE_On_Ok;
    procedure Test_ResultContextE_On_Err;
    procedure Test_ResultWithContextE_On_Ok;
    procedure Test_ResultWithContextE_On_Err;
  end;

  { Transpose 测试 - Phase 6 }
  TTestCase_TResult_Transpose = class(TTestCase)
  published
    { ResultTranspose: Result<Option<T>,E> -> Option<Result<T,E>> }
    procedure Test_ResultTranspose_OkSome_ReturnsSomeOk;
    procedure Test_ResultTranspose_OkNone_ReturnsNone;
    procedure Test_ResultTranspose_Err_ReturnsSomeErr;
    { OptionTransposeResult: Option<Result<T,E>> -> Result<Option<T>,E> }
    procedure Test_OptionTranspose_None_ReturnsOkNone;
    procedure Test_OptionTranspose_SomeOk_ReturnsOkSome;
    procedure Test_OptionTranspose_SomeErr_ReturnsErr;
  end;

  { 快速接口测试 - Phase 5 (M3) }
  TTestCase_TResult_FastAPI = class(TTestCase)
  published
    procedure Test_ResultEnsure_When_True_Returns_Ok;
    procedure Test_ResultEnsure_When_False_Returns_Err;
    procedure Test_ResultEnsureWith_When_True_DoesNotCallThunk;
    procedure Test_ResultEnsureWith_When_False_CallsThunk;

    procedure Test_ResultFromBool_When_True_Returns_Ok;
    procedure Test_ResultFromBool_When_False_Returns_Err;

    procedure Test_ResultZip_OkOk_Returns_Ok;
    procedure Test_ResultZip_ErrOk_Returns_Err;
    procedure Test_ResultZip_OkErr_Returns_Err;
    procedure Test_ResultZip_ErrErr_Returns_FirstErr;

    procedure Test_ResultZipWith_OkOk_Maps;
    procedure Test_ResultZipWith_Err_DoesNotCallMapper;

    procedure Test_ResultFromOption_Some_Returns_Ok;
    procedure Test_ResultFromOption_None_Returns_Err;
    procedure Test_ResultFromOptionElse_None_CallsThunk;
    procedure Test_ResultFromOptionElse_Some_DoesNotCallThunk;

    procedure Test_TResult_CollectPtrIntoArray_Empty_ReturnsOkAndOutEmpty;
    procedure Test_TryCollectPtrIntoArray_AllOk_ReturnsTrue;
    procedure Test_TryCollectPtrIntoArray_FirstErr_ReturnsFalse;
    procedure Test_TryCollectPtrIntoArray_MixedWithErr_ReturnsFalseWithFirstErr;

    procedure Test_Facade_Ensure_Works;
    procedure Test_Facade_TryCollect_Works;
  end;

  { 错误类型测试 - Removed as types were removed }
  { TTestCase_ErrorTypes removed }

  { 方法式 API 测试 - Merged into Combinators }


implementation

type
  TIntResult = specialize TResult<Integer, string>;
  TStrResult = specialize TResult<string, Integer>;

{ 辅助函数 }
function IncOne(const X: Integer): Integer;
begin
  Result := X + 1;
end;

function DoubleIt(const X: Integer): Integer;
begin
  Result := X * 2;
end;

function IntToStrFunc(const X: Integer): string;
begin
  Result := IntToStr(X);
end;

function AppendBang(const S: string): string;
begin
  Result := S + '!';
end;

function StrLen(const S: string): Integer;
begin
  Result := Length(S);
end;

function IntEq(const A, B: Integer): Boolean;
begin
  Result := A = B;
end;

function StrEq(const A, B: string): Boolean;
begin
  Result := A = B;
end;

function IsPositive(const X: Integer): Boolean;
begin
  Result := X > 0;
end;

function IsNegative(const X: Integer): Boolean;
begin
  Result := X < 0;
end;

function MakeNegError(const AValue: Integer): string;
begin
  if AValue = AValue then; // suppress hint
  Result := 'not positive';
end;

function WorkOk: Integer;
begin
  Result := 42;
end;

function WorkFail: Integer;
begin
  Result := 0; // never reached, but silences warning
  raise Exception.Create('work failed');
end;

function MapExToStr(const Ex: Exception): string;
begin
  Result := Ex.Message;
end;

function StrToEx(const S: string): Exception;
begin
  Result := Exception.Create(S);
end;

var
  GInspectCount: Integer = 0;
  GInspectValue: Integer = 0;
  GInspectErrValue: string = '';

procedure InspectInt(const X: Integer);
begin
  Inc(GInspectCount);
  GInspectValue := X;
end;

procedure InspectStr(const S: string);
begin
  Inc(GInspectCount);
  GInspectErrValue := S;
end;

{ TTestCase_TResult_Basic }

procedure TTestCase_TResult_Basic.Test_Ok_Construct_And_Query;
var
  R: TIntResult;
begin
  R := TIntResult.Ok(123);
  CheckTrue(R.IsOk, 'IsOk should be true');
  CheckFalse(R.IsErr, 'IsErr should be false');
end;

procedure TTestCase_TResult_Basic.Test_Err_Construct_And_Query;
var
  R: TIntResult;
begin
  R := TIntResult.Err('error');
  CheckFalse(R.IsOk, 'IsOk should be false');
  CheckTrue(R.IsErr, 'IsErr should be true');
end;

procedure TTestCase_TResult_Basic.Test_Unwrap_On_Ok;
var
  R: TIntResult;
begin
  R := TIntResult.Ok(42);
  CheckEquals(42, R.Unwrap);
end;

procedure TTestCase_TResult_Basic.Test_Unwrap_On_Err_Raises;
var
  R: TIntResult;
begin
  R := TIntResult.Err('fail');
  try
    R.Unwrap;
    Fail('Unwrap on Err should raise');
  except
    on E: EResultUnwrapError do
      ; // expected
  end;
end;

procedure TTestCase_TResult_Basic.Test_UnwrapOr;
var
  ROk, RErr: TIntResult;
begin
  ROk := TIntResult.Ok(10);
  RErr := TIntResult.Err('x');
  CheckEquals(10, ROk.UnwrapOr(99));
  CheckEquals(99, RErr.UnwrapOr(99));
end;

procedure TTestCase_TResult_Basic.Test_Expect_On_Ok;
var
  R: TIntResult;
begin
  R := TIntResult.Ok(7);
  CheckEquals(7, R.Expect('should not fail'));
end;

procedure TTestCase_TResult_Basic.Test_Expect_On_Err_Raises;
var
  R: TIntResult;
begin
  R := TIntResult.Err('boom');
  try
    R.Expect('custom message');
    Fail('Expect on Err should raise');
  except
    on E: EResultUnwrapError do
      CheckEquals('custom message', E.Message);
  end;
end;

procedure TTestCase_TResult_Basic.Test_UnwrapErr_On_Err;
var
  R: TIntResult;
begin
  R := TIntResult.Err('my error');
  CheckEquals('my error', R.UnwrapErr);
end;

procedure TTestCase_TResult_Basic.Test_UnwrapErr_On_Ok_Raises;
var
  R: TIntResult;
begin
  R := TIntResult.Ok(1);
  try
    R.UnwrapErr;
    Fail('UnwrapErr on Ok should raise');
  except
    on E: EResultUnwrapError do
      ; // expected
  end;
end;

procedure TTestCase_TResult_Basic.Test_ExpectErr_On_Err;
var
  R: TIntResult;
begin
  R := TIntResult.Err('err');
  CheckEquals('err', R.ExpectErr('should not fail'));
end;

procedure TTestCase_TResult_Basic.Test_ExpectErr_On_Ok_Raises;
var
  R: TIntResult;
begin
  R := TIntResult.Ok(1);
  try
    R.ExpectErr('ok value');
    Fail('ExpectErr on Ok should raise');
  except
    on E: EResultUnwrapError do
      ; // expected
  end;
end;

procedure TTestCase_TResult_Basic.Test_TryUnwrap;
var
  ROk, RErr: TIntResult;
  V: Integer;
begin
  ROk := TIntResult.Ok(55);
  RErr := TIntResult.Err('x');

  CheckTrue(ROk.TryUnwrap(V));
  CheckEquals(55, V);

  CheckFalse(RErr.TryUnwrap(V));
  CheckEquals(0, V); // default value
end;

procedure TTestCase_TResult_Basic.Test_TryUnwrapErr;
var
  ROk, RErr: TIntResult;
  E: string;
begin
  ROk := TIntResult.Ok(1);
  RErr := TIntResult.Err('error msg');

  CheckFalse(ROk.TryUnwrapErr(E));
  CheckEquals('', E); // default

  CheckTrue(RErr.TryUnwrapErr(E));
  CheckEquals('error msg', E);
end;

procedure TTestCase_TResult_Basic.Test_UnwrapUnchecked;
var
  R: TIntResult;
begin
  R := TIntResult.Ok(99);
  CheckEquals(99, R.UnwrapUnchecked);
end;

procedure TTestCase_TResult_Basic.Test_Default_Initialization;
var
  R: TIntResult;
begin
  // R is not explicitly initialized, should be Err(Default(E))
  // In our case E is string, default is ''
  CheckTrue(R.IsErr, 'Default initialized result should be Err');
  CheckFalse(R.IsOk, 'Default initialized result should not be Ok');
  CheckEquals('', R.UnwrapErr, 'Default error value should be empty string');
end;

{ TTestCase_TResult_ToString }

procedure TTestCase_TResult_ToString.Test_ToString_Basic;
var
  ROk, RErr: TIntResult;
begin
  ROk := TIntResult.Ok(1);
  RErr := TIntResult.Err('e');
  CheckEquals('Ok', ROk.ToString);
  CheckEquals('Err', RErr.ToString);
end;

procedure TTestCase_TResult_ToString.Test_ToString_Formatted;
var
  ROk, RErr: TIntResult;
begin
  ROk := TIntResult.Ok(1);
  RErr := TIntResult.Err('e');
  CheckEquals('success', ROk.ToString('success', 'failure'));
  CheckEquals('failure', RErr.ToString('success', 'failure'));
end;

{ TTestCase_TResult_Combinators }

procedure TTestCase_TResult_Combinators.Test_Map_On_Ok;
var
  R, R2: TIntResult;
begin
  R := TIntResult.Ok(5);
  R2 := specialize ResultMap<Integer, string, Integer>(R, @IncOne);
  CheckTrue(R2.IsOk);
  CheckEquals(6, R2.Unwrap);
end;

procedure TTestCase_TResult_Combinators.Test_Map_On_Err;
var
  R, R2: TIntResult;
begin
  R := TIntResult.Err('err');
  R2 := specialize ResultMap<Integer, string, Integer>(R, @IncOne);
  CheckTrue(R2.IsErr);
  CheckEquals('err', R2.UnwrapErr);
end;

procedure TTestCase_TResult_Combinators.Test_MapErr_On_Ok;
var
  R: TIntResult;
  R2: specialize TResult<Integer, Integer>;
begin
  R := TIntResult.Ok(10);
  R2 := specialize ResultMapErr<Integer, string, Integer>(R, @StrLen);
  CheckTrue(R2.IsOk);
  CheckEquals(10, R2.Unwrap);
end;

procedure TTestCase_TResult_Combinators.Test_MapErr_On_Err;
var
  R: TIntResult;
  R2: specialize TResult<Integer, Integer>;
begin
  R := TIntResult.Err('hello');
  R2 := specialize ResultMapErr<Integer, string, Integer>(R, @StrLen);
  CheckTrue(R2.IsErr);
  CheckEquals(5, R2.UnwrapErr);
end;

procedure TTestCase_TResult_Combinators.Test_AndThen_On_Ok;
var
  R, R2: TIntResult;
  F: specialize TResultFunc<Integer, TIntResult>;
begin
  R := TIntResult.Ok(5);
  F := function(const X: Integer): TIntResult
  begin
    if X > 0 then
      Result := TIntResult.Ok(X * 2)
    else
      Result := TIntResult.Err('negative');
  end;
  R2 := specialize ResultAndThen<Integer, string, Integer>(R, F);
  CheckTrue(R2.IsOk);
  CheckEquals(10, R2.Unwrap);
end;

procedure TTestCase_TResult_Combinators.Test_AndThen_On_Err;
var
  R, R2: TIntResult;
  F: specialize TResultFunc<Integer, TIntResult>;
begin
  R := TIntResult.Err('original');
  F := function(const X: Integer): TIntResult
  begin
    Result := TIntResult.Ok(X * 2);
  end;
  R2 := specialize ResultAndThen<Integer, string, Integer>(R, F);
  CheckTrue(R2.IsErr);
  CheckEquals('original', R2.UnwrapErr);
end;

procedure TTestCase_TResult_Combinators.Test_OrElse_On_Ok;
var
  R: TIntResult;
  R2: TIntResult;
  F: specialize TResultFunc<string, TIntResult>;
begin
  R := TIntResult.Ok(42);
  F := function(const S: string): TIntResult
  begin
    Result := TIntResult.Ok(Length(S));
  end;
  R2 := specialize ResultOrElse<Integer, string, string>(R, F);
  CheckTrue(R2.IsOk);
  CheckEquals(42, R2.Unwrap);
end;

procedure TTestCase_TResult_Combinators.Test_OrElse_On_Err;
var
  R: TIntResult;
  R2: TIntResult;
  F: specialize TResultFunc<string, TIntResult>;
begin
  R := TIntResult.Err('hello');
  F := function(const S: string): TIntResult
  begin
    Result := TIntResult.Ok(Length(S));
  end;
  R2 := specialize ResultOrElse<Integer, string, string>(R, F);
  CheckTrue(R2.IsOk);
  CheckEquals(5, R2.Unwrap);
end;

procedure TTestCase_TResult_Combinators.Test_MapOr;
var
  ROk, RErr: TIntResult;
begin
  ROk := TIntResult.Ok(3);
  RErr := TIntResult.Err('x');

  CheckEquals(6, specialize ResultMapOr<Integer, string, Integer>(ROk, 0, @DoubleIt));
  CheckEquals(0, specialize ResultMapOr<Integer, string, Integer>(RErr, 0, @DoubleIt));
end;

procedure TTestCase_TResult_Combinators.Test_MapOrElse;
var
  ROk, RErr: TIntResult;
  FErr: specialize TResultFunc<string, Integer>;
  FOk: specialize TResultFunc<Integer, Integer>;
begin
  ROk := TIntResult.Ok(5);
  RErr := TIntResult.Err('abc');

  FErr := function(const S: string): Integer begin Result := Length(S); end;
  FOk := function(const X: Integer): Integer begin Result := X * 10; end;

  CheckEquals(50, specialize ResultMapOrElse<Integer, string, Integer>(ROk, FErr, FOk));
  CheckEquals(3, specialize ResultMapOrElse<Integer, string, Integer>(RErr, FErr, FOk));
end;

procedure TTestCase_TResult_Combinators.Test_Match;
var
  ROk, RErr: TIntResult;
  FOk: specialize TResultFunc<Integer, string>;
  FErr: specialize TResultFunc<string, string>;
begin
  ROk := TIntResult.Ok(42);
  RErr := TIntResult.Err('fail');

  FOk := function(const X: Integer): string begin Result := 'val:' + IntToStr(X); end;
  FErr := function(const S: string): string begin Result := 'err:' + S; end;

  CheckEquals('val:42', specialize ResultMatch<Integer, string, string>(ROk, FOk, FErr));
  CheckEquals('err:fail', specialize ResultMatch<Integer, string, string>(RErr, FOk, FErr));
end;

procedure TTestCase_TResult_Combinators.Test_Swap;
var
  R: TIntResult;
  RS: specialize TResult<string, Integer>;
begin
  R := TIntResult.Ok(42);
  RS := specialize ResultSwap<Integer, string>(R);
  CheckTrue(RS.IsErr);
  CheckEquals(42, RS.UnwrapErr);

  R := TIntResult.Err('e');
  RS := specialize ResultSwap<Integer, string>(R);
  CheckTrue(RS.IsOk);
  CheckEquals('e', RS.Unwrap);
end;

procedure TTestCase_TResult_Combinators.Test_Flatten;
var
  Inner: TIntResult;
  Outer: specialize TResult<TIntResult, string>;
  Flat: TIntResult;
begin
  Inner := TIntResult.Ok(99);
  Outer := specialize TResult<TIntResult, string>.Ok(Inner);
  Flat := specialize ResultFlatten<Integer, string>(Outer);
  CheckTrue(Flat.IsOk);
  CheckEquals(99, Flat.Unwrap);

  Outer := specialize TResult<TIntResult, string>.Err('outer err');
  Flat := specialize ResultFlatten<Integer, string>(Outer);
  CheckTrue(Flat.IsErr);
  CheckEquals('outer err', Flat.UnwrapErr);
end;

procedure TTestCase_TResult_Combinators.Test_And_;
var
  A, B, C: TIntResult;
begin
  A := TIntResult.Ok(1);
  B := TIntResult.Ok(2);
  C := A.And_(B);
  CheckTrue(C.IsOk);
  CheckEquals(2, C.Unwrap);

  A := TIntResult.Err('first');
  C := A.And_(B);
  CheckTrue(C.IsErr);
  CheckEquals('first', C.UnwrapErr);
end;

procedure TTestCase_TResult_Combinators.Test_Or_;
var
  A, B, C: TIntResult;
begin
  A := TIntResult.Err('e');
  B := TIntResult.Ok(99);
  C := A.Or_(B);
  CheckEquals(99, C.Unwrap);

  A := TIntResult.Ok(1);
  C := A.Or_(B);
  CheckEquals(1, C.Unwrap);
end;

procedure TTestCase_TResult_Combinators.Test_Contains;
var
  R: TIntResult;
begin
  R := TIntResult.Ok(42);
  CheckTrue(R.Contains(42, @IntEq));
  CheckFalse(R.Contains(99, @IntEq));

  R := TIntResult.Err('x');
  CheckFalse(R.Contains(42, @IntEq));
end;

procedure TTestCase_TResult_Combinators.Test_ContainsErr;
var
  R: TIntResult;
begin
  R := TIntResult.Err('error');
  CheckTrue(R.ContainsErr('error', @StrEq));
  CheckFalse(R.ContainsErr('other', @StrEq));

  R := TIntResult.Ok(1);
  CheckFalse(R.ContainsErr('error', @StrEq));
end;

procedure TTestCase_TResult_Combinators.Test_FilterOrElse;
var
  R, R2: TIntResult;
begin
  R := TIntResult.Ok(5);
  R2 := specialize ResultFilterOrElse<Integer, string>(R, @IsPositive, @MakeNegError);
  CheckTrue(R2.IsOk);
  CheckEquals(5, R2.Unwrap);

  R := TIntResult.Ok(-3);
  R2 := specialize ResultFilterOrElse<Integer, string>(R, @IsPositive, @MakeNegError);
  CheckTrue(R2.IsErr);
  CheckEquals('not positive', R2.UnwrapErr);

  R := TIntResult.Err('original');
  R2 := specialize ResultFilterOrElse<Integer, string>(R, @IsPositive, @MakeNegError);
  CheckTrue(R2.IsErr);
  CheckEquals('original', R2.UnwrapErr);
end;

procedure TTestCase_TResult_Combinators.Test_IsOkAnd;
var
  R: TIntResult;
begin
  R := TIntResult.Ok(5);
  CheckTrue(R.IsOkAnd(@IsPositive));

  R := TIntResult.Ok(-1);
  CheckFalse(R.IsOkAnd(@IsPositive));

  R := TIntResult.Err('e');
  CheckFalse(R.IsOkAnd(@IsPositive));
end;

procedure TTestCase_TResult_Combinators.Test_IsErrAnd;
var
  R: TStrResult;
  IsNeg: specialize TResultFunc<Integer, Boolean>;
begin
  IsNeg := function(const X: Integer): Boolean begin Result := X < 0; end;

  R := TStrResult.Err(-1);
  CheckTrue(R.IsErrAnd(IsNeg));

  R := TStrResult.Err(1);
  CheckFalse(R.IsErrAnd(IsNeg));

  R := TStrResult.Ok('ok');
  CheckFalse(R.IsErrAnd(IsNeg));
end;

procedure TTestCase_TResult_Combinators.Test_Chain;
var
  A, B, C: TIntResult;
begin
  A := TIntResult.Ok(1);
  B := TIntResult.Ok(2);
  C := specialize ResultChain<Integer, string>(A, B);
  CheckEquals(2, C.Unwrap);

  A := TIntResult.Err('first');
  C := specialize ResultChain<Integer, string>(A, B);
  CheckTrue(C.IsErr);
end;

procedure TTestCase_TResult_Combinators.Test_Equals;
var
  A, B: TIntResult;
begin
  // Ok vs Ok (equal)
  A := TIntResult.Ok(42);
  B := TIntResult.Ok(42);
  CheckTrue(A.Equals(B, @IntEq, @StrEq));

  // Ok vs Ok (not equal)
  B := TIntResult.Ok(99);
  CheckFalse(A.Equals(B, @IntEq, @StrEq));

  // Err vs Err (equal)
  A := TIntResult.Err('error');
  B := TIntResult.Err('error');
  CheckTrue(A.Equals(B, @IntEq, @StrEq));

  // Err vs Err (not equal)
  B := TIntResult.Err('other');
  CheckFalse(A.Equals(B, @IntEq, @StrEq));

  // Ok vs Err
  A := TIntResult.Ok(42);
  B := TIntResult.Err('e');
  CheckFalse(A.Equals(B, @IntEq, @StrEq));

  // Err vs Ok
  A := TIntResult.Err('e');
  B := TIntResult.Ok(42);
  CheckFalse(A.Equals(B, @IntEq, @StrEq));
end;

procedure TTestCase_TResult_Combinators.Test_MapBoth;
var
  R: TIntResult;
  R2: specialize TResult<string, Integer>;
begin
  // Ok path: map value
  R := TIntResult.Ok(42);
  R2 := specialize ResultMapBoth<Integer, string, string, Integer>(R, @IntToStrFunc, @StrLen);
  CheckTrue(R2.IsOk);
  CheckEquals('42', R2.Unwrap);

  // Err path: map error
  R := TIntResult.Err('hello');
  R2 := specialize ResultMapBoth<Integer, string, string, Integer>(R, @IntToStrFunc, @StrLen);
  CheckTrue(R2.IsErr);
  CheckEquals(5, R2.UnwrapErr);
end;

procedure TTestCase_TResult_Combinators.Test_Fold;
var
  ROk, RErr: TIntResult;
  FOk: specialize TResultFunc<Integer, string>;
  FErr: specialize TResultFunc<string, string>;
begin
  ROk := TIntResult.Ok(42);
  RErr := TIntResult.Err('fail');

  FOk := function(const X: Integer): string begin Result := 'val:' + IntToStr(X); end;
  FErr := function(const S: string): string begin Result := 'err:' + S; end;

  // ResultFold should behave same as ResultMatch
  CheckEquals('val:42', specialize ResultFold<Integer, string, string>(ROk, FOk, FErr));
  CheckEquals('err:fail', specialize ResultFold<Integer, string, string>(RErr, FOk, FErr));
end;

{ TTestCase_TResult_ExceptionBridge }

procedure TTestCase_TResult_ExceptionBridge.Test_ResultToTry_On_Ok;
var
  R: TIntResult;
  V: Integer;
begin
  R := TIntResult.Ok(42);
  V := specialize ResultToTry<Integer, string>(R, @StrToEx);
  CheckEquals(42, V);
end;

procedure TTestCase_TResult_ExceptionBridge.Test_ResultToTry_On_Err_Raises;
var
  R: TIntResult;
begin
  R := TIntResult.Err('my error');
  try
    specialize ResultToTry<Integer, string>(R, @StrToEx);
    Fail('ToTry on Err should raise');
  except
    on E: Exception do
      CheckEquals('my error', E.Message);
  end;
end;

procedure TTestCase_TResult_ExceptionBridge.Test_ResultFromTry_Success;
var
  R: TIntResult;
begin
  R := specialize ResultFromTry<Integer, string>(@WorkOk, @MapExToStr);
  CheckTrue(R.IsOk);
  CheckEquals(42, R.Unwrap);
end;

procedure TTestCase_TResult_ExceptionBridge.Test_ResultFromTry_Exception;
var
  R: TIntResult;
begin
  R := specialize ResultFromTry<Integer, string>(@WorkFail, @MapExToStr);
  CheckTrue(R.IsErr);
  CheckEquals('work failed', R.UnwrapErr);
end;

{ TTestCase_TResult_Inspect }

procedure TTestCase_TResult_Inspect.Test_Inspect_On_Ok;
var
  R, R2: TIntResult;
begin
  GInspectCount := 0;
  GInspectValue := 0;

  R := TIntResult.Ok(77);
  R2 := R.Inspect(@InspectInt);

  CheckEquals(1, GInspectCount);
  CheckEquals(77, GInspectValue);
  CheckTrue(R2.IsOk);
end;

procedure TTestCase_TResult_Inspect.Test_Inspect_On_Err;
var
  R, R2: TIntResult;
begin
  GInspectCount := 0;

  R := TIntResult.Err('e');
  R2 := R.Inspect(@InspectInt);

  CheckEquals(0, GInspectCount);
  CheckTrue(R2.IsErr);
end;

procedure TTestCase_TResult_Inspect.Test_InspectErr_On_Ok;
var
  R, R2: TIntResult;
begin
  GInspectCount := 0;

  R := TIntResult.Ok(1);
  R2 := R.InspectErr(@InspectStr);

  CheckEquals(0, GInspectCount);
  CheckTrue(R2.IsOk);
end;

procedure TTestCase_TResult_Inspect.Test_InspectErr_On_Err;
var
  R, R2: TIntResult;
begin
  GInspectCount := 0;
  GInspectErrValue := '';

  R := TIntResult.Err('error msg');
  R2 := R.InspectErr(@InspectStr);

  CheckEquals(1, GInspectCount);
  CheckEquals('error msg', GInspectErrValue);
  CheckTrue(R2.IsErr);
end;

{ TTestCase_ErrorTypes removed }

{ TTestCase_TResult_Methods merged into Combinators }

{ TTestCase_TResult_NewAPI - Phase 2 }

function GetDefaultInt: Integer;
begin
  Result := 999;
end;

function IntPrinter(const X: Integer): string;
begin
  Result := IntToStr(X);
end;

function StrPrinter(const S: string): string;
begin
  Result := '"' + S + '"';
end;

procedure TTestCase_TResult_NewAPI.Test_UnwrapOrElse_On_Ok;
var
  R: TIntResult;
begin
  R := TIntResult.Ok(42);
  CheckEquals(42, R.UnwrapOrElse(@GetDefaultInt));
end;

procedure TTestCase_TResult_NewAPI.Test_UnwrapOrElse_On_Err;
var
  R: TIntResult;
begin
  R := TIntResult.Err('error');
  CheckEquals(999, R.UnwrapOrElse(@GetDefaultInt));
end;

procedure TTestCase_TResult_NewAPI.Test_UnwrapOrDefault_On_Ok;
var
  R: TIntResult;
begin
  R := TIntResult.Ok(42);
  CheckEquals(42, R.UnwrapOrDefault);
end;

procedure TTestCase_TResult_NewAPI.Test_UnwrapOrDefault_On_Err;
var
  R: TIntResult;
begin
  R := TIntResult.Err('error');
  CheckEquals(0, R.UnwrapOrDefault); // Default(Integer) = 0
end;

procedure TTestCase_TResult_NewAPI.Test_OkOption_On_Ok;
var
  R: TIntResult;
  Opt: specialize TOption<Integer>;
begin
  R := TIntResult.Ok(42);
  Opt := R.OkOption;
  CheckTrue(Opt.IsSome);
  CheckEquals(42, Opt.Unwrap);
end;

procedure TTestCase_TResult_NewAPI.Test_OkOption_On_Err;
var
  R: TIntResult;
  Opt: specialize TOption<Integer>;
begin
  R := TIntResult.Err('error');
  Opt := R.OkOption;
  CheckTrue(Opt.IsNone);
end;

procedure TTestCase_TResult_NewAPI.Test_ErrOption_On_Ok;
var
  R: TIntResult;
  Opt: specialize TOption<string>;
begin
  R := TIntResult.Ok(42);
  Opt := R.ErrOption;
  CheckTrue(Opt.IsNone);
end;

procedure TTestCase_TResult_NewAPI.Test_ErrOption_On_Err;
var
  R: TIntResult;
  Opt: specialize TOption<string>;
begin
  R := TIntResult.Err('my error');
  Opt := R.ErrOption;
  CheckTrue(Opt.IsSome);
  CheckEquals('my error', Opt.Unwrap);
end;

procedure TTestCase_TResult_NewAPI.Test_ToDebugString;
var
  ROk, RErr: TIntResult;
begin
  ROk := TIntResult.Ok(42);
  RErr := TIntResult.Err('fail');
  CheckEquals('Ok(42)', ROk.ToDebugString(@IntPrinter, @StrPrinter));
  CheckEquals('Err("fail")', RErr.ToDebugString(@IntPrinter, @StrPrinter));
end;

procedure TTestCase_TResult_NewAPI.Test_UnwrapErrUnchecked;
var
  R: TIntResult;
begin
  R := TIntResult.Err('my error');
  CheckEquals('my error', R.UnwrapErrUnchecked);
end;

function GetFallbackResult: TIntResult;
begin
  Result := TIntResult.Ok(999);
end;

procedure TTestCase_TResult_NewAPI.Test_OrElseThunk_On_Ok;
var
  R, R2: TIntResult;
begin
  R := TIntResult.Ok(42);
  R2 := R.OrElseThunk(@GetFallbackResult);
  CheckTrue(R2.IsOk);
  CheckEquals(42, R2.Unwrap);
end;

procedure TTestCase_TResult_NewAPI.Test_OrElseThunk_On_Err;
var
  R, R2: TIntResult;
begin
  R := TIntResult.Err('error');
  R2 := R.OrElseThunk(@GetFallbackResult);
  CheckTrue(R2.IsOk);
  CheckEquals(999, R2.Unwrap);
end;

{ TTestCase_TOption_NewAPI - Phase 3 }

type
  TIntOption = specialize TOption<Integer>;

function GetDefaultIntForOption: Integer;
begin
  Result := 999;
end;

function IntEqForOption(const A, B: Integer): Boolean;
begin
  Result := A = B;
end;

procedure TTestCase_TOption_NewAPI.Test_UnwrapOrElse_On_Some;
var
  O: TIntOption;
begin
  O := TIntOption.Some(42);
  CheckEquals(42, O.UnwrapOrElse(@GetDefaultIntForOption));
end;

procedure TTestCase_TOption_NewAPI.Test_UnwrapOrElse_On_None;
var
  O: TIntOption;
begin
  O := TIntOption.None;
  CheckEquals(999, O.UnwrapOrElse(@GetDefaultIntForOption));
end;

procedure TTestCase_TOption_NewAPI.Test_UnwrapOrDefault_On_Some;
var
  O: TIntOption;
begin
  O := TIntOption.Some(42);
  CheckEquals(42, O.UnwrapOrDefault);
end;

procedure TTestCase_TOption_NewAPI.Test_UnwrapOrDefault_On_None;
var
  O: TIntOption;
begin
  O := TIntOption.None;
  CheckEquals(0, O.UnwrapOrDefault); // Default(Integer) = 0
end;

procedure TTestCase_TOption_NewAPI.Test_TryUnwrap_On_None_OverwritesOutParam;
var
  O: TIntOption;
  V: Integer;
begin
  O := TIntOption.None;
  V := 123;

  CheckFalse(O.TryUnwrap(V));
  CheckEquals(0, V); // must not leak previous value
end;

procedure TTestCase_TOption_NewAPI.Test_IsSomeAnd;
var
  O: TIntOption;
  Pred: specialize TOptionFunc<Integer, Boolean>;
begin
  Pred := function(const X: Integer): Boolean begin Result := X > 0; end;
  
  O := TIntOption.Some(5);
  CheckTrue(O.IsSomeAnd(Pred));
  
  O := TIntOption.Some(-1);
  CheckFalse(O.IsSomeAnd(Pred));
  
  O := TIntOption.None;
  CheckFalse(O.IsSomeAnd(Pred));
end;

procedure TTestCase_TOption_NewAPI.Test_Contains;
var
  O: TIntOption;
begin
  O := TIntOption.Some(42);
  CheckTrue(O.Contains(42, @IntEqForOption));
  CheckFalse(O.Contains(99, @IntEqForOption));
  
  O := TIntOption.None;
  CheckFalse(O.Contains(42, @IntEqForOption));
end;

procedure TTestCase_TOption_NewAPI.Test_Or;
var
  A, B, C: TIntOption;
begin
  A := TIntOption.Some(1);
  B := TIntOption.Some(2);
  C := A.Or_(B);
  CheckTrue(C.IsSome);
  CheckEquals(1, C.Unwrap); // Some.Or_(*) returns first
  
  A := TIntOption.None;
  C := A.Or_(B);
  CheckTrue(C.IsSome);
  CheckEquals(2, C.Unwrap); // None.Or_(Some) returns second
  
  A := TIntOption.None;
  B := TIntOption.None;
  C := A.Or_(B);
  CheckTrue(C.IsNone);
end;

procedure TTestCase_TOption_NewAPI.Test_And;
var
  A, B, C: TIntOption;
begin
  A := TIntOption.Some(1);
  B := TIntOption.Some(2);
  C := A.And_(B);
  CheckTrue(C.IsSome);
  CheckEquals(2, C.Unwrap); // Some.And_(Some) returns second
  
  A := TIntOption.Some(1);
  B := TIntOption.None;
  C := A.And_(B);
  CheckTrue(C.IsNone); // Some.And_(None) returns None
  
  A := TIntOption.None;
  B := TIntOption.Some(2);
  C := A.And_(B);
  CheckTrue(C.IsNone); // None.And_(*) returns None
end;

procedure TTestCase_TOption_NewAPI.Test_Xor;
var
  A, B, C: TIntOption;
begin
  A := TIntOption.Some(1);
  B := TIntOption.None;
  C := A.Xor_(B);
  CheckTrue(C.IsSome);
  CheckEquals(1, C.Unwrap);
  
  A := TIntOption.None;
  B := TIntOption.Some(2);
  C := A.Xor_(B);
  CheckTrue(C.IsSome);
  CheckEquals(2, C.Unwrap);
  
  A := TIntOption.Some(1);
  B := TIntOption.Some(2);
  C := A.Xor_(B);
  CheckTrue(C.IsNone); // Both Some -> None
  
  A := TIntOption.None;
  B := TIntOption.None;
  C := A.Xor_(B);
  CheckTrue(C.IsNone); // Both None -> None
end;

procedure TTestCase_TOption_NewAPI.Test_Flatten;
var
  Inner: TIntOption;
  Outer: specialize TOption<TIntOption>;
  Flat: TIntOption;
begin
  Inner := TIntOption.Some(42);
  Outer := specialize TOption<TIntOption>.Some(Inner);
  Flat := specialize OptionFlatten<Integer>(Outer);
  CheckTrue(Flat.IsSome);
  CheckEquals(42, Flat.Unwrap);
  
  Outer := specialize TOption<TIntOption>.None;
  Flat := specialize OptionFlatten<Integer>(Outer);
  CheckTrue(Flat.IsNone);
end;

procedure TTestCase_TOption_NewAPI.Test_Zip;
var
  A: TIntOption;
  B: specialize TOption<string>;
  Zipped: specialize TOption<specialize TPair<Integer, string>>;
begin
  A := TIntOption.Some(42);
  B := specialize TOption<string>.Some('hello');
  Zipped := specialize OptionZip<Integer, string>(A, B);
  CheckTrue(Zipped.IsSome);
  CheckEquals(42, Zipped.Unwrap.First);
  CheckEquals('hello', Zipped.Unwrap.Second);
  
  A := TIntOption.None;
  Zipped := specialize OptionZip<Integer, string>(A, B);
  CheckTrue(Zipped.IsNone);
end;

{ TTestCase_TResult_Context - Phase 4 }

type
  TIntErrResult = specialize TResult<Integer, Integer>;

function MakeContextStr(const ErrCode: Integer): string;
begin
  Result := 'Error code: ' + IntToStr(ErrCode);
end;

procedure TTestCase_TResult_Context.Test_ResultContext_On_Ok;
var
  R: TIntErrResult;
  R2: TIntResult;
begin
  R := TIntErrResult.Ok(42);
  R2 := specialize ResultContext<Integer, Integer>(R, 'operation failed');
  CheckTrue(R2.IsOk);
  CheckEquals(42, R2.Unwrap);
end;

procedure TTestCase_TResult_Context.Test_ResultContext_On_Err;
var
  R: TIntErrResult;
  R2: TIntResult;
begin
  R := TIntErrResult.Err(404);
  R2 := specialize ResultContext<Integer, Integer>(R, 'file not found');
  CheckTrue(R2.IsErr);
  CheckEquals('file not found', R2.UnwrapErr);
end;

procedure TTestCase_TResult_Context.Test_ResultWithContext_On_Ok;
var
  R: TIntErrResult;
  R2: TIntResult;
begin
  R := TIntErrResult.Ok(100);
  R2 := specialize ResultWithContext<Integer, Integer>(R, @MakeContextStr);
  CheckTrue(R2.IsOk);
  CheckEquals(100, R2.Unwrap);
end;

procedure TTestCase_TResult_Context.Test_ResultWithContext_On_Err;
var
  R: TIntErrResult;
  R2: TIntResult;
begin
  R := TIntErrResult.Err(500);
  R2 := specialize ResultWithContext<Integer, Integer>(R, @MakeContextStr);
  CheckTrue(R2.IsErr);
  CheckEquals('Error code: 500', R2.UnwrapErr);
end;

{ TErrorCtx 与 ResultContextE/ResultWithContextE 测试 }

type
  TIntErrorCtx = specialize TErrorCtx<Integer>;
  TIntCtxResult = specialize TResult<Integer, TIntErrorCtx>;

function IntPrinterForCtx(const X: Integer): string;
begin
  Result := IntToStr(X);
end;

procedure TTestCase_TResult_Context.Test_TErrorCtx_Create_And_Fields;
var
  Ctx: TIntErrorCtx;
begin
  Ctx := TIntErrorCtx.Create('file not found', 404);
  CheckEquals('file not found', Ctx.Msg);
  CheckEquals(404, Ctx.Inner);
end;

procedure TTestCase_TResult_Context.Test_TErrorCtx_ToDebugString;
var
  Ctx: TIntErrorCtx;
  S: string;
begin
  Ctx := TIntErrorCtx.Create('operation failed', 500);
  S := Ctx.ToDebugString(@IntPrinterForCtx);
  CheckEquals('operation failed (caused by: 500)', S);
end;

procedure TTestCase_TResult_Context.Test_ResultContextE_On_Ok;
var
  R: TIntErrResult;
  R2: TIntCtxResult;
begin
  R := TIntErrResult.Ok(42);
  R2 := specialize ResultContextE<Integer, Integer>(R, 'should not appear');
  CheckTrue(R2.IsOk);
  CheckEquals(42, R2.Unwrap);
end;

procedure TTestCase_TResult_Context.Test_ResultContextE_On_Err;
var
  R: TIntErrResult;
  R2: TIntCtxResult;
  ErrCtx: TIntErrorCtx;
begin
  R := TIntErrResult.Err(404);
  R2 := specialize ResultContextE<Integer, Integer>(R, 'file not found');
  CheckTrue(R2.IsErr);
  ErrCtx := R2.UnwrapErr;
  CheckEquals('file not found', ErrCtx.Msg);
  CheckEquals(404, ErrCtx.Inner); // 原始错误保留
  CheckEquals('file not found (caused by: 404)', ErrCtx.ToDebugString(@IntPrinterForCtx));
end;

procedure TTestCase_TResult_Context.Test_ResultWithContextE_On_Ok;
var
  R: TIntErrResult;
  R2: TIntCtxResult;
begin
  R := TIntErrResult.Ok(100);
  R2 := specialize ResultWithContextE<Integer, Integer>(R, @MakeContextStr);
  CheckTrue(R2.IsOk);
  CheckEquals(100, R2.Unwrap);
end;

procedure TTestCase_TResult_Context.Test_ResultWithContextE_On_Err;
var
  R: TIntErrResult;
  R2: TIntCtxResult;
  ErrCtx: TIntErrorCtx;
begin
  R := TIntErrResult.Err(500);
  R2 := specialize ResultWithContextE<Integer, Integer>(R, @MakeContextStr);
  CheckTrue(R2.IsErr);
  ErrCtx := R2.UnwrapErr;
  CheckEquals('Error code: 500', ErrCtx.Msg);
  CheckEquals(500, ErrCtx.Inner); // 原始错误保留
end;

{ TTestCase_TResult_FastAPI - Phase 5 (M3) }

type
  TUnitStrResult = specialize TResult<TUnit, string>;
  TStrStrResult = specialize TResult<string, string>;
  TTupIntStr = specialize TTuple2<Integer, string>;
  TTupIntStrResult = specialize TResult<TTupIntStr, string>;

var
  GEnsureErrThunkCount: Integer = 0;
  GZipWithMapCount: Integer = 0;
  GFromOptionErrThunkCount: Integer = 0;

function MakeEnsureErrMsg: string;
begin
  Inc(GEnsureErrThunkCount);
  Result := 'ensure failed';
end;

function TupIntStrToString(const P: TTupIntStr): string;
begin
  Inc(GZipWithMapCount);
  Result := IntToStr(P.First) + ':' + P.Second;
end;

function MakeOptionErrMsg: string;
begin
  Inc(GFromOptionErrThunkCount);
  Result := 'none';
end;

procedure TTestCase_TResult_FastAPI.Test_ResultEnsure_When_True_Returns_Ok;
var
  R: TUnitStrResult;
begin
  R := specialize ResultEnsure<string>(True, 'bad');
  CheckTrue(R.IsOk);
  R.Unwrap; // should not raise
end;

procedure TTestCase_TResult_FastAPI.Test_ResultEnsure_When_False_Returns_Err;
var
  R: TUnitStrResult;
begin
  R := specialize ResultEnsure<string>(False, 'bad');
  CheckTrue(R.IsErr);
  CheckEquals('bad', R.UnwrapErr);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultEnsureWith_When_True_DoesNotCallThunk;
var
  R: TUnitStrResult;
begin
  GEnsureErrThunkCount := 0;
  R := specialize ResultEnsureWith<string>(True, @MakeEnsureErrMsg);
  CheckTrue(R.IsOk);
  CheckEquals(0, GEnsureErrThunkCount);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultEnsureWith_When_False_CallsThunk;
var
  R: TUnitStrResult;
begin
  GEnsureErrThunkCount := 0;
  R := specialize ResultEnsureWith<string>(False, @MakeEnsureErrMsg);
  CheckTrue(R.IsErr);
  CheckEquals(1, GEnsureErrThunkCount);
  CheckEquals('ensure failed', R.UnwrapErr);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultFromBool_When_True_Returns_Ok;
var
  R: TIntResult;
begin
  R := specialize ResultFromBool<Integer, string>(True, 7, 'no');
  CheckTrue(R.IsOk);
  CheckEquals(7, R.Unwrap);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultFromBool_When_False_Returns_Err;
var
  R: TIntResult;
begin
  R := specialize ResultFromBool<Integer, string>(False, 7, 'no');
  CheckTrue(R.IsErr);
  CheckEquals('no', R.UnwrapErr);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultZip_OkOk_Returns_Ok;
var
  A: TIntResult;
  B: TStrStrResult;
  Z: TTupIntStrResult;
begin
  A := TIntResult.Ok(42);
  B := TStrStrResult.Ok('hello');

  Z := specialize ResultZip<Integer, string, string>(A, B);
  CheckTrue(Z.IsOk);
  CheckEquals(42, Z.Unwrap.First);
  CheckEquals('hello', Z.Unwrap.Second);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultZip_ErrOk_Returns_Err;
var
  A: TIntResult;
  B: TStrStrResult;
  Z: TTupIntStrResult;
begin
  A := TIntResult.Err('e1');
  B := TStrStrResult.Ok('hello');

  Z := specialize ResultZip<Integer, string, string>(A, B);
  CheckTrue(Z.IsErr);
  CheckEquals('e1', Z.UnwrapErr);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultZip_OkErr_Returns_Err;
var
  A: TIntResult;
  B: TStrStrResult;
  Z: TTupIntStrResult;
begin
  A := TIntResult.Ok(42);
  B := TStrStrResult.Err('e2');

  Z := specialize ResultZip<Integer, string, string>(A, B);
  CheckTrue(Z.IsErr);
  CheckEquals('e2', Z.UnwrapErr);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultZip_ErrErr_Returns_FirstErr;
var
  A: TIntResult;
  B: TStrStrResult;
  Z: TTupIntStrResult;
begin
  A := TIntResult.Err('e1');
  B := TStrStrResult.Err('e2');

  Z := specialize ResultZip<Integer, string, string>(A, B);
  CheckTrue(Z.IsErr);
  CheckEquals('e1', Z.UnwrapErr);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultZipWith_OkOk_Maps;
var
  A: TIntResult;
  B: TStrStrResult;
  Z: specialize TResult<string, string>;
begin
  GZipWithMapCount := 0;

  A := TIntResult.Ok(42);
  B := TStrStrResult.Ok('hello');

  Z := specialize ResultZipWith<Integer, string, string, string>(A, B, @TupIntStrToString);
  CheckTrue(Z.IsOk);
  CheckEquals(1, GZipWithMapCount);
  CheckEquals('42:hello', Z.Unwrap);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultZipWith_Err_DoesNotCallMapper;
var
  A: TIntResult;
  B: TStrStrResult;
  Z: specialize TResult<string, string>;
begin
  GZipWithMapCount := 0;

  A := TIntResult.Err('e1');
  B := TStrStrResult.Ok('hello');

  Z := specialize ResultZipWith<Integer, string, string, string>(A, B, @TupIntStrToString);
  CheckTrue(Z.IsErr);
  CheckEquals(0, GZipWithMapCount);
  CheckEquals('e1', Z.UnwrapErr);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultFromOption_Some_Returns_Ok;
var
  O: TIntOption;
  R: TIntResult;
begin
  O := TIntOption.Some(42);
  R := specialize ResultFromOption<Integer, string>(O, 'none');
  CheckTrue(R.IsOk);
  CheckEquals(42, R.Unwrap);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultFromOption_None_Returns_Err;
var
  O: TIntOption;
  R: TIntResult;
begin
  O := TIntOption.None;
  R := specialize ResultFromOption<Integer, string>(O, 'none');
  CheckTrue(R.IsErr);
  CheckEquals('none', R.UnwrapErr);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultFromOptionElse_None_CallsThunk;
var
  O: TIntOption;
  R: TIntResult;
begin
  GFromOptionErrThunkCount := 0;

  O := TIntOption.None;
  R := specialize ResultFromOptionElse<Integer, string>(O, @MakeOptionErrMsg);
  CheckTrue(R.IsErr);
  CheckEquals(1, GFromOptionErrThunkCount);
  CheckEquals('none', R.UnwrapErr);
end;

procedure TTestCase_TResult_FastAPI.Test_ResultFromOptionElse_Some_DoesNotCallThunk;
var
  O: TIntOption;
  R: TIntResult;
begin
  GFromOptionErrThunkCount := 0;

  O := TIntOption.Some(7);
  R := specialize ResultFromOptionElse<Integer, string>(O, @MakeOptionErrMsg);
  CheckTrue(R.IsOk);
  CheckEquals(0, GFromOptionErrThunkCount);
  CheckEquals(7, R.Unwrap);
end;

procedure TTestCase_TResult_FastAPI.Test_TResult_CollectPtrIntoArray_Empty_ReturnsOkAndOutEmpty;
var
  Items: array of TIntResult = nil;
  OutValues: specialize TValueArray<Integer> = nil;
  FirstErr: string;
  Success: Boolean;
begin
  SetLength(Items, 0);

  // Arrange: ensure out array is not empty initially
  SetLength(OutValues, 1);
  OutValues[0] := 99;
  CheckEquals(1, Length(OutValues));

  // Act - use TryCollectPtrIntoArray which returns Boolean
  Success := specialize TryCollectPtrIntoArray<Integer, string>(nil, Length(Items), OutValues, FirstErr);

  // Assert
  CheckTrue(Success);
  CheckEquals(0, Length(OutValues));
end;

procedure TTestCase_TResult_FastAPI.Test_TryCollectPtrIntoArray_AllOk_ReturnsTrue;
var
  Items: array[0..2] of TIntResult;
  OutValues: specialize TValueArray<Integer> = nil;
  FirstErr: string;
  Success: Boolean;
begin
  Items[0] := TIntResult.Ok(10);
  Items[1] := TIntResult.Ok(20);
  Items[2] := TIntResult.Ok(30);

  Success := specialize TryCollectPtrIntoArray<Integer, string>(@Items[0], Length(Items), OutValues, FirstErr);

  CheckTrue(Success);
  CheckEquals(3, Length(OutValues));
  CheckEquals(10, OutValues[0]);
  CheckEquals(20, OutValues[1]);
  CheckEquals(30, OutValues[2]);
  CheckEquals('', FirstErr);
end;

procedure TTestCase_TResult_FastAPI.Test_TryCollectPtrIntoArray_FirstErr_ReturnsFalse;
var
  Items: array[0..2] of TIntResult;
  OutValues: specialize TValueArray<Integer> = nil;
  FirstErr: string;
  Success: Boolean;
begin
  Items[0] := TIntResult.Err('error1');
  Items[1] := TIntResult.Ok(20);
  Items[2] := TIntResult.Ok(30);

  // Arrange: ensure out array is not empty initially
  SetLength(OutValues, 1);
  OutValues[0] := 99;

  Success := specialize TryCollectPtrIntoArray<Integer, string>(@Items[0], Length(Items), OutValues, FirstErr);

  CheckFalse(Success);
  CheckEquals(0, Length(OutValues));
  CheckEquals('error1', FirstErr);
end;

procedure TTestCase_TResult_FastAPI.Test_TryCollectPtrIntoArray_MixedWithErr_ReturnsFalseWithFirstErr;
var
  Items: array[0..2] of TIntResult;
  OutValues: specialize TValueArray<Integer> = nil;
  FirstErr: string;
  Success: Boolean;
begin
  Items[0] := TIntResult.Ok(10);
  Items[1] := TIntResult.Err('middle error');
  Items[2] := TIntResult.Ok(30);

  Success := specialize TryCollectPtrIntoArray<Integer, string>(@Items[0], Length(Items), OutValues, FirstErr);

  CheckFalse(Success);
  CheckEquals(0, Length(OutValues));
  CheckEquals('middle error', FirstErr);
end;

procedure TTestCase_TResult_FastAPI.Test_Facade_Ensure_Works;
var
  R: TUnitStrResult;
begin
  R := specialize ResultEnsure<string>(True, 'bad');
  CheckTrue(R.IsOk);
end;

procedure TTestCase_TResult_FastAPI.Test_Facade_TryCollect_Works;
var
  Items: array[0..1] of TIntResult;
  OutValues: specialize TValueArray<Integer> = nil;
  FirstErr: string;
  Success: Boolean;
begin
  Items[0] := TIntResult.Ok(1);
  Items[1] := TIntResult.Ok(2);

  // 使用 facade 的 TryCollect
  Success := specialize TryCollect<Integer, string>(@Items[0], Length(Items), OutValues, FirstErr);

  CheckTrue(Success);
  CheckEquals(2, Length(OutValues));
  CheckEquals(1, OutValues[0]);
  CheckEquals(2, OutValues[1]);
end;

{ TTestCase_TResult_Transpose - Phase 6 }

type
  TIntOptResult = specialize TResult<specialize TOption<Integer>, string>;
  TOptIntResult = specialize TOption<TIntResult>;

procedure TTestCase_TResult_Transpose.Test_ResultTranspose_OkSome_ReturnsSomeOk;
var
  R: TIntOptResult;
  O: TOptIntResult;
  Inner: TIntResult;
begin
  // Ok(Some(42)) -> Some(Ok(42))
  R := TIntOptResult.Ok(specialize TOption<Integer>.Some(42));
  O := specialize ResultTranspose<Integer, string>(R);
  CheckTrue(O.IsSome, 'Should be Some');
  Inner := O.Unwrap;
  CheckTrue(Inner.IsOk, 'Inner should be Ok');
  CheckEquals(42, Inner.Unwrap);
end;

procedure TTestCase_TResult_Transpose.Test_ResultTranspose_OkNone_ReturnsNone;
var
  R: TIntOptResult;
  O: TOptIntResult;
begin
  // Ok(None) -> None
  R := TIntOptResult.Ok(specialize TOption<Integer>.None);
  O := specialize ResultTranspose<Integer, string>(R);
  CheckTrue(O.IsNone, 'Should be None');
end;

procedure TTestCase_TResult_Transpose.Test_ResultTranspose_Err_ReturnsSomeErr;
var
  R: TIntOptResult;
  O: TOptIntResult;
  Inner: TIntResult;
begin
  // Err(e) -> Some(Err(e))
  R := TIntOptResult.Err('failed');
  O := specialize ResultTranspose<Integer, string>(R);
  CheckTrue(O.IsSome, 'Should be Some');
  Inner := O.Unwrap;
  CheckTrue(Inner.IsErr, 'Inner should be Err');
  CheckEquals('failed', Inner.UnwrapErr);
end;

procedure TTestCase_TResult_Transpose.Test_OptionTranspose_None_ReturnsOkNone;
var
  O: TOptIntResult;
  R: TIntOptResult;
  InnerOpt: specialize TOption<Integer>;
begin
  // None -> Ok(None)
  O := TOptIntResult.None;
  R := specialize OptionTransposeResult<Integer, string>(O);
  CheckTrue(R.IsOk, 'Should be Ok');
  InnerOpt := R.Unwrap;
  CheckTrue(InnerOpt.IsNone, 'Inner should be None');
end;

procedure TTestCase_TResult_Transpose.Test_OptionTranspose_SomeOk_ReturnsOkSome;
var
  O: TOptIntResult;
  R: TIntOptResult;
  InnerOpt: specialize TOption<Integer>;
begin
  // Some(Ok(42)) -> Ok(Some(42))
  O := TOptIntResult.Some(TIntResult.Ok(42));
  R := specialize OptionTransposeResult<Integer, string>(O);
  CheckTrue(R.IsOk, 'Should be Ok');
  InnerOpt := R.Unwrap;
  CheckTrue(InnerOpt.IsSome, 'Inner should be Some');
  CheckEquals(42, InnerOpt.Unwrap);
end;

procedure TTestCase_TResult_Transpose.Test_OptionTranspose_SomeErr_ReturnsErr;
var
  O: TOptIntResult;
  R: TIntOptResult;
begin
  // Some(Err(e)) -> Err(e)
  O := TOptIntResult.Some(TIntResult.Err('failed'));
  R := specialize OptionTransposeResult<Integer, string>(O);
  CheckTrue(R.IsErr, 'Should be Err');
  CheckEquals('failed', R.UnwrapErr);
end;

initialization
  RegisterTest(TTestCase_TResult_Basic);
  RegisterTest(TTestCase_TResult_ToString);
  RegisterTest(TTestCase_TResult_Combinators);
  RegisterTest(TTestCase_TResult_ExceptionBridge);
  RegisterTest(TTestCase_TResult_Inspect);
  RegisterTest(TTestCase_TResult_NewAPI);
  RegisterTest(TTestCase_TOption_NewAPI);
  RegisterTest(TTestCase_TResult_Context);
  RegisterTest(TTestCase_TResult_Transpose);
  RegisterTest(TTestCase_TResult_FastAPI);
end.
