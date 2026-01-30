{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_datetime_negatives;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_DateTime_Negatives = class(TTestCase)
  published
    procedure Test_OffsetDateTime_Invalid_Offset_Format_Should_Fail;
    procedure Test_LocalDateTime_Invalid_Fractional_TooManyDigits_Should_Fail;
  end;

implementation

procedure TTestCase_DateTime_Negatives.Test_OffsetDateTime_Invalid_Offset_Format_Should_Fail;
var
  Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 无效偏移格式（分钟缺失冒号）
  AssertFalse(Parse(RawByteString('ts = 1979-05-27T00:32:00-0700'), Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure TTestCase_DateTime_Negatives.Test_LocalDateTime_Invalid_Fractional_TooManyDigits_Should_Fail;
var
  Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 小数秒位数过多（若实现不支持更高精度，应报错；若支持应截断但通常规范建议至毫秒）
  AssertFalse(Parse(RawByteString('ldt = 1979-05-27T00:32:00.1234567890123'), Doc, Err));
  AssertTrue(Err.HasError);
end;

initialization
  RegisterTest(TTestCase_DateTime_Negatives);
end.

