{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_field_index_error;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_FieldIndex_Error = class(TTestCase)
  published
    procedure Test_Field_Index_Out_Of_Range_Message_Contains_Index_Count;
  end;

implementation

procedure TTestCase_Reader_FieldIndex_Error.Test_Field_Index_Out_Of_Range_Message_Contains_Index_Count;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; S: TStringList;
  Raised: Boolean; Msg: string;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  TmpFile := 'tmp_field_index.csv'; S := TStringList.Create; try
    S.Text := 'a,b'; S.SaveToFile(TmpFile);
  finally S.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    try
      Msg := Rec.Field(5); // out of range
    except
      on E: Exception do begin Raised := True; Msg := E.Message; end;
    end;
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
  AssertTrue(Raised);
  AssertTrue(Pos('index=', Msg) > 0);
  AssertTrue(Pos('count=', Msg) > 0);
end;


initialization
  RegisterTest(TTestCase_Reader_FieldIndex_Error);

end.
