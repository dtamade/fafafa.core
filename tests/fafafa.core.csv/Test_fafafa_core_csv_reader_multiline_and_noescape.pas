{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_multiline_and_noescape;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_Multiline_NoEscape = class(TTestCase)
  published
    procedure Test_Quoted_Field_Spans_Multiple_Lines_CRLF_and_CR;
    procedure Test_Backslash_Not_Escape_When_Escape_Disabled;
  end;

implementation

procedure TTestCase_Reader_Multiline_NoEscape.Test_Quoted_Field_Spans_Multiple_Lines_CRLF_and_CR;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  TmpFile := 'tmp_multiline.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  // "line1\r\nline2\rline3",z
  Raw := '"line1' + #13#10 + 'line2' + #13 + 'line3",z';
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('line1' + #13#10 + 'line2' + #13 + 'line3', Rec.Field(0));
    AssertEquals('z', Rec.Field(1));
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
end;

procedure TTestCase_Reader_Multiline_NoEscape.Test_Backslash_Not_Escape_When_Escape_Disabled;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.Escape := #0; // disable escape
  TmpFile := 'tmp_noescape.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  Raw := '"a\\""b",c'; // backslash present but not escape
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    // With escape disabled, content should treat backslash literally; doubled quotes still apply
    AssertEquals('a' + '\' + '\' + '"' + 'b', Rec.Field(0));
    AssertEquals('c', Rec.Field(1));
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
end;


initialization
  RegisterTest(TTestCase_Reader_Multiline_NoEscape);

end.
