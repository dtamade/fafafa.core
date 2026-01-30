{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_toFile_parseFileEx;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_ToFile_ParseFileEx = class(TTestCase)
  published
    procedure Test_ToFile_Then_ParseFile_Roundtrip;
    procedure Test_ParseFileEx_Returns_Encoding;
  end;

implementation

procedure TTestCase_ToFile_ParseFileEx.Test_ToFile_Then_ParseFile_Roundtrip;
var
  Doc1, Doc2: IIniDocument; Err: TIniError; tmp: String; Out1: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('[a]'#10'a=1'#10), Doc1, Err));
  tmp := 'tmp_out.ini';
  AssertTrue(ToFile(Doc1, tmp, [iwfSpacesAroundEquals, iwfForceLF]));
  Err.Clear;
  AssertTrue(ParseFile(tmp, Doc2, Err));
  Out1 := ToIni(Doc2, [iwfSpacesAroundEquals, iwfForceLF]);
  AssertTrue(Pos('[a]', String(Out1))>0);
  // 未脏回放时，写出保持原样（可能是 'a=1'）；已脏时才受 iwfSpacesAroundEquals 影响
  AssertTrue( (Pos('a = 1', String(Out1))>0) or (Pos('a=1', String(Out1))>0) );
  if FileExists(tmp) then DeleteFile(tmp);
end;

procedure TTestCase_ToFile_ParseFileEx.Test_ParseFileEx_Returns_Encoding;
var
  Doc: IIniDocument; Err: TIniError; tmp: String; enc: String;
begin
  tmp := 'tmp_utf8bom.ini';
  // 写入 UTF-8 BOM 文件
  with TFileStream.Create(tmp, fmCreate) do
  try
    // BOM
    WriteBuffer(#$EF#$BB#$BF, 3);
    // 内容
    WriteBuffer(PAnsiChar(AnsiString('[x]'#13#10'a=1'#13#10))^, Length(AnsiString('[x]'#13#10'a=1'#13#10)));
  finally
    Free;
  end;
  Err.Clear;
  AssertTrue(ParseFileEx(tmp, Doc, Err, enc, []));
  AssertTrue((enc='UTF-8-BOM') or (enc='UTF-8'));
  if FileExists(tmp) then DeleteFile(tmp);
end;

initialization
  RegisterTest(TTestCase_ToFile_ParseFileEx);
end.

