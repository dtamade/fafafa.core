{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_mixed_newlines;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_MixedNewlines = class(TTestCase)
  published
    procedure Test_Mixed_CRLF_LF_CR_Reads_All_Records;
    procedure Test_Unexpected_Quote_Error_On_Line2_RecordStart;
  end;

implementation

procedure TTestCase_Reader_MixedNewlines.Test_Mixed_CRLF_LF_CR_Reads_All_Records;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream; Raw: RawByteString;
  Count: Integer;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  TmpFile := 'tmp_mixed_newlines.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  // a,b\r\nc,d\n e,f\r g,h
  Raw := 'a,b' + #13#10 + 'c,d' + #10 + 'e,f' + #13 + 'g,h';
  FS := TFileStream.Create(TmpFile, fmCreate);
  try
    FS.WriteBuffer(Pointer(Raw)^, Length(Raw));
  finally FS.Free; end;

  Count := 0;
  try
    R := OpenCSVReader(TmpFile, D);
    while R.ReadNext(Rec) do Inc(Count);
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertEquals(4, Count);
end;

procedure TTestCase_Reader_MixedNewlines.Test_Unexpected_Quote_Error_On_Line2_RecordStart;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream; Raw: RawByteString;
  GotLine, GotCol: Integer; Raised: Boolean;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.AllowLazyQuotes := False;
  TmpFile := 'tmp_unexpected_quote_line2.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  // line1 ok; line2 contains unexpected quote inside unquoted field
  Raw := 'a,b' + #13#10 + 'c,d"e' + #10 + 'x,y';
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;

  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec)); // line1
    try
      R.ReadNext(Rec); // should raise on line2
    except on E: ECSVError do begin Raised := True; GotLine := E.Line; GotCol := E.Column; end; end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue(Raised);
  AssertEquals(2, GotLine);
  AssertEquals(1, GotCol);
end;


initialization
  RegisterTest(TTestCase_Reader_MixedNewlines);

end.
