{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_error_codes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_ErrorCodes = class(TTestCase)
  published
    procedure Test_ErrorCode_UnexpectedQuote;
    procedure Test_ErrorCode_UnterminatedQuote;
    procedure Test_ErrorCode_FieldCountMismatch;
    procedure Test_ErrorCode_InvalidUTF8_Strict;
    procedure Test_ErrorCode_RecordTooLarge;
  end;

implementation

procedure TTestCase_Reader_ErrorCodes.Test_ErrorCode_UnexpectedQuote;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream;
  Raised: Boolean; Code: TECSVErrorCode;
  Raw: RawByteString;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.AllowLazyQuotes := False;
  TmpFile := 'tmp_err_unexpected_quote.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  // unquoted field contains '"' in the middle -> should raise unexpected quote
  Raw := 'ab"cd,ef' + #10;
  SetCodePage(Raw, CP_UTF8, False);
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    try
      R.ReadNext(Rec);
    except
      on E: ECSVError do begin Raised := True; Code := E.Code; end;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue('Should raise ECSVError', Raised);
  AssertEquals(Ord(csvErrUnexpectedQuote), Ord(Code));
end;

procedure TTestCase_Reader_ErrorCodes.Test_ErrorCode_UnterminatedQuote;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream;
  Raised: Boolean; Code: TECSVErrorCode;
  Raw: RawByteString;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.AllowLazyQuotes := False;
  TmpFile := 'tmp_err_unterminated.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  // starting quote but no closing quote before EOL/EOF
  Raw := '"abc,def' + #10; // unterminated quoted field
  SetCodePage(Raw, CP_UTF8, False);
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    try
      R.ReadNext(Rec);
    except
      on E: ECSVError do begin Raised := True; Code := E.Code; end;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue('Should raise ECSVError', Raised);
  AssertEquals(Ord(csvErrUnterminatedQuote), Ord(Code));
end;

procedure TTestCase_Reader_ErrorCodes.Test_ErrorCode_FieldCountMismatch;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string;
  Raised: Boolean; Code: TECSVErrorCode;
  FS: TFileStream; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.AllowVariableFields := False;
  TmpFile := 'tmp_err_mismatch.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  Raw := 'a,b,c' + #10 + '1,2' + #10; // second line fewer fields => mismatch
  SetCodePage(Raw, CP_UTF8, False);
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    // first record ok
    AssertTrue(R.ReadNext(Rec));
    // second should raise
    try
      R.ReadNext(Rec);
    except
      on E: ECSVError do begin Raised := True; Code := E.Code; end;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue('Should raise mismatch', Raised);
  AssertEquals(Ord(csvErrFieldCountMismatch), Ord(Code));
end;

procedure TTestCase_Reader_ErrorCodes.Test_ErrorCode_InvalidUTF8_Strict;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string;
  Raised: Boolean; Code: TECSVErrorCode;
  FS: TFileStream; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.StrictUTF8 := True; D.ReplaceInvalidUTF8 := False;
  TmpFile := 'tmp_err_invalid_utf8.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  SetCodePage(Raw, CP_UTF8, False);
  Raw := 'ok,' + AnsiChar(#$C3) + ',end' + #10; // truncated 2-byte seq
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    try
      R.ReadNext(Rec);
    except
      on E: ECSVError do begin Raised := True; Code := E.Code; end;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue('Should raise invalid UTF-8 under StrictUTF8', Raised);
  AssertEquals(Ord(csvErrInvalidUTF8), Ord(Code));
end;

procedure TTestCase_Reader_ErrorCodes.Test_ErrorCode_RecordTooLarge;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string;
  Raised: Boolean; Code: TECSVErrorCode;
  FS: TFileStream; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.MaxRecordBytes := 8; // small threshold to trigger
  TmpFile := 'tmp_err_record_too_large.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  SetCodePage(Raw, CP_UTF8, False);
  Raw := 'abcdefghij' + #10; // 10 bytes > 8
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    try
      R.ReadNext(Rec);
    except
      on E: ECSVError do begin Raised := True; Code := E.Code; end;
    end;
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
  AssertTrue('Should raise record too large', Raised);
  AssertEquals(Ord(csvErrRecordTooLarge), Ord(Code));
end;

initialization
  RegisterTest(TTestCase_Reader_ErrorCodes);
end.

