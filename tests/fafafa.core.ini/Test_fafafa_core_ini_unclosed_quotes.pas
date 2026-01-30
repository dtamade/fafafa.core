{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_unclosed_quotes;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_UnclosedQuotes = class(TTestCase)
  published
    procedure Test_Unclosed_Quotes_Error;
  end;

implementation

procedure TTestCase_UnclosedQuotes.Test_Unclosed_Quotes_Error;
const
  SRC = '[a]'+LineEnding+
        'x = "1;keep ; trailing'+LineEnding; // unclosed double quote
var Doc: IIniDocument; Err: TIniError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString(SRC), Doc, Err, [irfInlineComment]));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(iecInvalidIni), Ord(Err.Code));
end;

initialization
  RegisterTest(TTestCase_UnclosedQuotes);
end.

