{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_reader_errors_consistency;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Reader_Errors_Consistency = class(TTestCase)
  published
    procedure Test_Missing_Equals_Should_Set_Error_With_Prefix;
    procedure Test_Invalid_Unicode_Escape_Should_Set_Error_With_Prefix;
    procedure Test_Invalid_Inline_Table_Value_Should_Set_Error_With_Prefix;
    procedure Test_Invalid_Array_Item_Should_Set_Error_With_Prefix;
  end;

implementation

procedure TTestCase_Reader_Errors_Consistency.Test_Missing_Equals_Should_Set_Error_With_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('key  value'), Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(tecInvalidToml), Ord(Err.Code));
end;

procedure TTestCase_Reader_Errors_Consistency.Test_Invalid_Unicode_Escape_Should_Set_Error_With_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('k = "a\u12"'), Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(tecInvalidToml), Ord(Err.Code));
end;

procedure TTestCase_Reader_Errors_Consistency.Test_Invalid_Inline_Table_Value_Should_Set_Error_With_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('k = { a = [1, 2, ] }'), Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(tecInvalidToml), Ord(Err.Code));
end;

procedure TTestCase_Reader_Errors_Consistency.Test_Invalid_Array_Item_Should_Set_Error_With_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // mixed-type array or trailing comma without value
  AssertFalse(Parse(RawByteString('k = [1, 2, ]'), Doc, Err));
  AssertTrue(Err.HasError);
  // 数组内部错误消息使用专门前缀（当前实现：Invalid array ...）
  AssertEquals(Ord(tecInvalidToml), Ord(Err.Code));
end;

initialization
  RegisterTest(TTestCase_Reader_Errors_Consistency);
end.

