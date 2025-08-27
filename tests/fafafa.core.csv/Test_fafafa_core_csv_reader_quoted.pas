{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_quoted;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv, Test_CSV_Utils;

type
  TTestCase_Reader_Quoted = class(TTestCase)
  published
    procedure Test_Quoted_With_Comma_And_DoubleQuote;
    procedure Test_Quoted_With_Embedded_Newline;
  end;

implementation

procedure TTestCase_Reader_Quoted.Test_Quoted_With_Comma_And_DoubleQuote;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;

  // fields: "a,b", "c""d" (both fields properly quoted according to RFC4180)
  TmpFile := CreateTempCSVFile('quoted', '"a,b","c""d"' + #13#10 + 'x,y');

  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(2, Rec.Count);
    AssertEquals('a,b', Rec.Field(0));
    AssertEquals('c"d', Rec.Field(1));
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('x', Rec.Field(0));
    AssertEquals('y', Rec.Field(1));
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_Reader_Quoted.Test_Quoted_With_Embedded_Newline;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;

  // first field has embedded newline inside quotes
  TmpFile := CreateTempCSVFile('quoted_nl', '"line1' + #10 + 'line2",z' + #13#10 + 'p,q');

  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(2, Rec.Count);
    AssertEquals('line1' + #10 + 'line2', Rec.Field(0));
    AssertEquals('z', Rec.Field(1));
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('p', Rec.Field(0));
    AssertEquals('q', Rec.Field(1));
  finally
    CleanupTempFile(TmpFile);
  end;
end;


initialization
  RegisterTest(TTestCase_Reader_Quoted);

end.
