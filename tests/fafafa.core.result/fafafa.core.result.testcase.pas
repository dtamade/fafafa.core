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
    procedure Test_Map_On_Err_DoesNotCallMapper;
    procedure Test_MapErr_On_Ok;
    procedure Test_MapErr_On_Ok_DoesNotCallErrMapper;
    procedure Test_MapErr_On_Err;
    procedure Test_AndThen_On_Ok;
    procedure Test_AndThen_On_Err;
    procedure Test_AndThen_On_Err_DoesNotCallFunc;
    procedure Test_OrElse_On_Ok;
    procedure Test_OrElse_On_Ok_DoesNotCallRecover;
    procedure Test_OrElse_On_Err;
    procedure Test_MapOr;
    procedure Test_MapOrElse;
    procedure Test_MapOrElse_OnlyCallsMatchingBranch;
    procedure Test_Match;
    procedure Test_Swap;
    procedure Test_Flatten;
    procedure Test_And_;
    procedure Test_Or_;
    procedure Test_Contains;
    procedure Test_ContainsErr;
    procedure Test_FilterOrElse;
    procedure Test_FilterOrElse_On_Err_DoesNotCallPredOrErrFactory;
    procedure Test_IsOkAnd;
    procedure Test_IsErrAnd;
    procedure Test_Chain;
    procedure Test_Equals;
    procedure Test_MapBoth;
    procedure Test_Fold;
  end;

  { nil 回调/Printer 契约测试（防止 AV，提供更 Rust-like 的错误提示） }
  TTestCase_TResult_CallbackContracts = class(TTestCase)
  published
    procedure Test_ToDebugString_Ok_NilOkPrinter_UsesPlaceholder;
    procedure Test_ToDebugString_Err_NilErrPrinter_UsesPlaceholder;
    procedure Test_TErrorCtx_ToDebugString_NilPrinter_UsesPlaceholder;

    procedure Test_TryCollectPtrIntoArray_CountTooLarge_Raises;

    procedure Test_NilCallbacks_UnusedBranches_DoNotRaise;
    procedure Test_NilCallbacks_UnusedBranches_DoNotRaise_Methods;

    procedure Test_ResultMap_Ok_NilMapper_Raises;
    procedure Test_ResultMapErr_Err_NilMapper_Raises;
    procedure Test_ResultAndThen_Ok_NilFunc_Raises;
    procedure Test_ResultOrElse_Err_NilRecover_Raises;
    procedure Test_ResultMapOr_Ok_NilMapper_Raises;
    procedure Test_ResultMapOrElse_Ok_NilOkMapper_Raises;
    procedure Test_ResultMapOrElse_Err_NilErrMapper_Raises;
    procedure Test_ResultMatch_Ok_NilOkHandler_Raises;
    procedure Test_ResultMatch_Err_NilErrHandler_Raises;
    procedure Test_ResultMapBoth_Ok_NilOkMapper_Raises;
    procedure Test_ResultMapBoth_Err_NilErrMapper_Raises;
    procedure Test_ResultFilterOrElse_Ok_NilPred_Raises;
    procedure Test_ResultFilterOrElse_Ok_PredFalse_NilErrFactory_Raises;
    procedure Test_ResultEnsureWith_False_NilThunk_Raises;
    procedure Test_ResultFromOptionElse_None_NilThunk_Raises;
    procedure Test_ResultZipWith_OkOk_NilMapper_Raises;
    procedure Test_ResultWithContext_Err_NilFunc_Raises;
    procedure Test_ResultWithContextE_Err_NilFunc_Raises;
    procedure Test_ResultToTry_Err_NilMapper_Raises;
    procedure Test_ResultFromTry_NilWork_Raises;
    procedure Test_ResultFromTry_Exception_NilMapEx_Raises;

    procedure Test_TResult_UnwrapOrElse_Err_NilThunk_Raises;
    procedure Test_TResult_OrElseThunk_Err_NilThunk_Raises;
    procedure Test_TResult_Inspect_Ok_NilProc_Raises;
    procedure Test_TResult_InspectErr_Err_NilProc_Raises;
    procedure Test_TResult_IsOkAnd_Ok_NilPred_Raises;
    procedure Test_TResult_IsErrAnd_Err_NilPred_Raises;
    procedure Test_TResult_Contains_Ok_NilEq_Raises;
    procedure Test_TResult_ContainsErr_Err_NilEq_Raises;
    procedure Test_TResult_Equals_OkOk_NilEqT_Raises;
    procedure Test_TResult_Equals_ErrErr_NilEqE_Raises;
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
    procedure Test_OrElseThunk_On_Ok_DoesNotCallThunk;
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

  { Option nil 回调/Printer 契约测试（防止 AV，提供更一致的错误提示） }
  TTestCase_TOption_CallbackContracts = class(TTestCase)
  published
    procedure Test_ToDebugString_Some_NilPrinter_UsesPlaceholder;
    procedure Test_NilCallbacks_UnusedBranches_DoNotRaise;
    procedure Test_UnwrapOrElse_None_NilThunk_Raises;
    procedure Test_Inspect_Some_NilProc_Raises;
    procedure Test_IsSomeAnd_Some_NilPred_Raises;
    procedure Test_Contains_Some_NilEq_Raises;
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

  { 边界情况测试 - Phase 3.2 }
  TTestCase_TResult_EdgeCases = class(TTestCase)
  published
    { Batch 1: TryUnwrapErr 边界测试 }
    procedure Test_TryUnwrapErr_Ok_OverwritesOutParam;
    procedure Test_TryUnwrapErr_Err_MultipleCallsSameVar;
    { Batch 2: UnwrapUnchecked 边界测试 }
    procedure Test_UnwrapUnchecked_Performance_Comparison;
    procedure Test_UnwrapErrUnchecked_Performance_Comparison;
    { Batch 3: 复杂嵌套测试 }
    procedure Test_Flatten_TripleNested;
    procedure Test_Transpose_ComplexNesting;
  end;

  { 增强边界测试 - Phase 3.6 }
  TTestCase_TResult_EnhancedBoundary = class(TTestCase)
  published
    { Batch 1: 默认初始化和边界测试 }
    procedure Test_Default_Init_IsErr_ReturnsTrue;
    procedure Test_Default_Init_Unwrap_Raises;
    procedure Test_Ok_EmptyString_Operations;
    procedure Test_Err_EmptyString_Operations;
    procedure Test_Ok_MaxInt64_Unwrap;
    procedure Test_Ok_MinInt64_Unwrap;
    { Batch 2: 组合子链式调用测试 }
    procedure Test_Map_AndThen_MapErr_LongChain;
    procedure Test_Filter_Map_OrElse_Chain;
    procedure Test_Inspect_Map_InspectErr_Chain;
    procedure Test_Flatten_QuadrupleNested;
    procedure Test_MapBoth_AndThen_Chain;
    procedure Test_Swap_Swap_Identity;
    procedure Test_OrElse_AndThen_Chain;
    { Batch 3: 错误上下文和边界测试 }
    procedure Test_TErrorCtx_EmptyMsg;
    procedure Test_TErrorCtx_NestedErrorCtx;
    procedure Test_ResultContextE_MultipleChain;
    procedure Test_Equals_CustomEq_CaseInsensitive;
    procedure Test_ToString_SpecialChars;
    procedure Test_TryCollectPtrIntoArray_EmptyArray;
    procedure Test_ResultZip_MultipleResults;
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
    procedure Test_TryCollectPtrIntoArray_NilPtrWithCount_Raises;
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

uses
  fafafa.core.base;

type
  TIntResult = specialize TResult<Integer, string>;
  TStrResult = specialize TResult<string, Integer>;
  TTupIntInt = specialize TTuple2<Integer, Integer>;
  TTupIntIntResult = specialize TResult<TTupIntInt, string>;

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

function StrToStrFunc(const S: string): string;
begin
  Result := S;
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

{ Batch 2 辅助函数 }
function IncOneResult(const X: Integer): TIntResult;
begin
  Result := TIntResult.Ok(X + 1);
end;

function MakeErrMsg(const X: Integer): string;
begin
  Result := 'Error: ' + IntToStr(X);
end;

function AppendBangResult(const S: string): TStrResult;
begin
  Result := TStrResult.Ok(S + '!');
end;

function RecoverFromErr(const E: string): TIntResult;
begin
  if E = E then; // suppress hint
  Result := TIntResult.Ok(0);
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

procedure TTestCase_TResult_Combinators.Test_Map_On_Err_DoesNotCallMapper;
var
  Calls: Integer;
  R, R2: TIntResult;
  F: specialize TResultFunc<Integer, Integer>;
begin
  Calls := 0;
  F := function(const X: Integer): Integer
  begin
    Inc(Calls);
    Result := X + 1;
  end;

  R := TIntResult.Err('err');
  R2 := specialize ResultMap<Integer, string, Integer>(R, F);

  CheckEquals(0, Calls);
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

procedure TTestCase_TResult_Combinators.Test_MapErr_On_Ok_DoesNotCallErrMapper;
var
  Calls: Integer;
  R: TIntResult;
  R2: specialize TResult<Integer, Integer>;
  F: specialize TResultFunc<string, Integer>;
begin
  Calls := 0;
  F := function(const S: string): Integer
  begin
    Inc(Calls);
    Result := Length(S);
  end;

  R := TIntResult.Ok(10);
  R2 := specialize ResultMapErr<Integer, string, Integer>(R, F);

  CheckEquals(0, Calls);
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

procedure TTestCase_TResult_Combinators.Test_AndThen_On_Err_DoesNotCallFunc;
var
  Calls: Integer;
  R, R2: TIntResult;
  F: specialize TResultFunc<Integer, TIntResult>;
begin
  Calls := 0;
  F := function(const X: Integer): TIntResult
  begin
    Inc(Calls);
    Result := TIntResult.Ok(X * 2);
  end;

  R := TIntResult.Err('original');
  R2 := specialize ResultAndThen<Integer, string, Integer>(R, F);

  CheckEquals(0, Calls);
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

procedure TTestCase_TResult_Combinators.Test_OrElse_On_Ok_DoesNotCallRecover;
var
  Calls: Integer;
  R: TIntResult;
  R2: TIntResult;
  F: specialize TResultFunc<string, TIntResult>;
begin
  Calls := 0;
  F := function(const S: string): TIntResult
  begin
    Inc(Calls);
    Result := TIntResult.Ok(Length(S));
  end;

  R := TIntResult.Ok(42);
  R2 := specialize ResultOrElse<Integer, string, string>(R, F);

  CheckEquals(0, Calls);
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

