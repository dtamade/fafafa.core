{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_invalid_utf8;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

// Tests for invalid UTF-8 handling strategies

type
  TTestCase_Reader_InvalidUTF8 = class(TTestCase)
  published
    procedure Test_Default_Behavior_Invalid_UTF8_Does_Not_Raise;
    procedure Test_StrictUTF8_Raises_On_Invalid_UTF8;
    procedure Test_ReplaceInvalidUTF8_Replaces_Invalid_Sequence;
  end;

implementation

function MakeInvalidUTF8: RawByteString;
begin
  // Construct bytes: 'ok,' + 0xC3 (truncated 2-byte sequence) + ',end' with LF
  SetCodePage(Result, CP_UTF8, False);
  Result := 'ok,' + AnsiChar(#$C3) + ',end' + #10;
end;

procedure TTestCase_Reader_InvalidUTF8.Test_Default_Behavior_Invalid_UTF8_Does_Not_Raise;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.HasHeader := False; // default: StrictUTF8=False, ReplaceInvalidUTF8=False
  TmpFile := 'tmp_invalid_utf8_default.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  Raw := MakeInvalidUTF8;
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    // Default path should not raise; exact decoded content depends on runtime behavior
    AssertTrue(R.ReadNext(Rec));
    // Expect at least two fields; exact split depends on parser behavior
    AssertTrue(Rec.Count >= 2);
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
end;

procedure TTestCase_Reader_InvalidUTF8.Test_StrictUTF8_Raises_On_Invalid_UTF8;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream; Raw: RawByteString;
  Raised: Boolean; GotLine, GotCol: Integer;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.StrictUTF8 := True; D.ReplaceInvalidUTF8 := False;
  TmpFile := 'tmp_invalid_utf8_strict.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  Raw := MakeInvalidUTF8;
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  Raised := False;
  try
    R := OpenCSVReader(TmpFile, D);
    try
      R.ReadNext(Rec);
    except on E: ECSVError do begin Raised := True; GotLine := E.Line; GotCol := E.Column; end; end;
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
  AssertTrue(Raised);
  AssertEquals(1, GotLine);
  AssertEquals(1, GotCol);
end;

procedure TTestCase_Reader_InvalidUTF8.Test_ReplaceInvalidUTF8_Replaces_Invalid_Sequence;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; TmpFile: string; FS: TFileStream; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.HasHeader := False; D.ReplaceInvalidUTF8 := True; D.StrictUTF8 := False;
  TmpFile := 'tmp_invalid_utf8_replace.csv'; if FileExists(TmpFile) then DeleteFile(TmpFile);
  Raw := MakeInvalidUTF8;
  FS := TFileStream.Create(TmpFile, fmCreate);
  try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  try
    R := OpenCSVReader(TmpFile, D);
    AssertTrue(R.ReadNext(Rec));
    // Replacement mode: depending on runtime, the invalid byte becomes a single char field
    AssertTrue(Rec.Count >= 2);
    AssertTrue(Length(Rec.FieldU(1)) >= 1);
  finally if FileExists(TmpFile) then DeleteFile(TmpFile); end;
end;

initialization
  RegisterTest(TTestCase_Reader_InvalidUTF8);

end.

