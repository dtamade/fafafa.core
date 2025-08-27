{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_headers_strict;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_Headers_Strict = class(TTestCase)
  published
    procedure Test_Strict_FieldCount_Uses_First_Data_Row_When_Header;
    procedure Test_TryGetByName_With_Header;
  end;

implementation

procedure TTestCase_Reader_Headers_Strict.Test_Strict_FieldCount_Uses_First_Data_Row_When_Header;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
  S: TStringList;
  Raised: Boolean;
begin
  D := DefaultRFC4180;
  D.HasHeader := True;
  D.AllowVariableFields := False;

  TmpFile := 'tmp_header_strict.csv';
  S := TStringList.Create;
  try
    S.Text := 'h1,h2,h3' + #13#10 + 'a,b,c' + #13#10 + 'x,y'; // last row has 2 fields
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;

  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec)); // first data row OK -> 3 fields baseline
    try
      R.ReadNext(Rec); // second data row mismatch -> should raise
    except
      on E: ECSVError do Raised := True;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue('Should raise mismatch vs first data row field count', Raised);
end;

procedure TTestCase_Reader_Headers_Strict.Test_TryGetByName_With_Header;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  TmpFile: string;
  S: TStringList;
  V: string;
begin
  D := DefaultRFC4180;
  D.HasHeader := True;

  TmpFile := 'tmp_header_getname.csv';
  S := TStringList.Create;
  try
    S.Text := 'h1,h2' + #13#10 + 'a,b';
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;

  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertTrue(Rec.TryGetByName('h1', V));
    AssertEquals('a', V);
    AssertTrue(Rec.TryGetByName('h2', V));
    AssertEquals('b', V);
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;


initialization
  RegisterTest(TTestCase_Reader_Headers_Strict);

end.
