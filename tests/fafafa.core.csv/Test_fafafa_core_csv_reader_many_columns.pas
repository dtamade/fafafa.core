{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_many_columns;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_ManyCols = class(TTestCase)
  published
    procedure Test_One_Row_Thousand_Columns_Strict_OK;
  end;

implementation

procedure TTestCase_Reader_ManyCols.Test_One_Row_Thousand_Columns_Strict_OK;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; I: Integer;
  S: TStringList; Line: string;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.AllowVariableFields := False;
  TmpFile := 'tmp_many_cols.csv';
  S := TStringList.Create;
  try
    Line := '';
    for I := 0 to 999 do
    begin
      if I > 0 then Line := Line + ',';
      Line := Line + 'f' + IntToStr(I);
    end;
    S.Text := Line;
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(1000, Rec.Count);
    AssertEquals('f0', Rec.Field(0));
    AssertEquals('f999', Rec.Field(999));
    AssertFalse(R.ReadNext(Rec));
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;

initialization
  RegisterTest(TTestCase_Reader_ManyCols);

end.

