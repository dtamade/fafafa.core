{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_unicode_negatives;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Unicode_Negatives = class(TTestCase)
  published
    procedure Test_uXXXX_Invalid_Length;
    procedure Test_uXXXX_NonHex;
    procedure Test_UXXXXXXXX_OutOfRange;
    procedure Test_uXXXX_Surrogate_Alone_Should_Fail;
  end;

implementation

procedure TTestCase_Unicode_Negatives.Test_uXXXX_Invalid_Length;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 少于4位
  AssertFalse(Parse(RawByteString('s = "\u123"'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Unicode_Negatives.Test_uXXXX_NonHex;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('s = "\u12G4"'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Unicode_Negatives.Test_UXXXXXXXX_OutOfRange;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 超过 10FFFF
  AssertFalse(Parse(RawByteString('s = "\U110000"'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Unicode_Negatives.Test_uXXXX_Surrogate_Alone_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 孤立代理项
  AssertFalse(Parse(RawByteString('s = "\uD800"'), Doc, Err));
  AssertTrue(Err.HasError);
end;

initialization
  RegisterTest(TTestCase_Unicode_Negatives);
end.