procedure TTestCase_TResult_Combinators.Test_MapOrElse_OnlyCallsMatchingBranch;
var
  CallsOk, CallsErr: Integer;
  R: TIntResult;
  FErr: specialize TResultFunc<string, Integer>;
  FOk: specialize TResultFunc<Integer, Integer>;
  V: Integer;
begin
  CallsOk := 0;
  CallsErr := 0;

  FErr := function(const S: string): Integer
  begin
    Inc(CallsErr);
    Result := Length(S);
  end;

  FOk := function(const X: Integer): Integer
  begin
    Inc(CallsOk);
    Result := X * 10;
  end;

  R := TIntResult.Ok(5);
  V := specialize ResultMapOrElse<Integer, string, Integer>(R, FErr, FOk);
  CheckEquals(50, V);
  CheckEquals(1, CallsOk);
  CheckEquals(0, CallsErr);

  R := TIntResult.Err('abc');
  V := specialize ResultMapOrElse<Integer, string, Integer>(R, FErr, FOk);
  CheckEquals(3, V);
  CheckEquals(1, CallsOk);
  CheckEquals(1, CallsErr);
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
  // Ok(Ok(v)) -> Ok(v)
  Inner := TIntResult.Ok(99);
  Outer := specialize TResult<TIntResult, string>.Ok(Inner);
  Flat := specialize ResultFlatten<Integer, string>(Outer);
  CheckTrue(Flat.IsOk);
  CheckEquals(99, Flat.Unwrap);

  // Ok(Err(e)) -> Err(e) (inner error propagates)
  Inner := TIntResult.Err('inner err');
  Outer := specialize TResult<TIntResult, string>.Ok(Inner);
  Flat := specialize ResultFlatten<Integer, string>(Outer);
  CheckTrue(Flat.IsErr);
  CheckEquals('inner err', Flat.UnwrapErr);

  // Err(e) -> Err(e) (outer error)
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

procedure TTestCase_TResult_Combinators.Test_FilterOrElse_On_Err_DoesNotCallPredOrErrFactory;
var
  CallsPred, CallsErrFactory: Integer;
  R, R2: TIntResult;
  Pred: specialize TResultFunc<Integer, Boolean>;
  ErrFactory: specialize TResultFunc<Integer, string>;
begin
  CallsPred := 0;
  CallsErrFactory := 0;

  Pred := function(const X: Integer): Boolean
  begin
    Inc(CallsPred);
    Result := X > 0;
  end;

  ErrFactory := function(const X: Integer): string
  begin
    if X = X then; // suppress hint
    Inc(CallsErrFactory);
    Result := 'not positive';
  end;

  R := TIntResult.Err('original');
  R2 := specialize ResultFilterOrElse<Integer, string>(R, Pred, ErrFactory);

  CheckEquals(0, CallsPred);
  CheckEquals(0, CallsErrFactory);
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

{ TTestCase_TResult_CallbackContracts }

procedure TTestCase_TResult_CallbackContracts.Test_ToDebugString_Ok_NilOkPrinter_UsesPlaceholder;
var
  R: TIntResult;
  OkP: specialize TResultFunc<Integer, string>;
  ErrP: specialize TResultFunc<string, string>;
begin
  R := TIntResult.Ok(42);
  OkP := nil;
  ErrP := function(const S: string): string
  begin
    Result := S;
  end;

  CheckEquals('Ok(?)', R.ToDebugString(OkP, ErrP));
end;

procedure TTestCase_TResult_CallbackContracts.Test_ToDebugString_Err_NilErrPrinter_UsesPlaceholder;
var
  R: TIntResult;
  OkP: specialize TResultFunc<Integer, string>;
  ErrP: specialize TResultFunc<string, string>;
begin
  R := TIntResult.Err('fail');
  OkP := function(const X: Integer): string
  begin
    Result := IntToStr(X);
  end;
  ErrP := nil;

  CheckEquals('Err(?)', R.ToDebugString(OkP, ErrP));
end;

procedure TTestCase_TResult_CallbackContracts.Test_TErrorCtx_ToDebugString_NilPrinter_UsesPlaceholder;
type
  TIntErrorCtx = specialize TErrorCtx<Integer>;
var
  Ctx: TIntErrorCtx;
  P: specialize TResultFunc<Integer, string>;
begin
  Ctx := TIntErrorCtx.Create('operation failed', 500);
  P := nil;
  CheckEquals('operation failed (caused by: ?)', Ctx.ToDebugString(P));
end;

procedure TTestCase_TResult_CallbackContracts.Test_TryCollectPtrIntoArray_CountTooLarge_Raises;
var
  OutValues: specialize TValueArray<Integer> = nil;
  FirstErr: string;
  Count: SizeUInt;
begin
  // Arrange: pre-fill outputs to ensure they don't leak on exception
  SetLength(OutValues, 1);
  OutValues[0] := 123;
  FirstErr := 'old';

  Count := SizeUInt(High(SizeInt));
  Inc(Count);

  // Act + Assert
  try
    specialize TryCollectPtrIntoArray<Integer, string>(Pointer(1), Count, OutValues, FirstErr);
    Fail('Expected exception when Count is too large');
  except
    on E: EOutOfRange do
      CheckEquals('Count is out of range', E.Message);
  end;

  // Even on exception, outputs should have been reset at function entry
  CheckEquals(0, Length(OutValues));
  CheckEquals('', FirstErr);
end;

procedure TTestCase_TResult_CallbackContracts.Test_NilCallbacks_UnusedBranches_DoNotRaise;
type
  TIntIntResult = specialize TResult<Integer, Integer>;
  TStrStrResult = specialize TResult<string, string>;
  TTupIntStr = specialize TTuple2<Integer, string>;
  TIntErrResult = specialize TResult<Integer, Integer>;
  TIntStrResult = specialize TResult<Integer, string>;
  TIntCtxResult = specialize TResult<Integer, specialize TErrorCtx<Integer>>;
var
  R: TIntResult;
  R2: TIntResult;
  R2IntInt: TIntIntResult;
  RMb: TIntIntResult;
  Guard: specialize TResult<TUnit, string>;
  Opt: specialize TOption<Integer>;
  MapF: specialize TResultFunc<Integer, Integer>;
  MapErrF: specialize TResultFunc<string, Integer>;
  AndThenF: specialize TResultFunc<Integer, TIntResult>;
  OrElseF: specialize TResultFunc<string, TIntResult>;
  MapOrElseFerr: specialize TResultFunc<string, Integer>;
  MapOrElseFok: specialize TResultFunc<Integer, Integer>;
  MatchFok: specialize TResultFunc<Integer, Integer>;
  MatchFerr: specialize TResultFunc<string, Integer>;
  MapBothFok: specialize TResultFunc<Integer, Integer>;
  MapBothFerr: specialize TResultFunc<string, Integer>;
  Pred: specialize TResultFunc<Integer, Boolean>;
  ErrFactory: specialize TResultFunc<Integer, string>;
  EnsureThunk: specialize TResultThunk<string>;
  OptErrThunk: specialize TResultThunk<string>;
  ZipMapper: specialize TResultFunc<TTupIntStr, string>;
  A: TIntResult;
  B: TStrStrResult;
  Z: TStrStrResult;
  CtxFunc: specialize TResultFunc<Integer, string>;
  MapE: specialize TResultFunc<string, Exception>;
  Work: specialize TResultThunk<Integer>;
  MapEx: specialize TResultFunc<Exception, string>;
  ResInt: Integer;
  RIntErr: TIntErrResult;
  RCtx: TIntStrResult;
  RCtxE: TIntCtxResult;
