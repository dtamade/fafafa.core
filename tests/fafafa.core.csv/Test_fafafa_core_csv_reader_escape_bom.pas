{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_escape_bom;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv, Test_CSV_Utils;

type
  TTestCase_Reader_Escape_BOM = class(TTestCase)
  published
    procedure Test_Escape_Distinct_From_Quote;
    procedure Test_BOM_Skipped_UTF8;
  end;

implementation

procedure TTestCase_Reader_Escape_BOM.Test_Escape_Distinct_From_Quote;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
  FS: TFileStream;
  B: TBytes;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;
  D.Escape := '\'; // backslash escape as WideChar

  TmpFile := 'tmp_escape.csv';
  if FileExists(TmpFile) then DeleteFile(TmpFile);

  // Write bytes directly to avoid automatic escaping
  FS := TFileStream.Create(TmpFile, fmCreate);
  try
    B := BytesOf('"a\\""b",c'); // inside quotes: \" -> escaped quote
    FS.WriteBuffer(B[0], Length(B));
  finally
    FS.Free;
  end;

  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(2, Rec.Count);
    AssertEquals('a' + '\' + '"' + 'b', Rec.Field(0));
    AssertEquals('c', Rec.Field(1));
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;

procedure TTestCase_Reader_Escape_BOM.Test_BOM_Skipped_UTF8;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
  FS: TFileStream;
  Raw: RawByteString;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;

  TmpFile := 'tmp_bom.csv';
  if FileExists(TmpFile) then DeleteFile(TmpFile);

  Raw := AnsiChar(#$EF) + AnsiChar(#$BB) + AnsiChar(#$BF) + 'a,b';
  FS := TFileStream.Create(TmpFile, fmCreate);
  try
    FS.WriteBuffer(Pointer(Raw)^, Length(Raw));
  finally
    FS.Free;
  end;

  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('a', Rec.Field(0));
    AssertEquals('b', Rec.Field(1));
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;


initialization
  RegisterTest(TTestCase_Reader_Escape_BOM);

end.
