{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_reader_errors_consistency_2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Reader_Errors_Consistency_2 = class(TTestCase)
  published
    procedure Test_Invalid_Table_Header_Segment_Should_Set_Error_With_Prefix;
    procedure Test_Invalid_Array_Boolean_Should_Set_Error_With_Prefix;
  end;

implementation

procedure TTestCase_Reader_Errors_Consistency_2.Test_Invalid_Table_Header_Segment_Should_Set_Error_With_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 空段：[] 或 [a..b]
  AssertFalse(Parse(RawByteString('[a..b]'), Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(tecInvalidToml), Ord(Err.Code));
end;

procedure TTestCase_Reader_Errors_Consistency_2.Test_Invalid_Array_Boolean_Should_Set_Error_With_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 非法布尔值（数组内）
  AssertFalse(Parse(RawByteString('k = [true, Truth]'), Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(tecInvalidToml), Ord(Err.Code));
end;

initialization
  RegisterTest(TTestCase_Reader_Errors_Consistency_2);
end.

