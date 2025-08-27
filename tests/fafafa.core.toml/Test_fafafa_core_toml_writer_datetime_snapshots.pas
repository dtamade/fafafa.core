{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_datetime_snapshots;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_DateTime_Snapshots = class(TTestCase)
  published
    procedure Test_Writer_OffsetDateTime_RFC3339;
    procedure Test_Writer_LocalDateTime_RFC3339;
    procedure Test_Writer_LocalDate_RFC3339;
    procedure Test_Writer_LocalTime_RFC3339;
  end;

implementation

procedure TTestCase_Writer_DateTime_Snapshots.Test_Writer_OffsetDateTime_RFC3339;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('ts = 1979-05-27T07:32:00Z'), Doc, Err));
  AssertFalse(Err.HasError);
  S := String(ToToml(Doc, []));
  AssertTrue(Pos('ts = 1979-05-27T07:32:00Z', S) > 0);
end;

procedure TTestCase_Writer_DateTime_Snapshots.Test_Writer_LocalDateTime_RFC3339;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('ldt = 1979-05-27T07:32:00'), Doc, Err));
  AssertFalse(Err.HasError);
  S := String(ToToml(Doc, []));
  AssertTrue(Pos('ldt = 1979-05-27T07:32:00', S) > 0);
end;

procedure TTestCase_Writer_DateTime_Snapshots.Test_Writer_LocalDate_RFC3339;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('ld = 1979-05-27'), Doc, Err));
  AssertFalse(Err.HasError);
  S := String(ToToml(Doc, []));
  AssertTrue(Pos('ld = 1979-05-27', S) > 0);
end;

procedure TTestCase_Writer_DateTime_Snapshots.Test_Writer_LocalTime_RFC3339;
var
  Doc: ITomlDocument; Err: TTomlError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('lt = 07:32:00'), Doc, Err));
  AssertFalse(Err.HasError);
  S := String(ToToml(Doc, []));
  AssertTrue(Pos('lt = 07:32:00', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_DateTime_Snapshots);
end.

