{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_utf16_bom;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_Utf16BOM = class(TTestCase)
  published
    procedure Test_ParseFile_UTF16LE_BOM_Success;
  end;

implementation

procedure TTestCase_Utf16BOM.Test_ParseFile_UTF16LE_BOM_Success;
var
  TmpFile: String;
  FS: TFileStream;
  Doc: IIniDocument; Err: TIniError;
  S: RawByteString;
  WS: UnicodeString;
begin
  TmpFile := 'tmp_utf16_le.ini';
  // Prepare UTF-16LE BOM + content: [a]\r\nx=1\r\n
  WS := UnicodeString('[a]'#13#10'x=1'#13#10);
  try
    FS := TFileStream.Create(TmpFile, fmCreate);
    try
      // Write BOM FF FE
      S := '';
      SetLength(S, 2);
      S[1] := AnsiChar(#$FF);
      S[2] := AnsiChar(#$FE);
      if Length(S) > 0 then FS.WriteBuffer(S[1], Length(S));
      // Write UTF-16LE bytes of WS
      if Length(WS) > 0 then
        FS.WriteBuffer(WS[1], Length(WS)*SizeOf(WideChar));
    finally
      FS.Free;
    end;

    Err.Clear;
    AssertTrue(ParseFile(TmpFile, Doc, Err));
    AssertTrue(Doc.HasSection('a'));
    AssertTrue(Doc.TryGetString('a','x', TmpFile)); // reuse TmpFile as a string holder
    AssertEquals('1', TmpFile);
  finally
    if FileExists(TmpFile) then DeleteFile(TmpFile);
  end;
end;

initialization
  RegisterTest(TTestCase_Utf16BOM);
end.

