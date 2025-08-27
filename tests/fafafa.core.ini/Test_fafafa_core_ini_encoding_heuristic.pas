{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_encoding_heuristic;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_EncodingHeuristic = class(TTestCase)
  published
    procedure Test_ASCII_NoBOM_Treated_As_UTF8;
    procedure Test_UTF8_NoBOM_With_NonASCII_Treated_As_UTF8;
  end;

implementation

procedure TTestCase_EncodingHeuristic.Test_ASCII_NoBOM_Treated_As_UTF8;
const SRC = '[s]'#10'a=abc123'#10;
var Doc: IIniDocument; Err: TIniError; Enc: String; tmp: String;
begin
  tmp := 'tmp_ascii.ini';
  with TFileStream.Create(tmp, fmCreate) do
  try
    WriteBuffer(PAnsiChar(AnsiString(SRC))^, Length(AnsiString(SRC)));
  finally Free; end;
  Err.Clear;
  AssertTrue(ParseFileEx(tmp, Doc, Err, Enc, []));
  AssertTrue((Enc='UTF-8') or (Enc='UTF-8-BOM'));
  if FileExists(tmp) then DeleteFile(tmp);
end;

procedure TTestCase_EncodingHeuristic.Test_UTF8_NoBOM_With_NonASCII_Treated_As_UTF8;
const SRC = '[s]'#10'a=中文'#10; // UTF-8 无 BOM
var Doc: IIniDocument; Err: TIniError; Enc: String; tmp: String; Out1: RawByteString;
begin
  tmp := 'tmp_utf8_nobom.ini';
  with TFileStream.Create(tmp, fmCreate) do
  try
    // 直接按 UTF-8 写入
    WriteBuffer(PAnsiChar(UTF8Encode(SRC))^, Length(UTF8Encode(SRC)));
  finally Free; end;
  Err.Clear;
  AssertTrue(ParseFileEx(tmp, Doc, Err, Enc, []));
  AssertTrue((Enc='UTF-8') or (Enc='UTF-8-BOM'));
  Out1 := ToIni(Doc, [iwfForceLF]);
  AssertTrue(Pos('a=中文', String(Out1))>0);
  if FileExists(tmp) then DeleteFile(tmp);
end;

initialization
  RegisterTest(TTestCase_EncodingHeuristic);
end.

