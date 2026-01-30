{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_multiline_edgecases;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_Multiline_Edge = class(TTestCase)
  published
    procedure Test_Quoted_Field_Spans_CRLF_and_LF_Mixed;
    procedure Test_Unterminated_Quoted_Field_On_Line2_Column1;
  end;

implementation

procedure TTestCase_Reader_Multiline_Edge.Test_Quoted_Field_Spans_CRLF_and_LF_Mixed;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  TmpFile := 'tmp_multiline_mixed.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  // "a\r\nb\n c",z\n x,y
  Raw := '"a' + #13#10 + 'b' + #10 + ' c",z' + #10 + 'x,y';
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('a' + #13#10 + 'b' + #10 + ' c', Rec.Field(0));
    AssertEquals('z', Rec.Field(1));
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('x', Rec.Field(0));
    AssertEquals('y', Rec.Field(1));
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
end;

procedure TTestCase_Reader_Multiline_Edge.Test_Unterminated_Quoted_Field_On_Line2_Column1;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream; Raw: RawByteString;
  Raised: Boolean; GotLine, GotCol: Integer;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  TmpFile := 'tmp_unterm_line2.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  // line1 ok; line2 starts quote, no closing until EOF
  Raw := 'ok1,ok2' + #13#10 + '"start' + #10 + 'mid';
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;

  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec)); // line1
    try
      R.ReadNext(Rec);
    except on E: ECSVError do begin Raised := True; GotLine := E.Line; GotCol := E.Column; end; end;
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
  AssertTrue(Raised);
  AssertEquals(2, GotLine);
  AssertEquals(1, GotCol);
end;


initialization
  RegisterTest(TTestCase_Reader_Multiline_Edge);

end.
