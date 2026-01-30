{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_positions_more;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_Positions_More = class(TTestCase)
  published
    procedure Test_Unterminated_Quoted_Field_Raises;
    procedure Test_Unexpected_Quote_In_Unquoted_Field_Raises;
  end;

implementation

procedure TTestCase_Reader_Positions_More.Test_Unterminated_Quoted_Field_Raises;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
  S: TStringList;
  Raised: Boolean;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;
  TmpFile := 'tmp_unterm.csv';
  S := TStringList.Create;
  try
    S.Text := '"abc';
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;

  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    try
      R.ReadNext(Rec);
    except
      on E: ECSVError do Raised := True;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue('Unterminated quoted field should raise', Raised);
end;

procedure TTestCase_Reader_Positions_More.Test_Unexpected_Quote_In_Unquoted_Field_Raises;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
  S: TStringList;
  Raised: Boolean;
begin
  D := DefaultRFC4180;
  D.HasHeader := False;
  D.AllowLazyQuotes := False;
  TmpFile := 'tmp_unexpected_quote.csv';
  S := TStringList.Create;
  try
    S.Text := 'a"b,c';
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;

  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    try
      R.ReadNext(Rec);
    except
      on E: ECSVError do Raised := True;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue('Unexpected quote in unquoted field should raise', Raised);
end;


initialization
  RegisterTest(TTestCase_Reader_Positions_More);

end.
