{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_strict;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_Strict = class(TTestCase)
  published
    procedure Test_FieldCount_Mismatch_Should_Raise;
  end;

implementation

procedure TTestCase_Reader_Strict.Test_FieldCount_Mismatch_Should_Raise;
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
  D.AllowVariableFields := False; // strict

  TmpFile := 'tmp_mismatch.csv';
  S := TStringList.Create;
  try
    S.Text := 'a,b,c'#13#10'd,e';
    S.SaveToFile(TmpFile);
  finally
    S.Free;
  end;

  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    try
      // second read triggers mismatch (3 vs 2)
      R.ReadNext(Rec);
    except
      on E: ECSVError do
        Raised := True;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue('Should raise ECSVError on field count mismatch in strict mode', Raised);
end;


initialization
  RegisterTest(TTestCase_Reader_Strict);

end.
