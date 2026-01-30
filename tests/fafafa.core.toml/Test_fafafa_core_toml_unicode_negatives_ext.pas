{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_unicode_negatives_ext;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Unicode_Negatives_Ext = class(TTestCase)
  published
    procedure Test_uXXXX_OutOfRange_Should_Fail;
    procedure Test_UXXXXXXXX_Above_10FFFF_Should_Fail;
  end;

implementation

procedure TTestCase_Unicode_Negatives_Ext.Test_uXXXX_OutOfRange_Should_Fail;
var
  Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // surrogate 范围（非法）：D800
  AssertFalse(Parse(RawByteString('k = "\uD800"'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Unicode_Negatives_Ext.Test_UXXXXXXXX_Above_10FFFF_Should_Fail;
var
  Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 超上界：110000
  AssertFalse(Parse(RawByteString('k = "\U00110000"'), Doc, Err));
  AssertTrue(Err.HasError);
end;

initialization
  RegisterTest(TTestCase_Unicode_Negatives_Ext);
end.

