{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_builder_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_BuilderOptions = class(TTestCase)
  published
    procedure Test_Builder_StrictUTF8_Raises;
    procedure Test_Builder_ReplaceInvalidUTF8_Allows;
    procedure Test_Builder_MaxRecordBytes_Limit;
  end;

implementation

function MakeInvalidUTF8: RawByteString;
begin
  // 'ok,' + 0xC3 (truncated 2-byte sequence) + ',end' + LF
  SetCodePage(Result, CP_UTF8, False);
  Result := 'ok,' + AnsiChar(#$C3) + ',end' + #10;
end;

procedure TTestCase_Reader_BuilderOptions.Test_Builder_StrictUTF8_Raises;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; Tmp: string; FS: TFileStream;
  Raised: Boolean; Code: TECSVErrorCode; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  Tmp := 'tmp_builder_strictutf8.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  // write invalid-UTF8 content
  FS := TFileStream.Create(Tmp, fmCreate);
  try
    // use a local variable for Raw (declare before use)
    Raw := MakeInvalidUTF8;
    FS.WriteBuffer(Pointer(Raw)^, Length(Raw));
  finally
    FS.Free;
  end;
  Raised := False; Code := csvErrUnknown;
  try
    R := CSVReaderBuilder.FromFile(Tmp).Dialect(D).StrictUTF8(True).Build;
    try
      R.ReadNext(Rec);
    except on E: ECSVError do begin Raised := True; Code := E.Code; end; end;
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
  AssertTrue('Should raise under StrictUTF8', Raised);
  AssertEquals('Error code should be InvalidUTF8', Ord(csvErrInvalidUTF8), Ord(Code));
end;

procedure TTestCase_Reader_BuilderOptions.Test_Builder_ReplaceInvalidUTF8_Allows;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; Tmp: string; FS: TFileStream; Raw: RawByteString;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  Tmp := 'tmp_builder_replaceutf8.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  FS := TFileStream.Create(Tmp, fmCreate);
  try
    Raw := MakeInvalidUTF8;
    FS.WriteBuffer(Pointer(Raw)^, Length(Raw));
  finally
    FS.Free;
  end;
  try
    R := CSVReaderBuilder.FromFile(Tmp).Dialect(D).ReplaceInvalidUTF8(True).Build;
    AssertTrue('Should read first record', R.ReadNext(Rec));
    AssertTrue('Should have at least 2 fields', Rec.Count >= 2);
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

procedure TTestCase_Reader_BuilderOptions.Test_Builder_MaxRecordBytes_Limit;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; Tmp: string; F: TextFile;
  Raised: Boolean; Code: TECSVErrorCode;
begin
  D := DefaultRFC4180; D.HasHeader := False;
  Tmp := 'tmp_builder_maxrecord.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  // line longer than 8 bytes
  AssignFile(F, Tmp); Rewrite(F); Writeln(F, 'abcdefghij'); CloseFile(F);
  Raised := False; Code := csvErrUnknown;
  try
    R := CSVReaderBuilder.FromFile(Tmp).Dialect(D).MaxRecordBytes(8).Build;
    try
      R.ReadNext(Rec);
    except on E: ECSVError do begin Raised := True; Code := E.Code; end; end;
  finally
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
  AssertTrue('Should raise when record exceeds MaxRecordBytes', Raised);
  AssertEquals('Error code should be RecordTooLarge', Ord(csvErrRecordTooLarge), Ord(Code));
end;

initialization
  RegisterTest(TTestCase_Reader_BuilderOptions);

end.

