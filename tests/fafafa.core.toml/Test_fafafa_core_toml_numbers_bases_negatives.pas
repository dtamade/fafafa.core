{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_numbers_bases_negatives;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Numbers_Bases_Negatives = class(TTestCase)
  published
    procedure Test_Hex_Invalid_Underscores_Should_Fail;
    procedure Test_Octal_Invalid_Underscores_Should_Fail;
    procedure Test_Binary_Invalid_Underscores_Should_Fail;
  end;

implementation

procedure TTestCase_Numbers_Bases_Negatives.Test_Hex_Invalid_Underscores_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 前缀后直接下划线、尾随下划线、连续下划线
  AssertFalse(Parse(RawByteString('n = 0x_1'), Doc, Err));
  AssertFalse(Parse(RawByteString('n = 0x1_'), Doc, Err));
  AssertFalse(Parse(RawByteString('n = 0x1__2'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Bases_Negatives.Test_Octal_Invalid_Underscores_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('n = 0o_7'), Doc, Err));
  AssertFalse(Parse(RawByteString('n = 0o7_'), Doc, Err));
  AssertFalse(Parse(RawByteString('n = 0o7__1'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Numbers_Bases_Negatives.Test_Binary_Invalid_Underscores_Should_Fail;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('n = 0b_1'), Doc, Err));
  AssertFalse(Parse(RawByteString('n = 0b1_'), Doc, Err));
  AssertFalse(Parse(RawByteString('n = 0b1__0'), Doc, Err));
  AssertTrue(Err.HasError);
end;

initialization
  RegisterTest(TTestCase_Numbers_Bases_Negatives);
end.

