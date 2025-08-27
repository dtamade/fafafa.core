{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_reader_builder_precedence;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Reader_BuilderPrecedence = class(TTestCase)
  published
    procedure Test_Builder_Overrides_Dialect_Strict_to_Replace;
    procedure Test_Builder_Overrides_Dialect_Replace_to_Strict;
  end;

implementation

function MakeInvalidUTF8: RawByteString;
begin
  SetCodePage(Result, CP_UTF8, False);
  Result := 'ok,' + AnsiChar(#$C3) + ',end' + #10; // truncated sequence
end;

procedure TTestCase_Reader_BuilderPrecedence.Test_Builder_Overrides_Dialect_Strict_to_Replace;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; Tmp: string; FS: TFileStream; Raw: RawByteString;
begin
  // Dialect says Strict, Builder says Replace -> Builder should win (no raise)
  D := DefaultRFC4180; D.HasHeader := False; D.StrictUTF8 := True; D.ReplaceInvalidUTF8 := False;
  Tmp := 'tmp_builder_prec_strict_to_replace.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  Raw := MakeInvalidUTF8; FS := TFileStream.Create(Tmp, fmCreate); try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  try
    R := CSVReaderBuilder.FromFile(Tmp).Dialect(D).ReplaceInvalidUTF8(True).Build;
    AssertTrue('Read should succeed without exception', R.ReadNext(Rec));
  finally if FileExists(Tmp) then DeleteFile(Tmp); end;
end;

procedure TTestCase_Reader_BuilderPrecedence.Test_Builder_Overrides_Dialect_Replace_to_Strict;
var
  D: TCSVDialect; R: ICSVReader; Rec: ICSVRecord; Tmp: string; FS: TFileStream; Raw: RawByteString;
  Raised: Boolean; Code: TECSVErrorCode;
begin
  // Dialect says Replace, Builder says Strict -> Builder should win (raise)
  D := DefaultRFC4180; D.HasHeader := False; D.StrictUTF8 := False; D.ReplaceInvalidUTF8 := True;
  Tmp := 'tmp_builder_prec_replace_to_strict.csv'; if FileExists(Tmp) then DeleteFile(Tmp);
  Raw := MakeInvalidUTF8; FS := TFileStream.Create(Tmp, fmCreate); try FS.WriteBuffer(Pointer(Raw)^, Length(Raw)); finally FS.Free; end;
  Raised := False; Code := csvErrUnknown;
  try
    R := CSVReaderBuilder.FromFile(Tmp).Dialect(D).StrictUTF8(True).Build;
    try R.ReadNext(Rec); except on E: ECSVError do begin Raised := True; Code := E.Code; end; end;
  finally if FileExists(Tmp) then DeleteFile(Tmp); end;
  AssertTrue('Should raise under Strict from Builder', Raised);
  AssertEquals('Error code should be InvalidUTF8', Ord(csvErrInvalidUTF8), Ord(Code));
end;

initialization
  RegisterTest(TTestCase_Reader_BuilderPrecedence);

end.

