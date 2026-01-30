{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_unicode_keys_negatives;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Unicode_Keys_Negatives = class(TTestCase)
  published
    procedure Test_Quoted_Key_Invalid_u_Short;
    procedure Test_Table_Header_Invalid_U_OutOfRange;
  end;

implementation

procedure TTestCase_Unicode_Keys_Negatives.Test_Quoted_Key_Invalid_u_Short;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('"a\u12" = 1'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_Unicode_Keys_Negatives.Test_Table_Header_Invalid_U_OutOfRange;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('["\U110000" ]'), Doc, Err));
  AssertTrue(Err.HasError);
end;

initialization
  RegisterTest(TTestCase_Unicode_Keys_Negatives);
end.

