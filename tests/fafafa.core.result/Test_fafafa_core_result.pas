{$CODEPAGE UTF8}
unit Test_fafafa_core_result;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testutils, testregistry;

type
  { TTestCase_Global }
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_Construct_IsOk_IsErr;
    procedure Test_Unwrap_UnwrapOr_Expect_UnwrapErr;
    procedure Test_Map_MapErr_AndThen_OrElse;
    procedure Test_Generic_Instantiations;
  end;

implementation

uses
  fafafa.core.result; // 待实现单元

type
  TResultIntStr = specialize TResult<Integer, string>;
  TResultStrInt = specialize TResult<string, Integer>;

procedure TTestCase_Global.Test_Construct_IsOk_IsErr;
var
  R1: TResultIntStr;
  R2: TResultIntStr;
begin
  R1 := TResultIntStr.Ok(42);
  AssertTrue(R1.IsOk);
  AssertFalse(R1.IsErr);

  R2 := TResultIntStr.Err('e');
  AssertTrue(R2.IsErr);
  AssertFalse(R2.IsOk);
end;

procedure TTestCase_Global.Test_Unwrap_UnwrapOr_Expect_UnwrapErr;
var
  ROk: TResultIntStr;
  RErr: TResultIntStr;
  Got: Integer;
  procedure P_UnwrapErr; begin RErr.Unwrap; end;
  procedure P_Expect; begin RErr.Expect('need value'); end;
  procedure P_UnwrapErrOnOk; begin ROk.UnwrapErr; end;
begin
  ROk := TResultIntStr.Ok(7);
  Got := ROk.Unwrap;
  AssertEquals(7, Got);
  AssertEquals(7, ROk.UnwrapOr(9));

  RErr := TResultIntStr.Err('bad');
  AssertEquals(9, RErr.UnwrapOr(9));


  AssertException(EResultUnwrapError, @P_UnwrapErr);
  AssertException(EResultUnwrapError, @P_Expect);
  AssertException(EResultUnwrapError, @P_UnwrapErrOnOk);
end;

function Inc1(const X: Integer): Integer; begin Result := X + 1; end;
function AsLen(const S: string): Integer; begin Result := Length(S); end;

function Bind_Positive(const X: Integer): specialize TResult<Integer, string>;
begin
  if X >= 0 then
    Exit(specialize TResult<Integer,string>.Ok(X))
  else
    Exit(specialize TResult<Integer,string>.Err('neg'));
end;

function Bind_Tag(const E: string): specialize TResult<Integer, string>;
begin
  Exit(specialize TResult<Integer,string>.Err('tag:' + E));
end;

procedure TTestCase_Global.Test_Map_MapErr_AndThen_OrElse;
var
  R: TResultIntStr;
  R2: TResultIntStr;
  R3: specialize TResult<Integer, Integer>;
  U: TResultIntStr;
  VInt: specialize TResult<Integer, Integer>;
  W: TResultIntStr;
begin
  R := TResultIntStr.Ok(1);
  R2 := ResultMap<Integer,string,Integer>(R, @Inc1);
  AssertTrue(R2.IsOk);
  AssertEquals(2, R2.Unwrap);

  U := TResultIntStr.Err('e');
  VInt := ResultMapErr<Integer,string,Integer>(U, @AsLen);
  AssertTrue(VInt.IsErr);
  R3 := VInt;
  AssertEquals(1, R3.UnwrapErr);

  W := ResultAndThen<Integer,string,Integer>(R, @Bind_Positive);
  AssertTrue(W.IsOk);
  AssertEquals(1, W.Unwrap);

  W := ResultOrElse<Integer,string,string>(U, @Bind_Tag);
  AssertTrue(W.IsErr);
  AssertEquals('tag:e', W.UnwrapErr);
end;

procedure TTestCase_Global.Test_Generic_Instantiations;
var
  R1: specialize TResult<string,Integer>;
  R2: specialize TResult<Integer,Exception>;
begin
  R1 := specialize TResult<string,Integer>.Ok('x');
  AssertTrue(R1.IsOk);
  R2 := specialize TResult<Integer,Exception>.Err(Exception.Create('oops'));
  AssertTrue(R2.IsErr);
end;

initialization
  RegisterTest(TTestCase_Global);
end.