begin
  // ResultMap: Err + nil mapper
  MapF := nil;
  R := TIntResult.Err('e');
  R2 := specialize ResultMap<Integer, string, Integer>(R, MapF);
  CheckTrue(R2.IsErr);

  // ResultMapErr: Ok + nil err-mapper
  MapErrF := nil;
  R := TIntResult.Ok(1);
  R2IntInt := specialize ResultMapErr<Integer, string, Integer>(R, MapErrF);
  CheckTrue(R2IntInt.IsOk);
  CheckEquals(1, R2IntInt.Unwrap);

  // ResultAndThen: Err + nil func
  AndThenF := nil;
  R := TIntResult.Err('e');
  R2 := specialize ResultAndThen<Integer, string, Integer>(R, AndThenF);
  CheckTrue(R2.IsErr);

  // ResultOrElse: Ok + nil recover
  OrElseF := nil;
  R := TIntResult.Ok(7);
  R2 := specialize ResultOrElse<Integer, string, string>(R, OrElseF);
  CheckTrue(R2.IsOk);
  CheckEquals(7, R2.Unwrap);

  // ResultMapOr: Err + nil mapper
  ResInt := specialize ResultMapOr<Integer, string, Integer>(TIntResult.Err('e'), 123, MapF);
  CheckEquals(123, ResInt);

  // ResultMapOrElse: Ok uses Fok; Ferr may be nil
  MapOrElseFerr := nil;
  MapOrElseFok := function(const X: Integer): Integer
  begin
    Result := X * 2;
  end;
  ResInt := specialize ResultMapOrElse<Integer, string, Integer>(TIntResult.Ok(10), MapOrElseFerr, MapOrElseFok);
  CheckEquals(20, ResInt);

  // ResultMapOrElse: Err uses Ferr; Fok may be nil
  MapOrElseFok := nil;
  MapOrElseFerr := function(const S: string): Integer
  begin
    Result := Length(S);
  end;
  ResInt := specialize ResultMapOrElse<Integer, string, Integer>(TIntResult.Err('abc'), MapOrElseFerr, MapOrElseFok);
  CheckEquals(3, ResInt);

  // ResultMatch: Ok uses Fok; Ferr may be nil
  MatchFerr := nil;
  MatchFok := function(const X: Integer): Integer
  begin
    Result := X + 1;
  end;
  ResInt := specialize ResultMatch<Integer, string, Integer>(TIntResult.Ok(1), MatchFok, MatchFerr);
  CheckEquals(2, ResInt);

  // ResultMatch: Err uses Ferr; Fok may be nil
  MatchFok := nil;
  MatchFerr := function(const S: string): Integer
  begin
    Result := Length(S);
  end;
  ResInt := specialize ResultMatch<Integer, string, Integer>(TIntResult.Err('abc'), MatchFok, MatchFerr);
  CheckEquals(3, ResInt);

  // ResultMapBoth: Ok uses Fok; Ferr may be nil
  MapBothFerr := nil;
  MapBothFok := function(const X: Integer): Integer
  begin
    Result := X;
  end;
  RMb := specialize ResultMapBoth<Integer, string, Integer, Integer>(TIntResult.Ok(5), MapBothFok, MapBothFerr);
  CheckTrue(RMb.IsOk);
  CheckEquals(5, RMb.Unwrap);

  // ResultMapBoth: Err uses Ferr; Fok may be nil
  MapBothFok := nil;
  MapBothFerr := function(const S: string): Integer
  begin
    Result := Length(S);
  end;
  RMb := specialize ResultMapBoth<Integer, string, Integer, Integer>(TIntResult.Err('abc'), MapBothFok, MapBothFerr);
  CheckTrue(RMb.IsErr);
  CheckEquals(3, RMb.UnwrapErr);

  // ResultFilterOrElse: Err uses no callbacks
  Pred := nil;
  ErrFactory := nil;
  R := TIntResult.Err('orig');
  R2 := specialize ResultFilterOrElse<Integer, string>(R, Pred, ErrFactory);
  CheckTrue(R2.IsErr);
  CheckEquals('orig', R2.UnwrapErr);

  // ResultEnsureWith: Cond=True does not call ErrThunk
  EnsureThunk := nil;
  Guard := specialize ResultEnsureWith<string>(True, EnsureThunk);
  CheckTrue(Guard.IsOk);

  // ResultFromOptionElse: Some does not call ErrThunk
  OptErrThunk := nil;
  Opt := specialize TOption<Integer>.Some(42);
  R := specialize ResultFromOptionElse<Integer, string>(Opt, OptErrThunk);
  CheckTrue(R.IsOk);
  CheckEquals(42, R.Unwrap);

  // ResultZipWith: Err path does not call mapper
  ZipMapper := nil;
  A := TIntResult.Err('e1');
  B := TStrStrResult.Ok('hello');
  Z := specialize ResultZipWith<Integer, string, string, string>(A, B, ZipMapper);
  CheckTrue(Z.IsErr);
  CheckEquals('e1', Z.UnwrapErr);

  // ResultWithContext: Ok does not call CtxFunc
  CtxFunc := nil;
  RIntErr := TIntErrResult.Ok(1);
  RCtx := specialize ResultWithContext<Integer, Integer>(RIntErr, CtxFunc);
  CheckTrue(RCtx.IsOk);
  CheckEquals(1, RCtx.Unwrap);

  // ResultWithContextE: Ok does not call CtxFunc
  RCtxE := specialize ResultWithContextE<Integer, Integer>(RIntErr, CtxFunc);
  CheckTrue(RCtxE.IsOk);
  CheckEquals(1, RCtxE.Unwrap);

  // ResultToTry: Ok does not call MapE
  MapE := nil;
  ResInt := specialize ResultToTry<Integer, string>(TIntResult.Ok(7), MapE);
  CheckEquals(7, ResInt);

  // ResultFromTry: success does not call MapEx
  Work := @WorkOk;
  MapEx := nil;
  R := specialize ResultFromTry<Integer, string>(Work, MapEx);
  CheckTrue(R.IsOk);
  CheckEquals(42, R.Unwrap);
end;

procedure TTestCase_TResult_CallbackContracts.Test_NilCallbacks_UnusedBranches_DoNotRaise_Methods;
var
  R, R2: TIntResult;
  ThunkInt: specialize TResultThunk<Integer>;
  ThunkRes: specialize TResultThunk<TIntResult>;
  ProcInt: specialize TResultProc<Integer>;
  ProcStr: specialize TResultProc<string>;
  PredInt: specialize TResultFunc<Integer, Boolean>;
  PredStr: specialize TResultFunc<string, Boolean>;
  EqInt: specialize TResultBiPred<Integer, Integer>;
  EqStr: specialize TResultBiPred<string, string>;
  Other: TIntResult;
  EqT: specialize TResultBiPred<Integer, Integer>;
  EqE: specialize TResultBiPred<string, string>;
begin
  // UnwrapOrElse: Ok does not call thunk
  ThunkInt := nil;
  R := TIntResult.Ok(42);
  CheckEquals(42, R.UnwrapOrElse(ThunkInt));

  // OrElseThunk: Ok does not call thunk
  ThunkRes := nil;
  R := TIntResult.Ok(1);
  R2 := R.OrElseThunk(ThunkRes);
  CheckTrue(R2.IsOk);
  CheckEquals(1, R2.Unwrap);

  // Inspect: Err does not call proc
  ProcInt := nil;
  R := TIntResult.Err('e');
  R2 := R.Inspect(ProcInt);
  CheckTrue(R2.IsErr);
  CheckEquals('e', R2.UnwrapErr);

  // InspectErr: Ok does not call proc
  ProcStr := nil;
  R := TIntResult.Ok(1);
  R2 := R.InspectErr(ProcStr);
  CheckTrue(R2.IsOk);
  CheckEquals(1, R2.Unwrap);

  // IsOkAnd: Err does not call pred
  PredInt := nil;
  R := TIntResult.Err('e');
  CheckFalse(R.IsOkAnd(PredInt));

  // IsErrAnd: Ok does not call pred
  PredStr := nil;
  R := TIntResult.Ok(1);
  CheckFalse(R.IsErrAnd(PredStr));

  // Contains: Err does not call Eq
  EqInt := nil;
  R := TIntResult.Err('e');
  CheckFalse(R.Contains(1, EqInt));

  // ContainsErr: Ok does not call Eq
  EqStr := nil;
  R := TIntResult.Ok(1);
  CheckFalse(R.ContainsErr('e', EqStr));

  // Equals: Ok vs Err does not call EqT/EqE
  EqT := nil;
  EqE := nil;
  R := TIntResult.Ok(1);
  Other := TIntResult.Err('e');
  CheckFalse(R.Equals(Other, EqT, EqE));
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultMap_Ok_NilMapper_Raises;
var
  R: TIntResult;
  F: specialize TResultFunc<Integer, Integer>;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  // Release 模式下跳过此测试，因为 nil 检查已被移除以提升性能
  R := TIntResult.Ok(1);
  F := nil;
  try
    specialize ResultMap<Integer, string, Integer>(R, F);
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsOk then; // suppress unused variable warning
  if F = F then;  // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultMapErr_Err_NilMapper_Raises;
var
  R: TIntResult;
  F: specialize TResultFunc<string, Integer>;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Err('e');
  F := nil;
  try
    specialize ResultMapErr<Integer, string, Integer>(R, F);
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsErr then; // suppress unused variable warning
  if F = F then;   // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultAndThen_Ok_NilFunc_Raises;
var
  R: TIntResult;
  F: specialize TResultFunc<Integer, TIntResult>;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Ok(1);
  F := nil;
  try
    specialize ResultAndThen<Integer, string, Integer>(R, F);
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsOk then; // suppress unused variable warning
  if F = F then;  // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultOrElse_Err_NilRecover_Raises;
var
  R: TIntResult;
  F: specialize TResultFunc<string, TIntResult>;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Err('e');
  F := nil;
  try
    specialize ResultOrElse<Integer, string, string>(R, F);
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsErr then; // suppress unused variable warning
  if F = F then;   // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultMapOr_Ok_NilMapper_Raises;
var
  R: TIntResult;
  F: specialize TResultFunc<Integer, Integer>;
  V: Integer;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Ok(1);
  F := nil;
  try
    V := specialize ResultMapOr<Integer, string, Integer>(R, 0, F);
    if V = V then; // suppress hint
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsOk then; // suppress unused variable warning
  if F = F then;  // suppress unused variable warning
  V := 0;         // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultMapOrElse_Ok_NilOkMapper_Raises;
