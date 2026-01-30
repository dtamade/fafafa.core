{$CODEPAGE UTF8}
// NOTE: Flush no longer closes the stream; tests that read back from a file after Flush must call Close explicitly.

unit Test_fafafa_core_csv_writer_behaviors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Writer_Behaviors = class(TTestCase)
  published
    procedure Test_Writer_Quotes_Fields_With_Delimiter_Newline_Spaces;
    procedure Test_Writer_UseCRLF_and_UnixDialect_Newline;
    procedure Test_Writer_Header_Writes_Once_With_Mixed_Calls;
    procedure Test_Writer_DoubleQuote_Escape_Precise;
    procedure Test_Writer_Custom_Delimiters_Precise;
    procedure Test_Writer_QuoteMode_None_Raises_On_Specials;
    procedure Test_Writer_QuoteMode_None_Raises_On_TrailingSpace;
    procedure Test_Writer_QuoteMode_None_Raises_On_Leading_Comment_Char;
  end;

implementation

procedure TTestCase_Writer_Behaviors.Test_Writer_Quotes_Fields_With_Delimiter_Newline_Spaces;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; FS: TFileStream; Raw: RawByteString; Expected: RawByteString;
begin
  try
    D := DefaultRFC4180;
    OutFile := 'tmp_writer_quote.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
    W := OpenCSVWriter(OutFile, D);
    W.WriteRow(['a, b','c'#10'd',' e ']);
    W.Flush;
    W.Close; // release file handle before reading
    // 期望：整行内容为 "a, b","c\nd"," e " 后跟 CRLF
    Expected := '"a, b","c' + #10 + 'd"," e "' + #13#10;
    FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Raw, FS.Size);
      if FS.Size > 0 then FS.ReadBuffer(Pointer(Raw)^, Length(Raw));
    finally
      FS.Free;
    end;
    AssertEquals(Length(Expected), Length(Raw));
    AssertTrue(Raw = Expected);
  finally
    if FileExists(OutFile) then DeleteFile(OutFile);
  end;
end;

procedure TTestCase_Writer_Behaviors.Test_Writer_UseCRLF_and_UnixDialect_Newline;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; Raw: RawByteString; FS: TFileStream;
begin
  try
    // RFC4180: CRLF
    D := DefaultRFC4180; OutFile := 'tmp_writer_crlf.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
    W := OpenCSVWriter(OutFile, D); W.WriteRow(['a']); W.Flush; W.Close;
    FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
    try SetLength(Raw, FS.Size); if FS.Size>0 then FS.ReadBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
    AssertTrue(Pos(#13#10, Raw) > 0);
    // Unix
    D := UnixDialect; OutFile := 'tmp_writer_lf.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
    W := OpenCSVWriter(OutFile, D); W.WriteRow(['a']); W.Flush; W.Close;
    FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
    try SetLength(Raw, FS.Size); if FS.Size>0 then FS.ReadBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
    AssertTrue(Pos(#10, Raw) > 0);
  except
    on E: Exception do begin WriteLn('ERROR in Test_Writer_UseCRLF_and_UnixDialect_Newline: ', E.ClassName, ': ', E.Message); raise; end;
  end;
end;

procedure TTestCase_Writer_Behaviors.Test_Writer_Header_Writes_Once_With_Mixed_Calls;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; SL: TStringList;
begin
  D := DefaultRFC4180; OutFile := 'tmp_writer_header_once.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
  W := CSVWriterBuilder.ToFile(OutFile).Dialect(D).WithHeaders(['h1','h2']).Build;
  W.WriteRow(['a','b']);
  W.WriteAll([['x','y']]);
  W.Flush; W.Close;
  SL := TStringList.Create; try
    SL.LoadFromFile(OutFile);
    AssertEquals('h1,h2', TrimRight(SL[0]));
    AssertEquals('a,b',   TrimRight(SL[1]));
    AssertEquals('x,y',   TrimRight(SL[2]));
  finally SL.Free; if FileExists(OutFile) then DeleteFile(OutFile); end;
end;

procedure TTestCase_Writer_Behaviors.Test_Writer_DoubleQuote_Escape_Precise;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; FS: TFileStream; Raw, Expected: RawByteString;
begin
  try
    D := DefaultRFC4180; OutFile := 'tmp_writer_escape.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
    W := OpenCSVWriter(OutFile, D);
    W.WriteRow(['a"b','c']);
    W.Flush; W.Close;
    Expected := '"a""b",c' + #13#10;
    FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
    try SetLength(Raw, FS.Size); if FS.Size>0 then FS.ReadBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
    AssertTrue(Raw = Expected);
  finally
    if FileExists(OutFile) then DeleteFile(OutFile);
  end;
end;

procedure TTestCase_Writer_Behaviors.Test_Writer_Custom_Delimiters_Precise;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; FS: TFileStream; Raw, Expected: RawByteString;
begin
  try
    // semicolon
    D := DefaultRFC4180; D.Delimiter := ';'; OutFile := 'tmp_writer_sc.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
    W := OpenCSVWriter(OutFile, D); W.WriteRow(['a;b','c']); W.Flush; W.Close;
    Expected := '"a;b";c' + #13#10;
    FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
    try SetLength(Raw, FS.Size); if FS.Size>0 then FS.ReadBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
    AssertTrue(Raw = Expected);
    if FileExists(OutFile) then DeleteFile(OutFile);
    // tab
    D := DefaultRFC4180; D.Delimiter := #9; OutFile := 'tmp_writer_tab.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
    W := OpenCSVWriter(OutFile, D); W.WriteRow(['a'#9'b','c']); W.Flush; W.Close;
    Expected := '"a'#9'b"'#9'c' + #13#10;
    FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
    try SetLength(Raw, FS.Size); if FS.Size>0 then FS.ReadBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
    AssertTrue(Raw = Expected);
  finally
    if FileExists(OutFile) then DeleteFile(OutFile);
  end;
end;

procedure TTestCase_Writer_Behaviors.Test_Writer_QuoteMode_None_Raises_On_Specials;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; Raised: Boolean;
begin
  D := DefaultRFC4180; D.QuoteMode := csvQuoteNone;
  OutFile := 'tmp_writer_qnone.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
  W := OpenCSVWriter(OutFile, D);
  Raised := False;
  try
    try
      // contains delimiter -> should raise under QuoteMode=None
      W.WriteRow(['a,b']);
    except
      on E: ECSVError do Raised := True;
    end;
  finally
    W.Close;
    if FileExists(OutFile) then DeleteFile(OutFile);
  end;
  AssertTrue('QuoteMode=None should raise on fields requiring quotes', Raised);
end;

procedure TTestCase_Writer_Behaviors.Test_Writer_QuoteMode_None_Raises_On_TrailingSpace;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; Raised: Boolean; Code: TECSVErrorCode;
begin
  D := DefaultRFC4180; D.QuoteMode := csvQuoteNone;
  OutFile := 'tmp_writer_qnone_space.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
  W := OpenCSVWriter(OutFile, D);
  Raised := False; Code := csvErrUnknown;
  try
    try
      // trailing space should require quotes -> raise when QuoteMode=None
      W.WriteRow(['a ']);
    except
      on E: ECSVError do begin Raised := True; Code := E.Code; end;
    end;
  finally
    W.Close;
    if FileExists(OutFile) then DeleteFile(OutFile);
  end;
  AssertTrue('QuoteMode=None should raise on trailing space field', Raised);
  AssertEquals('Error code should be csvErrInvalidFieldForQuoteMode', Ord(csvErrInvalidFieldForQuoteMode), Ord(Code));
end;

procedure TTestCase_Writer_Behaviors.Test_Writer_QuoteMode_None_Raises_On_Leading_Comment_Char;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; Raised: Boolean; Code: TECSVErrorCode;
begin
  D := DefaultRFC4180; D.QuoteMode := csvQuoteNone; D.Comment := '#';
  OutFile := 'tmp_writer_qnone_comment.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
  W := OpenCSVWriter(OutFile, D);
  Raised := False; Code := csvErrUnknown;
  try
    try
      // field starts with comment char -> should require quote -> raise in QuoteMode=None
      W.WriteRow(['#note']);
    except
      on E: ECSVError do begin Raised := True; Code := E.Code; end;
    end;
  finally
    W.Close;
    if FileExists(OutFile) then DeleteFile(OutFile);
  end;
  AssertTrue('QuoteMode=None should raise on field starting with comment char', Raised);
  AssertEquals('Error code should be csvErrInvalidFieldForQuoteMode', Ord(csvErrInvalidFieldForQuoteMode), Ord(Code));
end;

initialization
  RegisterTest(TTestCase_Writer_Behaviors);

end.
