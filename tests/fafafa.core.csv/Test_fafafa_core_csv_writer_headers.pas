{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_writer_headers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Writer_Headers = class(TTestCase)
  published
    procedure Test_Write_WithHeaders_FirstLine;
  end;

implementation

procedure TTestCase_Writer_Headers.Test_Write_WithHeaders_FirstLine;
var
  D: TCSVDialect;
  W: ICSVWriter;
  OutFile: string;
  SL: TStringList;
begin
  D := DefaultRFC4180;
  OutFile := 'tmp_out_headers.csv';
  if FileExists(OutFile) then DeleteFile(OutFile);
  W := CSVWriterBuilder
        .ToFile(OutFile)
        .Dialect(D)
        .WithHeaders(['h1','h2','h3'])
        .Build;
  AssertTrue('Writer should be created', W <> nil);
  W.WriteRow(['a','b','c']);
  W.Flush;
  W.Close; // Flush no longer closes; explicitly close before reading back on Windows

  SL := TStringList.Create;
  try
    SL.LoadFromFile(OutFile);
    AssertEquals('h1,h2,h3', TrimRight(SL[0]));
    AssertEquals('a,b,c',   TrimRight(SL[1]));
  finally
    SL.Free;
    if FileExists(OutFile) then DeleteFile(OutFile);
  end;
end;


initialization
  RegisterTest(TTestCase_Writer_Headers);

end.
