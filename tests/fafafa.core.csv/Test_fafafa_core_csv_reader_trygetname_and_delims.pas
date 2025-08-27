{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_trygetname_and_delims;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_TryGet_And_Delims = class(TTestCase)
  published
    procedure Test_TryGetByName_Missing_Returns_False_CaseInsensitive;
    procedure Test_Custom_Semicolon_Delimiter;
    procedure Test_Custom_Tab_Delimiter;
  end;

implementation

procedure TTestCase_Reader_TryGet_And_Delims.Test_TryGetByName_Missing_Returns_False_CaseInsensitive;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList; V: string; Ok: Boolean;
begin
  D := DefaultRFC4180; D.HasHeader := True;
  TmpFile := 'tmp_tryget.csv'; S := TStringList.Create;
  try
    S.Text := 'Name,Age' + #13#10 + 'Alice,30';
    S.SaveToFile(TmpFile);
  finally S.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    Ok := Rec.TryGetByName('name', V);  AssertTrue(Ok);   AssertEquals('Alice', V);
    Ok := Rec.TryGetByName('AGE', V);   AssertTrue(Ok);   AssertEquals('30', V);
    Ok := Rec.TryGetByName('City', V);  AssertFalse(Ok);
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;

procedure TTestCase_Reader_TryGet_And_Delims.Test_Custom_Semicolon_Delimiter;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.Delimiter := ';';
  TmpFile := 'tmp_sc.csv'; S := TStringList.Create;
  try
    S.Text := 'a;b;c'; S.SaveToFile(TmpFile);
  finally S.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('a', Rec.Field(0)); AssertEquals('b', Rec.Field(1)); AssertEquals('c', Rec.Field(2));
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
end;

procedure TTestCase_Reader_TryGet_And_Delims.Test_Custom_Tab_Delimiter;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.Delimiter := #9;
  TmpFile := 'tmp_tab.csv'; S := TStringList.Create;
  try
    S.Text := 'a'#9'b'#9'c'; S.SaveToFile(TmpFile);
  finally S.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('a', Rec.Field(0)); AssertEquals('b', Rec.Field(1)); AssertEquals('c', Rec.Field(2));
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
end;


initialization
  RegisterTest(TTestCase_Reader_TryGet_And_Delims);

end.
