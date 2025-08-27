{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_read_flags_extras;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_ReadFlags_Extras = class(TTestCase)
  published
    procedure Test_StrictKeyChars_Rejects_Illegal;
    procedure Test_AllowQuotedValue_Preserves_Quotes;
  end;

implementation

procedure TTestCase_ReadFlags_Extras.Test_StrictKeyChars_Rejects_Illegal;
const
  SRC = '[s]'+LineEnding+'a b=1'+LineEnding; // 键名含空格非法
var Doc: IIniDocument; Err: TIniError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString(SRC), Doc, Err, [irfStrictKeyChars]));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(iecInvalidIni), Ord(Err.Code));
end;

procedure TTestCase_ReadFlags_Extras.Test_AllowQuotedValue_Preserves_Quotes;
const
  SRC = '[s]'+LineEnding+'a="v;#"'+LineEnding;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err, [irfInlineComment, irfAllowQuotedValue]));
  AssertTrue(Doc.TryGetString('s','a', S));
  // 保留外层引号
  AssertEquals('"v;#"', S);
end;

initialization
  RegisterTest(TTestCase_ReadFlags_Extras);
end.

