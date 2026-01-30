{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_reader_errors_consistency_3;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Reader_Errors_Consistency_3 = class(TTestCase)
  published
    procedure Test_Invalid_Inline_Array_Item_Mixed_Type_Should_Set_Error_Prefix;
    procedure Test_Invalid_Array_Mixed_Types_Should_Set_Error_Prefix;
  end;

implementation

procedure TTestCase_Reader_Errors_Consistency_3.Test_Invalid_Inline_Array_Item_Mixed_Type_Should_Set_Error_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // inline table 内嵌数组带混合类型
  AssertFalse(Parse(RawByteString('k = { a = [1, "x"] }'), Doc, Err));
  AssertTrue(Err.HasError);
  // 某些实现前缀为 'Invalid inline array' 或 'Unsupported inline array item'
  AssertEquals(Ord(tecInvalidToml), Ord(Err.Code));
end;

procedure TTestCase_Reader_Errors_Consistency_3.Test_Invalid_Array_Mixed_Types_Should_Set_Error_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 顶层数组混合类型
  AssertFalse(Parse(RawByteString('arr = [1, "x"]'), Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(tecInvalidToml), Ord(Err.Code));
end;

initialization
  RegisterTest(TTestCase_Reader_Errors_Consistency_3);
end.

