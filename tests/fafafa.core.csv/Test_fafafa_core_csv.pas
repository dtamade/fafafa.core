{$CODEPAGE UTF8}
unit Test_fafafa_core_csv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv, Test_CSV_Utils;

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_DefaultRFC4180;
    procedure Test_UnixDialect;
    procedure Test_ExcelDialect;
  end;

  TTestCase_Reader = class(TTestCase)
  published
    procedure Test_Read_Basic_NoHeader;
  end;

implementation

procedure TTestCase_Global.Test_DefaultRFC4180;
var
  D: TCSVDialect;
begin
  D := DefaultRFC4180;
  AssertEquals(',', UTF8Encode(D.Delimiter)[1]);
  AssertEquals('"', UTF8Encode(D.Quote)[1]);
  AssertEquals(True, D.UseCRLF);
  AssertFalse(D.TrimSpaces);
  AssertFalse(D.AllowLazyQuotes);
  AssertFalse(D.AllowVariableFields);
end;

procedure TTestCase_Global.Test_UnixDialect;
var
  D: TCSVDialect;
begin
  D := UnixDialect;
  AssertEquals(',', UTF8Encode(D.Delimiter)[1]);
  AssertEquals(False, D.UseCRLF);
end;

procedure TTestCase_Global.Test_ExcelDialect;
var
  D: TCSVDialect;
begin
  D := ExcelDialect;
  AssertEquals(',', UTF8Encode(D.Delimiter)[1]);
  AssertEquals(True, D.UseCRLF);
end;

procedure TTestCase_Reader.Test_Read_Basic_NoHeader;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;

  TmpFile := CreateTempCSVFile('basic', 'a,b,c'#13#10'd,e,f');

  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue('Reader should be created', R <> nil);
    AssertTrue('First record', R.ReadNext(Rec));
    AssertEquals(3, Rec.Count);
    AssertEquals('a', Rec.Field(0));
    AssertEquals('b', Rec.Field(1));
    AssertEquals('c', Rec.Field(2));
    AssertTrue('Second record', R.ReadNext(Rec));
    AssertEquals('d', Rec.Field(0));
    AssertEquals('e', Rec.Field(1));
    AssertEquals('f', Rec.Field(2));
  finally
    CleanupTempFile(TmpFile);
  end;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_Reader);
end.
end.

