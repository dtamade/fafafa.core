{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_positions_asserts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_Positions_Asserts = class(TTestCase)
  published
    procedure Test_FieldCount_Mismatch_Position_Is_RecordStart;
    procedure Test_Unterminated_Quoted_Field_Position_Is_RecordStart;
    procedure Test_Unexpected_Quote_Position_Is_RecordStart;
    procedure Test_Header_Strict_Mismatch_Position_Is_ThirdLine_Start;
  end;

implementation

procedure TTestCase_Reader_Positions_Asserts.Test_FieldCount_Mismatch_Position_Is_RecordStart;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList;
  GotLine, GotCol: Integer; Raised: Boolean;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.AllowVariableFields := False;
  TmpFile := 'tmp_pos_mismatch.csv';
  S := TStringList.Create; try
    S.Text := 'a,b,c' + #13#10 + 'x,y';
    S.SaveToFile(TmpFile);
  finally S.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    try
      R.ReadNext(Rec);
    except
      on E: ECSVError do begin Raised := True; GotLine := E.Line; GotCol := E.Column; end;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue(Raised);
  AssertEquals(2, GotLine);
  AssertEquals(1, GotCol);
end;

procedure TTestCase_Reader_Positions_Asserts.Test_Unterminated_Quoted_Field_Position_Is_RecordStart;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList;
  GotLine, GotCol: Integer; Raised: Boolean;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  TmpFile := 'tmp_pos_unterm.csv';
  S := TStringList.Create; try
    S.Text := '"abc';
    S.SaveToFile(TmpFile);
  finally S.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    try
      R.ReadNext(Rec);
    except on E: ECSVError do begin Raised := True; GotLine := E.Line; GotCol := E.Column; end; end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue(Raised);
  AssertEquals(1, GotLine);
  AssertEquals(1, GotCol);
end;

procedure TTestCase_Reader_Positions_Asserts.Test_Unexpected_Quote_Position_Is_RecordStart;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList;
  GotLine, GotCol: Integer; Raised: Boolean;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.AllowLazyQuotes := False;
  TmpFile := 'tmp_pos_unexpected.csv';
  S := TStringList.Create; try
    S.Text := 'a"b,c';
    S.SaveToFile(TmpFile);
  finally S.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    try
      R.ReadNext(Rec);
    except on E: ECSVError do begin Raised := True; GotLine := E.Line; GotCol := E.Column; end; end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue(Raised);
  AssertEquals(1, GotLine);
  AssertEquals(1, GotCol);
end;

procedure TTestCase_Reader_Positions_Asserts.Test_Header_Strict_Mismatch_Position_Is_ThirdLine_Start;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList;
  GotLine, GotCol: Integer; Raised: Boolean;
begin
  D := DefaultRFC4180; D.HasHeader := True; D.AllowVariableFields := False;
  TmpFile := 'tmp_pos_header_strict.csv';
  S := TStringList.Create; try
    S.Text := 'h1,h2,h3' + #13#10 + 'a,b,c' + #13#10 + 'x,y';
    S.SaveToFile(TmpFile);
  finally S.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec)); // first data row
    try
      R.ReadNext(Rec); // mismatch row 3
    except on E: ECSVError do begin Raised := True; GotLine := E.Line; GotCol := E.Column; end; end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue(Raised);
  AssertEquals(3, GotLine);
  AssertEquals(1, GotCol);
end;


initialization
  RegisterTest(TTestCase_Reader_Positions_Asserts);

end.
