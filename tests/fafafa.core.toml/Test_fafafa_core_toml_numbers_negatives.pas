{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_numbers_negatives;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Numbers_Negatives = class(TTestCase)
  published
    procedure Test_Integer_Underscore_Leading_Should_Fail;
    procedure Test_Integer_Underscore_Trailing_Should_Fail;
    procedure Test_Float_Underscore_NextTo_Dot_Should_Fail;
    procedure Test_Exponent_Missing_Digits_Should_Fail;
    procedure Test_Exponent_Underscore_At_Start_Should_Fail;
    procedure Test_Integer_Consecutive_Underscores_Should_Fail;
    procedure Test_Exponent_Trailing_Underscore_Should_Fail;
    procedure Test_Exponent_Sign_Followed_By_Underscore_Should_Fail;
    procedure Test_Exponent_Sign_Double_Should_Fail;
    procedure Test_Integer_Sign_Followed_By_Underscore_Should_Fail;
    procedure Test_Float_Underscore_At_Start_Should_Fail;
    procedure Test_Exponent_Consecutive_Underscores_Should_Fail;
    procedure Test_Integer_Leading_Zero_Should_Fail;
    procedure Test_Float_Leading_Zero_Should_Fail;
  end;

implementation

procedure TTestCase_Numbers_Negatives.Test_Integer_Underscore_Leading_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('n = _1'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Integer_Underscore_Trailing_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('n = 1_'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Float_Underscore_NextTo_Dot_Should_Fail;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertFalse(Parse(RawByteString('f = 1._2'), LDoc, LErr));
  AssertTrue(LErr.HasError);

  LErr.Clear;
  AssertFalse(Parse(RawByteString('f = 1_.2'), LDoc, LErr));
  AssertTrue(LErr.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Exponent_Missing_Digits_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('f = 1e'), Doc, Err));
  AssertFalse(Parse(RawByteString('f = 1e+'), Doc, Err));
  AssertFalse(Parse(RawByteString('f = 1e-'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Exponent_Underscore_At_Start_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('f = 1e_10'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Integer_Consecutive_Underscores_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('n = 1__2'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Exponent_Trailing_Underscore_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('f = 1e10_'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Exponent_Sign_Followed_By_Underscore_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('f = 1e+_10'), Doc, Err));
  AssertTrue(Err.HasError);
end;


procedure TTestCase_Numbers_Negatives.Test_Exponent_Sign_Double_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('f = 1e+-10'), Doc, Err));
  AssertFalse(Parse(RawByteString('f = 1e-+10'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Integer_Sign_Followed_By_Underscore_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('n = -_1'), Doc, Err));
  AssertFalse(Parse(RawByteString('n = +_1'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Float_Underscore_At_Start_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('f = _1.0'), Doc, Err));
  AssertTrue(Err.HasError);
end;


procedure TTestCase_Numbers_Negatives.Test_Exponent_Consecutive_Underscores_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('f = 1e1__0'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Integer_Leading_Zero_Should_Fail;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertFalse(Parse(RawByteString('n = 01'), LDoc, LErr));
  AssertTrue(LErr.HasError);
end;

procedure TTestCase_Numbers_Negatives.Test_Float_Leading_Zero_Should_Fail;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertFalse(Parse(RawByteString('f = 00.1'), LDoc, LErr));
  AssertTrue(LErr.HasError);
end;

initialization
  RegisterTest(TTestCase_Numbers_Negatives);
end.