var
  R: TIntResult;
  Ferr: specialize TResultFunc<string, Integer>;
  Fok: specialize TResultFunc<Integer, Integer>;
  V: Integer;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Ok(1);
  Ferr := function(const S: string): Integer
  begin
    Result := Length(S);
  end;
  Fok := nil;

  try
    V := specialize ResultMapOrElse<Integer, string, Integer>(R, Ferr, Fok);
    if V = V then; // suppress hint
    Fail('Expected exception: aFok is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aFok is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsOk then;  // suppress unused variable warning
  Ferr := nil;     // suppress unused variable warning
  Fok := nil;      // suppress unused variable warning
  V := 0;          // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultMapOrElse_Err_NilErrMapper_Raises;
var
  R: TIntResult;
  Ferr: specialize TResultFunc<string, Integer>;
  Fok: specialize TResultFunc<Integer, Integer>;
  V: Integer;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Err('abc');
  Ferr := nil;
  Fok := function(const X: Integer): Integer
  begin
    Result := X;
  end;

  try
    V := specialize ResultMapOrElse<Integer, string, Integer>(R, Ferr, Fok);
    if V = V then; // suppress hint
    Fail('Expected exception: aFerr is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aFerr is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsErr then; // suppress unused variable warning
  Ferr := nil;     // suppress unused variable warning
  Fok := nil;      // suppress unused variable warning
  V := 0;          // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultMatch_Ok_NilOkHandler_Raises;
var
  R: TIntResult;
  Fok: specialize TResultFunc<Integer, Integer>;
  Ferr: specialize TResultFunc<string, Integer>;
  V: Integer;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Ok(1);
  Fok := nil;
  Ferr := function(const S: string): Integer
  begin
    Result := Length(S);
  end;

  try
    V := specialize ResultMatch<Integer, string, Integer>(R, Fok, Ferr);
    if V = V then; // suppress hint
    Fail('Expected exception: aFok is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aFok is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsOk then; // suppress unused variable warning
  Fok := nil;     // suppress unused variable warning
  Ferr := nil;    // suppress unused variable warning
  V := 0;         // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultMatch_Err_NilErrHandler_Raises;
var
  R: TIntResult;
  Fok: specialize TResultFunc<Integer, Integer>;
  Ferr: specialize TResultFunc<string, Integer>;
  V: Integer;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Err('abc');
  Fok := function(const X: Integer): Integer
  begin
    Result := X;
  end;
  Ferr := nil;

  try
    V := specialize ResultMatch<Integer, string, Integer>(R, Fok, Ferr);
    if V = V then; // suppress hint
    Fail('Expected exception: aFerr is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aFerr is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsErr then; // suppress unused variable warning
  Fok := nil;      // suppress unused variable warning
  Ferr := nil;     // suppress unused variable warning
  V := 0;          // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultMapBoth_Ok_NilOkMapper_Raises;
var
  R: TIntResult;
  Fok: specialize TResultFunc<Integer, Integer>;
  Ferr: specialize TResultFunc<string, Integer>;
  OutR: specialize TResult<Integer, Integer>;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Ok(1);
  Fok := nil;
  Ferr := function(const S: string): Integer
  begin
    Result := Length(S);
  end;

  try
    OutR := specialize ResultMapBoth<Integer, string, Integer, Integer>(R, Fok, Ferr);
    if OutR.IsOk then; // suppress hint
    Fail('Expected exception: aFok is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aFok is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsOk then;   // suppress unused variable warning
  Fok := nil;       // suppress unused variable warning
  Ferr := nil;      // suppress unused variable warning
  if OutR.IsOk then; // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultMapBoth_Err_NilErrMapper_Raises;
var
  R: TIntResult;
  Fok: specialize TResultFunc<Integer, Integer>;
  Ferr: specialize TResultFunc<string, Integer>;
  OutR: specialize TResult<Integer, Integer>;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Err('abc');
  Fok := function(const X: Integer): Integer
  begin
    Result := X;
  end;
  Ferr := nil;

  try
    OutR := specialize ResultMapBoth<Integer, string, Integer, Integer>(R, Fok, Ferr);
    if OutR.IsErr then; // suppress hint
    Fail('Expected exception: aFerr is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aFerr is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsErr then;  // suppress unused variable warning
  Fok := nil;       // suppress unused variable warning
  Ferr := nil;      // suppress unused variable warning
  if OutR.IsErr then; // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultFilterOrElse_Ok_NilPred_Raises;
var
  R: TIntResult;
  Pred: specialize TResultFunc<Integer, Boolean>;
  Ferr: specialize TResultFunc<Integer, string>;
  OutR: TIntResult;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Ok(1);
  Pred := nil;
  Ferr := function(const X: Integer): string
  begin
    if X = X then; // suppress hint
    Result := 'bad';
  end;

  try
    OutR := specialize ResultFilterOrElse<Integer, string>(R, Pred, Ferr);
    if OutR.IsOk then; // suppress hint
    Fail('Expected exception: aPred is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aPred is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsOk then;  // suppress unused variable warning
  Pred := nil;     // suppress unused variable warning
  Ferr := nil;     // suppress unused variable warning
  OutR := R;       // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultFilterOrElse_Ok_PredFalse_NilErrFactory_Raises;
var
  R: TIntResult;
  Pred: specialize TResultFunc<Integer, Boolean>;
  Ferr: specialize TResultFunc<Integer, string>;
  OutR: TIntResult;
begin
  {$IFDEF DEBUG}
  // ✅ Phase 4.2.2: nil 检查仅在 Debug 模式下有效
  R := TIntResult.Ok(1);
  Pred := function(const X: Integer): Boolean
  begin
    if X = X then; // suppress hint
    Result := False;
  end;
  Ferr := nil;

  try
    OutR := specialize ResultFilterOrElse<Integer, string>(R, Pred, Ferr);
    if OutR.IsErr then; // suppress hint
    Fail('Expected exception: aFerr is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aFerr is nil', E.Message);
  end;
  {$ELSE}
  // Release 模式：nil 检查已移除，测试自动通过
  if R.IsOk then;  // suppress unused variable warning
  Pred := nil;     // suppress unused variable warning
  Ferr := nil;     // suppress unused variable warning
  OutR := R;       // suppress unused variable warning
  {$ENDIF}
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultEnsureWith_False_NilThunk_Raises;
var
  Thunk: specialize TResultThunk<string>;
  R: specialize TResult<TUnit, string>;
begin
  Thunk := nil;
  try
    R := specialize ResultEnsureWith<string>(False, Thunk);
    if R.IsOk then; // suppress hint
    Fail('Expected exception: ErrThunk is nil');
  except
    on E: EArgumentNil do
      CheckEquals('ErrThunk is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultFromOptionElse_None_NilThunk_Raises;
var
  O: specialize TOption<Integer>;
  Thunk: specialize TResultThunk<string>;
  R: TIntResult;
begin
  O := specialize TOption<Integer>.None;
  Thunk := nil;

  try
    R := specialize ResultFromOptionElse<Integer, string>(O, Thunk);
    if R.IsOk then; // suppress hint
    Fail('Expected exception: ErrThunk is nil');
  except
    on E: EArgumentNil do
      CheckEquals('ErrThunk is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultZipWith_OkOk_NilMapper_Raises;
type
  TStrStrResult = specialize TResult<string, string>;
  TTupIntStr = specialize TTuple2<Integer, string>;
var
  A: TIntResult;
  B: TStrStrResult;
  F: specialize TResultFunc<TTupIntStr, string>;
  Z: TStrStrResult;
begin
  A := TIntResult.Ok(1);
  B := TStrStrResult.Ok('x');
  F := nil;

  try
    Z := specialize ResultZipWith<Integer, string, string, string>(A, B, F);
    if Z.IsOk then; // suppress hint
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultWithContext_Err_NilFunc_Raises;
type
  TIntErrResult = specialize TResult<Integer, Integer>;
  TIntStrResult = specialize TResult<Integer, string>;
var
  R: TIntErrResult;
  CtxFunc: specialize TResultFunc<Integer, string>;
  R2: TIntStrResult;
begin
  R := TIntErrResult.Err(123);
  CtxFunc := nil;

  try
    R2 := specialize ResultWithContext<Integer, Integer>(R, CtxFunc);
    if R2.IsOk then; // suppress hint
    Fail('Expected exception: CtxFunc is nil');
  except
    on E: EArgumentNil do
      CheckEquals('CtxFunc is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultWithContextE_Err_NilFunc_Raises;
type
  TIntErrResult = specialize TResult<Integer, Integer>;
  TIntCtxResult = specialize TResult<Integer, specialize TErrorCtx<Integer>>;
var
  R: TIntErrResult;
  CtxFunc: specialize TResultFunc<Integer, string>;
  R2: TIntCtxResult;
begin
  R := TIntErrResult.Err(123);
  CtxFunc := nil;

  try
    R2 := specialize ResultWithContextE<Integer, Integer>(R, CtxFunc);
    if R2.IsOk then; // suppress hint
    Fail('Expected exception: CtxFunc is nil');
  except
    on E: EArgumentNil do
      CheckEquals('CtxFunc is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultToTry_Err_NilMapper_Raises;
var
  R: TIntResult;
  MapE: specialize TResultFunc<string, Exception>;
  V: Integer;
begin
  R := TIntResult.Err('boom');
  MapE := nil;

  try
    V := specialize ResultToTry<Integer, string>(R, MapE);
    if V = V then; // suppress hint
    Fail('Expected exception: MapE is nil');
  except
    on E: EArgumentNil do
      CheckEquals('MapE is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultFromTry_NilWork_Raises;
var
  Work: specialize TResultThunk<Integer>;
  MapEx: specialize TResultFunc<Exception, string>;
  R: TIntResult;
begin
  Work := nil;
  MapEx := function(const Ex: Exception): string
  begin
    Result := Ex.Message;
  end;

  try
    R := specialize ResultFromTry<Integer, string>(Work, MapEx);
    if R.IsOk then; // suppress hint
    Fail('Expected exception: Work is nil');
  except
    on E: EArgumentNil do
      CheckEquals('Work is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_ResultFromTry_Exception_NilMapEx_Raises;
var
  Work: specialize TResultThunk<Integer>;
  MapEx: specialize TResultFunc<Exception, string>;
  R: TIntResult;
begin
  Work := @WorkFail;
  MapEx := nil;

  try
    R := specialize ResultFromTry<Integer, string>(Work, MapEx);
    if R.IsOk then; // suppress hint
    Fail('Expected exception: MapEx is nil');
  except
    on E: EArgumentNil do
      CheckEquals('MapEx is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_TResult_UnwrapOrElse_Err_NilThunk_Raises;
var
  R: TIntResult;
  F: specialize TResultThunk<Integer>;
  V: Integer;
begin
  R := TIntResult.Err('e');
  F := nil;

  try
    V := R.UnwrapOrElse(F);
    if V = V then; // suppress hint
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_TResult_OrElseThunk_Err_NilThunk_Raises;
var
  R, R2: TIntResult;
  F: specialize TResultThunk<TIntResult>;
begin
  R := TIntResult.Err('e');
  F := nil;

  try
    R2 := R.OrElseThunk(F);
    if R2.IsOk then; // suppress hint
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_TResult_Inspect_Ok_NilProc_Raises;
var
  R, R2: TIntResult;
  F: specialize TResultProc<Integer>;
begin
  R := TIntResult.Ok(1);
  F := nil;

  try
    R2 := R.Inspect(F);
    if R2.IsOk then; // suppress hint
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_TResult_InspectErr_Err_NilProc_Raises;
var
  R, R2: TIntResult;
  F: specialize TResultProc<string>;
begin
  R := TIntResult.Err('e');
  F := nil;

  try
    R2 := R.InspectErr(F);
    if R2.IsErr then; // suppress hint
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_TResult_IsOkAnd_Ok_NilPred_Raises;
var
  R: TIntResult;
  Pred: specialize TResultFunc<Integer, Boolean>;
  B: Boolean;
begin
  R := TIntResult.Ok(1);
  Pred := nil;

  try
    B := R.IsOkAnd(Pred);
    if B then; // suppress hint
    Fail('Expected exception: aPred is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aPred is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_TResult_IsErrAnd_Err_NilPred_Raises;
var
  R: TIntResult;
  Pred: specialize TResultFunc<string, Boolean>;
  B: Boolean;
begin
  R := TIntResult.Err('e');
  Pred := nil;

  try
    B := R.IsErrAnd(Pred);
    if B then; // suppress hint
    Fail('Expected exception: aPred is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aPred is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_TResult_Contains_Ok_NilEq_Raises;
var
  R: TIntResult;
  Eq: specialize TResultBiPred<Integer, Integer>;
  B: Boolean;
begin
  R := TIntResult.Ok(1);
  Eq := nil;

  try
    B := R.Contains(1, Eq);
    if B then; // suppress hint
    Fail('Expected exception: aEq is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aEq is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_TResult_ContainsErr_Err_NilEq_Raises;
var
  R: TIntResult;
  Eq: specialize TResultBiPred<string, string>;
  B: Boolean;
begin
  R := TIntResult.Err('e');
  Eq := nil;

  try
    B := R.ContainsErr('e', Eq);
    if B then; // suppress hint
    Fail('Expected exception: aEq is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aEq is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_TResult_Equals_OkOk_NilEqT_Raises;
var
  A, B: TIntResult;
  EqT: specialize TResultBiPred<Integer, Integer>;
  EqE: specialize TResultBiPred<string, string>;
  Res: Boolean;
begin
  A := TIntResult.Ok(1);
  B := TIntResult.Ok(1);
  EqT := nil;
  EqE := @StrEq;

  try
    Res := A.Equals(B, EqT, EqE);
    if Res then; // suppress hint
    Fail('Expected exception: aEqT is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aEqT is nil', E.Message);
  end;
end;

procedure TTestCase_TResult_CallbackContracts.Test_TResult_Equals_ErrErr_NilEqE_Raises;
var
  A, B: TIntResult;
  EqT: specialize TResultBiPred<Integer, Integer>;
  EqE: specialize TResultBiPred<string, string>;
  Res: Boolean;
begin
  A := TIntResult.Err('e');
  B := TIntResult.Err('e');
  EqT := @IntEq;
  EqE := nil;

  try
    Res := A.Equals(B, EqT, EqE);
    if Res then; // suppress hint
    Fail('Expected exception: aEqE is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aEqE is nil', E.Message);
  end;
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

{ TTestCase_TOption_CallbackContracts }

procedure TTestCase_TOption_CallbackContracts.Test_ToDebugString_Some_NilPrinter_UsesPlaceholder;
type
  TIntOption = specialize TOption<Integer>;
var
  O: TIntOption;
  P: specialize TOptionFunc<Integer, string>;
begin
  O := TIntOption.Some(42);
  P := nil;
  CheckEquals('Some(?)', O.ToDebugString(P));
end;

procedure TTestCase_TOption_CallbackContracts.Test_NilCallbacks_UnusedBranches_DoNotRaise;
type
  TIntOption = specialize TOption<Integer>;
var
  O: TIntOption;
  Thunk: specialize TOptionThunk<Integer>;
  Proc: specialize TOptionProc<Integer>;
  Pred: specialize TOptionFunc<Integer, Boolean>;
  Eq: specialize TOptionBiPred<Integer, Integer>;
  B: Boolean;
begin
  // UnwrapOrElse: Some does not call thunk
  Thunk := nil;
  O := TIntOption.Some(1);
  CheckEquals(1, O.UnwrapOrElse(Thunk));

  // Inspect: None does not call proc
  Proc := nil;
  O := TIntOption.None;
  O := O.Inspect(Proc);
  CheckTrue(O.IsNone);

  // IsSomeAnd: None does not call pred
  Pred := nil;
  O := TIntOption.None;
  B := O.IsSomeAnd(Pred);
  CheckFalse(B);

  // Contains: None does not call Eq
  Eq := nil;
  O := TIntOption.None;
  B := O.Contains(1, Eq);
  CheckFalse(B);
end;

procedure TTestCase_TOption_CallbackContracts.Test_UnwrapOrElse_None_NilThunk_Raises;
type
  TIntOption = specialize TOption<Integer>;
var
  O: TIntOption;
  Thunk: specialize TOptionThunk<Integer>;
  V: Integer;
begin
  O := TIntOption.None;
  Thunk := nil;

  try
    V := O.UnwrapOrElse(Thunk);
    if V = V then; // suppress hint
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
end;

procedure TTestCase_TOption_CallbackContracts.Test_Inspect_Some_NilProc_Raises;
type
  TIntOption = specialize TOption<Integer>;
var
  O: TIntOption;
  Proc: specialize TOptionProc<Integer>;
begin
  O := TIntOption.Some(1);
  Proc := nil;

  try
    O := O.Inspect(Proc);
    if O.IsSome then; // suppress hint
    Fail('Expected exception: aF is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aF is nil', E.Message);
  end;
end;

procedure TTestCase_TOption_CallbackContracts.Test_IsSomeAnd_Some_NilPred_Raises;
type
  TIntOption = specialize TOption<Integer>;
var
  O: TIntOption;
  Pred: specialize TOptionFunc<Integer, Boolean>;
  B: Boolean;
begin
  O := TIntOption.Some(1);
  Pred := nil;

  try
    B := O.IsSomeAnd(Pred);
    if B then; // suppress hint
    Fail('Expected exception: aPred is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aPred is nil', E.Message);
  end;
end;

procedure TTestCase_TOption_CallbackContracts.Test_Contains_Some_NilEq_Raises;
type
  TIntOption = specialize TOption<Integer>;
var
  O: TIntOption;
  Eq: specialize TOptionBiPred<Integer, Integer>;
  B: Boolean;
begin
  O := TIntOption.Some(1);
  Eq := nil;

  try
    B := O.Contains(1, Eq);
    if B then; // suppress hint
    Fail('Expected exception: aEq is nil');
  except
    on E: EArgumentNil do
      CheckEquals('aEq is nil', E.Message);
  end;
end;

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

procedure TTestCase_TResult_NewAPI.Test_OrElseThunk_On_Ok_DoesNotCallThunk;
var
  Calls: Integer;
  R, R2: TIntResult;
  Thunk: specialize TResultThunk<TIntResult>;
begin
  Calls := 0;
  Thunk := function: TIntResult
  begin
    Inc(Calls);
    Result := TIntResult.Ok(999);
  end;

  R := TIntResult.Ok(42);
  R2 := R.OrElseThunk(Thunk);

  CheckEquals(0, Calls);
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
  Zipped: specialize TOption<specialize TTuple2<Integer, string>>;
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

procedure TTestCase_TResult_FastAPI.Test_TryCollectPtrIntoArray_NilPtrWithCount_Raises;
var
  OutValues: specialize TValueArray<Integer> = nil;
  FirstErr: string;
begin
  // Arrange: pre-fill outputs to ensure they don't leak on exception
  SetLength(OutValues, 1);
  OutValues[0] := 123;
  FirstErr := 'old';

  // Act + Assert
  try
    specialize TryCollectPtrIntoArray<Integer, string>(nil, 1, OutValues, FirstErr);
    Fail('Expected exception when ItemsPtr=nil and Count>0');
  except
    on E: EArgumentNil do
      CheckEquals('ItemsPtr is nil', E.Message);
  end;

  // Even on exception, outputs should have been reset at function entry
  CheckEquals(0, Length(OutValues));
  CheckEquals('', FirstErr);
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

{ TTestCase_TResult_EdgeCases - Phase 3.2 }

procedure TTestCase_TResult_EdgeCases.Test_TryUnwrapErr_Ok_OverwritesOutParam;
var
  R: TIntResult;
  E: string;
begin
  // 测试 Ok 时 out 参数是否被覆盖为默认值
  E := 'previous value';
  R := TIntResult.Ok(42);

  CheckFalse(R.TryUnwrapErr(E), 'TryUnwrapErr on Ok should return false');
  CheckEquals('', E, 'Out param should be overwritten with default value');
end;

procedure TTestCase_TResult_EdgeCases.Test_TryUnwrapErr_Err_MultipleCallsSameVar;
var
  R1, R2: TIntResult;
  E: string;
begin
  // 测试连续调用 TryUnwrapErr 到同一个变量
  R1 := TIntResult.Err('first error');
  R2 := TIntResult.Err('second error');

  CheckTrue(R1.TryUnwrapErr(E), 'First TryUnwrapErr should succeed');
  CheckEquals('first error', E, 'First error should be extracted');

  CheckTrue(R2.TryUnwrapErr(E), 'Second TryUnwrapErr should succeed');
  CheckEquals('second error', E, 'Second error should overwrite first');
end;

procedure TTestCase_TResult_EdgeCases.Test_UnwrapUnchecked_Performance_Comparison;
var
  R: TIntResult;
  I, Iterations: Integer;
  StartTime, EndTime: QWord;
  UncheckedTime, CheckedTime: QWord;
begin
  // 性能对比测试：UnwrapUnchecked vs Unwrap
  Iterations := 1000000;
  R := TIntResult.Ok(42);

  // 测试 UnwrapUnchecked 性能
  StartTime := GetTickCount64;
  for I := 1 to Iterations do
    R.UnwrapUnchecked;
  EndTime := GetTickCount64;
  UncheckedTime := EndTime - StartTime;

  // 测试 Unwrap 性能
  StartTime := GetTickCount64;
  for I := 1 to Iterations do
    R.Unwrap;
  EndTime := GetTickCount64;
  CheckedTime := EndTime - StartTime;

  // UnwrapUnchecked 应该更快或相当（允许一些误差）
  CheckTrue(UncheckedTime <= CheckedTime + 100,
    Format('UnwrapUnchecked (%d ms) should be faster than or equal to Unwrap (%d ms)',
    [UncheckedTime, CheckedTime]));
end;

procedure TTestCase_TResult_EdgeCases.Test_UnwrapErrUnchecked_Performance_Comparison;
var
  R: TIntResult;
  I, Iterations: Integer;
  StartTime, EndTime: QWord;
  UncheckedTime, CheckedTime: QWord;
begin
  // 性能对比测试：UnwrapErrUnchecked vs UnwrapErr
  Iterations := 1000000;
  R := TIntResult.Err('error');

  // 测试 UnwrapErrUnchecked 性能
  StartTime := GetTickCount64;
  for I := 1 to Iterations do
    R.UnwrapErrUnchecked;
  EndTime := GetTickCount64;
  UncheckedTime := EndTime - StartTime;

  // 测试 UnwrapErr 性能
  StartTime := GetTickCount64;
  for I := 1 to Iterations do
    R.UnwrapErr;
  EndTime := GetTickCount64;
  CheckedTime := EndTime - StartTime;

  // UnwrapErrUnchecked 应该更快或相当（允许一些误差）
  CheckTrue(UncheckedTime <= CheckedTime + 100,
    Format('UnwrapErrUnchecked (%d ms) should be faster than or equal to UnwrapErr (%d ms)',
    [UncheckedTime, CheckedTime]));
end;

procedure TTestCase_TResult_EdgeCases.Test_Flatten_TripleNested;
var
  Innermost: TIntResult;
  Middle: specialize TResult<TIntResult, string>;
  Outer: specialize TResult<specialize TResult<TIntResult, string>, string>;
  FlatOnce: specialize TResult<TIntResult, string>;
  FlatTwice: TIntResult;
begin
  // 测试三层嵌套：Result<Result<Result<Int, Str>, Str>, Str>

  // Ok(Ok(Ok(99))) -> 展平两次 -> Ok(99)
  Innermost := TIntResult.Ok(99);
  Middle := specialize TResult<TIntResult, string>.Ok(Innermost);
  Outer := specialize TResult<specialize TResult<TIntResult, string>, string>.Ok(Middle);

  FlatOnce := specialize ResultFlatten<TIntResult, string>(Outer);
  CheckTrue(FlatOnce.IsOk, 'First flatten should be Ok');

  FlatTwice := specialize ResultFlatten<Integer, string>(FlatOnce);
  CheckTrue(FlatTwice.IsOk, 'Second flatten should be Ok');
  CheckEquals(99, FlatTwice.Unwrap, 'Final value should be 99');

  // Ok(Ok(Err(e))) -> 展平两次 -> Err(e)
  Innermost := TIntResult.Err('inner error');
  Middle := specialize TResult<TIntResult, string>.Ok(Innermost);
  Outer := specialize TResult<specialize TResult<TIntResult, string>, string>.Ok(Middle);

  FlatOnce := specialize ResultFlatten<TIntResult, string>(Outer);
  FlatTwice := specialize ResultFlatten<Integer, string>(FlatOnce);
  CheckTrue(FlatTwice.IsErr, 'Should be Err');
  CheckEquals('inner error', FlatTwice.UnwrapErr, 'Inner error should propagate');

  // Ok(Err(e)) -> 展平一次 -> Err(e)
  Middle := specialize TResult<TIntResult, string>.Err('middle error');
  Outer := specialize TResult<specialize TResult<TIntResult, string>, string>.Ok(Middle);

  FlatOnce := specialize ResultFlatten<TIntResult, string>(Outer);
  CheckTrue(FlatOnce.IsErr, 'Should be Err');
  CheckEquals('middle error', FlatOnce.UnwrapErr, 'Middle error should propagate');

  // Err(e) -> 展平一次 -> Err(e)
  Outer := specialize TResult<specialize TResult<TIntResult, string>, string>.Err('outer error');

  FlatOnce := specialize ResultFlatten<TIntResult, string>(Outer);
  CheckTrue(FlatOnce.IsErr, 'Should be Err');
  CheckEquals('outer error', FlatOnce.UnwrapErr, 'Outer error should propagate');
end;

procedure TTestCase_TResult_EdgeCases.Test_Transpose_ComplexNesting;
var
  // 测试链式 Transpose：先 Option->Result，再 Result->Option
  OptResult: specialize TOption<TIntResult>;
  ResultOpt: specialize TResult<specialize TOption<Integer>, string>;
  TransposedBack: specialize TOption<TIntResult>;
  FinalResult: TIntResult;
  FinalOpt: specialize TOption<Integer>;
  // 多层 Option 嵌套类型
  NestedOpt: specialize TOption<specialize TOption<Integer>>;
  InnerOpt: specialize TOption<Integer>;
begin
  // 测试复杂嵌套：链式应用 Transpose

  // 场景 1: Some(Ok(42)) -> Ok(Some(42)) -> Some(Ok(42))
  OptResult := specialize TOption<TIntResult>.Some(TIntResult.Ok(42));

  // 第一次转置：Option<Result<T,E>> -> Result<Option<T>,E>
  ResultOpt := specialize OptionTransposeResult<Integer, string>(OptResult);
  CheckTrue(ResultOpt.IsOk, 'First transpose should be Ok');
  FinalOpt := ResultOpt.Unwrap;
  CheckTrue(FinalOpt.IsSome, 'Should be Some');
  CheckEquals(42, FinalOpt.Unwrap, 'Value should be 42');

  // 第二次转置：Result<Option<T>,E> -> Option<Result<T,E>>
  TransposedBack := specialize ResultTranspose<Integer, string>(ResultOpt);
  CheckTrue(TransposedBack.IsSome, 'Second transpose should be Some');
  FinalResult := TransposedBack.Unwrap;
  CheckTrue(FinalResult.IsOk, 'Final should be Ok');
  CheckEquals(42, FinalResult.Unwrap, 'Final value should be 42');

  // 场景 2: Some(Err(e)) -> Err(e) (第一次转置后就是 Err，无法继续)
  OptResult := specialize TOption<TIntResult>.Some(TIntResult.Err('error'));
  ResultOpt := specialize OptionTransposeResult<Integer, string>(OptResult);
  CheckTrue(ResultOpt.IsErr, 'Should be Err');
  CheckEquals('error', ResultOpt.UnwrapErr, 'Error should propagate');

  // 场景 3: None -> Ok(None) -> None
  OptResult := specialize TOption<TIntResult>.None;
  ResultOpt := specialize OptionTransposeResult<Integer, string>(OptResult);
  CheckTrue(ResultOpt.IsOk, 'Should be Ok');
  FinalOpt := ResultOpt.Unwrap;
  CheckTrue(FinalOpt.IsNone, 'Should be None');

  // 第二次转置
  TransposedBack := specialize ResultTranspose<Integer, string>(ResultOpt);
  CheckTrue(TransposedBack.IsNone, 'Should be None after second transpose');

  // 场景 4: 测试多层 Option 嵌套
  // Some(Some(42))
  NestedOpt := specialize TOption<specialize TOption<Integer>>.Some(
    specialize TOption<Integer>.Some(42)
  );
  CheckTrue(NestedOpt.IsSome, 'Outer should be Some');
  InnerOpt := NestedOpt.Unwrap;
  CheckTrue(InnerOpt.IsSome, 'Inner should be Some');
  CheckEquals(42, InnerOpt.Unwrap, 'Value should be 42');

  // Some(None)
  NestedOpt := specialize TOption<specialize TOption<Integer>>.Some(
    specialize TOption<Integer>.None
  );
  CheckTrue(NestedOpt.IsSome, 'Outer should be Some');
  InnerOpt := NestedOpt.Unwrap;
  CheckTrue(InnerOpt.IsNone, 'Inner should be None');

  // None
  NestedOpt := specialize TOption<specialize TOption<Integer>>.None;
  CheckTrue(NestedOpt.IsNone, 'Should be None');
end;

{ TTestCase_TResult_EnhancedBoundary }

procedure TTestCase_TResult_EnhancedBoundary.Test_Default_Init_IsErr_ReturnsTrue;
var
  R: TIntResult;
begin
  // 默认初始化的 Result 应该是 Err 状态
  CheckTrue(R.IsErr, 'Default initialized Result should be Err');
  CheckFalse(R.IsOk, 'Default initialized Result should not be Ok');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_Default_Init_Unwrap_Raises;
var
  R: TIntResult;
  ExceptionRaised: Boolean;
begin
  // 默认初始化的 Result 调用 Unwrap 应该抛出异常
  ExceptionRaised := False;
  try
    R.Unwrap;
  except
    on E: EResultUnwrapError do
      ExceptionRaised := True;
  end;
  CheckTrue(ExceptionRaised, 'Unwrap on default initialized Result should raise EResultUnwrapError');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_Ok_EmptyString_Operations;
var
  R: specialize TResult<string, Integer>;
  Value: string;
begin
  // 测试 Ok('') 的各种操作
  R := specialize TResult<string, Integer>.Ok('');

  CheckTrue(R.IsOk, 'Ok with empty string should be Ok');
  CheckFalse(R.IsErr, 'Ok with empty string should not be Err');

  Value := R.Unwrap;
  CheckEquals('', Value, 'Unwrap should return empty string');

  Value := R.UnwrapOr('default');
  CheckEquals('', Value, 'UnwrapOr should return empty string, not default');

  CheckTrue(R.TryUnwrap(Value), 'TryUnwrap should return True');
  CheckEquals('', Value, 'TryUnwrap should set value to empty string');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_Err_EmptyString_Operations;
var
  R: specialize TResult<Integer, string>;
  ErrValue: string;
begin
  // 测试 Err('') 的各种操作
  R := specialize TResult<Integer, string>.Err('');

  CheckTrue(R.IsErr, 'Err with empty string should be Err');
  CheckFalse(R.IsOk, 'Err with empty string should not be Ok');

  ErrValue := R.UnwrapErr;
  CheckEquals('', ErrValue, 'UnwrapErr should return empty string');

  CheckTrue(R.TryUnwrapErr(ErrValue), 'TryUnwrapErr should return True');
  CheckEquals('', ErrValue, 'TryUnwrapErr should set error to empty string');

  CheckEquals(42, R.UnwrapOr(42), 'UnwrapOr should return default value');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_Ok_MaxInt64_Unwrap;
var
  R: specialize TResult<Int64, string>;
  Value: Int64;
begin
  // 测试 Ok(High(Int64)) 的行为
  R := specialize TResult<Int64, string>.Ok(High(Int64));

  CheckTrue(R.IsOk, 'Ok with High(Int64) should be Ok');

  Value := R.Unwrap;
  CheckEquals(High(Int64), Value, 'Unwrap should return High(Int64)');

  Value := R.UnwrapOr(0);
  CheckEquals(High(Int64), Value, 'UnwrapOr should return High(Int64), not default');

  CheckTrue(R.TryUnwrap(Value), 'TryUnwrap should return True');
  CheckEquals(High(Int64), Value, 'TryUnwrap should set value to High(Int64)');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_Ok_MinInt64_Unwrap;
var
  R: specialize TResult<Int64, string>;
  Value: Int64;
begin
  // 测试 Ok(Low(Int64)) 的行为
  R := specialize TResult<Int64, string>.Ok(Low(Int64));

  CheckTrue(R.IsOk, 'Ok with Low(Int64) should be Ok');

  Value := R.Unwrap;
  CheckEquals(Low(Int64), Value, 'Unwrap should return Low(Int64)');

  Value := R.UnwrapOr(0);
  CheckEquals(Low(Int64), Value, 'UnwrapOr should return Low(Int64), not default');

  CheckTrue(R.TryUnwrap(Value), 'TryUnwrap should return True');
  CheckEquals(Low(Int64), Value, 'TryUnwrap should set value to Low(Int64)');
end;

{ Batch 2: 组合子链式调用测试 }

procedure TTestCase_TResult_EnhancedBoundary.Test_Map_AndThen_MapErr_LongChain;
var
  R: TIntResult;
  R2: TIntResult;
  R3: TIntResult;
begin
  // 测试 Map → AndThen → MapErr 长链式调用
  // 场景 1: Ok 路径
  R := TIntResult.Ok(10);

  // Map: 10 -> 20
  R2 := specialize ResultMap<Integer, string, Integer>(R, @DoubleIt);
  CheckTrue(R2.IsOk, 'After Map should be Ok');
  CheckEquals(20, R2.Unwrap, 'Map should double the value');

  // AndThen: 20 -> Ok(21)
  R3 := specialize ResultAndThen<Integer, string, Integer>(R2, @IncOneResult);
  CheckTrue(R3.IsOk, 'After AndThen should be Ok');
  CheckEquals(21, R3.Unwrap, 'AndThen should increment the value');

  // MapErr: 不应该被调用（因为是 Ok）
  R3 := specialize ResultMapErr<Integer, string, string>(R3, @AppendBang);
  CheckTrue(R3.IsOk, 'After MapErr should still be Ok');
  CheckEquals(21, R3.Unwrap, 'Value should remain unchanged');

  // 场景 2: Err 路径
  R := TIntResult.Err('error');

  // Map: 不应该被调用
  R2 := specialize ResultMap<Integer, string, Integer>(R, @DoubleIt);
  CheckTrue(R2.IsErr, 'After Map should be Err');
  CheckEquals('error', R2.UnwrapErr, 'Error should propagate');

  // AndThen: 不应该被调用
  R3 := specialize ResultAndThen<Integer, string, Integer>(R2, @IncOneResult);
  CheckTrue(R3.IsErr, 'After AndThen should be Err');
  CheckEquals('error', R3.UnwrapErr, 'Error should propagate');

  // MapErr: 应该被调用
  R3 := specialize ResultMapErr<Integer, string, string>(R3, @AppendBang);
  CheckTrue(R3.IsErr, 'After MapErr should be Err');
  CheckEquals('error!', R3.UnwrapErr, 'MapErr should append bang');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_Filter_Map_OrElse_Chain;
var
  R: TIntResult;
  R2: TIntResult;
  R3: TIntResult;
begin
  // 测试 FilterOrElse → Map → OrElse 链式调用
  // 场景 1: Filter 通过
  R := TIntResult.Ok(10);

  // FilterOrElse: 10 > 5, 通过
  R2 := specialize ResultFilterOrElse<Integer, string>(R, @IsPositive, @MakeErrMsg);
  CheckTrue(R2.IsOk, 'Filter should pass for positive value');
  CheckEquals(10, R2.Unwrap, 'Value should remain unchanged');

  // Map: 10 -> 20
  R3 := specialize ResultMap<Integer, string, Integer>(R2, @DoubleIt);
  CheckTrue(R3.IsOk, 'After Map should be Ok');
  CheckEquals(20, R3.Unwrap, 'Map should double the value');

  // OrElse: 不应该被调用（因为是 Ok）
  R3 := R3.Or_(TIntResult.Ok(999));
  CheckTrue(R3.IsOk, 'After OrElse should be Ok');
  CheckEquals(20, R3.Unwrap, 'Value should remain unchanged');

  // 场景 2: Filter 失败
  R := TIntResult.Ok(-5);

  // FilterOrElse: -5 < 0, 失败
  R2 := specialize ResultFilterOrElse<Integer, string>(R, @IsPositive, @MakeErrMsg);
  CheckTrue(R2.IsErr, 'Filter should fail for negative value');

  // Map: 不应该被调用
  R3 := specialize ResultMap<Integer, string, Integer>(R2, @DoubleIt);
  CheckTrue(R3.IsErr, 'After Map should be Err');

  // OrElse: 应该被调用
  R3 := R3.Or_(TIntResult.Ok(999));
  CheckTrue(R3.IsOk, 'After OrElse should be Ok');
  CheckEquals(999, R3.Unwrap, 'OrElse should provide fallback value');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_Inspect_Map_InspectErr_Chain;
var
  R: TIntResult;
  R2: TIntResult;
  R3: TIntResult;
  InspectCalled: Boolean;
  InspectErrCalled: Boolean;
begin
  // 测试 Inspect → Map → InspectErr 链式调用
  InspectCalled := False;
  InspectErrCalled := False;

  // 场景 1: Ok 路径
  R := TIntResult.Ok(10);

  // Inspect: 应该被调用
  R2 := R.Inspect(
    procedure(const V: Integer)
    begin
      InspectCalled := True;
      CheckEquals(10, V, 'Inspect should receive correct value');
    end
  );
  CheckTrue(InspectCalled, 'Inspect should be called for Ok');
  CheckTrue(R2.IsOk, 'After Inspect should be Ok');
  CheckEquals(10, R2.Unwrap, 'Value should remain unchanged');

  // Map: 10 -> 20
  R3 := specialize ResultMap<Integer, string, Integer>(R2, @DoubleIt);
  CheckTrue(R3.IsOk, 'After Map should be Ok');
  CheckEquals(20, R3.Unwrap, 'Map should double the value');

  // InspectErr: 不应该被调用（因为是 Ok）
  R3 := R3.InspectErr(
    procedure(const E: string)
    begin
      InspectErrCalled := True;
    end
  );
  CheckFalse(InspectErrCalled, 'InspectErr should not be called for Ok');
  CheckTrue(R3.IsOk, 'After InspectErr should be Ok');
  CheckEquals(20, R3.Unwrap, 'Value should remain unchanged');

  // 场景 2: Err 路径
  InspectCalled := False;
  InspectErrCalled := False;
  R := TIntResult.Err('error');

  // Inspect: 不应该被调用
  R2 := R.Inspect(
    procedure(const V: Integer)
    begin
      InspectCalled := True;
    end
  );
  CheckFalse(InspectCalled, 'Inspect should not be called for Err');
  CheckTrue(R2.IsErr, 'After Inspect should be Err');

  // Map: 不应该被调用
  R3 := specialize ResultMap<Integer, string, Integer>(R2, @DoubleIt);
  CheckTrue(R3.IsErr, 'After Map should be Err');

  // InspectErr: 应该被调用
  R3 := R3.InspectErr(
    procedure(const E: string)
    begin
      InspectErrCalled := True;
      CheckEquals('error', E, 'InspectErr should receive correct error');
    end
  );
  CheckTrue(InspectErrCalled, 'InspectErr should be called for Err');
  CheckTrue(R3.IsErr, 'After InspectErr should be Err');
  CheckEquals('error', R3.UnwrapErr, 'Error should remain unchanged');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_Flatten_QuadrupleNested;
var
  Quadruple: specialize TResult<specialize TResult<specialize TResult<TIntResult, string>, string>, string>;
  Triple: specialize TResult<specialize TResult<TIntResult, string>, string>;
  Double: specialize TResult<TIntResult, string>;
  Single: TIntResult;
begin
  // 测试四层嵌套 Flatten
  // 场景 1: Ok(Ok(Ok(Ok(42))))
  Quadruple := specialize TResult<specialize TResult<specialize TResult<TIntResult, string>, string>, string>.Ok(
    specialize TResult<specialize TResult<TIntResult, string>, string>.Ok(
      specialize TResult<TIntResult, string>.Ok(
        TIntResult.Ok(42)
      )
    )
  );

  // 第一次 Flatten
  Triple := specialize ResultFlatten<specialize TResult<TIntResult, string>, string>(Quadruple);
  CheckTrue(Triple.IsOk, 'First flatten should be Ok');

  // 第二次 Flatten
  Double := specialize ResultFlatten<TIntResult, string>(Triple);
  CheckTrue(Double.IsOk, 'Second flatten should be Ok');

  // 第三次 Flatten
  Single := specialize ResultFlatten<Integer, string>(Double);
  CheckTrue(Single.IsOk, 'Third flatten should be Ok');
  CheckEquals(42, Single.Unwrap, 'Final value should be 42');

  // 场景 2: Ok(Ok(Err(e)))
  Quadruple := specialize TResult<specialize TResult<specialize TResult<TIntResult, string>, string>, string>.Ok(
    specialize TResult<specialize TResult<TIntResult, string>, string>.Ok(
      specialize TResult<TIntResult, string>.Err('inner error')
    )
  );

  // 第一次 Flatten
  Triple := specialize ResultFlatten<specialize TResult<TIntResult, string>, string>(Quadruple);
  CheckTrue(Triple.IsOk, 'First flatten should be Ok');

  // 第二次 Flatten
  Double := specialize ResultFlatten<TIntResult, string>(Triple);
  CheckTrue(Double.IsErr, 'Second flatten should be Err');
  CheckEquals('inner error', Double.UnwrapErr, 'Error should propagate');

  // 场景 3: Err(e)
  Quadruple := specialize TResult<specialize TResult<specialize TResult<TIntResult, string>, string>, string>.Err('outer error');

  // 第一次 Flatten
  Triple := specialize ResultFlatten<specialize TResult<TIntResult, string>, string>(Quadruple);
  CheckTrue(Triple.IsErr, 'First flatten should be Err');
  CheckEquals('outer error', Triple.UnwrapErr, 'Outer error should propagate');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_MapBoth_AndThen_Chain;
var
  R: TIntResult;
  R2: specialize TResult<string, Integer>;
  R3: specialize TResult<string, Integer>;
begin
  // 测试 MapBoth → AndThen 链式调用
  // 场景 1: Ok 路径
  R := TIntResult.Ok(10);

  // MapBoth: Ok(10) -> Ok("10")
  R2 := specialize ResultMapBoth<Integer, string, string, Integer>(R, @IntToStrFunc, @StrLen);
  CheckTrue(R2.IsOk, 'MapBoth should be Ok');
  CheckEquals('10', R2.Unwrap, 'MapBoth should convert to string');

  // AndThen: "10" -> Ok("10!")
  R3 := specialize ResultAndThen<string, Integer, string>(R2, @AppendBangResult);
  CheckTrue(R3.IsOk, 'AndThen should be Ok');
  CheckEquals('10!', R3.Unwrap, 'AndThen should append bang');

  // 场景 2: Err 路径
  R := TIntResult.Err('error');

  // MapBoth: Err("error") -> Err(5)
  R2 := specialize ResultMapBoth<Integer, string, string, Integer>(R, @IntToStrFunc, @StrLen);
  CheckTrue(R2.IsErr, 'MapBoth should be Err');
  CheckEquals(5, R2.UnwrapErr, 'MapBoth should convert error to length');

  // AndThen: 不应该被调用（因为是 Err）
  R3 := specialize ResultAndThen<string, Integer, string>(R2, @AppendBangResult);
  CheckTrue(R3.IsErr, 'AndThen should be Err');
  CheckEquals(5, R3.UnwrapErr, 'Error should propagate');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_Swap_Swap_Identity;
var
  R: TIntResult;
  R2: TStrResult;
  R3: TIntResult;
begin
  // 测试 Swap → Swap 应该返回原值
  // 场景 1: Ok(42)
  R := TIntResult.Ok(42);

  // 第一次 Swap: Ok(42) -> Err(42)
  R2 := specialize ResultSwap<Integer, string>(R);
  CheckTrue(R2.IsErr, 'First swap should be Err');
  CheckEquals(42, R2.UnwrapErr, 'Error should be original value');

  // 第二次 Swap: Err(42) -> Ok(42)
  R3 := specialize ResultSwap<string, Integer>(R2);
  CheckTrue(R3.IsOk, 'Second swap should be Ok');
  CheckEquals(42, R3.Unwrap, 'Value should be original value');

  // 场景 2: Err("error")
  R := TIntResult.Err('error');

  // 第一次 Swap: Err("error") -> Ok("error")
  R2 := specialize ResultSwap<Integer, string>(R);
  CheckTrue(R2.IsOk, 'First swap should be Ok');
  CheckEquals('error', R2.Unwrap, 'Value should be original error');

  // 第二次 Swap: Ok("error") -> Err("error")
  R3 := specialize ResultSwap<string, Integer>(R2);
  CheckTrue(R3.IsErr, 'Second swap should be Err');
  CheckEquals('error', R3.UnwrapErr, 'Error should be original error');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_OrElse_AndThen_Chain;
var
  R: TIntResult;
  R2: TIntResult;
  R3: TIntResult;
begin
  // 测试 OrElse → AndThen 链式调用
  // 场景 1: Ok 路径
  R := TIntResult.Ok(10);

  // OrElse: 不应该被调用（因为是 Ok）
  R2 := specialize ResultOrElse<Integer, string, string>(R, @RecoverFromErr);
  CheckTrue(R2.IsOk, 'OrElse should be Ok');
  CheckEquals(10, R2.Unwrap, 'Value should remain unchanged');

  // AndThen: 10 -> Ok(11)
  R3 := specialize ResultAndThen<Integer, string, Integer>(R2, @IncOneResult);
  CheckTrue(R3.IsOk, 'AndThen should be Ok');
  CheckEquals(11, R3.Unwrap, 'AndThen should increment the value');

  // 场景 2: Err 路径
  R := TIntResult.Err('error');

  // OrElse: 应该被调用
  R2 := specialize ResultOrElse<Integer, string, string>(R, @RecoverFromErr);
  CheckTrue(R2.IsOk, 'OrElse should recover to Ok');
  CheckEquals(0, R2.Unwrap, 'OrElse should provide fallback value');

  // AndThen: 0 -> Ok(1)
  R3 := specialize ResultAndThen<Integer, string, Integer>(R2, @IncOneResult);
  CheckTrue(R3.IsOk, 'AndThen should be Ok');
  CheckEquals(1, R3.Unwrap, 'AndThen should increment the value');
end;

{ Batch 3: 错误上下文和边界测试 }

procedure TTestCase_TResult_EnhancedBoundary.Test_TErrorCtx_EmptyMsg;
var
  Ctx: TIntErrorCtx;
begin
  // 测试空消息的 TErrorCtx
  Ctx := TIntErrorCtx.Create('', 404);
  CheckEquals('', Ctx.Msg, 'Empty message should be preserved');
  CheckEquals(404, Ctx.Inner, 'Inner error should be preserved');
  CheckEquals(' (caused by: 404)', Ctx.ToDebugString(@IntPrinterForCtx), 'Empty message should show only inner error');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_TErrorCtx_NestedErrorCtx;
type
  TNestedErrorCtx = specialize TErrorCtx<TIntErrorCtx>;
  TNestedCtxResult = specialize TResult<Integer, TNestedErrorCtx>;
var
  InnerCtx: TIntErrorCtx;
  OuterCtx: TNestedErrorCtx;
  R: TNestedCtxResult;
begin
  // 测试 TErrorCtx<TErrorCtx<E>> 嵌套
  InnerCtx := TIntErrorCtx.Create('database error', 500);
  OuterCtx := TNestedErrorCtx.Create('operation failed', InnerCtx);

  CheckEquals('operation failed', OuterCtx.Msg, 'Outer message should be preserved');
  CheckEquals('database error', OuterCtx.Inner.Msg, 'Inner message should be preserved');
  CheckEquals(500, OuterCtx.Inner.Inner, 'Innermost error should be preserved');

  // 测试嵌套 Result
  R := TNestedCtxResult.Err(OuterCtx);
  CheckTrue(R.IsErr, 'Result should be Err');
  CheckEquals('operation failed', R.UnwrapErr.Msg, 'Outer message should be accessible');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_ResultContextE_MultipleChain;
var
  R: TIntErrResult;
  R2: TIntCtxResult;
  R3: specialize TResult<Integer, specialize TErrorCtx<TIntErrorCtx>>;
  ErrCtx: specialize TErrorCtx<TIntErrorCtx>;
begin
  // 测试多次 ResultContextE 链式调用
  R := TIntErrResult.Err(404);

  // 第一次添加上下文
  R2 := specialize ResultContextE<Integer, Integer>(R, 'file not found');
  CheckTrue(R2.IsErr, 'First context should be Err');
  CheckEquals('file not found', R2.UnwrapErr.Msg, 'First context message should be correct');

  // 第二次添加上下文（嵌套）
  R3 := specialize ResultContextE<Integer, TIntErrorCtx>(R2, 'operation failed');
  CheckTrue(R3.IsErr, 'Second context should be Err');
  ErrCtx := R3.UnwrapErr;
  CheckEquals('operation failed', ErrCtx.Msg, 'Outer context message should be correct');
  CheckEquals('file not found', ErrCtx.Inner.Msg, 'Inner context message should be correct');
  CheckEquals(404, ErrCtx.Inner.Inner, 'Original error should be preserved');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_Equals_CustomEq_CaseInsensitive;
var
  R1, R2: TStrResult;

  function CaseInsensitiveEq(const A, B: string): Boolean;
  begin
    Result := LowerCase(A) = LowerCase(B);
  end;

begin
  // 测试大小写不敏感的相等性
  R1 := TStrResult.Ok('Hello');
  R2 := TStrResult.Ok('HELLO');

  // 默认相等性（大小写敏感）
  CheckFalse(R1.Equals(R2, @StrEq, @IntEq),
    'Default equality should be case-sensitive');

  // 自定义相等性（大小写不敏感）
  CheckTrue(R1.Equals(R2, @CaseInsensitiveEq, @IntEq),
    'Custom equality should be case-insensitive');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_ToString_SpecialChars;
var
  R: TStrResult;
  S: string;
begin
  // 测试 ToString 的基本行为
  R := TStrResult.Ok('Hello'#10'World'#13#10'!');
  S := R.ToString('Ok: value', 'Err: error');
  CheckEquals('Ok: value', S, 'ToString should return Ok label for Ok result');

  // 测试错误情况
  R := TStrResult.Err(123);
  S := R.ToString('Ok: value', 'Err: error');
  CheckEquals('Err: error', S, 'ToString should return Err label for Err result');

  // 测试空标签
  R := TStrResult.Ok('test');
  S := R.ToString('', '');
  CheckEquals('', S, 'ToString should return empty string for empty Ok label');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_TryCollectPtrIntoArray_EmptyArray;
var
  Arr: array of TIntResult;
  OutArr: array of Integer;
  OutErr: string;
  Success: Boolean;
begin
  // 测试空数组的 collect
  SetLength(Arr, 0);
  Success := specialize TryCollectPtrIntoArray<Integer, string>(nil, 0, OutArr, OutErr);

  CheckTrue(Success, 'Empty array should succeed');
  CheckEquals(0, Length(OutArr), 'Output array should be empty');
  CheckEquals('', OutErr, 'Error should be empty');
end;

procedure TTestCase_TResult_EnhancedBoundary.Test_ResultZip_MultipleResults;
var
  R1, R2, R3: TIntResult;
  R12: TTupIntIntResult;
  R123: specialize TResult<specialize TTuple2<TTupIntInt, Integer>, string>;
begin
  // 测试多个 Result 的 Zip 操作
  R1 := TIntResult.Ok(1);
  R2 := TIntResult.Ok(2);
  R3 := TIntResult.Ok(3);

  // 先 Zip R1 和 R2
  R12 := specialize ResultZip<Integer, Integer, string>(R1, R2);
  CheckTrue(R12.IsOk, 'First zip should be Ok');
  CheckEquals(1, R12.Unwrap.First, 'First value should be 1');
  CheckEquals(2, R12.Unwrap.Second, 'Second value should be 2');

  // 再 Zip R12 和 R3
  R123 := specialize ResultZip<TTupIntInt, Integer, string>(R12, R3);
  CheckTrue(R123.IsOk, 'Second zip should be Ok');
  CheckEquals(1, R123.Unwrap.First.First, 'First value should be 1');
  CheckEquals(2, R123.Unwrap.First.Second, 'Second value should be 2');
  CheckEquals(3, R123.Unwrap.Second, 'Third value should be 3');
end;

initialization
  RegisterTest(TTestCase_TResult_Basic);
  RegisterTest(TTestCase_TResult_ToString);
  RegisterTest(TTestCase_TResult_Combinators);
  RegisterTest(TTestCase_TResult_CallbackContracts);
  RegisterTest(TTestCase_TResult_ExceptionBridge);
  RegisterTest(TTestCase_TResult_Inspect);
  RegisterTest(TTestCase_TResult_NewAPI);
  RegisterTest(TTestCase_TOption_NewAPI);
  RegisterTest(TTestCase_TOption_CallbackContracts);
  RegisterTest(TTestCase_TResult_Context);
  RegisterTest(TTestCase_TResult_Transpose);
  RegisterTest(TTestCase_TResult_FastAPI);
  RegisterTest(TTestCase_TResult_EdgeCases);
  RegisterTest(TTestCase_TResult_EnhancedBoundary);
end.
