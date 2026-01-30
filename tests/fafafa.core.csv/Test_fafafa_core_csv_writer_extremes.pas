{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_writer_extremes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv, Test_CSV_Utils;

type
  TTestCase_Writer_Extremes = class(TTestCase)
  published
    procedure Test_Writer_Empty_Fields_Unquoted;
    procedure Test_Writer_Very_Long_Unicode_Field_ReadBack_OK;
  end;

implementation

function Checksum(const Rbs: RawByteString): UInt32;
var
  i: SizeInt;
  s: UInt32;
begin
  s := 0;
  for i := 1 to Length(Rbs) do
    s := ((s shl 5) or (s shr 27)) xor Byte(Rbs[i]);
  Result := s;
end;

procedure TTestCase_Writer_Extremes.Test_Writer_Empty_Fields_Unquoted;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; Raw: RawByteString; FS: TFileStream;
begin
  D := DefaultRFC4180; OutFile := 'tmp_writer_empty.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
  W := OpenCSVWriter(OutFile, D);
  AssertTrue('Writer should be created', W <> nil);
  W.WriteRow(['','','']);
  W.Flush; W.Close;
  FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Raw, FS.Size);
    if FS.Size > 0 then FS.ReadBuffer(Pointer(Raw)^, Length(Raw));
  finally
    FS.Free;
  end;
  // Expect: ",," + CRLF
  AssertTrue('should contain exactly ",," before line end', Copy(Raw, 1, 2) = ',,');
  AssertTrue('should end with CRLF', Copy(Raw, Length(Raw)-1, 2) = #13#10);
  if FileExists(OutFile) then DeleteFile(OutFile);
end;

procedure TTestCase_Writer_Extremes.Test_Writer_Very_Long_Unicode_Field_ReadBack_OK;
var
  D: TCSVDialect; W: ICSVWriter; R: ICSVReader; Rec: ICSVRecord; OutFile: string;
  S: UnicodeString; I: Integer; E, A: RawByteString;
  mismatchIdx: Integer;
  readField: UnicodeString;
  k: Integer;
begin
  D := DefaultRFC4180; OutFile := 'tmp_writer_long.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
  W := OpenCSVWriter(OutFile, D);
  AssertTrue('Writer should be created', W <> nil);
  SetLength(S, 100000);
  for I := 1 to Length(S) do S[I] := '你'; // multibyte UTF-8 char
  W.WriteRowU([S, 'end']);
  W.Flush; W.Close;
  R := OpenCSVReader(OutFile, D);
  AssertTrue('ReadNext should succeed', R.ReadNext(Rec));
  AssertEquals(2, Rec.Count);
  // Compare Unicode semantics with FieldU accessor
  AssertEquals('unicode length mismatch', Length(S), Length(Rec.FieldU(0)));
  // Debug: find first mismatch position
  if Rec.FieldU(0) <> S then
  begin
    mismatchIdx := -1;
    readField := Rec.FieldU(0);
    for k := 1 to Length(S) do
      if (k > Length(readField)) or (readField[k] <> S[k]) then begin mismatchIdx := k; Break; end;
    Fail(Format('long field unicode content mismatch at position %d (expected char %d, got %d)',
      [mismatchIdx, Ord(S[mismatchIdx]), Ord(readField[mismatchIdx])]));
  end;
  AssertEquals('end', Rec.Field(1));
  if FileExists(OutFile) then DeleteFile(OutFile);
end;

initialization
  RegisterTest(TTestCase_Writer_Extremes);

end.

