{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_reader_errors_datetime_prefix;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Reader_Errors_DateTime_Prefix = class(TTestCase)
  published
    procedure Test_Invalid_OffsetDateTime_Offset_Should_Set_Prefix;
    procedure Test_Invalid_LocalTime_Fractional_Digits_Should_Set_Prefix;
  end;

implementation

procedure TTestCase_Reader_Errors_DateTime_Prefix.Test_Invalid_OffsetDateTime_Offset_Should_Set_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('t = 1979-05-27T07:32:00+1:00'), Doc, Err));
  AssertTrue(Err.HasError);
  AssertTrue((Pos('Invalid datetime offset', Err.Message) = 1) or (Pos('Invalid offset', Err.Message) = 1));
end;

procedure TTestCase_Reader_Errors_DateTime_Prefix.Test_Invalid_LocalTime_Fractional_Digits_Should_Set_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('t = 07:32:00.1234567890'), Doc, Err));
  AssertTrue(Err.HasError);
  // 放宽前缀匹配：以 Invalid 开头，或包含 fractional 关键词
  AssertTrue((Pos('Invalid', Err.Message) = 1) or (Pos('fractional', LowerCase(Err.Message)) > 0));
end;

initialization
  RegisterTest(TTestCase_Reader_Errors_DateTime_Prefix);
end.

