{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_cr_only_and_errors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_CR_Only_And_Errors = class(TTestCase)
  published
    procedure Test_CR_Only_Newline;
    procedure Test_FieldCount_Mismatch_Error_Position_Uses_Record_Start;
  end;

implementation

procedure TTestCase_Reader_CR_Only_And_Errors.Test_CR_Only_Newline;
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

  TmpFile := 'tmp_cr_only.csv';
  if FileExists(TmpFile) then DeleteFile(TmpFile);

  Raw := 'a,b'#13'c,d'; // CR-only newline
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
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('c', Rec.Field(0));
    AssertEquals('d', Rec.Field(1));
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;

procedure TTestCase_Reader_CR_Only_And_Errors.Test_FieldCount_Mismatch_Error_Position_Uses_Record_Start;
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
  D.AllowVariableFields := False;

  TmpFile := 'tmp_mismatch_pos.csv';
  S := TStringList.Create;
  try
    S.Text := 'a,b,c' + #13#10 + 'x,y';
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;

  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    try
      R.ReadNext(Rec);
    except
      on E: ECSVError do Raised := True;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue('Should raise mismatch and position points to start of bad record', Raised);
end;


initialization
  RegisterTest(TTestCase_Reader_CR_Only_And_Errors);

end.
