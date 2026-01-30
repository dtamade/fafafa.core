{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_trim_lazy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_Trim_Lazy = class(TTestCase)
  published
    procedure Test_TrimSpaces_Unquoted_Only;
    procedure Test_LazyQuotes_Unquoted_Quotes_Accepted;
  end;

implementation

procedure TTestCase_Reader_Trim_Lazy.Test_TrimSpaces_Unquoted_Only;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
  S: TStringList;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;
  D.TrimSpaces := True;

  TmpFile := 'tmp_trim.csv';
  S := TStringList.Create;
  try
    // first field quoted -> spaces preserved; second field unquoted -> trimmed
    S.Text := '"  a  ",  b  ' + #13#10;
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;

  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('  a  ', Rec.Field(0));
    AssertEquals('b', Rec.Field(1));
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;

procedure TTestCase_Reader_Trim_Lazy.Test_LazyQuotes_Unquoted_Quotes_Accepted;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
  S: TStringList;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;
  D.AllowLazyQuotes := True;

  TmpFile := 'tmp_lazy.csv';
  S := TStringList.Create;
  try
    // unquoted field with quote inside -> as data when lazy quotes enabled
    S.Text := 'a"b,c' + #13#10;
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;

  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(2, Rec.Count);
    AssertEquals('a"b', Rec.Field(0));
    AssertEquals('c', Rec.Field(1));
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;


initialization
  RegisterTest(TTestCase_Reader_Trim_Lazy);

end.
