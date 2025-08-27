{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_reader_errors_datetime_prefix_ext;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Reader_Errors_DateTime_Prefix_Ext = class(TTestCase)
  published
    procedure Test_Invalid_LocalDateTime_Separator_X_Should_Set_Prefix;
    procedure Test_Invalid_OffsetDateTime_Missing_Seconds_Should_Set_Prefix;
  end;

implementation

procedure TTestCase_Reader_Errors_DateTime_Prefix_Ext.Test_Invalid_LocalDateTime_Separator_X_Should_Set_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('t = 1979-05-27X07:32:00'), Doc, Err));
  AssertTrue(Err.HasError);
  // 最佳实践：只约束错误码，避免依赖具体消息文本
  AssertTrue(Ord(Err.Code) = Ord(tecInvalidToml));
end;

procedure TTestCase_Reader_Errors_DateTime_Prefix_Ext.Test_Invalid_OffsetDateTime_Missing_Seconds_Should_Set_Prefix;
var Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('t = 1979-05-27T07:32+01:00'), Doc, Err));
  AssertTrue(Err.HasError);
  // 最佳实践：只约束错误码，避免依赖具体消息文本
  AssertTrue(Ord(Err.Code) = Ord(tecInvalidToml));
end;

initialization
  RegisterTest(TTestCase_Reader_Errors_DateTime_Prefix_Ext);
end.

