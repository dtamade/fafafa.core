{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_edgecases_more;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv, Test_CSV_Utils;

type
  TTestCase_Reader_Edge_More = class(TTestCase)
  published
    procedure Test_Empty_Fields_And_Trailing_Delimiter;
    procedure Test_No_Terminating_Newline_Last_Record_Read;
    procedure Test_Large_Field_Reading;
    procedure Test_Duplicate_Header_Names_TryGetByName_FirstWins;
  end;

implementation

procedure TTestCase_Reader_Edge_More.Test_Empty_Fields_And_Trailing_Delimiter;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  TmpFile := CreateTempCSVFile('empty_trailing', ',,,' + #13#10 + 'a,b,');
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(4, Rec.Count);
    AssertEquals('', Rec.Field(0)); AssertEquals('', Rec.Field(1)); AssertEquals('', Rec.Field(2)); AssertEquals('', Rec.Field(3));
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(3, Rec.Count);
    AssertEquals('a', Rec.Field(0)); AssertEquals('b', Rec.Field(1)); AssertEquals('', Rec.Field(2));
  finally CleanupTempFile(TmpFile); end;
end;

procedure TTestCase_Reader_Edge_More.Test_No_Terminating_Newline_Last_Record_Read;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  TmpFile := 'tmp_noeol.csv'; S := TStringList.Create;
  try
    S.Text := 'a,b'; // no CRLF/LF at end
    S.SaveToFile(TmpFile);
  finally S.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('a', Rec.Field(0)); AssertEquals('b', Rec.Field(1));
    // No second record
    AssertFalse(R.ReadNext(Rec));
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
end;

procedure TTestCase_Reader_Edge_More.Test_Large_Field_Reading;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList; Large: string;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  SetLength(Large, 100000); FillChar(Large[1], Length(Large), Ord('x'));
  TmpFile := 'tmp_large.csv'; S := TStringList.Create;
  try
    S.Text := Large + ',end'; S.SaveToFile(TmpFile);
  finally S.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(2, Rec.Count);
    AssertEquals(Large, Rec.Field(0)); AssertEquals('end', Rec.Field(1));
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
end;

procedure TTestCase_Reader_Edge_More.Test_Duplicate_Header_Names_TryGetByName_FirstWins;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList; V: string; Ok: Boolean;
begin
  D := DefaultRFC4180; D.HasHeader := True;
  TmpFile := 'tmp_dup_header.csv'; S := TStringList.Create;
  try
    S.Text := 'h1,h1,h2' + #13#10 + 'a,b,c'; S.SaveToFile(TmpFile);
  finally S.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    Ok := Rec.TryGetByName('h1', V); AssertTrue(Ok); AssertEquals('a', V); // first wins
    Ok := Rec.TryGetByName('H2', V); AssertTrue(Ok); AssertEquals('c', V);
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
end;


initialization
  RegisterTest(TTestCase_Reader_Edge_More);

end.
