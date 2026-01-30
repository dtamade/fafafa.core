{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_datetime;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_DateTime = class(TTestCase)
  published
    procedure Test_OffsetDateTime_Parse_And_Write;
    procedure Test_LocalDateTime_Parse_And_Write;
    procedure Test_LocalDate_Parse_And_Write;
    procedure Test_LocalTime_Parse_And_Write;
  end;

implementation

procedure TTestCase_DateTime.Test_OffsetDateTime_Parse_And_Write;
var
  Doc: ITomlDocument; Err: TTomlError; S: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('ts = 1979-05-27T07:32:00Z'), Doc, Err));
  AssertFalse(Err.HasError);
  S := ToToml(Doc, []);
  AssertTrue(Pos('ts = 1979-05-27T07:32:00Z', String(S)) > 0);
end;

procedure TTestCase_DateTime.Test_LocalDateTime_Parse_And_Write;
var
  Doc: ITomlDocument; Err: TTomlError; S: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('ldt = 1979-05-27T07:32:00'), Doc, Err));
  AssertFalse(Err.HasError);
  S := ToToml(Doc, []);
  AssertTrue(Pos('ldt = 1979-05-27T07:32:00', String(S)) > 0);
end;

procedure TTestCase_DateTime.Test_LocalDate_Parse_And_Write;
var
  Doc: ITomlDocument; Err: TTomlError; S: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('ld = 1979-05-27'), Doc, Err));
  AssertFalse(Err.HasError);
  S := ToToml(Doc, []);
  AssertTrue(Pos('ld = 1979-05-27', String(S)) > 0);
end;

procedure TTestCase_DateTime.Test_LocalTime_Parse_And_Write;
var
  Doc: ITomlDocument; Err: TTomlError; S: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('lt = 07:32:00'), Doc, Err));
  AssertFalse(Err.HasError);
  S := ToToml(Doc, []);
  AssertTrue(Pos('lt = 07:32:00', String(S)) > 0);
end;

initialization
  RegisterTest(TTestCase_DateTime);
end.

