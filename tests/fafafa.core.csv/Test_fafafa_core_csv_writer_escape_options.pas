{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_writer_escape_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_Writer_Escape_Options = class(TTestCase)
  published
    procedure Test_Writer_Escape_Backslash_When_DoubleQuote_False;
    procedure Test_Writer_DoubleQuote_Takes_Precedence_When_Both_Enabled;
    procedure Test_Writer_Escape_Backslash_Inside_Quoted_By_Space;
  end;

implementation

procedure TTestCase_Writer_Escape_Options.Test_Writer_Escape_Backslash_When_DoubleQuote_False;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; FS: TFileStream; Raw, Expected: RawByteString;
begin
  D := DefaultRFC4180;
  D.Escape := '\\'; // backslash as escape
  D.DoubleQuote := False; // prefer escape over doubling
  OutFile := 'tmp_writer_escape_only.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
  W := OpenCSVWriter(OutFile, D);
  W.WriteRow(['a"b','c']);
  W.Flush; W.Close;
  Expected := '"a\\""b",c' + #13#10; // " inside quotes; note: Pascal string needs escaping
  // Build expected precisely using bytes
  Expected := '"a' + RawByteString('\') + '"' + '"b",c' + #13#10;
  FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Raw, FS.Size);
    if FS.Size > 0 then FS.ReadBuffer(Pointer(Raw)^, Length(Raw));
  finally
    FS.Free;
  end;
  AssertTrue('Writer should use Escape for quotes when DoubleQuote=False', Raw = Expected);
  if FileExists(OutFile) then DeleteFile(OutFile);
end;

procedure TTestCase_Writer_Escape_Options.Test_Writer_DoubleQuote_Takes_Precedence_When_Both_Enabled;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; FS: TFileStream; Raw, Expected: RawByteString;
begin
  D := DefaultRFC4180;
  D.Escape := '\\';
  D.DoubleQuote := True; // precedence: double-quote wins
  OutFile := 'tmp_writer_escape_and_double.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
  W := OpenCSVWriter(OutFile, D);
  W.WriteRow(['a"b','c']);
  W.Flush; W.Close;
  Expected := '"a""b",c' + #13#10;
  FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Raw, FS.Size);
    if FS.Size > 0 then FS.ReadBuffer(Pointer(Raw)^, Length(Raw));
  finally
    FS.Free;
  end;
  AssertTrue('Writer should double quotes when DoubleQuote=True even if Escape is set', Raw = Expected);
  if FileExists(OutFile) then DeleteFile(OutFile);
end;

procedure TTestCase_Writer_Escape_Options.Test_Writer_Escape_Backslash_Inside_Quoted_By_Space;
var
  D: TCSVDialect; W: ICSVWriter; OutFile: string; FS: TFileStream; Raw, Expected: RawByteString;
begin
  D := DefaultRFC4180;
  D.Escape := '\\';
  D.DoubleQuote := True; // still allow escape for backslash itself
  OutFile := 'tmp_writer_escape_backslash.csv'; if FileExists(OutFile) then DeleteFile(OutFile);
  W := OpenCSVWriter(OutFile, D);
  // field requires quotes due to leading/trailing spaces; contains a backslash which should be escaped to \\
  W.WriteRow([' a\\b ','c']);
  W.Flush; W.Close;
  Expected := '" a\\\\b ",c' + #13#10; // becomes " a\\b " in CSV bytes
  // Build expected to avoid confusion
  Expected := '" a' + RawByteString('\\') + 'b ",c' + #13#10;
  FS := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Raw, FS.Size);
    if FS.Size > 0 then FS.ReadBuffer(Pointer(Raw)^, Length(Raw));
  finally
    FS.Free;
  end;
  AssertTrue('Backslash should be escaped as \\ inside quoted field when Escape is enabled', Raw = Expected);
  if FileExists(OutFile) then DeleteFile(OutFile);
end;

initialization
  RegisterTest(TTestCase_Writer_Escape_Options);

end.

