{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_writer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Writer = class(TTestCase)
  published
    procedure Test_Write_Basic;
  end;

implementation

procedure TTestCase_Writer.Test_Write_Basic;
var
  D: TCSVDialect;
  W: ICSVWriter;
  OutFile: string;
  SL: TStringList;
begin
  D := DefaultRFC4180;
  OutFile := 'tmp_out.csv';
  if FileExists(OutFile) then DeleteFile(OutFile);
  W := OpenCSVWriter(OutFile, D);
  AssertTrue('Writer should be created', W <> nil);
  W.WriteRow(['a','b','c']);
  W.WriteRow(['d','e','f']);
  W.Flush;
  W.Close; // release file handle before reading

  SL := TStringList.Create;
  try
    SL.LoadFromFile(OutFile);
    AssertEquals('a,b,c', TrimRight(SL[0]));
    AssertEquals('d,e,f', TrimRight(SL[1]));
  finally
    SL.Free;
    if FileExists(OutFile) then DeleteFile(OutFile);
  end;
end;


initialization
  RegisterTest(TTestCase_Writer);

end.
