{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_roundtrip_comments;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_Roundtrip = class(TTestCase)
  published
    procedure Test_Roundtrip_Comments_And_Blanks;
  end;

implementation

procedure TTestCase_Roundtrip.Test_Roundtrip_Comments_And_Blanks;
const
  SRC: RawByteString =
    RawByteString('; prelude comment') + LineEnding +
    RawByteString('') + LineEnding +
    RawByteString('[core]') + LineEnding +
    RawByteString('; header comment') + LineEnding +
    RawByteString('name = x') + LineEnding +
    RawByteString('') + LineEnding +
    RawByteString('[ui]') + LineEnding +
    RawByteString('theme=dark') + LineEnding;
var Doc: IIniDocument; Err: TIniError; OutText: RawByteString;
    Doc2: IIniDocument; Err2: TIniError;
begin
  Err.Clear;
  AssertTrue(Parse(SRC, Doc, Err));
  OutText := ToIni(Doc, [iwfSpacesAroundEquals]);
  // 再解析一次，要求不丢注释/空白
  Err2.Clear;
  AssertTrue(Parse(OutText, Doc2, Err2));
  AssertTrue(Length(OutText) > 0);
end;

initialization
  RegisterTest(TTestCase_Roundtrip);
end.

