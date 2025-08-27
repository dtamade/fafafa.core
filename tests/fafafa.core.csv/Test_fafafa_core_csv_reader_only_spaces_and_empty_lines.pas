{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_only_spaces_and_empty_lines;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_Spaces_Empty = class(TTestCase)
  published
    procedure Test_Empty_Line_And_Only_Spaces_Line_Preserved_When_NoTrim;
    procedure Test_Only_Spaces_Line_Trimmed_When_TrimSpaces;
  end;

implementation

procedure TTestCase_Reader_Spaces_Empty.Test_Empty_Line_And_Only_Spaces_Line_Preserved_When_NoTrim;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList;
begin
  D := DefaultRFC4180; D.TrimSpaces := False; D.HasHeader := False;
  TmpFile := 'tmp_only_spaces.csv';
  S := TStringList.Create;
  try
    // empty line, then fields with spaces only (unquoted)
    S.Text := '' + #13#10 + '  ,   ,    ';
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;
  try
    R := OpenCSVReader(TmpFile, D);
    // first record: empty line -> 1 empty field
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(1, Rec.Count);
    AssertEquals('', Rec.Field(0));
    // second record: spaces-only fields preserved
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(3, Rec.Count);
    AssertEquals('  ', Rec.Field(0));
    AssertEquals('   ', Rec.Field(1));
    AssertEquals('    ', Rec.Field(2));
    // no more
    AssertFalse(R.ReadNext(Rec));
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;

procedure TTestCase_Reader_Spaces_Empty.Test_Only_Spaces_Line_Trimmed_When_TrimSpaces;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList;
begin
  D := DefaultRFC4180; D.TrimSpaces := True; D.HasHeader := False;
  TmpFile := 'tmp_only_spaces_trim.csv';
  S := TStringList.Create;
  try
    S.Text := '  ,   ,    ';
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(3, Rec.Count);
    AssertEquals('', Rec.Field(0));
    AssertEquals('', Rec.Field(1));
    AssertEquals('', Rec.Field(2));
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_Spaces_Empty);

end.

