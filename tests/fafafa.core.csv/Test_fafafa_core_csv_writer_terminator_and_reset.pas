{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_writer_terminator_and_reset;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_WriterTerminatorAndReaderReset = class(TTestCase)
  published
    procedure Test_Writer_Terminator_LF;
    procedure Test_Reader_Reset_ClearsHeaders;
  end;

implementation

procedure TTestCase_WriterTerminatorAndReaderReset.Test_Writer_Terminator_LF;
var
  D: TCSVDialect;
  W: ICSVWriter;
  OutFile: string;
  FS: TFileStream;
  Bytes: TBytes;
  Raw: RawByteString;
begin
  D := DefaultRFC4180;
  OutFile := 'tmp_writer_lf_only.csv';
  if FileExists(OutFile) then DeleteFile(OutFile);
  W := CSVWriterBuilder.ToFile(OutFile).Dialect(D).Terminator(csvTermLF).Build;
  AssertTrue('Writer should be created', W <> nil);
  W.WriteRow(['a','b']);
  W.WriteRow(['c','d']);
  W.Close; // ensure data visible

  // Verify line endings are LF-only
  FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Bytes, FS.Size);
    if Length(Bytes) > 0 then FS.ReadBuffer(Bytes[0], Length(Bytes));
  finally
    FS.Free;
  end;
  SetLength(Raw, Length(Bytes));
  if Length(Bytes) > 0 then Move(Bytes[0], Pointer(Raw)^, Length(Bytes));
  // Expect "a,b\nc,d\n" (LF only)
  AssertTrue('Expect LF-only newlines', Pos(#13, Raw) = 0);
  AssertTrue('Expect two LF newlines', Pos('a,b'#10'c,d'#10, Raw) = 1);
  if FileExists(OutFile) then DeleteFile(OutFile);
end;

procedure TTestCase_WriterTerminatorAndReaderReset.Test_Reader_Reset_ClearsHeaders;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
  Tmp: string;
  F: TextFile;
  Headers: TStringArray;
begin
  // Prepare a file with header and one data row
  Tmp := 'tmp_reset_headers.csv';
  AssignFile(F, Tmp); Rewrite(F);
  Writeln(F, 'h1,h2');
  Writeln(F, 'v1,v2');
  CloseFile(F);

  D := DefaultRFC4180; D.HasHeader := True;
  R := OpenCSVReader(Tmp, D);
  AssertTrue('Read first record (header)', R.ReadNext(Rec));
  Headers := R.Headers;
  AssertEquals('Header count should be 2', 2, Length(Headers));

  // Reset and re-read; headers should be cleared and re-parsed
  R.Reset;
  AssertTrue('After Reset, should read first record again', R.ReadNext(Rec));
  Headers := R.Headers;
  AssertEquals('After Reset, header count should be 2', 2, Length(Headers));

  if FileExists(Tmp) then DeleteFile(Tmp);
end;

initialization
  RegisterTest(TTestCase_WriterTerminatorAndReaderReset);

end.

