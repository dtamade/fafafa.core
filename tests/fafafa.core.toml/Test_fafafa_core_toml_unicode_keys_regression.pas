{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_unicode_keys_regression;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Unicode_Keys_Regression = class(TTestCase)
  published
    // Positives
    procedure Test_Quoted_Key_Positive_uXXXX;
    procedure Test_Quoted_Key_Positive_UXXXXXXXX;
    procedure Test_Table_Header_Positive_uXXXX;
    procedure Test_Inline_Table_Positive_UXXXXXXXX;
    // Negatives
    procedure Test_Quoted_Key_Invalid_u_Short;
    procedure Test_Quoted_Key_Invalid_u_NonHex;
    procedure Test_Quoted_Key_Invalid_u_Surrogate;
    procedure Test_Quoted_Key_Invalid_U_OutOfRange;
    procedure Test_Table_Header_Invalid_u_Short;
    procedure Test_Inline_Table_Invalid_U_OutOfRange;
  end;

implementation

procedure TTestCase_Unicode_Keys_Regression.Test_Quoted_Key_Positive_uXXXX;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('"\u0061" = 1'), Doc, Err));
  AssertFalse(Err.HasError);
  AssertTrue(Doc.Root.Contains('a'));
end;

procedure TTestCase_Unicode_Keys_Regression.Test_Quoted_Key_Positive_UXXXXXXXX;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('"\U00000041" = 1'), Doc, Err));
  AssertFalse(Err.HasError);
  AssertTrue(Doc.Root.Contains('A'));
end;

procedure TTestCase_Unicode_Keys_Regression.Test_Table_Header_Positive_uXXXX;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('["\u0061"]' + LineEnding + 'val=1'), Doc, Err));
  AssertFalse(Err.HasError);
end;

procedure TTestCase_Unicode_Keys_Regression.Test_Inline_Table_Positive_UXXXXXXXX;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('tbl={"\U00000041"=1}'), Doc, Err));
  AssertFalse(Err.HasError);
end;

procedure TTestCase_Unicode_Keys_Regression.Test_Quoted_Key_Invalid_u_Short;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('"a\u12" = 1'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Unicode_Keys_Regression.Test_Quoted_Key_Invalid_u_NonHex;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('"a\uZZZZ" = 1'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Unicode_Keys_Regression.Test_Quoted_Key_Invalid_u_Surrogate;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('"a\uD800" = 1'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Unicode_Keys_Regression.Test_Quoted_Key_Invalid_U_OutOfRange;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('"a\U110000" = 1'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Unicode_Keys_Regression.Test_Table_Header_Invalid_u_Short;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('["a\u12"]'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Unicode_Keys_Regression.Test_Inline_Table_Invalid_U_OutOfRange;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('tbl={"a\U110000"=1}'), Doc, Err));
  AssertTrue(Err.HasError);
end;

initialization
  RegisterTest(TTestCase_Unicode_Keys_Regression);
end.

